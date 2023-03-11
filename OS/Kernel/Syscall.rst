

系统调用
=============
1. `the-definitive-guide-to-linux-system-calls  <https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/>`__
`系统调用权威指南 <https://arthurchiao.art/blog/system-call-definitive-guide-zh>`__
系统学习，有源码分析

2. `深入理解系统调用 <https://www.cnblogs.com/liujianing0421/p/12971722.html>`__

3. `调用门 - 硬件原理 <https://mp.weixin.qq.com/s/8BtdBNTW36BUxb5Ee-jKSw>`__
4. `Linux syscall过程 —— 栈切换等 <https://cloud.tencent.com/developer/article/1492374>`__

概念
------
在Linux中，系统调用是用户空间访问内核的唯一手段。

系统调用在用户空间进程和硬件设备之间添加了一个中间层，作用：

1. 为用户空间提供硬件抽象接口；
2. 保证系统的稳定与安全。内核基于权限、用户和其它规则对访问进行裁决；
3. 为运行在虚拟系统中的进程提供公共接口（？）。

应用程序编程接口API；在用户空间实现，应用程序使用其来编程。不需要和系统调用对应。

POSIX：提供一套大体基于UNIX的操可移植作系统标准。

C库：Linux系统调用像其它大多数UNIX系统一样，作为C库的一部分提供。C库提供了POSIX的大部分API。

UNIX接口设计：提供机制（功能定义）而不是策略（如何实现）。

eax：存放系统调用号、返回值。


系统调用的实现
--------------

系统调用列表：在sys_call_table中，空sys_ni_syscall()仅返回-ENOSYS。

系统调用设计：力求简洁，参数尽可能少；向前向后兼容性；可移植性。

参数验证：系统调用必须仔细检查参数是否合法。


syscall
~~~~~~~~~~~
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


系统调用上下文
~~~~~~~~~~~~~~
内核在执行系统调用时处于进程上下文。

在进程上下文中内核可以休眠（系统调用阻塞、显示调用schedule）并且可以被抢占。

- 可休眠说明系统调用可以使用内核提供的大部分功能（而不可休眠的中断在编程时会受到极大限制）；
- 可抢占可需要保证系统调用是可重入。

注册和使用
~~~~~~~~~~
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
1. `The Definitive Guide to Linux System Calls | Packagecloud Blog  <https://blog.packagecloud.io/the-definitive-guide-to-linux-system-calls/>`__

Due to ASLR `address space layout randomization <https://en.wikipedia.org/wiki/Address_space_layout_randomization>`__
the vDSO will be loaded at a random address when a program is started.

每次运行都会有不同的地址。程序代码、库代码、栈、全局变量和堆数据。
