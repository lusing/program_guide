# 06 · mark 与 region

Emacs 的编辑哲学是「先选中，再操作」。你要对一段文本做什么——删除、复制、改大小写、缩进、替换——先把它变成一个 **region**（区域），然后对 region 执行命令。这一章讲清 region 的两个端点——**point**（光标）和 **mark**（标记）——怎么设定、怎么在它们之间跳转、怎么操作 region 里的文本。

## 6.1 point、mark、region 三者的关系

**point** 就是光标所在的位置——你每次移动光标，point 就跟着变。

**mark** 是你在 buffer 里手动设定的另一个位置。mark 和 point 之间的那段文本就是 **region**。region 总是从 mark 到 point，不管谁在前谁在后——每次你移动 point，region 都跟着变。

设定 mark 的操作叫「设置标记」。mark 设好之后，Emacs 会把它**激活**——这时 region 被高亮显示（用 `region` 这个 face），让你一眼看到选中的范围。这种「设 mark → 高亮 region → 移动 point 调整范围 → 执行命令」的工作流，就是 **Transient Mark mode**，Emacs 默认开启。

### 一个完整的例子

假设你想把一段文字改成大写：

1. 把光标移到这段文字的开头。
2. 按 `C-SPC`（`set-mark-command`）——Emacs 显示 `Mark set`，mark 被设在当前位置。
3. 移动光标到这段文字的末尾——region 随着你的移动被高亮。
4. 按 `C-x C-u`（`upcase-region`）——region 里的文本全部变成大写，mark 自动取消激活。

## 6.2 设置 mark

| 键 | 命令 | 作用 |
|---|---|---|
| `C-SPC` | `set-mark-command` | 在 point 处设置 mark 并激活 |
| `C-@` | `set-mark-command` | 同上（在文本终端上 `C-SPC` 实际产生 `C-@`） |
| `C-x C-x` | `exchange-point-and-mark` | 交换 point 和 mark 的位置 |

`C-SPC` 是最常用的设置 mark 的方式。注意：ASCII 里没有 `C-SPC` 这个字符，在文本终端上它通常被解释为 `C-@`。Emacs 把两个键都绑定到了 `set-mark-command`，所以你不需要纠结。

如果 mark 已经在 point 的位置，再按 `C-SPC` 不会设新的 mark，只是激活已有的 mark。

`C-x C-x`（`exchange-point-and-mark`）交换 point 和 mark。这在一种场景下特别有用：你已经用 `C-SPC` + 移动光标定义了一个 region，但发现 point 跑到了 region 的另一端——你希望 point 在另一端。按 `C-x C-x` 就交换过来了。再按一次又换回去。

### 鼠标和 shift 选择

你也可以用鼠标设置 mark：

- **拖拽 `mouse-1`**：按下左键拖过一段文本，松开时 mark 在起点、point 在终点。
- **`mouse-3`**（`mouse-save-then-kill`）：在当前位置设 mark，然后把 point 移到你点击的地方。
- **Shift + 方向键**：如果 mark 未激活，先在当前 point 设 mark，再移动 point。这就是「shift 选择」，跟很多图形应用里的 Shift+方向键选文本一样。

## 6.3 Transient Mark mode 与 region 高亮

Transient Mark mode 是一个全局 minor mode，默认在交互式会话中开启。它的核心行为：

- 设置 mark 时自动激活它，region 被高亮。
- 执行大多数非移动命令（尤其是修改文本的命令）后，mark 自动**取消激活**，高亮消失。
- 你可以随时按 `C-g` 手动取消 mark 的激活状态。

关闭 Transient Mark mode（`M-x transient-mark-mode`）后：设置 mark 不再高亮 region，你必须自己记住 mark 在哪。一些原本对 region 生效的命令（比如 `M-%`）会改为对整个 buffer 生效。一般不建议关闭。

即使 Transient Mark mode 关闭，你也可以临时激活它：

- `C-SPC C-SPC`：连按两次 `C-SPC`——第一次设 mark，第二次因为 mark 已在同一位置所以取消激活；但在 Transient Mark mode 关闭时，这个操作会**临时开启** Transient Mark mode，直到 mark 下次被取消激活。
- `C-u C-x C-x`：带前缀参数调用 `exchange-point-and-mark`，激活 mark 并临时开启 Transient Mark mode。

## 6.4 标记文本对象的命令

除了手动 `C-SPC` + 移动光标，Emacs 提供了一批命令，直接把 region 设定为某个文本单位（词、段落、函数、整个 buffer 等）。这些命令同时设置 point 和 mark，省去你手动定位的麻烦。

| 键 | 命令 | 标记的对象 | 是否移动 point |
|---|---|---|---|
| `M-@` | `mark-word` | 从 point 起往后 N 个词 | 不移动 point，mark 设在词尾 |
| `C-M-@` | `mark-sexp` | 从 point 起往后 N 个平衡表达式 | 不移动 point，mark 设在表达式尾 |
| `M-h` | `mark-paragraph` | 当前段落 | point 移到段首，mark 设在段尾 |
| `C-M-h` | `mark-defun` | 当前顶层定义（defun） | point 移到定义开头，mark 设在定义结尾 |
| `C-x C-p` | `mark-page` | 当前页 | point 移到页首，mark 设在页尾 |
| `C-x h` | `mark-whole-buffer` | 整个 buffer | point 移到 buffer 开头，mark 设在 buffer 结尾 |

这些命令都接受数字参数 N，表示标记 N 个对象。重复调用会扩展 region——比如连续按 `M-@` 会把 mark 一个词一个词地往后推。

`M-@`（`mark-word`）值得多说两句：它**不移动 point**，只把 mark 设在从 point 往后数 N 个词的末尾。如果 mark 已经激活且在 point 之前，`M-@` 改为把 mark 往前移动——这个行为让你可以双向扩展 region。

`C-M-h`（`mark-defun`）是写代码时最常用的：在函数体内按 `C-M-h`，整个函数就被选中了。对 Lisp 来说是顶层 s-expression，对 C/Python 等来说是顶层函数或类定义。

`C-x h`（`mark-whole-buffer`）一键选中整个 buffer。

## 6.5 对 region 生效的命令

有了 region 之后，大量命令会自动把操作范围限制在 region 内。以下是最常用的：

| 操作 | 键 | 命令 |
|---|---|---|
| 杀掉（剪切） | `C-w` | `kill-region` |
| 复制 | `M-w` | `kill-ring-save` |
| 转大写 | `C-x C-u` | `upcase-region` |
| 转小写 | `C-x C-l` | `downcase-region` |
| 缩进 | `C-x <TAB>` | `indent-rigidly` |
| 缩进到正确格式 | `C-M-\` | `indent-region` |
| 填充（重排换行） | `M-x fill-region` | — |
| 替换 | `M-%` | `query-replace`（region 激活时只在 region 内替换） |
| 拼写检查 | `M-$` | `ispell-word`（region 激活时检查 region 内的拼写） |
| 撤销 region 内的修改 | `C-u C-/` | `undo`（带参数） |
| 存入寄存器 | `C-x r s` | `copy-to-register` |

### 两类对 region 敏感的命令

**第一类**：有默认行为，但 region 激活时改为操作 region。

- `M-$`（`ispell-word`）：默认检查 point 处的词；region 激活时检查 region 里的拼写。
- `DEL`（`backward-delete-char`）和 `<delete>`（`delete-forward-char`）：默认删除一个字符；region 激活时删除整个 region。变量 `delete-active-region` 控制这个行为：设为 `nil` 禁用；设为 `kill` 则删除时把文本存入 kill ring 而不是直接丢弃。

**第二类**：始终操作 region，不管 mark 是否激活。命令名里通常带 `region`。

- `C-w`（`kill-region`）、`C-x C-u`（`upcase-region`）等。如果 mark 未激活，它们操作 point 和最后一次设置 mark 的位置之间的文本。变量 `mark-even-if-inactive` 设为 `nil` 时，这些命令在 mark 未激活时会报错而不是默默操作。

### Delete Selection mode

默认情况下，在 region 激活时输入字符只会取消 mark 然后正常插入字符——region 不会被替换。如果你习惯了「选中后打字直接替换」的行为（Windows/macOS 的大多数应用都这样），可以开启 **Delete Selection mode**：

```
M-x delete-selection-mode
```

开启后，region 激活时输入文本会先删除 region 再插入新文本。

## 6.6 mark ring：回到去过的地方

每次你设置 mark，**旧的 mark 位置不会丢失**——它被压入当前 buffer 的 **mark ring**。mark ring 是一个位置栈，最多保存 `mark-ring-max` 个位置（默认 16）。

mark ring 最重要的用法是**记住位置然后跳回去**：

### 记住一个位置

```
C-SPC C-SPC
```

连按两次 `C-SPC`：第一次设 mark 并把旧 mark 压入 ring，第二次因为 mark 已在同一位置所以取消激活。效果是：当前 point 被存进 mark ring，但 region 不高亮。你可以把它理解为「在这里插了一根钉子」。

### 跳回标记的位置

```
C-u C-SPC
```

`C-u C-SPC`（`set-mark-command` 带前缀参数）把 point 移到 mark 的位置，并从 mark ring 恢复上一次的 mark。每按一次 `C-u C-SPC`，就跳到 mark ring 里的上一个位置。这些位置不会丢失——它们被移到 ring 的末尾，循环使用。

如果变量 `set-mark-command-repeat-pop` 设为非 `nil`，你在按了 `C-u C-SPC` 之后可以直接按 `C-SPC`（不需要再带 `C-u`）继续跳。默认是 `nil`。

### 实际工作流

一个常见模式：

1. 在 buffer 的 A 处按 `C-SPC C-SPC`，记住 A。
2. 移动到 B 处做编辑。
3. 按 `C-u C-SPC` 跳回 A。

这比来回滚动方便得多。如果你需要更持久的位置记录（跨 buffer、跨会话），可以用寄存器（第 15 章）。

## 6.7 被禁用的命令

Emacs 有一些命令默认是**被禁用的**——你第一次调用它们时，Emacs 会问你确认，而不是直接执行。这是一种保护机制，防止新手误操作那些「不可逆」或「容易让人困惑」的命令。

被禁用的命令包括 `upcase-region`、`downcase-region`、`delete-region` 等。第一次调用时你会看到类似：

```
upcase-region is a disabled command.
Type 'y' if you want to enable it and then run it.
Type 'n' to cancel.
```

按 `y` 启用并执行；按 `n` 取消。启用之后就不会再问了。

如果你想永久启用某个被禁用的命令，在 init file 里写：

```lisp
(put 'upcase-region 'disabled nil)
```

或者用 `M-x customize` 界面来管理。

## 6.8 小结

- region 是 point 和 mark 之间的文本。`C-SPC` 设 mark，移动 point 定义 region。
- Transient Mark mode（默认开启）让 region 高亮，大多数修改命令执行后自动取消高亮。
- `M-@` 标记词、`M-h` 标记段落、`C-M-h` 标记函数、`C-x h` 标记整个 buffer。
- `C-w` 杀掉 region、`M-w` 复制 region、`C-x C-u` / `C-x C-l` 改大小写、`C-M-\` 缩进 region。
- `C-SPC C-SPC` 记住位置，`C-u C-SPC` 跳回——mark ring 是你的位置历史。
- 被禁用的命令第一次调用时需要确认，之后可以永久启用。

---

上一章：[05 · minibuffer 与补全](05-minibuffer.md) ｜ 下一章：[07 · kill 与 yank：剪切与粘贴](07-kill-and-yank.md) ｜ 返回：[使用 Emacs 教程](README.md)
