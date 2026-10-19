# 31 · 正则驱动的文本推进：forward-sentence 与 forward-paragraph

> 所属部分：第 8 部分 · 跟随 eintr：读懂真实代码

> 示例：`examples/31-forward-sentence.el`

前面几章读的命令（`beginning-of-buffer`、`kill-region`、`yank`）处理的都是「一个明确的区间」：你知道起点和终点，只是要把它取出来或删掉。本章的对手不一样——**「一句话到哪里结束」「一段到哪里结束」并没有精确答案**，它取决于你的排版习惯。

Emacs 的解法是：用一个**正则表达式**把这种模糊的自然语言结构翻译成可计算的边界。`forward-sentence`（`M-e`）和 `forward-paragraph`（`M-}`）就是这套翻译的执行者。eintr 第 12 章（Regexp Search）第一次引入这个思路，本机把它的源码在 Emacs 31.1 下重新走一遍。

## 31.1 三个层次：命令、委托、实现

先看 `forward-sentence` 本身。这是 31.1 的真实源码：

```
(defun forward-sentence (&optional arg)
  "Move forward to next end of sentence.  With argument ARG, repeat.
If ARG is negative, move backward repeatedly to start of
sentence.  Delegates its work to `forward-sentence-function'."
  (interactive "^p")
  (or arg (setq arg 1))
  (funcall forward-sentence-function arg))
```

只有三行有内容，而且**一行正经事都没干**：

- `(interactive "^p")` —— 声明这是交互命令，参数是前缀数字（`p`）。那个 `^` 是个特殊记号：配合 `shift-select-mode` 时，不带参数调用会自动扩选（一旦这个命令移动了 point，就把它当作移位选择）。这是「读源码」章节里反复出现的模式——**许多表面简单的命令，其 docstring 和 `interactive` 声明就占了大半**。
- `(or arg (setq arg 1))` —— 没给参数就当 1，即「往前一个句子」。
- `(funcall forward-sentence-function arg)` —— 把活**委托**给变量 `forward-sentence-function` 指向的函数。

为什么绕一层变量？因为「怎么切句子」是**可替换**的。默认为 `forward-sentence-default-function`；如果某个 major mode 想用不同规则（比如程序代码），只要把 `forward-sentence-function` 设成别的函数即可，命令绑定和快捷键都不用改。**用变量存函数、运行时再分发**，是 [04 · 函数](04-functions.md) 讲过的「函数是值」在现场的一个直接应用。

## 31.2 句尾正则是「算」出来的

默认实现待会儿再看，先解决一个前置问题：句子结束的正则长什么样？它**不是一个写死的常量**，而是由 `sentence-end` 这个函数按当前设置**现算**出来的。最底层的一块拼图是常量 `sentence-end-base`：

```
(defcustom sentence-end-base "[.?!…‽][]\"'”’)}»›]*"
  "Regexp matching the basic end of a sentence, not including following space."
  :type 'regexp
  :safe #'stringp
  :version "25.1")
```

拆开读这个字符集：`[.?!…‽]` 匹配「句号、问号、感叹号、省略号、反向问号（西班牙语 ¿ 的变体）」，`[]\"'”’)}»›]*` 再吞掉紧跟其后的**成对收尾符号**——右中括号、引号、右括号、俄语书名号 `»`、法语引号 `›` 等等。所以 `他说：“完了。”` 里的右引号会被算进句尾，不会被漏掉。

但 `sentence-end-base` 只描述「基本句尾」，还不管后面跟几个空格。完整的句子结束正则由函数 `(sentence-end)` 负责拼装。示例的第 2 节就是把它打印出来（用第 4 节会讲到的可见化函数，把 TAB、换行显示成 `\t`、`\n`）：

```
== 2) sentence-end 是算出来的正则 ==
sentence-end 变量（没设过，所以是 nil） = nil
调用 (sentence-end) 算出来的正则：
  "\\([.?!…‽][]\"'”’)}»›]*\\($\\|[ \u00a0]$\\|\t\\|[ \u00a0][ \u00a0]\\)\\|[。．？！]+\\)[ \u00a0\t\n]*"
```

先注意第一行：变量 `sentence-end` 是 `nil`。**这里的 `sentence-end` 是「变量」也是「函数」，同名但两回事**：平时它是 `nil`，表示「按默认规则算」；`(sentence-end)` 是个函数，返回真正要用的正则。你如果直接 `(setq sentence-end "我的正则")`，就等于接管了切句规则（第 4 节会做这件事）。

再看算出来的正则（去掉转义后的可读版）：

- `\\( [.?!…‽][]\"'”’)}»›]* \\( $\|[ \u00a0]$\|\t\|[ \u00a0][ \u00a0] \\) \\|[。．？！]+ \\)` —— 前半段就是我们刚看的 `sentence-end-base`，后面接一个「必须出现」的结尾条件：行尾、一个「空格 + 行尾」、一个 TAB，或**两个连续的空格**；
- `\\|` 是「或者」；
- `[。．？！]+` —— 直接的「或者」：遇到全角的中文句号、点号、问号、感叹号（一个或多个）也算句尾；
- 最后 `[ \u00a0\t\n]*` —— 吞掉句尾后面所有空格、TAB、换行。

> 【坑】正则里的 `\u00a0` 不是「反斜杠 u 零零 a 零」，而是**不换行空格 NBSP**（U+00A0）。示例的可见化函数特意把它转义打印出来——在终端里它和普通空格**长得一模一样**，肉眼绝对分不出来。Emacs 31 的 `(sentence-end)` 源码里写着注释 `;; We accept non-break space along with space.`，也就是说**从网页上复制下来的文本里如果带 NBSP，`M-e` 会把它当成普通空格处理**。反过来说：如果你写了句尾却怎么也切不动，检查一下那个「空格」到底是不是真空格——在 Emacs 里把光标移到上面按 `C-u C-x =`（`what-cursor-position`）能看到字符码点。

那个「两个连续空格」就是下一节的主角。

## 31.3 `sentence-end-double-space`：一个被默认值坑到的细节

如果你在**只留一个空格**的英文文本上试 `M-e`，会遇到一个奇怪的现象：

```text
One sentence. Two sentences! Three? Four.
```

光标**不会**在 `sentence.` 后面停下。原因在上面的正则里——它要求句尾后跟「两个连续空格」。这个约定由变量 `sentence-end-double-space` 控制：

- 为 `t`（**本机 `-Q --batch` 下的默认值**）时，`(sentence-end)` 会生成上面那个「必须双空格」的版本；
- 为 `nil` 时，单个空格（或换行）就足以结束句子。

[03 · 变量与绑定](03-variables.md) 讲过 `let` 可以临时改一个变量的值。示例就用这个办法把两种约定放在一起对比。先看测量用的工具函数——它反复调用某个「前进函数」，把每次停下时覆盖的片段收集成列表：

```elisp
(defun my-collect-forward (fn text)
  "在 TEXT 里用 FN 一步步往前走，返回每次停下时覆盖的片段列表。
FN 走不动或报错（例如已到最后一个句尾）就停下。"
  (let ((acc nil))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (let ((start (point))
            (guard 0)
            (done nil))
        (while (and (not done) (< (point) (point-max)))
          (setq guard (1+ guard))
          (let ((before (point)))
            (condition-case nil
                (funcall fn 1)
              (error (setq done t)))
            (if (= (point) before)
                (setq done t)            ; 走不动了，退出
              (push (buffer-substring-no-properties start (point)) acc)
              (setq start (point))))
          (when (> guard 100) (setq done t)))   ; 防挂死的安全阀
        ;; 收尾：把剩下的文本作为最后一段
        (when (< start (point-max))
          (push (buffer-substring-no-properties start (point-max)) acc)))
      (nreverse acc))))
```

这段代码本身值得说两句，它是**写「逐段推进」类循环的标准套路**：

- `(funcall fn 1)` 每次让函数往前走一步；
- `(condition-case nil (funcall fn 1) (error (setq done t)))` —— 到了最后一个句尾，`forward-sentence` **会报错**（而不是安静地停下），必须接住错误。这是真实命令的常见行为：**能走就走，走不动就报错**；
- `(if (= (point) before) (setq done t) …)` —— 兜底判断：如果调用了函数但 point 没动，说明卡住了，赶紧退出，否则死循环；
- `guard` 安全阀是防止意外情况把示例挂死；
- 用 `with-temp-buffer` 起一个临时缓冲区，`goto-char (point-min)` 放到开头——**测移动函数一定要放进真实缓冲区**，因为这类函数的输入是「缓冲区里的文本」而不是字符串。

用它在两种约定下各走一遍：

```elisp
(let ((text "One sentence. Two sentences! Three? Four.\n"))
  (dolist (flag '(t nil))
    (let ((sentence-end-double-space flag))
      (princ (format "sentence-end-double-space = %S：\n" flag))
      (dolist (piece (my-collect-forward #'forward-sentence text))
        (princ (format "  [\"%s\"]\n" (my-visible piece)))))))
```

`dolist` 依次把 `flag` 取成 `t`、`nil`，内层 `let` 临时把 `sentence-end-double-space` 绑成它。输出：

```
默认值 = t
sentence-end-double-space = t：
  ["One sentence. Two sentences! Three? Four."]
  ["\n"]
sentence-end-double-space = nil：
  ["One sentence."]
  [" Two sentences!"]
  [" Three?"]
  [" Four."]
  ["\n"]
```

对照非常清楚：**`t` 时整行切不动**（因为全是单空格），只有末尾那个换行被当成了句尾；**`nil` 时四个句子被干净切开**（注意每段片段保留了前导空格，因为 `[  \t\n]*` 会把句尾后的空格一起吃进这一段，下一段就从下一个非空格字符开始——这和你按 `M-e` 后光标停在句子末尾、空格之前的手感是一致的）。

> 【坑】不要把这里和 word 处理混起来。`sentence-end-double-space` 的默认值是 `t` 早在 1980 年代（GNU Emacs 时代）就定下了，为的是区分「句子结束」和「缩写点」。现代英文排版大多用单空格，所以很多人第一次遇到 `M-e` 失灵都会困惑。示例里 `(princ (format "默认值 = %S\n" sentence-end-double-space))` 直接把它打出来，就是为了让这个隐藏的默认值现身。

## 31.4 走一遍默认实现 `forward-sentence-default-function`

回到 `forward-sentence` 委托出去的那个函数。31.1 的真实源码：

```
(defun forward-sentence-default-function (&optional arg)
  "Move forward to next end of sentence.  With argument, repeat.
When ARG is negative, move backward repeatedly to start of sentence.

The variable `sentence-end' is a regular expression that matches ends of
sentences.  Also, every paragraph boundary terminates sentences as well."
  (or arg (setq arg 1))
  (let ((opoint (point))
        (sentence-end (sentence-end)))
    (while (< arg 0)
      (let ((pos (point))
	    par-beg par-text-beg)
	(save-excursion
	  (start-of-paragraph-text)
	  ;; Start of real text in the paragraph.
	  ;; We move back to here if we don't see a sentence-end.
	  (setq par-text-beg (point))
	  ;; Start of the first line of the paragraph.
	  ;; We use this as the search limit
	  ;; to allow sentence-end to match if it is anchored at
	  ;; BOL and the paragraph starts indented.
	  (beginning-of-line)
	  (setq par-beg (point)))
	(if (and (re-search-backward sentence-end par-beg t)
		 (or (< (match-end 0) pos)
		     (re-search-backward sentence-end par-beg t)))
	    (goto-char (match-end 0))
	  (goto-char par-text-beg)))
      (setq arg (1+ arg)))
    (while (> arg 0)
      (let ((par-end (save-excursion (end-of-paragraph-text) (point))))
	(if (re-search-forward sentence-end par-end t)
	    (skip-chars-backward " \t\n")
	  (goto-char par-end)))
      (setq arg (1- arg)))
    (constrain-to-field nil opoint t)))
```

逐块读：

1. `(or arg (setq arg 1))` —— 和 `forward-sentence` 一样，缺省往前一句。
2. `(let ((opoint (point)) (sentence-end (sentence-end))) …)` —— 两个局部绑定值得注意：
   - `opoint` 记住**起始位置**，最后 `(constrain-to-field nil opoint t)` 用它（见下）；
   - `sentence-end` 这个名字**同时遮蔽了同名变量**：`let` 的绑定值来自函数调用 `(sentence-end)`。这样，函数体下面所有 `re-search-forward sentence-end …` 里用的都是「算好的正则」，而不是外面那个可能是 `nil` 的变量。**同一个名字在这里做「函数」和「变量」两种角色**——这是 Emacs Lisp 里合法的（Lisp-2 传统下函数和变量分属两个命名空间），但读代码时要看清哪一处是哪个。
3. 两个 `while` 循环：`(< arg 0)` 处理**往回走**，`(> arg 0)` 处理**往前走**。因为 `arg` 可能大于 1（`M-e` 带数字前缀），所以是循环而不是一次到位。
4. 往前走的循环是本章重点：

```
    (while (> arg 0)
      (let ((par-end (save-excursion (end-of-paragraph-text) (point))))
	(if (re-search-forward sentence-end par-end t)
	    (skip-chars-backward " \t\n")
	  (goto-char par-end)))
      (setq arg (1- arg)))
```

- `(save-excursion (end-of-paragraph-text) (point))` —— 先算出「当前段落的末尾」，作为搜索的**上界**。`save-excursion` 保证算完之后 point 回到原处。这就是那句 docstring 说的「段落边界也算句子终点」：**搜索不会越过段落末尾**，一段的最后一句哪怕没有句号，也会停在段落末尾。
- `(re-search-forward sentence-end par-end t)` —— 在 `par-end` 之前找句尾；`t` 表示找不到不报错、只返回 `nil`。
- 找到就 `(skip-chars-backward " \t\n")` —— 把 point 从「句尾正则匹配完的位置」**往回退掉尾随空白**。因为正则里的 `[  \t\n]*` 把句尾后的空格也吃掉了，不往后退，`M-e` 后光标会停在下一句开头，而不是本句末尾。
- 找不到就 `(goto-char par-end)` —— 直接跳到段落末尾。
- `(constrain-to-field nil opoint t)` —— 把 point「夹」回它所在的**字段（field）**范围内。字段是带文本属性的区域（比如 `comint` 提示符、被 `read-only` 保护的区域）。`opoint` 是移动前的原位置，用来判断「移动前在哪个字段」。这是很多移动命令都会做的收尾处理，本章不必深究，只需知道：**它保证你不会「穿出」一个带属性的区域**。

`arg` 为负的往回走分支逻辑对称：先用 `(save-excursion (start-of-paragraph-text) …)` 求出段落起点作为下界，再 `re-search-backward`。读到这里，本章开头那句「把自然语言结构翻译成正则」已经兑现：**剩下的全是围绕正则的边界管理**。

## 31.5 段落：由两个正则共同定义

句子的规则讲完了，段落呢？段落由**两个**正则共同定义，31.1 的真实默认值：

```
(defcustom paragraph-start "\f\\|[ \t]*$" "\
Regexp for beginning of a line that starts OR separates paragraphs.
This regexp should match lines that separate paragraphs
and should also match lines that start a paragraph
\(and are part of that paragraph).

This is matched against the text at the left margin, which is not necessarily
the beginning of the line, so it should never use \"^\" as an anchor.  This
ensures that the paragraph functions will work equally well within a region
of text indented by a margin setting.

The variable `paragraph-separate' specifies how to distinguish
lines that start paragraphs from lines that separate them.

If the variable `use-hard-newlines' is non-nil, then only lines following a
hard newline are considered to match."
  :type 'regexp
  :safe #'stringp)
```

```
(defcustom paragraph-separate "[ \t\f]*$"
  "Regexp for beginning of a line that separates paragraphs.
If you change this, you may have to change `paragraph-start' also.

This is matched against the text at the left margin, which is not necessarily
the beginning of the line, so it should not use \"^\" as an anchor.  This
ensures that the paragraph functions will work equally within a region of
text indented by a margin setting."
  :type 'regexp
  :safe #'stringp)
```

先看两个细节，它们解释了为什么源码长得有点怪：

- `paragraph-start` 的 docstring 是写在**第二行**的：`"Regexp for … paragraphs.` 前面那个 `"\` —— 行尾的**反斜杠**表示「紧接着的换行不算字符串内容」。这是 Emacs Lisp 里给 docstring 换行的老写法，效果是让首行不被算进 docstring（Emacs 的 docstring 约定：第一行应当是**独立完整的一句话**）。`paragraph-separate` 的 docstring 就正常写在值后面一行，没有这个反斜杠。
- 两个正则里都出现了 `\f`：`paragraph-start` 的 `"\f\\|[ \t]*$"` 是「分页符 **或** 空行」；`paragraph-separate` 的 `"[ \t\f]*$"` 把分页符也当成空白。Emacs 至今仍把 `^L`（分页符）当成分节符（`C-x ]` / `forward-page` 就靠它），段落函数顺手也认。

它们的默认值都匹配**空行**（`[ \t]*$` 是「只有空白直到行尾」，也就是空行），区别在于：

- `paragraph-start`：匹配「一行的开头，这一行**要么启动一段、要么分隔两段**」。所以它匹配空行，也匹配 `\f`（分页符）。
- `paragraph-separate`：匹配「一行的开头，这一行**分隔两段**（不是某段的一部分）」。默认也匹配空行。

两个都匹配空行时，空行**只起分隔作用**——所以「空行下面是新段落」。如果你改 `paragraph-start` 让它匹配别的（比如以 `*` 开头的行，第 6 节会做），空行就不一定是段首了，这时 `paragraph-separate` 负责把「纯粹的分隔行」和「真正开始一段的行」区分开。

docstring 里那句「should never use `^` as an anchor」很关键，它解释了段落函数的一个设计选择；最后那段 `use-hard-newlines` 说明开了「硬换行」模式后（长行不自动折行、`use-hard-newlines` 非 `nil`），只有**紧跟硬换行**的行才算匹配——这是 `longlines-mode` 那一类模式留下的钩子。

## 31.6 走一遍 `forward-paragraph`

31.1 的真实源码（较长，下面分段解释）：

```
(defun forward-paragraph (&optional arg)
  "Move forward to end of paragraph.
With argument ARG, do it ARG times;
a negative argument ARG = -N means move backward N paragraphs.

A line which `paragraph-start' matches either separates paragraphs
\(if `paragraph-separate' matches it also) or is the first line of a paragraph.
A paragraph end is the beginning of a line which is not part of the paragraph
to which the end of the previous line belongs, or the end of the buffer.
Returns the count of paragraphs left to move."
  (interactive "^p")
  (or arg (setq arg 1))
  (let* ((opoint (point))
	 (fill-prefix-regexp
	  (and fill-prefix (not (equal fill-prefix ""))
	       (not paragraph-ignore-fill-prefix)
	       (regexp-quote fill-prefix)))
	 ;; Remove ^ from paragraph-start and paragraph-sep if they are there.
	 ;; These regexps shouldn't be anchored, because we look for them
	 ;; starting at the left-margin.  This allows paragraph commands to
	 ;; work normally with indented text.
	 ;; This hack will not find problem cases like "whatever\\|^something".
	 (parstart (if (and (not (equal "" paragraph-start))
			    (equal ?^ (aref paragraph-start 0)))
		       (substring paragraph-start 1)
		     paragraph-start))
	 (parsep (if (and (not (equal "" paragraph-separate))
			  (equal ?^ (aref paragraph-separate 0)))
		     (substring paragraph-separate 1)
		   paragraph-separate))
	 (parsep
	  (if fill-prefix-regexp
	      (concat parsep "\\|"
		      fill-prefix-regexp "[ \t]*$")
	    parsep))
	 ;; This is used for searching.
	 (sp-parstart (concat "^[ \t]*\\(?:" parstart "\\|" parsep "\\)"))
	 start found-start)
```

先看 `let*` 里的准备工作（`let*` 与 `let` 的区别是会**依次**绑定，后面的绑定能用前面刚绑的值）：

- `opoint`：和 `forward-sentence` 一样，记起始位置，最后 `constrain-to-field` 用。
- `fill-prefix-regexp`：如果你设了 `fill-prefix`（比如邮件引用前缀 `"> "`），把它转成正则，让段落识别能正确处理缩进。
- **`parstart` / `parsep`：把 `paragraph-start`、`paragraph-separate` 开头的 `^` 去掉**。这就是 docstring 那句「不要用 `^`」的兑现方式——段落函数的搜索**不是从行首开始**，而是从「左边距（left margin）」开始：

```
	 (sp-parstart (concat "^[ \t]*\\(?:" parstart "\\|" parsep "\\)"))
```

- `sp-parstart` 把两个正则合成一个：「行首 + 任意前导空白 + （段首正则 **或** 段分隔正则）」。`\\(?: … \\)` 是**非捕获组**——只分组、不占用 `\1` 这样的捕获编号（`\1` 留给真正的 `\\(…\\)` 用）。因为去掉了 `^`，所以即使段落被缩进（前导空白由 `[ \t]*` 吃掉），也能正确匹配。
- `start`、`found-start`：`let*` 里**没有初值**的裸变量，先声明成 `nil`，循环里再用。

接下来两个 `while`，结构和 `forward-sentence` 完全对称。往回走的分支：

```
    (while (and (< arg 0) (not (bobp)))
      (if (and (not (looking-at parsep))
	       (re-search-backward "^\n" (max (1- (point)) (point-min)) t)
	       (looking-at parsep))
	  (setq arg (1+ arg))
	(setq start (point))
	;; Move back over paragraph-separating lines.
	(forward-char -1) (beginning-of-line)
	(while (and (not (bobp))
		    (progn (move-to-left-margin)
			   (looking-at parsep)))
	  (forward-line -1))
```

关键在于 `(move-to-left-margin)` 的出现：它把 point 移到**左边距**（而不是行首），然后 `(looking-at parsep)` 从那里开始匹配。这正是前面强调的「段落正则不做行首锚定」在代码里的落点。往回的空行被一段 `(forward-line -1)` 循环跨过；跨完之后，往回找段首用的也是 `sp-parstart`，只是方向反过来：

```
		(while (and (re-search-backward sp-parstart nil 1)
			    (setq found-start t)
			    ;; Found a candidate, but need to check if it is a
			    ;; REAL parstart.
			    (progn (setq start (point))
				   (move-to-left-margin)
				   (not (looking-at parsep)))
			    (not (and (looking-at parstart)
				      (or (not use-hard-newlines)
					  (bobp)
					  (get-text-property
					   (1- start) 'hard)))))
		  (setq found-start nil)
		  (goto-char start))
```

注意 `(setq found-start t)` 被塞进了 `while` 的**条件里**：`and` 的每个分支都会求值，所以「每找到一次候选就先把 `found-start` 置真」这个副作用就顺手办了。这种写法在真实代码里很常见，但读的时候要认出来——它不是在判断真假，而是在**顺带赋值**（`and` 只关心最后结果，`t` 恒真所以不影响条件）。循环体里的 `(setq found-start nil)` 才是「这个候选不合格」的回退。剩下那两个 `use-hard-newlines` / `get-text-property … 'hard` 的判断，是给 `use-hard-newlines`（硬换行）模式留的口子，这里不展开。

往前走的 `while` 分支是本章示例第 5、6 节实际走过的路径：

```
    (while (and (> arg 0) (not (eobp)))
      ;; Move forward over separator lines...
      (while (and (not (eobp))
		  (progn (move-to-left-margin) (not (eobp)))
		  (looking-at parsep))
	(forward-line 1))
      (unless (eobp) (setq arg (1- arg)))
      ;; ... and one more line.
      (forward-line 1)
      (if fill-prefix-regexp
	  ;; There is a fill prefix; it overrides parstart.
	  (while (and (not (eobp))
		      (progn (move-to-left-margin) (not (eobp)))
		      (not (looking-at parsep))
		      (looking-at fill-prefix-regexp))
	    (forward-line 1))
	(while (and (re-search-forward sp-parstart nil 1)
		    (progn (setq start (match-beginning 0))
			   (goto-char start)
			   (not (eobp)))
		    (progn (move-to-left-margin)
			   (not (looking-at parsep)))
		    (or (not (looking-at parstart))
			(and use-hard-newlines
			     (not (get-text-property (1- start) 'hard)))))
	  (forward-char 1))
	(if (< (point) (point-max))
	    (goto-char start))))
    (constrain-to-field nil opoint t)
    ;; Return the number of steps that could not be done.
    arg))
```

顺着读就是「一个段落往前走」的完整过程：

1. 先跨过**开头的空行**（`looking-at parsep` 的 `forward-line` 循环）；
2. `(unless (eobp) (setq arg (1- arg)))` —— 只要还不在文件末尾，就算消耗掉一次前进；
3. `(forward-line 1)` —— 至少往后过一行（保证进度）；
4. `(if fill-prefix-regexp … …)` —— **二选一**。如果设了 `fill-prefix`（例如邮件里每行前面的 `"> "`），就走 then 分支：逐行往下，只要还是「带 fill 前缀、且不是分隔行」就继续，也就是**按前缀来划段**，`parstart` 被完全忽略（注释里写的 `it overrides parstart`）。没设 `fill-prefix` 时走 else 分支，也就是下面第 5 步的正则搜索。示例用的是 `-Q --batch`，`fill-prefix` 是 `nil`，所以走的是 else。
5. 内层 `re-search-forward sp-parstart` 循环：**一直搜到下一个「段首或段分隔行」**。循环条件里的 `(or (not (looking-at parstart)) …)` 用来确认「匹配到的确实是新段的开始，而不是当前段自己中间某行恰好长得像段首」；
6. `(if (< (point) (point-max)) (goto-char start))` —— 回到那个「新段开始」的位置（`start` 是匹配位置的记录），于是光标就停在**上一段的末尾 / 新段之前**，这正是 `M-}` 的行为。
7. 最后的 `(constrain-to-field nil opoint t)` 与 `forward-sentence` 同款；返回值是「没能走完的步数」——正常走完时是 `0`。

示例第 5 节在一条多段文本上实测：

```
== 5) 用 forward-paragraph 走一遍 ==
  起点：第 1 行（point=1）
  前进后：第 3 行（point=39）
  前进后：第 5 行（point=50）
  前进后：第 8 行（point=64）
  收尾：第 8 行（point-max=64）
```

文本是 `"Para one line one.\nPara one line two.\n\nPara two.\n\n\nPara three.\n"`：第一段两行，空行分隔，第二段一行，两个空行，第三段一行。每次 `forward-paragraph` 都跳到下一个段落的**开头行**，最后停在文件末尾（`point=64` 即 `point-max`）。注意这里用的是「先检查 `< (point) (point-max)`、再调用」的写法（而不是靠 `forward-paragraph` 的返回值判断），因为前面提过：**它成功时返回 `0`，而 `0` 在 Lisp 里是真值**——如果写成 `(while (forward-paragraph 1) …)`，`0` 会让循环误以为「还可以继续」，反而容易踩坑。

第 6 节把 `paragraph-start` 改成 `"^\\*"`，让**以 `*` 开头的行**成为段首：

```
== 6) 自定义 paragraph-start ==
paragraph-start 设为 "^\\*"（forward-paragraph 会去掉开头的 ^）
  起点：第 1 行（point=1）
  前进后：第 3 行（point=12）
  前进后：第 5 行（point=23）
  收尾：第 5 行（point-max=23）
```

文本是 `"* 标题一\n正文一。\n* 标题二\n正文二。\n"`。设置为 `"^\\*"` 后，`forward-paragraph` 内部的 `parstart` 会把它变成 `"\\*"`（去掉那个 `^`），于是「以 `*` 开头」的判定在左边距处生效，每个 `*` 行都被当成新段落的开始。**这个「去掉开头 `^`」的动作就是 `let*` 里那段 `(substring paragraph-start 1)`**——回头再看它，就不是无意义的字符串截取了。

## 31.7 两个配角：`start-of-paragraph-text` 与 `end-of-paragraph-text`

`forward-sentence` 和 `forward-paragraph` 内部反复调用一对辅助函数，它们也值得单独看。31.1 的真实源码：

```
(defun start-of-paragraph-text ()
  "Move to the start of the current paragraph."
  (let ((opoint (point)) npoint)
    (forward-paragraph -1)
    (setq npoint (point))
    (skip-chars-forward " \t\n")
    ;; If the range of blank lines found spans the original start point,
    ;; try again from the beginning of it.
    ;; Must be careful to avoid infinite loop
    ;; when following a single return at start of buffer.
    (if (and (>= (point) opoint) (< npoint opoint))
	(progn
	  (goto-char npoint)
	  (if (> npoint (point-min))
	      (start-of-paragraph-text))))))
```

```
(defun end-of-paragraph-text ()
  "Move to the end of the current paragraph."
  (let ((opoint (point)))
    (forward-paragraph 1)
    (if (eq (preceding-char) ?\n) (forward-char -1))
    (if (<= (point) opoint)
	(progn
	  (forward-char 1)
	  (if (< (point) (point-max))
	      (end-of-paragraph-text))))))
```

两个函数都很短，但都是**递归**的（28 章讲过）：

- `start-of-paragraph-text`：先 `(forward-paragraph -1)` 退到上一段末尾，再 `(skip-chars-forward " \t\n")` 跳过空行走到本段真正开头的第一个非空白字符。如果「跳过的空行跨过了出发位置」（即出发时点在空行区里），就 `goto-char npoint` 回到更靠前的位置**再递归一次**，直到落进真正有文字的段落。这解决了「光标本来就在一串空行中间时，『上一段』到底是哪个」的歧义。
- `end-of-paragraph-text`：`(forward-paragraph 1)` 之后，如果前一个字符是换行就退一格（停在段落的最后一个非换行字符后面）。如果发现 point **没往前走**（`(<= (point) opoint)`，说明本来就卡在段落边界上），就 `(forward-char 1)` 强行推进再递归，避免原地打转。

示例第 7 节直接用这两个函数在段落之间定位：

```elisp
(with-temp-buffer
  (insert "Para one.\n\nPara two line one.\nPara two line two.\n\nPara three.\n")
  (goto-char (point-min))
  (forward-paragraph 1)                 ; 先走到第二段
  (end-of-paragraph-text)
  (princ (format "走到第二段末尾：point=%S，前面那个字符是 %S\n"
                 (point) (char-to-string (char-before))))
  (start-of-paragraph-text)
  (princ (format "回到第二段开头：point=%S，接下来是 %S\n"
                 (point) (buffer-substring-no-properties
                          (point) (min (+ (point) 8) (point-max))))))
```

输出：

```
== 7) 段落的起点与终点 ==
走到第二段末尾：point=49，前面那个字符是 "."
回到第二段开头：point=12，接下来是 "Para two"
```

`(char-before)` 是那个「前面那个字符」，打印出来是 `"."`——证明 `end-of-paragraph-text` 确实停在了第二段最后一个句号之后（而不是换行之后）；`start-of-paragraph-text` 之后 point 落在 `"Para two"` 的 `P` 上，位置从 49 回到 12，正是第二段的开头。

## 31.8 小结

| 零件 | 角色 | 一句话记忆 |
|---|---|---|
| `forward-sentence` | 命令外壳 | 只做 `(funcall forward-sentence-function arg)`，实现可替换 |
| `sentence-end-base` | 基本句尾正则 | `[.?!…‽]` + 一串成对收尾符号 |
| `(sentence-end)` 函数 | 现算完整句尾正则 | 受 `sentence-end-double-space` 影响；变量 `sentence-end` 为 `nil` 时走默认 |
| `forward-sentence-default-function` | 默认实现 | 先求段落边界作搜索上界，再 `re-search-forward` + `skip-chars-backward` |
| `paragraph-start` | 段首 OR 分隔行 | 默认匹配空行；**不要用 `^` 锚定** |
| `paragraph-separate` | 只管分隔行 | 和 `paragraph-start` 配合区分「新段」与「纯分隔」 |
| `forward-paragraph` | 段落推进 | `let*` 里去掉 `^`、拼出 `sp-parstart`，两个 `while` 对称处理正负参数；成功返回 `0`（真值！） |
| `start-of-paragraph-text` / `end-of-paragraph-text` | 段落两端定位 | 都是递归函数，处理「光标恰在空行/边界上」的歧义 |

贯穿本章的一条主线：**把「人觉得模糊」的结构（句子、段落）交给正则去定义，再用边界管理（`save-excursion`、`skip-chars`、段落上界）把 point 精确地放到位**。下一章我们用同样的手法，但把正则用在**计数**上：`count-words` 如何数清一个缓冲区里的词。

上一章：[30 · kill ring：剪切与粘贴的实现](30-kill-ring.md)　｜　下一章：[32 · 词频统计：从 count-words 到一个完整的扩展](32-count-words.md)　｜　返回：[Emacs 扩展开发指南](README.md)
