# 30 · kill ring：剪切与粘贴的实现

> 所属部分：第 8 部分 · 跟随 eintr：读懂真实代码

> 示例：`examples/30-kill-ring.el`

你每天按的 `C-w`（`kill-region`）、`M-w`（`kill-ring-save`）、`C-y`（`yank`）、`M-y`（`yank-pop`），背后是同一个数据结构——**kill ring（剪切环）**。eintr 用整个附录 B 讲它，因为它是「一个真实功能如何用 Lisp 实现」的最好样本：不复杂，但每个零件都有存在的理由。

这一章把环拆开看：它的两个变量、进环的两条路、出环的一种方式，全部是 Emacs 31.1 的真实源码。

## 30.1 kill ring 其实是两个变量

别被「ring（环）」这个词骗了。它**不是**环形数据结构，就是一个普通的字符串列表，外加一个指针：

| 变量 | 是什么 |
|---|---|
| `kill-ring` | 一个字符串列表，`(car kill-ring)` 是**最新**的一次剪切 |
| `kill-ring-yank-pointer` | 一个「列表尾」指针（`cdr` 链上的某个位置），指向下次 `yank` 会取的那个元素 |

因为 Emacs 的列表是 cons 链，所以「指向列表中的第 k 个元素」只要存**那个位置开始的整条子链**就够了——子链头就是第 k 个元素。这就是为什么指针变量的值是「一条列表」，而不是一个数字下标。

「环」体现在 `current-kill` 的取模算法上：指针往后走，走到底就绕回开头（30.5 会看到）。

## 30.2 最短的剪切命令：`zap-to-char`

先看一个最简的「剪切命令」。`M-z` 绑定的 `zap-to-char`：杀掉「从这里到某个字符（含该字符）」的文本。下面是示例运行时抓出来的 31.1 真实源码（即示例的 stdout）：

```
(defun zap-to-char (arg char &optional interactive)
  "Kill up to and including ARGth occurrence of CHAR.
When run interactively, the argument INTERACTIVE is non-nil.
Case is ignored if `case-fold-search' is non-nil in the current buffer.
Goes backward if ARG is negative; error if CHAR not found.
See also `zap-up-to-char'.
If called interactively, do a case sensitive search if CHAR
is an upper-case character."
  (interactive (list (prefix-numeric-value current-prefix-arg)
		     (read-char-from-minibuffer "Zap to char: "
						nil 'read-char-history)
               t))
  ;; Avoid "obsolete" warnings for translation-table-for-input.
  (with-no-warnings
    (if (char-table-p translation-table-for-input)
	(setq char (or (aref translation-table-for-input char) char))))
  (let ((case-fold-search (if (and interactive (char-uppercase-p char))
                              nil
                            case-fold-search)))
    (kill-region (point) (search-forward (char-to-string char) nil nil arg))))
```

核心只有最后一行：

```
    (kill-region (point) (search-forward (char-to-string char) nil nil arg))))
```

`search-forward` 把 point 移到「该字符之后」，**并返回那个位置**；于是 `kill-region` 拿到的区间就是 `(point) → (找到的位置)`，正好含目标字符。**一条命令干了两件事：搜索 + 剪切**。这是 Emacs 命令里非常常见的组合——用会移动 point 的函数当「定位器」。

`search-forward` 的参数含义：`(search-forward STRING BOUND NOERROR COUNT)`。这里 `BOUND` 和 `NOERROR` 都是 `nil`，意思是「不设边界、找不到就报错」；`COUNT` 是 `arg`，即「找第 arg 个」。

## 30.3 真正的剪切：`kill-region`

`zap-to-char` 把活交给了 `kill-region`。这是 31.1 的真实源码（示例 stdout 原文，**文档字符串太长，这里略去**，正文中逐句解释）：

```
(defun kill-region (beg end &optional region)
  ;; Pass mark first, then point, because the order matters when
  ;; calling `kill-append'.
  (interactive (progn
                 (let ((beg (mark kill-region-dwim))
                       (end (point)))
                   (cond
                    ((and kill-region-dwim (not (use-region-p)))
                     (list beg end kill-region-dwim))
                    ((not (and beg end))
                     (user-error "The mark is not set now, so there is no region"))
                    ((list beg end 'region))))))

  (condition-case nil
      (let ((string (cond
                     ((memq region '(unix-word emacs-word))
                      (let ((end (point)))
                        (save-excursion
                          (if (eq region 'emacs-word)
                              (forward-word -1)
                            (forward-unix-word -1))
                          (filter-buffer-substring (point) end 'delete))))
                     (region
                      (funcall region-extract-function 'delete))
                     ((filter-buffer-substring beg end 'delete)))))
	(when string			;STRING is nil if BEG = END
	  ;; Add that string to the kill ring, one way or another.
	  (if (and (not (memq region '(unix-word emacs-word)))
		   (eq last-command 'kill-region))
	      (kill-append string (< end beg))
	    (kill-new string)))
	(when (and (not (memq region '(unix-word emacs-word)))
		   (or string (eq last-command 'kill-region)))
	  (setq this-command 'kill-region))
	(setq deactivate-mark t)
	nil)
    ((buffer-read-only text-read-only)
     ;; The code above failed because the buffer, or some of the characters
     ;; in the region, are read-only.
     (copy-region-as-kill beg end region)
     (setq this-command 'kill-region)
     (if kill-read-only-ok
	 (progn (message "Read only text copied to kill ring") nil)
       (barf-if-buffer-read-only)
       (signal 'text-read-only (list (current-buffer)))))))
```

分四块读：

**(1) `interactive` 里的 `progn` + `cond`** —— 交互调用时决定参数。注意那句 `(mark kill-region-dwim)`：这是**极具 Emacs 特色的技巧**。`mark` 是一个函数，但这里写成了 `(mark kill-region-dwim)`，看起来像传参、其实是「调用 `mark` 并把 `kill-region-dwim` 当作 NO-FORCE 参数」——也就是当 `kill-region-dwim` 为 `nil` 时**不强制**返回标记，没有标记就返回 `nil`。然后用 `cond` 判断：没有标记（`beg` 为 `nil`）就直接 `user-error` 报「没有选区」。

**(2) 取文本** —— `cond` 的三条分支对应三种来源：

| 分支 | 场景 | 动作 |
|---|---|---|
| `region` 是 `'unix-word` / `'emacs-word` | 杀词模式（`M-d` / `M-DEL` 走 `kill-word`） | 向后移动一个词，再取区间 |
| `region` 非 nil | 交互式调用（总是有选区） | `(funcall region-extract-function 'delete)` |
| 都不满足 | 程序调用，传了 `beg` `end` | `(filter-buffer-substring beg end 'delete)` |

关键是第三个参数 `'delete`。`filter-buffer-substring` 平时只**返回**一段文本（给 `M-w` 用，不改缓冲区）；传 `'delete` 就表示「顺便从缓冲区里删掉」。**同一个函数，靠一个参数区分「复制」和「剪切」**——这是它被两个命令共用的原因。

**(3) 进环** —— `(when string …)`。`string` 为 `nil` 表示 `beg = end`（空区间），此时什么都不做。否则：

```
	  (if (and (not (memq region '(unix-word emacs-word)))
		   (eq last-command 'kill-region))
	      (kill-append string (< end beg))
	    (kill-new string)))
```

- 如果**上一条命令也是 `kill-region`**（连续按 `C-w`），就调用 `kill-append` 把新文本**并到环头那一条**上；
- 否则调用 `kill-new`，作为**新的一条**压进环。

`(< end beg)` 这个参数告诉 `kill-append`：「这次剪的文本位置在上一次**之前**，所以要拼在前面而不是后面」。这就是为什么「从后往前连续剪」拼出来的顺序依然正确。

**(4) `(setq this-command 'kill-region)` 与 `(setq deactivate-mark t)`** —— 前者让**下一次**调用能走到 `kill-append` 分支（因为下一轮 `last-command` 就变成 `kill-region` 了）；后者在命令循环结束后取消选区高亮。

**最后那个 `condition-case`** 是兜底：如果缓冲区（或区间里的字符）是只读的，上面的 `'delete` 会失败。它接住 `buffer-read-only` / `text-read-only` 两种错误，然后**改走 `copy-region-as-kill`**——只复制不删除。所以「在只读缓冲区里按 `C-w` 也能把文本存进环」正是这段代码给的。

## 30.4 入环的两条路：`kill-new` 与 `kill-append`

`kill-new` 负责「把一条新文本放进环的最前面」。下面是示例抓出来的真实源码，其中「与系统剪贴板同步」那一大段（`save-interprogram-paste-before-kill`）为了可读性略去，正文里单独讲：

```
(defun kill-new (string &optional replace)
  ;; Allow the user to transform or ignore the string.
  (when (or (not kill-transform-function)
            (setq string (funcall kill-transform-function string)))
    (unless (and kill-do-not-save-duplicates
	         ;; Due to text properties such as 'yank-handler that
	         ;; can alter the contents to yank, comparison using
	         ;; `equal' is unsafe.
	         (equal-including-properties string (car kill-ring)))
      (if (fboundp 'menu-bar-update-yank-menu)
	  (menu-bar-update-yank-menu string (and replace (car kill-ring)))))
    (unless (and kill-do-not-save-duplicates
	         (equal-including-properties string (car kill-ring)))
      (if (and replace kill-ring)
	  (setcar kill-ring string)
        (let ((history-delete-duplicates nil))
          (add-to-history 'kill-ring string kill-ring-max t))))
    (setq kill-ring-yank-pointer kill-ring)
    (if interprogram-cut-function
        (funcall interprogram-cut-function string))))
```

被略去的那一段长这样（同样摘自真实源码），它就是「剪之前先把系统剪贴板里的内容存进环」：

```
    (when save-interprogram-paste-before-kill
      (let ((interprogram-paste
             (and interprogram-paste-function
                  ;; On X, the selection owner might be slow, so the user might
                  ;; interrupt this. If they interrupt it, we want to continue
                  ;; so we become selection owner, so this doesn't stay slow.
                  (if (eq (window-system) 'x)
                      (ignore-error quit (funcall interprogram-paste-function))
                    (funcall interprogram-paste-function)))))
        (when interprogram-paste
          (setq interprogram-paste
                (if (listp interprogram-paste)
                    ;; Use `reverse' to avoid modifying external data.
                    (reverse interprogram-paste)
		  (list interprogram-paste)))
          (when (or (not (numberp save-interprogram-paste-before-kill))
                    (< (seq-reduce #'+ (mapcar #'length interprogram-paste) 0)
                       save-interprogram-paste-before-kill))
            (dolist (s interprogram-paste)
	      (unless (and kill-do-not-save-duplicates
                           (equal-including-properties s (car kill-ring)))
	        (push s kill-ring)))))))
```

三行是重点：

- **`(if (and replace kill-ring) (setcar kill-ring string) …)`** —— 如果 `replace` 为真且环非空，就**直接改环头那个 cons 的 `car`**（相当于「覆盖最新一条」）；否则走 `add-to-history`，把 `string` 压到列表最前面。
- **`(add-to-history 'kill-ring string kill-ring-max t)`** —— 这才是真正「push 进列表」的动作。`kill-ring-max`（默认 60）是环的容量，超过了就丢掉最老的；最后一个 `t` 表示「保留重复项」（`history-delete-duplicates` 被临时置 `nil`，所以环里允许出现相同的文本）。用 `add-to-history` 而不是简单的 `push`，是为了复用历史变量那套容量管理逻辑。
- **`(setq kill-ring-yank-pointer kill-ring)`** —— 每次入环，指针**重新指回环头**。道理很直观：刚剪完，接下来 `yank` 应该取出刚剪的那条。
- **`(if interprogram-cut-function (funcall interprogram-cut-function string))`** —— 这就是「Emacs 的 kill ring 和系统剪贴板同步」的挂载点。图形环境下它是一个 X/GTK 提供的函数，把文本塞进系统剪贴板；`--batch` 下它是 `nil`，所以示例里不会碰剪贴板。

`kill-append` 更短——它只是「把新文本拼到环头那一条上，再调用 `kill-new`」：

```
(defun kill-append (string before-p)
  (let ((cur (car kill-ring)))
    (kill-new (if before-p (concat string cur) (concat cur string))
              (or (= (length cur) 0)
                  (null (get-text-property 0 'yank-handler cur)))))
  (when (and kill-append-merge-undo (not buffer-read-only))
    (let ((prev buffer-undo-list)
          (next (cdr buffer-undo-list)))
      ;; Find the next undo boundary.
      (while (car next)
        (pop next)
        (pop prev))
      ;; Remove this undo boundary.
      (when prev
        (setcdr prev (cdr next))))))
```

（文档字符串略去；末尾那一段就是「把两次剪切的 undo 边界合并成一次」。）

- **`(concat cur string)` 或 `(concat string cur)`** —— 由 `before-p` 决定拼在前还是拼在后；
- **第二个参数 `replace`** —— 一般传 `t`，于是 `kill-new` 里走 `setcar` 分支，**替换**环头而不是新增一条。所以「连续剪三次」在环里只占**一条**，内容是三段的拼接——这正是你按 `C-w C-w C-w` 后 `C-y` 能一次粘出全部的原因；
- 末尾那段是 `undo` 的细节：把几次剪切之间的 undo 边界抹掉，于是 `C-/` 一次就能撤销掉整串剪切。这是「同一个操作被拆成多次命令，但用户眼里是一次」时该做的事。

## 30.5 `current-kill`：相对旋转，不是绝对下标

出环靠 `current-kill`。这是全章最精妙的一段：

```
(defun current-kill (n &optional do-not-move)
  (let ((interprogram-paste (and (= n 0)
				 interprogram-paste-function
				 (funcall interprogram-paste-function))))
    (if interprogram-paste
	(progn
	  ;; Disable the interprogram cut function when we add the new
	  ;; text to the kill ring, so Emacs doesn't try to own the
	  ;; selection, with identical text.
          ;; Also disable the interprogram paste function, so that
          ;; `kill-new' doesn't call it repeatedly.
          (let ((interprogram-cut-function nil)
                (interprogram-paste-function nil))
	    (if (listp interprogram-paste)
                ;; Use `reverse' to avoid modifying external data.
                (mapc #'kill-new (reverse interprogram-paste))
	      (kill-new interprogram-paste)))
	  (car kill-ring))
      (or kill-ring (error "Kill ring is empty"))
      (let ((ARGth-kill-element
	     (nthcdr (mod (- n (length kill-ring-yank-pointer))
			  (length kill-ring))
		     kill-ring)))
	(unless do-not-move
	  (setq kill-ring-yank-pointer ARGth-kill-element)
	  (when (and yank-pop-change-selection
		     (> n 0)
		     interprogram-cut-function)
	    (funcall interprogram-cut-function (car ARGth-kill-element))))
	(car ARGth-kill-element)))))
```

（文档字符串略去。）先看「正常路径」（`interprogram-paste` 为 `nil` 时）：

```
      (or kill-ring (error "Kill ring is empty"))
      (let ((ARGth-kill-element
	     (nthcdr (mod (- n (length kill-ring-yank-pointer))
			  (length kill-ring))
		     kill-ring)))
	(car ARGth-kill-element)))))
```

下标的算法（这是**公式**，不是程序输出；对应的真实代码是上面那段里的
`(nthcdr (mod (- n (length kill-ring-yank-pointer)) (length kill-ring)) kill-ring)`）：

```text
目标下标 = (n - 当前指针长度) mod (环长度)
```

**注意这里的 `n` 是「相对步数」，不是绝对下标。** `current-kill 1` 的意思是「从指针现在的位置往前走 1 步」，而不是「取环里第 1 个」。所以：

- 指针在头（长度 = 环长），`n = 0` → `(0 - 3) mod 3 = 0` → 取第 0 个（最新）；
- 指针在头，`n = 1` → `(1 - 3) mod 3 = 1` → 取第 1 个；
- 指针已在第 1 个（长度 = 2），再来 `n = 1` → `(1 - 2) mod 3 = 2` → 取第 2 个；
- 指针已在第 2 个（长度 = 1），再来 `n = 1` → `(1 - 1) mod 3 = 0` → **绕回第 0 个**。

最后一步就是「环」的全部含义：**取模让指针走到底能绕回开头**。而且因为每次计算都用「当前指针长度」做基准，做到的是「相对移动」——这正是 `M-y` 能一次一次往后翻、翻到头又回到最新的原因。

两个附带条件：

- **`(unless do-not-move …)`** —— 默认会**移动指针**（所以叫 `current-kill` 而不是 `get-kill`）；传第三参数 `t` 就只读不移动；
- **开头那段 `interprogram-paste`** —— 只有当 `n = 0`（即「取最新一条」）时，才去问系统剪贴板有没有新内容。有的话先 `kill-new` 塞进环，再返回。这就是「在别的程序里复制，回到 Emacs 按 `C-y` 能粘出来」的实现——**不是每次 yank 都去读剪贴板，只在「取最新一条」时才读**。

## 30.6 出环：`yank`

`yank` 把 `current-kill` 返回的字符串插进缓冲区：

```
(defun yank (&optional arg)
  (interactive "*P")
  (setq yank-window-start (window-start))
  ;; If we don't get all the way thru, make last-command indicate that
  ;; for the following command.
  (setq this-command t)
  (push-mark)
  (insert-for-yank (current-kill (cond
				  ((listp arg) 0)
				  ((eq arg '-) -2)
				  (t (1- arg)))))
  (if (consp arg)
      ;; This is like exchange-point-and-mark, but doesn't activate the mark.
      ;; It is cleaner to avoid activation, even though the command
      ;; loop would deactivate the mark because we inserted text.
      (goto-char (prog1 (mark t)
		   (set-marker (mark-marker) (point) (current-buffer)))))
  ;; If we do get all the way thru, make this-command indicate that.
  (if (eq this-command t)
      (setq this-command 'yank))
  nil)
```

（`yank` 的文档字符串有 40 多行，讲的全是 `yank-handler` 文本属性的细节，这里略去。）

逐句：

- **`(interactive "*P")`** —— 开头的 `*` 表示「缓冲区只读时报错」；`P` 是原始前缀（同第 29 章的 `beginning-of-buffer`）；
- **`(push-mark)`** —— 在插入点之前压一个标记。所以粘完之后 point 在末尾、mark 在开头，`C-x C-x` 能跳回粘贴起点；
- **`(insert-for-yank (current-kill …))`** —— 核心。`insert-for-yank` 是 `insert` 的增强版，会处理文本属性（`yank-handler`、`yank-excluded-properties` 等），让「带属性的文本」（比如从代码块里复制的缩进、从 magit 复制的 diff 高亮）粘进来时不乱套；
- **`(cond ((listp arg) 0) …)`** —— 这里藏着一个易忽略的知识点：`(listp nil)` 为 **`t`**。所以 `C-y` 不带前缀时 `arg = nil`，走 `0`（取最新一条）；带 `C-u` 时 `arg = (4)`，也是 `0`，但后面那个 `(if (consp arg) …)` 会把 point 和 mark 对调（`C-u C-y` 的效果：粘完后 point 在开头）；
- **数字前缀 `N`** —— `(1- arg)`：`M-y` 的「相对「往前 N-1 步」」由此而来（`current-kill` 的下标从 0 起算）；
- **`(setq this-command t)` … `(if (eq this-command t) (setq this-command 'yank))`** —— 一个「中途失败也要留痕」的技巧：先把 `this-command` 设成一个「非法但非 `nil`」的值 `t`；如果正常走到底就改成 `'yank`。万一中途出错，`this-command` 仍是 `t`，命令循环会因此**不把它当作成功的命令**——`last-command` 也就不会被错误地更新。

`yank-pop`（`M-y`）的做法正好相反：它**先删掉刚粘的那一段**，再插入 `current-kill 1` 取到的新文本，如此反复就能在环里「翻页」：

```
(defun yank-pop (&optional arg)
  (interactive "p")
  (if (not (eq last-command 'yank))
      (yank-from-kill-ring (read-from-kill-ring "Yank from kill-ring: ")
                           current-prefix-arg)
    (setq this-command 'yank)
    (unless arg (setq arg 1))
    (let ((inhibit-read-only t)
          (before (< (point) (mark t))))
      (if before
          (funcall (or yank-undo-function 'delete-region) (point) (mark t))
        (funcall (or yank-undo-function 'delete-region) (mark t) (point)))
      (setq yank-undo-function nil)
      (set-marker (mark-marker) (point) (current-buffer))
      (insert-for-yank (current-kill arg))
      ;; Set the window start back where it was in the yank command,
      ;; if possible.
      (set-window-start (selected-window) yank-window-start t)
      (if before
          ;; This is like exchange-point-and-mark, but doesn't activate the mark.
          ;; It is cleaner to avoid activation, even though the command
          ;; loop would deactivate the mark because we inserted text.
          (goto-char (prog1 (mark t)
                       (set-marker (mark-marker) (point) (current-buffer))))))
    nil))
```

要点：

- **`(if (not (eq last-command 'yank)) …)`** —— 如果上一条命令不是 `yank`，`M-y` 不是「换掉刚粘的」，而是弹出**补全界面**让你从环里挑（`yank-from-kill-ring` + `read-from-kill-ring`，即 31.x 的 `M-y` 新行为）；
- **`(let ((before (< (point) (mark t)))) …)`** —— 记住「粘贴区间是正序还是逆序」，删完了好把 point 放回原侧；
- **`(funcall (or yank-undo-function 'delete-region) …)`** —— 默认用 `delete-region` 删掉上次粘的；如果文本带 `yank-handler` 且指定了自定义撤销函数，就用它；
- **`(insert-for-yank (current-kill arg))`** —— `arg` 默认为 1，于是相对前移一步，取到上一次的剪切。

## 30.7 亲手把 kill ring 转一遍

现在不看源码，自己转一遍。示例先把 `kill-ring` 存起来，最后还回去，中间随便折腾：

```elisp
(defun my-yank-pos ()
  "返回 kill-ring-yank-pointer 相对于 kill-ring 头的偏移（0 = 最新）。"
  (- (length kill-ring) (length kill-ring-yank-pointer)))

(let ((saved kill-ring)
      (saved-ptr kill-ring-yank-pointer))
  ;; … 下面几节都在这个 let 里 …
  (setq kill-ring saved kill-ring-yank-pointer saved-ptr))
```

### 两次剪切 → 环里两条

```elisp
(setq kill-ring nil kill-ring-yank-pointer nil last-command nil)
(dolist (word '("alpha" "beta"))
  (with-temp-buffer
    (insert word)
    (kill-region (point-min) (point-max))))
(princ (format "剪了 alpha、beta 之后：%S\n" kill-ring))
(princ (format "指针指向第 %S 个（0 = 最新）\n" (my-yank-pos)))
```

输出：

```
剪了 alpha、beta 之后：("beta" "alpha")
指针指向第 0 个（0 = 最新）
```

新的在前、旧的在后，指针回到头部——和 30.4 说的完全一致。注意这里**不能**把 `last-command` 留成 `kill-region`，否则第二次会走 `kill-append` 合并；示例特意先 `(setq last-command nil)`，让两次都走「新增一条」。

### `kill-append` 会改环头那一条

```elisp
(kill-append "gamma" nil)
(princ (format "kill-append \"gamma\"（接在后面）：%S\n" kill-ring))
(kill-append "pre-" t)
(princ (format "kill-append \"pre-\"（接在前面）  ：%S\n" kill-ring))
```

输出：

```
kill-append "gamma"（接在后面）：("betagamma" "alpha")
kill-append "pre-"（接在前面）  ：("pre-betagamma" "alpha")
```

看到关键了吗：环里**始终只有两条**。`kill-append` 没有新增条目，而是把 `"beta"` 原地改成了 `"betagamma"`，再改成 `"pre-betagamma"`——这正是 `kill-new` 的 `replace` 分支 `(setcar kill-ring string)` 在起作用。

### `current-kill` 的相对语义与绕回

```elisp
(setq kill-ring '("a" "b" "c") kill-ring-yank-pointer kill-ring)
(dolist (n '(0 1 1 1))
  (let ((got (current-kill n)))
    (princ (format "current-kill %S -> %S（指针现在在第 %S 个）\n"
                   n got (my-yank-pos)))))
```

输出：

```
current-kill 0 -> "a"（指针现在在第 0 个）
current-kill 1 -> "b"（指针现在在第 1 个）
current-kill 1 -> "c"（指针现在在第 2 个）
current-kill 1 -> "a"（指针现在在第 0 个）
```

四步走完一圈回到起点。注意每一步的 `n` 都是 `1`（除了第一步的 `0`），但取到的元素却在变化——**因为 `n` 是相对步数，基准是「指针现在在哪」**。这就是 `M-y M-y M-y …` 能一路往前翻、翻到头又回到最新的原因。

### `zap-to-char`：一条命令封装的搜索 + 剪切

```elisp
(with-temp-buffer
  (insert "one two three")
  (goto-char (point-min))
  (zap-to-char 1 ?\s)
  (princ (format "缓冲区剩下 = %S\n" (buffer-string)))
  (princ (format "环头是        = %S\n" (car kill-ring))))
```

输出：

```
缓冲区剩下 = "two three"
环头是        = "one "
```

`"one "` 连同后面的空格一起被剪掉，留在缓冲区里的是 `"two three"`——和 30.2 里那行 `(kill-region (point) (search-forward …))` 的说法对上了。

### 取回来：手写 `yank` 的核心 + 真调用 `yank`

```elisp
(setq kill-ring '("hello" "world") kill-ring-yank-pointer kill-ring)
;; 手写一遍 yank 的核心动作
(with-temp-buffer
  (insert "→ ")
  (insert-for-yank (current-kill 0))
  (princ (format "手写核心：[%S]\n" (buffer-string))))
;; 再真的调用一次 yank（push-mark 的 "Mark set" 用 inhibit-message 静音）
(with-temp-buffer
  (let ((inhibit-message t))
    (yank)
    (princ (format "调用 yank：文本 = %S，point = %S，mark = %S\n"
                   (buffer-string) (point) (mark t)))))
```

输出：

```
手写核心：["→ hello"]
调用 yank：文本 = "hello"，point = 6，mark = 1
```

`yank` 跑完 `point = 6`（在末尾）、`mark = 1`（在开头）——正是 30.6 里那句 `(push-mark)` 的效果。

> 【坑】`(let ((inhibit-message t)) …)` 又出现了：`yank` 里的 `push-mark` 会打印 `Mark set`。而 `message` 走 **stderr**，不静音就会破坏「运行 stderr 为空」的标准。写这类「调用真实命令」的示例时要留意它们偷偷发出的消息。

## 30.8 小结

| 零件 | 作用 | 一句话记忆 |
|---|---|---|
| `kill-ring` | 字符串列表 | `car` 是最新一条 |
| `kill-ring-yank-pointer` | 一条子链 | 「指针指向第 k 个」= 存「从第 k 个开始的子链」 |
| `kill-region` | 删文本 + 入环 | 用 `filter-buffer-substring … 'delete` 一步完成「取 + 删」 |
| `kill-new` | 新增/覆盖环头 | `replace` 为真则 `setcar`，否则 `add-to-history` |
| `kill-append` | 并到环头 | 靠 `concat` + `kill-new` 的 `replace`，环里不新增条目 |
| `current-kill` | 取并相对移动指针 | `nthcdr (mod (- n 指针长) 环长)`，取模实现「绕回」 |
| `yank` | 取出并插入 | `insert-for-yank (current-kill …)`；`(listp nil)` = `t` 是关键 |
| `yank-pop` | 先删后插 | 依赖 `yank-window-start`、`yank-undo-function` |

下一章读的是另一类函数：**用正则一步步推进 point** 的 `forward-sentence` 和 `forward-paragraph`。它们展示了「把自然语言的段落结构翻译成正则」的做法。

上一章：[29 · 读懂真实函数：三个 buffer 命令的走查](29-read-source.md)　｜　下一章：[31 · 正则驱动的文本推进：forward-sentence 与 forward-paragraph](31-forward-sentence.md)　｜　返回：[Emacs 扩展开发指南](README.md)
