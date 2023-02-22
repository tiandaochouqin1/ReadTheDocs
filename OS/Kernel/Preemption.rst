
调度与抢占
=============


抢占和上下文切换
------------------

1. `调度时机 - Daniel.G - 博客园 <https://www.cnblogs.com/Daniel-G/p/3306674.html>`__
2. `进程管理(二十一)---进程调度时机_任务调度和进程调度 <https://blog.csdn.net/u012489236/article/details/122263474>`__
3. `进程切换：自愿(voluntary)与强制(involuntary) | Linux Performance  <http://linuxperf.com/?p=209>`__

抢占
~~~~~~
自愿切换和强制切换：

1. 自愿切换发生的时候，进程不再处于运行状态，比如由于等待IO而阻塞(TASK_UNINTERRUPTIBLE)，或者因等待资源和特定事件而休眠(TASK_INTERRUPTIBLE)，又或者被debug/trace设置为TASK_STOPPED/TASK_TRACED状态；
2. 强制切换发生的时候，进程仍然处于运行状态(TASK_RUNNING)，通常是由于被优先级更高的进程抢占(preempt)，或者进程的时间片用完了。

context_switch
~~~~~~~~~~~~~~~~~~~
上下文切换：即从一个可执行程序切换到另一个可执行程序。

_schedule -> context_switch()： 完成地址空间切换switch_mm()和处理器状态恢复switch_to()。

::

   /*
    * context_switch - switch to the new MM and the new thread's register state.
    */
   static __always_inline struct rq *
   context_switch(struct rq *rq, struct task_struct *prev,
   	       struct task_struct *next, struct rq_flags *rf)
   {
   	struct mm_struct *mm, *oldmm;
   ......
   	mm = next->mm;
   	oldmm = prev->active_mm;
   ......
   	switch_mm_irqs_off(oldmm, mm, next);
   ......
   	/* Here we just switch the register state and the stack. */
   	switch_to(prev, next, prev);
   	barrier();
   	return finish_task_switch(prev);
   }


switch_to
~~~~~~~~~~~
通过三个变量 switch_to(prev = A, next=B, last=C)，

A 进程就明白了，我当时被切换走的时候，是切换成 B，这次切换回来，是从 C 回来的。

::

   #define switch_to(prev, next, last)					\
   do {									\
   	prepare_switch_to(prev, next);					\
   									\
   	((last) = __switch_to_asm((prev), (next)));			\
   } while (0)



TSS
~~~~~~~
内核态。


x86 在内存里面维护一个 TSS（Task State Segment，任务状态段）结构。这里面有所有的寄存器。

为了避免全量切换，Linux在 cpu_init 中给每一个 CPU 关联一个 TSS，然后将 TR 永远指向这个 TSS。

task_struct的最后一个成员变量thread保存了需要切换的寄存器：


真的参与进程切换的寄存器很少，主要的就是 ``栈顶寄存器``。	


CPU角度的进程切换：将某个进程的 thread_struct 里面的寄存器的值，写入到 CPU 的 TR 指向的 tss_struct

::

   /* CPU-specific state of this task: */
   struct thread_struct		thread; //这个结构的内容与体系相关!! ia64和x86都不一样



pt_regs和cpu_context
~~~~~~~~~~~~~~~~~~~~~
task_struct成员stack指向内核栈，内核栈顶部的pt_regs中保存用户态的regs。


arm：

1. pt_regs和cpu_context都是处理器架构相关的结构。

2. pt_regs是发生异常时（当然包括中断）保存的处理器现场，用于异常处理完后来恢复现场，它保存在进程内核栈中。

3. cpu_context是发生进程切换时，保存当前进程的上下文，保存在当前进程的进程描述符中。

4. pt_regs表征发生异常时处理器现场，cpu_context发生调度时当前进程的处理器现场。

参考

1. `Arm64 Linux 5.0 - 深入理解Linux内核进程上下文切换 <https://cloud.tencent.com/developer/article/1710837>`__
2. `x86 Linux 4.6 - Linux进程上下文切换过程context_switch详解 <https://blog.csdn.net/gatieme/article/details/51872659>`__
3. `fork背后隐藏的技术细节 <https://zhuanlan.zhihu.com/p/373958196>`__


need_resched
~~~~~~~~~~~~~~
表明需要重新执行一次调度，强制调度，有调度延时。

当某个进程应该被抢占时，或更高优先级的进程进入可执行状态时，需要设置此标志。

该标志包含在进程描述符内，访问进程描述符内的变量比访问全局变量快（current宏速度快且进程描述符通常在告诉缓存内）。


用户抢占与内核抢占preempt
----------------------------
1. preempt_rt内核    :download:`网络基本功 <https://bootlin.com/doc/training/preempt-rt/preempt-rt-slides.pdf>`
2. `Linux用户抢占和内核抢占详解(概念, 实现和触发时机)` <https://cloud.tencent.com/developer/article/1368153>`__
3. `Linux内核抢占` <https://feilengcui008.github.io/post/linux%E5%86%85%E6%A0%B8%E6%8A%A2%E5%8D%A0/>`__

触发调度的点有： **定时器中断、唤醒进程时、迁移进程时、改变进程优先级时**。

执行调度的点有：

**用户抢占时机**

1. 从系统调用返回用户空间时；
2. 从中断处理程序返回用户空间时。


**内核抢占时机**

1. 中断返回到内核时。
2. 可以在任何时间抢占任务（只要没有锁）.通常发生在 禁用抢占临界区结束(preempt_enable)、禁用软中断临界区结束、cond_resched调用点。

preempt_enable() 会调用 preempt_count_dec_and_test()，判断 preempt_count 和 TIF_NEED_RESCHED 看是否可以被抢占。

如果可以，就调用 preempt_schedule->preempt_schedule_common->__schedule 进行调度。

.. figure:: /images/schedule_and_preempt.png

            抢占式调度


_schedule上下文切换
~~~~~~~~~~~~~~~~~~~~
.. important:: 上下文切换的具体过程？


.. figure:: /images/context_switch.jpg

               context_switch


中断为什么不能睡眠/调度
------------------------
1. `为什么Linux不能在中断中睡眠 - schips - 博客园  <https://www.cnblogs.com/schips/p/why_isr_can_not_schedule_in_linux.html>`__

.. important:: 中断为什么不能休眠？



中断只能被其他中断中止、抢占，进程不能中止、抢占中断。

中断是一种紧急事务，需要操作系统立即处理，不是不能做到睡眠，是没必要睡眠。



1. 无法被唤醒。在中断context中，唯一能打断当前中断handler的只有更高优先级的中断；
   所有的wake_up_xxx都是针对进程task_struct而言，
   Linux是以进程为调度单位的，调度器只看到进程内核栈，而看不到中断栈。

2. 导致上下文错乱。睡眠函数nanosleep(do_nanosleep,v5.13)会调用schedule()，切换进程时，保存当前的进程上下文，但此时的pc、sp等寄存器已经被中断修改了。中断发生后，内核会先保存当前被中断的进程上下文（在调用中断处理程序后恢复）。


中断睡眠后会发什么
~~~~~~~~~~~~~~~~~~

内核会刷屏以下两个打印：

::

   这个warn刷屏： preempt_count!=1，本应该为1
   bad: scheduling from the idle thread!
   
   开始是以下两类warn，20来次。preempt_count=1，
   BUG: scheduling while atomic: **thread_name**
   huh, entered softirq 2 NET_TX ffffffff81613740 preempt_count 00000101, exited with 7ffffffe?
   

均来自于schedule:

1. 中断与进程共享栈，如果idle进程中发生的中断进行睡眠，则内核会有警告。

   为什么do_idle -> schedule_idle不会走到这个分支: 因为执行了preempt_set_need_resched设置了preempt_count为可抢占？

::

   schedule -> __schedule -> deactivate_task -> dequeue_task_idle

   asmlinkage __visible void __sched schedule(void)
   {
      struct task_struct *tsk = current;

      sched_submit_work(tsk);
      do {
         preempt_disable();
         __schedule(false);
         sched_preempt_enable_no_resched();
      } while (need_resched());
      sched_update_worker(tsk);
   }


   /*
   * It is not legal to sleep in the idle task - print a warning
   * message if some code attempts to do it:
   */
   static void  dequeue_task_idle(struct rq *rq, struct task_struct *p, int flags)
   {
      raw_spin_unlock_irq(&rq->lock);
      printk(KERN_ERR "bad: scheduling from the idle thread!\n");
      dump_stack();
      raw_spin_lock_irq(&rq->lock);
   }


2. atomic

::

   __schedule -> schedule_debug -> __schedule_bug

   /*
   * Various schedule()-time debugging checks and statistics:
   */

   static inline void schedule_debug(struct task_struct *prev, bool preempt)
   {
   ....

      if (unlikely(in_atomic_preempt_off())) {
         __schedule_bug(prev);
         preempt_count_set(PREEMPT_DISABLED);
      }
   ...
      schedstat_inc(this_rq()->sched_count);
   }

   /*
   * Print scheduling while atomic bug:
   */
   static noinline void __schedule_bug(struct task_struct *prev)
   {

      printk(KERN_ERR "BUG: scheduling while atomic: %s/%d/0x%08x\n",
         prev->comm, prev->pid, preempt_count());
   ......
      dump_stack();
      add_taint(TAINT_WARN, LOCKDEP_STILL_OK);
   }

3. preempt count

::

   __do_softirq

   	while ((softirq_bit = ffs(pending))) {
		unsigned int vec_nr;
		int prev_count;

		h += softirq_bit - 1;

		vec_nr = h - softirq_vec;
		prev_count = preempt_count();

		kstat_incr_softirqs_this_cpu(vec_nr);

		trace_softirq_entry(vec_nr);
		h->action(h);
		trace_softirq_exit(vec_nr);
		if (unlikely(prev_count != preempt_count())) {
			pr_err("huh, entered softirq %u %s %p with preempt_count %08x, exited with %08x?\n",
			       vec_nr, softirq_to_name[vec_nr], h->action,
			       prev_count, preempt_count());
			preempt_count_set(prev_count);
		}
		h++;
		pending >>= softirq_bit;
	}

preempt_count
~~~~~~~~~~~~~~~~~~~
1. `调度器17—preempt_count和各种上下文 - Hello-World3 - 博客园  <https://www.cnblogs.com/hellokitty2/p/15652312.html>`__
2. `LWN：关于preempt_count()的四个小讨论！_LinuxNews搬运工的博客-CSDN博客  <https://blog.csdn.net/Linux_Everything/article/details/109088796>`__  https://lwn.net/Articles/831678/
3. `进程切换分析（3）：同步处理  <http://www.wowotech.net/process_management/scheudle-sync.html>`__
4. `Linux进程核心调度器之主调度器schedule--Linux进程的管理与调度(十九） - 腾讯云开发者社区-腾讯云  <https://cloud.tencent.com/developer/article/1367956>`__


.. figure:: /images/preempt_count.png

   preempt_count



include/preempt.h

::

   /*
   * We put the hardirq and softirq counter into the preemption
   * counter. The bitmask has the following meaning:
   *
   * - bits 0-7 are the preemption count (max preemption depth: 256)
   * - bits 8-15 are the softirq count (max # of softirqs: 256)
   *
   * The hardirq count could in theory be the same as the number of
   * interrupts in the system, but we run all interrupt handlers with
   * interrupts disabled, so we cannot have nesting interrupts. Though
   * there are a few palaeontologic drivers which reenable interrupts in
   * the handler, so we need more than one bit here.
   *
   *         PREEMPT_MASK:	0x000000ff
   *         SOFTIRQ_MASK:	0x0000ff00
   *         HARDIRQ_MASK:	0x000f0000
   *             NMI_MASK:	0x00f00000
   * PREEMPT_NEED_RESCHED:	0x80000000
   */



每次加1，schedule后不会回来继续执行，可能溢出到其它bit：

IRQ： __irq_enter、__irq_enter_raw、__nmi_enter


::

   /*
   * It is safe to do non-atomic ops on ->hardirq_context,
   * because NMI handlers may not preempt and the ops are
   * always balanced, so the interrupted value of ->hardirq_context
   * will always be restored.
   */
   #define __irq_enter()					\
      do {						\
         account_irq_enter_time(current);	\
         preempt_count_add(HARDIRQ_OFFSET);	\
         lockdep_hardirq_enter();		\
      } while (0)



softirq: __local_bh_disable_ip

::

   static __always_inline void __local_bh_disable_ip(unsigned long ip, unsigned int cnt)
   {
      preempt_count_add(cnt);
      barrier();
   }

   static inline void local_bh_enable_ip(unsigned long ip)
   {
      __local_bh_enable_ip(ip, SOFTIRQ_DISABLE_OFFSET);
   }

