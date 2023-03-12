
Syscall
=============
1. `the-definitive-guide-to-linux-system-calls  <https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/>`__
   `系统调用权威指南 <https://arthurchiao.art/blog/system-call-definitive-guide-zh>`__

2. `Linux syscall过程 —— 栈切换等 <https://cloud.tencent.com/developer/article/1492374>`__

概念
------

系统调用在用户空间进程和硬件设备之间添加了一个中间层，作用：

1. 为用户空间提供硬件抽象接口；
2. 保证系统的稳定与安全。内核基于权限、用户和其它规则对访问进行裁决；
3. 为运行在虚拟系统中的进程提供公共接口（？）。

其它：

1. 应用程序编程接口API：在用户空间实现，应用程序使用其来编程。不需要和系统调用对应。
2. POSIX：提供一套大体基于UNIX的操可移植作系统标准。
3. C库：Linux系统调用像其它大多数UNIX系统一样，作为C库的一部分提供。C库提供了POSIX的大部分API。
4. UNIX接口设计：提供机制（功能定义）而不是策略（如何实现）。
5. eax：存放系统调用号、返回值。

系统调用上下文
~~~~~~~~~~~~~~
内核在执行系统调用时处于进程上下文。

在进程上下文中内核可以休眠（系统调用阻塞、显式调用schedule）并且可以被抢占。

- 可休眠说明系统调用可以使用内核提供的大部分功能（而不可休眠的中断在编程时会受到极大限制）；
- 可抢占可需要保证系统调用是可重入。



x86 系统调用
--------------



1. 通过INT 0x80中断方式。
   
   * 在 2.6以前的 Linux 2.4 内核中，用户态 Ring3 代码请求内核态 Ring0 代码完成某些功能是通过系统调用完成的，而系统调用的是通过软中断指令(int 0x80) 实现的。在 x86 保护模式中，处理 INT 中断指令时
   * 在发生系统调用，由 Ring3 进入 Ring0 的这个过程浪费了不少的 CPU 周期，例如，系统调用必然需要由 Ring3 进入 Ring0，权限提升之前和之后的级别是固定的。

   ::

      1) CPU 首先从中断描述表 IDT 取出对应的门描述符
      2) 判断门描述符的种类
      3) 检查门描述符的级别 DPL 和 INT 指令调用者的级别 CPL，当 CPL<=DPL 也就是说 INT 调用者级别高于描述符指定级别时，才能成功调用
      4) 根据描述符的内容，进行压栈、跳转、权限级别提升
      5) 内核代码执行完毕之后，调用 IRET 指令返回，IRET 指令恢复用户栈，并跳转会低级别的代码 .
      

2. 32位快速系统调用： sysenter。

   sysenter 指令用于由 Ring3 进入 Ring0，SYSEXIT 指令用于由 Ring0 返回 Ring3。由于没有特权级别检查的处理，也没有压栈的操作，所以执行速度比 INT n/IRET 快了不少。
   
   sysenter和sysexit都是CPU原生支持的指令集

   内核函数 __kernel_vsyscall 封装了 sysenter 调用约定（calling convention）。它在内核实现，但每个用户进程启动的时候它会映射到用户进程。

   ::

      当执行 sysenter 时，执行以下操作：

      清除 FLAGS 的 VM 标志，确保在保护模式下运行
      清除 FLAGS 的 IF 标志，屏蔽中断
      加载 IA32_SYSENTER_ESP 的值到 esp
      加载 IA32_SYSENTER_EIP 的值到 eip
      加载 SYSENTER_CS_MSR 的值到 CS
      将 SYSENTER_CS_MSR + 8 的值加载到 ss 。因为在GDT中， ss 就跟在 cs 后面
      开始执行(cs:eip)指向的代码


3. 64位快速系统调用：Syscall
   sysenter 和 syscall 是为了加速系统调用所引入的新指令，通过引入新的 MSR 来存放内核态的代码和栈的段号和偏移量，从而实现快速跳转：

   syscall 调用约定（convention）： 用户空间程序将系统调用编号放到 rax 寄存器，参数放到通用寄存器。

   要使内核接收系统调用请求，必须将对应的回调函数地址写到 IA32_LSTAR MSR 







Linux系统调用的实现
--------------------------
1. `System calls · Linux Inside  <https://0xax.gitbooks.io/linux-insides/content/SysCall/>`__


根据系统调用号从系统调用表(sys_call_table) 中找到相应的处理函数

系统调用必须仔细检查参数是否合法。

syscall方式的实现
~~~~~~~~~~~~~~~~~~
1. 内核编译期间使用脚本从arch/x86/syscalls/syscall_64.tbl 生成 asm/syscalls_64.h(舒徐)
2. syscall_init将system_call 函数的地址写到了 **LSTAR MSR** （回调）
2. system_call调用sys_call_table中的函数


::

   void syscall_init(void)
   {
         /* ... other code ... */
         wrmsrl(MSR_LSTAR, system_call);




   system_call调用的实现 rch/x86/kernel/entry_64.S ：

   ENTRY(system_call)
      ...
      call *sys_call_table(,%rax,8)  # XXX:    rip relative



      asmlinkage const sys_call_ptr_t sys_call_table[__NR_syscall_max+1] = {
            /*
               * Smells like a compiler bug -- it doesn't work
               * when the & below is removed.
               */
            [0 ... __NR_syscall_max] = &sys_ni_syscall,
      #include <asm/syscalls_64.h>
      };


syscall注册和使用
~~~~~~~~~~~~~~~~~~~~~~~~
1. 加入系统调用表；
2. 编译进内核映像（不能是模块）；
3. 通过C库或使用_syscalln()访问系统调用。

_syscalln() -> K_INLINE_SYSCALL : 内联汇编


系统调用的替代：

1. 实现一个设备节点，然后使用read/write；
2. 使用文件描述符来表示。


虚拟系统调用vDSO和ASLR
----------------------
不进入内核即可执行系统调用，例如gettimeofday。


The Linux vDSO is a set of code that is part of the kernel.

The "vDSO" (virtual dynamic shared object) is a small shared  library that the kernel automatically maps into the address space   of all user-space applications.

地址随机(安全)
~~~~~~~~~~~~~~~~
Due to ASLR `address space layout randomization <https://en.wikipedia.org/wiki/Address_space_layout_randomization>`__
the vDSO will be loaded at a random address when a program is started.

每次运行都会有不同的地址。程序代码、库代码、栈、全局变量和堆数据。



syscall_wrapper x86
--------------------- 
**syscall wrapper function**: sysdeps/unix/sysv/linux/x86_64/syscall.S

::

   /* Usage: long syscall (syscall_number, arg1, arg2, arg3, arg4, arg5, arg6)
      We need to do some arg shifting, the syscall_number will be in
      rax.  */


   .text
   ENTRY (syscall)
         movq %rdi, %rax         /* Syscall number -> rax.  */
         movq %rsi, %rdi         /* shift arg1 - arg5.  */
         movq %rdx, %rsi
         movq %rcx, %rdx
         movq %r8, %r10
         movq %r9, %r8
         movq 8(%rsp),%r9        /* arg6 is on the stack.  */
         syscall                 /* Do the system call.  */
         cmpq $-4095, %rax       /* Check %rax for error.  */
         jae SYSCALL_ERROR_LABEL /* Jump to error handler if error.  */
   L(pseudo_end):
         ret                     /* Return to caller.  */


这段代码同时展示了两个调用约定：传递给这个函数的参数 符合 用户空间调用约定，
然后将这些参数移动到其他寄存器，使得它们在通过 syscall 进入内核之前符合 内核调用约定。


syscall 时，跳转到 entry_SYSCALL_64 开始执行，其定义在 arch/x86/entry/entry_64.S


手动syscall
~~~~~~~~~~~~~
不是所有的系统调用在glibc中都有对应的封装。

use syscall from glibc to call exit with exit status of 42:

::

   int
   main(int argc, char *argv[])
   {
   unsigned long syscall_nr = 60;
   long exit_status = 42;

   asm ("movq %0, %%rax\n"
         "movq %1, %%rdi\n"
         "syscall"
      : /* output parameters, we aren't outputting anything, no none */
         /* (none) */
      : /* input parameters mapped to %0 and %1, repsectively */
         "m" (syscall_nr), "m" (exit_status)
      : /* registers that we are "clobbering", unneeded since we are calling exit */
         "rax", "rdi");
   }
