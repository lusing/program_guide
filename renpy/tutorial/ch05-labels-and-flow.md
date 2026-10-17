# 第 5 章 标签与控制流

Ren'Py 剧本的执行模型很简单：**从 `start` 标签开始，语句自上而下顺序执行**。这一章讲的是让"直线叙事"变成"任意结构"的四件工具：`label`（路标）、`jump`/`call`（跳转与往返）、`pass`（占位）、`while`（循环）。

## 5.1 label：剧本的路标

```renpy
label start:
    "闹钟响了。"
    e "再睡五分钟……"
    jump late_for_class

label late_for_class:
    scene bg street with dissolve
    e "糟了，要迟到了！"
    return
```

逐点讲解：

- `label 名字:` 定义一个标签。标签名是标识符（字母或下划线开头），整个工程**全局可见**——这也是为什么你可以把剧本拆成任意多个 `.rpy` 文件（`script.rpy`、`chapter2.rpy`……），跨文件 `jump` 没有任何障碍。
- `start` 是一个特殊名字：玩家点"开始游戏"后，引擎从这里执行。
- `jump late_for_class` 是无条件跳转，"单程票"——执行点移动过去，不再回来。
- `return` 在主流程（`start` 一线）中出现时，结束游戏回到主菜单。
- 一个容易误解的点：**label 本身不是屏障**。某个 label 的语句块执行完后，会继续执行"文件中它后面的下一条语句"，哪怕中间隔着其他 label。上面的例子中，如果删掉 `jump late_for_class`，`e "再睡五分钟……"` 之后就会**直接落入** `late_for_class` 的场景语句继续演。这个"落入"特性是合法且有时有用的，但为了可读性，除非刻意为之，建议每个 label 都以 `jump`、`call` 或 `return` 收尾。

## 5.2 jump 与 call：单程票与往返票

`call` 是"带记忆的跳转"：它记住自己从哪里来，被调用的 label 执行到 `return` 时，控制权交还给调用处的下一条语句。

```renpy
label start:
    scene bg cafe with fade
    "你走进了咖啡馆。"
    call order_drink
    e "（喝了一口）不错，正是想要的。"
    return

label order_drink:
    menu:
        "点什么？"
        "拿铁":
            "你点了一杯拿铁。"
        "美式":
            "你点了一杯美式。"
    return
```

执行轨迹：`start` 演到 `call order_drink` 时进入点单环节；`order_drink` 里的 `return` 把流程送回 `call` 的下一句 `e "（喝了一口）……"`。这就是剧本语言里的"函数调用"：把一段相对独立、可能被多处触发的内容（点单、战斗、小游戏）封装成子流程。

注意上面 `menu:` 下第一行 `"点什么？"`——不带冒号的字符串行是菜单的**提示文本（caption）**，会显示在选项列表上方，可以省略。菜单的完整语法是第 6 章的主题。

## 5.3 call ... from：给返回点起一个稳定的名字

`call` 的隐式返回点是"下一条语句"，引擎内部用位置信息记录它。问题在于：如果你日后在 `call` 后面**插入或删除了语句**，老玩家读档时就可能回到错误的位置。官方给出的解法是给返回点显式命名：

```renpy
call chapter2 from _call_chapter2
```

`from` 后面的名字（惯例是 `_call_标签名`）成为一个固定的返回点标记。`lint` 工具会检查每一个没有 `from` 的 `call` 并提出警告（第 23 章），仓库自带的 `add_from` 命令还能批量补齐。从现在起养成习惯：**所有 `call` 都带 `from`**。

## 5.4 call 带参数与 expression 跳转

label 可以声明参数（含默认值），`call` 时传入：

```renpy
label start:
    call visit("图书馆") from _call_v1
    call visit(area="天台") from _call_v2
    return

label visit(area="教室"):
    scene expression "bg " + area with dissolve
    "你来到了[area]。"
    return
```

要点：

- `label visit(area="教室")` 声明了带默认值的参数，两种传参方式（位置、关键字）都合法。
- `scene expression "bg " + area`：`scene`/`show` 后面跟 `expression` 时，后面是**求值的表达式**而不是图像名——按场景名动态切背景的常用手法。
- `[area]` 是文本插值（第 7 章细讲），把参数值嵌进台词。

当跳转目标存在变量里时，用 expression 形式：

```renpy
default route = "route_school"

label choose_route:
    jump expression route
```

`call expression` 还能用 `pass` 子句传参：

```renpy
call expression "visit" pass ("体育馆")
```

`jump expression`、`call expression` 是做"路线选择表""章节调度器"这类动态流程的基础。

## 5.5 pass：什么都不做的语句

剧本块里不允许空着，"什么都不做"也要明写：

```renpy
menu:
    "沉默不语":
        pass
    "开口询问":
        jump ask
```

## 5.6 while：剧本里唯一的循环

Ren'Py 脚本级**没有** `for`、`continue`、`break`——唯一能直接写的循环是 `while`：

```renpy
default lives = 3

label start:
    while lives > 0:
        "还剩 [lives] 条命。"
        call play_round from _call_round
    "游戏结束。"
    return
```

`while` 条件是任意 Python 表达式，每轮循环都是独立的存档/回滚点——在循环里回滚，会精确退回上一轮的某条语句，不需要你做任何额外处理。

要遍历列表，标准做法是把索引用成计数器：

```renpy
default fruits = ["苹果", "橙子", "葡萄"]
default i = 0

label start:
    while i < len(fruits):
        if i == 1:
            "橙子之后是葡萄。"
        "水果：[fruits[i]]"
        $ i += 1
    return
```

注意一个常见混淆：**`"文本" if 条件` 这种后缀式条件只存在于 `menu` 选项上**，不是通用语句语法。正文流程里做条件判断，必须用块状 `if`（5.4 节的 `jump expression`、本例的 `if i == 1:` 块都是正确形态）。把菜单的条件写法带回正文，是新手最高频的语法错误之一。

## 5.7 特殊 label 一览

引擎保留了一批"入口"标签名，在特定时机自动进入：

| 标签 | 触发时机 |
|---|---|
| `start` | 主菜单点"开始游戏" |
| `splashscreen` | 启动器载入、主菜单出现之前 |
| `before_main_menu` | 主菜单显示之前（仍在新 context 中） |
| `main_menu` | 顶替默认主菜单 |
| `after_load` | 读档完成后 |
| `quit` | 退出流程 |

它们的用法与注意事项（context 隔离、`return` 的去向）集中在第 21 章讲解，这里先建立印象。

## 5.8 小结与实践

- `label` 全局可见、可跨文件；块尾会"落入"后续语句，收尾语句要明确；
- `jump` 不回头，`call`+`return` 是往返，**`call` 必带 `from`**；
- 动态目标用 `call/jump expression`，带参调用用 `pass` 子句；
- 循环只有 `while`，索引计数器代替 `for`；
- 本章的示例工程 `03_labels_and_flow` 演示了上述全部语法。

---

上一章：[04 图像与舞台](ch04-images-and-stage.md) · 下一章：[06 菜单、变量与分支](ch06-menus-and-variables.md)
