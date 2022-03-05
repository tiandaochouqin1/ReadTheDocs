=====================
Embeded OS
=====================

:Date:   2022-03-01 22:25:43

概念辨析
=========
核间中断IPI
------------


硬件线程也称之为逻辑核，将软件线程的任务分发在多个硬件线程上，通过负载均衡，可以分配在各个硬件线程之间。

设备 ——> IRQ线 ——> IPC控制器 <——> CPUs

多核cpu中，cpu核可通过ipc直接向目标cpu核发送中断信号，以使其执行特定操作——向ipc的IPI寄存器写入硬件线程ID、
中断向量、中断类型等，ipc则会通知目标cpu核挂起执行序列并跳转到isr。可使用共享内存进行核间通信。


NUMA
-------
非统一内存访问架构，Non-uniform memory access，简称NUMA。是一种为多处理器的电脑设计的内存架构。

在numa下，cpu访问本地内存比访问非本地内存/共享内存更快。（被共享的内存物理上是分布式的，所有这些内存的集合就是全局地址空间）

调度域
---------
1. `从CPU层次结构到调度域的建立  <https://arc.838281.xyz/archive/1646066823.474205/singlefile.html>`__

::

    调度范围： Threads   ->   Cores    ->  Clusters 
    共享：    所有Cache    LLC(一般为L3)    无


在numa中则还需要考虑内存访问速度，为了减少对内存总线的访问竞争，可以将CPU分属于不同的Node节点，通常情况下，CPU只访问Node内的memory。

isolcpu将cpu隔离到SMP调度域之外,并同时使用cpu亲和性，以保证进程的实时性。

在arm等大小核架构中，还需要考虑性能和功耗平衡。

cpud_idle
-----------
idle线程。节能+等待可调度线程。

https://elixir.bootlin.com/linux/v3.1.6/source/arch/x86/kernel/process_64.c#L109

::

    * The idle thread. There's no useful work to be
    * done, so just try to conserve power and have a
    * low exit latency (ie sit in a loop waiting for
    * somebody to say that they'd like to reschedule)



工具使用
==========
内存debug
----------

1. `KASAN实现原理  <http://www.wowotech.net/memory_management/424.html>`__
2. `SLUB DEBUG原理  <http://www.wowotech.net/memory_management/427.html>`__
3. `Linux内存管理 (22)内存检测技术(slub_debug/kmemleak/kasan) - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/8568090.html>`__
4. `【原创】（十一）Linux内存管理slub分配器 - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/11922887.html>`__

内存问题一般包括 内存越界（out-of-bounds）和访问已经释放的内存（use-after-free）；范围包括全局变量、栈、堆分配的内存。

内存检测工具
~~~~~~~~~~~~~~~
1. KASAN(KernelAddressSANitizer)，东内内存检测，功能全面。
2. SLUB DEBUG仅仅针对从slub分配器分配的内存。
3. kmemleak侧重于内存泄露问题发现。
4. `glibc提供的malloc()的调试工具 - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/10827884.html>`__ ：但是这几种技术检查的全面性都不够


KASAN
~~~~~~~~~
使用额外1/8的影子内存(shadow memory)来标记可用内存的属性。

编译时在memmory access(store/load)前插入__asan_load##size()或者__asan_store##size()函数调用（size是访问内存字节的数量），
以判断对应内存是否有效。

测试用例及分析：
kasan提供了一个测试程序test_kacan.c，将其编译成模块，加载到内核。可以模拟很多内存错误场景。
