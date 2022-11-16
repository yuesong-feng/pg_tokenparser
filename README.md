# PostgreSQL自定义文本检索分词规则

PostgreSQL的倒排索引十分强大，虽然为文本检索设计，但也可以移植到其他用途。

有如下数据表，其中`tagset`是一系列`tag`的集合：

|id|tagset|
|-|-|
|1001|"tag_01 tag_02 tag_05"|
|1024|"tag_02 tag_04 tag_06"|
|1032|"tag_03 tag_05 tag_06"|

要通过`id`找到`tagset`，可以直接使用普通B+树索引。但要是想高效地通过`tag`来找到所有的`id`呢？

例如，通过`tag_05`快速找到`id` 1001和1032，通过`tag_02 AND tag_05`快速找到`id` 1001，通过`tag_02 OR tag_04`快速找到`id` 1001和1024。

B+树索引无法完成这个功能，直接写SQL查询（`LIKE`语句）将会特别复杂、特别慢。而文本搜索+倒排索引可以实现这个快速查找的功能。

主要思路为，先将`tagset`转化为`ts_vector`，然后将查询转化为`ts_query`，使用文本匹配的方式来查询对应的`id`，并建立倒排索引加速查询。

此时又遇到了问题，将`tagset`转化为`ts_vector`需要经过分词器转化为token，然后经过一系列字典过滤掉无关信息、转化为lexeme。由于是为文本检索而设计，所以默认的分词规则和字典都是按照自然语言的规则来实现。要实现自己的功能，必须自定义文本检索配置。

`CREATE TEXT SEARCH [CONFIGURATION|DICTIONARY|PARSER|TEMPLATE]`

PostgreSQL提供了丰富的字典自定义方法，可以很轻松地对字典的规则进行自定义。而对于分词规则，PostgreSQL只有一套分词逻辑，在源码`src/backend/tsearch/wparser_def.c`中实现，官方文档写明适用于绝大部分文本。但对于以上需求，已经不是文本检索，而是为了使用文本检索+倒排索引实现自己的查询需求，所以分词器也需要自定义。

对于`tagset`，分割为`tag`的时候，如果使用默认的分词规则，极有可能遇到将一个`tag`继续拆分、或者多个`tag`不拆分的错误，也就是没有按照我们想要的规则进行分词。如：

```sql
yuesong=# SELECT to_tsvector('token_01 tagset-02 tagset03 token:04');
                        to_tsvector                        
-----------------------------------------------------------
 '-02':4 '01':2 '04':7 'tagset':3 'tagset03':5 'token':1,6
(1 row)

yuesong=# SELECT alias, description, token FROM ts_debug('token_01 tagset-02 tagset03 token:04');
   alias   |       description        |  token   
-----------+--------------------------+----------
 asciiword | Word, all ASCII          | token
 blank     | Space symbols            | _
 uint      | Unsigned integer         | 01
 blank     | Space symbols            |  
 asciiword | Word, all ASCII          | tagset
 int       | Signed integer           | -02
 blank     | Space symbols            |  
 numword   | Word, letters and digits | tagset03
 blank     | Space symbols            |  
 asciiword | Word, all ASCII          | token
 blank     | Space symbols            | :
 uint      | Unsigned integer         | 04
(12 rows)
```

我们希望按空格拆分成4个`tag`，而默认的分词规则进行了胡乱拆分，将`_`、`:`当成了分隔符，将`-`处理成了负号。

接下来自定义一个分词器，实现自定义规则拆分token的功能。如果直接改动默认分词规则`src/backend/tsearch/wparser_def.c`，将会影响到正常文本检索的分词逻辑，所以使用插件的方式新增一个分词规则。

PostgreSQL自定义分词规则的语法为：

```sql
CREATE TEXT SEARCH PARSER name (
    START = start_function ,
    GETTOKEN = gettoken_function ,
    END = end_function ,
    LEXTYPES = lextypes_function
    [, HEADLINE = headline_function ]
)
```

我们需要在插件中实现四个函数，分别为`START`, `GETTOKEN`, `END`, `LEXTYPES`。

编译、安装插件后，我们就可以使用我们自定义的分词规则：

```sql
yuesong=# SELECT alias, description, token FROM ts_debug('my_parser', 'token_01 tagset-02 tagset03 token:04');
 alias |  description  |   token   
-------+---------------+-----------
 word  | Word          | token_01
 blank | Space symbols |  
 word  | Word          | tagset-02
 blank | Space symbols |  
 word  | Word          | tagset03
 blank | Space symbols |  
 word  | Word          | token:04
(7 rows)

yuesong=# SELECT to_tsvector('my_parser', 'token_01 tagset-02 tagset03 token:04');
                     to_tsvector                      
------------------------------------------------------
 'tagset-02':2 'tagset03':3 'token:04':4 'token_01':1
(1 row)
```

可以看到`tagset`按照我们的要求被分成了四个`tag`，仅使用了空格作为token的分割符，所有token都是一种类型，完成了需求。对于分割符、分词规则、类型，都可以根据需求自定义。
