
=====================
Linux Drive Develop
=====================

:Date:   2022-06-18 23:02:43


总线设备驱动模型
===================

1. ☆ `Linux 设备总线驱动模型_Linux学习之路的博客-CSDN博客_linux总线设备驱动  <https://blog.csdn.net/lizuobin2/article/details/51570196>`__
2. ☆ `Linux 内核：设备驱动模型（2）driver-bus-device与probe - schips - 博客园  <https://www.cnblogs.com/schips/p/linux_device_model_2.html>`__
3. `Linux Device和Driver注册过程，以及Probe的时机_thl789的博客-CSDN博客  <https://blog.csdn.net/thl789/article/details/6723350>`__
4. `八、device_add_宁可一思进莫在一思停的博客-CSDN博客  <https://blog.csdn.net/qq_20678703/article/details/52841706>`__
5. `Linux设备和驱动的匹配过程_qwaszx523的博客-CSDN博客_linux设备和驱动的匹配  <https://blog.csdn.net/qwaszx523/article/details/65635071>`__


总线
--------

Linux 称为platform总线，为虚拟总线，所有直接通过内存寻址的设备都映射到这条总线上。让设备属性和驱动行为更好的分离。





设备与驱动的匹配
-----------------


1. bus(bus_register)维护注册进来的devcie 与 driver (各一个链表)，每注册(device_register/driver_register)一个device/driver 都会调用 **Bus->match** 函数(定义了Device和Driver绑定时的规则)，
将device 与 driver 进行配对，并将它们加入链表.

2. 如果配对成功，调用Bus->probe或者driver->probe函数， 调用 kobject_uevent 函数设置环境变量，mdev进行创建 **设备节点** 等操作。

3. 总线相应的结构体为struct bus_type，相应的设备为platform_device(链表)，相应的驱动为platform_drvier(链表)。


.. figure:: ../images/bus_device_drive.png
   :scale: 70 %

   bus_device_drive


.. figure:: ../images/register_call.png

   register_call



PCIE
======
1. ☆ `【原创】Linux PCI驱动框架分析（一） - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/14165852.html>`__
2. `【原创】Linux PCI驱动框架分析（二） - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/14209318.html>`__

pci总线地址空间
----------------
1. x86 CPU可以直接访问memory空间和I/O空间，而配置空间则不能直接访问；
2. 配置空间中有个寄存器：Base Address Register，也就是BAR空间，当PCI设备的配置空间被初始化后，该设备在PCI总线上就会拥有一个独立的PCI总线地址空间，这个空间就是BAR空间，BAR空间可以存放IO地址空间，也可以存放存储器地址空间。

.. figure:: ../images/PCIE_reg_conf.png
   :scale: 50 %
   :alt: alternate text



假设某个设备要对另一个设备进行读取数据的操作，首先这个设备（称之为Requester）需要向另一个设备发送一个Request，
然后另一个设备（称之为Completer）通过Completion Packet返回数据或者错误信息。

.. figure:: ../images/PCIE_tlp.png
   :scale: 70 %

   PCIE_tlp

Header中包含了地址信息，各种tlp类型header、寻址方式不同。


PCIE架构和分层
------------------

pcie架构
~~~~~~~~~~~~~~
.. figure:: ../images/PCIE_structure.png
   :scale: 70 %

   PCIE_structure


Root Complex：CPU和PCIe总线之间的接口可能会包含几个模块（处理器接口、DRAM接口等），甚至可能还会包含芯片，这个集合就称为Root Complex，
   它作为PCIe架构的根， **代表CPU与系统其它部分进行交互**。将CPU的request转换成PCIe的4种不同的请求（Configuration、Memory、I/O、Message）；


pcie分层
~~~~~~~~~~~~~~~
1. 与PCI总线不同（PCI设备共享总线），PCIe总线使用端到端的连接方式，互为接收端和发送端，全双工，基于数据包的传输；
2. 物理底层采用差分信号（PCI链路采用并行总线，而PCIe链路采用串行总线），一条Lane中有两组差分信号，共四根信号线，而PCIe Link可以由多条Lane组成(1/2/4/8/12/16/32)；

.. figure:: ../images/PCIE_layer.png

   PCIE_layer


1. Transaction层: 负责TLP包（Transaction Layer Packet）的封装与解封装，此外还负责QoS，流控、排序等功能；
2. Data Link层:负责DLLP包（Data Link Layer Packet）的封装与解封装，此外还负责链接错误检测和校正，使用Ack/Nak协议来确保传输可靠；
3. Physical层:负责Ordered-Set包的封装与解封装，物理层处理TLPs、DLLPs、Ordered-Set三种类型的包传输；

TLP事务层
~~~~~~~~~~~~
1. `PCIe扫盲——一个Memory Read操作的例子  <http://blog.chinaaet.com/justlxy/p/5100053263>`__

网络设备驱动
============
net_dev
----------

net_device_ops
~~~~~~~~~~~~~~~~~~~
include\linux\netdevice.h

::
    
    struct net_device_ops {
        int			(*ndo_init)(struct net_device *dev);
        int			(*ndo_open)(struct net_device *dev);
        int			(*ndo_stop)(struct net_device *dev);
        netdev_tx_t		(*ndo_start_xmit)(struct sk_buff *skb,
                            struct net_device *dev);

        u16			(*ndo_select_queue)(struct net_device *dev,
                                struct sk_buff *skb,
                                struct net_device *sb_dev);

        int			(*ndo_set_mac_address)(struct net_device *dev,
                                void *addr);

        int			(*ndo_do_ioctl)(struct net_device *dev,
                                struct ifreq *ifr, int cmd);

        int			(*ndo_change_mtu)(struct net_device *dev,
                            int new_mtu);

        void			(*ndo_tx_timeout) (struct net_device *dev,
                            unsigned int txqueue);

        void			(*ndo_get_stats64)(struct net_device *dev, 


ioctl
--------
ioctl调用链
~~~~~~~~~~~~~~~~
1. `Linux网络设备的系统调用_WGS_LV的博客-CSDN博客  <https://blog.csdn.net/lenk2010/article/details/39669411>`__

::

    ioctl(syscall) 
                    -> do_vfs_ioctl ->vfs_ioctl -> .unlocked_ioctl = sock_ioctl 
                    -> dev_ioctl -> dev_ifsioc- > .ndo_do_ioctl = my_dev_ioctl


fcntl
~~~~~~~

