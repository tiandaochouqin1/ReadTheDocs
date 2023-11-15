==============
虚拟内存与进程
==============
.. important:: 虚拟内存与分页？缺页page fault ？







页与区
=========
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



页表
------------

使用三级页表将虚地址转换为物理地址：

1. PGD：页全局目录，顶级页表。
2. PMD：中间页目录，二级页表。
3. PTE：页表，指向物理页面向记录的文件系统：丰富、结构化的表示。


一般由硬件完成页表的搜索。操作和检索页表时必须使用page_table_lock锁（进程描述符内）。

TLB：translate lookaside buffer,翻译后缓冲器。虚拟地址到物理地址映射的硬件缓存。


多级页表
~~~~~~~~~~~
如(PGD+PMD+PTE):

1. 可离散存储页表，利用碎片内存；
2. 页表管理粒度更小，可按需创建；
3. 增加了寻址次数。


区Zone
------------
区的使用的分布和体系结构相关。由于硬件限制，有些页位于特定的物理地址上。

* ZONE_DMA：一些硬件只能用特定的地址来执行DMA；
* ZONE_NORMAL：包含能正常映射的页；
* ZONE_HIGHEM：其中的页不能永久映射到内核地址空间。由于内存的物理寻址范围远大于虚拟寻址范围，
  如x86内核虚拟地址为1G，X64则不存在这个区。


高端内存的映射？

虚拟内存管理
==============
内存分配方法
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


**zone->free_area** 描述该管理区伙伴系统的空闲内存块:

::

   struct zone {
      ...
      struct free_area	free_area[MAX_ORDER];    // 分配的内存大小为 2^0 ~ 2^(MAX_ORDER-1) 个页
      ...
   }

   struct free_area {
      struct list_head	free_list[MIGRATE_TYPES];   // 隔离Non-movable/reclainmable/movalbe pages，减少碎片。双向链表
      unsigned long		nr_free;                    // 该free_area中总共的空闲内存块的数量
   };


.. figure:: /images/mem_zone.jpg
   :scale: 30%

   zone和伙伴系统


分配与回收
~~~~~~~~~~~   

伙伴系统与slub
~~~~~~~~~~~~~~~~~~~
Linux采用伙伴系统解决外部碎片的问题，采用slab解决内部碎片的问题。

1. 伙伴系统：物理页帧。负责多页组成的连续内存块的拆分与合并。
2. slab分配器：处理小块内存的分配，并提供用户层malloc的内核等价物。在伙伴系统之上。允许分配任意用途的小内存，还可以对常用数据结构创建缓存。

slab分配器
---------------------
1. `图解slub  <http://www.wowotech.net/memory_management/426.html>`__
2. `Linux Slob分配器(一)--概述-CSDN博客  <https://blog.csdn.net/peijian1998/article/details/30040139>`__

.. figure:: /images/mem_manage.png
   :scale: 30%

   内存管理



slab, slub和slob
~~~~~~~~~~~~~~~~~
1. 仅仅是分配内存策略不同。有时候用slab来统称slab, slub和slob。
2. slub用于替代slab，效率更高。
3. slob比较轻量，用于嵌入式系统。仅维护了3个不同size的缓存组。


slab层把不同的对象划分为高速缓存组，每个高速缓存组存放不同类型的对象（task_struct、inode等）。slab由一个或多个物理连续的页组成。


slab状态：满、部分满和空。


一下两个接口slab/slub通用：

1. kmem_cache_creat：创建高速缓存。
2. kmem_cache_alloc：从高速缓存分配结构。

kmalloc_caches
~~~~~~~~~~~~~~~~~~
1. ☆ `linux 内核 内存管理 slub算法 （一） 原理_slub算法原理-CSDN博客  <https://blog.csdn.net/bin_linux96/article/details/52980643>`__


.. figure:: /images/kmalloc_caches.png
   :scale: 90%

   kmalloc_caches


slub把内存分组管理kmalloc_caches，每个组分别包含2^3、2^4、...2^11个字节。

::

   struct kmem_cache kmalloc_caches[PAGE_SHIFT] __cacheline_aligned;

kmalloc_caches中有两个成员：

1. kmem_cache_cpu: cpu本地缓冲
2. kmem_cache_node: slab节点

.. figure:: /images/slab_caches.png
   :scale: 80%

   slab_caches


kmalloc与slab
~~~~~~~~~~~~~~~~~~~
`【精选】Linux内存管理(八): slub分配器和kmalloc_linux内存管理hober_Hober_yao的博客-CSDN博客  <https://blog.csdn.net/yhb1047818384/article/details/115604800>`__


kmalloc：通过size找到对应e的index，然后按index去申请对应cache。

::

   struct kmem_cache * kmalloc_caches[NR_KMALLOC_TYPES][KMALLOC_SHIFT_HIGH + 1];

   enum kmalloc_cache_type {
      KMALLOC_NORMAL = 0,
      KMALLOC_RECLAIM,
   #ifdef CONFIG_ZONE_DMA
      KMALLOC_DMA,
   #endif
      NR_KMALLOC_TYPES
   };

   static __always_inline void *kmalloc(size_t size, gfp_t flags)
   {
      if (__builtin_constant_p(size)) {
   #ifndef CONFIG_SLOB
         unsigned int index;
   #endif
         if (size > KMALLOC_MAX_CACHE_SIZE)
            return kmalloc_large(size, flags);
   #ifndef CONFIG_SLOB
         index = kmalloc_index(size);

         if (!index)
            return ZERO_SIZE_PTR;

         return kmem_cache_alloc_trace(
               kmalloc_caches[kmalloc_type(flags)][index],
               flags, size);
   #endif
      }
      return __kmalloc(size, flags);
   }



缺页中断
===========
1. `Linux内核缺页中断处理 - 知乎  <https://zhuanlan.zhihu.com/p/488042885>`__
2. `Linux虚拟内存和缺页中断  <https://cloud.tencent.com/developer/article/1688625>`__

.. Note:: 所有物理页都是缺页换进来的。包括 .text、.data等


缺页本身是一种中断，与一般的中断处理步骤相同

区别：

1. 在指令执行期间产生和处理缺页中断信号

2. 一条指令在执行期间，可能产生多次缺页中断

3. 缺页中断返回是，执行产生中断的一条指令，而一般的中断返回是，执行下一条指令。


缺页中断详细处理流程：

.. figure:: /images/do_page_fault.jpg
   :scale: 100%

   do_page_fault



进程地址空间
=======================
进程地址空间由进程可寻址的虚拟内存组成，进程之间以虚拟的方式共享内存。

段错误：进程访问不在有效范围内的内存区域，或以不正确的方式访问有限内存区域，那么内核就会终止该进程。

内存描述符
------------
mm_struct描述进程的地址空间。
其中mmap和mm_rb描述了该地址空间中的全部内存区域。

fork -> copy_mm 复制内存描述符，而其空间通过 allocate_mm -> mm_cachep slab缓存分配。

clone + CLONE_VM标志即线程，共享相同的地址空间。

内核线程
~~~~~~~~~~~~~~~~
内核线程：没有用户上下文，无进程地址空间，mm域为空。

当进程被调度时，该进程的mm域指向的地址空间被装在到内存，task_struct中的active_mm会被更新指向新地址空间。

内核线程并不需要访问任何用户空间的内存，而且因为在用户空间没有任何的页，所以不需要有自己的mm_struct和页表。

所有内核线程共享同一内核地址空间（使用上一个线程的地址空间）。

可减少mm_struct和页表占用空间，避免地址空间切换。

虚拟内存区域
----------------
vm_area_struct结构描述了指定地址空间内连续区间上的一段独立内存范围。内存描述符中的mmap（用于遍历）和mm_rb（用于查找）。

内核将每个内存区域作为单独的内存对象管理，该区域拥有一致的属性。
VMA则可以代表不同类型的内存区域。

每个VMA对应mm_struct中的唯一区间。线程共享地址空间自然也共享所有VMA。


查看实际使用的内存空间
~~~~~~~~~~~~~~~~~~~~~~~~~~
/proc文件系统或pmap工具。

如果一片内存范围是共享或不可写的，那么内核只需要在内存中为文件保留一份映射，如C库。



内存操作mmap
---------------
find_vma：查找给定内存地址属于哪个内存区域，mmap需要使用。


do_mmap:

1. 创建新的线性地址空间，会与相邻的同权限空间合并。
2. 指定文件名和偏移——文件映射；不指定——匿名映射。
3. 对应mmap系统调用。


do_mummap:从特定地址空间删除指定地址区间。系统调用mummap，与mmap作用相反。




mmap内存映射的过程
~~~~~~~~~~~~~~~~~~
1. `认真分析mmap：是什么 为什么 怎么用 - 胡潇 - 博客园  <https://www.cnblogs.com/huxiao-tee/p/4660352.html>`__

实现 零拷贝（OSC）。

mmap, munmap 

1. 用户空间：分配虚拟地址空间。map or unmap ``files or devices`` into memory
2. 内核空间：实现用户进程中的地址与内核中物理页面的映射


三个阶段：

1. 进程启动时在虚拟地址空间分配映射区域；
2. 内核将pcb中的未映射文件的物理地址和进程虚拟地址一一映射；
3. 访问导致缺页，将文件内容复制到物理内存。
