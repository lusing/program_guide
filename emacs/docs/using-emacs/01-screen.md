# 01 · 屏幕解剖：frame、window、mode line、echo area

这一章把 Emacs 屏幕上看得见摸得着的每一块东西讲清楚。读完之后你再看 Emacs 窗口就不会一头雾水——你知道每一行字、每一条线是什么、干什么用的。

## 1.1 frame 与 window：两个容易混淆的词

日常用语里「窗口」指的是操作系统里一个带标题栏、可以拖来拖去的矩形区域。Emacs 给这个概念另起了一个名字：**frame**。一个 frame 就是操作系统的一个图形窗口，或者一个文本终端的整块屏幕。Emacs 启动时默认只开一个 frame，但你可以随时再开——`C-x 5 2`（`make-frame-command`）就能新建一个。

frame 里面才是 Emacs 自己的「window」。一个 window 是显示一个 buffer 的区域。启动时 frame 里只有一个 window；你可以把它横切或竖切成多个 window，每个 window 独立显示不同的 buffer（或同一个 buffer 的不同位置）。切分 window 的命令是 `C-x 2`（`split-window-below`）和 `C-x 3`（`split-window-right`）。

**关键区别**：frame 是操作系统级别的窗口；window 是 Emacs 内部的分区。手册和教程里说「window」时，说的都是 Emacs 内部的分区，不是你桌面上那个窗口。

任何时候，恰好有一个 window 是**选中窗口**（selected window）。在图形界面下，选中窗口的光标更醒目（通常是实心闪烁的方块），其他窗口的光标是空心框。你敲的大多数命令都作用于选中窗口里显示的 buffer——这个 buffer 叫做**当前缓冲区**（current buffer）。

## 1.2 frame 的组成部分

一个 frame 从上到下由这几块组成：

```
┌──────────────────────────────────┐
│  Menu Bar（菜单栏）               │
├──────────────────────────────────┤
│  Tool Bar（工具栏，可选）          │
├──────────────────────────────────┤
│                                  │
│  Window（窗口区域）               │
│  显示 buffer 的内容               │
│  底部是 Mode Line（模式行）       │
│                                  │
├──────────────────────────────────┤
│  Echo Area（回显区）              │
└──────────────────────────────────┘
```

如果 frame 被切分成多个 window，每个 window 都有自己的 mode line。最下面的 window 的 mode line 紧贴 echo area 上方。

## 1.3 Point 与光标：你在哪里编辑

选中窗口里那个闪烁的方块光标，指示的是**point**的位置。Point 是 Emacs 里最重要的概念之一：**绝大多数编辑命令都在 point 所在的位置生效**。

有一个细节容易搞混：光标看起来是「盖在」一个字符上面，但你应该把 point 想成**那个字符之前、前一个字符之后**的间隙。举个例子，如果屏幕上显示 `frob`，光标盖在 `b` 上面，那么 point 位于 `o` 和 `b` 之间。此时你输入 `!`，结果是 `fro!b`——光标仍然盖在 `b` 上，point 仍然在 `b` 之前。

每个 buffer 都有自己的 point 值。如果一个 buffer 同时显示在多个 window 里，每个 window 各自记住自己的 point 位置——你在一个 window 里把光标移到第 50 行，切到另一个 window 看同一个 buffer，再切回来，光标还停在第 50 行。

你也可以用鼠标左键（`mouse-1`）在 buffer 里点一下，point 就会跳到点击的位置。

## 1.4 Mode Line：模式行

每个 window 的最后一行是 **mode line**（模式行），它报告当前 buffer 的各种状态。在图形界面下，mode line 有立体边框效果，选中窗口的 mode line 颜色通常与未选中的不同，方便你一眼看出哪个 window 是当前的。

mode line 的内容格式大致如下：

```
CS:CH-DFR  BUF      POS LINE   (MAJOR MINOR)
```

下面逐个字段解释。

### 1.4.1 CS——字符编码

最开头的 `CS` 表示当前 buffer 使用的字符编码（coding system）。如果是一个短横线 `-`，表示没有特殊的编码转换（Emacs 自动处理得挺好，大多数时候你看到的就是 `-`）。`=` 表示完全不做转换，通常用于包含非文本数据的 buffer。其他字符代表各种编码，例如 `1` 代表 ISO Latin-1。

在文本终端上，`CS` 前面还会多两个字符，分别描述键盘输入和终端输出的编码。如果你正在使用输入法（input method），`CS` 前面还会显示输入法的标识。

`CS` 后面通常跟一个冒号 `:`。如果显示的是别的字符，说明文件使用了非标准的换行符约定：

- `\` 或 `(DOS)`：MS-DOS 风格的回车+换行（CRLF）。
- `/` 或 `(Mac)`：老式 Mac 风格的回车（CR）。
- 某些系统会显示 `(Unix)` 表示标准的换行符（LF）。

### 1.4.2 CH——修改标记

冒号后面是 `CH`，这是你最该留意的字段之一：

- `--`：buffer 的内容与磁盘上的文件一致，**没有未保存的修改**。
- `**`：buffer 已经被修改过，**有未保存的内容**。
- `%%`：buffer 是只读的，没有修改。
- `%*`：buffer 是只读的，且有修改（例如你临时改了只读属性）。

**实战经验**：写东西的时候偶尔瞥一眼 mode line，确认是 `--` 还是 `**`。如果该保存了还没保存，这里会一直提醒你。

### 1.4.3 远程标记

`CH` 后面通常是一个短横线 `-`。如果当前 buffer 对应的 `default-directory` 在远程机器上（比如你通过 TRAMP 编辑远程文件），这个位置会显示 `@`。

### 1.4.4 D——窗口专用标记

如果 window 被「专用」于某个 buffer（dedicated），这里会显示 `D`（强专用）或 `d`（弱专用）。普通编辑时你不会看到这个标记。

### 1.4.5 FR——frame 名

在文本终端上，这里显示 frame 的名字，初始 frame 叫 `F1`。在图形界面上这个字段不显示。

### 1.4.6 BUF——buffer 名

这是你最常看的字段。它显示当前 window 正在显示的 buffer 的名字。如果你正在编辑一个文件，buffer 名通常就是文件名（不含路径），比如 `main.py`、`notes.org`。特殊 buffer 的名字通常用星号括起来，比如 `*scratch*`、`*Messages*`。

### 1.4.7 POS——位置指示

这个字段告诉你当前 window 显示的是 buffer 的哪一段：

- `All`：buffer 的全部内容都在 window 里看得见。
- `Top`：你正在看 buffer 的开头。
- `Bot`：你正在看 buffer 的末尾。
- `NN%`：buffer 的 NN% 的内容在当前 window 顶部之上。例如 `45%` 表示 window 顶部以上的部分占整个 buffer 的 45%。

### 1.4.8 LINE——行号

`L` 后面是 point 所在的行号。例如 `L53` 表示 point 在第 53 行。如果你打开了列号显示模式（`M-x column-number-mode`），行号后面还会显示列号。

### 1.4.9 MAJOR 与 MINOR——模式名

括号里先是**主模式**（major mode）的名字，比如 `Fundamental`、`Python`、`Org`、`Text`。主模式决定了 Emacs 怎么对待当前 buffer——缩进规则、语法高亮、哪些命令可用。

主模式后面跟着一些**次模式**（minor mode）的缩写。比如 `Fill` 表示 Auto Fill mode 开着，`Ovwrt` 表示 Overwrite mode 开着。

一些虽然不是次模式、但值得知道的状态也会在这里显示：

- `Narrow`：buffer 被限制了显示范围（narrowing），你只能看到一部分文本。
- `Def`：正在录制键盘宏。

如果 Emacs 处于递归编辑层（recursive editing level），模式名外面会出现方括号 `[...]`，嵌套越深括号越多。

### 1.4.10 用鼠标点击 mode line

mode line 不只是看的——它上面的不同区域可以响应鼠标点击，执行各种命令。把鼠标悬停在 mode line 上，会出现工具提示（tooltip）告诉你点击会做什么。

## 1.5 Echo Area：回显区

Frame 最底下那一行是 **echo area**。它有两种用途：

### 1.5.1 回显按键

当你输入一个多键序列（比如 `C-x` 之后等下一个键）时，Emacs 会在 echo area 显示你已经按了哪些键，提示你继续输入。单键命令不回显。如果你在多键序列中间停顿超过一秒，Emacs 就会把已输入的部分回显出来——这是给犹豫的用户一个反馈，熟练用户快速输入时不会被打扰。

### 1.5.2 显示消息

Emacs 用 echo area 显示两类消息：

**错误消息**——当命令无法执行时，echo area 会显示错误信息，通常伴随蜂鸣声或屏幕闪烁。例如你按了一个没有绑定的键，会看到 `C-x C-z is undefined`。

**信息消息**——命令执行后告诉你发生了什么。例如 `C-x C-s` 保存文件后，echo area 会显示 `Wrote filename`。这些消息不伴随蜂鸣。耗时较长的命令会显示以 `...` 结尾的消息，有时还带进度百分比，完成后加上 `done`。

**重要**：所有在 echo area 显示过的信息消息都会被记录在 `*Messages*` buffer 里。如果你没来得及看清一条消息，可以用 `C-h e`（`view-echo-area-messages`）打开 `*Messages*` buffer 回看。这个 buffer 的行数上限由变量 `message-log-max` 控制，超出后旧消息会被丢弃。

### 1.5.3 Echo Area 与 Minibuffer 的关系

Echo area 还兼作 **minibuffer**——当 Emacs 需要你输入一些信息（文件名、命令名、搜索关键词等）时，echo area 里会出现一个提示字符串（prompt），光标跳进 echo area，等你输入。这个时刻，echo area 就「变成」了 minibuffer。

关于 minibuffer 的详细用法，本教程第 5 章专门讲。这里先记住一点：**任何时候你不想在 minibuffer 里输入了，按 `C-g` 就能退出来**。

## 1.6 Menu Bar：菜单栏

Frame 顶部是 **menu bar**，提供一系列下拉菜单。菜单里的每个条目对应一个 Emacs 命令——很多条目右边还标注了该命令的快捷键。

用鼠标可以点选菜单。菜单项右边如果有箭头 `▶`，表示还有子菜单；如果有 `...`，表示选了之后还会提示你进一步输入。

不用鼠标也行：按 `<f10>`（`menu-bar-open`）可以打开菜单栏的第一个菜单，然后用方向键（或 `C-f`/`C-b` 左右、`C-p`/`C-n` 上下）导航，`RET` 确认，`C-g` 取消。

**实用提示**：菜单不是主要操作方式——快捷键更快。但菜单对新手的价值在于**发现功能**：你不知道某个操作怎么做时，翻一翻菜单往往能找到，而且菜单旁边就写着快捷键，正好记下来。

如果你想在菜单栏里查某个菜单项对应的完整命令名和文档，可以按 `C-h k`，然后用鼠标去选菜单项——Help 会显示该命令的完整说明。

## 1.7 Tool Bar：工具栏

在图形界面下，menu bar 下面通常还有一行 **tool bar**——一排图标按钮，每个对应一个常用命令（打开文件、保存、搜索等）。把鼠标悬停在图标上会显示工具提示。工具栏可以用 `M-x tool-bar-mode` 关闭以腾出更多显示空间。

## 1.8 Scroll Bar：滚动条

图形界面下，每个 window 的一侧有滚动条，可以用鼠标拖拽来滚动 buffer 内容。滚动条的行为与 mode line 一样，是图形界面提供的便利，不是 Emacs 编辑的核心。

## 1.9 小结

- **Frame** 是操作系统窗口；**window** 是 Emacs 内部分区。一个 frame 可以包含多个 window。
- **Point** 是编辑发生的位置，由选中窗口里的光标指示。Point 在字符之间，不是字符之上。
- **Mode line** 在 window 底部，报告 buffer 名、修改状态 `**`/`--`、编码、行号、主/次模式等。
- **Echo area** 在 frame 底部，用于回显按键、显示消息、以及充当 minibuffer。`C-h e` 回看消息历史。
- **Menu bar** 在 frame 顶部，`<f10>` 可以用键盘操作。菜单项旁边标注了快捷键，是发现功能的好入口。

---

上一章：[00 · 开始之前：Emacs 是什么、怎么启动](00-before-you-start.md) ｜ 下一章：[02 · 按键与命令](02-keys-and-commands.md) ｜ 返回：[使用 Emacs 教程](README.md)
