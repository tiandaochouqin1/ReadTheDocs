2024 Arm技术峰会
====================================

实际为arm ai计算技术峰会，覆盖了从硬件、软件、生态三个方面。去年的主题更偏重安全。



大模型面临的挑战（老生常谈）： 偏见、错误信息、数据安全、环保（一次问答所需电力是一次google的100倍）

arm ai硬件
~~~~~~~~~~~~~~
着重介绍了arm v9(N3、x925)的性能提升和AI特性。

凭借着节能与灵活的特性，arm似乎已经把intel甩在了后面。

从armv6开始，就开始不断添加能够加速矢量、矩阵计算的指令集，包括： NEO、bf16、SVE/2、SME

`【ARMv8/ARMv9 硬件加速系列 1 -- SVE | NEON | SIMD | VFP | MVE | MPE 基础介绍】_arm sve-CSDN博客  <https://blog.csdn.net/sinat_32960911/article/details/139662623>`__


1. NEON：是ARM上使用的一种SIMD（Single Instruction Multiple Data – 单指令多数据）指令集。可实现64位/128位的并行计算。简单理解就是一个计算指令，可以指定4个Float和4个Float并行计算（也可以是其他数据类型，但是必须包含在64位/128位内），得到4个Float结果。而不是一次只能一个Float和一个Float的计算。
2. BFloat:进行神经网络计算时，bfloat16格式与FP32一样准确，但是以一半的位数完成任务。因此，与32位相比，采用bfloat16吞吐量可以翻倍，内存需求可以减半。
3. SVE/2:继固定 128 位向量长度指令集的 Neon 架构扩展之后，SVE 引入可伸缩概念，允许灵活的向量长度实现，向量长度可以从最小 128 位到最大 2048 位不等
4. SME:可伸缩矩阵扩展,基建立在SVE2的基础上，新增了对矩阵tile的高效存取、向量插入提取以及矩阵转置等功能。

SME 引入了两个关键的新架构特性：Streaming SVE 模式和 ZA 存储。Streaming SVE 模式是一种高吞吐量的矩阵数据处理模式，ZA 存储则是一种专用的二维数组，可以方便地进行常见的矩阵操作。这些特性使 SME 和 SME2 能够高效地处理矩阵和基于向量的工作负载。


这些硬件指令模块是如何实现推理加速的？
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



`Scalable Matrix Extension for the Armv9-A Architecture - Architectures and Processors blog - Arm Community blogs - Arm Community  <https://community.arm.com/arm-community-blogs/b/architectures-and-processors-blog/posts/scalable-matrix-extension-armv9-a-architecture>`__

提高乘法与加载的比率（减少访存，提高吞吐量），以两个2为矩阵乘法为例：

- 简单的实现是三重嵌套循环算法，一次计算一个结果块，乘法与加载比率达到 1:2，即每加载两个元素进行 1 次乘法。
- 一次计算4个结果块（2*2），乘法与加载比率提高到 1:1
- SME：可以计算矩阵的外积并增加内部ZA存储，利用外积来进一步发挥了每次加载生成多个结果的理念。乘法与负载的比率取决于实现的宽度。例如，具有 32 位数据的 512 位向量实现将产生 256:2 的乘法与向量负载比率。


arm ai软件
~~~~~~~~~~~~~~


Kleidi
^^^^^^^^
包括KleidiAI和KleidiCV,CV没怎提及。


.. figure:: /images/arm_symposia_kleidi.jpg


   arm_symposia_kleidi.jpg


kleidi平台可将llm推理性能提升大于10倍。
`LLM Inference Demo with PyTorch on Arm Neoverse V2 - Infrastructure Solutions blog - Arm Community blogs - Arm Community  <https://community.arm.com/arm-community-blogs/b/infrastructure-solutions-blog/posts/llm-inference-demo-with-pytorch-on-arm-neoverse-v2>`__

一般用两个指标来衡量推理性能：首token时间和后续token生成速度。

大致的数据印象，一块GPU的生成速度已经达到1W+ token/s，而arm基于cpu（好像是多核N1）的生成速度在20-50 token/s。 差距挺大，但是也能满足人的阅读速度。

ARM CSS(Compute Subsystems)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
1. `Neoverse Compute Subsystems (CSS): Fast-Track to Production – Arm®  <https://www.arm.com/products/neoverse-compute-subsystems>`__

一个芯片设计、验证、性能优化的计算子系统。




生态
--------
arm邀请了vivo手机、广汽集团、中兴微电子做专门的报告，同时展台也有许多行业供应商。


移动设备
~~~~~~~~~~~
Ai on device Vs on Cloud。

arm坐拥大量的终端设备，想要在边缘终端发力AI（大会没有提及他们的GPU）。




手机总是能应用到arm最新的特性，但是目前AI在手机并没有找到突破点。

vivo在手机上应用ai的愿景/想象：聊天框复制-切换app(如地图)-粘贴搜索-选择然后打开；简化为一次点击即可获取想要的内容。


边缘设备AI的优劣
^^^^^^^^^^^^^^^^^^^^^

1. 数据安全，数据不用传输到云端；
2. 随手可得，使用门槛低
3. 延时低，无网络延时
4. 成本低

边缘设备AI的限制：成本(限制硬件规格)、功耗、ddr带宽、App大小等限制


AI for Game
~~~~~~~~~~~~~~~~~
1. 内容创造，即美工
2. 玩法增强，即ai npc
3. 更逼真的画面：如AI插帧、AI超分辨率、AI 光追。