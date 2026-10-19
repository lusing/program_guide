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
    (modify-syntax-entry ?\; "<" st)     ; ; 开始一个注释
    (modify-syntax-entry ?\n ">" st)     ; 换行结束注释
    (modify-syntax-entry ?- "w" st)      ; - 算作词组成字符
    st))
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
  `(("\\<TODO\\>" . warning)                    ; 整个匹配用 warning face
    ("\\<DONE\\>" . success)
    ("\\[\\([0-9]+\\)\\]" (1 'font-lock-constant-face))))  ; 只给第 1 组上色
```

```
6) TODO 处被着上的 face = warning
   DONE 处被着上的 face = success
   普通正文的 face = nil
```

两种写法：

- `(正则 . face)` —— 整个匹配都上这个 face；
- `(正则 (子组号 face ...) ...)` —— 只给指定子组上色，这是更常见的需求。

`font-lock-ensure` 强制把整个 buffer 着色一遍（异步字体锁平时是懒加载的，测试时必须显式调）。
**在 batch 模式下字体锁能正常工作** —— 这一点值得知道，因为它意味着高亮逻辑可以写进自动化测试。

> 【坑】**不是所有 major mode 的父类都会自动打开 font-lock**。`prog-mode` / `text-mode`
> 会自动开，但 `special-mode` 不会。派生自 `special-mode` 的 mode 需要自己在 body 里写
> `(font-lock-mode 1)`，否则 `font-lock-defaults` 设了也不生效。这个坑在写「只读列表型 mode」时必踩。

## 16.4 define-derived-mode

```elisp
(define-derived-mode demo-note-mode text-mode "Note"
  "一个极简的笔记文件主模式。"
  (setq-local font-lock-defaults '(demo-note-font-lock-keywords t))
  (set-syntax-table demo-note-mode-syntax-table)
  (add-hook 'after-save-hook #'demo-note-check nil t))
```

生成了：

- `demo-note-mode` 函数；
- `demo-note-mode-map`（parent 自动设成 `text-mode-map`）；
- `demo-note-mode-syntax-table`（parent 自动设成 `text-mode-syntax-table`）；
- `demo-note-mode-hook`，并且**在 mode 函数末尾自动 run 它**。

```
7) hook 触发顺序：
   "hook 跑了"，当前 mode = demo-note-mode，mode-name = "Note"
10) keymap 名 = demo-note-mode-map，hook 名 = demo-note-mode-hook
```

「hook 在 body 之后 run」这个顺序很重要：它保证用户挂在 `demo-note-mode-hook` 上的配置
能看到你在 body 里设好的一切。

## 16.5 派生关系怎么查

```elisp
(get 'demo-note-mode 'derived-mode-parent)    ; → text-mode
(derived-mode-p 'text-mode)                   ; 当前 buffer 里：→ text-mode
```

```
4) 派生关系: parent 属性 = text-mode
   derived-mode-p: text=text-mode prog=nil fundamental=nil
```

- `derived-mode-p` 返回的是**匹配到的那个 mode 符号**（不是 `t`），沿整条继承链往上找；
- 【坑】**当 parent 是 `fundamental-mode` 时，`derived-mode-parent` 属性是 nil** ——
  `fundamental-mode` 是根，`define-derived-mode` 不为它记录父关系。所以别用
  `(get 'xxx 'derived-mode-parent)` 去判断「是不是某个 mode 的子类」，要用 `derived-mode-p`。

## 16.6 关联文件后缀

```elisp
(add-to-list 'auto-mode-alist '("\\.note\\'" . demo-note-mode))
```

```
8) auto-mode-alist 新增前是否已有关联: nil
   加完之后: ("\\.note\\'" . demo-note-mode)
```

打开 `.note` 文件时自动进入这个 mode。注意**正则要用 `\\'` 锚定结尾**（不是 `$`），
否则 `.notebook` 这种也会被匹配上。

## 16.7 【坑】命名规范

- major mode 名必须**以 `-mode` 结尾**，而且**全局唯一**；
- 别的包的成员函数/变量一律加前缀（`demo-note-`），避免撞名；
- 私有函数用双横线（`demo-note--internal`）表示「不打算给外面用」。

```
9) 【坑】major mode 的命名必须以 -mode 结尾，且是全局唯一的
```

## 16.8 一个 mode 该提供什么的检查表

```
10) 一个 mode 该提供什么（checklist）：
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
