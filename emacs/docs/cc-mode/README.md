# CC Mode 教程

一套教你**怎么用**和**怎么配** GNU Emacs 自带 CC Mode 的中文教程。CC Mode 是 Emacs 编辑
C、C++、Objective-C、Java、CORBA IDL、Pike、AWK 的同一套 major mode 家族——缩进引擎、电键、风格
系统、字体化都共享，学好一份配置就能管好七种语言。

- 全部内容**提炼自 GNU《CC Mode Manual》（5.35）并自包含**——每一处键位、命令、变量、缩进规则、配置写法都在正文里讲透，不需要你再翻原书某一章。
- 所有结论都在 **GNU Emacs 31.1 + CC Mode 5.35.2** 上实测复现。原书与实现有漂移的地方（例如 `<TAB>` 实际绑 `c-indent-line-or-region`、`M-j` 在 c-mode 已不绑定、`C-c C-d` 现在是 `c-hungry-delete-forward`），正文第一次遇到就当场点明，并以实测行为为准。
- 这是「怎么用/怎么配 CC Mode」，不是「怎么用 Elisp 写扩展」。写扩展请看 [Emacs 扩展开发指南](../extending-emacs/README.md)；只想概览 Emacs 里编程相关能力，看 [使用 Emacs 教程 · 程序编辑](../using-emacs/14-programs.md)。

## 怎么读这套教程

- **先读第 00 章**，它把「CC Mode 是什么、怎么接管你的文件、模式行上的字母含义、上手先动的三个变量、配置的五层优先级、16 个风格变量」一次讲清，后面每一章都从这里出发。
- **第 1–2 章是这套配置的地基**：缩进的两步模型（syntactic symbol + anchor → offset）、以及 `c-offsets-alist` 里 offset 的七种形态与 line-up 函数。想理解「为什么这么缩」就读这两章。
- **第 3 章讲风格系统**：十种内置风格各自的真实缩进产物、怎么换风格、怎么定义你自己的风格。
- **第 4–6 章讲日常操作**：缩进/注释/移动/预处理命令，电键与 auto-newline 与 hungry delete，以及注释与字符串的填充和多行宏。
- **第 7 章讲字体化**，**第 8 章讲一份完整 init、性能调优与调试方法**。
- 每章末尾都有「上一章 ｜ 下一章 ｜ 返回」导航。建议边读边开一个 `emacs -Q` 的干净 Emacs 跟着敲。

## 目录

| 章 | 主题 | 讲什么 |
|---|---|---|
| [00 · CC Mode 是什么：一套引擎、七种语言](00-overview-and-activation.md) | 概览与启用 | 版本核对、auto-mode-alist 接管规则、模式行暗号、上手三变量、配置五层优先级、16 个风格变量、最小 init 片段 |
| [01 · 缩进引擎：两步模型与 syntactic context](01-indentation-engine.md) | 缩进原理 | 分析 syntactic symbol + anchor、`c-guess-basic-syntax`、全部 syntactic symbol 分类与命名约定、用 `C-c C-s` 现场查看 |
| [02 · c-offsets-alist 实战：offset 的形态与 line-up 函数](02-c-offsets-alist.md) | 缩进配置 | offset 七种形态（整数 / `+ ++ - -- * /` / 向量 / 函数 / 另一符号 / 变量 / 列表 first·min·max·add）、`c-set-offset`、43 个内置 line-up 函数分七族讲解、`c-special-indent-hook` |
| [03 · 风格系统：c-default-style、内置风格与自定义风格](03-styles.md) | 风格 | 六种配置写法与优先级、16 个风格变量详解、`c-default-style` 三形态、十种内置风格实测产物、`c-set-style`、`c-add-style` 自定义、`c-guess-style`、File Style |
| [04 · 日常命令：缩进、注释、移动、预处理](04-commands.md) | 命令 | `TAB` 族、注释命令族、函数/语句/条件编译移动族、宏展开、反斜杠对齐、hungry delete、narrowing |
| [05 · Electric Keys 与 Auto-newline](05-electric-and-auto-newline.md) | 输入行为 | 10 个 electric 键逐一实测、`c-hanging-braces-alist` 控制换行、`c-cleanup-list` 清理规则、hungry delete、subword mode |
| [06 · Filling、Macros 与注释格式](06-filling-and-macros.md) | 填充与宏 | `c-fill-paragraph` 注释折行、`c-backslash-region` 反斜杠对齐、`c-macro-expand` 宏展开、`c-block-comment-prefix`、`c-doc-comment-style` |
| [07 · Font Locking：语法高亮](07-font-locking.md) | 高亮 | 三个 font-lock 等级、`c-font-lock-extra-types` 自定义类型、性能调优、`font-lock-add-keywords` 自定义规则 |
| [08 · 定制总结与性能调优](08-customization-performance.md) | 收尾 | 完整配置模板、性能瓶颈分析与调优、调试方法、obsolete 变量清单、`c-mode-common-hook`、与 LSP/company 协作 |

## 版本

本教程基于 **GNU Emacs 31.1**（macOS MacPorts，`/opt/local/bin/emacs`）内置的 **CC Mode 5.35.2**
编写并验证。CC Mode 的默认键位与变量值随版本有细微变化，正文以 5.35.2 的实测为准。用 `M-x c-version`
可查你本机的 CC Mode 版本，`M-x emacs-version` 查 Emacs 版本。
