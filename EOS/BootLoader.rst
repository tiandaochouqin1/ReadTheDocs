==============
启动
==============

.. admonition:: 摘要

   系统启动流程笔记：x86 启动（BIOS→MBR/GPT→BootLoader→内核→init）和 ARM 启动（设备树+UEFI），以及无盘启动方案。适合需要理解系统启动全流程的嵌入式/系统开发者。


X86启动
=========
1. https://labex.io/lesson/boot-process-bootloader

bios->bootloader->kernel->init 

bios
-----
basic input output system 。

cpu上电、复位后后第一条指令的地址被硬连线指向一个固定位置（地址 0xFFFFFFF0 ），即rom中bios的起始地址。

bios并不会实际的载入到内存（ram）中去，内存地址的分配是混合分配的：并不是只有内存（ram）才会分配地址，
bios所在rom也会被分配地址空间。
有了分配的地址，cpu就可以在开机的时候通过寻址找到bios的二进制数据来进行处理。


主要功能：

1. POST，硬件初始化和自检。 initialize and test the system hardware, such as the CPU, memory, and hard drives
2. 找到bootloader的block位置，并决定如何启动bootloader。GPT分区和MBR分区格式下，会去不同的地址搜寻。


- MBR：在硬盘前512B空间，保存着boot代码和分区表，这块代码负责加载 bootloaer的加载程序。
- UEFI：比BIOS更快的启动速度，支持更大的硬盘。使用GPT，并兼容MBR。在esp分区中保存着bootloader。


bootloader-GRUB
-------------------
A bootloader in Linux is a small program that loads the operating system's kernel into memory and then executes it. 
It acts as the bridge between the system's firmware and the Linux kernel.

主要功能是 把内核加载进内存，传递启动参数，并转交控制：
1. 选择操作系统
2. 选择内核版本（linux下）
3. 传递内核参数


GRUB (GRand Unified Bootloader)的常见参数：
1. initrd：指定初始化的ramdisk，一个将被加载进内存的临时root文件系统。
2. BOOT_IMAGE：内核镜像
3. root：真实根文件系统的路径。一般是设备名（/dev/sda1、uuid）。可通过 /etc/default/grub配置。
4. quiet：suppress的detailed boot message
5. splash：开机动画、可视化。


kernel 
------------

内核需要运行驱动才能访问硬件设备，然而驱动文件通常保存在目前无法访问的存储设备上，因此linux使用临时根文件系统。

1. initrd (initial RAM disk)：硬盘镜像。需要创建和挂在块设备才能拿到里面的驱动。
2. initramfs：一种cpio压缩文件，直接解压到内存中的临时文件系统，更加高效。包含了内核访问启动分区和其它硬件的关键模块。


真实根文件系统挂在：
1. 内核将跟根文件系统以只读挂在，进行fsck检查文件系统的完整性。
2. 然后重新以读写属性挂载。
3. 开始运行内核第一个程序init

内核第一个程序init
-----------------------

init是所有进程的父进行，并负责启动保证系统可用的关键服务。


init的几种实现方式
1. system v init：通过脚本定义顺序的启动流程，通过runlevel来管理一系列的服务。
2. upstart：基于事件的init系统。通过事件启停服务。如网络设备就绪事件
3. systemd：现代linux系统使用。目标导向的系统，递归管理了依赖关系。指定一个目标状态，systemd会并行地处理所有依赖。


arm启动
===========


设备树
-------

uefi和设备树
~~~~~~~~~~~~~~~~~~
设备树是ARM 芯片主要用于嵌入式设备的时代的遗留物。

当芯片只与一组固定的外设通信时，不需要 BIOS/UEFI 的灵活性，可以简化 ROM 并减少与抽象相关的开销。

但转移到更通用的 SBC 和台式机/服务器设计时，便有了UEFI支持。



无盘启动
===========


其它启动方案
================

x86: bios->简化的linux->全量linux