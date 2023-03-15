============
中断 
============

1. ☆☆ `Linux中断管理 (1)Linux中断管理机制 - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/8659981.html>`__
2. ☆ 系列文章 `【原创】Linux中断子系统（三）-softirq和tasklet - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/13124803.html>`__
3. `Linux kernel的中断子系统之（二）：IRQ Domain介绍  <http://www.wowotech.net/irq_subsystem/irq-domain.html>`__

硬件中断架构、内核中断子系统、中断处理流程、软中断


中断控制器：将多路中断管线复用为一路并连接到处理器。

每个IRQ中断请求线关联一个中断值。值越小则优先级越高。

x86 中断
============
`Linux下的中断机制 x86 <https://lrita.github.io/2019/03/05/linux-interrupt-and-trap>`__

中断与异常
-------------

1. 中断：异步，由设备使用的硬件资源向处理器发送的电信号， 打断操作系统的执行（甚至是其它中断线上的处理函数），可随时产生。
2. 异常: 又称为同步中断，当指令执行时由CPU控制单元产生的，产生时必须考虑处理器时钟同步。


Intel文档把中断和异常分为以下几类：

**异常：**

当CPU执行指令时探测到一个异常，会产生一个处理器探测异常（processor-detected exception），可以进一步区分，这取决于CPU控制单元产生异常时保存在内核堆栈eip寄存器的值。

1. 故障（fault），通常可以纠正，一旦纠正，程序就可以重新开始，
   保存在eip寄存器中的值是引起故障的指令地址。
2. 陷阱（trap）在陷阱指令执行后立即报告，内核把控制权烦给程序后就可以继续它的执行而不失连续性。
   保存在eip中的值是一个随后要执行的指令地址。陷阱的主要作用是为了调试程序。
3. 异常中止（abort），发生一个严重的错误，控制单元出了问题，
   不能在eip寄存器中保存引起异常的指令所在的确切位置。异常中止用于报告严重的错误，例如硬件故障或系统表中无效的值或者不一致的值。这种异常会强制中止进程。
4. 编程异常（programmed exception），在编程者发出的请求时发送，是由int或int3指令触发的。



IDT表
~~~~~~~~~


IDT表有256成员向量(NR_VECTORS)。总中断数量还需考虑IO_APIC和PCI_MSI。

非屏蔽中断的向量和异常的向量是固定的，而可屏蔽中断的向量是可以通过对中断控制器的编程来改变。


arch/x86/include/asm/irq_vectors.h：

::

   * Linux IRQ vector layout.
   *
   * There are 256 IDT entries (per CPU - each entry is 8 bytes) which can
   * be defined by Linux. They are used as a jump table by the CPU when a
   * given vector is triggered - by a CPU-external, CPU-internal or
   * software-triggered event.
   *
   * Linux sets the kernel code address each entry jumps to early during
   * bootup, and never changes them. This is the general layout of the
   * IDT entries:
   *
   *  Vectors   0 ...  31 : system traps and exceptions - hardcoded events
   *  Vectors  32 ... 127 : device interrupts
   *  Vector  128         : legacy int80 syscall interface
   *  Vectors 129 ... LOCAL_TIMER_VECTOR-1
   *  Vectors LOCAL_TIMER_VECTOR ... 255 : special interrupts
   *
   * 64-bit x86 has per CPU IDT tables, 32-bit has one shared IDT table.



0-31号：arch/x86/include/asm/trapnr.h 与 SDM Volume 3中Table 6-1 Protected-Mode Exceptions and Interrupts一一对应。

中断/异常0-31：

::

   /* Interrupts/Exceptions */

   #define X86_TRAP_DE		 0	/* Divide-by-zero */
   #define X86_TRAP_DB		 1	/* Debug */
   #define X86_TRAP_NMI		 2	/* Non-maskable Interrupt */
   #define X86_TRAP_BP		 3	/* Breakpoint */
   #define X86_TRAP_OF		 4	/* Overflow */
   #define X86_TRAP_BR		 5	/* Bound Range Exceeded */
   #define X86_TRAP_UD		 6	/* Invalid Opcode */
   #define X86_TRAP_NM		 7	/* Device Not Available */
   #define X86_TRAP_DF		 8	/* Double Fault */
   #define X86_TRAP_OLD_MF		 9	/* Coprocessor Segment Overrun */
   #define X86_TRAP_TS		10	/* Invalid TSS */
   #define X86_TRAP_NP		11	/* Segment Not Present */
   #define X86_TRAP_SS		12	/* Stack Segment Fault */
   #define X86_TRAP_GP		13	/* General Protection Fault */
   #define X86_TRAP_PF		14	/* Page Fault */
   #define X86_TRAP_SPURIOUS	15	/* Spurious Interrupt */
   #define X86_TRAP_MF		16	/* x87 Floating-Point Exception */
   #define X86_TRAP_AC		17	/* Alignment Check */
   #define X86_TRAP_MC		18	/* Machine Check */
   #define X86_TRAP_XF		19	/* SIMD Floating-Point Exception */
   #define X86_TRAP_VE		20	/* Virtualization Exception */
   #define X86_TRAP_CP		21	/* Control Protection Exception */
   #define X86_TRAP_VC		29	/* VMM Communication Exception */
   #define X86_TRAP_IRET		32	/* IRET Exception */





arm64中断
==============
中断控制器
------------


arm64系统调用
--------------
1. `armv8/arm64 中断/系统调用流程 <https://cloud.tencent.com/developer/article/1413292>`__  
   `arm64系统调用分析 - tycoon3 - 博客园  <https://www.cnblogs.com/dream397/p/15993907.html>`__
2. ☆ `Linux Kernel 5.14 arm64异常向量表解读-中断处理解读  <https://blog.csdn.net/weixin_42135087/article/details/120232101>`__


arm异常向量表
~~~~~~~~~~~~~~~~~~
1. `ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/CHDEEDDC>`__


有四张表，每张表有四个异常入口，分别对应同步异常，IRQ，FIQ和出错异常。



.. figure:: /images/exception_vector_table.png
   :alt: exception_vector_table

3. 如果发生异常会导致exception level切换，并且比目的exception level低一级的exception level运行在AARCH64模式，那么使用第三张异常向量表。

每个异常入口占用0x80B空间，除了跳转指令还能放置其它指令。


arch/arm64/kernel/entry.S

::

   /*
   * Exception vectors.
   */
      .pushsection ".entry.text", "ax"

      .align	11
   SYM_CODE_START(vectors)
      kernel_ventry	1, sync_invalid			// Synchronous EL1t
      kernel_ventry	1, irq_invalid			// IRQ EL1t
      kernel_ventry	1, fiq_invalid			// FIQ EL1t
      kernel_ventry	1, error_invalid		// Error EL1t

      kernel_ventry	1, sync				// Synchronous EL1h
      kernel_ventry	1, irq				// IRQ EL1h
      kernel_ventry	1, fiq_invalid			// FIQ EL1h
      kernel_ventry	1, error			// Error EL1h

      kernel_ventry	0, sync				// Synchronous 64-bit EL0
      kernel_ventry	0, irq				// IRQ 64-bit EL0
      kernel_ventry	0, fiq_invalid			// FIQ 64-bit EL0
      kernel_ventry	0, error			// Error 64-bit EL0

   #ifdef CONFIG_COMPAT
      kernel_ventry	0, sync_compat, 32		// Synchronous 32-bit EL0
      kernel_ventry	0, irq_compat, 32		// IRQ 32-bit EL0
      kernel_ventry	0, fiq_invalid_compat, 32	// FIQ 32-bit EL0
      kernel_ventry	0, error_compat, 32		// Error 32-bit EL0
   #else
      kernel_ventry	0, sync_invalid, 32		// Synchronous 32-bit EL0
      kernel_ventry	0, irq_invalid, 32		// IRQ 32-bit EL0
      kernel_ventry	0, fiq_invalid, 32		// FIQ 32-bit EL0
      kernel_ventry	0, error_invalid, 32		// Error 32-bit EL0
   #endif
   SYM_CODE_END(vectors)


- 私有寄存器：即后缀带数字的那些寄存器。
- 公用寄存器：后缀不带数字，包括常见的x0-x30


linux中断向量表
~~~~~~~~~~~~~~~~~~~~
arch/arm64/kernel/entry.S：


当发生中断、异常、系统调用时，硬件会自动：

1. 把当前程序的pc值放入ELR_ELx中
2. 把当前状态PSTATE存入SPSR_ELx中
3. 改变PSTATE(中断:DAIF设置为1)
4. sp切换为sp_el1x。
5. 切换EL，pc跳转到el1_sync/el1_irq/el0_sync/el0_irq


.. important:: 如何切换EL？

`ARMV8/ARMV9的执行状态的切换_arm 任务切换_代码改变世界ctw的博客-CSDN博客  <https://blog.csdn.net/weixin_42135087/article/details/123422417>`__


el1_sync，el1_irq，el0_sync，el0_irq在开始时会调用kernel_entry，在结束时会调用kernel_exit。

1. **el1_sync**：当前处于内核态时，发生了指令执行异常、缺页中断（跳转地址或者取地址）。
2. **el1_irq**：当前处于内核态时，发生硬件中断。
3. **el0_sync**：当前处于用户态时，发生了指令执行异常、缺页中断（跳转地址或者取地址）、系统调用。
4. **el0_iqr**：当前处于用户态时，发生了硬件中断。


异常类别
~~~~~~~~~~~


系统调用指令异常
~~~~~~~~~~~~~~~~~~~~~~~~~~
SVC/HVC/SMC


1. svc:supervisor call 应用程序调用kernel（el0-》el1）功能
2. hvc：hypervisor call，os 调用hypervisor（EL2）
3. smc secure monitor call ，os or ypervisor 调用 secure monitor （El3）

SVC系统调用约定
~~~~~~~~~~~~~~~~~

SVC指令在ARMv8体系中为异常处理类指令

用 **SVC指令触发系统调用** 的约定如下：

1. 64位用户程序使用寄存器 **x8传递系统调用号**，32位用户程序使用寄存器x7传递系统调用号；
2. 使用寄存器x0-x6传递系统调用所需参数，最多可传递7个参数；
3. 系统调用执行完后，用寄存器 **x0存放返回值**。



request_irq
=================
request_irq参数
-----------------
`Linux(内核剖析):20---中断之中断处理程序（request_irq、free_irq）  <https://blog.csdn.net/qq_41453285/article/details/103945123>`__

handler：发生中断时首先要执行的硬，也可返回IRQ_HANDLE不执行中断线程

thread_fn : 中断线程，类似于中断下半部

::

   /**
   * request_irq - Add a handler for an interrupt line
   * @irq:	The interrupt line to allocate //逻辑中断号，/proc。可以预设固定、可以动态编程、可以探测获取。
   * @handler:	Function to be called when the IRQ occurs.  // irqreturn_t irq_handler_t(int irq, void *dev) 被调用时irq和dev来源于request_irq
   *		Primary handler for threaded interrupts
   *		If NULL, the default primary handler is installed
   * @flags:	Handling flags   //中断属性等。共享、关其它终端、上升沿
   * @name:	Name of the device generating this interrupt
   * @dev:	A cookie passed to the handler function //用于区分共享中断，也可传递其它结构
   *
   * This call allocates an interrupt and establishes a handler; see
   * the documentation for request_threaded_irq() for details.
   */
   static inline int __must_check
   request_irq(unsigned int irq, irq_handler_t handler, unsigned long flags,
         const char *name, void *dev)
   {
      return request_threaded_irq(irq, handler, NULL, flags, name, dev);
   }

   int request_threaded_irq(unsigned int irq, irq_handler_t handler,
            irq_handler_t thread_fn, unsigned long irqflags,
            const char *devname, void *dev_id)
   {
   .............

      desc = irq_to_desc(irq);

      action->handler = handler;
      action->thread_fn = thread_fn;
      action->flags = irqflags;
      action->name = devname;
      action->dev_id = dev_id;
   ..............
   // handler中断处理函数，可以通过返回 IRQ_WAKE_THREADED唤醒中断线程thread_fn


    



中断上半部
=============

即中断处理程序。运行于中断上下文中，不可阻塞。

上半部执行具有严格时限的工作，运行时可禁止所有其它中断（大部分不会），
同时在其它处理器上禁止同一中断线，即同一中断处理程序不会被同时调用以处理嵌套的中断，即无需重入。

中断栈
----------

中断栈的创建：内核启动时中会去为每个cpu创建一个per cpu的中断栈：start_kernel->init_IRQ->init_irq_stacks
中断栈的使用：中断发生和退出的时候调用irq_stack_entry和irq_stack_exit来进入和退出中断栈。


新内核中一般独立于线程栈,都是16K。栈溢出？

用户态线程栈：8M

::

   #define IRQ_STACK_SIZE   THREAD_SIZE

   thread_info.h中定义了大小。

   define THREAD_SIZE  16384     //也就是irq栈的大小大概15k


中断下半部
===============
下半部：所有用于实现将工作推后执行的内核机制。

1. 可调度/休眠 -> 工作队列
2. 性能要求高  -> 软中断
3. 大多数情况  -> tasklet

这里的软中断与系统调用使用的软件中断不同。



可延时函数与工作队列
-----------------------
2. `《深入理解Linux内核》软中断/tasklet/工作队列 - only_eVonne - 博客园  <https://www.cnblogs.com/li-hao/archive/2012/01/12/2321084.html>`__


1. 可延时函数：由软中断或tasklet实现。运行在中断上下文(如do_IRQ退出时即为一个软中断检查点)，不能睡眠、阻塞。
2. 工作队列：运行在进程上下文，可阻塞。
3. 中断线程化：wakeup_softirqd唤醒内核线程来执行，该线程和其它线程一样需要调度。 耗时较长、实时性不高的场景，避免影响用户线程的实时性。
4. 非线程化中断：调用__do_softirq函数来处理。Bottom-half Enable 和 do_IRQ退出 时检查执行。




软中断
----------
1. `Linux内核软中断softirq和小任务tasklet分析（六）_软中断在什么时候执行_业余程序员plus的博客-CSDN博客  <https://blog.csdn.net/u011037593/article/details/114795032>`__

- Linux中没有实现中断优先级，即不支持真正意义的中断嵌套。
- 硬中断处理时会停止响应其它中断，并且屏蔽本类型中断(丢失)。
- 软中断处理可能处于硬中断上下文(所以不能睡眠)，这时会打开本地中断，关闭软中断，处理完后在关闭本地中断。可能会发生中断处理函数嵌套()。
- Gicv3实现了 抢占+响应优先级，即中断嵌套

1. 对性能要求非常高的场景（如网络、SCSI）。编译时静态注册。
2. 



tasklet
-----------------

1. 适用大部分下半部处理。使用软中断实现。也可动态注册。
2. 两个不同类型的tasklet可以在不同处理器上同时执行，但两个相同类型的tasklet不能同时执行 。




工作队列
---------------

1. 可在进程上下文运行。
2. 允许重新调度和睡眠（获取大量内存、获取信号量、阻塞式IO时）。


工作队列提供把需要推后执行的任务交给特定的通用线程的接口。
工作队列线程被唤醒时，已被调度的任务才被执行。

工作队列处理函数运行在进程上下文中，但不能访问用户空间，
因为内核线程在用户空间没有相关的内存映射。

系统调用时内核代表用户空间的进程运行，可访问用户空间，会映射用户空间的内存。



中断嵌套
------------
实际就是高优先级中断打断低优先级中断，新版本内核已经不支持。




