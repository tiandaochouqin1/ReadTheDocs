=====
MySQL
=====

:Date:   2021-03-02 23:52:07

MySQL必知必会
=============

`MySQL必知必会-专栏配图 <https://github.com/cystanford/SQL-XMind>`__

关系型数据库（RDBMS）就是建立在关系模型基础上的数据库，SQL
就是关系型数据库的查询语言。

1. 关系型数据库：RDMMS，如MySQL，Oracle
2. 非关系型数据库（NOSQL）

   1. 文档型数据库：MongoDM，文档作为处理信息的基本单位。
   2. 搜索引擎：全文索引，倒排索引；
   3. 列式数据库：是相对于行式存储的数据库，可降低系统I/O；
   4. 图形数据库：利用了图这种数据结构存储了实体（对象）之间的关系

InnoDB，它是 MySQL5.5 版本之后默认的存储引擎。

MySQL指令执行过程
-----------------

.. figure:: /images/SQL_Process.png
   :alt: SQL_Process

   SQL_Process

1. 语法检查：检查 SQL 拼写是否正确。

2. 语义检查：检查 SQL 中的访问对象是否存在。

3. 权限检查：看用户是否具备访问该数据的权限。

4. 共享池检查：共享池（Shared Pool）是一块内存池，最主要的作用是缓存 SQL
   语句和该语句的执行计划。Oracle 通过检查共享池是否存在 SQL
   语句的执行计划，来判断进行软解析，还是硬解析。

   1. 在共享池中，Oracle 首先对 SQL 语句进行 Hash 运算，然后根据 Hash
      值在库缓存（Library Cache）中查找，如果存在 SQL
      语句的执行计划，就直接拿来执行，直接进入“执行器”的环节，这就是软解析。
   2. 如果没有找到 SQL 语句和执行计划，Oracle
      就需要创建解析树进行解析，生成执行计划，进入“优化器”这个步骤，这就是硬解析。

5. 优化器：优化器中就是要进行硬解析，也就是决定怎么做，比如创建解析树，生成执行计划。

6. 执行器：当有了解析树和执行计划之后，就知道了 SQL
   该怎么被执行，这样就可以在执行器中执行语句了。

.. figure:: /images/MySQL_CS.png
   :alt: MySQL_CS

   MySQL_CS

::

   show profiles; //查看所由命令的执行时间
   show profile for query 2; //查看命令执行时间，详细

   explain查看SELECT语句的执行计划

DDL数据定义语言
---------------

数据库定义： ``CREATE DATABASE,DROP DATABSE``

数据表定义： ``CREATE TABLE [table_name](),ALTER TABLE``

可视化管理和设计工具：Navicat、MySQL Workbench

约束：主键、外键、唯一性、NOT NULL、DEFAULT、CHECK

05丨检索数据：你还在SELECT \* 么？ TODO

MySQL Tutorial
==============

`Tutorail <https://dev.mysql.com/doc/refman/8.0/en/tutorial.html>`__

::

   登录
   mysql -h host -u user -p
   mysql -h host -u user -pPASSWORD

   权限
   GRANT ALL ON menagerie.* TO 'your_mysql_name'@'your_client_host';

   数据库操作
   CREATE DATABASE menagerie;
   SHOW DATABASES;
   SHOW DATABASE();//当前选中
   use DATABASES

   表操作
   CREATE TABLE pet (name VARCHAR(20), owner VARCHAR(20),species VARCHAR(20), sex CHAR(1), birth DATE, death DATE );
   SHOW CREATE TABLE pet;
   SHOW TABLES;
   DESCRIBE pet;

   加载文件书籍
   LOAD DATA LOCAL INFILE 'C:/Users/Administrator/Desktop/pet.txt' INTO TABLE pet LINES TERMINATED BY '\r\n';
       出现无法读取，解决方法：
       mysql -u root -p --local-infile
       查看是否开启加载本地文件 
       show variables like 'local_infile';
       开启全局本地文件设置 
       set global set local_infile=on;
   DELETE FROM pet;
   UPDATE pet SET birth = '1989-08-31' WHERE name = 'Bowser';
   UPDATE pet SET death=NULL WHERE death='0000-00-00';

   SELECT语句

   SELECT * FROM pet WHERE (species = 'cat' AND sex = 'm') OR (species = 'dog' AND sex = 'f');

   SELECT DISTINCT owner FROM pet;
   SELECT name, species, birth FROM pet
          WHERE species = 'dog' OR species = 'cat';

   SELECT name, birth, death, TIMESTAMPDIFF(YEAR, birth, death) AS age FROM pet WHERE death IS NOT NULL;
   //选出下个月生日
   SELECT name, birth FROM pet WHERE MONTH(birth) = MONTH(DATE_ADD(CURDATE(),INTERVAL 1 MONTH));
   SELECT '2020-02-28' + INTERVAL 1 DAY;
   SHOW WARNINGS;

   通配符和Regex
   SELECT * FROM pet WHERE name LIKE '%w%';
   //REGEXP_LIKE /  REGEXP / RLIKE
   SELECT * FROM pet WHERE REGEXP_LIKE(name, '^b' COLLATE utf8mb4_0900_as_cs);
   SELECT * FROM pet WHERE REGEXP_LIKE(name, BINARY '^b');
   SELECT * FROM pet WHERE REGEXP_LIKE(name, '^b', 'c');

   计数
   SELECT species, sex, COUNT(*) FROM pet  WHERE sex IS NOT NULL  GROUP BY species, sex;

   多表
   SELECT pet.name, TIMESTAMPDIFF(YEAR, birth, date) AS age, remark FROM pet INNER JOIN event ON pet.name=event.name WHERE Ttype='litter';
   单表多用
   SELECT p1.name, p1.sex, p2.name, p2.sex, p1.species FROM pet AS p1 INNER JOIN pet AS p2 ON p1.species=p2.species WHERE p1.sex='f' AND p1.death IS NULL AND p2.sex='m' AND p2.death IS NULL;

   脚本
   shell> mysql < batch-file | more
   shell> mysql < batch-file > mysql.out

   mysql> source filename;
   mysql> \. filename


   SELECT MAX(article) AS article FROM shop;
   没有比s1.price更大的s2.price值,即最大price值
   SELECT s1.article, s1.dealer, s1.price FROM shop s1  LEFT JOIN shop s2 ON s1.price < s2.price  WHERE s2.article IS NULL;
   SELECT article, MAX(price) AS price FROM shop GROUP BY article ORDER BY article;

   SELECT s1.article, s1.dealer, s1.price FROM shop s1 LEFT JOIN shop s2 ON s1.article=s2.article AND s1.price<s2.price WHERE s2.price IS NULL ORDER BY article; 

   变量定义 @var_name
   'SET variable=expression, ...', or 'SELECT expression(s)

   位运算
   SELECT year,month,BIT_COUNT(BIT_OR(1<<day)) AS days FROM t1  GROUP BY year,month;

A FOREIGN KEY - a key used to link two tables together. - a field (or
collection of fields) in one table that refers to the PRIMARY KEY in
another table.

JOIN
----

1. INNER JOIN ： selects records that have matching values in both
   tables.
2. LEFT JOIN ： returns all records from the left table (table1), and
   the matched records from the right table (table2). The result is NULL
   from the right side, if there is no match.
3. RIGHT JOIN： returns all records from the right table (table2), and
   the matched records from the left table (table1). The result is NULL
   from the left side, when there is no match.

`Tutorial 看到此处 <https://dev.mysql.com/doc/refman/8.0/en/example-auto-increment.html>`__\ ：TODO

MySQL实战45讲
=============

一条update语句的执行过程：

1.  首先客户端通过tcp/ip发送一条sql语句到server层的SQL interface
2.  SQL interface接到该请求后，先对该条语句进行解析，验证权限是否匹配
3.  验证通过以后，分析器会对该语句分析,是否语法有错误等
4.  接下来是优化器器生成相应的执行计划，选择最优的执行计划
5.  之后会是执行器根据执行计划执行这条语句。在这一步会去open
    table,如果该table上有MDL，则等待。
    如果没有，则加在该表上加短暂的MDL(S)
    (如果opend_table太大,表明open_table_cache太小。需要不停的去打开frm文件)
6.  进入到引擎层，首先会去innodb_buffer_pool里的data
    dictionary(元数据信息)得到表信息
7.  通过元数据信息,去lock
    info里查出是否会有相关的锁信息，并把这条update语句需要的
    锁信息写入到lock info里(锁这里还有待补充)
8.  然后涉及到的老数据通过快照的方式存储到innodb_buffer_pool里的undo
    page里,并且记录undo log修改的redo (如果data page里有就直接载入到undo
    page里，如果没有，则需要去磁盘里取出相应page的数据，载入到undo
    page里)
9.  在innodb_buffer_pool的data
    page做update操作。并把操作的物理数据页修改记录到redo log buffer里
    由于update这个事务会涉及到多个页面的修改，所以redo log
    buffer里会记录多条页面的修改信息。 因为group
    commit的原因，这次事务所产生的redo log
    buffer可能会跟随其它事务一同flush并且sync到磁盘上
10. 同时修改的信息，会按照event的格式,记录到binlog_cache中。(这里注意binlog_cache_size是transaction级别的,不是session级别的参数,
    一旦commit之后，dump线程会从binlog_cache里把event主动发送给slave的I/O线程)
11. 之后把这条sql,需要在二级索引上做的修改，写入到change buffer
    page，等到下次有其他sql需要读取该二级索引时，再去与二级索引做merge
    (随机I/O变为顺序I/O,但是由于现在的磁盘都是SSD,所以对于寻址来说,随机I/O和顺序I/O差距不大)
12. 此时update语句已经完成，需要commit或者rollback。这里讨论commit的情况，并且双1
13. commit操作，由于存储引擎层与server层之间采用的是内部XA(保证两个事务的一致性,这里主要保证redo
    log和binlog的原子性), 所以提交分为prepare阶段与commit阶段
14. prepare阶段,将事务的xid写入，将binlog_cache里的进行flush以及sync操作(大事务的话这步非常耗时)
15. commit阶段，由于之前该事务产生的redo
    log已经sync到磁盘了。所以这步只是在redo log里标记commit
16. 当binlog和redo
    log都已经落盘以后，如果触发了刷新脏页的操作，先把该脏页复制到doublewrite
    buffer里，把doublewrite buffer里的刷新到共享表空间，然后才是通过page
    cleaner线程把脏页写入到磁盘中

分析方法：先通过原理分析算出扫描行数，然后再通过查看慢查询日志。

框架
----

一个InnoDB表包含两部分：表结构定义和表数据。

复用与重建
~~~~~~~~~~

innodb_file_per_table 设置为
ON，此时每个表各保存为一个文件，而不是保存到共享区（导致被删除后空间不回收）。

-  记录复用：一条记录被删除后，该位置会被标记为删除，但不回收，等待复用，即与原数据相近的数据可插入该位置（B+树）。记录插入可能造成数据页分裂，导致空洞。
-  数据页复用：数据页删除、合并等操作后原数据页被删除。
-  重建表：去除孔洞，收缩表空间。 ``alter table A engine=InnoDB``
-  Online
   DDL:在重建过程中允许增删改（>=5.6版本，通过日志文件记录和重放操作实现）。

InnoDB刷脏页的控制策略
~~~~~~~~~~~~~~~~~~~~~~

使用缓冲池buffer
pool来管理内存，内存页有三种状态：脏页、干净页、未使用的页。

脏页：被修改过的、与磁盘数据页不一致的内存数据页。

-  innodb_io_capacity ：根据磁盘io速度配置。
-  innodb_flush_neighbors：同时刷相邻脏页。

日志模块
--------

`MySQL binlog and redolog <https://www.cnblogs.com/virgosnail/p/10398325.html>`__

WAL:Writt-Ahead
Logging，写完日志和内存即认为事务完成，后续再持久化到磁盘。

+----------------------------------+----------------------------------+
| redolog                          | binlog                           |
+==================================+==================================+
| 物理日志                         | 逻辑日志                         |
+----------------------------------+----------------------------------+
| InnoDB引擎独有，支持崩溃恢复     | MySQL                            |
|                                  | 的Server层实现，故许多其它系统机 |
|                                  | 制（如数据分析系统）会对其有依赖 |
+----------------------------------+----------------------------------+
| 循环写，不持久                   | 追加写，持久，归档               |
+----------------------------------+----------------------------------+
| 记录在某个页面上修改了什么       | 记录语句的原始逻辑               |
+----------------------------------+----------------------------------+
| innodb_flush_log_at_trx_commit=1 | sync_binlog=1                    |
| 每次事务都持久化到磁盘           | 每次事务都持久化到磁盘           |
+----------------------------------+----------------------------------+
| 减少刷盘次数                     | 事务commit时刷                   |
|                                  | 盘。用于归档，主从复制和数据恢复 |
+----------------------------------+----------------------------------+

redolog buffer：在commit前，redo log记录每一次的操作并保存在此内存rebo
buffer中，commit后才写到redo log文件。

为了保持两份日志的逻辑一致性（即保证用这两份log恢复出来的数据是一样的），将
redo log 的写入拆成了两个步骤：prepare 和
commit，即“两阶段提交”。（数据恢复时可由binlog commit记录退出redo log
commit）。

在进行恢复时事务要提交还是回滚，是由Binlog来决定的。当binlog
commit即确认事务已经提交，否则回滚（包括prepare redo log）。

CrashSafe指MySQL服务器宕机重启后，能够保证：

1. 所有已经提交的事务的数据仍然存在。
2. 所有没有提交的事务的数据自动回滚。

崩溃恢复当发生数据页级别的丢失，redolog才能恢复,故redolog是必需的。

事务隔离级别
------------

`事务隔离和锁 <https://developer.ibm.com/zh/technologies/databases/articles/os-mysql-transaction-isolation-levels-and-locks/>`__

MVCC(Multi Version Concurrency Control)：多版本并发控制。

ACID:事务四大属性

1. Atomic：原子性。事务开始后所有操作，要么全部做完，要么全部不做，不可能停滞在中间环节。
2. consistency：一致性。指事务将数据库从一种状态转变为另一种一致的的状态。
3. Isolations：隔离性。多个事务并发操作相同数据时，都有各自完整的数据空间。通过锁机制来保证。
4. Durability：持久性。事务一旦提交，其结果就是永久性的。通过redolog来保证。

事务视图：

类似GIT，每次变更时都会有一条记录（回滚日志），即同一个数据可同时存在多个版本。事务视图即对应一条记录。
只有当事务不再需要用到该条回滚日志时才会删除日志，即当前事务的
read-view中对应最早的回滚日志之前的记录会被删除。故需要避免长事务。
如何避免长事务：使用 set autocommit=1, 通过显式语句的方式来启动事务。

事务隔离级别：

1. 读未提交：read
   uncommitted，事务尚未提交时，其变更就能被其它事务看到。
2. 读已提交：read committed,事务提交后，其所做的变更才能被其它事务看到。
3. 可重复读：repeatable
   read，一个事务的执行过程中看到的数据是不变的，即和该事务启动时看到的数据一样。此时此事务未提交的变更对其它事务是不可见的。
4. 串行化：serializable,对于同一行数据的变更会加读、写锁，锁冲突时需要等待前一个事务释放锁。

各个事务隔离级别下V1、V2、V3的值分别是：读未提交-222；读已提交-122；可重复读-112；串行化-112.

每个row trx_id对应一个数据版本，每个事务或语句都有自己的一致性视图。

1. 一致性读：普通查询语句。根据row trx_id和一致性视图确定数据可见性。

-  可重复读：只承认事务启动前已提交的变更。
-  读提交： 只承认语句启动前已提交的变更。

2. 当前读：更新语句。更新数据都是先读后写的，只能读当前已提交的最新的值。

索引
----

索引算法：

-  有序数组：适用于静态存储引擎（等值查询和范围查询均可）。
-  N叉树：N>2（减少树的深度，减少磁盘写入）。InnoDB使用B+树。
-  哈希表:适用于等值查询（不适用范围查询）。
-  跳表、LSM 树等

主键查询与普通索引查询：

-  主键索引：聚簇索引（clustered index）。叶子保存整行数据。
-  普通索引查询：InnoDB中非主键索引也被称为二级索引（secondary
   index）。叶子保存主键值。

回表：

普通索引需要先查询普通索引树得到主键值，然后去主键索引树查询行数据。 -
尽量使用主键查询以避免回表。 -
短主键可减小普通索引的叶子大小。如自增主键NOT NULL PRIMARY KEY
AUTO_INCREMENT。

-  覆盖索引：普通索引覆盖了查询需求，即该索引的字段或主键是查询目标。
-  最左前缀：B+树的特性。指联合索引的最左N个字段、字符串索引恶最左N个字符。当已经有了
   (a,b) 联合索引后，一般不需要在 a 上建立索引，但b需要。
-  索引下推：索引遍历中，对索引包含的字段先做判断，过滤掉记录，以减少回表

1. 高频查询，可以建立联合索引来使用覆盖索引，不用回表。
2. 非高频查询，再已有的联合索引基础上，使用最左前缀原则来快速查询。

change
buffer：将变更操作先记录下来，在下次访问此数据页时/数据库定时，将操作merge到源数据，减少磁盘访问。change
buffer在内存中有拷贝，也可持久化到磁盘。

唯一索引：当用数据页不在内存中时，需要先将数据页读入内存，判断唯一性后才能进行变更，故change
buffer的优化机制，故当业务不会出现重复数据时可考虑使用普通索引。

优化器会基于扫描行数、是否排序、是否使用临时表等来选择索引。

MySQL会对将要扫描的行数进行不准确的估计，导致可能选错索引。可使用force
index来从

::

   explain select * from t where a between 5000 and 10000; //预估rows:9979

字符串索引如何创建：

1. 完整索引，空间占用大；
2. 前缀索引，利用最左前缀查询，但无法利用覆盖查询；
3. 倒叙插叙，字符串后缀区分度高时使用；不支持范围查询；
4. hash字段索引，额外的计算和空间消耗，不支持范围查询。

Slow Query Log： Stored Programs：

全局锁表级锁行锁
----------------

FTWRL：Flush Tables With Read
Lock，全局读锁，即只读，其它命令会被阻塞。适用于全局逻辑备份。

mysqldump使用
-single-transaction参数来启动事务也可得到一致性视图，但必须姻亲支持事务。

表级锁：

1. 表锁：lock tables …
   read/write加锁。unlock主动释放或客户端断开时释放。
2. MDL锁：访问表时自动加，以保证读写的正确性。事务提交时释放锁。读锁不互斥，有写锁时互斥。
3. 行锁：InnoDB支持，MyISAM不支持。
4. 两阶段协议：InnoDB事务中，在需要时才会加行锁，到事务提交才会释放锁。故在事务中尽量把可能造成锁冲突、影响并发度的所往后放。

死锁：

-  等待超时机制；
-  死锁检测机制：并发量大时cpu资源消耗大。
-  控制并发量，如使用中间件、排队策略等。

排序
----

ORDER BY

::

   select city,name,age from t where city='杭州' order by name limit 1000  ;

1. 全字段排序：取出所有字段放入临时表然后直接排序即可。为了减少磁盘访问，InnoDB表中会优先选择这个。（临时内存表排序则会优先使用ROW
   ID排序）。
2. ROW ID排序：排序时使用排序字段+row
   id，排序完成之后需要回表取得其它字段，占用内存（sort buffer）小。

-  ``SET max_length_for_sort_data = 16``\ ：单行数据长度超过限制即使用ROW
   ID排序。
-  ``tmp_table_size``\ ：限制了内存临时表大小。
-  ``sort_buffer_size``\ ：超过此限制则使用归并排序，否则使用优先队列排序。

rowid：若存在主键则为主键，若没有主键InnoDB等引擎会生成一个6字节的rowid来唯一标识数据行。
随机排序：

order by rand() ：开销大，使用了内存临时表，内存临时表排序的时候使用了
rowid 排序方法。

计数
----

count效率.

count：判断参数是否为NULL，不为NULL则累加。

使用count()聚合函数后，若有\ ``where``\ 条件，且where条件的字段未建立索引，则查询不会走索引，直接扫描了全表。

``count(字段)<count(主键 id)<count(1)≈count(*)``

-  count(字段)：若字段定义为NOT NULL则和主键处理流程一致。若为定义NOT
   NULL，则遍历表，并取出对应字段的值，并判断其是否为空，然后累加。
-  count(主键)：遍历表，去除主键id值，返回给server层，直接累加（因为其值不可能为空）。
-  count(1)：遍历表，但不取值，server对于每一行直接按行累加（1不可能为空，不需要判断）。
-  coutn(*)：数据库对此用法有优化，不取值，直接累加。当表有主键或表只有单列时比count(1)快。

条件字段中的函数操作可能会破坏索引值的有序性，故优化器决定不使用树搜索，而是使用遍历索引。

::

   select * from tradelog where id + 1 = 10000 //无法使用索引快速定位
   需要改为
   where id = 10000 -1

类型转换：
