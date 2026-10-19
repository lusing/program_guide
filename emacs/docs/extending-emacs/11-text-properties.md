# 11 · 文本属性与 overlay

> 所属部分：第 2 部分 · 编辑器数据结构

> 示例：`examples/11-text-properties.el`

这是「怎么给文本加高亮/链接/隐藏」这一整类功能的底层机制。Emacs 里有两套：**文本属性** 和 **overlay**。
它们的区别只有一条，但决定了该用哪个。

## 11.1 文本属性：粘在字符上

```elisp
(let ((s (propertize "重要" 'face 'bold)))
  s)
```

```
带属性字符串: #("重要" 0 2 (face bold))
取属性 face = bold，取不存在的 = nil
```

属性是 `(key . value)` 对，跟着**字符**走。在 buffer 里加：

```elisp
(put-text-property 1 3 'face 'error)         ; 区间 [1,3)
(add-text-properties 1 3 '(face error help-echo "点我"))
```

```
KEYWORD 首字符的 face = error，普通字符的 face = nil
属性变化点: 7
```

## 11.2 【坑】equal 忽略文本属性

```
equal = t，equal-including-properties = nil
```

一个带 face 的和一个不带 face 的同内容字符串，`equal` 认为相等。这在测试里会造成
「明明 face 没加上，测试却过了」的情况。要验属性用 `equal-including-properties`，或者直接查
`(get-text-property pos 'face)`。

## 11.3 【关键区别一】属性跟着字符走

```elisp
(let ((s (propertize "重要" 'face 'bold)))
  (concat s "后面"))
```

```
后面紧插的文本继承了属性: face@3 = nil
```

复制/拼接时属性会跟着字符一起移动。有意思的是「插入」时的继承规则：
**从带属性的字符后面插入，新文本会继承属性**；从前面插入则不继承 —— 所以这里 `face@3` 是 `nil`。

想彻底去掉属性：`substring-no-properties` / `(buffer-substring-no-properties ...)` /
`remove-text-properties`。

```
去掉属性后: "重要"，equal-including-properties = t
```

## 11.4 【关键区别二】overlay 是位置上的对象

overlay 不属于字符，它是**一个 (起, 止) 区间上的独立对象**：

```elisp
(let ((ov (make-overlay 3 6)))
  (overlay-put ov 'face 'highlight)
  (move-overlay ov 1 3)          ; 移动的是区间，不碰文本
  (delete-overlay ov))
```

```
overlay 范围 = 3..6，face = highlight
move 之后 = 1..3
查询 buffer 位置 2 上的 overlay: 1 个
删除后 overlays-at 2: 0 个
help-echo = "点我"
```

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

```
help-echo = "点我"
长度不受显示影响: 3
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

```
长度不受显示影响: 3
```

`invisible` 的文本**仍然在 buffer 里**：`buffer-string` 拿得到、`buffer-size` 算它、`point` 会走进去、
正则能匹配到。所以「用 invisible 实现折叠」时，所有遍历 buffer 的代码都要额外处理它
（看 `buffer-invisibility-spec`）。这一点很多人会想当然搞错。

---

上一章：[10 · buffer 与 point](10-buffers.md)　｜　下一章：[12 · 文件与目录](12-files.md)　｜　返回：[Emacs 扩展开发指南](README.md)
