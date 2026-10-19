# 11 · 文本属性与 overlay

> 所属部分：第 2 部分 · 编辑器数据结构

> 示例：`examples/11-text-properties.el`

这是「怎么给文本加高亮/链接/隐藏」这一整类功能的底层机制。Emacs 里有两套：**文本属性** 和 **overlay**。
它们的区别只有一条，但决定了该用哪个。

## 11.1 文本属性：粘在字符上

```elisp
(defvar demo-s (propertize "重要" 'face 'bold))
(princ (format "带属性字符串: %S\n" demo-s))
(princ (format "取属性 face = %S，取不存在的 = %S\n"
               (get-text-property 0 'face demo-s)
               (get-text-property 0 'nope demo-s)))
```

```
带属性字符串: #("重要" 0 2 (face bold))
取属性 face = bold，取不存在的 = nil
```

属性是 `(key . value)` 对，跟着**字符**走。`propertize` 造一个带属性的字符串，
`get-text-property` 读 —— 注意它读的是**该位置及其后最近一个**带此属性的字符的值。

在 buffer 里加，用三个「设属性」函数，区别在于是**设一个**、**加几个**还是**整份替换**：

```elisp
(with-temp-buffer
  (insert "normal KEYWORD normal")
  (goto-char (point-min))
  (re-search-forward "KEYWORD")
  (put-text-property (match-beginning 0) (match-end 0) 'face 'error)
  (princ (format "KEYWORD 首字符的 face = %S，普通字符的 face = %S\n"
                 (get-text-property 7 'face (buffer-string))
                 (get-text-property 2 'face (buffer-string))))
  (princ (format "属性变化点: %S\n"
                 (next-property-change 1 (buffer-string)))))
```

```
KEYWORD 首字符的 face = error，普通字符的 face = nil
属性变化点: 7
```

区间一律写成 `[起, 止)`（含起不含止），**buffer 位置从 1 开始，字符串下标从 0 开始** ——
所以 buffer 里第 8 个字符（KEYWORD 的 K），在 `buffer-string` 上的下标是 7。这是初学者最常
踩的索引错位。`next-property-change` 用来找「属性第一次变化的位置」，遍历属性区间就靠它
（到末尾都没变化返回 `nil`）。

三兄弟的语义差别值得单独演示：

```elisp
(with-temp-buffer
  (insert "abcdef")
  (put-text-property 1 4 'face 'bold)
  (add-text-properties 1 4 '(help-echo "点我"))
  (princ (format "put+add: face = %S，help-echo = %S\n"
                 (get-text-property 1 'face (buffer-string))
                 (get-text-property 1 'help-echo (buffer-string))))
  (set-text-properties 1 4 '(face italic))
  (princ (format "set 整份替换: face = %S，help-echo = %S\n"
                 (get-text-property 1 'face (buffer-string))
                 (get-text-property 1 'help-echo (buffer-string)))))
```

```
put+add: face = bold，help-echo = "点我"
set 整份替换: face = italic，help-echo = nil
```

`put-text-property` 设单个属性；`add-text-properties` 加列出的几个、不动其他；
`set-text-properties` 是**整份替换** —— 上面第三行 `help-echo` 被清成 `nil`，就是这个原因。
想给一段文本「只加高亮、不动原有属性」，用 `add-text-properties`，别用 `set-text-properties`。

## 11.2 【坑】equal 忽略文本属性

```elisp
(princ (format "equal = %S，equal-including-properties = %S\n"
               (equal "abc" (propertize "abc" 'face 'bold))
               (equal-including-properties "abc" (propertize "abc" 'face 'bold))))
```

```
equal = t，equal-including-properties = nil
```

一个带 face 的和一个不带 face 的同内容字符串，`equal` 认为相等。这在测试里会造成
「明明 face 没加上，测试却过了」的情况。要验属性用 `equal-including-properties`，或者直接查
`(get-text-property pos 'face)`。

## 11.3 【关键区别一】属性跟着字符走

```elisp
(princ (format "concat 带着属性走: face@1 = %S\n"
               (get-text-property 1 'face (concat (propertize "AA" 'face 'bold) "BB"))))
```

```
concat 带着属性走: face@1 = bold
```

复制、`concat`、kill-ring 里的文本，属性都跟着字符一起走 —— 这就是「属性粘在字符上」的
实际含义：你操作的是**带元数据的字符流**，不是裸字符。

但**插入**是另一回事，而且反直觉：

```elisp
(with-temp-buffer
  (insert (propertize "AAA" 'face 'bold))
  (goto-char (point-max))
  (insert "BBB")                        ; 普通 insert：不继承
  (princ (format "insert 后插 BBB: face@3 = %S\n"
                 (get-text-property 3 'face (buffer-string)))))
```

```
insert 后插 BBB: face@3 = nil
```

`insert` **不继承任何属性**：新文本只有字符串自带的属性。手册的原话是「do not inherit any
properties」—— 这是刻意的，程序经常把文本从一个语境搬进另一个语境（比如进出 kill-ring），
自动继承反而会出错。要「像用户打字那样，接着前面的字符继续带属性」，用
`insert-and-inherit`（另有 `insert-before-markers-and-inherit`，行为相同但插入点在 marker 之前）：

```elisp
(with-temp-buffer
  (insert (propertize "AAA" 'face 'bold))
  (goto-char (point-max))
  (insert-and-inherit "BBB")
  (princ (format "insert-and-inherit 后插: face@3 = %S\n"
                 (get-text-property 3 'face (buffer-string)))))
```

```
insert-and-inherit 后插: face@3 = bold
```

继承规则（stickiness）：

- 默认 **rear-sticky**（向后粘）：插在某个字符**后面** → 继承那个字符的属性；
- 默认 **front-nonsticky**（不向前粘）：插在某个字符**前面** → **不**继承它的属性；
- 同一属性两边都能给时，**前一个字符的值优先**。

两个特殊属性可以逐字改这个行为：`front-sticky`（该字向前粘）、`rear-nonsticky`（该字不再
向后粘）。值可以是 `t`（全部属性）或属性名列表。缓冲区级的默认值在
`text-property-default-nonsticky` 里 —— Emacs 31 的默认值只有 `composition`、`syntax-table`、
`display` 三项是 rear-nonsticky：

```elisp
(princ (format "text-property-default-nonsticky = %S\n" text-property-default-nonsticky))
```

```
text-property-default-nonsticky = ((composition . t) (syntax-table . t) (display . t))
```

```elisp
(with-temp-buffer
  (insert "PPP")
  (insert (propertize "AAA" 'face 'bold 'front-sticky t))
  (goto-char 4)                          ; 插在 P 和 A 之间
  (insert-and-inherit "M")
  (princ (format "front-sticky 向前粘: face@3 = %S\n"
                 (get-text-property 3 'face (buffer-string)))))
(with-temp-buffer
  (insert (propertize "AAA" 'face 'bold 'rear-nonsticky t))
  (goto-char (point-max))
  (insert-and-inherit "BBB")
  (princ (format "rear-nonsticky 不向后粘: face@3 = %S\n"
                 (get-text-property 3 'face (buffer-string)))))
```

```
front-sticky 向前粘: face@3 = bold
rear-nonsticky 不向后粘: face@3 = nil
```

第一段：插入点前的 P 没有 face，但后面的 A 标了 `front-sticky`，于是 M 继承了 bold。
第二段：A 标了 `rear-nonsticky`，默认的「向后粘」被关掉，后插的 BBB 就是裸文本。

想彻底去掉属性：`substring-no-properties` / `(buffer-substring-no-properties ...)` /
`remove-text-properties`。

```elisp
(princ (format "去掉属性后: %S，equal-including-properties = %S\n"
               (substring-no-properties demo-s)
               (equal-including-properties "重要" (substring-no-properties demo-s))))
```

```
去掉属性后: "重要"，equal-including-properties = t
```

## 11.4 【关键区别二】overlay 是位置上的对象

overlay 不属于字符，它是**一个 (起, 止) 区间上的独立对象**：

```elisp
(with-temp-buffer
  (insert "0123456789")
  (let ((ov (make-overlay 3 6)))
    (overlay-put ov 'face 'highlight)
    (princ (format "overlay 范围 = %S..%S，face = %S\n"
                   (overlay-start ov) (overlay-end ov) (overlay-get ov 'face)))
    (move-overlay ov 1 3)          ; 移动的是区间，不碰文本
    (princ (format "move 之后 = %S..%S\n" (overlay-start ov) (overlay-end ov)))
    (princ (format "查询 buffer 位置 2 上的 overlay: %S 个\n"
                   (length (overlays-at 2))))
    (delete-overlay ov)
    (princ (format "删除后 overlays-at 2: %S 个\n" (length (overlays-at 2))))))
```

```
overlay 范围 = 3..6，face = highlight
move 之后 = 1..3
查询 buffer 位置 2 上的 overlay: 1 个
删除后 overlays-at 2: 0 个
```

`overlays-at` 查某个位置上的 overlay，`overlays-in` 查区间内的。移动/删除 overlay 完全不碰
buffer 文本 —— 这是它与文本属性最直观的差别。

overlay 的常用属性：`face`、`display`（替换显示内容）、`invisible`、`help-echo`（悬停提示）、
`before-string` / `after-string`（在区间前后插显示内容，不影响 buffer 文本）、
`evaporate`（空了就自动删）、`priority`（重叠时谁在上面）。

## 11.5 什么时候用哪个

| 场景 | 用 | 理由 |
|---|---|---|
| 语法高亮（跟着词走） | 文本属性 | 编辑时自动跟着文本移动 |
| 临时高亮（搜索命中、选中） | overlay | 编辑时位置不跟着跑（通常正是想要的） |
| 给整行加个图标/箭头 | overlay + `before-string` | 不污染 buffer 内容 |
| 折叠/隐藏一段 | overlay + `invisible` | 可随时开关 |
| 链接（可点击） | 文本属性 + `keymap`/`mouse-face` | 要跟字符走 |

实际项目里两者常混用：font-lock 用文本属性，`hl-line` / `isearch` / `flymake` 用 overlay。

## 11.6 常用属性名

```elisp
(with-temp-buffer
  (insert (propertize "可点" 'help-echo "点我" 'mouse-face 'highlight))
  (princ (format "help-echo = %S\n"
                 (get-text-property 0 'help-echo (buffer-string)))))
```

```
help-echo = "点我"
```

| 属性 | 作用 |
|---|---|
| `face` | 字体/颜色（第 16 章的字体锁就是加这个） |
| `font-lock-face` | 同上，但会被 font-lock 管理 |
| `invisible` | 不显示 |
| `display` | 用别的内容替换显示 |
| `help-echo` | 鼠标悬停时的提示（也可以是函数，动态生成） |
| `keymap` | 这段文本上的局部按键绑定 |
| `mouse-face` | 鼠标悬停时的高亮 face |
| `read-only` | 这段文本不可修改 |
| `field` | 把一段文本当作一个整体（比如按钮） |

## 11.7 【坑】invisible 只是不显示

```elisp
(princ (format "长度不受显示影响: %S\n"
               (length (propertize "abc" 'invisible t))))
```

```
长度不受显示影响: 3
```

`invisible` 的文本**仍然在 buffer 里**：`buffer-string` 拿得到、`buffer-size` 算它、`point` 会走进去、
正则能匹配到。所以「用 invisible 实现折叠」时，所有遍历 buffer 的代码都要额外处理它
（看 `buffer-invisibility-spec`）。这一点很多人会想当然搞错。

---

上一章：[10 · buffer 与 point](10-buffers.md)　｜　下一章：[12 · 文件与目录](12-files.md)　｜　返回：[Emacs 扩展开发指南](README.md)
