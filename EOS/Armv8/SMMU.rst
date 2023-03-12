============
MMU和SMMU
============
1. :download:`Arm System Memory Management Unit Architecture Specification v3.3 </files/arm/ARM_IHI_0070_D_b_System_Memory_Management_Unit_Architecture_Specification.pdf>`




.. figure:: /images/smmu.png
   :scale: 60%

   System Memory Management Unit


arm mmu
============
1. arm mmu  `The-Memory-Management-Unit - PG   <https://developer.arm.com/documentation/den0024/a/The-Memory-Management-Unit>`__
2. `Translations-at-EL2-and-EL3 - PG <https://developer.arm.com/documentation/den0024/a/The-Memory-Management-Unit/Translations-at-EL2-and-EL3>`__
3. figuire 4-1 `Learn the architecture - AArch64 memory management  <https://developer.arm.com/documentation/101811/0102/The-Memory-Management-Unit--MMU-?lang=en>`__


.. figure:: /images/arm_mmu.png
   :scale: 60%

   arm_mmu



虚拟化
-------------
使系统可运行多任务，并且任务都是运行在独立的私有虚拟内存空间。

**hypervisor** 需要增加翻译步骤以在不同Guest OS间共享物理内存。

.. figure:: /images/two_stage_translation_process.png
   :scale: 50%

   two_stage_translation_process




2 stages
~~~~~~~~~~~~
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


SMMU
---------------
1. `ARM SMMU的原理与IOMMU   <https://blog.51cto.com/u_15155099/2767161>`__
2. 虚拟化和smmuv3 `ARMv8 Virtualization Overview · kernelgo  <https://kernelgo.org/armv8-virt-guide.html>`__

3. `ARM系列 -- SMMU（一） - 极术社区 - 连接开发者与智能计算生态  <https://aijishu.com/a/1060000000208280>`__



SMMU可以为ARM架构下实现虚拟化扩展提供支持。它可以和MMU一样，提供stage1转换（VA->IPA）, 或者stage2转换（IPA->PA）,或者stage1 + stage2转换（VA->IPA->PA）的灵活配置。


1. DMA需要连续的地址.
2. 虚拟化： 在虚拟化场景， 所有的VM都运行在中间层hypervisor上，每一个VM独立运行自己的OS（guest OS）,Hypervisor完成硬件资源的共享, 隔离和切换。
    但guest VM使用的物理地址是GPA, 看到的内存并非实际的物理地址HPA，因此Guest OS无法正常的将连续的物理地址分给DMA硬件。

因此，为了支持I/O透传机制中的DMA设备传输，而引入了IOMMU技术（ARM称作SMMU）。

.. figure:: /images/dma_smmu.png
   :scale: 80%

   虚拟化+DMA -> SMMU


smmu vs mmu
~~~~~~~~~~~~~~~~~~
.. important:: arm中smmu和mmu架构差异？

1. `SMMU跟TrustZone啥关系？ - 极术社区 - 连接开发者与智能计算生态  <https://aijishu.com/a/1060000000123590>`__
2. 没有区分mmu和smmu  `(Stage 2 translation) Learn the architecture: AArch64 Virtualization  <https://developer.arm.com/documentation/102142/0100/Stage-2-translation>`__


SMMU跟MMU非常相似，主要给其他Master来使用，连 **页表格式也是一样的**，只是编程方式不同，理论上可以让CPU的MMU和SMMU可以使用同一套页表。
增加SMMU后， **其他Master也相当于有了MMU的功能**。

2stages
~~~~~~~~~~~

.. figure:: /images/arm_smmu_2stage_translation.png
   :scale: 100%

   arm_smmu_2stage_tran



MMU-700
============
1. :download:`corelink_mmu700_system_memory_management_unit_technical_reference_manual </files/arm/corelink_mmu700_system_memory_management_unit_technical_reference_manual_101542_0001_04_en.pdf>`
    The MMU-700 is a System-level Memory Management Unit (SMMU) 

.. figure:: /images/armv8_mmu700.png
   :scale: 70%

   armv8_mmu700

1. TBU：translation buffer unit,包含tlb单元，缓存页表。可以有多个。
2. TCU: translation control unit,控制、管理地址翻译。一个mmu700仅一个tcu。
3. DTI: distributed traslation interface,amba协议，tbu和tcu之间的通信协议。


TBU
-------
1. ACE‑Lite TBU
2. Local Translation Interface (LTI) TBU


.. figure:: /images/arm_mmu700_tbu_ace-lite.png
   :scale: 100%

   arm_mmu700_tcu



.. figure:: /images/arm_mmu700_tbu_lti.png
   :scale: 100%

   arm_mmu700_tcu


TCU
-------

- Manages the memory queues
- Performs translation table walks
- Performs configuration table walks
- Implements backup caching structures
- Implements the SMMU programmers model

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



页表
========
1. `操作系统中的多级页表到底是为了解决什么问题？ - 知乎  <https://www.zhihu.com/question/63375062>`__
2.  ☆☆ `ARM SMMU学习笔记_Hober_yao的博客-CSDN博客_smmu  <https://blog.csdn.net/yhb1047818384/article/details/103329324>`__
3. `[mmu/cache]-ARM MMU/TLB的学习笔记和总结_arm tlb_代码改变世界ctw的博客-CSDN博客  <https://blog.csdn.net/weixin_42135087/article/details/109575691>`__

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



STE
-----------------------
.. figure:: /images/stream_table_entry.png
   :scale: 60%

   stream_table_entry

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


Linux mmu驱动
===============
SMMUV3驱动以platform device驱动加载，而SMMU设备为platform device

1. `IOMMU/SMMUV3代码分析（1）SMMU设备的分配_acpi iort_linux解码者的博客-CSDN博客  <https://blog.csdn.net/flyingnosky/article/details/122442735>`__
2. `IOMMU/SMMUV3代码分析（1）SMMU设备的分配_acpi iort_linux解码者的博客-CSDN博客  <https://blog.csdn.net/flyingnosky/article/details/122442735>`__




.. figure:: /images/software_smmu_driver.png
   :scale: 100%

   software_smmu_driver



0. SMMU处于IO设备和总线之间，负责将设备的输入IOVA转化为系统总线的物理地址PA; 
1. SMMU硬件包含configuration lookup/TLB/Page Table Walk以及cmdq/eventq等部分，其中configuration lookup部分查找stream id所对应的配置（ste/cd）, 最终指向page table基地址等；
2. SMMU通过configuration lookup找到设备的配置及页表基地址等，然后查询TLB中是否存在输入地址input的映射，如果TLB命中，直接返回输出PA；若TLB没有命中，PTW模块逐级查询页表，找到页表中的映射，输出PA；
3. 软件/SMMU驱动通过CMDQ/EVENTQ进行交互，驱动通过CMDQ发送命令给SMMU硬件（如TLBI/SYNC等）；
4. SMMU硬件通过EVENTQ通知驱动有事件需要处理（如设备缺页等） 软件/驱动建立和维护内存中的配置和页表；


smmu设备驱动
-------------
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


cache原理
==========
`Cache的基本原理 - 知乎  <https://zhuanlan.zhihu.com/p/102293437>`__

直接映射/组相联/全相联缓存、cache更新策略、