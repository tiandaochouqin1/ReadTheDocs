============
MMU和SMMU
============
1. :download:`Arm System Memory Management Unit Architecture Specification v3.3 </files/arm/ARM_IHI_0070_D_b_System_Memory_Management_Unit_Architecture_Specification.pdf>`





.. figure:: /images/smmu.png
   :scale: 60%

   System Memory Management Unit



1. 为什么需要MMU：支持虚拟化（虚拟内存）
2. 为什么还需要SMMU？：MMU只能给cpu使用（单设备，arm的TTBRx 为页表基地址，TCR寄存器为查表控制信息）；而SMMU使用SID区分设备，通过SID找到对应的STE，拿到STE->Context Descriptor里面有页表位置和其它控制位），拿到CD后的流程和MMU一模一样。
3. 什么是2 stage？  [虚拟地址 (VA)] --(ASID)--> [Stage 1] -> [中间物理地址 (IPA)] --(VMID)--> [Stage 2] -> [物理地址 (PA)]


arm mmu
============
1. arm mmu  `The-Memory-Management-Unit - PG   <https://developer.arm.com/documentation/den0024/a/The-Memory-Management-Unit>`__
2. `Translations-at-EL2-and-EL3 - PG <https://developer.arm.com/documentation/den0024/a/The-Memory-Management-Unit/Translations-at-EL2-and-EL3>`__
3. figuire 4-1 `Learn the architecture - AArch64 memory management  <https://developer.arm.com/documentation/101811/0102/The-Memory-Management-Unit--MMU-?lang=en>`__


.. figure:: /images/arm_mmu.png
   :scale: 60%

   arm_mmu


TTBRx 和 TCR
------------------
TTBR（Translation Table Base Register）寄存器用于保存页表的基地址。ARM 处理器通常有两个TTBR寄存器：

1. TTBR0：用于用户空间页表。
2. TTBR1：用于内核空间页表。

当处理器进行地址转换时，它会参考这些寄存器中的基地址，从而找到对应的页表条目。


TCR（Translation Control Register）寄存器用于控制地址转换的行为。它包含了多种控制位，可以配置如下内容：

2. 页表的级别：指定页表的起始级别。
2. 地址空间大小：定义虚拟地址空间的大小。
3. 粒度大小：设置页表条目的粒度（例如，4KB、16KB 或 64KB）。
4. 共享属性：指定内存是否可以在多个处理器间共享。
5. 缓存策略：定义缓存的行为，例如是否启用缓存和缓存的类型。


虚拟化 - 2 stage
------------------------------

1. 第一级转换：操作系统可以优化进程的内存访问。

2. 第二级转换：虚拟机监视器可以优化虚拟机的内存访问，管理整个系统的物理内存分配。

在不同Guest OS间共享物理内存。

.. figure:: /images/two_stage_translation_process.png
   :scale: 50%

   two_stage_translation_process




VMID ASID - 2 stages
-------------------------
**Stage 2** translation allows a hypervisor to control a view of memory in a Virtual Machine (VM). Specifically, it allows the hypervisor to control which memory-mapped system resources a VM can access, and where those resources appear in the address space of the VM.

This ability to control memory access is important for isolation and sandboxing


.. figure:: /images/Address_spaces_in_Armv8-A.jpg
   :scale: 120%
   
   Address_spaces_in_Armv8-A

.. figure:: /images/va-to-ipa-to-pa-address-translation.jpg
   :scale: 50%
   
   va-to-ipa-to-pa-address-translation


1. Stage 1 translation: OS，通过traslation table将虚拟地址空间转换为IPA(Intermediate Physical Address Space)。
2. Stage 2 translation: hyperviosr控制对应vm级别可使用的内存。ensure that a VM can only see the resources that are allocated to it


以下是一个示意图，展示 ASID、VMID 和两级地址转换的关系：

::

   [虚拟机1]
   |
   +--[进程1] --(ASID1)--> [第一级转换] -> [IPA1]
   |
   +--[进程2] --(ASID2)--> [第一级转换] -> [IPA2]

   [虚拟机2]
   |
   +--[进程1] --(ASID1)--> [第一级转换] -> [IPA1]
   |
   +--[进程2] --(ASID2)--> [第一级转换] -> [IPA2]

   [Hypervisor]
   |
   +--[虚拟机1] --(VMID1)--> [第二级转换] -> [PA1]
   |
   +--[虚拟机2] --(VMID2)--> [第二级转换] -> [PA2]



ASID（Address Space Identifier）
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ASID 是一个标识符，用于区分不同进程的地址空间。它的主要作用包括：

缓存管理：ASID 用于在 TLB（Translation Lookaside Buffer）中区分不同进程的虚拟地址。这样，在上下文切换时，TLB 不需要完全刷新，从而提高性能。
地址空间隔离：每个进程有一个唯一的 ASID，确保进程之间的地址空间隔离。


VMID（Virtual Machine Identifier）
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
VMID 是用于标识不同虚拟机的标识符。在虚拟化环境中，它的主要作用包括：

虚拟机隔离：VMID 用于区分不同虚拟机的地址空间，确保虚拟机之间的内存访问隔离。
二级转换缓存管理：在两级地址转换中，VMID 可以用于在二级转换过程中管理和区分不同虚拟机的地址转换条目。

arm SMMU
============
1. `ARM SMMU的原理与IOMMU   <https://blog.51cto.com/u_15155099/2767161>`__
2. 虚拟化和smmuv3 `ARMv8 Virtualization Overview · kernelgo  <https://kernelgo.org/armv8-virt-guide.html>`__

3. `ARM系列 -- SMMU（一） - 极术社区 - 连接开发者与智能计算生态  <https://aijishu.com/a/1060000000208280>`__



SMMU（IOMMU）和MMU一样，提供stage1转换（VA->IPA）, 或者stage2转换（IPA->PA）,或者stage1 + stage2转换（VA->IPA->PA）的灵活配置。


1. DMA需要连续的地址.
2. 虚拟化： 在虚拟化场景， 所有的VM都运行在中间层hypervisor上，每一个VM独立运行自己的OS（guest OS）,Hypervisor完成硬件资源的共享, 隔离和切换。
    但guest VM使用的物理地址是GPA, 看到的内存并非实际的物理地址HPA，因此Guest OS无法正常的将连续的物理地址分给DMA硬件。


.. figure:: /images/dma_smmu.png
   :scale: 80%

   虚拟化+DMA -> SMMU


smmu vs mmu
-------------
.. important:: arm中smmu和mmu架构差异？

1. `SMMU跟TrustZone啥关系？ - 极术社区 - 连接开发者与智能计算生态  <https://aijishu.com/a/1060000000123590>`__
2. 没有区分mmu和smmu  `(Stage 2 translation) Learn the architecture: AArch64 Virtualization  <https://developer.arm.com/documentation/102142/0100/Stage-2-translation>`__
3. `SMMU学习这一篇就够了(软件硬件原理/模型导读) - 极术社区 - 连接开发者与智能计算生态  <https://aijishu.com/a/1060000000383898#item-3-4>`__

- MMU 只能给 一个core用。而SMMU想给多个master用，多个master又对应不同的表。所以就搞了个STE。
- 每一个STE entry里，都可以指向多个context descriptor，然后每一个context descriptor 就相当于 MMU的TTBRx + TCR寄存器。
- context Descriptor之后，就和普通的MMU一样


SMMU跟MMU非常相似，主要给其他Master来使用，连 **页表格式也是一样的**，只是编程方式不同，理论上可以让CPU的MMU和SMMU可以使用同一套页表。
增加SMMU后， **其他Master也相当于有了MMU的功能**。

smmu
----------------
`iommu分析之---smmu v3的实现 - _备忘录 - 博客园  <https://www.cnblogs.com/10087622blog/p/15479476.html>`__

1. SID (arm smmu) <-> RequestID(x86 PCI): 区分设备
2. SSID(arm smmu) <-> PASID(x86 PCI):区分进程


.. figure:: /images/arm_smmu_2stage_translation.png
   :scale: 100%

   arm_smmu_2stage_tran



1. Guest驱动发起DMA请求，这个DMA请求包含VA + SID前缀
2. DMA请求到达SMMU，SMMU提取DMA请求中的SID就知道这个请求是哪个设备发来的，然后去StreamTable索引对应的STE
3. 从对应的STE表中查找到对应的CD，然后用ssid到CD中进行索引找到对应的S1 Page Table
4. IOMMU进行S1 Page Table Walk，将VA翻译成IPA并作为S2的输入
5. IOMMU执行S2 Page Table Walk，将IPA翻译成PA，地址转化结束。




页表与查找过程
==============
1. `操作系统中的多级页表到底是为了解决什么问题？ - 知乎  <https://www.zhihu.com/question/63375062>`__
2. `[mmu/cache]-ARM MMU/TLB的学习笔记和总结_arm tlb_代码改变世界ctw的博客-CSDN博客  <https://blog.csdn.net/weixin_42135087/article/details/109575691>`__

对于每次转换，MMU首先在TLB中检查现有的缓存。如果没有命中，根据CR3寄存器，Table Walk Unit将从内存中的页表查询。

多级页表
-----------
页表为什么分级？

1. 次级页表可按需创建，节省内存；
2. 次级页表可以不在内存，按需换页；(一般要求一级页表在内存)

.. figure:: /images/arm_3level_pt.png
   :scale: 90%

   arm_3level_pt

::

   (1)、在开启MMU后，cpu发起的读写地址是一个64bit的虚拟地址，
   (2)、该虚拟地址的高16bit要么是全0，要么是全1. 如果是全0，则选择TTBR0_ELx做为L1页表的基地址; 如果是全1，则选择TTBR1_ELx做为L1页表的基地址;
   (3)、TTBRx_ELn做为L1页表，它指向L2页表，在根据bit[41:29]的index，查询到L3页表的基地址
   (4)(5)、有了L3页表的基地址之后，在根据bit[28:16]的index，查询到页面的地址
   (6)、最后再根据bit[15:0]查找到最终的物理地址



vmid和ASID
-------------
VMID与VM关联，ASID与Appliation关联。

TLB entries can also be tagged with an Address Space Identifier (ASID). 
An application is assigned an ASID by the OS, and all the TLB entries in that application are tagged with that ASID.

Each VM is assigned a virtual machine identifier (VMID). 
The VMID is used to tag translation lookaside buffer (TLB) entries, to identify which VM each entry belongs to. 

页表与虚实转换
--------------
`Cache memory 、VA to PA、MMU 和 SMMU 总结 - 知乎  <https://zhuanlan.zhihu.com/p/436719684?utm_id=0>`__




STE-SMMU
-----------------------
1.  ☆☆ `ARM SMMU学习笔记_Hober_yao的博客-CSDN博客_smmu  <https://blog.csdn.net/yhb1047818384/article/details/103329324>`__

1. SMMU根据寄存器配置的STRTAB_BASE地址找到STE， STRTAB_BASE定义了STE的基地值， Stream id定义了STE的偏移。
2. STE指明了CD数据结构在DDR中的基地址S1ContextPTR, SSID(substream id)指明了CD数据结构的偏移，
3. cd表中信息包含memory属性，翻译控制信息，异常控制信息以及Page table walk(PTW)的起始地址TTB0, TTB1， 找到TTBx后，就可以PTW了。

.. figure:: /images/smmu_ste_cd.png
   :scale: 100%

   smmu_ste_cd




.. figure:: /images/stream_table_entry.png
   :scale: 80%

   stream_table_entry




.. figure:: /images/smmu_context_descriptor.png
   :scale: 80%

   smmu_context_descriptor




Linux SMMU 软件驱动
====================




.. figure:: /images/software_smmu_driver.png
   :scale: 100%

   software_smmu_driver



0. SMMU处于IO设备和总线之间，负责将设备的输入IOVA转化为系统总线的物理地址PA; 
1. SMMU硬件包含configuration lookup/TLB/Page Table Walk以及cmdq/eventq等部分，其中configuration lookup部分查找stream id所对应的配置（ste/cd）, 最终指向page table基地址等；
2. SMMU通过configuration lookup找到设备的配置及页表基地址等，然后查询TLB中是否存在输入地址input的映射，如果TLB命中，直接返回输出PA；若TLB没有命中，PTW模块逐级查询页表，找到页表中的映射，输出PA；
3. 软件/SMMU驱动通过CMDQ/EVENTQ进行交互，驱动通过CMDQ发送命令给SMMU硬件（如TLBI/SYNC等）；
4. SMMU硬件通过EVENTQ通知驱动有事件需要处理（如设备缺页等） 软件/驱动建立和维护内存中的配置和页表；


smmu设备分配
------------------
1. `IOMMU/SMMUV3代码分析（1）SMMU设备的分配_acpi iort_linux解码者的博客-CSDN博客  <https://blog.csdn.net/flyingnosky/article/details/122442735>`__


1. SMMUV3驱动以platform device驱动加载，而SMMU设备为platform device，匹配时会触发驱动的probe函数
2. SMMU设备在IORT表中被定义，它定义了SMMU设备的资源、特性以及SPI中断等。


::

   acpi_iort_init -> acpi_get_table    //获取iort表
                  -> iort_init_platform_devices // 根据iort表初始化platform设备
                                             -> ops=iort_get_dev_cfg   //获取dev cfg
                                             -> fwnode=acpi_allocl_fwnode_static //分配fwnode_handle
                                             -> iort_set_fwnode(iort_node,fwnode) 
                                             -> iort_add_platform_device(iort_node,ops) //分配并设置paltform device


         
.. figure:: /images/iort_add_platform_device.png
   :scale: 80%

   iort_add_platform_device


smmu驱动初始化
----------------
1. `IOMMU/SMMUV3代码分析（2）SMMUV3驱动初始化1_smmu驱动_linux解码者的博客-CSDN博客  <https://blog.csdn.net/flyingnosky/article/details/122463386>`__

         
.. figure:: /images/arm_smmu_device_probe.png
   :scale: 80%

   arm_smmu_device_probe

程序运行过程中打开mmu
------------------------
1. 提前对要执行的代码段建立页表(虚实相等的一一映射)
2. 正常建立页表，利用mmu sync abort返回到预先设置的虚地址处继续执行。

::

      ldr    x30, =mmu_on_addr   //设置返回地址(为虚拟地址，即为开启mmu后一条指令的虚地址)
      msr    SCTLR_EL1, x0       //开启MMU
      isb                        //MMU找不到这个地址，跳到异常sync abort 处理函数

   mmu_on_addr :
   ....

   vector_entry sync_exception_sp_elx  //异常处理函数返回到x30的地址，继续之星
      ret

The Translation Lookaside Buffer (TLB) is a cache of recently accessed page translations in the MMU. 


iommu框架
---------------


MMU-700 硬件架构
=================
1. :download:`corelink_mmu700_system_memory_management_unit_technical_reference_manual </files/arm/corelink_mmu700_system_memory_management_unit_technical_reference_manual_101542_0001_04_en.pdf>`
    The MMU-700 is a System-level Memory Management Unit (SMMU) 
2. `ARM系列 -- MMU-700 - 极术社区 - 连接开发者与智能计算生态  <https://aijishu.com/a/1060000000318128>`__

.. figure:: /images/armv8_mmu700.png
   :scale: 70%

   armv8_mmu700

1. TBU：translation buffer unit,包含tlb单元，缓存页表。可以有多个。
2. TCU: translation control unit,控制、管理地址翻译。一个mmu700仅一个tcu。
3. DTI: distributed traslation interface,amba协议，tbu和tcu之间的通信协议。


TBU
-------
1. ACE‑Lite TBU:For the TBS and TBM interfaces.
2. Local Translation Interface (LTI) TBU:For the LTI( point-to-point protocol between an I/O device and the TLBU).


::

   TBU内部的模块包括：

   Master and slave接口模块，上面已经讲过了
   Micro TLB，提供从输入地址到输出地址的端到端转换
   Main TLB，缓存TLB条目
   Translation manager，管理控制地址转换请求
   PMU，记录性能相关的事件数量
   Clock and power control，控制TBU的电源和时钟
   DTI接口模块
   Transaction tracker，管理超发（outstanding）的读/写事务


.. figure:: /images/arm_mmu700_tbu_ace-lite.png
   :scale: 100%

   arm_mmu700_tbu



.. figure:: /images/arm_mmu700_tbu_lti.png
   :scale: 100%

   arm_mmu700_tbu


TCU
-------

- Manages the memory queues
- Performs translation table walks
- Performs configuration table walks
- Implements backup caching structures
- Implements the SMMU programmers model


::

   TCU内部的模块包括：

   Walk cache，可配置bank和way的组相联缓存，记录translation table walks（不知道怎么翻译了）的结果
   Configuration cache，4路组相联的缓存，用于存储配置信息
   Translation manager，管理正在进行中的地址转换请求
   Translation request buffer，当Translation manager填满时，这个buffer存储来自TBU的地址转换请求，可防止请求过多导致DTI接口被阻塞
   PMU，记录性能相关的事件数量
   Clock and power control，电源和时钟管理
   Queue manager，管理SMMU的队列
   QTW/DVM interface
   Register file，SMMU的内部寄存器
   DTI interface，与DTI相连接


.. figure:: /images/arm_mmu700_tcu.png
   :scale: 100%

   arm_mmu700_tcu



tlb
--------
translation lookaside buffer


micro tlb main tlb
~~~~~~~~~~~~~~~~~~~~~
`ARM Cortex-A53 MPCore Processor Technical Reference Manual r0p3  <https://developer.arm.com/documentation/ddi0500/e/memory-management-unit/about-the-mmu>`__

The TBU compares incoming transactions with translations that are cached in the micro TLB before looking in the Main TLB (MTLB). 

1. micro tlb:全相联，data和instruction各一个。作为main tlb的cache。
2. main tlb：一般是多路组相联。

