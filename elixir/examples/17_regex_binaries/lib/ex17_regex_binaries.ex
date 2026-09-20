defmodule Ex17RegexBinaries do
  @moduledoc """
  第 17 章示例：正则表达式与二进制模式深入。

  上半部分是 Regex（`~r` 正则字面量、捕获组、命名捕获、scan/replace/split、
  Unicode 修饰符）；下半部分是二进制/位串匹配（字节序、size/unit、非字节对齐、
  `::utf8` 码点），最后用两种手段各写一个完整的小解析器：正则解析键值文本，
  手写二进制帧的编码与递归解析。
  """

  # ------------------------------------------------------------
  # 1. 正则匹配：match? / run / 命名捕获
  # ------------------------------------------------------------

  @doc """
  从文本中找第一个 `YYYY-MM`，用命名捕获取出年月并转成整数；没有匹配返回 `:nomatch`。

      iex> Ex17RegexBinaries.year_month("2026-09 开会")
      {:ok, {2026, 9}}

      iex> Ex17RegexBinaries.year_month("没有日期")
      :nomatch

  """
  @spec year_month(String.t()) :: {:ok, {pos_integer(), pos_integer()}} | :nomatch
  def year_month(text) when is_binary(text) do
    re = ~r/(?<y>\d{4})-(?<m>\d{2})/

    case Regex.named_captures(re, text) do
      %{"y" => y, "m" => m} -> {:ok, {String.to_integer(y), String.to_integer(m)}}
      nil -> :nomatch
    end
  end

  @doc """
  取正则在文本中的第一个完整匹配；无匹配返回 nil。

      iex> Ex17RegexBinaries.first_match(~r/\\d+/, "abc 42 def")
      "42"

      iex> Ex17RegexBinaries.first_match(~r/\d+/, "abc")
      nil

  """
  @spec first_match(Regex.t(), String.t()) :: String.t() | nil
  def first_match(%Regex{} = re, text) do
    case Regex.run(re, text) do
      [whole | _groups] -> whole
      nil -> nil
    end
  end

  # ------------------------------------------------------------
  # 2. 捕获迭代：scan / replace / split
  # ------------------------------------------------------------

  @doc """
  扫描全部 `key=value`，返回 `{键, 值}` 列表，按出现顺序排列。

      iex> Ex17RegexBinaries.parse_kv("a=1 b=2 c=3")
      [{"a", "1"}, {"b", "2"}, {"c", "3"}]

      iex> Ex17RegexBinaries.parse_kv("什么都没有")
      []

  """
  @spec parse_kv(String.t()) :: [{String.t(), String.t()}]
  def parse_kv(text) when is_binary(text) do
    re = ~r/(\w+)=(\w+)/

    for [_whole, key, val] <- Regex.scan(re, text), do: {key, val}
  end

  @doc """
  把 11 位手机号中间 4 位打码：捕获前 3 位，用反向引用 `\\1` 保留。

      iex> Ex17RegexBinaries.mask_phone("call 13812345678 now")
      "call 138****5678 now"

  """
  @spec mask_phone(String.t()) :: String.t()
  def mask_phone(text) when is_binary(text) do
    Regex.replace(~r/(\d{3})\d{4}(\d{4})/, text, "\\1****\\2")
  end

  @doc """
  按连续空白切词，`:trim` 去掉首尾空串。

      iex> Ex17RegexBinaries.words("  foo   bar baz ")
      ["foo", "bar", "baz"]

  """
  @spec words(String.t()) :: [String.t()]
  def words(text) when is_binary(text) do
    Regex.split(~r/\s+/, text, trim: true)
  end

  # ------------------------------------------------------------
  # 3. 二进制模式：定长字段、字节序、剩余二进制
  # ------------------------------------------------------------

  @doc """
  解析一个小端 16 位 x + 大端 16 位 y + 剩余字节的定长记录。

      iex> Ex17RegexBinaries.parse_point(<<1, 0, 0, 2, "z">>)
      %{point: {1, 2}, rest: "z"}

  """
  @spec parse_point(binary()) :: %{point: {non_neg_integer(), non_neg_integer()}, rest: binary()}
  def parse_point(<<x::16-little, y::16-big, rest::binary>>) do
    %{point: {x, y}, rest: rest}
  end

  @doc """
  按有符号 8 位解释一个字节：255 是 -1 的补码。

      iex> Ex17RegexBinaries.signed_byte(<<255>>)
      -1

      iex> Ex17RegexBinaries.signed_byte(<<127>>)
      127

  """
  @spec signed_byte(binary()) :: integer()
  def signed_byte(<<n::signed-8>>), do: n

  # ------------------------------------------------------------
  # 4. 位级模式：size/unit 与非字节对齐
  # ------------------------------------------------------------

  @doc """
  一个字节拆成两个 4 位字段：高 4 位版本号、低 4 位类型。

      iex> Ex17RegexBinaries.parse_nibbles(<<0xA3>>)
      %{version: 10, type: 3}

  """
  @spec parse_nibbles(binary()) :: %{version: 0..15, type: 0..15}
  def parse_nibbles(<<version::4, type::4>>) do
    %{version: version, type: type}
  end

  @doc """
  把 RGB 三通道压进 16 位 RGB565（红 5 位、绿 6 位、蓝 5 位）。

      iex> Ex17RegexBinaries.pack_rgb565(31, 63, 31)
      <<255, 255>>

      iex> Ex17RegexBinaries.pack_rgb565(1, 2, 3)
      <<8, 67>>

  """
  @spec pack_rgb565(0..31, 0..63, 0..31) :: binary()
  def pack_rgb565(r, g, b) do
    <<r::5, g::6, b::5>>
  end

  @doc """
  从连续的 16 位字里解出全部 RGB565 像素（位串推导）。

      iex> Ex17RegexBinaries.unpack_rgb565(<<255, 255, 0, 0>>)
      [{31, 63, 31}, {0, 0, 0}]

  """
  @spec unpack_rgb565(binary()) :: [{0..31, 0..63, 0..31}]
  def unpack_rgb565(bin) do
    for <<r::5, g::6, b::5 <- bin>>, do: {r, g, b}
  end

  # ------------------------------------------------------------
  # 5/6. 手写二进制帧：tag(1) + len(2, 大端) + payload(len) + xor 校验(1)
  # ------------------------------------------------------------

  @doc """
  编码一帧。校验字节 = tag 与 payload 各字节的异或。

      iex> Ex17RegexBinaries.encode_frame(1, "hi")
      <<1, 0, 2, 104, 105, 0>>

  """
  @spec encode_frame(byte(), binary()) :: binary()
  def encode_frame(tag, payload) when is_integer(tag) and is_binary(payload) do
    <<tag, byte_size(payload)::16, payload::binary, checksum(tag, payload)>>
  end

  @doc """
  递归解析 0~n 帧（支持多帧粘连）。返回：

  - `{:ok, 帧列表, ""}`：恰好吃完；
  - `{:incomplete, 已解析帧, 残片}`：尾部不够一帧（流场景下等更多字节）；
  - `{:error, :bad_checksum, tag, 已解析帧}`：校验不符，停在坏帧处。

      iex> bin = Ex17RegexBinaries.encode_frame(1, "hi") <>
      iex>        Ex17RegexBinaries.encode_frame(2, "ok")
      iex> Ex17RegexBinaries.parse_frames(bin)
      {:ok, [{:frame, 1, "hi"}, {:frame, 2, "ok"}], ""}

      iex> Ex17RegexBinaries.parse_frames(<<1, 0, 2, 104, 105, 99>>)
      {:error, :bad_checksum, 1, []}

      iex> Ex17RegexBinaries.parse_frames(
      iex>   Ex17RegexBinaries.encode_frame(1, "hi") <> <<255>>
      iex> )
      {:incomplete, [{:frame, 1, "hi"}], <<255>>}

  """
  @spec parse_frames(binary()) ::
          {:ok, [{:frame, byte(), binary()}], binary()}
          | {:incomplete, [{:frame, byte(), binary()}], binary()}
          | {:error, :bad_checksum, byte(), [{:frame, byte(), binary()}]}
  def parse_frames(bin) when is_binary(bin), do: parse_frames(bin, [])

  defp parse_frames(<<tag, len::16, payload::binary-size(len), sum, rest::binary>>, acc) do
    if checksum(tag, payload) == sum do
      parse_frames(rest, [{:frame, tag, payload} | acc])
    else
      {:error, :bad_checksum, tag, Enum.reverse(acc)}
    end
  end

  defp parse_frames(<<>>, acc), do: {:ok, Enum.reverse(acc), ""}
  defp parse_frames(leftover, acc), do: {:incomplete, Enum.reverse(acc), leftover}

  defp checksum(tag, payload) do
    Enum.reduce(:binary.bin_to_list(payload), tag, fn byte, acc ->
      :erlang.bxor(byte, acc)
    end)
  end

  # ------------------------------------------------------------
  # 7. Unicode：字节 / 码点 / 字素 三层长度
  # ------------------------------------------------------------

  @doc """
  返回 `{字节数, 码点数, 字素数}`。同一个视觉字符 é 有两种编码：
  单码点 U+00E9（2 字节）与 `e + 组合重音 U+0301`（3 字节、2 码点），
  但字素数都是 1。

      iex> Ex17RegexBinaries.three_lengths("é")
      {2, 1, 1}

      iex> Ex17RegexBinaries.three_lengths("e" <> <<0x301::utf8>>)
      {3, 2, 1}

  """
  @spec three_lengths(String.t()) :: {non_neg_integer(), non_neg_integer(), non_neg_integer()}
  def three_lengths(text) when is_binary(text) do
    {
      byte_size(text),
      length(String.codepoints(text)),
      length(String.graphemes(text))
    }
  end

  @doc """
  不加 `u` 修饰符时，`\\w` 只认 ASCII，é 的多字节序列会切断单词。

      iex> Ex17RegexBinaries.latin_words("café")
      ["caf"]

  """
  @spec latin_words(String.t()) :: [String.t()]
  def latin_words(text) do
    Regex.scan(~r/\w+/, text) |> Enum.map(&hd/1)
  end

  @doc """
  加 `u` 修饰符后按 Unicode 字符类匹配，整个词完整取出。

      iex> Ex17RegexBinaries.unicode_words("café")
      ["café"]

  """
  @spec unicode_words(String.t()) :: [String.t()]
  def unicode_words(text) do
    Regex.scan(~r/\w+/u, text) |> Enum.map(&hd/1)
  end
end
