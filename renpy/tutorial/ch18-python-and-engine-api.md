# 第 18 章 Python 语句与引擎 API

前面十七章里我们已经零散用过 `$`、`init python:`、`python:`。这一章把它们一次讲透，并给出引擎 API 的分类地图——不是字典式的罗列，而是按“你什么时候需要它”组织的检索框架。

## 18.1 四种 Python 代码的执行时机

Ren'Py 里写 Python 的方式有四种，差别全在**何时执行**：

```renpy
# ① $ 语句：执行到这行时执行。游戏进行时。
$ affection += 1

# ② python: 块：执行到时执行，可多行。游戏进行时。
python:
    affection += 1
    gold = min(gold + bonus, MAX_GOLD)

# ③ init python: 块：初始化阶段执行（启动或读入脚本时）。
init python:
    def add_affection(n):
        store.affection += n

# ④ define：初始化阶段执行一次，语义是"定义常量"。
define MAX_GOLD = 9999
```

③和④都在 init 阶段，但有个容易忽略的机关：**init 有优先级**。数字越小的越先执行：

```renpy
init 1 python:
    LATE_CONST = EARLY_CONST + 1      # 能读到，因为 init 1 晚于 init 0

init 0 python:
    EARLY_CONST = 10
```

不写数字默认是 0；`define` 等价于 `init 0` 的常量定义；`python early:` 则更早（在第 17 章的自定义命名空间示例里用过 `python early in items_data`——early 块在解析阶段运行，能参与“定义新语句”这类元编程，日常游戏开发极少需要）。优先级的实用价值：当你有一批“先算出基础值、再派生其他值”的初始化逻辑时，用优先级表达顺序，而不是把所有东西塞进一个巨大块。

还有个启动器生成的常见模式值得认识：`init offset = 5`（写在文件开头），它让**这个文件里后续所有 init 语句的优先级 +=5**——模板的 `gui.rpy` 用这招保证自己先于 `screens.rpy` 执行。

## 18.2 剧本里调用引擎：API 分区地图

引擎导出函数（`renpy.xxx`）有几百个，但按“你想干什么”分类后，常用的就几十个。这张地图按使用频率与场景组织，每格都注明本指南讲过它的章节：

**控制流程**（第 5 章讲过剧本语句版本，函数版本用于 Python 块内）：

```renpy
renpy.jump("label_name")            # 等价 jump
renpy.call("subroutine")            # 等价 call（在 Python 里从函数里跳走要小心用法）
renpy.full_restart()                # 回到主菜单重启界面
renpy.quit()                        # 退出游戏
```

Python 函数里**不能**用 `jump`/`call` 剧本语句——它们只存在于剧本层。函数想改变流程，要么返回值让剧本层 jump（推荐），要么用 `renpy.jump()`（它抛出一个引擎捕获的控制流异常，从深层函数里跳出来时反而很方便）。

**界面与演出**：

```renpy
renpy.show("eileen happy", at_list=[right])   # 等价 show 语句（函数版）
renpy.hide("eileen")                           # 等价 hide
renpy.scene()                                  # 等价 scene（清空主层）
renpy.show_screen("stats", gold=100)           # 显示屏幕并传参（第 14 章的 Show 动作底层）
renpy.hide_screen("stats")
renpy.call_screen("quiz")                      # 显示屏幕并等待其交互结束，拿 Return() 的值
renpy.pause(1.0)                               # 暂停
renpy.notify("已保存")                          # 角落通知（第 15 章）
```

`renpy.call_screen` 是“屏幕当函数用”的桥：屏幕里点 `Return(value)`，`call_screen` 就返回那个值。第 14 章 shop 屏幕用 `Return()` 结束交互，剧本侧 `call screen shop` 接住——同一个机制。

**信息查询**（做界面与调试最常用）：

```renpy
renpy.get_screen("stats")          # 屏幕是否在显示（返回对象或 None）
renpy.get_rollforward_info()       # 回滚前进信息（16.5 节）
renpy.seen_label("ch3")            # 已读检查（第 17 章）
renpy.variant("mobile")            # 平台判断（第 15 章 navigation 用过）
renpy.version                      # 引擎版本字符串
```

**音频**（第 9 章讲过语句版，函数版在 Python 块里控制播放列表）：

```renpy
renpy.music.play("music/theme.ogg", fadeout=1.0)
renpy.music.stop("music")
```

这张地图的用法：写代码前先问“这在剧本层能不能写”。**Ren'Py 的设计哲学是剧本语句优先**——`show`/`play`/`jump` 的语句版比函数版更常被引擎预测与优化。函数版留给“语句表达不了”的场景：循环里批量操作、条件分支里的复杂逻辑、函数库封装。

## 18.3 屏幕与 Python 的边界面

屏幕语言与 Python 的交界处有三件武器，第 14 章用过两件，这里集中说清：

**`$` 在屏幕里是“每次重算执行”**。第 14 章的世纪误解警告值得在此重申并补全机制：屏幕不是“显示一次”的东西，引擎在每次交互、每次动作后都可能**重算**（重新执行整个屏幕的语句流）。所以屏幕里 `$ total = sum(prices)` 会在每次重算时重新求值——用来做“派生显示值”是正当的（这正是 shop 屏幕里 `$ inv = "、".join(backpack)` 成立的原因），但绝不能放有副作用的语句（`$ renpy.save(...)`、`$ counter += 1` 这类，重算几次就执行几次）。

**`Function` 动作是“点击时执行一次”**。带 `_update_screens=True` 默认参数——执行完自动重算所有屏幕，所以改了变量的动作按钮能立即看到变化。

**`renpy.not_infinite_loop`** 不存在，屏幕循环防护的正解是理解重算模型本身。屏幕里的 `for` 只在重算时展开，不存在“死循环卡引擎”的问题（卡的是你把重算写成了无限递归——比如屏幕里改自己读的变量又触发重算，引擎有 `config.periodic_screen_redraw` 之外的自动保护提示）。

## 18.4 随机数与回滚：确定性随机

第 16.5 节埋的伏笔在此揭晓。Python 标准库的 `random` 模块与回滚**不兼容**：

```renpy
$ roll = random.randint(1, 6)     # 坏例子：回滚后前进，骰子会重掷！
```

回滚的机制是“重放语句”（16.5 节），重放时标准库的 RNG 状态已经变了，重掷出不同的点数——玩家滚回去再滚回来，世界就变了。引擎的解法是 `renpy.random`，一个“确定性随机数发生器”（源码类 `DetRandom` 的 docstring 原文："This is renpy.random."）。它的每次取值做两件事（源码 `random()` 方法）：**把结果记进当前回滚日志条目**、**强制产生一个检查点**。回滚重放时，日志里存过的随机值通过推回栈（`pushback` 机制）原样复用——世界保持一致。

```renpy
$ roll = renpy.random.randint(1, 6)     # 好：回滚重放时还是同一个点数
$ e "骰出了 [roll] 点。"
```

API 与标准库 `random.Random` 完全一致（`randint`/`choice`/`shuffle`/`random`…），区别只在回滚参与。两条补充：

- `renpy.random.Random(seed)` 返回一个**独立的**、同样参与回滚的 RNG 对象——给 minigame 或洗牌系统用，避免污染主 RNG 序列。
- 需要“故意不可回滚”的随机（如装饰性粒子效果），用标准库反而正确——粒子不需要跨回滚一致，还省日志空间。

## 18.5 存档安全的 Python 写法

16.4 节讲了“什么存不进去”，本节给出对应的写法守则，全部是第 14-17 章出现过的模式的归纳：

**守则一：类定义在 init，实例数据在 store。** 自定义类的定义放 `init python:`，实例存进 `default` 声明的变量——pickle 存实例时按“类名”引用定义，存档跨启动也能找到类。

```renpy
init python:
    class Quest:
        def __init__(self, title, done=False):
            self.title = title
            self.done = done

default quests = [Quest("找到灯塔"), Quest("雨夜追踪")]
```

**守则二：修改对象字段要“可感知”。** Ren'Py 的存档/回滚依赖“变量变化检测”（16.2 节的 ever_been_changed 机制对对象属性同样生效——引擎包装了常见容器（`RevertableList`/`RevertableDict`/`RevertableSet`），`default` 声明的列表/字典自动是回滚感知版本）。但**自定义类的实例字段**需要对象参与回滚日志，标准做法是让类继承引擎的 `object` 默认行为即可（Ren'Py 通过日志记录实例属性赋值），真正要避免的是“在 init 阶段创建、运行时修改后想回滚”的对象——init 对象不进回滚日志的根，改它不产生历史。

```renpy
default party = []            # 回滚感知列表
$ party.append("艾琳")         # 回滚会撤销这次 append

default stats = {}            # 回滚感知字典
$ stats["gold"] = 100         # 同上
```

**守则三：函数不存数据。** 需要随存档变化的配置，放变量；函数保持纯粹（参数进、结果出、副作用走 store）。第 14 章 `buy()` 函数改 `store.gold` 而不是改某个全局单例对象，就是这个守则的应用。

**守则四：跨版本的字段迁移靠“读档时补”。** 18.1 节的 init 优先级给了一个惯用法——在比 0 大的 init 里做存档兼容检查：

```renpy
init 5 python:
    # 引擎加载存档前，store 里还是 init 结果；靠 default 兜底为主，这里做对象级修补
    pass
```

（实际项目里对象级迁移通常在“读档后第一条语句”或包装 `renpy.load` 的辅助函数里做——把修补逻辑写成函数 `migrate_save()`，`label after_load:`（第 5.7 节的特殊 label）里调用它，这是 Ren'Py 官方推荐的迁移入口。）

## 18.6 综合实战：事件驱动的属性系统

用本章知识写一个“属性+事件”小系统（示例工程 `16_full_project` 的核心模块），覆盖 18.1-18.5 全部知识点：

```renpy
init python:
    class Stat:
        def __init__(self, name, value=0, maximum=100):
            self.name = name
            self.value = value
            self.maximum = maximum

    def gain(stat, n):
        # 修改 store 里的 stats 字典（回滚感知），并返回是否升级供剧本层用
        s = store.stats[stat]
        before = s.value
        s.value = min(s.value + n, s.maximum)
        return s.value > before and s.value == s.maximum

default stats = {"勇气": Stat("勇气"), "共情": Stat("共情")}

label start:
    "（旅途中……）"
    $ levelup = gain("勇气", 60)
    if levelup:
        "勇气突破上限！"
    $ roll = renpy.random.randint(1, 6)
    if roll >= 4:
        jump brave_path
    else:
        jump calm_path

label brave_path:
    "（你选择了直面危险。）"
    return

label calm_path:
    "（你选择了绕路而行。）"
    return
```

拆解：`Stat` 类在 `init python:` 定义（守则一）；`stats` 字典 `default` 声明，自动回滚感知（守则二）；`gain()` 纯函数、副作用写 `store.stats`（守则三）；随机用 `renpy.random`（18.4）；流程跳转用返回值+剧本层 `if`/`jump`，而不是函数里 `renpy.jump`（18.2 的“剧本语句优先”）。三十行代码，是把前十七章状态知识收拢成的一颗结晶。

## 18.7 小结与实践

本章没有新语法，只有一张把旧知识钉牢的地图：

- 四种 Python 代码 = 两个执行时机（init/运行时）× 两种语义（常量/过程）；
- 引擎 API 优先用剧本语句，函数版留给 Python 层；
- 屏幕重算模型决定 `$` 在屏幕里只能做纯计算；
- 随机数用 `renpy.random` 保回滚一致；
- 存档安全四守则：类在 init、数据在 default、函数纯、迁移靠 after_load。

实践：

1. 把 16.6 与 18.6 的两个系统合并：章节推进时 `gain()` 好感度，存档槽的 JSON 元数据里记录当前属性（`config.save_json_callbacks` + `renpy.slot_json` 读取显示）。
2. 故意写一个“屏幕里 `$ counter += 1`”的 bug，观察计数行为，体会重算模型——这次是你自己发现它，而不是书上告诉你。

至此，第五部分“状态篇”完结：变量、存档、回滚、持久化、Python 层——五块地基全部打好。下一部分“专题篇”开始盖房子：输入与历史、画廊与音乐室、回放系统、开场演出——这些“成品功能”全部由你已经掌握的零件组装而成。

---

上一章：[17 持久化：persistent 与跨周目数据](ch17-persistent.md) · 下一章：[19 输入与对话历史](ch19-input-and-history.md)
