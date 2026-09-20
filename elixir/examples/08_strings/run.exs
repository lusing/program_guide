# 第 08 章驱动脚本：cd examples/08_strings && mix run run.exs

# 与 locale 解耦：不设 LANG 时 BEAM 的 stdio 退回 latin1，非 ASCII 会被打成 \x{...}。
# 每个示例工程的 run.exs 第一行都是它；测试进程在 test_helper.exs 里同样设置。
:io.setopts(:standard_io, encoding: :utf8)

# 非 ASCII 探针字符串全部由库模块以转义提供，本脚本不直接写任何特殊字面量。
alias Ex08Strings

IO.puts("==== 08 字符串与 Unicode ====")

nfc = Ex08Strings.nfc_eacute()
nfd = Ex08Strings.nfd_eacute()
family = Ex08Strings.family()
wave = Ex08Strings.wave()
tone = Ex08Strings.tone()

print_units = fn label, bin ->
  u = Ex08Strings.units(bin)

  IO.puts(
    "  #{String.pad_trailing(label, 22)} bytes=#{u.bytes} codepoints=#{u.codepoints} graphemes=#{u.graphemes}"
  )
end

IO.puts("\n-- 1. 三个单位：字节 / 码点 / 字素簇（人眼的「一个字符」= 字素）--")
print_units.("\"abc\"", "abc")
print_units.("e-acute NFC (U+00E9)", nfc)
print_units.("e-acute NFD (e+U+0301)", nfd)
print_units.("wave emoji U+1F44B", wave)
print_units.("thumbs-up + skin tone", tone)
print_units.("family ZWJ sequence", family)

IO.puts("\n-- 2. 规范化：同一文本可以有不同字节编码 --")
IO.puts("NFC == NFD（比字节）         => #{inspect(nfc == nfd)}")
IO.puts("equivalent?(NFC, NFD)        => #{inspect(Ex08Strings.equivalent?(nfc, nfd))}")
IO.puts("to_nfc(NFD) == NFC           => #{inspect(Ex08Strings.to_nfc(nfd) == nfc)}")

IO.puts("\n-- 3. 大小写：会改变长度、不可逆、还跟语种有关 --")
IO.puts("case_report(\"stra\u00DFe\")  => #{inspect(Ex08Strings.case_report("stra\u00DFe"))}")
IO.puts("  \u00DF 大写展开成 SS：downcase(upcase(x)) 对不上原词")

IO.puts(
  "downcase(\"I\") 默认 / :turkic => #{inspect(String.downcase("I"))} / #{inspect(Ex08Strings.turkish_lower_i())}（U+0131 无点 i）"
)

IO.puts(
  "upcase(e-acute) 默认 / :ascii => #{inspect(String.upcase(nfc))} / #{inspect(Ex08Strings.ascii_upcase(nfc))}"
)

IO.puts("\n-- 4. 按字素切 vs 按字节切：切错就是半个字符 --")
IO.puts("first_grapheme(e-acute)       => #{inspect(Ex08Strings.first_grapheme(nfc))}")
IO.puts("first_byte(e-acute)          => #{inspect(Ex08Strings.first_byte(nfc))}（0xC3 只是首字节）")
IO.puts("头一字节是合法 UTF-8 吗       => #{inspect(Ex08Strings.first_byte_valid?(nfc))}（ASCII 才是 true）")

IO.puts("\n-- 5. 二进制模式：按码点 / 字节遍历，从码点构造 --")
IO.puts("codepoint_ints(wave)         => #{inspect(Ex08Strings.codepoint_ints(wave))}")
IO.puts("codepoint_ints(NFD)          => #{inspect(Ex08Strings.codepoint_ints(nfd))}")

IO.puts(
  "byte_ints(e-acute)           => #{inspect(Ex08Strings.byte_ints(nfc))}（0xC3 0xA9 = UTF-8 编码）"
)

IO.puts("byte_ints(wave)              => #{inspect(Ex08Strings.byte_ints(wave))}")
IO.puts("from_codepoint(0x1F44B)      => #{inspect(Ex08Strings.from_codepoint(0x1F44B))}")
IO.puts("graphemes(family)            => #{inspect(String.graphemes(family))}（5 码点 18 字节是一个字素）")

IO.puts("\n-- 6. iodata：二进制与码点列表任意嵌套，直接输出不拼接 --")
data = ["a", ~c"b", [?c], nfc]
IO.puts(["iodata 原样 => ", inspect(data), "；iodata_to_binary => ", IO.iodata_to_binary(data)])
IO.puts("iodata_bytes/1（不拼接计数）=> #{Ex08Strings.iodata_bytes(data)}")

IO.puts("\n-- 7. 常用操作：全部字素感知 --")
IO.puts("words(\"  a   b c \")          => #{inspect(Ex08Strings.words("  a   b c "))}")
IO.puts("pad_id(\"42\")                 => #{inspect(Ex08Strings.pad_id("42"))}")

IO.puts(
  "reverse_graphemes(\"a\u{1F44B}b\")=> #{inspect(Ex08Strings.reverse_graphemes("a#{wave}b"))}（emoji 完好）"
)

IO.puts(
  "mask_name / ends_with?       => #{inspect(Ex08Strings.mask_name("hello Ada", "Ada"))} / #{inspect(Ex08Strings.kind_of_file?("a.txt", ".txt"))}"
)

IO.puts("\n-- 8. 数字解析：to_integer 会崩，Integer.parse 会部分成功 --")

IO.puts(
  "parse_int(\"42\") / (\"42px\") / (\"abc\") => #{inspect(Ex08Strings.parse_int("42"))} / #{inspect(Ex08Strings.parse_int("42px"))} / #{inspect(Ex08Strings.parse_int("abc"))}"
)

IO.puts("\n-- 9. IO 编码纪律 --")
IO.puts("stdout 已显式 setopts encoding: :utf8，输出与系统 locale 无关；")
IO.puts("读外部字节先 String.valid?/1，切分按字素，比较前考虑规范化。")

IO.puts("\n==== 08 结束 ====")
