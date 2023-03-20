
C语言汇编实例
==============

c语言返回值
-----------
1. 返回值保存在eax中，即程序默认会去eax取返回值。
2. void类型函数不能作为整型表达式使用，编译报错 `error: invalid use of void expression`。
3. 使用struct作为返回值，实际是截取了前sizeof(int)字节内容。


struct返回值
~~~~~~~~~~~~~


::

      $ gcc exit_status.c -o exit_status
      $ ./exit_status
      $ echo $?
      8
      $ cat exit_status.c
      #include <stdio.h>
      struct st{

      int a;
      int b;
      };

      struct st main(){

      struct st A={.a=8,.b=2};
      return A;
      }



内联汇编修改eax
~~~~~~~~~~~~~~~~~~
::

      $ gcc add.c -o add
      $ ./add
      7
      666

      $ cat add.c
      #include <stdio.h>

      int add(int a, int b)
      {
            return a + b;
      }

      int asm_compare_one(int a)
      {
      asm volatile("movl $666,%eax");
      }

      int main()
      {
            int a, b;
      a = 2,b=5;
      //      scanf("%d %d", &a, &b);
            printf("%d\n", add(a, b));
            printf("%d\n", asm_compare_one(a));
            return 0;
      }



printf参数寄存器
----------------------
`printf汇编实现 <https://www.zhihu.com/question/383699152>`__

1 Linux 32位平台
~~~~~~~~~~~~~~~~~~~~~~~

::

      char* str = "Hello World!\n"
      void asmprint()
      {
      asm("movl $13, %%edx \n\t"
            "movl  %0,%%ecx \n\t"
            "movl $0,%%ebx \n\t"
            "movl $4,%%eax \n\t"
            "int $0x80  \n\t"
            ::"r"(str));
      }


32位linux内核调用0x80软中断来实现系统调用,

系统调用号4表示系统调用write,用eax寄存器传递，

write有三个参数，用ebx,ecx,edx传递，

其中ebx表示标准输出，这里是控制台，

ecx表示字符串地址，用%0来指定的str字符串“Hello World!”地址,

edx表示字符串长度，这里是13

2 Linux 64位平台
~~~~~~~~~~~~~~~~~~~~~~

::

      char* str = "Hello World!\n"
      void asmprint()
      {
      asm (
            "movq $13, %%rdx \n\t"
            "movq %0, %%rsi  \n\t"
            "movq $1, %%rdi  \n\t"
            "movq $1, %%rax  \n\t"
            "syscall      \n\t"
            ::"r"(str));
      }


64位linux内核使用syscall系统调用。

eax寄存器传递系统调用，1号表示write，，

write有三个参数，用rdi,rsi,rdx传递，

rdi为0表示标准输出

rsi表示字符串地址

rdx表示字符串长度   


注：本章以上内容均为x86。
