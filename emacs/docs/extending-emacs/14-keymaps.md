# 14 · keymap 与按键绑定

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/14-keymaps.el`

## 14.1 kbd：把「人写的按键」编译成 Emacs 内部表示

```elisp
(kbd "C-c x")      ; 两个元素的 key 序列
(kbd "M-x")
(kbd "C-<tab>")
(kbd "RET")
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
(lookup-key demo-map (kbd "C-c a"))        ; → demo-do-a
(lookup-key demo-map (kbd "C-c z"))        ; → nil
```

```
lookup "C-c a" = demo-do-a，"C-c z" = nil
```

- `define-key` 绑定；绑到 `nil` 就是解绑；
- `lookup-key` 只在**一个** keymap 里查，找不到返回 `nil`（不会往上找父 map）；
- 想查「在当前 buffer 里最终会执行什么」，用 `key-binding`（见 14.6）。

## 14.4 前缀键

```
define-prefix-command: find-file
前缀下的绑定: demo-do-a / demo-do-b
```

`C-c` 就是一个前缀 —— 一个键下面挂着一整棵子 keymap。定义自己的前缀：

```elisp
(define-prefix-command 'demo-map)
(define-key global-map (kbd "C-c d") 'demo-map)   ; C-c d 变成前缀
(define-key demo-map (kbd "r") #'demo-run)        ; 于是 C-c d r
```

`C-c` 后跟一个字母（`C-c a` 到 `C-c z`，不加其他修饰）是**保留给用户**的，
扩展**不应该占用**（见 14.9）。

## 14.5 keymap-parent：继承

```elisp
(set-keymap-parent child-map parent-map)
```

```
子 map 继承来的绑定: demo-do-a
```

子 map 里查不到的键会到父 map 里找。`define-derived-mode` 生成的 keymap 就自动把 parent 设成了
父 mode 的 keymap —— 这是「新 mode 自动拥有父 mode 所有按键」的实现方式。

## 14.6 【重点】一次按键到底触发谁

查询顺序（从高到低）：

1. 当前启用的 **minor mode** 的 keymap（按 `minor-mode-map-alist` 的顺序，后启用的优先）
2. 当前 buffer 的 **local keymap**（major mode 的 keymap）
3. **global-map**

实测：

```
global-map 里 C-x C-f 绑的是: find-file
global-set-key 之后: demo-do-a
local map 生效: demo-do-b
local-set-key 之后: demo-do-b
```

同一个键既在 local 又在 global 绑了，**local 赢** —— 这就是为什么 mode 可以覆盖全局快捷键。
想知道某个键最终执行什么：

```elisp
(key-binding (kbd "C-x C-f"))    ; → find-file
```

## 14.7 绑定到 global / local

```elisp
(global-set-key (kbd "C-c g") #'demo-do-a)       ; 全局
(local-set-key  (kbd "C-c l") #'demo-do-b)       ; 当前 buffer
```

扩展的纪律：**不要随便 `global-set-key`**。它会污染用户的全局环境并且和别的包冲突。
正确做法是定义自己的 map，然后挂到某个 mode 的 keymap 或 minor mode 上。

## 14.8 解绑与屏蔽

```elisp
(define-key map (kbd "C-c x") nil)          ; 解绑（回到继承来的绑定）
(define-key map (kbd "C-c x") #'undefined)  ; 屏蔽（彻底不响应，也不往上找）
```

```
解绑后 lookup = nil
```

区别在于：绑到 `nil` 只是删掉这一层的绑定，查询会继续往上找父 map；
绑到 `#'undefined` 则明确表示「这个键就是要无效」。

## 14.9 【坑】C-c + 单个字母是用户的

Emacs 官方约定：

| 键区 | 归属 |
|---|---|
| `C-c` + 字母 | **用户**保留（用户自己的快捷键） |
| `C-c C-<字母>` | 给 major mode 用 |
| `C-c` + 非字母字符 | 给少数特例（`C-c /` 之类） |

所以你的扩展要绑键，应该用 `C-c C-x` 这种**带修饰**的形式，或者自己造前缀（`C-c d` 那种）。
占用 `C-c a` 会和用户的配置打架，而且用户会很不高兴 —— 这是社区里有共识的礼节。

```
global-map 里 C-x C-f 绑的是: find-file
```

## 14.10 给用户提示

```elisp
(substitute-command-keys "\\[find-file]")
```

```
去掉属性之后: "C-x C-f"
```

`substitute-command-keys` 把 docstring 里的 `\[命令名]` 替换成**用户当前实际绑定的键**。
所以写 docstring 时应该写：

```elisp
(defun demo-run ()
  "运行当前项。\\[demo-run] 可以重新运行。"
  (interactive))
```

用户改了绑定之后，docstring 里显示的也是改后的键 —— 这比自己写死 `C-c r` 好得多。

```
命令的 docstring: "命令 A。"
```

> `substitute-command-keys` 会往字符串上加 `help-key-binding` 属性（好让 `C-h f` 里显示成一个
> 按钮）。想在纯文本输出里用，要先 `substring-no-properties` 去掉属性。

---

上一章：[13 · 交互式命令](13-interactive.md)　｜　下一章：[15 · minor mode](15-minor-mode.md)　｜　返回：[Emacs 扩展开发指南](README.md)
