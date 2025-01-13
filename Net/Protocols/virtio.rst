Virtio
=============

Virtio
-----------

1. `Virtio: An I/O virtualization framework for Linux - IBM Developer  <https://developer.ibm.com/articles/l-virtio/>`__  
译文 `virtio —— 一种 Linux I/O 半虚拟化框架 [译]-腾讯云开发者社区-腾讯云  <https://cloud.tencent.com/developer/article/2312201>`__
2. https://docs.oasis-open.org/virtio/virtio/v1.2/virtio-v1.2.html


virtio的框架
~~~~~~~~~~~~~~~~
1. ★★★ `Virtio：一种Linux I/O虚拟化框架-安全KER - 安全资讯平台  <https://www.anquanke.com/post/id/224001>`__
2. `【原创】Linux虚拟化KVM-Qemu分析（十一）之virtqueue - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/14589296.html>`__


1. virtio为半虚拟化提供了一系列通用设备仿真的接口。支持块设备、网络设备、pcie设备、balloon设备、终端设备。
2. 包括前端驱动（在guest os中）、和后端驱动（在hypervisor中），以及联结前后端的虚拟队列（vq）。


- 在全虚拟化中，客户操作系统在hypervisor上运行，相当于运行于裸机一般。
   客户机不知道它在虚拟机还是物理机中运行，不需要修改操作系统就可以直接运行。
- 在半虚拟化中，客户机操作系统不仅能够知道其运行于虚拟机之上，也必须包含与hypervisor进行交互的代码。
   但是能够在客户机和hypervisor的切换中，带来更高的效率

通过总线特定的方法发现和识别一个virtio设备(见总线特定部分：4.1通过PCI总线，4.2通过MMIO和4.3通过通道I/O)

.. figure:: /images/virtio_framwork.jpg
   :scale: 40%

   virtio_framwork.jpg

整个virtio协议中设备IO请求的工作机制可以简单地概括为：

- 前端驱动将IO请求放到Descriptor Table中，然后将索引更新到Available Ring中，然后kick后端去取数据；
- 后端取出IO请求进行处理，然后结果刷新到Descriptor Table中再更新Using Ring，然后发送中断notify前端。


virtio设备
~~~~~~~~~~~~~~~~~~~~~~~~~
1. `Virtio devices and drivers overview: Who is who  <https://www.redhat.com/en/blog/virtio-devices-and-drivers-overview-headjack-and-phone>`__

virtio设备和驱动很灵活，可支持多种不同的架构、场景。包括：

1. virtio-net：device在host kernel
2. virtio-user:device 在host user
3. virtio-user with userland driver: device 在host user + driver在guest user。

.. figure:: /images/virtio-net.png

   virtio-net



virtio设备包含4个重要部分：设备状态字、feature、notification、vq

1. 设备状态域：在驱动程序程序对设备进行初始化过程中，提供指示，包括设备是否有效、是否协商完feature。
2. featrue bits：驱动读取，并告诉设备它所接受的子集
3. notification：在设备与驱动之间发送，具体实现取决于特定传输实现（pcie标注位、mmio、中断陷入）。有三种类型通知：配置更改、可用缓冲、已用缓冲
4. vq：guest的buffer，一般实现为环形队列，提供给host消费（读或写），然后host会返还给guest。


buffer是guest视角的地址，device使用前需要转换地址。转换方式可能有：iommu、文件句柄、共享内存、虚拟机转换。

notification免打扰：a. 接收端设置标志位指示是否愿意接收； b. 设置阈值，达到一定数量后才进行通知


split queue
~~~~~~~~~~~~~~~

vq包含3个关键结构体：desc、avail、used

::

    struct virtq {
        // The actual descriptors (16 bytes each)
        struct virtq_desc desc[ Queue Size ];
        // A ring of available descriptor heads with free-running index.
        struct virtq_avail avail;
        // Padding to the next Queue Align boundary.
        u8 pad[ Padding ];

        // A ring of used descriptor heads with free-running index.
        struct virtq_used used;
    };


desc： 驱动分配好的内存的资源池

::

    struct virtq_desc {
        /* Address (guest-physical). */
        le64 addr;
        /* Length. */
        le32 len;
        /* This marks a buffer as continuing via the next field. */
        #define VIRTQ_DESC_F_NEXT   1
        /* This marks a buffer as device write-only (otherwise device read-only). */
        #define VIRTQ_DESC_F_WRITE     2
        /* This means the buffer contains a list of buffer descriptors. */
        #define VIRTQ_DESC_F_INDIRECT   4
        /* The flags as indicated above. */
        le16 flags;
        /* Next field if flags & NEXT */
        le16 next;
    };



avail： 

ring里面保存的是desc_idx，idx则是表示当前ring的索引。buffer放入avail之后，driver不能再更改对应的buffer。。

Driver负责更新头指针（idx），Device负责更新尾指针（Qemu中的Device负责维护一个last_avail_idx）

::

    struct virtq_avail {
    #define VIRTQ_AVAIL_F_NO_INTERRUPT
        le16 flags;
        le16 idx;
        le16 ring[ /* Queue Size */
        le16 used_event; /* Only if
    };




used: 与avail类似，used保存了已使用的desc_idx，另外还保存了对应buffer的已使用长度

::

    struct virtq_used {
    #define VIRTQ_USED_F_NO_NOTIFY  1
        le16 flags;
        le16 idx;
        struct virtq_used_elem ring[ /* Queue Size */];
        le16 avail_event; /* Only if VIRTIO_F_EVENT_IDX */
    };



packed queue
~~~~~~~~~~~~~~~
1. 系列三篇文章 `Packed virtqueue: How to reduce overhead with virtio  <https://www.redhat.com/en/blog/packed-virtqueue-how-reduce-overhead-virtio>`__
2. ★ `从dpdk1811看virtio1.1 的实现—packed ring-lvyilong316-ChinaUnix博客  <http://blog.chinaunix.net/uid-28541347-id-5819237.html>`__

split vq结构的三个部分在内存中是分散存储的，无法有效利用到cpu的cache机制，每次处理一个描述符需要多次pci的数据传输。所以将三环合一。

1. driver和device都分别维护一个翻转计数器（avail_wc、used_wc，初始值为1。wrap_counter的作用主要是为了解决desc ring回绕问题。）、表示下一个描述符位置的计数器（avail_idx、used_idx）。
2. driver和device按顺序使用描述符，当到达数组的最后一个时，则自己的翻转计数器进行翻转——效果就是无效了之前依据翻转计数器设置的描述符BIT位。
3. 队列flag字段有两个bit位：AVAIL-可用时，driver会将其置为与avail_wc一样；USED-使用完时device会将其置为与used_wc一致。



- AVAIL == USED - 已使用，可以标志为可用——即 avail_wc = AVAIL = !USED;
- AVAIL == !USED - 可用，使用完标志为已用—— AVAIL== USED = used_wc







智能网卡
----------
1. 传统网卡：guest的报文转发需要经过host内核，依赖bridge模块或open virtual switch(OVS)进行。
2. 智能网卡：具备硬件卸载功能的网卡设备。报文直接在网卡转发，使用SRIOV、virtio等协议。

SRIOV：将pcie设备的pf分为多个vf给多个虚拟机使用，虚拟机可以绕过中间虚拟层，直接使用pcie设备处理IO和传输数据。


