
============
Armv8-a PG
============

:Date:   2022-03-23 00:57:00


Fundamentals of Armv8
==========================

参考手册
------------

1. ☆ 两百多页，先看完这个再说 arm-pg `Cortex-A Series Programmer's Guide for ARMv8-A <https://developer.arm.com/documentation/den0024/a>`__

   :download:`ARMv8-A-Programmer-Guide </files/arm/ARMv8-A-Programmer-Guide.pdf>`

2. ☆☆ 很好，部分收费 `[目录]-博客笔记导读目录(全部)_代码改变世界ctw的博客-CSDN博客  <https://blog.csdn.net/weixin_42135087/article/details/107037145>`__
    `付费专栏-付费课程-【购买须知】 - 非广告_代码改变世界ctw的博客-CSDN博客_csdn付费专栏  <https://blog.csdn.net/weixin_42135087/article/details/124890300>`__

3. 单篇介绍各个概念的短文,基本都是2020年以后发布的 `Documentation – Arm Developer  <https://developer.arm.com/documentation/#&cf[navigationhierarchiesproducts]=%20Architectures,Learn%20the%20architecture>`__

4. ☆ `《TrustZone for Armv8-A》阅读笔记 - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/13993375.html>`__

To Learn
~~~~~~~~~~~~~~~
1. `Learn the architecture - TrustZone for AArch64  <https://developer.arm.com/documentation/102418/0101/TrustZone-in-the-processor>`__
2. `Learn the architecture - AArch64 memory management  <https://developer.arm.com/documentation/101811/0102/The-Memory-Management-Unit--MMU-?lang=en>`__


异常级别EL
-----------
1. `ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/Fundamentals-of-ARMv8>`__


Exception Level

.. figure:: /images/aarch64_exception_levels_2.png
   :scale: 60%

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


.. figure:: /images/mov_betw_aarch64_aarch32.png
   :scale: 60%

   mov_betw_aarch64_aarch32




ARM内存管理与cache
========================

cache shareable domain
---------------------------
1. `(Cacheable and shareable memory attributes) ARM Cortex-A Series Programmer's Guide for ARMv8-A <https://developer.arm.com/documentation/den0024/a/Memory-Ordering/Memory-attributes/Cacheable-and-shareable-memory-attributes>`__
2. `有关Non-cacheable,,Cacheable, non-shareable,inner-shareable,outer-shareable的理解  <https://blog.csdn.net/weixin_42135087/article/details/121117593>`__
3. `(Cache coherency) ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/Multi-core-processors/Cache-coherency?lang=en>`__


``Memory caching`` can be separately controlled through inner and outer attributes, for multiple levels of cache. 

.. figure:: /images/Cache_Sharable_Domain.png
   :scale: 50%
   
   Cache_Sharable_Domain



共享域（shareability domains.），包含以下几种：

1. Inner shareable，意味着它适用于整个内部可共享域。这表示该domain内的处理器之间可以相互share数据。一个系统可以有多个inner shareable domains，并且当某个操作影响到其中一个inner shareable domain时，它并不会影响到其它的inner shareable domain。
2. Outer shareable，意味着它适用于内部可共享和外部可共享域。一个outer shareable domain可以由一个或多个inner shareable domain组成，并且当一个操作影响到outer shareable domain时，也会影响到其下所有的inner shareable domain。
3. Non-shareable，表示相关区域只能给指定的处理器访问。
4. Full System，包含全部处理器。

MESI cache一致性协议
---------------------
1. `并发研究之CPU缓存一致性协议(MESI) - 枫飘雪落 - 博客园  <https://www.cnblogs.com/yanlong300/p/8986041.html>`__
2. `高速缓存一致性协议MESI与内存屏障 - 小熊餐馆 - 博客园  <https://www.cnblogs.com/xiaoxiongcanguan/p/13184801.html#_label1_0>`__
3. `arm64 cache机制分析  <https://mp.weixin.qq.com/s/NlWvs_fjWSSvW2S1FcpgkQ>`__


跟踪cache行的状态，ARM采用MESI协议.


MESI协议依赖 **总线侦听** 机制，在某个核心发生本地写事件时，
为了保证全局只能有一份缓存数据，要求其它核对应的缓存行统统设置为 **Invalid** 无效状态。

为了确保总线写事务的强一致性，发生本地写的高速缓存需要等到远端的所有核心都处理完对应的失效缓存行，
返回Ack确认消息后才能继续执行下面的内存寻址指令(阻塞)。

MESI协议的名字来源于cache line的四个状态：

1. Modified（M）：cache line数据有效，cache line数据被修改，与内存中的数据不一致，修改的数据只存在本cache中；
2. Exclusive（E）：cache line数据有效，cache line数据和内存中一致，数据只存在本cache中；
3. Shared（S）：cache line数据有效，cache line数据和内存中一致，数据存在于多个cache中；
4. Invalid（I）：cache line数据无效；


Memory Layout
----------------
1. `Memory Layout on AArch64 Linux — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/arm64/memory.html>`__
2. `(Address-spaces) Learn the architecture: AArch64 memory management  <https://developer.arm.com/documentation/101811/0102/Address-spaces?lang=en>`__


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




.. figure:: /images/Memory_Ordering_Arch.png
   
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
2. `Learn the architecture - Memory Systems, Ordering, and Barriers  <https://developer.arm.com/documentation/102336/0100/Load-Acquire-and-Store-Release-instructions?lang=en>`__



ARMv8.1还提供了带Load-Acquire或Store-Release单向内存屏障语义的指令。

1. Load-Acquire：这条指令 ``之后的所有加载和存储操作一定不会被重排序到这条指令之前``；
2. Store-Release：这条指令 ``之前`` 的所有加载和存储才做一定不会被重排序到这条指令之后；
3. 数据内存屏障 ``DMB = Load-Acquire + Store-Release`` ,可用于保护临界区代码

指令形式：

1. Store-Release：基本指令后面加上L；LDAR
2. Load-Acquire：基本指令后面加上A；STLR


.. figure:: /images/LDAR_STLR.png
   :scale: 60%

   LDAR_STLR





amba
===========
1. `Learn the architecture - An introduction to AMBA AXI  <https://developer.arm.com/documentation/102202/0300/What-is-AMBA--and-why-use-it-?lang=en>`__


.. figure:: /images/amba.png

   amba


axi
------
1. `Learn the architecture - An introduction to AMBA AXI  <https://developer.arm.com/documentation/102202/0300/AXI-protocol-overview?lang=en>`__

Advanced eXtensible Interface


axi定义了ip核的接口，而不是互联模块

.. figure:: /images/axi_components.jpg
   :scale: 80%

   axi_components


两种axi接口: manager和subordinate。所有互联均由这两个接口连接

.. figure:: /images/axi_interconnect.jpg

   axi_interconnect

   
.. figure:: /images/axi_channels.jpg

   axi_channels


特点:

1. 通道读写分离
2. 支持多个未决地址(并行)
3. 寻址和数据握作不需要严格
4. 支持非对齐数据传输(transfer)
5. 支持事务乱序(transaction)
6. Burst transactions based on start address:


1. A **transfer** is a single exchange of information, with one VALID and READY handshake.
2. A **transaction** is an entire burst of transfers, containing an address transfer, one or more data transfers, and, for write sequences, a response transfer.


.. figure:: /images/axi_write_transaction.jpg
   :scale: 50%

   axi_write_transaction


chi
----
1. `Learn the architecture - Introducing AMBA CHI  <https://developer.arm.com/documentation/102407/0100/Introduction-to-CHI?lang=en>`__
2. `ARM系列 -- CHI（一）` <https://mp.weixin.qq.com/s/FAluxBZac4V1TNyWETdOHQ>`__

Coherent Hub Interface (CHI) is an evolution of the AXI Coherency Extensions (ACE) protocol. 

CHI接口和ACE、AXI完全不一样：

- 独立分层实现：协议层、网络层、链路层
- 基于包传输
- CHI在写一次规定了各种transactioni；在网络层定义了packet；具体的信号在链路层

.. figure:: /images/chi_protocol.png
   :scale: 110%

   chi_protocol


三种拓扑：

.. figure:: /images/chi_topologies.jpg
   :scale: 80%

   chi_topologies

cmn-600
~~~~~~~~~~~~~
1. `CMN总线简介_qq_29188181的博客-CSDN博客_cmn700总线  <https://blog.csdn.net/qq_29188181/article/details/126338069>`__


The Arm CoreLink CMN-600 Coherent Mesh Network is designed for intelligent connected systems across a wide range of applications 
  including networking infrastructure, storage, server, HPC, automotive, and industrial solutions.

AMBA 5 CHI

.. figure:: /images/corelink_cmn-600_scaleable_mesh_network.png
   :scale: 25%

   cmn-600


- HN-主节点，处理request
- RN-请求节点，产生request/transaction
- SN-normal memory从节点，处理请求
- XP:crosspoint，交换/路由模块



.. figure:: /images/CHI_Nodes.png
   :scale: 60%

   CHI_Nodes


Generic Timer
==================
1. `Learn the architecture - Generic Timer` <https://developer.arm.com/documentation/102379/0101/What-is-the-Generic-Timer-?lang=en>`__


generic timer属于核内部结构，rtc属于soc。

定时器框架包括两部分：a system counter + a set of per-core timers

1. system counter: 56-64 bitwidth,累加器，1G Hz，broadcast。软件可使用 system counter + timestamp 的值作为时间。
2. timer：comparator比较器，与systemcounter 比较，达到设定的值时产生interrupts(非ipi)或events。


.. figure:: /images/System-counter-block-diagram.png
   :scale: 100%

   System-counter-block-diagram


CoreSight
============
1. `Learn the architecture - Introducing CoreSight debug and trace` <https://developer.arm.com/documentation/102520/latest/>`__
2. `Learn the architecture - Debugger usage on Armv8-A` <https://developer.arm.com/documentation/102140/latest/>`__
3. `Learn the architecture - AArch64 self-hosted debug` <https://developer.arm.com/documentation/102120/0100/Introduction-to-debug>`__

external debug
-------------------


Micro-Architecture
====================
1. `Cortex-A77 - Microarchitectures - ARM - WikiChip  <https://en.wikichip.org/wiki/arm_holdings/microarchitectures/cortex-a77>`__
2. `从A76到A78——在变化中学习ARM微架构  <https://mp.weixin.qq.com/s/hFK3qDxXpgs2J1C7TlYYAQ>`__
    `Arm微架构之Armv9时代-电子工程专辑  <https://www.eet-china.com/mp/a193253.html>`__

3. `ARM 之十五 扫盲 ARM 架构、指令集、ARM IP、授权方式_arm架构_ZC·Shou的博客-CSDN博客  <https://blog.csdn.net/ZCShouCSDN/article/details/120351435>`__

概念
--------
1. ARM 架构：通常是指 ARM **指令集架构**，指定了处理器的行为方式.包括 指令集、寄存器组、异常模型、内存模型、 调试跟踪和分析。
2. 微架构：处理器的 **构建和设计**，介绍了特定处理器的工作方式。微架构就是对于 ARM 架构的进一步的实现。
3. ARM 系统架构定义了 **相关组件和接口**，使硬件和软件更容易进行互操作。

系统架构的整体框图如下图所示：

.. figure:: /images/arm_system_structure.png
   :scale: 70%

   arm_system_structure


A77微架构
-------------

.. figure:: /images/A77_microarchitecture.png
   :scale: 100%

   A77_microarchitecture


1. BPU 分支预测单元：与指令fetch单元独立。
2. 前端提供多路decoder。
3. ROB(ReOrder-Buffer)：128 entries，指令重排，以尽可能填满流水线。带有MOP cache。
   Instruction -> MOP(Macro-Operation) -> uOP(Micro-Operation,处理器执行的基础指令)

4. 执行单元(Exection Engine): Dispatch将uOP发射到执行单元(Issue，具有120 entries)，
   执行单元包括 整型(里面包括分支单元)、浮点和读写。A77将发射列队（issue queue）统一成三个，整型、浮点和读写发射列队。

5. LSU(Load Store Unit)设计：LSU模块和执行单元的2个AGU相连接，同时连接64KB的L1数据缓存（DCache），并提供2个16B/cycle的load端口和1个32B/cycle的store端口


