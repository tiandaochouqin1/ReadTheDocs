
====================
Concurrency 
====================

:Date:   2021-07-31 13:37:13

并发编程
===========
1. 并发:系统支持两个或多个动作同时存在,不一定要同时执行。可以是多线程或单线程。
2. 并行:系统支持两个或多个动作同时执行。


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

CAS实现
-------

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

x8664汇编
~~~~~~~~~

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

arm64汇编
~~~~~~~~~

LDXR (load exclusive register 和STXR （store exclusive
register）及其变种指令。

`ARMv8
架构与指令集.学习笔记 <https://www.cnblogs.com/lvdongjie/p/6644821.html>`__

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

stlxr失败后重试。

ABA问题
~~~~~~~

1. 进程P1在共享变量中读到值为A
2. P1被抢占了，进程P2执行
3. P2把共享变量里的值从A改成了B，再改回到A，此时被P1抢占。
4. P1回来看到共享变量里的值没有被改变，于是继续执行。

使用double-CAS解决。

ARM内存屏障
-----------

由于一些编译器优化或者CPU设计的流水线乱序执行，导致最终内存的访问顺序可能和代码中的逻辑顺序不符，所以需要增加内存屏障指令来保证顺序性。
ARM平台上存在三种内存屏障指令：

1. DMB{cond} {option}
   这种指令只影响到了内存访问指令的顺序，保证在此指令前的内存访问完成后才执行后面的内存访问指令。
2. DSB{cond} {option}
   比DMB更加严格，保证在此指令前的内存访问指令/cache/TLB/分支预测指令都完成，然后才会执行后面的所有指令。
3. ISB{cond} {option}
   最为严格的一种，冲洗流水线和预取buffer，然后才会从cache或者内存中预取ISB后面的指令。

option的选择：

1. SY：完整的指令操作
2. ST：只等待store操作完成，就继续执行
3. ISH：该操作只针对inner shareable domain生效
4. ISHST：ISH+ST
5. NSH:该操作只针对outer to unification生效
6. NSHST：NSH+ST
7. OSH：该操作只针对outer shareable domain生效
8. OSHST：OSH+ST

内核实现

::

   #define dsb(option) __asm__ __volatile__ ("dsb " #option : : : "memory")
   #define dmb(option) __asm__ __volatile__ ("dmb " #option : : : "memory")


   #define mb()        do { dsb(); outer_sync(); } while (0)
   #define rmb()       dsb()
   #define wmb()       do { dsb(st); outer_sync(); } while (0)
   #define smp_mb()    dmb(ish)
   #define smp_rmb()   smp_mb()
   #define smp_wmb()   dmb(ishst)

由上面的宏定义可知，对于指令限制的严格程度：

::

   mb()>rmb()>wmb()>smb_mb()=smb_rmb()>smb_wmb()

smp相关的内存屏障都加入了ish选项，也就是限制指令只针对inner shareable
domain。

锁
==========

自旋锁、互斥量、信号量的实现原理。

`自旋锁 <http://www.wowotech.net/kernel_synchronization/460.html>`__ ;
`Linux 单/多处理器下的内核同步与实现---自旋锁 <https://zhuanlan.zhihu.com/p/115748853>`__
