
====================
Linux Route
====================

:Date:   2020-04-01 15:37:13


参考资料
==============

1. https://man7.org/linux/man-pages/man8/ip.8.html
2. `网络基本功 <https://www.bookstack.cn/read/network-basic/0.md>`__ or 
   `网络基本功 <https://wizardforcel.gitbooks.io/network-basic/content/index.html>`__
   :download:`NetworkBasics.pdf <../files/NetworkBasics.pdf>`


ip命令
=======

1. https://man7.org/linux/man-pages/man8/route.8.html

2. https://wangchujiang.com/linux-command/c/ip.html


用来显示或操纵Linux主机的路由、网络设备、策略路由和隧道，是Linux下较新的功能强大的网络配置工具。

语法
----

::

   ip(选项)(参数)
   Usage: ip [ OPTIONS ] OBJECT { COMMAND | help }
          ip [ -force ] -batch filename

选项
~~~~

::

   OBJECT := { link | address | addrlabel | route | rule | neigh | ntable |
          tunnel | tuntap | maddress | mroute | mrule | monitor | xfrm |
          netns | l2tp | macsec | tcp_metrics | token }
          
   -V：显示指令版本信息；
   -s：输出更详细的信息；
   -f：强制使用指定的协议族；
   -4：指定使用的网络层协议是IPv4协议；
   -6：指定使用的网络层协议是IPv6协议；
   -0：输出信息每条记录输出一行，即使内容较多也不换行显示；
   -r：显示主机时，不使用IP地址，而使用主机的域名。

参数
~~~~

::

   OPTIONS := { -V[ersion] | -s[tatistics] | -d[etails] | -r[esolve] |
           -h[uman-readable] | -iec |
           -f[amily] { inet | inet6 | ipx | dnet | bridge | link } |
           -4 | -6 | -I | -D | -B | -0 |
           -l[oops] { maximum-addr-flush-attempts } |
           -o[neline] | -t[imestamp] | -ts[hort] | -b[atch] [filename] |
           -rc[vbuf] [size] | -n[etns] name | -a[ll] }
           
   网络对象：指定要管理的网络对象；
   具体操作：对指定的网络对象完成具体操作；
   help：显示网络对象支持的操作命令的帮助信息。

实例
----

::

   ip -s link show                     # 显示网络接口信息
   ip link set eth0 up             # 开启网卡

   ip route list                       #核心路由表  = 等效于 route 命令

   #本机与192.168.98.0/24范围内的主机通信，需要途径网关192.168.99.1
   ip route add 192.168.98.0/24 via 192.168.99.1
   route add -net 192.168.98.0 netmask 255.255.255.0 gw 192.168.99.1

   ip neigh list                       #邻居表

   ip link | grep -E '^[0-9]' |awk -F: '{print $2}'  #网卡列表

iptables
========

Netfilter
---------

netfilter 是 Linux
内置的一种防火墙机制，我们一般也称之为\ ``数据包过滤机制``\ 。iptables
则是一个命令行工具，用来配置 netfilter 防火墙。

netfilter
在协议栈中添加了一些钩子，它允许内核模块通过这些钩子注册回调函数，这样经过钩子的所有数据包都会被注册在相应钩子上的函数所处理，包括修改数据包内容、给数据包打标记或者丢掉数据包等。netfilter
框架负责维护钩子上注册的处理函数或者模块，以及它们的优先级。netfilter
框架负责在需要的时候动态加载其它的内核模块，比如
ip_conntrack、nf_conntrack、NAT subsystem 等。

iptables 是运行在用户态的一个程序，通过 netlink 和内核的 netfilter
框架打交道，并负责往钩子上配置回调函数。

iptables 工作原理
-----------------

`iptables <https://wangchujiang.com/linux-command/c/iptables.html>`__

iptables的结构：\ ``iptables -> Tables -> Chains -> Rules.``
简单地讲，tables由chains组成，而chains又由rules组成。

-  Rules包括一个条件和一个目标(target)
-  如果满足条件，就执行目标(target)中的规则或者特定值。
-  如果不满足条件，就判断下一条Rules。

命令选项输入顺序
~~~~~~~~~~~~~~~~

::

   iptables -t 表名 
            <-A/I/D/R> 规则链名 [规则号] 
            <-i/o 网卡名> 
            -p 协议名 
            <-s 源IP/源子网> 
            --sport 源端口 
            <-d 目标IP/目标子网> 
            --dport 目标端口 
            -j 动作

四种内建表
~~~~~~~~~~

1. Filter表
   Filter表示iptables的默认表，因此如果你没有自定义表，那么就默认使用filter表，它具有以下三种内建链：

   -  INPUT链 – 处理来自外部的数据。
   -  OUTPUT链 – 处理向外发送的数据。
   -  FORWARD链 – 将数据转发到本机的其他网卡设备上。

2. NAT表 NAT表有三种内建链：

   -  PREROUTING链 –
      处理刚到达本机并在路由转发前的数据包。它会转换数据包中的目标IP地址（destination
      ip address），通常用于DNAT(destination NAT)。

   -  POSTROUTING链 –
      处理即将离开本机的数据包。它会转换数据包中的源IP地址（source ip
      address），通常用于SNAT（source NAT）。

   -  OUTPUT链 – 处理本机产生的数据包。

3. Mangle表
   Mangle表用于指定如何处理数据包。它能改变TCP头中的QoS位。Mangle表具有5个内建链：

   -  PREROUTING

   -  OUTPUT

   -  FORWARD

   -  INPUT

   -  POSTROUTING

4. Raw表 Raw表用于处理异常，它具有2个内建链：

   -  PREROUTING chain

   -  OUTPUT chain

iptables还支持自己定义链。但是自己定义的链，必须是跟某种特定的链关联起来的。在一个关卡设定，指定当有数据的时候专门去找某个特定的链来处理，当那个链处理完之后，再返回。接着在特定的链中继续检查。

注意：规则的次序非常关键，谁的规则越严格，应该放的越靠前，而检查规则的时候，是按照从上往下的方式进行检查的。

规则链
~~~~~~

(也被称为五个钩子函数（hook functions）)：

-  INPUT链 ：处理输入数据包。
-  OUTPUT链 ：处理输出数据包。
-  FORWARD链 ：处理转发数据包。
-  PREROUTING链 ：用于目标地址转换（DNAT）。
-  POSTOUTING链 ：用于源地址转换（SNAT）。

动作
~~~~

-  ACCEPT ：接收数据包。
-  DROP ：丢弃数据包。
-  REDIRECT ：重定向、映射、透明代理。
-  SNAT ：源地址转换。
-  DNAT ：目标地址转换。
-  MASQUERADE ：IP伪装（NAT），用于ADSL。
-  LOG ：日志记录。

基本参数
--------

========== ==============================================
参数       作用
========== ==============================================
-P         设置默认策略:iptables -P INPUT (DROP
-F         清空规则链
-L         查看规则链
-A         在规则链的末尾加入新规则
-I         num 在规则链的头部加入新规则
-D         num 删除某一条规则
-s         匹配来源地址IP/MASK，加叹号“!”表示除这个IP外。
-d         匹配目标地址
-i         网卡名称 匹配从这块网卡流入的数据
-o         网卡名称 匹配从这块网卡流出的数据
-p         匹配协议,如tcp,udp,icmp
–dport num 匹配目标端口号
–sport num 匹配来源端口号
========== ==============================================

::

   -t, --table table 对指定的表 table 进行操作， table 必须是 raw， nat，filter，mangle 中的一个。如果不指定此选项，默认的是 filter 表。

源地址目标地址的匹配
~~~~~~~~~~~~~~~~~~~~

::

   -p：指定要匹配的数据包协议类型；
   -s, --source [!] address[/mask] ：把指定的一个／一组地址作为源地址，按此规则进行过滤。当后面没有 mask 时，address 是一个地址，比如：192.168.1.1；当 mask 指定时，可以表示一组范围内的地址，比如：192.168.1.0/255.255.255.0。
   -d, --destination [!] address[/mask] ：地址格式同上，但这里是指定地址为目的地址，按此进行过滤。
   -i, --in-interface [!] <网络接口name> ：指定数据包的来自来自网络接口，比如最常见的 eth0 。注意：它只对 INPUT，FORWARD，PREROUTING 这三个链起作用。如果没有指定此选项， 说明可以来自任何一个网络接口。同前面类似，"!" 表示取反。
   -o, --out-interface [!] <网络接口name> ：指定数据包出去的网络接口。只对 OUTPUT，FORWARD，POSTROUTING 三个链起作用。

查看管理命令
~~~~~~~~~~~~

::

   -L, --list [chain] 列出链 chain 上面的所有规则，如果没有指定链，列出表上所有链的所有规则。

规则管理命令
~~~~~~~~~~~~

::

   -A, --append chain rule-specification 在指定链 chain 的末尾插入指定的规则，也就是说，这条规则会被放到最后，最后才会被执行。规则是由后面的匹配来指定。
   -I, --insert chain [rulenum] rule-specification 在链 chain 中的指定位置插入一条或多条规则。如果指定的规则号是1，则在链的头部插入。这也是默认的情况，如果没有指定规则号。
   -D, --delete chain rule-specification -D, --delete chain rulenum 在指定的链 chain 中删除一个或多个指定规则。
   -R num：Replays替换/修改第几条规则

链管理命令（立即生效）
~~~~~~~~~~~~~~~~~~~~~~

::

   -P, --policy chain target ：为指定的链 chain 设置策略 target。注意，只有内置的链才允许有策略，用户自定义的是不允许的。
   -F, --flush [chain] 清空指定链 chain 上面的所有规则。如果没有指定链，清空该表上所有链的所有规则。
   -N, --new-chain chain 用指定的名字创建一个新的链。
   -X, --delete-chain [chain] ：删除指定的链，这个链必须没有被其它任何规则引用，而且这条上必须没有任何规则。如果没有指定链名，则会删除该表中所有非内置的链。
   -E, --rename-chain old-chain new-chain ：用指定的新名字去重命名指定的链。这并不会对链内部造成任何影响。
   -Z, --zero [chain] ：把指定链，或者表中的所有链上的所有计数器清零。

   -j, --jump target <指定目标> ：即满足某条件时该执行什么样的动作。target 可以是内置的目标，比如 ACCEPT，也可以是用户自定义的链。
   -h：显示帮助信息；

原理图
------

::

                                       ┏╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┓
           ┌───────────────┐           ┃    Network    ┃
           │ table: filter │           ┗━━━━━━━┳━━━━━━━┛
           │ chain: INPUT  │◀────┐             │
           └───────┬───────┘     │             ▼
                   │             │   ┌───────────────────┐
           ┌      ▼      ┐       │   │ table: nat        │
           │local process│       │   │ chain: PREROUTING │
           └             ┘       │   └─────────┬─────────┘
                   │             │             │
                   ▼             │             ▼              ┌─────────────────┐
           ┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅   │     ┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅      │table: nat       │
           Routing decision      └───── outing decision ─────▶│chain: PREROUTING│
           ┅┅┅┅┅┅┅┅┅┳┅┅┅┅┅┅┅┅┅          ┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅      └────────┬────────┘
                   │                                                   │
                   ▼                                                   │
           ┌───────────────┐                                           │
           │ table: nat    │           ┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅               │
           │ chain: OUTPUT │    ┌─────▶ outing decision ◀──────────────┘
           └───────┬───────┘    │      ┅┅┅┅┅┅┅┅┳┅┅┅┅┅┅┅┅
                   │            │              │
                   ▼            │              ▼
           ┌───────────────┐    │   ┌────────────────────┐
           │ table: filter │    │   │ chain: POSTROUTING │
           │ chain: OUTPUT ├────┘   └──────────┬─────────┘
           └───────────────┘                   │
                                               ▼
                                       ┏╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┓
                                       ┃    Network    ┃
                                       ┗━━━━━━━━━━━━━━━┛

常用命令
--------

``root 用户执行``, sudo找不到命令。

**永久保存**

::

   iptables-save > /etc/network/iptables.up.rules

Ubuntu iptables默认重启服务器后清空，需在/etc/network/interfaces里写入

::

   pre-up iptables-restore < /etc/network/iptables.up.rules
    
   post-down iptables-save > /etc/network/iptables.up.rules

备份与恢复

::


   sudo iptables-save > iptables.conf
   sudo iptables-restore < iptables.conf

应用策略

::

   iptables-apply
   执行iptables-apply默认指向该文件/etc/network/iptables.up.rules

清空当前的所有规则和计数

::

   iptables -F  # 清空所有的防火墙规则
   iptables -X  # 删除用户自定义的空链
   iptables -Z  # 清空计数

配置允许ssh端口连接

::

   iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 22 -j ACCEPT
   ## 22为你的ssh端口， -s 192.168.1.0/24表示允许这个网段的机器来连接，其它网段的ip地址是登陆不了你的机器的。 -j ACCEPT表示接受这样的请求

允许本地回环地址可以正常使用

::

   iptables -A INPUT -i lo -j ACCEPT
   ##本地圆环地址就是那个127.0.0.1，是本机上使用的,它进与出都设置为允许
   iptables -A OUTPUT -o lo -j ACCEPT

设置默认的规则

::

       iptables -P INPUT DROP # 配置默认的不让进
       iptables -P FORWARD DROP # 默认的不允许转发
       iptables -P OUTPUT ACCEPT # 默认的可以出去

配置白名单

::

       iptables -A INPUT -p all -s 192.168.1.0/24 -j ACCEPT  # 允许机房内网机器可以访问
       iptables -A INPUT -p tcp -s 183.121.3.7 --dport 3380 -j ACCEPT # 允许183.121.3.7访问本机的3380端口

开启相应的服务端口

::

       iptables -A INPUT -p tcp --dport 80 -j ACCEPT # 开启80端口，因为web对外都是这个端口
       iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT # 允许被ping
       iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # 已经建立的连接得让它进来

保存规则到配置文件中

::

       cp /etc/sysconfig/iptables /etc/sysconfig/iptables.bak # 任何改动之前先备份，请保持这一优秀的习惯
       iptables-save > /etc/sysconfig/iptables
       cat /etc/sysconfig/iptables

列出已设置的规则

::

       iptables -L [-t 表名] [链名]

       iptables -L -nv  # 查看，这个列表看起来更详细

删除已添加的规则

::

       # 添加一条规则
       iptables -A INPUT -s 192.168.1.5 -j DROP
       将所有iptables以序号标记显示，执行：

       iptables -L -n --line-numbers
       比如要删除INPUT里序号为8的规则，执行：

       iptables -D INPUT 8

屏蔽IP

::

       iptables -A INPUT -p tcp -m tcp -s 192.168.0.8 -j DROP  # 屏蔽恶意主机（比如，192.168.0.8
       iptables -I INPUT -s 123.45.6.7 -j DROP       #屏蔽单个IP的命令
       iptables -I INPUT -s 123.0.0.0/8 -j DROP      #封整个段即从123.0.0.1到123.255.255.254的命令
       iptables -I INPUT -s 124.45.0.0/16 -j DROP    #封IP段即从123.45.0.1到123.45.255.254的命令
       iptables -I INPUT -s 123.45.6.0/24 -j DROP    #封IP段即从123.45.6.1到123.45.6.254的命令是

启动网络转发规则

::

       公网210.14.67.7让内网192.168.188.0/24上网
       iptables -t nat -A POSTROUTING -s 192.168.188.0/24 -j SNAT --to-source 210.14.67.127

本机的 2222 端口映射到内网 虚拟机的22 端口

::

       iptables -t nat -A PREROUTING -d 210.14.67.127 -p tcp --dport 2222  -j DNAT --to-dest 192.168.188.115:22

字符串匹配

::

   比如，我们要过滤所有TCP连接中的字符串test，一旦出现它我们就终止这个连接，我们可以这么做：

::

       iptables -A INPUT -p tcp -m string --algo kmp --string "test" -j REJECT --reject-with tcp-reset
       iptables -L

阻止Windows蠕虫的攻击

::

       iptables -I INPUT -j DROP -p tcp -s 0.0.0.0/0 -m string --algo kmp --string "cmd.exe"
       防止SYN洪水攻击
       iptables -A INPUT -p tcp --syn -m limit --limit 5/second -j ACCEPT

ufw
~~~

``UFW``\ 命令是管理iptables防火墙规则的一个用户友好的前端，使管理iptables更容易

::

   ufw status verbose
   ufw app list
   ufw app info 'Nginx Full'
   ufw allow 8000:8100/tcp
   ufw allow https
   ufw allow in on eth2 to any port 3306
   ufw allow from 192.168.1.0/24 to any port 33066

**ufw无法开机启动**\ ： 发现是已经安装\ ``firewalld``,Firewalld是RHEL
7系列上的默认防火墙管理软件。

需要停止并关闭firewalld自启动。

-  前面无法使用\ ``iptables-restore``\ 也是这个原因。




测试目标是否在监听端口
======================

根据目标服务协议选择适合的工具！

`如何测试端口通不通(四种方法） <https://blog.csdn.net/swazer_z/article/details/64442730>`__

telnet只能用于测试TCP端口，而nc即可用于测试TCP端口也可用来测试UDP端口。



方法概述
----------

需要主机在端口提供了服务，以web服务器为例。


**准备环境**

启动一个web服务器，提供端口.

::

       [wyq@localhost ~]$ python -m SimpleHTTPServer 8080
       Serving HTTP on 0.0.0.0 port 8080 ...


telnet连接tcp端口
----------------------

telnet是windows标准服务，可以直接用；如果是linux机器，需要安装telnet.

**用法: telnet ip port**

1）先用telnet连接不存在的端口

::

       [root@localhost ~]# telnet 10.0.250.3 80
       Trying 10.0.250.3...
       telnet: connect to address 10.0.250.3: Connection refused #直接提示连接被拒绝

2）再连接存在的端口

::

       [root@localhost ~]# telnet localhost 22
       Trying ::1...
       Connected to localhost. #看到Connected就连接成功了
       Escape character is '^]'.
       SSH-2.0-OpenSSH_5.3
       a
       Protocol mismatch.
       Connection closed by foreign host.

ssh测试tcp端口
------------------

ssh是linux的标准配置并且最常用

**用法: ssh -v -p port username@ip**

-  -v 调试模式(会打印日志).
-  -p 指定端口
-  username可以随意

1）连接不存在端口

::

       [root@localhost ~]# ssh 10.0.250.3 -p 80
       ssh: connect to host 10.0.250.3 port 80: Connection refused
       [root@localhost ~]# ssh 10.0.250.3 -p 80 -v
       OpenSSH_5.3p1, OpenSSL 1.0.1e-fips 11 Feb 2013
       debug1: Reading configuration data /etc/ssh/ssh_config
       debug1: Applying options for *
       debug1: Connecting to 10.0.250.3 [10.0.250.3] port 80.
       debug1: connect to address 10.0.250.3 port 80: Connection refused
       ssh: connect to host 10.0.250.3 port 80: Connection refused

2）连接存在的端口

[root@localhost ~]# ssh … -p

::

       [root@localhost ~]# ssh ... -p -v
       OpenSSH_.p, OpenSSL ..e-fips Feb
       debug: Reading configuration data /etc/ssh/ssh_config
       debug: Applying options for *
       debug: Connecting to ... [...] port .
       debug: Connection established.
       debug: permanently_set_uid: /
       debug: identity file /root/.ssh/identity type -
       debug: identity file /root/.ssh/identity-cert type -
       debug: identity file /root/.ssh/id_rsa type -
       debug: identity file /root/.ssh/id_rsa-cert type -
       debug: identity file /root/.ssh/id_dsa type -
       debug: identity file /root/.ssh/id_dsa-cert type -
       a
       ^C

wget和curl
------------
支持的协议？


wget是linux下的下载工具，需要先安装. 用法: ``wget ip:port``

1）连接不存在的端口

::

       [root@localhost ~]# wget ...:
       ---- ::-- http://.../
       Connecting to ...:... failed: Connection refused.

2）连接存在的端口

::

       [root@localhost ~]# wget ...:
       ---- ::-- http://...:/
       Connecting to ...:... connected.
       HTTP request sent, awaiting response...

专用工具tcping
--------------

`tcping <https://elifulkerson.com/projects/tcping.php>`__


netstat扫描监听端口
-------------------
tcp/udp

netstat参数解释：

::

       -l  (listen) 仅列出 Listen (监听) 的服务
       -t  (tcp) 仅显示tcp相关内容
       -n (numeric) 直接显示ip地址以及端口，不解析为服务名或者主机名
       -p (pid) 显示出socket所属的进程PID 以及进程名字
       --inet 显示ipv4相关协议的监听

Nmap网络扫描和嗅探
------------------
支持tcp/udp


1. `nmap命令-基础用法 <https://www.cnblogs.com/nmap/p/6232207.html>`__
2. `Nmap <https://nmap.org/download.html>`__\ 是一款网络扫描和主机检测的非常有用的工具，可以用来作为一个漏洞探测器或安全扫描器。适用于winodws,linux,mac等操作系统

**功能** 
1. 扫描主机端口，嗅探所提供的网络服务 
2. 探测一组主机是否在线 
3. 推断主机所用的操作系统，到达主机经过的路由，系统已开放端口的软件版本

扫描tcp端口
~~~~~~~~~~~

B机器上使用nmap扫描A机器所有端口（-p后面也可以跟空格）

下面表示扫描A机器的1到65535所有在监听的tcp端口。

``nmap 10.0.1.161  -p1-65535``

指定端口范围使用-p参数。Nmap默认扫描从1到1024再加上nmap-services列出的端口。

nmap-services是一个包含大约2200个著名的服务的数据库。

nmap端口状态解析
~~~~~~~~~~~~~~~~

+-----------------------------------+-----------------------------------+
| 状态                              | 解析                              |
+===================================+===================================+
| **open**                          | 应用程序在该端口接收 TCP 连接或者 |
|                                   | UDP 报文。                        |
+-----------------------------------+-----------------------------------+
| **closed**                        | 关闭的端口对于nmap也是可访问的，  |
|                                   | 它接收nmap探测报文并作出          |
|                                   | 响应。但没有应用程序在其上监听。  |
+-----------------------------------+-----------------------------------+
| **filtered**                      | 于包过滤阻止探测报文到达端口，n   |
|                                   | map无法确定该端口是否开放。过滤可 |
|                                   | 能来自专业的防火墙设备，路由规则  |
|                                   | 或者主机上的软件防火墙。          |
+-----------------------------------+-----------------------------------+
| **unfiltered**                    | 未被过滤状态意味着端口可访问，但  |
|                                   | 是nmap无法确定它是开放还是关闭。  |
|                                   | 只有用于映射防火墙规则集的 ACK    |
|                                   | 扫描才会把端口分类到这个状态。    |
+-----------------------------------+-----------------------------------+
| **open/filtered**                 | 无法确定端口是开放还是被过滤，    |
|                                   | 开放的端口不响应                  |
|                                   | 就是一个例子。没有响应也可能意味  |
|                                   | 着报文过滤器丢弃了探测报文或者它  |
|                                   | 引发的任何反应。UDP，IP协议,FIN,  |
|                                   | Null 等扫描会引起。               |
+-----------------------------------+-----------------------------------+
| **closed/filtered**               | （关闭或者被过滤的）：            |
|                                   | 无法确定端口是关闭的还是被过滤的  |
+-----------------------------------+-----------------------------------+

其它功能
~~~~~~~~

1. 扫描一个IP的多个端口：连续的端口可以使用横线\ ``-``\ 连起来，端口之间可以使用\ ``,``\ 逗号隔开；
2. 扫描多个IP：中间用空格分开；
3. 扫描连续的ip地址：横线连接；
4. 扫描一个子网网段所有IP：\ ``nmap  10.0.3.0/24``\ ；
5. 扫描文件里的IP：\ ``nmap -iL ip.txt``\ ；
6. 扫描地址段时排除某个IP地址:``nmap 10.0.1.161-162  --exclude 10.0.1.162``\ 。


