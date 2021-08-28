=====================
6.828 & xv6
=====================


:Date:   2021-07-20 00:52:25

简介
=========

xv6是由麻省理工学院(MIT)开发的一个教学目的的操作系统，它是在x86处理器上用ANSI标准C重新实现的Unix第六版(即v6)，
课程编号为6.828。2019年被移植到RISC-V之上，并设置了6.S081。

xv6的主要特征：

1) 开源，精简，代码仅两万行左右；

2) 功能完善，可全面理解操作系统的原理及实现；

3) 基于RISC-V、X86等架构，有利于深入理解体系结构；

4) 类Unix系统，可延伸学习其他常见操作系统，例如Linux、MacOS等。


参考链接
---------------

1. `6.828:Perating System Engineering - 2018 <https://pdos.csail.mit.edu/6.828/2018/schedule.html>`__
2. `6.S081 (Introduction to Operating Systems) <https://pdos.csail.mit.edu/6.828/2020/index.html>`__ 
   will be taught as a stand-alone AUS subject for undergraduates. 
   6.828 will be offered as a graduate-level seminar-style class focused on research in operating systems. 

3. `xv6 book <ttps://pdos.csail.mit.edu/6.828/2018/xv6/book-rev10.pdf>`__ 阅读xv6源码过程中最好的参考资料。
4. `MIT 6.828 实现操作系统--知乎 <https://zhuanlan.zhihu.com/c_1273723917820215296>`__ ，案例参考。
5. `MIT 6.828 JOS 操作系统学习笔记--cnblogs <https://www.cnblogs.com/fatsheep9146/category/769143.html>`__

GDB
============
1. `100个gdb小技巧 <https://wizardforcel.gitbooks.io/100-gdb-tips>`__
2. https://sourceware.org/gdb/onlinedocs/gdb/ 



基本使用
---------------
1. .gdbinit：`GDB配置与.gdbinit的编写 <https://blog.csdn.net/hexrain/article/details/12429267>`__，如指定符号文件;

2. 单行调试： step(step into called func)和next(step over);

3. 单指令调试：stepi和nexti;

4. 运行：continue(运行到断点或Ctrl+C)、finish(运行到当前函数返回)、advance <location>(运行到指定地址);

5. 断点：break <location>(地址、函数名、文件行号)，delete, disable, enable;

6. 条件断点：break <location> if <condition>、cond <number> <condition>;

7. 数据断点(watchpoints)：watch <expression>和watch -l <address> (value was changed)、rwatch [-l] <expression>( value was read);

8. 打印：x(格式化打印，如x/x、x/i)、p(以c语句形式打印)、list <location>(打印func源码);

9. info： info registers/frame/break;

10. 符号文件更换：symbol-file obj/kern/kernel

11. layout：显示调试窗口

gdb调试的layout使用：

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


GDB原理
-----------
1. `GDB底层实现原理 <https://mp.weixin.qq.com/s/y3c07Hk7g3P-rd0oDzszlA>`__
2. `一文带你看透 GDB 的 实现原理 -- ptrace真香 <https://blog.csdn.net/Z_Stand/article/details/108395906>`__
3. `一窥GDB原理 <https://bbs.pediy.com/thread-265599.htm>`__


> Todo: ptrace实现一个tracer

ptrace系统调用
~~~~~~~~~~~~~~~~
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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1. 当把 eflags 寄存器的 Trap Flag 设置为1后，CPU 每执行一条指令便会产生一个异常，然后会触发 Linux 的异常处理，Linux 便会发送一个 SIGTRAP 信号给被调试的进程。
2. 被调试进程处理 SIGTRAP 信号时会发送一个 SIGCHLD 信号给父进程（调试进程），并且让自己停止执行。
3. 父进程（调试进程）接收到 SIGCHLD 后，就可以对被调试的进程进行各种操作，比如读取被调试进程内存的数据和寄存器的数据，或者通过调用 ptrace(PTRACE_CONT, child,...) 来让被调试进程进行运行等。

被调试进程处理SIGTRAP
~~~~~~~~~~~~~~~~~~~~~
1. ptrace() 对 PTRACE_TRACEME 的处理就是把当前进程标志为 PTRACE 状态。
2. 被调试进程处理 SIGTRAP 信号时( do_signal),如果当前进程被标记为 PTRACE 状态，那么就
   
   1. 使自己进入停止运行状态。
   2. 发送 SIGCHLD 信号给父进程。
   3. 让出 CPU 的执行权限，使 CPU 执行其他进程。


断点原理int 3
~~~~~~~~~~~~~

1. 读取addr处的指令的位置，存入GDB维护的断点链表中。

2. 将中断指令 INT 3 （0xCC）打入原本的addr处。也就是将addr处的指令掉换成INT 3
 
3. 当执行到addr处（INT 3）时，CPU执行这条指令的过程也就是发生断点异常（breakpoint exception），tracee产生一个SIGTRAP，
   此时我们处于attach模式下，tracee的SIGTRAP会被tracer（GDB）捕捉。
   然后GDB去他维护的断点链表中查找对应的位置，如果找到了，说明hit到了breakpoint。
 
4. 接下来，如果我们想要tracee继续正常运行，GDB将INT 3指令换回原来正常的指令，回退重新运行正常指令，然后接着运行。

调试stripped程序
------------------
1. `Native Debugging Part 1 <https://www.humprog.org/~stephen//blog/2016/02/25/#native-debugging-part-1>`__
2. `Native Debugging Part 2 <https://www.humprog.org/~stephen//blog/2017/01/30/#native-debugging-part-2>`__
3. `stripped-binaries-in-gdb <https://tr0id.medium.com/working-with-stripped-binaries-in-gdb-cacacd7d5a33>`__

The __libc_start_main() function shall initialize the process, call the main function with appropriate arguments, and handle the return from main().
__libc_start_main() is not in the source standard; it is only in the binary standard.

方法：

1. info file 找到 Entry point ，并运行到该处；
2. 找到 __libc_start_main (libc.so.6)，其入参即为 main 地址，断点该地址；
3. 如何找到特定函数地址？


LAB1
===========
:download:`xv6 code-lab1 <../files/xv6.zip>`
   
1. `80386 Programmer's Reference Manual <https://pdos.csail.mit.edu/6.828/2018/readings/i386/toc.htm>`__
2. PC Assembly Language 


Part 1: PC Bootstrap
-------------------------
准备好代码和环境。此处使用ubuntu 18 x86_64(需要安装gcc-multilib以支持32位) 。

::

   实验代码：
   git clone https://pdos.csail.mit.edu/6.828/2018/jos.git lab
   make // 编译obj/kern/kernel.img（boot+kernel）

   qemu编译
   git clone https://github.com/mit-pdos/6.828-qemu.git qemu
   installing the following packages: libsdl1.2-dev, libtool-bin, libglib2.0-dev, libz-dev, and libpixman-1-dev
   ./configure --disable-kvm --disable-werror [--prefix=PFX] [--target-list="i386-softmmu x86_64-softmmu"]
   make && make install

   调试
   make qemu-nox-gdb/qemu-gdb  //使用obj/kern/kernel.img启动
   make gdb  //同一目录启动gdb





PA Layout
~~~~~~~~~~~~~
16位实模式地址访问： CS:IP，20位地址线。

physical address = 16 * segment（CS） + offset(IP)


::

   +------------------+  <- 0xFFFFFFFF (4GB)
   |      32-bit      |
   |  memory mapped   |
   |     devices      |
   |                  |
   /\/\/\/\/\/\/\/\/\/\

   /\/\/\/\/\/\/\/\/\/\
   |                  |
   |      Unused      |
   |                  |
   +------------------+  <- depends on amount of RAM
   |                  |
   |                  |
   | Extended Memory  |
   |                  |
   |                  |
   +------------------+  <- 0x00100000 (1MB)
   |     BIOS ROM     |
   +------------------+  <- 0x000F0000 (960KB)
   |  16-bit devices, |
   |  expansion ROMs  |
   +------------------+  <- 0x000C0000 (768KB)
   |   VGA Display    |
   +------------------+  <- 0x000A0000 (640KB)
   |                  |
   |    Low Memory    |
   |                  |
   +------------------+  <- 0x00000000




Part 2: The Boot Loader
-------------------------------
1. 阅读并理解源码oot/boot.S and  boot/main.c ；
2. 阅读obj/boot/boot.asm ， 

跟踪调试： boot.S(0x7c00) -> main.c(bootmain) -> readsect

`boot代码解析 <https://www.cnblogs.com/fatsheep9146/p/5115086.html>`__

boot流程
~~~~~~~~~~~
boot.S->main.c :

关键寄存器清零->使能A20地址线->加载gdt表->使能保护模式->配置相关寄存器->创建stack->call bootmain
->readseg->readsect

此处bootloader(对应内容为boot.S和main.c)保存在disk第一个扇区，elf格式的kernel image的起始位置为第二扇区。

1. cpu启动时加载BIOS到内存并执行；
2. BIOS初始化设备、中断线，加载boot到内存并jump到boot；
3. boot加载内核镜像的所有段到内存（位置为段指定的地址），并移交控制权给kernel。

Part 3: The Kernel
-------------------------------
关键lab内容：

1. 虚实地址的切换。进入内核后切换（entry  f010000c (virt)  0010000c (phys)）
2. vprintfmt + putch 原理，补充vprintfmt 8进制格式化代码。
3. 内核栈的初始化；利用eip回溯调用栈；结合asm和gdb分析test_backtrace每一层使用的栈空间（0x20）。

参考

1. `stabs调试信息 <https://sourceware.org/gdb/onlinedocs/stabs.html#Overview>`__
2. `journey-to-the-stack <https://manybutfinite.com/post/journey-to-the-stack/>`__
3. `exercise12_print_more_info <https://www.cnblogs.com/wuhualong/p/lab01_exercise12_print_more_info.html>`__
4. `glibc的backtrace实现 <https://elixir.bootlin.com/glibc/glibc-2.24/source/debug/backtrace.c#L89>`__

cprintf
~~~~~~~~~~
cprintf -> vcprintf -> putch + vprintfmt

1. vprintfmt: Main function to format and print a string.
2. putch: 输出字符，如下:

::

   // `High'-level console I/O.  Used by readline and cprintf.
   void
   cputchar(int c)
   {
      cons_putc(c);
   }

   // output a character to the console
   static void
   cons_putc(int c)
   {
      serial_putc(c);  //串口
      lpt_putc(c);     //并口
      cga_putc(c);     //显示屏
   }

   ...
   cga_putc
   1. 打印属性处理，如颜色；
   2. 特殊字符处理，如`\b \r \n \t`;
   3. 记录字符到缓冲区；
   4. 屏幕内容上下移动；
   5. outb输出缓冲区内容：
   /* move that little blinky thing */
   outb(addr_6845, 14);
   outb(addr_6845 + 1, crt_pos >> 8);
   outb(addr_6845, 15);
   outb(addr_6845 + 1, crt_pos);


内核栈初始化
~~~~~~~~~~~~~~
`Exercise 1.9 <https://www.cnblogs.com/fatsheep9146/p/5079177.html>`__

1. 通过cr0/cr3寄存器加载页表，进入具有分页机制的模式(加载之后，直接jump到对应虚地址即可)；
2. 然后初始化ebp、esp:

::

      movl    $0x0,%ebp            # nuke frame pointer
      movl    $(bootstacktop),%esp  # 0xf0110000 ,KSTKSIZE = 8 * PGSIZE = 32KB
      call    i386_init


basic backtrace
~~~~~~~~~~~~~~

::

   int* ebp;
   asm volatile("movl %%ebp,%0" : "=r" (ebp));   //汇编获取当前ebp
   ...
   ebp = (int*)*(ebp);      //获取上一层的ebp
   ....
   debuginfo_eip(ebp[1], &dbg_info); //ebp[1]即eip地址,查找更多debug信息



ebp(frame pointer,caller func的栈基址)与eip(Instruction Pointer Register,被保存为callee func返回地址）相邻：

::

   (FP is the frame pointer register——ebp):

         +-----------------+     +-----------------+
   FP -> | previous FP --------> | previous FP ------>...
         |                 |     |                 |
         | return address  |     | return address  |
         +-----------------+     +-----------------+



1. `gcc内建函数 <https://gcc.gnu.org/onlinedocs/gcc/Return-Address.html>`__ ,
   如 `void * __builtin_return_address (unsigned int level)` 、 `void * __builtin_frame_address (unsigned int level)`

backtrace more
~~~~~~~~~~~~~~~~~~~~
上文已经可根据ebp获得eip。


1. ld脚本中可将包含debug info的 section的起始、结束位置声明为全局变量，在代码中可直接使用，用于根据指令地址在section范围内查找debug信息；
2. 使用指令地址 (\*eip) 查找该指令的debug（stabs）信息， func -> line -> file(因为inline？所以放在最后)。


STABS 
~~~~~~~~~~
gcc -g生成的XCOFF有stab和stabstr段表.

STABS (Symbol TABle Strings) .

1.  .stab : contains an array of fixed length structures, one struct per stab
2. .stabstr : all the variable length strings that are referenced by stabs in the .stab section.

stabstr符号表内容如下：

1. Symnum是符号索引，即整个符号表看作一个数组，Symnum是当前符号在数组中的下标
2. n_type是符号类型，FUN指函数名，SLINE指在text段中的行号
3. n_othr目前没被使用，其值固定为0
3. n_desc表示在文件中的行号
4. n_value表示地址。只有FUN类型的符号的地址是绝对地址，SLINE符号的地址是偏移量，其实际地址为函数入口地址加上偏移量。
   比如第3行的含义是地址f01000b8(=0xf01000a6+0x00000012)对应文件第34行。

::

      $ objdump -G obj/kern/kernel

      obj/kern/kernel:     file format elf32-i386

      Contents of .stab section:
      
      Symnum n_type n_othr n_desc n_value  n_strx String
      
      -1     HdrSym 0      1300   0000198d 1
      0      SO     0      0      f0100000 1      {standard input}
      1      SOL    0      0      f010000c 18     kern/entry.S
      2      SLINE  0      44     f010000c 0
    ....

      12     SLINE  0      80     f0100039 0
      13     SLINE  0      83     f010003e 0
      14     SO     0      2      f0100040 31     kern/entrypgdir.c
      15     OPT    0      0      00000000 49     gcc2_compiled.
      16     LSYM   0      0      00000000 64     int:t(0,1)=r(0,1);-2147483648;2147483647;
      17     LSYM   0      0      00000000 106    char:t(0,2)=r(0,2);0;127;
      18     LSYM   0      0      00000000 132    long int:t(0,3)=r(0,3);-2147483648;2147483647;
      19     LSYM   0      0      00000000 179    unsigned int:t(0,4)=r(0,4);0;4294967295;
      
LAB2
===========
shell
------------
`6.828 操作系统 Homework: Shell <https://www.jianshu.com/p/64385b80210b>`__


实现了三种类型的命令：

1. 环境变量中搜索程序；
2. 标准输入输出重定向；
3. pipe实现

sh.c源码分析
~~~~~~~~~~~~
函数调用关系：

- peek: 跳过输入字符串*ps中开头的空白字符，然后读取一个非空字符，判断它是否在指定字符串toks中出现，若出现则返回非零值，否则返回0

- gettoken: 读取一个单词或"<|>"这几个字符，将其起始和结束位置分别保存在q和eq中，读取后ps偏移到下一个非空字符串的起始处。如果读取结果为"<|>"或结束符，则返回对应字符的值，否则返回字符'a'的值（代表解析结果是普通字符串）。

- parsecmd

::

   parsecmd 
   |- parseline 解析本行的命令
         |- parsepipe 
               |- parseexec 解析普通命令或重定向命令
                  |- execcmd 申请struct execcmd所需内存并初始化
                  |- parseedirs 解析重定向命令并返回解析结果
                        |- peek 判断下一个非空字符是否为"<"或">"，若是，则继续执行下面的操作，否则直接返回
                        |- gettoken 获取字符"<"或">"
                        |- gettoken 获取文件名
                        |- redircmd 将命令名、重定向符和文件名组成redircmd结构体并返回
                  |- peek 若接下来的非空字符为"|"，则结束解析；否则继续解析
                  |- gettoken 读取一个单词（即命令名或输入选项），并保存在cmd中
                  |- parseredir 判断下一个非空字符是否为"<"或">"，若是则解析重定向命令，否则继续解析普通命令
               |- peek 判断下一个字符是否为"|"，若是则继续下面的操作，否则直接返回parseexec的解析结果
               |- gettoken 跳过字符"|"
               |- pipecmd 将当前已解析的命令cmd和下一个命令组成pcmd，注意此处递归调用parsepipe，最终得到一棵右倾斜树
   |- peek 解析完成后，判断本行后面是否还有多余字符，若有则报错


