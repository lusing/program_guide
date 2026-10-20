# 07 · Font Locking：语法高亮

CC Mode 的 font locking（语法高亮）分**三个等级**，由 `font-lock-maximum-decoration` 控制。等级越高、高亮越细、越慢。本机实测各级的关键词数量：level 1 有 8 条、level 2 有 20 条、level 3 有 23 条。

## 7.1 三个等级

| 等级 | 变量 | 高亮内容 | 速度 |
|---|---|---|---|
| 1 | `c-font-lock-keywords-1` | 关键字、类型、注释、字符串、预处理 | 最快 |
| 2 | `c-font-lock-keywords-2` | level 1 + 函数名、变量名、常量 | 中等 |
| 3 | `c-font-lock-keywords-3` | level 2 + 更细粒度的语义高亮 | 最慢 |

本机实测 `font-lock-maximum-decoration` 默认值是 `t`——等价于 level 3（最高等级）。所以**默认就是最全的高亮**。

### 切换等级

```elisp
(setq font-lock-maximum-decoration 1)   ;; 全局用 level 1
(setq font-lock-maximum-decoration 2)   ;; 全局用 level 2
(setq font-lock-maximum-decoration t)   ;; 全局用 level 3（默认）
```

或按 mode 设：

```elisp
(setq font-lock-maximum-decoration '((c-mode . 2) (c++-mode . 3) (t . 1)))
;; c-mode 用 level 2、c++-mode 用 level 3、其它用 level 1
```

## 7.2 各级高亮什么

### Level 1：基础高亮

- **关键字**：`if`、`else`、`while`、`for`、`return`、`int`、`char`、`void` 等。
- **类型**：`int`、`char`、`float`、`double`、`struct`、`union`、`enum` 等。
- **注释**：`/* ... */` 和 `// ...`。
- **字符串**：`"..."`。
- **预处理指令**：`#include`、`#define`、`#if` 等。
- **常量**：数字、字符常量。

### Level 2：+ 标识符

在 level 1 基础上增加：

- **函数名**：函数定义和声明的名字。
- **变量名**：全局变量和局部变量的名字。
- **常量**：`NULL`、`EOF`、`TRUE`、`FALSE` 等。
- **标签**：`case` 标签、`goto` 标签。

### Level 3：+ 细粒度

在 level 2 基础上增加：

- **更精确的函数调用 vs 定义**区分。
- **命名空间/类限定符**。
- **模板参数**。
- **更多语义上下文相关的高亮**。

## 7.3 `c-font-lock-extra-types`：自定义类型高亮

CC Mode 默认把 C 标准类型（`int`、`char`、`FILE` 等）高亮为 `font-lock-type-face`。如果你想让**自定义类型**也高亮，加到 `c-font-lock-extra-types`。

本机实测默认值：

```elisp
("\\sw+_t"          ;; POSIX 风格：以 _t 结尾的类型名（如 size_t、pthread_t）
 "bool"             ;; C99 布尔
 "complex"          ;; C99 复数
 "imaginary"        ;; C99 虚数
 "FILE"             ;; stdio.h
 "lconv"            ;; locale.h
 "tm"               ;; time.h
 "va_list"          ;; stdarg.h
 "jmp_buf"          ;; setjmp.h
 "Lisp_Object")     ;; Emacs 内部类型
```

注意第一条 `"\\sw+_t"` 是正则——匹配任何以 `_t` 结尾的单词。所以 `size_t`、`pthread_t`、`uint32_t` 自动被高亮为类型。

### 添加自定义类型

```elisp
(add-to-list 'c-font-lock-extra-types "my_struct_t")
(add-to-list 'c-font-lock-extra-types "MyClass")     ;; C++ 类名
```

## 7.4 Font Locking 的性能

CC Mode 的 font locking 是**增量**的——只重新高亮修改过的区域，不是每次全 buffer 重扫。但在大文件（5000+ 行）里，level 3 的高亮仍可能卡顿。

### 提速方法

**方法 1：降低等级**

```elisp
(add-hook 'c-mode-hook
          (lambda ()
            (setq font-lock-maximum-decoration 1)))
```

**方法 2：关掉 font-lock**

```elisp
(add-hook 'c-mode-hook
          (lambda ()
            (font-lock-mode -1)))
```

**方法 3：lazy font-lock**

让 font-lock 只在「空闲时」做高亮，不阻塞输入：

```elisp
(setq font-lock-support-mode 'jit-lock-mode)   ;; 默认就是 jit-lock
(setq jit-lock-stealth-time 16)                 ;; 16 秒空闲后开始后台高亮
(setq jit-lock-chunk-size 500)                  ;; 每次高亮 500 行
```

`jit-lock-mode` 是 Emacs 的默认 font-lock 引擎——它把高亮拆成小块、在空闲时做。`jit-lock-stealth-time` 控制「多久不按键开始后台高亮」；`jit-lock-chunk-size` 控制「每次高亮多少行」。

## 7.5 自定义高亮规则

如果你想加自己的高亮规则（比如把某个特定函数名标红），用 `font-lock-add-keywords`：

```elisp
(font-lock-add-keywords 'c-mode
  '(("\\<my_special_function\\>" . font-lock-warning-face)))
```

这行把 `my_special_function` 高亮为 `font-lock-warning-face`（通常是红色）。

更复杂的规则——高亮 `TODO` 和 `FIXME` 注释：

```elisp
(font-lock-add-keywords 'c-mode
  '(("\\<\\(TODO\\|FIXME\\)\\>" 1 font-lock-warning-face t)))
```

## 7.6 CC Mode 的 font-lock 实现细节

CC Mode 的 font locking 不是简单的正则匹配——它用**语法分析**（syntactic analysis）辅助判断上下文。比如区分「`*` 是乘法还是指针声明」需要知道前面的 token 是类型还是变量。这就是为什么 CC Mode 的高亮比纯正则的 mode（比如早期的 `c-mode.el`）更准、但也更慢。

`font-lock-defaults` 里的 `c-beginning-of-syntax` 是 CC Mode 的语法分析入口——font-lock 在每次高亮前调用它确定当前位置的语法上下文。

## 7.7 常见坑

**坑 1：大文件里打字卡顿**

降低 `font-lock-maximum-decoration` 或关掉 font-lock（见 7.4）。

**坑 2：自定义类型没被高亮**

检查 `c-font-lock-extra-types`——你的类型名要在这里。注意默认值里有 `"\\sw+_t"`，所以以 `_t` 结尾的类型自动高亮；不以 `_t` 结尾的要手动加。

**坑 3：高亮颜色不对**

CC Mode 用标准的 font-lock faces（`font-lock-keyword-face`、`font-lock-type-face` 等）。改颜色要改这些 face，不是 CC Mode 的变量：

```elisp
(set-face-foreground 'font-lock-keyword-face "purple")
(set-face-foreground 'font-lock-type-face "teal")
```

**坑 4：`font-lock-add-keywords` 加了规则但没生效**

`font-lock-add-keywords` 只对**新打开的 buffer** 生效。已有 buffer 要 `M-x font-lock-fontify-buffer` 手动刷新。

## 7.8 本章导航速查

- 看当前 font-lock 等级：`C-h v font-lock-maximum-decoration`。
- 降等级提速：`(setq font-lock-maximum-decoration 1)`。
- 加自定义类型：`(add-to-list 'c-font-lock-extra-types "my_type_t")`。
- 加自定义高亮：`M-x font-lock-add-keywords`。
- 手动刷新高亮：`M-x font-lock-fontify-buffer`。

---

上一章：[06 · Filling、Macros 与注释格式](06-filling-and-macros.md)　｜　下一章：[08 · 定制总结与性能调优](08-customization-performance.md)　｜　返回：[CC Mode 教程](README.md)
