
====================
Concurrency 
====================

:Date:   2021-07-31 13:37:13

并发编程
===========
1. 并发:系统支持两个或多个动作同时存在,不一定要同时执行。可以是多线程或单线程。
2. 并行:系统支持两个或多个动作同时执行。

多进程
-------

多路IO复用
----------

多线程
---------

多线程编程
============
进程与线程的区别
----------------------
线程是一种对等关系：
 
pthread_create分析
-------------------
1. https://code.woboq.org/userspace/glibc/nptl/pthread_create.c.html#625
2. https://www.cnblogs.com/lidabo/p/5514100.html
3. `pthread_create源码分析 <https://blog.csdn.net/conansonic/article/details/77487925>`_
4. `GLIBC中NPTL线程实现代码阅读 <https://blog.csdn.net/hnwyllmm/article/details/45749063>`_


nptl
~~~~~~~~~
 NPTL (Native POSIX Threads Library) is the GNU C library POSIX
       threads implementation

joinable&detached
~~~~~~~~~~~~~~~~~~~
1. joinable: 线程默认状态，可被其它线程回收和杀死(pthread_join)，并且在被其它线程回收前其资源不会释放。
2. detached: pthread_attr_setdetachstate设置，不可被其它线程回收和杀死，在线程结束时系统会自动回收资源。

如何避免detached线程在pthread_create返回tid前结束，其tid和资源被释放后并被其它线程复用，
从而使pthread_create得到错误地返回值？ 
使用pthread_cond_timewait+pthread_cond_signal。

源码分析
~~~~~~~~~~~~


pthread_t
~~~~~~~~~~~~~~~~~~~
1. https://stackoverflow.com/questions/33285562/why-and-in-what-sense-is-pthread-t-an-opaque-type

::

   /* Thread identifiers. The structure of the attribute type is not
      exposed on purpose.  */
   typedef unsigned long int pthread_t;

   in pthreadtypes.h




无锁编程
========

1. `无锁队列的实现 <https://coolshell.cn/articles/8239.html>`__\ ：？？
2. `An Introduction to Lock-Free Programming <https://preshing.com/20120612/an-introduction-to-lock-free-programming/>`__:有图！
3. `ARM体系架构下的同步操作 <https://www.cnblogs.com/shangdawei/p/3915735.html>`__

处理器可能会对输入代码进行乱序执行（Out-Of-OrderExecution）优化，
处理器会在计算之后将乱序执行的结果重组，保证该结果与顺序执行的\ **结果一致**\ ，
但并不保证程序中各个语句计算的先后顺序与输入代码中的顺序一致。

因此，如果存在一个计算任务依赖另一个计算任务的\ **中间结果**\ ，那么其顺序性并不能靠代码的先后顺序来保证。

原子操作的使用
--------------

gcc built-in
~~~~~~~~~~~~

`Built-in functions for atomic memory
access <https://gcc.gnu.org/onlinedocs/gcc-4.1.2/gcc/Atomic-Builtins.html>`__

gcc从4.1.2提供了\_\ *sync*\ \*系列的built-in函数，用于提供加减和逻辑运算的原子操作。

C11支持原子变量\ `Atomic
types <https://en.cppreference.com/w/c/language/atomic>`__\ 和\ `Atomic
operations library <https://en.cppreference.com/w/c/atomic>`__

linux kernel
~~~~~~~~~~~~

`原子性操作atomic_t <https://blog.csdn.net/a775992553/article/details/8797474>`__

https://www.cnblogs.com/jyfyonghu/p/11256608.html

内核中汇编实现原子操作。架构路径下的：\ `arch/x86/include/asm/atomic.h <https://sbexr.rabexc.org/latest/sources/b6/c49b0975774d96.html>`__
。

同时提供原子变量（实际上就是int），用作原子操作的参数。

X86 CAS实现
------------

X86对应一个原子命令cmpxchgl，arm则使用内存屏障dmb+原子加载ldxr+原子存贮stlxr
实现。

::

   #include <stdatomic.h>

   int main()
   {

       int a = 10 ;
       int b = __sync_val_compare_and_swap (&a, 10, 9);
   //    int c = __sync_val_compare_and_swap (&a, 9, 8);

       return 0;
   }



汇编


::

   pushq   %rbp
   movq    %rsp, %rbp
   movl    $10, -8(%rbp)
   movl    $10, %eax
   movl    $9, %edx
   lock cmpxchgl   %edx, -8(%rbp)
   movl    %eax, -4(%rbp)
   movl    $0, %eax
   popq    %rbp






arm64原子操作
-------------------
1. `ARMv8 架构与指令集.学习笔记 <https://www.cnblogs.com/lvdongjie/p/6644821.html>`__
2. `ARMv8.1平台下新添加原子操作指令_  <https://blog.csdn.net/Roland_Sun/article/details/107552574>`__
3. `ARM64+Linux5.0 自旋锁  <https://blog.csdn.net/zhoutaopower/article/details/117966631>`__
4. `ARM平台下独占访问指令LDREX和STREX的原理与使用详解  <https://blog.csdn.net/Roland_Sun/article/details/47670099>`__

armv8.1指令集添加了不少新功能，包括lse(large system extension)——包括许多原生原子操作指令。

在这之前必须使用LL/SC操作来实现原子操作。


LL/SC
~~~~~~~~
Load-Link（LL）和Store-Conditional（SC）。

LL/SC操作本质上是 ``很多CPU核去抢某个内存变量的独占访问``，在核数量日渐增长的情况下会造成性能问题。

LL操作返回一个内存地址上当前存储的值，后面的SC操作，会向这个内存地址写入一个新值，
但是只有在这个内存地址上存储的值， ``从上个LL操作开始直到现在都没有发生改变的情况下``，
写入操作才能成功，否则都会失败。

对于ARM平台来说，也在硬件层面上提供了对LL/SC的支持，LL操作用的是LDREX指令，SC操作用的是STREX指令。

LDXR
~~~~~~~
LDXR (load exclusive register 和STXR （store exclusive register）及其变种指令。

stlxr失败后会重试。


::

           .arch armv8-a

   main:
   .LFB0:

           sub     sp, sp, #16
           mov     w0, 10
           str     w0, [sp, 8]
           add     x1, sp, 8
           mov     w2, 9
   .L3:
           ldxr    w0, [x1]
           cmp     w0, 10
           bne     .L4
           stlxr   w3, w2, [x1]
           cbnz    w3, .L3
   .L4:
           dmb     ish
           str     w0, [sp, 12]
           mov     w0, 0
           add     sp, sp, 16
           .cfi_def_cfa_offset 0
           ret
           .cfi_endproc
   .LFE0:
           .size   main, .-main
           .ident  "GCC: (Debian 8.3.0-6) 8.3.0"
           .section        .note.GNU-stack,"",@progbits



LSE指令
~~~~~~~~~~
LD/ST:ADD/SET/CLR/EOR/SMAX/UMAX、SWP、CAS 

ST打头的指令和LD打头的指令，基本功能上没区别。

只不过LD打头的指令会把在执行该原子指令之前内存中的值存入第二个参数指定的寄存器中，ST打头的指令则少一个参数，没有此功能。

默认有32位和64位两种形式。可加后缀H（Halfword）、B（Byte）。

::

   LDADD <Ws>, <Wt>, [<Xn|SP>]
   LDADD <Xs>, <Xt>, [<Xn|SP>]
    
   STADD <Ws>, [<Xn|SP>]
   STADD <Xs>, [<Xn|SP>]




ABA问题
---------

1. 进程P1在共享变量中读到值为A
2. P1被抢占了，进程P2执行
3. P2把共享变量里的值从A改成了B，再改回到A，此时被P1抢占。
4. P1回来看到共享变量里的值没有被改变，于是继续执行。

使用double-CAS解决。


指令集与性能
============
1. armv8.1 lse扩展将原先的原先的LL+SC（load link、store conditional）两条指令和为一条，同时效率更高。
2. gcc中原来的_sync_系列指令不在推荐，现使用_atomic(如_atomic_add_fetch),指令内部实现与架构相关，如armv8.1则使用lxadd。


x86?

锁
==========

自旋锁、互斥量、信号量的实现原理。

semphore
--------------
1. `【原创】Linux信号量机制分析 - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/12907230.html>`__

按照等待链表排队。

::

   struct semaphore {
      raw_spinlock_t		lock;       //自旋锁，用于count值的互斥访问
      unsigned int		count;      //计数值，能同时允许访问的数量，也就是上文中的N把锁
      struct list_head	wait_list;      //不能立即获取到信号量的访问者，都会加入到等待列表中
   };

   struct semaphore_waiter {
      struct list_head list;      //用于添加到信号量的等待列表中
      struct task_struct *task;   //用于指向等待的进程，在实际实现中，指向current
      bool up;                    //用于标识是否已经释放
   };


.. figure:: /images/semaphore.png

   semaphore


ownership
~~~~~~~~~~~~~~
Mutex被持有后有一个明确的owner，而Semaphore并没有owner，当一个进程阻塞在某个信号量上时，它没法知道自己阻塞在哪个进程（线程）之上；

没有ownership会带来以下几个问题：

1. 在保护临界区的时候，无法进行 **优先级反转** 的处理；
2. 系统无法对其进行跟踪断言处理，比如 **死锁检测** 等；
3. 信号量的 **调试** 变得更加麻烦；


mutex
----------------
1. `【原创】Linux Mutex机制分析 - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/12826811.html>`__

互斥锁是一种 **休眠锁** ，锁争用时可能存在进程的睡眠与唤醒，context的切换带来的代价较高，适用于加锁时间较长的场景；

每次只允许一个进程进入临界区，有点类似于二值信号量；与信号量相比，互斥锁的性能与扩展性都更好，因此，在内核中总是会 **优先考虑互斥锁** ；

缺点是互斥锁对象的结构较大，会占用更多的CPU缓存和内存空间；

三条处理路径
~~~~~~~~~~~~~~~
1. 快速路径：__mutex_trylock_fast，若失败则进入mid-path。
2. 中速路径：osq,乐观自旋。若持有锁者正在临界区运行，则osq；若锁持有者在临界区被调度出去了，则进入slow-path.
3. 慢速路径：schedule_preempt_disabled，将当前任务切换出去。


osq加锁
~~~~~~~~~~~~
optimistic spinning，乐观自旋.可以极大的提高性能

有几种情况：

1. 无人持有锁，那是最理想的状态，直接返回；
2. 有人持有锁，将当前的Node加入到OSQ队列中，在没有高优先级任务抢占时， **自旋等待前驱节点释放锁** ；
3. 自旋等待过程中，如果遇到高优先级 **任务抢占** ，那么将之前加入到OSQ队列中的当前节点从OSQ队列中移除。

解锁：当于锁的传递，从osq队列上一个节点传递给下一个节点。


spinlock
-----------
1. `自旋锁 <http://www.wowotech.net/kernel_synchronization/460.html>`__ ;
2. `Linux 单/多处理器下的内核同步与实现---自旋锁 <https://zhuanlan.zhihu.com/p/115748853>`__


spinlock的核心思想是基于tickets的机制：

1. 每个锁的数据结构arch_spinlock_t中维护两个字段：next和owner，只有当next和owner(local保存next自加前的值)相等时才能获取锁；
2. 每个进程在获取锁的时候，next值会增加，当进程在释放锁的时候owner值会增加；
3. 如果有多个进程在争抢锁的时候，看起来就像是一个 **排队系统， FIFO ticket spinlock**；

rwlock
~~~~~~~~~~~
写者饿死

seqlock
~~~~~~~~~~

stadda与spinlock的实现
~~~~~~~~~~~~~~~~~~~~~~~~
1. `Arm A64 Instruction Set Architecture  <https://developer.arm.com/documentation/ddi0596/2021-12/Base-Instructions/STADD--STADDL--Atomic-add-on-word-or-doubleword-in-memory--without-return--an-alias-of-LDADD--LDADDA--LDADDAL--LDADDL-?lang=en>`__
2. `Linux Kernel中spinlock的设计与实现_代码改变世界ctw的博客-CSDN博客_spinlock的实现  <https://blog.csdn.net/weixin_42135087/article/details/120950133>`__
3. `【原创】linux spinlock/rwlock/seqlock原理剖析（基于ARM64） - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/12632532.html>`__


spinlock基于lse 硬件独占指令实现。包括stxt、stadda、eor、ldaxrh。

Atomic add on halfword in memory, without return, atomically loads a 16-bit halfword from memory, adds the value held in a register to it, and stores the result back to memory.

::

   static inline void arch_spin_lock(arch_spinlock_t *lock)
   {
   	unsigned int tmp;
   	arch_spinlock_t lockval, newval;
    
   	asm volatile(
   	/* Atomically increment the next ticket. */
   	ARM64_LSE_ATOMIC_INSN(
   	/* LL/SC */
   "	prfm	pstl1strm, %3\n"
   "1:	ldaxr	%w0, %3\n"
   "	add	%w1, %w0, %w5\n"
   "	stxr	%w2, %w1, %3\n"
   "	cbnz	%w2, 1b\n",
   	/* LSE atomics */
   "	mov	%w2, %w5\n"
   "	ldadda	%w2, %w0, %3\n"
   	__nops(3)
   	)
   	/* Did we get the lock? */
   "	eor	%w1, %w0, %w0, ror #16\n"
   "	cbz	%w1, 3f\n"
   	/*
   	 * No: spin on the owner. Send a local event to avoid missing an
   	 * unlock before the exclusive load.
   	 */
   "	sevl\n"
   "2:	wfe\n"
   "	ldaxrh	%w2, %4\n"
   "	eor	%w1, %w2, %w0, lsr #16\n"
   "	cbnz	%w1, 2b\n"
   	/* We got the lock. Critical section starts here. */
   "3:"
   	: "=&r" (lockval), "=&r" (newval), "=&r" (tmp), "+Q" (*lock)
   	: "Q" (lock->owner), "I" (1 << TICKET_SHIFT)
   	: "memory");
   }
    
   static inline void arch_spin_unlock(arch_spinlock_t *lock)
   {
   	unsigned long tmp;
    
   	asm volatile(ARM64_LSE_ATOMIC_INSN(
   	/* LL/SC */
   	"	ldrh	%w1, %0\n"
   	"	add	%w1, %w1, #1\n"
   	"	stlrh	%w1, %0",
   	/* LSE atomics */
   	"	mov	%w1, #1\n"
   	"	staddlh	%w1, %0\n"
   	__nops(1))
   	: "=Q" (lock->owner), "=&r" (tmp)
   	:
   	: "memory");
   }



rcu
-------
1. `【原创】Linux RCU原理剖析（一）-初窥门径 - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/12681494.html>`__
2. `Linux中的RCU机制[一] - 原理与使用方法 - 知乎  <https://zhuanlan.zhihu.com/p/89439043>`__
3. `【原创】Linux RCU原理剖析（一）-初窥门径 - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/12681494.html>`__

RCU的基本思想是：先创建一个旧数据的copy，然后writer更新这个copy，最后再用新的数据替换掉旧的数据。

RCU, Read-Copy-Update，是Linux内核中的一种同步机制。

RCU常被描述为读写锁的替代品，特点是 **读者并不需要直接与写者进行同步**，读写能并发的执行。最大程度来减少 ``读者`` 侧的开销.

.. figure:: /images/rcu.png


volatile与sequence point
----------------------------
1. `Why the “volatile” type class should not be used — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/process/volatile-considered-harmful.html>`__
2. `ARM Compiler toolchain Using the Compiler Version 4.1  <https://developer.arm.com/documentation/dui0472/c/compiler-coding-practices/compiler-optimization-and-the-volatile-keyword>`__
3. `Volatiles (Using the GNU Compiler Collection (GCC))  <https://gcc.gnu.org/onlinedocs/gcc/Volatiles.html>`__


volatile 3种使用场景：(在当前线程之外被改变的变量。一些场景可以用同步原语替代——spinlock、mutex、memory barriers etc.)

1. accessing memory mapped peripherals
2. sharing global variables between multiple threads
3. accessing global variables in an interrupt routine or signal handler.

sequence point: 两个seq point之间只允许对同一个变量改变一次。

volatile memory
~~~~~~~~~~~~~~~~~~~~
1. `Extended Asm (Using the GNU Compiler Collection (GCC))  <https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html>`__
2. `c - The difference between asm, asm volatile and clobbering memory - Stack Overflow  <https://stackoverflow.com/questions/14449141/the-difference-between-asm-asm-volatile-and-clobbering-memory>`__

编译器级别的内存屏障。

asm volatile("" ::: "memory"); 


可重入、异步信号安全、多线程安全
================================
为了解决两个问题：多线程并发和信号中断。

可重入函数
-------------
被多线程调用时，不会引用任何共享数据。

1. 135个，apue figure 10.4；
2. 后缀_r的函数或对应的替代函数，SUSv3；
3. 自己实现。

异步信号安全函数
~~~~~~~~~~~~~~~~
函数可重入或无法被信号处理函数中断。

实际上与apue的可重入列表一致，tlpi 21.1.2。

仅当非信号安全函数被信号处理函数中断，并且在信号处理函数中调用该非信号安全函数时才是不安全的。

1. 确保信号处理函数代码可重入，且只调用信号安全函数；
2. 主程序调用不安全函数或操作信号处理函数可能更新的共享变量时，阻塞信号传递。



.. figure:: /images/SignalHandler.png

   信号处理器



线程安全函数
------------------
被多个并发线程反复调用时，一直产生正确的结果。

大部分linux函数都是线程安全的，只有少部分不安全(见apue figure 12.9、tlpi 31.1、csapp figure 12-41.)

线程不安全函数：

1. 不保护共享变量；
2. 保持跨越多个调用的状态的函数。只能重新实现，如rand；
3. 返回指向静态变量的指针的函数。大部分属于此类，可用加锁-复制来实现线程安全版本；
4. 调用线程不安全函数的函数（可能导致不安全）。
   若调用2中的函数，则必定不安全，若调用1、3则可使用互斥锁保护以实现线程安全。


线程安全函数包括：

1. 可重入函数；
2. 对临界区进行保护(解决的是并发问题)；