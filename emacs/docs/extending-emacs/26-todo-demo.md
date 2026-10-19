# 26 · 完整示例：一个 todo 扩展

> 所属部分：第 6 部分 · 把一切串起来

> 示例：`examples/26-todo-demo.el`

前面的 25 章都是零件。这一章把零件拼成一个**可用的扩展**，并且展示真实开发里「一个功能需要哪几样东西配合」的完整清单。

## 26.1 这个扩展长什么样

一个记录待办的小工具，具备：

- 内存中的数据结构（plist + 一组访问函数）
- 持久化（`prin1` 写、`read` 读）
- 一个 major mode 来显示列表（`define-derived-mode` + 字体锁）
- 键盘操作（keymap + 交互式命令）
- 单元测试（`ert`）

## 26.2 配置：defcustom 与 defgroup

```elisp
;; 第 1 步：配置（defgroup + defcustom）
(defgroup demo-todo nil
  "mini todo 扩展的配置。"
  :group 'emacs
  :prefix "demo-todo-")

(defcustom demo-todo-file
  (expand-file-name "demo-todo.eld" temporary-file-directory)
  "待办数据的保存位置。"
  :type 'file
  :group 'demo-todo)

(defcustom demo-todo-archive-done nil
  "刷新时是否把已完成的条目移到列表末尾。"
  :type 'boolean
  :group 'demo-todo)
```

先写 `defgroup` 再写 `defcustom`（第 18 章）：所有用户可改的东西都从这儿出去，用户就能用 `M-x customize-group` 统一改，你的代码里也只有一个地方需要读配置。

## 26.3 数据结构与持久化

数据模型用 **plist**——一条待办就是 `(:title "..." :done nil :created <float>)`，配一组一行的访问函数：

```elisp
;; 第 2 步：数据模型
;; 用 plist 表示一条待办：(:title "..." :done nil :created <float>)
(defun demo-todo-make (title)
  "造一条标题为 TITLE 的待办。"
  (list :title title :done nil :created (float-time)))

(defun demo-todo-title (item) "取标题。" (plist-get item :title))
(defun demo-todo-done-p (item) "是否已完成。" (plist-get item :done))

(defun demo-todo-set-done (item done)
  "设置 ITEM 的完成状态，返回**新的** item。

【坑】plist-put 是破坏性的，但「修改第一个 key」时它可能返回一个
新的 list，所以必须接住返回值，不能指望原对象被就地改好。"
  (plist-put item :done done))

(defvar demo-todo-items nil
  "当前内存里的待办列表。")
```

为什么不直接用 `cl-defstruct`？因为**持久化要写进文件**：plist 是普通 list，`prin1` 写出来、`read` 读回来都还是 plist，不需要任何序列化代码。`cl-defstruct` 生成的结构体打印出来是 `#s(...)` 这种带类型信息的读法，读回来依赖结构定义仍然存在——换一版定义就可能读不进去。

持久化就两个函数：

```elisp
;; 第 4 步：持久化
;; 用 prin1 写、read 读，比手写解析省事得多。
(defun demo-todo-save ()
  "把待办写到 demo-todo-file，返回写入的条数。"
  (interactive)
  (with-temp-file demo-todo-file
    ;; 【坑】prin1 默认会受 print-length / print-level 限制，
    ;; 长列表会被截断成 "..." —— 写文件前必须把它们关掉。
    (let ((print-length nil)
          (print-level nil))
      (prin1 demo-todo-items (current-buffer))))
  (message "已保存 %d 条到 %s" (length demo-todo-items)
           (file-name-nondirectory demo-todo-file))
  (length demo-todo-items))

(defun demo-todo-load ()
  "从 demo-todo-file 读回待办，返回读到的条数。"
  (interactive)
  (setq demo-todo-items
        (if (file-exists-p demo-todo-file)
            (with-temp-buffer
              (insert-file-contents demo-todo-file)
              (goto-char (point-min))
              ;; 【安全】read 只解析数据结构、不执行代码，
              ;; 但读进来的东西仍然应当校验（这里只简单检查是不是 list）。
              (let ((data (read (current-buffer))))
                (if (listp data) data nil)))
          nil))
  (message "已读取 %d 条" (length demo-todo-items))
  (length demo-todo-items))
```

**`prin1` + `read` 是 Elisp 里最省事的数据持久化方式**：`prin1` 写出的文本能被 `read` 读回来，不需要自己写序列化/反序列化。文件名用 `.eld` 后缀是 Emacs 的惯例（「Emacs Lisp Data」）。内置的 `savehist` / `desktop` 都是这么做的。

两个必须记住的坑：

- **`print-length` / `print-level` 会截断输出**。它们的默认值是 `nil`，但用户的配置里可能设过（`M-x customize` 里就有这两项），一旦非 nil，`prin1` 就会把长列表写成 `(a b ...)`——数据**静默丢失**。写文件前用 `let` 关掉它们。
- **`prin1` 写出来的是「可读的 S 表达式」，`read` 也只做解析**——但读进来的东西仍然要校验（示例里只检查了 `listp`）。别拿 `read` 去读来源不可信的文件。

跑一遍往返：

```elisp
;; 用一个临时目录 + 固定文件名，别污染用户目录。
;; 【坑】make-temp-file 生成的文件名每次都不同；如果它被打印进输出，
;;      本示例的输出就不可复现了 —— 所以这里只让**父目录**是临时的，
;;      文件名固定成 demo-todo.eld。
;; demo-todo-file 是 defcustom（special 变量），let 能临时改写它。
(defvar demo-todo-temp-dir (make-temp-file "demo-todo-" t))
(defvar demo-todo-temp-file (expand-file-name "demo-todo.eld" demo-todo-temp-dir))
...
(princ "3) 存盘后清空内存，再读回来：\n")
(demo-call #'demo-todo-save)
(setq demo-todo-items nil)
(princ (format "   清空后总数 = %S\n" (demo-todo-count)))
(demo-call #'demo-todo-load)
(princ (format "   读回后总数 = %S，未完成 = %S\n"
               (demo-todo-count) (demo-todo-pending-count)))
(princ (format "   标题顺序 = %S\n"
               (mapcar #'demo-todo-title demo-todo-items)))
```

```text
3) 存盘后清空内存，再读回来：
    -> 已保存 3 条到 demo-todo.eld
   清空后总数 = 0
    -> 已读取 3 条
   读回后总数 = 3，未完成 = 2
   标题顺序 = ("回复邮件" "买咖啡" "写 Emacs 教程")
```

标题顺序是 `("回复邮件" "买咖啡" "写 Emacs 教程")`，而添加顺序是「写 Emacs 教程、买咖啡、回复邮件」——**正好反过来**。因为 `demo-todo-add` 用的是 `push`（往表头加）。这不是 bug，是选择：新待办显示在最上面。

> 【坑】`(demo-call #'...)` 是示例自己的包装：batch 模式下 `message` 写 **stderr**，而这个示例要求 stderr 干净。`demo-call` 用 `cl-letf` 临时把 `message` 换成往 stdout 写的版本。真实项目里不需要这一手。

## 26.4 major mode 与渲染

```elisp
;; parent 用 special-mode：自带只读、q 退出、g 刷新等一大堆便利。
(defvar demo-todo-font-lock-keywords
  '(("^\\[x\\] \\(.*\\)$" 1 'font-lock-comment-face)   ; 已完成 -> 灰掉
    ("^\\[ \\] \\(.*\\)$" 1 'font-lock-string-face))   ; 未完成 -> 正常高亮
  "demo-todo-mode 的高亮规则。")

(define-derived-mode demo-todo-mode special-mode "Demo-Todo"
  "待办列表的主模式。"
  ;; 【坑】交互模式下 global-font-lock-mode 会自动给「支持字体锁的 mode」打开
  ;; 它（font-lock-global-modes 默认 t，**没有 special-mode 例外**）。
  ;; 但 batch 下 (font-lock-mode 1) 会被 font-lock-mode 自己的守卫打回 nil
  ;; （守卫条件是 noninteractive 或 buffer 名以空格开头），
  ;; 所以本示例里真正把字上色的是 demo-todo-render 末尾的 font-lock-ensure。
  (setq font-lock-defaults '(demo-todo-font-lock-keywords t))
  (font-lock-mode 1)
  (setq-local revert-buffer-function (lambda (_ignore-auto _noconfirm)
                                       (demo-todo-refresh))))
```

渲染函数：

```elisp
(defun demo-todo-render ()
  "把 demo-todo-items 渲染进当前 buffer。"
  (let ((inhibit-read-only t))        ; special-mode 的 buffer 是只读的
    (erase-buffer)
    (if (null demo-todo-items)
        (insert "（还没有待办，按 a 添加）\n")
      (seq-do-indexed
       (lambda (item idx)
         ;; 【技巧】把下标存成文本属性，比「数行号」稳健得多：
         ;; 加个表头、排个序都不会错位。
         (insert (propertize
                  (format "[%s] %s\n"
                          (if (demo-todo-done-p item) "x" " ")
                          (demo-todo-title item))
                  'demo-todo-index idx)))
       demo-todo-items))
    (goto-char (point-min)))
  (font-lock-ensure))
```

```text
4) 渲染成 buffer 并检查高亮：
   buffer 内容:
[ ] 回复邮件
[x] 买咖啡
[ ] 写 Emacs 教程
   第 1 行（未完成的回复邮件）标题的 face = font-lock-string-face
   第 2 行（已完成的买咖啡）标题的 face = font-lock-comment-face
   第 2 行的下标属性 = 1
```

四处值得注意：

1. **parent 用 `special-mode`** —— 白拿只读、`q` 退出、`g` 刷新、空格翻页等一大堆便利。代价是 buffer 只读，所以渲染时要 `(let ((inhibit-read-only t)) ...)`。
2. **font-lock 的实际生效路径是 `font-lock-ensure`**，不是 `(font-lock-mode 1)`。后者在 batch 下会被 `font-lock-mode` 自己的守卫打回 `nil`（守卫条件是 `noninteractive` 或 buffer 名以空格开头）。交互模式下 `global-font-lock-mode` 会自动开——`font-lock-global-modes` 默认是 `t`，**并没有「special-mode 例外」这回事**（第 16.3 节纠正过这个常见误解）。
3. **每个列表项都带一个「下标」文本属性**（`demo-todo-index`，由 `demo-todo--index-at-point` 读回），这样命令就知道「光标在哪一项上」。这是「行列表」型 mode 的标准做法——用文本属性把「显示」和「数据」关联起来，而不是靠数行号（加个表头、排个序都不会错位）。
4. `revert-buffer-function` 设成「重新渲染」——于是 `M-x revert-buffer` 在这个 mode 里就是刷新列表，符合用户直觉。

## 26.5 键盘操作

```elisp
(defvar demo-todo-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "a") #'demo-todo-add)
    (define-key map (kbd "RET") #'demo-todo-toggle-at-point)
    (define-key map (kbd "SPC") #'demo-todo-toggle-at-point)
    (define-key map (kbd "d") #'demo-todo-delete-at-point)
    (define-key map (kbd "g") #'demo-todo-refresh)
    map)
  "demo-todo-mode 的按键表。")
```

命令那一层：

```elisp
(defun demo-todo-toggle-at-point ()
  "切换光标所在行的完成状态。"
  (interactive)
  (let ((idx (demo-todo--index-at-point)))
    (unless idx
      (user-error "光标不在待办行上"))
    (demo-todo-toggle-at idx)
    (demo-todo-refresh)
    (forward-line 0)))
```

注意它读的是**下标属性**而不是行号：

```elisp
(defun demo-todo--index-at-point ()
  "返回光标所在行的待办下标，不在待办行上则返回 nil。"
  (get-text-property (line-beginning-position) 'demo-todo-index))
```

在 batch 里模拟一遍键盘操作（跳到第 3 行、按 `RET`；回到第 1 行、按 `d`）：

```elisp
(princ "5) 在列表 buffer 里用键盘命令操作：\n")
(with-temp-buffer
  (demo-todo-mode)
  (demo-todo-render)
  (goto-char (point-min))
  (forward-line 2)                        ; 跳到第 3 行「写 Emacs 教程」
  (demo-call #'demo-todo-toggle-at-point) ; 标记完成
  (princ (format "   切换后未完成 = %S\n" (demo-todo-pending-count)))
  (goto-char (point-min))                 ; 回到第 1 行「回复邮件」
  (demo-call #'demo-todo-delete-at-point) ; 删掉它
  (princ (format "   删除后总数 = %S，剩下的 = %S\n"
                 (demo-todo-count)
                 (mapcar #'demo-todo-title demo-todo-items))))
```

```text
5) 在列表 buffer 里用键盘命令操作：
    -> 完成：写 Emacs 教程
    -> 共 3 条，未完成 1 条
   切换后未完成 = 1
    -> 已删除：回复邮件
    -> 共 2 条，未完成 0 条
   删除后总数 = 2，剩下的 = ("买咖啡" "写 Emacs 教程")
```

模式是「命令改数据 → 重新渲染 → 光标回到原来的项」。这是「数据结构是真相、buffer 只是视图」的思路 —— 比「直接在 buffer 里改文本再解析回来」健壮得多，也是**大多数成熟 mode 的做法**。

`demo-todo-toggle-at-point` 末尾的 `(forward-line 0)` 就是「光标回到这一行的行首」——重渲染后 point 位置会乱，显式归位才不会跳。

## 26.6 清理已完成的条目

```elisp
(defun demo-todo-clear-done ()
  "清掉所有已完成的条目，返回清掉的数量。"
  (interactive)
  (let ((before (length demo-todo-items)))
    (setq demo-todo-items
          (seq-remove #'demo-todo-done-p demo-todo-items))
    (let ((removed (- before (length demo-todo-items))))
      (message "清掉了 %d 条已完成" removed)
      removed)))
```

```text
6) 清理已完成：
    -> 清掉了 2 条已完成
   清理后总数 = 0
8) 临时数据文件已清理: t
```

## 26.7 单元测试

```elisp
;; 第 7 步：单元测试（静默运行，理由见 25-tests.el）
(ert-deftest demo-todo-test-add-and-count ()
  (let ((demo-todo-items nil))
    (demo-todo-add "a")
    (demo-todo-add "b")
    (should (= 2 (demo-todo-count)))
    (should (= 2 (demo-todo-pending-count)))))

(ert-deftest demo-todo-test-toggle ()
  (let ((demo-todo-items (list (demo-todo-make "x"))))
    (should-not (demo-todo-done-p (nth 0 demo-todo-items)))
    (demo-todo-toggle-at 0)
    ;; 【坑】这里必须重新 nth 一次去取 —— plist-put 返回的是新对象
    (should (demo-todo-done-p (nth 0 demo-todo-items)))
    (should (= 0 (demo-todo-pending-count)))))

(ert-deftest demo-todo-test-save-load-roundtrip ()
  (let ((demo-todo-file (make-temp-file "demo-todo-test-" nil ".eld"))
        (demo-todo-items (list (demo-todo-make "持久化测试"))))
    (unwind-protect
        (progn
          (demo-todo-save)
          (setq demo-todo-items nil)
          (demo-todo-load)
          (should (= 1 (demo-todo-count)))
          (should (equal "持久化测试" (demo-todo-title (nth 0 demo-todo-items)))))
      (when (file-exists-p demo-todo-file)
        (delete-file demo-todo-file)))))

;; 【坑】测试用例是**直接**调用函数的，不走 demo-call，
;;    所以函数里的 message 会漏到 stderr。跑测试时要把 message 静音。
(let* ((stats (cl-letf (((symbol-function 'message) (lambda (&rest _args) nil)))
                (ert-run-tests "demo-todo-test" (lambda (&rest _args) nil))))
       (total (ert-stats-total stats))
       (bad (ert-stats-completed-unexpected stats)))
  (princ (format "7) 单元测试：共 %S 个用例，失败 %S 个\n" total bad)))
```

```text
7) 单元测试：共 4 个用例，失败 0 个
```

三个要点：

- 每个用例都用 `let` 把 `demo-todo-items` / `demo-todo-file` **局部化**，所以用例之间互不影响（第 25.5 节的动态绑定）。
- `demo-todo-test-toggle` 里那句「必须重新 `nth` 一次」是 `plist-put` 的真实坑：`demo-todo-set-done` 返回的是新对象，不接住就白改。
- 持久化测试用 `unwind-protect` 保证临时文件一定被删（第 22.6 节）。
- 跑测试时要把 `message` 静音——用例是直接调函数的，不走 `demo-call`，消息会漏到 stderr。

测试覆盖了「增删改、持久化往返」这些核心路径。**扩展有测试和没测试的差别，在于你敢不敢改它** —— 改完之后跑一遍，就知道有没有破坏别的地方。

## 26.8 一个扩展的完整清单

把这一章的东西抽象一下，就是写任何扩展都可以照抄的清单：

| 需要什么 | 用什么 | 本指南章节 |
|---|---|---|
| 数据结构 | plist / `cl-defstruct` / alist | 9.6 / 7.9 |
| 持久化 | `prin1` + `read`（`.eld`） | 26.3 |
| 用户选项 | `defcustom` + `defgroup` | 18 |
| 显示 | major mode + font-lock | 16 |
| 操作 | `interactive` 命令 + keymap | 13 / 14 |
| 状态关联 | 文本属性 / overlay | 11 |
| 扩展点 | hook | 17 |
| 后台任务 | timer / process | 20 / 21 |
| 健壮性 | `condition-case` + `unwind-protect` | 22 |
| 组织 | `provide` / `require` | 24 |
| 保证不坏 | `ert` | 25 |

发布到 MELPA 之前还差这些（第 24.11 节）：

```text
- 文件头：;;; demo-todo.el --- 一句话简介 -*- lexical-binding: t; -*-
- 结尾：(provide 'demo-todo) 和 ;;; demo-todo.el ends here
- M-x checkdoc：逐条检查 docstring 和文件头
- M-x package-lint：检查命名、依赖、autoload cookie
- 一个 README 和一份 NEWS
- 版本号 + Package-Requires: ((emacs "29.1"))
```

## 26.9 坑位清单

1. 用 `cl-defstruct` 存要持久化的结构 —— 打印成 `#s(...)`，读回来依赖结构定义；普通 plist 更稳。
2. `prin1` 写文件不关 `print-length` / `print-level` —— 长列表被静默截断成 `...`，数据丢了都不知道。
3. `read` 读进来的数据不校验 —— 至少检查类型（示例里用 `listp`）。
4. 以为 `plist-put` 一定会就地改好 —— 改第一个 key 时它可能返回新 list，必须接住返回值。
5. `special-mode` 的 buffer 是只读的 —— 渲染时要 `(let ((inhibit-read-only t)) ...)`。
6. 以为「special-mode 不会自动开 font-lock」—— 没有这个例外；batch 下真正的原因是 `noninteractive` 守卫，用 `font-lock-ensure` 解决。
7. 用「数行号」定位列表项 —— 加表头/排序就错位；用文本属性存下标。
8. 重渲染后不管 point —— 光标乱跳；显式 `(forward-line 0)` 之类归位。
9. 把随机临时文件名打印进输出 —— 输出不可复现；只让父目录随机，文件名固定。
10. 测试用例之间共享全局状态 —— 用 `let` 动态绑定局部化；临时文件用 `unwind-protect` 清理。
11. 忘了 `message` 在 batch 下写 stderr —— 要么像 `demo-call` 那样转发，要么跑测试时静音。

---

上一章：[25 · 测试](25-tests.md)　｜　下一章：[27 · cons 单元与列表的内存模型](27-cons-cells.md)　｜　返回：[Emacs 扩展开发指南](README.md)
