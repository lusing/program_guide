# 使用 Emacs 教程

一套教你**怎么用** GNU Emacs 的中文教程：从第一次打开、看懂屏幕，到编辑文本、管理文件与窗口、用 Dired/键盘宏/Shell、再到把 Emacs 定制成顺手的样子。

- 全部内容**提炼自 GNU Emacs 手册（对应 Emacs 31.1）并自包含**——每一处按键、命令、变量、行为都在正文里讲清楚，不需要你再去翻别的书或手册章节。
- 文中出现的每个键位都按 **GNU Emacs 31.1** 的默认绑定核验过（`C-x C-q` 在旧版本是 `toggle-read-only`、新版是 `read-only-mode` 这类差异会当场指出）。
- 想学**写扩展（Elisp 编程）**而不是用 Emacs，请看隔壁的 [Emacs 扩展开发指南](../extending-emacs/README.md)。

## 怎么读这套教程

- **按键记法**：`C-x` 表示按住 Control 再按 x；`M-x` 表示按住 Meta（多数键盘上是 Alt，或先按 `ESC` 再按 x）；`RET` 是回车键，`SPC` 是空格键，`DEL` 是退格键。像 `C-x C-f` 这样的多键序列要**连着按**：先 `C-x`，松开，再 `C-f`。第 2 章会把这套记法讲透。
- **命令名**：形如 `find-file` 的是命令（一个 Lisp 函数的名字），可以用 `M-x find-file RET` 直接按名字调用。每个命令通常都绑了快捷键，两者等价。
- **建议边读边开一个 Emacs 跟着敲**。想在不影响自己配置的情况下练手，用 `emacs -Q` 启动一个「干净」的 Emacs（不加载任何个人配置）。
- 每章末尾有「上一章 ｜ 下一章 ｜ 返回」导航。

## 目录

### 第一部分 · 上手

| 章 | 主题 |
|---|---|
| [00 · 开始之前：Emacs 是什么、怎么启动](00-before-you-start.md) | Emacs 的四个特点、从命令行启动、启动画面、访问文件、退出与挂起 |
| [01 · 屏幕解剖：frame、window、mode line、echo area](01-screen.md) | 看懂屏幕上的每一块：光标、point、mode line、echo area、minibuffer |
| [02 · 按键与命令](02-keys-and-commands.md) | 输入事件、键序列与前缀键、`M-x`、数字参数、重复命令 |
| [03 · 最基本的编辑](03-basic-editing.md) | 插入文本、移动 point、删除、撤销、空行、折行、位置信息 |
| [04 · 自助文档：Help 家族](04-help.md) | `C-h` 系列：查按键、查命令、查变量、apropos、Info |

### 第二部分 · 编辑核心

| 章 | 主题 |
|---|---|
| [05 · minibuffer 与补全](05-minibuffer.md) | 在 minibuffer 里输参数、文件名补全、历史、递归编辑 |
| [06 · mark 与 region](06-mark-and-region.md) | 设置 mark、标记文本对象、对 region 批量操作、mark ring |
| [07 · kill 与 yank：剪切与粘贴](07-kill-and-yank.md) | kill ring、`C-y`/`M-y`、追加 kill、矩形、剪贴板 |
| [08 · 搜索与替换](08-search-and-replace.md) | 增量搜索、正则搜索、`query-replace`、替换的特殊记法 |
| [09 · 文件操作](09-files.md) | 访问/保存文件、文件名、备份、自动保存、比较文件 |

### 第三部分 · 管理文本与窗口

| 章 | 主题 |
|---|---|
| [10 · 多 buffer、window 与 frame](10-buffers-windows-frames.md) | 切换/新建/删除 buffer、分屏、多窗口、多 frame |
| [11 · 显示控制](11-display.md) | 滚动、重定位光标、narrowing、折行、光标定位 |
| [12 · 文本编辑](12-text-editing.md) | 词/句/段、填充、缩进、大小写、文本模式 |
| [13 · 模式：major 与 minor](13-modes.md) | 模式概念、如何切换、模式钩子、mode line 上的模式标记 |
| [14 · 程序编辑](14-programs.md) | 程序模式、缩进、注释、括号匹配、语法高亮 |

### 第四部分 · 工具

| 章 | 主题 |
|---|---|
| [15 · Dired：目录与文件管理器](15-dired.md) | 打开目录、导航、标记、批量操作、就地编辑 |
| [16 · 键盘宏](16-keyboard-macros.md) | 录制、回放、计数、命名、编辑宏 |
| [17 · 寄存器与书签](17-registers-and-bookmarks.md) | 用寄存器存文本/位置/数字/窗口配置，书签跳转 |
| [18 · 拼写检查与缩写](18-spelling-and-abbrevs.md) | ispell 拼写检查、定义与展开缩写 |
| [19 · Shell、编译与调试入口](19-shell-and-build.md) | `M-!` 一次性 shell、`M-x shell`、compile、grep |

### 第五部分 · 定制与运维

| 章 | 主题 |
|---|---|
| [20 · 定制 Emacs](20-customization.md) | Customize 界面、改变量、init 文件、改键、选项 |
| [21 · 安装扩展包](21-packages.md) | package.el：仓库、`list-packages`、安装/更新/删除 |
| [22 · 会话与启动](22-sessions-and-startup.md) | 保存/恢复会话（desktop）、书签、启动选项、恢复编辑 |
| [23 · 出问题时](23-troubleshooting.md) | `C-g`、卡死与崩溃、报告 bug、常见延迟 |
| [24 · 附录：常用键位速查](24-cheatsheet.md) | 按主题整理的常用键位表 |

## 验证

- 键位核验：每章声称的「键 → 命令」映射都用 Emacs 31.1 的默认 keymap 实测过，核验入口是仓库根目录的 `tools/check_docs.py`（它会调 `emacs -Q --batch` 重新查一遍所有键位，对不上就报红）。
- 只依赖 Emacs 内置功能，不需要任何第三方包。
