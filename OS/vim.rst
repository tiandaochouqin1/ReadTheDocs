==============
Vim
==============

:Date:   2021-06-05 21:29:25


参考资料
==========

1. https://github.com/yianwillis/vimcdoc/releases
2. `vi/vim使用进阶: 目录 <https://blog.easwy.com/archives/advanced-vim-skills-catalog/>`__
3. 《VIM实用技巧第2版》
4. help usr_03.txt
5. help usr_29.txt


定位与编辑
==========

行定位
------------
::

    Ctrl + g
    3G or :3 


    Ctrl+O ：上一个位置
    Ctrl+I/Tab ：下一个位置
    `.  ：上一次编辑所在行
    '.  ：上一次编辑的精确位置


    Ctrl+d/u ：翻半页
    Ctrl+f/b ：翻一页


    { or }  ：移动到段首/段尾 （段落以空行区分）


    zz/zt/zb or M/H/L：移动到屏幕中间/顶部/底部
    nzz      ：第n行移动到中间
    .zz      ：当前行移动到中间

    Ctrl + e/y  ：向下/向上移动一行屏幕

    ma      ：标记位置
    'a      ：移动到标记行
    `a




行内定位
----------
``w/b/e``

``^/$/0``

``f/F + char``：移动到下/上一个char的位置。

``t/T + char``：移动到下/上一个char的前一个位置。

搜索与替换
-----------
正则语法： 括号 ``([{``需要加``\``转义才具有正则含义。

``q\``：搜索历史。
``q:``：命令模式历史。

搜索
~~~~~~
``:noh or :nohlsearch``：关闭搜索高亮。

``/ or ?``：向下/向上搜索。

``/str\c``：忽略大小写。

``* or #``：向下/向上搜索当前单词（精确匹配）。

``g + * or #``：向下/向上搜索当前字符串。

grep
~~~~~

``:grep``：vim封装的grep命令，在当前目录搜索。

``:copen``：在``quickfix``中打开搜索结果。


替换
~~~~~~~
``:5,12s/foo/bar/g``

``:.,12s/foo/bar/g``

``:s/foo/bar/g`` ：当前行内

``.``：当前行。

``%``：当前文件。

``c``：逐个确认。

范围操作
~~~~~~~~~~~
::

    np          ：粘贴n次  
    :3,26 co 28 ：范围复制并粘贴
    3Gy26G28Gp

    y + f + 字符 ：当前位置到字符
    /time回车 y/tutor : 指定字符串范围

    Ctrl + v ：区块模式 I/d/x + Esp


括号
~~~~~~
成对符号的快速操作： ``c/d/y/v + i/a + ' " ( [ { <``

``%``  ：找到行内最近的括号，并左右移动


寄存器
----------

::

    :reg
    "*p         ：外部剪切板
    "+reg+y
    "+reg+p
    Ctrl+R+reg ：在命令模式中粘贴


``q+reg``：记录宏，q停止。

``@+reg``：应用宏。


标签与窗口
===========
标签与分屏可同时存在。

``mksession name.session``：保存会话。

Buffer
---------
``vim a.txt b.txt``、``:E`` 浏览打开的文件都在Buffer里面。

::

    :ls
    :buffer 4    :b4
    :buffer name
    :bnext      缩写 :bn
    :bprevious   缩写 :bp
    :blast  缩写 :bl
    :bfirst 缩写 :bf


标签
--------

``vim -p file1 file2``：多标签打开。

``:Te``：新标签中浏览目录

``:tabe file``：

``:tabn/tabp``or``g/Gt``：移动到下/上一个标签

``:tabs``：

``:tabc``：


分屏
-------
``vim -O/o file1 file2``：垂直/水平多窗口打开。

``Ctrl + W + h/j/k/l``：光标移动。

``:He or :He!``：在上/下浏览目录并打开。

``:Ve or :Ve!``：在左/右浏览目录并打开。

``:set scb / scb!``：同步滚动。



配置与插件
==========

配置文件 ``~/.vimrc``

插件等放到 ``~/.vim``


VIM基本配置
------------

::

    set fileencoding=gb18030

    set fileencodings=utf-8,gb18030,utf-16,big5

    colorscheme  molokai

    " add tab space

    set ts=4

    set softtabstop=4

    set shiftwidth=4

    set expandtab

    set autoindent



cscope
------------

``cscope -Rbkq``

快捷键映射+自动添加数据库：

将以下内容粘贴到.vimrc

https://github.webxp.ml/adah1972/cscope_maps.vim/blob/master/plugin/cscope_maps.vim


``:cs find {querytype} {name}``

其中：

::

  {querytype} 即相对应于实际的cscope行接口数字，同时也相对应于nvi命令：

   0或者s  —— 符号

   1或者g  —— 定义

   2或者d  —— 被这个函数调用的函数（们）

   3或者c  —— 调用这个函数的函数（们）

   4或者t  —— 字符串

   6或者e  —— egrep匹配模式

   7或者f  —— 文件

   8或者i  —— #include这个文件的文件（们）



**自动加载：**

::

    function! LoadCscope()

    let db = findfile("cscope.out", ".;")

    if (!empty(db))

        let path = strpart(db, 0, match(db, "/cscope.out$"))

        set nocscopeverbose " suppress 'duplicate connection' error

        exe "cs add " . db . " " . path

        set cscopeverbose

    " else add the database pointed to by environment variable 

    elseif $CSCOPE_DB != "" 

        cs add $CSCOPE_DB

    endif

    endfunction

    au BufEnter /* call LoadCscope()


或者使用``autoload_cscope.vim``

https://vim.fandom.com/wiki/Autoloading_Cscope_Database



ctags
--------

::

    ctags --languages=c --langmap=c:.c.h --fields=+S -R .


    
**常用快捷键**

::

    Ctrl + ]　or  g + ]　　　 // 跳转到光标所在变量、宏、函数的定义处

    Ctrl + T 　　　　　// 返回到跳转前的位置

    Ctrl + W + ]　　 　// 分割当前窗口，并在新窗口中显示跳转到的定义

    Ctrl + O　　           // 返回之前的位置

    :ts　　　　            // 列出所有匹配的标签

    :ta　　　　            // 查找





**自动使用tags文件：**

::


    " 加入记录系统头文件的标签文件和上层的 tags 文件

    set tags=./tags,../tags,../../tags,../../../tags,../../../../tags,tags,/usr/local/etc/systags

    " 也可使用

    set tags=tags;  

    set autochdir 



自动更新
--------
自动更新影响操作，使用bash快捷别名手动更新。

``alias tagu='ctags -a --languages=c --langmap=c:.c.h --fields=+S -R . && cscope -Rbkq'``



ctags自动更新
~~~~~~~~~~~~~~~

::

    function! RunCtagsForC(root_path)

    " 保存当前目录

    let saved_path = getcwd()

    " 进入到项目根目录

    exe 'lcd ' . a:root_path

    " 执行 ctags；silent 会抑制执行完的确认提示

    silent !ctags --languages=c --langmap=c:.c.h --fields=+S -R .

    " 恢复原先目录

    exe 'lcd ' . saved_path

    endfunction



    " 当 /project/path/ 下文件改动时，更新 tags

    au BufWritePost /project/path/*  call

        \ RunCtagsForC('/project/path')



cscope自动更新
~~~~~~~~~~~~~~~~
参考ctags即可（不包括重连数据库），需要退出vim重新进去才自动重连。

vim可定义自动命令的动作 http://vimdoc.sourceforge.net/htmldoc/autocmd.html

BufWritePost（使用vim进行写入时）是比较合适的触发条件。


