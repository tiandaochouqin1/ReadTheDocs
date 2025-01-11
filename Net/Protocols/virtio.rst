Virtio
=============

Virtio
-----------

1. `Virtio: An I/O virtualization framework for Linux - IBM Developer  <https://developer.ibm.com/articles/l-virtio/>`__  
译文 `virtio —— 一种 Linux I/O 半虚拟化框架 [译]-腾讯云开发者社区-腾讯云  <https://cloud.tencent.com/developer/article/2312201>`__


智能网卡
----------
1. 传统网卡：guest的报文转发需要经过host内核，依赖bridge模块或open virtual switch(OVS)进行。
2. 智能网卡：具备硬件卸载功能的网卡设备。报文直接在网卡转发，使用SRIOV、virtio等协议。

SRIOV：将pcie设备的pf分为多个vf给多个虚拟机使用，虚拟机可以绕过中间虚拟层，直接使用pcie设备处理IO和传输数据。


