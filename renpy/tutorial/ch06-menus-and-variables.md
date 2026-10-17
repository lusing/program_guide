# 第 6 章 菜单、变量与分支

> [← 第 5 章 标签与控制流](ch05-labels-and-flow.md) ｜ [目录](index.md) ｜ [第 7 章 对话进阶与文本 →](ch07-text-and-dialogue.md)

## 6.1 menu 语句的完整形态

```renpy
label start:
    scene bg rain with dissolve
    menu:
        "外面下雨了，怎么办？"
        "冒雨回家":
            jump home_in_rain
        "在屋檐下等雨停":
            jump wait_rain
```

结构三要素：

1. **caption**：`menu:` 下方那行不带冒号的字符串（`"外面下雨了，怎么办？"`），显示在选项列表上方，可省略；
2. **选项**：`"选项文本":` + 缩进块，块内是任意剧本语句，通常以 `jump` 结束；
3. 选项可以被 `if` 条件修饰，可以过滤或灰显（6.2）。

## 6.2 条件项与灰显

选项后直接跟 `if`：

```renpy
default met_lily = False

label start:
    menu:
        "和莉莉搭话" if met_lily:
            jump talk_lily
        "回家":
            jump home
```

`if` 条件为假时，该选项**默认完全不出现**。如果你希望玩家"看见这个选项还锁着"，加一行全局配置：

```renpy
define config.menu_include_disabled = True
```

此后条件不满足的选项会以禁用样式显示（不可点击）。让玩家瞥见未解锁的内容，是叙事游戏常用的钩子。

## 6.3 选项块里能做什么，以及"汇合"写法

选项块里可以放任意语句：赋值、台词、`show`、甚至再嵌套 `menu`。而如果选项块**不写 `jump`**，块结束后会顺序落入 `menu` 之后的语句——用这个特性可以做"只收集决定、随后汇合"的菜单：

```renpy
label start:
    menu:
        "来点什么？"
        "咖啡":
            $ drink = "咖啡"
        "红茶":
            $ drink = "红茶"
    e "一杯[drink]，谢谢。"
    return
```

三个分支在 `e "一杯[drink]……"` 处汇合，不用为每个选项写重复台词。这是把 `menu` 当"交互式赋值器"用的惯用法。

## 6.4 set：让选项只出现一次

`menu` 支持 `set` 子句，接收一个**集合变量**：出现在集合里的选项被隐藏，玩家选中某项后其文本自动入集合。

```renpy
default asked = set()

label start:
    menu:
        set asked
        "什么是视觉小说？":
            "文字与选择交织而成的游戏类型。"
        "Ren'Py 只能做视觉小说吗？":
            "screen 系统足够支撑很多玩法。"
    "（没有可问的了。）"
    return
```

两个关键行为：

- 过滤后**一个选项都不剩**时，整个 `menu` 被直接跳过，不显示——所以上面 `"（没有可问的了。）"` 会在集合集满后自然接上；
- `set` 里的变量必须先 `default` 为 `set()`，它会随存档一起保存，"已经问过的问题"跨存档成立。

## 6.5 define、default、$：三种赋值，三种命运

| 写法 | 执行时机 | 参与存档/回滚 | 典型用途 |
|---|---|---|---|
| `define X = ...` | 初始化阶段执行一次 | 否 | 常量：Character、图像别名、配置值 |
| `default X = ...` | 首次需要而 X 没有值时赋值 | 是 | 游戏过程中会变化的状态 |
| `$ X = ...` | 执行到该行时 | 是（存档点记录它） | 过程性赋值 |

```renpy
define e = Character("艾琳", color="#c8ffc8")
default affection = 0

label start:
    e "初次见面。"
    $ affection += 1
    e "（好感度变成了 [affection]。）"
    return
```

实践准则：**会随剧情变化的量一律 `default`**（而不是在 `init python` 或 `define` 里赋值），这样它才完整参与存档、读档与回滚。`default` 还有一个隐藏价值：读档时如果存档里缺少某变量（比如新版本新增了它），引擎会用 `default` 的值补上——这是"更新游戏不毁旧存档"的机制。`define` 的对象（如 Character）进入存档时保存的是**名字引用**而非对象本身，相关的别名陷阱在第 16 章展开。

## 6.6 综合示例：三题问答

把本章语法拼成一个完整小游戏（对应示例工程 `04_menus_and_variables`）：

```renpy
default score = 0
default asked = set()

label start:
    scene black
    "欢迎来到三题问答。答完所有题后显示得分。"
    while len(asked) < 3:
        call ask_one from _call_ask_one
    "你的最终得分是 [score] / 3。"
    return

label ask_one:
    menu:
        set asked
        "天空为什么是蓝色的？":
            "因为大气对短波长光（蓝光）的散射更强。"
            $ score += 1
        "猫为什么喜欢盒子？":
            "狭小的空间能给猫安全感。"
            $ score += 1
        "海水为什么看起来是蓝的？":
            "海水主要反射天空的颜色。"
    return
```

执行轨迹逐步走一遍：

1. `asked` 为空集，`while len(asked) < 3` 成立，进入 `ask_one`；
2. `menu` 显示三个选项；玩家答一题，该题文本进入 `asked`，`return` 回到 `while`；
3. 第二轮还剩两题可选……第三轮只剩最后一题；
4. 第三次 `return` 后 `len(asked) == 3`，但 `while` 还会再进入一次 `ask_one`——此时 `menu` 的三个选项全部在集合中，**菜单被跳过**，`ask_one` 直接 `return`；
5. 回到 `while`，条件为假，退出循环，播报得分。

这个"集合空了菜单自动放行"的设计，让 `while + menu set` 成为天然的"题库轮换/支线清理"结构。

## 6.7 小结与实践

- caption、条件项、灰显、`set` 去重是菜单的四大开关；
- 选项块不 `jump` 就"汇合"，`menu` 可以只当赋值器；
- `default` 管状态、`define` 管常量、`$` 管过程赋值；
- 示例工程 `03_labels_and_flow` 与 `04_menus_and_variables` 可直接运行对照。

---

> [← 第 5 章 标签与控制流](ch05-labels-and-flow.md) ｜ [目录](index.md) ｜ [第 7 章 对话进阶与文本 →](ch07-text-and-dialogue.md)
