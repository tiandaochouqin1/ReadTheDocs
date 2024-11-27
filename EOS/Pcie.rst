
PCIE
======
1. ☆ `【原创】Linux PCI驱动框架分析（一） - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/14165852.html>`__
2. `【原创】Linux PCI驱动框架分析（二） - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/14209318.html>`__
3. `apachecn-linux-zh/11.md at master · apachecn/apachecn-linux-zh · GitHub  <https://github.com/apachecn/apachecn-linux-zh/blob/master/docs/master-linux-device-driver-dev/11.md>`__
4. ☆ `GitHub - ljgibbslf/Chinese-Translation-of-PCI-Express-Technology-  <https://github.com/ljgibbslf/Chinese-Translation-of-PCI-Express-Technology->`__
   `PCIe扫盲——一个Memory Read操作的例子   <https://blog.chinaaet.com/justlxy/p/5100053263>`__


PCIE拓扑
------------------

pcie树形拓扑
~~~~~~~~~~~~~~
.. figure:: /images/PCIE_structure.png
   :scale: 70 %

   PCIE_structure



Root Complex
^^^^^^^^^^^^^
PCIe架构的根， **代表CPU与系统其它部分进行交互**，只有RC能发出配置请求。

将CPU的request转换成PCIe的4种不同的请求（Configuration、Memory、I/O、Message）.CPU前端总线和PCIe总线之间的接口,可能会包含处理器接口、DRAM接口、甚至芯片.

ep访问rc通常使用dma。


Switch
^^^^^^^
提供了扇出以及聚合能力，使得单个 PCIe 端口上可以连接更多的设备.

pcie本身是点对点的，所以需要switch和bridge。

bridge
^^^^^^^
提供了一个通往其他总线的接口。

switch的每个端口都是bridge，都有配置空间（每个function都有配置空间）。

每个p2p bridge对应一个bus。

每个端口都需完整实现pcie 3个协议层次。

host to pci bridge通常映射到设备的特定寄存器。



PCIE协议分层
------------


pcie分层
~~~~~~~~~~~~~~~
1. 与PCI总线不同（PCI设备共享总线），PCIe总线使用端到端的连接方式，互为接收端和发送端，全双工，基于数据包的传输；
2. 物理底层采用差分信号（PCI链路采用并行总线，而PCIe链路采用串行总线），一条Lane中有两组差分信号，共四根信号线，而PCIe Link可以由多条Lane组成(1/2/4/8/12/16/32)；

.. figure:: /images/PCIE_layer.png

   PCIE_layer


1. Transaction层: 负责TLP包（Transaction Layer Packet）的封装与解封装，此外还负责QoS，流控、排序等功能；
2. Data Link层:负责DLLP包（Data Link Layer Packet）的封装与解封装，此外还负责链接错误检测和校正，使用Ack/Nak协议来确保传输可靠；
3. Physical层:负责Ordered-Set包的封装与解封装，物理层处理TLPs、DLLPs、Ordered-Set三种类型的包传输；以差分信号的形式进行传输

TLP事务层
~~~~~~~~~~~~
1. `PCIe扫盲——一个Memory Read操作的例子  <http://blog.chinaaet.com/justlxy/p/5100053263>`__


事务：通常是一个请求包+一个或多个完成包。请求包中的tag字段可关联完成包。

- Qos：软件给每个数据包都分配了优先级字段TC，硬件则多缓冲区VC buffer和仲裁。
- 流量控制：通过dllp包把自己的剩余的buffer空间告知发送方（DLLP 可以不管缓冲区状态就进行收发）。

tlp
^^^^^^^

假设某个设备要对另一个设备进行读取数据的操作，首先这个设备（称之为Requester）需要向另一个设备发送一个Request，
然后另一个设备（称之为Completer）通过Completion Packet返回数据或者错误信息。

.. figure:: /images/PCIE_tlp.png
   :scale: 70 %

   PCIE_tlp

Header中包含了地址信息，各种tlp类型header、寻址方式不同。

pcie数据包最大可支持4K。




数据链路层
~~~~~~~~~~~~
DLLP层有重传buffer，通过ack/nack机制来重传。

.. figure:: /images/pcie_dllp.jpg
   :scale: 100 %

   pcie_dllp


物理层
~~~~~~~


pci配置空间和配置请求
---------------------------
配置空间、存储器空间、IO空间。

1. x86 CPU可以直接访问memory空间和I/O空间;
2. x86 CPU无法直接访问配置空间，通过IO映射的数据端口和地址端口间接访问PCI的配置空间；
3. Bridge或Device类型的PCIE设备拥有不同的配置空间header。其中的Base Address Register BAR空间，当PCI设备的配置空间被初始化后，该设备在PCI总线上就会拥有一个独立的PCI总线地址空间即bar空间，BAR空间可以存放IO地址空间，也可以存放存储器地址空间。

.. figure:: /images/PCIE_reg_conf.png
   :scale: 50 %

   io映射的地址端口


.. figure:: /images/pcie_cfg_space.png
   :scale: 80 %

   pcie配置空间


原生pcie ep是内存映射设备，传统pcie ep才支持io空间。


枚举过程
~~~~~~~~
深度优先.

- 软件唯一知道的就是拓扑中有一个Host/PCI Bridge以及这个Bridge的次级总线Bus 0。通过读取整个系统中的Bus—Device—Function这三者所有组合中的Vendor ID寄存器，枚举软件可以搜索遍整个拓扑，并得知有哪些设备存在。

- device必须实现function 0,剩余function编号可以不连续。

- Header类型寄存器（Header Type Register，位于配置空间Header的偏移地址0Eh）的低7bit用于标识这个Function的基本种类


1. 配置软件分配总线号的过程中，首先从Bus 0/Device 0/Function 0开始搜索其他的Bridges。当找到一个Bridge之后，软件就给这个Bridge产生的新总线分配一个与上一级总线的总线号不同的、数字更大的编号。一旦新总线被分配了一个总线号之后，软件就会从新总线继续搜索更新的Bridges，而不是在上一级总线上继续搜索。

2. 从Device 0开始，枚举软件将会尝试去读取Bus 0上的32个可能存在的Device，读取的内容为它们各自的Function中的Vendor ID。如果Bus 0—Device 0—Function 0返回了一个有效的Vendor ID，那么就认为这个设备存在并至少含有一个Function。
若Bus 0—Device 0—Function 0没有返回一个有效的Vendor ID，则继续去探测Bus 0—Device 1—Function 0。



.. figure:: /images/pcie_enumeration.jpg
   :scale: 100 %

   pcie_enumeration


inbound outbound
~~~~~~~~~~~~~~~~~~~~~
1. `pcie inbound、outbound及EP、RC间的互相訪问 - blfshiye - 博客园  <https://www.cnblogs.com/blfshiye/p/4377496.html>`__


.. figure:: /images/pcie_outbound_inbound.png
   :scale: 70 %

   inbound outbound



ATU在存储器域上，inbound和outbound是以存储域为基准的概念。

每个bar地址都对应若干对in/outbound条目，所以ep和rp都需要配置。默认地址转换为等值转换，通常可以配为地址偏移的映射。


1. Inbound:PCI域訪问存储器域
2. Outbound:存储器域訪问PCI域

访问路径：

1. RC訪问EP: RC存储器域->outbound->RC PCI域->EP PCI域->inbound->EP存储器域
2. EP訪问RC: EP存储器域->outbound->EP PCI域->RC PCI域->inbound->RC存储器域


bar寄存器
~~~~~~~~~~~~~

1. type0:6个bar字段，每个32bit，同时表示了基地址和size。相邻两个可合成一个64bit。
2. 支持配置为mmio或io空间。
3. 由于64/32bit寄存器的设计，所有起始地址都是与size对齐，可能有多余的空间。

bar的请求写入使用：

1. 设备设计者将BARs的低位bit固定为某个值，以此来指示需要请求的地址空间的大小和类型。
2. 系统软件通过检查BARs的低位bit，将分配给这个设备的地址范围的基地址写入BAR中。
3. 当设备发现一个请求事务的地址是映射到自己的一个BAR时，它就会接收这个请求事务


.. figure:: /images/pcie_type01_bar.jpg
   :scale: 100 %

   pcie_type01_bar

base limit寄存器
~~~~~~~~~~~~~~~~~~
base+limit：3个，np-mmio（可扩展为64bit）、p-mmio、io。

Base/Limit寄存器只表示Bridge下方存在的地址空间,分配给下游设备的地址(bridge自身空间在bar里面)。

每个Bridge（例如Switch的端口和RC端口）都需要知道它下方所存在的可用地址范围，这样Bridge才能确定哪些请求需要从它的主接口（Primary interface，它在上方）被转发到它的次级接口（Secondary interface，它在下方）。


.. figure:: /images/pcie_bars_base_limit.jpg
   :scale: 100 %

   pcie_bars_base_limit


type0和type1配置请求
~~~~~~~~~~~~~~~~~~~~~~
Bridge为了响应配置请求，将会产生两种类型的配置请求，分别为Type 0和Type 1。具体产生哪一种类型的配置请求，取决于目标总线号是否与当前Bridge的次级总线号（Secondary Bus Number）相匹配。

增强型配置访问实例
~~~~~~~~~~~~~~~~~~~~~~


Wrd+CPLD的过程
~~~~~~~~~~~~~~~~~


地址空间与事务路由
------------------
switch/function如何知道自己的bus id、device id?  从接收到的type0 配置写的tlp header中捕获自己的bus和device，保存下来。


tlp类型
^^^^^^^^^

- non-posted: 有完成包
- posted: 无完成包，不等待。仅内存写和message会使用。

注意：链路层对于所有包都有ack/nack。


地址路由
~~~~~~~~~~~
仅tlp需要路由，dllp和ordered-set不需要

三种路由方法：
1. address 路由：Header中的Address字段来执行路由检查。Address字段可以是32bit也可以是64bit的。
2. ID(BDF)路由：ep-据自己的BDF来检查TLP Header中的ID字段。switch/bridge-检查这个TLP的预期目的地是不是端口自身，查看TLP的目标总线号是否在Switch端口下方的从属总线范围内（包括范围边界）
3. 隐式路由。减少边带信号，减少pin脚。message使用


.. figure:: /images/pcie_tlp_route.jpg
   :scale: 100 %

   pcie_tlp_route


.. figure:: /images/pcie_tlp_header_address.jpg
   :scale: 100 %

   pcie_tlp_header_address


.. figure:: /images/pcie_tlp_header_id.jpg
   :scale: 100 %

   pcie_tlp_header_id





基于消息的msi-x中断
-----------------------




UCIE
-----------
https://www.uciexpress.org/

- 提供不同制造商的chiplet之间的互操作性，在封装级别建立通用互联。
- 混合、配合来自多供应商的chiplet组件，以构建较大的芯片。
- 简历封装级别的通用互联，覆盖die to die I/O物理层，die to die协议层和软件栈（支持pcie、cxl行业标准）。
