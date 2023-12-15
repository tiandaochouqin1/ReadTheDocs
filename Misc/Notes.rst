=============
Misc Note
=============
.. important:: 让工具成为思想的延伸。


AI
========
相关行业
-------------


我们不能像ChatGPT一样，只是说出最普通、最自然的的句子，应该想到那些没有人想到过的句子才对。


.. important:: AI 让人思考得更快而不是更聪明。如同计算器


1. 外语
2. 教育
3. 画图
4. 编程

ChatGPT
-----------
插件：

1. ChatGPT Prompt Genius ： 提示语模板
2. ChatGPT Sidebar：侧边栏，可辅助搜索引擎


New Bing: 20230323国内已不能访问

OpenAi API
-------------
1. `Models - OpenAI API  <https://platform.openai.com/docs/models>`__
2. `Examples - OpenAI API  <https://platform.openai.com/examples>`__

搭建gpt网站
--------------

1. 购买api。https://nbfaka.com/ds/
   gpt3.5的api可以直接用；gpt4则需要去第三方网站兑换api，并且使用时要通过第三方网站访问。

2. 创建网页
https://github.com/ChatGPTNextWeb/ChatGPT-Next-Web


::

    docker run -d -p 4000:3000 \
    -e OPENAI_API_KEY=sxxx \
    -e CODE=xxx \
    -e BASE_URL=https://kkkc.net/ \
    yidadaa/chatgpt-next-web   



3. 配置域名。先在cloudflare配置dns，然后使用nginx-proxy-manager容器配置代理
https://github.com/NginxProxyManager/nginx-proxy-manager

docker-compose.yml

::

    version: '3.8'
    services:
    app:
        image: 'jc21/nginx-proxy-manager:latest'
        restart: unless-stopped
        ports:
        - '80:80'
        - '81:81'
        - '443:443'
        volumes:
        - ./data:/data
        - ./letsencrypt:/etc/letsencrypt

4. 访问网站。
两种选择：a. 填写访问密码后，可使用配置好的api；b. 填写自定义网址和api，以使用 自己的ap i或 第三方网站和api

code copilot
----------------
1. tabbnine:可本地
2. github copilot:必须联网，使用困难
3. cursor: 本身是个编辑器

Book
=========


.. important:: 阅读是获取知识的方法，不是最终目的


.. important:: 阅读必须做笔记。


1. 各行业书籍推荐 `Five Books - The Best Books Recommended by Experts  <https://fivebooks.com/>`__
2. `把阅读作为方法：从选书到笔记的经验分享 - 少数派  <https://sspai.com/post/78133>`__

阅读体系构建
-------------
1. `把阅读作为方法：从选书到笔记的经验分享 - 少数派  <https://sspai.com/post/78133>`__

.. important:: 兴趣书单->围绕主题制定年度阅读计划->阅读笔记->管理


1. 从pdf导出comments等 https://github.com/0xabu/pdfannots
2. kindle笔记也很容易导出

ai与读书的意义
-------------------
1. 当前：当 ChatGPT 无法提供来源而且错误率较高的时候，我们需要有足够强的判断力去分辨
2. 未来：(AI 真的能帮我们准确、高效地分析文本内容)。 思考与体验让人独一无二。

.. epigraph::

    因为 AI 不能替代我们去体验和思考，因为我们需要通过思考不让自己被异化。
    人创造了神，却在很长时间一段时间让神主宰人的命运；
    人创造了金钱作为交易的工具，金钱却逐渐成为了评价人的尺度；
    人创造了技术，如果不想再次重蹈覆辙、被自己的创造物所掌控，我们必须要自己去思考。


calibre
-------------
calibre为中心，管理书籍，kindle只放当前读的书。

Readings
--------------
1. 国富论
2. 亲密关系

笔记软件
-------------
1. `迈向笔记终点 - 少数派  <https://sspai.com/post/78322>`__

目前使用的是 evernote + restructure text + archive box

https://page.838281.xyz/NoteApps/

软件:

1. notion:
2. obsidian
3. onenote
4. joplin

文本、markdown？

======
1. coca 12000。
2. book
3. movies words(MuJing)
4. word power made easy 和 merriam web vocabulary builder
5. News: Bypass Paywalls插件 https://www.economist.com/


概念
========
Fiber Chanel
----------------
FC是一套复杂的网络协议，定义了一套完整的网络传输体系。

FC协议的物理层到传输层的逻辑大部分运行在FC适配卡的芯片中，只有小部分关于上层API的逻辑运行与操作系统FC卡驱动程序中。

效率高于Internet协议（tcp/ip以及网卡都跑在cpu上）


时序数据库
--------------
1. `什么是时序数据库？我们为什么需要时序数据库？｜时序数据库 - TDengine - 涛思数据  <https://www.taosdata.com/tdengine/time-series-database/what-is-a-time-series-database>`__

时序数据的特征：

1. 带时间戳
2. 结构化，如日志
3. 流量平稳可预测
4. 不变性，一般是append-only


时序数据库的特征：

1. 支持巨量数据
2. 可实时分析
3. 时间范围查询较多
4. 数据的变化比单点数据更重要

TIPC协议
-----------
1. https://docs.kernel.org/networking/tipc.html
2. `TIPC协议和实现解析_tipc原理-CSDN博客  <https://blog.csdn.net/sy_123a/article/details/107692721>`__

透明进程间通信协议

TIPC针对可信网络环境，减少了建立通信连接的步骤和寻址目标地址的操作 (在TCP/IP协议里, 完成这些操作节点间最少也需要9次包交换, 而使用TIPC则可以减少到2次)。这可以提高节点间信息交换的频率以及减少节点间等待的时间