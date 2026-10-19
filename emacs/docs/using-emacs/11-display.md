# 11 · 显示控制

一个 buffer 可能有几万行，而一个 window 只有几十行高——所以**屏幕永远只是 buffer 的一扇窗**，你看到的只是文本的一个切片。这一章讲怎么控制这扇窗：往哪滚（垂直、水平）、怎么快速把 point 摆到舒服的位置（重定位）、怎么干脆把窗「糊上一半」只看局部（narrowing）、长行是折还是截、字体缩放，以及让两个 window 像一台连体长屏那样滚动的 Follow mode。

## 11.1 先分清三个东西：buffer、window 的视图、point

- **buffer** 是全部文本，位置从 1 数到末尾，跟显示无关。
- **window 的视图**是 buffer 的一个连续片段。「滚动」改变的是这个片段的位置，**不移动 point、不改文本**。
- **point** 是你在 buffer 里的编辑位置。有一条铁律：**window 显示的片段永远包含 point**。你把 point 移出屏幕边缘（比如一路 `C-n` 到底），Emacs 会自动滚动把它拉回可见范围——这叫自动滚动。所以「滚出去找不到光标」不会发生；反过来，滚动命令滚到 point 会被甩出屏幕时，也会把 point 顶到屏幕边缘。

还有个术语坑要先填：Emacs 的「scroll up / scroll down」指的是**文本**在窗口里移动的方向，不是「窗口沿文本移动」的方向——这个约定早于现代 GUI 的流行。结果是：`C-v` 叫 `scroll-up-command`（文本上移，你看到**后面**的内容），相当于其他程序里的 PageDown。下文我们用「向前翻/向后翻」来避开歧义。

## 11.2 翻页：`C-v` 与 `M-v`

```text
C-v     ; 向前翻近一整屏（scroll-up-command）
M-v     ; 向后翻近一整屏（scroll-down-command）
```

「近一整屏」的意思是：`C-v` 把原窗口**底部两行**留作新窗口的顶部两行，下面接上没见过的内容——保留两行重叠，让你翻页时不丢上下文。重叠行数由变量 `next-screen-context-lines` 控制，默认 2。

细节：

- 如果 point 在翻走的文本里，`C-v` 后它会停在新窗口的顶行（`M-v` 则停在底行）。
- 给数字前缀参数 N 就滚 N 行而不是整屏，且 Emacs 尽量让 point 跟着文本走、保持屏幕位置不变；`C-v` 配负参数等效 `M-v`，反之亦然。
- `<next>`（多数键盘上的 PageDown 键）等效 `C-v`，`<prior>`（PageUp）等效 `M-v`。
- 滚到 buffer 头/尾再滚，默认是响铃/闪屏报错。把变量 `scroll-error-top-bottom` 设为 `t`，则改为把 point 推到能去的最远位置，到了头再报错。
- 想让翻页后光标保持在同一屏幕行（翻过去再翻回来 point 就回原位），把 `scroll-preserve-screen-position` 设为 `t`。
- 按住 `C-v` 不放触发键盘自动重复时，大 buffer 可能滚到卡死；把 `fast-but-imprecise-scrolling` 设为非 `nil` 可以跳过滚动途中的字体化（fontification）换取流畅。
- `M-x scroll-up` / `M-x scroll-down` 是更老更「原始」的版本（不受 `scroll-error-top-bottom` 影响）；`M-x scroll-up-line` / `M-x scroll-down-line` 一次一行，默认没有键，可自行绑定。

图形界面下滚动条和鼠标滚轮也都能滚，滚轮同样受 `scroll-preserve-screen-position` 影响。

## 11.3 重定位：`C-l` 的三态循环

`C-l`（`recenter-top-bottom`）是「把**当前行**摆到我想要的屏幕位置」的命令，设计得非常顺手——**连续按会在三个位置间循环**：

```text
C-l        ; 第 1 次：当前行滚到屏幕正中
C-l C-l    ; 第 2 次：当前行滚到顶行
C-l C-l C-l; 第 3 次：当前行滚到底行；再按回到正中……
```

「中 → 顶 → 底」的循环顺序由列表变量 `recenter-positions` 定制，默认 `(middle top bottom)`，元素还可以是整数（第几屏行）或 0.0–1.0 的浮点数（距顶部的百分比）。

带前缀参数时不循环：`C-u C-l` 单纯居中；`C-<N> C-l`（正数 N）把当前行放到距顶 N 行处；`C-0 C-l` 放到顶行；负数 −N 放到距底 N 行处。

`C-l` 在文本终端下还会顺带清屏重画（变量 `recenter-redisplay` 默认值 `tty` 的含义）——屏幕花掉时连按几下 `C-l` 常能救回来。更原始的「只居中不循环」是 `M-x recenter`。`C-M-l`（`reposition-window`）则是启发式滚动，尽量把对当前上下文有用的信息（比如所在函数的开头）搬上屏。

**什么时候用**：编辑到屏幕边缘觉得别扭时按一下 `C-l` 把当前行拉回正中；读代码时 `C-l C-l` 把关注行顶到屏幕顶部、下文尽收眼底。这是 Emacs 老手按得最频繁的键之一。

## 11.4 滚动另一个 window

上一分屏之后常见的场景：光标留在左边 window，右边 window 里的帮助文档想翻一翻。不用 `C-x o` 跳过去：

- `C-M-v`（`scroll-other-window`）：滚动「`C-x o` 会选中的那个 window」，行为像作用在那边的 `C-v`；
- `C-M-S-v`（`scroll-other-window-down`）：反方向；
- `C-M-S-l`（`recenter-other-window`）：相当于对另一个 window 按 `C-l`。

在 minibuffer 里按 `C-M-v` 滚动的是补全/帮助弹出的那个 window——输入长命令时翻文档全靠它。

## 11.5 水平滚动

长行超出 window 宽度时（截断显示状态下），可以左右平移视图：

- `C-x <`（`scroll-left`）：文本整体**向左**移（看到每行更靠右的部分）。默认一次移「window 宽度减两列」，数字参数 N 则移 N 列；
- `C-x >`（`scroll-right`）：向右移回来。

多数时候你不需要手动按它们：window 显示截断行时，point 移到屏幕左/右边缘外会**自动水平滚动**。相关变量：`auto-hscroll-mode`（设为特殊值 `current-line` 则只滚光标所在行；设为 `nil` 彻底关掉自动水平滚动——此时 point 出屏光标会消失以示警告）、`hscroll-margin`（point 距边缘几列时触发，默认 5）、`hscroll-step`（每次滚多少列；0 表示把 point 水平居中）。

注意：水平滚动只发生在**截断**显示的 window 里——折行（continuation）显示的 window 每行都完整可见，没什么可水平滚的。

## 11.6 narrowing：把 buffer 收窄到只看一段

**narrowing（收窄）**让 buffer 的其余部分暂时不可见也不可编辑，只剩你圈定的一段——叫**可访问部分（accessible portion）**。取消收窄、恢复全文叫 **widen**。

- `C-x n n`（`narrow-to-region`）：收窄到当前选区（point 和 mark 之间）；
- `C-x n w`（`widen`）：恢复完整 buffer；
- `C-x n p`（`narrow-to-page`）：收窄到当前**页**（page，以换页符 `C-l` 字符分隔，见下一章）；
- `C-x n d`（`narrow-to-defun`）：收窄到 point 所在的**函数**（defun）。

收窄生效期间 mode line 会显示 `Narrow` 字样。关键性质：

- 看不见 ≠ 不存在。移动命令出不了可访问部分，但**保存文件时保存的是整个 buffer**，被藏起来的文本一字不少。
- 用处一：**专注**。写长文档时把当前小节收窄出来，屏幕上没有别的干扰。
- 用处二：**限定命令的作用范围**。替换命令（`M-x replace-string` 等）、键盘宏的重复执行都只在可访问部分生效——想「只在这一节里替换」，先收窄再替换，做完 `C-x n w`。
- 因为新手容易被「文本怎么少了一大截」吓到，`narrow-to-region` 默认是**disabled command**：第一次用会要你确认，并顺手提供「永久启用」的选项。启用后不再问。
- `C-x =` 可以查看当前收窄范围等信息。

## 11.7 长行的两种命运：折行与截断

一个**逻辑行**（buffer 里以换行符结尾的一行）长过 window 宽度时，Emacs 有两种显示法：

**折行（continuation / line wrapping）**——默认。长行拆成多个**屏幕行**（screen line）显示。图形界面下 window 两侧 fringe 里画小弯箭头标记折行处，文本终端下在右边缘显示 `\`。

**截断（truncation）**。每个逻辑行只占一个屏幕行，放不下的部分干脆不显示。fringe 里画小直箭头，文本终端下右边缘显示 `$`（左边也被截时左边也有标记）。

切换截断的命令是 `C-x x t`（`toggle-truncate-lines`），它翻转 buffer 局部变量 `truncate-lines`（默认 `nil` 即折行）。另外记得上一章说的：`C-x 3` 分出来的窄窗若不足 50 列，Emacs 会自动改用截断（变量 `truncate-partial-width-windows` 控制这个阈值）。

怎么选？读散文/Markdown 之类，折行友好；看代码、表格、日志这种「一逻辑行是一个单元」的内容，截断更整齐——折行会把一行拆得七零八落，截断则保证「屏幕行 = 逻辑行」的对齐关系。

**重要区分**：绝大多数按行操作的命令（如 `C-k` 杀一行）作用于**逻辑行**，不是屏幕行；`C-n`/`C-p` 是例外，它们按屏幕行走。折行显示不改变文本内容——buffer 里并没有多出换行符。

想让折行更好看还有 `visual-wrap-prefix-mode`：给续行自动加上从上下文推算的缩进前缀（纯显示效果，不改 buffer）。

## 11.8 visual-line-mode：按词折行 + 按屏幕行编辑

默认折行是「顶到 window 右边缘才断」，可能把一个词从中间劈开。**Visual Line mode**（`M-x visual-line-mode`，再执行一次关闭；全局版 `M-x global-visual-line-mode`）改为**词边界折行（word wrap）**，开启后 mode line 显示 `wrap` 字样。它和截断互斥——开启它会自动关掉 `truncate-lines`。

Visual Line mode 不只是改显示，还改了一批编辑命令的语义，让它们按**屏幕行**工作：

- `C-a`（`beginning-of-visual-line`）：移到屏幕行行首；
- `C-e`（`end-of-visual-line`）：移到屏幕行行尾；
- `C-k`（`kill-visual-line`）：杀到屏幕行尾。

要按逻辑行移动则用 `M-x next-logical-line` / `M-x previous-logical-line`（默认无键，可自绑）。

**何时用**：编辑充满超长逻辑行的文本（无硬换行的笔记、字幕、某些标记语言）时开它，阅读体验和「行」命令的手感都更符合直觉。

## 11.9 follow-mode：两个 window 拼成一屏长窗

`M-x follow-mode` 是一个 minor mode，前提是**两个 window 显示同一个 buffer**（典型做法：单 window 的 frame 里 `C-x 3` 左右分屏，然后开启）。开启后这两个 window 像**一扇很高的虚拟窗口**一样协同滚动：在任意一边滚动，另一边跟着接续；point 移出一边可见范围、进入另一边可见范围时，选中的 window 也自动切换过去。再执行一次 `M-x follow-mode` 关闭。

用途：窄屏（或习惯左右分屏）下想获得「一屏 N 行」的连续阅读体验，比如读长代码、看 diff。

## 11.10 字体缩放：`C-x C-+` 一族

演示、眼累、屏幕太远时，临时放大当前 buffer 的字体：

- `C-x C-+` 或 `C-x C-=`：放大；
- `C-x C--`：缩小；
- `C-x C-0`：恢复默认大小。

这四个键绑的是**同一个命令** `text-scale-adjust`，它看「最后按的是哪个键」决定动作。每按一次缩放一档，一档是 1.2 倍（变量 `text-scale-mode-step` 可改）。最妙的是**尾键可连按**：`C-x C-= = =` 或 `C-x C-= C-= C-=` 都等于放大三档——按住不放即可连续缩放。缩放只对**当前 buffer** 生效（实现上开一个 `text-scale-mode` 并调 default face 的高度），别的 buffer 不受影响。

对应地，`C-x C-M-+` / `C-x C-M-=` / `C-x C-M--` / `C-x C-M-0`（命令 `global-text-scale-adjust`）做**全局**缩放，所有 buffer 一起变。图形界面下按住 `Ctrl` 滚滚轮缩放当前 buffer，按住 `Ctrl`+`Meta` 滚滚轮全局缩放。

## 11.11 小结

- 屏幕只是 buffer 的一扇窗；滚动移动的是窗，不是 point；window 永远包含 point。
- `C-v` / `M-v` 翻近一整屏（留两行重叠）；`C-l` 三态循环「中→顶→底」把当前行摆舒服；`C-M-v` 滚另一个 window。
- 水平滚动：`C-x <` / `C-x >`，只发生在截断显示的 window；point 出边缘会自动水平滚。
- `C-x n n` 收窄到选区、`C-x n w` 恢复；narrowing 既为专注也为限定替换/宏的范围；保存时全 buffer 都在。
- 长行默认折行（`truncate-lines` 为 `nil`），`C-x x t` 切截断；`visual-line-mode` 按词折行并让 `C-a`/`C-e`/`C-k` 按屏幕行工作；`follow-mode` 让同 buffer 的两个 window 连体滚动。
- `C-x C-+`/`C-x C--`/`C-x C-0` 缩放当前 buffer 字体，`C-x C-M-` 系列全局缩放。

视图的事说完了。下一章回到文本本身：Emacs 按词、句、段、页这些单位编辑文本的命令。

---

上一章：[10 · 多 buffer、window 与 frame](10-buffers-windows-frames.md)　｜　下一章：[12 · 文本编辑](12-text-editing.md)　｜　返回：[使用 Emacs 教程](README.md)
