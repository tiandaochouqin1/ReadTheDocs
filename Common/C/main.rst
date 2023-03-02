

main之前
==========
1. 英文版 `Linux x86 Program Start Up <http://dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html>`__ ;
   翻译不怎么样 `Linux X86 程序启动 <https://luomuxiaoxiao.com/?p=516>`__
2. glibc源码位置: https://code.woboq.org/userspace/glibc/csu/libc-start.c.html#129
3. https://www.gnu.org/software/hurd/glibc/startup.html GNU Hurd系统的参考过程
4. https://gcc.gnu.org/onlinedocs/gccint/Initialization.html

问题
------
1. 构造函数(__libc_csu_init)做了什么？ 哪些需要构造？C是否就不需要构造函数？ : 详细走一遍gdb


程序的运行与结束
----------------
``execvp -> preinit -> _start -> __libc_start_main -> __libc_csu_init -> _init -> main -> exit -> atexit/fini/destructor``


.. figure:: /images/main_call_graph.png
   :scale: 80%
   :alt: main_call_graph

   main_call_graph



1. execvp:   设置栈，压入argc、argv、envp的值，设置文件描述符（0、1、2），预初始化函数（.preinit）;
2. _start:  置零ebp标记最外层栈，esp对齐16B，压入__libc_start_main的参数（通过esp/esi取到的argc/argv的偏移）；位于glibc/csu/libc-start.c
3. __libc_start_main:  完成主要工作。setuid/setgid；将fini和rtld_fini传递给at_exit;调用init参数；
   并调用main（原型如下）；调用exit。

4. init -> __libc_csu_init -> _init :  调用_do_global_ctors_aux-构造函数constructor; 调用C代码里的Initializer；
5. exit :  先调用注册到atexit的函数，然后fini,最后destructor。

.. figure:: /images/stack_main_start.png
   :scale: 70%

   stack_main_start


execv
~~~~~~~~~~
`Linux内核之execve函数-BugMan-ChinaUnix博客  <http://blog.chinaunix.net/uid-69947851-id-5825847.html>`__

.. figure:: /images/execv.jpg

   execv x86_64

   

_start和__libc_start_main
----------------------------
glibc/csu/elf-init.c

函数原型
~~~~~~~~~

::
      
      int __libc_start_main(  int (*main) (int, char * *, char * *),
                int argc, char * * ubp_av,
                void (*init) (void),
                void (*fini) (void),
                void (*rtld_fini) (void),
                void (* stack_end));


      int main(int argc, char** argv, char** envp)


_start压入参数
~~~~~~~~~~~~~~~~

::

      080482e0 <_start>:
      80482e0:       31 ed                   xor    %ebp,%ebp     # 置零0，标记为初始栈帧
      80482e2:       5e                      pop    %esi          # 弹出argc的偏移，后面再压入。然后esp指向了argv
      80482e3:       89 e1                   mov    %esp,%ecx     # 弹出argv偏移
      80482e5:       83 e4 f0                and    $0xfffffff0,%esp  # esp对齐16B，栈向下生长
      80482e8:       50                      push   %eax          # 这里没有用，为了对齐
      80482e9:       54                      push   %esp          # stack_end，栈底
      80482ea:       52                      push   %edx          # rtld_fini，Destructor of dynamic linker from loader passed in %edx.
      80482eb:       68 00 84 04 08          push   $0x8048400    # fini，__libc_csu_fini - Destructor of this program.
      80482f0:       68 a0 83 04 08          push   $0x80483a0    # init，__libc_csu_init, Constructor of this program.
      80482f5:       51                      push   %ecx          # 压入argv的偏移
      80482f6:       56                      push   %esi          # 压入argc的偏移
      80482f7:       68 94 83 04 08          push   $0x8048394    # main函数
      80482fc:       e8 c3 ff ff ff          call   80482c4 <__libc_start_main@plt>
      8048301:       f4


不需要显式传入envp
~~~~~~~~~~~~~~~~~~~~~
在argv末尾紧接着的位置取envp， ** envp = &argv[argc + 1] 

> 为什么需要argc?根据null结束符即可判断argv数量（envp也没有显式的成员数量）




__libc_csu_init 
-------------------
x86环境上gdb跟踪（C语言），发现调用栈和参考文章的流程图不一样，缺少部分函数调用过程（C++和C一样，centos和ubuntu一样，arm和x86也类似，可能是gcc/g++版本的原因？）：

与这篇文章的反汇编相同 `who call main <http://wen00072.github.io/blog/2015/02/14/main-linux-whos-going-to-call-in-c-language/>`__

1. _init中只调用了__gmon_start,没有调用frame_dummy（有此符号）和__do_global_ctors_aux（无此符号）
2. constructor和gmon_start由init直接调用
3. 没有段.ctor


.ctor和.dtor段
~~~~~~~~~~~~~~~~~

`section自定义段 <https://sourceware.org/binutils/docs/as/Section.html>`__

https://gcc.gnu.org/onlinedocs/gccint/Initialization.html

- .ctor和.dtor段只在可自定义section名的目标文件中被支持（coff/elf都支持）

::
        
  The best way to handle static constructors works only for object file formats which provide arbitrarily-named sections.
   A section is set aside for a list of constructors, and another for a list of destructors. 
   Traditionally these are called ‘.ctors’ and ‘.dtors’. 
   Each object file that defines an initialization function also puts a word in the constructor section to point to that function. 
   The linker accumulates all these words into one contiguous ‘.ctors’ section. Termination functions are handled similarly.



- 查看源码得知，程序定义了  **USE_EH_FRAME_REGISTRY || USE_TM_CLONE_REGISTRY**  ，对应register_tm_clones和.eh_frame。
  该分支不定义__do_global_ctors_aux 。

https://github.com/gcc-mirror/gcc/blob/master/libgcc/crtstuff.c#L511

https://code.woboq.org/gcc/libgcc/crtstuff.c.html#448


::


      #ifdef OBJECT_FORMAT_ELF

      #if defined(USE_EH_FRAME_REGISTRY) \
      || defined(USE_TM_CLONE_REGISTRY)
      # 中间定义了frame_dummy

            #ifdef __LIBGCC_INIT_SECTION_ASM_OP__
                  CRT_CALL_STATIC_FUNCTION (__LIBGCC_INIT_SECTION_ASM_OP__, frame_dummy)
            #else /* defined(__LIBGCC_INIT_SECTION_ASM_OP__) */
                  static func_ptr __frame_dummy_init_array_entry[]
                  __attribute__ ((__used__, section(".init_array"), aligned(sizeof(func_ptr))))
                  = { frame_dummy };
            #endif /* !defined(__LIBGCC_INIT_SECTION_ASM_OP__) */

      #endif /* USE_EH_FRAME_REGISTRY || USE_TM_CLONE_REGISTRY */

      #else  /* OBJECT_FORMAT_ELF */ # 这个后面就是定义__do_global_ctors_aux的内容了


实际堆栈跟踪
~~~~~~~~~~~~~~~~~
**a_constructor**

::

      (gdb) bt
      #0  0x00007ffff7a62bf8 in _IO_puts (str=0x555555400718 <__FUNCTION__.2249> "a_constructor") at ioputs.c:46
      #1  0x000055555540066a in a_constructor () at constructor.c:4
      #2  0x00005555554006dd in __libc_csu_init ()
      #3  0x00007ffff7a03b88 in __libc_start_main (main=0x55555540066d <main>, argc=1, argv=0x7fffffffe388,
      #4  0x000055555540057a in _start ()


反汇编没有__do_global_ctors_aux ，只有 **__do_global_dtors_aux**:

::

      (gdb) bt
      #0  0x0000555555400610 in __do_global_dtors_aux ()
      #1  0x00007ffff7de3d13 in _dl_fini () at dl-fini.c:138
      #2  0x00007ffff7a25161 in __run_exit_handlers (status=0, listp=0x7ffff7dcd718 <__exit_funcs>,
      run_list_atexit=run_list_atexit@entry=true, run_dtors=run_dtors@entry=true) at exit.c:108
      #3  0x00007ffff7a2525a in __GI_exit (status=<optimized out>) at exit.c:139
      #4  0x00007ffff7a03bfe in __libc_start_main (main=0x55555540066d <main>, argc=1, argv=0x7fffffffe388,
      init=<optimized out>, fini=<optimized out>, rtld_fini=<optimized out>, stack_end=0x7fffffffe378)
      at ../csu/libc-start.c:344
      #5  0x000055555540057a in _start ()


::

      #include <stdio.h>
      void __attribute__ ((constructor)) constructor(void) {
            printf("%s\n", __FUNCTION__);
      }

      int main()
      {
            printf("%s\n",__FUNCTION__);
            return 0;
      }



.bss与__do_global_dtors_aux
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__do_global_dtors_aux使用到的一个变量completed.*** 放在.bss。

::

  cat bss.c

  #include <stdio.h>
  int a;
  int b=0;
  int c=1;
  void main(){
      printf("%d %d %d\n", a, b, c);
  }

  bss.o中.bss size=4: a为弱符号,在.common区
  bss.exe中.bss size=12: a、b在.bss,还多了一个变量 completed.***(1B,对齐4B) 。
         0000000000601038 l     O .bss   0000000000000001              completed.7247


::

      若completed.7247 不为 0,则直接返回。
      00000000004004e0 <__do_global_dtors_aux>:
      4004e0:       80 3d 51 0b 20 00 00    cmpb   $0x0,0x200b51(%rip)        # 601038 <__TMC_END__>
      4004e7:       75 17                   jne    400500 <__do_global_dtors_aux+0x20>
      4004e9:       55                      push   %rbp
      4004ea:       48 89 e5                mov    %rsp,%rbp
      4004ed:       e8 7e ff ff ff          callq  400470 <deregister_tm_clones>
      4004f2:       c6 05 3f 0b 20 00 01    movb   $0x1,0x200b3f(%rip)        # 601038 <__TMC_END__>
      4004f9:       5d                      pop    %rbp
      4004fa:       c3                      retq
      4004fb:       0f 1f 44 00 00          nopl   0x0(%rax,%rax,1)
      400500:       c3                      retq
      400501:       0f 1f 44 00 00          nopl   0x0(%rax,%rax,1)
      400506:       66 2e 0f 1f 84 00 00    nopw   %cs:0x0(%rax,%rax,1)
      40050d:       00 00 00



**以下为參考文章的内容：**

get_pc_truck
~~~~~~~~~~~~~~~~~

让位置无关码正常工作。将 **当前地址与GOT之间的偏移值** 存入基址寄存器(%ebp)。


_init
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1. gmon_start : 生成gmon.out，来源于程序分析工具gprof。
2. frame_dummy: initialize exception handling frame。
3. _do_global_ctors_aux: 构造函数

_do_global_ctors_aux
~~~~~~~~~~~~~~~~~~~~~~~
**__do_global_ctors_aux** 遍历 .CTORS section, 
 __do_global_dtors_aux 遍历 .DTORS section包含的destructors functions.


::

      #ifdef OBJECT_FORMAT_ELF
      static void __attribute__((used))
      __do_global_ctors_aux (void)
      {
            func_ptr *p;
            for (p = __CTOR_END__ - 1; *p != (func_ptr) -1; p--)
            (*p) ();
      }

在循环里面调用了用户定义的constructor。


查看环境变量
---------------
设置环境变量LD_SHOW_AUXV=1 ，运行程序即可打印环境变量。

::

      $ LD_SHOW_AUXV=1 ./strcat
      AT_SYSINFO_EHDR: 0x7ffd0712f000
      AT_HWCAP:        f8bfbff
      AT_PAGESZ:       4096
      AT_CLKTCK:       100
      AT_PHDR:         0x56004e000040
      AT_PHENT:        56
      AT_PHNUM:        9
      AT_BASE:         0x7efd65cdc000
      AT_FLAGS:        0x0
      AT_ENTRY:        0x56004e0005f0
      AT_UID:          1000
      AT_EUID:         1000
      AT_GID:          1000
      AT_EGID:         1000
      AT_SECURE:       0
      AT_RANDOM:       0x7ffd070a3a59
      AT_HWCAP2:       0x2
      AT_EXECFN:       ./strcat
      AT_PLATFORM:     x86_64
      abcd!
      16
      
      $ cat strcat.c
      #include <stdio.h>
      #include <string.h>

      int main(){

      char str1[20] = "abcd";
      strcat(str1,"!");
      printf("%s\n",str1);

      printf("%d\n",0x1<<1+3);
      return 0;
      }


完整示例
------------
源码

::

      #include <stdio.h>

      void preinit(int argc, char **argv, char **envp) {
      printf("%s\n", __FUNCTION__);
      }

      void init(int argc, char **argv, char **envp) {
      printf("%s\n", __FUNCTION__);
      }

      void fini() {
      printf("%s\n", __FUNCTION__);
      }

      __attribute__((section(".init_array"))) typeof(init) *__init = init;
      __attribute__((section(".preinit_array"))) typeof(preinit) *__preinit = preinit;
      __attribute__((section(".fini_array"))) typeof(fini) *__fini = fini;

      void  __attribute__ ((constructor)) constructor() {
      printf("%s\n", __FUNCTION__);
      }

      void __attribute__ ((destructor)) destructor() {
      printf("%s\n", __FUNCTION__);
      }

      void my_atexit() {
      printf("%s\n", __FUNCTION__);
      }

      void my_atexit2() {
      printf("%s\n", __FUNCTION__);
      }

      int main() {
      atexit(my_atexit);
      atexit(my_atexit2);
      }

输出：

::

      $ ./hooks
      preinit
      constructor
      init
      my_atexit2
      my_atexit
      fini
      destructor

