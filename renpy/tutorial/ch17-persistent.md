# 第 17 章 持久化：persistent 与跨周目数据

存档是一局游戏的记忆，persistent 是**玩家**的记忆：解锁过哪些结局、看过哪些 CG、设置里的音量、成就系统——这些不属于任何一局，而属于“这个玩家在这个设备上玩过的整个游戏”。Ren'Py 把这套数据挂在全局对象 `persistent` 上，引擎自动读写，你只管当普通变量用。

## 17.1 persistent 对象的基本用法

```renpy
label true_ending:
    "（达成真结局。）"
    $ persistent.unlocked_true = True
    $ persistent.endings_count = persistent.endings_count + 1
    return
```

两个反直觉的事实，都来自引擎源码（`renpy/persistent.py` 的 `Persistent` 类）：

**第一，未赋值的 persistent 字段读到的是 None，不是报错。** 源码里的 `__getattr__` 就一行逻辑：属性不存在就返回 None（双下划线开头的除外）。所以不需要初始化：

```renpy
label start:
    if persistent.unlocked_true:          # 第一次运行时它是 None，等同 False
        e "欢迎回来，真结局达成者。"
    else:
        e "欢迎来到新的故事。"
```

`None` 在条件判断里当假值用，一行判断就完成了“是否解锁过”的检查。但要注意它**不是 False**——`persistent.x is False` 和 `persistent.x is None` 是两种状态。习惯写 `if persistent.x:`，不要写 `if persistent.x is True:`。

**第二，引擎内置了几个下划线开头的字段，别撞名。** 同一文件的类定义原文列出了它们：`_preferences`（设置对象，第 14 章的 `Preference` 动作读写的就是它）、`_seen_ever`（已读语句表）、`_seen_images`（已看图像）、`_chosen`（选过的选项）、`_seen_audio`（已听音频）、`_seen_translates`（已读翻译）。你自己的字段用普通名字（`persistent.unlocked_true`），下划线命名空间留给引擎。

**什么时候写盘？** 引擎在游戏退出时、以及周期性地自动保存 persistent（`find_changes` 函数对比字段备份，发现变化才写，性能无忧）。想立刻落盘（比如存档页上的“已解锁 CG 计数”要即时可靠），调用：

```renpy
$ renpy.save_persistent()
```

一般用不上，知道即可。另一个实用方法：`persistent._clear(progress=True)` 重置全部持久化数据——做“删除通关记录”功能或调试时用。

## 17.2 已读系统：文本跳过与解锁检查

“已读”是最常用的持久化数据，引擎替你维护好了。玩家每读过一句话、看过一张图、听过一段音乐、选过一个选项，引擎都记进 `persistent` 的内置字段。你通过一组查询函数读它们：

```renpy
renpy.seen_label("chapter3")   # 是否经过过某个 label
renpy.seen_image("eileen happy")   # 是否显示过某图像
renpy.seen_audio("music/theme.ogg")   # 是否播放过某音频
renpy.seen_translation(tlid)   # 是否读过某翻译条目
```

配套的 `mark_label_seen`/`mark_label_unseen` 等函数可以手动标记（做“图鉴作弊码”或测试用）。这些函数的底层就是读写上节的 `_seen_ever`/`_seen_images`/`_seen_audio` 字段——源码 `persistentexports.py` 里 `seen_label` 的实现只有一行：查 `renpy.game.persistent._seen_ever`。

“已读”最出名的应用是**快进时跳过已读文本**（设置页的 "skip" 偏好，"Unseen Text"/"Seen Text"）。但同样的数据能支撑解锁系统：

```renpy
label gallery():
    menu:
        "画廊":
            call screen gallery_screen
        "返回":
            return
    jump gallery

screen gallery_screen():
    vbox:
        spacing 8
        text "CG 画廊" size 40

        # 看过的显示，没看过的显示"???"——一个 if 就是一个解锁条件
        if renpy.seen_image("cg sunset"):
            add "cg sunset"
        else:
            text "??？（未解锁）"

        if renpy.seen_image("cg lighthouse"):
            add "cg lighthouse"
        else:
            text "??？（未解锁）"

        textbutton "返回" action Return()
```

第 20 章会把画廊做成带分页与缩略图的完整版本，这里先记住原则：**解锁数据来自引擎自动记录的 seen 系列，展示层只做 `if` 判断**——数据与展示分离，画廊、音乐室、成就三个系统共用同一套思路。

## 17.3 偏好设置的存放处：persistent._preferences

玩家调的音量、文字速度、窗口模式存哪？答案：`persistent._preferences`，一个引擎自管理的 `Preferences` 对象。你在第 14 章用 `Preference("music volume", 0.8)` 调它、用 `Preference("display", "fullscreen")` 切全屏，引擎内部就是改这个对象并自动持久化——**所以“音量保存”不需要你写一行代码**，这是模板免费送的功能。

对它的直接操作只在少数场景需要（比如游戏内做“重置全部设置”）：

```renpy
$ persistent._preferences.text_cps = 40        # 文字速度
$ persistent._preferences.fullscreen = True    # 全屏
```

字段名与 `Preference` 动作一一对应。日常开发坚持用 `Preference` 动作——它自带选中态与持久化，直接改字段反而绕开了这些便利。

## 17.4 MultiPersistent：跨游戏共享数据

同一开发商的多部作品想共享数据（前作存档解锁后作彩蛋），persistent 不够——它按“游戏目录”隔离。引擎提供了 `MultiPersistent`：

```renpy
define mp = MultiPersistent("mycompany.demo_saga")

label import_check:
    if mp.demo_cleared:
        e "检测到前作通关记录，解锁特典立绘！"
        $ persistent.bonus_unlocked = True
    return

label demo_clear:
    $ mp.demo_cleared = True
    $ mp.save()
    return
```

三条铁律（全部来自源码验证）：

1. **必须在 init 阶段创建**。源码检查 `context().init_phase`，运行时创建直接抛异常。所以示例用 `define mp = MultiPersistent(...)`。
2. **写入后必须手动 `mp.save()`**。与 persistent 的自动保存不同，MultiPersistent 不自动落盘。
3. **存储位置按平台固定**（Windows 在 `~/RenPy/Persistent` 与 `%APPDATA%/RenPy/persistent`，macOS 在 `~/.renpy/persistent` 与 `~/Library/RenPy/persistent`，移动端退化为游戏自身存档目录）。`MultiPersistent("名字")` 的名字就是文件名——两部游戏传同一个名字，就共享同一份数据。

Steam/GOG 这类平台的成就与云存档走各自的 SDK 集成，不在 MultiPersistent 的职责内，但“跨会话记忆数据”的心智模型一致。

## 17.5 综合实战：结局收集与标题界面联动

把本章知识做成完整的“周目系统”（示例工程 `15_persistent` 的核心逻辑）：

```renpy
default affection = 0

label start:
    "（一周目开始。）"
    $ affection += 10
    menu:
        "陪她看海" (persistent.route_sea_seen):
            $ affection += 20
            jump ending_sea
        "陪她爬山":
            $ affection += 20
            jump ending_mountain

label ending_sea:
    $ persistent.route_sea_seen = True
    $ persistent.endings += 1
    $ renpy.save_persistent()
    "（海边结局 完。）"
    return

label ending_mountain:
    $ persistent.route_mountain_seen = True
    $ persistent.endings += 1
    $ renpy.save_persistent()
    "（山上结局 完。）"
    return
```

（`menu` 项后面括号里的表达式是“选项出现条件”——第 6 章讲过的语法，这里用它根据 persistent 换文案。）标题界面显示收集进度：

```renpy
screen main_menu():

    tag menu

    add gui.main_menu_background
    use navigation

    vbox:
        xalign 0.95 yalign 0.85
        spacing 6

        text "结局收集：[persistent.endings or 0] / 2"
        if persistent.route_sea_seen and persistent.route_mountain_seen:
            text "★ 全结局达成，隐藏章节已解锁" color "#ffcc00"
```

`[persistent.endings or 0]` 处理“从未玩过时是 None”的显示问题。全部结局达成后解锁隐藏章节——判断、标记、展示三层分离，任何周目系统都是这个骨架。

## 17.6 小结与实践

| 需求 | 工具 | 记忆周期 |
| --- | --- | --- |
| 一局内状态 | store 变量 | 一局 |
| 存档/读档 | `renpy.save/load`、File 系动作 | 玩家管理 |
| 回滚 | 日志倒放 + block/fix/suspend | 引擎自动 |
| 玩家数据 | `persistent.xxx` | 永久（自动保存） |
| 跨游戏 | `MultiPersistent` + `mp.save()` | 永久（手动保存） |

实践：

1. 给 17.5 的工程加成就屏幕：三个成就（海结局、山结局、双结局），用 `renpy.seen_label` + persistent 双数据源各做一个。
2. 写一个“开发者后门”屏幕：按钮调用 `persistent._clear(progress=True)` 并刷新界面，测试全结局状态如何复位。

下一章回到语言层：Python 语句的完整语义、引擎 API 的分类地图、以及随机数与回滚纠缠时的正确姿势——它们是支撑前面所有章节的地基。

---

上一章：[16 变量、存档与回滚](ch16-save-and-rollback.md) · 下一章：[18 Python 语句与引擎 API](ch18-python-and-engine-api.md)
