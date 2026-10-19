# 08 · 搜索与替换

Emacs 的主力搜索方式是**增量搜索（incremental search）**：你每打一个字符，Emacs 就立刻跳到当前 buffer 里匹配的位置。不用等打完整个关键词——边打边找，看到结果再决定要不要继续。这一章从增量搜索讲起，覆盖正则搜索、替换、query replace 的交互键，以及替换里的大小写和特殊记法。

## 8.1 增量搜索基础

| 键 | 命令 | 作用 |
|---|---|---|
| `C-s` | `isearch-forward` | 向前增量搜索 |
| `C-r` | `isearch-backward` | 向后增量搜索 |

### 搜索的交互过程

按 `C-s` 后，Emacs 进入增量搜索状态。echo area 出现 `I-search:` 提示，等你输入搜索字符串。你每打一个字符，Emacs 就立刻在 buffer 里找到下一个匹配位置，把光标移过去，并用 `isearch` 这个 face 高亮当前匹配。

举个例子：按 `C-s`，然后打 `F`——光标跳到 buffer 里第一个 `F` 后面。再打 `O`——光标跳到第一个 `FO` 后面（不一定是刚才那个 `F`）。再打 `O`——光标跳到第一个 `FOO` 后面。每一步你都能看到实时结果。

搜索过程中：

- **当前匹配**被 `isearch` face 高亮。
- **搜索字符串**显示在 echo area 的 `I-search:` 提示后面。
- **其他匹配**（如果暂停一下）会用 `lazy-highlight` face 高亮，让你提前看到 `C-s` 还能跳到哪些位置。变量 `isearch-lazy-highlight` 设为 `nil` 可以关掉这个功能。

### 结束搜索

| 键（在 isearch 里） | 命令 | 作用 |
|---|---|---|
| `RET` | `isearch-exit` | 结束搜索，光标留在当前匹配处 |
| 大多数非搜索命令 | — | 自动结束搜索，然后执行该命令 |

大多数时候你不需要显式按 `RET`——直接按你要做的下一个操作的键就行。比如搜到了想编辑那一行，直接按 `C-a`，搜索自动结束然后执行 `move-beginning-of-line`。

只有当你的下一个按键是搜索内的特殊键（`RET`、`DEL`、`C-s`、`C-r`、`C-w`、`C-y`、`M-y`、`M-e`、`M-r`、`M-c`、`C-q` 等）时，才需要先按 `RET` 退出搜索。

### 取消搜索

| 键（在 isearch 里） | 命令 | 作用 |
|---|---|---|
| `ESC ESC ESC` | `isearch-cancel` | 取消搜索，光标回到搜索开始前的位置 |
| `C-g C-g` | `isearch-abort` | 同上（按两次 `C-g`） |

`C-g` 在搜索里的行为比较特殊（详见 8.1.4）。要完全取消搜索并回到起点，按 `ESC ESC ESC` 或 `C-g C-g`。

### 搜索结束后的 mark

搜索退出时，Emacs 把搜索开始前的 point 位置存入 mark ring（不激活 mark）。这意味着你可以用 `C-u C-SPC` 跳回搜索前的位置，或者用 `C-x C-x` 在搜索起点和终点之间切换。

## 8.2 重复搜索与方向切换

| 键（在 isearch 里） | 命令 | 作用 |
|---|---|---|
| `C-s` | `isearch-repeat-forward` | 跳到下一个匹配 |
| `C-r` | `isearch-repeat-backward` | 跳到上一个匹配 |

在搜索中找到匹配后，再按 `C-s` 跳到下一个匹配，再按再跳。反复按可以逐个跳过所有匹配。带数字参数 N 可以一次跳 N 个。

**方向切换**：在向前搜索中按 `C-r`，搜索方向反转——在同一个匹配上但改为向后搜索。反之亦然。默认行为是切换方向时先停留在当前匹配上（光标移到匹配的另一端），再按一次同方向键才跳到下一个。如果你希望切换方向时立即跳到下一个匹配，把 `isearch-repeat-on-direction-change` 设为 `t`。

**搜索同一个字符串**：退出搜索后，`C-s C-s`（第一个 `C-s` 启动搜索，第二个 `C-s` 在搜索启动时发现搜索字符串为空，就用上次的字符串）搜索上一次的字符串。`C-r C-r` 反向搜索上一次的字符串。

**环绕（wrap around）**：向前搜索到 buffer 末尾还没找到时，再按 `C-s` 会从 buffer 开头重新开始搜索。提示里出现 `Wrapped`。继续搜过原始起点后变成 `Overwrapped`，表示你在重访已经看过的匹配。

变量 `isearch-wrap-pause` 控制到达末尾时的行为：`t`（默认）表示先报错、再按才环绕；`no` 表示直接环绕并响铃；`no-ding` 表示直接环绕不响铃；`nil` 表示从不环绕，停在最后一个匹配。

## 8.3 搜索失败时的处理

如果搜索字符串在 buffer 里找不到，echo area 显示 `Failing I-Search`，光标停在能匹配到的最长前缀处。比如搜 `FOOT` 但 buffer 里只有 `FOOL`，光标停在 `FOO` 后面，`T` 被高亮为失败部分（用 `isearch-fail` face）。

这时你有几个选择：

- **`DEL`**（`isearch-delete-char`）：撤销上一次输入，退回到上一个成功的搜索状态。
- **`C-M-d`**（`isearch-del-char`）：从搜索字符串末尾删一个字符。
- **`M-e`**（`isearch-edit-string`）：进入 minibuffer 编辑搜索字符串。
- **`C-g`**：第一次按 `C-g` 删掉搜索字符串中找不到的部分（上面的例子里会删掉 `T`，留下 `FOO`），搜索恢复成功状态。再按一次 `C-g` 取消整个搜索，回到搜索前的位置。
- **`RET`**：如果你对当前找到的位置满意（虽然不完全匹配），直接 `RET` 留在这里。

## 8.4 在搜索里 yank 文本

增量搜索中有一组专门的键，把 buffer 里或 kill ring 里的文本拉进搜索字符串：

| 键（在 isearch 里） | 命令 | 作用 |
|---|---|---|
| `C-w` | `isearch-yank-word-or-char` | 把 point 后面的一个词（或一个字符）追加到搜索字符串 |
| `C-M-w` | `isearch-yank-symbol-or-char` | 把 point 后面的一个符号（或一个字符）追加到搜索字符串 |
| `M-s C-e` | `isearch-yank-line` | 把当前行剩余部分追加到搜索字符串 |
| `C-y` | `isearch-yank-kill` | 把 kill ring 最新一条追加到搜索字符串 |
| `M-y` | `isearch-yank-pop-only` | 在 `C-y` 之后，替换为更早的 kill |
| `C-M-y` | `isearch-yank-char` | 把 point 后面的一个字符追加到搜索字符串 |
| `C-M-z CHAR` | `isearch-yank-until-char` | 把 point 到下一个 CHAR 之间的文本追加到搜索字符串 |

`C-w` 特别实用：你在 buffer 里看到一段文本想搜它，但手动打太麻烦。按 `C-w` 把下一个词拉进搜索字符串，再按 `C-w` 再拉一个词……直到搜索字符串够长能唯一确定你要找的位置。

`M-s M-.`（`isearch-forward-thing-at-point`）是一个独立的命令：它启动搜索时自动把 point 附近的文本（URL、符号、表达式等）作为初始搜索字符串。由 `isearch-forward-thing-at-point` 变量控制具体取什么。

## 8.5 搜索历史与编辑搜索字符串

| 键（在 isearch 里） | 命令 | 作用 |
|---|---|---|
| `M-p` | `isearch-ring-retreat` | 翻到搜索历史里的上一条 |
| `M-n` | `isearch-ring-advance` | 翻到搜索历史里的下一条 |
| `M-e` | `isearch-edit-string` | 在 minibuffer 里编辑搜索字符串 |

搜索历史（search ring）保存了你最近用过的搜索字符串，最多 `search-ring-max` 条（默认 16）。`M-p` / `M-n` 翻阅历史，找到想要的按 `RET`、`C-s` 或 `C-r` 开始搜索。

`M-e` 打开 minibuffer 让你编辑当前搜索字符串——你可以做更精细的修改，比如在中间插入或删除字符。编辑完按 `RET` 继续搜索。在 minibuffer 里按 `C-f` 或 `<RIGHT>` 可以从 buffer 中逐字符追加到搜索字符串。

## 8.6 大小写敏感

| 键（在 isearch 里） | 命令 | 作用 |
|---|---|---|
| `M-c` | `isearch-toggle-case-fold` | 切换大小写敏感 |

默认情况下，搜索字符串如果全是小写，搜索**不区分大小写**——`foo` 能匹配 `foo`、`Foo`、`FOO`。如果搜索字符串里出现了大写字母，搜索变为**区分大小写**。这就是变量 `search-upper-case` 的默认行为（`y-or-n`）。

按 `M-c` 可以手动切换。提示里会显示 `Case fold` 或 `Case sensitive`。

变量 `case-fold-search` 设为 `nil` 则总是区分大小写，不受搜索字符串影响。

## 8.7 正则表达式搜索

| 键 | 命令 | 作用 |
|---|---|---|
| `C-M-s` | `isearch-forward-regexp` | 向前正则增量搜索 |
| `C-M-r` | `isearch-backward-regexp` | 向后正则增量搜索 |

`C-M-s` 启动正则增量搜索。跟普通增量搜索一样，边打边找，但搜索字符串被当作**正则表达式**解释。例如输入 `foo\|bar` 会匹配 `foo` 或 `bar`；输入 `\<defun\>` 匹配完整的词 `defun`。

也可以在普通增量搜索中按 `M-r`（`isearch-toggle-regexp`）切换到正则模式。

正则搜索有独立的搜索历史，用 `M-p` / `M-n` 翻阅，最多 `regexp-search-ring-max` 条（默认 16）。

正则搜索默认**不**使用宽松空格匹配。按 `M-s SPC`（`isearch-toggle-lax-whitespace`）开启后，搜索字符串里的空格匹配任意长度的空白序列。

正则搜索也**不**支持字符折叠（character folding）。

注意：正向和反向正则搜索**不对称**。Emacs 的正则匹配总是从正则的开头开始正向尝试。反向搜索是在每个可能的位置尝试正向匹配，然后取最后一个——它不是正向搜索的镜像。

## 8.8 替换

### 无条件替换

```
M-x replace-string RET STRING RET NEWSTRING RET
```

把 point 之后所有的 `STRING` 替换为 `NEWSTRING`。如果 region 激活，只在 region 内替换。

`replace-string` 退出后，point 留在最后一次替换处。替换前的 point 位置被存入 mark ring，用 `C-u C-SPC` 可以跳回去。

带数字参数时，只替换被词边界包围的匹配。

```
M-x replace-regexp REGEXP NEWSTRING RET
```

正则版本。`NEWSTRING` 里可以用特殊记法引用匹配的内容（详见 8.10）。

### Query Replace：逐个确认的替换

| 键 | 命令 | 作用 |
|---|---|---|
| `M-%` | `query-replace` | 逐个确认替换字符串 |
| `C-M-%` | `query-replace-regexp` | 逐个确认替换正则匹配 |

`M-%` 是日常最常用的替换方式。它找到一处匹配后停下来，显示匹配内容，问你要不要替换。你逐个回答，直到处理完所有匹配或中途退出。

用法：按 `M-%`，输入搜索字符串 `RET`，输入替换字符串 `RET`。Emacs 找到第一处匹配并高亮，等你按键决定。

### Query Replace 的交互键

在 query-replace 遇到匹配等你决定时，以下键可用（通过 `query-replace-map` 核实）：

| 键 | 绑定 | 作用 |
|---|---|---|
| `SPC` 或 `y` | `act` | 替换这一处，继续找下一处 |
| `DEL` 或 `n` | `skip` | 跳过这一处不替换，继续找下一处 |
| `,`（逗号） | `act-and-show` | 替换这一处，**显示替换结果**，然后等你再按一个键决定下一步 |
| `.`（句号） | `act-and-exit` | 替换这一处，然后退出 |
| `!` | `automatic` | 替换**所有剩余**匹配，不再逐个询问 |
| `RET` 或 `q` | `exit` | 不替换，直接退出 |
| `^` | `backup` | 回到上一处匹配 |
| `u` | `undo` | 撤销上一次替换，回到那处匹配 |
| `U` | `undo-all` | 撤销所有替换，回到第一处匹配的位置 |
| `C-r` | `edit` | 进入递归编辑，手动修改匹配处的文本。改完后 `C-M-c` 继续 |
| `C-w` | `delete-and-edit` | 删除匹配处，进入递归编辑让你手动输入替换内容。改完 `C-M-c` 继续 |
| `e` | `edit-replacement` | 在 minibuffer 里编辑替换字符串。编辑后的内容替换当前匹配，并成为后续匹配的新替换字符串 |
| `E` | `edit-replacement-exact-case` | 类似 `e`，但当前这一次替换不做大小写转换 |
| `d` | `diff` | 显示一个 diff buffer，展示所有替换的效果 |
| `C-l` | `recenter` | 重绘屏幕，然后等你再按一个键 |
| `?` | `help` | 显示帮助信息，总结所有选项 |

几个要点：

**`,`（逗号）的用法**：它替换并让你看结果。看完之后你按 `SPC` 继续下一处，按 `C-r` 进入递归编辑修改刚替换的文本，或者按 `DEL` 跳过（虽然已经替换了，效果等同于继续）。

**`C-r` 递归编辑**：匹配处需要更复杂的修改（不只是简单替换）时，按 `C-r` 进入递归编辑。你可以自由移动、编辑。完成后 `C-M-c`（`exit-recursive-edit`）退出，query-replace 继续到下一处。

**`C-w` 删除后编辑**：跟 `C-r` 类似，但先帮你把匹配处删了，你再手动输入替换内容。

**`^`（回退）**：如果你跳过了一个匹配但后来想回去看，按 `^` 回到上一处。

**其他任何键**：退出 query-replace，然后那个键被当作普通按键重新执行。比如按 `C-k` 退出 query-replace 然后 kill 到行尾。`C-g` 也退出。

### Query Replace 的历史

query-replace 在提示搜索字符串时，可以用 `M-p` / `M-n` 翻阅之前的替换记录。记录格式是 `FROM -> TO`。按 `RET` 选择一条重用。变量 `query-replace-from-to-separator` 控制分隔符；设为 `nil` 则不记录历史。

### 多 buffer 替换

在多 buffer 操作（比如 Dired 的 `Q` 命令对多个文件做 query-replace）时，还有两个额外键：

- `Y`：替换当前 buffer 和所有后续 buffer 里的剩余匹配，不再询问。
- `N`：跳过当前 buffer 的剩余匹配，继续到下一个 buffer。

## 8.9 替换里的大小写处理

替换命令对大小写有三种行为：

1. **搜索字符串全小写**：搜索时不区分大小写（受 `case-fold-search` 和 `search-upper-case` 控制）。替换时**保留原文的大小写模式**——如果原文是 `FOO`，替换结果也变大写；原文是 `Foo`，替换结果首字母大写；原文是 `foo`，替换结果全小写。变量 `case-replace` 必须为非 `nil`（默认就是）才启用这个行为。

2. **搜索字符串含大写**：搜索时区分大小写，替换时按你给的替换字符串原样插入。

3. **替换字符串含大写**：不管搜索字符串如何，替换字符串里的大写字母每次都原样保留。

能识别的大小写模式只有三种：全小写、全大写、首字母大写。混合大小写（如 `fOo`）不被特殊处理。

## 8.10 正则替换里的特殊记法

在 `replace-regexp` 和 `query-replace-regexp` 的替换字符串里，以下记法有特殊含义：

| 记法 | 含义 |
|---|---|
| `\&` | 整个匹配到的文本 |
| `\N`（N 为数字） | 第 N 个括号分组匹配到的文本（`\1`、`\2`……） |
| `\#` | 已完成的替换次数（从 0 开始计数） |
| `\\` | 一个字面反斜杠 |
| `\?` | 每次替换时在 minibuffer 里编辑这部分替换字符串 |
| `\,EXPR` | 用 Lisp 表达式计算替换文本 |

### 例子

把 `cadr` 和 `cddr` 改成 `cadr-safe` 和 `cddr-safe`：

```
M-x replace-regexp RET c[ad]+r RET \&-safe RET
```

`\&` 代表匹配到的整个文本（`cadr` 或 `cddr`）。

交换 `x` 和 `y`：

```
M-x replace-regexp RET \(x\)\|y RET \,(if \1 "y" "x") RET
```

`\1` 是第一个括号分组匹配到的内容。`\,(...)` 里的 Lisp 表达式在每次替换时求值。

给空行加上编号：

```
M-x replace-regexp RET ^.\{0,72\}$ RET \,(format "%-72sABC%05d" \& \#) RET
```

`\#` 是替换计数。`\&` 是匹配到的整行文本。

## 8.11 搜索的其它选项

**宽松空格匹配**：在 isearch 里按 `M-s SPC`（`isearch-toggle-lax-whitespace`）开启后，搜索字符串里的空格匹配任意长度的空白序列。变量 `search-whitespace-regexp` 控制匹配空白的正则。

**字符折叠**：默认情况下普通 isearch 使用字符折叠——搜索 `a` 也能匹配 `à`、`á` 等变体。`M-s '`（`isearch-toggle-char-fold`）切换。替换命令默认不用字符折叠，由 `replace-char-fold` 控制。

**搜索不可见文本**：变量 `search-invisible` 控制搜索和替换是否进入不可见（被 outline 或 overlay 隐藏）的文本。

**高亮子表达式**：正则搜索时，`search-highlight-submatches`（默认 `t`）高亮正则里各括号分组匹配到的部分。

## 8.12 小结

- `C-s` 向前增量搜索，`C-r` 向后。边打边跳，`RET` 结束，`ESC ESC ESC` 取消。
- 搜索中 `C-s` / `C-r` 重复搜索下一个/上一个，`M-p` / `M-n` 翻搜索历史，`M-e` 编辑搜索字符串。
- `C-w` 在搜索中 yank 下一个词，`C-y` yank kill ring 的内容。
- `M-c` 切换大小写敏感。搜索字符串全小写时默认不区分大小写。
- `C-M-s` / `C-M-r` 正则增量搜索。`M-r` 在普通搜索和正则搜索之间切换。
- `M-%` query-replace、`C-M-%` query-replace-regexp。`SPC`/`y` 替换，`DEL`/`n` 跳过，`!` 全部替换，`.` 替换后退出，`q` 退出，`C-r` 递归编辑，`,` 替换并显示结果。
- 正则替换里 `\&` 代表整个匹配，`\1` 代表第一个分组，`\#` 代表替换计数，`\,EXPR` 用 Lisp 表达式计算替换文本。

---

上一章：[07 · kill 与 yank：剪切与粘贴](07-kill-and-yank.md) ｜ 下一章：[09 · 文件操作](09-files.md) ｜ 返回：[使用 Emacs 教程](README.md)
