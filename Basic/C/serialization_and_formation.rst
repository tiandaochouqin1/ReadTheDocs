
Serialize && Format
=======================


序列化工具
-----------
序列化和反序列化 用于解决数据一致性问题(输入数据与输出数据一致)，即 输入数据->网络传输/持久化存储 -> 输出数据。常用于 远程网络传输或持久化存储。

c语言序列化工具：

1. 直接写入文件：使用fwrite/fread
2. 使用xmal或json：将数据结构转换为xml或json格式，然后读写文件；
3. 使用序列化库：protobuf、thrift等

`protobuf-c/protobuf-c: Protocol Buffers implementation in C  <https://github.com/protobuf-c/protobuf-c>`__

cjson
~~~~~~~~~~
1. 看源码的api `cJSON/cJSON.c at master · DaveGamble/cJSON  <https://github.com/DaveGamble/cJSON/blob/master/cJSON.c>`__
2. `cJSON 如何遍历所有对象，获取到未知键名的内容  <https://blog.csdn.net/u011983700/article/details/125334512>`__

cjson实现的内容： AddItem、GetItem、Print

1. 反序列化GetItem：实际为 词法分析器+语法分析器+语义分析器。 cJSON_GetArrayItem、cJSON_GetObjectItem
2. 序列化AddItem：

::

    #include <stdio.h>
    #include "cJSON.h"

    int main() {
        // create a cJSON object
        cJSON *root = cJSON_CreateObject();

        // add some key-value pairs to the object
        cJSON_AddStringToObject(root, "name", "Alice");
        cJSON_AddNumberToObject(root, "age", 25);
        cJSON_AddTrueToObject(root, "is_student");

        // encode the object into a JSON string
        char *json_str = cJSON_Print(root);

        // print the JSON string
        printf("%s\n", json_str);

        // free the cJSON object and the JSON string
        cJSON_Delete(root);
        free(json_str);

        return 0;
    }


    #include <stdio.h>
    #include <stdlib.h>
    #include "cJSON.h"

    int main(int argc, char const *argv[])
    {
        char *json_string = "{\"name\": \"John Doe\", \"age\": 32, \"isMarried\": true}";

        cJSON *root = cJSON_Parse(json_string);

        cJSON *name = cJSON_GetObjectItem(root, "name");
        cJSON *age = cJSON_GetObjectItem(root, "age");
        cJSON *is_married = cJSON_GetObjectItem(root, "isMarried");

        printf("Name: %s", name->valuestring);
        printf("Age: %d", age->valueint);
        printf("Is Married: %s", is_married->valueint ? "true" : "false");

        cJSON_Delete(root);

        return 0;
    }


protobuf
~~~~~~~~~~~
1. https://github.com/protocolbuffers/protobuf 语言无关、平台无关、可扩展的序列化结构数据的方法
2. `protobuf-c的学习总结 - Rabbit_Dale - 博客园  <https://www.cnblogs.com/anker/p/3416541.html>`__


相对xml、json，protobuf的使用多了安装编译程序，从proto配置生成对应语言代码的步骤。 **proto配置定义了结构体信息**。

格式化输入输出与序列化
------------------------
格式化：即str与（bin data+类型)之间的转换， 易存储<-->可读 。也可以了理解为一种序列化。

sprintf和sscanf：用户态和内核通用。



1. 格式化详细见 The C Programming Language 2ed  C7.2/7.4
2. `The Linux Kernel API — The Linux Kernel documentation  <https://www.kernel.org/doc/html/latest/core-api/kernel-api.html#c.vsnprintf>`__

- s: 对象为字符串
- v: 使用va_list参数

::

    int sscanf(const char *buf, const char *fmt, ...)
        
    int vscnprintf(char *buf, size_t size, const char *fmt, va_list args)
    int scnprintf(char *buf, size_t size, const char *fmt, ...)

    scnprintf()和vscnprintf()返回的是写入到buf的字符数
    而snprintf()和vsnprintf()返回的是格式化之后得到字符的长度（可能比size要大）


.. figure:: /images/format_printf.png
   :scale: 100%

   printf格式化


.. figure:: /images/format_printf.png
   :scale: 100%

   scanf格式化
