defmodule Ex08StringsTest do
  use ExUnit.Case, async: true

  doctest Ex08Strings

  # 全部非 ASCII 字面量都用转义写，避免源码编码/规范化层面的歧义。
  @nfc "\u00E9"
  @nfd "e\u0301"
  @family "\u{1F468}\u200D\u{1F469}\u200D\u{1F467}"
  @wave "\u{1F44B}"
  @tone "\u{1F44D}\u{1F3FD}"

  describe "三个单位" do
    test "NFC \u00E9：2 字节 / 1 码点 / 1 字素" do
      assert Ex08Strings.units(@nfc) == %{bytes: 2, codepoints: 1, graphemes: 1}
    end

    test "NFD e+组合重音：3 字节 / 2 码点 / 1 字素" do
      assert Ex08Strings.units(@nfd) == %{bytes: 3, codepoints: 2, graphemes: 1}
    end

    test "ZWJ 家庭 emoji：18 字节 / 5 码点 / 1 字素" do
      assert Ex08Strings.units(@family) == %{bytes: 18, codepoints: 5, graphemes: 1}
    end

    test "肤色修饰：8 字节 / 2 码点 / 1 字素" do
      assert Ex08Strings.units(@tone) == %{bytes: 8, codepoints: 2, graphemes: 1}
    end

    test "挥手 emoji：4 字节 / 1 码点 / 1 字素" do
      assert Ex08Strings.units(@wave) == %{bytes: 4, codepoints: 1, graphemes: 1}
    end

    test "模块访问器与本地转义一致" do
      assert Ex08Strings.nfc_eacute() == @nfc
      assert Ex08Strings.nfd_eacute() == @nfd
      assert Ex08Strings.family() == @family
    end
  end

  describe "规范化" do
    test "NFC 与 NFD 字节不同但规范等价" do
      refute @nfc == @nfd
      assert byte_size(@nfc) == 2
      assert byte_size(@nfd) == 3
      assert Ex08Strings.equivalent?(@nfc, @nfd)
      assert String.equivalent?(@nfc, @nfd)
    end

    test "NFD 经 to_nfc/1 后与 NFC 字节相等" do
      assert Ex08Strings.to_nfc(@nfd) == @nfc
      assert Ex08Strings.to_nfc("abc") == "abc"
    end
  end

  describe "大小写" do
    test "德语 \u00DF 大写展开为 SS，长度变化且不可逆" do
      report = Ex08Strings.case_report("stra\u00DFe")
      assert report.up == "STRASSE"
      assert report.roundtrip? == false
      assert report.delta == 1
    end

    test "纯 ASCII 往返一致" do
      assert Ex08Strings.case_report("abc") ==
               %{up: "ABC", down: "abc", roundtrip?: true, delta: 0}
    end

    test "土耳其语 I 的小写是 U+0131 无点 i" do
      assert Ex08Strings.turkish_lower_i() == "ı"
      assert String.downcase("I") == "i"
    end

    test ":ascii 模式不碰非 ASCII 字符" do
      assert Ex08Strings.ascii_upcase(@nfc) == @nfc
      assert String.upcase(@nfc) == "\u00C9"
    end
  end

  describe "字节切 vs 字素切" do
    test "String.at 按字素取，binary_part 按字节切" do
      assert Ex08Strings.first_grapheme(@nfc) == @nfc
      assert Ex08Strings.first_byte("A") == 65
      assert Ex08Strings.first_byte(@nfc) == 0xC3
      assert Ex08Strings.first_byte_valid?("A")
      refute Ex08Strings.first_byte_valid?(@nfc)
      refute String.valid?(binary_part(@nfc, 0, 1))
    end
  end

  describe "二进制模式遍历" do
    test "码点整数列表" do
      assert Ex08Strings.codepoint_ints("AB") == [65, 66]
      assert Ex08Strings.codepoint_ints(@nfc) == [0xE9]
      assert Ex08Strings.codepoint_ints(@nfd) == [?e, 0x0301]
      assert Ex08Strings.codepoint_ints(@wave) == [0x1F44B]
      assert Ex08Strings.codepoint_ints("") == []
    end

    test "字节列表暴露 UTF-8 编码" do
      assert Ex08Strings.byte_ints("AB") == [65, 66]
      assert Ex08Strings.byte_ints(@nfc) == [0xC3, 0xA9]
      assert Ex08Strings.byte_ints(@wave) == [0xF0, 0x9F, 0x91, 0x8B]
    end

    test "从码点构造，emoji 自动编成 4 字节" do
      assert Ex08Strings.from_codepoint(0xE9) == @nfc
      assert Ex08Strings.from_codepoint(0x1F44B) == @wave
      assert byte_size(Ex08Strings.from_codepoint(0x1F44B)) == 4
    end

    test "码点列表往返" do
      s = "abc\u00E9\u{1F44B}"
      assert s |> Ex08Strings.codepoint_ints() |> Ex08Strings.from_codepoints() == s
    end
  end

  describe "iodata" do
    test "嵌套的二进制与码点列表直接被 IO 接受" do
      data = ["a", ~c"b", [?c], @nfc]
      assert IO.iodata_to_binary(data) == "abc\u00E9"
      assert Ex08Strings.iodata_bytes(data) == 5
      assert Ex08Strings.banner("x") |> IO.iodata_to_binary() == "== x =="
    end
  end

  describe "常用操作" do
    test "words/2 处理两端与连续空格" do
      assert Ex08Strings.words("  a   b c ") == ["a", "b", "c"]
    end

    test "pad / reverse 按字素工作" do
      assert Ex08Strings.pad_id("7") == "00007"
      assert Ex08Strings.reverse_graphemes("abc") == "cba"
      # 反转 emoji 不会切成半个
      assert Ex08Strings.reverse_graphemes("a#{@wave}b") == "b#{@wave}a"
    end

    test "后缀判定大小写敏感" do
      assert Ex08Strings.kind_of_file?("x.txt", ".txt")
      refute Ex08Strings.kind_of_file?("x.TXT", ".txt")
    end

    test "字面量替换" do
      assert Ex08Strings.mask_name("hi Ada bye", "Ada") == "hi *** bye"
    end
  end

  describe "解析" do
    test "Integer.parse 部分成功，String.to_integer 直接崩" do
      assert Ex08Strings.parse_int("42") == {:ok, 42, ""}
      assert Ex08Strings.parse_int("42px") == {:ok, 42, "px"}
      assert Ex08Strings.parse_int("abc") == :error

      assert_raise ArgumentError, fn -> String.to_integer("42px") end
    end
  end
end
