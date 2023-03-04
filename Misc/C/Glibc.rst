

glibc
==========

malloc原理
----------
1. https://code.woboq.org/userspace/glibc/malloc/malloc.c.html#1059
2. ☆ `malloc和free的实现原理解析 - JackTang's Blog  <https://jacktang816.github.io/post/mallocandfree/>`__
3. `深入理解glibcmalloc：malloc()与free()原理图解-面包板社区  <https://www.eet-china.com/mp/a108677.html>`__

POSIX 标明了通过malloc( ), calloc( ), 和 realloc( ) 返回的地址对于任何的C类型来说都是对齐的( **16B 对齐** )。

arena bin chunk
~~~~~~~~~~~~~~~~~
**arena -> bin -> chunk。** 

内存以chunk为单位管理。


1. arena: sbrk/mmap分配的堆区。main arena——sbrk/mmap；thread arena——mmap.
2. chunk: allocated/free/top/last remainer chunk。
3. bin: 用于保存free chunk链表表头信息的指针数组。


在bin或top chunk中找到（并分割出）所需内存块，其检索的优先级从高到低分别是：

``fastbinY -> small bins->unsorted bins->large bins->top chunk->sbrk->mmap``

bin
~~~~~~~~~
fastbinsY：用以保存fast bins。（可索引大小16~64B的内存块）

bins：用以保存unsorted、small以及large bins，共计可容纳126个：

    Bin 1 – unsorted bin

    Bin 2 to Bin 63 – small bin(可索引大小<512B的内存块)

    Bin 64 to Bin 126 – large bin（可索引大小≥512B的内存块）


内存释放：

16~64B的内存块会被添加入fastbinY中

samll及large的会添加在bins中的unsorted bins中。

mall bins和large bins中索引的内存块是在内存分配的过程中被添加的。


已分配的trunk
~~~~~~~~~~~~~~~~

::

        /*
          This struct declaration is misleading (but accurate and necessary).
          It declares a "view" into memory allowing access to necessary
          fields at known offsets from a given base. See explanation below.
        */
        struct malloc_chunk {
          INTERNAL_SIZE_T      mchunk_prev_size;  /* Size of previous chunk (if free).  */
          INTERNAL_SIZE_T      mchunk_size;       /* Size in bytes, including overhead. */
          struct malloc_chunk* fd;         /* double links -- used only if free. */
          struct malloc_chunk* bk;
          /* Only used for large blocks: pointer to next larger size.  */
          struct malloc_chunk* fd_nextsize; /* double links -- used only if free. */
          struct malloc_chunk* bk_nextsize;
        };
        /*
           malloc_chunk details:
            (The following includes lightly edited explanations by Colin Plumb.)
            Chunks of memory are maintained using a `boundary tag' method as
            described in e.g., Knuth or Standish.  (See the paper by Paul
            Wilson ftp://ftp.cs.utexas.edu/pub/garbage/allocsrv.ps for a
            survey of such techniques.)  Sizes of free chunks are stored both
            in the front of each chunk and at the end.  This makes
            consolidating fragmented chunks into bigger chunks very fast.  The
            size fields also hold bits representing whether chunks are free or
            in use.
            An allocated chunk looks like this:
            chunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             Size of previous chunk, if unallocated (P clear)  |
                    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             Size of chunk, in bytes                     |A|M|P|
              mem-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             User data starts here...                          .
                    .                                                               .
                    .             (malloc_usable_size() bytes)                      .
                    .                                                               |
        nextchunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             (size of chunk, but used for application data)    |
                    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             Size of next chunk, in bytes                |A|0|1|
                    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            Where "chunk" is the front of the chunk for the purpose of most of
            the malloc code, but "mem" is the pointer that is returned to the
            user.  "Nextchunk" is the beginning of the next contiguous chunk.
            Chunks always begin on even word boundaries, so the mem portion
            (which is returned to the user) is also on an even word boundary, and
            thus at least double-word aligned.
            Free chunks are stored in circular doubly-linked lists, and look like this:
            chunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             Size of previous chunk, if unallocated (P clear)  |
                    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            `head:' |             Size of chunk, in bytes                     |A|0|P|
              mem-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             Forward pointer to next chunk in list             |
                    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             Back pointer to previous chunk in list            |
                    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             Unused space (may be 0 bytes long)                .
                    .                                                               .
                    .                                                               |
        nextchunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
            `foot:' |             Size of chunk, in bytes                           |
                    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                    |             Size of next chunk, in bytes                |A|0|0|
                    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



未分配的trunk则在mem区域保存了 **双向链表指针** ，为list的成员。


分配过程
~~~~~~~~~
1. 使用内存池Arena，fast/small/unsorted bin/large bin 利用的局部性原理。具体分配流程见图；
2. 内存池Arena不够时，申请小内存则使用系统调用sbrk/brk，大内存则mmap(匿名映射只分配内存，无对应文件)。


malloc将内存分成了大小不同的chunk，使用双向链表将其组成成bin。

.. figure:: /images/malloc_sbrk_mmap.png

    malloc_sbrk_mmap


.. figure:: /images/malloc_bin_trunk.jpg

    malloc_bin_trunk


calloc
--------------
1. `Why does calloc exist? — njs blog` <https://vorpus.org/blog/why-does-calloc-exist/>`__

::

    void *malloc(size_t size);

    void *calloc(size_t nmemb, size_t size);


calloc在分配小内存时等价 malloc+memset。

calloc 与 malloc+memset的区别
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. 入参不同。malloc参数size溢出则截断，calloc参数nmemb*size溢出则报错；
2. calloc在分配大内存时效率更高（glibc中>128K为大内存）。

   1) 内核把内存交给进程前会清零，所以calloc不用再清零；(用户态也会管理内存池)
   2) 写时复制，calloc时并未真实分配内存，即在使用时才会 清零+赋值，cache友好。
