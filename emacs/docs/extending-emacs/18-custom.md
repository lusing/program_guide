# 18 · 可定制选项 defcustom

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/18-custom.el`

一个「能用」的扩展和一个「好用」的扩展，差别常常就在有没有把该暴露的东西做成 `defcustom`。

## 18.1 defgroup 与 defcustom

```elisp
(defgroup demo-timer nil
  "演示扩展的配置。"
  :group 'emacs
  :prefix "demo-timer-")     ; :prefix 只是约定声明，方便 checkdoc 检查命名

(defcustom demo-timer-interval 25
  "专注计时的默认时长，单位是分钟。"
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

`:type` 决定 customize 界面长什么样。示例里用到的几种真身：

```elisp
:type 'integer
:type 'sexp
:type '(choice (const :tag "关闭" nil)
               (const :tag "剩余时间" remaining)
               (const :tag "百分比" percent))
:type '(integer :value 10)
:type '(choice (const :tag "不响" nil)
               (file :must-match t :tag "音频文件"))
```

```
9) demo-timer-interval 的 :type = integer
   它的标准值（未改过的默认值）= 25
```

常用类型速查：

| 类型 | 界面 |
|---|---|
| `integer` / `number` / `string` / `boolean` / `symbol` | 对应的输入控件 |
| `(choice ...)` | 下拉/单选 |
| `(const SYM)` | 固定值，配合 `choice` 用 |
| `(repeat ...)` | 列表，可增删元素 |
| `(alist :key-type ... :value-type ...)` | 键值对列表 |
| `file` / `directory` | 带补全的路径 |
| `face` / `color` | face 或颜色 |
| `sexp` | 任意 Lisp 表达式（兜底用） |

> 【坑】示例里的 `demo-timer-sound` 是**故意写错的示范**：默认值写成了
> `'(choice (const :tag "不响" nil) file)`（一个 choice 形式的数据结构），
> 而 `:type` 却是 `sexp`。正确写法是「**默认值是数据，`:type` 是它的类型描述**」——
> 看 `demo-timer-file`：默认值 `nil`（数据），`:type` 是 `(choice (const ...) (file ...))`。

## 18.3 【坑】defcustom 不会覆盖已有值

```
5) 手动 setq 成 50 之后: 50
```

和 `defvar` 一样 —— 变量已经有值了就不覆盖。这是**故意的**：用户设置过的东西不能被包升级重置。

## 18.4 【重点】setq 不触发 :set，customize-set-variable 才触发

这是本章最实用的一节，也是很多人踩过的坑：

```elisp
(defcustom demo-timer-label "Focus"
  "计时器的显示名。"
  :type 'string
  :set (lambda (sym value)
         (set-default sym value)
         (setq demo-timer-applied (1+ demo-timer-applied))
         (princ (format "    [:set 触发] %s 变成 %S\n" sym value)))
  :initialize #'custom-initialize-default
  :group 'demo-timer)
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
(princ (format "8) demo-timer-interval 是用户选项吗: %S\n"
               (and (custom-variable-p 'demo-timer-interval) t)))
(princ (format "   普通 defvar 的: %S\n"
               (and (custom-variable-p 'demo-timer-applied) t)))
```

```
8) demo-timer-interval 是用户选项吗: t
   普通 defvar 的: nil
```

> 【坑】`custom-variable-p` 返回的**不是 `t`**，而是类型表达式本身，当成布尔用之前记得
> `(and ... t)` 转一下。
>
> 【坑】想取类型定义，标准函数 `custom-variable-type` 在裸 `emacs -Q` 下**并不在内存里**
> （`custom` 库只是按需自动加载），直接调用会 `void-function`，字节编译还会告
> "not known to be defined"。示例因此改用属性直读
> `(get 'demo-timer-interval 'custom-type)` —— 默认值同理存在 `standard-value` 属性里，
> 而且它是个**待求值的表达式的列表**，要 `(eval (car ...))` 才是真值。

## 18.6 defface

```elisp
(defface demo-timer-face
  '((t :inherit warning :weight bold))
  "计时器显示用的 face。"
  :group 'demo-timer)
```

```
10) face 定义好了: t
```

`defface` 的用法和 `defcustom` 类似，`(custom-set-faces ...)` 改它，`(facep 'xxx)` 判存在。
`'((t :inherit warning))` 里的 `t` 是「所有显示类型都适用」的通配规格，后面的 plist 是属性。

写 face 时注意：**优先 `:inherit` 而不是硬编码颜色**，让用户主题透出来；
非要设颜色时，记得同时考虑深色/浅色主题（用 `((class color) (min-colors 88))` 之类的规格分情况）。

## 18.7 打包建议

- 所有 `defcustom` **集中放在文件靠前的位置**，方便用户阅读和 `customize` 分组；
- 每个 `defcustom` 的 docstring 写清**取值范围和含义**（会显示在 customize 界面里）；
- `defgroup` 的 `:prefix` 让你的选项在 customize 里聚在一起；
- 不要用 `setq` 去改用户选项 —— 用 `customize-set-variable`。

---

上一章：[17 · hook](17-hooks.md)　｜　下一章：[19 · advice：不改源码改行为](19-advice.md)　｜　返回：[Emacs 扩展开发指南](README.md)
