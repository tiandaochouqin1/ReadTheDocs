
syslog & printk
====================

`内核printk原理介绍 - 知乎  <https://zhuanlan.zhihu.com/p/521094976?utm_id=0>`__

核心是一个叫做log buffer的循环缓冲区，printk作为生产者将消息存入该缓冲区，右边的log服务模块作为消费者可从log buffer中读取消息。

.. figure:: /images/printk_frame.png
   :scale: 60%

   printk_frame


log buffer的实现
-------------------
TODO


syslog
----------------
`内核日志及printk结构分析 <https://www.cnblogs.com/aaronLinux/p/6843131.html>`__

1. /proc/sys/kern/printk_ratelimit :监测周期，在这个周期内只能发出下面的控制量的信息).
2. /proc/sys/kernel/printk_ratelimit_burst :周期内的最大消息数.


printk
---------
1. 效率很低：做字符拷贝时一次只拷贝一个字节，且去 **调用console输出可能还产生中断**。
2. ring buffer只有1K。

dmesg时间戳
~~~~~~~~~~~~
dmesg时间为系统启动的时间Δ。

1. `[转载]date命令时间转换 - 苏小北1024 - 博客园  <https://www.cnblogs.com/muahao/p/6098675.html>`__

::
      
   date -d @12345  //即 date -d "1970-01-01 UTC 12345 seconds"


   dmesg log实际时间=格林威治1970-01-01+(date当前时间秒数 - uptime系统启动至今的秒数 + dmesg打印的log时间)

   date -d "1970-01-01 UTC `echo "$(date +%s)-$(cat /proc/uptime|cut -f 1 -d' ')+12288812.926194"|bc ` seconds"



printk等级
~~~~~~~~~~~~
1. `Message logging with printk — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/core-api/printk-basics.html>`__

1. All printk() messages are printed to the kernel log buffer, which is a ring buffer exported to userspace through /dev/kmsg。
2. printk的打印等级只是控制是否输出到console。 **message loglevel <= console_loglevel** 则输出到console。可增大console_loglevel来查看更多打印。
3. 4.9版本开始，printk默认会换行。不换行需使用pr_cont(KERN_CONT)。 `Message logging with printk — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/core-api/printk-basics.html>`__

**console level** 查看：

::
      
   You can check the current console_loglevel with:

   $ cat /proc/sys/kernel/printk
   4        4        1        7
   current, default, minimum and boot-time-default log levels.


boot(内核启动)可指定loglevel值、quiet(loglevel=4)。 https://www.kernel.org/doc/html/v4.14/admin-guide/kernel-parameters.html




printk源码
--------------
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
------------
call_console_drivers调用时也会 **关中断**。

::
        
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


