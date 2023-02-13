
====================
CoolShell
====================

:Date:   2022-01-01 00:03:05


CoolShell
===========


技术与技术领导力
------------------
1. 动手能力
2. 提升效率
3. 输出观点。写好文档和文章。
4. 不断提高对自己的要求标准
5. 赢得他人的信任
6. 保持热情和冲劲

SRE能力自评
~~~~~~~~~~~~
Google评分卡的来自Google的SRE。为了保证稳定可靠的服务，Google组建了一支专业的团队来负责运行后端服务——Site Reliability Engineer。

《Google SRE: How Google runs production systems》

0. you are unfamiliar with the subject area.

1. you can read/understand the most fundamental aspects of the subject area.

2. ability to implement small changes,understand basic principles and able to figure out additional details with minimal help.

3. basic proficiency in a subject area without relying on help.

4. you are comfortable with the subject area and all routine work on it.

   For software areas - ability to develop medium programs using all basic language features w/o book, awareness of more esoteric features (with book).
   
   For systems areas - understanding of many fundamentals of networking and systems administration, ability to run a small network of systems including recovery, debugging and nontrivial troubleshooting that relies on the knowledge of internals.

5. an even lower degree of reliance on reference materials. Deeper skills in a field or specific technology in the subject area.

6. ability to develop large programs and systems from scratch. Understanding of low level details and internals. Ability to design/deploy most large, distributed systems from scratch.

7. you understand and make use of most lesser known language features, technologies, and associated internals. Ability to automate significant amounts of systems administration.

8. deep understanding of corner cases, esoteric features, protocols and systems including "theory of operation". Demonstrated ability to design, deploy and own very critical or large infrastructure, build accompanying automation.

9. could have written the book about the subject area but didn't; works with standards committees on defining new standards and methodologies.

10. wrote the book on the subject area (there actually has to be a book). Recognized industry expert in the field, might have invented it.

Subject Areas:
^^^^^^^^^^^^^^^^
::
      
   TCP/IP Networking (OSI stack, DNS etc)
   Unix/Linux internals
   Unix/Linux Systems administration
   Algorithms and Data Structures
   C
   C++
   Python
   Java
   Perl
   Go
   Shell Scripting (sh, Bash, ksh, csh)
   SQL and/or Database Admin
   Scripting language of your choice (not already mentioned)
   People Management
   Project Management


基础知识分类
~~~~~~~~~~~~~
1. 程序语言：语言的原理，类库的实现，编程技术（并发、异步等），编程范式，设计模式……
2. 系统原理：计算机系统，操作系统，网络协议，数据库原理……
3. 中间件：消息队列，缓存系统，网关代理，调度系统 ……
4. 理论知识：算法和数据结构，数据库范式，网络七层模型，分布式系统……

总是在提供解决问题的思路和方案的人

做正确的事，比用正确的方式做事更重要，因为这样才始终会向目的地靠拢。

写文章的几个阶段
~~~~~~~~~~~~~~~~~~~~
1. 学习记录
2. 利益驱动
3. 记录自己的观点
4. 与他人交互

时间管理
~~~~~~~~~~~~
1. 主动管理时间，不被打扰
2. 说 不 的三种方式：给出新方案、部分满足、有条件地说是
3. 想清楚再做，每周/月反思

错误处理与异步
--------------
1. 错误返回码与异常捕捉的使用
2. 异步编程比较

分布式系统关键技术
~~~~~~~~~~~~~~~~~~~~~
.. figure:: /images/distributed_system_stack.png

   distributed_system_stack



1. 全栈监控：数据收集以及数据的关联
2. 服务治理：服务依赖问题、服务状态维持与拟合、服务的弹性伸缩与故障迁移、工作流和编排
3. 流量调度和状态数据调度

CAP 定理: 一致性、可用性、分区容忍

《数据密集型应用设计》：Designing Data Intensive Applications


编程范式
------------

编程语言本质上帮助程序员屏蔽底层机器代码的实现，而让我们可以更为关注于业务逻辑代码。

阅读资料：七周七语言、斯坦福大学的编程范式公开课



.. figure:: /images/Programming_paradigm_a.png
   :scale: 40%

   Programming_paradigm_a



.. figure:: /images/Programming_paradigm_b.png

   Programming_paradigm_b


泛型编程
~~~~~~~~~~
屏蔽掉数据和操作数据的细节，让算法更为通用，让编程者更多地关注算法的结构，而不是在算法中处理不同的数据类型。


1. 静态类型检查：强类型、弱类型
2. 动态类型检查：运行时typeof、is_arry

类型：

1. 类型是对内存的一种抽象。不同的类型，会有不同的内存布局和内存分配的策略。
2. 不同的类型，有不同的操作。所以，对于特定的类型，也有特定的一组操作。

要做到泛型需要做下面的事情。

1. 标准化掉类型的内存分配、释放和访问。
2. 标准化掉类型的操作。比如：比较操作，I/O 操作，复制操作……
3. 标准化掉数据容器的操作。比如：查找算法、过滤算法、聚合算法……
4. 标准化掉类型上特有的操作。需要有标准化的接口来回调不同类型的具体操作……

对应的C++的泛型实现：

1. 类的构造析构
2. 运算符重载
3. 模板生成特定数据类型的代码
4. 虚函数和运行时识别技术

`运行时类型识别 - 腾讯云开发者社区-腾讯云  <https://cloud.tencent.com/developer/article/1718803>`__

函数式编程
~~~~~~~~~~~~~~~
把一些功能或逻辑代码通过函数拼装方式组织起来。

1. map、reduce、filter，pipeline,柯里化，头等函数，尾递归优化。如 使用 Map & Reduce，不要使用循环
2. 无状态、不可变、惰性求值
3. 只关心定义输入数据和输出数据相关的关系
4. 关注的是做什么而不是怎么做，因而被称为声明式编程

decorator 
~~~~~~~~~~~~~~
用一个函数来构造另一个函数。

可实现普通函数管道化

面向对象编程
~~~~~~~~~~~~~
1. 桥接模式：类的拼装
2. 策略模式：分离出策略
3. 代理模式：RAII，
4. 接口编程与依赖倒置

原型编程
~~~~~~~~~
1. 没有class化，直接使用对象。
2. 使用委托指针来了链接原型。
3. 通过复制已有的对象或者通过扩展空对象创建对象

委托模式
~~~~~~~~~~~~~
类似面向对象和原型编程的综合

逻辑编程
~~~~~~~~~~~~
逻辑编程，把业务逻辑或是说算法抽象成只关心规则、事实和问题的推导这样的标准方式，
不需要关心程序控制，也不需要关心具体的实现算法。

编程的本质
~~~~~~~~~~~~~

``Program = Logic + Control + Data Structure``

control和logic耦合导致程序复杂混乱。


.. figure:: /images/logic_control.png

   logic_control



练级攻略
-----------
Linux系统、存储、网络

1. `HTTP | MDN  <https://developer.mozilla.org/zh-CN/docs/Web/HTTP>`__   
2. `How To Ask Questions The Smart Way  <http://www.catb.org/~esr/faqs/smart-questions.html>`__
3. `The C10K problem  <http://www.kegel.com/c10k.html>`__ 、  `The Secret to 10 Million Concurrent Connections -The Kernel is the Problem, Not the Solution - High Scalability -  <http://highscalability.com/blog/2013/5/13/the-secret-to-10-million-concurrent-connections-the-kernel-i.html>`__
4. `Hardening Your HTTP Security Headers - KeyCDN  <https://www.keycdn.com/blog/http-security-headers>`__
5. `TCP 的那些事儿（上） | 酷 壳 - CoolShell  <https://coolshell.cn/articles/11564.html>`__
6. `Let's code a TCP/IP stack, 1: Ethernet & ARP  <http://www.saminiir.com/lets-code-tcp-ip-stack-1-ethernet-arp/>`__
7. `What every programmer should know about memory, Part 1 [LWN.net]  <https://lwn.net/Articles/250967/>`__

高效沟通
-----------
好的沟通方式：

1. 尊重对方是赢得对方尊重的前提，一定要有观点的交互与碰撞，而不是只有附和；
2. 倾听，掌握更多信息，关注对方的利益点；
3. 情绪控制，慎用打岔与反驳，求同存异

沟通技巧：

1. 引起对方的兴趣，即对方的关注点
2. 直达主题，强化观点。换位思考，反复提炼浓缩要表达的信息
3. 用数据和事实说话。尽量少说 “可能、也许、我觉得就这样”

沟通技术：

1. 避免X/Y问题
2. 在高纬度拉拢/共同点，低纬度说服/反驳。
3. 共享、共利、共情

- 善于提问：引导的方式提问、问题反馈机制
- 赢得老板的信任——带来成绩
- 管理老板的期望-有条件地说是
