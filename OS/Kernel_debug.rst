=====================
Kernel Debug & Trace
=====================


:Date:   2021-07-18 18:52:25



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
==========
统计任务的调度、内存使用、I/O信息、系统调用的信息，基于netlink套接字，从内核向用户空间提供任务/进程的统计信息。

1. `Per-task statistics interface — The Linux Kernel documentation  <https://docs.kernel.org/accounting/taskstats.html>`__


debugfs
===============
https://www.kernel.org/doc/html/latest/filesystems/debugfs.html

**Debugfs** exists as a simple way for kernel developers to make information available to user space. 
Unlike /proc, which is only meant for information about a process, 
or sysfs, which has strict one-value-per-file rules, debugfs has no rules at all.
Developers can put any information they want there. 

挂载
-----------
::

   打开内核编译选项

   CONFIG_DEBUG_FS

   CONFIG_GENERIC_IRQ_DEBUGFS // v5.10.31 not set by default

   手动挂载
   mount -t debugfs none /sys/kernel/debug


`CONFIG_GENERIC_IRQ_DEBUGFS <https://www.kernel.org/doc/html/latest/core-api/irq/irq-domain.html>`__


ftrace
============

1. https://www.kernel.org/doc/html/latest/trace/ftrace.html 官方示例。

2. `Linux ftrace框架介绍及运用 <https://www.cnblogs.com/arnoldlu/p/7211249.html>`__

3. `ftrace笔记 <https://www.cnblogs.com/hellokitty2/p/13978805.html>`__

4. Debugging the kernel using Ftrace `Part 1 <https://lwn.net/Articles/365835/>`__ 
`Part2 <https://lwn.net/Articles/366796/>`__ lwn的教程。

5. `Linux使用 ftrace 来跟踪内核函数调用_SweeNeil的博客-CSDN博客  <https://blog.csdn.net/SweeNeil/article/details/90038286>`__
6. `问题排查利器：Linux 原生跟踪工具 Ftrace 必知必会` <https://mp.weixin.qq.com/s/ZepMzfxJ0aESvXYWUuCTPg>`__
7. `Ftrace function graph原理及性能瓶颈的分析` <https://mp.weixin.qq.com/s/LrRwjkyfO1fi56QgUNlGaQ>`__


used for debugging or analyzing latencies and performance issues that take place outside of user-space.

a framework of several assorted tracing utilities. 
There’s latency tracing to examine what occurs between interrupts disabled and enabled, 
as well as for preemption and from a time a task is woken to the task is actually scheduled in.

挂载debugfs
---------------
依赖debugfs.

挂载Debugfs

::

   CONFIG_IRQSOFF_TRACER=y

   mount -t tracefs nodev /sys/kernel/tracing

   the tracefs file system will be automatically mounted at:
   /sys/kernel/debug/tracing # 默认位置

   ln -s /sys/kernel/tracing /tracing



不同linux版本路径可能不同。

后续操作均在文件夹  `/sys/kernel/debug/tracing` 中。

per cpu
~~~~~~~~~~~~~~~
每个核均有独自的：per_cpu/cpu0/trace 、per_cpu/cpu0/stats



irqsoff tracer
-------------------
“irqsoff”：Traces the areas that disable interrupts and saves the trace with the longest max latency。

ftrace的时间都是ms。

在内核源码根目录文件 .config 中搜索 IRQSOFF，看到 # CONFIG_IRQSOFF_TRACER is not set (即默认不开启)。
在menuconfig中开启或直接修改.config即可。

使用方法：

::

   # echo 0 > options/function-trace
   # echo irqsoff > current_tracer
   # echo 1 > tracing_on
   # echo 0 > tracing_max_latency //每次trace均需要执行一次才能生效
   # echo 0 > tracing_on
   # cat trace

   #echo nop > current_tracer


trace-cmd
----------------
1. `ftrace利器之trace-cmd和kernelshark <https://www.cnblogs.com/arnoldlu/p/9014365.html>`__

2. `trace-cmd - command line reader for ftrace <https://lwn.net/Articles/341902/>`__

3. `ftrace和trace-cmd：跟踪内核函数的利器 <https://blog.csdn.net/weixin_44410537/article/details/103587609>`__

https://man7.org/linux/man-pages/man1/trace-cmd-record.1.html


trace-cmd作为ftrace的前端，对ftrace的各种设置进行包装，同时能对结果进行处理，极大地提高了ftrace的使用效率。

kernelshark作为trace-cmd的前端，借助图形化，灵活的filter，缩放功能，能更有效的帮助分析，高效的得到结果。


::

    sudo trace-cmd record -p irqsoff 
    sudo trace-cmd record -p function -P pid -l do_page_fault
    sudo trace-cmd report |less


graph function 
-------------------
::

   echo function_graph > current_tracer
   echo do_IRQ > set_graph_function
   echo 1 > tracing_cpumask
   echo 1 >tracing_on && sleep 1 && echo 0 > tracing_on


options选项功能
-----------------


stack trace
--------------

“function”:Function call tracer to trace all kernel functions.

stack tracer有点特殊，需要在/proc 开启关闭：

::


   echo 1  >  /proc/sys/kernel/stack_tracer_enabled
   echo 0 >  /proc/sys/kernel/stack_tracer_enabled

   stack trace的信息输出通过如下的节点上送给用户态：

   /sys/kernel/debug/tracing/stack_max_size
   /sys/kernel/debug/tracing/stack_trace 
   /sys/kernel/debug/tracing/stack_trace_filter

   指定pid
   echo pid > /sys/kernel/debug/tracing/set_ftrace_pid
   
   指定核
   echo 4 >tracing_cpumask



kprobe
==========
https://www.kernel.org/doc/Documentation/kprobes.txt

动态地跟踪内核的行为、收集debug信息和性能信息。可以跟踪内核几乎所有的代码地址


syslog & printk
====================

syslog
----------------
`内核日志及printk结构分析 <https://www.cnblogs.com/aaronLinux/p/6843131.html>`__

1. /proc/sys/kern/printk_ratelimit :监测周期，在这个周期内只能发出下面的控制量的信息).
2. /proc/sys/kernel/printk_ratelimit_burst :周期内的最大消息数.


printk
---------
1. 效率很低：做字符拷贝时一次只拷贝一个字节，且去 **调用console输出可能还产生中断**。
2. ring buffer只有1K。

printk等级
~~~~~~~~~~~~
1. `Message logging with printk — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/core-api/printk-basics.html>`__

1. All printk() messages are printed to the kernel log buffer, which is a ring buffer exported to userspace through /dev/kmsg。
2. 打印等级只是控制是否输出到console。message loglevel <= console_loglevel 则输出到console。
3. 4.9版本开始，printk默认会换行。不换行需使用pr_cont(KERN_CONT)。 `Message logging with printk — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/core-api/printk-basics.html>`__

console level查看：

::
      
   You can check the current console_loglevel with:

   $ cat /proc/sys/kernel/printk
   4        4        1        7
   The result shows the current, default, minimum and boot-time-default log levels.


boot(内核启动)可指定loglevel值、quiet(loglevel=4)。 https://www.kernel.org/doc/html/v4.14/admin-guide/kernel-parameters.html




printk源码
~~~~~~~~~~~~~
https://elixir.bootlin.com/linux/v4.4.157/source/kernel/printk/printk.c#L1659

printk ->  vprintk_default -> **vprintk_emit** -> console_unlock -> call_console_drivers 

会遍历所有console。

printk可以在任何上下文使用，由于 **要获取logbug_lock保护环形缓冲区,所以需要禁止本地中断，防止死锁.**


☆ `Printk实现流程 <https://blog.csdn.net/wdjjwb/article/details/88577419>`__

1. 如何把字符串放到缓存，如何从缓存写到串口。 **整个过程都处于关中断状态** 
   
   先关中断，保持 **logbuf_lock自旋锁** 的情况下，将数据格式化，放到printk_buf缓冲区，其大小为1K，然后再复制到log_buf缓冲区。
   
   获取console_sem信号量(如串口)，暂时放开自旋锁，所以在SMP下，其他CPU可能继续向log_buf中存放数据，并由本次printk的release_console_sem循环检查并输出。
   

2. 串口驱动输出采用轮询。输出时会 **关抢占，关中断**。
   serial8250_console_write 轮询。


::

   asmlinkage int vprintk_emit(int facility, int level,
               const char *dict, size_t dictlen,
               const char *fmt, va_list args)
   {
      static char textbuf[LOG_LINE_MAX];
      char *text = textbuf;
      size_t text_len = 0;

      0. 加锁
      
      /* This stops the holder of console_sem just where we want him */
      local_irq_save(flags);
      raw_spin_lock(&logbuf_lock);

      1. 格式化字符串

      /*
      * The printf needs to come first; we need the syslog
      * prefix which might be passed-in as a parameter.
      */
      text_len = vscnprintf(text, sizeof(textbuf), fmt, args);


      2. 解析打印等级

      /* strip kernel syslog prefix and extract log level or control flags */
      if (facility == 0) {
         int kern_level = printk_get_level(text);
         .....
         					level = kern_level - '0';
         .....
            text_len -= end_of_header - text;
            text = (char *)end_of_header;
      }

      3. 若cont且和其它cpu无冲突，则cont_add缓存；否则cont_flush

      if (!(lflags & LOG_NEWLINE)) {
         /*
         * Flush the conflicting buffer. An earlier newline was missing,
         * or another task also prints continuation lines.
         */
         if (cont.len && (lflags & LOG_PREFIX || cont.owner != current))
            cont_flush(LOG_NEWLINE);

         /* buffer line if possible, otherwise store it right away */
         if (cont_add(facility, level, text, text_len))
            printed_len += text_len;
         else
            printed_len += log_store(facility, level,
                     lflags | LOG_CONT, 0,
                     dict, dictlen, text, text_len);
      } else {
         bool stored = false;

         /*
         * If an earlier newline was missing and it was the same task,
         * either merge it with the current buffer and flush, or if
         * there was a race with interrupts (prefix == true) then just
         * flush it out and store this line separately.
         * If the preceding printk was from a different task and missed
         * a newline, flush and append the newline.
         */
         if (cont.len) {
            if (cont.owner == current && !(lflags & LOG_PREFIX))
               stored = cont_add(facility, level, text,
                     text_len);
            cont_flush(LOG_NEWLINE);
         }

         if (stored)
            printed_len += text_len;
         else
            printed_len += log_store(facility, level, lflags, 0,
                     dict, dictlen, text, text_len);
      }


      4. 放开logbuf_lock,开中断

      logbuf_cpu = UINT_MAX;
      raw_spin_unlock(&logbuf_lock);
      lockdep_on();
      local_irq_restore(flags);


      5. 关抢占，获取consle semaphore，console_unlock输出
   
      /* If called from the scheduler, we can not call up(). */
      if (!in_sched) {
         lockdep_off();
         /*
         * Disable preemption to avoid being preempted while holding
         * console_sem which would prevent anyone from printing to
         * console
         */
         preempt_disable();

         /*
         * Try to acquire and then immediately release the console
         * semaphore.  The release will print out buffers and wake up
         * /dev/kmsg and syslog() users.
         */
         if (console_trylock_for_printk())
            console_unlock();
         preempt_enable();
         lockdep_on();
      }

      return printed_len;
   }


串口驱动
~~~~~~~~~~~
call_console_drivers调用时也会 **关中断**。

univ8250_console_write -> serial8250_console_write -> uart_console_write -> 
serial8250_console_putchar -> wait_for_xmitr(此处最长循环等待10ms) -> io_serial_in

https://elixir.bootlin.com/linux/v4.4.157/source/drivers/tty/serial/8250/8250_port.c#L1711

::

   /*
   *	Wait for transmitter & holding register to empty
   */
   static void wait_for_xmitr(struct uart_8250_port *up, int bits)
   {
      unsigned int status, tmout = 10000;

      /* Wait up to 10ms for the character(s) to be sent. */
      for (;;) {
         status = serial_in(up, UART_LSR);

         up->lsr_saved_flags |= status & LSR_SAVE_FLAGS;

         if ((status & bits) == bits)
            break;
         if (--tmout == 0)
            break;
         udelay(1);
      }

      /* Wait up to 1s for flow control if necessary */
      if (up->port.flags & UPF_CONS_FLOW) {
         unsigned int tmout;
         for (tmout = 1000000; tmout; tmout--) {
            unsigned int msr = serial_in(up, UART_MSR);
            up->msr_saved_flags |= msr & MSR_SAVE_FLAGS;
            if (msr & UART_MSR_CTS)
               break;
            udelay(1);
            touch_nmi_watchdog();
         }
      }
   }





irq处理流程
-------------------
`中断处理流程 <https://peiyake.com/2020/09/16/kernel/linux%E4%B8%AD%E6%96%AD%E5%AD%90%E7%B3%BB%E7%BB%9F---%E4%B8%AD%E6%96%AD%E5%A4%84%E7%90%86%E6%B5%81%E7%A8%8B/>`__

http://www.wowotech.net/sort/irq_subsystem

local_irq_save()/local_irq_restore() 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
include/linux/irqflags.h

These routines disable hard interrupts on the local CPU, and restore them. 

They are **reentrant**; saving the previous state in their one unsigned long flags argument. 

若当前开关状态已知，则可直接使用 local_irq_disable() and local_irq_enable().


No irq handler
~~~~~~~~~~~~~~~~~~~~~
do_IRQ: 1.55 No irq handler for vector


**可能的原因**：  https://ilinuxkernel.com/?p=1192

驱动卸载时，调用free_irq（）释放中断资源，但仍需调用pci_disable_device（）来关闭PCI设备。

若不调用pci_disable_device（），则request_irq（）中申请到的中断向量vector与该PCI设备对应关系可能不会被解除。

于是当再次加载该PCI设备驱动后，PCI设备发出中断，内核仍然会以旧的中断向量vector来解析中断号。

而驱动卸载调用free_irq（）将vector与物理中断号irq对应关系解除。


**调试方法**：https://unix.stackexchange.com/questions/535199/how-to-deduce-the-nature-of-an-interrupt-from-its-number

If your current kernel has debugfs support and **CONFIG_GENERIC_IRQ_DEBUGFS** kernel option enabled,
 you might get a lot of information on the state of IRQ vector 55 with the following commands as root:

::

   mount -t debugfs none /sys/kernel/debug
   grep "Vector.*55" /sys/kernel/debug/irq/irqs/*



do_IRQ
~~~~~~~


https://elixir.bootlin.com/linux/v4.4.157/source/arch/x86/kernel/irq.c#L213

::

   __visible unsigned int __irq_entry do_IRQ(struct pt_regs *regs)
   {
      struct pt_regs *old_regs = set_irq_regs(regs);
      struct irq_desc * desc;
      /* high bit used in ret_from_ code  */
      unsigned vector = ~regs->orig_ax;


      entering_irq();

      /* entering_irq() tells RCU that we're not quiescent.  Check it. */
      RCU_LOCKDEP_WARN(!rcu_is_watching(), "IRQ failed to wake up RCU");

      desc = __this_cpu_read(vector_irq[vector]);

      if (!handle_irq(desc, regs)) {
         ack_APIC_irq();

         if (desc != VECTOR_RETRIGGERED) {
            pr_emerg_ratelimited("%s: %d.%d No irq handler for vector\n",
                     __func__, smp_processor_id(),
                     vector);
         } else {
            __this_cpu_write(vector_irq[vector], VECTOR_UNUSED);
         }
      }

      exiting_irq();

      set_irq_regs(old_regs);
      return 1;
   }



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


waitqueue
--------------
1. `源码解读Linux等待队列 - Gityuan博客 | 袁辉辉的技术博客` <http://gityuan.com/2018/12/02/linux-wait-queue/>`__
2. `Linux等待队列（Wait Queue） - huey_x - 博客园` <https://www.cnblogs.com/hueyxu/p/13745029.html>`__


一种重要的数据结构(链表实现)，和进程调度机制紧密相关。可以用于同步对系统资源的访问(互斥锁)、异步事件通知、跨进程通信等。

休眠与唤醒过程：

1. A: wait_event(wq,condition)向队列头添加等待队列项，记录当前进程+唤醒回调，然后schedule；
2. B: wake_up(wq)遍历wq中每一项并try_to_wake_up(),将对应进程加入rq队列，设置为TASK_RUNNING;
3. A: 被唤醒后继续执行(处于wait_event中)，判断是否跳出或继续schedule.

::

   ___wait_event(wq, condition, state, exclusive, ret, cmd){  
      wait_queue_t __wait;                    
      INIT_LIST_HEAD(&__wait.task_list);                
      for (;;) {
         //当检测进程是否有待处理信号则返回值__int不为0，【见3.1.1】
         long __int = prepare_to_wait_event(&wq, &__wait, state);
         if (condition)  //当满足条件，则跳出循环                    
               break;                        
                                       
         //当有待处理信号且进程处于可中断状态(TASK_INTERRUPTIBLE或TASK_KILLABLE))，则跳出循环
         if (___wait_is_interruptible(state) && __int) {        
               __ret = __int;                    
               break;                      
         }                            
         cmd; //schedule()，进入睡眠，从进程就绪队列选择一个高优先级进程来代替当前进程运行                       
      }                                
      finish_wait(&wq, &__wait);  //如果__wait还位于队列wq，则将__wait从wq中移除              
   }



might_sleep
~~~~~~~~~~~~~
1. `关于might_sleep的一点说明-MagicBoy2010-ChinaUnix博客` <http://blog.chinaunix.net/uid-23769728-id-3157536.html>`__

仅提醒函数会sleep

::

   /**
   * might_sleep - annotation for functions that can sleep
   *
   * this macro will print a stack trace if it is executed in an atomic
   * context (spinlock, irq-handler, ...). Additional sections where blocking is
   * not allowed can be annotated with non_block_start() and non_block_end()
   * pairs.
   *
   * This is a useful debugging help to be able to catch problems early and not
   * be bitten later when the calling function happens to sleep when it is not
   * supposed to.
   */
   # define might_sleep() \
      do { __might_sleep(__FILE__, __LINE__); might_resched(); } while (0)

