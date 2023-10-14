
信号
==========
1. `Linux信号（signal) 机制分析 <https://www.cnblogs.com/hoys/archive/2012/08/19/2646377.html>`__


原理
------

1. 实时信号：可靠信号，支持多个相同信号排队，不会丢失。信号值位于SIGRTMIN和SIGRTMAX之间
2. 非实时信号：不可靠信号，

发送信号
~~~~~~~~~~
1. 内核设置进程PCB的未决信号集对应的位并将信号信息加入未决信号信息链。（实时信号可重复注册）
2. 若进程睡眠且处于可被中断的优先级上，则唤醒。
3. 处理时机： ``从内核态返回用户态时``。
4. 处理信号有三种类型：进程接收到信号后退出；进程忽略该信号；进程收到信号后执行用户设定用系统调用signal的函数


signal原型
------------

::

   signal()的原型
   void ( * signal(int sig,void ( * func)(int)))(int);   #  func和signal函数声明一致，但是不是同一个函数！！

   需要拆分为两部分来理解：
   typedef void( * ptr_to_func)(int);
   ptr_to_func signal(int，ptr_to_func); # signal 

   或
   typedef void ( * sighandler_t)(int);   # sighandler_t代表一种函数类型的原型
   sighandler_t signal(int signum, sighandler_t handler); # signal的入参signum实际上作为sighandler_t 的入参int被使用！！ 


示例代码：

::

   #include <stdio.h>
   
   enum { RED, GREEN, BLUE };
   
   void OutputSignal(int sig)
   {
         printf("The signal you /'ve input is: ");
         switch(sig)
         {
               case RED:
                     puts("RED!");
                     break;
            case GREEN:
                     puts("GREEN!");
                     break;
            case BLUE:
                     puts("BLUE!");
                     break;
         }
   }
   
   void ( *signal( int sig, void (*func)(int) ) ) (int)
   {
            puts("Hello, world!");
   
            func(sig);
   
            return func;
   }
   
   int main(void)
   {
            (*signal(GREEN, &OutputSignal))(RED);
   
            return 0;
   }


sigaction
------------
man sigaction

sigaction()是较新的函数（由两个系统调用实现：sys_signal以及sys_rt_sigaction）

有三个参数，支持信号传递信息，使用sigqueue(pid, SIGQUIT, val) 发送带参数的信号。

::

   原型：
   int sigaction(int signum, const struct sigaction *act,
                     struct sigaction *oldact);
   
   结构体，
   struct sigaction {
      void     (*sa_handler)(int);
      void     (*sa_sigaction)(int, siginfo_t *, void *);
      sigset_t   sa_mask;
      int        sa_flags;         //SA_SIGINFO：使用sa_sigaction;否则使用sa_handler
      void     (*sa_restorer)(void);
  };


带参数的sa_sigaction
~~~~~~~~~~~~~~~~~~~~~~~~
1. man sigaction
2. `42-带参数的信号_--Allen--的博客-CSDN博客  <https://blog.csdn.net/q1007729991/article/details/53893743>`__

ucontext指向信号上下文信息保存到的用户栈位置(由内核保存)。

::

     void   handler(int sig, siginfo_t *info, void *ucontext)


    sig    The number of the signal that caused invocation of the handler.

    info   A pointer to a siginfo_t, which is a structure containing further information about the  signal,
           as described below.

    ucontext
           This  is  a pointer to a ucontext_t structure, cast to void *.  The structure pointed to by this
           field contains signal context information that was saved on the user-space stack by the  kernel;
           for  details, see sigreturn(2).  Further information about the ucontext_t structure can be found
           in getcontext(3).  Commonly, the handler function doesn't make any use of the third argument.


getcontext
~~~~~~~~~~~
1. `Unix/Linux编程：getcontext、setcontext  <https://blog.csdn.net/zhizhengguan/article/details/118702857>`__


SUSv3 规定了这些函数，但将它们标记为已废止。SUSv4 则将其删去。

context使得linux程序可以在用户态执行上下文切换，从而避免了进程或者线程切换导致的切换用户空间、切换堆栈，因此，效率相对更高。

内核如何产生信号
----------------
1. `为什么发送segment fault信号的进程总是PID0 ？ - One Man's Yammer  <http://laoar.github.io/blogs/435/>`__


在内核中，force_sig_fault_to_task获取了current (task_strcut,包括堆栈等信息), 然后产生信号(send_signal,带第三个参数，给sigaction处理).

::

   linux\arch\x86\mm\fault.c
   mm_fault_error -> bad_area_nosemaphore -> force_sig_fault 
   -> force_sig_fault_to_task -> send_signal最终发出信号

         
   int force_sig_fault_to_task(int sig, int code, void __user *addr
   	___ARCH_SI_TRAPNO(int trapno)
   	___ARCH_SI_IA64(int imm, unsigned int flags, unsigned long isr)
   	, struct task_struct *t)
   {
   	struct kernel_siginfo info;

   	clear_siginfo(&info);
   	info.si_signo = sig;
   	info.si_errno = 0;
   	info.si_code  = code;
   	info.si_addr  = addr;
   #ifdef __ARCH_SI_TRAPNO
   	info.si_trapno = trapno;
   #endif
   #ifdef __ia64__
   	info.si_imm = imm;
   	info.si_flags = flags;
   	info.si_isr = isr;
   #endif
   	return force_sig_info_to_task(&info, t);
   }



   int force_sig_fault(int sig, int code, void __user *addr
   	___ARCH_SI_TRAPNO(int trapno)
   	___ARCH_SI_IA64(int imm, unsigned int flags, unsigned long isr))
   {
   	return force_sig_fault_to_task(sig, code, addr
   				       ___ARCH_SI_TRAPNO(trapno)
   				       ___ARCH_SI_IA64(imm, flags, isr), current);
   }


   static int
   force_sig_info_to_task(struct kernel_siginfo *info, struct task_struct *t)
   {
   ....
   	int sig = info->si_signo;

   	spin_lock_irqsave(&t->sighand->siglock, flags);
   	action = &t->sighand->action[sig-1];
   	ignored = action->sa.sa_handler == SIG_IGN;
   	blocked = sigismember(&t->blocked, sig);
   ....
   	if (action->sa.sa_handler == SIG_DFL && !t->ptrace)
   		t->signal->flags &= ~SIGNAL_UNKILLABLE;
   	ret = send_signal(sig, info, t, PIDTYPE_PID);
   	spin_unlock_irqrestore(&t->sighand->siglock, flags);

   	return ret;
   }



常见信号
-----------
sigsegv vs sigbus
~~~~~~~~~~~~~~~~~~~~~~~~~
`Program Error Signals (The GNU C Library)  <https://www.gnu.org/software/libc/manual/html_node/Program-Error-Signals.html#:~:text=The%20difference%20between%20the%20two,address%20not%20divisible%20by%20four.>`__

- sigsegv: sig11, 访问无权限的地址和写只读地址。attempt to access a valid memory address in a way that is **contrary to its protection**. writing to read-only memory
- sigbus: sig7, 访问无效地址（未对齐地址或未映射地址）。attempting to access an address that is **invalid**. improperly aligned address or an address that is not mapped 