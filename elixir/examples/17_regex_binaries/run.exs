# 第 17 章驱动脚本：cd examples/17_regex_binaries && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex17RegexBinaries

IO.puts("==== 17 正则与二进制模式深入：捕获、位级模式、手写帧解析、Unicode 三层 ====")

# ------------------------------------------------------------
# 1. 正则匹配：match?/run 与命名捕获；无匹配是 nil（不抛异常）
# ------------------------------------------------------------
IO.puts("\n-- 1. ~r 字面量与命名捕获；无匹配返回 :nomatch --")
IO.puts("  年月 => #{inspect(Ex17RegexBinaries.year_month("2026-09 开会"))}")
IO.puts("  无日期 => #{inspect(Ex17RegexBinaries.year_month("没有日期"))}")
IO.puts("  第一个数字串 => #{inspect(Ex17RegexBinaries.first_match(~r/\d+/, "abc 42 def"))}")

# ------------------------------------------------------------
# 2. 捕获迭代：scan / replace（反向引用）/ split
# ------------------------------------------------------------
IO.puts("\n-- 2. scan 全部捕获；replace 反向引用打码；split+trim 切词 --")
IO.puts("  kv => #{inspect(Ex17RegexBinaries.parse_kv("a=1 b=2 c=3"))}")
IO.puts("  打码 => #{inspect(Ex17RegexBinaries.mask_phone("call 13812345678 now"))}")
IO.puts("  切词 => #{inspect(Ex17RegexBinaries.words("  foo   bar baz "))}")

# ------------------------------------------------------------
# 3. 二进制模式：定长字段、字节序、signed、剩余
# ------------------------------------------------------------
IO.puts("\n-- 3. 二进制模式：小端 x + 大端 y + rest；signed-8 补码 --")
IO.puts("  point => #{inspect(Ex17RegexBinaries.parse_point(<<1, 0, 0, 2, "z">>))}")
IO.puts("  <<255>> 有符号 => #{Ex17RegexBinaries.signed_byte(<<255>>)}")

# ------------------------------------------------------------
# 4. 位级模式：4 位字段与 RGB565 的 5/6/5
# ------------------------------------------------------------
IO.puts("\n-- 4. 非字节对齐：一个字节拆 4+4；RGB565 压进 16 位 --")
IO.puts("  nibbles => #{inspect(Ex17RegexBinaries.parse_nibbles(<<0xA3>>))}")
packed = Ex17RegexBinaries.pack_rgb565(31, 63, 31)

IO.puts(
  "  pack(31,63,31) => #{inspect(packed)}；解回 => #{inspect(Ex17RegexBinaries.unpack_rgb565(packed <> <<0, 0>>))}"
)

# ------------------------------------------------------------
# 5. 手写二进制帧：编码（tag + len + payload + xor 校验）
# ------------------------------------------------------------
IO.puts("\n-- 5. 帧编码：1 字节 tag + 2 字节大端长度 + payload + 1 字节异或校验 --")
frame1 = Ex17RegexBinaries.encode_frame(1, "hi")
IO.puts("  encode_frame(1, \"hi\") => #{inspect(frame1)}")

# ------------------------------------------------------------
# 6. 递归解析：多帧粘连 / 坏校验 / 不完整残帧
# ------------------------------------------------------------
IO.puts("\n-- 6. parse_frames：多帧粘连；坏校验停在坏帧；残帧等更多字节 --")
multi = frame1 <> Ex17RegexBinaries.encode_frame(2, "ok")
IO.puts("  两帧粘连 => #{inspect(Ex17RegexBinaries.parse_frames(multi))}")
IO.puts("  坏校验 => #{inspect(Ex17RegexBinaries.parse_frames(<<1, 0, 2, 104, 105, 99>>))}")
IO.puts("  完整帧 + 1 字节残头 => #{inspect(Ex17RegexBinaries.parse_frames(frame1 <> <<255>>))}")

# ------------------------------------------------------------
# 7. Unicode：字节 / 码点 / 字素；正则 u 修饰符
# ------------------------------------------------------------
IO.puts("\n-- 7. 同一个 é：字节/码点/字素三层；\\w 是否带 u 的差别 --")
decomposed = "e" <> <<0x301::utf8>>
IO.puts("  单码点 é 三层 => #{inspect(Ex17RegexBinaries.three_lengths("é"))}")
IO.puts("  e+组合重音 三层 => #{inspect(Ex17RegexBinaries.three_lengths(decomposed))}")
IO.puts("  \\w 无 u => #{inspect(Ex17RegexBinaries.latin_words("café"))}")
IO.puts("  \\w 带 u => #{inspect(Ex17RegexBinaries.unicode_words("café"))}")

IO.puts("""
-- 模式解析要点 --
  正则处理「文本」：捕获是字符串，无匹配返回 nil，Unicode 文本记得 u 修饰符
  二进制模式处理「字节/位」：size 定长、unit 定粒度、-little/-big 定字节序
  长度前缀用 ::16 + binary-size(len)；变长二进制必须放最后并配 rest::binary
  非整字节用 ::size 位域（4 位 nibble、5/6/5 像素），解析多值用位串推导
  流式解析区分三态：吃完 :ok、残帧 :incomplete、数据坏 :error
""")

IO.puts("==== 17 结束 ====")
