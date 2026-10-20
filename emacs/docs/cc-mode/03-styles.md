# 03 · 风格系统：c-default-style、内置风格与自定义风格

第 2 章把 `c-offsets-alist` 的七种 offset 形态讲透了。但如果每个 CC Mode 用户都要从零写一张 50+ 条的 offset 表，这套系统就没人用了。**风格（style）**就是 CC Mode 给出的「预设 offset 表 + 相关变量」打包——你选一个风格、再在它基础上做少量覆盖，就得到自己想要的缩进。

本章把风格系统讲透：风格是什么数据结构、`c-default-style` 怎么决定新 buffer 用哪个风格、10 个内置风格各自长什么样、怎么在 init/hook/file-local 不同层覆盖、怎么定义自己的风格、怎么让 CC Mode 从已有代码**反推**风格。

## 3.1 风格是「一组变量的预设值」

CC Mode 的**风格变量（style variables）**一共 16 个（本机实测 `c-style-variables` 的值）：

```elisp
(c-basic-offset                  c-comment-only-line-offset
 c-indent-comment-alist          c-indent-comments-syntactically-p
 c-block-comment-prefix          c-comment-prefix-regexp
 c-doc-comment-style             c-cleanup-list
 c-hanging-braces-alist          c-hanging-colons-alist
 c-hanging-semi&comma-criteria   c-backslash-column
 c-backslash-max-column          c-special-indent-hook
 c-label-minimum-indentation     c-offsets-alist)
```

风格就是「这 16 个变量的一组预设值」。`c-style-alist` 是风格注册表——一个 alist，key 是风格名（字符串），value 是「变量名 → 值」的 alist。

本机实测 `c-style-alist` 的全部 key（CC Mode 5.35.2）：

```text
gnu  k&r  bsd  stroustrup  whitesmith  ellemtel  linux  python  java  awk
```

**10 个内置风格**。每个风格通常只设置 16 个变量里的几个——风格是**增量层**，没设置的变量用 CC Mode 的默认值。这是关键：换风格不是「清空再装」，是「在默认值上叠一层」。

## 3.2 风格变量有两种：普通变量 vs 特殊的 hook

16 个变量里 16 个是**普通变量**——`c-set-style` 切换风格时直接 `setq`。但 `c-special-indent-hook` 是**特殊**的：风格只能**往上加函数、不能删除**——你 `c-set-style` 换风格时，旧风格加进 `c-special-indent-hook` 的函数不会被清掉，新风格的函数继续往上叠。这条规则手册第 6.2 节明确写了，实测也确认。

为什么这样设计？因为 `c-special-indent-hook` 上的函数通常是用户/其它包加的「缩进后收尾」逻辑（比如第 2 章 2.5 的 `my-extra-indent`），不属于任何具体风格——换风格时把用户的函数抹掉就反直觉了。

## 3.3 `c-default-style`：新 buffer 用哪个风格

`c-default-style` 决定**新打开的 CC Mode buffer 默认用哪个风格**。它的值有三种形态（手册第 6.1 节）：

**形态一：一个风格名（字符串）**

```elisp
(setq c-default-style "linux")
;; 所有 CC Mode buffer（c-mode/c++-mode/java-mode/...）都用 linux
```

**形态二：按 mode 映射的 alist**

```elisp
(setq c-default-style '((java-mode . "java")
                        (awk-mode  . "awk")
                        (c-mode    . "bsd")
                        (c++-mode  . "stroustrup")
                        (other     . "gnu")))
;; 每种 mode 用不同风格；other 是 fallback
```

**形态三：nil**

```elisp
(setq c-default-style nil)
;; 用 "gnu"（CC Mode 的硬编码默认）
```

本机实测：GNU Emacs 31.1 自带的 CC Mode 5.35.2 里，`c-default-style` 的默认值是：

```elisp
((java-mode . "java")
 (awk-mode  . "awk")
 (other     . "gnu"))
```

即：Java 文件用 `java` 风格、AWK 文件用 `awk` 风格、其它所有 CC Mode buffer 用 `gnu` 风格。所以你不配置任何东西，新 C buffer 就是 gnu 风格。

## 3.4 内置风格速览

先看每个风格的 `c-basic-offset`（本机实测，从 `c-style-alist` 直接读出）：

| 风格 | c-basic-offset | 备注 |
|---|---|---|
| gnu | 2 | GNU 项目官方风格 |
| k&r | 5 | Kernighan & Ritchie 经典 |
| bsd | 8 | BSD 内核风格 |
| stroustrup | 4 | Bjarne Stroustrup 的 C++ 风格 |
| whitesmith | 4 | Whitesmith 出版社风格 |
| ellemtel | 3 | Ellemtel 实验室风格 |
| linux | 8 | Linux 内核风格（tab 缩进） |
| python | 8 | CPython 解释器源码风格 |
| java | 4 | Java 标准风格 |
| awk | 4 | AWK 源码风格 |

注意几个**反直觉**的点：

- `k&r` 的 `c-basic-offset` 是 **5** 不是 4——这是历史原因，K&R 原书用 5 空格缩进。
- `bsd` 和 `linux` 的 `c-basic-offset` 都是 8，但**它们不是同一个风格**——bsd 用空格、linux 用 tab（`indent-tabs-mode`），且其它变量差异很大。
- `python` 不是给 Python 语言用的——它是给 **CPython 解释器的 C 源码**用的风格（Python 语言本身不用 CC Mode）。

### 一段代码在各风格下的真实缩进

本机实测：把同一段 C 代码在不同风格下 `c-indent-region`，得到：

```text
=== gnu (c-basic-offset=2) ===
int add(int a, int b) {
  if (a > b) {
    return a;
  } else {
    return b;
  }
}

=== linux (c-basic-offset=8) ===
int add(int a, int b) {
	if (a > b) {
		return a;
	} else {
		return b;
	}
}
```

**这两个的差异几乎只有 `c-basic-offset`**（2 vs 8）——因为这段代码全是块首语句（`statement-block-intro`），所有风格的这个 symbol 都是 `+`（一个 c-basic-offset）。差异要在**续行**、**case 标签**、**类访问标号**、**参数列表**这些「非块首」场景才显现。

下面这段能拉开差距：

```text
=== gnu (c-basic-offset=2) ===
void f(int x) {
  switch (x) {
  case 1:
    foo();
    break;
  }
}

=== ellemtel (c-basic-offset=3) ===
void f(int x) {
   switch (x) {
      case 1:
	 foo();
	 break;
   }
}
```

差异就在 `case-label` 一个 symbol：gnu 是 `0`（case 顶到 switch 那列）、ellemtel 是 `+`（case 缩进一层，cbo=3 所以是 3 列）。ellemtel 还把 `access-label`（C++ `public:`/`private:`）设成 `-`（往回缩一层）。注意 ellemtel 的 `case 1:` 下面是 tab——这是 `c-basic-offset=3` 时 tab 对齐的效果。

### 各风格的关键差异（本机实测）

把 10 个风格在 `c-style-alist` 里的真实值摊开，挑出最有区分度的几列：

| 风格 | substatement-open | case-label | access-label | indent-tabs-mode | c-cleanup-list |
|---|---|---|---|---|---|
| gnu | `+` | 0 (默认) | `-` | nil | nil |
| k&r | `0` | 0 (默认) | `-` | nil | nil |
| bsd | `0` | 0 (默认) | `-` | nil | nil |
| stroustrup | `0` | 0 (默认) | `-` | nil | nil |
| whitesmith | `+` | 0 (默认) | `-` | nil | nil |
| ellemtel | `0` | `+` | `-` | nil | nil |
| linux | `0` | 0 (默认) | `-` | **t** | `(brace-else-brace)` |
| python | `0` | 0 (默认) | 0 (默认) | **t** | nil |
| java | `+` | 0 (默认) | `0` | nil | nil |
| awk | `0` | 0 (默认) | 0 (默认) | nil | nil |

**怎么读这张表**：

- `substatement-open`：`+` 表示「`if`/`while` 后面的 `{` 单独一行且缩进一层」（gnu/whitesmith/java 风格）；`0` 表示「`{` 跟 `if` 同列」（k&r/bsd/stroustrup/linux 风格）。
- `case-label`：gnu 风格没显式设，走 CC Mode 默认 `0`；ellemtel 显式设 `+`。
- `access-label`：gnu/k&r/bsd/stroustrup/whitesmith/ellemtel/linux 都是 `-`（`public:` 往回缩一层）；java 是 `0`（不缩）；python/awk 没设（默认 `0`）。
- `indent-tabs-mode`：只有 linux 和 python 在风格定义里显式设了 `t`（tab 缩进），其它风格没设、用 Emacs 默认值（默认 `nil` = 空格缩进；如果你全局改过 `indent-tabs-mode`，结果会不同）。
- `c-cleanup-list`：只有 linux 设了 `brace-else-brace`——输入 `} else {` 时自动把 `else` 前后的空格清掉。

### whitesmith 风格：一个「全自定义」的样本

whitesmith 是 10 个内置风格里**唯一一个几乎重写了所有 offset** 的风格——其它风格只改几个 symbol，whitesmith 改了 30+ 个。它的签名是「`{` 单独一行、且缩进到块内容那列」：

```text
int add(int a, int b)
    {
    int tmp = a;
    if (a > b)
	{
	return a;
	}
    return tmp;
    }
```

（whitesmith 风格把 `defun-open` 设成 `+`、`defun-close` 设成 `c-lineup-whitesmith-in-block`、`defun-block-intro` 设成 `(add c-lineup-whitesmith-in-block c-indent-multi-line-block)`……一整套互相配合的 line-up 函数。注意它用 tab 字符缩进——`{` 是一个 tab = 4 列（`c-basic-offset=4`），块内容也是 tab。）

这个风格是「CC Mode 的 offset 系统能表达力有多强」的活广告——但也正因如此，**不要**在它基础上做增量修改；要 whitesmith 就用 whitesmith，要改就从头定义自己的风格。

## 3.5 交互式切换风格：`C-c .`

`C-c .`（`c-set-style`）在 buffer 里现场换风格。minibuffer 提示输入风格名，有补全。

**关键细节**：`c-set-style` **不会自动重排已有代码**——它只改 buffer-local 变量。已有代码要重新 `TAB` 或 `C-M-\`（`indent-region`）才按新风格重排。实测确认：

```text
M-x c-set-style RET linux RET   → mode line 风格指示变了
                                但代码缩进没变
C-x h C-M-\                     → 全选 + indent-region，代码按 linux 重排
```

## 3.6 在 init/hook 里配风格

### 方法 1：顶层 `setq`（影响所有 CC Mode buffer）

```elisp
(setq c-default-style "linux"
      c-basic-offset 4)
```

这是「全局默认」——所有 CC Mode buffer 都用 linux 风格、所有风格的 c-basic-offset 都被改成 4（注意：`c-basic-offset` 是**变量**不是风格的一部分，setq 它影响所有风格）。

### 方法 2：hook 里的 `c-set-style` + `c-set-offset`

```elisp
(add-hook 'c-mode-hook
          (lambda ()
            (c-set-style "bsd")           ; 这个 buffer 用 bsd
            (c-set-offset 'case-label '+) ; 但 case 缩进一层
            (c-set-offset 'substatement-open 0)))
```

`c-set-offset` 在 hook 里是「从当前风格再覆盖一个 symbol」——这是**最常用**的定制方式。第 2 章 2.3 讲过 `c-set-offset` 的两个语义：改 buffer-local 值、新增或替换条目。

### 方法 3：自定义风格 + `c-default-style` 按 mode 映射

```elisp
(c-add-style "my-style"
             '("bsd"                      ; 继承 bsd
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)
                                   (substatement-open . 0)))))
(setq c-default-style '((c-mode . "my-style")
                        (c++-mode . "my-style")
                        (other . "gnu")))
```

`c-add-style` 第一个参数是风格名（字符串），第二个参数是风格定义。风格定义是 alist，key 是变量名（**带** `c-` 前缀的符号，比如 `c-basic-offset`），value 是值。

**继承**：风格定义的第一个元素可以是另一个风格名（字符串），表示「从这个风格继承、后面的条目覆盖它」。上面 `"bsd"` 就是继承 bsd。

**实测验证**：

```elisp
(c-add-style "my-style"
             '("bsd"
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)))))
(with-temp-buffer
  (c-mode)
  (c-set-style "my-style")     ;; 注意：不要传第二个参数 t
  (princ c-basic-offset))      ;; → 4（继承 bsd 但被覆盖）
```

**注意 `c-set-style` 的第二个参数**：`(c-set-style "name" t)` 里的 `t` 表示「dry-run」——只返回风格的 alist 值、**不实际应用**到 buffer。这是源码级行为，手册没明说。要真正切换风格，用 `(c-set-style "name")` 或交互式 `M-x c-set-style`。

### 方法 4：File Style（文件级风格）

在文件第一行或最后一行写：

```c
/* -*- c-file-style: "bsd"; -*- */
```

Emacs 打开这个文件时会自动切到 bsd 风格。`c-file-style` 是 CC Mode 的 file-local 变量。

### 方法 5：File Local Variables（文件级变量）

更通用的 file-local 写法：

```c
/* Local Variables: */
/* c-basic-offset: 4 */
/* c-file-style: "bsd" */
/* End: */
```

### 方法 6：Directory Local Variables（目录级）

`.dir-locals.el`：

```elisp
((c-mode . ((c-file-style . "bsd")
            (c-basic-offset . 4))))
```

这个目录（及子目录）下所有 C 文件都用 bsd + cbo=4。

## 3.7 配置优先级：谁覆盖谁

六种方法同时存在时，谁赢？本机实测（第 0 章 0.5 节的四层优先级，这里把 file style 和 file local 加进来）：

```
Style (c-default-style / c-set-style)
  < File Style (c-file-style)
  < top-level setq / customize
  < Hook (c-mode-hook 里的 c-set-offset / c-set-style)
  < File Local Variables (含 c-file-style / c-basic-offset 等)
```

**记忆口诀**：越「局部」的越优先。buffer 自己的 file-local 最优先；hook 是「打开 buffer 时跑」，比顶层 setq 晚；顶层 setq 比 `c-default-style` 晚（因为 `c-default-style` 在 mode 初始化时读，setq 在那之后）。

实测验证：

```elisp
;; init 里
(setq c-basic-offset 4)
(add-hook 'c-mode-hook (lambda () (setq c-basic-offset 8)))
;; 打开一个 .c 文件（无 file-local）
;; 结果：c-basic-offset = 8（hook 赢）
```

## 3.8 自定义风格：`c-add-style` 详解

`c-add-style` 的完整签名：

```elisp
(c-add-style NAME DEFINITION &optional STYLE-DESCRIPTION)
```

- `NAME`：风格名（字符串）。
- `DEFINITION`：风格定义（alist 或另一个风格名字符串）。
- `STYLE-DESCRIPTION`：可选的描述字符串，只在 `M-x c-set-style` 的补全提示里显示。

风格定义的 key 是**带 `c-` 前缀**的符号（`c-basic-offset`、`c-offsets-alist` 等），与 `c-style-variables` 列表里的名字一致。CC Mode 内部用 `c-style-var-list` 做匹配。

允许的 key（即 16 个风格变量）：

```text
c-basic-offset                  c-offsets-alist
c-comment-only-line-offset      c-special-indent-hook
c-block-comment-prefix          c-label-minimum-indentation
c-hanging-braces-alist          c-indent-comment-alist
c-hanging-colons-alist          c-indent-comments-syntactically-p
c-hanging-semi&comma-criteria   c-backslash-column
c-backslash-max-column          c-doc-comment-style
c-comment-prefix-regexp         c-cleanup-list
```

值就是变量的值——`c-basic-offset` 是整数、`c-offsets-alist` 是 alist、`c-cleanup-list` 是符号列表，以此类推。

### 一个完整的自定义风格示例

```elisp
(c-add-style "my-linux"
             '("linux"
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)
                                   (substatement-open . 0)
                                   (arglist-cont-nonempty . c-lineup-arglist)
                                   (inline-open . 0)))
               (c-cleanup-list . (brace-else-brace
                                  empty-defun-braces
                                  defun-close-semi))
               (c-hanging-braces-alist . ((substatement-open after)
                                          (block-close . c-snug-do-while))))
```

这个风格：

- 从 linux 继承（tab 缩进、`indent-tabs-mode=t` 等）。
- `c-basic-offset` 改成 4（linux 原本是 8）。
- `case-label` 改成 `+`（case 缩进一层）。
- `arglist-cont-nonempty` 改成 `c-lineup-arglist`（参数续行对齐到第一个参数）。
- `c-cleanup-list` 加了三条清理规则（第 5 章细讲）。
- `c-hanging-braces-alist` 控制 auto-newline 时 `{` 是否另起一行（第 5 章细讲）。

### 风格定义里的 `:include` 伪指令

`c-add-style` 支持一个特殊 key `:include`，值是另一个风格名——显式声明继承：

```elisp
(c-add-style "my-style"
             '((:include "bsd")
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)))))
```

这跟把 `"bsd"` 作为第一个元素是等价的——两种写法都行。`:include` 的好处是「一眼看出继承谁」，且可以放在任意位置（虽然通常放最前面）。

## 3.9 从已有代码反推风格：`c-guess-style`

如果你接手一个老项目、代码已经按某种风格缩进好了，但没人知道具体参数——`c-guess-style` 可以从已有代码**反推**风格。

```elisp
M-x c-guess-style RET
;; 或
M-x c-guess-buffer RET    ;; 只看当前 buffer
```

`c-guess-style` 会分析 buffer（或 region）里的代码，猜测 `c-basic-offset`、`c-offsets-alist` 等变量的值，然后**临时应用**这个猜测的风格。

**实测注意**：`c-guess-style` 的猜测结果不一定准——它对「缩进规整」的代码效果好，对「混了多种风格」的代码效果差。猜测完后用 `C-h v c-offsets-alist` 检查它猜了什么、不对的地方手动 `c-set-offset` 修。

## 3.10 File Style vs File Local Variables

`c-file-style` 和 file-local 变量都能写在文件里，但作用域不同：

- `c-file-style`：只设**风格**（16 个风格变量的一组值）。
- file-local 变量：可以设**任何**变量（包括风格变量和非风格变量如 `fill-column`、`tab-width`）。

两者可以混用：

```c
/* -*- c-file-style: "bsd"; fill-column: 100; -*- */
```

这行同时设了风格（bsd）和非风格变量（fill-column=100）。

## 3.11 实战：给项目配一个统一风格

假设团队约定「4 空格缩进、case 缩进一层、tab 显示 8 列但不用 tab 字符」：

**项目根目录的 `.dir-locals.el`**：

```elisp
((c-mode . ((c-file-style . "my-team")
            (tab-width . 8)
            (indent-tabs-mode . nil)))
 (c++-mode . ((c-file-style . "my-team")
              (tab-width . 8)
              (indent-tabs-mode . nil))))
```

**init 里的风格定义**：

```elisp
(c-add-style "my-team"
             '("bsd"
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)
                                   (substatement-open . 0)))))
```

这样：打开项目里任何 `.c`/`.cc` 文件，自动用 `my-team` 风格（4 空格、case 缩进一层）；`.dir-locals.el` 里的 `indent-tabs-mode: nil` 保证不用 tab 字符（即使风格本身没设这个）；`tab-width: 8` 让屏幕上 tab 显示 8 列（对齐别人的代码时不乱）。

## 3.12 常见坑

**坑 1：`c-set-style` 后代码没变**

`c-set-style` 只改 buffer-local 变量，不重排代码。要 `C-x h C-M-\` 或 `M-x indent-region` 手动重排。

**坑 2：hook 里 `setq` 了但打开文件没生效**

检查 file-local 变量——file-local 优先级比 hook 高，文件里的 `/* -*- c-basic-offset: 8; -*- */` 会覆盖 hook 里的 `(setq c-basic-offset 4)`。

**坑 3：`c-add-style` 后 `c-set-style` 找不到**

`c-add-style` 的第一个参数是**字符串** `"my-style"` 不是符号 `'my-style`。`M-x c-set-style` 补全时输入 `my-` 应该能看到。

**坑 4：自定义风格的 key 没带 `c-` 前缀**

风格定义里写 `(basic-offset . 4)` 是**错的**——`c-add-style` 期望 `(c-basic-offset . 4)`。无前缀的 key 会被静默忽略（不报错，但不起作用）。

**坑 5：`c-default-style` 设了但某 mode 不生效**

`c-default-style` 的 alist 形态里 key 是 **mode 名**（`c-mode`、`c++-mode`），不是语言名。写 `(c . "bsd")` 是错的，要写 `(c-mode . "bsd")`。

## 3.13 本章导航速查

- 看当前 buffer 用什么风格：`C-h v c-style`（buffer-local 变量，当前风格名）。
- 换风格：`C-c .`（`c-set-style`）。
- 看所有内置风格：`C-h v c-style-alist`。
- 看 16 个风格变量：`C-h v c-style-variables`。
- 自定义风格：`c-add-style`（见 3.8）。
- 从已有代码反推：`M-x c-guess-style`（见 3.9）。
- 项目级统一风格：`.dir-locals.el` + `c-file-style`（见 3.11）。

---

上一章：[02 · c-offsets-alist 实战：offset 的形态与 line-up 函数](02-c-offsets-alist.md)　｜　下一章：[04 · 日常命令：缩进、注释、移动、预处理](04-commands.md)　｜　返回：[CC Mode 教程](README.md)
