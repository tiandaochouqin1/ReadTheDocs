
DHCP与PXE协议
===============

.. admonition:: 摘要

   BOOTP/DHCP 动态地址分配与 PXE 无盘启动协议的简要笔记，附带 UEFI 和 dnsmasq 的配置要点。适合需要搭建 PXE 启动环境或理解网络启动流程的系统管理员。

bootp与dhcp
------------
1. `【TCP/IP详解】BOOTP：引导程序协议 - Chen沉尘 - 博客园  <https://www.cnblogs.com/chen-cs/p/12898864.html>`__


DHCP:Dynamic Host Configuration Protocol, 是 BOOTP的扩展(bootp的选项里面有许多是dhcp的)。

**DHCP消息格式的定义采用扩展BOOTP的方式**

.. figure:: /images/pxe_dhcp/dhcp_bootp_header.png

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

.. figure:: /images/pxe_dhcp/pxe.png

   pxe

.. figure:: /images/pxe_dhcp/pxe_boot.png

   pxe_boot


UEFI
---------
`Specifications | Unified Extensible Firmware Interface Forum  <https://uefi.org/specifications>`__


dnsmasq
-------------
dns+dhcp功能，自带pxe server


.. _pxe_takeaways:

关键要点
========

1. **DHCP 是 BOOTP 的超集** — 报文格式完全兼容，DHCP 增加了租约管理、动态 IP 分配和更多选项。DHCP Server 可以识别 BOOTP Client 并退回静态绑定模式。
2. **PXE 启动链** — BIOS → PXE ROM → DHCP（获取 IP + TFTP 地址）→ TFTP（下载 pxelinux.0）→ 配置文件 → kernel + initramfs → init。每一步都有超时和重试，排查时逐步验证。
3. **dnsmasq 一条龙** — 同时提供 DNS + DHCP + TFTP，自带 PXE Server 支持。对于小规模环境，比 ISC DHCPd + tftp-hpa 的组合更轻量。

.. seealso::

   `BootLoader <../../EOS/BootLoader.rst>`_
      x86/ARM 启动流程的系统性梳理，与 PXE 无盘启动互补。