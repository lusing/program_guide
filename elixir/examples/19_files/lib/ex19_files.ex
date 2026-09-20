defmodule Ex19Files do
  @moduledoc """
  第 19 章示例：文件与 IO。

  File 模块的两类接口（带 ! 直接抛 / 不带 ! 返回 `{:ok, _}`、`{:error, reason}`）、
  File.stream! 按行流式处理大文件、Path 纯字符串工具、iodata 免拼接、
  目录递归与临时工作区、底层 :file 模块的定长随机读（pread）。

  所有函数都接收工作目录参数——路径由调用方提供（run.exs/测试在系统临时目录下
  造唯一目录），库代码不写死绝对路径。
  """

  # ------------------------------------------------------------
  # 1. 写读文件：tagged tuple 与异常两种风格
  # ------------------------------------------------------------

  @doc """
  写入再读回，返回 File.read/1 的 tagged tuple。

      iex> dir = Path.join(System.tmp_dir!(), "ex19_doctest_#{:erlang.unique_integer([:positive])}")
      iex> File.mkdir_p!(dir)
      iex> result = Ex19Files.write_and_read(dir, "a.txt", "你好")
      iex> File.rm_rf!(dir)
      iex> result
      {:ok, "你好"}

  """
  @spec write_and_read(Path.t(), Path.t(), iodata()) :: {:ok, binary()} | {:error, term()}
  def write_and_read(dir, name, content) do
    path = Path.join(dir, name)
    :ok = File.write(path, content)
    File.read(path)
  end

  @doc """
  读不存在的文件：返回 `{:error, :enoent}` 而不是抛异常。

      iex> Ex19Files.read_missing(System.tmp_dir!())
      {:error, :enoent}

  """
  @spec read_missing(Path.t()) :: {:error, :enoent}
  def read_missing(dir) do
    File.read(Path.join(dir, "ex19_no_such_file_#{:erlang.unique_integer([:positive])}"))
  end

  # ------------------------------------------------------------
  # 2. 行式流式改写：File.stream! + Stream.into
  # ------------------------------------------------------------

  @doc """
  把源文件每行大写化后流式写入目标文件（逐行经过，不整读），返回目标全文。

      iex> dir = Path.join(System.tmp_dir!(), "ex19_doctest_#{:erlang.unique_integer([:positive])}")
      iex> File.mkdir_p!(dir)
      iex> File.write!(Path.join(dir, "in.txt"), "cat\\ndog\\n")
      iex> result = Ex19Files.shout_file(dir, "in.txt", "out.txt")
      iex> File.rm_rf!(dir)
      iex> result
      "CAT\\nDOG\\n"

  """
  @spec shout_file(Path.t(), Path.t(), Path.t()) :: binary()
  def shout_file(dir, src, dst) do
    src_path = Path.join(dir, src)
    dst_path = Path.join(dir, dst)

    File.stream!(src_path)
    |> Stream.map(fn line -> String.upcase(String.trim_trailing(line)) <> "\n" end)
    |> Stream.into(File.stream!(dst_path))
    |> Stream.run()

    File.read!(dst_path)
  end

  # ------------------------------------------------------------
  # 3. 恒定内存统计：逐行 reduce，不整读
  # ------------------------------------------------------------

  @doc """
  逐行统计行数与单词数：Enum.reduce 跑在文件流上，任意时刻只有一行在内存。

      iex> dir = Path.join(System.tmp_dir!(), "ex19_doctest_#{:erlang.unique_integer([:positive])}")
      iex> File.mkdir_p!(dir)
      iex> path = Path.join(dir, "t.txt")
      iex> File.write!(path, "the cat\\nthe dog sat\\n")
      iex> result = Ex19Files.tally(path)
      iex> File.rm_rf!(dir)
      iex> result
      %{lines: 2, words: 5}

  """
  @spec tally(Path.t()) :: %{lines: non_neg_integer(), words: non_neg_integer()}
  def tally(path) do
    File.stream!(path)
    |> Enum.reduce(%{lines: 0, words: 0}, fn line, acc ->
      %{acc | lines: acc.lines + 1, words: acc.words + length(String.split(line))}
    end)
  end

  # ------------------------------------------------------------
  # 4. Path：只处理字符串，不碰文件系统
  # ------------------------------------------------------------

  @doc """
  拆解路径各部分。Path 是纯字符串工具——文件可以根本不存在。

      iex> Ex19Files.describe_path("logs/app.log")
      %{base: "app.log", dir: "logs", ext: ".log", root: "app"}

  """
  @spec describe_path(Path.t()) :: %{
          base: String.t(),
          dir: String.t(),
          ext: String.t(),
          root: String.t()
        }
  def describe_path(p) do
    %{
      dir: Path.dirname(p),
      base: Path.basename(p),
      ext: Path.extname(p),
      root: Path.basename(Path.rootname(p))
    }
  end

  @doc """
  Path.join 拼接，自动处理斜杠。

      iex> Ex19Files.join_path(["a", "b", "c.txt"])
      "a/b/c.txt"

  """
  @spec join_path([Path.t()]) :: Path.t()
  def join_path(parts), do: Path.join(parts)

  # ------------------------------------------------------------
  # 5. iodata：嵌套列表即字节序列，免扁平化
  # ------------------------------------------------------------

  @doc """
  iodata 是「字符串/字节/嵌套列表」的混合树，文件与套接字可以直接写，
  不必先拼成一个大二进制。返回 {字节数, 最终字符串}。

      iex> Ex19Files.iodata_info(["ab", ?c, ["d", ?!]])
      {5, "abcd!"}

  """
  @spec iodata_info(iodata()) :: {non_neg_integer(), binary()}
  def iodata_info(data) do
    {IO.iodata_length(data), IO.iodata_to_binary(data)}
  end

  @doc """
  用嵌套列表拼一张小表（典型的报表/协议响应构造）。

      iex> Ex19Files.table(a: 1, b: 2)
      ["# 表格\\n", [["a", " = ", "1", 10], ["b", " = ", "2", 10]]]

  """
  @spec table(keyword()) :: iolist()
  def table(rows) do
    [
      "# 表格\n",
      Enum.map(rows, fn {k, v} -> [to_string(k), " = ", to_string(v), ?\n] end)
    ]
  end

  # ------------------------------------------------------------
  # 6. 目录：递归列举（相对路径、排序）与清理
  # ------------------------------------------------------------

  @doc """
  造一棵小目录树并递归列出相对路径（目录以 / 结尾；结果排序，确定性）。

      iex> dir = Path.join(System.tmp_dir!(), "ex19_doctest_#{:erlang.unique_integer([:positive])}")
      iex> result = Ex19Files.make_tree(dir)
      iex> File.rm_rf!(dir)
      iex> result
      ["a.txt", "logs/", "logs/b.txt", "logs/c.log"]

  """
  @spec make_tree(Path.t()) :: [String.t()]
  def make_tree(root) do
    logs = Path.join(root, "logs")
    File.mkdir_p!(logs)
    File.write!(Path.join(root, "a.txt"), "A")
    File.write!(Path.join(logs, "b.txt"), "B")
    File.write!(Path.join(logs, "c.log"), "C")
    listing(root)
  end

  @doc """
  确认路径存在；rm_rf 后再查一次。

      iex> dir = Path.join(System.tmp_dir!(), "ex19_doctest_#{:erlang.unique_integer([:positive])}")
      iex> File.mkdir_p!(dir)
      iex> Ex19Files.exists_then_remove(dir)
      %{after: false, before: true}

  """
  @spec exists_then_remove(Path.t()) :: %{before: boolean(), after: false}
  def exists_then_remove(path) do
    before? = File.exists?(path)
    _ = File.rm_rf(path)
    %{before: before?, after: File.exists?(path)}
  end

  defp listing(root) do
    walk_relative(root, "")
  end

  defp walk_relative(abs_dir, prefix) do
    {:ok, entries} = File.ls(abs_dir)

    entries
    |> Enum.sort()
    |> Enum.flat_map(fn e ->
      abs_path = Path.join(abs_dir, e)
      rel = if prefix == "", do: e, else: Path.join(prefix, e)

      if File.dir?(abs_path) do
        [rel <> "/" | walk_relative(abs_path, rel)]
      else
        [rel]
      end
    end)
  end

  # ------------------------------------------------------------
  # 7. 底层 :file：定长随机读 pread
  # ------------------------------------------------------------

  @doc """
  写三条 4 字节定长记录，用 :file.pread 按偏移随机读第 2 条
  （pread 不移动顺序读位置，适合并发读同一文件句柄）。

      iex> dir = Path.join(System.tmp_dir!(), "ex19_doctest_#{:erlang.unique_integer([:positive])}")
      iex> File.mkdir_p!(dir)
      iex> result = Ex19Files.pread_record(dir, "rec.bin")
      iex> File.rm_rf!(dir)
      iex> result
      {:ok, "BBBB"}

  """
  @spec pread_record(Path.t(), Path.t()) :: {:ok, binary()} | {:error, term()}
  def pread_record(dir, name) do
    path = Path.join(dir, name)
    File.write!(path, "AAAA" <> "BBBB" <> "CCCC")

    File.open!(path, [:raw, :read], fn fd ->
      :file.pread(fd, 4, 4)
    end)
  end
end
