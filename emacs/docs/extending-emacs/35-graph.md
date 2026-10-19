# 35 · 收尾项目：打印一张带坐标的柱状图

> 所属部分：第 9 部分 · 跟随 eintr：调试与收尾项目

> 示例：`examples/35-graph.el`

全书的最后一个项目。eintr 的收尾章节是「画一张图」（Readying a Graph）：把数据画成带坐标轴的柱状图，打印在缓冲区里。这个项目不大，却几乎动用了整本书的零件——**列表**（[07 · 列表](07-lists.md)）、**递归**（[28 · 递归](28-recursion.md)）、**循环**（[05 · 控制流](05-control-flow.md)）、**把缓冲区当画布的 point 操作**（[10 · 缓冲区](10-buffers.md)、[29 · 读懂真实函数](29-read-source.md)）。eintr 原书的数据来自 kill ring 元素的长度（[30 · 剪贴板机制](30-kill-ring.md) 的延伸），本章换成一组固定的数字，让输出**完全可复现**，便于逐行验收。

这一章没有新概念，只有「组装」。但组装恰恰是写程序时最容易低估的环节：**坐标轴和图体如何对齐？最高柱不在刻度上怎么办？** eintr 在原书里为这两个问题各绕了几个弯，本章把弯路直接整理成直路讲给你。

## 35.1 列模型：一根柱 = 上空下实

一切从一个最小的抽象开始：**画布总高 `height`，要画一根高 `c` 的柱，这一列就是「上面 `height-c` 个空白、下面 `c` 个星号」的字符串列表，首元素对应图的最顶行**。

```elisp
(defun my-column-of-graph (max-height actual-height)
  "返回画一根柱的字符串列表：先 MAX-ACTUAL 个空白，再 ACTUAL 个星号。
列表首元素对应图的最顶行。"
  (let ((acc nil))
    (dotimes (_ (- max-height actual-height))
      (push " " acc))
    (dotimes (_ actual-height)
      (push "*" acc))
    (nreverse acc)))
```

实现是第 28 章「攒列表标准姿势」的又一次实战：`dotimes` 计数循环 + `push` 头插 + `nreverse` 翻正（[05 · 控制流](05-control-flow.md) 的 `dotimes`）。两个循环依次把空白和星号压进 `acc`，头插让**最后压入的排在最前**，所以 `nreverse` 之后恰好是「空白在前、星号在后」的自顶向下顺序。

```text
== 1) 列模型：一根柱 = 上空下实 ==
columns = (3 7 5 10 6 2 8 4 9 1)
画布总高（最高柱）= 10
列 4（高 10）自顶向下 = ("*" "*" "*" "*" "*" "*" "*" "*" "*" "*")
列 2（高 7）自顶向下 = (" " " " " " "*" "*" "*" "*" "*" "*" "*")
```

读法：数据是 10 根柱，最高 10，所以画布高 10。**列 4**（高 10）从头到尾都是星号；**列 2**（高 7）是 3 个空白后跟 7 个星号——上面空 3 行，正好 `10 - 7`。**记住这个模型，后面两种画法吃的都是它**：先有「每列长什么样」，才有「整张图怎么拼」。

## 35.2 把缓冲区当画布：递归逐列贴入

eintr 画图体的思路非常「Emacs」：**缓冲区就是画布**。先铺好 `height` 个等宽的空白行，然后一列一列地把星号「贴」进各自的位置——这和你在 29 章见过的 `append-to-buffer` 是同一种世界观：程序通过移动 point 来「落笔」。

贴一列的函数用**递归**写（从顶行贴到底行，每贴一格递归下一行）：

```elisp
(defun my-paint-column (col height c row)
  "把第 COL 列（高 C）贴进当前缓冲区画布，从第 ROW 行开始递归往下。"
  (when (< row height)
    (goto-char (point-min))
    (forward-line row)
    (forward-char (+ (* my-col-width col) (1- my-col-width)))
    (delete-char 1)
    (insert (if (>= c (- height row)) "*" " "))
    (my-paint-column col height c (1+ row))))
```

读法：

- **`(when (< row height) …)` 是递归的 base case**（[28 · 递归](28-recursion.md)）：`row` 从 0 数到 `height` 就停。每层递归负责**一行里的一格**。
- **定位三连**：`(goto-char (point-min))` 回到画布开头 → `(forward-line row)` 下到第 `row` 行 → `(forward-char …)` 横移到本列的落笔点。落笔点公式 `col × 列宽 + (列宽 - 1)` 把星号放在每个单元格的**末位**——这个约定马上会被 X 轴刻度利用。
- **`(delete-char 1)` + `insert` 是「覆盖一格」**：画布预先铺满了空格，先删掉那格空格、再写入星号或空白（未到「水位」的格子写回空格，等于洗掉上一列可能残留的东西——虽然本例画布是全新的，但这个习惯让函数可以安全地重复调用）。
- **`c` 和 `height - row` 比较**就是「水位判定」：第 `row` 行对应的「水位」是 `height - row`（顶行水位最高），柱够高才画星号。

贴完一列递归去贴下一列，外层也是递归：

```elisp
(defun my-paint-columns (columns col height)
  "递归：先把第 COL 列贴进画布，再处理余下的列。"
  (when columns
    (my-paint-column col height (car columns) 0)
    (my-paint-columns (cdr columns) (1+ col) height)))
```

于是「画整个图体」就是：铺画布 → 递归贴列 → 把缓冲区内容按行取回：

```elisp
(defun my-graph-body-print (columns)
  "把 COLUMNS 画成不带坐标轴的柱状图体，返回行列表（行尾已修剪）。
画布是临时缓冲区：先铺空行，再逐列递归贴星号。"
  (let ((height (apply #'max columns)))
    (with-temp-buffer
      (dotimes (_ height)
        (insert (make-string (* my-col-width (length columns)) ?\s) "\n"))
      (my-paint-columns columns 0 height)
      (mapcar #'string-trim-right
              (butlast (split-string (buffer-string) "\n"))))))
```

`(apply #'max columns)` 求画布总高；`with-temp-buffer` 提供一块随用随弃的画布（[34 · 初始化文件与 mode line](34-init-mode-line.md) 里它建的缓冲区叫 `" *temp*"`——前导空格的内部缓冲区约定）；最后 `split-string` 按行拆开、`mapcar` 逐行 `string-trim-right` 掉行尾空格（右侧列不够高的行都是空白结尾），`butlast` 丢掉结尾换行产生的空串。

```text
== 2) 把缓冲区当画布：逐列贴入 ==
画布上画出的图体（行尾已修剪）：
       *
       *         *
       *     *   *
   *   *     *   *
   *   * *   *   *
   * * * *   *   *
   * * * *   * * *
 * * * * *   * * *
 * * * * * * * * *
 * * * * * * * * * *
```

十行图体，从顶行（水位 10，只有第 4 列的柱够到）铺到底行（水位 1，除第 10 列（高 1）之外全部够到）。**逐行验收一遍**：对照数据 `(3 7 5 10 6 2 8 4 9 1)`，数一数每一行的第 2j 个字符（列 j 的星号位）——第 6 行（水位 5）起第 2 列出现，第 3 行（水位 8）起第 7、8 列出现。**图体是对的，但光有它还不成图**——没有坐标轴，你不知道每根柱代表几。

## 35.3 坐标轴：Y 轴刻度与 X 轴对齐

坐标轴是 eintr 原书着墨最多的部分，两个难点都值得单独看。

### Y 轴：top label 问题

Y 轴每逢刻度行显示行号，其余行用空格补位——前提是**行号右对齐到固定宽度**（最高柱是两位数，刻度就必须都占两位，否则竖线对不齐）：

```elisp
(defun my-pad-left (s width)
  "把字符串 S 右对齐到 WIDTH 宽（左侧补空格）。"
  (if (< (length s) width)
      (concat (make-string (- width (length s)) ?\s) s)
    s))

(defun my-y-prefix (i height)
  "图体第 I 行（1 起，自顶往下）的 Y 轴前缀。
落在刻度上的行显示行号，其余行用空格补位。"
  (let ((w (length (number-to-string height))))
    (concat (if (zerop (% i my-y-spacing))
                (my-pad-left (number-to-string i) w)
              (make-string w ?\s))
            " | ")))
```

eintr 原书在这里埋了一个真实的坑，原书称之为 **top label 问题**：如果最高柱**不在刻度上**（`height % spacing ≠ 0`），图体顶行的上方就永远显示不出最大值——`10` 不是 `4` 的倍数，逐行画刻度画到顶也只标到 `8`。原书试了几种「把顶部数字硬塞进图体」的写法都不干净，最后的结论朴实得很：**顶部单独打一行数字**。本章采用同一个方案：

```text
== 3) 坐标轴：Y 轴刻度与 X 轴对齐 ==
第 8 行的 Y 前缀 = " 8 | "（8 是 4 的倍数，标行号）
第 9 行的 Y 前缀 = "   | "（9 不是刻度，补空格）
最高柱 10 % 4 = 2 ≠ 0，所以顶部单独一行标 10
X 轴横线 = "   +--------------------"
X 轴标签 = "      1     4     7    10"
```

### X 轴：对齐是算出来的

X 轴两行：一条横线，一排刻度数字。**刻度数字的末位必须正好压在该柱星号的正下方**——这不能靠凑，得靠算：

```elisp
(defun my-x-axis-lines (ncols height)
  "返回 X 轴两行：横线行与刻度标签行。
刻度从第 1 根柱起、每 X-SPACING 根一个，数字末位对准该柱星号。"
  (let* ((w (length (number-to-string height)))
         (rule (concat (make-string (+ w 1) ?\s)
                       "+"
                       (make-string (* my-col-width ncols) ?-)))
         (labels (make-string (+ w 3) ?\s))
         (j 1))
    (while (<= j ncols)
      (let* ((num (number-to-string j))
             ;; 列 j 的星号在整行里的 1-based 位置：Y 前缀占 w+3 格，
             ;; 该列单元末位再往右 w*j 格
             (star-pos (+ w 3 (* my-col-width j)))
             (start (1+ (- star-pos (length num)))))
        (while (< (length labels) (1- start))
          (setq labels (concat labels " ")))
        (setq labels (concat labels num)))
      (setq j (+ j my-x-spacing)))
    (list rule labels)))
```

位置账本（全行 1-based 计数）：

- Y 轴前缀 = `w` 格行号 + `" | "`，共 **`w + 3` 格**，图体从第 `w + 4` 格开始；
- 列 `j` 的单元宽 `w`，星号在单元**末位**（35.2 定下的约定），所以**星号位置 = `w + 3 + w × j`**；
- 刻度数字 `num` 要让**末位**落在 `star-pos`，于是从 `star-pos - (length num) + 1` 处开始放；中间的空缺用 `while` 逐格补空格。
- 横线行的 `+` 放在第 `w + 2` 格——正好是 Y 轴竖线 `|` 的正下方（`" 8 | "` 里 `|` 在第 4 格，`w = 2` 时 `w + 2 = 4`）。

输出里 `X 轴标签 = "      1     4     7    10"`：`1` 在第 7 格、`4` 在第 13 格、`7` 在第 19 格、`10` 的 `0` 在第 25 格——与 `w + 3 + 2j` 逐一吻合。**「星号约定在单元末位」这个小决定，在这里兑现成了三行位置公式**；如果你把 35.2 的落笔点改成单元首位，这里就全得重推。设计数据表示时，这类「约定」值得写进注释。

## 35.4 组装：完整的图

零件齐了，组装就是把它们按行缝起来：

```elisp
(defun my-print-graph-lines (columns)
  "组装完整柱状图（Y 轴 + 图体 + X 轴），返回行列表。"
  (let* ((height (apply #'max columns))
         (body (my-graph-body-print columns))
         lines)
    ;; top label：最高柱不在刻度上时，单独打一行
    (unless (zerop (% height my-y-spacing))
      (push (my-pad-left (number-to-string height)
                         (length (number-to-string height)))
            lines))
    ;; 图体：从第 height 行（顶）往下到第 1 行
    (let ((i height))
      (while (>= i 1)
        (push (concat (my-y-prefix i height)
                      (nth (- height i) body))
              lines)
        (setq i (1- i))))
    ;; X 轴
    (let ((x (my-x-axis-lines (length columns) height)))
      (push (car x) lines)
      (push (cadr x) lines))
    (nreverse lines)))
```

结构是三段缝合：顶部按需补 top label；中间一个 `while` 从水位 `height` 降到 1，把 Y 轴前缀和图体行 `concat` 起来（`body` 是自顶向下的行列表，所以用 `(nth (- height i) body)` 索引）；底部接上 X 轴两行。照例 `push` 攒、`nreverse` 翻正。

```text
== 4) 组装：完整的图 ==
10
   |        *
   |        *         *
 8 |        *     *   *
   |    *   *     *   *
   |    *   * *   *   *
   |    * * * *   *   *
 4 |    * * * *   * * *
   |  * * * * *   * * *
   |  * * * * * * * * *
   |  * * * * * * * * * *
   +--------------------
      1     4     7    10
```

**这就是全书最后一张图，值得逐行读完**：顶部孤零零的 `10` 是 top label 方案；`8`、`4` 两行带行号，其余行空格补位，竖线笔直——`my-pad-left` 的功劳；X 轴每个数字的末位压在对应柱的正下方；横线从 `+` 一直铺到最后一列。一张图，三段代码，**没有任何魔法，只有算出来的位置**。

## 35.5 循环与递归：殊途同归

35.2 的画布版用缓冲区和递归——那是为了练「Emacs 味」。同一个模型，纯循环也能画：**逐行扫「水位」，够高的柱出星号**：

```elisp
(defun my-graph-body-lines-loop (columns)
  "循环版：逐行直接拼字符串，不经过缓冲区。"
  (let* ((height (apply #'max columns))
         lines)
    (dotimes (row height)
      (let ((line "")
            (level (- height row)))       ; 本行对应的「水位」
        (dolist (c columns)
          (setq line (concat line
                             (if (>= c level)
                                 (concat (make-string (1- my-col-width) ?\s) "*")
                               (make-string my-col-width ?\s)))))
        (push (string-trim-right line) lines)))
    (nreverse lines)))
```

外层 `dotimes` 数行（水位从 `height` 降到 1），内层 `dolist` 数柱，每格按水位判定给星号或空格——**逻辑与递归版一一对应，只是「往下走一行」从递归调用变成了循环变量**。

```text
== 5) 循环与递归：殊途同归 ==
画布版与循环版输出完全一致？ t
```

`(equal …)` 返回 `t`（[06 · 相等](06-equality.md)）：两个结构完全不同的实现，产出逐字节一致的列表。这不是巧合，而是**列模型先行的红利**——两种画法都只是模型的消费方，模型对了，怎么画都对。什么时候用哪个？**要在真实缓冲区里和用户交互（比如把图插进当前 buffer、配合 region 操作），画布版顺手；只出文本（写脚本、出报告），循环版更短**。eintr 用递归版本讲教学，也是同一考量：递归版能把「每一层只做一小步」看得更清楚。

## 35.6 小结

| 零件 | 函数 | 一句话 |
|---|---|---|
| 列模型 | `my-column-of-graph` | 一根柱 = 上空下实的字符串列表；首元素是顶行 |
| 画布 | `my-graph-body-print` | 缓冲区当画布：铺空行、递归贴列、取行修剪 |
| 递归 | `my-paint-column` / `my-paint-columns` | base case 是 `row`/`columns` 耗尽；每层只画一格/一列 |
| Y 轴 | `my-y-prefix` + `my-pad-left` | 行号右对齐补位；最高柱不在刻度上就**顶部单独一行** |
| X 轴 | `my-x-axis-lines` | 星号位置 `w+3+w·j` 是算出来的；数字末位压星号 |
| 组装 | `my-print-graph-lines` | top label + 图体逐行缝合 + X 轴 |
| 对照 | `my-graph-body-lines-loop` | 同一模型的循环实现，`equal` 验证殊途同归 |

到这里，从 eintr 出发的这条路线走完了：**第 27 章的 cons 单元**让你看清列表的内存形状，**第 28 章**给你递归的三种模式，**第 29–32 章**带你读了真实源码、解剖了 kill ring 和正则推进，**第 33–34 章**教会你调试与把代码安进 init.el，而这一章把所有零件拧成了一个能跑的完整程序。后面的两个附录是随用随查的工具书——常见坑（[附录 A](appendix-a-pitfalls.md)）和命令速查（[附录 B](appendix-b-cheatsheet.md)），不必通读。

编程到这一步，剩下的不再是「语法会不会」，而是「**愿不愿意把一个模糊的愿望拆成模型、位置和约定，然后一个一个算清楚**」。这张柱状图里的每一个空格，都是算出来的。祝你在自己的 Emacs 里，画出更大的图。

上一章：[34 · 初始化文件与 mode line](34-init-mode-line.md)　｜　下一章：[36 · 数字：整除、取整、bignum 与位运算](36-numbers.md)　｜　返回：[Emacs 扩展开发指南](README.md)
