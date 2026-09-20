# 17 · 正则与二进制模式深入

> 对应示例：`examples/17_regex_binaries/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

Elixir 有两套长得很像、哲学却不同的模式系统。处理**文本**用正则：`~r` 字面量、
捕获组、scan/replace/split；处理**字节**用二进制模式：定长字段、字节序、位域、
变长 `size(len)`。本章把两者各推进一步，并各写一个真正的解析器：正则解析
`key=value` 文本；二进制模式手写一个带长度前缀与校验和的**网络帧**编解码器。

## 17.1 ~r 与捕获：无匹配是 nil，不是异常

正则用 `~r/.../` 字面量创建（编译期完成，可加 `u`、`i` 等修饰符）。三个最基础的动词：

| 函数 | 返回 |
|---|---|
| `Regex.match?(re, s)` | 布尔 |
| `Regex.run(re, s)` | `[整匹配, 组1, 组2, ...]` 或 `nil` |
| `Regex.named_captures(re, s)` | `%{"名" => 值}` 或 `nil` |

注意返回值的第一个元素永远是**整段匹配**，捕获组从第二个开始；找不到时安静地返回
`nil`/`false`——正则库不靠异常表达「没找到」。命名捕获让代码不必数下标：

```elixir
def year_month(text) when is_binary(text) do
  re = ~r/(?<y>\d{4})-(?<m>\d{2})/

  case Regex.named_captures(re, text) do
    %{"y" => y, "m" => m} -> {:ok, {String.to_integer(y), String.to_integer(m)}}
    nil -> :nomatch
  end
end
```

```text
-- 1. ~r 字面量与命名捕获；无匹配返回 :nomatch --
  年月 => {:ok, {2026, 9}}
  无日期 => :nomatch
  第一个数字串 => "42"
```

## 17.2 scan / replace / split：对所有匹配动手

`Regex.run` 只给第一个匹配，`Regex.scan/2` 返回**全部**匹配（每行仍是
`[整匹配, 组1, ...]`），天然适合配合 `for` 提取：

```elixir
def parse_kv(text) when is_binary(text) do
  for [_whole, key, val] <- Regex.scan(~r/(\w+)=(\w+)/, text), do: {key, val}
end
```

`Regex.replace/3` 的替换串里 `\1`、`\2` 是**反向引用**（在 Elixir 源码里要写成
`"\\1****\\2"`——字符串转义一层、正则再解释一层）；`Regex.split/2` 配 `trim: true`
去掉首尾空串：

```text
-- 2. scan 全部捕获；replace 反向引用打码；split+trim 切词 --
  kv => [{"a", "1"}, {"b", "2"}, {"c", "3"}]
  打码 => "call 138****5678 now"
  切词 => ["foo", "bar", "baz"]
```

## 17.3 二进制模式：字段宽度、字节序与剩余

二进制匹配把模式写进 `<<>>`：`::16` 是 16 位整数，`-little`/`-big` 选字节序
（默认大端），`rest::binary` 收下其余全部字节。本章的小记录是
「小端 x + 大端 y + 剩余」：

```elixir
def parse_point(<<x::16-little, y::16-big, rest::binary>>) do
  %{point: {x, y}, rest: rest}
end
```

`<<1, 0, 0, 2, "z">>` 里前两字节按小端解释成 1，接下来两字节按大端解释成 2，
剩下 `"z"`。加 `signed-` 前缀按补码解释：`<<255>>` 作为 `signed-8` 是 -1，
不加就是 255：

```text
-- 3. 二进制模式：小端 x + 大端 y + rest；signed-8 补码 --
  point => %{rest: "z", point: {1, 2}}
  <<255>> 有符号 => -1
```

## 17.4 位级模式：size/unit 与非字节对齐

字段不必整字节。`::4` 就是 4 位，一个字节可以拆成两个 nibble；
通用写法是 `::size(n)-unit(u)`，占 **n×u 位**。RGB565 像素格式把红 5 位、
绿 6 位、蓝 5 位压进一个 16 位字：

```elixir
def pack_rgb565(r, g, b), do: <<r::5, g::6, b::5>>

def unpack_rgb565(bin) do
  for <<r::5, g::6, b::5 <- bin>>, do: {r, g, b}
end
```

`for <<... <- bin>>` 是**位串推导**：按模式反复切，余数不足一个完整模式时自动停。
`{31,63,31}`（三通道全满）压成 `<<255,255>>`；`{1,2,3}` 压成 `<<8,67>>`。

```text
-- 4. 非字节对齐：一个字节拆 4+4；RGB565 压进 16 位 --
  nibbles => %{type: 3, version: 10}
  pack(31,63,31) => <<255, 255>>；解回 => [{31, 63, 31}, {0, 0, 0}]
```

## 17.5 手写二进制帧：编码

正则解决不了「第 2~3 字节是长度、跟着恰好那么多字节的 payload」这类问题——
这正是二进制模式的主场。本章定义一个简单的线上帧格式：

```text
+--------+-------------+---------+-----------+
| tag 1B | len 2B 大端 | payload | xor 校验1B |
+--------+-------------+---------+-----------+
```

校验字节 = tag 与 payload 每个字节依次异或。编码就是一个 `<<>>`：

```elixir
def encode_frame(tag, payload) do
  <<tag, byte_size(payload)::16, payload::binary, checksum(tag, payload)>>
end
```

`payload::binary` 不能带固定宽度——它的宽度来自前面的 `len`，解析时写成
`payload::binary-size(len)`，len 字段必须在同一模式里更早绑定：

```text
-- 5. 帧编码：1 字节 tag + 2 字节大端长度 + payload + 1 字节异或校验 --
  encode_frame(1, "hi") => <<1, 0, 2, 104, 105, 0>>
```

`1 bxor 104 bxor 105 = 0`，所以校验字节是 0。

## 17.6 递归解析：粘连、坏帧、残片

解码是一条递归：匹配「完整帧」就收下、用 `rest` 继续递归；匹配不上时区分两种情况——
空二进制 = 恰好吃完；还剩点 = **不完整帧**（TCP 流里常见：字节还在路上）。
校验不符则停在坏帧处，返回 `:error` 与之前已解析的帧：

```elixir
defp parse_frames(<<tag, len::16, payload::binary-size(len), sum, rest::binary>>, acc) do
  if checksum(tag, payload) == sum do
    parse_frames(rest, [{:frame, tag, payload} | acc])
  else
    {:error, :bad_checksum, tag, Enum.reverse(acc)}
  end
end

defp parse_frames(<<>>, acc), do: {:ok, Enum.reverse(acc), ""}
defp parse_frames(leftover, acc), do: {:incomplete, Enum.reverse(acc), leftover}
```

子句顺序就是三态判定：能匹配完整帧 → 递归；否则空 → `:ok`；否则残片 → `:incomplete`。
`:incomplete` 不是错误，调用方攒够字节后把残片拼在新数据前面重入即可（测试里演示了
「半个帧 → 补齐 → 解析成功」）。

```text
-- 6. parse_frames：多帧粘连；坏校验停在坏帧；残帧等更多字节 --
  两帧粘连 => {:ok, [{:frame, 1, "hi"}, {:frame, 2, "ok"}], ""}
  坏校验 => {:error, :bad_checksum, 1, []}
  完整帧 + 1 字节残头 => {:incomplete, [{:frame, 1, "hi"}], <<255>>}
```

## 17.7 Unicode：字节 / 码点 / 字素三层

处理非 ASCII 文本前必须分清三个层次：

| 层 | 度量 | é（U+00E9） | é（e + U+0301 组合重音） |
|---|---|---|---|
| 字节 | `byte_size/1` | 2 | 3 |
| 码点 | `String.codepoints/1` | 1 | 2 |
| 字素簇 | `String.graphemes/1` | 1 | 1 |

视觉上同一个字符可以有两种字节序列：`==` 比字节（不相等），
`String.equivalent?/2` 比规范化后的字素（相等）。逐**码点**（而非逐字节）遍历用
`::utf8` 位段：`for <<cp::utf8 <- s>>, do: cp`。

正则这边有个对应陷阱：`\w` 默认只认 ASCII 单词字符，é 的 UTF-8 首字节不在范围内，
`"café"` 被切成 `"caf"`；加 `u` 修饰符后按 Unicode 字符类匹配，整词完整：

```text
-- 7. 同一个 é：字节/码点/字素三层；\w 是否带 u 的差别 --
  单码点 é 三层 => {2, 1, 1}
  e+组合重音 三层 => {3, 2, 1}
  \w 无 u => ["caf"]
  \w 带 u => ["café"]
```

## 17.8 模式解析要点

```text
  正则处理「文本」：捕获是字符串，无匹配返回 nil，Unicode 文本记得 u 修饰符
  二进制模式处理「字节/位」：size 定长、unit 定粒度、-little/-big 定字节序
  长度前缀用 ::16 + binary-size(len)；变长二进制必须放最后并配 rest::binary
  非整字节用 ::size 位域（4 位 nibble、5/6/5 像素），解析多值用位串推导
  流式解析区分三态：吃完 :ok、残帧 :incomplete、数据坏 :error
```

## 17.9 坑位清单

1. **文档/字符串里的正则反斜杠要过两道转义**。本章的 doctest 直接在 `@doc """..."""`
   里写 `~r/\d+/`，heredoc 先吃掉一层转义，doctest 拿到的正则失效（实测返回 nil）；
   文档里必须写 `\\d+`。普通 `.ex` 源码中的正则只有一层，照写 `\d`。
2. **`Regex.run/1` 的第一个元素是整匹配**，捕获组从第二个开始；解构写
   `[_whole, g1, g2]`，忘了第一项会全部错位。无匹配是 `nil`，不是异常。
3. **命名捕获的名字按字母序返回声明信息**：`Regex.names(~r/(?<y>..)-(?<m>..)/)`
   实测是 `["m", "y"]`；别依赖声明顺序。
4. **替换串的反向引用是 `"\\1"` 不是 `"\1"`**：后者在 Elixir 字符串里是码点 1
   的控制字符；源码里需要双反斜杠，正则运行时才看到 `\1`。
5. **变长字段只能在模式末尾**。`binary-size(len)`、`utf8`、`rest::binary` 这类
   不固定宽度的字段，后面不能再跟定长字段，否则编译错误；多个变长段必须递归拆。
6. **默认大端、默认无符号**。对端发来的 PC 常见小端整数要显式 `-little`；
   读补码要 `signed-`：`<<255>>` 默认是 255，`signed-8` 才是 -1。
7. **`::16` 是位数不是字节数**。完整规则是 `size(n)-unit(u)` = n×u 位；
   `binary` 类型的 unit 默认 8，`bitstring` 默认 1，混淆会读出错位数的字段。
8. **残帧不是错误**：流协议必须返回 `:incomplete` 并保留残片，等下一块数据拼回来；
   把残片当坏帧丢弃，就是偶发「请求解析失败」的根源。TCP 同时还有**粘包**——
   一次到账可能含多个完整帧，所以解析器天然要递归吃 0~n 帧。
9. **处理文本先想清楚在哪个层**：截字节会切断 UTF-8（é 占 2 字节、组合序列占 3），
   要安全截断/计数用 `String` 的码点、字素函数；正则处理 Unicode 文本记得 `u`。
10. **`inspect` 对小数字节有特殊渲染**：`<<9>>` 打印成 `"\t"`、`<<104,105>>`
    打印成 `"hi"`。本章残帧示例特意选 `<<255>>` 这种非打印字节，输出才是稳定的
    位串写法（这也是第 5 层逐字节比对能过的细节）。

---

下一章进入惰性集合：[18 · Stream](18-streams.md)
——`resource/iterate/cycle/unfold`、分块、无限流与恒定内存，把本章的帧解析思路
接到「字节源源不断到达」的真实流式场景。
