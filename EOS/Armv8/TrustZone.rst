==============
TrustZone
==============




TrustZone
============
1. ★ `4. Firmware Design — Trusted Firmware-A documentation  <https://trustedfirmware-a.readthedocs.io/en/latest/design/firmware-design.html>`__
2. ★ `ARM Trusted Firmware分析——启动、PSCI、OP-TEE接口 - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/14175126.html>`__
3. `学习整理：arm-trusted-firmware - HarmonyHu’s Blog  <https://harmonyhu.com/2018/06/23/Arm-trusted-firmware/>`__
4. `TEE Reference Documentation – Arm®  <https://www.arm.com/technologies/trustzone-for-cortex-a/tee-reference-documentation>`__
    其中包括 trustzone security white paper
5. `TrustZone for Cortex-A – Arm®  <https://www.arm.com/technologies/trustzone-for-cortex-a>`__

TF-A
-------
Trusted Firmware-A (TF-A) provides a reference implementation of secure world software for Armv7-A, Armv8-A and Armv9-A, 
including a Secure Monitor executing at Exception Level 3 (EL3) 
and a Secure Partition Manager running at Secure EL2 (S-EL2) of the Arm architecture.


Trusted Firmware-A implements various Arm interface standards, such as:

1. Power State Coordination Interface (PSCI)
2. Trusted Board Boot Requirements (TBBR)
3. SMC Calling Convention  (SMCCC)
4. System Control and Management Interface (SCMI)
5. Software Delegated Exception Interface (SDEI)


A **System Control Processor (SCP)** is a processor-based capability that provides a flexible and extensible platform 
for provision of **power management** functions and services. 

.. figure:: /images/ATF_Scp.png
   :scale: 60%

   ATF_Scp


ATF冷启动
-------------

.. figure:: /images/ATF_Boot.png

   ATF_Boot



.. figure:: /images/ATF_Cold_Boot.png

   ATF_Cold_Boot


ATF输出BL1、BL2、BL31，提供BL32和BL33接口。

ATF冷启动实现分为5个步骤：(详见参考文献)

1. BL1 - AP Trusted ROM，一般为BootRom。EL3。  选择cold/warm boot模式、建立exception vectors、加载BL2。
2. BL2 - Trusted Boot Firmware，一般为Trusted Bootloader。EL1。   加载BL3x。 
3. BL31 - EL3 Runtime Firmware，一般为SML，管理SMC执行处理和中断，运行在secure monitor中。EL3。 
4. BL32 - Secure-EL1 Payload，一般为TEE OS Image。
5. BL33 - Non-Trusted Firmware，一般为uboot、linux kernel。EL1。


从核启动
~~~~~~~~~~~
1. `ARM WFI和WFE指令  <http://www.wowotech.net/armv8a_arch/wfe_wfi.html>`__
2. `SMP多核启动 - yooooooo - 博客园  <https://www.cnblogs.com/linhaostudy/p/9371562.html>`__

启动流程：

1. 主核(核0)启动并运行Linux之后，继续 通过 **bl31->(PCSI)->scp->(SCMI)->ap** 来使从核上电。
2. 从核上电后从给定Linux位置(主核传参)启动，然后进入WFI/WFE状态等待，直到主核发送核间中断唤醒从核。
3. 从核之后则可以被动态负载均衡调度。

::

   echo 1/0 > /sys/devices/system/cpu/cpu1/online


Linux启动
~~~~~~~~~~~~~~
1. `Linux 内核启动分析-BugMan-ChinaUnix博客  <http://blog.chinaunix.net/uid-69947851-id-5830505.html>`__

arch/arm64/kernel/vmlinux.lds.S

::


   OUTPUT_ARCH(aarch64)
   ENTRY(_text)
   
   .....

   .head.text : {
   _text = .;

   .....

   HEAD_TEXT在 arch/arm64/kernel/head.S文件使用，如下：


   #define __PHYS_OFFSET   (KERNEL_START - TEXT_OFFSET) // 内核物理地址起始位置

   __HEAD
   _head:
       b stext // branch to kernel start, magic
       .long 0 // reserved
       le64sym _kernel_offset_le // Image load offset from start of RAM, little-endian
       le64sym _kernel_size_le // Effective size of kernel image, little-endian
       le64sym _kernel_flags_le // Informative flags, little-endian
       .quad 0 // reserved
       .quad 0 // reserved
       .quad 0 // reserved
       .ascii "ARM\x64" // Magic number
       .long 0 // reserved
   

   __INIT
   ENTRY(stext)
       bl  preserve_boot_args
       bl  el2_setup           // Drop to EL1, w0=cpu_boot_mode
       adrp    x23, __PHYS_OFFSET // 物理地址偏移
       and x23, x23, MIN_KIMG_ALIGN - 1    // KASLR offset, defaults to 0，一种内核安全机制，通过物理地址起始位置计算出偏移大小，偏移大小保存在X23寄存器
       bl  set_cpu_boot_mode_flag
       bl  __create_page_tables
       bl  __cpu_setup         // initialise processor
       b   __primary_switch
   ENDPROC(stext)


步骤:

1. preserve_boot_args: 将uboot传入的参数 保存到bootargs[4] 全局变量里面。

2. el2_setup :判断启动的模式是el2还是el1并进行相关级别的系统配置(armv8中el2是hypervisor模式,el1是标准的内核模式,具体的参考手册),  然后返回启动模式

3. set_cpu_boot_mode_flag: 将启动模式保存到全局变量

4. __create_page_tables: 创建内存映射表,一共两张,一张存放在swapper_pg_dir(线性映射),一张存放在idmap_pg_dir(一对一映射)。

5. __cpu_setup : 初始化处理器相关的代码,配置访问权限,内存地址划分等。

6. __primary_switch :开启MMU, 准备0号进程和内核栈,然后跳转到start_kernel运行

Dynamic TrustZone
=====================
1. `Arm's dynamic TrustZone technology - Architectures and Processors blog - Arm Community blogs - Arm Community  <https://community.arm.com/arm-community-blogs/b/architectures-and-processors-blog/posts/introducing-arms-dynamic-trustzone-technology>`__


This technology uses the Realm Management Extension (RME) to 
provide an architected mechanism to assign pages of memory between the Non-Secure and Secure address spaces, at run time.

Realm Management Extension
----------------------------


Confidential Compute Architecture
-------------------------------------
1. `Arm Confidential Compute Architecture – Arm®  <https://www.arm.com/architecture/security-features/arm-confidential-compute-architecture>`__

Confidential compute is a broad term for technologies that reduce the need to trust a computing infrastructure, 
such as the need for processes to trust operating system (OS) kernels and the need for virtual machines to trust hypervisors


可信计算
