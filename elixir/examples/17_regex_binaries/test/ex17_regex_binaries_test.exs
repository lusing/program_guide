defmodule Ex17RegexBinariesTest do
  use ExUnit.Case, async: true

  doctest Ex17RegexBinaries

  alias Ex17RegexBinaries

  describe "正则" do
    test "match? 风格的布尔判定" do
      assert Regex.match?(~r/\d{4}-\d{2}/, "2026-09")
      refute Regex.match?(~r/\d{4}-\d{2}/, "2026")
    end

    test "first_match 取第一个完整匹配，无匹配 nil" do
      assert Ex17RegexBinaries.first_match(~r/[a-z]+/, "12 ab cd") == "ab"
      assert is_nil(Ex17RegexBinaries.first_match(~r/[a-z]+/, "12"))
    end

    test "scan 多捕获保持出现顺序" do
      assert Ex17RegexBinaries.parse_kv("x=9 y=8") == [{"x", "9"}, {"y", "8"}]
    end

    test "replace 只替换第一处（global: false）" do
      assert Regex.replace(~r/\d/, "a1b2c3", "?", global: false) == "a?b2c3"
    end

    test "命名捕获的名字出现在 Regex.names/1" do
      assert Regex.names(~r/(?<y>\d{4})-(?<m>\d{2})/) == ["m", "y"]
    end
  end

  describe "二进制模式" do
    test "默认大端；-little 切换字节序" do
      <<big::16>> = <<1, 0>>
      <<little::16-little>> = <<1, 0>>
      assert {big, little} == {256, 1}
    end

    test "signed-8 补码区间" do
      assert Ex17RegexBinaries.signed_byte(<<128>>) == -128
      assert Ex17RegexBinaries.signed_byte(<<0>>) == 0
    end

    test "nibble 往返：4+4 合回一个字节" do
      %{version: v, type: t} = Ex17RegexBinaries.parse_nibbles(<<0x2B>>)
      assert {v, t} == {2, 11}
      assert <<v::4, t::4>> == <<0x2B>>
    end

    test "RGB565 往返与位边界" do
      bin = Ex17RegexBinaries.pack_rgb565(1, 2, 3)
      assert bin == <<8, 67>>
      assert Ex17RegexBinaries.unpack_rgb565(bin) == [{1, 2, 3}]
    end

    test "::size(n)-unit(8) 等价于 n 字节整字段" do
      <<a::size(2)-unit(8), rest::binary>> = <<"ABCD">>
      assert {a, rest} == {16706, "CD"}
    end
  end

  describe "手写帧" do
    test "异或校验：tag 与 payload 各字节异或" do
      frame = Ex17RegexBinaries.encode_frame(7, "AB")
      # 7 bxor 65 bxor 66 = 4
      assert frame == <<7, 0, 2, 65, 66, 4>>
    end

    test "三帧粘连一次递归吃完" do
      bin =
        Ex17RegexBinaries.encode_frame(1, "a") <>
          Ex17RegexBinaries.encode_frame(2, "bb") <>
          Ex17RegexBinaries.encode_frame(3, "")

      assert {:ok, frames, ""} = Ex17RegexBinaries.parse_frames(bin)

      assert frames == [
               {:frame, 1, "a"},
               {:frame, 2, "bb"},
               {:frame, 3, ""}
             ]
    end

    test "残片：只有帧头的一部分也算 incomplete" do
      partial = <<1, 0, 5, "ab">>
      assert {:incomplete, [], ^partial} = Ex17RegexBinaries.parse_frames(partial)
    end

    test "坏校验时之前已解析的帧仍保留" do
      good = Ex17RegexBinaries.encode_frame(1, "ok")
      bad = <<9, 0, 1, 120, 0>>

      assert {:error, :bad_checksum, 9, [{:frame, 1, "ok"}]} =
               Ex17RegexBinaries.parse_frames(good <> bad)
    end

    test "残帧补全后可接着解析（模拟流式续传）" do
      full = Ex17RegexBinaries.encode_frame(5, "xyz")
      <<head::binary-size(4), tail::binary>> = full
      assert {:incomplete, [], ^head} = Ex17RegexBinaries.parse_frames(head)
      assert {:ok, [{:frame, 5, "xyz"}], ""} = Ex17RegexBinaries.parse_frames(head <> tail)
    end
  end

  describe "Unicode" do
    test "组合字符：字节与码点不同，字素相同" do
      decomposed = "e" <> <<0x301::utf8>>
      assert Ex17RegexBinaries.three_lengths("é") == {2, 1, 1}
      assert Ex17RegexBinaries.three_lengths(decomposed) == {3, 2, 1}
      # 原始字节不同（== 为假），但字素规范化后等价
      assert "é" != decomposed
      assert String.equivalent?("é", decomposed)
    end

    test "::utf8 码点模式逐码点（非逐字节）遍历" do
      cps = for <<cp::utf8 <- "éx">>, do: cp
      assert cps == [0xE9, ?x]
    end

    test "u 修饰符让 \\w 覆盖 Unicode 字母" do
      assert Ex17RegexBinaries.latin_words("café") == ["caf"]
      assert Ex17RegexBinaries.unicode_words("café") == ["café"]
    end
  end
end
