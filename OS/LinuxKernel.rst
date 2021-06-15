=================
Linux Kernel
=================



:Date:   2021-04-24 16:52:25



问题记录
========

   
1. 段选择子的作用？三级页表的工作原理？
2. 上下文切换的具体过程？
3. RTC时钟和中断时钟在进程调度中的作用？vruntime更新使用哪个时间？ 
4. 异常、陷阱、中断、系统调用等概念辨析；中断为什么不能休眠？
5. 系统调用的细节：看参考博客文章。
   


内核入门
============

参考文档
--------

1. https://www.kernel.org/doc/html/latest/translations/zh_CN/
2. https://kernelnewbies.org/
3. https://lwn.net/
4. https://kernel.org/pub/linux/kernel/

在线源码搜索，包括linux、glibc、gcc等。

1. https://elixir.bootlin.com/linux/v5.10/C/ident/ 
2. http://sbexr.rabexc.org/latest/sources/meta/index
3. https://code.woboq.org/

参考书籍
~~~~~~~~

1. Linux Kernel Development V2.6.34
2. Linux Devices Driver V2.6.10
3. Proffesional Linux Kernel Architecture V2.6.24 
4. Understanding The Linux Kernel  V2.6.11


参考链接
~~~~~~~~
1. `6.828   实现xv6 <https://pdos.csail.mit.edu/6.S081/2020/>`__
2. `知乎-MIT 6.828   实现操作系统 <https://zhuanlan.zhihu.com/c_1273723917820215296>`__
3. `趣谈Linux操作系统——刘超 <https://zter.ml/>`__
4. 操作系统实战45讲

基本概念
--------
内核态拥有受保护的内存空间和访问硬件设备的所有权限。

应用程序通过库函数或系统调用让内核代替完成各种任务。
库函数不仅是对系统调用的打包，它也实现了系统调用不具备的功能，如strcpy。

.. figure:: ../images/SyscallAndLibc.png
   :alt: 库函数和系统调用

   库函数和系统调用


**处理器可能的状态：**

1. 运行于用户空间，执行用户进程；
2. 运行于内核空间，处于进程上下文，代表某个特定的进程执行；
3. 运行于内核空间，处于中断上下文，处理特定的中断（与任何进程无关）。
4. CPU空闲时，运行一个空进程，处于2的状态。

**微内核：**
将内核服务的地址空间隔离，内核只提供基础服务（IPC、内存、调度等），
其它服务组件如文件系统、驱动程序等则各自运行在独立的地址空间（用户空间），并以IPC的方式为其它应用程序提供服务。

微内核提升了稳定性、安全性、扩展性和内核实时性，但是损失了效率。


内核版本号
----------

`Linux内核版本号： <http://en.wikipedia.org/wiki/Linux_kernel#Version_numbering>`__

1. 2.x 版本奇数表示开发版、偶数表示稳定版。2.6.x系列覆盖了2003-2011年。
2. 3.0开始，版本号基于时间变化（近2个月更新一次小版本号），不代表有重大的内容更新。同时避免小版本号超过20。
3. 当前5.11为15-Feb-2021发布

-  mainline 是主线版本。
-  stable 是稳定版，由 mainline
   在时机成熟时发布，稳定版也会在相应版本号的主线上提供 bug
   修复和安全补丁
-  longterm
   是长期支持版，多为\ `6年 <https://www.kernel.org/category/releases.html>`__
-  RC：release candidates。


编译
--------------


下载源码
~~~~~~~~~
1. 下载发布版本包；
2. 下载Git。

::

   git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
   镜像
   git clone git clone https://mirrors.tuna.tsinghua.edu.cn/git/linux-stable.git

   在windows中有兼容性问题（aux文件在win中为设备文件）。
   git config core.protectNTFS false
   git rm --cache aux.c/h


3. 切换版本
   
::
   
   git tag
   git checkout V5.0


内核编译
~~~~~~~~
Kbuild+Makefile

编译选项通常有三个：Yes/No/Module。Module代表以模块的形式独立生成。

发布版：Ubuntu、Federo等发布版包含了预编译的内核，已启用了所需的功能，而驱动程序一般都是模块。


::

   安装依赖
   sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison


   make menuconfig

   cp /boot/config-$(uname -r) .config

   make oldconfig //验证.config

   make -j8 >> make.log

   make modules_install //安装启用的模块

   sudo make install //安装内核。然后需要更新引导！！


模块编译
~~~~~~~~



1. 源码树内部编译：
   
   1. 增加文件夹，在kconfig中添加编译选项
   2。 按照编译选项编写makefile

2. 在源码树外部编译：（OSC中的Lab，在ubuntu18中会提示insmod签名问题）

   :download:`simple.c <../files/code/simple.c>`


   需要自己写makefile。本机内核模块目录 ``/lib/modules/$(uname -r)/build``，避免在修改模块的源代码时重新编译整个内核。

::

   obj-m := hello_module.o
   ​
   KERNELBUILD := /lib/modules/$(uname -r)/build
   CURRENT_PATH := $(pwd)
   ​
   all:
       make -C $(KERNELBUILD) M=$(CURRENT_PATH) modules
   ​
   clean:
           make -C $(KERNELBUILD) M=$(CURRENT_PATH) clean


模块安装：``sudo insmod mod.ko``
dmesg : 查看内核日志缓冲区（包括printk的输出内容）。

进程
=====
进程管理
---------
进程：处于执行期的程序以及相关资源的总称。程序：存放在存储介质上的目标吗。


任务队列：task_struct双向循环列表。
进程描述符（task_struct）中保存了能完整描述一个正在执行的程序的左右数据。1.7KB(32位及机器)。
使用slab分配器分配，实现对象复用和缓存着色。
thread info结构在进程内核栈尾端分配，包含了指向task_struct的指针。
current宏：找到当前进程的进程描述符。

进程的五种状态
~~~~~~~~~~~~~~

1. TASK_RUNNING: 运行——可执行的,即正在执行或在运行队列中等待。用户空间进程的唯一状态；内核进程也有此状态。
2. TASK_INTERRUPTIBLE: 可中断的——睡眠中，等待特定条件达成，可被信号唤醒。
3. TASK_UNINTERRUPTIBLE: 不可中断——睡眠中，不会被信号唤醒。在进程等待过程必须不受干扰或等待事件很快会发生时使用。
4. __TASK_TRACED: 被其他进程跟踪，如ptrace。
5. __TASK_STOPPED: 停止执行，进程没有投入运行也不能投入运行。通常发生在接收SIGSTOP、SIGTSTP、SIGTTIN、SIGTTOU等信号时。

.. figure:: ../images/task_status.png

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


fork -> exec -> exit + wait

fork
开销：复制父进程的页表和创建子进程的进程描述符。
资源采用写时复制，即只有在需要写入时才拷贝页，是他们拥有独立的数据副本


线程：Linux中，只是进程间共享资源的手段。共享文件系统资源、地址空间、文件描述符和信号处理程序。

内核进程：没有独立的地址空间，可以被调度和抢占。

进程的生命周期
~~~~~~~~~~~~~~

fork -> clone -> _do_fork -> copy_process

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
-----------

Linux提供抢占式多任务模式（preemptive multitaking）。


调度程序：在TASK_RUNNING的进程之间分配有限的处理器时间资源。

调度策略的平衡： 优先调度IO消耗型以保证短的响应时间，或优先调度CPU消耗型以保证高吞吐量。

Linux更倾向于优先调度IO消耗型进程，以保证响应时间（交互式应用和桌面系统等）。


O(1)调度
~~~~~~~~~

1. 140个成员的array,各成员各对应一个FIFO队列；
2. 使用位图来各队列是否为空；
3. 调度时间复杂度为 O(1).

.. figure:: ../images/O(1)_schedule.jpg

           Linux2.6.23以前的O(1)调度


时间片与nice
~~~~~~~~~~~~
时间片：进程在被抢占之前能够运行的时间，预先分配的。
nice：决定处理器的使用比例。

采用固定时间片则会引发固定的切换频率，会影响公平性。

1. 若将nice映射到绝对的时间片，则进程切换无法最优化进行。如高nice值的进程切换会更频繁；同时nice值±1的效果取决于nice本身初始值。
2. 基于优先级的调度器为了优化交互任务，需要提升刚唤醒的进程的优先级，这样的优先级提升实际上是不公平的。
3. 时间片会随着定时器节拍改变，即最小时间片必须是定时器节拍的整数倍。


CFS调度
--------

1. CFS调度完全摒弃时间片的分配方法，而是给进程分配处理器的使用比例，确保了进程调度中有恒定的公平性，而切换频率则是不断变化的。
2. CFS有一个分配时间的最小粒度，默认1ms，在可运行进程数量较多时，可将切换消耗限制在一定范围。
3. 进程获得的处理器时间由自己和其它所有可运行进程的nice值的差值决定，nice相差1则相差1.25倍时间。

实时策略与普通策略
~~~~~~~~~~~~~~~~~~
`sched man <https://man7.org/linux/man-pages/man7/sched.7.html>`__ 讲得很清楚。

调度器为每个优先级维护一个等待list。选择最高优先级的非空list的第一个成员来执行。
调度策略只能决定同一等待list（同一优先级）的进程执行顺序。

1. normal scheduling policies： (SCHED_OTHER, SCHED_IDLE, SCHED_BATCH), sched_priority must be specified as 0.

   The nice value  (SCHED_OTHER, SCHED_BATCH) influence the CPU scheduler to favor or disfavor a process in scheduling decisions.
   the range is -20 (high priority) to +19 (low priority).

2. real-time policies：(SCHED_FIFO, SCHED_RR, SCHED_DEADLINE) have a sched_priority value in the range 1
(low) to 99 (high).

Linux的实时调度算法提供了一种软实时的工作方式，即尽力使进程在它的限定时间到来前运行，但内核不保证总能满足要求。

Linux调度程序默认试图使进程尽量在同一个处理器运行（软亲和性），同时提供了强制亲和性（通过task_struct的cpus_allowed位掩码标志）。


**六大调度策略**

1. SCHED_FIFO: 先进先出，无时间片。
2. SCHED_RR：时间片轮转，可抢占。
3. SCHED_DEADLINE：按照任务deadline来调度选择其 deadline 距离当前时间点最近的任务。
4. SCHED_OTHER：Linux中又名SCHED_NORMAL，根据nice值调度。
5. SCHED_BATCH：假定任务是CPU-intensive，对唤醒的进程做调度惩罚，即不提倡频繁切换。
6. SCHED_IDLE: nice值小于19，即用于优先级非常低的任务。


调度的实现
------------

时间记账vruntime
~~~~~~~~~~~~~~~~~
CFS使用调度器实体结构来维护每个进程运行的时间记张。（linux/sched.h -> struct_sched_entity）


vruntime存放进程的虚拟运行时间，是所有可运行进程总数的加权计算结果。单位ns，与定时器节拍不相关。
``虚拟运行时间 vruntime += 实际运行时间 delta_exec * NICE_0_LOAD/ 权重``

系统定时器周期性调用 update_curr()，以更新所有进程的vruntime(包括可运行和阻塞态的所有进程)。

针对刚创建的进程会进行一定的惩罚，将虚拟时间加上一个值。

`CFS调度器（2）-源码解析 <http://www.wowotech.net/process_management/448.html>`__

进程选择
~~~~~~~~~~~~
选择具有最小vruntime的任务。

使用红黑树rbtree来组织可运行的进程队列，节点键值即vruntime。


1. 选择下一个任务：pick_next_entity()，运行rbtree最左节点对应的进程。
此处不需要遍历树来查找最左节点，因为最左节点已经被缓存起来的（在更新rbtree时缓存的）。

2. 在rbtree插入进程：进程被唤醒或fork()创建进程时。enqueue_entity()更新当前任务的统计数据，并插入调度实体，并更新最左节点的缓存。
3. 删除进程：进程阻塞或终止时。dequeue_entity()。

调度器
~~~~~~~~~~~
每个CPU都有自己的 struct rq 结构，其用于描述在此 CPU 上所运行的所有进程，其包括一个实时进程队列 rt_rq 和一个 CFS 运行队列 cfs_rq。

调度类sched_class定义了很多种方法，用于操作上述调度队列上的任务。每种调度策略各实现了一种调度类，并放在同一个链表中。

调度类中的方法，如pick_next_task在不同的调度类中有不同的实现，返回空时则继续操作下一个队列。
fair_sched_class 的实现是 pick_next_task_fair，rt_sched_class 的实现是 pick_next_task_rt；
pick_next_task_rt 操作的是 rt_rq，pick_next_task_fair 操作的是 cfs_rq。

调用路径pick_next_task_fair -> pick_next_entity -> __pick_first_entity。

.. figure:: ../images/sched.jfif

           调度过程


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




抢占和上下文切换
------------------

上下文切换：即从一个可执行程序切换到另一个可执行程序。context_switch()完成地址空间切换switch_mm()和处理器状态恢复switch_to()。



need_resched
~~~~~~~~~~~~~~
表明需要重新执行一次调度，强制调度，有调度延时。

当某个进程应该被抢占时，或更高优先级的进程进入可执行状态时，需要设置此标志。

该标志包含在进程描述符内，访问进程描述符内的变量比访问全局变量快（current宏速度快且进程描述符通常在告诉缓存内）。


用户抢占与内核抢占
~~~~~~~~~~~~~~~~~~~~~
用户抢占发生在：

1. 从系统调用返回用户空间时；
2. 从中断处理程序返回用户空间时。

内核抢占：
可以在任何时间抢占任务（只要没有锁），通常发生在 preempt_enable() 中。
preempt_enable() 会调用 preempt_count_dec_and_test()，判断 preempt_count 和 TIF_NEED_RESCHED 看是否可以被抢占。
如果可以，就调用 preempt_schedule->preempt_schedule_common->__schedule 进行调度。

.. figure:: ../images/schedule_and_preempt.png

            抢占式调度



系统调用
=============
`the-definitive-guide-to-linux-system-calls <https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/>`__

`深入理解系统调用 <https://www.cnblogs.com/liujianing0421/p/12971722.html>`__


概念
------
在Linux中，系统调用是用户空间访问内核的唯一手段。

系统调用在用户空间进程和硬件设备之间添加了一个中间层，作用：

1. 为用户空间提供硬件抽象接口；
2. 保证系统的稳定与安全。内核基于权限、用户和其它规则对访问进行裁决；
3. 为运行在虚拟系统中的进程提供公共接口（？）。

应用程序编程接口API；在用户空间实现，应用程序使用其来编程。不需要和系统调用对应。

POSIX：提供一套大体基于UNIX的操可移植作系统标准。

C库：Linux系统调用像其它大多数UNIX系统一样，作为C库的一部分提供。C库提供了POSIX的大部分API。

UNIX接口设计：提供机制（功能定义）而不是策略（如何实现）。

eax：存放系统调用号、返回值。


系统调用的实现
--------------

系统调用列表：在sys_call_table中，空sys_ni_syscall()仅返回-ENOSYS。

系统调用设计：力求简洁，参数尽可能少；向前向后兼容性；可移植性。

参数验证：系统调用必须仔细检查参数是否合法。

系统调用上下文
~~~~~~~~~~~~~~
内核在执行系统调用时处于进程上下文。

在进程上下文中内核可以休眠（系统调用阻塞、显示调用schedule）并且可以被抢占。

- 可休眠说明系统调用可以使用内核提供的大部分功能（而不可休眠的中断在编程时会受到极大限制）；
- 可抢占可需要保证系统调用是可重入。

注册和使用
~~~~~~~~~~
1. 加入系统调用表；
2. 编译进内核映像（不能是模块）；
3. 通过C库或使用_syscalln()访问系统调用。

_syscalln() -> K_INLINE_SYSCALL : 内联汇编


系统调用的替代：

1. 实现一个设备节点，然后使用read/write；
2. 使用文件描述符来表示。

int 0x80和syscall/sysenter的区别
---------------------------------
https://www.cnblogs.com/LittleHann/p/4111692.html

1. 通过INT 0x80中断方式。
   
   * 在 2.6以前的 Linux 2.4 内核中，用户态 Ring3 代码请求内核态 Ring0 代码完成某些功能是通过系统调用完成的，而系统调用的是通过软中断指令(int 0x80) 实现的。在 x86 保护模式中，处理 INT 中断指令时
   * 在发生系统调用，由 Ring3 进入 Ring0 的这个过程浪费了不少的 CPU 周期，例如，系统调用必然需要由 Ring3 进入 Ring0，权限提升之前和之后的级别是固定的。
      
   1) CPU 首先从中断描述表 IDT 取出对应的门描述符
   2) 判断门描述符的种类
   3) 检查门描述符的级别 DPL 和 INT 指令调用者的级别 CPL，当 CPL<=DPL 也就是说 INT 调用者级别高于描述符指定级别时，才能成功调用
   4) 根据描述符的内容，进行压栈、跳转、权限级别提升
   5) 内核代码执行完毕之后，调用 IRET 指令返回，IRET 指令恢复用户栈，并跳转会低级别的代码 .
    
2. 通过sysenter指令方式。
sysenter 指令用于由 Ring3 进入 Ring0，SYSEXIT 指令用于由 Ring0 返回 Ring3。由于没有特权级别检查的处理，也没有压栈的操作，所以执行速度比 INT n/IRET 快了不少。
sysenter和sysexit都是CPU原生支持的指令集

中断为什么不能休眠
--------------------
https://www.cnblogs.com/schips/p/why_isr_can_not_schedule_in_linux.html

中断只能被其他中断中止、抢占，进程不能中止、抢占中断。

中断是一种紧急事务，需要操作系统立即处理，不是不能做到睡眠，是没必要睡眠。

ISR在执行过程中要借用进程的系统堆栈。

1. 无法被唤醒。在中断context中，唯一能打断当前中断handler的只有更高优先级的中断；所有的wake_up_xxx都是针对进程task_struct而言，
   Linux是以进程为调度单位的，调度器只看到进程内核栈，而看不到中断栈。

2. 导致上下文错乱。睡眠函数nanosleep(do_nanosleep,v5.13)会调用schedule导致进程切换。


内核数据结构
============
提倡在开发时重用Linux内建数据结构。

链表、队列、散列表、红黑树，还有基树（Radix Tree）、位图等。

链表
----------
静态数组：编译时需知道元素数量。

链表：动态创建并插入元素，无需占用连续内存。

Linux内核的标准链表为环形双向链表，灵活性高。

使用方法
~~~~~~~~~~~
在数据结构中嵌入链表。

::

   struct list_head {
       struct list_head *next;
       struct list_head *prev;
   }

   获取包含list_head的父类型结构体
   list_entry(ptr, type, member)

   遍历链表,O(n)
   list_for_each_entry(pos, head, member)


增加、删除、移动、合并节点的时间复杂度均为O(1) ，这些操作对应内部链表操作函数。在已有next/prev指针的情况下可直接调用内部链表函数。




队列
--------------
也称为FIFO。


kfifo为Linux内核通用队列实现。

两个主要操作：enqueue和dequeue（kfifo_in、kfifo_out）。维护两个偏移量：入口偏移和出口偏移。




映射
-------------
也称为关联数组。键到值的关联关系即为映射。可通过散列表、二叉搜索树来实现。

Linux内核提供的映射idr：将唯一的UID映射到一个指针。支持的操作 add、remove、lookup、allocate。

::

   使用idp指向的idr分配一个UID，并关联到ptr。
   idr__get_new(struct idr *idp, void *ptr,int *id)




二叉树
-----------------
Linux实现的红黑树为rbtree，为平衡二叉搜索树。

rbtree的实现并为提供搜索和插入方法。
C语言不方便泛型编程，同时最有效的搜索和插入方法应该由用户自己实现。


中断和中断处理
====================

