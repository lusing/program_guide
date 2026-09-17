# 08 · 二进制与位语法

> 对应示例：`examples/08_binaries/`

## 8.1 构造：段拼接出任意位串

```erlang
<<1, 2, 3>>.               %% 3 个字节
<<300:16>>.                %% 16 位放 300（单字节放不下时指定位数）
<<1:4, 2:4>>.              %% 两个 4 位段拼成 <<16#12>>
<<1:1, 0:1, 1:1>>.         %% 位串可以不满整字节（bit_size = 3）
<<<<1,2>>/binary, <<3,4>>/binary>>.   %% /binary 拼接避免复制
```

通式：`<<Value:Size/Type-Signedness-Endianness-Unit>>`，各段可省略用默认值。

## 8.2 匹配：构造与解析同一语法

```erlang
take_len_prefixed(<<N:8, P:N/binary, T/binary>>) -> {N, P, T}.
strip_get(<<"GET ", Path/binary>>) -> {ok, Path}.
```

**尺寸可以引用前面绑定的变量**（`P:N/binary`）——"读长度、按长度取负载"一次匹配完成，别的语言很难这么写。模式里还能直接写 ASCII 字面量（`"GET "`、`"IHDR"`）。

## 8.3 字节序、符号与浮点

```erlang
<<1:16>>.              %% <<0,1>> 默认大端
<<1:16/little>>.       %% <<1,0>>
<<255:8/signed>>.      %% -1（signed / unsigned 改变解释）
<<1.0:32/float>>.      %% IEEE 754 单精度；64 位双精度同理
```

`/native` 跟机器走（跨机器传输**不要用**，只用于本地计算）。utf16/utf32 的字节序写法是**短横线连接**：`<<$中/utf16-little>>`——写成 `/utf16/little` 是语法错误。

## 8.4 文本编码

```erlang
<<$中/utf8>>.      %% 3 字节；<<$中/utf16>> 2 字节；<<$中/utf32>> 4 字节
unicode:characters_to_list(<<"中文"/utf8>>).    %% [20013,25991] 解码
unicode:characters_to_binary([20013, 25991]).   %% 再编码回二进制
```

手工按 UTF-8 规则位级解码（0xxxxxxx / 110xxx xx…）见示例 `parse_utf8/1`——与标准库结果逐码点一致。

## 8.5 binary 模块

```erlang
binary:split(B, <<0>>, [global]).      %% 分割（保留空片段！string:split 不保留）
binary:matches(B, Pat).                %% 全部命中位置 [{Pos, Len}]
binary:part(B, 1, 3).                  %% 切片（0 基）
binary:replace(B, <<"X">>, <<"-">>, [global]).
binary:encode_unsigned(256).           %% <<1,0>>——大整数↔字节串
```

## 8.6 实战：TLV 与 PNG 头

```erlang
encode_tlv(Type, Value) -> <<Type:8, (byte_size(Value)):16, Value/binary>>.
parse_tlv(<<Type:8, Len:16, V:Len/binary, Rest/binary>>) -> {ok, {Type, V}, Rest};
parse_tlv(B) -> {incomplete, byte_size(B)}.       %% 半截帧识别

png_size(<<137, 80, 78, 71, 13, 10, 26, 10,      %% 8 字节魔数直接写进模式
           _Len:32, "IHDR", W:32, H:32, _/binary>>) -> {ok, W, H}.
```

编码与解码**对称**，两帧连着发也能顺序解开——这就是二进制协议的 Erlang 写法。

## 8.7 坑位清单

1. **裸字节段取值必须 0..255**：`<<300>>` 抛 badarg，要写 `<<300:16>>`。
2. **模式不匹配抛的是 function_clause**（单子句函数）——想报"格式错"要自己加兜底子句。
3. **utf16/utf32 字节序用 `-` 连接**：`<<$中/utf16-little>>`；`/utf16/little` 语法错。
4. **`/native` 只用于本地**：网络协议固定 big/little，别让字节序随机器漂。
5. **binary:split 保留空片段**：`split(<<0,1>>, <<0>>)` 得 `[<<>>,<<1>>]`；string:split 丢空的——两个模块行为不一致。
6. **bit_size vs byte_size**：位串不满整字节时 `byte_size` 向上取整，位级信息看 `bit_size`。

---
