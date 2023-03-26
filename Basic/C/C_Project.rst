
优秀项目学习
=================
动手项目
----------
`小白自制Linux开发板(F1C200s)整理系列，持续更新中 / 全志 SOC / WhyCan Forum(哇酷开发者社区)  <https://whycan.com/t_7275.html>`__

`小白自制Linux开发板 一. 瞎抄原理图与乱画PCB - 淡墨青云 - 博客园  <https://www.cnblogs.com/twzy/p/14714651.html>`__

`My Business Card Runs Linux • &> /dev/null  <https://www.thirtythreeforty.net/posts/2019/12/my-business-card-runs-linux/>`__

`自制超迷你的Linux卡片电脑_哔哩哔哩_bilibili  <https://www.bilibili.com/video/av65365123/?vd_source=9d49fa1e041dad3abcfb9134ffc49432>`__


todo
-----------

coreutils
~~~~~~~~~~~~~~~~~
1. `Decoded: GNU coreutils – MaiZure's Projects  <http://www.maizure.org/projects/decoded-gnu-coreutils/index.html>`__

This resource is for novice programmers exploring the design of command-line utilities.

ahttpd
~~~~~~~~~~~~
https://sqlite.org/althttpd/doc/trunk/althttpd.md

EasyLogger
~~~~~~~~~~~~~
`armink/EasyLogger: An ultra-lightweight(ROM<1.6K, RAM<0.3k), high-performance C/C++ log library. | 一款超轻量级(ROM<1.6K, RAM<0.3k)、高性能的 C/C++ 日志库  <https://github.com/armink/EasyLogger>`__


编译器
----------
1. `编译原理一：想初步了解编译原理？看这篇文章就够了 - 掘金  <https://juejin.cn/post/6938703901449256997>`__
2. `Create Your Own Compiler - Caught in the Web  <https://citw.dev/tutorial/create-your-own-compiler?p=1>`__

步骤：

1. 词法分析：扫描字符串，识别单词/关键字,得到token序列；
2. 语法分析：从token序列识别出各类短语，构造语法分析树(描述句子的语法结构);
3. 语义分析：收集标识符的各类属性(类型、作用域、值、参数等),语义检查(变量声明、操作符与操作数类型检查等);
4. 中间代码生成：通常和语义分析一起实现。对语法分析识别出的各类语法范畴，分析其含义，进行初步翻译。如三地址码、语法书、逆波兰式；
5. 代码优化：等价变换。包括公共子表达式提取、合并已知量、循环优化、删除无用语句；
6. 目标代码生成：分配寄存器，输出目标代码(绝对指令代码、可重定位指令代码、汇编指令代码);

编译器可识别语法、语义错误并报告。多遍扫描可节省内存空间、提高代码质量。


.. figure:: /images/Compiler.jpg
   :scale: 35%




busybox
-----------
1. `向busybox中添加自己的applet - ArnoldLu - 博客园  <https://www.cnblogs.com/arnoldlu/p/10905698.html>`__

applet_name
~~~~~~~~~~~~~~~
busybox内的工具均软链接到同一个busybox程序。

1. main()函数使用argv[0] (软链接名)作为参数在applets[]数组中查找合适的指向APPLET_main()函数的函数指针。
2. applet的执行路径，busybox的入口函数mian()根据传入的applet_name，然后通过find_applet_by_name()找到对应序号，然后执行applet_main[]函数。

applet如何添加
~~~~~~~~~~~~~~~~~
.c中的特殊注释config/applet/kbuild/usage，分别生成到miscutils/Config.in、include/applets.h、miscutils/Kbuild、include/usage.h四个文件中。

::

    //config:config MONITOR-----------------------------------------------------Config.src会读取下面内容写入到Config.in中，用于配置monitor功能。
    //config:    bool "monitor"
    //config:    default n
    //config:    select PLATFORM_LINUX
    //config:    help
    //config:      Monitor will collect system exception, daemon corruption, critical app exit. 

    //applet:IF_MONITOR(APPLET(monitor, BB_DIR_SBIN, BB_SUID_DROP))--------------此句会写入include/applets.h中，等于是声明了monitor_main()函数。

    //kbuild:lib-$(CONFIG_MONITOR) += monitor.o----------------------------------经由Kbuild.src生成写入到Kbuild中，是对是否编译monitor.c的控制。

    //usage:#define monitor_trivial_usage----------------------------------------写入到include/usage.h中，是monitor的帮助信息。
    //usage:       "[-q] [-o OFF] [-f FREQ] [-p TCONST] [-t TICK]"
    //usage:#define monitor_full_usage "\n\n"
    //usage:       "Monitor system or app exception.\n"
    //usage:     "\n    -q    Quiet"

    #include "libbb.h"
    #include <syslog.h>
    #include <sys/un.h>


sshfs
---------
1. `Releases · libfuse/sshfs` <https://github.com/libfuse/sshfs/releases>`__  sshfs已于202205停止维护。 


编译：<=3.20使用autotool,后续使用meson。依赖libfuse3。

性能
~~~~~~~~
1. `NAS Performance: NFS vs. SMB vs. SSHFS | Jake’s Blog` <https://blog.ja-ke.tech/2019/08/27/nas-performance-sshfs-nfs-smb.html>`__

sshfs基于ssh，默认aes加密。

1. mixed read sshfs比nfs(plain)差38%；mixed write sshfs差11%;
2. mixed read/write sshfs 比 nfs(aes)稍强;
