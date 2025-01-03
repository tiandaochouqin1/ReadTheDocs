
=====================
Linux Drive Develop
=====================

:Date:   2022-06-18 23:02:43


总线设备驱动模型
===================

1. ☆ `Linux 设备总线驱动模型   <https://blog.csdn.net/lizuobin2/article/details/51570196>`__
2. ☆ 详细 `Linux 内核：设备驱动模型（2）driver-bus-device与probe - schips - 博客园  <https://www.cnblogs.com/schips/p/linux_device_model_2.html>`__
3. `Linux设备模型(5)_device和device driver  <http://www.wowotech.net/linux_kenrel/device_and_driver.html>`__
4. `Linux设备和驱动的匹配过程   <https://blog.csdn.net/qwaszx523/article/details/65635071>`__


设备树
---------
1. `Device Tree（三）：代码分析  <http://www.wowotech.net/device_model/dt-code-analysis.html>`__
2. `Linux驱动之platform_bus、platform_device、platform_driver_eZiMu的博客-CSDN博客  <https://blog.csdn.net/eZiMu/article/details/85198617>`__
3. `Linux dts 设备树详解(一) 基础知识 - 小麦大叔 - 博客园  <https://www.cnblogs.com/unclemac/p/12783391.html>`__

- x86 通常不使用设备树，而是依靠ACPI/UEFI(BIOS中，)、pcie自动枚举来识别硬件。
- arm不使用bios(即固件)，故对应功能需要在linux实现，这里是使用设备树，也支持acpi了。


1. dts(device tree source)是一种描述设备的语法，kernel在启动的时候会把dts的描述转换为实际的 ``device``。
2. dtb(device tree blob) 是 dts 与 dtsi(device tree source include，公共抽象部分) 经dtc(device tree compiler)编译的二进制文件。
3. dtb可以存储在ROM中或在引导的早期阶段中生成，然后U-Boot和kexec在启动新os时传递dtb；
4. dtb的解析of_driver_match_device -> of_match_device -> __of_device_is_compatible

driver & device注册过程
-------------------------

1. bus(bus_register)维护注册进来的devcie 与 driver (各一个链表)，每注册(device_register/driver_register)一个device/driver 都会调用 **Bus->match** 函数(定义了Device和Driver绑定时的规则)，将device 与 driver 进行配对，并将它们加入链表.
2. 如果配对成功，调用 **bus->probe/driver->probe**函数(在probe函数中实现 **设备的初始化**、各种配置以及生成用户空间的文件接口) 
3. kobject_uevent 函数设置环境变量，mdev进行创建 **设备节点** 等操作。
4. 总线相应的结构体为struct bus_type，相应的设备为platform_device(链表)，相应的驱动为platform_drvier(链表)。

kset是相关的kobject的集合，在sysfs中处于同一目录。kobject与一个ktype关联(定义了默认的特性/属性)。


`一文搞懂驱动的platform分层分离 - 掘金  <https://juejin.cn/post/7087463596082331656>`__

.. figure:: /images/platform_drv_dev.png
   :scale: 70 %

   platform_drv_dev



.. figure:: /images/bus_device_drive.png
   :scale: 70 %

   bus_device_drive


总线
--------
内核里有各种各样的总线，如 usb_bus_type、spi_bus_type、pci_bus_type、platform_bus_type、i2c_bus_type 等，内核通过总线将设备与驱动分离。

platform总线为虚拟总线，所有直接通过 **内存寻址的设备** 都映射到这条总线上。让设备属性和驱动行为更好的分离。


platform_bus虚拟总线
~~~~~~~~~~~~~~~~~~~~~~
1. `platform_bus、device及driver 注册及介绍_禾仔仔的博客-CSDN博客  <https://blog.csdn.net/weixin_43083491/article/details/119457618>`__

platform bus也是驱动框架下的一个子系统，是构建在linux驱动框架bus，device，driver这种模型之上的

linux启动时，根据dts节点创建sturct platform_device实例,并且把dts节点reg（dts描述：控制器，寄存器地址，memery地址）,interrupts属性翻译成struct resource类型结构体存放.



bus match的规则
~~~~~~~~~~~~~~~~~~~
1. `Linux Device和Driver注册过程，以及Probe的时机_thl789的博客-CSDN博客  <https://blog.csdn.net/thl789/article/details/6723350>`__



match 和probe流程：

1. bus上实现的.match()函数，定义了Device和Driver绑定时的规则。 如果bus->match()函数没实现，认为Bus上的所有的Device和Driver都是match的，具体后续过程要看probe()的实现了。

2. probe规则：优先使用bus->probe；未实现bus->probe才会用 driver->probe.


match的判断规则：

1. 调用of_driver_match_device()函数；(为了支持设备树dts。OpenFirmware)
2. ACPI系统专用方法；
3. driver的id_table；
4. 设备的名称或别名和驱动的名称进行匹配的。


Platform实现的就是先比较id_table，然后比较name的规则。

::

   static int platform_match(struct device *dev, struct device_driver *drv)
   {
      struct platform_device *pdev = to_platform_device(dev);
      struct platform_driver *pdrv = to_platform_driver(drv);

      /* When driver_override is set, only bind to the matching driver */
      if (pdev->driver_override)
         return !strcmp(pdev->driver_override, drv->name);

      /* Attempt an OF style match first */
      if (of_driver_match_device(dev, drv))  
         return 1;

      /* Then try ACPI style match */
      if (acpi_driver_match_device(dev, drv))
         return 1;

      /* Then try to match against the id table */
      if (pdrv->id_table)
         return platform_match_id(pdrv->id_table, pdev) != NULL;

      /* fall-back to driver name match */
      return (strcmp(pdev->name, drv->name) == 0);
   }






of_driver_match_device
~~~~~~~~~~~~~~~~~~~~~~~~~
1. `内核添加dts后，device和device_driver的match匹配的变动：通过compatible属性进行匹配_jenney_的博客-CSDN博客  <https://blog.csdn.net/ruanjianruanjianruan/article/details/61622053>`__
2. `Linux驱动之platform_bus、platform_device、platform_driver_eZiMu的博客-CSDN博客  <https://blog.csdn.net/eZiMu/article/details/85198617>`__


内核解析dtb文件创建platform设备时，大部分platform设备是没有名字的，大部分是通过 ``compatible`` 这个属性匹配成功的（这个compatible也对应dts里的compatible字符串）。

调用到__of_match_node（）函数，把 device_driver的of_match_table（ **of_device_id** 结构体的数组）和device里的of_node（ **device_node** 结构体）进行匹配。
（比较两者的name、type、和compatible字符串，三者要同时相同。name、type通常为null。比较compatible是直接compare整个字符串，不管字符串里的逗号)


pci_driver示例
~~~~~~~~~~~~~~~~
有.id_table和.name

::

   static struct pci_device_id ids[] = {
      { PCI_DEVICE(0x8086, 0x1570), },
      { 0, }
   };

   static struct pci_driver pci_driver = {
      .name = "pci_e1000e",
      .id_table = ids,
      .probe = probe,
      .remove = remove,
   };


platform_set_drvdata
~~~~~~~~~~~~~~~~~~~~~~~~
`linux驱动platform_set_drvdata 和 platform_get_drvdata这两个函数_落叶逆风的博客-CSDN博客  <https://blog.csdn.net/lhl161123/article/details/53264314>`__

一般在probe()函数中动态申请设备结构体，并初始化它，然后使用platform_set_drvdata（）将其保存到platform_device中



device_register和driver_register
-------------------------------------------
device_attach与driver_attach
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

大部分内容一样。区别 ``device_attach`` 调用driver_match_device匹配设备和驱动，成功就结束循环退出（而不是执行完循环）

一个驱动可以支持多个设备；一个设备只能绑定一个驱动。



device_register
~~~~~~~~~~~~~~~~~~~~~
Device一般是先于Driver注册

::
   
   device_register(dev)[core.c]
      device_initialize()            // 1. 初始化设备结构

      device_add(dev) [core.c]      // 2. add device to device hierarchy.
         bus_add_device(dev)        // 2.1 add device to bus
         bus_probe_device(dev) [bus.c]   // 2.2 probe drivers for a new device
            if (dev->bus && dev->bus-op->drivers_autoprobe)
            device_attach(dev) [dd.c]
               if (dev->driver)          // 2.2 设备已有驱动
                  device_bind_driver(dev)
               else       // 从这里开始，与driver_attach一样
               
                  bus_for_each_dev(dev->bus, NULL, drv,__driver_attach)
                  __driver_attach(dev, drv) [dd.c]
                     driver_match_device(drv, dev) [base.h]
                        drv->bus->match ? drv->bus-amatch(dev, drv) : 1
                        if false, return;
                     driver_probe_device(drv, dev) [dd.c]
                        really_probe(dev, drv) [dd.c]
                        dev-driver = drv;
                        if (dev-bus->probe)
                           dev->bus->probe(dev);
                        else if (drv->probe)
                           drv->probe(dev);
                        probe_failed:
                           dev->-driver = NULL;



driver_register
~~~~~~~~~~~~~~~~~~~~~~~~~~

::
      
   driver_register(drv) [core.c]     
      
      driver_find(drv->name, drv->bus)  // 1. 判断是否已被注册

      bus_add_driver(drv) [bus.c]      // 2. 添加驱动到bus 
         if (drv->bus->p->drivers_autoprobe)

            driver_attach(dev)[dd.c]   /2.1 匹配dev
               bus_for_each_dev(dev->bus, NULL, drv,__driver_attach)
                  __driver_attach(dev, drv) [dd.c]
                     driver_match_device(drv, dev) [base.h]   // 匹配 现有的 drv 与 现在的 dev
                        drv-bus->match ? drv->bus->match(dev, drv) : 1
                           if false, return;
                        
                     driver_probe_device(drv, dev) [dd.c]    // attempt to bind device & driver together
                        really_probe(dev, drv) [dd.c]
                           dev-driver = drv;                //在 dev 中记录 driver
                           driver_sysfs_add(dev)            //通知bus，更新sysfs
                           if (dev-bus->probe)              //真正的 probe 方法。如果BUS上实现了probe就用BUS的probe；否则才会用driver的probe。
                              dev->bus->probe(dev);
                           else if (drv->probe)
                              drv-aprobe(dev);
                           probe_failed:
                              dev->-driver = NULL;
                           driver_bound(dev);                 //将 device 放入 driver 链表中

          
            klist_add_tail(&priv->knode_bus, &bus->p->klist_drivers);   // 2.2 将 driver 加入 Bus 的 drivers 链表中

      kobject_uevent(&drv->p->kobj, KOBJ_ADD)      //3. 通过uevent通知用户空间






设备驱动初始化的时机
---------------------
1. `Linux 内核：initcall机制与module_init - schips - 博客园  <https://www.cnblogs.com/schips/p/linux_kernel_initcall_and_module_init.html>`__
2. `Linux内核启动流程与模块机制 - zhuqingzhu - 博客园  <https://www.cnblogs.com/nju347/p/7586792.html>`__

do_initcalls()把.initcallxx.init段中的函数按顺序都执行一遍。

1. module_platform_driver: paltform设备初始化(注册)使用arch_initcall()调用，level为3；
2. module_init:驱动初测使用module_init()，即device_initcall()，level为6.


.. figure:: /images/do_initcalls.png

   do_initcalls


::

   #define pure_initcall(fn)                __define_initcall("0",fn,1)

   #define core_initcall(fn)                __define_initcall("1",fn,1)
   #define core_initcall_sync(fn)          __define_initcall("1s",fn,1s)
   #define postcore_initcall(fn)            __define_initcall("2",fn,2)
   #define postcore_initcall_sync(fn)       __define_initcall("2s",fn,2s)
   #define arch_initcall(fn)                __define_initcall("3",fn,3)
   #define arch_initcall_sync(fn)          __define_initcall("3s",fn,3s)
   #define subsys_initcall(fn)              __define_initcall("4",fn,4)
   #define subsys_initcall_sync(fn)         __define_initcall("4s",fn,4s)
   #define fs_initcall(fn)                    __define_initcall("5",fn,5)
   #define fs_initcall_sync(fn)            __define_initcall("5s",fn,5s)
   #define rootfs_initcall(fn)              __define_initcall("rootfs",fn,rootfs)
   #define device_initcall(fn)              __define_initcall("6",fn,6)
   #define device_initcall_sync(fn)        __define_initcall("6s",fn,6s)
   #define late_initcall(fn)               __define_initcall("7",fn,7)
   #define late_initcall_sync(fn)          __define_initcall("7s",fn,7s)


   * module_init() will either be called during do_initcalls() (if
   * builtin) or at module insertion time (if a module).  There can only
   * be one per module.
   */
   #define module_init(x)  __initcall(x);


   #define __define_initcall(fn, id) \
                  static initcall_t __initcall_##fn##id __used \
                  __attribute__((__section__(".initcall" #id ".init"))) = fn



Linux设备
================
块设备
-----------
文件系统使用。

misc和char dev
-------------------
1. `Linux中MISC驱动简介及其简单使用   <https://blog.csdn.net/weixin_45309916/article/details/118636702>`__
2. `001_Linux内核驱动之杂项设备（miscellaneous device)的misc.c源码解析  <https://blog.csdn.net/zhanghui962623727/article/details/117754604>`__


misc是主设备号为10的chrdev，可自动生成设备节点。

1. 节省了Linux 主设备号，不需要每次开发都申请主设备号，使用不同的从设备号即可(/proc/misc可以看)；
2. 便于使用，封装了chrdev的操作。如下

::

   alloc_chrdev_rgion // 申请设备号
   cdev_init     //初始化cdev
   cdev_add   //添加cdev
   class_create //创建类
   device_create //创建设备


miscdevice结构体

::

   struct miscdevice  {
      int minor;										/* 子设备号 */						
      const char *name;								/* 设备名字 */
      const struct file_operations *fops;				/* 设备操作集 */
      struct list_head list;
      struct device *parent;
      struct device *this_device;
      const struct attribute_group **groups;
      const char *nodename;
      umode_t mode;
   };



网络设备驱动
============
net_device
-----------

net_device_ops
~~~~~~~~~~~~~~~~~~~
``include\linux\netdevice.h``

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

in_device
-----------
1. `in_device和in_ifaddr数据结构_hhhhhyyyyy8的博客-CSDN博客  <https://blog.csdn.net/hhhhhyyyyy8/article/details/103227224>`__

::

   struct in_device {
      struct net_device	*dev;/*指向所属的网络设备*/
      atomic_t		refcnt;/*引用计数*/
      int			dead;/*为1时标识所在的IP配置块将要被释放，不允许再访问其成员*/
      
      /*指向 in_ifaddr架构链表，in_ifaddr中存储了网络设备的IP地址，
      因为一个网络设备可以配置多个IP地址，因此使用链表来存储。*/
      struct in_ifaddr	*ifa_list;
   
      struct ip_mc_list __rcu	*mc_list;	/* IP multicast filter chain    */
      struct ip_mc_list __rcu	* __rcu *mc_hash;
   
      /*与组播相关配置*/
      int			mc_count;	/* Number of installed mcasts	*/
      spinlock_t		mc_tomb_lock;
      struct ip_mc_list	*mc_tomb;
      unsigned long		mr_v1_seen;
      unsigned long		mr_v2_seen;
      unsigned long		mr_maxdelay;
      unsigned char		mr_qrv;
      unsigned char		mr_gq_running;
      unsigned char		mr_ifc_count;
      struct timer_list	mr_gq_timer;	/* general query timer */
      struct timer_list	mr_ifc_timer;	/* interface change timer */
   
      /*指向neigh_parms结构实例，存储一些与ARP相关的参数*/
      struct neigh_parms	*arp_parms;
      
      struct ipv4_devconf	cnf;
      
      /*RCU机制使用，实现互斥*/
      struct rcu_head		rcu_head;
   };


in_ifaddr数据结构
~~~~~~~~~~~~~~~~~~~~~~~

::

   struct in_ifaddr {
      struct hlist_node	hash;
      struct in_ifaddr	*ifa_next;//in_ifaddr链表
      struct in_device	*ifa_dev;//指向所属的in_device结构
      struct rcu_head		rcu_head;
      __be32			ifa_local;//本地IP地址
      __be32			ifa_address;//本地IP地址或对端IP地址
      __be32			ifa_mask;//子网掩码
      __be32			ifa_broadcast;//广播地址
      unsigned char		ifa_scope;//寻址范围
      unsigned char		ifa_prefixlen;//子网掩码长度
      __u32			ifa_flags;//IP地址属性
      char			ifa_label[IFNAMSIZ];//网络设备名
   
      /* In seconds, relative to tstamp. Expiry is at tstamp + HZ * lft. */
      __u32			ifa_valid_lft;
      __u32			ifa_preferred_lft;
      unsigned long		ifa_cstamp; /* created timestamp */
      unsigned long		ifa_tstamp; /* updated timestamp */
   };



ifa_local和ifa_address的区别：

1. ifa_local始终表示本地IP地址

2. 如果设备配置了支持广播，ifa_address和if_local一样；如果点对点链路，ifa_address表示对端的IP地址。


ioctl
--------
ioctl调用链
~~~~~~~~~~~~~~~~
1. `Linux网络设备的系统调用_WGS_LV的博客-CSDN博客  <https://blog.csdn.net/lenk2010/article/details/39669411>`__
2. `UNP编程：37---struct ifreq、 struct ifconf结构体_董哥的黑板报的博客-CSDN博客  <https://blog.csdn.net/qq_41453285/article/details/100567095>`__

::

    ioctl(syscall) 
                    -> do_vfs_ioctl ->vfs_ioctl -> .unlocked_ioctl = sock_ioctl 
                    -> dev_ioctl -> dev_ifsioc- > .ndo_do_ioctl = my_dev_ioctl



ifreq：保存接口信息。socket ioctl使用。ifconf的成员



fcntl
~~~~~~~

ifconfig
~~~~~~~~~~~
ifconfig使用ioctl，ip.routes使用netlink。

   up     This  flag causes the interface to be activated.  It is implicitly specified if an address is
         assigned to the interface.




内核通知链
------------
1. `Linux 内核| 内核通知链机制 - 一丁点儿  <https://www.dingmos.com/index.php/archives/18/#cl-4>`__

net_device和in_device均有各自的通知链结构体，直接使用已封装的api即可。

::
      
   blocking_notifier_chain_register

   notifier_call_chain

   struct notifier_block {
      notifier_fn_t notifier_call;       // 回调函数
      struct notifier_block __rcu *next; // 下一个回调块
      int priority;                      // 优先级
   };



stmmac driver
------------------
drivers/net/ethernet/stmicro/stmmac/stmmac_main.c


内核态文件操作
--------------
1. `那些可进入睡眠状态的Linux内核函数 - 沉风网事  <https://myself659.github.io/post/linux/2015-06-01-linux-may-sleep-function/>`__
2. `linux内核态文件操作filp_open/filp_close/vfs_read/vfs_write  <https://blog.csdn.net/w968516q/article/details/77964853>`__

filp_open/filp_close/kernel_read/kernel_write(vfs_read/vfs_write 4.14以后已废弃)

**内核态有snprintf，无fprintf/fwrite.**


::

   write(用户态) -> ksys_write->vfs_write->new_sync_write->call_write_iter ... 底层架构相关的功能，可能会使用semphore导致调用scheduled


1. filp_open需要判断返回值；
2. vfs_write之前需要set_fs为内核态。

::

   fp = filp_open("/home/kernel_file", O_RDWR | O_CREAT, 0644);  
   if (IS_ERR(fp)) {  
      printk("create file error\n");  
      return -1;  
   } 

   fs = get_fs();  
   set_fs(KERNEL_DS);

   pos = fp->f_pos; 
   vfs_write(fp, buf1, sizeof(buf1), &pos);  
   fp->f_pos = pos;

   set_fs(fs);


IO缓冲
~~~~~~~~~~~~~
1. `带缓冲I/O和不带缓冲I/O的区别与联系 - ITtecman - 博客园  <https://www.cnblogs.com/nufangrensheng/p/3501245.html>`__

read或write的数据都要被内核缓冲.

不带缓冲的I/O指的是在用户的进程中对这两个函数不会自动缓冲， **每次read或write就要进行一次系统调用**。


虚拟网卡
============
1. `Linux 虚拟网卡技术：Macvlan – 云原生实验室 - Kubernetes|Docker|Istio|Envoy|Hugo|Golang|云原生  <https://icloudnative.io/posts/netwnetwork-virtualization-macvlan/>`__

Macvlan
--------

.. figure:: /images/macvlan.jpg
   :scale: 70%

   macvlan



RDMA
======
1. `【RDMA】技术详解（一）：RDMA概述_bandaoyu的博客-CSDN博客_rdma  <https://blog.csdn.net/bandaoyu/article/details/112859853>`__

.. figure:: /images/rdma.png
   :scale: 80%

   RDMA


sr-iov
--------
SR-IOV 标准允许在虚拟机之间高效共享 PCIe

VF 与网络适配器上的 PCIe 物理 (PF) 相关联，表示网络适配器的虚拟化实例。 每个 VF 都有其自己的 PCI 配置空间。 每个 VF 还与 PF 和其他 VF 共享网络适配器上的一个或多个物理资源，例如外部网络端口。



用户态驱动与内核驱动
=========================

内核驱动通常有着稳定、效率高、标准化、可复用等特性，因此在重构时领导喜好“将驱动下沉到内核”。

然而这是因果倒置的，因为驱动只有具有这些特性才适合放到内核。可以现在用户态开发，待稳定后移植到内核。


用户态驱动的特点：

1. 可以使用C库，带来便利性的同时也引入了依赖；
2. 可以使用浮点数计算；
3. 方便调试；
4. 可以使用闭源的驱动程序（内核代码则需要符合GPL协议）；
5. 代码出问题时影响范围小,内核驱动出问题常会导致整个系统死掉；

内核态驱动的特点：

1. 直接支持中断（用户态可以使用UIO支持）；
2. 代码性能高，无系统调用开销；
3. 有标准的驱动框架；

