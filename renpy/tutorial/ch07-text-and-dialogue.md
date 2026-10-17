# 第 7 章 对话进阶与文本

> [← 第 6 章 菜单、变量与分支](ch06-menus-and-variables.md) ｜ [目录](index.md) ｜ [第 8 章 NVL 模式 →](ch08-nvl-mode.md)

对话是视觉小说的呼吸。这一章把 `say` 语句的全部能力——角色参数、附加参数、`extend`、多段独白、插值、文本标签、转义——一次讲透。

## 7.1 Character 的进阶参数

第 3 章用 `Character("名字", color=...)` 建立了基本认识，这里补齐最常用的进阶参数：

```renpy
define sys = Character("系统", what_prefix="【", what_suffix="】", what_color="#a0d0ff")
default speaker = "？？？"
define mystery = Character(dynamic=True)

label start:
    sys "神经同步系统已上线。"
    $ speaker = "艾莉"
    mystery "……我想起来了，我叫艾莉。"
    return
```

- `what_prefix` / `what_suffix`：包在**正文**两侧；对应的 `who_prefix` / `who_suffix` 包在**名字**两侧。
- `dynamic=True`：每次说话时，把这个 Character 的第一个位置参数当作**表达式重新求值**来得到名字。上面 `mystery` 的名字随变量 `speaker` 从"？？？"变成"艾莉"——做"未知身份逐步揭示"的利器。
- 第 4 章的图像关联与 `say` 属性（`e happy "..."` 切表情、`e @ happy "..."` 仅本句生效、`e -happy "..."` 摘掉属性）在这里同样适用，不再重复。

## 7.2 say 附加参数（say with arguments）

任何对话语句都可以追加括号内的关键字参数，临时覆盖该句的呈现样式：

```renpy
label start:
    e "这句话要显示得特别大。" (what_size=32)
    e "这一句显示完不会停留。" nointeract
    return
```

- 参数名带 `what_` 前缀作用于正文，`who_` 前缀作用于名字（`who_color`、`what_bold` 等，与 Character 参数同表）；
- `nointeract` 让这一句显示后不停顿等点击，常配合 `{nw}` 标签做连播。

## 7.3 extend：接着上一句说

```renpy
label start:
    e "你真的要离开吗？"
    extend "……好吧，我不问第二遍了。"
    return
```

`extend` 复用**上一位说话者**的 Character，在同一个对话窗内追加文字，不换窗、不重新打字机（从当前位置继续显示）。适合"打断""补刀""语气急转"。

## 7.4 Monologue：三引号多段独白

```renpy
label start:
    e """
    今天发生了很多事。

    先是迟到了，然后又把咖啡洒在了作业上。

    不过……至少明天是周末。
    """
    return
```

三引号字符串启用 monologue 模式：**空行分隔的每一段，都是独立的一个对话窗**，玩家逐段点击推进。这让大段自言自语不必写成一连串 `e "..."`。段内强制换行也可以保留（引擎会按原文断行）。

## 7.5 文本插值与转换旗标

```renpy
default player = "小雪"
default score = 42

label start:
    e "你好，[player]。"
    e "一加一等于 [1 + 1]。"
    e "当前得分 [score]。"
    return
```

`[...]` 里的表达式在文本显示时求值——可以是变量名，也可以是 `[1 + 1]` 这样的小表达式。当插值本身有格式需求时，在表达式后加**旗标**：

| 旗标 | 作用 |
|---|---|
| `!s` / `!r` | 转字符串 / repr 形式 |
| `!t` | 按当前语言翻译 |
| `!i` | 对插值结果再做一轮插值 |
| `!q` | 转义特殊字符（安全用于文件名、URL） |
| `!u` / `!l` / `!c` | 全大写 / 全小写 / 首字母大写 |

```renpy
label start:
    e "存档文件将是 [player!q].save。"
    e "调试输出：[player!r]。"
    e "庄重模式：[player!u]到！"
    return
```

多个旗标可以连写，生效顺序固定为：`!r`/`!s` → `!t` → `!i` → `!q` → `!u`/`!l` → `!c`（从左到右按此优先级排列，与书写顺序无关）。`!i` 的用武之地是"模板变量"：

```renpy
default tip = "记得存档，[player]。"

label start:
    e "[tip!i]"
    return
```

`[tip]` 的值本身含 `[player]`，用 `!i` 让引擎把它再展开一层。

## 7.6 文本标签（text tags）

文本标签写在字符串**内部**，控制节奏与样式。

**节奏标签：**

```renpy
label start:
    e "第一段{w}点击后才是第二段。"
    e "停 1.5 秒{w=1.5}自动继续。"
    e "点击分段{p}继续说。"
    e "这句显示完不会停留。{nw}"
    show eileen happy
    e "（刚才若点了，这句瞬间到结尾）{fast}"
    return
```

- `{w}` 等待点击；`{w=1.5}` 等 1.5 秒后自动继续；
- `{p}` 等待点击并**另起一段**；`{p=1.5}` 同理限时；
- `{nw}` 显示完不停留，立即执行**下一条语句**；`{fast}` 让本句跳过打字机动画瞬间显示。两者组合是官方惯用的"动画文本"技巧：玩家在 `{nw}` 触发前点击 → `show` 执行 → 下一句以 `{fast}` 一闪而出，产生"打断并立刻给出结果"的演出；
- `{cps=20}` 限定本句每秒显示字符数。

**样式标签（成对出现，`{/...}` 闭合）：**

```renpy
label start:
    e "{b}加粗{/b}、{i}斜体{/i}、{u}下划线{/u}、{s}删除线{/s}。"
    e "{color=#f00}红色{/color}、{alpha=0.5}半透明{/alpha}、{size=+10}更大{/size}。"
    e "{plain}剥掉所有装饰{/plain}。"
    return
```

`{size=+10}` 支持相对值；`{color}` 接 `#rgb`/`#rrggbb`/`#aarrggbb`。

**图像与间距标签：**

```renpy
label start:
    e "行内插图{image=icon heart}好看吧？"
    e "水平空隙{space=30}在这里。{vspace=40}这是竖直间距。"
    return
```

`{image=tag}` 在文本流中嵌入已定义的图像；`{space=像素}` 与 `{vspace=像素}` 插入空隙。

**无障碍标签：**

```renpy
e "{alt}（挥手的音效）{/alt}嗨！"
```

`{alt}` 包住的内容不会被显示，但会被"自述（self-voicing）"功能朗读给视障玩家；`{noalt}` 则定义只显示不朗读的替代文本。

## 7.7 转义：[[、{{、%%

插值与标签都占用了一个特殊字符，想显示它们本身就要双写：

```renpy
label start:
    e "方括号双写 [[ 才能显示 [，[player] 才是插值。"
    e "花括号双写 {{ 才能显示 {。"
    e "百分号也一样，%% 才是一个 %。"
    return
```

字符串内部的英文双引号用反斜杠转义（`"她说\"你好\""`），或改用单引号包裹整句。

## 7.8 screen 里的文本（预告）

```renpy
screen hud():
    text "得分：[score]" size 30 xpos 40 ypos 30
```

`text` 部件同样支持插值与文本标签——第 13 章起系统讲解。

## 7.9 小结与实践

- `dynamic` 角色做身份揭示，`what_prefix/suffix` 做播报腔；
- `extend` 是同窗续接，monologue 是分段独白；
- 插值旗标顺序：`!r/!s → !t → !i → !q → !u/!l → !c`；
- `{nw}+{fast}` 与 `{w=秒}` 是节奏控制的两大抓手；
- 示例工程 `05_text_and_dialogue` 覆盖本章语法。

---

> [← 第 6 章 菜单、变量与分支](ch06-menus-and-variables.md) ｜ [目录](index.md) ｜ [第 8 章 NVL 模式 →](ch08-nvl-mode.md)
