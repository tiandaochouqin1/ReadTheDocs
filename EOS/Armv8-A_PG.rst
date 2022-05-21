
============
Armv8-a PG
============

:Date:   2022-03-23 00:57:00


Fundamentals of Armv8
==========================

参考手册
------------

1. arm-pg `Cortex-A Series Programmer's Guide for ARMv8-A <https://developer.arm.com/documentation/den0024/a>`__

   :download:`ARMv8-A-Programmer-Guide <../files/arm/ARMv8-A-Programmer-Guide.pdf>`




异常级别EL
-----------
1. `ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/Fundamentals-of-ARMv8>`__


Exception Level

.. figure:: ../images/aarch64_exception_levels_2.png

    aarch64_exception_levels_2



1. 提高EL即提高软件的执行特权；
2. 异常exception需要在更高的EL下处理，故EL0下不能处理异常；
3. ERET 从异常返回，但不能返回到更高的EL；
4. 只有EL3返回时才能实现安全态和非安全态切换。

各级别EL的含义：

1. EL0： 就是用户空间，在Noraml world中比如运行的应用程序，在Secure world就是TA，Trust Application
2. EL1：运行操作系统，Noramal World比如Linux操作系统，或者WInce操作系统。在Secure World则就是Trusted OS，比如高通的QSEE, 开源的OP-TEE，豌豆荚的TEE等
3. EL2：ARM为了支持虚拟化，设计的Hypervisor层，只有在Noraml world使用。
4. EL3：Secure Moniter的作用是用于Noraml world和Secure world切换使用。当noraml world想要访问Secure world需要发送SMC指令进入Secure Moniter层，然后进入到Secure world

执行状态execution stat
-----------------------

1. aarch64状态： A64指令集，64位general-purpose registers，trusted OS在EL1;
2. aarch32状态： A32指令集，32位，trusted OS在EL3。


.. figure:: ../images/mov_betw_aarch64_aarch32.png

    mov_betw_aarch64_aarch32




ARM内存管理与cache
========================

cache shareable domain
---------------------------
1. `(Cacheable and shareable memory attributes) ARM Cortex-A Series Programmer's Guide for ARMv8-A <https://developer.arm.com/documentation/den0024/a/Memory-Ordering/Memory-attributes/Cacheable-and-shareable-memory-attributes>`__
2. `有关Non-cacheable,,Cacheable, non-shareable,inner-shareable,outer-shareable的理解  <https://blog.csdn.net/weixin_42135087/article/details/121117593>`__
3. `(Cache coherency) ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/Multi-core-processors/Cache-coherency?lang=en>`__


``Memory caching`` can be separately controlled through inner and outer attributes, for multiple levels of cache. 

.. figure:: ../images/Cache_Sharable_Domain.png
   
   Cache_Sharable_Domain



共享域（shareability domains.），包含以下几种：

1. Inner shareable，意味着它适用于整个内部可共享域。这表示该domain内的处理器之间可以相互share数据。一个系统可以有多个inner shareable domains，并且当某个操作影响到其中一个inner shareable domain时，它并不会影响到其它的inner shareable domain。
2. Outer shareable，意味着它适用于内部可共享和外部可共享域。一个outer shareable domain可以由一个或多个inner shareable domain组成，并且当一个操作影响到outer shareable domain时，也会影响到其下所有的inner shareable domain。
3. Non-shareable，表示相关区域只能给指定的处理器访问。
4. Full System，包含全部处理器。

MESI cache一致性协议
---------------------
1. `并发研究之CPU缓存一致性协议(MESI) - 枫飘雪落 - 博客园  <https://www.cnblogs.com/yanlong300/p/8986041.html>`__




Arm address space
-------------------
1. `(Address-spaces) Learn the architecture: AArch64 memory management  <https://developer.arm.com/documentation/101811/0102/Address-spaces?lang=en>`__
2. `(Stage 2 translation) Learn the architecture: AArch64 Virtualization  <https://developer.arm.com/documentation/102142/0100/Stage-2-translation#:~:text=The%20address%20space%20that%20the,Physical%20Address%20(IPA)%20space.>`__

Memory Layout
~~~~~~~~~~~~~~~~~
1. `Memory Layout on AArch64 Linux — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/arm64/memory.html>`__


arm64上linux进程用户地址空间和内核地址空间都是256TB.
Linux内核会配置使用TTBR0和TTBR1寄存器，TTBR0存放用户pgd的基址，TTBR1存放内核pgd的基址.
MMU根据传入的虚拟地址来选择使用TTBR0还是TTBR1寄存器。

::

   User addresses have bits 63:48 set to 0 while the kernel addresses have the same bits set to 1. 
   TTBRx selection is given by bit 63 of the virtual address.
   
    The swapper_pg_dir contains only kernel (global) mappings while the user pgd contains only user (non-global) mappings. 
    The swapper_pg_dir address is written to TTBR1 and never written to TTBR0.

   AArch64 Linux memory layout with 4KB pages + 4 levels (48-bit):(armv8.2支持64K Pages，故共52bits)

    Start                 End                     Size            Use
    -----------------------------------------------------------------------
    0000000000000000      0000ffffffffffff         256TB          user
    ffff000000000000      ffff7fffffffffff         128TB          kernel logical memory map
   [ffff600000000000      ffff7fffffffffff]         32TB          [kasan shadow region]
    ffff800000000000      ffff800007ffffff         128MB          bpf jit region
    ffff800008000000      ffff80000fffffff         128MB          modules
    ffff800010000000      fffffbffefffffff         124TB          vmalloc
    fffffbfff0000000      fffffbfffdffffff         224MB          fixed mappings (top down)
    fffffbfffe000000      fffffbfffe7fffff           8MB          [guard region]
    fffffbfffe800000      fffffbffff7fffff          16MB          PCI I/O space
    fffffbffff800000      fffffbffffffffff           8MB          [guard region]
    fffffc0000000000      fffffdffffffffff           2TB          vmemmap
    fffffe0000000000      ffffffffffffffff           2TB          [guard region]

2 stages
~~~~~~~~~~~
.. figure:: ../images/Address_spaces_in_Armv8-A.jpg
   
   Address_spaces_in_Armv8-A

.. figure:: ../images/va-to-ipa-to-pa-address-translation.jpg
   
   va-to-ipa-to-pa-address-translation


1. Stage 1 translation: OS，通过traslation table将虚拟地址空间转换为IPA(Intermediate Physical Address Space)。
2. Stage 2 translation: hyperviosr控制对应vm级别可使用的内存。ensure that a VM can only see the resources that are allocated to it

vmid和ASID
~~~~~~~~~~~~~~~
VMID与VM关联，ASID与Appliation关联。

TLB entries can also be tagged with an Address Space Identifier (ASID). 
An application is assigned an ASID by the OS, and all the TLB entries in that application are tagged with that ASID.

Each VM is assigned a virtual machine identifier (VMID). 
The VMID is used to tag translation lookaside buffer (TLB) entries, to identify which VM each entry belongs to. 


Memory Order & Barrier
==========================
Memory Order
--------------
1. `ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/Memory-Ordering>`__
2. ★ `Memory Model and Synchronization Primitive - Part 1: Memory Barrier - Alibaba Cloud Community  <https://www.alibabacloud.com/blog/memory-model-and-synchronization-primitive---part-1-memory-barrier_597460>`__
3. x86 cpu重排"无依赖"指令  `Memory Reordering Caught in the Act  <https://preshing.com/20120515/memory-reordering-caught-in-the-act/>`__


乱序可能出现的场景：

多核、直接load/write 将要执行的命令、操作页表。

if your code interacts directly either with the hardware or with code executing on other cores, 
or if it directly loads or writes instructions to be executed, 
or modifies page tables, you need to be aware of memory ordering issues.

在armv8中, 由于processor的预取, 流水线,  以及多线程并行的执行方式, 而且armv8-a中, 使用的是一种weakly-ordered memory model, 不保证program order和execute order一致。

armv8涉及到的优化包括：

1) multiple issue of instructions, 超流水线技术, 每个cycle, 都会有多个issue和execute, 保证不了各个指令的执行order。

2) ☆ out-of-order execution, 很多processor都会对non-dependent的指令, 做out-of-order的执行, 

3) Speculation, 分组预测, 在遇到conditional instruction时, 判断condition之前, 就会执行之后的instruction。

4) Speculative loads, 预取, 在执行上一条指令的同时, 将下一条指令的数据, 预取到cache中。

5) Load and Store optimizations, 由于写主存的latency很大, processor可以做很多优化, write-merge, write-buffer等。

6) External memory systems, 某些外部device, 像DRAM, 可以同时接受不同master的req, Transaction可能会被buffered, reordered。

7) ☆ Cache coherent multi-core, 一个cluster中的各个core, 对同一个cache的update, 看到的顺序不会是一致的。 因为cache无法实时update。

8) Optimizing compilers, 编译器在编译时的性能优化, 可能打乱program order。使用 ``asm volatile("" ::: "memory");`` 避免。

 
memory types
~~~~~~~~~~~~~~~~~
armv8支持的memory types：Normal memory和Device memory

1. Normal memory, 主要指RAM, ROM, FLASH等memory, 这类memory, processor以及compiler都可以对program做优化, 

2. Device memory, 通常都是peripheral对应的memory mapped。对于该memory type, processor的约束会很多；

1) write的次数, processor内部必须与program中的相同；

2) 不能将两次的writes, reads, 等效为一个；

3) 但是对于不同的device之间的memory access是不限制order的；

4) speculative是不允许的, 对device的memory；

5) 在device memory中execute, 也是不允许的；

强弱序内存模型
~~~~~~~~~~~~~~~~~
1. `CPU memory model  <http://bajamircea.github.io/coding/cpp/2019/10/25/cpu-memory-model.html>`__
2. `Memory ordering - Wikiwand  <https://www.wikiwand.com/en/Memory_ordering>`__


- Armv8为弱内存序模型，this means that the order of memory accesses is not required to be the same as the program order for load and store operations.

- x86为强内存序模型，其Write Buffer为FIFO。仅可能有reads can be reordered ahead of other writes。




.. figure:: ../images/Memory_Ordering_Arch.png
   
   Memory_Ordering_Arch



ARM内存屏障
-----------
1. arm-asm 3.37
2. https://developer.arm.com/documentation/dui0489/c/CIHGHHIE
3. https://www.cse.unsw.edu.au/~cs9242/16/lectures/04-smp_locking.pdf



由于一些 **编译器优化或者CPU设计的流水线乱序执行** ，导致最终内存的访问顺序可能和代码中的逻辑顺序不符，所以需要增加内存屏障指令来保证顺序性。

ARM平台上存在三种内存屏障指令：

1. DMB{cond} {option}：数据内存屏障。只作用于 `显式内存访问指令`，保证dmb前的显式内存访问指令先执行完。
   
   all explicit memory accesses that appear in program order before the DMB instruction are observed before any explicit memory accesses that appear in program order after the DMB instruction. 
   
   只影响内存访问指令的顺序，保证在此指令前的内存访问完成后才执行后面的内存访问指令。

2. DSB{cond} {option}：数据同步屏障。一种特殊的dmb，作用于所有指令，保证dsb之前的指令执行完之后才执行dsb之后的指令。
   
   No instruction in program order after this instruction executes until this instruction completes.

   dsb指令完成的条件包括：All Cache, Branch predictor and TLB maintenance operations before this instruction complete.

   ``比DMB更加严格``，保证在此指令前的 `内存访问/cache操作/TLB维护/分支预测指令` 都完成，然后才会执行后面的所有指令。

3. ISB{cond} {option}：指令同步屏障。清空cpu流水线。
   
   flushes the pipeline in the processor, so that all instructions following the ISB are fetched from cache or memory, after the instruction has been completed
   
   ensures that the effects of context altering operations executed before the ISB instruction are visible to the instructions fetched after the ISB.

   最为严格的一种，冲洗流水线和预取buffer，然后才会从cache或者内存中预取ISB后面的指令。保证上下文切换指令对isb后可见。

   
option的选择：

1. SY：完整的指令操作
2. ST：只等待store操作完成，就继续执行
3. ISH：该操作只针对inner shareable domain生效
4. ISHST：ISH+ST
5. NSH:该操作只针对outer to unification生效
6. NSHST：NSH+ST
7. OSH：该操作只针对outer shareable domain生效
8. OSHST：OSH+ST



   
context altering operations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ensures that the effects of context altering operations, 
such as changing the ASID,
or completed TLB maintenance operations, 
or branch predictor maintenance operations, 
as well as all changes to the CP15 registers,
executed before the ISB instruction are visible to the instructions fetched after the ISB.


Linux内核实现
~~~~~~~~~~~~~~

arch/arm/include/asm/barrier.h
::

   #if __LINUX_ARM_ARCH__ >= 7
   #define isb(option) __asm__ __volatile__ ("isb " #option : : : "memory")
   #define dsb(option) __asm__ __volatile__ ("dsb " #option : : : "memory")
   #define dmb(option) __asm__ __volatile__ ("dmb " #option : : : "memory"



   #ifdef CONFIG_ARCH_HAS_BARRIERS
   #include <mach/barriers.h>
   #elif defined(CONFIG_ARM_DMA_MEM_BUFFERABLE) || defined(CONFIG_SMP)
   #define mb()		do { dsb(); outer_sync(); } while (0)
   #define rmb()		dsb()
   #define wmb()		do { dsb(st); outer_sync(); } while (0)
   #define dma_rmb()	dmb(osh)
   #define dma_wmb()	dmb(oshst)


由上面的宏定义可知，对于指令限制的严格程度：

::

   mb()>rmb()>wmb()>smb_mb()=smb_rmb()>smb_wmb()

smp相关的内存屏障都加入了ish选项，也就是限制指令只针对inner shareable domain。

单向内存屏障
~~~~~~~~~~~~~
1. `Arm64内存屏障_Roland_Sun的博客-CSDN博客_arm 内存屏障  <https://blog.csdn.net/Roland_Sun/article/details/107468055>`__


ARMv8.1还提供了带Load-Acquire或Store-Release单向内存屏障语义的指令。

1. Load-Acquire：这条指令 ``之后的所有加载和存储操作一定不会被重排序到这条指令之前``；
2. Store-Release：这条指令 ``之前`` 的所有加载和存储才做一定不会被重排序到这条指令之后；
3. 数据内存屏障 ``DMB = Load-Acquire + Store-Release``

指令形式：

1. Store-Release：基本指令后面加上L；
2. Load-Acquire：基本指令后面加上A；

arm mmu
------------------
1. arm mmu  `ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/The-Memory-Management-Unit>`__
2. `ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/The-Memory-Management-Unit/Translations-at-EL2-and-EL3>`__

enable the system to run multiple tasks, as independent programs running in their own private virtual memory space.

The Translation Lookaside Buffer (TLB) is a cache of recently accessed page translations in the MMU. 

The **hypervisor** must perform some extra translation steps in a two stage process to share the physical memory system between the different guest operating systems.

.. figure:: ../images/two_stage_translation_process.png

    two_stage_translation_process


SMMU
--------
1. `ARM SMMU的原理与IOMMU   <https://blog.51cto.com/u_15155099/2767161>`__
2. `ARM SMMU学习笔记_Hober_yao的博客-CSDN博客_smmu  <https://blog.csdn.net/yhb1047818384/article/details/103329324>`__
3. :download:`smmu v3 <../files/arm/ARM_IHI_0070_D_b_System_Memory_Management_Unit_Architecture_Specification.pdf>`

SMMU可以为ARM架构下实现虚拟化扩展提供支持。它可以和MMU一样，提供stage1转换（VA->IPA）, 或者stage2转换（IPA->PA）,或者stage1 + stage2转换（VA->IPA->PA）的灵活配置。

.. figure:: ../images/smmu.png

   System Memory Management Unit


1. DMA需要连续的地址.
2. 虚拟化： 在虚拟化场景， 所有的VM都运行在中间层hypervisor上，每一个VM独立运行自己的OS（guest OS）,Hypervisor完成硬件资源的共享, 隔离和切换。
    但guest VM使用的物理地址是GPA, 看到的内存并非实际的物理地址HPA，因此Guest OS无法正常的将连续的物理地址分给DMA硬件。

因此，为了支持I/O透传机制中的DMA设备传输，而引入了IOMMU技术（ARM称作SMMU）。

.. figure:: ../images/dma_smmu.png

   虚拟化+DMA -> SMMU




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

.. figure:: ../images/ATF_Scp.png

   ATF_Scp


ATF冷启动
-------------

.. figure:: ../images/ATF_Boot.png

   ATF_Boot



.. figure:: ../images/ATF_Cold_Boot.png

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