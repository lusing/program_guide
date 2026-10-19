# 10 · buffer 与 point

> 所属部分：第 2 部分 · 编辑器数据结构
>
> **本部分导读**：到这里语言部分讲完了。接下来是 Emacs 的三个核心对象——**buffer**、**文本属性/overlay**、**文件**。写扩展和写普通 Lisp 程序最大的分界就在这儿：这些对象有状态、有生命周期、有「当前」的概念（`current-buffer`、`current-local-map`……），必须理解透彻。
>
> 示例：`examples/10-buffers.el`

## 10.1 buffer 是一等公民

**Emacs 里文本不是「在文件里」，而是在 buffer 里**。文件只是 buffer 的一个可选关联（第 12 章）。这个观念转换很重要——扩展操作的对象，绝大多数是 buffer。

```elisp
(princ (format "当前 buffer: %S，所有 buffer 数: %S\n"
               (buffer-name) (length (buffer-list))))
```

```
当前 buffer: "*scratch*"，所有 buffer 数: 4
```

每个 buffer 有名字（`*scratch*`、`*Messages*` 这种带星号的是内部 buffer）、有自己的文本、有自己的局部变量、有自己的 point。`buffer-list` 给出所有活着的 buffer。

**`with-temp-buffer` 是扩展里最常用的宏**：造一个临时 buffer，在里面设为当前 buffer，退出时自动 kill、自动恢复原来的当前 buffer：

```elisp
(with-temp-buffer
  (insert "第一行\n第二行\n第三行\n")
  (princ (format "bufname=%S 内容=%S\n" (buffer-name) (buffer-string))))
```

```
bufname=" *temp*" 内容="第一行
第二行
第三行
"
```

它保证：不污染用户正在编辑的 buffer、退出自动清理、可以嵌套。本仓库后面几乎所有操作 buffer 的示例都靠它。

## 10.2 point：位置是一个 1 开始的整数

point（光标位置）在 Elisp 里就是一个**从 1 开始**的整数：

```elisp
(with-temp-buffer
  (insert "abcdef")
  (princ (format "插入后 point = %S（停在新文本之后）\n" (point)))
  (goto-char (point-min))
  (princ (format "point-min = %S, point-max = %S, bobp = %S\n"
                 (point) (point-max) (bobp)))
  (goto-char (point-max))
  (princ (format "到末尾: point = %S, eobp = %S\n" (point) (eobp))))
```

```
插入后 point = 7（停在新文本之后）
point-min = 1, point-max = 7, bobp = t
到末尾: point = 7, eobp = t
```

三个事实：

- **point 从 1 开始**（不是 0）。`(point-min)` 通常是 1，`(point-max)` 是 `(buffer-size) + 1`；
- **插入文本后，point 停在新插入内容之后**；
- `bobp` / `eobp` 判断「在开头 / 在结尾」。

「位置」和「字符」的区别要记牢：`point-max` 是个**合法位置**，但那里**没有字符**（它是末尾之后）。所以 `(char-after (point-max))` 是 `nil`，而 `(char-after 1)` 是第一个字符的码位。

## 10.3 移动

```elisp
(with-temp-buffer
  (insert "aaa\nbbb\nccc")
  (goto-char (point-min))
  (forward-line 1)
  (princ (format "下移一行后 point = %S，当前行 = %S\n"
                 (point) (buffer-substring-no-properties
                          (line-beginning-position) (line-end-position)))))
```

```
下移一行后 point = 5，当前行 = "bbb"
```

常用移动函数：

```elisp
(with-temp-buffer
  (insert "aaa\nbbb\nccc")
  (goto-char (point-min))
  (forward-line 1)
  (princ (format "下移一行后 point = %S，当前行 = %S\n"
                 (point) (buffer-substring-no-properties
                          (line-beginning-position) (line-end-position)))))
```

```
下移一行后 point = 5，当前行 = "bbb"
```

- `goto-char` 绝对位置（**1 开始**）；`forward-char` / `forward-line` 相对移动；
- 越界时 `forward-char` 报错，`forward-line` 到文件尾返回 `nil`；
- `line-beginning-position` / `line-end-position` 拿当前行的起止。

`forward-line` 的返回值是「**还剩几行没移动**」——0 表示成功走完了，非 0 表示提前撞到 buffer 边界。判「有没有真的移动成功」靠这个返回值，比事后查位置可靠。

## 10.4 取内容

```elisp
(with-temp-buffer
  (insert "hello world")
  (princ (format "buffer-substring 1..6 = %S\n"
                 (buffer-substring-no-properties 1 6))))
```

```
buffer-substring 1..6 = "hello"
```

- `buffer-string` 拿整个 buffer 的内容；
- `buffer-substring start end` 拿区间 `[start, end)`；
- **强烈建议用 `-no-properties` 版本**。带文本属性的字符串在 `equal` 比较、写文件、插到别处时行为都和直觉不一样（第 11 章专门讲）。只有确实要保留属性时才用带属性的版本。

## 10.5 查找替换

关键点：`re-search-forward` **把 point 移到匹配的末尾**；`replace-match` 替换的正是「刚刚那次匹配」的文本（和第 8 章一样，依赖全局 match data）。所以两者天然配对。要拿匹配位置，用 `(match-beginning 0)` / `(match-end 0)`。

### 【坑】replace-match 默认适配大小写

```elisp
(with-temp-buffer
  (insert "keep-THIS-keep")
  (goto-char (point-min))
  (re-search-forward "THIS")
  (replace-match "that")
  (princ (format "replace-match 后: %S\n" (buffer-string))))
(with-temp-buffer
  (insert "keep-This-keep")
  (goto-char (point-min))
  (re-search-forward "This")
  (replace-match "that" t t)
  (princ (format "关掉大小写适配: %S\n" (buffer-string))))
```

```
replace-match 后: "keep-THAT-keep"
关掉大小写适配: "keep-that-keep"
```

注意第一行：原文是 `THIS`（全大写），替换串 `that`（全小写），结果却是 `THAT`——`replace-match` **默认会把全小写的替换串改成匹配原文的大小写**。写替换时如果原文大小写不确定，这个「智能」行为会给出意外结果。关掉它：传第 4 个参数 `t`（LITERAL，替换串完全按字面处理，顺带也关掉了 `\&` 之类的特殊语法）。

搜索函数一览：

| 函数 | 行为 |
|---|---|
| `search-forward` | 找字面字符串，point 停在匹配末尾 |
| `re-search-forward` | 找正则，point 停在匹配末尾 |
| `re-search-backward` | 往回找，point 停在匹配**开头** |
| `looking-at` | 从**当前位置**试匹配，**不移动** point |
| `looking-back` | 判断当前位置之前是否匹配（性能不如自己存位置） |

`replace-match` 的坑：替换字符串里 `\&`（整个匹配）和 `\N`（第 N 个捕获组）有特殊含义，字面反斜杠要写 `\\\\`。安全做法是用第 4 个参数 `LITERAL`：

```elisp
(with-temp-buffer
  (insert "keep-This-keep")
  (goto-char (point-min))
  (re-search-forward "This")
  (replace-match "that" t t)
  (princ (format "关掉大小写适配: %S\n" (buffer-string))))
```

```
关掉大小写适配: "keep-that-keep"
```

第 3 个参数 `FIXEDCASE`、第 4 个 `LITERAL`、第 5 个 `SUBEXP` —— 记不住顺序没关系，
记住「**替换串不想被当正则、也不想被改大小写，就传 `t t`**」这一条就够用了。

### 【坑】只读 buffer

buffer 可能是只读的（`*Messages*`、Dired、很多模式的输出 buffer 都是）。直接 `insert` 会报 `buffer-read-only` 错误。标准做法是**动态绑定** `inhibit-read-only`——这正是第 3 章「special 变量」的经典用途：

```elisp
(with-temp-buffer
  (insert "readonly-content")
  (setq buffer-read-only t)
  (let ((inhibit-read-only t))
    (goto-char (point-max))
    (insert " + forced"))
  (princ (format "只读 buffer 里强制插入: %S\n" (buffer-string))))
```

```
只读 buffer 里强制插入: "readonly-content + forced"
```

`let` 临时把 `inhibit-read-only` 绑成 `t`，退出自动还原——不记得手工恢复，也不会忘记。

## 10.6 【核心】save-excursion

写扩展时**最常用的宏**。「我要跳到别处做点事，然后让用户的光标回来」：

```elisp
(with-temp-buffer
  (insert "one two three")
  (goto-char 5)
  (save-excursion
    (goto-char (point-min))
    (insert ">> "))
  (princ (format "save-excursion 之后 point 还原到 %S，内容=%S\n"
                 (point) (buffer-string))))
```

```
save-excursion 之后 point 还原到 8，内容=">> one two three"
```

注意 point 从 5「还原到」了 8：因为开头插入了 3 个字符，保存的位置标记自动往后挪了 3 位——**它还原的是「文本里的那个位置」，不是死板的数字**。

`save-excursion` 保存的不只是 point：

- **point 和 mark**；
- **当前 buffer**（所以里面 `set-buffer` 也会被还原）；
- **narrowing 状态**（下一节）。

所以凡是「临时挪光标去看一眼」的地方一律包它，不要手工记位置——出错时（比如中途 `signal` 了错误）手工方案不会还原，`save-excursion` 会。代价是每次调用有微小开销，热路径里别滥用。

## 10.7 narrowing

把 buffer 逻辑上「裁」成一段，之后所有读写都只看这一部分：

```elisp
(with-temp-buffer
  (insert "A1\nA2\nB1\nB2\n")
  (goto-char (point-min))
  (save-excursion
    (save-restriction
      (search-forward "B1")
      (beginning-of-line)
      (narrow-to-region (point) (point-max))
      (princ (format "narrow 之后 point-min=%S point-max=%S 只看到=%S\n"
                     (point-min) (point-max) (buffer-string)))))
  (princ (format "还原之后又能看全: %S\n" (buffer-string))))
```

```
narrow 之后 point-min=7 point-max=13 只看到="B1
B2
"
还原之后又能看全: "A1
A2
B1
B2
"
```

`save-restriction` 保存/恢复 narrowing 状态。`save-excursion` 也会还原 narrowing，但**语义更明确的写法是 `save-restriction`**——两者嵌套时意图更清楚。

两个注意事项：

- narrowing 期间 `point-min` / `point-max` 会变，任何依赖绝对位置的代码在 narrowing 下都可能出错——所以「不确定外面有没有被 narrow 过」的代码先 `(widen)`；
- narrowing 是「逻辑裁剪」，文本没被删掉，`widen` 或退出 `save-restriction` 后全部回来。

## 10.8 在别的 buffer 里干活

```elisp
(let ((b (generate-new-buffer "demo-work")))
  (with-current-buffer b
    (insert "工作在别的 buffer")
    (princ (format "名字=%S 内容=%S\n" (buffer-name) (buffer-string))))
  (princ (format "回到主 buffer: %S，它还在吗: %S\n"
                 (buffer-name) (buffer-live-p b)))
  (kill-buffer b))
```

```
名字="demo-work" 内容="工作在别的 buffer"
回到主 buffer: "*scratch*"，它还在吗: t
```

- `with-current-buffer` 是**宏**：临时把当前 buffer 换成它，退出自动恢复，优先用它；
- `set-buffer` 是**函数**，不恢复——只有确定后面要一直待在那个 buffer 时才用；
- 注意 `with-current-buffer` **不切换用户看到的窗口**，只是换了「当前 buffer」这个内部状态。要让用户看到某个 buffer，得用 `pop-to-buffer` / `display-buffer` 这类操作窗口的函数（窗口章节会讲）。

按名字找 buffer：

```elisp
(let ((b (get-buffer-create "*demo-scratch*")))
  (princ (format "新建 buffer: %S，再取一次同一个对象: %S\n"
                 (buffer-name b) (eq b (get-buffer-create "*demo-scratch*"))))
  (kill-buffer b))
```

```
新建 buffer: "*demo-scratch*"，再取一次同一个对象: t
```

`get-buffer` 找不到返回 `nil`，**`get-buffer-create` 找不到就新建**——用错了会意外创建一堆垃圾 buffer。命名习惯：临时 buffer 用 `*星号*` 包起来（`*demo-scratch*`），避免和用户的文件 buffer 重名。

## 10.9 搜索收尾：looking-at 与匹配数据

```elisp
(with-temp-buffer
  (insert "id=42 name=bob")
  (goto-char (point-min))
  (when (re-search-forward "id=\\([0-9]+\\)" nil t)
    (princ (format "re-search-forward 找到 id=%S，point 现在在 %S\n"
                   (match-string-no-properties 1) (point))))
  (goto-char (point-min))
  (princ (format "looking-at 从当前位置匹配: %S\n"
                 (looking-at "id=[0-9]+"))))
```

```
re-search-forward 找到 id="42"，point 现在在 6
looking-at 从当前位置匹配: t
```

`re-search-forward` 的第三、四个参数：`BOUND`（搜索上限位置，`nil` 为 `point-max`）和 `NOERROR`（找不到时返回 `nil` 而不是报错）。**写扩展时几乎总是传 `nil t`**——「找不到」是正常情况，不该炸。

## 10.10 本章小结

| 需求 | 用什么 |
|---|---|
| 临时 buffer 里干活 | `with-temp-buffer` |
| 当前 buffer 的名字/列表 | `buffer-name` / `buffer-list` |
| 读位置 | `point` / `point-min` / `point-max` / `bobp` / `eobp` |
| 移动 | `goto-char` / `forward-char` / `forward-line` / `line-beginning-position` |
| 取文本 | `buffer-string` / `buffer-substring-no-properties` |
| 搜索 | `search-forward` / `re-search-forward`（传 `nil t`）/ `looking-at` |
| 替换 | `replace-match`（注意第 4 参数） |
| 临时改动后还原 | `save-excursion` |
| 只看一段 | `narrow-to-region` + `save-restriction` |
| 在别的 buffer 干活 | `with-current-buffer` / `get-buffer-create` |
| 只读 buffer 里写 | `let ((inhibit-read-only t))` |

---

上一章：[09 · 序列与 cl-lib](09-sequences.md)　｜　下一章：[11 · 文本属性与 overlay](11-text-properties.md)　｜　返回：[Emacs 扩展开发指南](README.md)
