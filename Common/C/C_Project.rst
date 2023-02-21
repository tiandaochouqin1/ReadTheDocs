
优秀项目学习
=================

cjson
--------
待总结。

coreutils
-----------
1. `Decoded: GNU coreutils – MaiZure's Projects  <http://www.maizure.org/projects/decoded-gnu-coreutils/index.html>`__

This resource is for novice programmers exploring the design of command-line utilities.

ahttpd
--------
https://sqlite.org/althttpd/doc/trunk/althttpd.md

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
