============
GDB
============

:Date:   2021-07-20 00:52:25

基本使用
===============
参考文档
-----------
1. https://sourceware.org/gdb/onlinedocs/gdb/ 
2. `100个gdb小技巧 <https://wizardforcel.gitbooks.io/100-gdb-tips>`__
3. `GDB调试入门指南 <https://zhuanlan.zhihu.com/p/74897601>`__
4. `GDB中应该知道的几个调试方法 | 酷 壳 - CoolShell  <https://coolshell.cn/articles/3643.html>`__
5. :download:`gdb_slides </files/gdb_slides.pdf>`
6. `GDB配置与.gdbinit的编写 <https://blog.csdn.net/hexrain/article/details/12429267>`__

基本命令
----------
::
        
   1. .gdbinit：      GDB配置，如指定符号文件、加载peda/pwndgb插件;

   2. 单行调试：      step(step into called func)和next(step over);

   3. 单指令调试：    stepi/si和nexti/ni; 
   
   4. 函数退出：     finish执行完当前函数并返回上一级，return跳过当前函数后续命令并返回上一级；

   5. 运行：         run(开始运行)、continue(运行到断点或Ctrl+C)、advance <location>(运行到指定地址);

   6. 断点：         break <location>(地址、函数名、文件行号). delete/disable/enable <num>; tbreak临时断点;

   7. 条件断点：     break <location> if <condition>、cond <number> <condition> ,如 b func if var == 1;

   8. 数据断点：     watchpoints。watch <expression>和watch -l <address> (value was changed)、
                                 rwatch [-l] <expression>( value was read);

   9. x打印：        x格式化打印，x/10xw——十六进制内容、x/10i——指令;

   10. p打印：        print。p /x addr，也可用于调用函数 

   11. list打印：    list <location>/func,按行打印源码; 
   
   12. 指定源码：    directory

   13. info打印：    info registers/frame/break/sharedlibrary —— 寄存器、栈帧、断电、共享库


   14. 反汇编:   disassemble func
   
   15. 符号文件更换： symbol-file obj/kern/kernel

   16. layout：      显示调试窗口
   
   17. 变量:       $a 定义gdb变量；set可更改程序变量和gdb变量
   
   18. 参数:       set args命令、-args参数

   19. 一直显示下一行源码对应的汇编: set disassemble-next-line on
   20. 返回值打桩:      进入函数后，return <val>

x命令
--------
::

    x/i  反汇编 – 通常，我们会使用 x/10i $ip-20 来查看当前的汇编（$ip是指令寄存器）
    x/x 以十六进制输出
    x/d 以十进制输出
    x/c 以单字符输出
    x/s 以字符串输出


栈帧
------
::
        
    1. bt/backtrace -full n:  显示n层调用链并打印局部变量

    2. info frame/f [n] :       显示栈信息，当前栈编号为0

    3. up/down :              向上向下 切换栈

    4. f n/addr :              切换到指定栈

    5. info args/locals :      当前栈帧

    6. info variables/functions : 当前程序


多线程调试
--------------

1. `GDB调试多线程及多进程  <https://ivanzz1001.github.io/records/post/cplusplus/2018/08/19/cpluscplus-gdbusage_part2>`__
2. https://cvvz.github.io/post/gdb-muti-process-and-signal-handle/

::

   1. info thread
   
   2. thread id ：切换
   
   3. break file.c:100 thread all  在file.c文件第100行处为所有经过这里的线程设置断点。
   
   4. set scheduler-locking off/on/step。all-stop模式中有效，只让被调试线程执行。原本在使用step或者continue命令调试当前被调试线程的时候，其他线程也是同时执行的。
      off 不锁定任何线程，也就是所有线程都执行，这是默认值。
      on 只有当前被调试程序会执行。
      step 在单步的时候，除了next过一个函数的情况(next其实是一个设置断点然后continue的行为)以外，只有当前线程会执行。

执行模式
~~~~~~~~~

1. All-Stop:任何一个线程在断点处hang住时，所有其他线程也会hang住。默认为all-stop模式。


2. Non-Stop:任何一个线程被stop甚至单步调试时，其他线程可以自由运行。continue/intterupt作用于当前线程: 加-a 作用域所有线程。


信号处理
------------
GDB能够检测到程序中产生的信号，并进行针对性的处理。通过info handle查看对所有信号的处理方式：

1. Stop：检测到信号是否停住程序的运行；
2. Print：是否打印收到该信号的信息；
3. Pass to program：是否把该信号传给进程处理（或者说是否屏蔽该信号，无法屏蔽SIGKILL和SIGSTOP信号）

通过handle SIG来指定某个信号的处理方式。


record历史
----------
::

   1. record
   
   2. rn/reverse-next :回退上一步
   
   3. rs
   
   4. record save/restore




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

断点
=========
数据断点watch
---------------------
::

   1. watch var/addr：可观察局部变量(作用域内)
   
   watch <expression>
   watch -l <address> (value was changed)、
   rwatch [-l] <expression>( value was read);


硬件断点
~~~~~~~~~
GDB always uses hardware-assisted watchpoints if they are available, and falls back on software watchpoints otherwise. 

1. 硬件断点：hardware-assisted
2. 软件断点：软件单步执行，效率很低。

不支持硬件断点时才会使用软件断点，场景包括：

1. watch的内存太大，如x86大于4B；
2. watchpoints数量超限；
3. 硬件不支持watchpoint;
4. 非memory值(如寄存器值)。

踩内存问题
~~~~~~~~~~~~
1. `如何利用硬件watchpoint定位踩内存问题 - 腾讯云开发者社区-腾讯云  <https://cloud.tencent.com/developer/article/1578336>`__

常用手段：

1. gdb内存断点。不适用于非固定内存、启动阶段等。
2. mmu保护。最小单位为4K。
3. 通过dump现场周边内存，分析数据特征。
4. 硬件watchpoint功能。
5. Address sanitizer等linux内存工具。

条件断点break
---------------
::
      
   break <location>(地址、函数名、文件行号). delete/disable/enable <num>; tbreak临时断点;
   break <location> if <condition>、cond <number> <condition> ,如 b func if var == 1;

  


辅助调试工具
============
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


coredump
-----------
1. `coredump配置、产生、分析以及分析示例 - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/11160510.html>`__
2. `调试器GDB的基本使用方法 - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/9633254.html#core_gdb>`__


保存了问题现场。可回溯堆栈等。 ``gdb ./main ./core`` 即可回到现场。

配置
~~~~~~

* 打开coredump: ``ulimit -c 81960``。
* coredump文件默认存储位置与可执行文件在同一目录下，文件名为core。

可以通过/proc/sys/kernel/core_pattern进行设置。

::
       
   %p  出Core进程的PID
   %u  出Core进程的UID
   %s  造成Core的signal号
   %t  出Core的时间，从1970-01-0100:00:00开始的秒数
   %e  出Core进程对应的可执行文件名

   $ cat /proc/sys/kernel/core_pattern
   |/usr/share/apport/apport %p %s %c %d %P %E


编译选项
-------------
1. -g: os native format，兼容性。
2. -ggdb: -ggdb2。gdb专用debug信息。
3. -ggdb3: 更多debug信息，包括宏。


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
