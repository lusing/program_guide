# 32 · 词频统计：从 count-words 到一个完整的扩展

> 所属部分：第 8 部分 · 跟随 eintr：读懂真实代码

> 示例：`examples/32-count-words.el`

上一章我们把「句子、段落」这类模糊结构交给正则去定义；本章把正则用在**计数**上。计数看似简单——「数一段文字里有几个词」——但它能把本教程前面所有零件串起来：正则搜索（[08 · 字符串与正则](08-strings-regexp.md)）、循环与递归（[05 · 控制流](05-control-flow.md)、[28 · 递归](28-recursion.md)）、`save-excursion`/`narrow-to-region`（[10 · buffer 与 point](10-buffers.md)）、哈希表，最后包成一个**能按 `M-x` 调用的命令**（[13 · 交互式命令](13-interactive.md)）。

eintr 用「数词数」这件小事演示了「同一个问题可以有多种写法」，本机把它在 Emacs 31.1 下重新走一遍，并把它扩成一个真正有用的**词频统计**工具。

## 32.1 读源码：Emacs 自己怎么数词

先看 Emacs 的 `count-words`。它是 Emacs 31.1 的真实源码（`simple.el`）：

```
(defun count-words (start end &optional totals)
  "Count words between START and END.
If called interactively, START and END are normally the start and
end of the buffer; but if the region is active, START and END are
the start and end of the region.  Print a message reporting the
number of lines, sentences, words, and chars.  With prefix
argument, also include the data for the entire (un-narrowed)
buffer.

If called from Lisp, return the number of words between START and
END, without printing any message.  TOTALS is ignored when called
from Lisp."
  (interactive (list nil nil current-prefix-arg))
  ;; When called from Lisp, return the data.
  (if (not (called-interactively-p 'any))
      (let ((words 0)
            ;; Count across field boundaries. (Bug#41761)
            (inhibit-field-text-motion t))
	(save-excursion
	  (save-restriction
	    (narrow-to-region start end)
	    (goto-char (point-min))
	    (while (forward-word-strictly 1)
	      (setq words (1+ words)))))
	words)
    ;; When called interactively, message the data.
    (let ((totals (if (and totals
                           (or (use-region-p)
                               (buffer-narrowed-p)))
                      (save-restriction
                        (widen)
                        (count-words--format "; buffer in total"
                                             (point-min) (point-max)))
                    "")))
      (if (use-region-p)
	  (message "%s%s" (count-words--format
                           "Region" (region-beginning) (region-end))
                   totals)
        (message "%s%s" (count-words--buffer-format) totals)))))
```

这个函数虽短，却藏着三个值得学的写法。

**一分为二：交互用法 vs 编程用法。** 看一眼结构就明白：整个函数体是一个大 `if`，条件是 `(not (called-interactively-p 'any))`。

- 从 Lisp 里调用（比如 `(count-words (point-min) (point-max))`）时，`called-interactively-p` 为 `nil`，走**上半支**：老老实实数词，**返回数字**（`words`），不打印任何消息。
- 按 `M-x count-words`、或绑定快捷键触发时，`called-interactively-p` 为真，走**下半支**：调用 `count-words--format` 拼出一句话，用 `message` **报**给用户（而不是返回数字）。

这就是 docstring 说的「Called from Lisp, return the number of words ... without printing any message」。**同一个命令，对「人」和「程序」是两副面孔**：人要看一句话，程序要拿一个数。`(interactive (list nil nil current-prefix-arg))` 那行负责在交互触发时把 START、END 填成 `nil`（表示「用默认范围」）、把前缀参数传给 `totals`。

**`words` 是累加器。** 上半支的核心是这个循环：

```
      (let ((words 0)
            ;; Count across field boundaries. (Bug#41761)
            (inhibit-field-text-motion t))
	(save-excursion
	  (save-restriction
	    (narrow-to-region start end)
	    (goto-char (point-min))
	    (while (forward-word-strictly 1)
	      (setq words (1+ words)))))
	words)
```

`words` 从 `0` 开始，每成功前移一个词就 `(1+ words)`。为什么循环条件能直接用 `(forward-word-strictly 1)` 的返回值？因为它的 docstring 说「Normally returns `t`。到缓冲区边界就停在那里并返回 `nil`」——**「还能往前走」这个事实，正好被它自己编码成了真/假**。于是循环不必额外判断「到没到头」，`nil` 自然终止。这跟上一章 `forward-paragraph` 返回 `0`（真值！）形成对照组，提醒我们：**调用前务必确认返回值的真假含义**。

`let` 里还多绑了一个一眼看不懂的 `(inhibit-field-text-motion t)`。上一章末尾提过「字段（field）」——带文本属性的受保护区域（`comint` 提示符、只读区域等），移动命令会用 `constrain-to-field` 把 point 夹在字段内。**字段边界会拦住移动函数**：`forward-word-strictly` 撞到字段边界也会返回 `nil`（docstring 明写）。于是如果区间里含字段边界，循环会提前停下、数少了。把它设成 `t` 就等于说「这次遍历别管字段」，配合源码里那句注释 `;; Count across field boundaries. (Bug#41761)`——**这是修一个真实 bug 时加进去的**。读真实源码常能撞见这种「一行补丁 + 一个 bug 号」，它往往正是最值得琢磨的地方：先想明白「没有这一行会怎样」，那一行的作用就懂了。

**`save-excursion` + `save-restriction` + `narrow-to-region` 三件套。** 这段是「在一个区间里做遍历、做完全复原」的标准范式：

- `(narrow-to-region start end)` 把缓冲区的**可见范围**收缩到 START..END，于是 `(point-min)`、`(point-max)` 都指向这个新区间的两端，循环天然只在区间内跑；
- `save-restriction` 保证函数返回时**把收缩还原**；
- `save-excursion` 保证函数返回时**把 point 还原**；
- 在它们里面 `(goto-char (point-min))` 从区间开头开始遍历。

[10 · buffer 与 point](10-buffers.md) 讲过 `narrow-to-region`；这里要记住的是：**「先缩范围、再遍历、最后复原」是写「处理某个区间」的第一选择**，你几乎不需要自己管边界加减。

## 32.2 `forward-word-strictly`：为什么不用 `forward-word`

`count-words` 用的不是 `forward-word`，而是 `forward-word-strictly`。同样是 Emacs 31.1 的真实源码（`subr.el`）：

```
(defun forward-word-strictly (&optional arg)
  "Move point forward ARG words (backward if ARG is negative).
If ARG is omitted or nil, move point forward one word.
Normally returns t.
If an edge of the buffer or a field boundary is reached, point is left there
and the function returns nil.  Field boundaries are not noticed if
`inhibit-field-text-motion' is non-nil.

This function is like `forward-word', but it is not affected
by `find-word-boundary-function-table'.  It is also not interactive."
  (let ((find-word-boundary-function-table
         (if (char-table-p word-move-empty-char-table)
             word-move-empty-char-table
           (setq word-move-empty-char-table (make-char-table nil)))))
    (forward-word (or arg 1))))
```

它的全部工作就是：**临时把 `find-word-boundary-function-table` 换成一个空字符表，然后调用普通的 `forward-word`**。

`find-word-boundary-function-table` 是一个「按字符决定词边界在哪」的查找表——某些 major mode（比如处理 CJK、或特殊脚本的模式）会用它**改写默认的词边界**。`forward-word` 尊重这张表，而 `forward-word-strictly` 用一张空表把它**屏蔽掉**，于是永远按 Emacs 内置的规则断词。

对计数来说为什么要这样？因为**计数要的是「同一把尺子量到底」**：`count-words--format` 还要拿 `count-words` 的结果去和行数、句数并列，如果断词规则随模式飘忽，同一段文字在不同 mode 下会数出不同的词数。用一个**不受模式影响的严格版本**，结果才稳定、可复现。

顺带留意那个 `word-move-empty-char-table` 的写法：它是个**缓存**。第一次调用时表还不存在，`(char-table-p …)` 为假，于是 `(setq … (make-char-table nil))` 造一张空表并存进变量；之后再调用就直接复用。**「用变量记住算过一次的东西、下次直接用」——惰性缓存**，你在真实代码里会经常见到。

## 32.3 三种算法，同一个答案

`count-words` 用的是「`forward-word` 循环 + 计数器」。示例的第 2 节干脆把**三种写法**摆在一起，看它们是否给出一致的结果。

先准备一段样本文本（示例里的 `my-text`）：

```elisp
(defconst my-text
  (concat "We hold these truths to be self-evident, that all men are created equal,"
          " that they are endowed by their Creator with certain unalienable Rights,"
          " that among these are Life, Liberty and the pursuit of Happiness.")
  "用来数词的样本文本。")
```

**(a) 迭代版**——最直白，一步一个词：

```elisp
(defun my-count-iter (start end)
  "数 START 到 END 之间的词数（迭代版）。"
  (let ((words 0))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (forward-word 1)
          (setq words (1+ words)))))
    words))
```

这几乎就是 `count-words` 上半支的翻版：同样的 `save-excursion`/`save-restriction`/`narrow-to-region` 三件套、同样的 `(while (forward-word 1) …)`。这里用 `forward-word` 而不是 strictly 版，是为了说明**在这个例子里两者结果相同**——区别只在特殊模式下才显现。

**(b) 递归版**——把「还有词吗」当作递归的驱动（eintr 第 13 章的写法）：

```elisp
(defun my-count-recursive (region-end)
  "point 到 REGION-END 之间的词数（递归）。"
  (if (and (< (point) region-end)
           (re-search-forward "\\w+\\W*" region-end t))
      (1+ (my-count-recursive region-end))
    0))

(defun my-count-recur (start end)
  "数 START 到 END 之间的词数（递归版的入口）。"
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (my-count-recursive (point-max)))))
```

读法：`(re-search-forward "\\w+\\W*" region-end t)` 从当前位置往后找一个「词后跟一串非词字符」，`\\w+` 是「一个或多个词构成字符」（字母、数字、下划线），`\\W*` 是「其后任意多的非词字符」（空格、标点都算）。找到一个，就在「本词的计数 1」上**递归**去数剩下的部分，直到 `re-search-forward` 再也找不到（返回 `nil`）——这时返回 `0`，递归逐层「加 1」回来。

[28 · 递归](28-recursion.md) 里讲过两个要点，这里正好对上：

- **必须有 base case**：`re-search-forward` 返回 `nil`（走不动了）时不再递归、直接返回 `0`；
- **`1+` 套在递归调用外面**：`(1+ (my-count-recursive region-end))` 表示「我这个词 + 后面的词」，让每层递归各自加一次自己的那份。

还要注意那个 `(< (point) region-end)` 的前置判断。它防止一种边界情况：如果当前位置已经在区间末尾，`re-search-forward` 可能一次也不匹配，光靠它的返回值也能停下；但这层显式判断让「已经到头」这件事一眼可见，读起来更清楚。

**(c) 一次正则版**——只遍历、不计数中间态：

```elisp
(defun my-count-regexp (start end)
  "数 START 到 END 之间的词数（正则版）。"
  (let ((n 0))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (re-search-forward "\\w+" nil t)
          (setq n (1+ n)))))
    n))
```

它不需要 `\\W*`：`re-search-forward "\\w+"` 每找到一个词就停在该词末尾，下一次从那里继续找下一个词，**中间的非词字符被自动跳过**，所以计数天然正确。三者殊途同归：

```
== 2) 三种算法对比 ==
文本共 209 个字符
真实 count-words   = 36
我的迭代版         = 36
我的递归版         = 36
我的一次正则版     = 36
```

四个数字都是 **36**。这里有个值得记的工程习惯：**当你用不同方法解同一个问题，就让它们互相对答案**。示例特意把「真实 `count-words`」也放进来当基准——如果某个自研版本数出 37，你立刻知道它错了，而不是等到用户抱怨才发现。这叫**用已知正确的实现做夹具（fixture）**。

## 32.4 一次报四样：`count-words--format`

回到 `count-words` 下半支调用的两个帮手。`count-words--format`（Emacs 31.1 真实源码）：

```
(defun count-words--format (str start end)
  (let ((lines (count-lines start end))
	(sentences (count-sentences start end))
	(words (count-words start end))
	(chars (- end start)))
    (format "%s has %d line%s, %d sentence%s, %d word%s, and %d character%s"
	     str
	     lines (if (= lines 1) "" "s")
	     sentences (if (= sentences 1) "" "s")
	     words (if (= words 1) "" "s")
	     chars (if (= chars 1) "" "s"))))
```

逐点看：

- `let` 里一次算出四个量：`lines` 用 `count-lines`、`sentences` 用 `count-sentences`、`words` 用 `count-words`（**注意这里就是递归地回到我们刚读的那个函数**），`chars` 直接是 `(- end start)`——字符数根本不用数，区间长度相减即可。
- `format` 里那串 `(if (= lines 1) "" "s")` 是**单复数处理**：1 行显示 `line`，否则 `line s`。四个量都套了同一招。**英文文案要显复数时，这是最省事的写法**，不用写四份分支模板。
- 注意 `count-words` 在这里**没有被交互地调用**，所以它走上半支、**返回数字**——这正是它的双面设计在内部被复用的地方。

`count-words--buffer-format` 更短，只是替 `count-words--format` 选好称呼和范围：

```
(defun count-words--buffer-format ()
  (count-words--format
   (if (buffer-narrowed-p) "Narrowed part of buffer" "Buffer")
   (point-min) (point-max)))
```

`(buffer-narrowed-p)` 判断当前缓冲区是否被 `narrow-to-region` 收缩过：是就说「Narrowed part of buffer」，否则说「Buffer」。示例第 3 节实测：

```
== 3) count-words--format：一次报四样 ==
Buffer has 2 lines, 2 sentences, 37 words, and 215 characters
```

文本是第一段样本文本再追加 `"\n第二段。\n"`：两行、两句、37 个词、215 个字符。

这里 `sentences` 用的 `count-sentences` 来自 `textmodes/paragraphs.el`，就是[上一章](31-forward-sentence.md)那群段落/句子函数的邻居：

```
(defun count-sentences (start end)
  "Count sentences in current buffer from START to END."
  (let ((sentences 0)
        (inhibit-field-text-motion t))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (let* ((prev (point))
               (next (forward-sentence)))
          (while (and (not (null next))
                      (not (= prev next)))
            (setq prev next
                  next (ignore-errors (forward-sentence))
                  sentences (1+ sentences))))
        ;; Remove last possibly empty sentence
        (when (/= (skip-chars-backward " \t\n") 0)
          (setq sentences (1- sentences)))
	sentences))))
```

它和你刚写的 `my-count-iter` **是同一个骨架**（三件套 + 从头遍历 + 累加），只是把 `forward-word` 换成了上一章的 `forward-sentence`。两个细节值得学：

- `ignore-errors` 包住 `(forward-sentence)`：上一章说过 `forward-sentence` 走到最后一个句尾会**报错**，`ignore-errors` 把错误吞掉、返回 `nil`，循环就自然结束了。**「能走就走、走不动就报错」的函数，在循环里就用 `ignore-errors` 兜底**。
- `(skip-chars-backward " \t\n")` 那一行：如果末尾只剩空白，说明最后切出来的是一个「空句子」，得把多算的 1 减掉。它顺便用返回值 `/= 0` 判断「是否有空白可跳」——`skip-chars-backward` 返回跳过的字符数。

**读到这里，本章的主题已经明确**：Emacs 的这一族计数命令，全是「三件套 + 某种推进函数 + 累加」的变体。`count-words` 推的是词，`count-sentences` 推的是句，`count-lines` 推的是行。

## 32.5 只数一个 defun 里的词

有了计数能力，就能做更有意思的事。eintr 第 14 章（Counting Words in a defun）的做法是：**先用 `beginning-of-defun` / `end-of-defun` 圈定范围，再数里面的词**。示例第 4 节：

```elisp
(defun my-count-words-in-defun ()
  "数「光标所在 defun」里的词数。"
  (save-excursion
    (let ((start (progn (beginning-of-defun) (point)))
          (end (progn (end-of-defun) (point))))
      (my-count-iter start end))))
```

`beginning-of-defun` 把 point 移到「当前 defun 的开头」，`end-of-defun` 移到它的结尾；`(progn … (point))` 用来「执行移动、然后返回移动后的位置」。**`progn` 按顺序求值一串表达式、返回最后一个的值**，是把「有副作用的动作」塞进需要「一个值」的地方时的常用小工具。拿到 `start` 和 `end` 后，直接丢给 `my-count-iter`。

```elisp
(with-temp-buffer
  (insert "(defun square (x)\n  \"Return X squared.\"\n  (* x x))\n")
  (goto-char (point-min))
  (princ (format "这个 defun 里有 %d 个词\n" (my-count-words-in-defun))))
```

```
== 4) 只数一个 defun 里的词 ==
这个 defun 里有 8 个词
```

这段 `(defun square (x) "Return X squared." (* x x))` 数出 **8** 个词：`defun`、`square`、`x`、`Return`、`X`、`squared`、`x`、`x`。注意字符串里的 `Return X squared` 也被按词切开了——因为 `forward-word` 不管「这在不在字符串里」，它只看字符是不是词构成字符。**想只数代码、不数字符串和注释，得靠 `syntax-ppss` 之类的语法分析，这是后面的高级话题**；eintr 此处只演示「圈范围 + 计数」这个组合本身。

## 32.6 从计数到词频：哈希表

「数出一个总数」只是热身。真正有用的是**每个词各出现几次**——词频统计。这需要一张「词 → 次数」的对照表，Emacs Lisp 里对这种「按字符串查值」的需求，标准答案是**哈希表**。[07 · 列表与关联结构](07-lists.md) 末尾把它和关联列表（alist）做过对比：少量数据用 alist 就够，数据多了要换哈希表，而这里正合适。

```elisp
(defun my-word-frequency (text)
  "返回 TEXT 里每个词的次数，按次数从多到少排成 alist。"
  (let ((table (make-hash-table :test 'equal)))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (re-search-forward "\\w+" nil t)
        (let ((word (downcase (match-string-no-properties 0))))
          (puthash word (1+ (gethash word table 0)) table))))
    ;; 把哈希表倒出来，再排序
    (let (pairs)
      (maphash (lambda (k v) (push (cons k v) pairs)) table)
      (sort pairs (lambda (a b)
                    (if (= (cdr a) (cdr b))
                        (string< (car a) (car b))   ; 次数相同按字母排，结果稳定
                      (> (cdr a) (cdr b))))))))
```

拆开看：

- `(make-hash-table :test 'equal)` —— 建表。`:test 'equal` 表示「键用 `equal` 比较」，因为键是**字符串**，必须用 `equal` 而不是默认的 `eq`（`eq` 比对象同一性，两个内容相同的字符串会判为不同）。
- `(while (re-search-forward "\\w+" nil t) …)` —— 就是我们前面的「一次正则版」循环。
- `(downcase (match-string-no-properties 0))` —— 取本次匹配到的词。`match-string-no-properties 0` 拿的是「第 0 组」，也就是整个匹配（`\\w+` 本身）；`downcase` 把 `The`、`THE`、`the` 统一成 `the`，否则它们会被当成不同的词。用 **no-properties** 版是为了去掉文本属性，得到干净的字符串。
- `(puthash word (1+ (gethash word table 0)) table)` —— 这是**「计数」惯用法**：`(gethash word table 0)` 读出当前的次数，**读不到时用默认值 `0`**（那个第三个参数 `0` 就是默认值），加一，再 `puthash` 写回去。一行搞定「在旧值上加一」，是所有计数场景的通用套路。
- 收集与排序：`maphash` 遍历哈希表，`(lambda (k v) (push (cons k v) pairs))` 把每对「键 . 值」做成一个 `(词 . 次数)`、推到 `pairs` 里。`maphash` 的**遍历顺序是不确定的**，所以必须自己排。
- `(sort pairs (lambda (a b) …))` 是**排序比较函数**：如果两个词次数相同（`(= (cdr a) (cdr b))`），就按 `string<` 比词本身（字母序），否则按次数从大到小（`(> (cdr a) (cdr b))`）。那句「次数相同按字母排」的注释很关键——**排序如果只按一个键，键相同的元素顺序是不稳定的**；补一个「次级比较键」，输出就**可复现**，示例验证时不会时好时坏。

配套一个打印函数：

```elisp
(defun my-print-freq (freq &optional limit)
  "打印词频 FREQ，最多打印 LIMIT 行。"
  (let ((n 0))
    (while (and freq (or (null limit) (< n limit)))
      (princ (format "  %-12s %d\n" (caar freq) (cdar freq)))
      (setq freq (cdr freq)
            n (1+ n)))))
```

它顺着 alist 一个 `cdr` 一个 `cdr` 地走，打印到 `limit` 行为止。`%-12s` 是「左对齐、宽度 12」的格式串，让数字列对齐。`(caar freq)` 是「第一个元素的 car」即词，`(cdar freq)` 是次数。第 5 节实测（前 6 名）：

```
== 5) 词频统计（前 6 名）==
  are          3
  that         3
  these        2
  all          1
  among        1
  and          1
  不同词数 = 31
```

`are`、`that` 各 3 次，`these` 2 次——正合样本文本里反复出现的 `that ... are`；`不同词数 = 31` 用 `(length (my-word-frequency my-text))` 得到，即不同的词有 31 个。

## 32.7 把它包成一个交互命令

最后一步：让上面这个「函数」变成**你能在编辑器里按 `M-x` 直接用的命令**。区别只在于 `(interactive …)` 声明和「对用户说什么」（[13 · 交互式命令](13-interactive.md)）。

```elisp
(defun my-word-frequency-buffer (&optional limit)
  "统计当前缓冲区（或激活的选区）里的词频，打印前 LIMIT 名。
交互调用时，用前缀参数指定要打印多少名。"
  (interactive "P")
  (let* ((limit (or limit 10))
         (freq (if (use-region-p)
                   (my-word-frequency
                    (buffer-substring-no-properties
                     (region-beginning) (region-end)))
                 (my-word-frequency
                  (buffer-substring-no-properties (point-min) (point-max))))))
    (with-temp-buffer
      (insert (format "词频（前 %d 名）：\n" limit))
      (let ((n 0))
        (while (and freq (< n limit))
          (insert (format "%4d  %s\n" (cdar freq) (caar freq)))
          (setq freq (cdr freq) n (1+ n))))
      (message "%s" (buffer-string)))))
```

读几个要点：

- `(interactive "P")` —— `P` 表示「前缀参数以原始 Lisp 形式传进来」（`C-u` 一下是 `(4)`，`C-u 20` 是 `(20)`）。因为函数形参 `limit` 是 `&optional`，不传就用 `(or limit 10)` 兜底成前 10 名。**用 `"P"` 而不是 `"p"`，是因为前缀参数可能不是数字**（`"p"` 会把 `C-u` 转成 `1`），原始形式更安全，取用时再判断。
- `(if (use-region-p) …)` —— 有激活选区就统计选区，否则统计整个缓冲区。`buffer-substring-no-properties` 把那段文字取成字符串，交给 `my-word-frequency`。**`use-region-p` 比 `(region-active-p)` 更准确**，它还会确认选区非空。
- 最后用 `with-temp-buffer` 把多条结果攒成一段文本，再 `(message "%s" (buffer-string))` 一次性显示。**为什么不用 `insert` 直接往用户缓冲区里塞**？因为交互命令不应该擅自改动用户的文档；`message` 只在回显区（echo area）显示，干净、无副作用。（想看长文本时，也可以用 `with-current-buffer` 把结果写进专门的输出缓冲区，那是后面的话题。）

示例第 6 节确认命令已就绪：

```
== 6) 交互命令也已定义 ==
命令 my-word-frequency-buffer 可用，文档：统计当前缓冲区（或激活的选区）里的词频，打印前 LIMIT 名。
交互调用时，用前缀参数指定要打印多少名。
```

`(documentation 'my-word-frequency-buffer t)` 取回它的 docstring——注意这里**也走了那一行 `interactive` 声明之外的「给人看」的信息**：docstring 里那句「交互调用时，用前缀参数指定要打印多少名」正是写给使用者看的。**命令的 docstring 是它的一部分，别偷懒。**

## 32.8 小结

| 零件 | 角色 | 一句话记忆 |
|---|---|---|
| `count-words` | 数词命令 | 交互时 `message` 报数，编程时**返回数字**；`called-interactively-p` 分野 |
| `forward-word-strictly` | 严格断词 | 屏蔽 `find-word-boundary-function-table`，让计数不受 mode 影响 |
| `save-excursion`/`save-restriction`/`narrow-to-region` | 区间遍历三件套 | 先缩范围、再从头遍历、最后自动复原 |
| 迭代 / 递归 / 正则 三解 | 同一个问题的三种写法 | 三个都该给同一个答案；用真实实现当夹具对照 |
| `count-words--format` | 一次报四样 | `count-lines`/`count-sentences`/`count-words` + `(- end start)`；`(if (= n 1) "" "s")` 处理复数 |
| `beginning-of-defun`/`end-of-defun` + `progn` | 圈定一个 defun | `progn` 执行一串动作、返回最后一个的值 |
| `make-hash-table`/`gethash`/`puthash` | 词频表 | `(puthash k (1+ (gethash k h 0)) h)` 是计数惯用法；默认值 `0` 在第三个参数 |
| `maphash` + `sort` | 导出并排序 | `maphash` 顺序不定，必须自己排；补次级比较键保证稳定 |

本章干的事，就是把前面所有零件组装成一个**真能用的工具**：从「读懂 `count-words`」，到「自己写三种计数算法互相对答案」，再到「哈希表算词频」，最后「包成 `M-x` 命令」。**这就是扩展 Emacs 的完整闭环**——读别人的代码学写法，写自己的代码解决问题，再把它变成日常可用的命令。

下一章换个角度：代码写好了**怎么查错**。我们将走进 Emacs 的调试工具——`debug-on-entry`、`edebug` 单步、以及在 `--batch` 下如何把错误现场抓出来。

上一章：[31 · 正则驱动的文本推进：forward-sentence 与 forward-paragraph](31-forward-sentence.md)　｜　下一章：[33 · 调试：debug-on-entry、edebug 与 batch 下的排查](33-debugging.md)　｜　返回：[Emacs 扩展开发指南](README.md)
