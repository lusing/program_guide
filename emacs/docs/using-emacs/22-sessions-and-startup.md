# 22 · 会话与启动

Emacs 不是那种「每次编辑都重启」的编辑器——推荐的做法是登录后只启动一次，整个会话里所有编辑都在这一个 Emacs 中进行。但「会话」意味着状态：打开的 buffer、光标位置、kill ring、寄存器……这一章讲怎么把这些状态**跨会话保留**，以及 Emacs 启动时能接受哪些命令行参数。

## 22.1 保存会话：`desktop-save-mode`

Emacs 自带一个叫 `desktop` 的库，能把你当前的「桌面」——打开的 buffer、每个 buffer 的文件名、major mode、point 位置、window/frame 配置、一些重要的全局变量——保存到一个文件里，下次启动时恢复。

启用方法（在 init 文件里加一行）：

```elisp
;; ~/.emacs.d/init.el
(desktop-save-mode 1)
```

启用后：

- Emacs 退出时**自动保存**桌面到 `desktop-path`（默认是 `user-emacs-directory`，即 `~/.emacs.d/`）里的 `desktop` 文件。
- Emacs 启动时**自动加载**找到的第一个桌面文件。
- 运行期间如果桌面配置变了（比如打开了新 buffer），会自动定期保存（频率由 `desktop-auto-save-timeout` 控制）。

你也可以手动操作：

- `M-x desktop-save`：立即保存当前桌面到指定目录。
- `M-x desktop-read`：从指定目录加载桌面。
- `M-x desktop-change-dir`：保存当前桌面到 A 目录，然后加载 B 目录的桌面。
- `M-x desktop-revert`：回退到上一次加载的桌面。
- `M-x desktop-clear`：清空当前桌面（关闭所有 buffer，但保留 `*scratch*` 等）。

### 桌面文件锁

桌面文件在 Emacs 运行期间会被**锁住**，防止另一个 Emacs 意外覆盖。如果 Emacs 或系统崩溃，锁会留下来，下次启动时 Emacs 会问你是否要加载这个被锁的桌面。变量 `desktop-load-locked-desktop` 控制行为：

- `nil`：不加载被锁的桌面。
- `t`：直接加载，不询问。
- `check-pid`：检查锁文件里记录的进程 ID 是否还在运行，没在运行就加载（适合单机环境）。

### 不想恢复桌面？

启动时加 `--no-desktop` 选项（见 22.3）可以跳过恢复。

## 22.2 书签：跨会话的位置标记

第 17 章讲过寄存器（`C-x r SPC` 存位置、`C-x r j` 跳回），但寄存器是**会话内的**——退出 Emacs 就没了。如果你需要**跨会话**记住某个位置（比如某本书的第 3 章、某个项目的核心文件），用**书签（bookmark）**。

书签的键和寄存器共享 `C-x r` 前缀：

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r m` | `bookmark-set` | 给当前位置设一个书签（会问名字） |
| `C-x r M` | `bookmark-set-no-overwrite` | 设书签，但同名书签已存在时不覆盖 |
| `C-x r b` | `bookmark-jump` | 跳到书签（会打开对应文件） |
| `C-x r l` | `bookmark-bmenu-list` | 列出所有书签（打开 `*Bookmark List*` buffer） |

书签默认**自动保存**到 `bookmark-save-flag` 指定的次数（每修改 N 次书签就自动保存一次），或退出 Emacs 时保存。文件是 `~/.emacs.d/bookmarks`。

在 `*Bookmark List*` buffer 里，`RET` 跳到书签、`d` 标记删除、`u` 取消标记、`x` 执行删除、`q` 退出。

## 22.3 启动选项

Emacs 命令行能接受很多选项。常用的：

| 选项 | 作用 |
|---|---|
| `emacs` | 正常启动（加载 init 文件） |
| `emacs -q` | 不加载 init 文件（`~/.emacs` 或 `~/.emacs.d/init.el`） |
| `emacs -Q` | 等同 `-q` 且**不加载任何包、site 配置**——最「干净」的启动 |
| `emacs -nw` | 不用图形界面，在终端里跑（no window） |
| `emacs -l FILE` | 启动时加载指定的 Elisp 文件 |
| `emacs --eval EXPR` | 启动时执行指定的 Elisp 表达式 |
| `emacs --batch --eval EXPR` | 批量模式：不打开窗口，执行 EXPR 后退出（用于脚本/测试） |
| `emacs --no-desktop` | 不恢复桌面（即使 `desktop-save-mode` 开着） |
| `emacs +LINE FILE` | 打开 FILE 并把 point 放到第 LINE 行 |
| `emacs +LINE:COLUMN FILE` | 打开 FILE 并把 point 放到指定行列 |
| `emacs --daemon` | 以「守护进程」模式启动（不打开 frame，等 `emacsclient` 连接） |

`-Q` 是调试神器：如果你怀疑某个包或 init 配置导致问题，用 `emacs -Q` 启动一个完全干净的环境，能立刻定位是不是你的配置问题。

## 22.4 Emacs Server 与 `emacsclient`

如果你用 Emacs 的图形界面，但有时需要从终端或别的程序（比如 git commit 编辑器）里把文件送进已开的 Emacs，可以用 **Emacs Server**。

### 启用 server

在 init 文件里加：

```elisp
;; ~/.emacs.d/init.el
(server-start)
```

或者临时启用：`M-x server-start`。

### 用 `emacsclient` 送文件

Emacs 已经在跑（且 server 开着）的情况下，从 shell 里：

```bash
emacsclient foo.txt
```

这会把 `foo.txt` 送进**已开的 Emacs** 里打开，而不是启动一个新的 Emacs 进程。编辑完后在 Emacs 里按 `C-x #`（`server-edit`）告诉 `emacsclient` 编辑结束，shell 命令就返回了。

### 作为 git 编辑器

```bash
git config --global core.editor "emacsclient -t"
```

`-t` 表示在终端里打开（如果你已经在图形 Emacs 里，去掉 `-t` 也行，会在图形 frame 里打开）。

### 守护进程模式

如果你想让 Emacs 在后台一直跑着（像 daemon），启动时：

```bash
emacs --daemon
```

然后用 `emacsclient -t`（终端）或 `emacsclient -c`（新建图形 frame）连接。退出时用 `C-x C-c` 会**杀掉整个 daemon**，所以通常不这么退出——而是让 daemon 一直跑，只在需要时连接。

## 22.5 小结

- `desktop-save-mode` 保存/恢复整个桌面（buffer、位置、window 配置）。
- 书签（`C-x r m`/`C-x r b`）是跨会话的位置标记，自动持久化。
- 启动选项 `-q`/`-Q`/`-nw`/`-l`/`--eval`/`--batch`/`--no-desktop`/`+LINE`/`--daemon` 各有用途。
- `server-start` + `emacsclient` 实现「从外部把文件送进已开的 Emacs」。

---

上一章：[21 · 安装扩展包](21-packages.md) ｜ 下一章：[23 · 出问题时](23-troubleshooting.md) ｜ 返回：[使用 Emacs 教程](README.md)
