# 19 · 文件 I/O 与序列化

> 对应示例：`examples/19_files/`（临时目录固定在 `build/erl-demo-19/`，跑完自清）

## 19.1 三层模型

`filename`（拼路径）→ `file`（字节）→ `io`（字符/行）。路径一律 `filename:join/1`（Windows 分隔符自动处理，手拼 `"a" ++ "/" ++ "b"` 就错了）：

```erlang
filename:join([Dir, "b.txt"]).    filename:basename/1.  filename:extension/1.
filename:join("/a/b", "/c/d").    %% 第二段是绝对路径 → 整体替换成 "/c/d"
```

## 19.2 一次性读写与 iodata

```erlang
file:write_file(F, <<"hello">>).        %% ok | {error, Reason}——可预期失败返回元组不抛
file:read_file(F).                      %% {ok, Binary}；文件不存在 {error, enoent}
file:write_file(F, More, [append]).     %% 不加 append 会截断！
filelib:ensure_dir("/x/y/f.txt").       %% 名字骗人：只建**目录**不建文件
```

iodata（binary | 字节列表 | 任意嵌套）写入零拷贝；`iolist_size` 不拼起来就能算长度。

## 19.3 头号编码坑：write_file 吃字节不吃字符串

```erlang
file:write_file(F, "你好").     %% {error, badarg}——码点 > 255（返回元组，不抛）
file:write_file(F, <<"你好"/utf8>>).            %% ✔
file:write_file(F, unicode:characters_to_binary("你好")).  %% ✔
```

`write_file/3` **不接受** `{encoding, utf8}` 选项（静默忽略、不报错）；要运行时做编码走 `file:open + {encoding, utf8} + io:put_chars`。latin1 设备上 `io:put_chars("你好")` 抛 `no_translation`。

## 19.4 流式与按行

```erlang
{ok, Fd} = file:open(F, [read, binary]).
file:read(Fd, 3).        %% {ok, Bin}；超过长度给**剩下的**（不是 eof）；再读才是 eof
file:position(Fd, {bof, 1}). / file:pread(Fd, 0, 2).
ok = file:close(Fd).
file:read(Fd, 1).        %% {error, terminated}——句柄一次性
```

> 实测平台差异：**Windows/OTP 29 上 `pread` 会移动当前偏移**（macOS 上不动）——别依赖 pread 保持位置。

按行读用 io 协议：`file:open(F, [read, {encoding, utf8}])` + `io:get_line(Fd, "")`——**末尾返回 `eof` 原子**（不是空串）；不开 encoding 按 latin1 读，UTF-8 中文变成一串单字节字符。`raw` 模式快但不支持 io 协议（`io:get_line` 直接 badarg）。

## 19.5 file:consult：Erlang 项当配置

```erlang
ok = file:write_file(F, [io_lib:format("~p.~n", [T]) || T <- [{port, 8080}]]).
{ok, [{port, 8080}]} = file:consult(F).   %% 坏文件返回 {error, {N, 解析器原因}}
```

## 19.6 二进制协议：编解码对称

```erlang
encode(Ver, Type, Payload) ->
    <<16#45, 16#52, Ver:8, Type:8, (byte_size(Payload)):16/big,
      Payload/binary, (erlang:crc32(Payload)):32/big>>.
decode(<<16#45, 16#52, Ver:8, Type:8, Len:16/big,
         Payload:Len/binary, Crc:32/big>>) when ... -> ...;
decode(_) -> {error, ...}.   %% bad_magic / truncated / crc_mismatch 显式分支
```

构造与匹配同一语法，一次模式完成"读头+按长取体"。四种解不开的情况（magic 错/头短/体短/CRC 不符）都要显式分支。

## 19.7 term_to_binary：任意 term ↔ 字节

```erlang
B = term_to_binary(Term).          %% 首字节固定 131（外部格式版本）
binary_to_term(B) =:= Term.        %% 完全还原
binary_to_term(Untrusted, [safe]). %% 不可信输入必须 [safe]
```

**`binary_to_term` 会创建原子**——原子表不回收，解不可信数据是真实 DoS 入口，加 `[safe]`（没见过的原子直接报错）。压缩对长数据明显；短数据实测持平（OTP 29/本机）。

## 19.8 json：OTP 27 内置的 JSON（EEP 68）

OTP 27 起标准库自带 `json` 模块（RFC 8259），不用再拉第三方依赖。编解码映射一张表说清：

| JSON | encode 自 | decode 成 |
|---|---|---|
| Object | map（atom/binary/integer 键） | **map（键一律 binary）** |
| Array | list | list |
| String | atom / binary | binary |
| Number | integer / float | integer / float |
| true / false | `true` / `false` | `true` / `false` |
| null | 任意其他 atom | 原子 **`null`** |

实测往返：

```erlang
iolist_to_binary(json:encode(#{name => <<"erlang">>, tags => [a, b], n => 42})).
%% <<"{\"name\":\"erlang\",\"tags\":[\"a\",\"b\"],\"n\":42}">>
%% ⚠ 键序是 map 的内部顺序，不作任何保证——别在测试里断言字节序，
%%   要比较就 decode 回来比 map。
json:decode(<<"{\"a\":1,\"b\":[true,null],\"c\":\"x\"}">>).
%% #{<<"a">> => 1, <<"b">> => [true, null], <<"c">> => <<"x">>}
```

三个要点：

1. **`encode` 返回 iodata**——直接喂 `file:write_file`、`gen_tcp:send` 零拷贝，要平面二进制自己 `iolist_to_binary`；
2. **decode 出的对象键是二进制**——访问时写 `maps:get(<<"a">>, M)`；想要原子键得用 `decode/3` 的 decoders 回调（官方示例用 `binary_to_existing_atom`，只许已存在的原子，安全）；
3. **`[{a, 1}]` 这种 kv 元组列表不能直接 encode**——`json:encode([{a,1}])` 抛 `{unsupported_type, {a,1}}`，要显式 `json:encode_key_value_list([{a,1},{b,2}], fun json:encode_value/2)` → `<<"{\"a\":1,\"b\":2}">>`。

非法输入抛 `error` 而不是返回元组，三种形态：`unexpected_end`（数据截断）、`{invalid_byte, Byte}`（error_info 里带 `position`）、`{unexpected_sequence, Bytes}`。给别人返回 400 前记得 try/catch。

超大 JSON（流式 TCP 分片）用续解析三件套——`decode_start/3` 开个头，之后每片喂 `decode_continue/2`，未完成返回 `{continue, State}`，解析完成直接给 `{Result, Acc, Rest}`：

```erlang
{continue, St1} = json:decode_start(<<"{\"a\":1">>, ok, #{}),
{continue, St2} = json:decode_continue(<<",\"b\":2">>, St1),
json:decode_continue(<<"}">>, St2).
%% {#{<<"a">> => 1, <<"b">> => 2}, ok, <<>>}
```

给人类看的输出用 `json:format/1,2,3`（OTP 27.1 起）：`json:format(#{a => 1, b => [1,2]})` 得到带缩进的 `<<"{\n  \"a\": 1,\n  \"b\": [1,2]\n}\n">>`。对"重键必须报错"的场景，`encode_map_checked` / `encode_key_value_list_checked` 遇到重复键抛 `{duplicate_key, Key}`（实测 `[{a,1},{a,2}]` 抛 `{duplicate_key, a}`）。

## 19.9 base64：一行编解码

```erlang
base64:encode(<<"hello">>).              %% <<"aGVsbG8=">>
base64:encode_to_string(<<"hello">>).    %% "aGVsbG8="——要字符串用这个
base64:decode(<<"aGVsbG8=">>).           %% <<"hello">>
base64:mime_decode(<<"aGVs\r\nbG8=">>).  %% <<"hello">>——容忍换行的 MIME 格式
```

两个注意：非法输入（如 `<<"!!!">>`）**抛** `missing_padding` 等错误，不返回元组；模块只提供 MIME 方向的**解**码（`mime_decode/1,2`），没有对应的 mime_encode。

## 19.10 zstd：现代压缩（OTP 28）

OTP 28 引入 `zstd`（Zstandard），同等压缩率下比 zlib 快一个量级，日志落盘、快照传输的首选：

```erlang
Data = binary:copy(<<"abcdef">>, 100).                 %% 600 字节
C = iolist_to_binary(zstd:compress(Data)).             %% → 23 字节
iolist_to_binary(zstd:decompress(C)) =:= Data.         %% true
```

**`compress` 与 `decompress` 返回的都是 iodata**（帧列表），比对或算大小前先 `iolist_to_binary`。压缩级别用 map 传：`zstd:compress(Data, #{compressionLevel => 20})`，文档范围 -22（极速）到 22（极压），默认 3 附近。需要流式压缩时分块喂 `zstd:compress(Data, Ctx)`，OTP 29 起可用 `zstd:flush/1` 强制吐出一个完整帧边界——对边压边发的协议很关键。

## 19.11 zip 与 erl_tar：归档读写

```erlang
zip:create("demo.zip", ["a.txt", "b.txt"], [{cwd, "/tmp/assets"}]).
%% {ok, "demo.zip"}——cwd 选项让裸文件名相对指定目录
zip:extract("demo.zip", [memory]).
%% {ok, [{"a.txt", <<"AAA">>}, {"b.txt", <<"BBB">>}]}——memory 直接拿内容不落盘
zip:table("demo.zip").     %% {ok, [zip_comment | zip_file 记录...]}：目录、大小、偏移
```

`erl_tar` 接口同形，但两个差异要记牢：① **没有 `cwd` 选项**，裸文件名只认当前工作目录，跨目录用**`{归档内名字, 磁盘路径}`** 元组（注意顺序，名字在前）：

```erlang
erl_tar:create("demo.tar", [{"a.txt", "/tmp/assets/a.txt"},
                            {"b.txt", "/tmp/assets/b.txt"}]).   %% ok
erl_tar:extract("demo.tar", [memory]).
%% {ok, [{"a.txt", <<"AAA">>}, {"b.txt", <<"BBB">>}]}
```

② 加 `compressed` 选项直接产出 `.tar.gz`。选哪个：Erlang 生态（release 打包）用 tar，对外交换用 zip。

## 19.12 file_sorter：内存放不下的排序

`lists:sort` 要求数据全在内存；`file_sorter` 做的是**外部归并排序**——分块读、排、写临时文件、多路归并，几百 MB 的 term 日志也能排：

```erlang
%% terms.txt 里每行一个 "Term." 格式
file_sorter:sort(["terms.txt"], "sorted.txt", [{format, term}]).   %% ok
file:consult("sorted.txt").      %% {ok, [{a,1},{b,2},{c,3}]}
file_sorter:keysort(2, ["terms.txt"], "ks.txt", [{format, term}]). %% 按 element(2) 排
```

**Input 是文件名列表**（或输入 fun）——单个文件名也得包一层列表；传裸字符串 `"terms.txt"` 会被当成字符列表拆开，报一个莫名其妙的 `{badarg, 47}`（47 就是 `/` 的码点，实测）。`format` 除了 `term`（文本 term），还有 `binary`（定长记录，配 `{size, N}`）与 `{header, N}`（N 字节长度头的变长记录）；`{order, descending}` 反序、`{unique, true}` 去重。配套的 `merge/keymerge` 合并多个已排序文件、`check/keycheck` 校验有序性。

## 19.13 坑位清单

1. **write_file 中文 badarg**：它吃字节 iodata；`/utf8` 二进制或 characters_to_binary。
2. **`{encoding, utf8}` 对 write_file 无效且静默**：不认识的选项一律静默忽略。
3. **忘 `[append]` 截断文件**：`[write]` 打开即清空。
4. **read 超长不返回 eof**：给剩下的；判断读完看**下一次** read。
5. **`io:get_line` 末尾是 `eof` 原子**：`L =:= eof` 判断，别用长度。
6. **句柄 terminated**：close 后再用报 `{error, terminated}`；忘 close 泄漏描述符。
7. **pread 是否移动偏移随平台变**（19.4 实测）——混用 read/pread 时显式 position。
8. **binary_to_term 不可信输入不加 [safe]**：原子表 DoS。
9. **json 三连**：encode 返回 iodata（要 iolist_to_binary）；decode 的键一律是二进制；`[{a,1}]` 直接 encode 抛 `{unsupported_type,{a,1}}`，须用 encode_key_value_list（19.8）。
10. **zstd 的 compress/decompress 都返回 iodata**：byte_size 或比对前先 iolist_to_binary（19.10）。
11. **erl_tar 没有 cwd 选项**（zip 有）；跨目录用 `{归档内名字, 磁盘路径}` 元组，顺序反了报 enoent（19.11）。
12. **file_sorter 的 Input 必须是文件名列表**：裸字符串被拆成码点，报 `{badarg, 47}`（47 即 `/` 的码点，19.12）。

---

---

上一章：[18 ETS](18-ets.md) · 下一章：[20 时间与定时器](20-time.md)
