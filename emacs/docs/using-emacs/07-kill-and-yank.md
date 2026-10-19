# 07 · kill 与 yank：剪切与粘贴

Emacs 里的「剪切」叫 **kill**，「粘贴」叫 **yank**。被 kill 的文本不会消失——它被存进一个叫 **kill ring** 的地方，可以反复取用。这一章讲清 kill 与 delete 的区别、各种 kill 命令、yank 和 yank-pop 的用法、kill ring 的结构、追加 kill、矩形操作，以及与系统剪贴板的关系。

## 7.1 kill 与 delete 的区别

Emacs 里删除文本有两类命令：

- **kill 命令**：删除文本，同时把文本存入 kill ring。命令名通常含 `kill`。你几乎总能用 `C-y` 把 kill 掉的文本找回来。
- **delete 命令**：删除文本，**不**存入 kill ring。命令名通常含 `delete`。删了就没了（除非用 `C-/` undo）。

区分的原则很直觉：**可能误删的、量大的**操作走 kill，让你能恢复；**确定不要的、量小的**操作走 delete。例如 `C-d`（`delete-char`）只删一个字符，用 delete；`C-w`（`kill-region`）可能删一大段，用 kill。

在只读 buffer 里，kill 命令的行为变成：不删除文本，但仍然把文本复制到 kill ring。

在图形界面上，kill 操作还会把文本同步到系统剪贴板（详见 7.7 节）。

## 7.2 常用 kill 命令

### 按行 kill

| 键 | 命令 | 作用 |
|---|---|---|
| `C-k` | `kill-line` | 杀掉从 point 到行尾的内容 |
| `C-S-backspace` | `kill-whole-line` | 杀掉整行（不管 point 在哪） |

`C-k` 的行为取决于 point 的位置：

- 如果 point 不在行尾（在最后一个非空白字符之前）：杀掉从 point 到行尾的文本，但**不杀换行符**。行变成空白。
- 如果 point 在行尾（最后一个非空白字符之后）：杀掉换行符，把下一行合并上来。
- 如果 point 正好在行首且行非空：需要按两次 `C-k` 才能杀掉整行——第一次杀文本，第二次杀换行符。

带数字参数 N 时，`C-k` 杀 N 整行（包括换行符）；带负参数 -N 杀前面 N 行；带参数 0 杀当前行 point 之前的部分。

`C-S-backspace`（`kill-whole-line`）更直接：不管 point 在行的什么位置，整行连同换行符一起杀掉。注意很多终端不支持 `C-S-backspace` 这个键组合。

变量 `kill-whole-line` 设为非 `nil` 时，`C-k` 在行首也会杀掉整行（包括换行符），行为类似 `kill-whole-line`。默认 `nil`。

### 按词、句子、表达式 kill

| 键 | 命令 | 作用 |
|---|---|---|
| `M-d` | `kill-word` | 杀掉从 point 往后的一个词 |
| `M-DEL` | `backward-kill-word` | 杀掉 point 之前的一个词 |
| `M-k` | `kill-sentence` | 杀掉从 point 到句尾 |
| `C-x DEL` | `backward-kill-sentence` | 杀掉从 point 到句首 |
| `C-M-k` | `kill-sexp` | 杀掉从 point 往后的一个平衡表达式 |

这些命令的语义跟对应的移动命令完全一致——`M-d` 杀的范围就是 `M-f` 移动的范围，`M-DEL` 杀的范围就是 `M-b` 移动的范围，以此类推。

### 按 region kill

| 键 | 命令 | 作用 |
|---|---|---|
| `C-w` | `kill-region` | 杀掉 region |
| `M-w` | `kill-ring-save` | 复制 region 到 kill ring（不删除原文） |

`C-w` 是「剪切」——region 里的文本被删除并存入 kill ring。`M-w` 是「复制」——文本存入 kill ring 但不从 buffer 里删除。如果 mark 未激活，这两个命令操作 point 到最后一次设 mark 的位置之间的文本。

### zap-to-char

| 键 | 命令 | 作用 |
|---|---|---|
| `M-z CHAR` | `zap-to-char` | 杀掉从 point 到下一个 CHAR（含 CHAR） |

`M-z` 结合了 kill 和搜索：你给它一个字符，它从 point 杀到 buffer 里下一个出现该字符的位置（包括那个字符）。带数字参数 N 表示杀到第 N 个匹配；负参数表示往前搜索。

`M-x zap-up-to-char` 类似，但**不**包含目标字符——杀到目标字符之前为止。

## 7.3 yank：从 kill ring 取回文本

| 键 | 命令 | 作用 |
|---|---|---|
| `C-y` | `yank` | 粘贴 kill ring 里最近一次 kill 的文本 |
| `M-y` | `yank-pop` | 在 `C-y` 之后轮换更早的 kill |

`C-y` 把 kill ring 里最新的一条插入到 point 处。它同时在插入文本的**开头**设 mark（不激活），这样你可以用 `C-u C-SPC` 跳回去。

带前缀参数 `C-u C-y` 时，光标留在插入文本的**前面**，mark 设在末尾。

带数字参数 `C-u N C-y` 时，粘贴 kill ring 里倒数第 N 条——这让你可以直接取回不是最新的 kill。

### 连续 kill 的合并

连续执行的 kill 命令会**合并**成一条 kill ring 条目。例如你连按 `C-k` 杀了三行，这三行在 kill ring 里是一条，`C-y` 一次全部粘贴回来。

向前杀（如 `M-d`、`C-k`）把新文本追加到前一条的末尾；向后杀（如 `M-DEL`）把新文本加到前一条的开头。这样不管你怎么混合前后杀，kill ring 里的文本顺序跟原来 buffer 里一致。

「连续」的意思是中间没有其他命令——只有数字参数不算打断。一旦中间执行了非 kill 命令（比如移动光标），下一次 kill 就开始新的一条。

### 强制追加

| 键 | 命令 | 作用 |
|---|---|---|
| `C-M-w` | `append-next-kill` | 让下一次 kill 追加到前一条 |

如果你两次 kill 之间隔了其他命令（比如移动光标），但又想让它们合并成一条，在第二次 kill 之前按 `C-M-w`。它告诉 Emacs：「下一个 kill 命令，请追加到前一条。」

注意：`M-w`（`kill-ring-save`）之后的 kill **不会**自动追加。

## 7.4 yank-pop：在 kill ring 里轮换

kill ring 是一个列表，最新的在最前面，最旧的在最后面。默认最多 `kill-ring-max` 条（默认 120）。

`M-y`（`yank-pop`）有两种用法：

**用法一：在 `C-y` 或 `M-y` 之后**

刚按了 `C-y` 粘贴了最新的一条，发现不是你想要的那条？按 `M-y`，Emacs 会把刚粘贴的文本替换成 kill ring 里的上一条。再按 `M-y`，再替换成更前一条。反复按就能在 kill ring 里往后翻，直到找到你要的。翻到最末尾后再按 `M-y` 会绕回最前面。

`M-y` 可以带数字参数 N，表示一次往前跳 N 条。负参数向后（向新的方向）跳。

找到想要的之后停下来就行——buffer 里的文本已经是你选中的那条了。之后只要不做新的 kill，再按 `C-y` 还是会粘贴同一条。

**用法二：在其他命令之后**

如果前一个命令不是 `C-y` 或 `M-y`，`M-y` 会打开一个带补全的 minibuffer，让你从 kill ring 的所有条目里选择。你可以用 `M-p` / `M-n` 翻历史，用 `TAB` 补全，找到想要的按 `RET` 插入。插入前你还可以在 minibuffer 里编辑这条文本。

## 7.5 kill ring 的细节

**大小**：`kill-ring-max` 控制最大条数，默认 120。超出时最旧的被丢弃。

**查看所有条目**：`C-h v kill-ring RET` 可以看到 kill ring 的全部内容。

**去重**：`kill-do-not-save-duplicates` 设为非 `nil` 时，连续 kill 相同的文本只存一条。

**去缩进**：开启 `kill-ring-deindent-mode` 后，存入 kill ring 的文本会自动减少缩进——减少量等于第一行的缩进量。

**变换**：`kill-transform-function` 可以设一个函数，在文本存入 kill ring 之前变换它。比如你可以用它过滤掉纯空白的 kill。

## 7.6 矩形操作

**矩形（rectangle）** 是由两个列位置和两个行位置界定的矩形区域。它在处理多列对齐的文本时特别有用。

要指定一个矩形，跟指定 region 一样：设 mark 在一个角，point 在对角。同一个 point + mark 组合既可以解释为 region（文本流），也可以解释为 rectangle（矩形区域），取决于你用哪个命令。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r k` | `kill-rectangle` | 杀掉矩形区域（存入专用位置，不在 kill ring） |
| `C-x r M-w` | `copy-rectangle-as-kill` | 复制矩形区域（不删除） |
| `C-x r d` | `delete-rectangle` | 删除矩形区域（不存入任何地方） |
| `C-x r y` | `yank-rectangle` | 粘贴最后一次 kill 的矩形 |
| `C-x r c` | `clear-rectangle` | 把矩形区域的内容替换为空格 |
| `C-x r o` | `open-rectangle` | 在矩形位置插入空白矩形，把原文推到右边 |
| `C-x r t STRING RET` | `string-rectangle` | 把矩形每一行替换为 STRING |
| `C-x r N` | `rectangle-number-lines` | 在矩形左缘插入行号 |
| `C-x SPC` | `rectangle-mark-mode` | 切换矩形选择模式 |

### 矩形 kill 与 yank 的特殊性

矩形的 kill 和 yank 跟普通文本不同：

- 杀掉矩形时，文本**不进入 kill ring**，而是存在一个专用的「最后杀掉矩形」的位置。只有最近一次 kill 的矩形被保存。
- `C-x r y`（`yank-rectangle`）粘贴矩形时，矩形的第一行插入 point 处，第二行插入下一行的同一列位置，以此类推。
- 没有 yank-pop 的矩形版本——你只能用最近一次 kill 的矩形。

### 矩形标记模式

`C-x SPC`（`rectangle-mark-mode`）切换矩形选择模式。开启后，region 以矩形方式高亮，移动 point 时按矩形方式扩展。在这种模式下，`C-w`、`M-w` 等普通命令也自动操作矩形。模式只在 region 激活期间有效。

在矩形标记模式下，`C-x C-x` 变成 `rectangle-exchange-point-and-mark`，在矩形的四个角之间循环切换。

### 实际例子

假设你有两列数据，想把右列移到左列旁边：

```
apple     red
banana    yellow
cherry    purple
```

1. 把 mark 设在 `red` 的 `r` 处，point 移到 `purple` 的 `e` 处——选中右列。
2. `C-x r k` 杀掉这个矩形。
3. 把 point 移到 `apple` 后面的空格处。
4. `C-x r y` 粘贴矩形。

`C-x r t`（`string-rectangle`）也很实用：它把矩形每一行的内容替换为你指定的字符串。比如你想把所有行的第 10-20 列替换为 `XXX`，设好矩形后 `C-x r t XXX RET` 即可。

## 7.7 与系统剪贴板的关系

在图形界面上，Emacs 的 kill/yank 与系统剪贴板自动同步：

**kill → 剪贴板**：每次 kill（`C-w`、`C-k`、`M-d` 等）或 copy（`M-w`）时，文本同时被复制到系统剪贴板。旧剪贴板内容丢失。

**剪贴板 → yank**：`C-y` 时，如果其他应用最近往剪贴板放了内容（比你在 Emacs 里的最后一次 kill 更晚），`C-y` 会粘贴剪贴板的内容而不是 kill ring 的内容。

**`M-y` 不影响剪贴板**：默认情况下，`M-y` 轮换 kill ring 条目时不更新剪贴板。如果你希望 `M-y` 也更新剪贴板，把 `yank-pop-change-selection` 设为 `t`。

**禁用剪贴板集成**：把 `select-enable-clipboard` 设为 `nil`，kill 和 yank 就不再碰系统剪贴板。

**剪贴板管理器**：在某些 X 桌面环境下，退出 Emacs 时如果有剪贴板管理器在运行，Emacs 会把剪贴板数据转给它保存。如果这导致退出卡顿，把 `x-select-enable-clipboard-manager` 设为 `nil`。

**防止覆盖**：变量 `save-interprogram-paste-before-kill` 设为数字时，如果剪贴板内容小于该数字（字符数），在 kill 之前先把剪贴板内容存入 kill ring，防止丢失。设为其他非 `nil` 值则总是保存。

## 7.8 小结

- kill 删除并存入 kill ring；delete 删除但不存。大量删除走 kill，单字符删除走 delete。
- `C-k` 杀到行尾、`C-w` 杀 region、`M-w` 复制 region、`M-d` / `M-DEL` 杀词、`M-k` / `C-x DEL` 杀句子、`C-M-k` 杀表达式、`M-z` 杀到指定字符。
- `C-y` 粘贴最新 kill，`M-y` 在 `C-y` 之后轮换更早的 kill。
- 连续 kill 自动合并成一条；`C-M-w` 强制追加。
- kill ring 默认 120 条，所有 buffer 共享。
- 矩形操作用 `C-x r` 前缀键，矩形 kill 不进 kill ring 而进专用位置。`C-x SPC` 切换矩形标记模式。
- 图形界面上 kill/yank 自动与系统剪贴板同步。

---

上一章：[06 · mark 与 region](06-mark-and-region.md) ｜ 下一章：[08 · 搜索与替换](08-search-and-replace.md) ｜ 返回：[使用 Emacs 教程](README.md)
