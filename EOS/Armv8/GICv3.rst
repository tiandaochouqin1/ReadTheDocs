
Generic Interrupt Controller v3
====================================
1. `6.分析request_irq和free_irq函数如何注册注销中断(详解) - 诺谦 - 博客园  <https://www.cnblogs.com/lifexy/p/7506613.html>`__
2. `Linux内核网络收包角度——浅入中断(1)  <https://mp.weixin.qq.com/s/H4YOd9IaLQBvNWc8Z7dSAg>`__
3. `7_Linux硬件中断处理 - 最后一只晴天小猪的博客  <https://santapasserby.com/2021/07/06/ldd/7_Linux%E7%A1%AC%E4%BB%B6%E4%B8%AD%E6%96%AD%E5%A4%84%E7%90%86/>`__
4. `Linux内核网络收包角度——浅入中断(1)  <https://mp.weixin.qq.com/s/H4YOd9IaLQBvNWc8Z7dSAg>`__
5. ☆ 从硬件到软件，系列4篇 `【原创】Linux中断子系统（一）-中断控制器及驱动分析 - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/12996812.html>`__

GIC v3
--------
1. `ARM GICv3中断控制器_Hober_yao的博客-CSDN博客  <https://blog.csdn.net/yhb1047818384/article/details/86708769>`__
2. `Learn the architecture - Arm Generic Interrupt Controller v3 and v4` <https://developer.arm.com/documentation/198123/0302/Arm-GIC-fundamentals?lang=en>`__

GICv3控制器组成和路由
~~~~~~~~~~~~~~~~~~~~~

1. distributor： SPI中断的管理，将中断发送给redistributor. (包括 enable/disable、priority、level/edge、group 等配置。distributor和redistributor功能实际很类似)
2. redistributor： PPI，SGI，LPI中断的管理，将中断发送给cpu interface
3. cpu interface： 传输中断给core
4. ITS： Interrupt Translation Service, 用来解析LPI中断

.. figure:: /images/GIC_v3.png

   GIC_v3

   
.. figure:: /images/GIC_v3_controller.png

   GIC_v3_controller


GIC v3中断类别
~~~~~~~~~~~~~~~~~~~~
GICv3定义了以下中断类型：

::
      
   SPI (Shared Peripheral Interrupt)
   公用的外部设备中断，也定义为共享中断。可以多个Cpu或者说Core处理，不限定特定的Cpu。比如按键触发一个中断，手机触摸屏触发的中断。

   PPI (Private Peripheral Interrupt)
   私有外设中断。这是每个核心私有的中断。PPI会送达到指定的CPU上，应用场景有CPU本地时钟。

   SGI (Software Generated Interrupt)
   软件触发的中断。软件可以通过写GICD_SGIR寄存器来触发一个中断事件，一般用于核间通信。

   LPI (Locality-specific Peripheral Interrupt)
   LPI是GICv3中的新特性，它们在很多方面与其他类型的中断不同。LPI始终是基于消息的中断，它们的配置保存在表中而不是寄存器。比如PCIe的MSI/MSI-x中断。



.. figure:: /images/gic_interrupt_type.jpg

   gic_interrupt_type


如图，GICv3有PPI和SPI两种中断。



中断处理流程
~~~~~~~~~~~~
1. 外设发起中断，发送给 Distributor
2. Distributor 将该中断，分发给合适的 Redistributor
3. Redistributor 将中断信息，发送给 CPU interface
4. CPU interface 产生合适的中断异常给处理器
5. 处理器接收该异常，并且软件处理该中断


.. figure:: /images/intr_state.png
   :scale: 80%

   intr_state


.. figure:: /images/Gic-600_interconnect.jpg
   :scale: 80%

   Gic-600_interconnect

distributor也可不直接连接interconnnect或its。见  `Arm CoreLink GIC-600 Generic Interrupt Controller Technical Reference Manual r1p6 <https://developer.arm.com/documentation/100336/0106/introduction/components>`__


ITS
~~~~~

.. figure:: /images/Gicv3_ITS.png
   :scale: 80%

   Gicv3_ITS


Linux GICv3实现
------------------
irq 管理数据结构
~~~~~~~~~~~~~~~~~~~~

1. `Linux 中断 —— GIC (数据结构 irq_domain/irq_desc/irq_data/irq_chip/irqaction)_irq domain和irq chip_爱洋葱的博客-CSDN博客  <https://blog.csdn.net/zhoutaopower/article/details/90648475>`__
2. `linux IRQ Management（五）- irq_desc_Hacker_Albert的博客-CSDN博客  <https://blog.csdn.net/weixin_41028621/article/details/101753159>`__


.. figure:: /images/irq_manage_struct.png

   irq_manage_struct


GICv3 初始化
~~~~~~~~~~~~~~~
1. `GICv3驱动初始化_Loopers的博客-CSDN博客  <https://blog.csdn.net/longwang155069/article/details/105275286>`__
2. ☆☆ `Linux中断管理 (1)Linux中断管理机制 - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/8659981.html>`__
3. `Linux kernel的中断子系统之（二）：IRQ Domain介绍  <http://www.wowotech.net/irq_subsystem/irq-domain.html>`__
4. `第五章 ARM的中断处理 | Linux内核与嵌入式开发  <https://wugaosheng.gitbooks.io/linux-arm/content/di-wu-zhang-arm-de-zhong-duan-chu-li.html>`__
5. ☆ 系列文章 `【原创】Linux中断子系统（三）-softirq和tasklet - LoyenWang - 博客园  <https://www.cnblogs.com/LoyenWang/p/13124803.html>`__


::

   init_IRQ -> irqchip_init -> of_irq_init(__irqchip_of_table) 根据dts匹配中断控制器 -> 回调gic_of_init 
    ->gic_of_init 初始化 -> set_handle_irq(gic_handle_irq)设置中断处理的回调函数,在汇编中被调用 

   gic_handle_irq -> handle_domain_irq -> handle_domain_irq -> generic_handle_irq ->generic_handle_irq_desc -> desc->handle_irq(desc) = 



一个中断的生命周期：

::

   vector_irq()->vector_irq()->__irq_svc()

   ->svc_entry()--------------------------------------------------------------------------保护中断现场

   ->irq_handler()->gic_handle_irq()------------------------------------------------具体到GIC中断控制器对应的就是gic_handle_irq()，此处从架构相关进入了GIC相关处理。

      ->GIC_CPU_INTACK--------------------------------------------------------------读取IAR寄存器，响应中断。

      ->handle_domain_irq()

         ->irq_enter()------------------------------------------------------------------------进入硬中断上下文

         ->generic_handle_irq()

         ->generic_handle_irq_desc()->handle_fasteoi_irq()--------------------根据中断号分辨不同类型的中断，对应不同处理函数，这里中断号取大于等于32。

            ->handle_irq_event()->handle_irq_event_percpu()

               ->action->handler()-----------------------------------------------------------对应到特定中断的处理函数，即上半部。

               ->__irq_wake_thread()-----------------------------------------------------如果中断函数处理返回IRQ_WAKE_THREAD，则唤醒中断线程进行处理，但不是立即执行中断线程。

         ->irq_exit()---------------------------------------------------------------------------退出硬中断上下文。视情况处理软中断。

         ->invoke_softirq()-----------------------------------------------------------------处理软中断，超出一定条件任务就会交给软中断线程处理。

      ->GIC_CPU_EOI--------------------------------------------------------------------写EOI寄存器，表示结束中断。至此GIC才会接收新的硬件中断，此前一直是屏蔽硬件中断的。

   ->svc_exit-------------------------------------------------------------------------------恢复中断现场



1. 中断上半部是关硬件中断的，直到写EOI之后。
2. 不是所有软中断都运行于软中断上下文中，部分软中断任务可能会交给ksoftirqd线程处理。


::

   /**
   * __handle_domain_irq - Invoke the handler for a HW irq belonging to a domain
   * @domain:	The domain where to perform the lookup
   * @hwirq:	The HW irq number to convert to a logical one
   * @lookup:	Whether to perform the domain lookup or not
   * @regs:	Register file coming from the low-level handling code
   *
   * Returns:	0 on success, or -EINVAL if conversion has failed
   */
   int __handle_domain_irq(struct irq_domain *domain, unsigned int hwirq,
            bool lookup, struct pt_regs *regs)
   {
      struct pt_regs *old_regs = set_irq_regs(regs);
      unsigned int irq = hwirq;
      int ret = 0;

      irq_enter();

   #ifdef CONFIG_IRQ_DOMAIN
      if (lookup)
         irq = irq_find_mapping(domain, hwirq);
   #endif

      /*
      * Some hardware gives randomly wrong interrupts.  Rather
      * than crashing, do something sensible.
      */
      if (unlikely(!irq || irq >= nr_irqs)) {
         ack_bad_irq(irq);
         ret = -EINVAL;
      } else {
         generic_handle_irq(irq);
      }

      irq_exit();
      set_irq_regs(old_regs);
      return ret;
   }



   /**
   * irq_enter - Enter an interrupt context including RCU update
   */
   void irq_enter(void)
   {
      rcu_irq_enter();
      irq_enter_rcu();
   }


   /**
   * irq_exit - Exit an interrupt context, update RCU and lockdep
   *
   * Also processes softirqs if needed and possible.
   */
   void irq_exit(void)
   {
      __irq_exit_rcu();    // call invoke_softirq
      rcu_irq_exit();
      /* must be last! */
      lockdep_hardirq_exit();
   }


irq_desc
~~~~~~~~~~~~

irq_domain
~~~~~~~~~~~~~~~~~~~


::

   static struct irq_chip gic_chip = {
      .name			= "GICv3",
      .irq_mask		= gic_mask_irq,
      .irq_unmask		= gic_unmask_irq,
      .irq_eoi		= gic_eoi_irq,
      .irq_set_type		= gic_set_type,
      .irq_set_affinity	= gic_set_affinity,
      .irq_retrigger          = gic_retrigger,
      .irq_get_irqchip_state	= gic_irq_get_irqchip_state,
      .irq_set_irqchip_state	= gic_irq_set_irqchip_state,
      .irq_nmi_setup		= gic_irq_nmi_setup,
      .irq_nmi_teardown	= gic_irq_nmi_teardown,
      .ipi_send_mask		= gic_ipi_send_mask,
      .flags			= IRQCHIP_SET_TYPE_MASKED |
               IRQCHIP_SKIP_SET_WAKE |
               IRQCHIP_MASK_ON_SUSPEND,
   };



`linux硬件中断（hwirq）和软件中断号（virq）的映射过程_linux中断号_田园诗人之园的博客-CSDN博客  <https://blog.csdn.net/u014100559/article/details/124918989>`__

::

   static int gic_irq_domain_translate(struct irq_domain *d,
                  struct irq_fwspec *fwspec,
                  unsigned long *hwirq,
                  unsigned int *type)
   {
      if (fwspec->param_count == 1 && fwspec->param[0] < 16) {
         *hwirq = fwspec->param[0];
         *type = IRQ_TYPE_EDGE_RISING;
         return 0;
      }

      if (is_of_node(fwspec->fwnode)) {
         if (fwspec->param_count < 3)
            return -EINVAL;

         switch (fwspec->param[0]) {
         case 0:			/* SPI */
            *hwirq = fwspec->param[1] + 32;
            break;
         case 1:			/* PPI */
            *hwirq = fwspec->param[1] + 16;
            break;
         case 2:			/* ESPI */
            *hwirq = fwspec->param[1] + ESPI_BASE_INTID;
            break;
         case 3:			/* EPPI */
            *hwirq = fwspec->param[1] + EPPI_BASE_INTID;
            break;
         case GIC_IRQ_TYPE_LPI:	/* LPI */
            *hwirq = fwspec->param[1];
            break;
         case GIC_IRQ_TYPE_PARTITION:
            *hwirq = fwspec->param[1];
            if (fwspec->param[1] >= 16)
               *hwirq += EPPI_BASE_INTID - 16;
            else
               *hwirq += 16;
            break;
         default:
            return -EINVAL;
         }

         *type = fwspec->param[2] & IRQ_TYPE_SENSE_MASK;

   .................

   }


proc interrupts
~~~~~~~~~~~~~~~~~~~~
1. `/proc/interrupts 的数值是如何获得的？ – 肥叉烧 feichashao.com  <https://feichashao.com/proc-interrupts/>`__
cat /proc/interrupts

kernel/irq/proc.c show_interrupts 调用 irq_to_desc() 获取中断的信息，并打印每个 CPU 对应的统计数量 kstat_irqs_cpu().
然后调用 arch_show_interrupts()，打印架构相关的中断信息。比如 MNI, TLB 等统计信息。

irq domain 内部维护了一个 hwirq,可能会显示在 触发方式(Edge/Level)的前一列。

