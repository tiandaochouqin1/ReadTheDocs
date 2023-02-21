
时间子系统 
============
1. 这个系列非常好！ `Linux时间子系统之（二）：软件架构 <http://www.wowotech.net/timer_subsystem/time-subsyste-architecture.html>`__
2. `Linux 时钟管理 <https://blog.csdn.net/johnson4303/article/details/7664182>`__
3. `Linux 时间系统分析 <https://www.binss.me/blog/linux-time-system-analysis/>`__
4. `An overview on hardware clock and system timer circuits <https://access.redhat.com/solutions/18627>`__
5. `Linux时间子系统之一：clock source（时钟源）_DroidPhone的博客-CSDN博客_clock source` <https://blog.csdn.net/DroidPhone/article/details/7975694>`__


概念：

1. clocksource: 查看当前时间。x86基本都是tsc。
2. clockevents: 定时器，在特定时间点触发事件。hpet、pic、apci_pm都有，这几个精度差别在一个数量级内。

查看clocksource和clockevents:

::

   cat /sys/devices/system/clocksource/clocksource0/current_clocksource
   cat /sys/devices/system/clockevents/broadcast/current_device


clocksource和clockevents
------------------------------
::

                 低精度定时器(timer)
                             相互替代
   框架层        tick_device  <-----> 高精度定时器(hrtimer)         timekeeper

   抽象层        时钟事件设备(clock_event_device)                   时钟源(clocksource)

   硬件层        硬件定时器(pit、apic、hpet、acpi_pm)               时钟源(RTC、hpet、TSC)


