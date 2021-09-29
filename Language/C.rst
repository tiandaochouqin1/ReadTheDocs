====================
C
====================

:Date:   2021-09-09 00:37:13

1. `用C语言实现面向对象编程OOP <https://mp.weixin.qq.com/s/Vj31M2q0H5eeJwMhvDyt6A>`__
2. `C语言实现面向对象的原理 <https://mp.weixin.qq.com/s/b9IXQ8Hbh-8ejmU010sWiA>`__

参考链接
==========
1. 在线gdb：https://www.onlinegdb.com/myfiles
2. 在线汇编：https://godbolt.org/

优秀项目学习
=================

cjson
--------
待总结。


cmockery
------------
https://github.com/google/cmockery

待学习。

mockcpp
--------

ahttpd
--------
https://sqlite.org/althttpd/doc/trunk/althttpd.md


gcov
-----
1. `GCC Coverage代码分析 <https://blog.csdn.net/livelylittlefish/category_826830.html>`__
2. `gcov代码覆盖率测试-原理和实践总结 <https://blog.csdn.net/yanxiangyfg/article/details/80989680>`__
3. https://github.com/yanxiangyfg/gcov 与上个文章中汇编不一样，因为是32位系统？





汇编伪指令
~~~~~~~~~~~~~~~~
gcc生成的汇编文件中，供编译器使用。不出现在在最终可执行程序。

1. https://sourceware.org/binutils/docs/as/Pseudo-Ops.html 或https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_chapter/as_7.html


开启gcov
~~~~~~~~~~~
在源码编译参数中加入-fprofile-arcs -ftest-coverage

* -ftest-coverage：在编译的时候产生.gcno文件，它包含了重建基本块图和相应的块的源码的行号的信息。
* -fprofile-arcs：在运行编译过的程序的时候，会产生.gcda文件，它包含了弧跳变的次数等信息。

生成gcda
~~~~~~~~~~~
程序exit时调用 exit handlers ( __gcov_exit() -> __gcov_flush() ) ，将覆盖率数据写到gcda。

生成报告
~~~~~~~~~~

$ lcov -c -d . -o helloworld_gcov.info
$ genhtml -o 111 helloworld_gcov.info


覆盖率统计原理
~~~~~~~~~~~~~~~~~~~
用 基本块BB 和 跳转ARC 计数，结合程序流图来实现代码覆盖率统计

1. 基本块BB：BB为执行次数相同的一段代码，一般为 多个顺序语句+跳转语句组成，有条件的跳转则会产生分支。

2. ARC：从一个BB到另一个BB的跳转。

3. 程序流图：BB为节点，ARC即弧/有向边。只需要知道部分BB和ARC的执行次数，即可推断出所有语句和分支的执行次数。


.. figure:: ../images/gcov_arc_bb.png

    gcov程序流图

.. figure:: ../images/gcov_stub.png

    gcov汇编插桩
