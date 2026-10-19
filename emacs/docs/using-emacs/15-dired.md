# 15 · Dired：目录与文件管理器

Dired（Directory Editor）是 Emacs 内置的文件管理器。它把一个目录的内容列在一个 buffer 里，然后你可以用键盘在这个 buffer 中浏览、打开、重命名、复制、删除文件——甚至批量操作。

Dired 不是一个"另外的工具"——它就是一个 Emacs buffer，用的是 Dired mode（一种 major mode）。这意味着你在 Emacs 里学到的所有文本操作能力（搜索、标记、region、宏）在 Dired 里都能用。

## 15.1 进入 Dired

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x d` | `dired` | 打开一个目录的 Dired buffer |
| `C-x 4 d` | `dired-other-window` | 在另一个 window 打开 Dired |
| `C-x 5 d` | `dired-other-frame` | 在新 frame 打开 Dired |
| `C-x C-j` | `dired-jump` | 打开当前 buffer 所在目录的 Dired |

`C-x d` 后在 minibuffer 里输入目录路径，回车。你也可以输入带通配符的文件名模式，如 `~/foo/*.el`，Dired 只列出匹配的文件。

`C-x C-f`（`find-file`）输入一个目录名也能进入 Dired——它和 `C-x d` 的效果一样。

`C-x C-j`（`dired-jump`）打开当前 buffer 对应文件所在目录的 Dired，并把光标定位到该文件那一行。这在编辑文件时想看看同目录还有什么文件特别方便。

变量 `dired-listing-switches` 控制传给 `ls` 的选项，默认包含 `-l`（长格式）。你可以用前缀参数临时覆盖：`C-u C-x d` 会在 minibuffer 里让你输入 `ls` 选项。

## 15.2 Dired Buffer 的结构

进入 Dired 后，你看到的 buffer 大致是这样的：

```
  /home/user/projects/emacs/:
  total 42
  -rw-r--r--  1 user staff   847 Oct 12 10:30 README.md
  -rw-r--r--  1 user staff  2048 Oct 12 11:00 init.el
  drwxr-xr-x  3 user staff    96 Oct 11 09:15 lisp/
  -rw-r--r--  1 user staff 15360 Oct 12 14:22 notes.txt
  -rw-r--r--  1 user staff   512 Oct 10 08:00 old-backup.el~
```

第一行是目录名。接下来是 `ls -l` 的输出——每行一个文件，显示权限、所有者、大小、日期、文件名。

**关键认识**：这个 buffer 里的文本是**只读的**（你不能像编辑普通文件那样直接打字修改它）。Dired 把字母键重新绑定成了文件操作命令。光标所在行的文件就是"当前文件"——大多数 Dired 命令都作用于当前文件。

## 15.3 在 Dired 中移动

Dired mode 重新定义了一些移动键，使它们自动跳到文件名所在位置（而不是行首的权限字段）：

| 键 | 命令 | 作用 |
|---|---|---|
| `n` / `SPC` | `dired-next-line` | 下一行（跳到文件名处） |
| `p` | `dired-previous-line` | 上一行 |
| `^` | `dired-up-directory` | 打开上级目录 |
| `j` | `dired-goto-file` | 输入文件名，跳到该行 |

`SPC` 等价于 `n`——向下移动是 Dired 里最频繁的操作，所以给它一个最容易按的键。`DEL` 向上移动同时取消标记（下一节讲）。

`^` 相当于在当前 Dired buffer 里打开 `..`。

`j` 在文件很多的目录里特别有用：输入文件名（支持补全），光标直接跳到那一行。

`M-s f C-s`（`dired-isearch-filenames`）只在文件名中搜索，忽略权限、大小等其他文本。

## 15.4 打开文件

| 键 | 命令 | 作用 |
|---|---|---|
| `RET` / `f` | `dired-find-file` | 打开当前文件（目录则进入该目录） |
| `o` | `dired-find-file-other-window` | 在另一个 window 打开 |
| `C-o` | `dired-display-file` | 在另一个 window 打开但不切换过去 |

`RET` 和 `f` 是最常用的：如果当前行是文件，打开它；如果是目录，进入该目录的 Dired buffer（替换当前 buffer 的内容）。

`o` 在另一个 window 打开文件，Dired buffer 保持可见——适合快速预览多个文件。

`C-o` 类似但**不切换**到那个 window——你可以看一眼内容然后继续在 Dired 里操作。

## 15.5 标记（Mark）与标记删除（Flag）的区别

Dired 有两种"做记号"的方式，理解它们的区别很重要：

**标记（Mark，字符 `*`）**：用 `m` 给文件打 `*` 标记。标记的文件可以被 `C`（复制）、`R`（改名）、`D`（删除）、`!`（shell 命令）等批量操作命令选中。

**标记删除（Flag，字符 `D`）**：用 `d` 给文件打 `D` 标记。只有 `x` 命令会处理这些文件——执行真正的删除。

为什么要有两种？因为**删除是最危险的操作**。用 flag + 确认（`d` 标记、`x` 执行）的流程，你可以在真正删除之前检查一遍所有被标记的文件，发现误标了可以用 `u` 取消。

Dired buffer 里标记显示在每行最左边：

```
  /home/user/projects/:
  D old-file.el         ← 被标记删除（D）
    init.el             ← 无标记
  * notes.txt           ← 被标记（*），等待批量操作
    README.md           ← 无标记
```

## 15.6 标记与取消标记

| 键 | 命令 | 作用 |
|---|---|---|
| `m` | `dired-mark` | 给当前文件打 `*` 标记 |
| `u` | `dired-unmark` | 取消当前行的所有标记 |
| `DEL` | `dired-unmark-backward` | 上移一行并取消标记 |
| `d` | `dired-flag-file-deletion` | 给当前文件打 `D` 标记 |
| `U` / `* !` | `dired-unmark-all-marks` | 取消所有标记 |
| `t` | `dired-toggle-marks` | 反转所有 `*` 标记 |

`m` 和 `d` 都会自动移到下一行——所以你可以连续按 `m` 或 `d` 逐个标记多个文件。带数值参数 N 标记接下来 N 个文件。如果 region 激活，`m` 和 `u` 对 region 内所有文件操作。

`DEL` 是 `u` 加上向上移动——回看时随手按 `DEL` 取消不想删的文件，非常顺手。

`t`（`dired-toggle-marks`）把所有 `*` 标记去掉、把所有未标记的文件打上 `*`。这在"选中除了几个之外的所有文件"时特别有用：先 `m` 标记全部（或 `* *` 标记所有可执行文件、`* /` 标记所有目录），然后 `t` 反转。

## 15.7 批量标记命令

| 键 | 命令 | 作用 |
|---|---|---|
| `#` | `dired-flag-auto-save-files` | 标记所有自动保存文件（`#...#`）待删 |
| `~` | `dired-flag-backup-files` | 标记所有备份文件（`...~`）待删 |
| `.` | `dired-clean-directory` | 标记多余的备份文件待删 |
| `% m REGEXP RET` | `dired-mark-files-regexp` | 标记文件名匹配正则的文件 |
| `% d REGEXP RET` | `dired-flag-files-regexp` | 标记文件名匹配正则的文件待删 |

`#` 和 `~` 是清理临时文件的利器——`#` 标记所有 `#filename#` 格式的自动保存文件，`~` 标记所有 `filename~` 格式的备份文件。标记后 `x` 一次性删除。

`% m` 用正则表达式批量标记。例如 `% m \.log$ RET` 标记所有 `.log` 结尾的文件。

## 15.8 执行操作

### 15.8.1 删除

| 键 | 命令 | 作用 |
|---|---|---|
| `x` | `dired-do-flagged-delete` | 删除所有 `D` 标记的文件 |
| `D` | `dired-do-delete` | 删除当前文件（或所有 `*` 标记的文件） |

`x` 处理的是 `D` 标记（flag）的文件。它会列出所有待删文件名，要求你输入 `yes` 确认。确认后文件被删除，对应行也从 Dired buffer 里消失。回答 `no` 或 `C-g` 则取消。

`D` 处理的是 `*` 标记的文件——如果没有 `*` 标记，就只删当前文件。与 `x` 的区别是：`D` 不需要先打 flag 再统一执行，适合你已经用 `m` 选好文件的场景。

### 15.8.2 复制与改名

| 键 | 命令 | 作用 |
|---|---|---|
| `C` | `dired-do-copy` | 复制文件 |
| `R` | `dired-do-rename` | 改名（或移动）文件 |

`C` 和 `R` 都要求输入一个目标路径。如果目标是目录，文件复制/移动到该目录下；如果操作的是单个文件且目标不是目录，则相当于"另存为"。

操作对象的选择逻辑：如果有 `*` 标记的文件，操作所有标记的文件；否则操作当前文件；带数值参数 N 则操作当前行开始的 N 个文件。

`R` 在单个文件时是改名，多个文件时是移动到目标目录——这和 shell 的 `mv` 行为一致。

### 15.8.3 链接

| 键 | 命令 | 作用 |
|---|---|---|
| `H` | `dired-do-hardlink` | 创建硬链接 |
| `S` | `dired-do-symlink` | 创建符号链接 |

用法与 `C`、`R` 类似——输入目标路径，对 `*` 标记的文件或当前文件创建链接。

### 15.8.4 其他文件操作

| 键 | 命令 | 作用 |
|---|---|---|
| `Z` | `dired-do-compress` | 压缩/解压缩文件 |
| `A` | `dired-do-find-regexp` | 在所有标记文件中搜索正则 |
| `M` | `dired-do-chmod` | 修改文件权限 |
| `G` | `dired-do-chgrp` | 修改文件所属组 |
| `O` | `dired-do-chown` | 修改文件所有者 |
| `T` | `dired-do-touch` | 修改文件时间戳 |
| `w` | `dired-copy-filename-as-kill` | 把文件名复制到 kill ring |
| `+` | `dired-create-directory` | 创建新目录 |

`Z` 对已压缩文件会执行解压缩，对未压缩文件执行压缩。对目录则打包成 `.tar.gz`。

`A` 在所有标记文件中搜索正则表达式（如果没标记则搜索当前文件），结果显示在 `*xref*` buffer 里——可以逐个跳转查看。

`w` 把文件名复制到 kill ring，方便你在其他 buffer 里 `C-y` 粘贴。带 `C-u` 参数复制相对路径，带 `0` 参数复制绝对路径。

## 15.9 Shell 命令

| 键 | 命令 | 作用 |
|---|---|---|
| `!` | `dired-do-shell-command` | 对文件执行 shell 命令 |
| `&` | `dired-do-async-shell-command` | 异步执行 shell 命令 |
| `X` | `dired-do-shell-command` | `!` 的同义词 |

`!` 读入一个 shell 命令，然后对选中的文件执行。命令字符串里：

- `*`（前后有空格的）被替换为所有文件名的列表，命令只执行一次。例如 `! tar cf archive.tar * RET` 把所有文件打包。
- `?` 被替换为当前文件名，命令对每个文件各执行一次。例如 `! gzip ? RET` 逐个压缩。
- 如果命令里既没有 `*` 也没有 `?`，文件名被追加到命令末尾，每个文件执行一次。

`&` 与 `!` 类似但是异步执行——命令在后台跑，不阻塞 Emacs。

## 15.10 刷新与退出

| 键 | 命令 | 作用 |
|---|---|---|
| `g` | `revert-buffer` | 重新读取目录，刷新 Dired buffer |
| `q` | `quit-window` | 关闭 Dired buffer（或 bury 它） |

`g` 在你用 shell 命令创建/删除了文件之后特别有用——Dired 不会自动更新，按 `g` 重新读取目录。

`q` 关闭当前 Dired window。如果这个 window 是专门为 Dired 创建的，window 也会被删除。

## 15.11 正则批量改名

`% R`（`dired-do-rename-regexp`）用正则表达式批量改名。它读入一个正则和一个替换串，对所有 `*` 标记的文件名（或当前文件名）做替换。

例如，把所有 `.txt` 文件改成 `.md`：

```
% R \.txt$ RET .md RET
```

这比在 shell 里写循环要直观得多。

## 15.12 Wdired：用编辑文本的方式操作文件

Dired buffer 默认只读。但你可以按 `C-x C-q`（命令 `dired-toggle-read-only`）进入 **Wdired mode**——在这个 mode 下，文件名变成了可编辑的文本。

在 Wdired mode 里：

- 直接修改文件名 = 改名
- 删除文件名 = 标记删除
- 修改文件路径 = 移动文件
- 修改符号链接的目标 = 改链接指向

编辑完后 `C-c C-c`（`wdired-finish-edit`）确认并执行所有变更，回到普通 Dired mode。`C-x C-q` 在 Wdired mode 里绑定的是 `wdired-exit`，也可以退出。

Wdired 的威力在于你可以用 Emacs 的所有文本编辑能力来操作文件名——正则替换（`M-x query-replace-regexp`）、矩形编辑（`C-x r`）、键盘宏等等。批量改名时这比 `% R` 更灵活。

## 15.13 小结

- `C-x d` 进入 Dired，`C-x C-j` 跳到当前文件所在目录。
- Dired buffer 是只读的，字母键绑定为文件操作命令。
- `n`/`SPC`/`p` 移动，`RET`/`f` 打开，`^` 上级，`o` 另一 window 打开。
- **标记 `*`**（`m`）用于批量操作；**标记删除 `D`**（`d`）用于 `x` 统一删除。
- `C` 复制、`R` 改名、`D` 删除（对 `*` 标记）、`!` shell 命令。
- `%` 系列用正则批量标记/改名。
- `C-x C-q` 进入 Wdired mode，用编辑文本的方式操作文件名。
- `g` 刷新，`q` 退出。

下一章讲键盘宏——把一系列按键录下来，然后一键重复播放。

---

上一章：[14 · 程序编辑](14-programs.md) ｜ 下一章：[16 · 键盘宏](16-keyboard-macros.md) ｜ 返回：[使用 Emacs 教程](README.md)
