# 15 · minor mode

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/15-minor-mode.el`

minor mode 就是「一个可以开关的附加功能」。绝大多数「我给 Emacs 加了个小功能」的场景，
正确的形态就是一个 minor mode。

## 15.1 define-minor-mode 一次生成四样东西

```elisp
(defvar demo-lint-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c l n") #'demo-lint-next)
    (define-key map (kbd "C-c l r") #'demo-lint-run)
    map)
  "demo-lint-mode 的按键表。")

(defun demo-lint-next ()
  "跳到下一个问题。"
  (interactive))
(defun demo-lint-run ()
  "跑一次检查。"
  (interactive))

(define-minor-mode demo-lint-mode
  "演示用的 minor mode：给当前 buffer 加上检查功能。"
  :lighter " Lint"
  :keymap demo-lint-mode-map
  :global nil          ; nil = 只对当前 buffer 生效（默认），t = 全局生效
  :init-value nil      ; 默认关
  (if demo-lint-mode
      ;; 【注意】body 在开关状态**改变之后**执行，
      ;; 变量 demo-lint-mode 此时已经是新值（t 或 nil）。
      (princ (format "  demo-lint-mode 已打开，buffer = %S\n" (buffer-name)))
    (princ (format "  demo-lint-mode 已关闭，buffer = %S\n" (buffer-name)))))
```

生成的是：

1. **`demo-lint-mode` 函数** —— 也就是 `M-x demo-lint-mode` 这个命令，负责开关；
2. **`demo-lint-mode` 变量** —— 布尔状态，`t` 表示开着。**它就是状态本身，别另外再定义一个布尔量**；
3. **`demo-lint-mode-map`** —— 由 `:keymap` 指定的按键表；
4. **`demo-lint-mode-hook`** —— 开关时运行的 hook。

后两样东西「装没装上」可以直接查：

```elisp
(princ (format "minor-mode-map-alist 里有没有 demo-lint-mode: %S\n"
               (assq 'demo-lint-mode minor-mode-map-alist)))
(princ (format "minor-mode-alist（mode-line 显示）: %S\n"
               (assq 'demo-lint-mode minor-mode-alist)))
```

```
minor-mode-map-alist 里有没有 demo-lint-mode: (demo-lint-mode keymap (3 keymap (108 keymap (114 . demo-lint-run) (110 . demo-lint-next))))
minor-mode-alist（mode-line 显示）: (demo-lint-mode " Lint")
```

注意 `assq` 查 `minor-mode-map-alist` 的前提是 mode **开着**（变量非 `nil`，见第 14 章 14.6）。
`:lighter` 是 mode-line 上显示的名字，**推荐前面加一个空格**（`" Lint"`），否则会和前一个指示器粘在一起。

## 15.2 buffer-local：一个 buffer 开不影响别的

```
  demo-lint-mode 已打开，buffer = "demo-a"
A 里: t，keymap 命中: 1
B 里: nil（不受影响）
```

默认 `define-minor-mode` 生成的变量是 buffer-local 的 —— 这正是「minor mode」的本意：
它是**当前 buffer 上**的一个附加状态。

## 15.3 body 里同时写开关两支

```
  demo-lint-mode 已关闭，buffer = " *temp*"
关闭后: nil
```

body 在**每次切换时**执行一次，`demo-lint-mode` 变量已经是新值。所以标准写法是
「开：装东西，关：拆干净」：

```elisp
(with-temp-buffer
  (demo-lint-mode 1)
  (princ (format "打开后: %S\n" demo-lint-mode))
  (demo-lint-mode -1)
  (princ (format "关闭后: %S\n" demo-lint-mode)))
```

```
  demo-lint-mode 已打开，buffer = " *temp*"
打开后: t
  demo-lint-mode 已关闭，buffer = " *temp*"
关闭后: nil
```

传给 mode 函数的参数语义：`1` / `t` 打开，`0` / `nil` 关闭，**`-1` 强制关闭**
（即使是全局 mode），省略参数则取反。

> **注意 add-hook 的 LOCAL 参数**。minor mode 的 body 是 buffer 局部的，所以它装的 hook
> 也应该用 `(add-hook ... nil t)` 装成 buffer 局部的 —— 否则关掉这个 buffer 的 mode 时会把
> **所有** buffer 的 hook 一起删掉。

## 15.4 :global t

```elisp
(defvar demo-global-count 0)
(define-minor-mode demo-global-mode
  "演示用的全局 minor mode。"
  :global t
  :group 'demo-lint
  :init-value nil
  (setq demo-global-count (if demo-global-mode 1 0))
  (princ (format "  全局 mode 现在是: %S\n" demo-global-mode)))
(demo-global-mode 1)
(princ (format "全局开关: %S, 计数 = %S\n" demo-global-mode demo-global-count))
(demo-global-mode -1)
```

```
  全局 mode 现在是: t
全局开关: t, 计数 = 1
  全局 mode 现在是: nil
```

区别：全局 mode 的变量**不是** buffer-local，一个开关控制所有 buffer。
它适合「影响整个 Emacs 的行为」（比如 `global-flycheck-mode`），不适合「这个文件要不要检查」。

> 【坑】`:global t` 时，`define-minor-mode` 会把开关变量定义成一个 **defcustom**
> （因为它对所有 buffer 生效，属于「用户选项」）—— 所以**必须给 `:group`**，
> 否则字节编译器会报 `in defcustom for 'xxx': fails to specify containing group`。
> 本示例开头那个 `defgroup demo-lint` 就是为它准备的。

## 15.5 【坑】keymap 变量名必须严格匹配

```
kill-all-local-variables 会连 minor mode 一起关掉
```

- keymap 变量名必须是 `<mode 名>-map`，**一个字都不能差**；
- `kill-all-local-variables` 会把所有 buffer-local 的 minor mode 关掉 —— 这通常是你想要的
  （切 mode 时旧功能的残留会清掉）。但如果你**不希望**它被关，就得在 mode 的 body 里处理，
  或者用 `(put '<mode> 'permanent-local t)`。

## 15.6 【坑】body 里不要写 message

mode 会在**每个** buffer 里各跑一次（比如切 mode、`kill-all-local-variables` 时），
如果 body 里有 `(message ...)`，用户会看到一堆莫名其妙的回显，而且会污染你的 batch 输出。
要调试就写进 `*Messages*` 之外的地方，或者用 `(message nil)` 清空。

## 15.7 更轻量的选择

```
已定义的 minor mode 里含 demo-lint-mode: t
```

如果只是想给几个键加绑定、不需要开关状态，**不一定要写 mode**。两个更轻的方案：

- 直接用 `with-eval-after-load` + `define-key`（第 24 章）；
- 用 `local-set-key` 在某个 hook 里绑。

只有需要「用户能开关」「有状态」「mode-line 有指示器」这几个特性时，才值得写一个 minor mode。

---

上一章：[14 · keymap 与按键绑定](14-keymaps.md)　｜　下一章：[16 · major mode](16-major-mode.md)　｜　返回：[Emacs 扩展开发指南](README.md)
