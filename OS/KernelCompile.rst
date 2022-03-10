==================
Kernel Compile
==================


下载源码
============

方法：

1. 下载release包；
2. 下载Git。

::

   git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
   镜像
   git clone git clone https://mirrors.tuna.tsinghua.edu.cn/git/linux-stable.git

   在windows中有兼容性问题（aux文件在win中为设备文件）。
   git config core.protectNTFS false
   git rm --cache aux.c/h


3. 切换版本
   
::
   
   git tag
   git checkout V5.0


内核编译与更换
====================
Kbuild+Makefile

编译选项通常有三个：Yes/No/Module。Module代表以模块的形式独立生成。

发布版：Ubuntu、Federo等发布版包含了预编译的内核，已启用了所需的功能，而驱动程序一般都是模块。

编译内核并安装
----------------
尽量别在虚拟机编，虚拟机空间清理麻烦。可以试用github action编译。

https://www.linuxprobe.com/linux-kernel-compilation.html

1. 安装依赖
   
   - sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison

2. 配置config。 使用当前内核config
   
   - cp /boot/config-$(uname -r) .config

   - make menuconfig //配置.config


3. 编译内核与模块
   
   - make clean       清空一些编译信息

   - make -j4 >> make.log

   此时make指令分别执行：make bzImage 和 make modules。
   
   会生成生成相应内核版本的内核模块和vmlinuz，initrd.img，Symtem.map文件。

4. 安装
   
   - make modules_install //安装启用的模块。在/lib/modules/目录下生成对应版本的内核模块。

   - sudo make install //安装内核。这一步已经更新引导！！ 把System.map, vmlinux，config，initrd.img文件拷贝到/boot/目录下。


5. reboot


::

   make[1]: *** No rule to make target 'debian/canonical-certs.pem',
    needed by 'certs/x509_certificate_list'.  Stop.
   Makefile:1821: recipe for target 'certs' failed
   make: *** [certs] Error 2

   需要设置 CONFIG_SYSTEM_TRUSTED_KEYS="" 为空字符


config
~~~~~~~~~~
内核配置好后，配置项存放在源代码内核源码根目录的 .config 文件中，

可以直接修改该文件，修改后应该更新用 $ make oldconfig 更新配置


menuconfig通过调用各级目录下Kconfig文件来形成图形界面的

下载内核并安装
------------------

此方法占用空间少，image+modules在1G以内，而自己编译的内核modules大小高达7G（未进行精简，其中大部分为driver）。


1. 选择版本5.5.0，并下载三个包 https://kernel.ubuntu.com/~kernel-ppa/mainline/

::

   wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.5/linux-headers-5.
   5.0-050500_5.5.0-050500.202001262030_all.deb

   wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.5/linux-headers-5.
   5.0-050500-generic_5.5.0-050500.202001262030_amd64.deb

   wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.5/linux-image-unsigned-5.5.0-050500-generic_5.5.0-050500.202001262030_amd64.deb
   wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.5/linux-modules-5.5.0-050500-generic_5.5.0-050500.202001262030_amd64.deb

2. ``sudo dpkg -i *.deb``

3. reboot

5.5.0可正常安装，5.12.14安装headers报错。没找到解决办法，貌似不影响系统工作？

::

   Errors were encountered while processing:
   linux-headers-5.12.14-051214-generic


引导grub
-----------------
1. 查看现有引导： 
   
   - grep menuentry /boot/grub/grub.cfg

2. 更改引导。
   
   - sudo vi /etc/default/grub
   - GRUB_DEFAULT="" //必须加双引号

3. 目录引导：
   
   内核增删后，序号会变！！

   序号是按照grub菜单目标编号的。有两层目录，均以0开始。首层0为默认第一个menuentry。

   支持以下三种方法：
   

   1. GRUB_DEFAULT="1>8" //其中编号4是步骤1中的menuentry顺序。

   2. GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 5.4.0-72-generic"
   
   3. GRUB_DEFAULT="gnulinux-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c>gnulinux-5.4.0-72-generic-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c"

4. sudo update-grub ，检查并更新grub。注意查看命令结果。如

::

   Warning: Please don't use old title `Ubuntu, with Linux 5.4.0-72-generic' for GRUB_DEFAULT,
   use `Advanced options for Ubuntu>Ubuntu, with Linux 5.4.0-72-generic' (for versions before 2.00) 
   or `gnulinux-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c>gnulinux-5.4.0-72-generic-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' (for 2.00 or later)

开启grub菜单显示
~~~~~~~~~~~~~~~~~~~~~~~~~~
grub菜单的顺序即为menuentry的顺序。

#GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=5

GRUB_DEFAULT
~~~~~~~~~~~~~~~~~~~~
`Gnu grub config <https://www.gnu.org/software/grub/manual/grub/html_node/Simple-configuration.html>`__

::

   ‘GRUB_DEFAULT’
   The default menu entry. This may be a number, 
   in which case it identifies the Nth entry in the generated menu counted from zero, 
   or the title of a menu entry

menuentry
~~~~~~~~~~~~~~~~~~~~~
`grub架构解析 <https://hugh712.gitbooks.io/grub/content/configuration-parameters.html?q=#GRUB_DEFAULT>`__

::

   ~$ grep menuentry /boot/grub/grub.cfg
   if [ x"${feature_menuentry_id}" = xy ]; then
   menuentry_id_option="--id"
   menuentry_id_option=""
   export menuentry_id_option
   menuentry 'Ubuntu' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
   submenu 'Advanced options for Ubuntu' $menuentry_id_option 'gnulinux-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
      menuentry 'Ubuntu, with Linux 5.12.14-051214-generic' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.12.14-051214-generic-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
      menuentry 'Ubuntu, with Linux 5.12.14-051214-generic (recovery mode)' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.12.14-051214-generic-recovery-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
      menuentry 'Ubuntu, with Linux 5.10.31' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.10.31-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
      menuentry 'Ubuntu, with Linux 5.10.31 (recovery mode)' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.10.31-recovery-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
      menuentry 'Ubuntu, with Linux 5.5.0-050500-generic' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.5.0-050500-generic-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
      menuentry 'Ubuntu, with Linux 5.5.0-050500-generic (recovery mode)' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.5.0-050500-generic-recovery-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
      menuentry 'Ubuntu, with Linux 5.4.0-77-generic' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.4.0-77-generic-advanced-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
      menuentry 'Ubuntu, with Linux 5.4.0-77-generic (recovery mode)' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.4.0-77-generic-recovery-51c0823c-4ec6-4ce0-bdb7-a041e23f430c' {
   menuentry 'Memory test (memtest86+)' {
   menuentry 'Memory test (memtest86+, serial console 115200)' {


卸载内核
-------------------

`内核卸载与禁止更新 <https://www.cnblogs.com/youpeng/p/11219485.html>`__

查看已安装内核，自己编译安装的内核不会显示出来：

::

   dpkg --get-selections | grep linux-image

   sudo apt purge linux-image-3.19.0-15

   sudo apt purge linux-headers-3.19.0-15


模块编译与安装
==============



1. 源码树内部编译：
   
   1. 增加文件夹，在kconfig中添加编译选项
   2。 按照编译选项编写makefile

2. 在源码树外部编译：（OSC中的Lab，在ubuntu18中会提示insmod签名问题）

   :download:`kernel_module.c <../files/code/kernel_module.c>`


   需要自己写makefile。本机内核模块目录 ``/lib/modules/$(uname -r)/build``，避免在修改模块的源代码时重新编译整个内核。

::

   obj-m := hello_module.o
   ​
   KERNELBUILD := /lib/modules/$(uname -r)/build
   CURRENT_PATH := $(pwd)
   ​
   all:
       make -C $(KERNELBUILD) M=$(CURRENT_PATH) modules
   ​
   clean:
           make -C $(KERNELBUILD) M=$(CURRENT_PATH) clean


模块安装：``sudo insmod mod.ko``
dmesg : 查看内核日志缓冲区（包括printk的输出内容）。


交叉编译
==============

1. `ARM工具链选择参考 <https://www.cnblogs.com/arnoldlu/p/14243491.html>`__
2. `Cortex-A toolchain <https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads>`__


交叉编译工具链的命名规则
------------------------
``arch [-vendor] [-os] [-(gnu)eabi]``

1. arch - 体系架构。arm(armv7)、aarch64(armv8)。be为大端。
2. vendor - 工具链提供商。none。
3. os - 目标操作系统。linux(适用于Linux OS)。elf(bare-metal,裸机，无操作系统的硬件。
4. eabi - 嵌入式应用二进制接口（Embedded Application Binary Interface）。
   gnu(使用glibc)。hf( hard float,fpu计算并传参，性能好，中断负荷高)


配置工具链目录：

::

   export PATH=$PATH:/usr/local/arm/gcc-arm-none-eabi-10-2020-q4-major/bin
   export命令只对当前shell生效，可加入.bashrc中并source。


包管理器安装
------------------------
centos默认安装的为gcc-4.8

::

   //32bit and 64bit ARM :

   sudo apt-get install gcc-arm-linux-gnueabihf
   sudo apt-get install gcc-aarch64-linux-gnu

   //installed in /usr/bin 

   export CROSS_COMPILE=arm-linux-gnueabihf-

   export CROSS_COMPILE=aarch64-linux-gnu-

编译strace
-----------------
下载源码：https://github.com/strace/strace。 阅读 README-configure 编译配置指南。

`configure关于交叉编译的参数设置 <https://www.cnblogs.com/sky-heaven/p/8625248.html>`__

- 最新版本依赖较多（多依赖librt.so.1），编译时需要静态链接才能使用。动态链接编译的程序无法在环境上运行（？？）
- 老版本依赖较少（如v4.18），可使用。


configure
~~~~~~~~~~~~
::

   arm64，可在raspberry 4B运行。

   ./configure --host=aarch64-linux-gnu   CC=aarch64-linux-gnu-gcc LD=aarch64-linux-gnu-ld AR=aarch64-linux-gnu-ar
   strace v5.12版本需要加参数：--disable-mpers

   make 


安装
~~~~~~~~~~~~~
::

   make install
   make install -n  //只查看，不运行

   install -c -m 644 "$file" "$inst"    //等于 cp、strip、chown、chmod

注意事项
~~~~~~~~~~~~~~~~
1. 静态链接时，v5.12 CFLAGS参数需要加pthread 即：LDFLAGS='-static -pthread'
https://github.com/strace/strace/issues/67
   
2. arm-none-eabi不可用于编译linux程序，需使用arm-linux-eabi。

3. 工具链版本需要满足编译要求，不可太高或太低。可能有如下类似错误，使用gcc 7.5解决（gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu）。

::

   configure: error: C compiler cannot create executables



