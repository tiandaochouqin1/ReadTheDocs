=====================
Kernel Debug & Trace
=====================


:Date:   2021-07-18 18:52:25

.. important:: 如何使用qemu

内核调试手段
===============
方法概述
-----------

- `Linux内核调试的方式以及工具集锦 <https://blog.csdn.net/gatieme/article/details/68948080>`__
- `Linux内核调试方法总结 <https://blog.csdn.net/bob_fly1984/article/details/51405776>`__

1. **debugfs等文件系统**	提供了 procfs, sysfs, debugfs以及 relayfs 来与用户空间进行数据交互, 
   尤其是 debugfs, 这是内核开发者们实现的专门用来调试的文件系统接口. 其他的工具或者接口, 多数都依赖于 debugfs.
2. **printk**	强大的输出系统, 没有什么逻辑上的bug是用PRINT解决不了的
3. **ftrace及其前端工具trace-cmd**	内核提供了 ftrace 工具来实现检查点, 事件等的检测,debugfs 的 tracing 子系统, 
   对内核实现检测和分析. 功能强大, trace-cmd 等前端工具简化了 ftrace 的使用.
4. **kprobe以及systemtap**	内核中实现的 krpobe 通过类似与代码劫持一样的技巧, 
   在内核的代码或者函数执行前后, 强制加上某些调试信息. 劫持代码需要用驱动的方式编译并加载,

   通过 systemtap 用户只需要编写脚本, 就可以自动生成劫持代码并自动加载和收集数据.
5. **kgdb && kgtp**	KGTP则通过驱动的方式强化了 gdb的功能, 诸如tracepoint, 打印内核变量等.
6. **perf**	Perf 是一款随 Linux内核代码一同发布和维护的性能诊断工具, 多功能的性能统计工具集.

7. **LTTng**	LTTng 是一个 Linux 平台开源的跟踪工具, 是一套软件组件,  可允许跟踪 Linux 内核和用户程序, 并控制跟踪会话(开始/停止跟踪、启动/停止事件 等等).
8. **KDB**   访问内核内存和数据结构。需要打补丁并重新编译内核。
9. **kdump+crash**： `kdump机制和crash常见使用 - AhaoMu - 博客园  <https://www.cnblogs.com/muahao/p/9884175.html>`__


taskstats
-------------
统计任务的调度、内存使用、I/O信息、系统调用的信息，基于netlink套接字，从内核向用户空间提供任务/进程的统计信息。

1. `Per-task statistics interface — The Linux Kernel documentation  <https://docs.kernel.org/accounting/taskstats.html>`__

虚拟文件virtual file
==================================
proc debugfs seq_file 都创建虚拟文件。

procfs
-----------
处理>4K的文件时比较麻烦。 

实际编码与debugfs类似。


debugfs
-----------
1. https://www.kernel.org/doc/html/latest/filesystems/debugfs.html
2. `[Linux]使用debugfs文件系统_debugfs_create_file_Oscar_O的博客-CSDN博客  <https://blog.csdn.net/ai126323/article/details/120937866>`__


**Debugfs** exists as a simple way for kernel developers to make information available to user space. 
Unlike /proc, which is only meant for information about a process, 
or sysfs, which has strict one-value-per-file rules, debugfs has no rules at all.
Developers can put any information they want there. 

挂载
~~~~~~~~~~~~
::

   打开内核编译选项

   CONFIG_DEBUG_FS

   CONFIG_GENERIC_IRQ_DEBUGFS // v5.10.31 not set by default

   手动挂载
   mount -t debugfs none /sys/kernel/debug


`CONFIG_GENERIC_IRQ_DEBUGFS <https://www.kernel.org/doc/html/latest/core-api/irq/irq-domain.html>`__

使用debugfs api
~~~~~~~~~~~~~~~~~~~
1. 可直接使用已经封装好的整数、字符串、数组、寄存器列表等api，不需要实现file_operations
2. debugfs_create_file需自己实现file_operations(read/write等，通常使用到copy_to/from_user)

::

   struct dentry *debugfs_create_dir(const char *name, struct dentry *parent);
      
   void debugfs_create_u32_array(const char *name, umode_t mode,
                     struct dentry *parent,
                     struct debugfs_u32_array *array);

   void debugfs_create_u64(const char *name, umode_t mode,
                           struct dentry *parent, u64 *value);

   struct dentry *debugfs_create_file(const char *name, umode_t mode,
                                    struct dentry *parent, void *data,
                                    const struct file_operations *fops);

   debugfs_create_regset32(const char *name, umode_t mode,
                           struct dentry *parent,
                           struct debugfs_regset32 *regset);


seq_file
---------------
1. https://www.kernel.org/doc/html/latest/filesystems/seq_file.html
2. `内核proc文件系统与seq接口（4）---seq_file接口编程浅析_seq_write  <https://blog.csdn.net/weixin_39094034/article/details/110529178>`__
3. `seq_file工作机制实例_koson_L的博客-CSDN博客  <https://blog.csdn.net/liaokesen168/article/details/49183703>`__

sdddsd

**创建字符串虚拟文件。封装了迭代器，便于使用。**

组成与使用
~~~~~~~~~~~~~~
1. seq_operations: **迭代器** 接口，位于file_operations的 .open成员中。
2. seq_printf等：格式化函数，无缓冲区问题。通常在迭代器接口实现中使用(如.show)
3. file_operations : 虚拟文件需要的操作

::
      
   struct seq_operations {
      void * (*start) (struct seq_file *m, loff_t *pos);
      void (*stop) (struct seq_file *m, void *v);
      void * (*next) (struct seq_file *m, void *v, loff_t *pos);
      int (*show) (struct seq_file *m, void *v);
   };


   file_operations的.open成员即由seq_operations实现：

   static const struct file_operations ct_file_ops = {
         .owner   = THIS_MODULE,
         .open    = ct_open,
         .read    = seq_read,
         .llseek  = seq_lseek,
         .release = seq_release
   };   


seq_file结构体
~~~~~~~~~~~~~~~~~~~~
1. `linux内核seq_file接口 - yuxi_o - 博客园  <https://www.cnblogs.com/embedded-linux/p/9751995.html>`__


::

   struct seq_file {
      char *buf;  //序列文件对应的数据缓冲区，要导出的数据是首先打印到这个缓冲区，然后才被拷贝到指定的用户缓冲区。
      size_t size;  //缓冲区大小，默认为1个页面大小，随着需求会动态以2的级数倍扩张，4k,8k,16k...
      size_t from;  //没有拷贝到用户空间的数据在buf中的起始偏移量
      size_t count; //buf中没有拷贝到用户空间的数据的字节数，调用seq_printf()等函数向buf写数据的同时相应增加m->count
      size_t pad_until; 
      loff_t index;  //正在或即将读取的数据项索引，和seq_operations中的start、next操作中的pos项一致，一条记录为一个索引
      loff_t read_pos;  //当前读取数据（file）的偏移量，字节为单位
      u64 version;  //文件的版本
      struct mutex lock;  //序列化对这个文件的并行操作
      const struct seq_operations *op;  //指向seq_operations
      int poll_event; 
      const struct file *file; // seq_file相关的proc或其他文件
      void *private;  //指向文件的私有数据
   };

kprobe
==========
https://www.kernel.org/doc/Documentation/kprobes.txt

动态地跟踪内核的行为、收集debug信息和性能信息。可以跟踪内核几乎所有的代码地址





crash &panic
================
crash
----------
内核coredump分析。


hung task detect
--------------------
1. `Linux hung task detect_yinjian1013的博客-CSDN博客_hungtask  <https://blog.csdn.net/yinjian1013/article/details/78261879>`__


宏配置：

::
      
   kernel/linux/arch/arm64/configs/deconfig

   CONFIG_DETECT_HUNG_TASK=y
   CONFIG_DEFAULT_HUNG_TASK_TIMEOUT=120
   CONFIG_BOOTPARAM_HUNG_TASK_PANIC=y
   CONFIG_BOOTPARAM_HUNG_TASK_PANIC_VALUE=1

   /proc/sys/kernel/hung_task_timeout_secs




函数调用关系

::

   kernel/linux/kernel/hung_task.c

   subsys_initcall(hung_task_init)->hung_task_init->kthread_run->watchdog->check_hung_uninterruptible_tasks->check_hung_task

   hung_task_init：  创建名为“khungtaskd”的线程，其中watchdog函数为线程运行的函数；
   watchdog：    每隔CONFIG_DEFAULT_HUNG_TASK_TIMEOUT（120S）时间，检测是否有进程hung；
   check_hung_uninterruptible_tasks：  遍历所有线程（进程），如果有线程处于TASK_UNINTERRUPTIBLE状态，则执行check_hung_task函数；
   check_hung_task：   两次间隔CONFIG_DEFAULT_HUNG_TASK_TIMEOUT时间内，如果线程没有主动放弃CPU或者被抢占，则打印hung相关信息，
   如果CONFIG_BOOTPARAM_HUNG_TASK_PANIC_VALUE为1，则产生panic。


   sysctl_hung_task_timeout_secs = CONFIG_DEFAULT_HUNG_TASK_TIMEOUT;
   sysctl_hung_task_panic =  CONFIG_BOOTPARAM_HUNG_TASK_PANIC_VALUE;


::
   
   kernel\sysctl.c

   #ifdef CONFIG_DETECT_HUNG_TASK
   ....
      {
         .procname	= "hung_task_timeout_secs",
         .data		= &sysctl_hung_task_timeout_secs,
         .maxlen		= sizeof(unsigned long),
         .mode		= 0644,
         .proc_handler	= proc_dohung_task_timeout_secs,
         .extra2		= &hung_task_timeout_max,
      },
   .....
   #endif

kernel panic
---------------
有两种主要类型 kernel panic：

1. hard panic(也就是Aieee信息输出)
2. soft panic (也就是Oops信息输出)

sysrq魔术键
----------------
1. `Linux Magic System Request Key Hacks — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html>`__
2. `linux 中的 SysRq 魔术键 | RQ BLOG  <https://rqsir.github.io/2019/05/02/linux%E4%B8%AD%E7%9A%84SysRq%E9%AD%94%E6%9C%AF%E9%94%AE/>`__


the kernel will respond to regardless of whatever else it is doing, unless it is completely locked up

::

   E - 向除 init 以外所有进程发送 SIGTERM 信号 (让进程自己正常退出)
      SysRq: Terminate All Tasks
      
   I - 向除 init 以外所有进程发送 SIGKILL 信号 (强制结束进程)
      SysRq: Kill All Tasks
      
   K - 结束与当前控制台相关的全部进程
      SysRq : SAK 
      
   F - 人为触发 OOM Killer (可选，除非可以确认是内存使用问题，尽量避免使用这个组合键)
      SysRq : Manual OOM execution 
      (OOM Killer 将根据各进程的内存处理情况选取最合适的“凶手”进程，并向其发送 SIGKILL 信		号，中	止其运行。)


   M - 打印内存使用信息
      SysRq : Show Memory
      
   P - 打印当前 CPU 寄存器信息
      SysRq : Show Regs
      
   T - 打印进程列表
      SysRq : Show State
      
   W - 打印 CPU 信息
      SysRq : Show CPUs


   


典型故障
==========
kernel deadlock
------------------
1. `Linux内核死锁检测机制` <https://e-mailky.github.io/2017-01-18-kernel-daedlock>`__
   `Linux内核调试技术——进程D状态死锁检测` <https://e-mailky.github.io/2017-01-18-kernel-daedlock-check>`__
   `Linux内核调试技术——进程R状态死锁检测` <https://e-mailky.github.io/2017-01-18-kernel-daedlock-check2>`__


- D状态死锁：进程长时间处于TASK_UNINTERRUPTIBLE而不恢复的状态。
- R状态死锁：进程长时间处于TASK_RUNNING 状态抢占CPU而不发生切换(关抢占/中断)。分为softlockup和hardlockup。

D状态死锁-hung task
~~~~~~~~~~~~~~~~~~~~~~~~
内核线程循环检测处于D状态的每个进程，两次监测之间(120s，/proc/sys/kernel/hung_task_timeout_secs)若无调度则判断进程一直处于D状态，则触发报警日志打印。

TASK_UNINTERRUPTIBLE，称为D状态，该种状态下进程不接收信号，只能通过wake_up唤醒。 
例如mutex锁就可能会设置进程于该状态，有时候进程在等待某种IO资源就绪时 (wait_event机制)会设置进程进入该状态。

R状态死锁-softlockup和hardlockup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1. https://www.kernel.org/doc/Documentation/lockup-watchdogs.txt
2. `Real-Time进程会导致系统lockup吗？ | Linux Performance` <http://linuxperf.com/?p=197>`__

机制
^^^^^^
1. lockup detector机制：在中断上下文中发生死锁时，nmi(不可屏蔽的中断)处理也可正常进入，因此可用来监测中断中的死锁。

2. 优先级关系：进程上下文 < 中断 < nmi中断。

3. 代码路径：kernel/watchdog.c


- softlockup：20s。
- hardlockup:HARDLOCKUP_DETECTOR需要nmi中断的支持。10s


.. figure:: /images/lockup_detector.jpg
   :scale: 80%

   lockup_detector



perf性能优化
=============
主要为用户态，也有内核。

1. `☆ perf examples <https://www.brendangregg.com/perf.html>`__ :详细介绍了events
2. `flamegraphs <https://www.brendangregg.com/flamegraphs.html>`__
3. https://perf.wiki.kernel.org/index.php/Tutorial
4. `系统级性能分析工具perf的介绍与使用 <https://www.cnblogs.com/arnoldlu/p/6241297.html>`__
5. `Linux性能优化全景指南 <https://mp.weixin.qq.com/s/dcE5TZ9lBOpZdRDeHsHUYQ>`__

sudo执行。-p pid

- perf top：实时性能
- perf stat：统计信息
- perf record + report：精确分析，函数级别
- perf annotate: 源码级别
- perf bench: 性能bennchmark
- 

   
::

   perf record -vv -e sched:sched_stat_sleep -e sched:sched_switch -e sched:sched_process_exit -gP



.. figure:: /images/perf_events_map.png

   

perf events
--------------

The types of events are:

::


  Hardware Events: CPU performance monitoring counters.
  Software Events: These are low level events based on kernel counters. For example, CPU migrations, minor faults, major faults, etc.
  Kernel Tracepoint Events: This are static kernel-level instrumentation points that are hardcoded in interesting and logical places in the kernel.
  User Statically-Defined Tracing (USDT): These are static tracepoints for user-level programs and applications.
  Dynamic Tracing: Software can be dynamically instrumented, creating events in any location. For kernel software, this uses the kprobes framework. For user-level software, uprobes.
  Timed Profiling: Snapshots can be collected at an arbitrary frequency, using perf record -FHz. This is commonly used for CPU usage profiling, and works by creating custom timed interrupt events.
