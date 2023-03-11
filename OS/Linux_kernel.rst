
===============
Linux Kernel
===============


:Date:   2021-04-24 16:52:25



问题记录TODO
=============
以下各问题可新开主题来回答。
   
1. 异常、陷阱、中断、系统调用等概念辨析；如何查看中断向量表？实模式？系统调用的细节？
   `request_irq和free_irq函数如何注册注销中断(详解) <https://www.cnblogs.com/lifexy/p/7506613.html>`__
2. 自旋锁、互斥量、信号量的实现原理。无锁编程。
   `自旋锁 <http://www.wowotech.net/kernel_synchronization/460.html>`__ ;
   `Linux 单/多处理器下的内核同步与实现---自旋锁 <https://zhuanlan.zhihu.com/p/115748853>`__

3. `高速缓存与一致性 <https://zhuanlan.zhihu.com/cpu-cache>`__


   


内核入门
============
本文主要来源于LKD。

参考文档
--------

内核相关文档
~~~~~~~~~~~~~~~~~

1. https://www.kernel.org/doc/html/latest/translations/zh_CN/
2. https://kernelnewbies.org/
3. https://lwn.net/
4. https://kernel.org/pub/linux/kernel/
5. https://wiki.linuxfoundation.org/realtime/start

在线源码
~~~~~~~~~~~~~~~~~~
linux、glibc、gcc等。

1. https://elixir.bootlin.com/linux/v5.10/C/ident/ 不止有Linux。
2. http://sbexr.rabexc.org/latest/sources/meta/index : 搜索很快
3. https://code.woboq.org/ : 跳转准确
4. https://www.busybox.net/

参考书籍
~~~~~~~~

1. Linux Kernel Development， V2.6.34
2. Linux Devices Driver， V2.6.10
   :download:`ldd3 </books/ldd3.pdf>` 
3. Proffesional Linux Kernel Architecture， V2.6.24 
   :download:`深入Linux内核架构 </books/深入Linux内核架构.pdf>` 

   :download:`PLKA </books/Professional_Linux_Kernel_Architecture.pdf>` 

4. Understanding The Linux Kernel，  V2.6.11 
   :download:`ulk3 </books/ulk3.pdf>` 
   :download:`深入理解linux内核中文第三版 </books/深入理解linux内核中文第三版.pdf>` 

5. 奔跑吧Linux内核：几个重点模块讲解较仔细。


参考链接
~~~~~~~~

1. `趣谈Linux操作系统——刘超 <https://zter.ml/>`__ :完成一遍，后一半的内容比较深入，后续可作为相关知识点的参考。
2. 操作系统实战45讲
3. 有深度：`linux-inside <https://0xax.gitbooks.io/linux-insides/content/>`__ or 
   `linux-inside-zh <https://github.com/MintCN/linux-insides-zh>`__
4. `Linux进程管理与调度 <https://blog.csdn.net/gatieme/category_6225543.html>`__
5. http://www.wowotech.net/ ：很多不错的文章
6. `Linux内存管理专题 - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/8051674.html>`__ ：Linux等多个系列文章
7. ☆ `深入理解Linux进程调度  <https://mp.weixin.qq.com/s/3rV6d04QjO9_8Nkq9SrWYg>`__


开源协议
~~~~~~~~~~~
1. `常见的开源协议 - 简书  <https://www.jianshu.com/p/02e4248173fc>`__

Linux采用GPLv2。

- GPL（GNU General Public License）：只要你用了任何该协议的库、甚至是一段代码，那么你的整个程序，不管以何种方式链接，都必须全部使用GPL协议、并遵循该协议开源。
- LGPL （Lesser GPL）是GPL针对动态链接库放松要求了的版本

基本概念
--------
内核态拥有受保护的内存空间和访问硬件设备的所有权限。

应用程序通过库函数或系统调用让内核代替完成各种任务。
库函数不仅是对系统调用的打包，它也实现了系统调用不具备的功能，如strcpy。

.. figure:: /images/SyscallAndLibc.png
   :alt: 库函数和系统调用

   库函数和系统调用


**处理器可能的状态：**

1. 运行于用户空间，执行用户进程；
2. 运行于内核空间，处于进程上下文，代表某个特定的进程执行；
3. 运行于内核空间，处于中断上下文，处理特定的中断（与任何进程无关）。
4. CPU空闲时，运行一个空进程，处于2的状态。

**微内核：**
将内核服务的地址空间隔离，内核只提供基础服务（IPC、内存、调度等），
其它服务组件如文件系统、驱动程序等则各自运行在独立的地址空间（用户空间），并以IPC的方式为其它应用程序提供服务。

微内核提升了稳定性、安全性、扩展性和内核实时性，但是损失了效率。


内核版本号
----------

`Linux内核版本号： <http://en.wikipedia.org/wiki/Linux_kernel#Version_numbering>`__

1. 2.x 版本奇数表示开发版、偶数表示稳定版。2.6.x系列覆盖了2003-2011年。
2. 3.0开始，版本号基于时间变化（近2个月更新一次小版本号），不代表有重大的内容更新。同时避免小版本号超过20。
3. 当前5.11为15-Feb-2021发布

-  mainline 是主线版本。
-  stable 是稳定版，由 mainline   在时机成熟时发布，稳定版也会在相应版本号的主线上提供 bug   修复和安全补丁
-  longterm   是长期支持版，多为\ `6年 <https://www.kernel.org/category/releases.html>`__
-  RC：release candidates。



内核数据结构
============
.. important:: 实际开发中实用的知识


提倡在开发时重用Linux内建数据结构。

链表、队列、散列表、红黑树，还有基树（Radix Tree）、位图等。

链表
----------
静态数组：编译时需知道元素数量。

链表：动态创建并插入元素，无需占用连续内存。

Linux内核的标准链表为环形双向链表，灵活性高。

使用方法
~~~~~~~~~~~
在数据结构中嵌入链表。

::

   struct list_head {
       struct list_head *next;
       struct list_head *prev;
   }

   //返回包含list_head的父类型结构体（type），ptr为父结构体中的成员member。
   list_entry(ptr, type, member) 

   // for 循环，利用传入的 pos 作为循环变量，从表头 head 开始，逐项向后（ next方向）移动 pos ，直至又回到 head
   //head为数据结构的第一项成员时，与list_for_each_entry等价
   list_for_each(pos, head) 


   //遍历结构体head的成员member，存放到pos,O(n)
   list_for_each_entry(pos, head, member)


增加、删除、移动、合并节点的时间复杂度均为O(1) ，这些操作对应内部链表操作函数。在已有next/prev指针的情况下可直接调用内部链表函数。




队列
--------------
也称为FIFO。


kfifo为Linux内核通用队列实现。

两个主要操作：enqueue和dequeue（kfifo_in、kfifo_out）。维护两个偏移量：入口偏移和出口偏移。




映射
-------------
也称为关联数组。键到值的关联关系即为映射。可通过散列表、二叉搜索树来实现。

Linux内核提供的映射idr：将唯一的UID映射到一个指针。支持的操作 add、remove、lookup、allocate。

::

   使用idp指向的idr分配一个UID，并关联到ptr。
   idr__get_new(struct idr *idp, void *ptr,int *id)




二叉树
-----------------
Linux实现的红黑树为rbtree，为平衡二叉搜索树。

rbtree的实现并为提供搜索和插入方法。
C语言不方便泛型编程，同时最有效的搜索和插入方法应该由用户自己实现。


虚拟文件系统
===============

.. note:: 虚拟内存见另一篇文章

VFS概念
------------

VFS提供了一个通用的文件系统模型，囊括了文件系统的常用功能集和行为，
使得用户可以使用open、read、write这样的系统调用而无需考虑具体的文件系统和物理介质。

文件系统是特殊的数据分层存储结构，包含文件、目录和相关控制信息。

面向记录的文件系统：丰富、结构化的表示。
面向字节流的文件系统：Unix，简单、灵活。

VFS对象及其数据结构
------------------------
super_block
~~~~~~~~~~~~~~~~~~~~~~
超级快对象存储特定文件系统的信息。对应于存放在磁盘特定扇区中文件系统超级块或文件系统控制块。

文件系统安装时，调用alloc_super()创建并初始化超级块对象，以便从磁盘读取超级块，并填充到内存的超级块对象中。

super_operations()成员函数执行文件系统和索引节点的底层操作。如索引节点的创建、释放等。

inode
~~~~~~~~~~~~~~~~~
索引节点对象包含内核操作文件或目录时需要的全部信息，一个索引文件即代表文件系统中的一个文件。

仅当文件被访问时，才在内存中创建索引节点（从磁盘中提取相关信息，磁盘可能没有索引节点）。

inode_operations()中的操作方法常常与dentry对象相关。包含文件/目录的新建、删除、链接等方法，被相应的系统调用所使用。


dentry
~~~~~~~~~~~~~~
为了方便解析路径、查找文件，引入的目录项dentry。

路径中的每一个部分（包括普通文件）都是目录项对象。

目录项对象没有对应的磁盘数据结构，VFS根据字符串形式的路径名现场创建它。

**目录项状态**:被使用、未被使用和负状态。
一个被使用或未被使用的目录项对应这一个有效的索引节点（由d_inode指向），而负状态的目录项则不对应索引节点（作为缓存）。

**目录项缓存dcache**:文件访问具有空间和时间的局部性，故缓存非常重要。

1. “被使用的”目录项缓存链表，一个索引节点具有多个硬链接时则有多个目录项对象，因此inode中的i_dentry为链表；
2. “最近被使用的”目录项双向链表，包含未被使用和负状态的目录项对象，头部插入尾部删除；
3. 散列表，将路径快速解析为相关的目录项对象。


目录项会让索引节点的使用计数为正，可确保索引节点缓存在内存中。

file
~~~~~~~~~~~
文件对象是进程已打开的文件在内存中的表示（open创建，close撤销）。

文件对象file仅在观点上表示已打开的文件，实际指向目录项对象（指向索引节点），实际只有目录项对象才表示**已打开的实际文件**。

一个文件对应的文件对象不唯一（多个进程可同时打开同一文件），但对应的索引节点和目录项是唯一的。

file和dentry都没有实际的磁盘数据。
file通过f_entry指向相关的目录项对象dentry，dentry则通过d_inode指向对应的索引节点inode，inode中会记录文件是否为脏、是否需要写回磁盘。

file的相关操作与系统调用和类似，如llseek、read、write、flush、open等。

其它数据结构
---------------
其它文件系统数据结构
~~~~~~~~~~~~~~~~~~~~~~~~~

1. file_system_type，描述各种特定文件系统类型，每种文件系统只有一个该结构；
2. vfsmount，描述一个安装文件系统的实例，即代表一个安装点。

和进程相关的数据结构
~~~~~~~~~~~~~~~~~~~~~~~
1. file_struct：由进程描述符中的files指向，包含的fd_array指向已打开的文件对象。
2. fs_struct：由进程描述符的fs指向，包含的当前工作目录和根目录路径结构体中包含目录项对象。
3. mmt_namespace：由进程描述符的mmt_namespace指向，使得每个进程都看到唯一的安装文件系统，list域为已安装的文件系统的双向链表。

使用CLONE_FILES或CLONE_FS创建的进程才会共享file_struct或fs_struct,故结构体中需要维护count计数以防止被撤销。

进程一般继承父进程的命名空间（除非使用CLONE_NEWS标志），因此在大多数系统行只有一个命名空间。

块IO层
=============

块设备：能够随机访问固定到小数据片的硬件设备。复杂性高，对其性能要求也高。

字符设备：按照字节流的方式顺序访问的设备。只需控制一个位置（当前位置），内核不必提供专门的子系统来管理字符设备。

扇区：硬扇区、设备块。块设备中的最小可寻址单元。常为512字节。

块：文件块、IO块。内核最小寻址单元。大小为扇区的2*n倍，并小于页。

缓冲区
-----------
块被调入内存后存储在缓冲区中。
一个缓冲区对应一个块，相当于磁盘块在内存中的表示。

一个页可容纳多个内存中的块。

buffer_head
~~~~~~~~~~~~~
缓冲区头包含内核操作缓冲区所需的全部信息，描述了磁盘块和物理内存缓冲区的特定映射关系。

1. 结构体大。内核倾向于操作页面。
2. 仅描述单个缓冲区。大块数据的IO操作被分解造成不必要的负担。

bio结构
----------------
bio结构代表了在现场的以链表形式组织的一个块的IO操作。

即使缓冲区分散在多个内存位置上，bio也保证内核能够执行IO操作，即聚散IO。

bio中，bio_io_vec为bio_vec结构体数组，包含了一个IO操作所需要使用到的所有片段。bio_vec结构：<page,offset,len>。

bi_vcnt为数组成员数量，bi_idx为当前索引位置。

请求队列
~~~~~~~~~~~
块设备将挂起的块IO请求保存在请求队列reques_queue中，该结构包含一个双向请求队列以及相关控制信息。

队列不为空时，对应的块设备驱动程序就会从队列头获取请求，并送到对应的块设备上去。

每个请求request可由多个bio结构体组成。

IO调度程序
-----------------------
内核在将请求提交给块设备前，先执行合并与排序的预操作，以减少磁盘寻址时间


1. Linus电梯IO调度程序：执行合并和排序，以磁盘物理位置为次序维护请求队列——排序队列。2.6已废弃。
2. 最终期限IO调度程序deadline：排序队列+读/写请求FIFO队列，请求会同时插入排序队列和FIFO队列，使用FIFO队列请求超时来防止请求饥饿。
3. 预测IO调度程序as：与deadline类似。跟踪并统计进程的块IO操作习惯，当进程可能很快发出另一个读请求时则延迟一会。内核缺省。
4. 完全公正的排队IO调度程序：每个提交IO的进程都有一个队列，以时间片轮转调度队列，选取固定请求数（默认4）。
5. 空操作的IO调度程序：只执行与相邻请求合并的操作。

内核选项elevator=foo，选择调度程序。

writes-starving-reads
~~~~~~~~~~~~~~~~~~~~~~~
即写使得读请求饥饿。

写请求通常是异步的，而读请求通常是同步的。即读请求会阻塞到直到该请求被满足，故读操作响应对系统性能非常重要。


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

MESI
~~~~~~~~~~
1. `高速缓存一致性协议MESI与内存屏障 - 小熊餐馆 - 博客园  <https://www.cnblogs.com/xiaoxiongcanguan/p/13184801.html#_label1_0>`__
2. `arm64 cache机制分析  <https://mp.weixin.qq.com/s/NlWvs_fjWSSvW2S1FcpgkQ>`__


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

页表
------------

使用三级页表将虚地址转换为物理地址：

1. PGD：页全局目录，顶级页表。
2. PMD：中间页目录，二级页表。
3. PTE：页表，指向物理页面向记录的文件系统：丰富、结构化的表示。


一般由硬件完成页表的搜索。操作和检索页表时必须使用page_table_lock锁（进程描述符内）。

TLB：translate lookaside buffer,翻译后缓冲器。虚拟地址到物理地址映射的硬件缓存。

页高速缓存与页回写
==========================

页高速缓存：由内存中的物理页面组成，其内容对应磁盘上的物理块。

**写缓存策略**

1. 写透策略：写操作自动更新内存缓存，同时更新磁盘文件。
2. 回写策略：
   写操作直接写到缓存中，将页高速缓存中被写入的页面标记为脏，并加入到脏页链表，
   然后由一个会写进程周期性地将脏页链表中的页写回磁盘。
   


**缓存回收策略**

1. LRU：跟踪每个页面的访问踪迹，回收最老时间戳的页面。
2. 双链策略：LRU/2，或LRU/n，以伪LRU规则维护活跃链表和非活跃链表，并维持两个链表的平衡。
   解决了LRU算法中对仅一次访问的窘境。


页高速缓存buffer
----------------
缓存各种基于页的对象，包含各种类型的文件和各种类型的文件映射。

所有的页IO操作必然通过页高速缓存进行。

使用address_space（更应该叫page_cache_entity或physical_pages_of_a_file）结构体管理缓存项和页IO操作。
一个文件只能有一个adrress_sapce。


查找
~~~~~~~~
页面中包含的磁盘块不一定连续，查找特定数据是否已被缓存较为困难。

每个address_space都有唯一的基树radix_tree（一种二叉树）。

find_get_page -> radix_tree_lookup。

以前的页散列表

1. 单个全局锁保护散列表竞争严重；
2. 散列表包含页高速缓存中的所有页面，而搜索只需要和当前文件相关的页；
3. 搜索失败时需要遍历指定散列键值的整个列表；
4. 占用更多内存。


缓冲区高速缓存cached
------------------------
磁盘块通过块IO缓存被存入页高速缓存。

映射内存中的页面到磁盘块，以减少块IO操作时的磁盘访问。

缓冲区高速缓存是作为页高速缓存的一部分实现的。

free查看buffer和cached
~~~~~~~~~~~~~~~~~~~~~~~~~~~
free -m 的结果：

1. buffers: For the buffer cache, used for block device I/O.
2. cached: For the page cache, used by file systems.

flusher线程
-------------------
不同的flusher线程处理不同的设备队列，各自独立地执行脏页刷回磁盘的操作。

脏页回写时机；

1. 空闲内存低于阈值时；内核会调用flusher_threads唤醒一个或多个flusher线程。
2. 脏页驻留内存超时；flusher线程被定时器周期性唤醒。
3. 用户进程调用sync和fsync系统调用时，内核会执行回写。

laptop_mode：

该策略意图将硬盘装懂的机械行为最小化，以节省电量。
flusher会找准磁盘运转的时机，以执行所有其他的物理磁盘IO、刷新脏缓冲等。


定时器
---------
https://elixir.bootlin.com/linux/v2.6.32/source/kernel/timer.c

1. Insert：
定时器的插入，首先都要根据定时器的超时时间与每级时间轮所能表示的时长进行比较，来觉得插入到那个轮子中，再根据当前轮子已走的索引，计算出待插入定时器在该轮子中应插入的spoke。


2. Schedule：
多级时间轮定时器触发机制为周期性tick出发，每个tick到来，最低级的tv1的spoke index都会+1，如果该spoke中有timer，那么就处理该timer list中的所有超时timer。

2. Cascade：
Cascade可以翻译成降级处理。每个tick到来，都只会去检测最低级的tv1的时间轮，因为多级时间轮的设计决定了最低级的时间轮永远保存这最近要超时的定时器。
多级时间轮最重要的一个处理流程就是cascade，当每一级(除了最高级)时间轮走到超出该级时间轮的范围时，就会触发上一级时间轮所在spoke+1的cascade过程，如果上一级时间轮也走出来时间轮的范围，也同样会触发cascade过程，这是一个递归过程。


