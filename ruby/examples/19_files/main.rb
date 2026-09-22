# 19 文件与 IO：File 读写、Dir/glob、FileUtils、Pathname、Tempfile、JSON、FileTest
# 运行：ruby main.rb
# frozen_string_literal: true

require "tmpdir"      # Dir.mktmpdir
require "fileutils"   # mkdir_p / cp / mv / rm_f / rm_rf
require "pathname"    # 面向对象的路径
require "tempfile"    # Tempfile.create
require "json"        # JSON 落盘往返

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 19.1 File.write / File.read 与编码：UTF-8 中文往返
sec("19.1 File.write / File.read 与编码")
Dir.mktmpdir do |dir|
  path = File.join(dir, "greeting.txt")
  text = "你好，Ruby！\n文件 IO 第一行"
  File.write(path, text)                    # 返回写入的字节数
  ok File.write(path, text) == text.bytesize
  round = File.read(path)                   # 整个文件读成一个 String
  ok round == text, "UTF-8 中文往返应逐字节相等"
  ok round.encoding == Encoding::UTF_8      # read 默认按 UTF-8 解释（locale 决定）
  ok round.bytesize > round.length          # 中文多字节：字节数 > 字符数
  puts "往返相等 = #{round == text}；字节 #{round.bytesize} / 字符 #{round.length}"
  # 二进制模式：强制 ASCII-8BIT，不做换行/编码转换
  ok File.binread(path).encoding == Encoding::ASCII_8BIT
end

# ═══ 19.2 File.open 块形式与追加模式 "a"
sec("19.2 File.open 块形式（自动 close）与追加模式")
Dir.mktmpdir do |dir|
  path = File.join(dir, "log.txt")
  File.open(path, "w") do |f|      # 块形式：块结束时保证 f.close，异常也不例外
    f.puts("第一行")
    f.puts("第二行")
  end
  File.open(path, "a") { |f| f.puts("追加行") }   # "a" 追加模式：不清空原内容
  ok File.read(path) == "第一行\n第二行\n追加行\n"
  # "w" 每次清空重建；"r+" 读写不改长度处；文件句柄用完必须 close（块形式免操心）
  File.open(path, "w") { |f| f.puts("覆盖") }
  ok File.read(path) == "覆盖\n"
  puts "块形式自动 close；w 覆盖、a 追加 —— 覆盖后内容 #{File.read(path).strip.inspect}"
end

# ═══ 19.3 逐行读取：each_line / lineno / readlines
sec("19.3 逐行：each_line / lineno / readlines")
Dir.mktmpdir do |dir|
  path = File.join(dir, "poem.txt")
  File.write(path, "春眠不觉晓\n处处闻啼鸟\n夜来风雨声\n")
  seen = []
  File.open(path) do |f|
    f.each_line do |line|          # 逐行惰性读取，大文件也吃得住
      seen << [f.lineno, line.strip]   # lineno 从 1 计数（含换行的当前行号）
    end
  end
  ok seen == [[1, "春眠不觉晓"], [2, "处处闻啼鸟"], [3, "夜来风雨声"]]
  ok File.readlines(path).size == 3            # 一次性读成行数组（含 \n）
  ok File.readlines(path, chomp: true) == ["春眠不觉晓", "处处闻啼鸟", "夜来风雨声"]
  puts "each_line 行号序列：#{seen.map { |n, _| n }.inspect}；readlines(chomp: true) 去掉行尾换行"
end

# ═══ 19.4 Dir 与 Dir.glob：目录枚举与通配符
sec("19.4 Dir 与 Dir.glob")
Dir.mktmpdir do |dir|
  # 在临时目录里建固定名文件（目录名本身是随机的 —— 绝不打印！）
  %w[report.txt notes.md image.png data.txt].each do |name|
    File.write(File.join(dir, name), name)
  end
  FileUtils.mkdir_p(File.join(dir, "sub"))     # 建个子目录供 ** 递归用
  File.write(File.join(dir, "sub", "nested.txt"), "n")

  names = Dir.glob(File.join(dir, "*.txt")).map { |p| File.basename(p) }.sort
  ok names == ["data.txt", "report.txt"], "glob *.txt 应命中两个 txt"
  all_txt = Dir.glob(File.join(dir, "**", "*.txt")).map { |p| File.basename(p) }.sort
  ok all_txt == ["data.txt", "nested.txt", "report.txt"]   # ** 递归进子目录
  ok Dir.children(dir).sort == ["data.txt", "image.png", "notes.md", "report.txt", "sub"]
  puts "glob(*.txt) → #{names.inspect}；glob(**/*.txt) 递归 → #{all_txt.inspect}"
  puts "Dir.children 直接列出条目名（不含 . 和 ..）"
end

# ═══ 19.5 FileUtils：mkdir_p / cp / mv / rm_f
sec("19.5 FileUtils：批量文件操作")
Dir.mktmpdir do |dir|
  src = File.join(dir, "src")
  dst = File.join(dir, "dst", "deep")       # dst/deep 并不存在
  FileUtils.mkdir_p(dst)                    # -p 语义：沿途缺哪级建哪级，已存在也不报错
  FileUtils.mkdir_p(dst)                    # 幂等：重复执行安全
  ok File.directory?(dst)
  payload = File.join(src = File.join(dir, "payload.txt"), "")
  File.write(File.join(dir, "payload.txt"), "数据")
  FileUtils.cp(File.join(dir, "payload.txt"), File.join(dst, "copy.txt"))
  ok File.read(File.join(dst, "copy.txt")) == "数据"
  FileUtils.mv(File.join(dst, "copy.txt"), File.join(dir, "moved.txt"))   # mv 可当重命名用
  ok !File.exist?(File.join(dst, "copy.txt")) && File.exist?(File.join(dir, "moved.txt"))
  FileUtils.rm_f(File.join(dir, "moved.txt"))       # rm_f：不存在也不抛错
  FileUtils.rm_f(File.join(dir, "从不存在.txt"))
  ok !File.exist?(File.join(dir, "moved.txt"))
  puts "mkdir_p 幂等建多级；cp 复制 / mv 移动或重命名 / rm_f 静默删除 —— 全部收尾由 mktmpdir 兜底"
end

# ═══ 19.6 Pathname：把路径当对象操作
sec("19.6 Pathname 实操")
Dir.mktmpdir do |dir|
  pn = Pathname(dir) + "demo.txt"           # + 即 join，跨平台分隔符
  pn.write("路径也是对象")
  ok pn.read == "路径也是对象"
  ok pn.file? && !pn.directory?
  ok pn.extname == ".txt"                   # 扩展名
  ok pn.basename.to_s == "demo.txt"
  ok pn.parent.basename.to_s == File.basename(dir)   # parent 指向临时目录
  joined = Pathname(dir) + "a" + "b.txt"    # 链式 join
  ok joined.to_s == File.join(dir, "a", "b.txt")
  puts "Pathname#write/read/file? 直接可用；join 用 +，extname/basename/parent 全是方法"
end

# ═══ 19.7 tempfile：临时文件不用手洗
sec("19.7 tempfile：Tempfile.create")
# Tempfile.create 块形式：自动建唯一名文件、自动关闭并删除 —— 也不打印它的随机名
Tempfile.create("tut19") do |f|
  f.write("临时数据 42")
  f.rewind                       # 写完读回要先 rewind（或重新 open）
  ok f.read == "临时数据 42"
  ok File.exist?(f.path)         # 块内活着；块结束自动删除
end
Tempfile.create("tut19b") do |f|
  path = f.path                  # 想跨块使用就把路径记下来
  File.write(path, "第二次写入")
  ok File.read(path) == "第二次写入"
end
puts "Tempfile.create 块形式：块结束自动 close 并删除，随机文件名无需关心"

# ═══ 19.8 JSON 落盘往返
sec("19.8 JSON 落盘往返")
Dir.mktmpdir do |dir|
  path = File.join(dir, "data.json")          # 固定文件名，随机的是目录
  data = { "名称" => "迷你笔记", "版本" => 4, "标签" => ["ruby", "io"] }
  File.write(path, JSON.pretty_generate(data))  # pretty_generate 带缩进，人类可读
  loaded = JSON.parse(File.read(path))
  ok loaded == data, "JSON 往返应相等（键都是字符串）"
  ok loaded["标签"] == ["ruby", "io"]
  # 坑：JSON.parse 默认把所有键变成 String；symbolize_names: true 才还原成 Symbol
  ok JSON.parse(File.read(path), symbolize_names: true)[:名称] == "迷你笔记"
  puts "写 → pretty_generate，读 → JSON.parse；往返相等 = #{loaded == data}"
end

# ═══ 19.9 FileTest：存在性 / 大小断言
sec("19.9 FileTest 存在性与大小")
Dir.mktmpdir do |dir|
  path = File.join(dir, "sized.txt")
  ok !FileTest.exist?(path)                 # 还没建
  content = "12345"
  File.write(path, content)
  ok FileTest.exist?(path) && FileTest.file?(path)
  ok FileTest.size(path) == 5 && FileTest.size?(path) == 5   # size?：0 或不存在返回 nil
  ok FileTest.readable?(path) && FileTest.writable?(path)
  empty = File.join(dir, "empty.txt")
  FileUtils.touch(empty)
  ok FileTest.zero?(empty) && !FileTest.size?(empty)          # 空文件：zero? 真、size? 为 nil
  puts "exist? / file? / size=5 / 空文件 zero?=true —— FileTest 是模块函数，直接调用"
end

puts
puts("==== 19 结束 ====")
