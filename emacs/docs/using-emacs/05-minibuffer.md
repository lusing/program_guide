# 05 · minibuffer 与补全

前面几章你见过 `C-x C-f` 打开文件、`M-x` 调用命令——它们都会在屏幕底部弹出一行提示，等你输入参数。这行提示背后的机制就是 **minibuffer**。这一章把它讲透：它是什么、怎么在里面编辑、怎么用补全少打字、怎么翻历史、密码怎么输、yes-or-no 怎么回答、递归编辑又是什么。

## 5.1 minibuffer 是什么

minibuffer 是一个**专用 buffer**，占据 echo area 那一行（不够高时会自动撑开）。当 Emacs 命令需要你提供比「一个按键」更复杂的参数时——文件名、buffer 名、命令名、Lisp 表达式——它就把 minibuffer 叫出来，显示一段**提示（prompt）**，等你输入。

提示通常以冒号结尾，用 `minibuffer-prompt` 这个 face 高亮。例如按 `C-x C-f`，你会看到：

```
Find file: ~/
```

这里 `Find file: ` 是提示，`~/` 是**默认目录**——它已经替你填好了起点，你接着敲文件名就行。

提示里有时还会在冒号前用括号显示一个**默认值**，例如：

```
Switch to buffer (default *scratch*):
```

这时直接按 `RET` 就会用括号里的默认值。变量 `minibuffer-default-prompt-format` 控制默认值的显示格式。如果你打开 `minibuffer-electric-default-mode`（`M-x minibuffer-electric-default-mode`），一旦你修改了 minibuffer 里的文字，默认值提示就会自动隐藏——因为你再按 `RET` 已经不是提交默认值了。

### 提交与取消

- 输入完成后按 `RET` 提交参数，minibuffer 消失，命令继续执行。
- 想放弃这次操作？按 `C-g`（`keyboard-quit` / `abort-minibuffers`），minibuffer 消失，命令被取消。

`RET` 在 minibuffer 里**不是换行**——它是提交。如果你真的想在参数里插入一个换行符，用 `C-q C-j`（插入一个字面 `C-j` 字符，等价于换行）。

## 5.2 在 minibuffer 里编辑

minibuffer 虽然小，但它是一个正经的 Emacs buffer，**常规编辑命令都能用**。在 minibuffer 里（通过 `minibuffer-mode`）：

| 键 | 命令 | 作用 |
|---|---|---|
| `C-a` | `move-beginning-of-line` | 跳到参数文本开头（不是提示开头） |
| `C-e` | `move-end-of-line` | 跳到行尾 |
| `C-f` / `C-b` | 前进/后退一个字符 | 光标移动 |
| `C-k` | `kill-line` | 删到行尾 |
| `C-y` | `yank` | 粘贴 kill ring 里的内容 |
| `DEL` | `delete-backward-char` | 删除前一个字符 |

注意 `C-a` 在 minibuffer 里的行为与普通 buffer 不同：它跳到**参数文本的开头**，跳过提示。提示是只读的，你改不了它。这个设计让你可以方便地用 `C-a C-k` 清空整个参数重新输入。

### 多行 minibuffer

如果你输入的内容超过一行，minibuffer 窗口会自动撑高。变量 `resize-mini-windows` 控制这个行为：默认值 `grow-only` 表示只自动长高不自动缩矮；设为 `t` 则双向自动调整；设为 `nil` 则完全手动。`max-mini-window-height` 控制最大高度，默认 0.25（即 frame 高度的 25%）。

### 在 minibuffer 里切换 window

minibuffer 激活时，你可以用 `C-x o` 切到其他 window 去查看或复制文本，然后再切回来继续输入。你甚至可以在别的 window 里 `C-w` 杀一段文本，回到 minibuffer 里 `C-y` 粘贴进来。但 minibuffer window 本身**不能拆分**。

### 滚动帮助文本

当补全命令在另一个 window 弹出 `*Completions*` buffer 时，你可以在 minibuffer 里用 `C-M-v` 滚动那个 window 的内容。

## 5.3 补全：让 Emacs 替你打字

补全是 minibuffer 最强大的功能之一。你只打几个字母，Emacs 就能把剩下的部分填出来——或者列出所有候选项让你挑。

### 5.3.1 三个核心补全键

当 minibuffer 用于补全时（比如 `M-x` 输入命令名、`C-x b` 输入 buffer 名），以下三个键被重新绑定：

| 键 | 命令 | 作用 |
|---|---|---|
| `TAB` | `minibuffer-complete` | 补全到最长公共前缀；如果无法进一步补全，弹出候选列表 |
| `SPC` | `minibuffer-complete-word` | 补全到下一个单词边界（连字符或空格） |
| `?` | `minibuffer-completion-help` | 弹出 `*Completions*` buffer 显示所有候选 |

`TAB` 是你最常用的补全键。举个例子：在 `M-x` 后输入 `auto-f`，按 `TAB`，Emacs 发现所有以 `auto-f` 开头的命令里最长公共前缀是 `auto-fill-`，于是补到 `auto-fill-`。再按 `TAB`，如果只有一个候选（`auto-fill-mode`），就直接补全；如果有多个，就弹出列表。

`SPC` 比 `TAB` 更保守——它每次只补一个词。比如输入 `auto-f` 按 `SPC`，补到 `auto-fill-`（到连字符为止）；再按 `SPC`，才补到 `auto-fill-mode`。注意：在文件名补全中 `SPC` **不**触发补全（因为文件名可以含空格），而是直接插入空格——这是 `minibuffer-local-filename-completion-map` 的特殊处理。

`?` 直接列出所有候选。它和 `TAB` 补全失败时弹出的列表是同一个东西。

### 5.3.2 `*Completions*` buffer：候选列表

按 `?` 或 `TAB` 无法唯一补全时，Emacs 在另一个 window 弹出 `*Completions*` buffer。你可以在这个 buffer 里用以下命令浏览和选择：

| 键（在 `*Completions*` 里） | 命令 | 作用 |
|---|---|---|
| `RET` | `choose-completion` | 选择光标下的候选，提交并退出 minibuffer |
| `mouse-1` / `mouse-2` | — | 点击选择候选 |
| `TAB` 或 `n` | `next-completion` | 移到下一个候选 |
| `S-TAB` 或 `p` | `previous-completion` | 移到上一个候选 |
| `<RIGHT>` / `<LEFT>` | 列方向导航 | 按列移动 |
| `<DOWN>` / `<UP>` | 行方向导航 | 按行移动 |
| `q` | `quit-window` | 关闭候选窗口，回到 minibuffer |
| `z` | `kill-current-buffer` | 杀掉 `*Completions*` buffer |

你也可以**不切到候选 window**，直接在 minibuffer 里用 `M-<down>`（`minibuffer-next-completion`）和 `M-<up>`（`minibuffer-previous-completion`）浏览候选。如果 `minibuffer-completion-auto-choose` 为非 `nil`，浏览的同时会把候选插入 minibuffer。找到想要的之后按 `M-RET`（`minibuffer-choose-completion`）或 `RET` 提交。

`M-v`（`switch-to-completions`）在 minibuffer 里按了会切到候选 window，让你用上面的导航键操作。

### 5.3.3 补全退出方式

`RET`（`minibuffer-completion-exit`）在补全 minibuffer 里不只是提交——它会先尝试补全，再根据命令的要求决定是否允许退出。Emacs 有四种补全退出策略：

1. **严格补全**：只接受精确匹配。`RET` 时如果 minibuffer 文本不是精确候选，就拒绝退出并尝试补全。`M-x` 用的就是这种——你不可能调用一个不存在的命令。
2. **谨慎补全**：类似严格，但如果 `RET` 时文本刚好补全到一个精确匹配，它执行补全但**不退出**，要你按第二次 `RET` 确认。
3. **宽松补全**：接受任何输入，候选只是建议。`RET` 直接提交你输入的文本。
4. **宽松 + 确认**：默认宽松，但如果你刚按了 `TAB` 且补全没到底（不是精确匹配），`RET` 会显示 `[Confirm]` 要求再按一次确认，防止你手滑。`C-x C-f` 和 `C-x b` 用的就是这种。变量 `confirm-nonexistent-file-or-buffer` 控制行为：默认 `after-completion`（只在 `TAB` 后确认）；`nil` 表示完全不确认；其他非 `nil` 值表示每次都确认。

## 5.4 补全风格（Completion Styles）

补全怎么判断「匹配」？Emacs 用一组**补全风格**按顺序尝试，第一个产生匹配的风格胜出。变量 `completion-styles` 控制这个列表。默认包含三种风格：

**`basic`**：候选必须以 minibuffer 中光标前的文本开头。如果光标后还有文本，那部分必须作为子串出现在候选的剩余部分里。这是最传统、最保守的风格。

**`partial-completion`**：把 minibuffer 文本按连字符或空格拆成多段，每段分别匹配。例如输入 `em-l-m` 能补全到 `emacs-lisp-mode`。`*` 当通配符用。如果 `completion-pcm-leading-wildcard` 设为 `t`，每段开头隐含一个通配符，于是 `l-ode` 也能匹配 `emacs-lisp-mode`。

**`emacs22`**：类似 `basic`，但忽略光标后的文本。

你还可以手动添加更多风格到 `completion-styles`：

- **`substring`**：候选只要包含光标前和光标后的文本（按顺序）就匹配。输入 `foobar`（光标在 `foo` 和 `bar` 之间）能匹配 `AfooBbarC`。
- **`flex`**：也叫模糊补全（fuzzy / scatter）。按顺序的子序列匹配——`foo` 能匹配 `frodo` 或 `fbarbazoo`。非常宽松，候选会很多。
- **`initials`**：匹配首字母缩写。`lch` 能匹配 `list-command-history`。最激进。

你可以用 `completion-category-overrides` 为不同种类的补全指定不同风格。例如默认设置里，buffer 名补全只用 `basic` 和 `substring`，不用 `partial-completion`。

## 5.5 补全的其它选项

**大小写敏感**：命令名补全总是区分大小写。文件名补全是否区分大小写由 `read-file-name-completion-ignore-case` 控制（在 GNU/Linux 上默认 `nil` 即区分，在 Windows 上默认非 `nil`）。buffer 名类似，由 `read-buffer-completion-ignore-case` 控制。

**忽略扩展名**：文件名补全时，`completion-ignored-extensions` 列出的后缀（如 `.o`、`.elc`、`~`）默认被隐藏。但如果所有候选都以被忽略的后缀结尾，就不忽略了。

**自动弹出帮助**：`completion-auto-help` 控制候选列表的弹出时机。`nil` 表示从不自动弹出（你要手动按 `?`）；`lazy` 表示第一次 `TAB` 失败时不弹，第二次才弹；`always` 表示每次尝试补全都弹。

**循环补全**：如果 `completion-cycle-threshold` 非 `nil`，`TAB` 不再补到公共前缀，而是在候选之间循环切换。设为 `t` 总是循环；设为数字 N 表示候选数 ≤ N 时才循环。

**候选排序**：`completions-sort` 控制 `*Completions*` 里的排序。默认 `alphabetical`（字母序）；`historical` 按历史使用频率排；`nil` 不排序。

**候选排列**：`completions-format` 控制候选的排列方式。默认 `horizontal`（从左到右横排）；`vertical` 按列竖排；`one-column` 单列。

## 5.6 minibuffer 历史

你在 minibuffer 里输入过的每一个值，Emacs 都记在**历史列表**里。下次再遇到同类参数时，可以用以下键翻出来：

| 键 | 命令 | 作用 |
|---|---|---|
| `M-p` | `previous-history-element` | 翻到上一条历史 |
| `M-n` | `next-history-element` | 翻到下一条历史 |
| `<UP>` | `previous-line-or-history-element` | 类似 `M-p`，但多行历史项里先移上一行 |
| `<DOWN>` | `next-line-or-history-element` | 类似 `M-n`，但多行历史项里先移下一行 |
| `M-r RET` | `previous-matching-history-element` | 搜索匹配正则的**更早**历史项 |
| `M-s RET` | `next-matching-history-element` | 搜索匹配正则的**更晚**历史项 |

`M-p` 每次把上一条历史替换进 minibuffer，替换的是整个内容。反复按 `M-p` 就不断往更早的历史翻。`M-n` 反向。

`M-n` 还有一个特殊行为：如果你还没翻过历史（即当前就是最新输入），按 `M-n` 会翻到**默认值列表**（也叫"未来历史"）。对于文件名补全，默认值包括光标附近的文件名或 URL（由 `file-name-at-point-functions` 控制，默认调用 `ffap` 包来猜测）。

`M-r` 和 `M-s` 用正则表达式搜索历史。它们会再用 minibuffer 问你正则（是的，这是递归使用 minibuffer），找到匹配的历史项后替换进 minibuffer。正则里有大写字母则区分大小写。

Emacs 为不同种类的参数维护**独立的历史列表**：文件名一个、buffer 名一个、命令名（`M-x`）一个、命令参数一个。变量 `history-length` 控制每条历史的最大长度，默认无限（`t`）。`history-delete-duplicates` 设为非 `nil` 时，新加入的项会自动删除历史中的重复项。

### 用历史补全

除了翻历史，你还可以用历史来**补全**：

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x <UP>` | `minibuffer-complete-history` | 用历史项作为候选来补全 |
| `C-x <DOWN>` | `minibuffer-complete-defaults` | 用默认值作为候选来补全 |

## 5.7 重复执行 minibuffer 命令

每个使用过 minibuffer 的命令都会被记录到**命令历史**里，连同它的参数。你可以用 `C-x <ESC> <ESC>`（`repeat-comcomplex-command`）重新执行它们。

不带参数时，`C-x <ESC> <ESC>` 重复上一次使用 minibuffer 的命令。它会把这个命令转换成一条 Lisp 表达式放在 minibuffer 里——即使你不会 Lisp，也能看出大概是什么命令和参数。直接按 `RET` 就原样重放；你也可以编辑这条表达式再执行。

带数字参数 N 表示重复倒数第 N 个命令。

进入 `C-x <ESC> <ESC>` 的 minibuffer 后，你可以用 `M-p` / `M-n` 翻阅命令历史。

`M-x list-command-history` 显示完整的命令历史列表。

## 5.8 文件名的 minibuffer

`C-x C-f`（`find-file`）等命令用 minibuffer 读文件名时，minibuffer 里已经预填了**默认目录**，例如：

```
Find file: /home/user/projects/
```

你接着敲相对路径就行。如果想指定父目录的文件，用 `..`：`/a/b/../foo.el` 等价于 `/a/foo.el`。你也可以用 `M-DEL`（`backward-kill-word`）逐段删掉目录名。

如果想完全忽略默认目录、指定一个绝对路径，有两种办法：

1. 用 `C-a C-k` 清空默认目录，重新输入。
2. 直接在默认目录后面输入**双斜杠**加绝对路径：`Find file: /home/user/projects//etc/termcap`。双斜杠 `//` 让 Emacs 忽略它之前的所有内容，最终打开 `/etc/termcap`。被忽略的部分会变暗（由 File Name Shadow mode 控制，`M-x file-name-shadow-mode` 切换）。

`~/` 会被展开为你的 home 目录；`~USER/` 展开为用户 `USER` 的 home 目录。

变量 `insert-default-directory` 设为 `nil` 时，minibuffer 启动时是空的——但相对路径仍然按默认目录解释。

## 5.9 密码输入

当 Emacs 需要你输入密码时（比如访问远程文件），它在 echo area 显示类似 `Password:` 的提示。你输入的每个字符都显示为 `*`，防止旁人偷看。

密码输入模式**不是**完整的 minibuffer——没有历史、没有补全、不能切换 window。可用的操作很有限：

| 键 | 作用 |
|---|---|
| `DEL` | 删除最后一个字符 |
| `C-u` | 删除所有已输入的内容 |
| `C-g` | 取消 |
| `C-y` | 粘贴 kill ring 的内容 |
| `TAB` | 切换密码可见性 |
| `RET` 或 `ESC` | 提交密码 |

mode line 上也有一个图标可以点击切换密码可见性。

## 5.10 yes-or-no 提示

Emacs 有两种 yes-or-no 提问方式：

**简短型**——提示以 `(y or n)` 结尾。你只按一个键：`y` 或 `n`，立即生效。用于后果不严重的确认，比如覆盖已有文件：

```
File 'foo.el' exists; overwrite? (y or n)
```

**完整型**——提示以 `(yes or no)` 结尾。你必须在 minibuffer 里输入完整的 `yes` 或 `no` 再按 `RET`。用于后果严重的操作，比如丢弃未保存的修改：

```
Buffer foo.el modified; kill anyway? (yes or no)
```

完整型的提示文本可以通过 `yes-or-no-prompt` 变量自定义。

两种提示里你都可以用 `C-l` 重绘屏幕、`C-v` / `M-v` 滚动、`C-x o` 切换 window、`M-p` / `M-n` 翻历史。`C-g` 取消整个操作。

## 5.11 递归编辑

**递归编辑**是指你在一个 Emacs 命令的执行过程中，进入一个「嵌套的编辑状态」。典型的场景：在 `query-replace`（`M-%`）里按 `C-r`，Emacs 暂停替换，让你自由编辑当前 buffer——这就是递归编辑。编辑完了用 `C-M-c`（`exit-recursive-edit`）退出，回到暂停处的 `query-replace` 继续。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-M-c` | `exit-recursive-edit` | 退出当前递归编辑层，恢复被暂停的命令 |
| `C-]` | `abort-recursive-edit` | 中止当前递归编辑层，同时取消被暂停的命令 |

mode line 会告诉你当前是否在递归编辑：正常时 mode line 里的模式名被圆括号包围如 `(Text ...)`,递归编辑时每嵌套一层就多一对方括号 `((Text ...))`。

递归编辑可以嵌套——在递归编辑里再触发一次递归编辑，mode line 就显示两层方括号。`C-M-c` 只退出最内层。

`M-x top-level` 更暴力：一次性退出**所有**递归编辑层，回到最顶层。

## 5.12 小结

- minibuffer 是 Emacs 读复杂参数的专用 buffer，`RET` 提交、`C-g` 取消。
- 在 minibuffer 里可以用常规的移动、删除、粘贴命令编辑参数文本。
- `TAB` 补全到最长公共前缀，`SPC` 补全一个词，`?` 列出候选。`*Completions*` buffer 里可以浏览和选择候选。
- 补全风格由 `completion-styles` 控制，默认有 `basic`、`partial-completion`、`emacs22`；可以加 `substring`、`flex`、`initials` 等。
- `M-p` / `M-n` 翻历史，`M-r` / `M-s` 按正则搜索历史。
- 密码输入是简化版 minibuffer，每个字符显示为 `*`。
- yes-or-no 有两种：按单键 `(y or n)` 和输入完整词 `(yes or no)`。
- 递归编辑中用 `C-M-c` 退出、`C-]` 中止。

---

上一章：[04 · 自助文档：Help 家族](04-help.md) ｜ 下一章：[06 · mark 与 region](06-mark-and-region.md) ｜ 返回：[使用 Emacs 教程](README.md)
