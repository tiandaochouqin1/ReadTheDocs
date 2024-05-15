
==============
cache原理
==============
`Cache的基本原理 - 知乎  <https://zhuanlan.zhihu.com/p/102293437>`__

直接映射/组相联/全相联缓存


**cache组相联是为了解决cache颠簸。**

cache的查找过程
====================

先使用index/set找到对应的一个或多个cache条目，然后比较tag是否一致(这一步通常是tcam实现)，若一致则使用offset拿到具体地址的值。

512 Bytes cache size，64 Bytes cache line size。

地址划分方法：offset、index和tag分别使用6 bits、3 bits和39 bits。如下图所示。

.. figure:: /images/cache_direct_mapped_cache.png
   :scale: 90%

   cache_direct_mapped_cache

   
.. figure:: /images/cache_2way_set_assosiative_cache.png
   :scale: 100%

   cache_2way_set_assosiative_cache

   
.. figure:: /images/cache_4way_set_assosiative_cache.png
   :scale: 100%

   cache_4way_set_assosiative_cache


cache分配与更新策略
====================

cache更新策略
----------------------


1. 写直通：cache和memory数据始终保持一致。
2. 写回：cacheline中数据被修改时置D，只有被置换或clean时才写到memory。

cache分配策略
----------------------


1. 读分配:cpu读miss时分配cacheline，默认情况下，cache都支持读分配。
2. 写分配：cpu写cache缺失时，若不支持写分配则直接更新到memory，否则要先从memory中加载到cacheline再更新cache。


cache的性能陷阱
====================

cache乒乓
------------

多线程并行运行在不同cpu上，频繁修改同一个变量，变量被修改后会置另一个线程cpu上变量对应的cache为无效(cache一致性)，
这使得维护cache和从内存读取的开销占了主导（当然也未利用到cache的优势）。

.. figure:: /images/cache_pingpong.png
   :scale: 70%

   cache_pingpong


伪共享
--------
多线程修改的不同变量，但变量处于同一cacheline内(如64B)时也会导致相同的pingpong问题。

可以通过调整变量顺序或填充数据来使得变量不处于同一个cacheline。

