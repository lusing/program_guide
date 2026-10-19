# 26 · 完整示例：一个 todo 扩展

> 所属部分：第 6 部分 · 把一切串起来

> 示例：`examples/26-todo-demo.el`

前面的 25 章都是零件。这一章把零件拼成一个**可用的扩展**，并且展示真实开发里
「一个功能需要哪几样东西配合」的完整清单。

## 26.1 这个扩展长什么样

一个记录待办的小工具，具备：

- 内存中的数据结构（`cl-defstruct`）
- 持久化（`read` / `prin1` 到文件）
- 一个 major mode 来显示列表（`define-derived-mode` + 字体锁）
- 键盘操作（keymap + 交互式命令）
- 单元测试（`ert`）

## 26.2 数据结构与持久化

```elisp
(cl-defstruct (demo-todo-item (:constructor demo-todo-item-create))
  title done)

(defun demo-todo-save ()
  (with-temp-file demo-todo-file
    (prin1 demo-todo-items (current-buffer))))   ; prin1 = 可被 read 回来

(defun demo-todo-load ()
  (with-temp-buffer
    (insert-file-contents demo-todo-file)
    (goto-char (point-min))
    (setq demo-todo-items (read (current-buffer)))))
```

```
3) 存盘后清空内存，再读回来：
    -> 已保存 3 条到 demo-todo-OKvImD.eld
   清空后总数 = 0
    -> 已读取 3 条
   读回后总数 = 3，未完成 = 2
   标题顺序 = ("回复邮件" "买咖啡" "写 Emacs 教程")
```

**`prin1` + `read` 是 Elisp 里最省事的数据持久化方式**：`prin1` 写出的文本能被 `read` 读回来,
不需要自己写序列化/反序列化。文件名用 `.eld` 后缀是 Emacs 的惯例（「Emacs Lisp Data」）。
内置的 `savehist` / `desktop` 都是这么做的。

## 26.3 major mode 与渲染

```elisp
(define-derived-mode demo-todo-mode special-mode "Todo"
  "待办列表的主模式。"
  ;; 【坑】special-mode 不会自动打开 font-lock，要自己开。
  (setq font-lock-defaults '(demo-todo-font-lock-keywords t))
  (font-lock-mode 1))
```

```
4) 渲染成 buffer 并检查高亮：
   buffer 内容:
[ ] 回复邮件
[x] 买咖啡
[ ] 写 Emacs 教程
   第 1 行（未完成的回复邮件）标题的 face = font-lock-string-face
   第 2 行（已完成的买咖啡）标题的 face = font-lock-comment-face
   第 2 行的下标属性 = 1
```

两处值得注意：

1. **`special-mode` 不会自动开 font-lock**，必须自己 `(font-lock-mode 1)`。派生自
   `prog-mode` / `text-mode` 的 mode 则是自动开的 —— 这个差异很容易忽略（第 16.3 节也提过）。
2. **每个列表项都带一个「下标」文本属性**（`demo-todo--index-at-point`），
   这样命令就知道「光标在哪一项上」。这是「行列表」型 mode 的标准做法 ——
   用文本属性把「显示」和「数据」关联起来，而不是靠数行号。

## 26.4 键盘操作

```elisp
(goto-char (point-min))
(forward-line 2)
(demo-todo-toggle-at-point)      ; 标记完成
```

```
5) 在列表 buffer 里用键盘命令操作：
    -> 完成：写 Emacs 教程
    -> 共 3 条，未完成 1 条
   切换后未完成 = 1
    -> 已删除：回复邮件
    -> 共 2 条，未完成 0 条
   删除后总数 = 2，剩下的 = ("买咖啡" "写 Emacs 教程")
```

模式是「命令改数据 → 重新渲染 → 光标回到原来的项」。这是「数据结构是真相、buffer 只是视图」
的思路 —— 比「直接在 buffer 里改文本再解析回来」健壮得多，也是**大多数成熟 mode 的做法**。

## 26.5 清理

```
6) 清理已完成：
    -> 清掉了 2 条已完成
   清理后总数 = 0
8) 临时数据文件已清理: t
```

## 26.6 单元测试

```
7) 单元测试：共 4 个用例，失败 0 个
```

测试覆盖了「增删改、持久化往返」这些核心路径。**扩展有测试和没测试的差别，
在于你敢不敢改它** —— 改完之后跑一遍，就知道有没有破坏别的地方。

## 26.7 一个扩展的完整清单

把这一章的东西抽象一下，就是写任何扩展都可以照抄的清单：

| 需要什么 | 用什么 | 本指南章节 |
|---|---|---|
| 数据结构 | `cl-defstruct` / alist | 9.6 / 7.9 |
| 持久化 | `prin1` + `read` | 26.2 |
| 用户选项 | `defcustom` | 18 |
| 显示 | major mode + font-lock | 16 |
| 操作 | `interactive` 命令 + keymap | 13 / 14 |
| 状态关联 | 文本属性 / overlay | 11 |
| 扩展点 | hook | 17 |
| 后台任务 | timer / process | 20 / 21 |
| 健壮性 | `condition-case` + `unwind-protect` | 22 |
| 组织 | `provide` / `require` | 24 |
| 保证不坏 | `ert` | 25 |

---

上一章：[25 · 测试](25-tests.md)　｜　下一章：[27 · cons 单元与列表的内存模型](27-cons-cells.md)　｜　返回：[Emacs 扩展开发指南](README.md)
