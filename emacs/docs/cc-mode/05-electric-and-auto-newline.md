# 05 · Electric Keys 与 Auto-newline

第 4 章讲的命令是你**主动按**的。这一章讲 CC Mode 的「自动驾驶」——你输入 `{`、`}`、`;`、`:`、`,`、`#`、`*`、`/` 这些字符时，CC Mode 会自动做缩进、换行、清理。这套机制叫 **electric keys** 和 **auto-newline**，是 CC Mode「让写 C 代码感觉像在跟编辑器对话」的核心。

## 5.1 Electric Keys：输入即缩进

CC Mode 把一组键重定义成 **electric** 版本——按下去不只插入字符，还会触发 `c-indent-line-or-region` 重新缩进当前行。本机实测 c-mode 的 electric 键：

| 键 | 命令 | 触发时机 |
|---|---|---|
| `{` | `c-electric-brace` | 插入 `{` 后重新缩进 |
| `}` | `c-electric-brace` | 插入 `}` 后重新缩进 + 可能换行 |
| `(` | `c-electric-paren` | 插入 `(` 后重新缩进 |
| `)` | `c-electric-paren` | 插入 `)` 后重新缩进 |
| `;` | `c-electric-semi&comma` | 插入 `;` 后重新缩进 + 可能换行 |
| `,` | `c-electric-semi&comma` | 插入 `,` 后重新缩进 |
| `:` | `c-electric-colon` | 插入 `:` 后重新缩进 + 可能换行 |
| `#` | `c-electric-pound` | 插入 `#` 后重新缩进（预处理指令顶格） |
| `*` | `c-electric-star` | 插入 `*` 后重新缩进（指针声明/解引用） |
| `/` | `c-electric-slash` | 插入 `/` 后重新缩进（注释开始） |

**注意**：`&`、`|`、`=`、`+`、`-` 等**不是** electric 键——它们就是普通的 `self-insert-command`。electric 只覆盖「语法上有特殊意义」的字符。

### 实测：electric `}` 的效果

```text
void f() {
  int x = 1;
}                    ← 光标在 } 后面按 }，} 自动顶到列 0
```

electric `}` 会：插入 `}` → 重新缩进当前行（`}` 顶到列 0）→ 如果 `c-auto-newline` 开启还会额外做换行（见 5.2）。

### 实测：electric `#` 的效果

```text
int x = 1;
#                    ← 光标在行首按 #，# 顶到列 0
#define FOO 1
```

`#` 自动顶格——这是 `c-electric-pound` 的特化行为，保证预处理指令永远从列 0 开始（与 `cpp-macro` 的 `[0]` offset 配合）。

### 实测：electric `*` 的效果

```text
int x = 5;
int *p = &x;         ← 输入 * 后，* 前面的空白被规范化
int y = *p;          ← 解引用场景，* 紧贴操作数
```

`c-electric-star` 会判断当前 `*` 是「指针声明」还是「乘法/解引用」，调整周围空白。

### 实测：electric `/` 的效果

```text
int x = 1;
//                   ← 输入 // 后，注释符号按 c-indent-comment-alist 缩进
```

`c-electric-slash` 检测 `//` 或 `/*` 序列，按注释规则缩进。

### 开关：electric 可以整体关掉

```elisp
(setq c-electric-flag nil)     ;; 关闭所有 electric 行为
;; 或交互式：
M-x c-toggle-electric-state    ;; 切换 electric on/off
```

`c-electric-flag` 默认 `t`（开启）。关掉后 `{`、`}`、`;` 等键只插入字符、不做任何缩进——CC Mode 退化成「普通编辑 + 手动 TAB 缩进」。

## 5.2 Auto-newline：输入即换行

`c-auto-newline` 是 electric 之上的**可选层**——默认 **关闭**（本机实测 `c-auto-newline` 默认 `nil`）。开启后，electric 键在插入字符的同时**自动插入换行**。

```elisp
(setq c-auto-newline t)
;; 或交互式：
M-x c-toggle-auto-newline      ;; C-c C-a
```

### 实测：auto-newline + `{`

```text
输入：void f() 然后按 {
结果：
void f()
{
  ← 光标在这里（自动换行 + 缩进）
```

`{` 触发了：插入 `{` → 重新缩进 `{` 到列 0 → 自动换行 → 新行缩进一个 `c-basic-offset`。

### 实测：auto-newline + `;`

```text
输入：int x = 1 然后按 ;
结果：
  int x = 1;
  ← 光标在这里（自动换行 + 缩进，准备下一行）
```

### 实测：auto-newline + `}`

```text
输入：}（在函数体最后一行）
结果：
}
← 光标在这里（} 后面自动换行）
```

### auto-newline 的「hang」行为：由 `c-hanging-braces-alist` 控制

auto-newline 不是「一律换行」——它查 `c-hanging-braces-alist` 决定**在哪换、在哪不换**。这个 alist 把 syntactic context 映到 `(before after)` 列表，表示「在 `{` 前/后是否换行」。

本机实测 gnu 风格的 `c-hanging-braces-alist`：

```elisp
((substatement-open before after)    ;; if/while 后的 {：前后都换行
 (arglist-cont-nonempty))             ;; 参数列表里的 {：不换行
```

意思是：gnu 风格里 `if` 后面的 `{` **前后都换行**（`{` 单独一行），但函数参数列表里的 `{` **不换行**（紧贴参数）。

linux 风格：

```elisp
((brace-list-open)                    ;; 初始化列表的 {：换行
 (brace-entry-open)                   ;; 条目后的 {：换行
 (substatement-open after)            ;; if/while 后的 {：只后面换行（{ 跟 if 同行）
 (block-close . c-snug-do-while)      ;; do-while 的 }：紧贴 while
 (arglist-cont-nonempty))             ;; 参数列表里的 {：不换行
```

差异：`substatement-open` 是 `(after)` 不是 `(before after)`——linux 风格里 `if` 后面的 `{` **跟 `if` 同一行**（K&R 风格），gnu 风格里 `{` **单独一行**。

这就是「同一个 auto-newline 开关，不同风格行为不同」的原因——背后都是 `c-hanging-braces-alist`。

### auto-newline 的冒号行为：由 `c-hanging-colons-alist` 控制

类似地，`:` 的 auto-newline 行为由 `c-hanging-colons-alist` 控制。本机实测 gnu 和 linux 都没设这个（默认 nil），所以 `:` 默认不换行。java 风格也没设。

### auto-newline 的分号/逗号行为：由 `c-hanging-semi&comma-criteria` 控制

`;` 和 `,` 的 auto-newline 由 `c-hanging-semi&comma-criteria` 控制——一个函数列表，每个函数判断当前上下文是否该换行。默认行为：`;` 在语句末尾换行、`,` 在参数列表里不换行。

## 5.3 Hungry Delete：删除即清场

`c-hungry-delete-key` 控制「向前删除时是否吃掉所有空白」。默认 **关闭**（本机实测 `c-hungry-delete-key` 默认 `nil`）。

开启后，`C-d`（`c-hungry-delete-forward`）和 `DEL`（`c-hungry-delete-backward`）会**跳过所有空白和换行**，直到下一个非空白字符。

```elisp
(setq c-hungry-delete-key t)
;; 或交互式：
M-x c-toggle-hungry-state
```

**注意**：`c-toggle-hungry-state` 在 CC Mode 5.35.2 里**没有默认键绑定**——要 `M-x c-toggle-hungry-state` 显式调用。`C-c C-d` 绑定的是 `c-hungry-delete-forward`（单次 hungry 删除，不是开关）。

## 5.4 Clean-ups：输入后的自动清理

`c-cleanup-list` 是一组符号，控制 electric 键在特定场景下的**额外清理动作**。本机实测 gnu 风格的 `c-cleanup-list`：

```elisp
(scope-operator)    ;; C++ :: 运算符前不加空格
```

linux 风格：

```elisp
(brace-else-brace)  ;; } else { 的 else 前后空格规范化
```

### 常见 cleanup 符号

| 符号 | 效果 |
|---|---|
| `scope-operator` | `::` 前不加空格（`foo::bar` 不是 `foo :: bar`） |
| `brace-else-brace` | `} else {` 的 `else` 前后各留一个空格 |
| `empty-defun-braces` | 空函数体 `{}` 不拆行 |
| `defun-close-semi` | 函数定义后的 `;` 紧贴 `}` |
| `list-close-comma` | `}` 前的 `,` 被清掉 |
| `comment-close-slash` | `*/` 前加空格 |

这些 cleanup 在 electric 键触发时自动执行——比如输入 `:` 后如果形成 `::`，`scope-operator` cleanup 会把 `::` 前面的空格删掉。

## 5.5 Subword Mode：驼峰式单词移动

C++ 代码里常见 `myLongVariableName` 这样的驼峰式命名。默认 `M-f`/`M-b`（`forward-word`/`backward-word`）把它当作**一个单词**；`c-subword-mode` 开启后把它当作**多个子单词**。

本机实测：

```text
光标在 myLongVariableName 开头

默认 M-f     → 光标移到末尾（19 列）——整个变量名是一个单词
subword M-f  → 光标移到 Long 开头（3 列）——驼峰分段
```

开关：

```elisp
M-x c-subword-mode    ;; C-c C-w
```

`c-subword-mode` 是一个 minor mode，开启后 `M-f`/`M-b`/`M-d`/`M-DEL` 都按子单词边界操作。

## 5.6 实战：三种编辑风格

### 风格 A：全手动（electric off, auto-newline off）

```elisp
(setq c-electric-flag nil
      c-auto-newline nil)
```

适合：不喜欢编辑器「自作主张」的人。`{`、`}`、`;` 只插入字符，缩进全靠 `TAB`。

### 风格 B：electric on, auto-newline off（默认）

```elisp
(setq c-electric-flag t
      c-auto-newline nil)
```

适合：大多数人。输入 `{` 后当前行自动缩进，但不会自动换行——你手动 `RET` 决定换不换。这是 CC Mode 的默认行为。

### 风格 C：electric on, auto-newline on

```elisp
(setq c-electric-flag t
      c-auto-newline t)
```

适合：喜欢「编辑器帮我排版」的人。输入 `{` 自动换行+缩进、输入 `;` 自动换行——写代码时几乎不用按 `RET`。代价是有时 auto-newline 的换行位置不合预期，要手动修。

## 5.7 常见坑

**坑 1：auto-newline 开了但 `{` 没自动换行**

检查当前风格的 `c-hanging-braces-alist`——它控制「哪种 syntactic context 下的 `{` 换行」。比如 gnu 风格里 `arglist-cont-nonempty` 的 `{` 不换行（函数参数列表里的 `{` 紧贴参数）。

**坑 2：electric `*` 把乘法星号当成指针星号**

`c-electric-star` 的判断基于上下文，有时会误判。如果它把 `a * b` 的 `*` 当成指针声明、调整了空白，按 `C-_`（undo）回退、然后 `M-x c-toggle-electric-state` 临时关掉 electric 再输入 `*`。

**坑 3：`C-c C-a` 开了 auto-newline 但 `;` 不换行**

`c-hanging-semi&comma-criteria` 里的函数判断当前 `;` 是否该换行。比如在 `for` 语句的 `;` 就不换行。这是设计行为。

**坑 4：subword mode 影响所有 buffer**

`c-subword-mode` 是 buffer-local 的——只在当前 CC Mode buffer 生效，不影响其它 buffer。

## 5.8 本章导航速查

- 关闭/开启 electric：`M-x c-toggle-electric-state`（`C-c C-l`）。
- 关闭/开启 auto-newline：`M-x c-toggle-auto-newline`（`C-c C-a`）。
- 关闭/开启 hungry delete：`M-x c-toggle-hungry-state`（无默认键）。
- 驼峰式单词移动：`M-x c-subword-mode`（`C-c C-w`）。
- auto-newline 行为微调：`c-hanging-braces-alist`、`c-hanging-colons-alist`、`c-hanging-semi&comma-criteria`。
- 输入后清理：`c-cleanup-list`。

---

上一章：[04 · 日常命令：缩进、注释、移动、预处理](04-commands.md)　｜　下一章：[06 · Filling、Macros 与注释格式](06-filling-and-macros.md)　｜　返回：[CC Mode 教程](README.md)
