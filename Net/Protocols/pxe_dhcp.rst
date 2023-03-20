
DHCP与PXE协议
===============
bootp与dhcp
------------
1. `【TCP/IP详解】BOOTP：引导程序协议 - Chen沉尘 - 博客园  <https://www.cnblogs.com/chen-cs/p/12898864.html>`__


DHCP:Dynamic Host Configuration Protocol, 是 BOOTP的扩展(bootp的选项里面有许多是dhcp的)。

**DHCP消息格式的定义采用扩展BOOTP的方式**

.. figure:: /images/dhcp_bootp_header.png

   dhcp_bootp_header



1. bootp 中ip与mac静态绑定，需要预先配置。
2. dhcp则具有动态性，包括动态ip、保留ip、租约等功能。
3. dhcp server可兼容bootp client。
4. rarp仅可获取ip地址，链路层广播，无法路由转发。

pxe
------
1. `DHCP协议和PXE - kumata - 博客园  <https://www.cnblogs.com/kumata/p/9186532.html>`__


Preboot eXecution Environment：基于dhcp、tftp实现的无盘启动。




bios ->pxe ->dhcp ->tftp ->pxelinux.0 ->pxlinux.cfg ->image+initramfs ->init

.. figure:: /images/pxe.png

   pxe

.. figure:: /images/pxe_boot.png

   pxe_boot


UEFI
---------
`Specifications | Unified Extensible Firmware Interface Forum  <https://uefi.org/specifications>`__


dnsmasq
-------------
dns+dhcp功能，自带pxe server