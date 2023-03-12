=============
Arm Assembly
=============

:Date:   2021-09-29 19:28:27


1. ☆ 速查表 `ARM64 Assembly Language Notes <https://cit.dixie.edu/cs/2810/arm64-assembly.html>`__     :download:`arm-assembly </files/arm/syshella_arm-assembly.pdf>`
2. ☆ 栈回溯 `A Guide to ARM64 <https://modexp.wordpress.com/2018/10/30/arm64-assembly/#registers>`__
3. ☆指令大全 `ARMv8 A64 Quick Reference <https://courses.cs.washington.edu/courses/cse469/19wi/arm64.pdf>`__
4. https://developer.arm.com/documentation/dui0801/a/Overview-of-AArch64-state/Registers-in-AArch64-state



arm寄存器
============
arm64寄存器
-----------------

.. figure:: /images/armv8_regs.png
   :scale: 70%

   armv8_regs


通用寄存器
~~~~~~~~~~~~~~~
> 9.1.1 Parameters in general-purpose registers
  arm-pg `Cortex-A Series Programmer's Guide for ARMv8-A <https://developer.arm.com/documentation/den0024/a>`__
  :download:`ARMv8-A-Programmer-Guide </files/arm/ARMv8-A-Programmer-Guide.pdf>`

1. x0–x7: function arguments, ``scratch`` (x0 is also function return value)
2. x8–x18: ``scratch`` (x8 is syscall number, x16–x18 sometimes reserved)
3. x19–x28: callee-saved registers (save to stack at beginning of function, restore from stack before returning)
4. **x29: frame pointer**
5. **x30: link register** (save to stack for non-leaf functions)
6. sp: stack pointer
7. pc: The Program Counter (PC) is not a general-purpose register in A64, and it cannot be used with data processing instructions.
8. There is no register named W31 or X31. Depending on the instruction, 
   register 31 is either the stack pointer or the zero register. When used as the stack pointer, you refer to it as SP. 
   W   hen used as the zero register, you refer to it as WZR in a 32-bit context or XZR in a 64-bit context.


.. figure:: /images/abi_general_purpose_registers.png
   :scale: 80%
   :alt: abi_general_purpose_registers



* callee-saved registers: 保存在callee的stack上,并在返回时恢复。
* caller-saved registers: caller在调用subroutine前需保存,因为callee会进行修改且不会恢复。

arm64浮点寄存器
~~~~~~~~~~~~~~~~
1. `ARM Developer Suite Assembler Guide  <https://developer.arm.com/documentation/dui0068/b/Vector-Floating-point-Programming/Floating-point-registers>`__

* 32 single-precision registers, s0 to s31. Each register can contain either a single-precision floating-point value, or a 32-bit integer.

* These 32 registers are also treated as 16 double-precision registers, d0 to d15. dn occupies the same hardware as s(2n) and s(2n+1).


scratch register
~~~~~~~~~~~~~~~~~
1. `abi-aa/aapcs32.rst at 320a56971fdcba282b7001cf4b84abb4fd993131 · ARM-software/abi-aa  <https://github.com/ARM-software/abi-aa/blob/320a56971fdcba282b7001cf4b84abb4fd993131/aapcs32/aapcs32.rst>`__

又名temporary register，保存算术运算中间值(一般不对应程序中的变量)。



arm32汇编和寄存器
~~~~~~~~~~~~~~~~~~
1. `arm asm cheat-sheets <https://cheatography.com/syshella/cheat-sheets/arm-assembly/>`__
2. https://azeria-labs.com/writing-arm-assembly-part-1/



.. figure:: /images/arm_asm.png
      :alt: asm cheetsheet


**常用寄存器：**

accessible in any privilege mode: r0-15.

+----------+----------------------------+-------------------------+
| ARM      | Description                | x86                     |
+==========+============================+=========================+
| R0       | General Purpose            | EAX                     |
+----------+----------------------------+-------------------------+
| R1-R5    | General Purpose            | EBX, ECX, EDX, ESI, EDI |
+----------+----------------------------+-------------------------+
| R6-R10   | General Purpose            | –                       |
+----------+----------------------------+-------------------------+
| R11 (FP) | Frame Pointer              | EBP                     |
+----------+----------------------------+-------------------------+
| R12      | Intra Procedural Call      | –                       |
+----------+----------------------------+-------------------------+
| R13 (SP) | Stack Pointer              | ESP                     |
+----------+----------------------------+-------------------------+
| R14 (LR) | Link Register              | –                       |
+----------+----------------------------+-------------------------+
| R15 (PC) | <- Program Counter /       | EIP                     |
|          | Instruction Pointer ->     |                         |
+----------+----------------------------+-------------------------+
| CPSR     | Current Program State      | EFLAGS                  |
|          | Register/Flags             |                         |
+----------+----------------------------+-------------------------+


CPSR: 对应x86的EFLAGS

arm汇编
=============

aarch64状态与寄存器组
---------------------


In AArch64 state, the following registers are available:

1. 31 64-bit general-purpose registers X0-X30, the bottom halves of which are accessible as W0-W30.
2. 4 stack pointer registers SP_EL0, SP_EL1, SP_EL2, SP_EL3.
3. 3 exception link registers ELR_EL1, ELR_EL2, ELR_EL3.
4. 3 saved program status registers SPSR_EL1, SPSR_EL2, SPSR_EL3.
5. 1 program counter.

arm64指令格式
--------------
``指令方向： 从右向左``

::

   MNEMON­IC{­S}{­con­dition} {Rd}, Operand1, Operand2
   

   MNEMONIC   Descri­ption
   {S}
   An optional suffix. If S is specified, the condition flags are updated on the result of the operation
   
   {condi­tion}
   Condition that is needed to be met in order for the instru­ction to be executed
   
   {Rd}
   Register destin­ation for storing the result of the instru­ction
   
   Operand1
   First operand. Either a register or an inmediate value
   
   Operand2
   Second (flexible) operand. Either an inmediate value (number) or a register with an optional shift
   
   {} - Optional


寻址模式和偏移模式
--------------------
三种 **寻址模式** ：偏移寻址（Offset addressing），前变址寻址（Pre-indexed addressing），后变址寻址（Post-indexed addressing）。

::
      
   偏移寻址

   [Rn, offset]
   最终访问内存的地址 = Rn+offset
   这种操作后Rn的值不会改变

   前变址寻址

   [Rn, offset]!
   最终访问内存的地址 = Rn+offset
   这种操作后Rn的值 = Rn+offset

   后变址寻址

   [Rn], offset
   最终访问内存的地址 = Rn
   这种操作后Rn的值 = Rn+offset


LDR(从左到右，右为目标) 和 STR（从右到左，arm大部分指令的方向） 有三种 **偏移形式**：

::
            
      立即数作为偏移量：ldr r3, [r1, #4]
      寄存器作为偏移量：ldr r3, [r1, r2]

      带有位移操作的寄存器作为偏移量：ldr r3, [r1, r2, LSL#2]


      如果带有!，就是前变址寻址
      ldr r3, [r1, #4]!

      如果基地值寄存器（R1）带中括号，就是后变址寻址
      ldr r3, [r1], #4

      其他的都是带偏移量的寄存器间接寻址
      ldr r3, [r1, #4]



LDM和STM指令，"M"在这里代表Multiple。

1. STM是把多个寄存器的值传送到内存相邻的位置。
2. LDM多个寄存器在ARM汇编语言中用"{}"圈起来，表示待传送的寄存器列表。

arm memory barrier
----------------------
arm-asm 3.37

https://developer.arm.com/documentation/dui0489/c/CIHGHHIE


1. DMB:Data Memory Barrier
2. DSB:Data Synchronization Barrier
3. ISB:Instruction Synchronization Barrier
   
arm64常用汇编指令
----------------------

adrp
~~~~~~~~~~~
1. `Arm A-profile A64 Instruction Set Architecture  <https://developer.arm.com/documentation/ddi0602/2022-03/Base-Instructions/ADRP--Form-PC-relative-address-to-4KB-page->`__

``ADRP <Xd>, <label>`` : 加载4k对齐的地址到寄存器。

adds an immediate value that is shifted left by 12 bits, to the PC value to form a PC-relative address,
 with the bottom 12 bits masked out, and writes the result to the destination register.



::

   imm = SignExtend(immhi:immlo:Zeros(12), 64);

   bits(64) base = PC[];
   if page then
      base<11:0> = Zeros(12);
   X[d] = base + imm;


x86与arm函数调用规约
=======================
1. `[原创]常见函数调用约定(x86、x64、arm、arm64) <https://bbs.pediy.com/thread-224583.htm>`__，主要是windows
2. `GCC的调用约定 <https://blog.csdn.net/weixin_44395686/article/details/105036297>`__
3. `system V ABI <https://blog.csdn.net/weixin_44395686/article/details/105022059>`__
4. `ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/AArch64-Floating-point-and-NEON/NEON-and-Floating-Point-architecture/Floating-point-parameters>`__


X86 函数调用规约
--------------------
1. X86 有三种常用调用约定，cdecl(C规范)/stdcall(WinAPI默认)/fastcall 函数调用约定。

   1. cdecl 函数调用约定

   参数从右往左一次入栈，调用者实现栈平衡，返回值存放在 EAX 中。允许了变长入参如printf
   GCC的默认调用约定为cdecl

   2. stdcall 函数调用约定

   参数从右往左一次入栈，被调用者实现栈平衡，返回值存放在 EAX 中。

   3. fastcall 函数调用约定

   参数1、参数2分别保存在 ECX、EDX ，剩下的参数从右往左一次入栈，被调用者实现栈平衡，返回值存放在 EAX 中。

2. X86-64

x64的调用约定只有一种，遵守system v ABI的规范。但是Linux和windows却有一些差别。
 
   1. 在windows X64中，前4个参数通过rcx，rdx，r8，r9来传递；
   2. 在Linux上，则是前6个参数通过rdi，rsi，rdx，rcx，r8，r9传递。
   3. 其余的参数按照从右向左的顺序压栈。

若入参、返回值为浮点型，则会对应使用浮点寄存器，可与整型寄存器一起使用。

ARM和ARM64函数调用规约
---------------------------
使用的是ATPCS(ARM-Thumb Procedure Call Standard/ARM-Thumb过程调用标准)的函数调用约定。

1. ARM：参数1~参数4 分别保存到 R0~R3 寄存器中 ，剩下的参数从右往左一次入栈，被调用者实现栈平衡，返回值存放在 R0 中。
2. ARM64：参数1~参数8 分别保存到 X0~X7 寄存器中 ，剩下的参数从右往左一次入栈，被调用者实现栈平衡，返回值存放在 X0 中。

浮点型
~~~~~~~~
1. `ARM Cortex-A Series Programmer's Guide for ARMv8-A  <https://developer.arm.com/documentation/den0024/a/AArch64-Floating-point-and-NEON/NEON-and-Floating-Point-architecture/Floating-point-parameters>`__

* the floating-point parameters are passed in the floating-point H, S or D registers and other parameters are passed in integer X or W registers.
* Both integer (general-purpose) and floating-point registers can be used at the same time. 


aarch64堆栈
==================
1. Many CPU instructions automatically update esp as a side effect, ebp is mostly maintained by program code with little CPU interference. 
   一些cpu指令会自动更新esp(push、call)，ebp则是由代码显式维护。
   `journey-to-the-stack <https://manybutfinite.com/post/journey-to-the-stack/>`__

2. ☆ `ARM64 Assembly Language Notes  <https://cit.dixie.edu/cs/2810/arm64-assembly.html>`__
3. `Releases · ARM-software/abi-aa  <https://github.com/ARM-software/abi-aa/releases>`__ ; Procedure Call、Elf等内容。


重点概念
---------
1. **栈帧16Bytes对齐。** 
2. **变量所占空间与其类型一致，使用对应宽度的寄存器保存。**

aarch64函数调用Stack
----------------------
1. 由x29保存的fp `递归串起来` —— ``本层fp起始地址中保存着上层caller fp的地址``。

2. fp+8则为 link returnd地址，该地址addr2line可得出对应函数。

3. dump出来的stack memory通常按地址增长方向显示。

栈帧的保存与恢复
~~~~~~~~~~~~~~~~~
栈帧地址=栈顶地址=入栈的最后一个元素的地址

::

   /* 函数调用，会将bl的下一条指令保存到x30
   bl func

   -->

   /* 保存x29到sp -> 保存x30到sp+4 -> sp=sp-32
   stp    x29, x30, [sp, #-32]!
   /* 将新栈地址保存到x29。当前x29的值为旧x29被保存到栈的地址
   mov    x29, sp
   ......

   /* 恢复
   ldp     x29, x30, [sp], #32
   ret



Load and store pair 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1. `Learn the architecture: AArch64 Instruction Set Architecture  <https://developer.arm.com/documentation/102374/0101/Loads-and-stores---load-pair-and-store-pair>`__


often used for pushing, and popping off the stack. 

::
      
   This first instruction pushes X0 and X1 onto the stack:
   STP        X0, X1, [SP, #-16]!

   This second instruction pops X0 and X1 from the stack:
   LDP        X0, X1, [SP], #16

   Remember that in AArch64 the stack-pointer must be 128-bit aligned.



栈帧视图
~~~~~~~~~~~~
::

        |                      |
        | caller's stack frame |     bigger addr
        |                      |     
        +----------------------+
        | saved return address |  +8   // x30,lr
        +----------------------+
   fp-->| saved frame pointer  |   0   // x29,fp(栈保存的sp)
        +----------------------+
        | saved x22            |  -8
        +----------------------+
        | saved x21            |  -16
        +----------------------+
        | saved x20            |  -24
        +----------------------+
   sp-->| saved x19            |  -32
        +----------------------+


frame-pointer
--------------
需要显示指定gcc编译选项 ``--fno-omit-frame-pointer`` , 编译时会使用专门的寄存器保存fp。

默认为 ``--fomit-frame-pointer`` ， 若函数本身不需要使用fp则不保存，以减少elf体积，不占用专门的reg，影响debug。

For AArch64, the register is ``X29``. This is reserved for the stack frame pointer when the option is set. (Otherwise, it can be used for other purposes.) 

::

   ffffff80080851b8 <arch_align_stack>:
   ffffff80080851b8: a9be7bfd stp x29, x30, [sp, #-16]!
   ffffff80080851bc: 910003fd mov x29, sp


Here, so-called indirect addressing with pre-increment where the stack pointer (SP) is decreased by 32 at the beginning and then x29, x30 are sequentially saved in the memory by the value obtained in the first instruction.

Usually, the function finishes as follows:

::
      
   ffffff80080851fc: a8c27bfd ldp x29, x30, [sp], #32
   ffffff8008085200: d65f03c0 ret


The indirect addressing with the post-increment where the saved values x29, x30, are taken from the memory on the stack pointer (SP) and then SP increases by 32. 
The code examples above are called the prologue and epilogue of the function respectively. 

Linux on AArch64 is compiled with that flag so that stack frames look like regular code (except assembly code).
