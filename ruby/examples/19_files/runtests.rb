# 19 测试层：minitest 套件（自包含，不 require main.rb —— 避免把演示输出打进测试结果）
# frozen_string_literal: true
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "tempfile"
require "json"

class TestFiles < Minitest::Test
  def test_write_read_roundtrip_utf8
    Dir.mktmpdir do |dir|
      path = File.join(dir, "greeting.txt")
      text = "你好，Ruby！\n文件 IO 第一行"
      File.write(path, text)
      assert_equal text, File.read(path)
      assert_equal text.bytesize, File.write(path, text)
      assert_equal Encoding::UTF_8, File.read(path).encoding
    end
  end

  def test_open_block_auto_close_and_append
    Dir.mktmpdir do |dir|
      path = File.join(dir, "log.txt")
      File.open(path, "w") do |f|
        f.puts("第一行")
        f.puts("第二行")
      end
      File.open(path, "a") { |f| f.puts("追加行") }
      assert_equal "第一行\n第二行\n追加行\n", File.read(path)
      File.open(path, "w") { |f| f.puts("覆盖") }
      assert_equal "覆盖\n", File.read(path)
    end
  end

  def test_each_line_lineno_and_readlines
    Dir.mktmpdir do |dir|
      path = File.join(dir, "poem.txt")
      File.write(path, "春眠不觉晓\n处处闻啼鸟\n夜来风雨声\n")
      seen = []
      File.open(path) do |f|
        f.each_line { |line| seen << [f.lineno, line.strip] }
      end
      assert_equal [[1, "春眠不觉晓"], [2, "处处闻啼鸟"], [3, "夜来风雨声"]], seen
      assert_equal %w[春眠不觉晓 处处闻啼鸟 夜来风雨声],
                   File.readlines(path, chomp: true)
    end
  end

  def test_dir_glob_patterns
    Dir.mktmpdir do |dir|
      %w[report.txt notes.md image.png data.txt].each { |n| File.write(File.join(dir, n), n) }
      FileUtils.mkdir_p(File.join(dir, "sub"))
      File.write(File.join(dir, "sub", "nested.txt"), "n")
      names = Dir.glob(File.join(dir, "*.txt")).map { |p| File.basename(p) }.sort
      assert_equal %w[data.txt report.txt], names
      recursive = Dir.glob(File.join(dir, "**", "*.txt")).map { |p| File.basename(p) }.sort
      assert_equal %w[data.txt nested.txt report.txt], recursive
      assert_equal %w[data.txt image.png notes.md report.txt sub], Dir.children(dir).sort
    end
  end

  def test_fileutils_operations
    Dir.mktmpdir do |dir|
      dst = File.join(dir, "dst", "deep")
      FileUtils.mkdir_p(dst)
      FileUtils.mkdir_p(dst) # 幂等
      assert File.directory?(dst)
      File.write(File.join(dir, "payload.txt"), "数据")
      FileUtils.cp(File.join(dir, "payload.txt"), File.join(dst, "copy.txt"))
      assert_equal "数据", File.read(File.join(dst, "copy.txt"))
      FileUtils.mv(File.join(dst, "copy.txt"), File.join(dir, "moved.txt"))
      refute File.exist?(File.join(dst, "copy.txt"))
      assert File.exist?(File.join(dir, "moved.txt"))
      FileUtils.rm_f(File.join(dir, "moved.txt"))
      FileUtils.rm_f(File.join(dir, "从不存在.txt")) # 不存在也不抛错
      refute File.exist?(File.join(dir, "moved.txt"))
    end
  end

  def test_pathname_operations
    Dir.mktmpdir do |dir|
      pn = Pathname(dir) + "demo.txt"
      pn.write("路径也是对象")
      assert_equal "路径也是对象", pn.read
      assert pn.file?
      refute pn.directory?
      assert_equal ".txt", pn.extname
      assert_equal "demo.txt", pn.basename.to_s
      chain = Pathname(dir) + "a" + "b.txt"
      assert_equal File.join(dir, "a", "b.txt"), chain.to_s
    end
  end

  def test_tempfile_create_block
    Tempfile.create("tut19") do |f|
      f.write("临时数据 42")
      f.rewind
      assert_equal "临时数据 42", f.read
      assert File.exist?(f.path)
    end
  end

  def test_json_roundtrip
    Dir.mktmpdir do |dir|
      path = File.join(dir, "data.json")
      data = { "名称" => "迷你笔记", "版本" => 4, "标签" => ["ruby", "io"] }
      File.write(path, JSON.pretty_generate(data))
      assert_equal data, JSON.parse(File.read(path))
      assert_equal "迷你笔记", JSON.parse(File.read(path), symbolize_names: true)[:名称]
    end
  end

  def test_filetest_predicates
    Dir.mktmpdir do |dir|
      path = File.join(dir, "sized.txt")
      refute FileTest.exist?(path)
      File.write(path, "12345")
      assert FileTest.exist?(path)
      assert FileTest.file?(path)
      assert_equal 5, FileTest.size(path)
      assert_equal 5, FileTest.size?(path)
      assert FileTest.readable?(path)
      assert FileTest.writable?(path)
      empty = File.join(dir, "empty.txt")
      FileUtils.touch(empty)
      assert FileTest.zero?(empty)
      assert_nil FileTest.size?(empty)
    end
  end

  def test_binread_encoding
    Dir.mktmpdir do |dir|
      path = File.join(dir, "bin.txt")
      File.write(path, "中文")
      assert_equal Encoding::ASCII_8BIT, File.binread(path).encoding
    end
  end
end
