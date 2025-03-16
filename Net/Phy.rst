
PHY及其驱动架构
====================


phy芯片
------------
PHY是物理接口收发器,它实现物理层.IEEE-802.3标准定义了以太网PHY.包括MII/GMII(介质独立接口)子层,PCS(物理编码子层),PMA(物理介质附加)子层,PMD(物理介质相关)子层,MDI子层.

从硬件上来说，一般PHY芯片为模数混合电路，负责接收电、光这类模拟信号，经过解调和A/D转换后通过MII接口将信号交给MAC芯片进行处理。一般MAC芯片为纯数字电路。

物理层定义了数据传送与接收所需要的电与光信号、线路状态、时钟基准、数据编码和电路等，并向数据链路层设备提供标准接口。物理层的芯片称之为PHY。

常用phy芯片
~~~~~~~~~~~~~~

rtl8211fs(i)(-vs)-cg :网上无公开datasheet

rtl8211e(g)-vb(vl)-cg: `千兆PHY详解及调试举例 <https://cloud.tencent.com/developer/article/1652191>`_

marvel 88e1111:https://blog.csdn.net/qq_39466755/article/details/109050806

PHY寄存器
~~~~~~~~~~~~~~
https://blog.csdn.net/ZCShouCSDN/article/details/80090802

地址空间为5位，从0到31最多可以定义32个寄存器（随着芯片功能不断增加，很多PHY芯片采用分页技术来扩展地址空间以定义更多的寄存器），IEEE802.3定义了地址为0-15这16个寄存器的功能，地址16-31的寄存器留给芯片制造商自由定义.

具体见IEEE802.3标准的 22.2.4 Management functions 节,Table 22–6—MII management register set。

MDIO
~~~~~~~~~~
https://blog.csdn.net/rhythmwang/article/details/62039140

MDIO是Management Data Input/Output 的缩写，有两根线，分别为双向的MDIO和单向的MDC，用于以太网设备中上层对物理层的管理。

在第22中，一个单独的帧指定要读或写的地址和数据，同时完成了这些工作。45号中改变这种范式，第一个地址帧发送到指定的MMD和寄存器，然后发送第二帧来执行读或写。

SERDES的通用结构介绍
~~~~~~~~~~~~~~~~~~~~

https://bbs.huaweicloud.com/blogs/detail/282347




phy驱动架构
-------------

以下为层次结构：



|        Linux 网络协议栈（TCP/IP）                |

|        MAC 驱动 (MAC Controller)                |
|        - 负责数据帧的封装、解析                  |
|        - 通过 PHY 设备管理接口控制 PHY          |

|        PHY 子系统（PHY Framework）               |
|        - 通过 MDIO 读取/写入 PHY 寄存器         |
|        - 维护 PHY 状态                           |

|        MDIO 总线（mii_bus）                       |
|        - 通过 MDIO 访问 PHY                      |
|        - 负责 PHY 设备的管理                     |

|        硬件：MAC 控制器 + MDIO 控制器 + PHY      |




设备树
~~~~~~~~~~~~~~~~
设备	作用	设备树绑定方式

MDIO 控制器	访问 PHY 设备	定义 mdio 节点，reg 指定寄存器地址

PHY 设备	物理层芯片	在 mdio 下定义 ethernet-phy@x，reg 指定 MDIO 地址

MAC 设备	以太网控制器	phy-handle 绑定 PHY，phy-mode 指定接口模式

MAC 通过 phy-handle 绑定 PHY，MDIO 通过 reg 连接 PHY 设备，Linux 通过设备树解析这些关系并正确加载驱动。


mdio既是总线也是设备
~~~~~~~~~~~~~~~~~~~~~
MDIO 既是 platform_device，又是 总线（mii_bus），因为：

作为 platform_device：
它是 SoC 的一个硬件控制器，管理 MDIO 总线的底层寄存器访问。
需要 platform_driver 进行初始化，并通过 platform_device 绑定设备树。

作为总线（mii_bus）：
它负责管理 PHY 设备，并提供 phy_read() / phy_write() API。
通过 mdiobus_register() 让 PHY 设备可以动态发现和驱动匹配。

这种设计使得 MDIO 既能作为 SoC 内部设备受管理，又能作为网络 PHY 设备的管理者，实现了良好的扩展性和兼容性。


mdio不是标准的总线模型
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

类型	适用范围	设备管理方式	是否基于 bus_type

Linux 标准总线（PCI/I2C）	通用外设	bus_register()	是

MDIO 总线	PHY 设备	mdiobus_register()	否（使用 mii_bus）

平台设备	SoC 内部设备	platform_driver_register()	否

关键点：

MDIO 是 SoC 提供的一个特殊总线，通常是 platform_device，但它使用 mii_bus 进行管理。

PHY 设备不是平台设备，而是由 mii_bus 直接管理的 MDIO 设备。

MDIO 设备与 PHY 驱动的匹配机制类似 PCI/I2C，但使用 phy_id 而非 bus_type.match()。


这种架构保证了 MDIO 设备（PHY）独立于 SoC 的硬件平台，而且能够适配不同厂商的 PHY 设备，同时兼容 Linux 设备驱动模型。