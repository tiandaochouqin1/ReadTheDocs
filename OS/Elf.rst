=====================
ELF、Compile & Main
=====================

:Date:   2020-07-15 22:45:43


参考文章
==============
1. Linux/UNIX系统编程手册(TLPI)

2. :download:`gcc 9.2 manual </files/gcc_9.2_manuals.pdf>`


反汇编常用命令
===============

objdump
----------
objdump -x -D -s:

::

   -x:    文件头、动态库、符号表. 等于-a -f -h -p -r -t
   -s:    二进制形式打印所有段内容
   -D:    反汇编所有段
   -d/S:  反汇编代码段
   -t:    符号表 = nm
   -j .text/.data: 指定段,需要配合-d使用
   -h:    关键段表
          

readelf
---------

1. readelf -h : elf文件头。elf文件和平台信息;Program Header Table 和 Section Header Table 的 offset/size/number。
2. readelf -S : 节区表/节头部表Section Headers。 objdump -h(只显示关键段)。
3. readelf -r .so ：查看重定位表。
4. readelf -s : 符号表（nm、objdump -t）
5. readelf -l : rogram Headers,以及segment与Section的对应关系
6. readelf -a : 所有
7. readelf -d : 查看so的.dynamic段。


8. ldd exe： 查看so依赖
9. ar:  静态库打包、解压等
10. strings: 查看可打印字符串
11. size exe: 查看text、data、bss的长度。

.. figure:: /images/Elf-layout.png
   :scale: 70%

   ELF结构

vim xxd
-----------
objdump和readelf可查看解析后的符号表，xxd查看原始二进制符号表。

::

      vim -b main.o
      hex形式-- vim执行 %!xxd
      回写  ：%!xxd -r



ELF结构
=============
1. ☆ `[原创] ELF文件结构详解-Android安全-看雪论坛-安全社区|安全招聘|bbs.pediy.com  <https://bbs.pediy.com/thread-255670.htm>`__
2. ☆ `elf(5) - Linux manual page  <https://man7.org/linux/man-pages/man5/elf.5.html>`__
3. ☆ `.symtab: Symbol Table - CTF Wiki  <https://ctf-wiki.org/executable/elf/structure/symbol-table/#_2>`__
4. `File Format (Linker and Libraries Guide)  <https://docs.oracle.com/cd/E19683-01/816-1386/6m7qcoblj/index.html#chapter6-tbl-21>`__



- Elf文件头：readelf -h 



Section Header
----------------

::

   include/uapi/linux/elf.h

  #define EI_NIDENT 16

  typedef struct
  {
       unsigned char	e_ident[EI_NIDENT];	/* Magic number and other info */
       Elf64_Half	e_type;			/* Object file type */
       Elf64_Half	e_machine;		/* Architecture */
       Elf64_Word	e_version;		/* Object file version */
       Elf64_Addr	e_entry;		/* Entry point virtual address */
       Elf64_Off	e_phoff;		/* Program header table file offset */
       Elf64_Off	e_shoff;		/* Section header table file offset */
       Elf64_Word	e_flags;		/* Processor-specific flags */
       Elf64_Half	e_ehsize;		/* ELF header size in bytes */
       Elf64_Half	e_phentsize;		/* Program header table entry size */
       Elf64_Half	e_phnum;		/* Program header table entry count */
       Elf64_Half	e_shentsize;		/* Section header table entry size */
       Elf64_Half	e_shnum;		/* Section header table entry count */
       Elf64_Half	e_shstrndx;		/* Section header string table index */
  } Elf64_Ehdr;

  52 or 64 bytes long for 32-bit and 64-bit binaries respectively.


.. figure:: /images/elf_header.png

      开头的16B Magic number



段位置与长度
~~~~~~~~~~~~~

::

   # readelf -h SimpleSection.o
   ELF Header:
   Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
   Class:                             ELF64
   Data:                              2's complement, little endian
   Version:                           1 (current)
   OS/ABI:                            UNIX - System V
   ABI Version:                       0
   Type:                              REL (Relocatable file)
   Machine:                           Advanced Micro Devices X86-64
   Version:                           0x1
   Entry point address:               0x0
   Start of program headers:          0 (bytes into file)
   Start of section headers:          1040 (bytes into file)
   Flags:                             0x0
   Size of this header:               64 (bytes)
   Size of program headers:           0 (bytes)
   Number of program headers:         0
   Size of section headers:           64 (bytes)
   Number of section headers:         13
   Section header string table index: 12

   # readelf -S SimpleSection.o
   There are 13 section headers, starting at offset 0x410:

   Section Headers:
   [Nr] Name              Type             Address           Offset
         Size              EntSize          Flags  Link  Info  Align
   [ 0]                   NULL             0000000000000000  00000000
         0000000000000000  0000000000000000           0     0     0
   [ 1] .text             PROGBITS         0000000000000000  00000040
         0000000000000054  0000000000000000  AX       0     0     1
   [ 2] .rela.text        RELA             0000000000000000  00000300
         0000000000000078  0000000000000018   I      10     1     8
   [ 3] .data             PROGBITS         0000000000000000  00000094
         0000000000000008  0000000000000000  WA       0     0     4
   [ 4] .bss              NOBITS           0000000000000000  0000009c
         0000000000000004  0000000000000000  WA       0     0     4
   [ 5] .rodata           PROGBITS         0000000000000000  0000009c
         0000000000000004  0000000000000000   A       0     0     1
   [ 6] .comment          PROGBITS         0000000000000000  000000a0
         000000000000002e  0000000000000001  MS       0     0     1
   [ 7] .note.GNU-stack   PROGBITS         0000000000000000  000000ce
         0000000000000000  0000000000000000           0     0     1
   [ 8] .eh_frame         PROGBITS         0000000000000000  000000d0
         0000000000000058  0000000000000000   A       0     0     8
   [ 9] .rela.eh_frame    RELA             0000000000000000  00000378
         0000000000000030  0000000000000018   I      10     8     8
   [10] .symtab           SYMTAB           0000000000000000  00000128
         0000000000000180  0000000000000018          11    11     8
   [11] .strtab           STRTAB           0000000000000000  000002a8
         0000000000000053  0000000000000000           0     0     1
   [12] .shstrtab         STRTAB           0000000000000000  000003a8
         0000000000000061  0000000000000000           0     0     1

       
SimpleSection.o 大小为 1872（0x750）字节。

shstrtab结束后长度为0x410（1040），段表长度为64×13=832（0x340）,刚好为文件长度。

此处段表位于最后，与csapp的描述一致。




Program header (Phdr)
----------------------

::

   typedef struct {
        Elf64_Word      p_type;
        Elf64_Word      p_flags;
        Elf64_Off       p_offset;
        Elf64_Addr      p_vaddr;
        Elf64_Addr      p_paddr;
        Elf64_Xword     p_filesz;
        Elf64_Xword     p_memsz;
        Elf64_Xword     p_align;
   } Elf64_Phdr;

   

p_paddr：

::

   man5/elf.5.html
   On systems for which physical addressing is relevant, this
   member is reserved for the segment's physical address.
   Under BSD this member is not used and must be zero.


   Oracle Solaris 11 
   The segment's physical address for systems in which physical addressing is relevant.
   Because the system ignores physical addressing for application programs, 
   this member has unspecified contents for executable files and shared objects.

   该字段在所有系统中都没有意义?


symbol table
--------------
符号表定义在linux-src\include\uapi\linux\elf.h

::

      typedef struct elf64_sym {
           Elf64_Word st_name;		/* Symbol name, index in string tbl */  在字符串表的索引
           unsigned char	st_info;	/* Type and binding attributes */   4bits BIND : 4bits TYPE
           unsigned char	st_other;	/* No defined meaning, 0 */
           Elf64_Half st_shndx;		/* Associated section index */    符号定义所处的section。外部引用符号为0
           Elf64_Addr st_value;		/* Value of the symbol */
           Elf64_Xword st_size;		/* Associated symbol size */
      } Elf64_Sym;



st_name
~~~~~~~~~~~~~~~~~~~~~

symtab中的st_name指向字符串表的索引。

`Symbol Table Section <https://docs.oracle.com/cd/E19120-01/open.solaris/819-0690/chapter6-79797/index.html>`__


An index into the object file's symbol string table, which holds the character representations of the symbol names. 
If the value is nonzero, the value represents a string table index that gives the symbol name. 


st_value
~~~~~~~~~~~~~~~~
symtab中的st_value。

`Symbol Values <https://docs.oracle.com/cd/E19120-01/open.solaris/819-0690/chapter6-35166/index.html>`__

st_value的含义取决于object文件类型：

   1. In relocatable files, st_value holds alignment constraints for a symbol whose section index is SHN_COMMON.

   2. In relocatable files, st_value holds a section offset for a defined symbol. st_value is an offset from the beginning of the section that st_shndx identifies.

   3. In **executable and shared object files**, st_value holds a virtual address. To make these files' symbols more useful for the runtime linker, the section offset (file interpretation) gives way to a virtual address (memory interpretation) for which the section number is irrelevant.
   即指向了 **符号的虚拟地址**。



st_info
~~~~~~~~~

::

      /* This info is needed when parsing the symbol table */

      #define STB_LOCAL  0
      #define STB_GLOBAL 1
      #define STB_WEAK   2

      /* 表示符号关联(BIND)的对象的信息。
      /* 若外部引用符号为未解析则为STT_NOTYPE，其类型由找到的外部定义来确定（这里不区分函数、变量）。
      #define STT_NOTYPE  0         //The symbol's type is not defined.
      #define STT_OBJECT  1         //The symbol is associated with a data object.
      #define STT_FUNC    2         //The symbol is associated with a function or other executable code.
      #define STT_SECTION 3
      #define STT_FILE    4
      #define STT_COMMON  5
      #define STT_TLS     6

      #define ELF_ST_BIND(x)		((x) >> 4)
      #define ELF_ST_TYPE(x)		(((unsigned int) x) & 0xf)


.. figure:: /images/elf_st_info.png
   :alt: elf_st_info


符号表反汇编实例
~~~~~~~~~~~~~~~~~~~
x86 小端，gcc version 9.3.0 

外部引用符号f未被解析TYPE则为STT_NOTYPE，其类型由找到的外部定义来确定（这里不区分函数、变量）；其BIND为STB_GLOBAL。

::

      readelf -S main.o

        [10] .symtab           SYMTAB           0000000000000000  000000e8
             0000000000000120  0000000000000018          11     9     8
        [11] .strtab           STRTAB           0000000000000000  00000208
             0000000000000025  0000000000000000           0     0     1

         

      readelf -s main.o

      Symbol table '.symtab' contains 12 entries:
         Num:    Value          Size Type    Bind   Vis      Ndx Name
           0: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT  UND
           1: 0000000000000000     0 FILE    LOCAL  DEFAULT  ABS main.c
           2: 0000000000000000     0 SECTION LOCAL  DEFAULT    1
           3: 0000000000000000     0 SECTION LOCAL  DEFAULT    3
           4: 0000000000000000     0 SECTION LOCAL  DEFAULT    4
           5: 0000000000000000     0 SECTION LOCAL  DEFAULT    6
           6: 0000000000000000     0 SECTION LOCAL  DEFAULT    7
           7: 0000000000000000     0 SECTION LOCAL  DEFAULT    8
           8: 0000000000000000     0 SECTION LOCAL  DEFAULT    5
           9: 0000000000000000    35 FUNC    GLOBAL DEFAULT    1 main
          10: 0000000000000000     0 NOTYPE  GLOBAL DEFAULT  UND _GLOBAL_OFFSET_TABLE_
          11: 0000000000000000     0 NOTYPE  GLOBAL DEFAULT  UND f


      f符号表项起始地址: 0xe8 + (Elf64_Sym结构体 24Bytes * f编号11) = 0x1f0;

         000001f0: 2300 0000 1000 0000 0000 0000 0000 0000  #...............
         00000200: 0000 0000 0000 0000 006d 6169 6e2e 6300  .........main.c.
         00000210: 6d61 696e 005f 474c 4f42 414c 5f4f 4646  main._GLOBAL_OFF
          
      可得: st_name=0x23; bind=1,type=0;st_shndx=st_value=st_size=0



重定位表
---------------------------------
Relocation entries (Rel & Rela)


elf程序装载
-----------

elf文件头中的section表按照读写属性在程序头中的segment表中合并。
有两个segment：data段-RW 和 code段-RX。

段地址对齐：elf文件逻辑上被分为4k大小的块装入物理内存，而在虚拟内存中，包含两个段接壤部分的块会被映射两次。


elf可执行文件的装载：load_elf_binary()位于fs/Binfmt_elf.C

1. 检查elf有效性；
2. .interp段中寻找动态链接器路径；
3. 根据程序头表进行映射；
4. 初始化elf进程环境；
5. 将返回地址修改位elf可执行文件的入口。

段分布(.o/exe/vm)
------------------
1. bss在.o和exe中不占用空间，只有一条段表条目 **指示在vm中需要占用的空间**。
2. dynsym是symtab的子集，symtab不会被加载到内存，dl_runtime_resolve时只需要dynsym。
3. strip移除symtab和strtab(都属于non-alloctable)，GNU strip discards all symbols from object files objfile. 


.. figure:: /images/Elf_Obj_Sections.png
   :scale: 70%
   :alt: Elf_Obj_Sections

.. figure:: /images/Elf_Exe_Sections.png
   :scale: 70%
   :alt: Elf_Exe_Sections


.. figure:: /images/Procee_Vm_Sections.png
   :scale: 70%
   :alt: Procee_Vm_Sections


静态链接
===========
链接器两大功能：

1. 符号解析：将目标文件中每个全局符号都绑定到一个唯一的定义；
2. 重定位：聚合节以确定每个全局符号的最终内存地址，并修改对这些符号的引用（rel.data/rel.text）。


符号
---------
弱符号与强符号：处理链接时多次定义的情况。

1. 强符号：函数与已初始化的全局变量；
2. 弱符号：未初始化的全局变量，或 __attribute__((weak))


强引用与弱引用：处理链接时找不到引用的外部符号的情况。

1. 强引用：符号未定义错误；
2. 弱引用：不报错，默认为0。__attribute__ ((weakref))

弱符号和弱链接对于库很有用，使得程序功能更容易裁剪和组合。用户可覆盖库的弱符号；库可覆盖用户的弱引用。


ld脚本与静态链接
---------------------
静态库：多个目标文件经过打包压缩而来。链接时是分.o链接的。

ar -t libc.a 查看包含的.O


相似段合并，两步链接：

1. 空间与地址分配：扫描输入文件，计算合并段的位置和长度；同时生成全局符号表。
2. 符号解析与重定位：将未定义符号与定义关联，调整代码中的地址等。

objdump -r .o:重定位表，所有引用外部符号的地址。


指令修正方式，x86有两种基本重定位类型。

1. 绝对寻址修正：S+A，得到符号实际地址；
2. 相对寻址修正：S+A-P，得到符号相对被修正位置的地址差。

S实际地址；A被修正位置的值；P被修正的位置。

ld链接脚本：控制输入段如何变成输出段。ld使用默认链接脚本。

指定段：在全局变量或函数前加上 `__attribute__((section("name")))`



