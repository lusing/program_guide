# 24 · 实战：迷你 Markdown → HTML 渲染器

> 对应示例：`examples/24_capstone/`

全书收官：一个约 100 行的 Markdown → HTML 渲染器。它没有新 API，价值在于**架构**——纯函数核心 `MDEngine`（无 IO、无状态、输入→输出）+ 一层薄演示。词法、切分、渲染、转义、错误输入规则，每一层都是前面章节的旧知识（正则、gsub 块、case、冻结字符串、确定性纪律）的一次总装配。这个示例还背着一个教训：**一个 case 分支的遗漏就能让整个程序挂死**——24.2 细讲。

## 24.1 词法：行分类器

渲染器的第一层是纯函数 `classify_line`：一行文本 → 一个确定的块类型符号。前缀判断有个顺序纪律——**先判长的前缀**：

```ruby
def self.classify_line(line)
  return :blank      if line.strip.empty?
  return :h3         if line.start_with?("### ")   # 三级标题（先判长的前缀）
  return :h2         if line.start_with?("## ")
  return :h1         if line.start_with?("# ")
  return :fence      if line.start_with?("```")
  return :list_item  if line.start_with?("- ")
  return :olist_item if line.match?(/\A\d+\. /)    # 数字 + 点 + 空格
  :paragraph                                       # 其余一律是段落
end
```

为什么顺序重要：`### 三级` 也满足 `start_with?("# ")`？不满足——`"### "` 开头是 `#` 后跟 `#`，不是空格。但 `## 二级` 会同时命中 `#` 后空格吗？也不会。真正的顺序陷阱在通配前缀：若先判 `start_with?("#")`（不带空格），`#### 四级` 会误判成 h1。示例把 `#### 四级` 判成 `:paragraph`——本渲染器只到 h3，四级标题按普通段落处理，这是**写死的规则**而不是 bug：

```text
---- 24.1 词法：行分类器 ----
9 种行各归其类：h1/h2/h3/list/olist/fence/blank/paragraph；#### 按段落处理
```

纯函数的回报在这条断言里现形：8 种输入符号 + 1 种兜底，每个分支都能独立断言，不需要任何上下文。

## 24.2 块切分：行流 → 块流

`group_blocks` 把行流切成块流 `[类型, 内容行数组]`：空行只分隔不产出；相邻同类行合并（段落成段、列表项成 ul/ol）；围栏代码块吞到下一个 ``` 为止：

```ruby
doc = "# 大标题\n\n正文一行\n正文两行\n\n- 甲\n- 乙\n\n1. 一\n2. 二\n\n```\ncode A\ncode B\n```\n"
blocks = MDEngine.group_blocks(doc.lines.map(&:chomp))
blocks.map(&:first)   # => [:h1, :paragraph, :ul, :ol, :code]
```

实测输出：

```text
---- 24.2 块切分：行流 → 块流 ----
切分结果：[:h1, :paragraph, :ul, :ol, :code] —— 空行分隔、相邻同类行合并、围栏吞行
```

**本章（也是本书写作过程中）最贵的一个坑在这里**：`group_blocks` 最初版本的 case 里没有 `when :h1, :h2, :h3` 分支，标题行落进了 `else`（段落分支）。看 else 怎么推进游标：

```ruby
else   # 段落：吞到非段落行为止
  j = i
  j += 1 while j < lines.size && classify_line(lines[j]) == :paragraph
  blocks << [:paragraph, lines[i...j]]
  i = j
end
```

`# 标题` 被 `classify_line` 判成 `:h1`，而段落分支的推进条件是「下一行还是 `:paragraph`」——第一行自己就不是段落，`j` 纹丝不动，`lines[i...j]` 切出空数组，`i = j` 原地踏步，`while i < lines.size` **死循环**，程序无声挂死。教训有两条：

1. **分类符号的集合与 case 分支的集合必须一一对应**：`classify_line` 能返回的每个符号，`group_blocks` 的 case 都得有去处。词法层加了类型，语法层忘接——两层纯函数之间的接口漂移。
2. **游标不前进的循环必死**：写「吞行」式循环时，先问「最坏情况下 `i` 动不动」。补上 `when :h1, :h2, :h3` 分支（单行成块、剥掉 `#` 前缀、`i += 1`）后死循环消失。

## 24.3 行内渲染：转义 → 代码 → 粗体 → 斜体

行内渲染管段落/标题/列表项里的文本，处理顺序是纪律：

```ruby
def self.escape(s)
  s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")   # & 必须最先
end

def self.inline(s)
  s = escape(s)                                              # 1) 先转义
  s = s.gsub(/`([^`]+)`/)        { "<code>#{Regexp.last_match(1)}</code>" }
  s = s.gsub(/\*\*([^*]+)\*\*/)  { "<strong>#{Regexp.last_match(1)}</strong>" }
  s = s.gsub(/\*([^*]+)\*/)      { "<em>#{Regexp.last_match(1)}</em>" }
end
```

三条顺序规则：

1. **`&` 必须最先转义**：`&` 是所有实体的前缀，先转别的再转 `&` 会把 `&lt;` 二次污染成 `&amp;lt;`。
2. **转义先于一切标签插入**：用户写的 `<script>` 变成 `&lt;script&gt;` 失去 HTML 身份，之后我们自己插入的 `<code>`/`<strong>` 才不会被误转——端到端注入防护就在这一步。
3. **粗体（`\*\*`）在斜体（`\*`）之前**：`\*\*([^*]+)\*\*` 先吃掉成对的 `**`，剩下的单 `*` 才轮到斜体——反过来斜体会把粗体的半个定界符吞掉。

实测输出：

```text
---- 24.3 行内渲染：转义 → 代码 → 粗体 → 斜体 ----
转义最先执行 —— 用户 HTML 失效、自家标签安全；顺序反了整条管线都会被二次转义污染
```

gsub 全部用**块形式**（第 7 章/正则章的旧规则）：块里 `Regexp.last_match(1)` 取捕获组，`\1` 反向引用在替换文本里遇到转义边界时会踩坑，块形式没有这层问题。

## 24.4 块渲染：block → html

`render_block(type, lines)` 把块流翻译成 HTML，七种块一一对应。要点只有两条：标题/段落/列表的**块内文本全部过 `inline`**（标题里可以有粗体）；代码块**只转义不做行内渲染**——里面的 `*` 和 `` ` `` 都是字面量：

```ruby
when :paragraph then "<p>#{inline(lines.join("\n"))}</p>"
when :ul        then "<ul>#{lines.map { |s| "<li>#{inline(s)}</li>" }.join}</ul>"
when :code      then "<pre><code>#{escape(lines.join("\n"))}</code></pre>"
else raise("未知块类型：#{type}")
```

实测输出：

```text
---- 24.4 块渲染：block → html ----
七种块一一对应输出；块内文本全部经 inline（代码块只转义不渲染）
```

那个 `else raise` 不是摆设——它就是 24.2 教训的保险丝：万一将来有人在 `classify_line` 加新类型忘了同步，render 阶段会**立刻显式抛错**而不是静默产出错误 HTML。

## 24.5 全链路：render(md) → html

`render` 是三行的管道：

```ruby
def self.render(md_string)
  group_blocks(md_string.lines.map { |l| l.chomp })
    .map { |type, lines| render_block(type, lines) }
    .join("\n")
end
```

实测输出：

```text
---- 24.5 全链路：render(md) → html ----
端到端 "<p>你好 <strong>世界</strong></p>" —— 中文、列表、代码、注入防护全过
```

断言把全链路的承诺逐条钉死：全链路输出与手写 HTML 完全一致、中文全文正常、有序列表成 `<ol>`、`<img>` 注入被转义成纯文本、空文档输出空串。注意 `lines.map(&:chomp)`——`String#lines` 保留行尾 `\n`（19.3 的老坑），不 chomp 的话每个段落行都会把换行带进 `<p>` 里。

## 24.6 未闭合围栏：明确规则

错误输入也要有确定行为。规则写死：**围栏没有闭合时，从 ``` 起、包括 ``` 在内的剩余所有行整体降级为普通段落**：

```ruby
MDEngine.render("```ruby\nputs 1\n")   # => "<p>```ruby\nputs 1</p>"
```

实测输出：

```text
---- 24.6 未闭合围栏：明确规则 ----
未闭合围栏 → "<p>```ruby\nputs 1</p>" —— 降级为段落，渲染器永不抛错
```

理由：**渲染器永不抛错、永不挂起**——坏输入也要有一个确定的、可预测的输出。这条规则同时封死两种坏结局：不产生悬空的 `<pre><code>`（那会污染整个后续页面），也不死循环（对照 24.2：未闭合围栏走的是 `blocks << [:paragraph, lines[i..]]; i = lines.size`，游标一步跳到末尾）。「降级」是个工程决定而不是渲染标准——真正的 Markdown 规范怎么处理是另一回事，重要的是规则写死且可断言。

## 24.7 演示：样例文档全渲染

最后用一篇样例文档走一遍全链路（这段输出是确定性的，可直接引用）：

输入：

```markdown
# Ruby 迷你笔记

用 **Fiber** 可以写 *生成器*，配合 `Enumerator` 更顺手。

- 纯函数核心
- 薄薄的 IO 壳

1. 词法
2. 块切分

```
render(md) # → html
```
```

实测输出：

```text
---- 24.7 演示：样例文档全渲染 ----
<h1>Ruby 迷你笔记</h1>
<p>用 <strong>Fiber</strong> 可以写 <em>生成器</em>，配合 <code>Enumerator</code> 更顺手。</p>
<ul><li>纯函数核心</li><li>薄薄的 IO 壳</li></ul>
<ol><li>词法</li><li>块切分</li></ol>
<pre><code>render(md) # → html</code></pre>
```

收个尾：核心 `MDEngine` 是纯函数（无 IO、无状态、不碰文件不碰全局），演示壳只负责喂数据打输出。想给它加功能——表格、嵌套列表、Setext 标题——从改 `classify_line` 的符号集开始，然后逐层同步 `group_blocks` 的 case 和 `render_block` 的分支，并让 24.2 的死循环教训替你把关：**每加一个类型，先问游标会不会前进**。这也是全书的方法论缩影：小函数、纯核心、断言钉死、坑写进清单。

## 24.8 坑位清单

1. **词法新类型与 case 分支脱节会死循环**：`group_blocks` 最初漏了 `when :h1, :h2, :h3`，标题行落进段落分支导致游标原地踏步、程序无声挂死（24.2）。
2. **「吞行」式循环先验证最坏情况下游标会前进**：`j` 不动的每一圈都是白转，`while i < lines.size` 立即变死循环（24.2）。
3. **`String#lines` 保留行尾 `\n`**：切块前 `lines.map(&:chomp)`，否则换行混进 `<p>`（24.5、19.3 老坑再现）。
4. **HTML 转义 `&` 必须最先**：否则 `&lt;` 被二次污染成 `&amp;lt;`，整条管线逐层坏掉（24.3）。
5. **转义先于标签插入**：先让用户 `<script>` 失去 HTML 身份，自家 `<strong>` 才不会被误转——顺序即安全（24.3）。
6. **粗体正则在斜体之前**：`\*\*` 先吃，单 `\*` 才归斜体；顺序颠倒互吞定界符（24.3）。
7. **gsub 替换用块形式取捕获组**：`Regexp.last_match(1)` 代替字符串里的 `\1`，避开转义边界（24.3）。
8. **代码块只转义不渲染**：块内的 `*`、`` ` ``、`<` 都是字面量，过了 `inline` 就毁内容（24.4）。
9. **render_block 的 `else raise` 是接口保险丝**：新类型漏同步时立刻炸出来，别静默产出错误 HTML（24.4）。
10. **前缀判断先长后短**：`### ` 在 `# ` 之前；通配 `#`（不带空格）会把 `####` 误吞（24.1）。
11. **未闭合围栏降级为段落是写死规则**：渲染器永不抛错、永不挂起，坏输入也要有确定输出（24.6）。
12. **扩展渲染器从符号集开始逐层同步**：`classify_line` 的符号、`group_blocks` 的分支、`render_block` 的分支三处必须一一对应（24.1–24.4）。

---

**上一章**：[23 · Fiddle C 互操作](23-ffi.md)
