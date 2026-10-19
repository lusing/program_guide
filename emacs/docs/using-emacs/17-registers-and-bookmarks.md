# 17 · 寄存器与书签

这一章讲两种「暂存」机制：**寄存器**（register）和**书签**（bookmark）。它们解决的问题一样——把某个东西存下来、稍后取回——但适用场景不同。寄存器是会话内的快速暂存槽，关掉 Emacs 就没了；书签会自动持久化到文件，下次启动 Emacs 还在。先把寄存器讲透，再讲书签，最后对比两者的取舍。

## 17.1 寄存器的基本概念

Emacs 的寄存器是一批有名字的「隔间」。每个隔间可以存**一种**东西：一段文本、一个光标位置、一个矩形、一个数字、一个窗口布局、一个文件名、一个 buffer 名、甚至一个键盘宏。一个寄存器同一时刻只能存一类内容，但你可以随时用新内容覆盖旧内容。

每个寄存器的名字是**单个字符**——字母、数字都行，大小写敏感（寄存器 `a` 和 `A` 是两个不同的寄存器）。你甚至可以用非字母数字字符，比如 `C-d`，方法是在提示输入寄存器名时用 `C-q C-d` 插入。

所有寄存器操作都挂在 `C-x r` 这个前缀键下（keymap 叫 `ctl-x-r-map`）。记忆口诀：`r` = register。

### 查看寄存器内容

如果你忘了某个寄存器里存了什么，用：

```
M-x view-register RET R
```

它会显示寄存器 `R` 里存的是哪种内容以及具体值。从 Emacs 29 开始，所有要求输入寄存器名的命令默认会弹出一个预览窗口列出已有的寄存器及其内容，等你按键选择。这个预览行为由变量 `register-use-preview` 控制，默认值是 `traditional`——先等延迟（由 `register-preview-delay` 决定秒数）再显示预览，你可以直接敲寄存器名覆盖。如果你更喜欢每次都立即看到预览并能上下导航选择，把它改成 `t` 或 `nil`。

## 17.2 存光标位置

这是寄存器最典型的用法之一：在长文件里标记几个重要位置，之后随时跳回去。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r SPC R` | `point-to-register` | 把当前 buffer 和光标位置存入寄存器 `R` |
| `C-x r j R` | `jump-to-register` | 跳到寄存器 `R` 保存的 buffer 和位置 |

`C-x r SPC`（注意最后一个键是空格）把「当前 buffer + 光标位置」打包存进寄存器 `R`。之后不管你怎么编辑、切换到别的文件，只要用 `C-x r j R` 就能跳回去。跳回去时 Emacs 会在 mark ring 里推一个 mark，所以你可以用 `C-u SPC`（`set-mark-command` 的前缀形式）跳回跳转前的位置。

寄存器里的位置不会被消耗——你可以反复 `C-x r j` 同一个寄存器。如果原来保存位置时对应的 buffer 已经被 kill 了，`C-x r j` 会尝试重新打开对应的文件（前提是这个 buffer 当时在访问一个文件）。

**典型场景**：你在一个项目的三四个文件之间来回改，每个文件里都有一个关键位置。用 `C-x r SPC 1`、`C-x r SPC 2`……把位置分别存进寄存器 `1`、`2`……，之后用 `C-x r j 1`、`C-x r j 2` 秒跳。这比 `C-x b` 切 buffer 再手动找位置快得多。

## 17.3 存文本

当你需要反复插入同一段文本时，把它存进寄存器比反复从 kill ring 里 yank 更可靠——kill ring 里每杀一次新内容就把旧条目往下推，而寄存器里的内容不会被动到。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r s R` | `copy-to-register` | 把 region 的文本**复制**到寄存器 `R` |
| `C-u C-x r s R` | `copy-to-register`（带前缀参数） | 把 region 的文本**移动**到寄存器 `R`（复制后删除原文） |
| `C-x r i R` | `insert-register` | 把寄存器 `R` 的内容插入到当前 buffer |

`C-x r s` 的 `s` 可以理解为 "store" 或 "save"。如果 mark 没激活，Emacs 会先重新激活上次设置的 mark，然后复制 region。复制完成后 mark 会被取消。

`C-x r i` 的 `i` 是 "insert"。默认情况下 point 留在插入文本之后、mark 设在插入文本之前（但未激活）。加前缀参数 `C-u C-x r i R` 则反过来：point 在文本之前、mark 在文本之后。

还有两个没有默认键绑定但很实用的命令：

- `M-x append-to-register RET R`：把 region 的文本**追加**到寄存器 `R` 已有文本的末尾。加前缀参数会同时删除 region。
- `M-x prepend-to-register RET R`：把 region 的文本**前置**到寄存器 `R` 已有文本的开头。

这两个命令让你可以分多次收集文本片段到同一个寄存器里。如果你希望各片段之间有分隔符（比如空行），可以配置 `register-separator` 变量：

```elisp
;; 把寄存器 "+" 设为分隔寄存器，内容是两个换行（即一个空行）
(setq register-separator ?+)
(set-register register-separator "\n\n")
```

第一行把 `register-separator` 设为字符 `+`（`?+` 是 Emacs Lisp 里表示字符 `+` 的写法），意思是「收集文本时用寄存器 `+` 的内容作为片段之间的分隔符」。第二行把寄存器 `+` 的内容设为两个换行。这段代码已经用 `emacs -Q --batch` 验证过，不会报错。

另外，当寄存器里存的是文本时，`C-x r +`（`increment-register`）的行为是**追加**文本到该寄存器——跟 `append-to-register` 效果一样。

## 17.4 存矩形

矩形（rectangle）是 Emacs 里一种特殊的文本区域——不是逐行的整段文字，而是由起止列界定的一个「方块」。第 11 章详细讲过矩形操作。寄存器可以存一个矩形，之后插入到任意位置。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r r R` | `copy-rectangle-to-register` | 把当前矩形区域复制到寄存器 `R` |
| `C-u C-x r r R` | `copy-rectangle-to-register`（带前缀参数） | 复制后删除原矩形 |

取出用同一个 `C-x r i R`——`insert-register` 会根据寄存器里存的是普通文本还是矩形自动选择正确的插入方式。

## 17.5 存窗口布局

有时候你在一个 frame 里精心排好了多个 window 的分割方式——上面一个看代码、下面左右各一个看编译输出和测试——想暂时切去做别的事、之后恢复这个布局。寄存器可以保存整个窗口布局甚至所有 frame 的布局。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r w R` | `window-configuration-to-register` | 保存当前 frame 的窗口布局到寄存器 `R` |
| `C-x r f R` | `frameset-to-register` | 保存所有 frame（包括各自的窗口布局）到寄存器 `R` |
| `C-x r j R` | `jump-to-register` | 恢复寄存器 `R` 保存的布局 |

`C-x r w` 的 `w` 是 "window"。注意它只保存**窗口怎么分割、每个窗口显示哪个 buffer**，不保存光标位置。如果你既要保存布局又要保存位置，需要分别用 `C-x r w` 和 `C-x r SPC` 存到不同寄存器。

`C-x r f` 的 `f` 是 "frame"。保存所有 frame 的完整状态。恢复时，不在保存配置里的现有 frame 会被隐藏（不是删除）。如果你想直接删除它们，用 `C-u C-x r j R`。

恢复布局用的还是 `C-x r j`——跟跳位置是同一个命令。Emacs 会根据寄存器里存的内容类型自动做正确的事。

## 17.6 存数字

寄存器可以存一个整数，也可以对它做加法。这在键盘宏里特别有用——比如你想给每一行加上递增的编号。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-u NUMBER C-x r n R` | `number-to-register` | 把数字 `NUMBER` 存入寄存器 `R` |
| `C-u NUMBER C-x r + R` | `increment-register` | 把寄存器 `R` 里的数字加上 `NUMBER` |
| `C-x r i R` | `insert-register` | 把寄存器 `R` 里的数字插入 buffer |

不加前缀参数时：`C-x r n` 存入 0，`C-x r +` 加 1。

**典型场景**：在键盘宏里，先用 `C-x r i R` 插入当前编号，再用 `C-u 1 C-x r + R` 把编号加 1，然后移到下一行。重复执行宏就能给多行加上连续编号。

## 17.7 存文件名和 buffer 名

如果你频繁访问某几个文件，可以把文件名存进寄存器，用 `C-x r j` 一键打开。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r F R` | `file-to-register` | 把当前访问的文件名存入寄存器 `R` |
| `C-x r B R` | `buffer-to-register` | 把当前 buffer 名存入寄存器 `R` |

之后 `C-x r j R` 就会打开对应的文件（或切到对应的 buffer）。`C-x r F` 加前缀参数可以手动输入一个文件名存入寄存器。

一个实用细节：如果你用 `C-x r B` 存了一个 buffer 名，后来这个 buffer 被关闭了（kill 了），Emacs 会自动把该寄存器转换成文件引用——这样你 `C-x r j` 时它会重新打开那个文件，而不是报错。

## 17.8 存键盘宏

第 16 章讲过键盘宏。如果你录了一个常用的键盘宏想反复调用，可以把它存进寄存器：

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x C-k x R` | `kmacro-to-register` | 把最近录制的键盘宏存入寄存器 `R` |

执行寄存器里的键盘宏同样用 `C-x r j R`——Emacs 发现寄存器里存的是键盘宏就会执行它。

## 17.9 书签：持久化的「寄存器」

书签和寄存器的思路类似——都是「存一个位置、之后跳回去」——但有两个关键区别：

1. **书签的名字可以很长**（一个字符串），而寄存器的名字只能是单个字符。所以书签可以叫 `"第 7 章-关于并发的那节"` 而不是 `a`。
2. **书签会自动持久化**。Emacs 退出时会把书签保存到文件 `~/.emacs.d/bookmarks`，下次启动时自动加载。寄存器则不会——关掉 Emacs，寄存器里的东西就没了。

书签的典型用法是：记录你在各个文件里读到哪里了。

### 设置和跳转

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r m RET` | `bookmark-set` | 为当前文件在当前光标位置设一个书签（默认用文件名为书签名） |
| `C-x r m BOOKMARK RET` | `bookmark-set` | 设一个名为 `BOOKMARK` 的书签 |
| `C-x r M BOOKMARK RET` | `bookmark-set-no-overwrite` | 设书签，但如果同名书签已存在则报错（不覆盖） |
| `C-x r b BOOKMARK RET` | `bookmark-jump` | 跳到名为 `BOOKMARK` 的书签 |
| `C-x r l` | `bookmark-bmenu-list` | 列出所有书签 |

`C-x r m` 的 `m` 是 "mark"。如果你直接按 `RET`（不输入名字），Emacs 默认用当前访问的文件名作为书签名。这意味着如果你习惯把书签跟文件一一对应，设书签只需要 `C-x r m RET` 两个键。

在图形界面下，设书签时 Emacs 还会在对应行的左侧 fringe 上放一个小标记，提醒你这一行有个书签。这个行为由变量 `bookmark-fringe-mark` 控制，默认开启；设成 `nil` 可以关掉。

`C-x r b` 的 `b` 是 "bookmark"。跳到书签时，Emacs 会打开对应的文件并把光标移到保存的位置。书签保存位置时会记录周围的一些上下文文字，所以即使文件被小幅修改过，Emacs 也能找到正确的位置（上下文记录的长度由 `bookmark-search-size` 控制）。

### 管理书签

`C-x r l` 打开一个专门的 `*Bookmark List*` buffer，里面列出所有书签及其对应的文件和位置。在这个 buffer 里你可以编辑书签定义、添加注释。按 `C-h m` 可以看这个 buffer 里所有可用的操作键。

书签的保存和加载：

- **自动保存**：Emacs 正常退出时，如果你改过任何书签，会自动保存到 `~/.emacs.d/bookmarks`。
- **手动保存**：`M-x bookmark-save` 立即保存。
- **自动保存频率**：变量 `bookmark-save-flag` 控制。默认值是一个数字，表示每修改这么多次书签就自动保存一次。设成 `1` 则每次修改都保存（最安全，但频繁写磁盘）。设成 `nil` 则只在你手动 `M-x bookmark-save` 或退出 Emacs 时才保存。

```elisp
;; 每次修改书签都立即保存——防止 Emacs 崩溃丢失书签
(setq bookmark-save-flag 1)
```

这段代码已经用 `emacs -Q --batch` 验证过。

其他管理命令：

- `M-x bookmark-delete RET BOOKMARK RET`：删除名为 `BOOKMARK` 的书签。
- `M-x bookmark-load RET FILENAME RET`：从另一个文件加载书签。
- `M-x bookmark-insert-location RET BOOKMARK RET`：在 buffer 里插入书签对应的文件路径。
- `M-x bookmark-insert RET BOOKMARK RET`：在 buffer 里插入书签对应文件的**内容**。

## 17.10 寄存器 vs 书签：怎么选

| 特性 | 寄存器 | 书签 |
|---|---|---|
| 名字 | 单个字符 | 任意长度字符串 |
| 持久化 | 否（会话结束即丢失） | 是（自动保存到文件） |
| 能存的内容 | 位置、文本、矩形、数字、窗口布局、frame 布局、文件名、buffer 名、键盘宏 | 文件 + 位置（+ 可选注释） |
| 典型用途 | 编辑过程中的快速暂存 | 跨会话的阅读位置标记 |

**经验法则**：

- 编辑过程中需要临时记住几个位置或几段文本 → 用寄存器。
- 想记住「我上次在这本书的第 X 章读到哪了」 → 用书签。
- 需要存文本片段、矩形、数字、窗口布局 → 只能用寄存器，书签做不到。

两者不冲突，可以一起用。比如你用寄存器 `a` 暂存一段待插入的文本，同时用书签 `"第 7 章"` 记住阅读位置——互不干扰。

## 17.11 小结

- 寄存器用单字符命名，全部操作在 `C-x r` 前缀下。
- `C-x r SPC` / `C-x r j` 存/跳位置；`C-x r s` / `C-x r i` 存/取文本；`C-x r r` 存矩形；`C-x r w` / `C-x r f` 存窗口/frame 布局；`C-x r n` / `C-x r +` 存/增数字；`C-x r F` / `C-x r B` 存文件/buffer 名。
- 书签是持久化的「位置 + 文件」记录，用 `C-x r m` 设、`C-x r b` 跳、`C-x r l` 列表。
- 书签自动保存到 `~/.emacs.d/bookmarks`；寄存器不保存。

---

上一章：[16 · 键盘宏](16-keyboard-macros.md) ｜ 下一章：[18 · 拼写检查与缩写](18-spelling-and-abbrevs.md) ｜ 返回：[使用 Emacs 教程](README.md)
