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
```

`string:*` 的函数同时接受列表与二进制（chardata）。注意 `string:pad` 返回**嵌套列表**（iodata），要平面字符串再 `lists:flatten`。

## 9.5 iolist：拼接不复制

```erlang
Deep = ["a", [$b, $c], <<"def">>, [[<<"g">>]]].
iolist_to_binary(Deep).    %% <<"abcdefg">>
iolist_size(Deep).         %% 7（不用扁平化就能算大小）
```

iodata = binary | 0..255 列表 | 任意嵌套。`file:write_file`、`gen_tcp:send`、`io:format` 都吃它——**拼接零复制**，比反复 `++` 高效得多。

## 9.6 坑位清单

1. **`<<"中文">>` 必须写 `/utf8`**：本教程出现频率最高的坑，静态看不出错。
2. **`~s` 打中文抛 badarg**：`~s` 只认 latin1，中文一律 `~ts`（02 章）。
3. **`"abc"` 与 `<<"abc">>` 不相等**：跨表示比较先统一（`unicode:characters_to_binary/list`）。
4. **`length` ≠ `string:length`**：字素簇 vs 码点；emoji（组合字符）场景差得更多。
5. **`string:pad/find/slice` 可能返回嵌套列表**：它们按 iodata 设计，别直接当平面串比较。
6. **`io:get_line` 返回 `eof` 原子**：文件读完不是 `{error,...}` 也不是 `<<>>`，模式匹配记得接住（19 章）。

---
