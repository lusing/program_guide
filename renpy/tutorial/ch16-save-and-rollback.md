# 第 16 章 变量、存档与回滚

前四个部分教你怎么“演”，这一章开始教你怎么“记”。状态（state）是游戏区别于幻灯片的本质：玩家的每一次选择、每一点好感度变化、每一张已解锁的 CG，都是状态。Ren'Py 用三套机制管理状态——**store 变量**（一局游戏内的记忆）、**存档**（跨次启动的记忆）、**回滚**（向回走的记忆）——再加上下一章的 **persistent**（跨周目的记忆）。四套机制的边界与配合，就是本章的全部内容。

第 6.5 节给过一张“三种赋值，三种命运”的表，当时承诺的“别名陷阱”与底层原理，在本章兑现。我们会像上一章拆模板屏幕那样，直接拆引擎源码——Ren'Py 的存档与回滚机制是公开的 Python 代码，讲清楚它们不需要猜。

## 16.1 变量的家：store 命名空间

你在剧本里写的 `default affection = 0`、`$ gold += 10`，这些变量住在哪？答案是 **store**：Ren'Py 的全局命名空间，本质上一个 Python 模块（`renpy.store`）。剧本语言与 Python 在这里是同一个世界：

```renpy
default affection = 0

label start:
    $ affection += 1
    python:
        affection += 1
        bonus = affection * 2
    e "好感度 [affection]，加成 [bonus]。"
```

`$` 语句、`python:` 块、剧本变量完全互通——都在 store 里。但有两个地方“隔着一条街”，需要显式过桥：

**第一，`init python:` 块**。初始化阶段执行的代码不在“游戏进行时”，但 store 还是那个 store，只是访问逻辑值要过桥：

```renpy
define MAX_AFFECTION = 100

init python:
    # 这里的变量若想给剧本用，直接赋值即可（初始化阶段赋的值不进存档）
    CHEAT_ENABLED = False
```

初始化阶段赋的变量游戏里直接可用。真正要过桥的场景是**函数内部**：

```renpy
init python:
    def add_affection(n):
        # 函数里的赋值默认是局部变量，改游戏变量必须声明命名空间
        store.affection += n

init python:
    def get_affection():
        # 读取不用声明也能读到（Python 作用域规则），但写入必须 store.
        return affection
```

规则一句话：**函数里读全局变量可以直接读，写必须写 `store.变量名`**。这不是 Ren'Py 的怪癖，而是 Python 的作用域规则——Ren'Py 只是把 store 暴露成了一个模块。第 14 章的 `buy`、`use_item` 函数已经在用这个写法。

**第二，屏幕作用域**。屏幕里 `$` 与 `default` 造出的是**屏幕局部变量**，与 store 同名变量互不相通（第 13 章讲过）。屏幕里想读写游戏变量，也是 `store.affection`——第 14 章的 `difficulty_pick` 里 `SetVariable` 内部就是这么干的。

**自定义命名空间**：当常量越积越多，可以把它们收进独立命名空间，避免污染 store：

```renpy
python early in items_data:
    ITEMS = {
        "potion": {"name": "治疗药水", "price": 30},
        "sword":  {"name": "铁剑", "price": 120},
    }
```

剧本里用 `items_data.ITEMS["potion"]["price"]` 访问。命名空间里的值同样遵循“init 阶段赋值不进存档”的规则。游戏数据规模大了之后，这是比“全部堆 store”更干净的组织方式。

## 16.2 存档到底存了什么

大部分教程会说“存档保存了所有变量”。这句话不准确，而准确的那句话会让你少踩一半的存档坑。引擎源码（`renpy/rollback.py` 的 `get_roots` 方法）的注释原文是：

> Return a map giving the current roots of the store. This is a map from a variable name in the store to the value of that variable. **A variable is only in this map if it has ever been changed since the init phase finished.**

翻译过来：**只有“初始化阶段结束后被改动过”的变量才会进存档。** 这条规则是理解一切存档行为的钥匙，我们把它推演成四条实用结论：

**结论一：`define` 的常量不进存档。** `define` 在初始化阶段赋值，之后若从未被改动，它不在保存名单里。读档后引擎照常执行 define 语句，变量自然恢复。这也是 `define` 适合放常量、Character 对象的原因——它们根本不需要进存档。

**结论二：在运行时改动过的 `define` 变量，会进存档。** 这是结论一的推论，也是最反直觉的一条。假如你写了 `define mode = "normal"`，然后游戏里 `$ mode = "hard"`——`mode` 已经“被改动过”，于是它进存档、读档恢复。所以“define 不进存档”的完整表述是：**未被运行时改动的 define 值不进存档（以 init 结果为准）；被改过的会进。** 想要“无论读不读档都保持 init 值”的量，别让人在运行时写它。

**结论三：`default` 的兜底是版本升级的安全网。** `default affection = 0` 的变量一旦在游戏里被改过就进存档；读档时若存档里没有它（比如新版本才加的字段），引擎会在启动阶段用 default 值补上。这就是第 6.5 节说的“更新游戏不毁旧存档”的机制——前提是你给每个会变的量都写了 default。

**结论四：除了 store，还存一份“游戏日志”。** 存档不只保存变量，还保存 renpy 的内部状态：当前执行到哪条语句、每层上下文（call 链）、当前显示的每一层画面（哪张背景、哪个立绘、什么位置、哪个屏幕开着）、以及回滚日志。所以读档后画面、菜单状态、甚至还能不能往回滚，都和存档那一刻一致——这不是魔法，是“日志”本身就在存档里。

**存档文件里有什么？** 从引擎 `renpy/loadsave.py` 的写入代码可以直接读出来，一个存档是一个 zip 包：

```python
with zipfile.ZipFile(filename_new, "w", zipfile.ZIP_DEFLATED) as zf:
    # Screenshot.
    zf.writestr("screenshot.png", self.screenshot)
    # Extra info.
    zf.writestr("extra_info", self.extra_info.encode("utf-8"))
    # Json
    zf.writestr("json", self.json)
    # Version.
    zf.writestr("renpy_version", renpy.version)
    # The actual game.
    zf.writestr("log", self.log)
    # The signatures.
    zf.writestr("signatures", renpy.savetoken.sign_data(self.log))
```

六件套一目了然：截图（存档界面缩略图）、附加信息（`save_name`，人类可读的存档名）、JSON 元数据、Ren'Py 版本号、真正的游戏状态（变量+日志，pickle 格式）、签名（8.5 新增的防篡改机制）。JSON 元数据的字段在同一个文件里可见：

```python
json = {
    "_save_name": extra_info,
    "_renpy_version": list(renpy.version_tuple),
    "_version": renpy.config.version,
    "_game_runtime": renpy.exports.get_game_runtime(),
    "_ctime": time.time(),
}
for i in renpy.config.save_json_callbacks:
    i(json)
```

`_game_runtime` 是游戏运行时长，`_ctime` 是创建时间；`config.save_json_callbacks` 允许你往元数据里塞自定义字段（比如当前章节号、周目数），再配合第 14 章讲过的 `FileJson(slot, key)` 就能在外部工具或界面里展示。这是 8.x 推荐的存档元数据方案，比旧教程教的“解析 extra_info 字符串”干净得多。

## 16.3 直接操作存档的 Python API

第 14 章讲的是“界面上点按钮”的存读档动作（`FileSave`/`FileLoad`/`FileAction`）。有时你想在剧本里直接存档——比如关键剧情节点自动存一个“剧情存档”。引擎导出的函数覆盖这些需求：

```renpy
label chapter1_end:
    e "第一章 完"

    # 先截屏（当前画面会成为存档缩略图），再存档
    $ renpy.take_screenshot()
    $ renpy.save("chapter1", extra_info="第一章·岔路口")

    e "（已自动保存剧情存档。）"
    jump chapter2
```

`renpy.save(filename, extra_info="")` 的 filename 是槽名，遵循“页-槽”编号（如 `"1-1"` 是第 1 页第 2 格，`"chapter1"` 这种自定义名也合法）。配套的还有：

- `renpy.can_load(filename)`——检查某槽是否存在存档（bool）。典型用法：标题界面检测“剧情存档”决定要不要显示“继续游戏”按钮。
- `renpy.load(filename)`——直接读档，之后代码不会回到下一行（游戏状态整体替换）。
- `renpy.list_saved_games(regexp=r".", fast=False)`——列出存档，返回 `(槽名, extra_info, 时间戳, json)` 元组列表，正则可筛选。
- `renpy.slot_json(slotname)`——取某槽的 JSON 元数据（上一节那些字段）。

一个“续章”按钮的完整例子：

```renpy
screen chapter_select():

    vbox:
        spacing 10

        if renpy.can_load("chapter1"):
            textbutton "第一章·岔路口" action renpy.curry(renpy.load)("chapter1")
        else:
            text "第一章（未解锁）"

        if renpy.can_load("chapter2"):
            textbutton "第二章·灯塔" action renpy.curry(renpy.load)("chapter2")
```

（`renpy.curry` 把“带参数的函数调用”变成动作对象；也可以直接写 `Function(renpy.load, "chapter1")`，更常见。）

自动存档与快速存档是引擎内置的两条特殊轨道：`config.has_autosave`/`config.has_quicksave` 开关（模板默认都开），自动档按 `config.autosave_frequency` 的间隔与切场景时机写入 `auto` 页，快速档由 `QuickSave()`/`QuickLoad()` 动作（第 14 章）读写 `quick` 页的 1 号槽。这两条轨道不需要你写任何代码，理解它们存在即可——第 15 章拆的页码行里那两个 `A`/`Q` 按钮就是它们的入口。

## 16.4 存档的边界：什么存不进去

pickle（Ren'Py 存档用的序列化格式）有边界。以下东西进不了存档，引擎会在保存时抛异常或存出坏档：

**一、运行中打开的资源**。文件句柄、数据库连接、音频流——这些和操作系统状态绑定，pickle 无能为力。游戏里几乎不会碰到，碰到就是设计问题。

**二、匿名函数与闭包**。`lambda`、函数内部定义的函数，都带不上“定义位置”以外的身份信息。第 14 章反复强调“动作列表里放函数对象而不是函数调用”，这里再补一刀：想存档安全，函数一律在 store 顶层（`init python:` 里）定义，实例数据存变量、不存函数。

**三、模块与类型本身**。`renpy/rollback.py` 的 `NOROLLBACK_TYPES` 明确列出：`types.ModuleType`、`StoreModule`、`SlottedNoRollback`、`io.IOBase`、`type`——模块和类对象不参与保存/回滚，保存的是它们的属性值所指的数据。

**四、被“改到一半”的对象**。Ren'Py 的解法是 `config.save_json_callbacks` 之外的另一件武器：把易变状态收拢进少量容器对象，避免“几十个散变量互相引用”。这是架构建议而非语法要求，但它决定存档能不能跨版本存活。

还有一条**工程级忠告**：游戏更新后，类定义改了（加字段、改结构），旧存档里的对象还是旧形状——读档时旧对象按旧形状恢复，访问新字段就会出问题。应对手段按规模递增：小改用 `default` 补字段（读档时引擎把 init 阶段的 default 值补给存档里缺的 store 变量，但对“对象内部缺字段”无效）；对象结构变了，提供迁移代码（读档入口检查 `persistent._version` 或存档 JSON 的 `_version`，按需修复）；彻底重做了，换存档槽名或提供 `config.load_failed_label`（读档失败时跳转到指定 label，给玩家一个体面的解释）。单变量靠 default、对象靠迁移、重写靠 label——三档策略记住即可。

## 16.5 回滚：时间倒流是怎么实现的

按住滚轮往上滚，游戏一句句往回退——这是视觉小说的标配体验，也是 Ren'Py 存档机制的一个副产品：既然游戏日志记下了每一步的状态变化，那么“往回走”就是把日志倒着放。

**回滚的粒度是“语句”，锚点叫 checkpoint（检查点）。** 每条剧本语句执行完毕，引擎自动调用一次 `renpy.checkpoint()`——你不用写，它就是“玩家可以往回退到的位置”。玩家按住滚轮回滚时，引擎沿日志把变量、画面、上下文逐条还原到上一个检查点；松开继续前进时，日志正着重放，游戏状态精确回到原样。第 16.2 节说存档里含回滚日志，两者是同一份日志。

理解了粒度，三个控制函数就各就各位（签名来自引擎 `renpy/exports/rollbackexports.py`，均为引擎导出）：

**`renpy.block_rollback(purge=False)`**——禁止回滚越过当前语句。经典场景：玩家做出重大选择、进入新章节，此时不许“滚轮回去反悔”。在节点语句后调用即可：

```renpy
label chapter2:
    "（第二章开始。从这里不能回滚到第一章了。）"
    $ renpy.block_rollback()
    e "那么，正式开始吧。"
```

`purge=True` 更狠——不但挡住，还把之前的回滚数据直接丢弃（省内存，且读档后也无法回滚到更早）。

**`renpy.suspend_rollback(flag)`**——临时挂起回滚。与 block 不同，suspend 是“这一段整体跳过”：回滚会像越过不存在的区域一样跳过挂起区间。适合由外部脚本驱动的过场。

**`renpy.fix_rollback()`**——“锁定玩家的选择，但保留浏览”。调用后，之前的选择按钮在回滚浏览时会变成“不可再改”的样子（选中态固定），玩家还能翻看历史，但点不出不同结果。适合“回忆章节”的演出。配套的 `renpy.in_fixed_rollback()` 让你的屏幕能区分“正在锁定状态浏览”与“正常游戏”，给按钮换样式。

**`renpy.retain_after_load()`**——解决“读档后丢状态”。引擎默认：读档后一切以存档为准。但有些状态不该随存档回退，比如“已经播放过的新手引导”（读完档总不能再教一遍）。在改写这类状态之前调用它，之后的修改会在下次读档时保留：

```renpy
label tutorial:
    $ renpy.retain_after_load()
    show screen tutorial_hud
    "（教学开始——这条屏幕就算读档也不会消失。）"
```

**`renpy.rollback()`**——程序主动回滚。参数 `checkpoints=1` 表示回退几个检查点，`force=True` 无视一切限制。用于“回答错误，重来一遍”之类的玩法。

**`renpy.roll_forward_info()`**——取回滚前进信息。给“自定义交互”（如 minigame）判断“玩家是正常玩到这里，还是从未来滚回来的”，配合 `renpy.checkpoint(data)` 的 data 参数可以实现“回滚重试时直接跳过已玩过的 minigame”。进阶用法，知道存在即可。

最后是第 18 章要展开的一个预告：**`$` 语句在回滚后重放，而不是恢复中间值**。日志记录的是语句与语句时刻的状态，前进时重放执行 `$ x = renpy.random.random()` 会重新掷骰子。想要“回滚也保持同样的随机数”，用引擎提供的 `renpy.random`（它的每次取值都会被记入日志、重放时复用，源码里那个 `DetRandom` 类注释原文就是 "This is renpy.random"）——细节在第 18.4 节。

## 16.6 综合实战：带“剧情存档”的章节推进

把本章知识拼成一个可运行的小系统（对应示例工程 `14_save_rollback` 的核心）：三个 label 组成的短篇，开场自动存“剧情存档”，章节边界 `block_rollback`，教学屏幕 `retain_after_load`，章节选择界面用 `renpy.can_load` 解锁。

```renpy
default chapter = 1
default met_teacher = False

label start:
    scene bg black with dissolve        # 免素材：用纯色层示意
    "（游戏开始。章节一：雨夜。）"
    call chapter1
    jump chapter_gate

label chapter1:
    e "夜里的雨下个不停。"
    menu:
        "追出去":
            $ chapter = 2
            e "你冲进了雨幕。"
        "留在屋里":
            $ chapter = 2
            e "你留在了原地，听着门外的脚步声远去。"
    return

label chapter_gate:
    "（第二章：灯塔。此处之前的进度将被封锁。）"
    $ renpy.block_rollback()
    $ renpy.take_screenshot()
    $ renpy.save("chapter2", extra_info="第二章·灯塔")
    $ renpy.notify("已保存剧情存档：第二章·灯塔")
    call chapter2
    return

label chapter2:
    if renpy.can_load("chapter2"):
        pass
    e "灯塔的光扫过海面。"
    if not met_teacher:
        $ met_teacher = True
        $ renpy.retain_after_load()
        show screen tutorial_hud
        "（教学：左上角的教学提示会在读档后保留。）"
        hide screen tutorial_hud
    e "第二章 完。"
    return

screen tutorial_hud():
    frame:
        xalign 0.0 yalign 0.0
        padding (12, 8)
        text "提示：点击对话继续" size 22
```

逐段过一遍：`default` 声明的两个变量全程参与存档与回滚；`chapter_gate` 里 `block_rollback()` 先封锁，`take_screenshot()` + `save("chapter2", extra_info=...)` 把当前画面存进自定义槽，`notify()`（第 15 章）给玩家反馈；`chapter2` 开头 `renpy.can_load` 的判断在这里只是演示 API（真实项目里它会出现在章节选择界面）；教学屏幕用了 `retain_after_load`，读任何档它都不会消失，直到你主动 hide。

这个示例同时是“自动存档”的反面教材：Ren'Py 的 auto 轨道已经覆盖了“防止玩家丢进度”，剧情存档的价值在于**语义**——“第二章开头”比“某次自动保存”更值得被命名。命名存档 + 章节选择界面，就是galgame 常见的“章节跳转”功能的全部秘密。

## 16.7 小结与实践

本章把“状态”拆成了三层记忆，每层一个心智模型：

| 层 | 载体 | 生命周期 | 关键 API/语句 |
| --- | --- | --- | --- |
| 一局之内 | store 变量 + 游戏日志 | 从开始到结束 | `default`、`$`、`store.x` |
| 跨次启动 | 存档（zip：截图+元数据+状态） | 玩家或代码管理 | `renpy.save/load/can_load`、`FileSave` 系动作 |
| 一步之内 | 回滚日志（同一份日志的倒放） | 引擎自动 | `block_rollback`、`fix_rollback`、`retain_after_load` |

实践三题：

1. 在第 16.6 节的工程里加一个“章节选择”屏幕：两个按钮分别 `Function(renpy.load, "chapter2")`，未解锁时按钮不敏感（`sensitive renpy.can_load("chapter2")`——注意 `sensitive` 属性接受表达式，第 14 章的 potion_belt 用过）。
2. 制造一个“define 被运行时改动”的 bug（`define score = 0` 然后 `$ score += 1`），存档读档验证它进了存档；然后改成 `default score = 0` 再验证。亲手做一遍，比读十遍规则记得牢。
3. 给 `chapter_gate` 加一行 `$ renpy.retain_after_load()`，观察教学屏幕在读档后的表现差异。

下一章把记忆的第三层——跨周目的 persistent——讲透，它是画廊、音乐室、“已读跳过”与成就系统的地基。

---

上一章：[15 特殊屏幕与菜单定制](ch15-special-screens.md) · 下一章：[17 持久化：persistent 与跨周目数据](ch17-persistent.md)
