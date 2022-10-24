=====================
Clean Architecture
=====================

:Date:   2022-07-02 14:39:00


:download:`Clean Architecture <../files/Clean Architecture_ A Craftsman’s Guide to Software Structure and Design.PDF>`


概述与编程范式
=========================

1. 结构化编程：限制程序控制权的直接转移。goto -> 顺序/分支/循环结构。 功能性拆解。
2. 面向对象编程：限制程序控制权的间接转移。函数指针 -> 多态。控制源代码的依赖关系，不受系统控制流的限制。
3. 函数式编程：限制程序中的赋值操作，变量不可变。分离可变组件和不可变组件。




设计原则
===========
1. `SOLID: The First 5 Principles of Object Oriented Design | DigitalOcean  <https://www.digitalocean.com/community/conceptual_articles/s-o-l-i-d-the-first-five-principles-of-object-oriented-design#interface-segregation-principle>`__

SOLID原则紧贴在代码层级以上，帮助定义模块和组件中使用的软件结构种类。

软件构建"中层"结构的目标： 可改动、易理解、可复用。

SRP
--------------
A module should be responsible to one, and only one, actor.

讨论的是函数和类之间的关系，将服务不同actor的代码切分。

以两种不同的形式出现：

- 组件层面：CCP共同闭包原则
- 软件架构层面：奠定架构边界的变更轴心。


OCP
----------
开闭原则：A software artifact should be open for extension but closed for modification.

是进行架构设计的 **主导原则**。

将组件间的依赖关系按照层次结构进行组织，让系统易于扩展，同时限制每次被修改的影响范围。

LSP
----------
可替换性。

::

    S o1
    T o2
    P 可操作T
    
    若o2(T)替换o1(S)时,P行为保持不变，则S为T的子类型


1. 指导如何使用继承关系
2. 更广泛的、指导接口与其实现方式的设计原则。