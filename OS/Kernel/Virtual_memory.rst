
虚拟内存管理
=============
.. important:: 虚拟内存与分页？缺页page fault ？



Linux内核内存管理的一项重要工作就是如何在频繁申请释放内存的情况下，避免碎片的产生。

Linux采用伙伴系统解决外部碎片的问题，采用slab解决内部碎片的问题。


缺页中断
------------
1. `Linux内核缺页中断处理 - 知乎  <https://zhuanlan.zhihu.com/p/488042885>`__
2. `Linux虚拟内存和缺页中断  <https://cloud.tencent.com/developer/article/1688625>`__


缺页本身是一种中断，与一般的中断处理步骤相同

区别：

1. 在指令执行期间产生和处理缺页中断信号

2. 一条指令在执行期间，可能产生多次缺页中断

3. 缺页中断返回是，执行产生中断的一条指令，而一般的中断返回是，执行下一条指令。


缺页中断详细处理流程：

.. figure:: /images/do_page_fault.jpg
   :scale: 100%

   do_page_fault


页
------------
MMU：内存管理单元，管理内存并将虚拟地址转换为物理地址的硬件。

MMU以页为单位进行处理，即虚拟内存中页即最小单位。处理器最小可寻址单位为字。

struct pages表示系统中的物理页，而不是虚拟页。
其目的是描述物理内存本身，而不是其中包含的数据。
描述当前时刻相关的物理页中存放的东西，该结构对页的描述只是短暂的。

分页与分段
~~~~~~~~~~~~~
1. `x86段寄存器和分段机制 - 知乎  <https://zhuanlan.zhihu.com/p/324210723>`__


1. x86 cpu才有分段机制，x86_64摒弃使用分段，arm没有分段。
2. Linux实际没有使用分段。

::

   段选择符:逻辑地址 --->  线性地址 ---> 物理地址
                     分段       分页

   x64或Linux中，逻辑地址=线性地址


分段作用：

1. 权限控制。 linux只使用了这个功能。
2. 划分物理内存为段，使os支持访问大于地址线对应的物理内存。linux使用分页+虚拟内存实现了该功能。


页目录要放在线性映射区，但页表却不一定。
`进程的页表和页目录存储在内核空间还是用户空间？低端内存还是高端内存_NewThinker_wei的博客-CSDN博客_页表存放在哪里  <https://blog.csdn.net/NewThinker_wei/article/details/42089707>`__

多级页表
~~~~~~~~~~~
如(PGD+PMD+PTE):

1. 可离散存储页表，利用碎片内存；
2. 页表管理粒度更小，可按需创建；
3. 增加了寻址次数。

区
------------
区的使用的分布和体系结构相关。由于硬件限制，有些页位于特定的物理地址上。

* ZONE_DMA：一些硬件只能用特定的地址来执行DMA；
* ZONE_NORMAL：包含能正常映射的页；
* ZONE_HIGHEM：其中的页不能永久映射到内核地址空间。由于内存的物理寻址范围远大于虚拟寻址范围，
  如x86内核虚拟地址为1G，X64则不存在这个区。


高端内存的映射？


内存分配
-------------

1. 连续物理页： 低级页分配器或kmalloc。
2. 高端内存： alloc_pages()，返回指向pages结构的指针，而不是逻辑地址的指针（高端内存可能并没有被映射到逻辑地址）。使用kmap映射。
3. 连续虚拟地址： vmalloc，相比kmalloc有一定性能损失。
4. 大量数据结构： ``slab高速缓存``。



低级页分配
~~~~~~~~~~~~~~
1. alloc_pages：以页为单位分配内存，分配连续的物理页。

2. page_address：将获得的页转换成它的逻辑地址。

3. __get_free_pages ：返回第一个页的逻辑地址。

4. get_zero_page：填充0。



kmalloc
~~~~~~~~~~~~~~
kmalloc与用户空间的malloc函数类似，以字节为单位获取内核内存。分配的内存在物理上连续。

kfree：释放kmalloc分配的内存。


gfp_mask分配器标志
^^^^^^^^^^^^^^^^^^^^^^^
三类标志：

* 行为修饰符：表示如何分配内存，如是否允许睡眠。
* 区修饰符：表示从哪个区分配。
* 类型标志：组合行为修饰符和区修饰符。


**常用的标志**

1. GFP_KERNEL：这种分配可能引起睡眠，普通优先级。可能阻塞，只能用在可以重新安全调度的进程上下文中（不持有锁时）。
2. GFP_ATOMIC：不能睡眠的内存分配。分配成功可能性较小。用于中断处理程序、软中断、tasklet等。


vmalloc
~~~~~~~~~~~~~~
vmalloc分配虚拟地址连续的内存，物理内存则无需连续，可能睡眠。（与用户空间的malloc类似）

大多数情况下，只有硬件设备需要物理地址连续的内存。一般在获取大块内存时使用，如插入内核模块时。

为了将物理上不连续的页转换为虚拟地址中连续的页，需要专门建立页表项，将获得的页一一映射。性能低，会导致比直接内存映射大得多的TLB抖动。

栈上的静态分配
~~~~~~~~~~~~~~~
进程内核栈目前（>=2.6.37）为两页。历史上可为一页或两页。

用户空间栈大小为8M（ulimit -a）。



percpu数据
~~~~~~~~~~~~~~~
创建一个变量，然后每个 CPU 上都会有一个此变量的拷贝。

需要禁止内核抢占。

1. 减少数据锁定，不需要锁；
2. 较少缓存失效。

`静态和动态per-CPU变量 <https://blog.csdn.net/longwang155069/article/details/52033243>`__



伙伴系统
------------
1. `Linux伙伴系统(一)--伙伴系统的概述_橙色逆流的博客-CSDN博客_伙伴系统  <https://blog.csdn.net/vanbreaker/article/details/7605367>`__

struct zone中的struct free_area则是用来描述该管理区伙伴系统的空闲内存块

::

   struct zone {
      ...
      struct free_area	free_area[MAX_ORDER]; // 分配的内存大小为 2^0 ~ 2^(MAX_ORDER-1) 个页
      ...
   }

   struct free_area {
      struct list_head	free_list[MIGRATE_TYPES]; // 隔离Non-movable/reclainmable/movalbe pages，减少碎片。双向链表
      unsigned long		nr_free;                  // 该free_area中总共的空闲内存块的数量
   };


.. figure:: /images/mem_zone.jpg
   :scale: 30%

   zone和伙伴系统

   

slab分配器
---------------------
1. `图解slub  <http://www.wowotech.net/memory_management/426.html>`__

.. figure:: /images/mem_manage.png
   :scale: 30%

   内存管理


1. 伙伴系统：物理页帧的管理。负责多页组成的连续内存块的拆分与合并。
2. slab分配器：处理小块内存的分配，并提供用户层malloc的内核等价物。在伙伴系统之上。允许分配任意用途的小内存，还可以对常用数据结构创建缓存。

3. slab, slub和slob仅仅是分配内存策略不同。有时候用slab来统称slab, slub和slob。


slab层把不同的对象划分为高速缓存组，每个高速缓存组存放不同类型的对象（task_struct、inode）。slab由一个或多个物理连续的页组成。


kmalloc建立而在slab层之上，对应一组高速缓存组。slab状态：满、部分满和空。

1. kmem_cache_creat：创建高速缓存。

2. kmem_cache_alloc：从高速缓存分配结构。

slub cache
---------------
`图解slub  <http://www.wowotech.net/memory_management/426.html>`__
