

ftrace
============

Reference
-----------

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

