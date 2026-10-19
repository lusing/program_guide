# 09 · 文件操作

操作系统把数据永久保存在一个个有名字的**文件**里，所以你编辑的文本几乎总是从文件来、最终回文件去。这一章讲 Emacs 处理文件的完整生命周期：怎么把文件读进来（visit）、怎么把改动写回去（save）、Emacs 如何在背后给你留后路（备份文件、自动保存）、怎么反悔（revert）、怎么比较、以及一些零散但常用的文件操作。

## 9.1 核心机制：文件、buffer、visit 与 save

先把这一章反复出现的模型立起来：

- **文件**存在于磁盘上，是持久的。
- **buffer** 存在于 Emacs 内存里，是你实际编辑的东西。
- **访问（visit）一个文件**，就是让 Emacs 把这个文件的内容读进一个 buffer。之后你的所有编辑命令都作用在 buffer 里的这份**副本**上，磁盘上的文件纹丝不动。
- **保存（save）一个 buffer**，就是把 buffer 的当前内容写回它所访问的文件，让你的改动落到磁盘上。

这个「先读副本、改副本、显式写回」的机制是理解 Emacs 一切文件行为的钥匙：

1. Emacs 为**每个**你访问的文件建一个**独立**的 buffer。同一个文件被访问两次不会读两份——第二次 `C-x C-f` 同一个文件，Emacs 直接切换到已存在的那个 buffer。
2. 你在 buffer 里改了东西但还没保存，就说这个 buffer 是**被修改的（modified）**。mode line 左端会出现两个星号 `**` 提醒你。改动只在内存里，断电就没了——所以下面 9.6、9.7 讲的备份和自动保存机制才那么重要。
3. 保存之后 buffer 回到「未修改」状态，星号消失。

顺带一提：Emacs 编辑远程机器上的文件（`/ssh:user@host:/path` 这类名字）用的是内置的 Tramp 机制，用起来和本地文件几乎一样，本章不展开。

## 9.2 访问文件：`C-x C-f`

访问文件的命令是 `C-x C-f`（`find-file`）。「find」的意思是：如果这个文件已经有 buffer，就**找**到它切过去；没有才新建。

```text
C-x C-f ~/notes/todo.txt RET
```

按下 `C-x C-f` 后，Emacs 在底部的 minibuffer 里提示 `Find file:`，并**预填了当前 buffer 的默认目录**（见下），你补全或输入文件名后按 `RET`。成功的话屏幕上出现文件内容，mode line 上显示 buffer 名——buffer 名通常取文件名去掉目录部分，比如 `/usr/rms/emacs.tex` 访问后 buffer 叫 `emacs.tex`；如果同名 buffer 已存在，Emacs 会加上基于目录的后缀（如 `emacs.tex<tmp>`）保证唯一。

几个重要行为和技巧：

**新建文件也用同一个命令。** 输入一个不存在的文件名按 `RET`，echo area 显示 `(New file)`，你得到一个空 buffer，之后第一次保存时文件才被真正创建。（如果你刚用补全补出一个不存在的名字就按 `RET`，Emacs 会显示 `[Confirm]` 要求再按一次 `RET` 确认——这是防手滑的保护。）

**默认目录与相对路径。** 每个 buffer 有一个 buffer 局部变量 `default-directory`，记录它的默认目录。访问文件时它被设成该文件所在目录；用 `C-x b` 新建的不访问文件的 buffer 则继承当时的当前 buffer。`Find file:` 提示里预填的就是它。你输入的相对文件名都相对于它解析。`M-x pwd` 可以查看当前 buffer 的默认目录，`M-x cd` 可以修改它（不改 buffer 访问的文件名）。

**文件名里的快捷写法。** 在 minibuffer 里输入文件名时：
- `~/` 展开为你的主目录；
- `//` 会丢掉第二个斜杠之前的所有内容（用来快速「重起炉灶」输绝对路径）；
- `$VAR` 或 `${VAR}` 展开为环境变量（如果没定义，`$` 就是它自己；文件名里真有 `$` 就写 `$$`）。

**补全。** 文件名输入支持 Tab 补全，扩展名在变量 `completion-ignored-extensions` 里的文件（`.o`、`.pyc` 之类）在补全时会被忽略，让候选列表更干净。

**通配符。** 如果文件名里含 shell 风格通配符 `*`、`?`、`[...]`，`C-x C-f` 会访问**所有**匹配的文件，每个一个 buffer。（想在文件名里输入字面的 `?` 得用 `C-q ?`。）这个行为由变量 `find-file-wildcards` 控制。

**输入目录名会进 Dired。** 如果 `C-x C-f` 你给的是一个目录，Emacs 会启动目录编辑器 Dired 列出它的内容（可用变量 `find-file-run-dired` 关掉）。

**大文件。** 超过变量 `large-file-warning-threshold`（默认约 10 MB）的文件，Emacs 会先问你：答 `y` 照常访问，答 `l` 以「字面」方式访问（关掉各种昂贵特性，导航编辑更快）。

## 9.3 访问的姊妹命令

围绕 `find-file` 有一圈变体，都值得一知道：

- `C-x C-r`（`find-file-read-only`）：以**只读**方式访问，看得改不得。适合翻文档、看别人不该动的文件。
- `C-x C-v`（`find-alternate-file`）：**换**一个文件访问——先杀掉当前 buffer（若有改动会先问你要不要保存），再访问新文件。专治「文件名打错了一个字母」：它预填整个当前文件名、光标停在目录之后，改起来最快。
- `C-x 4 C-f`（`find-file-other-window`）：在**另一个 window** 里访问文件，当前 window 显示的内容不动。
- `C-x 5 C-f`（`find-file-other-frame`）：在**新 frame** 里访问文件。

后两个的 `C-x 4`、`C-x 5` 是前缀键，含义见下一章。

`M-x find-file-literally` 则完全不做任何转换（编码、格式检测等都不做）地访问文件，偶尔用于处理「非正常」文件。

## 9.4 保存文件：`C-x C-s` 与 `C-x s`

**保存当前 buffer** 用 `C-x C-s`（`save-buffer`）。保存完 echo area 显示：

```text
Wrote /u/rms/gnu/gnu.tasks
```

如果 buffer 本来就没被修改，保存是无意义的空操作，Emacs 显示 `(No changes need to be saved)`。这个「没事就不写盘」的细节值得知道：`C-x C-s` 按多少次都安全，不会平白刷文件的修改时间。

**保存一批 buffer** 用 `C-x s`（`save-some-buffers`）。它把所有被修改的 buffer 逐个问一遍，回答方式和查询替换（`M-%`）一致：

- `y` 或 `SPC`：保存这个，继续问下一个；
- `n` 或 `DEL`：不保存这个，继续问下一个；
- `!`：保存这个和其余所有，不再问；
- `q` 或 `RET`：到此为止，剩下的都不保存；
- `.`：保存这个，然后立即结束（连问都不问了）；
- `d`：先 diff 一下这个 buffer 和它的文件，看看要保存的是什么改动（调用 `diff-buffer-with-file`，见 9.9）；
- `C-r`：进入 View mode 看看这个 buffer，退出后回到提问；
- `M-~`：不保存，并且清掉它的修改标记（见下）。

退出 Emacs 的 `C-x C-c` 内部就是调 `save-some-buffers`，所以退出时你会看到同样的提问——这就是第 0 章说的「先兜住你的改动再走」。

**`M-~`（`not-modified`）**：告诉 Emacs「忘掉这个 buffer 被改过」。清了标记之后，`C-x s` 和 `C-x C-c` 都不会再对它提问。适合你改乱了但又不想 revert 的场景。加前缀参数（`C-u M-~`）则反过来，把干净的 buffer 标记为已修改。

**另存为：`C-x C-w`（`write-file`）**。它在 minibuffer 里读一个新文件名，把当前 buffer 的内容保存过去，并且让 buffer 从此访问新文件（等价于 `set-visited-file-name` + `C-x C-s`；目标文件已存在时会先要你确认）。如果新文件名暗示了别的 major mode，多数情况下会切过去。

相关的还有：

- `M-x set-visited-file-name`：只改「这个 buffer 将来保存到哪」的记录，不立即写盘，同时把 buffer 标记为已修改。
- `M-x rename-visited-file`：同上，但连磁盘上的文件一起重命名。
- `M-x write-region`：把**选区**（region）的内容写进指定文件——「只保存一部分」用的就是它。它的反面是 9.10 的 `insert-file`。`M-x append-to-file` 把选区追加到某文件末尾。

一个细节：对**不访问文件**的 buffer（比如 `C-x b` 随手建的），按 `C-x C-s` 的效果等同于 `C-x C-w`——它会问你要个文件名，然后就地保存。

## 9.5 修改标记与只读文件

前面说过，buffer 被修改时 mode line 左端显示 `**`。反过来，**只读** buffer 在 mode line 上显示 `%%`。

一个文件如果操作系统不让写、或被标记了只读位，Emacs 访问它时会把对应 buffer 也设成只读——这样你改了半天却发现保存不了的窘境就不会发生。想解除只读、允许编辑，按：

```text
C-x C-q
```

这个键是一个**开关**（toggle）：只读时按一下变为可写，可写时按一下变回只读。

**版本差异注意**：在 Emacs 31.1 里 `C-x C-q` 绑定的是 `read-only-mode`（一个 minor mode，开/关 buffer 的只读状态）；在较老的版本里绑的是 `toggle-read-only`。功能一样，只是命令换了名字——你在旧教程或旧配置里看到 `toggle-read-only` 不要困惑。

只读 buffer 里试图编辑，Emacs 会报错并提示你按 `C-x C-q` 解除只读。

## 9.6 备份文件：保存前的「上一版」

多数操作系统上，重写文件会直接毁掉旧内容。Emacs 不肯这么干：它在**真正写盘之前**，先把文件的旧内容复制到一个**备份文件（backup file）**里。

备份的规则值得记清楚：

- **只在这个 buffer 第一次保存时做备份。** 之后你再保存多少次，备份文件都保持不动——它永远是「你这次编辑会话开始前的版本」。杀掉 buffer 重新访问再保存，才会产生新备份。
- 默认备份文件名是原文件名后加 `~`：`eval.c` 的备份是 `eval.c~`。
- 如果权限不允许在原目录写备份，Emacs 退而写到 `~/.emacs.d/%backup%~`。

**编号备份**：Emacs 也可以为每个文件保留一系列编号备份 `eval.c.~1~`、`eval.c.~2~`……由变量 `version-control` 控制：

- `nil`（默认）：已经有编号备份的文件继续编号，其他文件做单一 `~` 备份；
- `t`：一律做编号备份；
- `never`：一律做单一备份。

环境变量 `VERSION_CONTROL` 在 Emacs 启动时也会按同样的语义设置这个变量。

总开关是变量 `make-backup-files`（默认 `t`）。受版本控制（如 git）管理的文件默认**不**做备份（`vc-make-backup-files` 默认为 `nil`），因为历史版本已经由 VCS 管着了。想让备份不落在原目录，可定制 `backup-directory-alist`。

保存时还能显式操纵备份：`C-u C-x C-s` 保存并安排下次保存时再做一次备份；`C-u C-u C-x C-s` 先把当前磁盘上的旧内容做成新备份、再保存；`C-u C-u C-u C-x C-s` 两件事都干。

**误区提醒**：备份只防「保存错了/覆盖旧版」，不防崩溃——崩溃时你的未保存改动根本还没到过磁盘上的原文件，管这个的是下一节的自动保存。

## 9.7 自动保存与崩溃恢复：`#file#`

**自动保存（auto-save）**是 Emacs 的防崩溃机制：每隔一阵子，Emacs 把每个访问文件的 buffer 的内容写到**另一个**文件里——**自动保存文件**，名字是原文件名前后各加一个 `#`：`foo.c` 的自动保存文件是 `#foo.c#`。为什么不直接写原文件？因为自动保存的时机你控制不了，把一个改了一半、你并不想落盘的状态写进原文件可能更糟。原文件只在你显式 `C-x C-s` 时才变。

何时触发自动保存：

- 敲字够多——每输入 `auto-save-interval` 个字符（默认 300）做一次；
- 停顿够久——闲置 `auto-save-timeout` 秒（默认 30 秒）后做一次；
- Emacs 收到致命错误时（包括从 shell `kill` 掉 Emacs、断网断线）。

自动保存发生时 echo area 会闪一句 `Auto-saving...`。文件 buffer 默认都开自动保存（变量 `auto-save-default` 为 `t`）；`M-x auto-save-mode` 对当前 buffer 开关它；`M-x do-auto-save` 立即手动做一次。你正常 `C-x C-s` 保存后，对应的 `#file#` 会被删掉——所以磁盘上看到孤零零的 `#foo.c#`，通常意味着「上次编辑没善终」。

一个贴心设计：当你在一个大 buffer 里**删掉了一大段文本**时，该 buffer 的自动保存会临时关闭——万一你是误删，自动保存文件里还留着被删的内容。恢复自动保存：`C-x C-s` 保存一次，或 `C-u 1 M-x auto-save-mode`。

**崩溃之后怎么捞回来**：

- `M-x recover-file RET foo.c RET`：访问 `foo.c`，然后（经你确认）把 `#foo.c#` 的内容装回 buffer。确认前 Emacs 会列出两个文件的大小和日期供你比较；如果自动保存文件更旧，它根本不会提议恢复。提问时答 `diff` 或 `=` 可以先看两者的差异再决定。恢复进 buffer 后记得 `C-x C-s`，捞回的内容才真正写进文件。
- `M-x recover-session`：整场崩溃（Emacs 挂了/机器挂了）后，恢复**上次会话里所有正在编辑的文件**。Emacs 把被中断会话的记录存在 `~/.emacs.d/auto-save-list/.saves-PID-HOSTNAME~`；这个命令列出候选会话让你挑（`C-c C-c` 确认），然后对当时的每个文件逐一问你要不要恢复。恢复完同样要保存才算数。

另外还有个可选的 `auto-save-visited-mode`（全局 minor mode）：让自动保存**直接保存进原文件**（闲置 5 秒触发，`auto-save-visited-interval` 可调），相当于「持续保存」。要不要用看个人口味。

## 9.8 反悔：revert-buffer

改了一堆又不想要了？两条路：`C-x u` 一路 undo 回去，或者更干脆的 **revert（还原）**——扔掉 buffer 里的全部改动，从磁盘重新读文件。

```text
M-x revert-buffer RET
```

Emacs 31.1 还给了个更快的键：`C-x x g`（`revert-buffer-quick`）——和 `revert-buffer` 一样，但提问更少：buffer 访问着文件且未被修改时它压根不问。buffer 被修改过时它仍会要你确认，毕竟 revert 会丢掉全部未保存改动。

几个值得知道的点：

- revert 后 buffer 标记为未修改，但**被 revert 掉的改动会作为一步进入 undo 历史**——后悔了后悔，`C-/` 还能把它们找回来。
- `revert-buffer` 会尽量让 point 停在还原前对应的文本位置；改动太大时可能停不准。
- 更保守的版本是 `revert-buffer-with-fine-grain`，尽力保留 marker、属性、overlay。
- 不访问文件的 buffer（如 Dired buffer）revert 的含义是「重新计算内容」；`C-x b` 建的普通 buffer 没有可还原的来源，revert 会报错。
- 想让某类文件被外部程序改动时**自动**还原（比如一直滚动的日志），要么设置变量 `revert-without-query`（正则表，匹配的文件悄悄自动 revert），要么开 `auto-revert-mode`。

## 9.9 比较文件

**`M-x diff`**：读两个文件名，跑系统的 `diff` 程序（选项来自变量 `diff-switches`，默认 `"-u"` 即 unified 格式），把差异显示在 `*diff*` buffer 里。这个 buffer 用的是 **Diff mode**——差异被组织成一个个 **hunk**（连续变更块），`M-n` / `M-p` 在 hunk 之间跳，`C-c C-a` 把 hunk 应用到源文件，`C-c C-b` 细化高亮当前 hunk。Diff buffer 本身可以像普通 buffer 一样编辑，Emacs 会即时修正 hunk 头里的行号，保证它仍是个合法补丁。

其他比较命令：

- `M-x diff-backup`：比较一个文件和它**最近的备份**（给它备份文件名则反向比较）。「我这次到底改了啥」一步到位。
- `M-x diff-buffer-with-file`：比较 buffer 和它的文件——预览「现在按 `C-x C-s` 会写进去什么改动」。
- `M-x diff-buffers`：比较任意两个 buffer。
- `M-x compare-windows`：比较当前 window 和上一个选中的 window 里、各自 point 之后的文本，跳到第一处不匹配。反复调用可以逐段扫差异；带数字前缀参数时忽略空白差异。
- **`M-x ediff`**：功能强得多的可视化比较/合并工具，三个 window 并排显示两个文件和差异，按键在差异间导航、选择取哪边。要认真做合并就用它。
- `M-x smerge-mode`：处理版本控制合并冲突留下的 `<<<<<<<`/`>>>>>>>` 标记的 minor mode，提供逐处「取哪边」的命令。

## 9.10 其他文件操作

- **`C-x i`（`insert-file`）**：把指定文件的内容**插入当前 buffer 的 point 处**——不新建 buffer，就是「把别的文件的内容搬进来」。插入内容之后的位置会被放进 mark ring（不激活选区），方便 `C-x C-x` 跳回去选中刚插入的整块。它的反面是 9.4 提过的 `M-x write-region`（把选区写出去）。`M-x insert-file-literally` 是零转换版本。
- **`M-x delete-file`**：删一个文件。默认**不进回收站**；想让删除命令走系统废纸篓，把变量 `delete-by-moving-to-trash` 设为 `t`（此时给 `delete-file` 加前缀参数则强制彻底删除）。`M-x move-file-to-trash` 无条件进废纸篓。受版本控制的文件应该用 `M-x vc-delete-file` 删。
- **`M-x copy-file` / `M-x rename-file`**：复制/重命名单个文件（目标存在会要确认）。批量操作这些还是 Dired 更顺手。
- **`M-x set-file-modes`**（别名 `chmod`）：按 `chmod` 的符号或八进制格式（如 `u+x`）改文件权限。

这些命令都一次只操作一个文件，不吃通配符；要批量处理目录，学 Dired。

## 9.11 小结

- 编辑的是 buffer 里的副本；`C-x C-f` 读进来，`C-x C-s` 写回去；改动落在磁盘前，文件是安全的旧版。
- `C-x s` 批量保存；`C-x C-w` 另存为；`M-x write-region` 只保存选区。
- 修改标记 `**`、只读标记 `%%`；`C-x C-q` 开关只读（31.1 是 `read-only-mode`，旧版叫 `toggle-read-only`）。
- 备份文件 `foo~` 保存的是「本次会话开始前」的版本；自动保存文件 `#foo#` 是崩溃保险，用 `M-x recover-file` / `M-x recover-session` 捞回。
- 反悔用 `M-x revert-buffer`（或 `C-x x g`）；比较用 `M-x diff` / `M-x ediff`；插入别的文件用 `C-x i`。

文件进了 buffer，接下来的问题就是：多个 buffer 怎么切换？屏幕怎么分给它们？下一章见。

---

上一章：[08 · 搜索与替换](08-search-and-replace.md)　｜　下一章：[10 · 多 buffer、window 与 frame](10-buffers-windows-frames.md)　｜　返回：[使用 Emacs 教程](README.md)
