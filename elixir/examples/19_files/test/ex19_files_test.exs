defmodule Ex19FilesTest do
  use ExUnit.Case, async: true

  doctest Ex19Files

  alias Ex19Files

  describe "读写与 tagged tuple" do
    test "写入再读回" do
      dir = tmp_dir()
      assert Ex19Files.write_and_read(dir, "x.bin", <<1, 2, 3>>) == {:ok, <<1, 2, 3>>}
    end

    test "缺失文件 {:error, :enoent}；read! 版本抛异常" do
      dir = tmp_dir()
      assert Ex19Files.read_missing(dir) == {:error, :enoent}

      assert_raise File.Error, fn ->
        File.read!(Path.join(dir, "missing"))
      end
    end

    test "File.write 对不可写路径返回 error tuple" do
      dir = tmp_dir()
      path = Path.join(dir, "missing_dir")
      # 父目录不存在：write 不抛，返回 tagged error
      assert {:error, :enoent} = File.write(Path.join(path, "f"), "x")
    end
  end

  describe "流式读写" do
    test "shout_file 逐行大写" do
      dir = tmp_dir()
      File.write!(Path.join(dir, "in.txt"), "abc\nxyz\n")
      assert Ex19Files.shout_file(dir, "in.txt", "out.txt") == "ABC\nXYZ\n"
    end

    test "tally 大行数也只逐行流过" do
      dir = tmp_dir()
      path = Path.join(dir, "big.txt")

      stream =
        Stream.repeatedly(fn -> "one two three\n" end)
        |> Enum.take(100)

      File.write!(path, stream)
      assert Ex19Files.tally(path) == %{lines: 100, words: 300}
    end

    test "File.stream! 默认按行、行尾保留" do
      dir = tmp_dir()
      path = Path.join(dir, "l.txt")
      File.write!(path, "a\nb")
      assert File.stream!(path) |> Enum.to_list() == ["a\n", "b"]
    end
  end

  describe "Path" do
    test "各拆解函数" do
      assert Ex19Files.describe_path("logs/app.log") ==
               %{dir: "logs", base: "app.log", ext: ".log", root: "app"}
    end

    test "join 自动处理多余斜杠" do
      assert Ex19Files.join_path(["a/", "/b/", "c"]) == "a/b/c"
    end

    test "Path 函数不触碰文件系统" do
      # 不存在的路径照样能算
      assert Path.dirname("/no/such/thing/x") == "/no/such/thing"
    end
  end

  describe "iodata" do
    test "嵌套列表的字节数与摊平" do
      assert Ex19Files.iodata_info(["a", ~c"b", [?c]]) == {3, "abc"}
    end

    test "table 结构是可直接写出的嵌套列表" do
      bin = Ex19Files.table(a: 1) |> IO.iodata_to_binary()
      assert bin == "# 表格\na = 1\n"
    end

    test "字符列表（charlist）也是 iodata" do
      assert IO.iodata_to_binary([?h, ?i]) == "hi"
    end
  end

  describe "目录" do
    test "make_tree 相对路径排序列举，目录带斜杠" do
      dir = tmp_dir()
      assert Ex19Files.make_tree(dir) == ["a.txt", "logs/", "logs/b.txt", "logs/c.log"]
    end

    test "exists_then_remove" do
      dir = tmp_dir()
      assert Ex19Files.exists_then_remove(dir) == %{after: false, before: true}
    end

    test "File.ls 不保证顺序，使用方要自己 sort" do
      dir = tmp_dir()

      for name <- ["c", "a", "b"], do: File.write!(Path.join(dir, name), "")

      {:ok, raw} = File.ls(dir)
      assert Enum.sort(raw) == ["a", "b", "c"]
    end
  end

  describe ":file" do
    test "pread 按偏移定长随机读" do
      dir = tmp_dir()
      assert Ex19Files.pread_record(dir, "r.bin") == {:ok, "BBBB"}
    end

    test "pread 按偏移读；顺序位置是否被移动取决于平台" do
      dir = tmp_dir()
      path = Path.join(dir, "s.bin")
      File.write!(path, "0123456789")

      result =
        File.open!(path, [:raw, :read], fn fd ->
          {:file.pread(fd, 5, 2), :file.read(fd, 3)}
        end)

      # 随机读本身两个平台都按偏移拿 "56"；之后的顺序读则不同：
      # Unix 上 pread 不动顺序位置（从头拿 "012"）；Windows 实测 raw 文件的
      # pread 由底层 SetFilePointer+ReadFile 模拟，指针被挪到读末尾（拿 "789"）。
      # 可移植代码不能依赖 pread 之后的顺序位置——要顺序读就显式 :file.position。
      seq =
        case :os.type() do
          {:win32, _} -> {:ok, "789"}
          _ -> {:ok, "012"}
        end

      assert result == {{:ok, "56"}, seq}
    end

    test "raw 模式直接写字节，无字符串编码转换" do
      dir = tmp_dir()
      path = Path.join(dir, "raw.bin")

      :ok =
        File.open!(path, [:raw, :write], fn fd ->
          :file.write(fd, <<0, 1, 255>>)
        end)

      assert File.read!(path) == <<0, 1, 255>>
    end
  end

  defp tmp_dir do
    dir = Path.join(System.tmp_dir!(), "ex19_test_#{:erlang.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    dir
  end
end
