======
Linux
======

:Date:   2021-04-24 16:52:25


内核开发入门
============

参考资料
--------

https://www.kernel.org/doc/html/latest/translations/zh_CN/

https://kernelnewbies.org/

https://lwn.net/

https://kernel.org/pub/linux/kernel/


参考书籍
~~~~~~~~

1. Linux内核设计与实现 第三版
2. `趣谈Linux操作系统——刘超 <https://zter.ml/>`__
3. Linux Devices Driver
4. Proffesional Linux Kernel Architecture

基本概念
~~~~~~~~
内核态拥有受保护的内存空间和访问硬件设备的所有权限。

应用程序通过库函数或系统调用让内核代替完成各种任务。
库函数不仅是对系统调用的打包，它也实现了系统调用不具备的功能，如strcpy。

.. figure:: ../images/SyscallAndLibc.png
   :alt: 库函数和系统调用

   库函数和系统调用


**处理器可能的状态：**

1. 运行于用户空间，执行用户进程；
2. 运行于内核空间，处于进程上下文，代表某个特定的进程执行；
3. 运行于内核空间，处于中断上下文，处理特定的中断（与任何进程无关）。
4. CPU空闲时，运行一个空进程，处于2的状态。

**微内核：**
将内核服务的地址空间隔离，内核只提供基础服务（IPC、内存、调度等），
其它服务组件如文件系统、驱动程序等则各自运行在独立的地址空间（用户空间），并以IPC的方式为其它应用程序提供服务。

微内核提升了稳定性、安全性、扩展性和内核实时性，但是损失了效率。


内核版本号
----------

`Linux内核版本号： <http://en.wikipedia.org/wiki/Linux_kernel#Version_numbering>`__

1. 2.x 版本奇数表示开发版、偶数表示稳定版。2.6.x系列覆盖了2003-2011年。
2. 3.0开始，版本号基于时间变化（近2个月更新一次小版本号），不代表有重大的内容更新。同时避免小版本号超过20。
3. 当前5.11为15-Feb-2021发布

-  mainline 是主线版本。
-  stable 是稳定版，由 mainline
   在时机成熟时发布，稳定版也会在相应版本号的主线上提供 bug
   修复和安全补丁
-  longterm
   是长期支持版，多为\ `6年 <https://www.kernel.org/category/releases.html>`__
-  RC：release candidates。


编译
--------------


下载源码
~~~~~~~~~
1. 下载发布版本包；
2. 下载Git。

::

   git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
   镜像
   git clone git clone https://mirrors.tuna.tsinghua.edu.cn/git/linux-stable.git

   在windows中有兼容性问题（aux文件在win中为设备文件）。
   git config core.protectNTFS false
   git rm --cache aux.c/h


3. 切换版本
   
::
   
   git tag
   git checkout V5.0


内核编译
~~~~~~~~
Kbuild+Makefile

编译选项通常有三个：Yes/No/Module。Module代表以模块的形式独立生成。

发布版：Ubuntu、Federo等发布版包含了预编译的内核，已启用了所需的功能，而驱动程序一般都是模块。


::

   安装依赖
   sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison


   make menuconfig

   cp /boot/config-$(uname -r) .config

   make oldconfig //验证.config

   make -j8 >> make.log

   make modules_install //安装启用的模块

   sudo make install //安装内核。然后需要更新引导！！


模块编译
~~~~~~~~



1. 源码树内部编译：
   
   1. 增加文件夹，在kconfig中添加编译选项
   2。 按照编译选项编写makefile

2. 在源码树外部编译：（OSC中的Lab，在ubuntu18中会提示insmod签名问题）

   :download:`simple.c <../files/code/simple.c>`


   需要自己写makefile。本机内核模块目录 ``/lib/modules/$(uname -r)/build``，避免在修改模块的源代码时重新编译整个内核。

::

   obj-m := hello_module.o
   ​
   KERNELBUILD := /lib/modules/$(uname -r)/build
   CURRENT_PATH := $(pwd)
   ​
   all:
       make -C $(KERNELBUILD) M=$(CURRENT_PATH) modules
   ​
   clean:
           make -C $(KERNELBUILD) M=$(CURRENT_PATH) clean


模块安装：``sudo insmod mod.ko``
dmesg : 查看内核日志缓冲区（包括printk的输出内容）。

进程
=====
进程管理
---------


