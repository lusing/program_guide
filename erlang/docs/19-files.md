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

## 19.8 坑位清单

1. **write_file 中文 badarg**：它吃字节 iodata；`/utf8` 二进制或 characters_to_binary。
2. **`{encoding, utf8}` 对 write_file 无效且静默**：不认识的选项一律静默忽略。
3. **忘 `[append]` 截断文件**：`[write]` 打开即清空。
4. **read 超长不返回 eof**：给剩下的；判断读完看**下一次** read。
5. **`io:get_line` 末尾是 `eof` 原子**：`L =:= eof` 判断，别用长度。
6. **句柄 terminated**：close 后再用报 `{error, terminated}`；忘 close 泄漏描述符。
7. **pread 是否移动偏移随平台变**（19.4 实测）——混用 read/pread 时显式 position。
8. **binary_to_term 不可信输入不加 [safe]**：原子表 DoS。

---
