
======================
Packet Send & Recieve
======================

:Date:   2021-07-31 15:17:13


参考文档TODO
=============

   
1.  `系列文章 <https://www.privateinternetaccess.com/blog/linux-networking-stack-from-the-ground-up-part-1/>`__ 。2022有更新

   `Linux 网络栈监控和调优：接收数据 <http://arthurchiao.art/blog/tuning-stack-rx-zh/>`__；
   `英文原版 <https://blog.packagecloud.io/eng/2016/06/22/monitoring-tuning-linux-networking-stack-receiving-data/>`__；
   `英文版配图 <https://blog.packagecloud.io/eng/2016/10/11/monitoring-tuning-linux-networking-stack-receiving-data-illustrated/>`__

   `Linux 网络栈监控和调优：发送数据 <http://arthurchiao.art/blog/tuning-stack-tx-zh/>`__；
   `英文原版 <https://blog.packagecloud.io/eng/2017/02/06/monitoring-tuning-linux-networking-stack-sending-data/>`__；



2. `极客时间-趣谈Linux操作系统 <https://zter.ml/>`__
3. 《深入linux内核架构》 ：大体框架

4.  :download:`ULNI </books/Understanding_Linux_Network_Internals.pdf>` 
5. `图解Linux网络包接收过程 <https://zhuanlan.zhihu.com/p/256428917>`__ 
    :download:`理解了实现再谈网络性能 </books/理解了实现再谈网络性能.pdf>` 
    
6. :download:`追踪Linux.TCP／IP代码运行：基于2.6内核 </books/追踪Linux.TCP／IP代码运行：基于2.6内核.pdf>` 



问题记录
------------
1. TCP/IP中tcp可靠性？其它层为什么不可靠？
2. dpdk、netfilter、ebpf
3. BBR


socket
============


udp tcp sctp
------------------
- udp：用户数据报协议，无连接。
- tcp：传输控制协议，面向连接、可靠全双工、字节流，确认、超时、重传。
- sctp：流控制传输协议，面向连接(关联)、可靠全双工、消息服务、多宿。可接受对端的事件通知

socket系统函数
----------------

tcp socket过程
~~~~~~~~~~~~~~~~

.. figure:: /images/socket_tcp_procedure.jpg
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

.. figure:: /images/tcp_stat_check.jpg
   :scale: 80%

   tcp_stat_check


shutdown和close: 半开连接
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
::

   int shutdown(int sockfd, int howto)

   close(int sockfd)  //尝试将sndbuf的数据发送，并立即返回。 SO_LINGER可改变此默认行为。


.. figure:: /images/socket_shutdown_close.jpg
   :scale: 70%

   socket_shutdown_close


fcntl ioctl 描述符控制
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. figure:: /images/sockect_fd_property.jpg
   :scale: 80%

   socket_protocol

最后一列表示posix推荐的方式。

socket()
~~~~~~~~~~~~~~~~~
family+type -> protocol

.. figure:: /images/socket_protocol.jpg
   :scale: 80%

   socket_protocol


bind(): tcp client 通常不会绑定ip，内核根据路由选择.

fork(): 实现网络多线程
~~~~~~~~~~~~~~~~~~~~~~~~~
1. 需要处理SIGCHLD信号，使用waitpid避免留下僵死进程。waitpid可指定子进程和是否阻塞，wait不能；
2. 捕获信号时，需处理被中断的系统调用。返回值为EINTR则重启socket函数（connect除外）.

I/O复用：select和poll
------------------------
io模型
~~~~~~~~~~~
同步IO模型：其真正的IO操作会阻塞进程。包括阻塞式IO、非阻塞式IO、IO复用、信号驱动式IO。

.. figure:: /images/IO_models.jpg
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

.. figure:: /images/select_ready_condition.jpg

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


.. figure:: /images/poll_events_revents.jpg
   :scale: 70%

   poll_events_revents



udp socket
--------------

.. figure:: /images/udp_exchg.jpg
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


.. figure:: /images/socket_datagram_info.jpg
   :scale: 100%

   socket_datagram_info



已连接udp socket与异步错误
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
只有已连接的udp socket，其引发的异步错误(如icmp端口不可达)才会返回给它。

connect后即为已连接socket。 

1. 存储了对方的ip+port，后面socket需使用write/send、read/recv/recvmsg。
2. 选择了本地ip和路由。


.. figure:: /images/udp_connected_socket.jpg
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

.. figure:: /images/tcp_state_trans.jpg
   :scale: 80%

   tcp_state_trans

.. figure:: /images/tcp_seg_exchg.jpg
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

Linux网络IO模式
================
1. `Linux IO模式及 select、poll、epoll详解 <https://segmentfault.com/a/1190000003063859>`__


.. figure:: /images/IO_models.png

   IO 模式比较



当一个read操作发生时，它会经历两个阶段：

1. 等待数据经网卡到达内核；non-blocking/blocking IO指的就是这一步。
2. 数据从内核态拷贝到用户态；在等待拷贝完成的过程中，Linux都会阻塞当前线程。

同步和异步描述的则是read的整个过程。

在处理 IO 的时候，阻塞和非阻塞都是同步 IO。只有使用了特殊的 API(部分系统实现) 才是异步 IO。

同步与异步
-------------
关注的是通信机制。用户角度，如

- 同步：发出一个调用后，在没得到结果之前主动等待，该调用不返回。一旦返回就得到了返回值。
- 异步：发出一个调用后，这个调用直接返回，无返回值。而后被调用者会通过状态、通知来通知调用者，或使用回调函数来处理这个调用。

POSIX的定义：

- A synchronous I/O operation causes the requesting process to be blocked until that I/O operation completes;
- An asynchronous I/O operation does not cause the requesting process to be blocked;

阻塞和非阻塞
-------------------
关注的是程序在等待 **调用结果** （消息，返回值）时的状态。

- 阻塞调用是指调用结果返回之前，当前线程会被挂起。调用线程只有在得到结果之后才会返回。
- 非阻塞调用指在不能立刻得到结果之前立即返回，不阻塞进程；而在数据已经准备好了的时候，会将数据从内核拷贝到用户态，这个过程中线程阻塞。

poll与epoll
-----------

1. 在 select/poll中，进程只有在调用一定的方法后，内核才对所有监视的文件描述符进行遍历扫描。
2. epoll事先通过epoll_ctl()来注册一 个文件描述符，一旦基于某个文件描述符就绪时，
   内核会采用类似callback的回调机制，迅速激活这个文件描述符，当进程调用epoll_wait() 时便得到通知。
   (此处去掉了遍历文件描述符，而是通过监听回调的的机制。)
 

网卡收包与中断上下文
==========================
> ULNI：chapter9/10


1. https://code.woboq.org/linux/linux/net/core/dev.c.html#net_rx_action
2. `linux 网络收包流程（NAPI） <https://flyingbyte.cc/post/napi-in-linux.cn>`__
3. `Linux协议栈--NAPI机制 <http://cxd2014.github.io/2017/10/15/linux-napi/>`__
4. `Linux内核源码分析--详谈NAPI原理机制 <https://zhuanlan.zhihu.com/p/403239331>`__
5. `内核网络中的GRO、RFS、RPS技术介绍和调优 <http://kerneltravel.net/blog/2020/network_ljr9/>`__


6. `结合中断分析TCP/IP协议栈在LINUX内核中的运行时序 <https://www.cnblogs.com/ypholic/p/14337328.html>`__


socket收包过程
----------------

1. 网卡将数据帧DMA到内存的RingBuffer中，然后向CPU发起中断通知
2. CPU响应中断请求，调用网卡启动时注册的中断处理函数
3. 中断处理函数几乎没干啥，就发起了软中断请求
4. 内核线程ksoftirqd线程发现有软中断请求到来，先关闭硬中断
5. ksoftirqd线程开始调用驱动的poll函数收包
6. poll函数将收到的包送到协议栈注册的ip_rcv函数中
7. ip_rcv函数再讲包送到udp_rcv函数中（对于tcp包就送到tcp_rcv）

.. figure:: /images/pkt_rcv.png

   收包过程


NAPI
-------
轮询+中断，比netif_rx性能好。

1. 减少中断。
2. 多设备公平。


NAPI的工作机制如下：

1. 第一个分组将导致网络适配器发出IRQ，为防止进一步的分组导致更多的IRQ，驱动程序会关闭该适配器的rx IRQ，并将该适配器放到一个轮询表上。
    关闭设备中断后，设备收到包后不再产生中断（或者内核不再响应中断），而只是将数据包放到DMA中。
2. 只要适配器上还有分组需要处理，内核就一直对轮询表上的设备进行轮询，处理剩下的分组。

3. 重新启动rx IRQ。


设备满足如下两个条件，才能实现NAPI方法：

1. 设备必须能够保留多个接收的分组，例如保存到DMA环形缓冲区中。
2. 设备必须能够禁止用于接收分组的IRQ，而且发送分组或其他可能通过IRQ进行的操作，都仍然必须是启用的。

::

   IRQ
    ->__napi_schedule
        ->进入软中断
            ->net_rx_action
                ->napi_poll
                    ->驱动注册的poll
                        ->napi_gro_receive。



``napi时使用napi_schedule发起软中断，软中断中执行net_rx_action``


napi_schedule源码
~~~~~~~~~~~~~~~~~~~~~
napi_schedule -> __napi_schedule -> ____napi_schedule -> __raise_softirq_irqoff 然后在软中断中调用

::

   
   /**
    *	napi_schedule - schedule NAPI poll
    *	@n: NAPI context
    *
    * Schedule NAPI poll routine to be called if it is not already
    * running.
    */
   static inline void napi_schedule(struct napi_struct *n)
   {
   	if (napi_schedule_prep(n))
   		__napi_schedule(n);
   }


   
   /* Called with irq disabled */
   static inline void ____napi_schedule(struct softnet_data *sd,
   				     struct napi_struct *napi)
   {
   	list_add_tail(&napi->poll_list, &sd->poll_list);
   	__raise_softirq_irqoff(NET_RX_SOFTIRQ);
   }



net_rx_action
-----------------
很下半部收包函数， ``NAPI设备和非NAPI设备都会使用net_rx_action来收包``。
该函数的主要工作就是操作收包队列和执行poll函数。


net_rx_action -> nic_poll -> 注册的用户实现的poll/process_backlog 

linux 通过软中断机制调用网络协议栈代码，处理数据。 在 net_dev 模块初始化时，注册网络收发数据的软中断处理函数：

::

   static int __init net_dev_init(void)
   {
   	open_softirq(NET_TX_SOFTIRQ, net_tx_action);
   	open_softirq(NET_RX_SOFTIRQ, net_rx_action);
   }


kernel 为每个 cpu 创建一个本地的数据结构： softnet_data，在代码中简写为 sd。

::
      
   DEFINE_PER_CPU_ALIGNED(struct softnet_data, softnet_data);
   EXPORT_PER_CPU_SYMBOL(softnet_data);

   struct softnet_data {
   	// 当前 CPU 需要被处理的 napi 链表
   	struct list_head	poll_list;


   	struct sk_buff_head	process_queue;

   	/* Non-NAPI
   	   软中断 NET_RX_SOFTIRQ 处理这个队列中的数据
        This queue, initialized in net_dev_init, is where incoming frames are stored before being processed by the driver. 
        It is used by non-NAPI drivers; those that have been upgraded to NAPI use their own private queues.
   	*/
      struct sk_buff_head	input_pkt_queue;

   	struct napi_struct	backlog;
   };


netif_rx
--------------

1. https://www.cnblogs.com/hustcat/archive/2009/09/26/1574371.html

.. figure:: /images/netif_rx.png


在传统的收包方式中，数据帧向网络协议栈中传递发生在中断上下文（在接收数据帧时）中调用netif_rx的函数中。
变体netif_rx_ni被用于中断上下文之外。


netif_rx函数在收包过程中用到了napi_strcut结构，因为软中断处理使用了NAPI的框架（软中断流程类似）。也用到了net_rx_action。

kernel 在 sd 中实现了一个缺省的 napi_struct : backlog，以兼容不支持 NAPI 机制的网卡驱动。

netif_rx源码
~~~~~~~~~~~~~

https://code.woboq.org/linux/linux/net/core/dev.c.html#netif_rx

netif_rx可用于中断和进程上下文；__netif_rx用于中断上下文。


``netif_rx -> netif_rx_internal -> enqueue_to_backlog -> ____napi_schedule + __skb_queue_tail``

::

    /**
    *	netif_rx	-	post buffer to the network code
    *	@skb: buffer to post
    *
    *	This function receives a packet from a device driver and queues it for
    *	the upper (protocol) levels to process.  It always succeeds. The buffer
    *	may be dropped during processing for congestion control or by the
    *	protocol layers.
    *
    *	return values:
    *	NET_RX_SUCCESS	(no congestion)
    *	NET_RX_DROP     (packet was dropped)
    *
    */

   int netif_rx(struct sk_buff *skb)
   {
   	int ret;
   	trace_netif_rx_entry(skb);
   	ret = netif_rx_internal(skb);
   	trace_netif_rx_exit(ret);
   	return ret;
   }
   EXPORT_SYMBOL(netif_rx);


    /*
    * enqueue_to_backlog is called to queue an skb to a per CPU backlog
    * queue (may be a remote CPU queue).
    */


在中断期间处理多帧
~~~~~~~~~~~~~~~~~~
一些驱动虽然没有使用NAPI收包机制，但在驱动中通过设置类似weight的权值，实现在一个中断到来时尝试处理多个数据包。

在中断处理程序中添加了一个quota值限定每次中断可以处理数据包的个数，在每次中断到来时关闭设备自身的收包中断，并尝试从DMA中获取不大于quota数量的数据包，
交给netif_rx处理或直接交给netif_receive_skb()。



tcpdump原理
============
1. `用户态 tcpdump 如何实现抓到内核网络包的?  <https://mp.weixin.qq.com/s/ZX8Jluh-RgJXcVh3OvycRQ>`__
2. `图解Linux网络包接收过程  <https://mp.weixin.qq.com/s?__biz=MjM5Njg5NDgwNA==&mid=2247484058&idx=1&sn=a2621bc27c74b313528eefbc81ee8c0f&scene=21#wechat_redirect>`__
3. `25 张图，一万字，拆解 Linux 网络包发送过程  <https://mp.weixin.qq.com/s?__biz=MjM5Njg5NDgwNA==&mid=2247485146&idx=1&sn=e5bfc79ba915df1f6a8b32b87ef0ef78&scene=21#wechat_redirect>`__
4. `Linux 网络设备驱动开发（一） —— linux内核网络分层结构_mb5fe94ba3ca002的技术博客_51CTO博客  <https://blog.51cto.com/u_15069477/3560475>`__

tcpdump使用指南
----------------

1. `全网最详细的 tcpdump 使用指南 - 王一白 - 博客园  <https://www.cnblogs.com/wongbingming/p/13212306.html>`__

 
libpcap原理
------------
注册一个虚拟协议，收发包时会送虚拟协议处理，这时拷贝skb。

抓包位置分析
--------------


.. figure:: /images/pkt_tx.png

    pkt_tx

.. figure:: /images/net_dev_layer.png

    net_dev_layer


收包
~~~~~
rx比tx经过的路径少，无网络设备子系统层？？？。因为已经硬中断已经区分了硬件接口/队列?

::

   netif_receive_skb->..-> __netif_receive_skb_core函数中抓包

   	list_for_each_entry_rcu(ptype, &ptype_all, list) {
		if (pt_prev)
			ret = deliver_skb(skb, pt_prev, orig_dev);
		pt_prev = ptype;
      }

发包
~~~~~~~~~~~
网络设备子系统抓包。主要实现队列选择

dev_queue_xmit->   : Queue a buffer for transmission to a network device

::

   dev_queue_xmit->   : Queue a buffer for transmission to a network device
      
      ..->dev_hard_start_xmit->xmit_one

                                 -> dev_queue_xmit_nit ： 这里抓包
                                 -> netdev_start_xmit ->..->(net_device_ops->ndo_start_xmit)


::

   static int xmit_one(struct sk_buff *skb, struct net_device *dev,
            struct netdev_queue *txq, bool more)
   {
      unsigned int len;
      int rc;

      if (dev_nit_active(dev))
         dev_queue_xmit_nit(skb, dev);

      len = skb->len;
      PRANDOM_ADD_NOISE(skb, dev, txq, len + jiffies);
      trace_net_dev_start_xmit(skb, dev);
      rc = netdev_start_xmit(skb, dev, txq, more);
      trace_net_dev_xmit(skb, rc, dev, len);

      return rc;
   }



