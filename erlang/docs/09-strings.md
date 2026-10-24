# 09 · 字符串与 Unicode

> 对应示例：`examples/09_strings/`

## 9.1 字符串就是整数列表

```erlang
"abc" =:= [97, 98, 99].    %% true —— 没有专门的字符串类型
[$a, $b, $c].              %% "abc"；$x 取字符码点（$中 = 20013）
[C + 1 || C <- "abc"].     %% "bcd"：列表推导直接处理字符串
```

好处：全部列表函数都能用；代价：一个字符一个机器字，**大量文本请用二进制** `<<"abc">>`（但 `"abc" =/= <<"abc">>`，它们是两种东西）。

## 9.2 头号编码坑：`<<"中文">>` 被 latin1 截断

```erlang
<<"中">>.           %% <<45>> —— 码点 20013 被截成 20013 rem 256 = 45
<<"中"/utf8>>.      %% 三字节 UTF-8 —— 正确写法
```

**二进制字面量里的字符串默认按 latin1 编码**——不报错、静默截断，下游解码才以奇怪的方式炸（`unicode:characters_to_list(<<"中文">>)` 返回 `{error,"-",<<135>>}`）。同样：`list_to_binary([$中])` 抛 badarg，要转二进制用 `unicode:characters_to_binary([$中])`。

## 9.3 三个"长度"

| 函数 | 数的是什么 | `"中文"`（UTF-8 二进制）|
|---|---|---|
| `length/1` | 码点 | 2 |
| `byte_size/1` | 字节 | 6 |
| `string:length/1` | **字素簇** | 2 |

`e` + 组合重音符（U+0301）是两个码点、**一个字素簇**——`length` 得 2、`string:length` 得 1。面向用户的截断/计数用 `string:*`。

## 9.4 string 模块（chardata 通吃）

```erlang
string:split("a,b,c", ",", all).     %% ["a","b","c"]
string:lexemes("a,,b", ",").         %% ["a","b"]：连续分隔符当一个
string:trim("  x  ").                %% "x"
string:to_integer("42x").            %% {42,"x"}——失败返回 {error,no_integer} 不抛
string:replace("a-b-c", "-", "+").         %% ["a","+","b-c"]：默认只换第一处
string:replace("a-b-c", "-", "+", all).    %% ["a","+","b","+","c"]：全换
```

`string:*` 的函数同时接受列表与二进制（chardata）。注意 `string:pad` 返回**嵌套列表**（iodata），要平面字符串再 `lists:flatten`。

`string:replace/3,4`（OTP 20）也是 iodata 派：上面两个结果都是嵌套列表，要平面二进制得 `unicode:characters_to_binary(string:replace("a-b-c", "-", "+", all))` → `<<"a+b+c">>`。第四参控制替换方向——`leading`（默认）只换第一处、`all` 全换、`trailing` 只换**最后一处**（`string:replace("a-b-c", "-", "+", trailing)` 得 `["a-b","+","c"]`）。想换掉所有出现记得显式写 `all`。

## 9.5 iolist：拼接不复制

```erlang
Deep = ["a", [$b, $c], <<"def">>, [[<<"g">>]]].
iolist_to_binary(Deep).    %% <<"abcdefg">>
iolist_size(Deep).         %% 7（不用扁平化就能算大小）
```

iodata = binary | 0..255 列表 | 任意嵌套。`file:write_file`、`gen_tcp:send`、`io:format` 都吃它——**拼接零复制**，比反复 `++` 高效得多。

## 9.6 三引号字符串：多行文本不用转义

写多行文本（SQL、HTML 模板、给用户看的说明）时，普通字符串得给每行补 `\n`、把每个 `"` 写成 `\"`。三引号字符串（OTP 27 起）解决了这个痛点——它**逐字**（verbatim）：引号和反斜杠都不再特殊，换行就是换行。实测：

```erlang
Doc = """
第一行，可以直接写 "引号"
第二行：反斜杠 \n 不会被转义
""",
%% ==> "第一行，可以直接写 \"引号\"\n第二行：反斜杠 \\n 不会被转义\n"
%% 注意：这里的 \" 和 \\ 是普通字符串的转义写法；Doc 里它们都是字面字符
```

三条规则把它讲透：

1. **开引号行不能有别的内容**：`"""` 之后只允许空白，正文从下一行开始；
2. **缩进由收尾行的 `"""` 决定**：收尾 `"""` 前面有多少空白，就从**每一条内容行**前面删掉多少。把收尾 `"""` 对齐到代码缩进，内容就自动左对齐；
3. **首行与末行的换行不算内容**：开引号行的换行、以及收尾行前那一行的换行都被吃掉；中间内容行的换行保留。

内容行相对收尾缩进的**额外**缩进会被保留——正好用来表达嵌套结构：

```erlang
Code = """
   f() ->
       ok.
   """,
%% ==> "f() ->\n    ok."   收尾前 3 个空格被统一删掉，ok. 多出的 4 个保留
```

想在内容里写一整行 `"""`？把定界符加长即可——用 5 个引号定界，内容里就能放 4 个引号：

```erlang
"""""
""""
"""""
%% ==> "\"\"\"\""（4 个引号）
```

**注意**：OTP 27 之前 `"""` 被读作 `"" "`（空串接后面的串），含义不同。所以老代码里成排的引号升级后可能变味——见下一节的相邻字面量规则。

## 9.7 sigil：给字符串字面量加前缀

*Sigil*（符文）是 `~` 开头、紧跟一个字母的字面量前缀，用来改变字符串的**类型**与**转义**处理。OTP 27 起可用，编译器只认四个字母，分工明确：

| sigil | 结果类型 | 转义处理 |
|---|---|---|
| `~b` | 二进制（UTF-8） | **解释** `\t`、`\n` 等转义 |
| `~B` | 二进制（UTF-8） | **逐字**，反斜杠原样保留 |
| `~s` | 字符串（列表） | **解释**转义 |
| `~S` | 字符串（列表） | **逐字**，反斜杠原样保留 |

规律一句话：**小写解释转义，大写逐字**（`B`/`S` 是"绝不转义"的那个）。实测对照：

```erlang
~b"abc\txyz".   %% <<"abc\txyz">>   = <<97,98,99,9,120,121,122>>  制表符进来了
~B"abc\txyz".   %% <<"abc\\txyz">>  = <<97,98,99,92,116,...>>    反斜杠+t 原样保留
~s"abc\txyz".   %% "abc\txyz"（列表，含制表符）
~S"abc\txyz".   %% "abc\\txyz"（列表，含反斜杠）
```

引号里不方便放某个字符时，sigil 还能**换定界符**——成对用 `() [] {} <>`，或对称地用 `/ | ' " \` #`：

```erlang
~s/含有 "双引号" 的串/.    %% 用 / 定界，串里就不用写 \"
~B[UTF-8 二进制：中文].    %% <<228,184,173,230,150,135>>——直接得到 UTF-8 字节
```

`~B[...]` 是 `<<"..."/utf8>>` 的简洁写法，专治 9.2 的 latin1 截断坑：**要 UTF-8 二进制又不想记 `/utf8`，用 `~B`**。

还有**不带字母的默认 sigil** `~"..."`：它产出一个二进制，是否解释转义取决于后面接的形式——内联字符串解释转义，三引号不解释。可以把它理解为"无脑把普通字符串变成二进制"：

```erlang
~"abc\ndef".    %% <<"abc\ndef">>，与 <<"abc\ndef">> 同义
```

## 9.8 相邻字面量：中间必须有空白

**相邻的两个字符串字面量会被编译期拼接**，这是跨行写长串的老办法：

```erlang
S = "abc" "def".      %% "abcdef"
```

但 **OTP 27 起，相邻字面量之间必须留空白**，否则是语法错：

```erlang
S = "abc""def".   %% ✘ error: adjacent string literals without intervening white space
```

这条规则是为了和三引号消歧（`"""` 曾经被读作 `"" "`）。结论：**永远在两个串之间留一个空格**，别写贴在一起的引号。

## 9.9 源码编码：默认 UTF-8

Erlang 源文件默认按 **UTF-8** 解析，所以字符串里的中文可以直接写（`"中文"` 是合法的源码文本）。编码可以在**文件前两行**用注释声明，取第一个匹配 `coding\s*[:=]\s*([-a-zA-Z0-9])+` 的串；合法值只有 `Latin-1` 与 `UTF-8`（大小写随意），非法值忽略：

```erlang
%% -*- coding: latin-1 -*-
```

两条纪律：① 默认就是 UTF-8（OTP 17 起从 Latin-1 改的），日常文件**不需要**这条注释；② 注意区分"源码编码"和"字符串在运行期的表示"——源文件是 UTF-8，但 `<<"中">>` 默认仍按 latin1 截断（9.2），两者是两回事。

## 9.10 uri_string：解析与构造 URI（OTP 21）

HTTP 客户端、回调地址、配置里的连接串——碰到 URI 就别手写正则，`uri_string` 模块（OTP 21 起）把解析、重组、规整、百分号编码全包了。

**解析**用 `uri_string:parse/1`，返回一个 map，**只包含 URI 里真实出现过的部件**：

```erlang
uri_string:parse("https://user@example.com:8443/a/b?x=1#frag").
%% #{scheme => "https", userinfo => "user", host => "example.com",
%%   port => 8443, path => "/a/b", query => "x=1", fragment => "frag"}
```

候选键共七个：`scheme`、`userinfo`、`host`、`port`、`path`、`query`、`fragment`。注意 `port` 是**整数**，其余是字符串。因为没出现的部件不进 map，取可选项要给默认值：

```erlang
uri_string:parse("https://example.com/").
%% #{scheme => "https", host => "example.com", path => "/"}——没有 port 键
maps:get(port, uri_string:parse("https://example.com/"), 443).   %% 443
```

非法输入不抛异常，返回**三元组** `{error, Reason, Rest}`：

```erlang
uri_string:parse("http://h/p?a=b c").     %% 含空格
%% {error, invalid_uri, ":"}
```

**重组**用 `uri_string:recompose/1` 把部件 map 拼回 URI 字符串——函数名是 `recompose`，不是 `compose`，别记错：

```erlang
uri_string:recompose(#{scheme => "https", host => "example.com", path => "/a"}).
%% "https://example.com/a"
```

**规整**用 `uri_string:normalize/1`：scheme 和 host 转小写、默认端口去掉、能解码的百分号编码解码。比较两个 URI 是否等价之前先 normalize：

```erlang
uri_string:normalize("HTTP://Example.COM:80/%7euser").
%% "http://example.com/~user"
```

最后，`uri_string:quote/1` 与 `uri_string:unquote/1` 做百分号编解码——往 query 里拼用户输入时先 quote：

```erlang
uri_string:quote("a b").        %% "a%20b"
uri_string:unquote("a%20b").    %% "a b"
```

## 9.11 坑位清单

1. **`<<"中文">>` 必须写 `/utf8`**：本教程出现频率最高的坑，静态看不出错。
2. **`~s` 打中文抛 badarg**：`~s` 只认 latin1，中文一律 `~ts`（02 章）。
3. **`"abc"` 与 `<<"abc">>` 不相等**：跨表示比较先统一（`unicode:characters_to_binary/list`）。
4. **`length` ≠ `string:length`**：字素簇 vs 码点；emoji（组合字符）场景差得更多。
5. **`string:pad/find/slice` 可能返回嵌套列表**：它们按 iodata 设计，别直接当平面串比较。
6. **`io:get_line` 返回 `eof` 原子**：文件读完不是 `{error,...}` 也不是 `<<>>`，模式匹配记得接住（19 章）。
7. **三引号字符串是逐字的**：`"""` 里的 `\n` 是"反斜杠 + n"两个字符，不是换行；要真换行就直接在源码里回车（9.6）。
8. **sigil 小写解释、大写逐字**：`~b`/`~s` 会处理 `\t`、`\n` 转义，`~B`/`~S` 原样保留反斜杠——别把 `~B` 当成"更强的 `~b`"（9.7）。
9. **相邻字面量之间必须留空白**：`"a" "b"` 合法（编译期拼成 `"ab"`），`"a""b"` 是语法错（9.8，OTP 27 起）。
10. **源码编码默认 UTF-8**：`coding` 注释只认前两行、只认 `Latin-1`/`UTF-8`；它管的是**源码文本怎么读**，跟运行时 `<<"中">>` 的 latin1 截断（9.2）完全无关。
11. **`string:replace` 返回 iodata 且默认只换第一处**：要平面串记得 `unicode:characters_to_binary`，要全换记得显式写 `all`（9.4）。
12. **`uri_string:parse` 的 map 键不全**：没出现的部件不进 map，取 `port` 用 `maps:get/3` 带默认值；非法 URI 返回 `{error, Reason, Rest}` 三元组，不抛异常（9.10）。

---

---

上一章：[08 二进制与位语法](08-binaries.md) · 下一章：[10 映射与记录](10-maps.md)
