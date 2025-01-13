
==========
AI
==========

AI发展和趋势
==============

pre
-----
1. 2022.11 gtp 3.5;
2. 2023.03 gpt4

2024
-----
`2024 年关于法学硕士 (LLM) 的学习内容  <https://simonwillison.net/2024/Dec/31/llms-in-2024/>`__

1. 2024.5 gpt4o和claude 3.5 sonnet和Gemini 1.5 Pro 均在全球大部分地区免费提供。
2. 2024.12 chatgpt pro推出，支持o1 pro， Sora发布几个月后也对plus用户开放。即将发布的o3单次推理成本达到3000美元。
3. Ai agent还未出现，通用机器人或是下一个AI爆发点。已经开始在部分领域出现杀手锏，特别在搜索（如perplexity）和编码领域（cursor、copilot）
4. 国产模型追赶迅速，不断出现接近chatgpt4o、claude 3.5 sonnet的模型。其中12月的低训练成本的DeepSeek v3表现亮眼
5. openai 年中推出的实时语音和摄像功能强大。
6. 现在已经有70+模型超越gpt-4。 随着模型能力提升，去年盛行的提示词工程已经没人提起
7. GPU: 大厂一面依赖英伟达，一面也都在自研芯片。代工（台积电、英特尔）+设计（博通等等、）
8. 五大大型提供商：微软/Openai、亚马逊、谷歌、Meta、xAI


大模型技术
==========

如何训练一个大模型
------------------
1. 收集数据：需要高质量的数据，覆盖广泛的知识领域，不同语言形式的知识。
2. 数据预处理：数据清洗、去噪声、格式化
3. 分词：即token化
4. 预训练：使得模型能够理解基本的语言结构和基本语义。
5. 微调：基于特定任务的数据集进行微调，以适应特定的应用场景，比如文本处理、问答系统等等
6. 验证、评估模型，和部署发布

如何理解token
--------------
分词是处理文本的关键，有以下几种方式：

1. 基于词典匹配的分词：维护词典，将句子中的字串与词典进行匹配，找到则切分。如正向最大匹配法（南京市/长江/大桥）/逆向最大匹配法（南京、市长/江大桥）。
2. 基于统计的分词方法：基于字与字的共现概率，确定词的边界。对语料质量要求较高。 类比压缩中的哈夫曼编码（基于数据中符号的出现频率构造最优二叉树，频率高的符号分配短编码，频率低的分配长编码）。
3. 基于机器学习的分词方法：通过对大量标注语料的训练，能够有效地处理中文分词中的歧义和未登录词问题，提高分词的准确性。

大模型的推理是逐个token输出的，它能理解一句话的含义吗？

大模型中token的局限性：

1. token是离散的符号，而人类的思维是连续、复杂的；计算机不能真正地理解真实世界（计算机擅长处理离散的向量，工程上使用token较便利）
2. 人是以概念的形式进行思考的，而不是离散的词/token。比如：看到天气好->（马上想到的就是）“适合出去散步”这个概念。

meta最近（202412）提出出以“概念”来训练大模型的方法——对语句进行“概念化”替代原先的“token化”，
LLM的输入输出都是概念，基于概念进行推理，然后使用专门的工具将概念和句子进行转换。

1. 突破符号层面的机械思维，转而在语义空间进行推理生成。
2. 能够有更长的上下文处理。
3. 天然的多语言泛化支持：不同语言对应的概念是同一个。
4. 多模态泛化的支持：文本、语音、图像都是概念，在同一语义空间。


工具网站
===========
1. 在线ps https://www.photopea.com/
2. https://www.16personalities.com/intj-personality
3. `WaytoAGI-通往AGI之路，最好的 AI 知识库和工具站  <https://www.waytoagi.com/>`__
4. `302.AI - 企业级AI应用平台  <https://302.ai/>`__
5. `ToolAI The world's most complete and comprehensive collection of AI artificial intelligence tools  <https://toolai.io/>`__
6. `AI工具集官网 | 1000+ AI工具集合，国内外AI工具集导航大全  <https://ai-bot.cn/>`__


大模型排行：
1. ☆`Chatbot Arena (formerly LMSYS): Free AI Chat to Compare & Test Best AI Chatbots  <https://lmarena.ai/>`__
2. `OpenCompass司南 - 评测榜单  <https://rank.opencompass.org.cn/home>`__
3. `jeinlee1991/chinese-llm-benchmark: 中文大模型能力评测榜单 <https://github.com/jeinlee1991/chinese-llm-benchmark>`__

问gpt4的几个问题
------------------
2024，基本是gpt4水平才能答出来

1. 鲁迅为什么暴打周树人？
2. 树上9只鸟，打掉1只，还剩几只？
3. 孙悟空的妈妈是谁
4. 昨天的当天是明天的什么？
5. 生鱼片是死鱼片


code copilot
----------------
1. tabbnine:可本地
2. github copilot:必须联网，使用困难
3. cursor: 本身是个编辑器

相关行业
-------------


我们不能像ChatGPT一样，只是说出最普通、最自然的的句子，应该想到那些没有人想到过的句子才对。


.. important:: AI 让人思考得更快而不是更聪明。如同计算器


1. 外语
2. 教育
3. 画图
4. 编程

ai agent
-------------
Devin.

cursor是ide里面包了ai，而Devin是ai里面用到了ide。





ChatGPT
============
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
1. api管理： `songquanpeng/one-api: OpenAI 接口管理 & 分发系统  <https://github.com/songquanpeng/one-api>`__
    https://oneapi.838281.xyz/
2. 发卡： `assimon/dujiaoka: 🦄独角数卡(自动售货系统)-开源站长自动化售货解决方案、高效、稳定、快速！🚀🚀🎉🎉  <https://github.com/assimon/dujiaoka>`__
3. 网页前端：https://github.com/ChatGPTNextWeb/ChatGPT-Next-Web


发卡
~~~~~~~
2025.01.11 容器源、apt源各种报错，无法安装软件。

搭建网页前端：
~~~~~~~~~~~~~~~~

1. 购买api。

2. 创建网页
https://github.com/ChatGPTNextWeb/ChatGPT-Next-Web


::

    docker run -d -p 4000:3000 \
    -e OPENAI_API_KEY=sxxx \
    -e CODE=xxx \
    -e BASE_URL=https://kkkc.net/ \
    yidadaa/chatgpt-next-web   




3. 配置域名。先在cloudflare配置dns，然后使用nginx-proxy-manager容器配置代理（能一键配置ssl）
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
两种选择：a. 填写访问密码后，可使用配置好的api；b. 填写自定义网址和api，以使用 自己的api或 第三方网站和api


