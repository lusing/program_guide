# 19 · Shell、编译与调试入口

这一章讲 Emacs 怎么跟外部程序打交道：跑一次性 shell 命令、开一个交互式 shell、编译项目、搜索代码、以及启动调试器。这些功能的共同点是 Emacs 作为「前端」管理子进程——你不用离开 Emacs 就能完成从编译到调试的整个开发流程，而且 Emacs 能把编译器的错误信息变成可点击的链接、把 grep 的搜索结果变成可跳转的列表。

## 19.1 一次性 Shell 命令

最简单的用法：跑一条 shell 命令、看结果、回来继续编辑。

| 键 | 命令 | 作用 |
|---|---|---|
| `M-!` | `shell-command` | 读一条 shell 命令并执行 |
| `M-\|` | `shell-command-on-region` | 把选区内容作为 shell 命令的标准输入 |
| `M-&` | `async-shell-command` | 异步执行 shell 命令 |

### `M-!`（`shell-command`）

按 `M-!`，Emacs 在 minibuffer 里提示你输入一条 shell 命令。输入完按 `RET`，Emacs 启动一个子 shell 执行这条命令。

命令的输出分两种情况：

- **输出很短**（一行两行）：直接显示在 echo area（屏幕底部）。
- **输出比较长**：显示在 `*Shell Command Output*` buffer 里。这个 buffer 的名字由变量 `shell-command-buffer-name` 控制。

命令的默认工作目录是当前 buffer 的 default directory（见第 7 章）。

**同步 vs 异步**：如果命令末尾没有 `&`，命令**同步**执行——Emacs 会等你命令跑完才能继续操作。如果等太久想中断，按 `C-g`，Emacs 会发 `SIGINT` 给子进程；再按一次 `C-g` 发 `SIGKILL`（无法忽略）。如果命令末尾有 `&`，命令**异步**执行，你可以继续用 Emacs。

**把输出插入当前 buffer**：加数字前缀参数。`M-1 M-!` 会把命令的终端输出插入到当前 buffer（而不是 `*Shell Command Output*`）。比如 `M-1 M-! cat foo.txt RET` 会把 `foo.txt` 的内容插入到当前 buffer 的光标位置。默认情况下 point 在输出之后、mark 在输出之前。

**`M-|`（`shell-command-on-region`）**：跟 `M-!` 类似，但会把当前选区的内容作为 shell 命令的标准输入。比如你选了一段 JSON，然后 `M-| python3 -m json.tool RET`，Emacs 会把选区内容喂给 `python3 -m json.tool`，输出显示在 `*Shell Command Output*` buffer 里。加数字前缀参数会用输出**替换**选区——这就变成了一个「过滤」操作：选区内容 → shell 命令处理 → 替换原内容。

**`M-&`（`async-shell-command`）**：等同于在 `M-!` 的命令末尾加 `&`。命令在后台跑，输出实时写入 `*Async Shell Command*` buffer（由 `shell-command-buffer-name-async` 控制）。适合跑耗时较长的命令——比如 `M-& make -j4 RET`，你可以继续编辑，编译在后台跑。

如果你同时跑多个异步命令，它们可能会争抢同一个输出 buffer。变量 `async-shell-command-buffer` 控制冲突时的行为（比如重命名旧 buffer、为新命令创建新 buffer 等）。

### 使用哪个 shell

这些命令使用的 shell 由变量 `shell-file-name` 指定。默认值取决于 Emacs 启动时的 `SHELL` 环境变量。如果 default directory 是远程的（通过 TRAMP），默认用 `/bin/sh`。

## 19.2 交互式 Shell

`M-!` 适合跑「一条命令就走」的场景。如果你想长时间跟一个 shell 交互——跑多条命令、用 shell 的管道和重定向、甚至跑 `vim`（虽然没意义）——用 `M-x shell`。

`M-x shell` 创建（或重新使用）一个叫 `*shell*` 的 buffer，在里面启动一个 shell 子进程。这个 buffer 就是你的 shell 终端：shell 的输出显示在 buffer 里，你在这个 buffer 的末尾输入命令、按 `RET` 发送给 shell。

前缀参数 `C-u M-x shell` 会让你输入一个新的 buffer 名——这样可以同时开多个 shell。

### Shell 模式（Shell Mode）

`*shell*` buffer 使用 Shell mode，一个专门用来跟 shell 子进程交互的 major mode。它基于更通用的 Comint mode（Communication with Inferior Processes），很多键绑定实际来自 Comint mode。

以下是 Shell 模式的核心键绑定（来自 comint-mode-map 和 shell-mode-map）：

| 键 | 命令 | 作用 |
|---|---|---|
| `RET` | `comint-send-input` | 把当前行（从 prompt 之后到行尾）作为输入发送给 shell |
| `TAB` | `completion-at-point` | 补全命令名或文件名 |
| `M-p` | `comint-previous-input` | 取上一条 shell 命令（历史） |
| `M-n` | `comint-next-input` | 取下一条 shell 命令（历史） |
| `M-r` | `comint-history-isearch-backward-regexp` | 在 shell 命令历史里做正则搜索 |
| `C-d` | `comint-delchar-or-maybe-eof` | 在 buffer 末尾发送 EOF；否则删除一个字符 |
| `C-c C-c` | `comint-interrupt-subjob` | 中断 shell 或其当前子任务 |
| `C-c C-o` | `comint-delete-output` | 删除上一条 shell 命令的输出 |
| `C-c C-u` | `comint-kill-input` | 删除所有待发送的输入 |
| `C-c C-a` | `comint-bol-or-process-mark` | 跳到当前行的 prompt 之后；再按一次跳到 process mark |
| `C-c SPC` | `comint-accumulate` | 插入换行但不发送——累积多行输入 |
| `C-c .` | `comint-insert-previous-argument` | 插入上一条命令的最后一个参数（类似 bash 的 `ESC .`） |
| `C-c C-r` | `comint-show-output` | 滚动到上一条命令输出的开头 |
| `C-c C-e` | `comint-show-maximum-output` | 滚动到 buffer 末尾 |

几个要点：

**`RET` 发送当前行**：你不需要把光标移到 buffer 末尾才能输入命令。只要光标在某一行上，`RET` 就会把那一行（prompt 之后的部分）发送给 shell。这意味着你可以滚动回之前的命令、修改、再按 `RET` 重新执行。

**`M-p` / `M-n` 翻历史**：跟 minibuffer 历史一样，`M-p` 取更早的命令、`M-n` 取更晚的命令。每次按键都会替换 buffer 末尾的当前输入。这些命令操作的是一个独立的历史列表，不是 buffer 里的文本——所以你删改 buffer 内容不会影响历史。

**`M-r` 搜索历史**：按 `M-r` 后开始输入正则表达式，Emacs 做增量搜索，找到匹配的历史命令后按 `RET` 把它放到命令行。

**`C-c C-o` 清屏**：删除上一条命令的输出。如果输出太长挡住了你关心的内容，用它清掉。加前缀参数会把删除的文本存进 kill ring。

**目录跟踪**：Emacs 会尝试跟踪 shell 的当前目录——它通过监控你输入的 `cd` 命令以及 shell 发出的 OSC 转义序列来更新 buffer 的 default directory。为了让目录跟踪更可靠，可以在 shell 的 prompt 里加上 OSC 7 转义序列：

```bash
printf "\e]7;file://%s%s\e\\" "$HOSTNAME" "$PWD"
```

然后在 init 文件里让 Emacs 处理这些转义序列：

```elisp
(add-hook 'comint-output-filter-functions #'comint-osc-process-output)
```

### 使用哪个 shell

`M-x shell` 使用的 shell 由以下优先级决定：

1. 变量 `explicit-shell-file-name`（如果非 `nil`）。
2. 环境变量 `ESHELL`（如果存在）。
3. 变量 `shell-file-name`（跟 `M-!` 用的一样）。

Emacs 启动 shell 时会先读取 `~/.emacs_SHELLNAME`（比如 `~/.emacs_bash`）作为输入；如果找不到，再试 `~/.emacs.d/init_SHELLNAME.sh`（比如 `~/.emacs.d/init_bash.sh`）。你可以在这些文件里设置 shell 选项。

Emacs 在子 shell 里设置环境变量 `INSIDE_EMACS` 为 `VERSION,comint`（如 `31.1,comint`），外部程序可以据此判断自己是否运行在 Emacs 的子 shell 里。

### 彩色输出

把 `comint-terminfo-terminal` 设成 `"dumb-emacs-ansi"` 可以让很多命令在 Shell buffer 里输出彩色文本：

```elisp
(setq comint-terminfo-terminal "dumb-emacs-ansi")
```

## 19.3 编译（Building）

`M-x compile` 让你在 Emacs 里跑编译命令（如 `make`），并把编译输出收集到一个专门的 buffer 里。

### 运行编译

```
M-x compile RET
```

Emacs 在 minibuffer 里提示你输入编译命令。默认值是 `make -k`（`-k` 让 make 遇到错误后继续编译尽可能多的文件）。直接 `RET` 接受默认值，或者输入你自己的命令。

编译在异步子进程里运行，输出写入 `*compilation*` buffer。Emacs 不会自动切到这个 buffer——它在另一个 window 里显示但不选中它。你可以在 mode line 里看到 `Compiling` 字样和已经发现的错误/警告数量。编译完成后 mode line 会显示 `exit`（正常退出，跟退出码）或 `signal`（被信号终止）。

编译命令的工作目录是当前 buffer 的 default directory。所以通常在项目根目录的源文件里执行 `M-x compile` 就能让 make 找到 Makefile。

**重新编译**：`M-x recompile` 用上次相同的命令再跑一次。在 `*compilation*` buffer 里可以直接按 `g` 重新编译。

**终止编译**：`M-x kill-compilation`。

**前缀参数**：`C-u M-x compile` 会让 `*compilation*` buffer 使用 Comint mode，这样可以交互式地输入密码等凭证。

变量 `compile-command` 保存了上次的编译命令。文件可以通过 file-local variable 指定自己的 `compile-command`——这样在特定项目里 `M-x compile` 总是用对的命令。

### Compilation Mode

`*compilation*` buffer 使用 Compilation mode。这个模式的核心功能是**把编译器的错误信息变成可点击的超链接**：

- 把光标移到一条错误信息上按 `RET`，Emacs 会在另一个 window 里打开对应的源文件、跳到出错的那一行。
- 鼠标点击错误信息也能跳转。

| 键 | 命令 | 作用 |
|---|---|---|
| `RET` | `compile-goto-error` | 跳到光标所在错误信息对应的源码位置 |
| `M-n` | `compilation-next-error` | 把光标移到下一条错误信息（不跳转源码） |
| `M-p` | `compilation-previous-error` | 把光标移到上一条错误信息 |
| `M-}` | `compilation-next-file` | 跳到下一个文件的错误 |
| `M-{` | `compilation-previous-file` | 跳到上一个文件的错误 |
| `C-c C-f` | `next-error-follow-minor-mode` | 开关 Next Error Follow 模式——光标移动自动显示对应源码 |
| `SPC` | `scroll-up-command` | 向下翻一屏 |
| `DEL` | `scroll-down-command` | 向上翻一屏 |
| `g` | `recompile` | 重新编译 |

### `C-x \``（`next-error`）：在错误间跳转

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x \`` | `next-error` | 跳到下一条编译错误/搜索匹配 |
| `M-g M-n` | `next-error` | 同上 |
| `M-g n` | `next-error` | 同上 |
| `M-g M-p` | `previous-error` | 跳到上一条编译错误/搜索匹配 |
| `M-g p` | `previous-error` | 同上 |

`C-x \`` 是开发中最常用的键之一。它不限于 `*compilation*` buffer——**任何 buffer 都能用**。第一次按的时候，Emacs 找到当前关联的错误列表（通常是最近的编译或 grep 结果），跳到第一条错误。之后每次按都跳到下一条。

`next-error` 的智能之处在于它会自动寻找错误来源：先看当前 buffer 是不是包含错误信息（比如你正在 `*compilation*` buffer 里），然后在当前 frame 的 window 里找，再找之前用过的错误 buffer。

`C-u M-g M-n` 从头开始——跳到第一条错误。

默认情况下 `next-error` 会跳过比 warning 级别低的消息。变量 `compilation-skip-threshold` 控制：`1`（默认）跳过 warning 以下的；`2` 跳过 warning 只停 error；`0` 每条都停。

跳到源码位置时，Emacs 会短暂高亮出错的那一行。高亮持续时间由 `next-error-highlight` 控制。

## 19.4 Grep 搜索

Emacs 可以跑 `grep` 并把结果收集到一个 buffer 里，结果中的每一行都是可点击的超链接——跟编译错误一样的交互方式。

| 命令 | 作用 |
|---|---|
| `M-x grep` | 在当前目录跑 grep |
| `M-x lgrep` | 交互式 grep（分别提示正则、文件名、目录） |
| `M-x rgrep` | 递归 grep（搜索目录树） |
| `M-x grep-find` / `M-x find-grep` | 用 `find` + `grep` 搜索 |
| `M-x zrgrep` | 用 `zgrep` 搜索 gzip 压缩文件 |

`M-x grep` 提示你输入完整的 grep 命令行（包括正则和文件名）。如果加了前缀参数，Emacs 会把光标处的标识符（identifier）作为默认搜索词。

`M-x lgrep` 和 `M-x rgrep` 更友好——它们分别问你三个问题：搜什么正则、搜哪些文件（支持通配符）、在哪个目录下搜。`lgrep` 搜当前目录，`rgrep` 递归搜索整个目录树。`rgrep` 会自动跳过 `grep-find-ignored-directories` 里列出的目录（默认包含 `.git`、`.svn` 等版本控制目录）。

grep 的输出进入 `*grep*` buffer，使用 Grep mode（Compilation mode 的变体）。你可以用同样的方式跳转：

- `RET` 或鼠标点击跳转到匹配行。
- `M-g M-n` / `M-g M-p` 在匹配间前后跳转。
- `M-n` / `M-p` 在匹配行之间移动光标但不跳转源码。

在 `*grep*` buffer 里按 `e` 进入 Grep Edit mode，可以直接编辑匹配行——修改会同步反映到源文件 buffer。按 `C-c C-c` 退出编辑模式。

变量 `grep-save-buffers` 控制跑 grep 前是否保存 buffer。默认值 `ask` 会问你要不要保存；`t` 直接全部保存；`nil` 不保存。

## 19.5 调试器（GUD）

Emacs 可以通过 GUD（Grand Unified Debugger）界面跟各种调试器交互。GUD 提供了一套统一的键绑定，不管你用的是 GDB、LLDB、pdb 还是其他调试器。

| 命令 | 调试器 |
|---|---|
| `M-x gdb` | GDB（完整的 IDE 式界面） |
| `M-x gud-gdb` | GDB（基本的交互 buffer） |
| `M-x lldb` | LLDB |
| `M-x pdb` | Python debugger |
| `M-x jdb` | Java debugger |
| `M-x perldb` | Perl debugger |

每个命令都会在 minibuffer 里提示你输入调试器命令行（包括可执行文件名）。初始内容会预填调试器名和常用选项，有时还会猜你要调试的可执行文件。

`M-x gdb` 和 `M-x gud-gdb` 的区别：

- `M-x gdb` 提供一个完整的 IDE 式界面：源码窗口、断点列表、栈帧列表、变量查看等分窗口显示。功能更强大。
- `M-x gud-gdb` 只提供一个交互 buffer，跟终端里用 GDB 类似，但可以在源码上设断点等。

GUD 的统一键绑定让你在切换不同调试器时不需要重新学。比如在源码 buffer 里，`C-x SPC`（`gud-break`）在当前行设/取消断点——不管你用的是哪个调试器。

TRAMP 还支持远程调试——调试器和被调试程序都在同一台远程机器上运行。

## 19.6 小结

- `M-!` 跑一次性 shell 命令，输出到 `*Shell Command Output*`；`M-1 M-!` 把输出插入当前 buffer。
- `M-|` 把选区内容喂给 shell 命令；加前缀参数用输出替换选区。
- `M-&` 异步跑 shell 命令。
- `M-x shell` 开交互式 shell buffer。Shell mode 里 `RET` 发送、`M-p`/`M-n` 翻历史、`C-c C-c` 中断。
- `M-x compile` 跑编译，`*compilation*` buffer 里错误可点击跳转。
- `C-x \``（`next-error`）在编译错误/grep 匹配间跳转——可以在任何 buffer 里用。
- `M-x grep` / `M-x lgrep` / `M-x rgrep` 搜索代码，结果同样可跳转。
- `M-x gdb` / `M-x gud-gdb` 启动 GDB 调试器。

---

上一章：[18 · 拼写检查与缩写](18-spelling-and-abbrevs.md) ｜ 下一章：[20 · 定制 Emacs](20-customization.md) ｜ 返回：[使用 Emacs 教程](README.md)
