============
GDB
============

:Date:   2021-07-20 00:52:25

基本使用
===============
参考文档
-----------
1. `100个gdb小技巧 <https://wizardforcel.gitbooks.io/100-gdb-tips>`__
2. https://sourceware.org/gdb/onlinedocs/gdb/ 
3. `GDB调试入门指南 <https://zhuanlan.zhihu.com/p/74897601>`__
4. :download:`gdb_slides <../files/gdb_slides.pdf>`
5. `GDB配置与.gdbinit的编写 <https://blog.csdn.net/hexrain/article/details/12429267>`__

基本命令
----------
::
        
   1. .gdbinit：      GDB配置，如指定符号文件、加载peda/pwndgb插件;

   2. 单行调试：      step(step into called func)和next(step over);

   3. 单指令调试：    stepi/si和nexti/ni; 
   
   4. 函数退出：     finish执行完当前函数并返回上一级，return跳过当前函数后续命令并返回上一级；

   5. 运行：         run(开始运行)、continue(运行到断点或Ctrl+C)、advance <location>(运行到指定地址);


   6. 断点：         break <location>(地址、函数名、文件行号)，delete, disable, enable;

   7. 条件断点：     break <location> if <condition>、cond <number> <condition> ,如 b func if var == 1;

   8. 数据断点：     watchpoints。watch <expression>和watch -l <address> (value was changed)、
                                 rwatch [-l] <expression>( value was read);

   9. x打印：        x格式化打印，x/10xw——十六进制内容、x/10i——指令;

   10. p打印：        print。以c语句形式打印;

   11. list打印：    list <location>,按行打印源码;

   12. info打印：    info registers/frame/break/sharedlibrary —— 寄存器、栈帧、断电、共享库


   13. 反汇编:   disassemble func
   
   14. 符号文件更换： symbol-file obj/kern/kernel

   15. layout：      显示调试窗口

   16. 一直显示下一行源码对应的汇编: set disassemble-next-line on


栈帧
------
::
        
    1. bt/backtrace -full n:  显示n层调用链并打印局部变量

    2. info frame/f n :       显示栈信息，当前栈编号为0

    3. up/down :              向上向下 切换栈

    4. info args/locals :      当前栈帧

    5. info variables/functions : 当前程序

dump栈内存
----------
运行程序并使用i frame等命令确定目标栈地址范围，然后dump到文件，使用vim-xxd查看，文件中的地址从0开始。

``dump memory ./stack.dump 0x7ffffff000 0x8000000000``

dump memory -- Write contents of memory to a raw binary file



xxd命令
~~~~~~~~~~
``xxd -g 8 -e``

::
       
   option	meaning
   -c N	每行显示的字节数，默认是16
   -g N	将每行的字节数据打包成 N 个字节的 8位元组，默认是2
   -e   以小端little-endian显示
   -ps	输出连续的字节串
   -l N	只显示前 N 个字节的数据
   -s N / -s -N	跳过前 N 个字节的数据，之后开始显示，-N 则表示只显示文件末尾的 N 个数据

可视化
----------
layout使用
~~~~~~~~~~~~
::

   layout：用于分割窗口，可以一边查看代码，一边测试。主要有以下几种用法：
   layout src：显示源代码窗口
   layout asm：显示汇编窗口
   layout regs：显示源代码/汇编和寄存器窗口
   layout split：显示源代码和汇编窗口
   layout next：显示下一个layout
   layout prev：显示上一个layout
   Ctrl + L：刷新窗口
   Ctrl + x，再按1：单窗口模式，显示一个窗口
   Ctrl + x，再按2：双窗口模式，显示两个窗口

   Ctrl + x，再按a：回到传统模式，即退出layout，回到执行layout之前的调试窗口。

tui
-------

pwndbg和peda
-------------

GDB原理
========
1. `GDB底层实现原理 <https://mp.weixin.qq.com/s/y3c07Hk7g3P-rd0oDzszlA>`__
2. `一文带你看透 GDB 的 实现原理  <https://blog.csdn.net/Z_Stand/article/details/108395906>`__
3. `一窥GDB原理 <https://bbs.pediy.com/thread-265599.htm>`__


> Todo: ptrace实现一个tracer

ptrace系统调用
---------------
进程(gdb)可以读写另外一个进程(test)的指令空间、数据空间、堆栈和寄存器的值。

https://man7.org/linux/man-pages/man2/ptrace.2.html

`long ptrace(enum __ptrace_request request,  pid_t pid, void *addr,  void *data);`


1. request：指定调试的指令，指令的类型很多，如：PTRACE_TRACEME、PTRACE_PEEKUSER、PTRACE_CONT、PTRACE_GETREGS等等

   - PTRACE_TRACEME表示被追踪进程调用，让父进程来追踪自己。通常是gdb调试新进程时使用。
   - PTRACE_ATTACH父进程attach到正在运行的子进程上，这种追踪方式会检查权限，普通用户无法追踪root用户下的进程

2. pid：进程的ID（这个不用解释了）。
3. addr：进程的某个地址空间，可以通过这个参数对进程的某个地址进行读或写操作。addr参数值是从哪里获取到的（来源于elf?）？这个值是tracee的虚地址，这需要提前获取到tracee的地址空间？
4. data：根据不同的指令，有不同的用途，下面会介绍。

单步调试模式（PTRACE_SINGLESTEP）
------------------------------------
1. 当把 eflags 寄存器的 Trap Flag 设置为1后，CPU 每执行一条指令便会产生一个异常，然后会触发 Linux 的异常处理，Linux 便会发送一个 SIGTRAP 信号给被调试的进程。
2. 被调试进程处理 SIGTRAP 信号时会发送一个 SIGCHLD 信号给父进程（调试进程），并且让自己停止执行。
3. 父进程（调试进程）接收到 SIGCHLD 后，就可以对被调试的进程进行各种操作，比如读取被调试进程内存的数据和寄存器的数据，或者通过调用 ptrace(PTRACE_CONT, child,...) 来让被调试进程进行运行等。

被调试进程处理SIGTRAP
------------------------
1. ptrace() 对 PTRACE_TRACEME 的处理就是把当前进程标志为 PTRACE 状态。
2. 被调试进程处理 SIGTRAP 信号时( do_signal),如果当前进程被标记为 PTRACE 状态，那么就
   
   1. 使自己进入停止运行状态。
   2. 发送 SIGCHLD 信号给父进程。
   3. 让出 CPU 的执行权限，使 CPU 执行其他进程。


断点原理int 3
-------------------

1. 读取addr处的指令的位置，存入GDB维护的断点链表中。

2. 将中断指令 INT 3 （0xCC）打入原本的addr处。也就是将addr处的指令掉换成INT 3
 
3. 当执行到addr处（INT 3）时，CPU执行这条指令的过程也就是发生断点异常（breakpoint exception），tracee产生一个SIGTRAP，
   此时我们处于attach模式下，tracee的SIGTRAP会被tracer（GDB）捕捉。
   然后GDB去他维护的断点链表中查找对应的位置，如果找到了，说明hit到了breakpoint。
 
4. 接下来，如果我们想要tracee继续正常运行，GDB将INT 3指令换回原来正常的指令，回退重新运行正常指令，然后接着运行。

调试stripped程序
-----------------------
1. `Native Debugging Part 1 <https://www.humprog.org/~stephen//blog/2016/02/25/#native-debugging-part-1>`__
2. `Native Debugging Part 2 <https://www.humprog.org/~stephen//blog/2017/01/30/#native-debugging-part-2>`__
3. `stripped-binaries-in-gdb <https://tr0id.medium.com/working-with-stripped-binaries-in-gdb-cacacd7d5a33>`__

The __libc_start_main() function shall initialize the process, call the main function with appropriate arguments, and handle the return from main().
__libc_start_main() is not in the source standard; it is only in the binary standard.

方法：

1. info file 找到 Entry point ，并运行到该处；
2. 找到 __libc_start_main (libc.so.6)，其入参即为 main 地址，断点该地址；
3. 如何找到特定函数地址？