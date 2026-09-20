# 第 19 章驱动脚本：cd examples/19_files && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

# 工作区放在系统临时目录下并带唯一后缀；全程只打印相对名与内容，不打印绝对路径。
workspace =
  Path.join(System.tmp_dir!(), "ex19_run_#{:erlang.unique_integer([:positive])}")

File.mkdir_p!(workspace)

alias Ex19Files

IO.puts("==== 19 文件与 IO：tagged tuple、流式读写、Path、iodata、目录、:file pread ====")

# ------------------------------------------------------------
# 1. 写读：! 风格与 tagged tuple 风格
# ------------------------------------------------------------
IO.puts("\n-- 1. File.write/read 返回 :ok 与 {:ok,_}；缺失是 {:error, :enoent} --")
IO.puts("  写后读 => #{inspect(Ex19Files.write_and_read(workspace, "hello.txt", "你好\n"))}")
IO.puts("  读缺失 => #{inspect(Ex19Files.read_missing(workspace))}")

# ------------------------------------------------------------
# 2. 行式流式改写
# ------------------------------------------------------------
IO.puts("\n-- 2. File.stream! 逐行读 → 变换 → Stream.into 逐行写 --")
File.write!(Path.join(workspace, "in.txt"), "cat\ndog\nfish\n")
IO.puts("  大写化结果 => #{inspect(Ex19Files.shout_file(workspace, "in.txt", "out.txt"))}")

# ------------------------------------------------------------
# 3. 恒定内存统计
# ------------------------------------------------------------
IO.puts("\n-- 3. reduce 跑在文件流上：任意时刻只有一行在内存 --")
File.write!(Path.join(workspace, "words.txt"), "the cat\nthe dog sat\none more line\n")
IO.puts("  行/词统计 => #{inspect(Ex19Files.tally(Path.join(workspace, "words.txt")))}")

# ------------------------------------------------------------
# 4. Path：纯字符串
# ------------------------------------------------------------
IO.puts("\n-- 4. Path 只切字符串，不碰文件系统 --")
IO.puts("  拆解 => #{inspect(Ex19Files.describe_path("logs/app.log"))}")
IO.puts("  拼接 => #{inspect(Ex19Files.join_path(["a", "b", "c.txt"]))}")

# ------------------------------------------------------------
# 5. iodata：嵌套列表直接写
# ------------------------------------------------------------
IO.puts("\n-- 5. iodata 免拼接：嵌套列表/字符/字符串的混合树 --")
IO.puts("  {字节数, 摊平} => #{inspect(Ex19Files.iodata_info(["ab", ?c, ["d", ?!]]))}")
table = Ex19Files.table(a: 1, b: 2)
IO.puts("  直接写表 => #{inspect(IO.iodata_to_binary(table))}")

# ------------------------------------------------------------
# 6. 目录树：递归列举（相对路径、排序）与清理
# ------------------------------------------------------------
IO.puts("\n-- 6. mkdir_p 造树；递归相对列举；rm_rf 清理 --")
tree_root = Path.join(workspace, "tree")
IO.puts("  目录树 => #{inspect(Ex19Files.make_tree(tree_root))}")
IO.puts("  删前后存在性 => #{inspect(Ex19Files.exists_then_remove(tree_root))}")

# ------------------------------------------------------------
# 7. :file 定长随机读
# ------------------------------------------------------------
IO.puts("\n-- 7. :file.pread 按偏移读定长记录，不移动顺序位置 --")
IO.puts("  三条 4 字节记录中的第 2 条 => #{inspect(Ex19Files.pread_record(workspace, "rec.bin"))}")

# 收尾：整个工作区删掉（rm_rf 返回的是绝对路径，不打印）。
File.rm_rf!(workspace)
IO.puts("\n工作区清理后存在？ => #{File.exists?(workspace)}")

IO.puts("""
-- 文件 IO 要点 --
  确定路径用 ! 版本（抛异常）；边界/库代码用 tagged tuple 版本
  逐行处理用 File.stream! 接 Stream：读一行、变一行、写一行，内存恒定
  Path.* 是纯字符串函数，从不访问磁盘
  组装输出用 iodata（嵌套列表），交给 IO/File 直接写，省一次大拼接
  临时产物放系统临时目录 + 唯一名；结尾 rm_rf；绝不在确定性输出里打印绝对路径
""")

IO.puts("==== 19 结束 ====")
