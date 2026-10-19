# 18 · 可定制选项 defcustom

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/18-custom.el`

一个「能用」的扩展和一个「好用」的扩展，差别常常就在有没有把该暴露的东西做成 `defcustom`。

## 18.1 defgroup 与 defcustom

```elisp
(defgroup demo-timer nil
  "演示用的定时器功能。"
  :group 'tools
  :prefix "demo-timer-")

(defcustom demo-timer-interval 25
  "两次提醒之间的分钟数。"
  :type 'integer
  :group 'demo-timer)
```

`defcustom` 比 `defvar` 多了三样东西：

1. **`:type`** —— 告诉 customize 界面该显示成什么控件；
2. **`:group`** —— 归到哪个分组；
3. **`:set` / `:initialize`** —— 值变化时的回调。**这是 `defcustom` 最有价值的部分**：
   用户改配置时你能立刻做出反应（重设定时器、重建 buffer、刷新显示）。

```
11) 本示例共有 6 个自定义选项
```

## 18.2 :type 常用类型

```elisp
:type 'integer
:type 'string
:type 'boolean
:type '(choice (const :tag "关闭" nil) (const :tag "警告" warn) (const :tag "报错" error))
:type '(repeat string)
:type '(alist :key-type symbol :value-type string)
:type 'file
:type 'directory
:type 'face
```

```
9) demo-timer-interval 的 :type = integer
   它的标准值（未改过的默认值）= 25
```

## 18.3 【坑】defcustom 不会覆盖已有值

```
5) 手动 setq 成 50 之后: 50
```

和 `defvar` 一样 —— 变量已经有值了就不覆盖。这是**故意的**：用户设置过的东西不能被包升级重置。

## 18.4 【重点】setq 不触发 :set，customize-set-variable 才触发

这是本章最实用的一节，也是很多人踩过的坑：

```elisp
(defcustom demo-timer-label "默认"
  "..."
  :type 'string
  :set (lambda (sym val)
         (set-default sym val)              ; ← 一定要真的把值设上
         (setq demo-timer-applied (1+ demo-timer-applied))))  ; 再做副作用
```

```
6) 对比两种改法：
   改之前 applied = 0
   setq 之后 applied = 0（没有触发 :set）
    [:set 触发] demo-timer-label 变成 "走 customize"
   customize-set-variable 之后 applied = 1
7) custom-set-variables：
    [:set 触发] demo-timer-label 变成 "批量设置"
   applied = 2，当前值 = "批量设置"
```

| 改法 | 触发 `:set` 吗 | 用于 |
|---|---|---|
| `(setq demo-timer-label "x")` | **不会** | 内部代码临时改 |
| `(customize-set-variable 'demo-timer-label "x")` | 会 | 程序化地「像用户改配置一样」改 |
| `(custom-set-variables '(demo-timer-label "x"))` | 会 | Emacs 写进 custom-file 的形式 |
| customize 界面 | 会 | 用户手点 |

关键结论：**`defcustom` 的 `:set` 只保证「通过 customize 机制改」时被调用。**
如果你的代码里需要「改了选项就立刻生效」，要么用 `customize-set-variable`，
要么在改完之后显式调用生效函数。指望 `setq` 触发 `:set` 是不行的。

`:set` 函数里的 `set-default` 也不能忘 —— 忘了的话值根本没被设上，只有副作用发生了。

## 18.5 判断「是不是用户选项」

```elisp
(custom-variable-p 'demo-timer-interval)     ; → t
(custom-variable-p 'demo-timer-applied)      ; 普通 defvar → nil
```

```
8) demo-timer-interval 是用户选项吗: t
   普通 defvar 的: nil
```

相关函数：`custom-variable-type` 取类型定义（注意它需要 `custom` 已加载，
并且在字节编译时需要 `declare-function`，否则会报未定义警告）。

## 18.6 defface

```elisp
(defface demo-timer-face
  '((t :foreground "orange" :weight bold))
  "演示用的 face。"
  :group 'demo-timer)
```

```
10) face 定义好了: t
```

`defface` 的用法和 `defcustom` 类似，`(custom-set-faces ...)` 改它，`(facep 'xxx)` 判存在。
`'((t :foreground "orange"))` 里的 `t` 表示「所有终端类型都适用」（老式写法，
现在基本都写 `t`）。

写 face 时注意：**只设前景色**通常是最安全的做法，让用户主题的背景色透出来；
如果要设背景色，记得同时考虑深色/浅色主题。

## 18.7 打包建议

- 所有 `defcustom` **集中放在文件靠前的位置**，方便用户阅读和 `customize` 分组；
- 每个 `defcustom` 的 docstring 写清**取值范围和含义**（会显示在 customize 界面里）；
- `defgroup` 的 `:prefix` 让你的选项在 customize 里聚在一起；
- 不要用 `setq` 去改用户选项 —— 用 `customize-set-variable`。

---

上一章：[17 · hook](17-hooks.md)　｜　下一章：[19 · advice：不改源码改行为](19-advice.md)　｜　返回：[Emacs 扩展开发指南](README.md)
