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


LAB1
===========
:download:`xv6 code-lab1 </files/xv6.zip>`
   
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
   b *0x7c00
   c
   





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
2. x86函数调用栈帧 `journey-to-the-stack <https://manybutfinite.com/post/journey-to-the-stack/>`__ ; 
   函数调用返回与缓冲区溢出 `Epilogues, Canaries, and Buffer Overflows  <https://manybutfinite.com/post/epilogues-canaries-buffer-overflows/>`__
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


x86 栈帧回溯
~~~~~~~~~~~~~~~~
与aarch64栈帧回溯方法一致。

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
   FP -> | previous FP --------> | previous FP ------>...      pushl %ebp :save 
         |                 |     |                 |
         | return address  |     | return address  |           callq func: will auto save ret addr
         +-----------------+     +-----------------+
            (bigger addr.)



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
4. n_desc表示在文件中的行号
5. n_value表示地址。只有FUN类型的符号的地址是绝对地址，SLINE符号的地址是偏移量，其实际地址为函数入口地址加上偏移量。
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


Part 1:Physical Page Management
-----------------------------------

内存布局：

::

   /*
   *                     .                              .
   *                     .       Managable Space        .
   *                     .                              .
   pages ends 0x158000 -->+------------------------------+
   *                     |                              |
   *                     .                              .
   *                     .   pages management array     .
   *                     .                              .
   *                     |                              |
   *  pages 0x118000 ->  +------------------------------+
   *                     |        Kernel is here        |
   *    EXT 0x100000 ->  +------------------------------+
   *                     |                              |
   *                     |          IO Hole             |
   *                     |                              |
   * BASEMEM 0xa0000 ->  +------------------------------+
   *                     |    Basic Managable Space     |
   *    KERNBASE ----->  +------------------------------+
   */



Todo-20220202
-----------------
基础不够，学起来吃力。

1. https://pdos.csail.mit.edu/6.828/2018/readings/i386/s05_01.htm
2. https://pdos.csail.mit.edu/6.828/2018/labs/lab2/
3. https://zhuanlan.zhihu.com/p/183974374
4. https://www.cnblogs.com/fatsheep9146/p/5124921.html
5. https://pdos.csail.mit.edu/6.828/2018/schedule.html

Part 2: Virtual Memory
-------------------------------------



Part 3: Kernel Address Space
---------------------------------

