==============
Vim
==============

:Date:   2021-06-05 21:29:25


参考资料
==========
Doc
-----------


1. `VimDoc <https://yianwillis.github.io/vimcdoc/doc/help.html>`__
2. 《Vim - Vi Improved》 - by Steve Oualline
3. 《VIM实用技巧第2版》
4. help usr_03.txt ：help usr_03.txt



Tutor&CheetSheet
---------------------

1. `vi/vim使用进阶: 目录 <https://blog.easwy.com/archives/advanced-vim-skills-catalog/>`__
2. `Vim 从入门到精通 <https://github.com/wsdjeg/vim-galore-zh_cn>`__ 
3. `CheetSheet <https://vim.rtorr.com/lang/zh_cn>`__

.. figure:: ../images/vim_cheetsheet.png

            vim_cheetsheet


定位与编辑
==========
https://yianwillis.github.io/vimcdoc/doc/change.html


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



    zz/zt/zb ：当前行移动到屏幕中间/顶部/底部
    .zz      ：当前行移动到中间
    nzz      ：第n行移动到中间

    M/H/L    ：光标移动到屏幕中间/顶部/底部

    Ctrl + e/y  ：向下/向上移动一行屏幕

    ma      ：标记位置
    'a      ：移动到标记行
    `a




行内定位
----------
[motion]

``w/b/e``

``^/$/0``

``f/F + char``：移动到下/上一个char的位置。

``t/T + char``：移动到下/上一个char的前一个位置。

``s``: 删除字符并插入
``c{motion}`` : 将 {motion} 跨过的文本删除，并插入


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


标签与会话
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


session
------------
https://blog.easwy.com/archives/advanced-vim-skills-session-file-and-viminfo/

插件相关的信息不会保存.

打开wb[.session]后会自动执行 wbx.vim内的命令。

session中当前行高亮失效，使用此方法解决。

::

    :mksession session.name

    :wviminfo [file]  //viminfo保存了命令历史、缓冲区、寄存器等等

    :rviminfo [file]


代码折叠
------------
https://yianwillis.github.io/vimcdoc/doc/fold.html#fold-commands

配置

::

    ' 基于缩进进行代码折叠
    set foldmethod=syntax
    ' 启动 Vim 时关闭折叠
    set nofoldenable


快捷键：

::

    za //切换折叠与展开

    zc //折叠一层
    zo //展开一层

    zC/O //折叠、展开所有层

    zm //所有代码折叠更多层more
    zr //所有代码展开更多层reduce

    zM/R //所有代码展开/折叠所有层


函数调用关系
---------------
doxygen和graphviz ?



calltree
~~~~~~~~~~~~
:download:`calltree-2.3.tar.bz2 <../files/calltree-2.3.tar.bz2>` 


2004年的软件,需要 `修改编译选项 <https://www.jianshu.com/p/da5086f9f91d>`__ 。

编译
^^^^^

::

    使用gmake（实际就是make）
    cp ./Gmake.linux /usr/bin/Gmake 
    cp RULES/i686-linux-cc.rul RULES/x86_64-linux-cc.rul

    修改与gcc内部关键字冲突的变量
    find . -name "*.[c|h]" |xargs sed -i -e "s/fexecve/fexecve_calltree/"
    find . -name "*.[c|h]" |xargs sed -i -e "s/getline/getline_calltree/"

    make

    拷贝目录到/usr/local/
    cp -rf ./calltree-2.3 /usr/local/
    建立软链接
    ln -s /usr/local/calltree-2.3/calltree/OBJ/x86_64-linux-cc/calltree /bin/calltree


使用
^^^^^^^^^

`calltree看代码调用图 <https://www.cnblogs.com/mylinux/p/6145625.html>`__

::

    设置好（1）想要关心的函数（2）调用深度（3）关心的目录。文件多了查找仍然慢（如5.10内核就要查找很久）
    calltree -np -b  list=start_kernel    depth=3 `find ./init/ ./kernel/ -name "*.c"` > maps

    也可搭配graphviz使用。
    calltree -np -b -dot list=start_kernel ./init/*.c > ~/start_kernel.dot
    dot -T png start_kernel.dot -o ./testhaha.png

配置与插件
==========

配置文件 ``~/.vimrc``

插件等放到 ``~/.vim``

1. tagbar替换taglist;
2. vim-airline\neocomplete


Vim基本配置
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

    " 高亮当前行，可选颜色有限（:h highlight）
    set cursorline
    
    hi CursorLine   cterm=NONE  ctermfg=blue guifg=blue


补全键
~~~~~~~~~~~~~

使用pumvisible()来判断下拉菜单是否显示，如果下拉菜单显示了，键映射为了另一个值。

::


    " mapping

    inoremap <expr> <CR>       pumvisible()?"\<C-Y>":"\<CR>"

    inoremap <expr> <C-J>      pumvisible()?"\<PageDown>\<C-N>\<C-P>":"\<C-X><C-O>"

    inoremap <expr> <C-K>      pumvisible()?"\<PageUp>\<C-P>\<C-N>":"\<C-K>"

    inoremap <expr> <C-U>      pumvisible()?"\<C-E>":"\<C-U>" 


备份文件
~~~~~~~~~

::

    set nobackup       "不生成备份文件 filename~
    
    set noswapfile     "不生成交换文件 .filename.swp
    
    set noundofile     "不生成undo备份 .filename.un~


包管理器
-------------

1. 使用内置包管理器。Vim 8增加了加载原生第三方插件的可能性。可以通过在〜/.vim/pack/foo中存储第三方软件包来使用此功能。
2. 第三方插件管理器。Vundle、Pathogen等。

内置包管理器
~~~~~~~~~~~~~~
没搞成功，无法自动加载。

::

    Loading packages automatically will not happen if loading plugins is disabled,
    see |load-plugins|.



查看文档 :h packages。


`vim8原生内置(naive)插件安装 <https://blog.csdn.net/qq_27825451/article/details/100557133>`__


Vim8 会自动加载 ~/.vim/pack/*/start/

不想自动加载的插件可以放到 opt 目录下 ~/.vim/pack/*/opt
随后在 ~/.vimrc 中使用 packadd 来手动加载插件，有应用场景如下
可以根据某个编译版本来选择使用插件的版本。

::

    if foo_compiler_version > 34
        packadd foo_new
    else
        packadd foo_old
    endif



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

安装： `sudo apt-get install ctags\cscope`
    
**常用快捷键**

::

    Ctrl + ]　or  g + ]　　　 // 跳转到光标所在变量、宏、函数的定义处

    Ctrl + T 　　　　　// 返回到跳转前的位置

    Ctrl + W + ]　　 　// 分割当前窗口，并在新窗口中显示跳转到的定义

    Ctrl + O　　           // 返回之前的位置

    :ts　　　　            // 列出所有匹配的标签

    :ta　　　　            // 查找

    vi –t tag   //查找tag





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



taglist
---------
https://sourceforge.net/projects/vim-taglist/files/

https://blog.easwy.com/archives/advanced-vim-skills-taglist-plugin/


同一session中多个tab打开taglist会出现buffer冲突。


使用下面的命令生成帮助标签（下面的操作在vim中进行）：


``:helptags ~/.vim/doc``

生成帮助标签后，你就可以用下面的命令查看taglist的帮助了：

``:help taglist.txt`` 


::


    """"""""""""""""""""""""""""""

    " Tag list (ctags)

    """"""""""""""""""""""""""""""

    "if MySys() == "windows"                "设定windows系统中ctags程序的位置

    "let Tlist_Ctags_Cmd = 'ctags'

    "elseif MySys() == "linux"              "设定linux系统中ctags程序的位置

    let Tlist_Ctags_Cmd = '/usr/bin/ctags'

    "endif

    let Tlist_Show_One_File = 1            "不同时显示多个文件的tag，只显示当前文件的

    let Tlist_Exit_OnlyWindow = 1          "如果taglist窗口是最后一个窗口，则退出vim

    let Tlist_Use_Right_Window = 1         "在右侧窗口中显示taglist窗口 


    map <silent> <F9> :TlistToggle<cr> 



在taglist窗口中，可以使用下面的快捷键：

::


    <CR>          跳到光标下tag所定义的位置，用鼠标双击此tag功能也一样

    o             在一个新打开的窗口中显示光标下tag

    <Space>       显示光标下tag的原型定义

    u             更新taglist窗口中的tag

    s             更改排序方式，在按名字排序和按出现顺序排序间切换

    x             taglist窗口放大和缩小，方便查看较长的tag

    +             打开一个折叠，同zo

    -             将tag折叠起来，同zc

    *             打开所有的折叠，同zR

    =             将所有tag折叠起来，同zM

    [[            跳到前一个文件

    ]]            跳到后一个文件

    q             关闭taglist窗口

    <F1>          显示帮助 




tagbar
------------------
https://www.vim.org/scripts/script.php?script_id=3465

tagbar+ctrlp 替代taglist

安装：

::

    vim tagbar.vba
    :so %
    :q



配置：

::

     nmap <silent> <F8> :TagbarToggle<CR>        "按F8即可打开tagbar界面
     let g:tagbar_ctags_bin = 'ctags'                       "tagbar以来ctags插件
     let g:tagbar_left = 1                                          "让tagbar在页面左侧显示，默认右边
     let g:tagbar_width = 30                                     "设置tagbar的宽度为30列，默认40
     let g:tagbar_autofocus = 1                                "这是tagbar一打开，光标即在tagbar页面内，默认在vim打开的文件内
     let g:tagbar_sort = 0                                         "设置标签不排序，默认排序



lookupfile
------------
https://www.vim.org/scripts/script.php?script_id=1581

https://blog.easwy.com/archives/advanced-vim-skills-lookupfile-plugin/

支持vim的正则。 开头加\c忽略大小写。

::


    """"""""""""""""""""""""""""""

    " lookupfile setting

    """"""""""""""""""""""""""""""

    let g:LookupFile_MinPatLength = 2               "最少输入2个字符才开始查找

    let g:LookupFile_PreserveLastPattern = 0        "不保存上次查找的字符串

    let g:LookupFile_PreservePatternHistory = 1     "保存查找历史

    let g:LookupFile_AlwaysAcceptFirst = 1          "回车打开第一个匹配项目

    let g:LookupFile_AllowNewFiles = 0              "不允许创建不存在的文件

    if filereadable("./filenametags")                "设置tag文件的名字

    let g:LookupFile_TagExpr = '"./filenametags"'

    endif

    "映射LookupFile为,lk

    nmap <silent> <leader>lk :LUTags<cr>

    "映射LUBufs为,ll

    nmap <silent> <leader>ll :LUBufs<cr>

    "映射LUWalk为,lw

    nmap <silent> <leader>lw :LUWalk<cr>





shell脚本，生成一个文件名tag文件。(ctags文件搜索太慢)

::

    #!/bin/sh

    # generate tag file for lookupfile plugin

    echo -e "!_TAG_FILE_SORTED\t2\t/2=foldcase/" > filenametags

    find . -not -regex '.*\.\(c~\|un~\)' -type f -printf "%f\t%p\t1\n" | \

        sort -f >> filenametags 



需要指定tags路径，否则默认使用ctags文件

::

    :let g:LookupFile_TagExpr = '"./filenametags"'  


问题
=========
E212
-------
E212：无法打开并写入文件 的错误提示。

1. 保存到临时文件 ``:wq ! ~/tmp`` ，更改属主后覆盖原文件。
2. sudo保存 ``: w ! sudo tee %``。