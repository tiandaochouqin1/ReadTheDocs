==============
启动
==============

.. admonition:: 摘要

   系统启动流程笔记：x86 启动（BIOS→MBR/GPT→BootLoader→内核→init）和 ARM 启动（三级引导+设备树+UEFI），以及无盘启动方案。适合需要理解系统启动全流程的嵌入式/系统开发者。


X86启动
=========

.. note::

   参考：`Embedded Linux Design: File System and Bootloader - EDN <https://www.edn.com/embedded-linux-design-file-system-and-bootloader/>`__


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


ARM启动
===========

.. note::

   参考：`How does ARM boot? <https://fedevel.com/blog/how-does-arm-boot>`__ 、
   `Booting ARM Linux — The Linux Kernel documentation <https://docs.kernel.org/arch/arm/booting.html>`__ 、
   `ARM64的启动过程之（五）：UEFI <http://www.wowotech.net/armv8a_arch/UEFI.html>`__


与 x86 的关键区别
--------------------

x86 上电后 CPU 跳到一个固定的 BIOS 地址（0xFFFFFFF0），由 BIOS 完成硬件枚举和启动介质选择。但 ARM **没有 BIOS**。

ARM 的做法是：CPU 内部有一块固化的 ROM，上电后执行其中的代码。这段 ROM 代码通过读取 **启动引脚（bootstrap pins）** 或 **eFuse** 的电平/状态，来决定从哪个外设（NAND、SD 卡、SPI Flash、Ethernet 等）加载下一阶段的代码。eFuse 一旦烧写为 1 就不可逆。

这是一个硬件层面的"启动策略选择"，替代了 x86 BIOS 的软件枚举角色。


ARM 三级启动流程
------------------

.. code-block:: text

   CPU上电 → [Stage1: 片内ROM] → [Stage2: SRAM中的loader] → [Stage3: DRAM中的bootloader/OS]

**Stage 1 — 片内 Boot ROM**

- CPU 固化的 ROM 代码执行，**此时 DRAM 还没有初始化，只能使用片内 SRAM**。
- 根据启动引脚/eFuse 选择启动外设。
- 从外设读取一小段 loader 到片内 SRAM，校验后跳转执行。
- 也支持通过串口或 USB 直接下载镜像（空板烧写场景）。

**Stage 2 — Bootloader（DRAM 初始化）**

- 这段代码运行在片内 SRAM 中，首要任务是 **初始化 DRAM 控制器**。
- DRAM 就绪后，从外设加载完整的 bootloader（如 U-Boot）到 DRAM 中执行。
- 后续和 x86 的 GRUB 类似：加载内核、传递参数、跳转。

**Stage 3 — OS 加载**

- U-Boot 等 bootloader 将内核和 DTB 加载到 DRAM，按 ARM Linux 启动协议跳转到内核。


ARM Linux 内核启动协议
------------------------

Bootloader 跳转到 ARM Linux 内核时，有一组强制的寄存器约定（来自内核文档 ``Documentation/arch/arm/booting.rst``）：

**寄存器状态：**

====  ============================================
r0    必须为 0
r1    机器类型号（MACH_TYPE），DT-only 平台填 ~0
r2    ATAG 列表或 DTB 的物理地址
====  ============================================

**CPU 状态要求：**

- 中断：IRQ 和 FIQ **必须关闭**
- CPU 模式：无虚拟化扩展 → **SVC 模式**；有虚拟化扩展 → 推荐 **HYP 模式**（否则也必须是 SVC）
- MMU：**必须关闭**（内核自己开）
- D-Cache：**必须关闭**（防止脏数据被内核当作有效内存）
- I-Cache：可开可关（开了也没事，内核会处理）
- DMA：bootloader **必须静止所有具备 DMA 能力的设备**，否则网络 DMA 等可能在内存中写入垃圾数据破坏内核

**两种启动数据传递方式：**

ATAG（Tagged List）：
  以 ``ATAG_CORE`` 开始、``ATAG_NONE`` 结束的链表。至少包含内存大小/位置和根文件系统位置。
  推荐放在 RAM 前 16 KiB。**旧方案，已逐步被 DTB 取代。**

DTB（Device Tree Blob）：
  必须 **64 位对齐** 存储在 RAM 中。内核通过检测魔数 ``0xd00dfeed`` 区分 DTB 和 ATAG。
  推荐放在 RAM 起始地址之上 **128 MiB 边界处**，避免被内核解压器覆盖。


ARM64 UEFI 启动
------------------

当 ARM 从嵌入式走向 SBC/服务器时，需要和 x86 一样的通用固件接口，于是有了 ARM64 上的 UEFI。

ARM64 UEFI 固件遵循 PI（Platform Initialization）规范，分四个阶段：

.. code-block:: text

   Reset → SEC → PEI → DXE → BDS → OS Loader → OS

**SEC（Security Phase）**
  复位后第一条指令。ARM64 上这里有一个关键差异：**DRAM 还没初始化，只能把 CPU Cache 当 RAM 用**（Cache-as-RAM, CAR）。SEC 负责固件完整性校验（Boot Guard），然后定位 PEI Core。

**PEI（Pre-EFI Initialization）**
  初始化 DRAM 控制器、MMU、Cache、异常级别、GPIO/时钟树。PEI 的输出是 **HOB 列表**（Hand-Off Blocks）——一个描述物理内存布局和固件卷位置的数据结构链表，传给 DXE。

**DXE（Driver Execution Environment）**
  固件的"主力阶段"。初始化 Boot Services / Runtime Services 表、Handle Database、按依赖顺序加载驱动。产出 ACPI 表、SMBIOS 表，枚举 PCI、存储、网络、USB、图形控制台、GIC 中断控制器、ARM 架构定时器。

**BDS（Boot Device Selection）**
  最后一个固件阶段。枚举启动设备（硬盘、USB、PXE），处理 Secure Boot 策略和启动顺序，加载并执行 OS boot loader（GRUB2、systemd-boot、或 Linux 内核自身的 EFI stub）。

ARM64 的 Linux 内核通过 **EFI Stub**（``CONFIG_EFI_STUB``）直接伪装成 PE/COFF 可执行文件（``arch/arm64/boot/Image``），没有 x86 的 bzImage 压缩层。BDS 把它当普通 UEFI 应用加载，EFI stub 内部调用 ``GetMemoryMap()`` 获取内存布局、填充 DT ``/chosen`` 节点、调用 ``ExitBootServices()`` 后跳转到内核入口。


设备树
-------

设备树是 ARM 芯片主要用于嵌入式设备的时代的遗留物。

当芯片只与一组固定的外设通信时，不需要 BIOS/UEFI 的灵活性，可以简化 ROM 并减少与抽象相关的开销。

但转移到更通用的 SBC 和台式机/服务器设计时，便有了UEFI支持。


无盘启动
===========

.. note::

   参考：`Embedded Linux Design: File System and Bootloader - EDN <https://www.edn.com/embedded-linux-design-file-system-and-bootloader/>`__

无盘启动的核心思路：目标设备无本地存储，通过网络完成从 bootloader 到 rootfs 的全部加载。

三段式流程：

.. code-block:: text

   [PXE/DHCP] → [TFTP下载bootloader+内核] → [NFS挂载rootfs]

**阶段 1** — 网卡固件通过 DHCP 获取 IP 和 bootloader 文件名（``filename`` 选项），从 TFTP 下载 ``pxelinux.0``。

**阶段 2** — pxelinux.0 通过 TFTP 下载内核和 initramfs，内核命令行指定 ``nfsroot=<ip>:<path>``。

**阶段 3** — 内核启动后通过 NFS 挂载根文件系统（只读）。``/tmp``、``/var/run`` 等可写目录用 tmpfs 承载。

服务端需要四个组件：

====  =============  ===================================
DHCP  dhcpd/dnsmasq   分配 IP、告知 TFTP 地址和 NFS 路径
TFTP  tftpd-hpa      提供 pxelinux.0、内核、initramfs
NFS   nfs-kernel      导出只读根文件系统
====  =============  ===================================

内核需启用：``CONFIG_NFS_FS``、``CONFIG_ROOT_NFS``、``CONFIG_IP_PNP``、``CONFIG_IP_PNP_DHCP``。

进阶用法：多个客户端共享同一份 NFS root，各自通过 **overlayfs** 叠加一层 tmpfs 作为可写层，所有写入留在本地 RAM 中，每次启动都是干净状态。


其它启动方案
=============

kexec — 内核级快速重启
------------------------

.. note::

   参考：`linux kexec内核引导 - wahaha02 - 博客园 <https://www.cnblogs.com/wahaha02/p/7152796.html>`__

kexec 的核心价值：**跳过固件和 bootloader，从当前内核直接启动新内核**。kdump 崩溃转储机制就是基于它。

分两步操作：

====  =====================================================  ================
加载  ``kexec -l /bzImage --initrd=... --append="..."``       内核段→内存
执行  ``kexec -e``                                            跳转到新内核
====  =====================================================  ================

执行时的核心流程（x86 为例）：

1. 调用每个设备驱动的 shutdown 接口 → 静止硬件
2. 关闭 IO-APIC / LAPIC → 禁所有中断
3. 关闭非 0 号 CPU
4. 刷新 TLB
5. 重配 GDT/IDT/段寄存器
6. 构建新栈，新内核入口地址压栈
7. CR0/CR4 启用分页和扩展寻址，CR3 切换到新页表
8. 复制新内核段覆盖当前内核
9. ``ret`` 弹出入栈的入口地址 → 新内核开始执行

关键风险：
  - **不做硬件复位**：设备状态不是上电初始态，依赖每个驱动 shutdown 实现的正确性。
  - **文件系统不 sync/umount**：用户自己保证数据安全。
  - 底层 ``relocate_new_kernel`` 是架构相关的汇编，x86/ARM64/PowerPC 各不相同。

.. code-block:: text

   正常启动：BIOS/UEFI → Bootloader → Kernel → init
   kexec：   运行中的 Kernel → 新 Kernel
