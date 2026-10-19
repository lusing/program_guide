# 17 · hook

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/17-hooks.el`

hook 是「在某个事件发生时，按顺序跑一串函数」的机制。它是**无侵入式扩展**的关键 ——
你不需要改别人的代码，只要往他的 hook 里加函数。

## 17.1 hook 就是一个函数列表

```elisp
(add-hook 'demo-hook #'demo-first)
(remove-hook 'demo-hook #'demo-first)
(run-hooks 'demo-hook)
```

```
4) hook 里装的是符号: (demo-first)
```

约定：hook 变量以 `-hook` 结尾，里面装的是**函数符号**而不是 lambda。

> 【坑】**永远不要把 lambda 直接加进 hook**。原因有二：`remove-hook` 比的是对象身份，
> 匿名 lambda 每次都是新对象，加进去就摘不掉；而且 `run-hooks` 对 lambda 的处理在不同版本/是否
> 字节编译下有所不同。**具名函数是唯一正确的写法。**

## 17.2 【坑】默认是插到最前面

```elisp
(add-hook 'demo-hook #'demo-first)
(add-hook 'demo-hook #'demo-second)
```

```
1) 按加入顺序（默认插在最前面，所以后加的先跑）：
    [second] 执行
    [first] 执行
2) 传 t 之后（后加的后跑）：
    [first] 执行
    [second] 执行
```

`add-hook` 默认把新函数**插到列表最前面**，所以执行顺序是**后加的先生效** —— 这和「按加入顺序」
的直觉相反。想按加入顺序执行，第 3 个参数传 `t`（append）：

```elisp
(add-hook 'demo-hook #'demo-first)
(add-hook 'demo-hook #'demo-second t)     ; 追加到末尾
```

## 17.3 add-hook 是幂等的

```
3) 加了两次，hook 里只有 1 个函数
```

重复 `add-hook` 同一个函数不会加两次。但**这有个副作用**：如果同一个函数被两个包用不同的
「顺序参数」加过，第二次的调用只改顺序不加函数，结果可能和预期不同。

## 17.4 带参数的 hook（abnormal hook）

普通 hook 里的函数**不接收参数**，`run-hooks` 只是无参调用它们。要传参得用 abnormal hook：

```elisp
;; 名字以 -functions 结尾（不是 -hook）的通常是 abnormal hook
(add-hook 'demo-save-functions #'demo-on-save)

(defun demo-on-save (filename)
  (princ (format "    [on-save] 保存了 %S\n" filename)))

(run-hook-with-args 'demo-save-functions "/tmp/a.txt")
```

```
    [on-save] 保存了 "/tmp/a.txt"
```

命名约定：

| 后缀 | 含义 |
|---|---|
| `-hook` | 普通 hook，函数无参 |
| `-functions` | abnormal hook，函数接收参数 |
| `-function` | 单个函数（不是列表） |

## 17.5 直到成功 / 直到失败

```
6) until-success 传 'b: "B 接下了"
   until-failure 传 'b: nil
```

`run-hook-with-args-until-success` / `-until-failure` 会给每个函数传参，**遇到第一个返回非 nil
（或 nil）的就停下**。适合做「谁来负责处理这件事」的分派 ——
比如 `find-file-not-found-functions` 就是：第一个成功打开的包负责到底，后面的不再跑。

## 17.6 精确控制顺序：DEPTH

```elisp
(add-hook 'demo-hook #'demo-first  -10)    ; 数字更小的更早跑
(add-hook 'demo-hook #'demo-second 10)
```

```
7) 按 depth 排序后: (demo-second demo-first)
```

第 3 个参数是整数 `DEPTH`（-100..100），更小的先跑。这比 `append` 更精细，适合
「我的扩展必须在某类包之前/之后初始化」的场景。

## 17.7 buffer 局部 hook

```elisp
(add-hook 'demo-hook #'demo-first nil t)    ; 第 4 个参数 t = 只对当前 buffer 生效
```

```
8) buffer A 里的 hook: (t demo-first)
   buffer B 里的 hook: (demo-second demo-first)（不受影响）
```

第 4 个参数 `LOCAL` 为 `t` 时，hook 只加在当前 buffer 上。**这是写 mode / minor mode 时必须
注意的**：mode 是 buffer 局部的，它装的 hook 也应该局部，否则会互相干扰。

Buffer A 的 hook 里出现了 `t`，这是 buffer-local 绑定在默认值上的标记 —— 打印出来看到
「列表里混了个 `t`」是正常的。

## 17.8 「一次性」hook

```elisp
(let ((demo-hook (list #'demo-temp)))     ; 动态绑定覆盖 hook 变量
  (demo-run-temp-hook))
;; 出了 let 自动恢复
```

```
9) 临时替换 hook：
    [临时] 只跑这一次
   退出 let 后恢复为: (demo-first)
```

利用 `let` 对 special 变量的动态绑定（第 3.4 节）：`let` 期间 hook 里只有你想跑的那个函数，
退出后自动恢复。这比「加进去再摘掉」安全得多（中途出错也不会漏摘）。

## 17.9 常用内置 hook

```
10) find-file-hook 里现在有 2 个函数
```

| hook | 时机 |
|---|---|
| `find-file-hook` | 打开文件之后 |
| `before-save-hook` / `after-save-hook` | 保存前 / 后 |
| `kill-buffer-hook` | 关闭 buffer 前 |
| `after-change-functions` | buffer 内容变化后 |
| `post-command-hook` | 每条命令之后 |
| `prog-mode-hook` / `text-mode-hook` | 进入对应 mode 时 |
| `window-configuration-change-hook` | 窗口布局变化 |
| `emacs-startup-hook` / `after-init-hook` | 启动完成后 |

## 17.10 【坑】高频 hook

```
11) post-command-hook 和 after-change-functions 每次击键都会跑
```

这两个 hook **每次按键都跑**。在里面做重活会立刻让 Emacs 卡顿。如果确实需要，
用定时器延后（第 21 章的空闲定时器）或者加节流。

---

上一章：[16 · major mode](16-major-mode.md)　｜　下一章：[18 · 可定制选项 defcustom](18-custom.md)　｜　返回：[Emacs 扩展开发指南](README.md)
