# 08 · 定制总结与性能调优

最后一章：把前 7 章散落的知识点串成一份「实战配置手册」，并回答一个常见问题——**CC Mode 卡了怎么办**。

## 8.1 完整配置模板

一份「开箱即用」的 CC Mode 配置，覆盖日常 90% 的需求：

```elisp
;; ========== CC Mode 配置 ==========

;; 1. 风格：用 linux 做基底（tab 缩进、K&R 括号），但改成 4 空格
(c-add-style "my-style"
             '("linux"
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)
                                   (substatement-open . 0)
                                   (arglist-cont-nonempty . c-lineup-arglist)))
               (c-cleanup-list . (brace-else-brace
                                  empty-defun-braces
                                  defun-close-semi))))

;; 2. 默认风格
(setq c-default-style '((c-mode    . "my-style")
                        (c++-mode  . "my-style")
                        (java-mode . "java")
                        (other     . "gnu")))

;; 3. 缩进细节
(setq c-basic-offset 4
      c-tab-always-indent t
      indent-tabs-mode nil)           ;; 用空格不用 tab

;; 4. Electric / auto-newline
(setq c-electric-flag t
      c-auto-newline nil)             ;; electric 开、auto-newline 关（默认）

;; 5. Hungry delete
(setq c-hungry-delete-key t)          ;; C-d 和 DEL 都走 hungry delete

;; 6. Subword mode（驼峰式单词移动）
(add-hook 'c-mode-common-hook #'c-subword-mode)

;; 7. Font locking
(setq font-lock-maximum-decoration t) ;; level 3（默认）

;; 8. 注释
(setq c-block-comment-prefix "* "     ;; 块注释续行加 * 前缀
      c-doc-comment-style 'javadoc)   ;; 文档注释用 Javadoc 格式

;; 9. 反斜杠对齐
(setq c-backslash-column 48
      c-backslash-max-column 72)
```

## 8.2 性能调优

CC Mode 的两大性能瓶颈：**syntactic indentation**（每次缩进都要做语法分析）和 **font locking**（高亮大文件时扫全 buffer）。

### 瓶颈 1：Syntactic Indentation

每次 `TAB`、每次 electric 键触发，CC Mode 都会调 `c-guess-basic-syntax` 分析当前行的 syntactic context。在普通文件里这是毫秒级；在**巨大文件**（10000+ 行）或** deeply nested** 代码里可能卡。

**关掉 syntactic indentation**（终极手段）：

```elisp
(setq c-syntactic-indentation nil)
```

关掉后 `TAB` 只做「对齐到上一行同列」这种简单缩进，不做语法分析。速度最快，但缩进质量下降——不推荐日常用，只在「大文件里临时提速」时用。

**更细的控制**：只关宏里的 syntactic indentation：

```elisp
(setq c-syntactic-indentation-in-macros nil)
```

宏定义（`#define` 里的多行代码）的 syntactic 分析特别慢——因为宏体不是真正的 C 语法，CC Mode 要做额外判断。关掉这个变量后宏里的缩进用简单规则，宏外仍用完整 syntactic 分析。

### 瓶颈 2：Font Locking

见第 7 章 7.4 节。核心思路：

```elisp
;; 大文件里降等级
(add-hook 'c-mode-hook
          (lambda ()
            (when (> (buffer-size) 100000)
              (setq font-lock-maximum-decoration 1))))
```

### 瓶颈 3：Auto-newline + Electric

auto-newline 每次触发都要做完整的 syntactic 分析 + 可能的 clean-up。写代码时如果感觉「每打一个 `{` 都要卡一下」，先关 auto-newline：

```elisp
(setq c-auto-newline nil)
```

electric 本身（不含 auto-newline）开销很小——它只是「插入字符 + 重新缩进当前行」，通常不会卡。

### 性能变量速查

| 变量 | 默认 | 调优建议 |
|---|---|---|
| `c-syntactic-indentation` | `t` | 大文件里设 `nil`（牺牲缩进质量） |
| `c-syntactic-indentation-in-macros` | `t` | 宏特别多时设 `nil` |
| `c-auto-newline` | `nil` | 已默认关闭；开了卡就关 |
| `font-lock-maximum-decoration` | `t` | 大文件里设 1 或 2 |
| `c-electric-flag` | `t` | 极端情况下设 `nil`（完全关 electric） |

## 8.3 调试：CC Mode 行为不对怎么办

### 看 syntactic context

```elisp
C-c C-s    ;; c-show-syntactic-information
```

显示当前行的 syntactic element 列表 + 高亮 anchor 位置。这是调试缩进问题的第一步——先看 CC Mode 把当前行识别成了什么。

### 看实际生效的 offset

```elisp
C-h v c-offsets-alist
```

看当前 buffer 的完整 offset 表（buffer-local 值）——包含风格默认值 + 你的 hook 覆盖。

### 看当前风格

```elisp
C-h v c-style
```

显示当前 buffer 的风格名。

### 逐层排查

缩进不对时，按这个顺序查：

1. `C-c C-s` 看 syntactic symbol 是什么。
2. `C-h v c-offsets-alist` 看这个 symbol 的 offset 是什么。
3. 如果 offset 不对，检查：风格定义 → hook 覆盖 → file-local 变量（第 3 章 3.7 优先级）。
4. 如果 offset 对但结果不对，检查 anchor 位置是否合理（`C-c C-s` 会高亮 anchor）。

## 8.4  obsolete 变量：不要碰

CC Mode 历史上有几个变量已标记为 obsolete——**不要在新配置里用**：

| 变量 | 状态 | 替代方案 |
|---|---|---|
| `c-strict-syntax-p` | obsolete | 不需要——line-up 函数返回 nil 是正常行为 |
| `c-echo-syntactic-information-p` | obsolete | 用 `C-c C-s` 按需查看 |
| `c-report-syntactic-errors` | 仍存在但默认 nil | 不需要开——错误会在 echo area 自然显示 |
| `c-indent-level` | 不存在 | 用 `c-basic-offset` |

## 8.5 CC Mode 的 `c-mode-common-hook`

所有 CC Mode 派生 mode（c-mode、c++-mode、java-mode、objc-mode、awk-mode、pike-mode）共享一个 hook：`c-mode-common-hook`。在这里加的配置对所有 CC Mode 语言生效：

```elisp
(add-hook 'c-mode-common-hook
          (lambda ()
            (setq c-basic-offset 4)
            (c-set-offset 'case-label '+)
            (c-subword-mode 1)))
```

如果只想对特定语言生效，用对应的 mode hook（`c-mode-hook`、`c++-mode-hook` 等）。

## 8.6 与其他 package 的协作

### Company / Auto-completion

CC Mode 本身不带补全。要补全用 company-mode 或 corfu + cape。CC Mode 提供语法分析基础，补全前端在它之上工作。

### LSP (lsp-mode / eglot)

CC Mode 可以和 LSP 共存——LSP 提供跳转/补全/诊断，CC Mode 提供缩进/高亮/编辑辅助。两者不冲突：

```elisp
(add-hook 'c-mode-hook #'eglot-ensure)
```

### Flycheck / Flymake

语法检查用 flycheck 或 flymake。CC Mode 不管语法检查——它只管「编辑体验」（缩进、高亮、移动）。

## 8.7 终极配置：一份 init.el 片段

把本章内容浓缩成一份可直接抄的 init 片段：

```elisp
;; ========== CC Mode 完整配置 ==========

;; 风格定义
(c-add-style "my-c-style"
             '("linux"
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)
                                   (substatement-open . 0)
                                   (arglist-cont-nonempty . c-lineup-arglist)))))

;; 默认风格
(setq c-default-style '((c-mode    . "my-c-style")
                        (c++-mode  . "my-c-style")
                        (java-mode . "java")
                        (other     . "gnu")))

;; 缩进
(setq c-basic-offset 4
      c-tab-always-indent t
      indent-tabs-mode nil)

;; Electric / auto-newline / hungry delete
(setq c-electric-flag t
      c-auto-newline nil
      c-hungry-delete-key t)

;; 注释
(setq c-block-comment-prefix "* "
      c-doc-comment-style 'javadoc)

;; 反斜杠
(setq c-backslash-column 48
      c-backslash-max-column 72)

;; 共享 hook
(add-hook 'c-mode-common-hook
          (lambda ()
            (c-subword-mode 1)))

;; 大文件性能
(add-hook 'c-mode-hook
          (lambda ()
            (when (> (buffer-size) 100000)
              (setq font-lock-maximum-decoration 1))))
```

## 8.8 本章导航速查

- 完整配置模板：见 8.1 和 8.7。
- 性能调优：见 8.2。
- 调试缩进问题：`C-c C-s` + `C-h v c-offsets-alist`。
- 全套教程到此结束——返回 [CC Mode 教程](README.md) 查看更多章节。

---

上一章：[07 · Font Locking：语法高亮](07-font-locking.md)　｜　下一章：（无下一章）　｜　返回：[CC Mode 教程](README.md)
