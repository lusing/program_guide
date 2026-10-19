# 04 · 自助文档：Help 家族

Emacs 最该先学会的不是任何编辑命令，而是**怎么问 Emacs 自己**。这一章讲透 Help 系统：所有帮助命令都以 `C-h`（等价于 `<f1>`）为前缀，覆盖从「这个键干什么」到「跟某个主题相关的所有命令」的各种场景。

## 4.1 Help 前缀键

`C-h`（`help-command`）是一个前缀键，等价于 `<f1>`。按了 `C-h` 之后，Emacs 等你按下一个键来决定具体执行哪个帮助命令。

**最万能的入口**：`C-h C-h`（`help-for-help`）。它列出一个所有帮助命令的清单，你可以用 `SPC` 向下翻、`DEL` 向上翻，找到想要的命令后按对应键即可。不想查了按 `C-g` 退出。

**在任何前缀键后面按 `C-h`**，Emacs 会列出该前缀键下所有可用的后续键和命令。例如 `C-x C-h` 列出所有 `C-x` 开头的绑定。唯一例外是 `ESC`：`ESC C-h` 等于 `C-M-h`（`mark-defun`），不是查帮助——对 `ESC` 前缀要用 `ESC <f1>`。

## 4.2 查键：这个键干什么？

### C-h c（describe-key-briefly）

`C-h c` 然后按一个键序列，echo area 显示该键绑定的命令名。例如：

```
C-h c C-f
```

echo area 显示 `forward-char`。快速、不打扰。

### C-h k（describe-key）

`C-h k` 然后按一个键序列，Emacs 打开一个 `*Help*` buffer，显示该命令的完整文档字符串。例如：

```
C-h k C-x C-f
```

会显示 `find-file` 的完整说明，包括它接受什么参数、有什么副作用。

`C-h k` 是你在日常编辑中用得最多的帮助命令——看到某个键想知道它详细做什么，`C-h k` 然后按那个键。

### C-h K（Info-goto-emacs-key-command-node）

`C-h K` 然后按一个键序列，Emacs 打开 Info 手册直接跳到该键对应命令的文档节点。比 `C-h k` 更详细——它给你的是手册里的完整章节，而不只是文档字符串。

### C-h w（where-is）

`C-h w` 然后输入命令名，echo area 显示该命令绑定在哪些键上。例如：

```
C-h w forward-char RET
```

echo area 显示 `C-f`（以及可能的其他绑定）。如果命令没有绑定到任何键，会告诉你 `is not on any key`——意味着你只能用 `M-x` 来调用它。

## 4.3 查命令和函数：这个命令做什么？

### C-h x（describe-command）

`C-h x` 然后输入命令名，在 `*Help*` buffer 里显示该命令的文档。例如：

```
C-h x auto-fill-mode RET
```

这是查看一个**命令**的文档的正则方式。即使该命令没有键绑定，也能用这个方式查。

### C-h f（describe-function）

`C-h f` 然后输入 Lisp 函数名，显示该函数的文档。因为所有命令都是 Lisp 函数，所以 `C-h f` 也能查命令——但 `C-h x` 更专门。

`C-h f` 的主要用途是查**非命令的 Lisp 函数**。例如你在读别人的配置时看到 `(make-vector len)`，不确定 `make-vector` 做什么：

```
C-h f make-vector RET
```

**智能默认值**：如果 point 在一个 Lisp 表达式里、紧挨着一个函数名，按 `C-h f RET`（不输入名字直接确认）会自动用那个函数名作为默认值。这在你边写 Lisp 边查文档时非常方便。

### C-h v（describe-variable）

`C-h v` 然后输入变量名，显示该变量的文档和当前值。例如：

```
C-h v fill-column RET
```

与 `C-h f` 类似，如果 point 在一个变量名上面，直接 `RET` 就用它作默认值。

### C-h o（describe-symbol）

`C-h o` 然后输入符号名，显示该符号**所有**的文档——如果它同时是函数、变量和 face，会依次显示三者的文档。当你不确定一个名字是什么类型时，用 `C-h o` 最全面。

### C-h F（Info-goto-emacs-command-node）

`C-h F` 然后输入命令名，打开 Info 手册跳到该命令的文档节点。与 `C-h x` 的区别是它给你的是手册里的完整章节。

## 4.4 Apropos：按主题搜索

当你不知道要找的命令叫什么名字，只知道大概跟什么主题相关时，用 apropos 命令。

### C-h a（apropos-command）

`C-h a` 然后输入关键词，Emacs 列出所有名字匹配的**命令**。例如：

```
C-h a file RET
```

列出所有名字包含 `file` 的命令：`copy-file`、`find-file`、`write-file` 等等。每个命令旁边有简短说明和当前绑定的键。

带前缀参数 `C-u C-h a` 时，搜索范围扩大到包括非命令的函数。

### C-h d（apropos-documentation）

`C-h d` 然后输入关键词，搜索所有函数和变量的**文档字符串**（而不是名字）。适合你连命令名都没头绪、只知道它「做什么」的时候。例如：

```
C-h d kill backward word RET
```

会找到文档字符串中包含这些词的函数和变量。

### C-h u（apropos-user-option）

`C-h u` 搜索用户可定制的变量。带前缀参数时扩大到包括不可定制的变量。

### 搜索模式

Apropos 的关键词可以是：

- **单个词**：匹配名字或文档中包含该词的所有条目。
- **多个词**（空格分隔）：名字必须包含至少两个词才匹配。
- **正则表达式**：如果关键词包含 `^$*+?.\[` 中的任何一个，整个关键词被当作正则表达式处理。

## 4.5 查当前模式

### C-h m（describe-mode）

`C-h m`（`describe-mode`）显示当前 buffer 的主模式文档，以及所有启用的次模式的文档。这是你了解「当前 buffer 里哪些键有特殊含义」的最快方式。

例如在一个 Python buffer 里按 `C-h m`，你会看到 Python mode 的说明，包括它定义了哪些特殊的键绑定、缩进规则等。

### C-h b（describe-bindings）

`C-h b`（`describe-bindings`）列出当前所有生效的键绑定：先列次模式的绑定，再列主模式的绑定，最后列全局绑定。这个列表通常很长，但如果你想全面了解「我现在能按什么键」，这是最权威的来源。

### C-h s（describe-syntax）

`C-h s`（`describe-syntax`）显示当前 buffer 的语法表内容——哪些字符是单词的一部分、哪些是分隔符、哪些是注释起始符等。这在你需要理解为什么 `M-f` 在某种文件里按特定方式分词时很有用。

## 4.6 Help buffer 的操作

大多数帮助命令在 `*Help*` buffer 里显示结果。这个 buffer 使用 Help mode，有一套专门的导航键：

| 键 | 命令 | 作用 |
|----|------|------|
| `SPC` | 向下滚动 | 与 View mode 相同 |
| `DEL` | 向上滚动 | 与 View mode 相同 |
| `RET` | `help-follow` | 跟踪 point 处的超链接 |
| `TAB` | `forward-button` | 跳到下一个超链接 |
| `S-TAB` | `backward-button` | 跳到上一个超链接 |
| `n` | 下一页 | 在分页的 help buffer 里翻页 |
| `p` | 上一页 | 在分页的 help buffer 里翻页 |
| `C-c C-c` | `help-follow-symbol` | 显示 point 处符号的所有文档 |
| `C-c C-b` 或 `l` | `help-go-back` | 回到 help 浏览历史的上一页 |
| `C-c C-f` 或 `r` | `help-go-forward` | 前进到 help 浏览历史的下一页 |
| `s` | `help-view-source` | 查看当前 help 主题的源码 |
| `i` | `help-goto-info` | 在 Info 手册里查看当前主题 |
| `c` | `help-customize` | 定制当前变量或 face |

Help buffer 里的函数名、变量名、face 名通常是带下划线的超链接。把 point 移上去按 `RET`（或鼠标点击），就能跳到该符号的文档。要回来按 `l`（`help-go-back`）。

**退出 help buffer**：跟其他 buffer 一样，`C-x k` 杀掉就行；或者用 `q`（如果 help buffer 是以特殊方式显示的，`q` 会关闭窗口）。

### help-window-select 变量

默认情况下（`help-window-select` 为 `nil`），帮助命令在新窗口里显示 `*Help*` buffer 但**不切换到那个窗口**——你当前的编辑窗口不受干扰。如果你想让帮助窗口自动获得焦点，把 `help-window-select` 设为 `t`。

## 4.7 其他有用的 Help 命令

### C-h i（info）

`C-h i`（`info`）启动 Info——GNU 的结构化文档浏览器。整个 Emacs 手册都可以通过 Info 阅读。进入 Info 后按 `h` 可以运行一个 Info 使用教程。

`C-h r`（`info-emacs-manual`）直接打开 Emacs 手册的 Info 版本。

### C-h t（help-with-tutorial）

`C-h t`（`help-with-tutorial`）打开 Emacs 自带的交互式入门教程。这是一个边讲边练的教程，适合完全没接触过 Emacs 的人。

### C-h e（view-echo-area-messages）

`C-h e`（`view-echo-area-messages`）打开 `*Messages*` buffer，回看 echo area 的历史消息。如果你没来得及看清某条消息，在这里能找到。

### C-h l（view-lossage）

`C-h l`（`view-lossage`）显示你最近按过的 300 个键和它们执行的命令。当你做了某件事但不记得自己按了什么的时候，这个命令能帮你回忆。默认记录 300 个键，可以用 `M-x lossage-size` 修改。

### C-h n（view-emacs-news）

`C-h n`（`view-emacs-news`）显示当前版本 Emacs 的新特性和变化。升级 Emacs 后值得一看。

### C-h p（finder-by-keyword）

`C-h p`（`finder-by-keyword`）按关键词搜索可用的 Emacs 包。

### C-h h（view-hello-file）

`C-h h`（`view-hello-file`）显示 `HELLO` 文件，里面有各种语言/文字系统的「Hello」示例——用来测试字符显示。

### C-h S（info-lookup-symbol）

`C-h S`（`info-lookup-symbol`）在编程语言的 Info 手册里查找 point 处的符号。例如编辑 Python 代码时，对 `os.path.join` 按 `C-h S`，Emacs 会在 Python 手册里找它的文档。

### C-h C-q（help-quick-toggle）

`C-h C-q`（`help-quick-toggle`）切换显示一个速查窗口，列出最常用的命令和快捷键。每个绑定都是可点击的按钮。

### C-h .（display-local-help）

`C-h .`（`display-local-help`）显示 point 处的活动文本（如超链接、mode line 区域）的帮助信息。在图形界面上，鼠标悬停时会自动显示工具提示（tooltip）；在文本终端上，用 `C-h .` 手动查看。

## 4.8 Help 文件

Emacs 还内置了一些帮助文件，涵盖许可证、FAQ、已知问题等：

| 键 | 命令 | 内容 |
|----|------|------|
| `C-h C-c` | `describe-copying` | 复制和 Redistribution 规则 |
| `C-h C-f` | `view-emacs-FAQ` | 常见问题解答 |
| `C-h C-n` | `view-emacs-news` | 新版本特性 |
| `C-h C-o` | `describe-distribution` | 如何获取最新 Emacs |
| `C-h C-p` | `view-emacs-problems` | 已知问题 |
| `C-h C-w` | `describe-no-warranty` | 无担保声明 |
| `C-h g` | `describe-gnu-project` | GNU 项目介绍 |

## 4.9 Help Echo：悬停提示

在图形界面上，把鼠标悬停在活动文本（超链接、mode line 区域、工具栏图标等）上，会显示一个工具提示（tooltip）告诉你这个区域的作用。这就是 **help echo**。

在文本终端上不支持鼠标悬停，可以用 `C-h .`（`display-local-help`）在 echo area 显示 point 处的帮助文本。如果想让 help echo 在 point 空闲时自动显示，把变量 `help-at-pt-display-when-idle` 设为 `t`。

## 4.10 找不到帮助时怎么办

如果你知道有某个功能但不知道叫什么名字、在哪里找，按这个顺序试：

1. **`C-h a`**：用关键词搜索命令名。试几个相关的英文词。
2. **`C-h r i TOPIC RET`**：在 Emacs Info 手册的索引里搜索。按 `,` 看下一个匹配。
3. **`C-h C-f`**：看 FAQ。
4. **`C-h p`**：按关键词搜索外部包。
5. **`M-x list-packages RET`**：浏览所有可用的外部包。

## 4.11 小结

- 所有帮助命令以 `C-h`（或 `<f1>`）为前缀。`C-h C-h` 列出所有帮助命令。
- 查键：`C-h c`（简要）→ `C-h k`（详细文档）→ `C-h K`（Info 手册）。
- 查命令/函数/变量：`C-h x`（命令）→ `C-h f`（函数）→ `C-h v`（变量）→ `C-h o`（所有）。
- 按主题搜索：`C-h a`（命令名）→ `C-h d`（文档字符串）。
- 查当前环境：`C-h m`（模式文档）→ `C-h b`（所有绑定）→ `C-h s`（语法表）。
- Help buffer 里 `RET` 跟链接、`TAB` 跳到下一个链接、`l` 后退、`q` 退出。
- `C-h i` 打开 Info，`C-h t` 打开教程，`C-h e` 看消息历史，`C-h l` 看按键历史。

---

上一章：[03 · 最基本的编辑](03-basic-editing.md) ｜ 下一章：[05 · minibuffer 与补全](05-minibuffer.md) ｜ 返回：[使用 Emacs 教程](README.md)
