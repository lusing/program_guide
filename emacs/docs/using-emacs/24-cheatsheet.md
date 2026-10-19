# 24 · 附录：常用键位速查

这一章按主题整理 Emacs 最常用的键位。所有绑定都按 **GNU Emacs 31.1** 默认 global-map 核验过。如果你发现某个键在你那里行为不同，可能是你的 init 文件或某个 minor mode 改了绑定——用 `C-h w <命令名>` 可以反查某个命令绑在哪些键上。

## 24.1 基本移动

| 键 | 命令 | 作用 |
|---|---|---|
| `C-f` | `forward-char` | 前进一个字符 |
| `C-b` | `backward-char` | 后退一个字符 |
| `C-n` | `next-line` | 下一行 |
| `C-p` | `previous-line` | 上一行 |
| `C-a` | `move-beginning-of-line` | 行首 |
| `C-e` | `move-end-of-line` | 行尾 |
| `M-f` | `forward-word` | 前进一个词 |
| `M-b` | `backward-word` | 后退一个词 |
| `M-<` | `beginning-of-buffer` | buffer 开头 |
| `M->` | `end-of-buffer` | buffer 末尾 |
| `M-g M-g` | `goto-line` | 跳到指定行 |
| `M-g c` | `goto-char` | 跳到指定字符位置 |

## 24.2 基本编辑

| 键 | 命令 | 作用 |
|---|---|---|
| `DEL` | `delete-backward-char` | 删除光标前一个字符（退格） |
| `C-d` | `delete-char` | 删除光标后一个字符 |
| `C-k` | `kill-line` | 删除到行尾（进 kill ring） |
| `M-d` | `kill-word` | 删除下一个词 |
| `M-DEL` | `backward-kill-word` | 删除前一个词 |
| `C-/` | `undo` | 撤销 |
| `C-x u` | `undo` | 撤销（同上） |
| `C-o` | `open-line` | 在光标处插入空行，光标不动 |
| `C-x C-o` | `delete-blank-lines` | 删除多余空行 |
| `RET` | `newline` | 换行 |
| `C-j` | `electric-newline-and-maybe-indent` | 换行并自动缩进 |

## 24.3 kill 与 yank（剪切/粘贴）

| 键 | 命令 | 作用 |
|---|---|---|
| `C-w` | `kill-region` | 剪切 region |
| `M-w` | `kill-ring-save` | 复制 region（不删除） |
| `C-y` | `yank` | 粘贴 |
| `M-y` | `yank-pop` | 在 `C-y` 后轮换 kill ring 里的内容 |

## 24.4 mark 与 region

| 键 | 命令 | 作用 |
|---|---|---|
| `C-SPC` | `set-mark-command` | 设置 mark |
| `C-x C-x` | `exchange-point-and-mark` | 交换 point 和 mark |
| `M-@` | `mark-word` | 标记下一个词 |
| `C-M-@` | `mark-sexp` | 标记下一个表达式 |
| `M-h` | `mark-paragraph` | 标记当前段 |
| `C-M-h` | `mark-defun` | 标记当前函数/定义 |
| `C-x h` | `mark-whole-buffer` | 标记整个 buffer |

## 24.5 搜索与替换

| 键 | 命令 | 作用 |
|---|---|---|
| `C-s` | `isearch-forward` | 增量向前搜索 |
| `C-r` | `isearch-backward` | 增量向后搜索 |
| `C-M-s` | `isearch-forward-regexp` | 正则增量向前搜索 |
| `C-M-r` | `isearch-backward-regexp` | 正则增量向后搜索 |
| `M-%` | `query-replace` | 交互式替换 |
| `C-M-%` | `query-replace-regexp` | 正则交互式替换 |

## 24.6 文件操作

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x C-f` | `find-file` | 访问（打开）文件 |
| `C-x C-s` | `save-buffer` | 保存当前 buffer |
| `C-x s` | `save-some-buffers` | 保存部分 buffer（会逐个问） |
| `C-x C-w` | `write-file` | 另存为 |
| `C-x C-q` | `read-only-mode` | 切换只读模式 |
| `C-x i` | `insert-file` | 把文件内容插入当前 buffer |

## 24.7 buffer、window、frame

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x b` | `switch-to-buffer` | 切换 buffer |
| `C-x C-b` | `list-buffers` | 列出所有 buffer |
| `C-x k` | `kill-buffer` | 关闭 buffer |
| `C-x 0` | `delete-window` | 关闭当前 window |
| `C-x 1` | `delete-other-windows` | 只留当前 window |
| `C-x 2` | `split-window-below` | 上下分屏 |
| `C-x 3` | `split-window-right` | 左右分屏 |
| `C-x o` | `other-window` | 跳到另一个 window |

## 24.8 显示控制

| 键 | 命令 | 作用 |
|---|---|---|
| `C-v` | `scroll-up-command` | 向前翻一页 |
| `M-v` | `scroll-down-command` | 向后翻一页 |
| `C-l` | `recenter-top-bottom` | 重定位当前行（中→顶→底循环） |
| `C-x n n` | `narrow-to-region` | 只显示 region 部分 |
| `C-x n w` | `widen` | 取消 narrowing，显示全部 |

## 24.9 文本编辑

| 键 | 命令 | 作用 |
|---|---|---|
| `M-q` | `fill-paragraph` | 填充当前段（重新排版换行） |
| `C-x f` | `set-fill-column` | 设置填充列宽（默认 70） |
| `M-l` | `downcase-word` | 下一个词转小写 |
| `M-u` | `upcase-word` | 下一个词转大写 |
| `M-c` | `capitalize-word` | 下一个词首字母大写 |
| `C-x C-l` | `downcase-region` | region 转小写 |
| `C-x C-u` | `upcase-region` | region 转大写 |

## 24.10 程序编辑

| 键 | 命令 | 作用 |
|---|---|---|
| `TAB` | `indent-for-tab-command` | 缩进当前行或 region |
| `M-;` | `comment-dwim` | 注释/取消注释（智能） |
| `C-M-\` | `indent-region` | 缩进 region |
| `C-M-f` | `forward-sexp` | 前进一个表达式 |
| `C-M-b` | `backward-sexp` | 后退一个表达式 |
| `C-M-k` | `kill-sexp` | 删除下一个表达式 |
| `C-M-@` | `mark-sexp` | 标记下一个表达式 |
| `C-M-a` | `beginning-of-defun` | 跳到当前函数开头 |
| `C-M-e` | `end-of-defun` | 跳到当前函数末尾 |

## 24.11 Help（自助文档）

| 键 | 命令 | 作用 |
|---|---|---|
| `C-h k` | `describe-key` | 查某个键绑定的命令 |
| `C-h f` | `describe-function` | 查某个函数的文档 |
| `C-h v` | `describe-variable` | 查某个变量的文档和当前值 |
| `C-h m` | `describe-mode` | 查当前 buffer 的 major/minor mode |
| `C-h a` | `apropos-command` | 按关键词查命令 |
| `C-h w` | `where-is` | 查某个命令绑在哪些键上 |
| `C-h i` | `info` | 打开 Info 文档浏览器 |
| `C-h t` | `help-with-tutorial` | 打开 Emacs 交互式教程 |
| `C-h l` | `view-lossage` | 看最近 300 个输入事件 |
| `C-h e` | `view-echo-area-messages` | 看 echo area 的历史消息 |
| `C-h P` | `describe-package` | 查某个包的说明 |

## 24.12 系统

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x C-c` | `save-buffers-kill-terminal` | 退出 Emacs |
| `C-z` | `suspend-frame` | 挂起 Emacs（终端下回到 shell） |
| `C-g` | `keyboard-quit` | 取消当前操作 |
| `M-x` | `execute-extended-command` | 按名字调用命令 |
| `C-u` | `universal-argument` | 数字前缀参数 |
| `C-x z` | `repeat` | 重复上一个命令 |

## 24.13 寄存器与书签

| 键 | 命令 | 作用 |
|---|---|---|
| `C-x r SPC` | `point-to-register` | 把当前位置存到寄存器 |
| `C-x r j` | `jump-to-register` | 跳到寄存器存的位置/文本 |
| `C-x r s` | `copy-to-register` | 把 region 存到寄存器 |
| `C-x r i` | `insert-register` | 把寄存器的内容插入 buffer |
| `C-x r m` | `bookmark-set` | 设书签 |
| `C-x r b` | `bookmark-jump` | 跳到书签 |
| `C-x r l` | `bookmark-bmenu-list` | 列出所有书签 |

## 24.14 Shell 与构建

| 键 | 命令 | 作用 |
|---|---|---|
| `M-!` | `shell-command` | 执行一次性 shell 命令 |
| `M-&` | `async-shell-command` | 异步执行 shell 命令 |
| `C-x \`` | `next-error` | 跳到下一个编译错误 |

## 24.15 键盘宏

| 键 | 命令 | 作用 |
|---|---|---|
| `<f3>` | `kmacro-start-macro` | 开始录制宏 |
| `<f4>` | `kmacro-end-or-call-macro` | 结束录制并回放，或回放已录好的宏 |
| `C-x e` | `kmacro-end-and-call-macro` | 结束并回放 |

## 24.16 小结

这张表覆盖了 Emacs 最常用的 100+ 个键位。完整列表可以用 `C-h b`（`describe-bindings`）查看当前 buffer 的所有绑定，或 `C-h P`（`describe-package`）查某个包的说明。

遇到不熟悉的命令，用 `C-h f <命令名>` 查文档；遇到不熟悉的键，用 `C-h k <按键>` 查它做什么。Emacs 的自助文档系统（第 4 章）是你最可靠的参考。

---

上一章：[23 · 出问题时](23-troubleshooting.md) ｜ 下一章：（无下一章） ｜ 返回：[使用 Emacs 教程](README.md)
