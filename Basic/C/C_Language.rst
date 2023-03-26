
:Date:   2021-09-09 00:37:13



C语法知识
=========
参考链接
---------
1. 在线gdb：https://www.onlinegdb.com/myfiles
2. 在线汇编：https://godbolt.org/
3. `用C语言实现面向对象编程OOP <https://mp.weixin.qq.com/s/Vj31M2q0H5eeJwMhvDyt6A>`__
4. `C语言实现面向对象的原理 <https://mp.weixin.qq.com/s/b9IXQ8Hbh-8ejmU010sWiA>`__

- The C Programming Language 2ed.pdf
- `gnu-c-language-manual Richard Stallman <https://github.com/VernonGrant/gnu-c-language-manual>`__

声明与定义
---------------

别名alias
~~~~~~~~~~
1. `Common Variable Attributes (Using the GNU Compiler Collection (GCC))  <https://gcc.gnu.org/onlinedocs/gcc/Common-Variable-Attributes.html>`__
2. https://developer.arm.com/documentation/dui0491/f/Compiler-specific-Features/--attribute----alias---function-attribute

alias和real_func可以同时使用。


Where a function is defined in the current translation unit, the alias call is replaced by a call to the function, 
and the alias is emitted alongside the original name


::

    int var_target;
    extern int __attribute__ ((alias ("var_target"))) var_alias;

    或

    void __f () { /* Do something. */; }
    void f () __attribute__ ((weak, alias ("__f")));


复杂的函数声明(signal)
~~~~~~~~~~~~~~~~~~~~~~

typedef
~~~~~~~~


数组与指针比较
--------------
1. 数组名与指针可互换使用，编译器会对寻址解析自动进行转换。
2. sizeof(arr)与sizeof(p) 不同。
3. 定义字符串时，arr可变，p指向的字符串不可变。
4. 若在引用外部arr/p时使用了混用了声明形式，则会导致错误。如 使用extern int * arr 声明数组arr[size].

extern
---------
1. static： The static declaration, applied to an external variable or function, limits the scope of
that object to the rest of the source file being compiled.
2. extern： Functions themselves are always external, because C does not allow functions to be defined inside other functions

inline关键字
----------------
☆☆ 参考： https://gcc.gnu.org/onlinedocs/gcc/Inline.html 6.45 An Inline Function is As Fast As a Macro

1. 减少 function-call overhead
2. 编译时优化常数入参,减少代码体积。
3. 不适合inline: 变参函数、调用alloca栈分配函数、使用goto/setjump等跳转指令


::

  # gcc -std=gnu99 -Og inline.c -o inline

   /tmp/ccr0JbZ0.o: In function `main':
   inline.c:(.text+0xa): undefined reference to `fa'
   collect2: error: ld returned 1 exit status


   # cat inline.c

   #include <stdio.h>
   inline int fa(int a); // 显式声明。隐私声明则认为没有inline。
   inline int fa(int a)
   {
       printf("%d\n", a);
       printf("%d\n", a+1);
       return a;
   }

   int main()
   {
       int var = 1;
       fa(var);
       return 0;
    }

          
查看inline.o，发现 main通过call调用fa，.symtab中有fa(UND)，而.text中无单独的fa。

只有在main调用external函数fa + inline声明使得.text无fa时才会符号解析失败。

影响是否真实inline的因素: ``_always_inline/inline -> -On -> -std=gnu** -> static -> asm行数 -> 声明(c99)/定义(c90)形式(inline、extern等)``

::

    1. __attribute__(__always_inline)☆ : fa真实inline插入到main。inline✔

    2. inline☆  -> 无-On优化: 普通函数,inline完全不起作用。
    3.                       -> static: 限制了fa不会在.symtab中。符号表call✔
    4.                       -> external、非static: fa在.symtab。位置偏移call✔
                 -> 有-On优化:如下
    5. inline+On: 
    6.           -> c89/c90 ☆   -> static :  fa真实inline插入。inline✔
    7.                                        -> static定义+非static声明: 不冲突,当作了两个不同函数。
    8.                           -> 非static  -> 显式extern定义 : .text不保存fa。inline✔
    9.                                        -> 非显式extern: .text一直保存fa。 call✔ 
    10.          -> c99/c11/c17☆ -> static : fa真实inline插入。inline✔
    11.                                        -> static定义+非static声明: 类型冲突。
    12.                           -> 非static  -> 非static定义+static声明: 效果通inline✔
    13.                                        -> fa汇编行数少(约七八行): inline✔
    14.                                        -> fa汇编行数多: main中调用fa 
    15.                                                   -> inline声明fa : .text不保存fa , ld符号解析失败。 ★★
    16.                                                   -> 非inline声明/隐式声明: 默认为external, .text保存fa, ld成功。call✔
    17.                                                   -> 若声明使用static

    未特别指出参数的均为定义处/或定义声明相同。 
    
    这里static/inline使用时的类型取决于声明。


其它相关编译选项
~~~~~~~~~~~~~~~~~
https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html

1. -fkeep-inline-functions: inline+ On + static 时保留fa 代码段
2. -finline-functions : 足够小的函数则inline。 O2打开。
3. -finline-functions-called-once: 被调用一次的static函数。 O1打开。

位域、联合体与大小端
---------------------
1. `简单讲解C/C++中大小端及其对位域的影响 - FranzKafka Blog  <https://coderfan.net/big-endian-and-little-endian-in-c-or-c-plus.html>`__

如果是 ``大端模式，其位域排列顺序对应在内存中由高bit指向低bit``，而小端模式则相反。

::

    #include <stdio.h>

   typedef struct{
       int a;       int b;       int c;
   }S_a;

   typedef struct{
       int a:4;       int b:5;       int c:6;       int d:7;
       // int e:6;
   }S_b;

   int main ()
   {
       S_a s_a;       s_a.a = 1;       s_a.b = 2;       s_a.c = 3;
       S_b s_b;       s_b.a = 1;       s_b.b = 2;       s_b.c = 3;       s_b.d = 5;
       // s_b.e = 6; 

       int a[3];       a[0]=1;       a[1]=2;       a[2]=3;

       printf("struct: %p %p %p\n", &s_a.a, &s_a.b, &s_a.c);
       printf("array:  %p %p %p\n", &a[0], &a[1], &a[2]);
       int* a2 = &s_b;
       printf("bitfield:0x%x \n", a2[0]);

       return 0;
   }


::
    
      x86小端结果:
      struct: 0x7ffea082ac00 0x7ffea082ac04 0x7ffea082ac08
      array:  0x7ffea082ac0c 0x7ffea082ac10 0x7ffea082ac14
      bitfield:0x28621 

      arrch64_be大端端结果:
      struct和array的成员均是地址逐渐增长，与x86一直
      bitfiesd:0x110617ff


大小端读取的bitfield对比：(aarch64_be剩余未使用bit为1，x86为0)

::

                    |a:4=1|b:5=2 |c:6=3  |d:7=5     |剩余10bits为1
    大端0x110617ff： 0001  0001  0000  0110  0001  0111  1111  1111

                    |剩余10bits为0 |d:7=5     |c:6=3 |b:5=2  |a:4=1|       
    小端0x00028621： 0000  0000  0000  0010  1000  0110  0010  0001


可得： ``大端时bitfiled先往大地址存数据``，小端先往小地址存数据。 位域本身的bits无大小端。


位域的存储顺序取决于实现
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1. `Bit field extract with struct and endianness in C - Stack Overflow  <https://stackoverflow.com/questions/54223407/bit-field-extract-with-struct-and-endianness-in-c>`__
2. `EXP11-C. Do not make assumptions regarding the layout of structures with bit-fields - SEI CERT C Coding Standard - Confluence  <https://wiki.sei.cmu.edu/confluence/display/c/EXP11-C.+Do+not+make+assumptions+regarding+the+layout+of+structures+with+bit-fields>`__
3. 6.7.2 Type specifiers, paragraph 11 of the C Standard:

以上两处参考文献均指出：

1. 存储顺序：The order of allocation of bit-fields within a unit (high-order to low-order or low-order to high-order) is ``implementation-defined``. 
2. 对齐：The alignment of the addressable storage unit is unspecified.

推测(××)：

1. 大小端按照bit全部反序(而不是按照Bytes),这样可兼容 Byte和bitfield (屏蔽了内部bit顺序)。
2. 其它数据类型(int/char等)Byte读取，计算机对我们屏蔽了Byte内部bit顺序的差异，所以平常可按Byte理解。
3. bitfield内部bit也全部反序，读写入时计算机仍然屏蔽了bitfield内部bit的顺序差异
4. 如何验证? `C语言面试题——位域及大小端模式的理解 - 云+社区 - 腾讯云  <https://cloud.tencent.com/developer/article/1692952>`__

位域结构体顺序
~~~~~~~~~~~~~~~~
位域在大端和小端系统上的定义顺序需要相反，这样无论在大小端系统，按bitfield保存值后，按整体读出来的值是一样的。。(见iphdr)


`Linux v5.17-rc8 - include/uapi/linux/ip.h  <https://sbexr.rabexc.org/latest/sources/c7/124a3bc7fedb4c.html#000560010006a001>`__

::

   struct iphdr {
   #if defined(__LITTLE_ENDIAN_BITFIELD)
   	__u8	ihl:4,
   		version:4;
   #elif defined (__BIG_ENDIAN_BITFIELD)
   	__u8	version:4,
     		ihl:4;
   #else
   #error	"Please fix <asm/byteorder.h>"
   #endif
   	__u8	tos;
   	__be16	tot_len;
   	__be16	id;
   	__be16	frag_off;
   	__u8	ttl;
   	__u8	protocol;
   	__sum16	check;
   	__be32	saddr;
   	__be32	daddr;
   	/*The options start here. */
   };


部分初始化
~~~~~~~~~~~~
1. `ARR02-C. Explicitly specify array bounds, even if implicitly defined by an initializer - SEI CERT C Coding Standard - Confluence  <https://wiki.sei.cmu.edu/confluence/display/c/ARR02-C.+Explicitly+specify+array+bounds%2C+even+if+implicitly+defined+by+an+initializer>`__
2. K&R A.8.7 Initialization

aggregate类型（数组和结构体）使用括号列表初始化时，剩余成员隐式初始化为0。()

If there are fewer initializers in a ``brace-enclosed list`` than there are elements or members of ``an aggregate``, 
or fewer characters in a string literal used to initialize an array of known size than there are elements in the array, 
the remainder of the aggregate shall be initialized implicitly the same as objects that have ``static storage duration``.

If an array of unknown size is initialized, its size is determined by the largest indexed element with an explicit initializer. The array type is completed at the end of its initializer list.


size_t类型
---------------
1. `About size_t and ptrdiff_t  <https://pvs-studio.com/en/blog/posts/cpp/a0050/>`__
2. `int - What is size_t in C? - Stack Overflow  <https://stackoverflow.com/questions/2550774/what-is-size-t-in-c>`__


跨平台移植性。安全性(越界问题)。可提升性能。

1. wherever you deal with pointers or arrays, you should use size_t and ptrdiff_t types.
2. 存储ptr时一般使用uintptr_t/intptr_t

特性：

1. size_t ： 
 
 - sizeof返回值的类型。
 - unsigned，与uintptr_t同义。
 - store the maximum size of a theoretically possible array of any type. 
 - size_t type is usually used for loop counters, array indexing, and address arithmetic.


2. ptrdiff_t： 

 - signed与intptr_t同义。
 - ptrdiff_t is the type of the result of an expression where one pointer is subtracted from the other (ptr1-ptr2)
 - ptrdiff_t type is usually used for loop counters, array indexing, size storage, and address arithmetic.

换行、字符串结束符、EOF
------------------------
::
        
    文件标记,Ascii,含义
    ‘’\n’,10,换行
    ‘\0’,0,c语言中表示字符串结束符
    EOT,4,传输结束符
    EOF,-1,文件/流结束符
    

CERT C
=======
sequence point
-----------------
1. `EXP30-C. Do not depend on the order of evaluation for side effects - SEI CERT C Coding Standard - Confluence  <https://wiki.sei.cmu.edu/confluence/display/c/EXP30-C.+Do+not+depend+on+the+order+of+evaluation+for+side+effects>`__
2. `Warning Options (Using the GNU Compiler Collection (GCC))  <https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html>`__

1. 序列点可保证其前后求值的顺序。
2. 若无序列点，则表达式求值顺序未定义。

3. 两个序列点之间，只能修改一次值。

the C and C++ standards specify that “Between the previous and next sequence point an object 
shall **have its stored value modified at most once by the evaluation of an expression.**
Furthermore, the prior value shall be read only to determine the value to be stored.”

序列点
~~~~~~~~~~~
包括: 函数调用、控制语句(如while)、 **部分运算符(逻辑与、逻辑或、逗号、条件运算符。其它运算符均非序列点!!)** 。

常见问题与示例
~~~~~~~~~~~~~~~~

1. 函数参数求值顺序不定
2. 自增/减使用的一些场景，如下。

::

    /* i is modified twice between sequence points */
    i = ++i + 1; 
    
    /* i is read other than to determine the value to be stored */
    a[i++] = i;  

