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
-----------
1. `100个gdb小技巧 <https://wizardforcel.gitbooks.io/100-gdb-tips>`__
2. https://sourceware.org/gdb/onlinedocs/gdb/ 

调试stripped程序
~~~~~~~~~~~~~~~~~~~
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
3. 

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





PA 
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

跟踪调试： 0x7c00 -> bootmain -> readsect

`boot代码解析 <https://www.cnblogs.com/fatsheep9146/p/5115086.html>`__

Part 3: The Boot Loader
-------------------------------
1. 虚拟内存的切换。进入内核后切换（entry  f010000c (virt)  0010000c (phys)）
2. vprintfmt + putch 原理，增加vprintfmt oct进制打印。
3. 内核栈的初始化
4. 利用eip回溯调用栈。
5. 结合asm和gdb分析test_backtrace每一层使用的栈空间（0x20）。

参考

1. `stabs调试信息 <https://sourceware.org/gdb/onlinedocs/stabs.html#Overview>`__
