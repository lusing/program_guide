# 24 实战：迷你 Markdown → HTML 渲染器（纯函数核心 MDEngine + 全链路演示）
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══════════ 纯函数核心：MDEngine（无 IO、无状态、输入→输出） ═══════════
module MDEngine
  # ---- 24.1 词法：行分类器（一行 → 确定的块类型符号） ----
  def self.classify_line(line)
    return :blank      if line.strip.empty?
    return :h3         if line.start_with?("### ")   # 三级标题（先判长的前缀）
    return :h2         if line.start_with?("## ")
    return :h1         if line.start_with?("# ")     # 一级标题
    return :fence      if line.start_with?("```")    # 围栏代码块的开/闭标记
    return :list_item  if line.start_with?("- ")     # 无序列表项
    return :olist_item if line.match?(/\A\d+\. /)    # 有序列表项：数字 + 点 + 空格
    :paragraph                                       # 其余一律是段落
  end

  # ---- 24.2 块切分：行流 → 块流（[类型, 内容行数组]） ----
  def self.group_blocks(lines)
    blocks = []
    i = 0
    while i < lines.size
      case classify_line(lines[i])
      when :blank            then i += 1                       # 空行只负责分隔块，不产出块
      when :fence                                              # 围栏：吞到下一个 ``` 为止
        j = i + 1
        j += 1 while j < lines.size && classify_line(lines[j]) != :fence
        if j < lines.size
          blocks << [:code, lines[(i + 1)...j]]                # 开/闭围栏本身不进内容
          i = j + 1
        else                                                   # 24.6 规则：未闭合围栏
          blocks << [:paragraph, lines[i..]]                   # 整段降级为普通段落
          i = lines.size
        end
      when :list_item                                          # 相邻 - 行合并成一个 ul
        j = i
        j += 1 while j < lines.size && classify_line(lines[j]) == :list_item
        blocks << [:ul, lines[i...j].map { |l| l.delete_prefix("- ") }]
        i = j
      when :olist_item                                         # 相邻 1. 行合并成一个 ol
        j = i
        j += 1 while j < lines.size && classify_line(lines[j]) == :olist_item
        blocks << [:ol, lines[i...j].map { |l| l.sub(/\A\d+\. /, "") }]
        i = j
      when :h1, :h2, :h3                                       # 标题：单行成块（去掉 # 前缀）
        type = classify_line(lines[i])
        prefix = { h1: "# ", h2: "## ", h3: "### " }[type]
        blocks << [type, [lines[i].delete_prefix(prefix)]]
        i += 1
      else                                                     # 段落：吞到非段落行为止
        j = i
        j += 1 while j < lines.size && classify_line(lines[j]) == :paragraph
        blocks << [:paragraph, lines[i...j]]
        i = j
      end
    end
    blocks
  end

  # ---- 24.3 行内渲染：转义 → 代码 → 粗体 → 斜体（顺序是纪律） ----
  def self.escape(s)
    s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")   # & 必须最先，否则二次转义
  end

  def self.inline(s)
    s = escape(s)                      # 1) 先转义：用户写的 < > & 失去 HTML 身份，
                                       #    后面我们自己插入的 <strong> 等标签才不会被误转
    s = s.gsub(/`([^`]+)`/) { "<code>#{Regexp.last_match(1)}</code>" }        # 2) 行内代码
    s = s.gsub(/\*\*([^*]+)\*\*/) { "<strong>#{Regexp.last_match(1)}</strong>" } # 3) 粗体
    s = s.gsub(/\*([^*]+)\*/) { "<em>#{Regexp.last_match(1)}</em>" }          # 4) 斜体
    s
  end

  # ---- 24.4 块渲染：[类型, 行] → HTML ----
  def self.render_block(type, lines)
    case type
    when :h1        then "<h1>#{inline(lines.first)}</h1>"
    when :h2        then "<h2>#{inline(lines.first)}</h2>"
    when :h3        then "<h3>#{inline(lines.first)}</h3>"
    when :paragraph then "<p>#{inline(lines.join("\n"))}</p>"
    when :ul        then "<ul>#{lines.map { |s| "<li>#{inline(s)}</li>" }.join}</ul>"
    when :ol        then "<ol>#{lines.map { |s| "<li>#{inline(s)}</li>" }.join}</ol>"
    when :code      then "<pre><code>#{escape(lines.join("\n"))}</code></pre>"
                        # 代码块只转义不做行内渲染 —— 里面的 * 和 ` 都是字面量
    else raise("未知块类型：#{type}")
    end
  end

  # ---- 24.5 全链路：markdown 字符串 → html 字符串 ----
  def self.render(md_string)
    group_blocks(md_string.lines.map { |l| l.chomp })
      .map { |type, lines| render_block(type, lines) }
      .join("\n")
  end
end

# ═══ 24.1 词法：行分类器断言
sec("24.1 词法：行分类器")
ok MDEngine.classify_line("# 标题") == :h1
ok MDEngine.classify_line("## 二级") == :h2
ok MDEngine.classify_line("### 三级") == :h3
ok MDEngine.classify_line("- 甲") == :list_item
ok MDEngine.classify_line("1. 第一") == :olist_item
ok MDEngine.classify_line("```") == :fence
ok MDEngine.classify_line("") == :blank
ok MDEngine.classify_line("普通正文") == :paragraph
ok MDEngine.classify_line("#### 四级") == :paragraph   # 本渲染器只到 h3，#### 是普通段落
puts "9 种行各归其类：h1/h2/h3/list/olist/fence/blank/paragraph；#### 按段落处理"

# ═══ 24.2 块切分断言
sec("24.2 块切分：行流 → 块流")
doc = "# 大标题\n\n正文一行\n正文两行\n\n- 甲\n- 乙\n\n1. 一\n2. 二\n\n```\ncode A\ncode B\n```\n"
blocks = MDEngine.group_blocks(doc.lines.map(&:chomp))
ok blocks.map(&:first) == [:h1, :paragraph, :ul, :ol, :code]
ok blocks[1][1] == ["正文一行", "正文两行"]               # 相邻段落行合并
ok blocks[2][1] == ["甲", "乙"]                          # 相邻列表项合并成一个 ul
ok blocks[4][1] == ["code A", "code B"]                  # 围栏吞进多行内容
ok MDEngine.group_blocks(["a", "", "b"]).size == 2       # 空行分隔，不产出块
puts "切分结果：#{blocks.map(&:first).inspect} —— 空行分隔、相邻同类行合并、围栏吞行"

# ═══ 24.3 行内渲染断言
sec("24.3 行内渲染：转义 → 代码 → 粗体 → 斜体")
ok MDEngine.inline("<b> & \"q\"") == "&lt;b&gt; &amp; \"q\""   # 转义先行
ok MDEngine.inline("`x = 1`") == "<code>x = 1</code>"
ok MDEngine.inline("**重点**") == "<strong>重点</strong>"
ok MDEngine.inline("*强调*") == "<em>强调</em>"
ok MDEngine.inline("**粗** 与 *斜* 与 `码`") == "<strong>粗</strong> 与 <em>斜</em> 与 <code>码</code>"
ok MDEngine.inline("<script>") == "&lt;script&gt;"       # 注入被拆解成纯文本
puts "转义最先执行 —— 用户 HTML 失效、自家标签安全；顺序反了整条管线都会被二次转义污染"

# ═══ 24.4 块渲染断言
sec("24.4 块渲染：block → html")
ok MDEngine.render_block(:h1, ["标题"]) == "<h1>标题</h1>"
ok MDEngine.render_block(:h2, ["二级"]) == "<h2>二级</h2>"
ok MDEngine.render_block(:h3, ["三级"]) == "<h3>三级</h3>"
ok MDEngine.render_block(:paragraph, ["正文"]) == "<p>正文</p>"
ok MDEngine.render_block(:ul, ["甲", "乙"]) == "<ul><li>甲</li><li>乙</li></ul>"
ok MDEngine.render_block(:ol, ["一"]) == "<ol><li>一</li></ol>"
ok MDEngine.render_block(:code, ["x < y"]) == "<pre><code>x &lt; y</code></pre>"
ok MDEngine.render_block(:h1, ["**粗**标题"]) == "<h1><strong>粗</strong>标题</h1>"   # 标题也走行内渲染
puts "七种块一一对应输出；块内文本全部经 inline（代码块只转义不渲染）"

# ═══ 24.5 全链路断言
sec("24.5 全链路：render(md) → html")
md = <<~MD
  # 笔记

  这是 **加粗** 与 `code` 混排的段落。

  - 读文件
  - 写测试
MD
expected = "<h1>笔记</h1>\n<p>这是 <strong>加粗</strong> 与 <code>code</code> 混排的段落。</p>\n<ul><li>读文件</li><li>写测试</li></ul>"
ok MDEngine.render(md) == expected, "全链路输出应与手写 HTML 一致"
ok MDEngine.render("你好 **世界**") == "<p>你好 <strong>世界</strong></p>"   # 中文全文
ok MDEngine.render("1. 甲\n2. 乙\n") == "<ol><li>甲</li><li>乙</li></ol>"
ok MDEngine.render("<img>") == "<p>&lt;img&gt;</p>"                        # 端到端注入防护
ok MDEngine.render("") == ""                                              # 空文档 → 空 HTML
puts "端到端 #{MDEngine.render("你好 **世界**").inspect} —— 中文、列表、代码、注入防护全过"

# ═══ 24.6 错误输入纪律：未闭合围栏的写死规则
sec("24.6 未闭合围栏：明确规则")
# 规则（写死）：围栏没有闭合时，从 ``` 起、包括 ``` 在内的剩余所有行整体降级为普通段落。
# 理由：渲染器永不抛错、永不挂起 —— 坏输入也要有一个确定的、可预测的输出。
unclosed = "```ruby\nputs 1\n"
ok MDEngine.render(unclosed) == "<p>```ruby\nputs 1</p>"
ok MDEngine.render(unclosed).include?("<p>")      # 不存在悬空的 <pre><code>
puts "未闭合围栏 → #{MDEngine.render(unclosed).inspect} —— 降级为段落，渲染器永不抛错"
ok MDEngine.render("```\ncode\n```\n") == "<pre><code>code</code></pre>"   # 闭合的正常走代码块

# ═══ 24.7 演示：渲染一篇样例文档
sec("24.7 演示：样例文档全渲染")
sample = <<~MD
  # Ruby 迷你笔记

  用 **Fiber** 可以写 *生成器*，配合 `Enumerator` 更顺手。

  - 纯函数核心
  - 薄薄的 IO 壳

  1. 词法
  2. 块切分

  ```
  render(md) # → html
  ```
MD
puts MDEngine.render(sample)   # 文档正文要引用的确定性样例输出
ok MDEngine.render(sample).start_with?("<h1>Ruby 迷你笔记</h1>")
ok MDEngine.render(sample).include?("<em>生成器</em>")

puts
puts("==== 24 结束 ====")
