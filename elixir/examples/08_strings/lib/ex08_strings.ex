defmodule Ex08Strings do
  @moduledoc """
  第 08 章示例：字符串与 Unicode 深水区。

  Elixir 字符串是 UTF-8 二进制，三个单位（字节 / 码点 / 字素簇）在非 ASCII
  世界里彻底分家。本章用可断言的函数钉死四组事实：

  1. 同一个 é 的 NFC（U+00E9）与 NFD（e + U+0301）字节不同、`==` 为假，
     但 `String.equivalent?/2` 按规范等价判为同一串文本；
  2. 一个 emoji（含 ZWJ 家庭、肤色修饰）可能是 1 个字素、多个码点、十几字节；
  3. 大小写转换不是一一对应：德语 ß 大写变 "SS"（长度改变、不可逆），
     土耳其语 I 的小写要 `:turkic` 模式才得到无点 i（U+0131）；
  4. 按字节切会切出无效 UTF-8，按字素切才安全。

  doctest 只用 ASCII：期望输出是逐字符比对，非 ASCII 的结论统一在测试文件
  里用转义断言，避免源码编码层面的歧义。

      iex> Ex08Strings.units("abc")
      %{bytes: 3, codepoints: 3, graphemes: 3}

  """

  # 所有非 ASCII 常量一律用转义书写：不依赖编辑器/工具链对源码做的规范化。
  @nfc_eacute "\u00E9"
  @nfd_eacute "e\u0301"

  # 男人 ZWJ 女人 ZWJ 女孩：人眼是「一家人」一个 emoji。
  @family "\u{1F468}\u200D\u{1F469}\u200D\u{1F467}"
  @wave "\u{1F44B}"
  # 竖起拇指 + 中等肤色修饰符。
  @tone "\u{1F44D}\u{1F3FD}"

  # ============================================================
  # 1. 三个单位：字节 / 码点 / 字素簇
  # ============================================================

  @doc """
  一次性给出三种长度。

      iex> Ex08Strings.units("abc")
      %{bytes: 3, codepoints: 3, graphemes: 3}

      iex> Ex08Strings.units("")
      %{bytes: 0, codepoints: 0, graphemes: 0}

  """
  @spec units(binary()) :: %{
          bytes: non_neg_integer(),
          codepoints: non_neg_integer(),
          graphemes: non_neg_integer()
        }
  def units(bin) when is_binary(bin) do
    %{
      bytes: byte_size(bin),
      codepoints: length(String.codepoints(bin)),
      graphemes: String.length(bin)
    }
  end

  # 让 run.exs / 测试能拿到本章固定的几个探针字符串。
  def nfc_eacute, do: @nfc_eacute
  def nfd_eacute, do: @nfd_eacute
  def family, do: @family
  def wave, do: @wave
  def tone, do: @tone

  # ============================================================
  # 2. 规范化：同一文本的多种字节编码
  # ============================================================

  @doc """
  `String.equivalent?/2` 按 Unicode 规范等价判断（双方都做 NFC 再比）。
  NFC 与 NFD 的 é 字节不同、`==` 为假，但它判为同一串文本——文件系统、
  数据库、外部 API 边界常见这种差异。

      iex> Ex08Strings.equivalent?("a", "a")
      true

  """
  @spec equivalent?(binary(), binary()) :: boolean()
  def equivalent?(a, b) when is_binary(a) and is_binary(b) do
    String.equivalent?(a, b)
  end

  @doc """
  用 Erlang 标准库做 NFC 规范化——规范化后再比较，`==` 才是可靠的文本相等。

      iex> Ex08Strings.to_nfc("abc")
      "abc"

  """
  @spec to_nfc(binary()) :: binary()
  def to_nfc(bin), do: :unicode.characters_to_nfc_binary(bin)

  # ============================================================
  # 3. 大小写：长度会变、不可逆、语种相关
  # 实测（1.20 / OTP 29）：
  #   upcase("straße")        => "STRASSE"（ß 展开成 SS，长度 +1）
  #   downcase(upcase(...))   => "strasse"（对不上原词，往返不成立）
  #   downcase("I", :turkic)  => "ı"（U+0131 无点 i；默认模式给 "i"）
  # ============================================================

  @doc """
  大小写体检：上移、下移、是否往返一致、字素长度变化。
  "straße" 的报告是 `%{up: "STRASSE", down: "strasse", roundtrip?: false, delta: 1}`。

      iex> Ex08Strings.case_report("abc")
      %{up: "ABC", down: "abc", roundtrip?: true, delta: 0}

  """
  @spec case_report(binary()) ::
          %{up: binary(), down: binary(), roundtrip?: boolean(), delta: integer()}
  def case_report(word) do
    up = String.upcase(word)
    down = String.downcase(up)

    %{
      up: up,
      down: down,
      roundtrip?: down == word,
      delta: String.length(up) - String.length(word)
    }
  end

  @doc """
  土耳其语模式：I 的小写是无点 i（U+0131），不是 ASCII i。
  德语 ß、希腊语终西格玛同样有语种特殊规则。

      iex> Ex08Strings.turkish_lower_i() == "ı"
      true

  """
  @spec turkish_lower_i() :: binary()
  def turkish_lower_i, do: String.downcase("I", :turkic)

  @doc """
  `:ascii` 模式只处理 A-Z/a-z，其余原样保留——处理字节协议标识符时
  比默认的全 Unicode 行为更可预测。

      iex> Ex08Strings.ascii_upcase("abc")
      "ABC"

  """
  @spec ascii_upcase(binary()) :: binary()
  def ascii_upcase(bin), do: String.upcase(bin, :ascii)

  # ============================================================
  # 4. 字节切 vs 字素切
  # ============================================================

  @doc """
  按字素取第一个「字符」，多字节字符完整返回。

      iex> Ex08Strings.first_grapheme("hi")
      "h"

  """
  @spec first_grapheme(binary()) :: binary()
  def first_grapheme(bin), do: String.at(bin, 0)

  @doc """
  取头一个字节的整数值。对多字节字符，这一个字节是**半字符**，
  单独拿出来不是合法 UTF-8（见 `first_byte_valid?/1`）。

      iex> Ex08Strings.first_byte("hi")
      104

  """
  @spec first_byte(binary()) :: byte()
  def first_byte(bin), do: :binary.first(bin)

  @doc """
  头字节单独切出来是否仍是合法 UTF-8。ASCII 为真，任何多字节字符为假。

      iex> Ex08Strings.first_byte_valid?("hi")
      true

  """
  @spec first_byte_valid?(binary()) :: boolean()
  def first_byte_valid?(bin), do: String.valid?(binary_part(bin, 0, 1))

  # ============================================================
  # 5. 二进制模式：按码点 / 字节遍历
  # <<cp::utf8, rest::binary>> 每次吃掉一个完整码点（1..4 字节）；
  # <<b <- bin>> 推导式每次吃一个字节。
  # ============================================================

  @doc """
  用二进制模式把字符串拆成码点整数列表（不用 String 模块）。

      iex> Ex08Strings.codepoint_ints("A")
      [65]

      iex> Ex08Strings.codepoint_ints("")
      []

  """
  @spec codepoint_ints(binary()) :: [non_neg_integer()]
  def codepoint_ints(bin), do: codepoint_ints(bin, [])

  defp codepoint_ints(<<cp::utf8, rest::binary>>, acc) do
    codepoint_ints(rest, [cp | acc])
  end

  defp codepoint_ints(<<>>, acc), do: Enum.reverse(acc)

  @doc """
  字节列表。ASCII 与码点一致；非 ASCII 立刻现出 UTF-8 原型
  （U+00E9 编码成 `0xC3 0xA9`，即 195、169）。

      iex> Ex08Strings.byte_ints("A")
      [65]

  """
  @spec byte_ints(binary()) :: [byte()]
  def byte_ints(bin), do: for(<<b <- bin>>, do: b)

  @doc """
  从一个码点整数构造二进制（`::utf8` 负责编码成 1..4 字节）。
  emoji 码点（如 0x1F44D）会自动编成 4 字节。

      iex> Ex08Strings.from_codepoint(65)
      "A"

  """
  @spec from_codepoint(non_neg_integer()) :: binary()
  def from_codepoint(cp), do: <<cp::utf8>>

  # ============================================================
  # 6. iodata：不必拼接就能输出
  # ============================================================

  @doc """
  返回一段 iodata（二进制与码点整数列表任意嵌套）。`IO.puts/1` 直接接受，
  不需要先拼成一个新二进制——高并发写日志/响应时少一次大字符串分配。

      iex> Ex08Strings.banner("hi") |> IO.iodata_to_binary()
      "== hi =="

  """
  @spec banner(binary()) :: iolist()
  def banner(title), do: ["== ", title, " =="]

  @doc """
  iodata 的「长度」是拼起来后的字节数，不实际拼接、不复制内容。

      iex> Ex08Strings.iodata_bytes(["ab", [?c, ?d], "ef"])
      6

  """
  @spec iodata_bytes(iolist()) :: non_neg_integer()
  def iodata_bytes(data), do: IO.iodata_length(data)

  # ============================================================
  # 7. 常用操作：trim / split / pad / replace / 判定（全部字素感知）
  # ============================================================

  @doc """
  去掉两端空白，再按空格切，`trim: true` 吞掉连续空格。

      iex> Ex08Strings.words("  a   b c ")
      ["a", "b", "c"]

  """
  @spec words(binary()) :: [binary()]
  def words(s), do: s |> String.trim() |> String.split(" ", trim: true)

  @doc """
  字素级补白（补 emoji 也按一个字素算，不会补出半个字符）。

      iex> Ex08Strings.pad_id("42")
      "00042"

  """
  @spec pad_id(binary()) :: binary()
  def pad_id(s), do: String.pad_leading(s, 5, "0")

  @doc """
  字素感知的反转：对多字节字符不会反转出乱码
  （老语言按字节 reverse UTF-8 是经典 bug）。

      iex> Ex08Strings.reverse_graphemes("abc")
      "cba"

  """
  @spec reverse_graphemes(binary()) :: binary()
  def reverse_graphemes(s), do: String.reverse(s)

  @doc """
  后缀判定（大小写敏感——大小写规则见上，别自己瞎折）。

      iex> Ex08Strings.kind_of_file?("a.txt", ".txt")
      true

      iex> Ex08Strings.kind_of_file?("a.TXT", ".txt")
      false

  """
  @spec kind_of_file?(binary(), binary()) :: boolean()
  def kind_of_file?(name, ext), do: String.ends_with?(name, ext)

  @doc """
  字面量替换（正则替换是 17 章内容）。

      iex> Ex08Strings.mask_name("hello Ada", "Ada")
      "hello ***"

  """
  @spec mask_name(binary(), binary()) :: binary()
  def mask_name(s, name), do: String.replace(s, name, "***")

  # ============================================================
  # 8. 解析：String.to_integer 会崩，Integer.parse 会「部分成功」
  # ============================================================

  @doc """
  `Integer.parse/1` 不抛异常，且允许「前缀是数字、后面还有东西」的部分解析，
  返回 `{整数, 剩余串}`；完全不是数字才返回 `:error`。
  相比之下 `String.to_integer("42px")` 直接抛 ArgumentError。

      iex> Ex08Strings.parse_int("42")
      {:ok, 42, ""}

      iex> Ex08Strings.parse_int("42px")
      {:ok, 42, "px"}

      iex> Ex08Strings.parse_int("abc")
      :error

  """
  @spec parse_int(binary()) :: {:ok, integer(), binary()} | :error
  def parse_int(s) do
    case Integer.parse(s) do
      {n, rest} -> {:ok, n, rest}
      :error -> :error
    end
  end

  @doc """
  charlist（码点整数列表）转二进制，是 `String.to_charlist/1` 的逆操作。

      iex> Ex08Strings.from_codepoints([65, 66])
      "AB"

  """
  @spec from_codepoints([non_neg_integer()]) :: binary()
  def from_codepoints(list), do: List.to_string(list)
end
