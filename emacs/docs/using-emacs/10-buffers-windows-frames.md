# 10 · 多 buffer、window 与 frame

上一章你学会了把文件装进 buffer、把 buffer 存回文件。但一个真实的编辑会话远不止一个文件：你可能同时开着源码、笔记、帮助文档，还要一边写一边对照。这一章讲 Emacs 组织这一切的三层结构——**buffer、window、frame**——以及在各层之间穿行的命令。

## 10.1 三层概念：先把模型立正

这三个词在日常用语里几乎同义，在 Emacs 里却各有严格含义，混淆它们是很多新手困惑的根源：

- **buffer**：内存中的文本容器。你编辑的永远是 buffer，不是文件、不是「窗口」。每访问一个文件建一个 buffer；帮助信息进 `*Help*` buffer，草稿进 `*scratch*` buffer。buffer 可以存在但不显示在任何地方。
- **window**：frame 内部的一块矩形显示区域，**任一时刻显示且只显示一个 buffer**。一个 frame 可以切分出多个 window；同一个 buffer 也可以同时显示在多个 window 里。注意：这和操作系统意义上的「窗口」不是一回事。
- **frame**：操作系统层面的窗口（图形界面下）或整块终端屏幕（文本终端下）。一个 Emacs 进程可以有多个 frame，**所有 frame 共享同一批 buffer**——在 frame A 里改了某个 buffer，frame B 里显示它的地方立刻同步。

一句话记忆：**frame 是房子，window 是房间里的窗，buffer 是挂在窗前的画卷**。同一幅画可以同时挂在多扇窗、多个房子里。

配套的「当前性」概念：任何时刻恰有一个 buffer 被**选中**，叫**当前 buffer（current buffer）**——你敲的所有编辑命令都作用于它。当前 buffer 就是**选中 window**（selected window）里显示的那个。图形界面下，选中 window 里的 point 用实心闪烁光标显示，未选中 window 里的 point 显示为空心框；文本终端下只有选中 window 画光标。每个 window 有自己的 mode line，选中 window 的 mode line 颜色不同。

## 10.2 buffer 的名字与内情

每个 buffer 有一个**唯一**的名字，任意长，大小写敏感。访问文件的 buffer 名字取自文件名（去掉目录）；内部用的 buffer 名字通常用星号包起来，如 `*Messages*`、`*Help*`，名字以空格开头的 buffer 是 Emacs 内部自用的，列表里默认不显示。刚启动的 Emacs 里就有一个 `*scratch*`，不关联任何文件，适合随手记东西、试想法。

除了文本本身，每个 buffer 还各自记着一套信息：访问的文件（如有）、是否被修改、major mode 和 minor modes、point 位置、mark、narrowing 状态等等。这些都存在 **buffer 局部变量**里——每个 buffer 一份，互不干扰。这就是为什么「切到另一个文件」连缩进风格、折行宽度都会跟着变。

## 10.3 切换与创建 buffer：`C-x b`

```text
C-x b notes.txt RET
```

`C-x b`（`switch-to-buffer`）在 minibuffer 里读一个 buffer 名，把那个 buffer 设为当前并显示在选中的 window 里。要点：

- **支持补全和历史**（`TAB`、`M-p`/`M-n`）。输入一个不存在的名字按 `RET`，Emacs 显示 `[Confirm]`，再按一次 `RET` 才**新建**一个空 buffer——这个空 buffer 不访问任何文件，major mode 取变量 `major-mode` 的默认值（默认 Fundamental mode）。很多人拿它当临时记事本；之后按 `C-x C-s` 保存时 Emacs 会问文件名。
- **直接按 `RET`（空输入）** 切换到「最近当前过、且此刻没显示在任何 window 里」的那个 buffer——也就是通常意义上的「上一个 buffer」。这使 `C-x b RET` 成为在两个 buffer 之间反复横跳的最短路径。
- `C-x <left>`（`previous-buffer`）和 `C-x <right>`（`next-buffer`）按当前 frame 的最近使用顺序循环切换 buffer，不用进 minibuffer，适合在少数几个 buffer 间走马灯式浏览。支持数字前缀参数当重复次数。
- `C-x 4 b`（`switch-to-buffer-other-window`）：在**另一个 window** 里选中某 buffer（并选中那个 window）。
- `C-x 5 b`（`switch-to-buffer-other-frame`）：在**另一个 frame** 里选中某 buffer；如果别的 frame 已经显示着它，就选中那个 frame 而不是新建。

记住上一节的区分：`C-x b` 只动选中 window 显示的 buffer，其他 window 一概不影响。

## 10.4 列出所有 buffer：`C-x C-b` 与 Buffer Menu

`C-x C-b`（`list-buffers`）弹出一个名为 `*Buffer List*` 的 buffer 清单，按「最近当前过」的顺序排列。每行一个 buffer，长这样：

```text
CRM Buffer                Size  Mode              File
. * .emacs                3294  Elisp/l           ~/.emacs
 %  *Help*                 101  Help
    search.c             86055  C                 ~/cvs/emacs/src/search.c
 %  src                  20959  Dired by name     ~/cvs/emacs/src/
    * *mail*                  42  Mail
```

开头几个标志位的含义：`.` 表示这是当前 buffer；`*` 表示已修改（该保存了）；`%` 表示只读；`M` 列标记 minor modes。`C-u C-x C-b` 只列出访问文件的 buffer。

这个清单不只是「看」的——它就是 **Buffer Menu**，一个类 Dired 的操作界面（major mode 是 `Buffer-menu-mode`）。先在列表里给 buffer 打标记，再一次性执行：

- `d`（`Buffer-menu-delete`）：标记**待杀**（行首出现 `D`），point 下移一行；`C-d` 同样但上移；
- `s`（`Buffer-menu-save`）：标记**待保存**（行首出现 `S`）；同一 buffer 可以同时被标记保存和待杀；
- `~`（`Buffer-menu-not-modified`）：清掉该 buffer 的修改标记；
- `%`（`Buffer-menu-toggle-read-only`）：切换只读；
- `u`（`Buffer-menu-unmark`）：撤销当前行的标记；
- `x`（`Buffer-menu-execute`）：**执行**所有标记——保存该保存的、杀掉该杀的；
- `RET` / `f`（`Buffer-menu-this-window`）：在当前 window 里选中原行那个 buffer；
- `o`（`Buffer-menu-other-window`）：在另一个 window 里显示它；
- `1`（`Buffer-menu-1-window`）：让选中的 buffer 独占整个 frame；`2`（`Buffer-menu-2-window`）：把它和上一行的 buffer 各占一屏；
- `q`（`quit-window`）：退出 Buffer Menu。

（以上按键都在 `Buffer-menu-mode` 里生效，出了这个 buffer 它们各有别的含义。）`M-x buffer-menu` 直接在当前 window 打开这个界面，`M-x buffer-menu-other-window` 在另一个 window 打开并选中。

## 10.5 杀 buffer：`C-x k`

buffer 不用了就**杀掉（kill）**——别的编辑器叫「关闭文件」，Emacs 叫杀 buffer，释放内存。

```text
C-x k RET          ; 杀当前 buffer（RET 用默认值）
C-x k notes RET    ; 杀名叫 notes 的 buffer
```

`C-x k`（`kill-buffer`）在 minibuffer 里读要杀的 buffer 名，**默认就是当前 buffer**。杀掉当前 buffer 后，Emacs 自动让「最近当前过、且没显示在任何 window」的 buffer 顶上。要杀的 buffer 若访问着文件且**被修改**，Emacs 会要求你输入完整的 `yes` 确认——这是在防你丢掉未保存的改动。

批量清理：

- `M-x kill-some-buffers`：把所有 buffer 逐个问一遍杀不杀；
- `M-x kill-matching-buffers`：按正则匹配批量问杀（加前缀参数连内部 buffer 也算上）；`M-x kill-matching-buffers-no-ask` 不问直接杀；
- `M-x clean-buffer-list`：杀掉所有「很久没用过」且未修改的 buffer——Emacs 一开好多天的人的定期大扫除，默认规则是三天没显示过就杀（可定制）。

**杀掉 window 里显示的 buffer ≠ 删 window；删 window ≠ 杀 buffer**——下面马上见分晓。

## 10.6 indirect buffer：同一文本的两个化身

**indirect buffer** 和它的**base buffer** 共享同一份文本——在任何一个里编辑，另一个立刻同步，相当于文件符号链接的 buffer 版。但除此之外两者完全独立：各有自己的名字、point、narrowing、marker、overlay、major mode 和局部变量。典型用法：同一份长文档，一个 window 里全宽显示，另一个用 indirect buffer 单独 narrow 到某一节专注编辑；或者对同一段文本同时开两种 major mode 看。

- `M-x make-indirect-buffer RET BASE RET NAME RET`：以 BASE 为底建一个名叫 NAME 的 indirect buffer；
- `M-x clone-indirect-buffer RET`：克隆当前 buffer（连 major mode 都继承）；
- `C-x 4 c`（`clone-indirect-buffer-other-window`）：克隆当前 buffer 并在另一个 window 里选中它——最常用，一步得到「左右对照、改一处两边动」。

indirect buffer 不能访问文件；对它执行保存，实际保存的是 base buffer。杀掉 base，indirect 也一并死掉。

## 10.7 window：分屏、穿行、删除、调整

### 10.7.1 分屏：`C-x 2` 与 `C-x 3`

新 window 都是**切分**现有 window 得来的：

- `C-x 2`（`split-window-below`）：把选中 window **上下**一分为二。分完后选中的仍是上半，新 window 在下。两个 window 显示同一 buffer 的同一部分、point 位置相同。数字前缀参数指定上半占多少行（负数则指定下半）。
- `C-x 3`（`split-window-right`）：**左右**一分为二，选中左边。正参数指定左窗宽度（列数），负参数指定右窗。
- 图形界面下 `C-mouse-2` 点在某个 window 的 mode line 上，就在点击处切分它。

两个细节。其一，同一 buffer 显示在多个 window 时，**每个 window 有自己的 point**（所以两边可以停在不同位置对照着看），但 **mark 是 buffer 级的、两边共享**。其二，`C-x 3` 切出的窗如果太窄，续行（continuation）会难看得没法读，所以 window 宽度小于 50 列时 Emacs 自动改用**截断行**显示；阈值由变量 `truncate-partial-width-windows` 控制（显示控制的细节见下一章）。

### 10.7.2 在 window 间穿行：`C-x o` 与 `C-x 4` 前缀

- `C-x o`（`other-window`）——是字母 **o**（other），不是零——按「从上到下、从左到右」的循环顺序选中下一个 window。数字参数跳 n 步，负参数反着走。minibuffer 激活时它排在循环末尾，所以你可以从 minibuffer 里跳出去干别的再跳回来继续输入。
- `C-x O`（`other-window-backward`）：反方向的 `C-x o`。
- 鼠标 `mouse-1` 点某个 window 的文本区：选中它并把 point 移到点击处；点 mode line 只选中、不动 point。

`C-x 4` 是一个**前缀键**（按下后 Emacs 等下一个键），统领「在另一个 window 里做某事」的一族命令：

- `C-x 4 C-f`（`find-file-other-window`）：在另一个 window 访问文件——上一章见过；
- `C-x 4 b`（`switch-to-buffer-other-window`）：在另一个 window 选 buffer；
- `C-x 4 d`（`dired-other-window`）：在另一个 window 打开目录；
- `C-x 4 r`（`find-file-read-only-other-window`）：只读访问，显示在另一个 window；
- `C-x 4 C-o`（`display-buffer`）：**显示**一个 buffer 但不选中它——「给我摆出来看，别抢我的光标」；
- `C-x 4 4`（`other-window-prefix`）：更狠的前缀——它让你接着按的**任意命令**都作用在另一个 window 里。

「另一个 window」如果没有现成的，Emacs 会自动切分出一个来。

滚动类的跨 window 命令（`C-M-v` 滚动另一个 window 等）放在下一章讲。

### 10.7.3 删除 window

- `C-x 0`（`delete-window`）——结尾是**零**——删除选中 window，它占的空间让给相邻 window。**buffer 毫发无损**，`C-x b` 随时切回去。「关闭这个窗」和「杀掉这份文本」是两回事。
- `C-x 1`（`delete-other-windows`）：只留选中 window，删掉 frame 里其他所有 window——「我要独占全屏」。记法：1 个 window。
- `C-x 4 0`（`kill-buffer-and-window`）：两件事一起干——杀掉 window 里的 buffer（会按 `C-x k` 的规矩问确认）再删掉 window。
- `M-x delete-windows-on`：删除所有显示某个指定 buffer 的 window。

### 10.7.4 调整 window 大小

- `C-x ^`（`enlarge-window`）：选中 window 长高一行，空间从上下相邻的 window 里抠。正参数加 n 行，负参数减 n 行。
- `C-x }`（`enlarge-window-horizontally`）：加宽；`C-x {`（`shrink-window-horizontally`）：减窄。记忆：`}` 往右撑，`{` 往左缩。
- 下限保护：window 高度不能压到 `window-min-height`（默认 4 行）以下，宽度不能小于 `window-min-width`（默认 10 列），硬压会报错。
- `C-x -`（`shrink-window-if-larger-than-buffer`）：如果 window 比它显示的 buffer 内容还高，就收缩到刚好，多余的行还给别的 window。
- `C-x +`（`balance-windows`）：把 frame 里所有 window 的尺寸摆平——相邻的横向一对等高、纵向一对等宽。
- 鼠标党：直接拖动 mode line 或 window divider 就能改高度。

## 10.8 frame：`C-x 5` 一族

`C-x 5` 之于 frame，正如 `C-x 4` 之于 window——一个前缀键，后面跟「在另一个 frame 里做某事」。规则：如果某个已存在（可见或最小化）的 frame 正显示着你要的 buffer，就把它抬到前台；否则新建一个 frame。

- `C-x 5 2`（`make-frame-command`）：凭空新建一个 frame；
- `C-x 5 c`（`clone-frame`）：按当前 frame 的窗口布局和参数复制一个新 frame；
- `C-x 5 b` / `C-x 5 f` / `C-x 5 d`（`switch-to-buffer-other-frame` / `find-file-other-frame` / `dired-other-frame`）：在另一个 frame 里选 buffer / 访问文件 / 开目录；
- `C-x 5 o`（`other-frame`）：循环切换到下一个 frame；
- `C-x 5 0`（`delete-frame`）：删掉选中 frame——**只剩最后一个 frame 时会拒绝**，防止你把整个会话「关没了」（daemon 模式下有虚拟 frame 兜底，可以删到零，用 `emacsclient` 再连回来）。对照：`C-x C-c` 是退出整个 Emacs。
- `C-x 5 1`（`delete-other-frames`）：删掉当前终端/显示器上除选中 frame 外的所有 frame。

frame 级的其他常用键：

- `C-z`（`suspend-frame`）：图形界面下最小化当前 frame；文本终端下挂起 Emacs 回到 shell（第 0 章讲过）。
- `M-<f10>`（`toggle-frame-maximized`）：切换最大化。
- `<f11>`（`toggle-frame-fullscreen`）：切换全屏（比最大化更进一步，连窗口管理器的标题栏都藏掉）。

文本终端下也能建多个 frame（每个占满整块终端屏，一次显示一个），但没有鼠标、菜单栏这些图形特性。

## 10.9 小结

- 三层结构：buffer 装文本，window 显示 buffer，frame 装 window；所有 frame 共享所有 buffer。当前 buffer = 选中 window 显示的那个。
- `C-x b` 切/建 buffer（`RET` 空输入 = 上一个 buffer），`C-x C-b` 列 buffer 并用 Buffer Menu 批量保存/杀，`C-x k` 杀 buffer。
- `C-x 2` / `C-x 3` 分屏，`C-x o` 穿行，`C-x 0` / `C-x 1` 删窗，`C-x ^` `C-x }` `C-x {` `C-x +` 调大小；删 window 不杀 buffer。
- `C-x 4 <cmd>` 在另一个 window 做，`C-x 5 <cmd>` 在另一个 frame 做；`C-x 5 2` 新建 frame，`C-x 5 0` 删 frame。
- 同一 buffer 可显示在多个 window，各 window 的 point 独立、mark 共享；indirect buffer（`C-x 4 c`）让同一文本有多个独立视图。

buffer 摆上了屏，接下来的问题是：一屏装不下时怎么看——翻页、重定位、截断还是折行、放大缩小。下一章讲显示控制。

---

上一章：[09 · 文件操作](09-files.md)　｜　下一章：[11 · 显示控制](11-display.md)　｜　返回：[使用 Emacs 教程](README.md)
