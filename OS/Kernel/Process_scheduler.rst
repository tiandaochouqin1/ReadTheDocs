=====
进程
=====
进程管理与生命周期
===================

进程管理
---------
* 进程：处于执行期的程序以及相关资源的总称。
* 程序：存放在存储介质上的。

管理结构
~~~~~~~~~~~~~~
1. 任务队列：task_struct双向循环列表。
2. 进程描述符（task_struct）中保存了能完整描述一个正在执行的程序的左右数据。1.7KB(32位机器)。
3. 使用slab分配器分配，实现对象复用和缓存着色。
4. thread info结构在进程内核栈尾端分配，包含了指向task_struct的指针。
5. current宏：一个宏，找到当前进程的进程描述符。

进程的五种状态
~~~~~~~~~~~~~~

1. TASK_RUNNING: 运行——可执行的,即正在执行或在运行队列中等待。 **用户空间进程的唯一状态**；内核进程也有此状态。
2. TASK_INTERRUPTIBLE: 可中断的——睡眠中，等待特定条件达成，可被信号唤醒。
3. TASK_UNINTERRUPTIBLE: 不可中断——睡眠中， **不会被信号唤醒**。在进程等待过程必须不受干扰或等待事件很快会发生时使用(硬件操作、io等)。
4. __TASK_TRACED: 被其他进程跟踪，如ptrace。
5. __TASK_STOPPED: 停止执行，进程没有投入运行也不能投入运行。通常发生在接收SIGSTOP、SIGTSTP、SIGTTIN、SIGTTOU等信号时。

.. figure:: /images/task_status.png
   :scale: 50%

   任务状态


::

   linux 5.8
   /*
    * Task state bitmask. NOTE! These bits are also
    * encoded in fs/proc/array.c: get_task_state().
    *
    * We have two separate sets of flags: task->state
    * is about runnability, while task->exit_state are
    * about the task exiting. Confusing, but this way
    * modifying one set can't modify the other one by
    * mistake.
    */

   /* Used in tsk->state: */
   #define TASK_RUNNING			0x0000
   #define TASK_INTERRUPTIBLE		0x0001
   #define TASK_UNINTERRUPTIBLE		0x0002
   #define __TASK_STOPPED			0x0004
   #define __TASK_TRACED			0x0008
   /* Used in tsk->exit_state: */
   #define EXIT_DEAD			0x0010
   #define EXIT_ZOMBIE			0x0020
   #define EXIT_TRACE			(EXIT_ZOMBIE | EXIT_DEAD)
   /* Used in tsk->state again: */
   #define TASK_PARKED			0x0040
   #define TASK_DEAD			0x0080
   #define TASK_WAKEKILL			0x0100
   #define TASK_WAKING			0x0200
   #define TASK_NOLOAD			0x0400
   #define TASK_NEW			0x0800
   #define TASK_STATE_MAX			0x1000



fork
-----
1. `vfork(2) - Linux manual page  <https://man7.org/linux/man-pages/man2/vfork.2.html>`__
2. `fork 在 Linux 内核里面的实现 - scriptk1d - 博客园  <https://www.cnblogs.com/crybaby/p/12938807.html#_do_frok>`__


开销： **复制父进程的页表和创建子进程的进程描述符。**

资源采用写时复制，即只有在需要写入时才拷贝页，是他们拥有独立的数据副本


线程：Linux中，只是进程间共享资源的手段。共享文件系统资源、地址空间、文件描述符和信号处理程序。

内核进程：没有独立的地址空间，可以被调度和抢占。


fork vfork clone比较
~~~~~~~~~~~~~~~~~~~~~

1. clone比fork提供更多选项控制父子进程共享的执行上下文；
2. vfork(与fork相比)calling 挂起，且共享所有memory(包括stack)，直到child结束或执行execv；vfork共享vm，不复制页表.

       it is used to create new
       processes without copying the page tables of the parent process.
       It may be useful in performance-sensitive applications where a
       child is created which then immediately issues an execve(2).

::


    vfork = clone + (CLONE_VM | CLONE_VFORK | SIGCHLD)
    
    ntpl  pthread_create = 
    const int clone_flags = (CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SYSVSEM | CLONE_SIGHAND | CLONE_THREAD | CLONE_SETTLS | CLONE_PARENT_SETTID | CLONE_CHILD_CLEARTID | 0);
    ARCH_CLONE (&start_thread, STACK_VARIABLES_ARGS, clone_flags, pd, &pd->tid, tp, &pd->tid)；




进程的生命周期
------------------
fork -> exec -> exit + wait

fork / clone(pthread_create) -> _do_fork -> copy_process

1.  dup_task_struct(): 创建内核栈、task_struct、thread_info.
2.  检查当前用户进程数目是否超出限制。
3.  清除任务描述法的部分统计信息，如运行统计。
4.  设置为 TASK_INTERRUPTIBLE。
5.  copy_flags()更新flags。
6.  alloc_pid()分配新PID。
7.  根据clone()传递的参数标识，copy_process()拷贝或共享 
    打开的文件、文件系统、信号处理函数、进程地址空间、命名空间等。
8. copy_process()返回指向子进程的指针。
9. _do_fork -> wake_up_new_task。
   设置为 TASK_RUNNING;
   activate_task 加入对应的调度队列；
   check_preempt_wakeup 设置父进程TIF_NEED_RESCHED，即在返回时抢占父进程，
   子进程先执行，避免写时复制的开销

exit() -> do_exit()

1. 设置task_struct的标识成员为PF_EXITING,表示正在退出。
2. 删除内核定时器。
3. 释放地址空间mm_struct。
4. exit_fs()、exit_files()，分别递减文件系统、文件描述符的引用计数。
5. 设置EXIT_ZOMBIE，调用schedule切换到新进程。
   
   * 这是进程执行的最后一段代码，do_exit永不返回。
   * 此时与进程相关的所有资源都被释放掉了。
   * 进程此时占有的内存只有内核栈、thread_info、task_struct。

6. 父进程可获取已终止的子进程信息wait4()，然后通知内核释放所占用的剩余资源，
   release_task() -> _exit_signal()

::

   kernel/exit.c
   void __noreturn do_exit(long code)
   {

   		preempt_count_set(PREEMPT_ENABLED);

   		set_current_state(TASK_UNINTERRUPTIBLE);
   		schedule();

   	exit_signals(tsk);  /* sets PF_EXITING */

   	exit_mm();

   	exit_sem(tsk);
   	exit_shm(tsk);
   	exit_files(tsk);
   	exit_fs(tsk);
   	if (group_dead)
   		disassociate_ctty(1);
   	exit_task_namespaces(tsk);
   	exit_task_work(tsk);
   	exit_thread(tsk);
   	exit_umh(tsk);

   	debug_check_no_locks_held();

   	if (tsk->io_context)
   		exit_io_context(tsk);

   	if (tsk->splice_pipe)
   		free_pipe_info(tsk->splice_pipe);

   	if (tsk->task_frag.page)
   		put_page(tsk->task_frag.page);

   	validate_creds_for_do_exit(tsk);

   	check_stack_usage();
   	preempt_disable();

   	exit_rcu();
   	exit_tasks_rcu_finish();

   	lockdep_free_task(tsk);
   	do_task_dead();
   }



进程调度
==============

Linux提供抢占式多任务模式（preemptive multitaking）。


调度程序：在TASK_RUNNING的进程之间分配有限的处理器时间资源。

调度策略的平衡： 优先调度IO消耗型以保证短的响应时间，或优先调度CPU消耗型以保证高吞吐量。

Linux更倾向于 ``优先调度IO消耗型进程``，以保证响应时间（交互式应用和桌面系统等）。



六大调度策略
----------------
1. `sched man <https://man7.org/linux/man-pages/man7/sched.7.html>`__ 讲得很清楚。
2. `翻译版 <https://www.cnblogs.com/charlieroro/p/12133100.html>`__ 。



1. SCHED_FIFO: 先进先出，无时间片。
2. SCHED_RR：时间片轮转，可抢占。
3. SCHED_DEADLINE：按照任务deadline来调度选择其 deadline 距离当前时间点最近的任务。
4. SCHED_OTHER：Linux中又名SCHED_NORMAL，根据nice值调度。
5. SCHED_BATCH：假定任务是CPU-intensive，对唤醒的进程做调度惩罚，即不提倡频繁切换。
6. SCHED_IDLE: nice值小于19，即用于优先级非常低的任务。

不同类型进程优先级为

::

    __stop_sched_class -> __dl_sched_class -> __rt_sched_class -> __fair_sched_class -> __idle_sched_class


实时策略
------------


调度器为每个优先级维护一个等待list。选择最高优先级的非空list的第一个成员来执行。
调度策略只能决定同一等待list（同一优先级）的进程执行顺序。

1. normal scheduling policies： (SCHED_OTHER, SCHED_IDLE, SCHED_BATCH), sched_priority must be specified as 0.

   The nice value  (SCHED_OTHER, SCHED_BATCH) influence the CPU scheduler to favor or disfavor a process in scheduling decisions.
   the range is -20 (high priority) to +19 (low priority).

2. **real-time policies**：(SCHED_FIFO, SCHED_RR, SCHED_DEADLINE) have a sched_priority value in the range **1 (low) to 99 (high)**.

Linux的实时调度算法提供了一种软实时的工作方式，即尽力使进程在它的限定时间到来前运行，但内核不保证总能满足要求。

Linux调度程序默认试图使进程尽量在同一个处理器运行（软亲和性），同时提供了强制亲和性（通过task_struct的cpus_allowed位掩码标志）。

FIFO与RR
~~~~~~~~~~~~~
1. `实时调度类分析 <https://www.cnblogs.com/arnoldlu/p/9025981.html>`__ （源码分析）

2. `Linux进程调度总结 <https://zhuanlan.zhihu.com/p/335846858>`__ (图不错)
3. `Linux schedule 调度算法  <https://mp.weixin.qq.com/s/GaZbL1LVq4rFmKIWwiKOeQ>`__

FIFO:严格按照优先级来执行，同一优先级先进先得到执行。

RR:调度策略，:存在一个RR_TIMESLICE时隙设置，可以通过调节时隙让各进程得到相对公平的机会。

当相同优先级的FIFO和RR进程执行时，RR相对吃亏，因为FIFO一旦抢占会执行到不会主动放弃。


RT Bandwidth
~~~~~~~~~~~~~~~~~~~~~~
RT进程和普通进程之间有一个分配带宽的比例，默认情况是 RT:CFS=95:5。

通过/proc/sys/kernel/sched_rt_period_us和/proc/sys/kernel/sched_rt_runtime_us来设置。


大小核与HFI
~~~~~~~~~~~~~~~~
1. `14. Hardware-Feedback Interface for scheduling on Intel Hardware — The Linux Kernel documentation  <https://docs.kernel.org/x86/intel-hfi.html#implementation-details-for-linux>`__

The Hardware Feedback Interface provides to the operating system information 
about the **performance and energy efficiency of each CPU** in the system. 
Each capability is given as a unit-less quantity in the range **[0-255]**. 
Higher values indicate higher capability. Energy efficiency and performance are reported in separate capabilities. 


调度器
~~~~~~~~~~~
每个CPU都有自己的 struct rq 结构，其用于描述在此 CPU 上所运行的所有进程，其包括一个实时进程队列 rt_rq 和一个 CFS 运行队列 cfs_rq。

调度类sched_class定义了很多种方法，用于操作上述调度队列上的任务。每种调度策略各实现了一种调度类，并放在同一个链表中。

调度类中的方法，如pick_next_task在不同的调度类中有不同的实现，返回空时则继续操作下一个队列。

1. fair_sched_class 的实现是 pick_next_task_fair，rt_sched_class 的实现是 pick_next_task_rt；
2. pick_next_task_rt 操作的是 rt_rq，pick_next_task_fair 操作的是 cfs_rq。

调用路径pick_next_task_fair -> pick_next_entity -> __pick_first_entity。

.. figure:: /images/sched.jpg
   :scale: 30%

   调度过程


O(1)调度
~~~~~~~~~

1. 140个成员的array,各成员各对应一个FIFO队列；
2. 使用位图来各队列是否为空；
3. 调度时间复杂度为 O(1).

.. figure:: /images/O(1)_schedule.jpg
   :scale: 50%

   Linux2.6.23以前的O(1)调度


休眠与唤醒
~~~~~~~~~~~~

休眠（被阻塞）通过等待队列处理，有两种状态，TASK_INTTERUPTIBLE和TASK_UNITTERUPTIBLE。

当与等待队列相关的时间发生时，队列上所有进程都会被唤醒（存在虚假唤醒）。

1. DEFINE_WAIT()创建一个等待队列的项；
2. add_wait_queue()加入队列中；
3. prepare_to_wait()设置进程状态为TASK_INTTERUPTIBLE或TASK_UNITTERUPTIBLE；
4. 若被信号唤醒，则检查条件是否为真；
5. 条件满足后设置状态为TASK_RUNNING并调用finish_wait()移出等待队列。

wake_up() -> try_to_wake_up()。通常是促使条件达成的代码来调用此函数，比如磁盘数据到来时，VFS需要调用。

1. 设置状态为TASK_RUNNIN并调用finish_wait；
2. enqueue_task()放入调度队列；
3. 若被唤醒的进程优先级比正在运行的进程优先级高，则设置need_resched标志。

wake_up
~~~~~~~~
1. `进程调度API之wake_up_process_tiantao2012的博客-CSDN博客  <https://blog.csdn.net/tiantao2012/article/details/78872831>`__
2. `sched feature: TTWU_QUEUE_yiyeguzhou100的博客-CSDN博客  <https://blog.csdn.net/yiyeguzhou100/article/details/104336751>`__
3. https://elixir.bootlin.com/linux/latest/source/kernel/sched/core.c#L3778

唤醒方式：

1. 分支1：cpus_share_cache判断如果目标CPU与当前CPU **不共享LLC**（即L3 cache），则将该线程加到目标cpu的wake_list后，向目标CPU发送 **IPI中断**。
2. 分支2：(同Cluster，非IPI形式)try_to_wake_up() 调用 ttwu_queue() 将这个唤醒的任务添加到队列当中。ttwu_queue() 再调用 ttwu_do_activate() 激活这个任务。ttwu_do_activate() 调用 ttwu_do_wakeup()



CFS调度
=========

`CFS调度器（2）-源码解析 <http://www.wowotech.net/process_management/448.html>`__

1. CFS调度完全摒弃时间片的分配方法，而是给进程分配处理器的使用比例，确保了进程调度中有恒定的公平性，而切换频率则是不断变化的。
2. CFS有一个分配时间的最小粒度，默认1ms，在可运行进程数量较多时，可将切换消耗限制在一定范围。
3. 进程获得的处理器时间由自己和其它所有可运行进程的nice值的差值决定，nice相差1则相差1.25倍时间。



cfs调度的实现
---------------

时间记账vruntime
~~~~~~~~~~~~~~~~~
CFS使用调度器实体结构来维护每个进程运行的时间记张。（linux/sched.h -> struct_sched_entity）


vruntime存放进程的虚拟运行时间，是所有可运行进程总数的加权计算结果。单位ns，与定时器节拍不相关。

``虚拟运行时间 vruntime += 实际运行时间 delta_exec * NICE_0_LOAD/ 权重``

系统定时器周期性调用 update_curr()，以更新所有进程的vruntime(包括可运行和阻塞态的所有进程)。

针对刚创建的进程会进行一定的惩罚，将虚拟时间加上一个值。

调度延时
~~~~~~~~~
又被称为调度周期，即该时间内所有任务均会被运行一次。

当进程数 < sched_nr_latency(默认为为8)时，值固定的为sysctl_sched_latency(6 ms)

当进程数 > sched_nr_latency(8)时,为进程数乘以sched_min_granularity_ns(0.75ms)

**sysctl_sched_latency  =   cat /proc/sys/kernel/sched_latency_ns**

`[scheduler] 调度时延，调度最小抢占粒度，调度唤醒抢占粒度详解 <https://blog.csdn.net/wukongmingjing/article/details/105433479>`__


进程选择
~~~~~~~~~~~~
选择具有最小vruntime的任务。

使用红黑树rbtree来组织可运行的进程队列，节点键值即vruntime。


1. 选择下一个任务：pick_next_entity()，运行rbtree最左节点对应的进程。此处不需要遍历树来查找最左节点，因为 ``最左节点已经被缓存起来`` （在更新rbtree时缓存的）。
2. 在rbtree插入进程： ``进程被唤醒或fork()创建进程时``。enqueue_entity()更新当前任务的统计数据，并插入调度实体，并更新最左节点的缓存。
3. 删除进程：进程阻塞或终止时。dequeue_entity()。



时间片与nice
------------
1. 时间片：进程在被抢占之前能够运行的时间，预先分配的。
2. nice：决定处理器的使用比例。

采用固定时间片则会引发固定的切换频率，会影响公平性。

1. 若将nice映射到绝对的时间片，则进程切换无法最优化进行。如高nice值的进程切换会更频繁；同时nice值±1的效果取决于nice本身初始值。
2. 基于优先级的调度器为了优化交互任务，需要提升刚唤醒的进程的优先级，这样的优先级提升实际上是不公平的。
3. 时间片会随着定时器节拍改变，即最小时间片必须是定时器节拍的整数倍。


进程优先级的表示
-----------------
1. `关于Linux进程优先级数字混乱的彻底澄清 <https://mp.weixin.qq.com/s/44Gamu17Vkl77OGV2KkRmQ>`__
2. `proc(5) - Linux manual page  <https://man7.org/linux/man-pages/man5/proc.5.html>`__

**用户态：**
~~~~~~~~~~~~~~~~~~~

1. sched_priority(chrt、/proc/pid/stat 字段 **40**)，最常用。sched_priority : 1(low) to 99(high)
2. nice(/proc/pid/stat 字段 **19**)。nice :-19(high) to 20(low)
3. policy(字段 **41**)



**内核态：**
~~~~~~~~~~~~~~~~
内核调度bitmap使用。 /proc/pid/sched。小->优先级高。

prio = 99 - sched_priority

normal = 120 + nice

**top命令：**
~~~~~~~~~~~~~~~
/proc/pid/stat 字段 **18**. top_prio = -1 - sched_priority

