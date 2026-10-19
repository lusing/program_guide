# 03 · 最基本的编辑

这一章把日常编辑的看家本领过一遍：输入文字、移动光标、删除文本、撤销、插入空行、理解折行与截断、查看位置信息。全部命令都经过实测，你在 `emacs -Q` 里跟着敲就能对上。

## 3.1 插入文本

### 3.1.1 直接打字

输入普通可打印字符（字母、数字、标点）就会把它插入到 point 所在的位置，point 跟着往后移。就这么简单——Emacs 默认就是插入模式，你打什么它就收什么。

### 3.1.2 RET 与 C-j

按 `RET`（`newline`）插入一个换行符，然后**自动缩进**新行（由主模式决定缩进量）。如果 point 在行尾，效果是在下面开一个新行并缩进；如果 point 在行中间，效果是从 point 处把行一分为二。

如果你不想自动缩进，有两种办法：

- 用 `C-j`（`electric-newline-and-maybe-indent`）——这个命令插入换行但行为与 `RET` 略有不同。在默认开启的 Electric Indent mode 下，`C-j` 实际上也做缩进；但如果你关闭了 Electric Indent mode（`M-x electric-indent-mode` 切换），`C-j` 只插入换行不做缩进。
- 关闭 Electric Indent mode 后，`RET`（`newline`）也只插入换行加缩进（由主模式的缩进函数决定），而 `C-j` 则只插入纯粹的换行。

**常见误区**：很多人以为 `C-j` 是「不带缩进的换行」——这在关闭 Electric Indent mode 后是对的，但在默认配置下 `C-j` 仍然可能做缩进。如果你想确保不缩进，最稳妥的办法是先关掉 Electric Indent mode 再用 `C-j`。

### 3.1.3 插入不可打印字符

有些字符键盘上打不出来（控制字符、特殊 Unicode）。用 `C-q`（`quoted-insert`）来插入：

- `C-q` 然后按一个不可打印字符（甚至 `C-g`）：直接插入该字符。例如 `C-q <DEL>` 插入一个字面的 DEL 字符。
- `C-q` 然后输入八进制数字：插入对应编码的字符。任何非数字键结束输入。如果结束键是 `RET`，`RET` 只起结束作用不被插入。

变量 `read-quoted-char-radix` 控制进制：默认是 8（八进制），设为 10 或 16 可以用十进制或十六进制。

### 3.1.4 插入 Unicode 字符

`C-x 8 RET`（`insert-char`）提示你输入 Unicode 字符名或码位。输入名称时支持补全（`TAB`）；输入码位时用十六进制（这是 Unicode 的惯例）。

```
C-x 8 RET left single quotation mark RET
C-x 8 RET 2018 RET
```

两种写法都插入 `‘`（U+2018）。

`C-x 8` 后面还有一些快捷方式：`C-x 8 [` 插入 `'`，`C-x 8 ]` 插入 `'`，`C-x 8 {` 插入 `"`，`C-x 8 }` 插入 `"`。`C-x 8 C-h` 列出所有可用的快捷。

### 3.1.5 Auto Fill mode 与 Overwrite mode

两个值得知道的次模式：

- **Auto Fill mode**：自动在行太长时插入换行，避免手动拆行。
- **Overwrite mode**：插入字符时覆盖（替换）后面的文本，而不是把它往后推。

这两个模式默认都是关闭的。

## 3.2 移动 Point

这是你最常用的操作。下面列出所有基本移动命令，每个都经过 keyq.py 实测。

### 3.2.1 字符级移动

| 键 | 命令 | 作用 |
|----|------|------|
| `C-f` | `forward-char` | 向前（右）移一个字符 |
| `C-b` | `backward-char` | 向后（左）移一个字符 |

`C-f` 和 `C-b` 是最基础的移动。在行尾按 `C-f` 会跳到下一行行首；在行首按 `C-b` 会跳到上一行行尾。

### 3.2.2 行级移动

| 键 | 命令 | 作用 |
|----|------|------|
| `C-n` | `next-line` | 向下移一行（屏幕行） |
| `C-p` | `previous-line` | 向上移一行（屏幕行） |
| `C-a` | `move-beginning-of-line` | 移到行首 |
| `C-e` | `move-end-of-line` | 移到行尾 |

`C-n` 和 `C-p` 按**屏幕行**（visual line）移动，不是逻辑行。如果一行文本因为太长而被折行显示成多行屏幕行，`C-n` 会移到下一个屏幕行。如果你希望它们按逻辑行移动，把变量 `line-move-visual` 设为 `nil`。

`C-a` 和 `C-e` 则始终按**逻辑行**操作：`C-a` 到逻辑行行首，`C-e` 到逻辑行行尾。

### 3.2.3 词级移动

| 键 | 命令 | 作用 |
|----|------|------|
| `M-f` | `forward-word` | 向前移一个单词 |
| `M-b` | `backward-word` | 向后移一个单词 |

「单词」的定义取决于主模式的语法表。在文本模式里就是自然语言的单词；在编程模式里通常是标识符。

### 3.2.4 Buffer 级移动

| 键 | 命令 | 作用 |
|----|------|------|
| `M-<` | `beginning-of-buffer` | 移到 buffer 开头 |
| `M->` | `end-of-buffer` | 移到 buffer 末尾 |

带数字参数 N 时，`M-<` 移到 buffer 的 N/10 处。例如 `M-5 M-<` 移到 buffer 的 50% 处。

### 3.2.5 窗口级移动

| 键 | 命令 | 作用 |
|----|------|------|
| `M-r` | `move-to-window-line-top-bottom` | 在窗口顶部、中间、底部循环切换 |
| `C-v` | `scroll-up-command` | 向下翻一屏 |
| `M-v` | `scroll-down-command` | 向上翻一屏 |

`M-r` 的行为比较特别：第一次按，point 跳到窗口中间那行的行首；再按，跳到底部那行的行首；再按，回到顶部——如此循环。带数字参数 N 时，直接跳到从窗口顶部数第 N 行（0 是顶行，-1 是底行）。

`C-v` 和 `M-v` 主要作用是滚动显示，但如果滚动后 point 不在可见区域了，它们也会把 point 移到可见范围内。

### 3.2.6 跳到指定行或字符位置

| 键 | 命令 | 作用 |
|----|------|------|
| `M-g M-g`（或 `M-g g`） | `goto-line` | 跳到指定行号 |
| `M-g c` | `goto-char` | 跳到指定字符位置 |
| `M-g TAB` | `move-to-column` | 跳到当前行的指定列 |

`M-g M-g` 会在 minibuffer 里提示你输入行号。如果 point 当前在一个数字上面或紧挨着数字，那个数字会自动作为默认值——直接按 `RET` 就跳到该行。你也可以用前缀参数：`M-5 0 M-g M-g` 直接跳到第 50 行，不需要在 minibuffer 里输入。

`M-g c` 类似，但接受的是 buffer 中的字符位置（从 1 开始计数）。

### 3.2.7 固定目标列

`C-x C-n`（`set-goal-column`）把 point 当前的列设为「半永久目标列」。之后 `C-n`、`C-p` 在垂直移动时会尽量保持在这个列上。这在你要沿一列不规则文本上下移动时很有用。

`C-u C-x C-n` 取消目标列，恢复正常行为。

## 3.3 删除与 Kill

Emacs 有两类删除操作，理解它们的区别很重要。

**删除**（delete）——单纯地把文本去掉，不保存。

**Kill**——把文本去掉的同时保存到 **kill ring**（剪切历史）里，之后可以用 `C-y`（`yank`）粘贴回来。

### 3.3.1 删除命令

| 键 | 命令 | 作用 |
|----|------|------|
| `DEL`（退格） | `delete-backward-char` | 删除 point 前面的字符 |
| `C-d` | `delete-char` | 删除 point 后面的字符 |

`DEL` 就是你键盘上的 Backspace 键。如果 point 在行首，`DEL` 会删掉上一行的换行符，把当前行接到上一行后面。

**注意**：如果 region 是激活状态（高亮选区），`DEL` 会删除整个选区的内容，而不是只删一个字符。`C-d` 则不管 region 是否激活，始终只删除 point 后面的一个字符。

### 3.3.2 Kill 命令

| 键 | 命令 | 作用 |
|----|------|------|
| `C-k` | `kill-line` | Kill 到行尾 |
| `M-d` | `kill-word` | Kill 前面的一个单词 |
| `M-DEL` | `backward-kill-word` | Kill 后面的一个单词 |

`C-k` 的行为取决于 point 的位置：

- 在行中间：kill 从 point 到行尾的所有文本。
- 在行尾：kill 换行符本身（把下一行合并上来）。

连续两次 `C-k`（都在不带参数的情况下）可以杀掉一整行非空行：第一次杀掉行尾内容，第二次杀掉换行符。

`M-d` 杀掉从 point 到当前单词末尾的文本。`M-DEL` 杀掉从 point 到前一个单词开头的文本。

所有 kill 命令去掉的文本都进入 kill ring，可以用 `C-y` 粘贴。Kill ring 的详细内容在后面的章节讲。

## 3.4 撤销

| 键 | 命令 | 作用 |
|----|------|------|
| `C-/` | `undo` | 撤销一步 |
| `C-x u` | `undo` | 同上 |
| `C-_` | `undo` | 同上 |

三个键绑的是同一个命令 `undo`。`C-/` 在大多数图形终端上最方便（不需要 Shift）；在某些文本终端上 `C-/` 可能不存在，但 Emacs 通常会把它映射到 `C-_`；还有些终端允许你省略 Shift 来输入 `C-_`（实际上按的是 `C--`）。

撤销只针对 buffer 内容的变化，不针对光标移动。

连续按 `C-/` 会逐步撤销更早的改动，直到撤销记录的极限。如果所有可撤销的改动都已经撤销了，再按会显示错误消息。

**常见误区**：撤销不是「撤销最后一次按键」，而是「撤销 undo 记录里的一条」。一条 undo 记录通常对应一个编辑命令，但非常简单的命令可能会被合并，复杂的命令也可能被拆成多条记录。

## 3.5 空行操作

| 键 | 命令 | 作用 |
|----|------|------|
| `C-o` | `open-line` | 在 point 后面插入换行（point 不移动） |
| `C-x C-o` | `delete-blank-lines` | 删除多余的空行 |

`C-o` 与 `RET` 的区别：`RET` 在 point 处拆行并把 point 移到新行；`C-o` 在 point 后面插入换行但 point 留在原地——效果是在 point 后面开一个空行，你可以在这个空行里输入文字。

带数字参数时，`C-o` 插入对应数量的空行：`M-3 C-o` 插入 3 个空行。

`C-x C-o`（`delete-blank-lines`）是清理多余空行的利器：

- 如果 point 在连续多个空行中间：删除到只剩一个空行。
- 如果 point 在一个单独的空行上：删除这个空行。
- 如果 point 在一个非空行上：删除后面紧跟的所有空行。

## 3.6 折行与截断

当一行文本（逻辑行）比窗口宽时，Emacs 有两种处理方式：

### 3.6.1 折行（Continuation / Line Wrapping）

默认行为。长行在窗口右边缘被折到下一行显示。在图形界面上，折行的行在左侧 fringe 区域有一个小弯箭头指示；在文本终端上，右边缘显示 `\` 字符。

折行可能在单词中间断开，影响阅读。解决办法是手动在合适的位置插入换行，或者开启 Auto Fill mode 让 Emacs 自动断行。

### 3.6.2 截断（Line Truncation）

长行只显示窗口宽度内的部分，超出部分不显示。在图形界面上，被截断的行在右侧 fringe 有一个直箭头；在文本终端上，右边缘显示 `$`。

截断可以用 `M-x toggle-truncate-lines` 切换。某些主模式（如 `prog-mode` 的子模式）默认开启截断。

### 3.6.3 Visual Line mode

`M-x visual-line-mode` 开启 Visual Line mode 后，折行会在单词边界（空格或 Tab）处进行，而不是在窗口边缘硬切。同时 `C-a`、`C-n`、`C-k` 等命令会改为按屏幕行操作而非逻辑行。这在编辑自然语言文本时很有用。

## 3.7 位置信息

### 3.7.1 Mode line 里的信息

如第 1 章所述，mode line 显示当前行号（`L` 加数字）和位置百分比（`Top`/`Bot`/`NN%`）。开启 `M-x column-number-mode` 后还会显示列号。

### 3.7.2 C-x =（what-cursor-position）

`C-x =`（`what-cursor-position`）在 echo area 显示一条详细信息：

```
Char: c (99, #o143, #x63) point=28062 of 36168 (78%) column=53
```

各字段含义：

- `Char: c`：point 后面的字符。
- `(99, #o143, #x63)`：该字符的十进制、八进制、十六进制编码。
- `point=28062`：point 在 buffer 中的字符位置（从 1 开始）。
- `of 36168`：buffer 总字符数。
- `(78%)`：point 位置占总字符数的百分比。
- `column=53`：point 所在的列。

如果变量 `what-cursor-show-names` 为非 `nil`（默认就是），还会显示字符的 Unicode 名称：

```
Char: c (99, #o143, #x63, LATIN SMALL LETTER C) point=28062 ...
```

如果 buffer 被 narrowed（限制了可见范围），`C-x =` 还会显示可访问范围的两端位置。

### 3.7.3 M-x what-line

`M-x what-line RET` 在 echo area 显示当前行号。通常 mode line 已经显示行号了，所以这个命令的主要用途是在 buffer 被 narrowed 时：它会同时显示相对于 narrowed 区域的行号和相对于整个 buffer 的行号。

### 3.7.4 M-=（count-words-region）

`M-=`（`count-words-region`）统计 region（选区）内的行数、句子数、单词数和字符数。如果 region 没有激活，会提示你先设置 mark。

带前缀参数 `C-u M-=` 时，统计整个 buffer 而不是 region。

### 3.7.5 M-x count-words

`M-x count-words RET` 与 `M-=` 功能类似但调用方式不同：如果 region 激活了就统计 region，否则统计整个 buffer。

## 3.8 小结

- 直接打字即可插入文本；`RET` 换行并缩进，`C-j` 换行（缩进行为取决于 Electric Indent mode）。
- 移动 point：`C-f`/`C-b`（字符）、`C-n`/`C-p`（屏幕行）、`C-a`/`C-e`（行首/行尾）、`M-f`/`M-b`（单词）、`M-<`/`M->`（buffer 首/尾）、`M-g M-g`（跳行）。
- `DEL` 删前面字符，`C-d` 删后面字符——这是 delete，不进 kill ring。`C-k`/`M-d`/`M-DEL` 是 kill，进 kill ring 可以粘贴。
- `C-/`、`C-x u`、`C-_` 撤销。
- `C-o` 在 point 后开空行，`C-x C-o` 清理多余空行。
- 长行默认折行显示，可切换为截断；Visual Line mode 在单词边界折行。
- `C-x =` 查看字符编码和位置详情；`M-=` 统计 region 的字数。

---

上一章：[02 · 按键与命令](02-keys-and-commands.md) ｜ 下一章：[04 · 自助文档：Help 家族](04-help.md) ｜ 返回：[使用 Emacs 教程](README.md)
