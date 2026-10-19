# 23 · 出问题时

Emacs 绝大多数时候都很稳，但偶尔会遇到：按了个键没反应、屏幕花了、某个命令卡住、甚至整个进程挂掉。这一章给你一套**从最轻到最重**的排查和自救手段。

## 23.1 `C-g`：最轻的刹车

`C-g`（命令 `keyboard-quit`）是 Emacs 里的「取消」键。任何时候你：

- 按了个前缀键（比如 `C-x`）但后悔了；
- 在增量搜索里想退出；
- 在 minibuffer 里想放弃输入；
- 某个命令正在跑、你想中止它；
- region 高亮了想取消；

按 `C-g` 就能回到「什么都没在干」的稳定状态。**按一次不行就再按一次**——有些状态需要多次 `C-g` 才能完全退出（比如递归编辑里）。

`C-g` 在正在运行的命令里按，会触发 `quit` 信号，命令通常会安全地中止（比如 kill 到一半被取消，要么全部在 buffer 里、要么全部在 kill ring 里，不会丢数据）。

## 23.2 更重的刹车：`C-]` 和 `ESC ESC ESC`

如果 `C-g` 不管用（比如你在一个递归编辑里），试试：

- `C-]`（命令 `abort-recursive-edit`）：退出**最内层**的递归编辑，并取消调用它的那个命令。
- `ESC ESC ESC`（命令 `keyboard-escape-quit`）：智能选择——如果在递归编辑里就退出递归编辑，否则等同 `C-g`。
- `M-x top-level`：退出**所有**递归编辑层级，回到最顶层。

「递归编辑」是什么？比如你在 `M-x query-replace` 里按了 `C-r` 进入递归编辑去修改文本，或者某些命令在 minibuffer 里又弹了个 minibuffer。mode line 上的括号 `(…)` 会变成 `[…]`，表示你在嵌套层里。`C-]` 或 `M-x top-level` 能把你拉回顶层。

## 23.3 屏幕花了：`C-l` 和 `M-x redraw-display`

如果屏幕显示乱了（比如终端被别的程序输出污染了），连按几下 `C-l`（`recenter-top-bottom`）——它在终端下会顺带清屏重画。

如果 `C-l` 不管用，用 `M-x redraw-display` 强制重绘整个屏幕。

## 23.4 卡住了 / 无响应

Emacs 卡住通常有几种原因：

1. **正在跑一个很慢的命令**（比如在大 buffer 里跑正则搜索）：按 `C-g` 中止它。
2. **在等输入**（比如某个命令在 minibuffer 里等你输东西，但你没注意到）：看 echo area 有没有提示；按 `C-g` 取消。
3. **在递归编辑里**：mode line 上有 `[...]` 标记；按 `C-]` 或 `M-x top-level`。
4. **Emacs 真的挂了**（进程无响应）：
   - 图形界面下：等一会儿，看它是不是在忙（比如加载大文件）；如果真挂了，从另一个终端 `kill -9 <pid>` 杀掉 Emacs 进程。
   - 纯终端下：按 `C-z`（`suspend-frame`）把 Emacs 挂起，回到 shell，然后用 `fg` 恢复或 `kill` 杀掉。

### 崩溃后的恢复

Emacs 崩溃（进程异常退出）后，你的改动**可能还在**——Emacs 会定期把 buffer 内容写到 **auto-save 文件**（文件名形如 `#foo.txt#`，和原文件同目录）。恢复方法：

- `M-x recover-file RET foo.txt RET`：恢复单个文件的 auto-save 版本。Emacs 会显示 auto-save 文件和你上次保存的文件之间的 diff，让你确认。
- `M-x recover-session`：恢复整个会话——列出所有崩溃前打开过的、有 auto-save 文件的 buffer，让你逐个选择恢复哪个。

auto-save 文件在正常退出 Emacs 时会被**自动删除**，所以只有崩溃时它们才有用。

## 23.5 排查：我到底按了啥？

`M-x view-lossage`（快捷键 `C-h l`，命令 `view-lossage`）会显示你**最近 300 个输入事件**（按键、命令调用等）。如果你按了一通键后 Emacs 行为诡异，用这个看看自己到底按了什么——经常能发现「哦，我无意中按了 `C-x C-k C-f` 改了个宏格式」。

`M-x emacs-version`（命令 `emacs-version`）显示当前 Emacs 版本。报 bug 或求助时这是必给的信息。

## 23.6 报告 bug

如果你确定遇到了 Emacs 的 bug（不是你的配置问题——先用 `emacs -Q` 验证），用 `M-x report-emacs-bug`（命令 `report-emacs-bug`）。它会帮你起草一封 bug 报告邮件，自动包含版本信息、系统信息等。

报告 bug 前：

1. **用 `emacs -Q` 复现**：排除你的 init 文件和第三方包的影响。
2. **写清步骤**：从 `emacs -Q` 启动，按什么键、输入什么命令，能稳定复现问题。
3. **给出期望行为 vs 实际行为**。

## 23.7 常见「延迟」原因

Emacs 偶尔会「卡一下」，通常不是 bug，而是：

- **字体化（fontification）**：打开大文件时，Emacs 要给语法高亮，可能卡几秒。变量 `jit-lock-defer-time` 控制延迟字体化的时间。
- **自动保存**：Emacs 定期写 auto-save 文件，大 buffer 时可能卡一下。
- **GC（垃圾回收）**：Emacs 内存用多了会触发 GC，会卡一下。变量 `gc-cons-threshold` 和 `gc-cons-percentage` 控制 GC 频率。
- **网络操作**：访问远程文件（TRAMP）、从 ELPA 下载包等，网络慢时会卡。

如果频繁卡，可以临时提高 GC 阈值（在 init 文件里 `(setq gc-cons-threshold 100000000)`），或关掉不必要的 minor mode（比如在大 buffer 里关掉 `font-lock-mode`）。

## 23.8 小结

- `C-g` 是万能刹车，按一次不行就再按。
- `C-]` / `ESC ESC ESC` / `M-x top-level` 退出递归编辑。
- `C-l` 重画屏幕；`M-x redraw-display` 强制重绘。
- 崩溃后用 `M-x recover-file` / `M-x recover-session` 恢复 auto-save 文件。
- `C-h l`（`view-lossage`）看最近按了啥；`M-x emacs-version` 查版本。
- 报 bug 用 `M-x report-emacs-bug`，先用 `emacs -Q` 排除配置问题。

---

上一章：[22 · 会话与启动](22-sessions-and-startup.md) ｜ 下一章：[24 · 附录：常用键位速查](24-cheatsheet.md) ｜ 返回：[使用 Emacs 教程](README.md)
