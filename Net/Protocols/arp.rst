
arp原理与源码
=============

ARP具有MAC头，消息体包含网络层地址和MAC地址，故有重复信息。

ARP地址解析协议
------------------
1. `arp(7) - Linux manual page  <https://man7.org/linux/man-pages/man7/arp.7.html>`__
2. `邻居子系统之邻居项状态更新_fanxiaoyu321的博客-CSDN博客  <https://blog.csdn.net/xiaoyu_750516366/article/details/104590052>`__
3. `邻居子系统_fanxiaoyu321的博客-CSDN博客  <https://blog.csdn.net/xiaoyu_750516366/category_9761623.html>`__
4. `Linux网络协议栈3--neighbor子系统 - 简书  <https://www.jianshu.com/p/afee7bada23a>`__
5. `linux arp机制解析 | i博客  <https://vcpu.me/linuxarp/>`__
   
   arping会让对端增加arp且处于stale? ping但禁止了回应，会让对端+delay？


``ip neigh show``

nud状态转换
~~~~~~~~~~~~~
.. figure:: /images/nud_states_transmitions.png
   :scale: 80%

   nud状态转换

   

.. figure:: /images/nud_states_transition_2.png
   :scale: 60%

   nud状态转换-简化版


关键函数
~~~~~~~~~~~~
1. neigh_timer_handler：异步，会有延时。 定时器超时事件导致的状态机更新。L4 confirmation后要到下一次timer执行状态转换。
2. neigh_update ：同步。RX solicitation reply。
3. neigh_resolve_output-> neigh_event_send，数据报文接收事件导致的状态机更新。更新neigh结构体各个状态值、timer管理
4. neigh_periodic_work : 工作队列实现。hash表维护，neigh_rand_reach_time、neigh_cleanup_and_release。每BASE_REACHABLE_TIME/2 遍历hash buckets。
5. arp_ioctl : 用户io接口—— del/set/get 

::

   ioctl: 
   arp_req_get -> arp_state_to_flags -> return ATF_COM;
   #define NUD_VALID	(NUD_PERMANENT|NUD_NOARP|NUD_REACHABLE|NUD_PROBE|NUD_STALE|NUD_DELAY) 

neigh_periodic_work： https://linux-kernel-labs.github.io/refs/heads/master/labs/deferred_work.html
::
      
   INIT_DEFERRABLE_WORK(&tbl->gc_work, neigh_periodic_work);
   queue_delayed_work(system_power_efficient_wq, &tbl->gc_work,
         tbl->parms.reachable_time);


3个关键时间
~~~~~~~~~~~~
::

   neigh->confirmed: 可达确认
   neigh->used: 被使用
   neigh->updated :nud_state更新


neigh_update
----------------------------
协议报文接收事件导致的状态机更新，直接的状态维护可能是在调用它的函数中，

收到arp request/reply报文（arp_process），静态配置arp表项(neigh_add)等。

::

      We want to add an entry to our cache if it is a reply
   *  to us or if it is a request for our address.

	if (n) {
		int state = NUD_REACHABLE;
		int override;

		/* If several different ARP replies follows back-to-back,
		   use the FIRST one. It is possible, if several proxy
		   agents are active. Taking the first reply prevents
		   arp trashing and chooses the fastest router.
		 */
		override = time_after(jiffies,
				      n->updated +
				      NEIGH_VAR(n->parms, LOCKTIME)) ||
			   is_garp;

		/* Broadcast replies and request packets
		   do not assert neighbour reachability.
		 */
		if (arp->ar_op != htons(ARPOP_REPLY) ||
		    skb->pkt_type != PACKET_HOST)
			state = NUD_STALE;
		neigh_update(n, sha, state,
			     override ? NEIGH_UPDATE_F_OVERRIDE : 0, 0);
		neigh_release(n);
	}





neigh_timer_handler
----------------------
定时器超时事件导致的状态机更新。

reachable->stale/delay部分。

::

   if (state & NUD_REACHABLE) {
		if (time_before_eq(now,
				   neigh->confirmed + neigh->parms->reachable_time)) {
			neigh_dbg(2, "neigh %p is still alive\n", neigh);
			next = neigh->confirmed + neigh->parms->reachable_time;
		} else if (time_before_eq(now,
					  neigh->used +
					  NEIGH_VAR(neigh->parms, DELAY_PROBE_TIME))) {     // 最近是否被使用过
			neigh_dbg(2, "neigh %p is delayed\n", neigh);
			neigh->nud_state = NUD_DELAY;
			neigh->updated = jiffies;
			neigh_suspect(neigh);
			next = now + NEIGH_VAR(neigh->parms, DELAY_PROBE_TIME);
		} else {
			neigh_dbg(2, "neigh %p is suspected\n", neigh);
			neigh->nud_state = NUD_STALE;
			neigh->updated = jiffies;
			neigh_suspect(neigh);
			notify = 1;
		}
   } 



可达性确认与L4 confirm
-------------------------------
可达性确认(变为reachable)有两种方式：
1. 收到unicast solicitation' reply。（broadcast solicitation's reply则变为stale）
2. L4的有数据流的信息（IP层无），当host收到neighbor's pkt是对以前host发出去的pkt的回应，则说明neighbor可达。

L4 confirm
~~~~~~~~~~~~~~~
1. tcp的ack包，发出即可达确认。
2. 其它协议在传输函数中使用MSG_CONFIRM标志来确认可达。Valid only on  SOCK_DGRAM and SOCK_RAW sockets and currently implemented only for IPv4 and IPv6. 


好乱!!

::
      
   ip协议：ip_finish_output2->sock_confirm_neigh->skb_get_dst_pending_confirm并更新 neigh->confirmed 

         __ip_append_data(MSG_CONFIRM)->skb_set_dst_pending_confirm

         __tcp_send_ack-> **__tcp_transmit_skb 每个tcp都是?** ->skb_set_dst_pending_confirm -> __ip_queue_xmit ->ip_output 

                        -> tcp_send_syn_data : Build and send a SYN with data and (cached) Fast Open cookie.
                                             -> 
                                                   err = tp->fastopen_req ? tcp_send_syn_data(sk, buff) :
                                                         tcp_transmit_skb(sk, buff, 1, sk->sk_allocation);

   套接字： raw_sendmsg/udp_sendmsg(MSG_CONFIRM)->dst_confirm_neigh->.confirm_neigh->ipv4_confirm_neigh 更新 neigh->confirmed




发出L4 confirm ?

::

   MSG_CONFIRM: 阻止 ARP 缓存过期


   if (msg->msg_flags&MSG_CONFIRM)
            goto do_confirm;
   back_from_confirm:


MSG_CONFIRM
~~~~~~~~~~~~~~~~~~
1. `arp(7) - Linux manual page  <https://man7.org/linux/man-pages/man7/arp.7.html>`__
2. `send(2) - Linux manual page  <https://man7.org/linux/man-pages/man2/sendmsg.2.html>`__



查看arp配置
-----------
1. `邻居表项的retrans_time时长_redwingz的博客-CSDN博客_retrans timer  <https://blog.csdn.net/sinat_20184565/article/details/109655387>`__

常用命令
~~~~~~~~~~~~
1. ``ip ntable show dev eth0``
2. ``arp_tbl`` 里定义了值(net\ipv4\arp.c : neigh_table arp_tbl), neigh_sysctl_table定义了PROC文件信息
3. ``/proc/sys/net/ipv4/neigh/eth0/``

arp_tbl
~~~~~~~~~~~~~

::

   struct neigh_table arp_tbl = {
      .family		= AF_INET,
      .key_len	= 4,
      .protocol	= cpu_to_be16(ETH_P_IP),
      .hash		= arp_hash,
      .key_eq		= arp_key_eq,
      .constructor	= arp_constructor,
      .proxy_redo	= parp_redo,
      .is_multicast	= arp_is_multicast,
      .id		= "arp_cache",
      .parms		= {
         .tbl			= &arp_tbl,
         .reachable_time		= 30 * HZ,
         .data	= {
            [NEIGH_VAR_MCAST_PROBES] = 3,
            [NEIGH_VAR_UCAST_PROBES] = 3,
            [NEIGH_VAR_RETRANS_TIME] = 1 * HZ,
            [NEIGH_VAR_BASE_REACHABLE_TIME] = 30 * HZ,
            [NEIGH_VAR_DELAY_PROBE_TIME] = 5 * HZ,
            [NEIGH_VAR_GC_STALETIME] = 60 * HZ,
            [NEIGH_VAR_QUEUE_LEN_BYTES] = SK_WMEM_MAX,
            [NEIGH_VAR_PROXY_QLEN] = 64,
            [NEIGH_VAR_ANYCAST_DELAY] = 1 * HZ,
            [NEIGH_VAR_PROXY_DELAY]	= (8 * HZ) / 10,
            [NEIGH_VAR_LOCKTIME] = 1 * HZ,
         },
      },
      .gc_interval	= 30 * HZ,
      .gc_thresh1	= 128,
      .gc_thresh2	= 512,
      .gc_thresh3	= 1024,
   };


proc neigh配置查看
~~~~~~~~~~~~~~~~~~~~~
`/proc/sys/net/ipv4/neigh/eth0/`

1. base_reachable_time_ms: 30000
2. gc_stale_time: 60,还需要满足refcnt=1.(或refcnt=1 且fail)
3. delay_first_probe_time: 5
4. retrans_time_ms：1000。函数 neigh_max_probes 值，计算结果为3。3次*1s = 3s




::

   static __inline__ int neigh_max_probes(struct neighbour *n)
   {
      struct neigh_parms *p = n->parms;
      return NEIGH_VAR(p, UCAST_PROBES) + NEIGH_VAR(p, APP_PROBES) +
            (n->nud_state & NUD_PROBE ? NEIGH_VAR(p, MCAST_REPROBES) :
            NEIGH_VAR(p, MCAST_PROBES));
   }

   对应 ubuntu 5.4.0-42-generic #46-Ubuntu SMP Fri Jul 10 00:24:02 UTC 2020 x86_64 

   mcast_solicit  3
   app_solicit  0
   ucast_solicit  3
   mcast_resolicit  0


neigh_rand_reach_time
~~~~~~~~~~~~~~~~~~~~~~~~~~
30即15~44

net\core\neighbour.c : neigh_periodic_work -> neigh_rand_reach_time

::

   unsigned long neigh_rand_reach_time(unsigned long base)
   {
      return base ? (prandom_u32() % base) + (base >> 1) : 0;
   }
   
