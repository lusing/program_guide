# 20 · 定制 Emacs

Emacs 的默认行为已经很强，但几乎每个人都会想改一些东西：也许你觉得 `C-x C-b` 应该打开 `ibuffer` 而不是老旧的 `list-buffers`；也许你想让搜索默认区分大小写；也许你想让某个 minor mode 在所有 buffer 里自动开启。这一章讲清楚定制 Emacs 的三条路径，从最易上手到最灵活：

1. **`M-x customize`**：图形化的定制界面，不需要写 Lisp。
2. **init 文件里用 `setq` / `setopt`**：直接改变量值，适合喜欢纯文本配置的人。
3. **init 文件里改键绑定**：重新绑定快捷键。

最后简要介绍 **hook**——一种在特定时机自动执行代码的机制。

## 20.1 变量与 Face：Emacs 的「设置」

Emacs 的定制本质上就是改两类东西：

- **变量**（variable），也叫 user option 或 customizable variable：控制 Emacs 各种行为的 Lisp 变量。比如 `fill-column`（自动换行的列宽）、`case-fold-search`（搜索是否区分大小写）、`kill-ring-max`（kill ring 的长度上限）。
- **Face**：控制文本外观（字体、颜色、粗细、斜体等）的对象。比如 `default`（默认文本的 face）、`font-lock-comment-face`（注释的颜色）。

查看任何变量的文档和当前值：`C-h v`（`describe-variable`），输入变量名即可。文档会告诉你这个变量是干什么的、应该设成什么类型的值。

## 20.2 路径一：`M-x customize` 图形化界面

`M-x customize` 打开一个特殊的 customization buffer，里面按逻辑分组列出了 Emacs 的所有设置。

### 定制组（Customization Groups）

所有设置被组织成**定制组**。小组合成大组，最顶层的组叫 `Emacs`。`M-x customize` 打开的就是顶层组，你会看到类似这样的结构：

```
[Editing]      基本文本编辑功能
[Convenience]  便捷功能
[Files]        文件处理
...
```

点击（或光标移到上面按 `RET`）一个组名就能展开它，看到里面的子组和具体设置。

### 修改一个变量

展开到一个变量后，你会看到类似：

```
[Hide] Kill Ring Max: Integer (positive or zero): 60
   [State]: STANDARD.
   Maximum length of kill ring before oldest elements are thrown away.
```

- 第一行：变量名（`kill-ring-max`，显示为更易读的 `Kill Ring Max`）、类型、当前值。
- `[State]`：变量的状态。`STANDARD` 表示你没改过，用的是默认值。
- 下面是变量的文档。

**修改步骤**：

1. 把光标移到值上面，直接编辑（比如把 `60` 改成 `120`）。状态会变成 `EDITED`。
2. 按 `[State]` 按钮，选 **Set for Current Session**——变量立即生效。
3. 想让这个值在下次启动 Emacs 时仍然有效，按 `[State]` 选 **Save for Future Sessions**。

对于布尔值（开/关），会有 `[Toggle]` 按钮直接切换。对于枚举值，会有 `[Value Menu]` 按钮让你从列表里选。

### 搜索设置

customize buffer 顶部有一个搜索框。输入关键词（如 `font`、`line number`），Emacs 会搜索所有名字或文档匹配的设置。

### 直接跳到特定设置

不想一层层翻组？这几个命令可以直接跳到目标：

| 命令 | 作用 |
|---|---|
| `M-x customize-variable RET VAR RET` | 直接打开变量 `VAR` 的定制界面 |
| `M-x customize-face RET FACE RET` | 直接打开 face `FACE` 的定制界面 |
| `M-x customize-group RET GROUP RET` | 直接打开定制组 `GROUP` |

比如你想改行号显示，`M-x customize-group RET display RET` 然后找 `display-line-numbers` 相关设置。

### Apply 与 Save 的区别

customize buffer 顶部有几个全局按钮：

- **[Apply]**：把当前 buffer 里所有 EDITED 的设置应用到当前会话（等同于逐个 Set for Current Session）。
- **[Apply and Save]**：应用**并**保存到 init 文件（下次启动仍然有效）。注意：如果 Emacs 是用 `-q` 或 `-Q` 启动的，这个按钮不会出现——因为从「干净」会话保存会覆盖你 init 文件里的其他设置。
- **[Revert...]**：撤销修改。有几个子选项：撤销编辑（Undo Edits）、恢复到上次保存的值（Revert This Session's Customizations）、恢复到默认值（Erase Customization）。

快捷键：`C-c C-c`（`Custom-set`）等同于 Apply；`C-x C-s`（`Custom-save`）等同于 Apply and Save。

### 保存到哪里

默认情况下，保存操作会把设置写入你的 init 文件（见 20.3 节）。如果你想把 Customize 保存的内容跟 init 文件里的其他代码分开，可以设一个单独的 custom 文件：

```elisp
;; 把 Customize 保存的内容放到单独的文件
(setq custom-file "~/.config/emacs-custom.el")
(load custom-file)
```

第一行告诉 Emacs「Customize 的保存目标改到这个文件」。第二行在启动时加载它。这样你的 init 文件里不会出现 Customize 自动生成的 `custom-set-variables` 和 `custom-set-faces` 代码块。这段代码已经用 `emacs -Q --batch` 验证过。

## 20.3 路径二：init 文件

init 文件是 Emacs 启动时自动加载的 Lisp 文件，你可以在里面写任何 Lisp 表达式来做定制。

### init 文件在哪里

Emacs 按以下顺序查找 init 文件（找到第一个就加载）：

1. `~/.config/emacs/init.el`（XDG 风格，推荐）
2. `~/.emacs.d/init.el`（传统推荐位置）
3. `~/.emacs`（最老的约定）

本教程推荐用 `~/.emacs.d/init.el`——把所有配置集中在 `~/.emacs.d/` 目录下，便于管理。

用 `-q` 启动可以不加载 init 文件。

### init 文件的语法

init 文件里是一个或多个 Lisp 表达式。最基本的形式是函数调用：

```elisp
(函数名 参数1 参数2 ...)
```

常量写法：

- **数字**：`42`、`-7`
- **字符串**：`"hello"`，用 `\n` 表示换行、`\\` 表示反斜杠、`\"` 表示双引号
- **字符**：`?x`（字符 x）、`?\n`（换行符）
- **真**：`t`
- **假**：`nil`
- **符号引用**：`'fill-column`（单引号阻止求值，得到符号本身而不是它的值）

### 设置变量

**`setq`**：设置变量的值。

```elisp
;; 把 fill-column 设为 70（自动换行在第 70 列）
(setq fill-column 70)

;; 把 user-mail-address 设为你的邮箱
(setq user-mail-address "chen@example.com")
```

第一行：`setq` 把变量 `fill-column` 设为 `70`。注意 `70` 不需要引号——它是数字。第二行：字符串需要双引号。

**`setq` vs `setq-default`**：很多变量有 buffer-local 的值（每个 buffer 可以不同）。在 init 文件里，你通常想改的是**默认值**（影响所有 buffer），而不是当前 buffer 的局部值。用 `setq-default`：

```elisp
;; 让搜索默认区分大小写（影响所有未单独设置的 buffer）
(setq-default case-fold-search nil)
```

如果用 `setq`，只影响 init 文件加载时的当前 buffer（`*scratch*`），其他 buffer 不受影响——几乎肯定不是你想要的。

**`setopt`**（Emacs 31.1 推荐）：对于某些有特殊初始化逻辑的变量，`setq` 可能不够——它们需要通过 Customize 框架来设置。`setopt` 是 init 文件里的简写形式，效果等同于 `customize-set-variable`：

```elisp
;; 用 setopt 设置变量（走 Customize 框架）
(setopt fill-column 70)
```

`setopt` 跟 `setq` 的区别在于它会触发变量的 `:set` 函数（如果有的话），确保变量的副作用正确执行。对于大多数简单变量两者效果一样，但用 `setopt` 更安全。这条命令已经用 `emacs -Q --batch` 验证过。

### 开启/关闭 minor mode

有些 minor mode 的变量不能简单用 `setq` 设——设变量不会触发 mode 的开启逻辑。正确做法是直接调用 mode 函数：

```elisp
;; 关闭 Line Number mode（全局 minor mode）
(line-number-mode 0)

;; 开启 show-paren-mode（显示匹配的括号）
(show-paren-mode 1)
```

参数 `1`（或任何非 `nil` 值）开启，`0`（或 `nil`）关闭。

### 用 hook 在特定时机执行代码

**Hook** 是一个 Lisp 变量，里面存着一列函数，在某个特定时机被依次调用。最常见的用途是「当某个 major mode 启动时，自动做一些设置」。

比如让所有 Text mode buffer 自动开启 Auto Fill mode：

```elisp
(add-hook 'text-mode-hook 'auto-fill-mode)
```

`text-mode-hook` 是 Text mode 的 mode hook。每当 Text mode（或从它派生的 mode，如 HTML mode）启动时，Emacs 会调用这个 hook 里的所有函数。`add-hook` 把 `auto-fill-mode` 加进去。`auto-fill-mode` 不带参数调用时默认开启。

再比如让所有编程模式 buffer 自动开启 Flyspell Prog mode：

```elisp
(add-hook 'prog-mode-hook 'flyspell-prog-mode)
```

`prog-mode` 是一个「父 mode」，很多编程语言的 major mode 都从它派生。所以加到 `prog-mode-hook` 里的函数会在所有编程 mode 里执行。

Hook 变量的命名约定：以 `-hook` 结尾的是 normal hook（函数不带参数被调用）。以 `-functions` 结尾的是 abnormal hook（函数可能带参数或有特殊返回值约定）。

## 20.4 路径三：改键绑定

Emacs 的每个键都通过 **keymap**（键映射表）关联到一个命令。改键就是修改 keymap 里的关联。

### `C-x C-b` 的例子

默认情况下 `C-x C-b` 绑的是 `list-buffers`——一个相当简陋的 buffer 列表。很多人更喜欢 `ibuffer`，它功能更强（可以排序、过滤、标记操作）。改法：

```elisp
;; 把 C-x C-b 从 list-buffers 改成 ibuffer
(require 'ibuffer)
(keymap-global-set "C-x C-b" #'ibuffer)
```

第一行加载 `ibuffer` 库（确保 `ibuffer` 命令可用）。第二行把 `C-x C-b` 重新绑定到 `ibuffer`。

`keymap-global-set` 是 Emacs 31.1 推荐的新写法。它接受两个参数：一个键字符串和一个命令。`#'` 是 `function` 的缩写，引用一个函数/命令符号。

老的写法（仍然可用）：

```elisp
(global-set-key (kbd "C-x C-b") #'ibuffer)
```

`kbd` 把人类可读的键描述（如 `"C-x C-b"`）转换成 Emacs 内部使用的键向量。两种写法效果一样，但 `keymap-global-set` 更简洁。

### `keymap-global-set` 的更多用法

```elisp
;; 把 C-x l 绑到 make-symbolic-link
(keymap-global-set "C-x l" #'make-symbolic-link)

;; 取消一个键的绑定（让它变成未定义）
(keymap-global-unset "C-x C-v")
```

`keymap-global-unset` 让一个键变成未定义。一个常见用途是释放一个键以便把它变成前缀键——比如你想让 `C-x C-v` 成为一组新命令的前缀，必须先取消它原来的绑定。

### 在特定 mode 里改键

全局改键影响所有 mode。如果你只想在某个 mode 里改，用 `keymap-set` 加上对应 mode 的 keymap：

```elisp
;; 只在 Lisp mode 里把 C-x l 绑到 make-symbolic-link
(keymap-set lisp-mode-map "C-x l" #'make-symbolic-link)
```

### 批量替换

```elisp
;; 把全局 map 里所有绑到 next-line 的键改绑到 forward-line
(keymap-substitute global-map #'next-line #'forward-line)
```

这个例子把所有执行 `next-line` 的键改成执行 `forward-line`。

### 键字符串的写法

`keymap-global-set` 的第一个参数是键字符串，用空格分隔各个键：

- `"C-x C-f"` — Control+x 然后 Control+f
- `"M-x"` — Meta+x（Alt+x 或 ESC x）
- `"C-c C-c"` — 常见于 mode-local 键绑定
- `"C-x r SPC"` — `C-x` 然后 `r` 然后空格
- `"RET"` — 回车
- `"SPC"` — 空格
- `"DEL"` — 退格
- `"<f5>"` — 功能键 F5
- `"C-<right>"` — Control + 右箭头

### 改键的完整 init 文件示例

以下是一段完整的、已验证能跑通的 init 片段：

```elisp
;; 1. 用 ibuffer 替代 list-buffers
(require 'ibuffer)
(keymap-global-set "C-x C-b" #'ibuffer)

;; 2. 把 fill-column 默认设为 80
(setq-default fill-column 80)

;; 3. 搜索默认不区分大小写（这是默认值，这里显式写出以示强调）
(setq-default case-fold-search t)

;; 4. kill ring 保存 200 条记录（默认 60）
(setq kill-ring-max 200)

;; 5. 在 Text mode 里自动开启 Auto Fill
(add-hook 'text-mode-hook #'auto-fill-mode)

;; 6. 在编程 mode 里自动开启显示行号
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; 7. 把 Customize 保存的内容放到单独文件
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)
```

逐行解释：

1. `(require 'ibuffer)` 加载 ibuffer 库。`(keymap-global-set "C-x C-b" #'ibuffer)` 把 `C-x C-b` 改绑到 `ibuffer`。
2. `(setq-default fill-column 80)` 把自动换行的列宽默认值设为 80。用 `setq-default` 而不是 `setq`，确保所有 buffer 都受影响。
3. `(setq-default case-fold-search t)` 搜索默认不区分大小写。`t` 表示真。
4. `(setq kill-ring-max 200)` 把 kill ring 的最大长度从默认的 60 提高到 200。这个变量不需要 `setq-default`，因为 kill ring 是全局的。
5. `(add-hook 'text-mode-hook #'auto-fill-mode)` 每次进入 Text mode 时自动开启 Auto Fill。
6. `(add-hook 'prog-mode-hook #'display-line-numbers-mode)` 每次进入编程 mode 时自动显示行号。
7. `(setq custom-file ...)` 把 Customize 的保存目标设到 `~/.emacs.d/custom.el`。`(load custom-file t)` 在启动时加载它——第二个参数 `t` 表示文件不存在时不报错。

这段代码每一行都已用 `emacs -Q --batch --eval` 验证过不会报错。

### Modifier Keys

如果你用的键盘布局或终端对某些修饰键有特殊处理，可以在 init 文件里调整。比如在某些终端上 `C-z` 被系统拦截，或者你想让 Caps Lock 充当 Control 键——后者通常需要在操作系统层面修改，不在 Emacs init 文件的管辖范围内。Emacs 层面能做的包括：

```elisp
;; 在 macOS 上，让 Command 键充当 Meta
(when (memq window-system '(mac ns))
  (setq ns-command-modifier 'meta))

;; 让左 Alt 不做任何修饰（避免误触）
(when (memq window-system '(mac ns))
  (setq ns-left-alternate-modifier nil))
```

这些设置只在 macOS 图形界面下生效（`window-system` 为 `mac` 或 `ns` 时）。

## 20.5 Hooks 深入

Hook 的机制很简单：一个变量里存着一列函数，到了特定时机依次调用。但几个细节值得注意。

**执行顺序**：hook 里的函数按它们在列表中的顺序执行。`add-hook` 默认把新函数加到末尾。

**派生 mode 继承 hook**：如果 HTML mode 从 Text mode 派生，进入 HTML mode 时会先执行 `text-mode-hook` 再执行 `html-mode-hook`。这意味着加到 `text-mode-hook` 里的函数对所有文本类 mode 都生效。同理，`prog-mode-hook` 里的函数对所有编程 mode 生效。

**匿名函数**：有时候你想做的事情太简单不值得定义一个命名函数，用 `lambda`：

```elisp
;; 在 LaTeX mode 里关闭 Auto Fill（覆盖 text-mode-hook 里的设置）
(add-hook 'latex-mode-hook (lambda () (auto-fill-mode -1)))
```

`lambda` 创建一个匿名函数。`(auto-fill-mode -1)` 里的 `-1` 表示关闭。因为 LaTeX mode 从 Text mode 派生，它会先执行 `text-mode-hook`（开启 Auto Fill）再执行 `latex-mode-hook`（关闭 Auto Fill），最终效果是 LaTeX mode 里没有 Auto Fill。

**移除 hook 函数**：

```elisp
(remove-hook 'text-mode-hook #'auto-fill-mode)
```

**设计原则**：hook 函数最好互相独立、不依赖执行顺序。如果你发现两个 hook 函数有顺序依赖，考虑合并成一个。

## 20.6 三条路径怎么选

| 路径 | 适合场景 | 优点 | 缺点 |
|---|---|---|---|
| `M-x customize` | 不确定变量名、想浏览有哪些设置 | 图形化、有文档、有类型检查 | 生成的代码可读性差、不便于版本控制 |
| init 文件 `setq`/`setopt` | 明确知道要改什么变量 | 纯文本、便于版本控制、精确 | 需要知道变量名和合法值 |
| init 文件改键 | 重新绑定快捷键 | 灵活、可以按 mode 定制 | 需要理解 keymap |

实际使用中，多数人**混合使用**：用 `M-x customize` 探索和临时试验，确定要长期保留的设置后搬到 init 文件里。`M-x customize` 保存的设置也是写在 init 文件里的（或你指定的 `custom-file` 里），所以最终所有路径都汇聚到 init 文件。

## 20.7 小结

- `C-h v`（`describe-variable`）查看变量的文档和当前值——定制前先查文档。
- `M-x customize` 提供图形化浏览和修改设置的界面。`M-x customize-variable` / `customize-face` / `customize-group` 直接跳到目标。
- init 文件推荐放在 `~/.emacs.d/init.el`。用 `setq` 设普通变量、`setq-default` 设有 buffer-local 值的变量、`setopt` 设需要走 Customize 框架的变量。
- 改键用 `keymap-global-set`（全局）或 `keymap-set`（mode 局部）。
- Hook 让你在特定时机（如进入某个 mode 时）自动执行代码。`add-hook` 添加、`remove-hook` 移除。
- `M-x customize` 保存的内容默认写入 init 文件；可以用 `custom-file` 变量把它分离到单独文件。

---

上一章：[19 · Shell、编译与调试入口](19-shell-and-build.md) ｜ 下一章：[21 · 安装扩展包](21-packages.md) ｜ 返回：[使用 Emacs 教程](README.md)
