# 24 测试层：minitest 套件（自包含，不 require main.rb —— 避免把演示输出打进测试结果；
# MDEngine 与 main.rb 同源独立复写）
# frozen_string_literal: true
require "minitest/autorun"

module MDEngine
  def self.classify_line(line)
    return :blank      if line.strip.empty?
    return :h3         if line.start_with?("### ")
    return :h2         if line.start_with?("## ")
    return :h1         if line.start_with?("# ")
    return :fence      if line.start_with?("```")
    return :list_item  if line.start_with?("- ")
    return :olist_item if line.match?(/\A\d+\. /)
    :paragraph
  end

  def self.group_blocks(lines)
    blocks = []
    i = 0
    while i < lines.size
      case classify_line(lines[i])
      when :blank            then i += 1
      when :fence
        j = i + 1
        j += 1 while j < lines.size && classify_line(lines[j]) != :fence
        if j < lines.size
          blocks << [:code, lines[(i + 1)...j]]
          i = j + 1
        else
          blocks << [:paragraph, lines[i..]]
          i = lines.size
        end
      when :list_item
        j = i
        j += 1 while j < lines.size && classify_line(lines[j]) == :list_item
        blocks << [:ul, lines[i...j].map { |l| l.delete_prefix("- ") }]
        i = j
      when :olist_item
        j = i
        j += 1 while j < lines.size && classify_line(lines[j]) == :olist_item
        blocks << [:ol, lines[i...j].map { |l| l.sub(/\A\d+\. /, "") }]
        i = j
      when :h1, :h2, :h3
        type = classify_line(lines[i])
        prefix = { h1: "# ", h2: "## ", h3: "### " }[type]
        blocks << [type, [lines[i].delete_prefix(prefix)]]
        i += 1
      else
        j = i
        j += 1 while j < lines.size && classify_line(lines[j]) == :paragraph
        blocks << [:paragraph, lines[i...j]]
        i = j
      end
    end
    blocks
  end

  def self.escape(s)
    s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end

  def self.inline(s)
    s = escape(s)
    s = s.gsub(/`([^`]+)`/) { "<code>#{Regexp.last_match(1)}</code>" }
    s = s.gsub(/\*\*([^*]+)\*\*/) { "<strong>#{Regexp.last_match(1)}</strong>" }
    s = s.gsub(/\*([^*]+)\*/) { "<em>#{Regexp.last_match(1)}</em>" }
    s
  end

  def self.render_block(type, lines)
    case type
    when :h1        then "<h1>#{inline(lines.first)}</h1>"
    when :h2        then "<h2>#{inline(lines.first)}</h2>"
    when :h3        then "<h3>#{inline(lines.first)}</h3>"
    when :paragraph then "<p>#{inline(lines.join("\n"))}</p>"
    when :ul        then "<ul>#{lines.map { |s| "<li>#{inline(s)}</li>" }.join}</ul>"
    when :ol        then "<ol>#{lines.map { |s| "<li>#{inline(s)}</li>" }.join}</ol>"
    when :code      then "<pre><code>#{escape(lines.join("\n"))}</code></pre>"
    else raise("未知块类型：#{type}")
    end
  end

  def self.render(md_string)
    group_blocks(md_string.lines.map { |l| l.chomp })
      .map { |type, lines| render_block(type, lines) }
      .join("\n")
  end
end

class TestMDEngine < Minitest::Test
  # 24.1 词法
  def test_classify_line_all_types
    assert_equal :h1, MDEngine.classify_line("# 标题")
    assert_equal :h2, MDEngine.classify_line("## 二级")
    assert_equal :h3, MDEngine.classify_line("### 三级")
    assert_equal :list_item, MDEngine.classify_line("- 甲")
    assert_equal :olist_item, MDEngine.classify_line("1. 第一")
    assert_equal :fence, MDEngine.classify_line("```")
    assert_equal :blank, MDEngine.classify_line("")
    assert_equal :paragraph, MDEngine.classify_line("普通正文")
    assert_equal :paragraph, MDEngine.classify_line("#### 四级")
  end

  # 24.2 块切分
  def test_group_blocks_types_and_merging
    doc = "# 大标题\n\n正文一行\n正文两行\n\n- 甲\n- 乙\n\n1. 一\n2. 二\n\n```\ncode A\ncode B\n```\n"
    blocks = MDEngine.group_blocks(doc.lines.map(&:chomp))
    assert_equal [:h1, :paragraph, :ul, :ol, :code], blocks.map(&:first)
    assert_equal ["正文一行", "正文两行"], blocks[1][1]
    assert_equal %w[甲 乙], blocks[2][1]
    assert_equal %w[一 二], blocks[3][1]
    assert_equal ["code A", "code B"], blocks[4][1]
  end

  def test_blank_lines_do_not_create_blocks
    assert_equal 2, MDEngine.group_blocks(["a", "", "", "b"]).size
    assert_equal 0, MDEngine.group_blocks(["", ""]).size
  end

  def test_heading_prefix_stripped_in_grouping
    blocks = MDEngine.group_blocks(["# 笔记"])
    assert_equal [:h1, ["笔记"]], blocks.first
  end

  # 24.3 行内渲染
  def test_escape_comes_first
    assert_equal "&lt;b&gt; &amp; \"q\"", MDEngine.inline("<b> & \"q\"")
    assert_equal "&lt;script&gt;", MDEngine.inline("<script>")
    assert_equal "&amp;amp;", MDEngine.inline("&amp;") # & 先转义，不会被二次处理
  end

  def test_inline_code_bold_italic
    assert_equal "<code>x = 1</code>", MDEngine.inline("`x = 1`")
    assert_equal "<strong>重点</strong>", MDEngine.inline("**重点**")
    assert_equal "<em>强调</em>", MDEngine.inline("*强调*")
    assert_equal "<strong>粗</strong> 与 <em>斜</em> 与 <code>码</code>",
                 MDEngine.inline("**粗** 与 *斜* 与 `码`")
  end

  # 24.4 块渲染
  def test_render_block_each_type
    assert_equal "<h1>标题</h1>", MDEngine.render_block(:h1, ["标题"])
    assert_equal "<h2>二级</h2>", MDEngine.render_block(:h2, ["二级"])
    assert_equal "<h3>三级</h3>", MDEngine.render_block(:h3, ["三级"])
    assert_equal "<p>正文</p>", MDEngine.render_block(:paragraph, ["正文"])
    assert_equal "<ul><li>甲</li><li>乙</li></ul>", MDEngine.render_block(:ul, %w[甲 乙])
    assert_equal "<ol><li>一</li></ol>", MDEngine.render_block(:ol, ["一"])
    assert_equal "<pre><code>x &lt; y</code></pre>", MDEngine.render_block(:code, ["x < y"])
    assert_equal "<h1><strong>粗</strong>标题</h1>", MDEngine.render_block(:h1, ["**粗**标题"])
  end

  def test_code_block_escapes_but_no_inline_rendering
    html = MDEngine.render_block(:code, ["*不斜体* `不代码` <tag>"])
    assert_equal "<pre><code>*不斜体* `不代码` &lt;tag&gt;</code></pre>", html
  end

  # 24.5 全链路
  def test_render_end_to_end
    md = <<~MD
      # 笔记

      这是 **加粗** 与 `code` 混排的段落。

      - 读文件
      - 写测试
    MD
    expected = "<h1>笔记</h1>\n<p>这是 <strong>加粗</strong> 与 <code>code</code> 混排的段落。</p>\n<ul><li>读文件</li><li>写测试</li></ul>"
    assert_equal expected, MDEngine.render(md)
  end

  def test_render_chinese_and_ordered_list
    assert_equal "<p>你好 <strong>世界</strong></p>", MDEngine.render("你好 **世界**")
    assert_equal "<ol><li>甲</li><li>乙</li></ol>", MDEngine.render("1. 甲\n2. 乙\n")
  end

  def test_render_neutralizes_html_injection
    assert_equal "<p>&lt;img&gt;</p>", MDEngine.render("<img>")
  end

  def test_render_empty_document
    assert_equal "", MDEngine.render("")
  end

  # 24.6 未闭合围栏规则
  def test_unclosed_fence_degrades_to_paragraph
    assert_equal "<p>```ruby\nputs 1</p>", MDEngine.render("```ruby\nputs 1\n")
    assert_equal "<pre><code>code</code></pre>", MDEngine.render("```\ncode\n```\n")
  end

  # 24.7 样例文档
  def test_sample_document
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
    html = MDEngine.render(sample)
    assert html.start_with?("<h1>Ruby 迷你笔记</h1>")
    assert_includes html, "<em>生成器</em>"
    assert_includes html, "<ul><li>纯函数核心</li><li>薄薄的 IO 壳</li></ul>"
    assert_includes html, "<ol><li>词法</li><li>块切分</li></ol>"
    assert_includes html, "<pre><code>render(md) # → html</code></pre>"
  end
end
