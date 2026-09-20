defmodule Ex24Capstone.PureTest do
  use ExUnit.Case, async: true

  doctest Ex24Capstone

  alias Ex24Capstone

  test "tokenize 空串与纯标点为空" do
    assert Ex24Capstone.tokenize("") == []
    assert Ex24Capstone.tokenize("!!! ...") == []
  end

  test "merge_counts 满足交换结合（用于并发归并）" do
    a = %{"x" => 1}
    b = %{"x" => 2}
    c = %{"y" => 3}

    assert Ex24Capstone.merge_counts(Ex24Capstone.merge_counts(a, b), c) ==
             Ex24Capstone.merge_counts(a, Ex24Capstone.merge_counts(b, c))
  end

  test "top_n n 大于词数时全部返回" do
    assert Ex24Capstone.top_n(%{"a" => 1}, 5) == [{"a", 1}]
  end
end

defmodule Ex24Capstone.IntegrationTest do
  use ExUnit.Case, async: false

  alias Ex24Capstone.{Cache, Words}

  defp tmp_dir do
    dir = Path.join(System.tmp_dir!(), "ex24test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  defp make_corpus(dir) do
    File.write!(Path.join(dir, "a.txt"), "hello world\nhello beam\n")
    File.write!(Path.join(dir, "b.txt"), "world of beam\n")
    File.write!(Path.join(dir, "c.txt"), "你好 世界\n世界 beam\n")
    File.write!(Path.join(dir, "skip.md"), "hello\n")
    dir
  end

  describe "Cache" do
    test "put/get/size/keys/delete（用唯一 key 避免跨用例污染）" do
      key = :"k#{System.unique_integer([:positive])}"
      assert Cache.put(key, 7) == :ok
      assert Cache.get(key) == 7
      assert key in Cache.keys()
      assert Cache.delete(key) == :ok
      assert Cache.get(key) == nil
    end

    test "被杀后监督重启：新进程、状态清空、仍可写" do
      Cache.put(:restart_probe, 1)
      Process.exit(Process.whereis(Cache), :kill)

      Enum.reduce_while(1..50, nil, fn _, _ ->
        if Process.whereis(Cache), do: {:halt, :ok}, else: {:cont, Process.sleep(20)}
      end)

      assert Cache.get(:restart_probe) == nil
      assert Cache.put(:after_restart, :yes) == :ok
      assert Cache.get(:after_restart) == :yes
    end
  end

  describe "Words 并发词频" do
    setup do
      [dir: make_corpus(tmp_dir())]
    end

    test "非 txt 忽略；合并计数正确", %{dir: dir} do
      result = Words.count_dir(dir)
      names = Enum.map(result.file_counts, &elem(&1, 0))
      assert names == ["a.txt", "b.txt", "c.txt"]

      assert result.merged == %{
               "hello" => 2,
               "world" => 2,
               "beam" => 3,
               "of" => 1,
               "你好" => 1,
               "世界" => 2
             }
    end

    test "top3 排序确定", %{dir: dir} do
      result = Words.count_dir(dir)

      assert Ex24Capstone.top_n(result.merged, 3) ==
               [{"beam", 3}, {"hello", 2}, {"world", 2}]
    end

    test "kill_first：worker 被杀后自动重试，结果一致", %{dir: dir} do
      normal = Words.count_dir(dir)
      killed = Words.count_dir(dir, kill_first: ["c.txt"])

      assert killed.kill_tags == [{:killed, "c.txt", :killed}]
      assert killed.merged == normal.merged
    end

    test "空目录返回空结果" do
      dir = tmp_dir()
      result = Words.count_dir(dir)
      assert result.file_counts == []
      assert result.merged == %{}
      assert result.kill_tags == []
    end
  end
end
