# 16 · major mode

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/16-major-mode.el`

major mode 是「一个 buffer 的主语言/主用途」。一个 buffer 同时只有一个 major mode。
写 major mode 是「支持一门新语言/新格式」的标准做法。

## 16.1 四个组成部分

一个 major mode 要做四件事：

1. **语法表**（syntax table）—— 告诉 Emacs 哪些字符是注释、字符串引号、词的组成；
2. **字体锁**（font-lock）—— 用正则给不同部分上不同 face；
3. **`-mode` 函数** —— 设置上面两样东西；
4. **`-mode-hook`** —— 给用户/别的包插入自己配置的点。

## 16.2 语法表

```elisp
(defvar demo-note-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; ";" 行注释，且第二字符也是 ";"（Emacs 用 ". 12" 表示注释起始+第二字符）
    (modify-syntax-entry ?\; ". 12" st)
    ;; 换行符结束注释
    (modify-syntax-entry ?\n ">" st)
    ;; 连字符"-"、下划线"_"、冒号":"算作单词组成字符，
    ;; 这样 M-f 移动和正则 \\sw 匹配就会把 my-tag 当成一个整体
    (modify-syntax-entry ?- "w" st)
    (modify-syntax-entry ?_ "w" st)
    st)
  "demo-note-mode 的语法表。")
```

```
5) ';' 的语法类别 = "."（'< ' 表示注释起始）
   '-' 的语法类别 = "w"（'w' 表示单词组成）
```

语法类别速查：

| 类别 | 含义 |
|---|---|
| `w` | 词组成字符（`forward-word` 会跳过） |
| `-` / `_` | 符号组成字符 |
| `.` | 标点 |
| `(` `)` | 配对括号 |
| `"` | 字符串引号 |
| `<` `>` | 注释的起止 |
| `\` | 转义 |
| ` ` | 空白 |

`char-syntax` 返回的就是类别的字符（比如 `.` 表示标点）。

## 16.3 字体锁关键字

```elisp
(defvar demo-note-font-lock-keywords
  '(("^#\\s-+\\(.*\\)$"                 1 'bold)          ; 标题
    ("^\\*\\s-+\\(TODO\\)\\s-"          1 'warning t)     ; TODO
    ("^\\*\\s-+\\(DONE\\)\\s-"          1 'success t)     ; DONE
    ("\\(@[a-zA-Z0-9_-]+\\)"            1 'italic t))     ; @标签
  "demo-note-mode 的高亮规则。")
```

```
6) (font-lock-mode 1) 之后变量 = nil（batch 下被守卫打回）
   TODO 处被着上的 face = warning
   DONE 处被着上的 face = success
   普通正文的 face = nil
```

两种写法：

- `(正则 . face)` —— 整个匹配都上这个 face；
- `(正则 (子组号 face ...) ...)` —— 只给指定子组上色，这是更常见的需求。

`font-lock-ensure` 强制把整个 buffer 着色一遍（交互模式下字体锁是懒加载的，测试时必须显式调）。
**在 batch 模式下字体锁照样能工作** —— 这一点值得知道，因为它意味着高亮逻辑可以写进自动化测试。

```elisp
(with-temp-buffer
  (demo-note-mode)
  (insert "# 我的笔记\n")
  (insert "* TODO 买咖啡\n")
  (insert "* DONE 写教程 @emacs\n")
  (font-lock-mode 1)
  (princ (format "6) (font-lock-mode 1) 之后变量 = %S（batch 下被守卫打回）\n" font-lock-mode))
  (font-lock-ensure)
  ;; 【坑】search-forward 结束后 point 停在匹配的**末尾**，
  ;; 而属性区间是左闭右开的，所以要在 (match-beginning 0) 处取属性。
  (goto-char (point-min))
  (search-forward "TODO")
  (princ (format "   TODO 处被着上的 face = %S\n"
                 (get-text-property (match-beginning 0) 'face)))
  (goto-char (point-min))
  (search-forward "DONE")
  (princ (format "   DONE 处被着上的 face = %S\n"
                 (get-text-property (match-beginning 0) 'face)))
  (goto-char (point-min))
  (search-forward "咖啡")
  (princ (format "   普通正文的 face = %S\n"
                 (get-text-property (match-beginning 0) 'face))))
```

```
6) (font-lock-mode 1) 之后变量 = nil（batch 下被守卫打回）
   TODO 处被着上的 face = warning
   DONE 处被着上的 face = success
   普通正文的 face = nil
```

> 【坑】`font-lock-mode` 的函数体里有一条硬守卫：**`noninteractive`（batch）或 buffer 名以
> 空格开头时，`(font-lock-mode 1)` 会被打回 `nil`**。但 `font-lock-ensure` 不走这个守卫，
> 照样能把字上色（上面第二行就是证据）。所以：batch 里测字体锁，别信 `font-lock-mode`
> 变量，信 `font-lock-ensure` 的结果。
>
> 交互场景下，`global-font-lock-mode`（默认开）会自动给「支持字体锁的 mode」打开它，
> 范围由 `font-lock-global-modes` 控制（默认 `t` = 所有 mode，没有按 mode 类别的例外）。

## 16.4 define-derived-mode

```elisp
(define-derived-mode demo-note-mode text-mode "Note"
  "极简笔记格式的 major mode。"
  ;; 注释相关（M-; 依赖这些）
  (setq-local comment-start "; ")
  (setq-local comment-end "")
  ;; 字体锁：font-lock-defaults 的第二个参数表示「是否关掉语法阶段着色」
  (setq font-lock-defaults '(demo-note-font-lock-keywords nil t))
  ;; 缩进：简单起见让 Tab 走 indent-relative
  (setq-local indent-line-function #'indent-relative))
```

注意 body 里**没有** `(set-syntax-table ...)` —— 因为 `define-derived-mode` 按命名约定
（`<mode 名>-syntax-table`）自动声明 `demo-note-mode-syntax-table`，并在生成的 mode 函数里
自动 `set-syntax-table`。你只管把表填好，安装是它的事。

生成了：

- `demo-note-mode` 函数；
- `demo-note-mode-map`、`demo-note-mode-syntax-table`、`demo-note-mode-abbrev-table`；
- `demo-note-mode-hook`，并且**在 mode 函数末尾自动 run 它**（body 之后，见 16.6）。

## 16.5 派生关系怎么查

```elisp
(princ (format "4) 派生关系: parent 属性 = %S\n"
               (get 'demo-note-mode 'derived-mode-parent)))
(princ (format "   定义后立刻查: keymap parent = %S，语法表 parent 是标准表? %S\n"
               (keymap-parent demo-note-mode-map)
               (eq (char-table-parent demo-note-mode-syntax-table)
                   (standard-syntax-table))))
(with-temp-buffer
  (demo-note-mode)
  (princ (format "   进入 mode 后: keymap parent = text-mode-map? %S，语法表 parent = text-mode 表? %S\n"
                 (eq (keymap-parent demo-note-mode-map) text-mode-map)
                 (eq (char-table-parent demo-note-mode-syntax-table)
                     text-mode-syntax-table)))
  (princ (format "   derived-mode-p: text=%S prog=%S fundamental=%S\n"
                 (derived-mode-p 'text-mode)
                 (derived-mode-p 'prog-mode)
                 (derived-mode-p 'fundamental-mode)))
  (princ (format "   major-mode 本身 = %S\n" major-mode)))
```

```
4) 派生关系: parent 属性 = text-mode
   定义后立刻查: keymap parent = nil，语法表 parent 是标准表? t
   进入 mode 后: keymap parent = text-mode-map? t，语法表 parent = text-mode 表? t
   derived-mode-p: text=text-mode prog=nil fundamental=nil
   major-mode 本身 = demo-note-mode
```

三个要点：

- `derived-mode-p` 返回的是**匹配到的那个 mode 符号**（不是 `t`），沿整条继承链往上找；
- 【坑】**keymap 的 parent 和语法表的 parent 都是「首次进入 mode 时」才设上的**
  （设成当时的 local map / 当前语法表）。定义完立刻查，keymap parent 是 `nil`、
  语法表 parent 还是标准语法表 —— 这不是 bug，别去「修」它；
- 【坑】**parent 是 `fundamental-mode` 时，`derived-mode-parent` 属性是 `nil`**
  （`fundamental-mode` 是根，`define-derived-mode` 不为它记录父关系），且
  `(derived-mode-p 'fundamental-mode)` 永远是 `nil`。所以别用
  `(get 'xxx 'derived-mode-parent)` 判断「是不是某个 mode 的子类」，要用 `derived-mode-p`。

## 16.6 hook 在 body 之后

```elisp
(let ((log nil))
  (with-temp-buffer
    (let ((demo-note-mode-hook (list (lambda () (push "hook 跑了" log)))))
      (demo-note-mode))
    (princ (format "   %S，当前 mode = %S，mode-name = %S\n"
                   (car log) major-mode mode-name))))
```

```
7) hook 触发顺序：
   "hook 跑了"，当前 mode = demo-note-mode，mode-name = "Note"
```

`run-mode-hooks` 在 mode 函数**末尾**执行，body 里的一切此时都已设好 —— 这保证用户挂在
`demo-note-mode-hook` 上的配置能看到完整的 mode 状态。反过来也意味着：**hook 里不要改
`major-mode`，也不该做只有 mode 自己能做的设置**。

想「用户配置跑完之后再补一刀」，用 `:after-hook` 关键字参数（Emacs 29+）：

```elisp
(defvar demo-ah-order nil)
(define-derived-mode demo-ah-mode text-mode "AH"
  :after-hook (setq-local demo-ah-order (cons :after-hook demo-ah-order))
  (setq-local demo-ah-order (cons :body demo-ah-order)))
```

```
11) 执行顺序（晚执行的排在前面）= (:after-hook :body)
```

顺序是 **body → hook → `:after-hook`**。它比「往 mode hook 里 `add-hook` 再 `remove-hook`」
干净得多 —— 典型的用途是「用户可能在 hook 里改了某个设置，我要在最后校验/修正它」。

## 16.7 关联文件后缀

```elisp
(add-to-list 'auto-mode-alist '("\\.note\\'" . demo-note-mode))
```

```
8) auto-mode-alist 新增前是否已有关联: nil
   加完之后: ("\\.note\\'" . demo-note-mode)
```

打开 `.note` 文件时自动进入这个 mode。注意**正则要用 `\\'` 锚定结尾**（不是 `$`），
否则 `.notebook` 这种也会被匹配上。

## 16.8 【坑】命名规范

- major mode 名必须**以 `-mode` 结尾**，而且**全局唯一**；
- 别的包的成员函数/变量一律加前缀（`demo-note-`），避免撞名；
- 私有函数用双横线（`demo-note--internal`）表示「不打算给外面用」。

变量、keymap、hook 都靠 mode 名派生（`demo-note-mode-map`、`demo-note-mode-hook`），
改名的成本很高，一开始就取好。

## 16.9 一个 mode 该提供什么的检查表

```elisp
(princ (format "10) keymap 名 = %S，hook 名 = %S\n"
               'demo-note-mode-map 'demo-note-mode-hook))
```

```
10) keymap 名 = demo-note-mode-map，hook 名 = demo-note-mode-hook
```

写新 major mode 时逐条对照：

- [ ] `xxx-mode` 函数（用 `define-derived-mode`）
- [ ] `xxx-mode-syntax-table`（有特殊语法时）
- [ ] 字体锁关键字，并在 body 里开 font-lock
- [ ] `xxx-mode-map`，parent 设成合适的父 mode
- [ ] `auto-mode-alist` 关联（可选，通常是用户在配置里做）
- [ ] `imenu` 支持（能按结构跳转）
- [ ] `indent-line-function`（缩进规则）
- [ ] docstring 里写清用法

---

上一章：[15 · minor mode](15-minor-mode.md)　｜　下一章：[17 · hook](17-hooks.md)　｜　返回：[Emacs 扩展开发指南](README.md)
