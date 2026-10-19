# 14 · keymap 与按键绑定

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/14-keymaps.el`

## 14.1 kbd：把「人写的按键」编译成 Emacs 内部表示

```elisp
(princ (format "kbd \"C-c x\"   = %S（内部是 %S 个元素的序列）\n"
               (key-description (kbd "C-c x")) (length (kbd "C-c x"))))
(princ (format "kbd \"M-x\"     = %S\n" (key-description (kbd "M-x"))))
(princ (format "kbd \"C-<tab>\" = %S\n" (key-description (kbd "C-<tab>"))))
(princ (format "kbd \"RET\"     = %S\n" (key-description (kbd "RET"))))
(princ (format "kbd \"C-M-s\"   = %S\n" (key-description (kbd "C-M-s"))))
(princ (format "kbd \"<f5>\"    = %S\n" (key-description (kbd "<f5>"))))
```

```
kbd "C-c x"   = "C-c x"（内部是 2 个元素的序列）
kbd "M-x"     = "M-x"
kbd "C-<tab>" = "C-<tab>"
kbd "RET"     = "RET"
kbd "C-M-s"   = "C-M-s"
kbd "<f5>"    = "<f5>"
```

`kbd` 是**宏**，参数必须是编译期已知的字符串常量。写按键就用它，**不要手写
`[?\C-c ?x]` 这种向量** —— 前者可读、跨平台一致（`RET` vs `\r`），后者容易写错。

> **注意** 上面那些 `= "C-c x"` 是 `key-description` 的输出。如果你用 `%S` 直接打印 `(kbd "C-c x")`，
> 得到的是含原始控制字节的 `"^Cx"` —— 这正好触发第 0.3 节的「控制字符」判定，所以展示键序列一律
> 先过 `key-description`。

## 14.2 keymap 就是一个 list

```
空 keymap: (keymap)
绑定后: (keymap (3 keymap (98 . demo-do-b) (97 . demo-do-a)))
```

car 是符号 `keymap`，后面的条目形如 `(字符 . 命令)` 或 `(字符 keymap ...)`（子前缀）。
看懂这个结构对调试很有帮助 —— 遇到「按键不生效」时直接打印 keymap 就能看出问题。

## 14.3 绑定与查询

```elisp
(define-key demo-map (kbd "C-c a") #'demo-do-a)
(define-key demo-map (kbd "C-c b") #'demo-do-b)
(princ (format "lookup \"C-c a\" = %S，\"C-c z\" = %S\n"
               (lookup-key demo-map (kbd "C-c a"))
               (lookup-key demo-map (kbd "C-c z"))))
```

```
lookup "C-c a" = demo-do-a，"C-c z" = nil
```

- `define-key` 绑定；绑到 `nil` 就是解绑；
- `lookup-key` 只在**一个** keymap 里查，找不到返回 `nil`（不会往上找父 map）；
- 想查「在当前 buffer 里最终会执行什么」，用 `key-binding`（见 14.6）。

## 14.4 前缀键

```elisp
(define-key demo-map (kbd "C-c m") (make-sparse-keymap))
(define-key demo-map (kbd "C-c m s") #'demo-do-a)
(define-key demo-map (kbd "C-c m t") #'demo-do-b)
```

```
前缀下的绑定: demo-do-a / demo-do-b
```

`C-c` 就是一个前缀 —— 一个键下面挂着一整棵子 keymap。前缀本身也是一个 keymap，挂上去就行。

想让前缀同时**是个命令**（能 `M-x` 执行、能被 which-key 识别），用 `define-prefix-command`：

```elisp
(define-prefix-command 'demo-prefix-map)
(define-key demo-map (kbd "C-c p") 'demo-prefix-map)
(define-key demo-map (kbd "C-c p f") #'find-file)
```

```
define-prefix-command: find-file
```

`C-c` 后跟一个字母（`C-c a` 到 `C-c z`，不加其他修饰）是**保留给用户**的，
扩展**不应该占用**（见 14.9）。

## 14.5 keymap-parent：继承

```elisp
(defvar demo-child (make-sparse-keymap))
(set-keymap-parent demo-child demo-map)
```

```
子 map 继承来的绑定: demo-do-a
```

子 map 里查不到的键会到父 map 里找。`define-derived-mode` 生成的 keymap 就自动把 parent 设成了
父 mode 的 keymap —— 这是「新 mode 自动拥有父 mode 所有按键」的实现方式。

## 14.6 【重点】一次按键到底触发谁

查询顺序（从高到低，手册的伪代码总结）：

1. `overriding-terminal-local-map`（极少用，`set-transient-map` 就设它）
2. `overriding-local-map`（极少用）
3. point 处的 `keymap` 文本属性 / overlay keymap
4. `emulation-mode-map-alists`
5. `minor-mode-overriding-map-alist`
6. `minor-mode-map-alist`（按 alist 顺序，**越靠前越优先**；只有变量非 `nil` 的条目才算数）
7. point 处的 `local-map` 属性，否则当前 buffer 的 local map（major mode 的 keymap）
8. `global-map`

```
global-map 里 C-x C-f 绑的是: find-file
global-set-key 之后: demo-do-a
local map 生效: demo-do-b
local-set-key 之后: demo-do-b
```

同一个键既在 local 又在 global 绑了，**local 赢** —— 这就是为什么 mode 可以覆盖全局快捷键。
同理，minor mode 的键会盖住 major mode 的键：「major mode 的键被 minor mode 挡住」是正常
现象，不是 bug。

想知道某个键最终执行什么，用 `key-binding`（它会走完整套查找），别用 `lookup-key`
（它只看一个 map）：

```elisp
(princ (format "key-binding C-x C-f = %S\n" (key-binding (kbd "C-x C-f"))))
```

```
key-binding C-x C-f = find-file
```

## 14.7 绑定到 global / local

```elisp
(global-set-key (kbd "C-c d") #'demo-do-a)       ; 全局
(local-set-key  (kbd "C-c l") #'demo-do-b)       ; 当前 buffer
```

扩展的纪律：**不要随便 `global-set-key`**。它会污染用户的全局环境并且和别的包冲突。
正确做法是定义自己的 map，然后挂到某个 mode 的 keymap 或 minor mode 上。

## 14.8 解绑与屏蔽

```elisp
(define-key demo-map (kbd "C-c a") nil)          ; 解绑（回到继承来的绑定）
```

```
解绑后 lookup = nil
```

绑到 `nil` 只是删掉这一层的绑定，查询会继续往上找父 map；要「屏蔽」某个键则绑到
`#'undefined`，它明确表示「这个键就是要无效」，不再继续找。

## 14.9 【坑】C-c + 单个字母是用户的

Emacs 官方约定（手册附录 D.2）：

| 键区 | 归属 |
|---|---|
| `C-c` + 字母（大小写、含非 ASCII 字母） | **用户**保留，且是唯一留给用户的序列 |
| `F5`–`F9` 无修饰键 | **用户**保留 |
| `C-c` + 控制字符或数字 | **major mode** |
| `C-c` + `{` `}` `<` `>` `:` `;` | **major mode** |
| `C-c` + 其他 ASCII 标点/符号 | **minor mode**（major mode 用也不算禁，但可能被 minor mode 盖住） |

另外几条常被违反的：

- 任何前缀后面**不要绑 `C-h`**（`C-h` 要留给「列出这个前缀下有哪些子命令」）；
- 不要绑以 `ESC` 结尾的序列（跟在另一个 `ESC` 后面除外），否则干扰终端转义序列识别；
- 不要绑以 `C-g` 结尾的序列（`C-g` 是通用的「取消」）；
- 临时性 mode/状态应该提供 `ESC ESC`（或接受普通命令的状态用 `ESC ESC ESC`）作为退出。

占用 `C-c a` 会和用户的配置打架 —— 这是社区里有共识的礼节。

## 14.10 给用户提示

```elisp
(princ (format "命令的 docstring: %S\n" (documentation #'demo-do-a)))
(princ (format "docstring 替换后: %S\n"
               (substring-no-properties
                (substitute-command-keys "运行：\\[demo-do-a]"))))
```

```
命令的 docstring: "命令 A。"
docstring 替换后: "运行：C-c d"
```

`substitute-command-keys` 把 docstring 里的 `\[命令名]` 替换成**用户当前实际绑定的键**。
所以写 docstring 时应该写 `\\[命令名]`，不要写死 `C-c r` —— 上面第二行输出的是 `C-c d`
（本例里 `demo-do-a` 绑在 `C-c d` 上），用户改了绑定之后，docstring 里显示的也是改后的键。

> `substitute-command-keys` 会往字符串上加 `help-key-binding` 属性（好让 `C-h f` 里显示成一个
> 按钮）。想在纯文本输出里用，要先 `substring-no-properties` 去掉属性。

---

上一章：[13 · 交互式命令](13-interactive.md)　｜　下一章：[15 · minor mode](15-minor-mode.md)　｜　返回：[Emacs 扩展开发指南](README.md)
