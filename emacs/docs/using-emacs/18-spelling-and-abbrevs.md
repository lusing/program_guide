# 18 · 拼写检查与缩写

这一章讲两类辅助写作的工具：**拼写检查**帮你发现和纠正拼错的单词；**缩写**（abbrev）让你输入一个短词就自动展开成一段长文本。两者看似无关，实际上 Emacs 可以把拼写检查的纠正结果自动保存为缩写——拼错过的词下次自动改正。最后讲**动态缩写**（dabbrev），它能根据 buffer 里已有的文本自动补全单词，是日常编辑中最常用的「看前面写过的词、帮我补全」功能。

## 18.1 拼写检查

Emacs 本身不做拼写检查——它调用外部程序。支持的拼写检查器有 Hunspell、Aspell、Ispell 和 Enchant，它们不是 Emacs 的一部分，但多数 GNU/Linux 和类 Unix 系统上至少装了一个。如果你装了多个，可以用变量 `ispell-program-name` 指定用哪个。Emacs 第一次调用拼写检查命令时会自动找到可用的程序。

### 检查一个词

| 键 | 命令 | 作用 |
|---|---|---|
| `M-$` | `ispell-word` | 检查光标处（或之前）的单词的拼写 |
| `C-u M-$` | `ispell-continue` | 继续上次被中断的拼写检查 |

`M-$` 是最常用的拼写检查键。它会检查光标所在位置（或光标之前）的单词。如果当前有选区（region 处于激活状态），则检查选区内所有单词。

遇到疑似拼错的词时，Emacs 会在一个窗口里列出编号的「近似词」（near-misses）——跟拼错的词长像的候选词——然后等你输入单字符指令。以下是可用的响应：

| 按键 | 含义 |
|---|---|
| `数字` | 用对应的近似词替换（仅本次） |
| `SPC` | 跳过这个词（视为正确但不修改） |
| `r NEW RET` | 用 `NEW` 替换（仅本次） |
| `R NEW RET` | 用 `NEW` 替换，并做 `query-replace` 在全文替换 |
| `a` | 在本次会话中接受这个词（不再报错） |
| `A` | 在本次会话的当前 buffer 中接受这个词 |
| `i` | 把这个词加入你的个人词典——以后永远不再报错 |
| `u` | 把这个词的小写形式加入个人词典 |
| `l WORD RET` | 在词典中查找匹配 `WORD` 的词（`*` 是通配符），用结果替换近似词列表 |
| `C-g` 或 `X` | 中断拼写检查，光标留在当前词。之后可用 `C-u M-$` 继续 |
| `x` | 退出拼写检查，光标回到开始检查前的位置 |
| `q` | 退出拼写检查并终止拼写检查子进程 |
| `C-r` | 进入递归编辑（可以查看 buffer 内容但不修改拼错的词），用 `C-M-c` 退出后继续检查 |
| `?` | 显示帮助（列出所有选项） |

`i` 是最实用的选项之一：遇到一个专有名词或术语被标记为拼错，按 `i` 把它加进个人词典，以后就再也不会被报了。个人词典的位置由 `ispell-personal-dictionary` 指定；如果是 `nil`，就用拼写检查程序自己的默认位置。

### 检查整个 buffer

| 命令 | 作用 |
|---|---|
| `M-x ispell` | 检查整个 buffer（有选区则只检查选区） |
| `M-x ispell-buffer` | 明确检查整个 buffer |
| `M-x ispell-region` | 明确检查选区 |
| `M-x ispell-message` | 检查邮件草稿（跳过引用内容） |
| `M-x ispell-comments-and-strings` | 只检查注释和字符串（写代码时用） |
| `M-x ispell-comment-or-string-at-point` | 检查光标处的注释或字符串 |

`M-x ispell` 和 `M-x ispell-buffer` 的区别很微妙：如果选区激活了，`M-x ispell` 只检查选区；`M-x ispell-buffer` 始终检查整个 buffer。

`M-x ispell-comments-and-strings` 对程序员特别有用——它会跳过代码本身，只检查注释和字符串字面量里的英文。写英文注释或文档字符串时用它，不会被代码里的标识符干扰。

### 词典

拼写检查器使用两种词典：标准词典和个人词典。标准词典由 `ispell-local-dictionary` 或 `ispell-dictionary` 指定；如果都是 `nil`，就用拼写检查程序的默认词典。

切换词典用：

```
M-x ispell-change-dictionary RET DICT RET
```

这会重启拼写检查子进程并使用新词典。比如你在写英文文档和法文文档之间切换，就需要切换词典。

Hunspell 比较特殊：它支持同时使用多个词典。用 `M-x ispell-hunspell-add-multi-dic` 指定逗号分隔的词典组合（如 `"en_US,de_DE,ru_RU"`），之后就可以在混排多种语言时一次性检查。

### 拼写检查子进程

拼写检查器启动后作为一个子进程持续运行，等待后续命令。这样第二次以后的拼写检查会更快。如果你想终止这个子进程，用 `M-x ispell-kill-ispell`——不过通常没必要，因为子进程在不检查拼写时不占 CPU。

### 自动拼写检查：Flyspell 模式

如果你希望**边打字边检查**——拼错的词立刻被高亮——可以启用 Flyspell 模式：

```
M-x flyspell-mode
```

这是一个 buffer-local 的 minor mode。启用后，你输入或移动光标经过的每个词都会被检查，拼错的词会以特殊 face 高亮。

对程序文件，更好的选择是：

```
M-x flyspell-prog-mode
```

它只检查注释和字符串里的词——跟 `ispell-comments-and-strings` 的范围一样。

要在所有文本模式 buffer 里自动启用 Flyspell：

```elisp
(add-hook 'text-mode-hook 'flyspell-mode)
```

要在所有编程模式 buffer 里自动启用 Flyspell Prog mode：

```elisp
(add-hook 'prog-mode-hook 'flyspell-prog-mode)
```

高亮的拼错词可以用以下方式纠正：

- 鼠标中键（`mouse-2`）点它，弹出纠正菜单。
- `C-.` 或 `M-TAB`（`flyspell-auto-correct-word`）：逐个提出纠正建议。
- `C-c $`（`flyspell-correct-word-before-point`）：弹出纠正菜单。

注意：Flyspell 需要在你移动光标时检查每个经过的词，所以它会让光标移动和滚动变慢。它也不会自动检查你没有移动经过的文本——要检查那些，用 `M-x flyspell-region` 或 `M-x flyspell-buffer`。

### 单词补全

| 键 | 命令 | 作用 |
|---|---|---|
| `M-TAB` | `complete-symbol` | 根据拼写词典和其他补全源补全光标前的单词 |

输入一个单词的前几个字母，按 `M-TAB`，Emacs 会给出补全候选。如果你的窗口管理器拦截了 `M-TAB`，可以用 `ESC TAB` 或 `C-M-i` 代替。

## 18.2 缩写（Abbrev）：定义与展开

缩写（abbrev）是你定义的一个短词，输入它之后按空格或标点，Emacs 自动把它替换成你预设的长文本。比如你定义 `foo` 展开为 `find outer otter`，那么输入 `foo SPC` 后 buffer 里就变成了 `find outer otter `。

### 18.2.1 基本概念

缩写有两个层次：

- **全局缩写**（global abbrev）：在所有 major mode 下都生效。
- **模式缩写**（mode-specific abbrev）：只在特定 major mode 下生效。

同一个缩写可以同时有全局定义和模式定义。在当前 major mode 有定义的情况下，模式定义优先于全局定义。

缩写只有在 **Abbrev mode** 开启时才会自动展开。Abbrev mode 是一个 buffer-local 的 minor mode：

```
M-x abbrev-mode
```

加正参数开启、负参数或零关闭。关掉 Abbrev mode 不会丢失缩写定义——只是不自动展开了。如果你想在所有 buffer 里默认开启 Abbrev mode：

```elisp
(setq-default abbrev-mode t)
```

### 18.2.2 定义缩写

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x a g` | `add-global-abbrev` | 用光标前的一个或多个词作为展开文本，定义一个全局缩写 |
| `C-x a l` | `add-mode-abbrev` | 同上，但定义的是当前 major mode 的模式缩写 |
| `C-x a i g` | `inverse-add-global-abbrev` | 反向定义：光标处是缩写名，在 minibuffer 里输入展开文本 |
| `C-x a i l` | `inverse-add-mode-abbrev` | 同上，但定义模式缩写 |

**正序定义**（`C-x a g` / `C-x a l`）：先在 buffer 里输入你想让缩写展开成的文本，光标放在文本后面，然后按 `C-x a g`。Emacs 会在 minibuffer 里问你缩写名是什么。比如你想让缩写 `cnst` 展开为 `construction`：

1. 输入 `construction`
2. 光标在 `construction` 后面
3. 按 `C-x a g`
4. 在 minibuffer 里输入 `cnst RET`

如果光标前有多个词，默认全部作为展开文本。用数字前缀参数可以指定取几个词：`C-u 3 C-x a g` 取光标前 3 个词。如果 Transient Mark mode 开着（默认就开着）且有选区，选区内容作为展开文本。

**反序定义**（`C-x a i g` / `C-x a i l`）：适合缩写名已经在 buffer 里的情况。光标放在缩写名上，按 `C-x a i g`，然后在 minibuffer 里输入展开文本。

**不用 buffer 直接定义**：

```
M-x define-global-abbrev RET ABBREV RET EXP RET
M-x define-mode-abbrev RET ABBREV RET EXP RET
```

直接在 minibuffer 里输入缩写名和展开文本，不需要先在 buffer 里写任何东西。

**删除缩写定义**：给定义命令传负参数。`C-u - C-x a g` 删除一个全局缩写定义，`C-u - C-x a l` 删除一个模式缩写定义。`M-x kill-all-abbrevs` 删除所有缩写定义。

### 18.2.3 展开行为

Abbrev mode 开启时，你在输入一个已定义的缩写之后打一个非词字符（空格、逗号、句号等），缩写就会被替换成展开文本。

展开会**保留大小写模式**：

- `cnst` → `construction`（全小写）
- `Cnst` → `Construction`（首字母大写）
- `CNST` → 默认 `Construction`（每个词首字母大写）；如果把 `abbrev-all-caps` 设为非 `nil`，则变成 `CONSTRUCTION`（全大写）

**不想展开怎么办？** 如果你打了缩写名但不想它展开，在后面的分隔符前加 `C-q`。比如 `cnst C-q ,` 会留下 `cnst,` 而不是展开。已经误展开了可以用 `C-/`（`undo`）撤销，或者用 `M-x unexpand-abbrev` 撤销最近一次展开。

**前缀标记**（`M-'`）：有时候你想给展开加前缀。比如 `cnst` 展开为 `construction`，你想输入 `reconstruction`。直接打 `recnst` 不行——`recnst` 不是一个已定义的缩写。做法是：

1. 输入 `re`
2. 按 `M-'`（`abbrev-prefix-mark`）——buffer 里会出现一个连字符 `re-`
3. 输入 `cnst`
4. 打一个空格触发展开

结果是 `reconstruction`——连字符被删掉，前缀 `re` 和展开文本 `construction` 合在一起。

### 18.2.4 手动展开

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x a e` | `expand-abbrev` | 手动展开光标前的缩写（即使 Abbrev mode 没开也能用） |

`M-x expand-region-abbrevs`：搜索选区里所有已定义的缩写，对每一个问你要不要展开。如果你忘了开 Abbrev mode 就打了一堆缩写，用这个命令一次性展开。

## 18.3 查看和编辑缩写列表

```
M-x list-abbrevs
```

列出所有缩写定义。输出格式类似：

```
(global-abbrev-table)
"cnst"        0    "construction"
"dfn"         5    "definition"
```

每个缩写表（abbrev table）有一行标题，如 `(global-abbrev-table)` 是全局缩写表，`(c-mode-abbrev-table)` 是 C 模式的缩写表。每行定义一个缩写：缩写名、展开次数、展开文本。展开次数是 Emacs 帮你追踪的，方便你清理那些从来不用的缩写。

```
M-x edit-abbrevs
```

跟 `list-abbrevs` 格式一样，但会把结果放在一个叫 `*Abbrevs*` 的 buffer 里让你直接编辑。你可以添加新行、修改展开文本、删除行。编辑完后按 `C-c C-c` 安装修改后的定义——任何不在 buffer 里的定义会被删除。

## 18.4 保存缩写

缩写可以保存到文件，下次启动 Emacs 时自动加载。

| 命令 | 作用 |
|---|---|
| `M-x write-abbrev-file RET FILE RET` | 把所有缩写定义写入文件 `FILE` |
| `M-x read-abbrev-file RET FILE RET` | 从文件 `FILE` 读取缩写定义 |

如果不指定文件名（直接 `RET`），默认使用 `abbrev-file-name` 变量的值，即 `~/.emacs.d/abbrev_defs`。

Emacs 启动时会自动从这个文件加载缩写（batch 模式除外）。

Emacs 在退出时（`C-x s` 或 `C-x C-c`），如果你改过任何缩写，会主动问你要不要保存。这个行为由变量 `save-abbrevs` 控制：

- `nil`：不自动保存。
- `t`（默认值）：问你要不要保存。
- `silently`：自动保存、不问你。

如果你确定要持久保存缩写，推荐设成 `silently`：

```elisp
(setq save-abbrevs 'silently)
```

## 18.5 动态缩写（Dabbrev）：最实用的补全

动态缩写（dynamic abbreviation expansion，简称 dabbrev）是另一种补全机制，跟前面讲的「预定义缩写」完全不同：

- 预定义缩写需要你事先定义好「缩写 → 展开」的映射。
- 动态缩写**不需要预定义**——它直接在当前 buffer（以及其他 buffer）里搜索，找所有以你输入的前缀开头的词，逐个提供给你选。

| 键 | 命令 | 作用 |
|---|---|---|
| `M-/` | `dabbrev-expand` | 动态展开光标前的词 |
| `C-M-/` | `dabbrev-completion` | 动态补全（把所有匹配的共同前缀插入） |

`M-/` 是日常编辑中使用频率非常高的键。用法：

1. 输入一个词的前几个字母，比如 `fol`。
2. 按 `M-/`。
3. Emacs 从光标位置**向前**搜索所有以 `fol` 开头的词，找到最近的一个（比如 `follow`），替换你输入的 `fol`。
4. 再按一次 `M-/`，找下一个匹配（比如 `folder`）。
5. 继续按 `M-/` 会遍历所有匹配。搜完光标前的文本后，会继续搜索光标后的文本。

数字前缀参数 `C-u 3 M-/` 直接跳到第 3 个不同的展开。负参数 `C-u - M-/` 改变搜索方向——先搜光标后面、再搜其他 buffer、最后才搜光标前面。

搜索范围不限于当前 buffer。Emacs 会搜索其他 buffer，由 `dabbrev-check-all-buffers` 和 `dabbrev-check-other-buffers` 控制。变量 `dabbrev-ignored-buffer-modes` 列出应该跳过的 major mode（比如 `dired-mode`）。

**追加后续词**：展开一个词之后，按 `SPC M-/` 可以复制展开词在原上下文中的下一个词。再按 `SPC M-/` 复制再下一个。空格和标点也会一起复制。这在复制一个长短语时特别方便。

`C-M-/`（`dabbrev-completion`）跟 `M-/` 不同：它找到所有匹配后，插入它们的**公共前缀**。如果公共前缀就是完整词，就直接补完；如果没有公共前缀，就列出所有候选让你选。

动态缩写完全独立于 Abbrev mode——不管 Abbrev mode 开没开，`M-/` 都能用。

### 动态缩写的定制

变量 `dabbrev-limit`（如果非 `nil`）限制在当前 buffer 里搜索的距离（字符数）。超出这个距离的词不会被找到。

`dabbrev-ignored-buffer-names` 是一个 buffer 名列表，搜索时跳过这些 buffer。`dabbrev-ignored-buffer-regexps` 是正则表达式列表，buffer 名匹配任一正则的 buffer 也会被跳过。

## 18.6 拼写检查与缩写的联动

Emacs 可以把拼写检查的纠正自动保存为全局缩写。变量 `ispell-save-corrections-as-abbrevs` 控制这个行为：

- 设为非 `nil`：每次你在拼写检查中纠正一个词，Emacs 自动把纠正保存为全局缩写。以后你打出拼错的词再加空格，就会自动展开成正确的拼写。
- 默认值 `nil`：不自动保存。此时加 `C-u` 前缀参数选择替换则会保存为缩写。

这个功能让你「错一次、记住一辈子」——拼错过的词以后自动改正。

## 18.7 小结

- `M-$`（`ispell-word`）检查一个词的拼写；`M-x ispell-buffer` 检查整个 buffer。
- 拼写检查交互中：数字选候选、`SPC` 跳过、`i` 加入个人词典、`r` 替换、`q` 退出。
- `M-x flyspell-mode` 边打字边高亮拼错的词。
- `C-x a g` / `C-x a l` 定义全局/模式缩写；Abbrev mode 开启时自动展开。
- `M-/`（`dabbrev-expand`）根据 buffer 里已有的文本动态补全——最常用的「帮我补完这个词」。
- `C-M-/`（`dabbrev-completion`）插入所有匹配的共同前缀。
- 缩写保存在 `~/.emacs.d/abbrev_defs`，Emacs 启动时自动加载。

---

上一章：[17 · 寄存器与书签](17-registers-and-bookmarks.md) ｜ 下一章：[19 · Shell、编译与调试入口](19-shell-and-build.md) ｜ 返回：[使用 Emacs 教程](README.md)
