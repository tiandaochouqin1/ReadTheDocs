=================
Blog
=================

:Date:   2019-11-24 17:28:53



--------------

Read the Docs
=============

-  `Read the  Docs <https://readthedocs.org/>`__\ 一个在线文档托管服务，可以从各种版本控制系统中导入文档。

-  将项目部署到Github，然后RTD则可自动调用项目中的脚本进行构建并发布。

-  比docsify强大，比markdow移植性强，但VsCode扩展功能少。

本地静态html
------------

::

   make html

参考资料
--------

1. `RST语法 <https://sphinx-doc.readthedocs.io/zh_CN/master/usage/restructuredtext/basics.html>`__

2. `Quick  reStructuredText <https://docutils.sourceforge.io/docs/user/rst/quickref.html>`__

3. `Sphinx 使用手册 -  入门 <https://zh-sphinx-doc.readthedocs.io/en/latest/tutorial.html>`__
   or `Sphinx  使用手册2 <https://sphinx-doc.readthedocs.io/zh_CN/master/usage/quickstart.html>`__

4. `Docutils: Documentation  Utilities <https://docutils.sourceforge.io/rst.html>`__

5. `Sphinx + GitHub + ReadtheDocs  托管文档 <https://www.xncoding.com/2017/01/22/fullstack/readthedoc.html>`__

readthedocs配置
---------------

待补充。

语法
----

1. **列表、代码块等前后均需要空一行。**
2. 会自动忽略空格和回车/换行。空行才是换行。

表格
~~~~

**rst表格需要严格对齐，但是有中文时显示是不对齐的。**\ 在线生成：https://truben.no/table/

缩进
~~~~~
``Literal block expected; none found.restructuredtext``：各行缩进要统一（Tab/Space）。

Section
~~~~~~~~
部分文件的Section title会提示语法错误：``(INFO/1) Enumerated list start value not ordinal-1: "3" (ordinal 3)``


从markdown迁移
--------------

**markdown可移植性太低**\ ，每个工具都有一些自己特定的特性。

1. 特定格式的md表格才可转为rst。
2. 超链接会在空格处换行（不影响最终文档）。

::

   pandoc --standalone --from markdown --to rst src.md  -o  des.rst

图片链接替换：注意文件目录和图片目录等级

::

   <img\s{1,4}src=\"(.*)"\s?alt="?(.*?)"?\s*\w{5,6}=.*$
   ![\2]\(\1\)

::

   无序列表
   ^\s{0,3}\*(?=\s\S)
   \n*

   有序列表
   ^\s{0,3}(?=\w\.\s\S)
   \n

   标题
   ^#
   \n#

由于转义字符、特殊字符*.等转换不兼容，建议将其变成inline code然后转换

兼容markdown
~~~~~~~~~~~~

https://sphinx-doc.readthedocs.io/zh_CN/master/usage/markdown.html

安装Markdown解析器 recommonmark， 并将 recommonmark 添加到
已配置的扩展名列表

::

   pip install --upgrade recommonmark
   extensions = ['recommonmark']

如果要使用除 .md 以外的扩展名的Markdown文件，请调整 source_suffix 变量。
下面的示例配置Sphinx将所有扩展名为 .md 和 .txt 的文件解析为 Markdown:

::

   source_suffix = {
       '.rst': 'restructuredtext',
       '.txt': 'markdown',
       '.md': 'markdown',
   }

其它搭建Blog方法
================

1. 静态托管：如wordpress.com，有免费套餐。\ `Netlify <https://www.netlify.com/>`__\ 。
   `腾讯静态网站托管按量计费 <https://cloud.tencent.com/document/product/1210/43365>`__\ 
   一年\ `不到10  Rmb <https://cloud.tencent.com/act/pro/wh99>`__\ ，支持hexo、VuePress、hugo等。
2. 购买建站主机使用，通常按使用量计费。
3. 购买云服务器，选择wordpress镜像的系统，开箱即用。
4. 使用\ `宝塔 <https://www.aapanel.com/>`__\ 面板，方便的可视化操作。

HUGO
----

``Hexo 是一个博客框架，Hugo 是一个网站框架。``
`Hugo中文文档 <https://www.gohugo.org/doc/tutorials/github-pages-blog/>`__

Hugo 是一个基于 Go 语言开发的静态网站生成器。与目前国内流行的 Hexo
相比，Hugo
的速度可称为飞速🚀——在安装和使用上都是如此。目前有很多知名网站都在使用
Hugo：Netlify、Let’s Encrypt、IPFS、Cloudflare Developers、DigitalOcean
Docs、1Password 等等。

-  毫秒级的页面生成。
-  主题多，集成度高（集成了阅读时间，字数统计，图片预览）,文件的统一管理。

**Hugo 目前存在的问题**

1. Hugo 在传播度上不及 Hexo，相应的搭建教程及 bug 修复上也没有 Hexo
   来的齐全，因此会要求用户有一定的代码能力和 debug 能力。
2. 从 Hexo 迁移到 Hugo 会存在一定的时间成本，因为两者的 markdown
   文件中对于 Front Matter
   的格式定义不同，因此需要修改每篇博文的该部分（当然用脚本去修改是最好的）。
3. Hugo 上面还没有像 Next
   一样完善成熟的主题，但选择也非常多，官网提供了将近 300 个主题。

gitbook
-------

新版不太好用了。

-  新版本的Gitbook不再有桌面编辑器。
-  移除了静态站点生成器，并且不再使用gitbook CLI 来构建文档输出。
-  gitbook-cli 2.3.2已不再维护，但我们仍可以使用

Docsify
-------

`QuickStart <https://docsify.js.org/#/configuration>`__
动态网页生成，即不需要提前将md生成html。

功能简单，适用于\ **知识归类**\ 。

-  各层网站目录需要手动填写。
-  文章第一个标题会被忽略。
-  原githubpages的md文件头无法正常识别（gitbook可以部分识别）。
-  配置仅显示首页后无法直接跳到原来的文档首页/第一页。
-  手机上网页加载时间较长。

notion
------

Notion是一款提供笔记、任务、数据库、看板、维基、日历和提醒等组件的应用程序。
无官方导出功能，\ `第三方导出不够流畅 <https://sspai.com/post/61551>`__

HALO
----

一套独立的博客系统。 Java环境，使用自带的 H2 Database或MYSQL。
https://docs.halo.run/zh/install/config

Github Pages 使用
=================

最完整的githubpages教程:`这可能是迄今为止最全的hexo博客搭建教程 <https://cloud.tencent.com/developer/article/1520557>`__

github图床
----------

1. 使用公共仓库建立。

   ::

      https://raw.githubusercontent.com/username/repository/master/example.jpg
      或
      https://github.comusername/repository/blob/master/example.jpb?raw=true

2. 放到blog项目中。

   ::

      ![](../images/boot.jpg)
      或
      <img  src="../images/boot.jpg" alt=" "width=900   align=center>

   也可放置其它较小的附件等。

图床上传工具
~~~~~~~~~~~~

图床上传工具\ `PicGo <https://github.com/Molunerfinn/PicGo/>`__\ ，使用token绑定。

1. 不能同步删除。
2. 不可预览仓库图片；只能浏览本地已上传图片。
3. 可自定义域名（对于CDN需求）。
4. 自动复制链接到剪切板：https://raw.githubusercontent.com/username/repository/master/example.jpg

域名或链接问题
--------------

用户名不可随意改动
~~~~~~~~~~~~~~~~~~

若改动，则GitHub上的所有项目，均有重新配置路径。

本地预览问题
~~~~~~~~~~~~

1. hexo s命令后，本地Git pages的文章网址路径不正确。可能与路径配置有关。
   (本地操作时，路径更改后可能未及时生效，需重启浏览器等操作)。

2. 将githubpages的网址路径太长，改为根目录名。

文章链接
~~~~~~~~

:post_title.md :title.md

修改GitHub Pages地址
~~~~~~~~~~~~~~~~~~~~

同一仓库只可绑定一个域名，不同仓库可绑定不同域名。

域名使用\ ``CNAME``\ 接入\ ``*.github.io``
，也可查询ip后使用\ ``A记录``\ 。

可启用强制https，域名绑定24小时后此选项可用。

无法开启https
~~~~~~~~~~~~~

未解决。

可能是域名提供商的配置问题，如处于parking状态。\ 
`参考 <https://github.community/t/certificate-request-error-is-persistent-tls-certificate-cant-be-provisioned/11008>`__

进入repository的设置：

1. 将Repository name改为 tiandaochouqin1.github.io ；
2. 选择 GitHub Pages->branch->master， 则网页提示 Your site is published
   at https://tiandaochouqin1.github.io/

若仓库名为test，对应网址为 https://tiandaochouqin1.github.io/test。

部分文章404
~~~~~~~~~~~

::

   404
   File not found

   The site configured at this address does not contain the requested file.

   If this is your site, make sure that the filename case matches the URL.
   For root URLs (like http://example.com/) you must provide an index.html file.

1. 去掉.md文件名中的\ ``-``\ 。（有些包含\ ``-``\ 的文章却能打开）
2. 如果不包含\ ``-``\ ，则更改md文件名。

部署后域名被重置
~~~~~~~~~~~~~~~~

在博客的source目录下），创建一个CNAME文件，填写写自己新的域名，保存成（All
files格式）。

email设置为privacy
------------------

可能导致以下问题

GitHub desktop无法fetch
~~~~~~~~~~~~~~~~~~~~~~~

需要将github desktop中的邮箱设置为
124******+tiandaochouqin1@users.noreply.github.com

hexo d失败
~~~~~~~~~~

修改hexo安装目录下的_config.yml文件，找到Deployment：reop 修改为：

::

   git@github.com:tiandaochouqin1/blog.git

网站统计
--------

1. busuanzi更换域名会重置计数。数据不在自己手中。

2. `百度统计 <https://tongji.baidu.com/web/homepage/index>`__\ 和\ 
   `谷歌分析 <https://analytics.google.com/analytics/web/>`__\ 可获得更为详细的
   访问数据，管理方便。但是会被隐私工具拦截。直接注册添加域名，验证域名即可。

3. `Google搜索分析 <ttps://search.google.com/search-console>`__\ ：查看从Google搜索进入的网站流量。有网站转移工具(使用301定向来验证)。
   \ `站长工具 <http://tool.chinaz.com/pagestatus/>`__\ 查看域名为301状态，但google无法验证。实际访问可正常重定向。

关闭busuanzi：\ ``next_config.yml``

::

   busuanzi_count:
     enable: false

sitemap
~~~~~~~

百度站点地图需要实名。Github Pages禁止了百度爬取。

::

   npm install hexo-generator-sitemap --save     
   npm install hexo-generator-baidu-sitemap --save

会在sources文件夹下生成sitemap.xml、baidu-sitemap.xml

站点config文件加入：

::

   ## hexo sitemap
   sitemap:
     path: sitemap.xml

   baidusitemap:
     path: baidusitemap.xml

Google\ **无法获取站点地图**\ ：
`增加robots.txt <https://zhang0peter.com/2020/03/10/google-error/>`__\ 或
\ `参考 <https://www.cnblogs.com/lfri/p/12219639.html>`__,未解决。

其它
----

博文按时间分类
~~~~~~~~~~~~~~

文章数量逐渐增加，需要分类？

语法错误
--------

1. 卸载hexo,重新安装；
2. 重新下载对应版本的next主题并复制博客和主题的config.yml文件；
3. 复制scalffolds文件夹，不需要复制node_modules;
4. 将post文件夹移动过去（以保持文件创建时间不变）

::

   \node_modules\hexo-tag-bootstrap\input.js:8
   <div class="form-group">
   ^

   SyntaxError: Unexpected token '<'
       at Module._compile (internal/modules/cjs/loader.js:892:18)
       at Object.Module._extensions..js (internal/modules/cjs/loader.js:973:10)
       at Module.load (internal/modules/cjs/loader.js:812:32)
       at Function.Module._load (internal/modules/cjs/loader.js:724:14)
       at Module.require (internal/modules/cjs/loader.js:849:19)
