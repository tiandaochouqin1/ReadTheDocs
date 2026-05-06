======================
Socket编程及调优
======================

:Date:   2021-07-31 15:17:13

.. admonition:: 摘要

   梳理 TCP/UDP Socket 编程的系统调用、套接字选项配置以及 Nagle/DelayAck 调优策略，适合需要编写高性能网络应用或排查连接问题的后端/系统开发者。配合 `Packet Send & Recieve <./Pkt_Snd&Rcv.rst>`__ 阅读效果更佳。

socket
============


1. `Linux 网络栈接收数据（RX）：配置调优（2022）  <https://arthurchiao.art/blog/linux-net-stack-tuning-rx-zh/>`__
2. 参考《Packet Send & Recieve》的资料

udp tcp sctp
------------------
- udp：用户数据报协议，无连接。
- tcp：传输控制协议，面向连接、可靠全双工、字节流，确认、超时、重传。
- sctp：流控制传输协议，面向连接(关联)、可靠全双工、消息服务、多宿。可接受对端的事件通知

socket系统函数
----------------

tcp socket过程
~~~~~~~~~~~~~~~~

.. figure:: /images/Socket/socket_tcp_procedure.jpg
   :scale: 70%

   socket_tcp_procedure


::

   #include <sys/socket.h>

   int socket(int family, int type, int protocol)  // 返回非负的套接字描述符,主动套接字

   int connect(int sockfd, const struct sockaddr *servaddr, socklen_t addrlen)  // servaddr包含服务器ip和端口

   int bind(int sockfd, const struct sockaddr *myaddr, socklen_t addrlen)  //绑定本端端口、ip

   int listen(int sockfd, int backlog) // 转化为被动套接字，即监听描述符。backlog - socket排队的最大连接数

   int accept(int sockfd, struct sockaddr *cliaddr, socklen_t *addrlen) // 三次握手，然后返回已连接描述符和client地址


socket选项
~~~~~~~~~~~
::

   int getdockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen)

   int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen)

connect/accept完成三次握手后返回已连接套接字，并从监听套接字继承以下属性故这些属性需要在accept之前设置：
``SO_DEBUG、SO_DONTROUTE、SO_KEEPALIVE\SO_LINGER、SO_OOBILINE、SO_RCVBUF、SO_SNDBUF、SO_RCVLOWAT、SO_SNDLOWAT、TCP_MACMSG、TCP_DELAY``

1. https://man7.org/linux/man-pages/man7/socket.7.html
2. `linux - How do SO_REUSEADDR and SO_REUSEPORT differ? - Stack Overflow  <https://stackoverflow.com/questions/14388706/how-do-so-reuseaddr-and-so-reuseport-differ>`__

::

   UNP 7.5

   SO_KEEPALIVE: 2h后发送保活探测分节。检测对端主机奔溃、不可达等状态（即半开连接）

   SO_RCVBUF: client在connect之前设置，sever在listen之前设置。因为tcp窗口规模是在建立连接时通过互换syn分节得到的。
   SO_SNDBUF: client保存发送的seg，直到收到ack

   SO_REUSEADDR: 允许使用不同IP(如通配符与特定IP)重用相同port；某些协议(如udp)支持完全重复的ip+port。
   SO_REUSEPORT: 由多播的引入而添加到选项。相同ip+port的所有套接字都指定本选项时才支持完全重复的绑定。多播时与SO_REUSEADDR同义。

   SO_LINGER: 控制close函数的返回时机和行为。

   TCP_NODELAY/SCTP_NODELAY:  禁止Nagle算法
   TCP_MAXSEG/SCTP_MAXSEG:  最大分节MSS，通常来源于对端的syn


- Nagle算法：减少网络上的分组数量。当有一个未确认分组时，则不继续发送
- Ack延滞算法：收到数据后不立即恢复ack，等待一段时间，期望自身数据发送时捎带上ack，减少tcp分节。


tcp条件检测：

.. figure:: /images/Socket/tcp_stat_check.jpg
   :scale: 80%

   tcp_stat_check


shutdown和close: 半开连接
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
::

   int shutdown(int sockfd, int howto)

   close(int sockfd)  //尝试将sndbuf的数据发送，并立即返回。 SO_LINGER可改变此默认行为。


.. figure:: /images/Socket/socket_shutdown_close.jpg
   :scale: 70%

   socket_shutdown_close


fcntl ioctl 描述符控制
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. figure:: /images/Socket/sockect_fd_property.jpg
   :scale: 80%

   socket_protocol

最后一列表示posix推荐的方式。

socket()
~~~~~~~~~~~~~~~~~
family+type -> protocol

.. figure:: /images/Socket/socket_protocol.jpg
   :scale: 80%

   socket_protocol


bind(): tcp client 通常不会绑定ip，内核根据路由选择.

fork(): 实现网络多线程
~~~~~~~~~~~~~~~~~~~~~~~~~
1. 需要处理SIGCHLD信号，使用waitpid避免留下僵死进程。waitpid可指定子进程和是否阻塞，wait不能；
2. 捕获信号时，需处理被中断的系统调用。返回值为EINTR则重启socket函数（connect除外）.

.. _socket_nagle:

nagle算法与delay ack
---------------------

上面梳理了套接字的基本操作和选项配置，但在实际调优中，影响 TCP 小包性能最直接的就是 Nagle 算法和 Delay Ack 的相互作用。下面分别拆解。

nagle算法：
~~~~~~~~~~~~~~~~~~
设计目标：在保证时效的前提下，减少小包发送，增加报文有效负载比。

实现：当要发送的数据累积大于MSS或包包含FIN时才允许发送报文。否则要等到每次收到对方的ack时才发送。

问题：

开关：TCP_QUICKACK

delay ack: 
~~~~~~~~~~~~~~~~
设计目标：在保证时效的前提下，减少ack包数量。

实现：延时发送ack，直到超时200ms，或发送数据时捎带上ack。

问题：与nagle、慢启动、拥塞避免一起使用时会有性能问题。

开关： TCP_NODELAY



.. figure:: /images/Socket/nagle-algorithm-delay-ack.jpg
   :scale: 60%

   nagle-algorithm-delay-ack



selective ack
~~~~~~~~~~~~~~~~~
快速重传：采用累积确认，即确认收到的完整序列的最大编号。

选择确认：允许携带4个组已接收的序号范围，告诉发送方哪些报文丢失了。

发送方收到了三次同样的 ACK 确认报文，于是就会触发快速重发机制，实现只重传丢失的报文。


Linux 下，可以通过net.ipv4.tcp_sack参数打开。


Duplicate selective ack
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
使用了 SACK 来告诉「发送方」有哪些数据被重复接收了（快速重传机制下的假丢包）。

让「发送方」知道，是发出去的包丢了，还是接收方回应的 ACK 包丢了;

可以知道是不是「发送方」的数据包被网络延迟了;

可以知道网络中是不是把「发送方」的数据包给复制了。

Linux 下可以通过net.ipv4.tcp_dsack参数开启/关闭这个功能。

.. _socket_io_multiplex:

I/O复用：select和poll
------------------------

了解了 TCP 的可靠性机制后，接下来看一个服务端必须面对的问题：如何同时管理成千上万个连接。I/O 复用是答案。
io模型
~~~~~~~~~~~
同步IO模型：其真正的IO操作会阻塞进程。包括阻塞式IO、非阻塞式IO、IO复用、信号驱动式IO。

.. figure:: /images/Socket/IO_models.jpg
   :scale: 70%

   IO_models


select
~~~~~~~~~~~~~~~~

:: 

   int select(int maxfdp1, fd_set *readset, fd_set *writeset, fd_set * *exceptset, const struct timeval *timeout)

   fd_set: 描述符集。通常是一个整数数组，每整数的每一位对应一个描述符。
           select返回时，fd_set就绪位置1，因此重新select之前需要重新设置fd_set。

   maxfdp1: 待测试的描述符个数。0开始，即最大描述符+1.

   void FD_ZERO(fd_set *fdset)
   void FD_SET(int fd, fd_set *fdset)
   void FD_CLR(int fd, fd_set *fdset)
   int FD_ISSET(int fd, fd_set *fdset)



select就绪条件：

.. figure:: /images/Socket/select_ready_condition.jpg

   select_ready_condition


套接字描述符唯一的异常条件是带外数据的到达。


poll
~~~~~~~~~

::

   int poll(struct pollfd *fdarrya, unsigned long nfds, int timeout)

   struct pollfd {
       int fd;
       short events;   /* para in. event of interest */
       short revents;  /* return */
   }



poll识别三类数据：normal、priority band、high priority，体现在event/revent中。


.. figure:: /images/Socket/poll_events_revents.jpg
   :scale: 70%

   poll_events_revents



udp socket
--------------

.. figure:: /images/Socket/udp_exchg.jpg
   :scale: 70%

   udp_exchg


udp套接字函数
~~~~~~~~~~~~~~~~~
::

   ssize_t recvfrom(int sockfd, oid *buff, size_t nbytes, int flags, struct sockaddr *from, socklen_t *addrlen)

   ssize_t sendto  (int sockfd, oid *buff, size_t nbytes, int flags, const struct sockaddr *to, socklen_t *addrlen)

   recvfrome/sendto 返回值为所读写的数据大小，recvfrom返回0是可接受的。都可以用于tcp。


若client没有绑定port，则首次sendto时内核选择一个临时端口。

无连接，意味着udp每个数据报的目的地址可变。


- 弱端系统模型：大多数ip实现接收目的地址为本机任一ip地址的数据报，而不管数据报到达的接口。
- 网卡混杂模式：网卡能够接收所有经过它的数据流，而不论其目的地址(mac)是否是它。


.. figure:: /images/Socket/socket_datagram_info.jpg
   :scale: 100%

   socket_datagram_info



已连接udp socket与异步错误
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
只有已连接的udp socket，其引发的异步错误(如icmp端口不可达)才会返回给它。

connect后即为已连接socket。 

1. 存储了对方的ip+port，后面socket需使用write/send、read/recv/recvmsg。
2. 选择了本地ip和路由。


.. figure:: /images/Socket/udp_connected_socket.jpg
   :scale: 80%

   udp_connected_socket


未连接socket每次需要复制一次目的ip+port的套接字结构体，约占整个udp传输的的1/3。故udp多次使用同一目的地址时，已连接套接字效率更高。

name and address
--------------------

tcp ip illustrated
=======================

长肥管道：高带宽或高延时网络。

FIN：本端不再发送数据，对端将其作为文件结束符传递给应用。


TCP报文段结构
----------------
`https://www.ietf.org/rfc/rfc793.txt  <https://www.ietf.org/rfc/rfc793.txt>`__

::

       0                   1                   2                   3   
       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |          Source Port          |       Destination Port        |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                        Sequence Number                        |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                    Acknowledgment Number                      |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |  Data |           |U|A|P|R|S|F|                               |
      | Offset| Reserved  |R|C|S|S|Y|I|            Window             |
      |       |           |G|K|H|T|N|N|                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |           Checksum            |         Urgent Pointer        |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                    Options                    |    Padding    |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                             data                              |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


长度20B，带选项可达60B。

1. 序号：报文的首字节的字节编号，初始为随机生成，c/s两端各有一个。
2. 确认号：期望收到的下一字节的序号。
3. 接收窗口：指示接收方愿意接收的字节数量，用于流量控制。
4. 6比特标识字段：ACK、RST、SYN、FIN、PSH、URG。
5. The checksum field is the 16-bit ones' complement of the ones' complement sum of all 16-bit words in the header and text. 
   见 `ComputerNetwork <./ComputerNetwork.rst>`_



tcp状态转换和分组交换
------------------------

.. figure:: /images/Socket/tcp_state_trans.jpg
   :scale: 80%

   tcp_state_trans

.. figure:: /images/Socket/tcp_seg_exchg.jpg
   :scale: 70%

   tcp_seg_exchg


TIME_WAIT状态为 2*MSL：

1. 实现全双工连接的可靠终止：发送最后一个ack后进入TIME_WAIT并持续2msl。若最后一个ack丢失，则client维护的状态可允许server retransfer FIN(tcp总是重传fin)。
2. 2msl保证老连接的重复分节在网络上消逝：若老连接结束后出现一个ip+port均一样的连接，则可避免新连接被老连接的分组影响。

tcp超时与重传
--------------
1. rtt的几种算法
2. 重传二义性：不能区分是对第一次还是第二次的传输的的确认。karn算法：重传时间指数退避和接收到重传数据的确认信息时不用于更新rtt估计值(解决二义性问题)
3. 快速重传：基于接收端的反馈信息来引发重传，及时有效修复丢包。当失序数据到达时，应立即回复ack。重复ack阈值dupthresh 用于确定是否重传。
4. 伪超时与伪重传

重传超时算法
~~~~~~~~~~~~~
EWMA: 指数加权移动平均、低通过滤器。

1. 经典方法： 得到srtt即平滑的rtt估计值

.. math::

   SRTT ⬅ α(SRTT) + (1- α)RTT-SRTT

   RTO = min( ubound, max(lbound, (SRTT)β))


2. 标准方法：结合平均值和平均偏差。

.. math::

   Err = M RTT-SRTT

   srtt ⬅ srtt + g(Err)

   rttvar ⬅ rttvar + h(|Err| - rttvar)

   RTO = srtt + s(rttvar)



3. Linux采用的方法： mdev(计算方法同标准方法中的rttvar)和mdev_max(本方法实际使用的rttvar)

  1) Linux采用更频繁地RTT测量和更细的时钟粒度。可能导致rttvar趋于最小。—— 记录mdev_max，保证rttvar>=mdev_max
  2) 标准方法中实际RTT大幅降低也会导致RTO增大。 —— Linux方法针对这种情况会减少新样本的权重。

伪超时与伪重传
~~~~~~~~~~~~~~~~
伪重传原因包括伪超时、包失序、包重复、ack丢失。

伪超时：实际rtt显著增长，超过当前rto时，可能出现。处理伪超时的两种方法：检测算法和响应算法。

细分为：

1. 伪超时：通过检查ack或原始传输能假造检测出。Eifel检测算法、F-RTO
2. 迟伪超时：基于超时（伪）而引发的重传所返回的ack来判定。dsack


**重传计时器超时后记录新变量srtt_prev和rttvar_prev，触发检测算法，得到伪重传标志，然后在响应算法中更新srtt、rttvar、RTO的值。**


**检测算法**：用于判断某个超时或基于计时器的重传是否真实。

1. 重复sack(dsack)扩展：sack可告知失序报文段。在sack接收端赛用dsack，可在第一个sack块中告知接收端收到的重复报文段序列号，以判断不必要的重传。
2. Eifel检测算法：利用tcp的tsopt来检测伪重传（保存重传的tsv值并与ack比较）。Eifel比dsack能更早地检测到伪重传，有效避免 回退N 行为。
3. 前移RTO恢复（F-RTO）: 检测伪重传的标准算法，只检测由重传计时器引发的伪重传。 重传计时器超时后接收到第一个ack时，发送新数据并检查下一个ack，若这两个ack都是acceptable(即非重复ack，acceptable ACKs that advance the sender’s window),则是伪重传。

Eifel响应算法：

1. 可与任何检测算法结合
2. 延迟大幅增长的情况下会重设srtt和rttvar

包失序与包重复
~~~~~~~~~~~~~~~~
重复 和 严重失序 都比较少见。

失序：ip层不能保证传输有序。

1. 反向（ack）链路失序：导致发送窗口快速前移，流量突发；
2. 正向链路：无法正确区分失序和丢包，导致伪重传（重复ack导致快速重传）。

重复：IP协议可能会把一个包传输多次，如 **链路层协议的重传** 。可采用sack、dsack。  
`这一次，彻底拿下计算机网络链路层！ - 程序员cxuan - 博客园  <https://www.cnblogs.com/cxuanBlog/p/14600398.html>`__

重新组包：超时重传时，不需要重传完全相同的报文段（tcp根据字节号识别数据），可发送一个更大的报文段来提升性能。

存储连接状态
~~~~~~~~~~~~~~
与同一个接收端建立新tcp连接时，会基于之前保存的度量值来设置初始值。（路由、转发表项、或其它系统数据结构）

tcp数据流与窗口管理
--------------------

1. 延时Ack
2. nagle算法
3. 窗口通告和窗口检测
4. 糊涂窗口综合征
5. 缓存、自动调优
6. 滑动窗口

与tcp相关的攻击
--------------------
tcp重传相关的攻击
~~~~~~~~~~~~~~~~~~
1. 低速率dos攻击：使target感知拥塞，持续处于超时重传状态，无法正常使用网络带宽。
2. 使target rtt估计过大，减慢target发送。
3. 使target rtt估计过小，造成大量无效传输。


.. _socket_debug:

调试技巧
========

排查连接问题
------------

**检查监听端口和连接状态：**

.. code-block:: bash

   # 列出所有 TCP 监听端口及对应进程
   ss -nltp

   # 列出所有已建立的 TCP 连接
   ss -ntp state established

   # 查看 TIME_WAIT 状态的连接数
   ss -ant | grep TIME_WAIT | wc -l

**追踪套接字选项生效情况：**

.. code-block:: bash

   # 查看某个进程的套接字选项（如 SO_REUSEADDR、TCP_NODELAY）
   ss -ntpoe | grep <pid>

**排查半开连接：**

.. code-block:: bash

   # 查看 CLOSE_WAIT 堆积（服务端未正确 close）
   ss -antp state close-wait

   # 查看 FIN_WAIT2 堆积（服务端未发送 FIN）
   ss -antp state fin-wait-2

调优 Nagle 和 Delay Ack
------------------------

.. code-block:: bash

   # 关闭 Nagle 算法（减少小包延迟，适合交互式应用）
   int flag = 1;
   setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));

   # 关闭 Delay Ack（减少 ack 等待时间，与 TCP_NODELAY 搭配使用）
   int flag = 1;
   setsockopt(fd, IPPROTO_TCP, TCP_QUICKACK, &flag, sizeof(flag));

.. note::

   TCP_NODELAY 和 TCP_QUICKACK 配对禁用能有效降低延迟，但会增加小包数量。适合 Redis、SSH 等延迟敏感场景；不适合大文件传输。

抓包验证

.. code-block:: bash

   # 抓取特定端口的 TCP 包，观察 Nagle 行为（小包是否合并）
   tcpdump -i eth0 -nn port 8080 -A

   # 观察三次握手和选项协商（MSS、窗口缩放、SACK 等）
   tcpdump -i eth0 -nn 'tcp[tcpflags] & (tcp-syn|tcp-fin) != 0'

查看内核 TCP 参数

.. code-block:: bash

   # 查看当前 TCP 调优参数
   sysctl -a | grep net.ipv4.tcp | grep -E "sack|nodelay|rmem|wmem"

   # 查看套接字缓冲区大小
   sysctl net.ipv4.tcp_rmem net.ipv4.tcp_wmem

追踪套接字系统调用

.. code-block:: bash

   # strace 追踪进程的 socket 调用（connect/bind/listen/setsockopt）
   strace -e trace=network -p <pid>


.. _socket_takeaways:

关键要点
========

1. **listen 的 backlog** — 影响的是已完成三次握手的连接队列（全连接队列），不是半连接队列。队列溢出时内核默认丢弃，可通过 ``net.core.somaxconn`` 调大。
2. **SO_REUSEADDR vs SO_REUSEPORT** — 前者允许绑定不同 IP 的相同端口；后者允许多个进程绑定完全相同的 IP+端口，常用于多进程负载均衡（如 Nginx worker）。
3. **Nagle + Delay Ack 互斥效应** — 当写入的数据小于 MSS 且对端启用了 Delay Ack 时，Nagle 会等 ack，Delay Ack 会等数据，形成 200ms 的僵持。解决方案就是同时禁用两者。
4. **UDP 已连接套接字** — 连接后使用 write/read 而非 sendto/recvfrom，可减少 1/3 的传输开销（避免每次复制目标地址），且能接收异步错误（ICMP 端口不可达）。

.. seealso::

   `Packet Send & Recieve <./Pkt_Snd&Rcv.rst>`_
      深入内核收发包路径，理解 Ring Buffer、NAPI、软中断的完整流程。

   `Computer Network <./ComputerNetwork.rst>`_
      计算机网络各层协议的系统性讲解，与本文 TCP 状态机、RTT 计算部分互补。
