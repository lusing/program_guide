# 第 14 章 Screen 动作与数据绑定

> [← 第 13 章 Screen 语言基础](ch13-screen-basics.md) ｜ [目录](index.md) ｜ [第 15 章 特殊屏幕与菜单定制 →](ch15-special-screens.md)

上一章我们学会了"搭界面"——容器、定位、显示物、屏幕作用域。但一个没有按钮的界面只是风景画，这一章要让界面"动"起来。核心概念只有一个词：**action（动作）**。

## 14.1 action 是按钮的灵魂：三态模型

把一个按钮交给 Ren'Py，引擎每次重算界面时都会问它三个问题：

- **敏感吗（sensitive）**——现在能不能点？不能点就显示成灰的，点了也没反应；
- **选中吗（selected）**——按钮当前是否处于"生效"状态？选中的按钮会高亮，用来表达单选、复选、开关；
- **做什么（action）**——被点击时执行什么。

这三个问题的答案，全部来自按钮的 `action` 属性。**没有 action 的按钮永远不敏感**——你可以给它配置任何样式，它就是一块不会响应的石头。这是初学者最常撞上的墙，先把结论钉在这里：

```renpy
# 这样写，按钮永远点不动：
textbutton "点我"          # 没有 action，永远不敏感

# 这样才是一个活按钮：
textbutton "点我" action Jump("next_scene")
```

一个 action 本质上是一个对象。Ren'Py 内置了上百个 action 类，覆盖流程控制、界面切换、数据修改、文件存读档等场景。这些内置 action 还不够用时，你可以自己写一个——只要继承 `Action` 基类，实现几个约定方法即可：

- `__call__(self)`：点击时执行（**必写**）；
- `get_sensitive(self)`：返回 True/False 决定敏感态（不写则永远敏感）；
- `get_selected(self)`：返回 True/False 决定选中态（不写则永远不选中）;
- `get_tooltip(self)`：返回悬浮提示文本（不写则没有提示）。

引擎在每次界面重算时都会来询问 `get_sensitive` 和 `get_selected`，所以你不用做任何"刷新"工作——条件一变，按钮自动变灰或点亮。下面写一个自定义 action 感受一下：营地里的一张床，体力没满时可以睡，睡满就自动变灰。

```renpy
default hp = 30
default hp_max = 100

init python:

    class Heal(Action):
        """点击后回复全部体力；体力已满时按钮自动变灰。"""

        def __init__(self, amount):
            self.amount = amount

        def __call__(self):
            store.hp = min(store.hp + self.amount, store.hp_max)
            renpy.notify("体力回复了！")

        def get_sensitive(self):
            return store.hp < store.hp_max

        def get_selected(self):
            return False

        def get_tooltip(self):
            return "回复 {} 点体力".format(self.amount)

screen campfire():
    frame:
        xalign 0.5 yalign 0.5
        vbox:
            spacing 8
            text "体力 [hp] / [hp_max]"
            textbutton "安眠" action Heal(40)
```

逐条拆解这段代码的机关：

- `class Heal(Action)` 必须写在 `init python:` 块里，游戏启动时类就定义好了；`Action` 基类由 Ren'Py 提供，不需要 import；
- `__init__` 接收 `amount` 并存到实例上——这样 `Heal(40)` 和 `Heal(10)` 可以是两个不同的按钮、不同的回复量；
- `__call__` 里用的是 `store.hp` 而不是直接写 `hp`。原因：这个方法定义在 `init python:` 块中，执行时机是"玩家点击的那一刻"，而 `hp` 是剧本用 `default` 声明的**存档变量**，存在于 Ren'Py 的 store 命名空间里。用 `store.` 前缀访问最直白，也最容易读对（它同时也是回滚和存档感知的正规入口，第 16 章细讲）；`renpy.notify()` 则会调用第 15 章要讲的 notify 通知屏幕，弹一条两秒左右的消息；
- `get_sensitive` 返回 `store.hp < store.hp_max`：每次界面重算（包括点击任何按钮之后）引擎都会重新询问这个方法。所以当 `hp` 回满的一瞬间，按钮**自己**变成灰色——你没有写过任何一行"刷新按钮状态"的代码；
- `get_tooltip` 返回一句提示，鼠标悬停时显示（与 14.9 的 tooltip 系统配合）。

`renpy.notify` 的官方行为是：弹出默认的 notify 屏幕，消息溶解进场、停留约两秒、溶解离场。它是给"点了按钮但屏幕上没别的反馈"的场合补一条轻量提示用的，后面章节会反复用到它。

## 14.2 流程动作：让按钮指挥剧本

第一类内置 action 管游戏流程——跳转、调用、返回、开新游戏、回主菜单、退出。这些是按钮最常用的"干什么"，签名与用途如下：

| 动作 | 作用 |
| --- | --- |
| `Start()` | 从主菜单开始新游戏（跳到 `start` 标签） |
| `Jump(label)` | 跳转到剧本标签，不回头 |
| `Call(label)` | 调用剧本标签，之后可以 `return` 回来 |
| `Return(value)` | 结束当前 `call`/`call screen`，值存入 `_return` |
| `ShowMenu(screen)` | 打开游戏内菜单页（存档、读档、偏好等） |
| `MainMenu()` | 回到主菜单（带确认对话框） |
| `Quit(confirm=True)` | 退出游戏；`confirm=True` 时先弹确认框 |

这些动作没有难用的，难点在"什么时候用哪个"。下面照着官方模板 `navigation` 屏幕的骨架，写一个迷你导航栏，把最常用的几个串起来。模板里有一行 `if main_menu:`——`main_menu` 不是普通变量，而是 Ren'Py **自动维护**的内置全局变量：处在主菜单时为 True，进入游戏后为 False。所以同一块屏幕代码能同时服务主菜单和游戏内菜单：

```renpy
screen mini_nav():
    vbox:
        spacing 6
        if main_menu:
            textbutton "开始游戏" action Start()
        else:
            textbutton "存档" action ShowMenu("save")
            textbutton "读档" action ShowMenu("load")
            textbutton "偏好设置" action ShowMenu("preferences")
            textbutton "主菜单" action MainMenu()
        textbutton "退出" action Quit(confirm=not main_menu)
```

几个值得咀嚼的细节：

- `if main_menu:` 分支里只有 `Start()`——在主菜单当然没有"存档"可点；进了游戏换成菜单页入口。这就是模板导航栏的原始思路：**一块屏幕，两种语境**；
- `Quit(confirm=not main_menu)`：从游戏里退出丢进度，所以要确认；从主菜单退出没损失，`confirm=False` 直接走。一个表达式把两种情况都照顾到了；
- `ShowMenu("save")` 的参数就是第 15 章要讲的特殊屏幕名。`ShowMenu` 会套上游戏菜单的框架（标题、返回键），和 `Show` 的"裸显示"不同。

关于 `Return(value)`：它在 `call screen` 场景里是绝对主角——上一章的 `yes_no` 屏幕就靠它传回 True/False。规则很简单：`Return(True)` 把 True 交给 `_return`，然后剧本从 `call screen` 的下一行继续。

## 14.3 场景动作：Show / Hide / ShowTransient

第二类 action 管屏幕的挂载与摘除，就是上一章 `show screen` / `hide screen` 语句的动作版：

| 动作 | 作用 |
| --- | --- |
| `Show(screen, *args, **kwargs)` | 挂载一个屏幕，参数原样传给屏幕；同名屏幕已在则只刷新 |
| `ShowTransient(screen, ...)` | 挂载一个屏幕，但下次交互结束后自动移除 |
| `Hide(screen=None)` | 摘除屏幕；不给名字就摘除当前层的屏幕 |
| `ShowMenu(screen)` | 以"游戏菜单"方式挂载（带菜单框架、Esc 可返回） |

`Show` 最实用的地方是**可以带参数**——屏幕的参数和 `default` 一起构成屏幕作用域，动作这边一传参，屏幕那边就能拿到。写一个侧边面板的例子：同一块面板屏幕，用不同参数打开两次，展示出不同的标题。

```renpy
screen side_panel(title):
    frame:
        xpos 30 ypos 30
        vbox:
            spacing 8
            text title
            textbutton "关闭" action Hide("side_panel")

screen side_panel_demo():
    vbox:
        xalign 0.9 yalign 0.1
        textbutton "打开任务面板" action Show("side_panel", title="任务列表")
        textbutton "打开物品面板" action Show("side_panel", title="物品栏")
```

注意 `Show("side_panel", title="任务列表")`——`title` 是关键字参数，直接进入屏幕作用域，屏幕里的 `text title` 就显示它。两个按钮共用一块面板代码，只是数据不同：这就是"动作传参 + 屏幕参数"的组合拳。

`Hide("side_panel")` 里的名字必须与屏幕名一致（字符串）。这里故意用动作而不是上一章的 `hide screen` 语句，因为这个"关闭"按钮在屏幕自己内部——屏幕不能在剧本语句里摘除自己，动作才可以。

`Show` 与 `ShowTransient` 的差别用一句话记：`Show` 的屏幕会一直挂着直到你 `Hide`；`ShowTransient` 的屏幕在一次交互结束后自动消失，适合"临时提示框"。

## 14.4 数据动作：一行改一个变量

第三类 action 专门改数据，是"选项按钮""开关按钮"的原材料。Ren'Py 用一套小机制批量生成它们：**5 种访问器 × 4 种操作 = 20 个动作类**。

5 种访问器决定"改哪儿的数据"：

| 访问器 | 数据位置 | 例子 |
| --- | --- | --- |
| `Variable` | store 里的全局变量 | `SetVariable("gold", 100)` |
| `Field` | 对象的字段 | `SetField(player, "hp", 100)` |
| `Dict` | 字典的键 | `SetDict(stats, "mp", 50)` |
| `ScreenVariable` | 当前屏幕作用域的变量 | `SetScreenVariable("clicks", 0)` |
| `LocalVariable` | use 内联屏幕的局部变量 | `SetLocalVariable("tries", 0)` |

4 种操作决定"怎么改"：

| 操作 | 语义 |
| --- | --- |
| `Set` | 直接设为给定值 |
| `Toggle` | 在两个值之间切换（默认 True/False） |
| `Cycle` | 按给定列表循环取值 |
| `Increment` | 加上给定数值（默认 +1） |

两者的名字直接拼接，就得到全部 20 个：`SetVariable`、`ToggleVariable`、`CycleVariable`、`IncrementVariable`、`SetField`、`ToggleField`、`CycleField`、`IncrementField`、`SetDict`、`ToggleDict`、`CycleDict`、`IncrementDict`、`SetScreenVariable`、`ToggleScreenVariable`、`CycleScreenVariable`、`IncrementScreenVariable`、`SetLocalVariable`、`ToggleLocalVariable`、`CycleLocalVariable`、`IncrementLocalVariable`。

最妙的是，**数据动作自带选中态**：`Set` 类动作在"目标变量已经等于目标值"时自动选中。你不用写任何高亮逻辑，单选组就免费得到了。看这个三档难度选择：

```renpy
default difficulty = "normal"

screen difficulty_pick():
    vbox:
        spacing 6
        text "选择难度："
        textbutton "轻松" action SetVariable("difficulty", "easy")
        textbutton "普通" action SetVariable("difficulty", "normal")
        textbutton "困难" action SetVariable("difficulty", "hard")
```

运行后你会发现：点"困难"，它亮，另外两个灭；`difficulty` 被改成 "hard"。三个按钮谁该亮，引擎通过询问每个 `SetVariable` 动作"你的目标值和当前值相等吗"自动判定——**数据即高亮**。第 13 章讲过的"声明式"哲学，在动作层面再次兑现。

`Toggle` 系则负责开关类按钮。默认在 True/False 间切换，也可以指定两端的值：

```renpy
default sound_on = True

screen sound_switch():
    textbutton "音效：开关" action ToggleVariable("sound_on")
```

`Cycle` 系做"每按一次换下一档"：`CycleVariable("weather", ["晴", "雨", "雪"])` 三按一个轮回。`Increment` 系做计数器：`IncrementVariable("gold", -10)` 就是花 10 金币。

还有三个处理集合的动作，专管"多选"场景：

```renpy
default likes = set()

screen hobby_picker():
    vbox:
        spacing 6
        text "你的爱好（可多选）："
        textbutton "猫" action ToggleSetMembership("likes", "猫")
        textbutton "狗" action ToggleSetMembership("likes", "狗")
        textbutton "鸟" action ToggleSetMembership("likes", "鸟")
```

- `AddToSet(set_name, value)`：把 value 加进集合（若集合变量是 list 则 append 到尾部）；
- `RemoveFromSet(set_name, value)`：从集合移除；
- `ToggleSetMembership(set_name, value)`：有则移除、无则加入，并且**当 value 是集合成员时按钮自动选中**——天然的多选按钮。

注意第一个参数是**存集合的变量名（字符串）**，第二个才是值。

最后一个易混淆点必须掰开讲：`SetScreenVariable` 与 `SetVariable` 只差一个词，作用域却天差地别。`SetVariable` 改的是 store 里的全局变量，**会进存档**；`SetScreenVariable` 改的是当前屏幕作用域里的变量（由屏幕内 `default` 声明），屏幕一关就没了。下面的对照屏幕把两条路并排放着：

```renpy
default global_clicks = 0

screen counter_pair():
    default clicks = 0

    vbox:
        spacing 6
        textbutton "屏幕内计数 [clicks]" action IncrementScreenVariable("clicks")
        textbutton "全局计数 [global_clicks]" action IncrementVariable("global_clicks")
```

点几下"屏幕内计数"，数字涨；关掉屏幕再开，数字归零——它只活在屏幕里。而"全局计数"会跨屏幕存活、进存档。选择器就一条：**跟着存档走的数据用 `SetVariable`，屏幕自己的临时状态用 `SetScreenVariable`**。

## 14.5 Function 动作：点击时执行任意 Python 函数

前面 20 个数据动作都是"改一个变量"这种小刀。真要做多步逻辑——扣钱、加物品、弹提示、写标记——就需要 `Function` 动作，它可以包装**任意 Python 函数**：

```renpy
Function(函数, 位置参数..., 关键字参数...)
```

规则有三条，每条都是考点：

1. **点击时才执行**：包在 `Function` 里的函数，在玩家点击按钮的那一刻运行，而不是界面构建时；
2. **返回值有意义**：函数返回 `None`，交互继续；返回非 `None`，当前交互结束，返回值存入 `_return`——这让 `Function` 也能在 `call screen` 里充当"复杂版的 Return"；
3. **执行完自动刷新界面**：函数返回后 Ren'Py 默认重算所有屏幕（可用 `_update_screens=False` 关掉），所以函数里改了变量，界面上的插值文本立即更新。

写一个完整的药水腰带：

```renpy
default hp = 50
default hp_max = 100
default potions = 3

init python:

    def drink_potion(amount=20):
        store.hp = min(store.hp + amount, store.hp_max)
        store.potions -= 1
        renpy.notify("回血了！还剩 {} 瓶。".format(store.potions))

screen potion_belt():
    vbox:
        spacing 6
        text "体力 [hp]/[hp_max]　药水 [potions] 瓶"
        textbutton "喝一瓶" action Function(drink_potion, 20) sensitive (potions > 0)
```

逐条讲：

- `Function(drink_potion, 20)`：点击时以参数 20 调用 `drink_potion`。注意写的是**函数名本身**，没有括号——`Function(drink_potion())` 是初学者头号错误，那样写会在构建按钮时就执行函数，按钮上挂的是它的返回值（None），点了什么都不会发生；
- `sensitive (potions > 0)`：这是**按钮属性**（14.1 讲过 action 自带三态，但按钮自身也接受 `sensitive` 属性做额外限制）。药水喝光时按钮变灰，防止 `potions` 减成负数；
- 函数体里的三件事——改 `hp`、减 `potions`、发通知——之后界面上的"体力 [hp]"和"药水 [potions]"插值文本**立刻**更新，因为 Function 动作执行完默认重算屏幕。

**`$` 与 `Function` 的世纪误解**必须单独辟一节讲清楚。剧本里的 `$` 语句是"执行到这里就立刻运行"；screen 语言里的 `$` 同样如此——**每次屏幕重算都会执行一遍**，与点击毫无关系。如果你把"点按钮要做的事"写成 screen 里的 `$`：

```renpy
# 错误示范！不要这样写！
screen broken():
    $ hp += 20          # 这行在屏幕每次重算时都执行——
                        # 界面上任何风吹草动都会让你白涨 20 点体力
    textbutton "喝药水" action ???    # 根本没有可挂的动作
```

后果是灾难性的：你以为"点按钮才加血"，实际上屏幕因为滚动、悬停、任何变量变化而重算时，`hp` 就被偷偷加 20。**结论**：screen 里该在"点击时"执行的逻辑，一律装进函数、挂到 `Function` 动作上；screen 里的 `$` 只用于准备工作（比如上面示例里的 `$ slot = i + 1` 那种给循环用的局部计算）。

## 14.6 存读档动作：自建一个存档界面

Ren'Py 的存档系统有一套页-槽结构：**9 个普通页**（第 1 到第 9 页）加上**自动存档页**（auto）和**快速存档页**（quick），每页若干槽位。动作族围绕两个坐标工作——`page`（哪一页）和 `name`（页内第几槽）。常用动作如下：

| 动作 | 作用 |
| --- | --- |
| `FileSave(name, confirm=True, newest=True, page=None)` | 存档到当前页第 `name` 槽；覆盖已有档时弹确认 |
| `FileLoad(name, confirm=True, page=None)` | 读档；会弹确认防误触 |
| `FileDelete(name, confirm=True, page=None)` | 删除该槽存档 |
| `FileAction(name, ...)` | 聪明档：槽内有档就读，没档就存（存读共用界面时用） |
| `FilePage(page)` | 切换到某一页（数字 1-9 或 "auto"/"quick"） |
| `FilePageNext(max=None)` / `FilePagePrevious(...)` | 下一页 / 上一页 |
| `FileScreenshot(name, empty=None, page=None)` | 取该槽的截图显示物（空槽显示 empty 内容） |
| `FileTime(name, empty="", ...)` | 取该槽的存档时间文本 |
| `FileSaveName(name, empty="", ...)` | 取该槽存档时的角色名 |
| `FileSlotName(slot, slots_per_page)` | 把"页内槽号"换算成全局槽名（如 "1-3"） |
| `QuickSave()` / `QuickLoad()` | 快速存/读档（存在 quick 页固定槽） |

配套的 `FileTakeScreenshot()` 负责截图，`FileJson(name)` 能读出存档的元数据（版本号等）。这些函数的名字参数都指**页内槽号**，从 1 开始；而 `FileSlotName` 把页内槽号换算成"第几页-第几槽"的全局名，专门用来**显示**。

官方模板的存读档屏幕（`file_slots`）就是用这组动作拼的。现在我们从零自建一个 6 槽迷你存档屏，把主要动作都串进去：

```renpy
screen simple_save():
    modal True
    frame:
        xalign 0.5 yalign 0.5
        vbox:
            spacing 10
            text "存档"
            hbox:
                spacing 10
                textbutton "上一页" action FilePagePrevious()
                textbutton "下一页" action FilePageNext(max=9)
            grid 2 3:
                spacing 10
                for i in range(1, 7):
                    button:
                        action FileSave(i)
                        key "save_delete" action FileDelete(i)
                        xysize (300, 100)
                        vbox:
                            spacing 2
                            text FileSlotName(i, 6)
                            text FileTime(i, empty="空槽位") size 16
                            text FileSaveName(i, empty="") size 16
            textbutton "关闭" action Return()
```

在剧本里用 `call screen simple_save` 打开它。逐块拆解：

- `for i in range(1, 7)` 造出 6 个槽位按钮，`$` 都不需要——`i` 直接就是页内槽号；
- `button:` 是裸按钮（相比 textbutton 能自由装内容），里面塞一个 vbox 排三行文字；
- `action FileSave(i)`：把当前游戏存到**当前页**的第 `i` 槽。若槽上已有存档，`confirm=True` 的默认值会先弹确认框；
- `key "save_delete" action FileDelete(i)`：键盘映射——官方模板约定 `save_delete` 键（默认是 Delete），聚焦某槽时按删除键即可删档。把这个约定搬进自定义界面，老玩家会感谢你；
- `text FileSlotName(i, 6)`：显示全局槽名。当前在第 1 页时，六个槽显示 "1-1" 到 "1-6"；翻到第 2 页就变成 "2-1" 到 "2-6"。页面和槽位的关系一目了然；
- `text FileTime(i, empty="空槽位")`：有档显示存档时间，无档显示"空槽位"——`FileTime`/`FileSaveName`/`FileScreenshot` 这类"查询"动作都接受 `empty` 参数兜底；
- `FilePagePrevious()` / `FilePageNext(max=9)`：翻页。`max=9` 限制普通页最多到第 9 页（auto/quick 页由专门入口进，这里不展开）。

把这个屏幕想成官方 `file_slots` 的"素描版"：官方版多出来的只是截图缩略图（`add FileScreenshot(slot)`）、页码按钮行和输入页名的输入框——材料完全是同一套动作。读档界面只需把 `FileSave(i)` 换成 `FileLoad(i)`（或者用 `FileAction(i)`，让"点击空槽存档、点击有档槽读档"自动二合一）。

顺带交代一个日常玩家最熟悉的功能：快速存读档。给任意按钮挂上 `QuickSave()` / `QuickLoad()`，或者剧本里需要时直接调用引擎函数，就能得到"一键存、一键读"的体验——底层就是往 quick 页的固定槽里存读。

## 14.7 Preference 动作：接住玩家的偏好设置

第五类 action 读写 Ren'Py 内建的**玩家偏好**——音量、文字速度、跳过设置、窗口模式。它们自动存入持久化数据（第 17 章），游戏重启也记得住，你一行保存代码都不用写。

`Preference` 有两种用法，取决于你把它挂在哪里：

- 挂在按钮的 `action` 上：`Preference(名称, 值)`——点击时设置或切换某项偏好；
- 挂在 bar 的 `value` 上：`bar value Preference("music volume")`——拖动条实时调节数值型偏好。

官方模板的偏好设置屏幕用到的全部名称，按用法整理成表（这 11 个覆盖了绝大多数游戏的需求）：

| 名称 | 用法 | 说明 |
| --- | --- | --- |
| `"display"` | action | 显示模式切换；第二参数可指定 `"window"` / `"fullscreen"` / `"toggle"` |
| `"skip"` | 切换动作 | 是否跳过已读文本 |
| `"after choices"` | 切换动作 | 遇到菜单选项时是否暂停（不自动跳过） |
| `"transitions"` | 切换动作 | 跳过转场开关 |
| `"text speed"` | bar value | 文字逐字出现的速度 |
| `"auto-forward time"` | bar value | 自动播放时每句的停顿时长 |
| `"music volume"` | bar value | 音乐通道音量 |
| `"sound volume"` | bar value | 音效通道音量 |
| `"voice volume"` | bar value | 语音通道音量 |
| `"all mute"` | 切换动作 | 全部静音 |
| `"auto-forward"` | 切换动作 | 自动播放开关 |

拼一个游戏内随时可唤出的"快速设置"面板，两种用法各就各位：

```renpy
screen quick_prefs():
    frame:
        xalign 0.5 yalign 0.5
        vbox:
            spacing 8
            text "快速设置"
            hbox:
                spacing 8
                text "音乐音量" yalign 0.5
                bar value Preference("music volume") xsize 400 yalign 0.5
            hbox:
                spacing 8
                text "音效音量" yalign 0.5
                bar value Preference("sound volume") xsize 400 yalign 0.5
            hbox:
                spacing 8
                text "文字速度" yalign 0.5
                bar value Preference("text speed") xsize 400 yalign 0.5
            textbutton "自动播放" action Preference("auto-forward", "toggle")
            textbutton "跳过已读文本" action Preference("skip", "toggle")
            textbutton "全部静音" action Preference("all mute", "toggle")
```

机制上没有新东西，全是老朋友的变体：

- `bar value Preference("music volume")` 是**双向绑定**：拖动条即改音量，玩家从系统菜单改了音量，条也会跟着走。第 13 章的 `VariableValue` 绑定自定义变量、这一节的 `Preference` 绑定内建偏好——两者遵守同一套 bar value 协议，学会了就通吃；
- `Preference("auto-forward", "toggle")` 这类切换动作**自带选中态**：自动播放开着时按钮亮，和 14.4 的 Toggle 系一个脾气；
- 第二参数 `"toggle"` 表示切换；对 `"display"` 这类多态偏好，也可以写死一个目标值，比如 `Preference("display", "fullscreen")` 一键全屏。

## 14.8 动作修饰器：SelectedIf、SensitiveIf、InvertSelected

按钮挂**单个**动作时，三态由它自己说了算；挂**一组**动作时，麻烦来了——选中态和敏感态该听谁的？Ren'Py 提供三个修饰器，把决定权精确交给列表中的某一个。

**SelectedIf**：包住一个动作，让它的选中态代表整个按钮，点击时动作照常执行。官方文档的原始例子是"前往火星"按钮：点击要同时记录旗标并跳场景，但又想让按钮在旗标已亮时保持高亮：

```renpy
textbutton "前往火星基地":
    action [ SelectedIf(SetVariable("mars_flag", True)), SetVariable("on_mars", True) ]
```

读法：动作列表里第一个是 `SelectedIf` 包住的 `SetVariable`——按钮**是否选中**由它决定（`mars_flag` 为 True 时亮），**点击时**两个动作都照常执行。`SensitiveIf` 与它是一对，唯一区别是决定的是**敏感态**。这两个修饰器只在动作列表里有意义；单动作按钮要控制三态，直接用 action 自带机制或按钮的 `sensitive` 属性（14.5 的药水按钮那样）更直白。

**InvertSelected**：反转一个动作的选中态，其余（点击行为、敏感态）原样代理。它解决的是"动作语义与按钮文案相反"的别扭场景。官方模板的跳过设置页里就有活例子：

```renpy
label _("Skip")
textbutton _("Unseen Text") action Preference("skip", "toggle")
textbutton _("After Choices") action Preference("after choices", "toggle")
textbutton _("Transitions") action InvertSelected(Preference("transitions", "toggle"))
```

第三行的逻辑值得细品：`Preference("transitions", "toggle")` 的语义是**"跳过转场"**开关，开启时动作处于选中态。但这行按钮的文字是"Transitions（转场）"，玩家会把亮着理解为"要播放转场"。于是模板给动作套上 `InvertSelected`——开关内部还是那个开关，只是**指示灯接反了**：跳过转场关闭（即播放转场）时按钮亮。前两行按钮的文案与动作语义一致，就不用套。读模板代码时看到 `InvertSelected`，先问一句"这个开关的默认语义和按钮文案是不是反的"，多半就通了。

## 14.9 悬浮提示：tooltip 属性与 GetTooltip

桌面玩家把鼠标悬在按钮上时，游戏有义务告诉他"这个按钮是干嘛的"。Ren'Py 的提示系统由两个零件组成：

1. 给任何可悬停的显示物（textbutton、imagebutton、hbox……）加 `tooltip` 属性，值是提示文本；
2. 在屏幕的某个固定位置用 `text GetTooltip()` 展示"当前悬停的提示"。

```renpy
screen item_bag():
    frame:
        xalign 0.5 yalign 0.5
        vbox:
            spacing 6
            hbox:
                spacing 12
                textbutton "长剑" tooltip "攻击 +10，剑刃易碎。"
                textbutton "药水" tooltip "回复 20 点体力。"
                textbutton "护符" tooltip "防御 +5，来历不明。"
            null height 6
            text (GetTooltip() or "把鼠标放到物品上试试") xsize 420
```

运行它：鼠标移到"长剑"上，底部那行字变成"攻击 +10，剑刃易碎。"；移开，又回到兜底文案。机制拆开看：

- `tooltip "..."`：悬停时把这段文本注册为"当前提示"，移开自动注销——**没有计时器、没有 hovered 事件代码**，一切由引擎代劳；
- `GetTooltip()`：取回当前提示文本；什么都没悬停时返回 None，所以用 `or` 给个兜底文案。它和 `tooltip` 属性是同一枚硬币的两面：属性负责"注册"，函数负责"展示"。

`GetTooltip` 还有两个进阶参数：`screen="屏幕名"` 可以跨屏幕取提示——比如 HUD 挂着物品栏屏幕，主屏幕想共享同一块提示展示区；`last=True` 取**最近一次**显示过的提示，专治"屏幕重算导致悬停状态瞬间丢失、提示闪一下就没了"的毛病。

顺带一提：早期版本的文档还有一种基于 `Tooltip` 类的提示写法，功能与属性式重叠，新代码用 `tooltip` 属性加 `GetTooltip()` 这套组合就好。

## 14.10 综合实战：道具商店

把本章的家伙什全用上——`Function` 处理买卖逻辑、`sensitive` 控制余额、`tooltip` 展示商品详情、`if`/`for` 让货架和背包随数据生长。目标是一个乡村商店：左边货架三件商品（钱不够自动置灰、悬停看说明），右边背包实时更新（每件物品一个"使用"按钮），点"离开商店"回到剧情。

```renpy
default gold = 120
default backpack = []

define shop_goods = [
    {"name": "长剑", "price": 80, "tip": "攻击 +10，剑刃易碎。"},
    {"name": "药水", "price": 30, "tip": "回复 20 点体力。"},
    {"name": "护符", "price": 150, "tip": "防御 +5，来历不明。"},
]

init python:

    def buy(item):
        store.gold -= item["price"]
        store.backpack.append(item["name"])
        renpy.notify("买下了{}。".format(item["name"]))

    def use_item(name):
        store.backpack.remove(name)
        renpy.notify("使用了{}。".format(name))

screen item_shop():
    modal True
    frame:
        xalign 0.5 yalign 0.5
        vbox:
            spacing 8
            text "商店　金币 [gold]"
            hbox:
                spacing 24
                vbox:
                    spacing 4
                    text "货架"
                    for item in shop_goods:
                        textbutton "{}（{} 金）".format(item["name"], item["price"]):
                            tooltip item["tip"]
                            sensitive (gold >= item["price"])
                            action Function(buy, item)
                vbox:
                    spacing 4
                    text "背包"
                    if backpack:
                        $ inv = "、".join(backpack)
                        text "[inv]" xsize 300
                        for name in backpack:
                            textbutton "使用 {}".format(name):
                                action Function(use_item, name)
                    else:
                        text "空空如也。"
            null height 4
            text (GetTooltip() or "把鼠标放到商品上看看详情。") size 18
            textbutton "离开商店" action Return()
```

剧本侧只需要 `call screen`：

```renpy
label shop_demo:
    scene black with dissolve
    "村口的老商人掀开推车上的油布。"
    call screen item_shop
    "你合上背包，向老商人道别。"
    return
```

逐条拆解设计决策：

- `shop_goods` 用 **define** 而不是 default：它是纯静态数据（商品目录），不随游戏进度变化，也不该进存档；`gold` 和 `backpack` 用 **default**：它们是玩家状态，必须跟着存档走。define 管不变的数据，default 管会变的状态——这条分界线第 6 章画过，这里是它在实战中的位置；
- `buy(item)` 收到的是**整个商品字典**：`Function(buy, item)` 把循环变量 `item` 原样传给函数，函数里取 `item["price"]`、`item["name"]`。screen 的 for 每次重算都会重建按钮和动作，所以每个按钮挂着的都是自己那件商品的数据，不会串；
- `sensitive (gold >= item["price"])`：余额不足的按钮自动变灰。之后无论打怪掉钱还是买了别的东西，灰与不灰都由引擎重算——你还是一行刷新代码都没写；
- `tooltip item["tip"]`：商品说明悬停即见，展示区就是底部那行 `GetTooltip()`。商品数据、按钮文案、提示文本同源（都来自 `shop_goods`），不会出现"按钮上叫长剑、提示里说法杖"的失配；
- `if backpack: ... else: ...`：背包空时显示提示；`$ inv = "、".join(backpack)` 把列表拼成一句话——这是 screen 里 `$` 的**正当用途**（给插值做准备工作），和 14.5 痛批的"用 $ 写点击逻辑"是两回事；
- `for name in backpack` 给每件物品生成一个"使用"按钮：买两瓶药水就有两行"使用 药水"，点掉一行背包少一瓶——声明式界面的自动生长与收缩；
- `modal True`：商店开着时挡住下层剧情界面的点击，玩家不会隔着商店误点对话；
- `Return()` 结束 `call screen`，`_return` 里是 None——本例不需要返回值，但如果你想要"离开时带走账单"，把 `Return()` 换成 `Return(backpack)` 即可在剧本里拿到。

一个值得体会的设计权衡：这个商店**没有用任何数据动作**。买药水不是 `ToggleSetMembership`，因为买卖带价格校验和两处数据变更（扣钱+进包），是复合逻辑——这正是"数据动作做单点修改、`Function` 做复合逻辑"的分界。如果哪天需求简化成"免费试吃、爱吃哪个点哪个"，`ToggleSetMembership("tasted", item["name"])` 一行就能替掉整个 `buy` 函数。

## 14.11 小结与实践

- action 是按钮的灵魂，三态模型：**敏感**（可点）、**选中**（高亮）、**动作**（点击行为）；没有 action 的按钮永远不敏感；
- 自定义 action：`init python:` 里继承 `Action`，必写 `__call__`，按需写 `get_sensitive`/`get_selected`/`get_tooltip`；引擎每次重算时自动询问，条件一变按钮状态自动更新；
- 流程动作 `Start`/`Jump`/`Call`/`Return`/`ShowMenu`/`MainMenu`/`Quit`；`main_menu` 是引擎自动维护的内置变量；
- 场景动作 `Show`（可带参数进屏幕作用域）、`ShowTransient`（交互结束自动消失）、`Hide`；
- 数据动作 = 5 种访问器 × 4 种操作共 20 个，`Set` 系自带选中态，集合三兄弟管多选；`SetVariable`（进存档）与 `SetScreenVariable`（随屏幕生灭）的作用域之分；
- `Function` 动作点击时执行、返回非 None 则结束交互、执行后自动刷新屏幕；screen 里的 `$` 是**重算时执行**——两者千万别混；
- 文件动作按"页-槽"组织，`FileSave`/`FileLoad`/`FileDelete`/`FilePage` 做事，`FileSlotName`/`FileTime`/`FileSaveName`/`FileScreenshot` 查询展示，`QuickSave`/`QuickLoad` 一键存读；
- `Preference` 两种用法：按钮上切设置、bar value 上拖数值，全部自动持久化；
- `SelectedIf`/`SensitiveIf` 把三态决定权交给动作列表中的指定成员，`InvertSelected` 反转指示灯；
- `tooltip` 属性注册提示，`GetTooltip()` 展示提示；
- 示例工程 `12_actions` 实现了 14.6 的迷你存档屏与 14.10 的道具商店。

---

> [← 第 13 章 Screen 语言基础](ch13-screen-basics.md) ｜ [目录](index.md) ｜ [第 15 章 特殊屏幕与菜单定制 →](ch15-special-screens.md)
