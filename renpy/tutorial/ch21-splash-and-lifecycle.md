# 第 21 章 开场动画与游戏生命周期

玩过足够多的游戏之后，那一串开场动作会变成肌肉记忆：双击图标 → 一个浅色的小窗口一闪（presplash）→ 一段厂商 logo 或标题动画 → 主菜单音乐响起 → 点“开始游戏”→ 第一句台词出现。

这串动作背后没有魔法，只有几个固定名字的 label 被引擎依次执行。本章要把它们全部摊开：从你双击图标那一刻起，Ren'Py 走了哪几个 label、每句话在干什么、你能在哪些位置插进自己的开场动画、以及“开始游戏”和“返回主菜单”这两个按钮究竟让引擎做了什么。

与前二十章有一点根本不同：**本章引用的源码是 Ren'Py 引擎自身的源码，不是你的项目代码。** 这看似违背了“不要让读者看源码”的原则，其实正相反——`_start`、`_invoke_main_menu`、`_main_menu`、`_splashscreen` 这些以下划线开头的 label，是引擎**留给作者覆盖和挂钩的公开接口**（官方文档把它们写在 *Special Labels* 里）。你要定制开场流程，唯一的方式就是理解这几个 label 的执行顺序。所以本章的“源码”就是讲解对象本身，我会把每一行都读给你听，你不需要去打开引擎目录。

## 21.1 生命周期的引擎骨架：一个 `while True`

Ren'Py 从启动到退出，外层只跑了一个死循环。它位于 `renpy/main.py`：

```python
        # Start things running.
        restart = None

        while True:
            if "traceback_load" in renpy.session:
                del renpy.session["traceback_load"]

            if restart:
                renpy.display.screen.before_restart()

            try:
                try:
                    run(restart)
                finally:
                    restart = (renpy.config.end_game_transition, "_invoke_main_menu", "_main_menu")

            except renpy.game.QuitException:
                renpy.audio.audio.fadeout_all()
                raise

            except game.FullRestartException as e:
                restart = e.reason

            finally:
                renpy.persistent.update(True)
                renpy.persistent.save_on_quit_MP()

                # Reset live2d if it exists.
                try:
                    renpy.gl2.live2d.reset_states()
                except Exception:
                    pass

                # Flush any pending interface work.
                renpy.display.interface.finish_pending()

                # Give Ren'Py a couple of seconds to finish saving.
                renpy.loadsave.autosave_not_running.wait(3.0)

                # Run the at exit callbacks.
                for cb in renpy.config.at_exit_callbacks:
                    cb()

    finally:
        gc.set_debug(0)

        for i in renpy.config.quit_callbacks:
            i()
```

（`renpy/main.py` 第 584–631 行，略去与主题无关的注释）

我们一行一行读，这里藏着整个生命周期的秘密。

**`restart = None`**。`restart` 是本轮的“重启参数”，初值 `None` 表示“这是第一次启动”。

**`while True:`**。整个游戏（不是“一局游戏”，是“从双击程序到关闭程序”）跑在这一个循环里。循环体每转一圈，就是“一次完整的进入游戏”。

**`try: run(restart)`**。`run()` 函数就是“跑一轮游戏”：它会把场景清空到初始状态，从 `_start`（或 `start`）开始执行，一路跑到玩家关游戏或回到主菜单为止。`run()` 的细节马上讲。

**`finally: restart = (renpy.config.end_game_transition, "_invoke_main_menu", "_main_menu")`**。这是最容易被忽略、也最关键的一行。注意它是 `finally`——**无论 `run()` 是正常返回还是抛异常，这行都会执行。** 也就是说：

> 只要一轮游戏结束（哪怕只是剧情跑到了最后一句、正常 `return`），`restart` 就会被赋成这个三元组 `(转场, "_invoke_main_menu", "_main_menu")`。下一轮循环就会“重启并回到主菜单”。

三元组的三个元素各有用途，记住它们的顺序 `(transition, label, target)`：

1. `renpy.config.end_game_transition`——回到主菜单时播放的转场（默认 `None`，即无转场，你可以设成 `Dissolve(1.0)` 之类的淡出）。
2. `"_invoke_main_menu"`——下一轮 `run()` 跑到 `_start` 尾部时要跳转到的 label。
3. `"_main_menu"`——真正显示主菜单的 label。

**`except renpy.game.QuitException: fadeout_all(); raise`**。玩家关游戏时，引擎从里到外先做一次声音淡出，然后把这个异常继续往上抛，抛到最外层 `finally` 去收尾。`QuitException` 不走上面的 `finally` 赋值（`raise` 会跳过本轮 `restart` 赋值直接离开循环），所以关游戏就是真的退出。

**`except game.FullRestartException as e: restart = e.reason`**。这是“主动重启”的通道。`FullRestartException` 携带的 `reason` 正好是上面那种 `(transition, label, target)` 三元组——它**覆盖**掉 `finally` 里的默认值。所以“返回主菜单”“从头开始”这类需求，走的是这条路（21.5 会看到 `full_restart()` 怎么造这个异常）。

**`finally:`（内层）**：`renpy.persistent.update(True)` 把 persistent 数据落盘（第 17 章讲过 persistent 会在退出时保存）；`save_on_quit_MP()` 保存 `_quit_slot`（“退出时自动存档”）；`autosave_not_running.wait(3.0)` 等最多 3 秒让自动存档写完；最后依次调用 `config.at_exit_callbacks` 里的回调。

**最外层 `finally:`**：`config.quit_callbacks` 里的回调——这是程序真正退出的钩子（注意与上面的 `at_exit_callbacks` 区别：`at_exit_callbacks` 每轮回主菜单都跑，`quit_callbacks` 只在关程序时跑一次）。

现在再看 `run()` 本身，它是“一轮游戏”的全部内容：

```python
def run(restart):
    """
    This is called during a single run of the script. Restarting the script
    will cause this to change.
    """

    reset_clock()

    # Reset the store to a clean version of itself.
    renpy.python.clean_stores()
    log_clock("Cleaning stores")

    renpy.sl2.slast.load_cache()
    log_clock("Load screen analysis")

    # Analyze the screens.
    renpy.display.screen.analyze_screens()
    log_clock("Analyze screens")

    ...

    # Re-Initialize the log.
    game.log = renpy.python.RollbackLog()

    # Switch contexts, begin logging.
    game.contexts = [renpy.execution.Context(True)]

    # Jump to an appropriate start label.
    if game.script.has_label("_start"):
        start_label = "_start"
    else:
        start_label = "start"

    game.context().goto_label(start_label)

    ...

    # Note if this is a restart.
    renpy.store._restart = restart

    # We run until we get an exception.
    renpy.display.interface.enter_context()

    log_clock("Running {}".format(start_label))

    renpy.execution.run_context(True)
```

（`renpy/main.py` 第 60–135 行，省略了缓存、存档字节码、参数处理等中间部分）

逐条：

- **`renpy.python.clean_stores()`**：把 store（也就是 `define`、`default` 定义的变量所处的命名空间）**清空重置**。这一句解释了为什么“返回主菜单再开始游戏”，所有剧情变量都会回到初始值——不是有人替你重置，而是整轮 `run()` 从零开始。第 18 章讲的 `init python` 和 `define` 会在这之后重新执行一遍（`init` 阶段在 `run()` 之前）。
- **`game.log = renpy.python.RollbackLog()`**：新建一份回滚日志。第 16 章讲过回滚，这里就是回滚日志被清空的位置——每一轮游戏从零开始记录，所以返回主菜单后你回滚不到上一局的剧情。
- **`game.contexts = [renpy.execution.Context(True)]`**：新建**一个**“顶层上下文”（`True` 表示它是可存档的顶层上下文，第 14 章讲过 `context` 概念，第 20 章回放用过 `call_replay` 的隔离上下文）。
- **`start_label` 的选择**：`has_label("_start")` 有就跳 `_start`，没有就跳 `start`。引擎自带 `_start`（下一节全文），所以正常项目永远走 `_start`。**这一行是理解“为什么游戏从 `_start` 而不是从你写的 `start` 开始”的答案。**
- **`renpy.store._restart = restart`**：**这就是你在脚本里能读到的那个 `_restart` 变量**。它的值要么是 `None`（首次），要么是 `(transition, label, target)` 三元组（重启）。`_start` 里到处用 `if not _restart:` 判断“是不是首次启动”，就是读它。
- **`renpy.execution.run_context(True)`**：真正开始执行脚本，`True` 表示“这是顶层上下文”。它会一直跑到脚本结束或抛出 `QuitException`/`FullRestartException`。

把上面两段拼起来，就是整个生命周期：

```
双击图标
   │  初始化、加载脚本、执行 init（第 2、18 章）
   ▼
main.py: while True  ───────────────────────────────────────┐
   │   run(restart)                                          │
   │     · clean_stores()      ← 清空 store，回到初始值        │
   │     · 新 RollbackLog       ← 回滚日志清零                │
   │     · 新 Context(True)     ← 新的可存档顶层上下文         │
   │     · goto_label("_start")                             │
   ▼                                                        │
_start  ← 每一轮的“零点”                                     │
   │   default 语句 / 语言 / 关回滚                           │
   │   _gl_test / warp / auto_load / _load_reload_game       │
   ▼                                                        │
_splashscreen ──► 你的 splashscreen label                    │
   ▼                                                        │
_invoke_main_menu                                           │
   │   call_in_new_context("_main_menu")                    │
   ▼                                                        │
_main_menu ──► _main_menu_screen ──► 你的 main_menu 屏幕      │
   │                                                        │
   │   玩家点“开始”（Start()）                                │
   ▼                                                        │
jump "start" ──► 你的剧情 ──► 剧情结束（return / 跑到末尾）    │
   │                                                        │
   │   run() 返回；finally 里设好 _restart 三元组             │
   └────────────────────────────────────────────────────────┘
                    （带上 end_game_transition 回到主菜单）
```

这张图是本章的总纲，后面每一节都是在放大它的某一段。

## 21.2 `_start`：每一轮的零点

`_start` 是引擎真正的起点（`run()` 优先跳它）。它定义在 `renpy/common/00start.rpy`，全文如下：

```renpy
# This is the true starting point of the program. Sssh... Don't
# tell anyone.
label _start:

    if config.early_start_store:
        call _start_store

    python:
        renpy.execute_default_statement(True)

    if not config.early_start_store:
        call _start_store

    python:
        _init_language()

        # Predict the main menu. When a load occurs, the loaded data will
        # overwrite the prediction requests.
        if renpy.has_screen("main_menu"):
            renpy.start_predict_screen("main_menu")

        renpy.block_rollback()

    scene black

    if not _restart:
        call _gl_test

    python hide:
        renpy.warp.warp()

    call _load_reload_game from _call__load_reload_game_1

    python hide:
        auto_load = renpy.os.environ.get("RENPY_AUTO_LOAD", config.auto_load)
        if not _restart and auto_load and renpy.can_load(auto_load):
            renpy.load(auto_load)

    if config.start_scene_black:
        scene black

    if not _restart:
        $ renpy.display.interface.with_none(overlay=False)

    $ renpy.block_rollback()

    $ _old_game_menu_screen = _game_menu_screen
    $ _game_menu_screen = None
    $ _old_history = _history
    $ _history = False

    python hide:
        for i in config.main_menu_stop_channels:
            renpy.music.stop(channel=i, fadeout=0.0)

    if renpy.has_label("splashscreen") and (not _restart) and (not renpy.os.environ.get("RENPY_SKIP_SPLASHSCREEN", None)):
        call _splashscreen from _call_splashscreen_1

    $ _game_menu_screen = _old_game_menu_screen
    $ del _old_game_menu_screen
    $ _history = _old_history
    $ del _old_history

    $ renpy.block_rollback()

    if config.main_menu_music:
        $ renpy.music.play(config.main_menu_music, if_changed=True, fadein=config.main_menu_music_fadein)
    else:
        $ renpy.music.stop()

    scene black

    python:
        # Stop predicting the main menu, now that we're ready to show it.
        if renpy.has_screen("main_menu"):
            renpy.stop_predict_screen("main_menu")

        # Implement config.window
        _init_window()

    # This has to be Python, to deal with a case where _restart may
    # change across a shift-reload.
    python:
        if _restart is None:
            renpy.transition(config.end_splash_transition)
        else:
            renpy.transition(_restart[0])

            renpy.game.context().force_checkpoint = True
            renpy.jump(_restart[1])
```

（`renpy/common/00start.rpy` 第 202–291 行）

一次读不完没关系，我按功能把它切成六块。

**第一块：初始化 store 与语言。**

```renpy
    if config.early_start_store:
        call _start_store

    python:
        renpy.execute_default_statement(True)

    if not config.early_start_store:
        call _start_store

    python:
        _init_language()
```

`renpy.execute_default_statement(True)` 执行的是**所有 `default` 语句**——这就是“游戏开始时，`default` 变量被赋初值”的地方。参数 `True` 表示“这是游戏开始”，引擎会强制把每个 `default` 变量设成初值（21.6 会对比“读档时传 `False`”的差异）。

`_start_store` 是个小 label，同样在 `00start.rpy`：

```renpy
# Common code for _start and _start_replay.
label _start_store:

    python hide:
        store.main_menu = False
        renpy.context()._menu = False
        renpy.context()._main_menu = False

        for i in config.start_callbacks:
            i()

    return
```

（`renpy/common/00start.rpy` 第 162–173 行）

它做三件事：把 `main_menu` 标记清掉（“我现在不在主菜单里”）、修正上下文的 `_menu`/`_main_menu` 标志、执行 `config.start_callbacks`（你能注册“开局时跑一次”的回调）。`config.early_start_store` 默认 `False`，所以 `_start_store` 在 `default` 之后执行；把它设成 `True` 可以让它在 `default` 之前执行（极少数需要在 default 之前准备数据的场景才用）。

`_init_language()` 决定开局的语言，它的实现是：

```python
    def _init_language():
        """
        Changes the default language. This is called automatically by
        Ren'Py as it starts up.
        """

        import os

        language = os.environ.get("RENPY_LANGUAGE") or config.language or _preferences.language

        renpy.change_language(language, force=True)
```

（`renpy/common/00start.rpy` 第 76–86 行）

优先级很清楚：环境变量 `RENPY_LANGUAGE` > `config.language` > 玩家的语言偏好（`_preferences.language`，也就是设置界面里选过的语言）。你平时用不到它，但记住 `config.language` 可以强制开局语言。

**第二块：预热主菜单。**

```renpy
        if renpy.has_screen("main_menu"):
            renpy.start_predict_screen("main_menu")

        renpy.block_rollback()

    scene black
```

`start_predict_screen("main_menu")` 是**预测加载**：让引擎在后台提前把主菜单屏幕需要的图片装载进显存，这样主菜单弹出时不卡顿。预测只是优化，不影响正确性。

`renpy.block_rollback()` 把“回滚屏障”设到当前位置（第 16 章讲过 `block_rollback`）——玩家不能从游戏里回滚回主菜单。

`scene black` 把画面清成纯黑，作为主菜单之前的底色。

**第三块：warp、重载恢复与自动读档。**

```renpy
    if not _restart:
        call _gl_test

    python hide:
        renpy.warp.warp()

    call _load_reload_game from _call__load_reload_game_1

    python hide:
        auto_load = renpy.os.environ.get("RENPY_AUTO_LOAD", config.auto_load)
        if not _restart and auto_load and renpy.can_load(auto_load):
            renpy.load(auto_load)
```

`_gl_test` 只在首次启动时跑，做一次显卡能力自检（判断能不能开硬件加速），这是引擎内部逻辑，作者不用管。

`renpy.warp.warp()` 是开发者用的“时空穿梭”功能（`renpy.sh <项目> warp <label>` 之类），让你直接从某个 label 启动游戏调试。正常玩时它是空操作。

`call _load_reload_game` 是 **shift+R 快速重载**的恢复点：开发者改完脚本按 shift+R 重载引擎，重载前会把当前存档槽临时记在 `renpy.session["_reload_slot"]`，重载后 `_load_reload_game` 检查这个值，若有效就立刻把玩家载回原处（而不是回到主菜单）。它放在 splash 之前，所以重载时不会重播开场动画。这一节先知道“有这么个 label”，第 23 章讲调试时会展开。

最后是**自动读档**：`config.auto_load` 指向一个存档槽（例如 `"auto-1"`），或环境变量 `RENPY_AUTO_LOAD` 覆盖它。若该槽存在且当前不是重启，就自动 `renpy.load(auto_load)`——一句话实现“开发商 demo：打开即从指定存档继续”。

**第四块：暂时关掉存档与历史。**

```renpy
    $ _old_game_menu_screen = _game_menu_screen
    $ _game_menu_screen = None
    $ _old_history = _history
    $ _history = False

    python hide:
        for i in config.main_menu_stop_channels:
            renpy.music.stop(channel=i, fadeout=0.0)
```

这两对 `_old_... = ...; ... = ...` 是“临时禁用再恢复”的写法：`_game_menu_screen = None` 表示**此刻点右键或按 Esc 打不开游戏菜单**（因为现在还没进入游戏），`_history = False` 表示**此刻不记录对话历史**（第 19 章讲过 `_history`）。它们会在后面被 `_old_...` 还原。

`config.main_menu_stop_channels` 默认是 `["sound", "voice", "movie"]`，这里对每个通道执行 `renpy.music.stop(...)`——**进主菜单前，把音效、语音、视频通道全部停掉**。注意列表里**没有 `"music"`**，因为主菜单自己要用 music 通道放 BGM（下一块就是）。这就是为什么“返回主菜单后，战斗音效停了但 BGM 是主菜单 BGM”。

**第五块：splashscreen（只跑一次）。**

```renpy
    if renpy.has_label("splashscreen") and (not _restart) and (not renpy.os.environ.get("RENPY_SKIP_SPLASHSCREEN", None)):
        call _splashscreen from _call_splashscreen_1
```

这一行的三个条件决定了开场动画**只在首次启动时播放**：

1. `renpy.has_label("splashscreen")`——你确实写了 `splashscreen` 这个 label；
2. `not _restart`——当前不是重启（不是从游戏返回主菜单，也不是 shift+R）；
3. `not RENPY_SKIP_SPLASHSCREEN`——环境变量没要求跳过。发布版和调试都能用它跳过一次开场动画，省时间。

三个条件同时满足才 `call _splashscreen`。`from _call_splashscreen_1` 是 `from` 子句（第 5 章讲过 `call` 要配 `from`），保证存档兼容。

紧接着那几行 `$ _game_menu_screen = _old_game_menu_screen` 就是上面第四块的“恢复现场”。

**第六块：主菜单 BGM 与最后的转场/跳转。**

```renpy
    if config.main_menu_music:
        $ renpy.music.play(config.main_menu_music, if_changed=True, fadein=config.main_menu_music_fadein)
    else:
        $ renpy.music.stop()

    scene black

    python:
        if renpy.has_screen("main_menu"):
            renpy.stop_predict_screen("main_menu")

        _init_window()

    python:
        if _restart is None:
            renpy.transition(config.end_splash_transition)
        else:
            renpy.transition(_restart[0])

            renpy.game.context().force_checkpoint = True
            renpy.jump(_restart[1])
```

`config.main_menu_music` 就是主菜单 BGM。注意 `if_changed=True`——**只有曲目没变时才不重新播放**，所以从游戏返回主菜单、主菜单 BGM 恰好还是同一首时，它不会被从头打断。`fadein=config.main_menu_music_fadein` 是淡入时长（默认 `0.0`，不淡入）。若 `config.main_menu_music` 是 `None`，则 `renpy.music.stop()` 停掉 music 通道（这也是默认行为，所以新手常问“为什么主菜单没音乐”——因为默认没设）。

最后这个 `python:` 块是**整个 `_start` 的分岔口**：

- `_restart is None`（首次启动）：`renpy.transition(config.end_splash_transition)`——播完 splash 后用一个转场淡入主菜单。`config.end_splash_transition` 默认 `None`（无转场），设成 `Dissolve(0.5)` 就是常见的“logo 淡出、主菜单淡入”。然后代码自然往下走，进入 `_invoke_main_menu`（下一个 label）。
- `_restart` 是三元组（重启）：`renpy.transition(_restart[0])` 播结尾转场，`force_checkpoint = True` 强制打一个存档检查点（第 16 章），然后 `renpy.jump(_restart[1])`——跳到三元组第二项 `"_invoke_main_menu"`。**这就是“返回主菜单”的路径：`_start` 只负责把转场和跳转做完。**

一句话总结 `_start`：**它是每一轮游戏的零点，负责把世界重置（store、回滚、语言、画面、音频），播放一次性的开场动画，然后决定去主菜单还是直接进剧情。**

## 21.3 splashscreen：只播一次的开机画面

`_start` 在满足三条件时会 `call _splashscreen`。这个 label 是“跳板”，全文如下：

```renpy
label _splashscreen:

    python:

        if config.splashscreen_suppress_overlay:
            renpy.dynamic(suppress_overlay=True, _confirm_quit=False)

        renpy.dynamic(_autosave=False)

    jump expression "splashscreen"
```

（`renpy/common/00start.rpy` 第 191–200 行）

它做两件事，然后**跳到你的 `splashscreen` label**：

1. `config.splashscreen_suppress_overlay`（默认 `True`）为真时，用 `renpy.dynamic(...)` 把两个变量临时改成：`suppress_overlay=True`（不显示右键菜单/快捷栏等 overlay，第 15 章）和 `_confirm_quit=False`（这期间点关闭不弹“确定要退出吗”，避免玩家在 logo 上误触弹窗）。
2. `renpy.dynamic(_autosave=False)`：**开场画面期间不自动存档**（第 16 章的自动存档）。

`renpy.dynamic` 是“临时改变量”的机制（第 18 章）：它设的值在当前 label（及其调用栈）结束后自动恢复，不用手动还原。这里正好用它把“开场画面这段特殊时期”和“正式游戏”隔开。

然后用 `jump expression "splashscreen"` 跳到你写的 label。注意这里是 `jump`（不是 `call`）——**你的 `splashscreen` 结尾 `return` 时，会回到 `call _splashscreen` 的下一行**（因为 `_splashscreen` 是被 `_start` 用 `call` 调起来的，`jump` 只是借道）。这个“跳板”设计的妙处是：你可以把 `splashscreen` 写成一条龙（`label splashscreen:` 里直接 `scene logo` + `with dissolve` + `pause`），也可以在里面 `call` 别的 label，结尾统一 `return` 即可。

**写一个免素材的开场动画。** 官方教程用一张图片做 logo，但我们强调“零素材可编译”，所以用引擎内建的 `Text` 显示物充当 logo——它把一个字符串当图像显示，不需要任何图片文件：

```renpy
# 开场动画：只用内建 Text 显示物，不需要任何图片素材。
label splashscreen:

    # scene 清屏，然后 show 一行“厂商 logo”文字。
    scene black
    show text "{size=64}{color=#ffffff}STARDUST LABS{/color}{/size}" as logo:
        # ATL：从透明到完全不透明，1.2 秒。
        alpha 0.0
        linear 1.2 alpha 1.0
    with Dissolve(0.4)

    # 停留 1.5 秒（玩家点击也能跳过 pause）。
    pause 1.5

    # logo 淡出。
    hide logo
    with Dissolve(0.8)

    # 开场结束，交还给 _splashscreen 的调用者（即 _start）。
    return
```

`show text "..." as logo` 中的 `as logo` 给这个显示物起了个名字，方便后面 `hide logo`。后面的 ATL 块（第 10 章）让文字从透明渐变到不透明。`pause 1.5` 停 1.5 秒（点击可跳过），然后淡出、`return`。整段不需要一张图、一段音频。

**关于 `end_splash_transition` 的配合。** 回想 `_start` 第六块的 `renpy.transition(config.end_splash_transition)`——它在 `_splashscreen` 返回**之后**执行。所以“logo 淡出后主菜单淡入”的完整做法是：

```renpy
define config.end_splash_transition = Dissolve(0.5)
```

logo 自己在 splashscreen 里淡出，然后引擎再用 `end_splash_transition` 把主菜单淡进来，两个转场衔接成一次流畅的开机体验。若不设，默认 `None` 就是硬切。

**跳过开场动画。** 三种方式：

- 玩家角度：开场动画里放一个 `pause`，或让玩家点击即可跳过（`pause` 支持点击继续）。
- 调试角度：游戏启动前设环境变量 `RENPY_SKIP_SPLASHSCREEN=1`，`_start` 的条件三不满足，直接不播。
- 只要不是首次启动就不会播（条件二的 `not _restart`）——所以从游戏返回主菜单、或 shift+R 重载，都不会再看到 logo。

## 21.4 主菜单：从 `_invoke_main_menu` 到你写的屏幕

`_start` 走到末尾，控制权交给下一个 label `_invoke_main_menu`：

```renpy
label _invoke_main_menu:

    # Again, this has to be Python.
    python:
        if _restart:
            renpy.call_in_new_context(_restart[2])
        elif not renpy.os.environ.get("RENPY_SKIP_MAIN_MENU", False):
            renpy.call_in_new_context("_main_menu")


    # If the main menu returns, then start the game.

    python:
        renpy.game.context().force_checkpoint = True
        renpy.jump("start")
```

（`renpy/common/00start.rpy` 第 293–307 行）

三行核心逻辑：

- 若是重启（`_restart` 有值）：`call_in_new_context(_restart[2])`，即调用三元组第三项 `"_main_menu"`。
- 若不是重启（首次启动）且没有 `RENPY_SKIP_MAIN_MENU` 环境变量：`call_in_new_context("_main_menu")`。
- 两种情况都是 `call_in_new_context`——**主菜单跑在一个全新的、临时的上下文里**（第 14 章讲过上下文的隔离性；第 20 章回放也用了新上下文隔离）。这解释了很多现象：主菜单里的回滚被隔离、玩法变量的修改在退出主菜单时不会带进游戏、等等。

关键在最后两行：**`call_in_new_context` 返回时**（也就是主菜单上下文结束，玩家点了“开始游戏”），执行 `force_checkpoint = True` + `renpy.jump("start")`——打一个存档检查点，然后跳到 `start` 开始剧情。**这就是“点开始游戏 → 进入剧情”的引擎侧实现。**

那主菜单本身呢？`_main_menu`：

```renpy
# At this point, we've been switched into a new context. So we
# initialize it.
label _main_menu(_main_menu_screen="_main_menu_screen"):

    python:
        renpy.block_rollback(purge=True)

        _enter_menu()

        renpy.dynamic(_load_prompt=False)

        renpy.context()._main_menu = True
        store.main_menu = True

    jump expression _main_menu_screen
```

（`renpy/common/00start.rpy` 第 309–323 行）

注意它是一个**带参数**的 label（`_main_menu_screen="_main_menu_screen"`）——默认参数是 `"_main_menu_screen"`，即默认跳到那个 label。它做四件事：`block_rollback(purge=True)` 清掉回滚点（主菜单里不能回滚，且顺手把旧的回滚日志清掉）；`_enter_menu()` 见下；`_load_prompt=False` 临时关掉读档提示；最后把上下文的 `_main_menu` 和 store 的 `main_menu` 都设成 `True`（双轨标记，第 15 章的屏幕会读 `main_menu` 判断自己是不是在主菜单里）。

`_enter_menu()` 定义在 `renpy/common/00gamemenu.rpy`：

```renpy
    def _enter_menu():
        config.skipping = None

        renpy.movie_stop(only_fullscreen=True)
        if not renpy.context()._menu:
            renpy.take_screenshot((config.thumbnail_width, config.thumbnail_height), keep_existing=config.keep_screenshot_entering_menu)

        for i in config.menu_clear_layers:
            renpy.scene(layer=i)

        renpy.context()._menu = True
        renpy.context()._main_menu = main_menu

        renpy.context_dynamic("main_menu")
        renpy.context_dynamic("_window_subtitle")
        renpy.context_dynamic("_window")
        renpy.context_dynamic("_history")
        renpy.context_dynamic("_menu")
```

（`renpy/common/00gamemenu.rpy` 第 80–97 行）

它做“进入任何系统菜单（主菜单、存档、设置……）都需要的准备工作”：停掉快进（`config.skipping = None`）、停全屏视频、若非从菜单进入则拍一张缩略图（存档缩略图就用它）、清空 `config.menu_clear_layers` 里列出的图层、标记 `_menu = True`，最后一批 `context_dynamic(...)` 声明这些变量在菜单上下文里是“动态变量”。

然后 `jump expression _main_menu_screen` 跳到 `_main_menu_screen`（默认就是 `"_main_menu_screen"`），它是一个**四级接管链**：

```renpy
# This is called to show the main menu to the user.
label _main_menu_screen:

    # Let the user give code that runs in the main menu context before
    # the main menu runs.
    if renpy.has_label("before_main_menu"):
        call expression "before_main_menu"

    # Let the user completely override the main menu. (But please note
    # it still lives in the menu context, rather than the game context.)
    if renpy.has_label("main_menu"):
        jump expression "main_menu"

    # New name.
    elif renpy.has_label("main_menu_screen"):
        jump expression "main_menu_screen"

    # Compatibility name.
    elif renpy.has_label("_library_main_menu"):
        jump expression "_library_main_menu"

    return
```

（`renpy/common/00start.rpy` 第 325–346 行）

按优先级，它依次尝试：

| 顺序 | 检查 | 你的机会 |
| --- | --- | --- |
| 0 | `before_main_menu` label | 在主菜单**显示前**跑一段代码（`call`，跑完继续），比如重置状态、播放开场音 |
| 1 | `main_menu` label | **完全接管**主菜单（`jump`，不再回来） |
| 2 | `main_menu_screen` label | 覆盖主菜单屏幕（新名字） |
| 3 | `_library_main_menu` label | 旧版兼容名 |
| 兜底 | 都没有则 `return` | 见下 |

**这里有个新手必然会困惑的点：** 新建项目的模板里，你明明只写了 `screen main_menu():`（在 `gui/game/screens.rpy`），并没有写 `label main_menu`，那上面四级全落空、直接 `return`——主菜单怎么还显示得出来？

答案是一条**隐藏的兜底链**：

1. `_main_menu_screen` 全落空 `return` → 控制回到 `_main_menu` 的调用处。
2. 但在此之前，`gui.init()`（模板的 `gui.rpy` 会调用）已经执行了 `layout.defaults()`。`layout.defaults()` 里有一行：

```python
        if renpy.has_screen("main_menu"):
            defaults["main_menu"] = layout.screen_main_menu
```

（`renpy/common/00layout.rpy` 第 124–125 行）

含义是：**只要你定义了 `screen main_menu`，引擎就把“主菜单提供者”注册为 `layout.screen_main_menu`**（`layout` 是第 15 章讲过的界面适配层）。

3. `layout.screen_main_menu` 指向一个内建模块 `_layout/screen_main_menu.rpym`，它的全部内容是：

```renpy
init python:

    layout.provides('main_menu')

label main_menu_screen:

    python hide:
        name = renpy.session.pop("_main_menu_screen", "main_menu")
        args = renpy.session.pop("_main_menu_screen_args", tuple())
        kwargs = renpy.session.pop("_main_menu_screen_kwargs", { })

        renpy.show_screen(name, *args, **kwargs)

        ui.interact()

    return
```

（`renpy/common/_layout/screen_main_menu.rpym`）

它做的事很直白：读一个 session 变量（若有）决定显示哪个屏幕，默认就是 `"main_menu"`，然后 `show_screen("main_menu")` + `ui.interact()`——**把你在 `screens.rpy` 里写的 `screen main_menu` 显示出来，并等待交互。** 而它自己就叫 `label main_menu_screen`，正好命中了上面四级链的第 2 级。

所以完整链路是：`_main_menu_screen` 第 2 级命中内建 `label main_menu_screen` → 该 label `show_screen("main_menu")` 显示你写的屏幕。**你没有写任何 label，是引擎的内建模块替你写了。** 理解了这条链，你就能三种方式定制主菜单：改屏幕（最轻，改 `screen main_menu`）、覆盖 `main_menu_screen` label（中，自己控制显示逻辑）、覆盖 `main_menu` label（最重，完全自己来，但仍在菜单上下文里）。

> 注意顶部 `init python: layout.provides('main_menu')` 的作用：`provides` 是声明“本模块提供名为 main_menu 的布局”，与 `layout.defaults()` 的 `defaults["main_menu"]` 对接。这套 `provides`/`defaults` 机制是引擎内部插件式布局的实现（第 15 章提过 layout），你不需要动它，但看懂它就不会被“主菜单从哪来”搞晕。

---

## 21.5 Start、MainMenu 与 `_restart`：四条回路

前面四节我们看到引擎骨架里藏着几个“重启信号”：`while True` 捕获 `QuitException` 与 `FullRestartException`，`utter_restart` 抛 `UtterRestartException`。这一节把它们与主菜单上的按钮连起来，让你彻底明白“点一下【开始游戏】”到底触发了什么。

先从最简单的【开始游戏】按钮说起——它就是 `Start()`：

```renpy
    @renpy.pure
    class Start(Action, DictEquality):
        """
        :doc: menu_action

        Causes Ren'Py to jump out of the menu context to the named
        label. The main use of this is to start a new game from the
        main menu. Common uses are:

        * Start() - Start at the start label.
        * Start("foo") - Start at the "foo" label.
        """

        def __init__(self, label="start"):
            self.label = label

        def __call__(self):
            renpy.jump_out_of_context(self.label)
```

（`renpy/common/00action_menu.rpy`，第 182-199 行）

`Start` 是一个 Action——被点击时执行 `__call__`，而它只做一件事：`renpy.jump_out_of_context(self.label)`。默认 `label="start"`，所以 `Start()` 就是“从 `start` 标签开始新游戏”；`Start("chapter2")` 则从任意标签开始（做章节选择、测试关卡时很有用）。

那 `jump_out_of_context` 是什么？看它的实现，短得出奇：

```python
def jump_out_of_context(label):
    """
    :doc: context

    Causes control to leave the current context, and then to be
    transferred in the parent context to the given label.
    """

    raise renpy.game.JumpOutException(label)
```

（`renpy/exports/contextexports.py`，第 55-63 行）

它只抛出一个 `JumpOutException`。这个异常会被谁接住？**就是那个用 `call_in_new_context("_main_menu")` 把主菜单调起来的地方**——即 `call_in_new_context` 自己。我们回看它的收尾段（第 21.1 节引过全貌，这里聚焦异常处理）：

```python
    try:
        context.goto_label(label)
        return renpy.execution.run_context(False)

    except renpy.game.JumpOutException as e:
        contexts[-2].force_checkpoint = True
        contexts[-2].abnormal = True
        raise renpy.game.JumpException(e.args[0])

    finally:
        contexts.pop()
        contexts[-1].do_deferred_rollback()

        if interface and interface.restart_interaction and contexts:
            contexts[-1].scene_lists.focused = None
```

（`renpy/game.py`，第 344-358 行）

把两段合起来读，`Start()` 的完整效果就清楚了：

1. `Start()` → `jump_out_of_context("start")` → 抛出 `JumpOutException("start")`。
2. 主菜单上下文（由 `call_in_new_context` 建立）里的执行循环收到异常，冒泡到上面这个 `except`。
3. `except` 做两件事：给**父上下文**（游戏上下文）打上 `force_checkpoint = True`（下一次交互强制产生检查点，回滚点才正确）与 `abnormal = True`；然后抛出 `JumpException("start")`。
4. `finally` 里 `contexts.pop()` 把主菜单上下文弹出销毁——**整个菜单上下文没了**。
5. 抛出的 `JumpException("start")` 冒泡到最外层的 `run_context(True)`，被解释为“当前上下文跳转到 `start` 标签”。

所以 `Start()` 的语义是：**退出菜单上下文，在游戏上下文里跳转到指定标签**。它不重启引擎、不重跑 `init`，只是从菜单上下文“跳出来”进入剧情——这也解释了为什么点【开始游戏】几乎没有延迟。

> 顺带补齐另一条路径。`_invoke_main_menu` 末尾那两行（第 21.4 节引过）：
>
> ```renpy
>     python:
>         renpy.game.context().force_checkpoint = True
>         renpy.jump("start")
> ```
>
> 这是“菜单**正常返回**（而不是被 `Start()` 跳出）”时的收尾：如果主菜单 label 自己 `return` 了（没有 `Start()`），引擎就补一句跳到 `start`。两条路径殊途同归——都是进入游戏上下文的 `start` 标签。

再看【返回主菜单】按钮 `MainMenu()`：

```renpy
    @renpy.pure
    class MainMenu(Action, DictEquality):
        """
        :doc: menu_action

        Causes Ren'Py to return to the main menu.

        `confirm`
            If true, causes Ren'Py to ask the user if he wishes to
            return to the main menu, rather than returning
            directly.

        `save`
            If true, the game is saved in :var:`_quit_slot` before Ren'Py
            restarts and returns the user to the main menu. The game is not
            saved if :var:`_quit_slot` is None.
        """

        save = True

        def __init__(self, confirm=True, save=True):
            self.confirm = confirm
            self.save = save

        def __call__(self):

            if not self.get_sensitive():
                return

            if self.confirm:
                if config.autosave_on_quit:
                    renpy.force_autosave()

                layout.yesno_screen(layout.MAIN_MENU, MainMenu(False, save=self.save))
            else:
                renpy.full_restart(config.game_main_transition, save=self.save)

        def get_sensitive(self):
            return not renpy.context()._main_menu
```

（`renpy/common/00action_menu.rpy`，第 202-240 行）

逐条看：

- `get_sensitive()` 返回 `not renpy.context()._main_menu`——**只有在游戏里（不在主菜单）时才敏感**。所以在主菜单上这个按钮是灰的。
- `confirm=True`（默认）时先问一句。`config.autosave_on_quit` 为真就先自动存一次档，然后调 `layout.yesno_screen(layout.MAIN_MENU, MainMenu(False, save=self.save))`——**弹确认框，并把“不带确认的 MainMenu”作为用户在框里点“是”后的动作**。这就是“两段式”：第一次点击弹框，点“是”才真正执行 `MainMenu(confirm=False)`。
- `confirm=False` 时直接调 `renpy.full_restart(config.game_main_transition, save=self.save)`。

`full_restart` 的实现：

```python
def full_restart(transition=False, label="_invoke_main_menu", target="_main_menu", save=False):
    """
    :doc: other
    :args: (transition=False, *, save=False)

    Causes Ren'Py to restart, returning the user to the main menu.

    `transition`
        If given, the transition to run, or None to not run a transition.
        False uses :var:`config.end_game_transition`.

    `save`
        If true, the game is saved in :var:`_quit_slot` before Ren'Py
        restarts and returns the user to the main menu.
    """

    if save and (renpy.store._quit_slot is not None):
        renpy.loadsave.save(renpy.store._quit_slot, getattr(renpy.store, "save_name", ""))

    if transition is False:
        transition = renpy.config.end_game_transition

    raise renpy.game.FullRestartException((transition, label, target))
```

（`renpy/exports/restartexports.py`，第 29-51 行）

关键在最后一行：`raise FullRestartException((transition, label, target))`。它抛出的**三元组**正是第 21.1 节 `main.py` 里 `except FullRestartException as e: restart = e.reason` 接住、并传给下一轮 `run()` 的东西。默认值：

- `transition` = `config.end_game_transition`（游戏 → 主菜单的转场）
- `label` = `"_invoke_main_menu"`（新一轮要跳到哪儿）
- `target` = `"_main_menu"`（主菜单上下文用哪个 label）

这个三元组最终以 `store._restart` 的形式进入脚本世界（`run()` 里那句 `renpy.store._restart = restart`），有**两个消费点**：

1. **`_start` 末尾的分岔**（第 21.2 节引过）：

   ```renpy
       if _restart is None:
           renpy.transition(config.end_splash_transition)
       else:
           renpy.transition(_restart[0])
           renpy.game.context().force_checkpoint = True
           renpy.jump(_restart[1])
   ```

   首次启动 `_restart` 是 `None`，走 `end_splash_transition` 继续往下；`full_restart` 之后 `_restart` 是那个三元组，于是用 `_restart[0]` 做转场、`renpy.jump(_restart[1])` 直接跳到 `_invoke_main_menu`——**跳过 splash，直接回主菜单**。这正是“返回主菜单时不会再播一遍开场动画”的原因。

2. **`_invoke_main_menu` 里**：

   ```renpy
       python:
           if _restart:
               renpy.call_in_new_context(_restart[2])
           elif not renpy.os.environ.get("RENPY_SKIP_MAIN_MENU", False):
               renpy.call_in_new_context("_main_menu")
   ```

   首次启动走 `elif` 调 `_main_menu`；重启后走 `if` 调 `_restart[2]`（也是 `"_main_menu"`）。两者等价，但重启路径允许你用 `full_restart(target="...")` 指定别的主菜单 label。

现在把四条“离开当前状态”的路径摆在一起对比。它们的**本质区别在于抛出的异常，以及 `main.py` 如何接住它**：

| 入口 | 调用方式 | 抛出的异常 | `main.py` 的响应 | 效果 |
| --- | --- | --- | --- | --- |
| `Start("label")` | Action / `renpy.jump_out_of_context` | `JumpOutException` | 无（在 `call_in_new_context` 内被转成 `JumpException`） | 退出菜单上下文，在**同一轮**游戏上下文里跳到 label |
| `MainMenu()` / `renpy.full_restart()` | Action / 函数 | `FullRestartException` | `restart = e.reason`，`while True` 开**新一轮** | （可选保存）→ 转场 → 回到 `_invoke_main_menu` |
| `renpy.utter_restart()` | 开发用（shift+R 链路） | `UtterRestartException` | 在最外层处理，**重新加载脚本并重跑 `init`** | 彻底重启（第 23 章详讲） |
| `renpy.quit()` | `Quit()` Action / 函数 | `QuitException` | `fadeout_all()` 后 `raise` 退出 | 若有 `quit` label 先执行它，再退出程序 |

再补 `Quit` 的细节——它和 `MainMenu` 一样是两段式，且 `confirm=None` 时“**只有在游戏里才问**”（在主菜单点退出不该再问一次）：

```python
        def __call__(self):

            confirm = self.confirm

            if confirm is None:
                confirm = (not main_menu) and _confirm_quit

            if confirm:
                if config.autosave_on_quit:
                    renpy.force_autosave()

                layout.yesno_screen(layout.QUIT, Quit(False))
```

（`renpy/common/00action_menu.rpy`，第 260-271 行）

而 `Quit` 最终调用的 `renpy.quit()` 会在退出前**先执行名为 `quit` 的 label**（如果存在）：

```python
    if save and (renpy.store._quit_slot is not None):
        renpy.loadsave.save(renpy.store._quit_slot, getattr(renpy.store, "save_name", ""))

    if renpy.exports.has_label("quit"):
        renpy.exports.call_in_new_context("quit")

    status |= renpy.test.testexecution.quit_handler()

    raise renpy.game.QuitException(relaunch=relaunch, status=status)
```

（`renpy/exports/restartexports.py`，第 127-135 行）

所以你可以写一个 `label quit:` 做“退出前的收尾”——记录统计、上传日志、说一句告别。它在**一个新的上下文**里运行（`call_in_new_context`），不会污染游戏状态。

把整个生命周期画成一个环：

```
        启动引擎 ──► while True ──► _start ──► [_splashscreen]
                         ▲                         │
                         │                         ▼
                         │                  _invoke_main_menu
                         │                         │
                         │                         ▼
                         │              [_main_menu 菜单上下文]
                         │              ┌──────────┴───────────┐
                         │        点【开始】            点【返回主菜单】
                         │              │                      │
                         │              ▼                      │
                         │     Start() ── JumpException ──► label start
                         │              │                      │
                         │              ▼                      │
                         │        剧情 / 游戏循环 ── full_restart() ──┐
                         │              │                            │
                         │        （点【退出】/ 剧本结束）             │
                         │              ▼                            │
                         └──── FullRestartException ◄────────────────┘
                                        │
                                  quit label ──► QuitException ──► 退出
```

**小结要点**：`Start()` 跳出菜单上下文进游戏（同一轮）；`MainMenu()`/`full_restart()` 抛 `FullRestartException` 开新一轮回主菜单；`utter_restart()` 连脚本都重载（开发用）；`renpy.quit()` 可选先跑 `quit` label 再退出。它们的共同点是——**都通过抛异常把控制权交回 `main.py` 的主循环**。这正是“一个 `while True`”设计的威力。

---

## 21.6 读档：两个阶段、一次上下文切换

读档是生命周期里最容易被误解的一段。很多人以为“读档 = 把变量覆盖回去就完了”，其实引擎把它拆成了**两个阶段**，中间还夹着一次**上下文切换**。这一节把 `load()` 的实现完整摊开。

读档入口是 `renpy.load()`：

```python
def load(filename):
    """
    :doc: loadsave

    Loads the game state from the save slot `filename` (e.g. '3-2' for page 3, slot 2). If the file is loaded
    successfully, this function never returns.
    """

    log_data, signature = location.load(filename)

    if not renpy.savetoken.check_load(log_data, signature):
        return

    try:
        json = slot_json(filename)
    except Exception as e:
        json = {}

    renpy.session["traceback_load"] = "_traceback" in json

    renpy.exports.call_in_new_context("_before_load")

    roots, log = loads(log_data)

    log.unfreeze(roots, label="_after_load")
```

（`renpy/loadsave.py`，第 614-638 行）

先注意 docstring 最后一句：**“如果加载成功，这个函数永不返回。”**——因为游戏状态已经被整个换掉、控制权跑进读出来的进度里去了。逐行看：

1. `log_data, signature = location.load(filename)`：把存档文件读成原始数据与签名。
2. `renpy.savetoken.check_load(...)`：校验签名（防止把别人的存档拿来用）。不通过就 `return`（安静失败）。
3. 读 slot 的 JSON 元信息，记录是否带 traceback（调试用）。
4. **`renpy.exports.call_in_new_context("_before_load")`**：在**新上下文**里跑 `_before_load`。**这一步发生在游戏状态被替换之前**——旧状态还在。
5. `roots, log = loads(log_data)`：把存档反序列化成“变量根集合 `roots`”与日志对象 `log`。
6. `log.unfreeze(roots, label="_after_load")`：真正“解冻”状态回去，并指定解冻完成后要跳转的 label 为 `_after_load`。

第 4 步与第 6 步就是**两个阶段**。先看阶段一 `_before_load`：

```renpy
# Called before a load.
label _before_load:

    if renpy.has_label("before_load"):
        call expression "before_load"

    python hide:
        for i in config.before_load_callbacks:
            i()

    return
```

（`renpy/common/00start.rpy`，第 88-98 行）

`_before_load` 给作者留了两个钩子：`label before_load`（你自己写的 label，用 `call` 调用，`return` 后还会回到这里）与 `config.before_load_callbacks`（回调列表）。**此时旧状态仍在**，所以 `before_load` 适合做“离开当前进度前的清理”——停止音乐、记日志、上报当前分数之类。

阶段二由 `log.unfreeze(...)` 触发，而它的实现其实只是**抛一个异常**：

```python
    def unfreeze(self, roots, label=None):
        """
        Used to unfreeze the game state after a load of this log
        object.

        @param roots: The roots returned from freeze.

        @param label: The label that is jumped to in the game script
        after rollback has finished, if it exists.
        """

        if not self.can_rollback(0, True):
            if not renpy.config.load_failed_label:
                raise Exception("Could not load the game. Perhaps the script changed in an incompatible way.")

        raise UnfreezeException(self, roots, label)
```

（`renpy/rollback.py`，第 1081-1096 行）

`UnfreezeException` 会被 `run_context` 接住，转而调用 `unfreeze_core` 真正解冻：

```python
    def unfreeze_core(self, roots, label=None):
        """
        Called after an UnfreezeException is raised to actually perform
        the unfreeze.
        """

        # Fix up old screens.
        renpy.display.screen.before_restart()

        # Set us up as the game log.
        renpy.game.log = self

        renpy.python.clean_stores()

        store_dicts = renpy.python.store_dicts

        for name, value in roots.items():
            if "." in name:
                store_name, name = name.rsplit(".", 1)
            else:
                store_name = "store"

            if store_name not in store_dicts:
                continue

            store = store_dicts[store_name]
            store.ever_been_changed.add(name)

            if value is deleted:
                if name in store:
                    del store[name]
            else:
                store[name] = value

        # Now, rollback to an acceptable point.

        greedy = getattr(renpy.store, "_greedy_rollback", True)
        greedy = renpy.session.pop("_greedy_rollback", greedy)

        self.rollback_core(0, label=label, greedy=greedy, on_load=True)
```

（`renpy/rollback.py`，第 1098-1139 行）

它做三件事：先修整旧屏幕（`renpy.display.screen.before_restart()`）、把自己设为当前日志、**清空 store 后把 `roots` 里的变量逐个写回**（带 `deleted` 标记的则删除），最后调 `rollback_core(..., on_load=True)` 回到一个可用点。就是在这次 `rollback_core` 里，游戏会跳到 `label="_after_load"`。看 `_after_load`：

```renpy
# This fixes up the context, if necessary, then calls the real
# after_load.
label _after_load:

    python:
        renpy.context()._menu = False
        renpy.context()._main_menu = False
        main_menu = False
        _in_replay = None

        # Older save games could have this set to non-None, so reset it.
        _side_image_attributes = None


    python hide:

        for i in config.after_load_callbacks:
            i()

        _init_language()

        if config.after_load_transition:
            renpy.transition(config.after_load_transition, force=True)

        if "_reload_time" in renpy.session:
            start = renpy.session.pop("_reload_time")
            import time

            if config.profile_reload:
                print("Reloading took:", time.time() - start, "seconds" )

        menu = renpy.session.pop("_reload_screen", None)

        if config.reload_menu and (menu is not None):
            renpy.run(ShowMenu(menu,
                *renpy.session.pop("_reload_screen_args", tuple()),
                **renpy.session.pop("_reload_screen_kwargs", { })
                ))

    if renpy.has_label("after_load"):
        jump expression "after_load"
    else:
        return
```

（`renpy/common/00start.rpy`，第 100-142 行）

`_after_load` 运行时**新状态已经就位**。它先修正上下文标志（`_menu = False`、`_main_menu = False`、`main_menu = False`，把“菜单模式”关掉；`_in_replay = None`；`_side_image_attributes = None` 是老存档兼容），然后依次：跑 `config.after_load_callbacks` → `_init_language()`（按当前语言偏好重新设定）→ 若配置了 `config.after_load_transition` 就跑转场 → 处理“重载脚本后恢复菜单”的 session 变量 → 最后若有 `label after_load` 就跳过去，否则直接 `return` 继续游戏。

两个阶段的时序：

| 阶段 | 在哪 | 游戏状态 | 你的钩子 | 适合做什么 |
| --- | --- | --- | --- | --- |
| 一 | `call_in_new_context("_before_load")` | **旧状态** | `label before_load` / `config.before_load_callbacks` | 离开前清理（停音乐、上报） |
| （中间） | `loads()` + `unfreeze_core()` | 正在被替换 | —— | —— |
| 二 | `_after_load` | **新状态** | `label after_load` / `config.after_load_callbacks` | 读档后修正（见下） |

现在讲**版本迁移**，这是 `after_load` 最实用、也最容易被讲错的地方。你在开发中会不断加新变量，老存档里没有这些变量；加载老存档时它们会是“未定义”吗？

答案藏在 `unfreeze_core` 调用的 `rollback_core` 里——它内部会执行一句 `renpy.exports.execute_default_statement(False)`（`rollback.py` 第 1041 行，注意参数是 `False`）。`execute_default_statement` 会遍历所有 `default` 语句：

```python
def execute_default_statement(start=False):
    """
    :undocumented:

    Executes the default statement.

    `start`
        This is true at the start of the game, and false at other
        times.
    """

    for i in renpy.ast.default_statements:
        i.execute_default(start)

    for i in renpy.config.after_default_callbacks:
        i()
```

（`renpy/exports/statementexports.py`，第 355-371 行）

每条 `default` 语句的 `execute_default` 长这样：

```python
    def execute_default(self, start):
        ...
        # Handle normal namespaces.
        d = renpy.python.store_dicts[self.store]

        defaults_set = d.get("_defaults_set", None)

        if defaults_set is None:
            d["_defaults_set"] = defaults_set = renpy.revertable.RevertableSet()
            d.ever_been_changed.add("_defaults_set")

        if self.varname in defaults_set:
            if start and renpy.config.developer:
                raise Exception("{}.{} is being given a default a second time.".format(self.store, self.varname))
            return
        ...

        if start or (self.varname not in d.ever_been_changed):
            d[self.varname] = renpy.python.py_eval_bytecode(self.code.bytecode)

        d.ever_been_changed.add(self.varname)

        defaults_set.add(self.varname)
```

（`renpy/ast.py`，第 2557-2593 行，省略了几条仅开发者模式生效的校验）

关键在 `_defaults_set`：它是一个“**已经赋过默认值的变量名集合**”，而且**随存档一起被保存**。于是读档时：

- 存档里**已有**的变量：它的名字在恢复回来的 `_defaults_set` 里，`execute_default` 走到 `if self.varname in defaults_set: ... return` 就**直接返回，不覆盖**——你的进度不会被打回默认值。
- 更新后**新增**的 `default` 变量：它的名字不在老存档的 `_defaults_set` 里，于是执行 `d[self.varname] = ...`，**自动补上默认值**。

**结论**：新增 `default` 变量，老存档能自动获得默认值，**无需**写 `after_load` 迁移代码。真正需要 `after_load` 的是**语义迁移**——“变量名还在、但含义变了”或“结构变了”的情况。例如：

- 把一个 `default score = 0` 改成 `default score = 0.0`（类型变了，老存档里仍是整数）；
- 把 `default inventory = []` 改成 `default inventory = {}`（结构变了）；
- 把若干分散变量合并成一个字典，需要把老存档的旧字段“搬运”到新结构里。

这些场景 `_defaults_set` 帮不了你（变量名还在，不会被重置），得自己在 `after_load` 里手写迁移：

```renpy
label after_load:

    # 语义迁移：把老版本的数据搬进新结构
    python:
        # 例 1：老存档没有 save_version——虽然 default 能兜底，
        #       但为了记录“这条存档来自哪个版本”，我们显式补齐。
        if not hasattr(store, "save_version"):
            save_version = 1

        # 例 2：类型/结构变了，需要转换
        if isinstance(score, int):
            score = float(score)

        # 例 3：老存档把数据放在别的变量里，搬过来
        if hasattr(store, "old_items") and not hasattr(store, "items"):
            items = list(old_items)
            del store.old_items

    return
```

> 一句口诀：**“加字段靠 default，改含义靠 after_load。”** 加新 `default`，引擎自动补；改旧变量的含义或结构，才写 `after_load`。

顺带一提 `label before_load` 的典型用途——它运行在**旧状态**上，适合“读档前先把当前这局未保存的东西记下来”，或“停掉正在播放的音乐/视频”：

```renpy
label before_load:
    # 此时还是旧进度：先停掉当前音乐，避免读档后残留
    stop music fadeout 0.5
    return
```

> 注意 `before_load` 在**新上下文**里运行，对 `store` 的修改不会写回游戏，所以这里更适合做“有副作用的清理”，而不是改游戏变量。

**小结要点**：读档 = `_before_load`（旧状态、新上下文）+ 反序列化 + `_after_load`（新状态，由 `unfreeze_core → rollback_core` 调起）。新增 `default` 变量读档会自动补值（靠随存档保存的 `_defaults_set`）；`after_load` 的真正用途是**语义/结构迁移**。

---

## 21.7 综合实战：`19_lifecycle` 生命周期演示

这一节把前六节的知识组装成一个可运行的示例工程 `examples/19_lifecycle/`。它把生命周期的每个阶段都挂上一个可观察的“信号”，而且**完全不依赖图片或音频素材**——所有视觉效果都用内建转场与纯文字实现。

工程结构：

```
19_lifecycle/
└── game/
    ├── options.rpy     # 配置：主菜单音乐、转场
    ├── gui.rpy         # 极简 GUI 初始化
    ├── screens.rpy     # 主菜单屏幕（含 dialogue/choice 屏幕）
    └── script.rpy      # 生命周期各阶段的 label
```

先说 `options.rpy`：

```renpy
define config.name = _("生命周期演示")
define config.version = "1.0"

# 免素材：用引擎内置的静音伪文件当作主菜单音乐（第 20 章讲过音频的特殊文件名）
define config.main_menu_music = "<silence 30.0>"

# 转场全部用内建转场，无需任何图片
define config.end_splash_transition = Dissolve(0.5)   # 开场动画 → 主菜单
define config.end_game_transition = Dissolve(0.5)     # 游戏 → 主菜单

define config.developer = True
```

`config.main_menu_music = "<silence 30.0>"` 用的是一种特殊文件名：`<silence 秒数>` 会让引擎播放一段指定时长的静音（见 `renpy/audio/audio.py` 第 457-459 行——引擎把 `silence` 子句解析成 `_silence.ogg`）。这样我们既演示了“主菜单 BGM”的配置，又不需要准备音频文件。

再说 `gui.rpy`。这里有个**必须注意的坑**，正是第 21.4 节末尾埋下的伏笔：

```renpy
init offset = -2

# 关键只有一行：gui.init() 会顺带调用 layout.defaults()，
# 把内建的 main_menu 布局注册进 layout，主菜单才能被显示。
init python:
    gui.init(1280, 720)
```

为什么这行不能省？回看 `layout.defaults()`（第 21.4 节）：它把 `defaults["main_menu"] = layout.screen_main_menu` 写进布局表，而 `_main_menu_screen` 的四级接管链**只有靠它注册的 `label main_menu_screen` 才能显示你写的 `screen main_menu`**。`layout.defaults()` 的调用点非常少——只有 `gui.init()`（`renpy/common/00gui.rpy` 第 58 行）与 00themes 里的主题函数会调它。所以：**如果一个极简工程既不写 `gui.rpy` 调 `gui.init()`、也不应用主题，那么 `_main_menu_screen` 四级全部落空、直接 `return`，主菜单会被跳过、直奔 `label start`。** 这就是这个示例必须保留 `gui.rpy` 的原因。

`screens.rpy` 只保留生命周期演示必需的几个屏幕。核心是主菜单屏幕（`Start()`、`MainMenu()`、`Quit()` 都在这里被调用）：

```renpy
screen main_menu():

    tag menu

    add Solid("#1a1a2e")          # 纯色背景，代替背景图

    vbox:
        align (0.5, 0.35)
        spacing 20
        text "生命周期演示" xalign 0.5 size 48 color "#ffffff"

        # 你已打开主菜单的次数（由 before_main_menu 统计，见 script.rpy）
        text "主菜单打开次数：[persistent.menu_visits]" xalign 0.5 size 20 color "#aaaaff"

    vbox:
        align (0.5, 0.7)
        spacing 12

        textbutton "开始游戏" action Start()          # 第 21.5 节：跳出菜单上下文进 start
        textbutton "退出"     action Quit(confirm=False)   # 主菜单上直接退出，不再问
```

（`screens.rpy` 里还需要 `screen say`、`screen choice` 等基础屏幕，以及样式定义，这些属于第 11 章的 GUI 内容，此处从略——示例工程里给出了完整可运行版本。）

主菜单里 `Start()` 与 `Quit(confirm=False)` 正是第 21.5 节讲的 Action：前者 `jump_out_of_context("start")`，后者走 `Quit` 的 `__call__` → `renpy.quit()`。

现在是重头戏 `script.rpy`，生命周期的六个阶段各对应一个 label：

```renpy
# 默认值：persistent 里从未赋值过的字段一律是 None（renpy/persistent.py
# 第 67-71 行，Persistent.__getattr__ 对未知字段直接返回 None、并不抛出
# AttributeError），所以这里必须用 default 给出初值 0——主菜单屏幕里的
# 「打开次数」才能显示 0 而不是 None，计数也才能从 0 开始加。
default persistent.menu_visits = 0

# ===========================================================================
# 阶段 1：开场动画（splashscreen）——只在“首次启动”时播放一次
# ===========================================================================
label splashscreen:

    scene black
    with Pause(0.3)

    # 用纯文字当 logo，配合 ATL 做淡入 → 停留 → 淡出
    show text "{size=+40}生命周期演示{/size}" as logo:
        alpha 0.0
        linear 0.8 alpha 1.0
        pause 1.0
        linear 0.5 alpha 0.0

    # show 只是创建图层；用一个 pause（本身是一次交互）推进并等 ATL 演完
    pause 2.4

    hide logo

    return   # 返回后，引擎按 config.end_splash_transition 转场进主菜单

# ===========================================================================
# 阶段 2：进入主菜单前（before_main_menu）——每次回主菜单都会跑
# ===========================================================================
label before_main_menu:

    # 记录“打开主菜单的次数”，存进 persistent（第 15 章）
    $ persistent.menu_visits += 1

    return

# ===========================================================================
# 阶段 3：主菜单本身在 screens.rpy 的 screen main_menu（见上）
# ===========================================================================

# ===========================================================================
# 阶段 4：游戏主流程（start）
# ===========================================================================
label start:

    scene black
    with Dissolve(0.5)

    "你已经在游戏里了。"

    "点【返回主菜单】会触发 full_restart（第 21.5 节）；"
    "点【退出】会走 quit label（本文件末尾）。"

    # 一个简单循环，方便反复试验各条回路
    menu:
        "返回主菜单":
            $ renpy.full_restart()
        "查看持久化计数":
            "你已经打开主菜单 [persistent.menu_visits] 次了。"
            jump start
        "结束这段演示":
            "演示结束。"
            return

# ===========================================================================
# 阶段 5：读档后（after_load）——语义迁移的入口
# ===========================================================================
label after_load:

    # 新增 default 变量引擎会自动补默认值（第 21.6 节）；
    # 这里演示“结构/含义变化”时才需要的迁移。
    if not hasattr(store, "save_version"):
        $ save_version = 1

    $ renpy.notify("读档完成，存档版本：[save_version]")

    return

# ===========================================================================
# 阶段 6：退出前（quit）——renpy.quit() 会先运行这个 label
# ===========================================================================
label quit:

    # 此时即将退出、不会再回到游戏，适合做最后一次记录
    $ persistent.last_quit = "用户在游戏里退出"

    return
```

逐段对应前文的机制：

- **`label splashscreen`（阶段 1）** —— 由 `_start` 里那段 `if has_label("splashscreen") and (not _restart) and (not RENPY_SKIP_SPLASHSCREEN): call _splashscreen` 调起（第 21.2 节）。`_splashscreen` 用 `renpy.dynamic` 临时关掉 overlay 与自动存档，再 `jump expression "splashscreen"` 进到你写的这个 label。它**只在首次启动时播**（`not _restart` 保证返回主菜单时不再播）。ATL 的 `alpha` 渐变与 `pause 2.4` 配合，把“logo 淡入 → 停留 → 淡出”演完，然后 `return`，引擎按 `config.end_splash_transition` 转场。
- **`label before_main_menu`（阶段 2）** —— 由 `_main_menu_screen` 的第一级 `if has_label("before_main_menu"): call expression "before_main_menu"` 调起（第 21.4 节）。它在**菜单上下文**里运行，所以这里对 `persistent` 的修改会落盘，但对普通 `store` 变量的修改不会带到游戏里。用它做“每次进主菜单都要做的统计/检查”正合适。
- **`label start`（阶段 4）** —— `Start()` 跳出菜单上下文后落到这里（或 `_invoke_main_menu` 末尾的兜底 `jump("start")`）。菜单里的 `$ renpy.full_restart()` 展示第 21.5 节的 `FullRestartException` 回路。
- **`label after_load`（阶段 5）** —— 由 `_after_load` 末尾的 `if has_label("after_load"): jump expression "after_load"` 调起（第 21.6 节）。这里演示语义迁移。
- **`label quit`（阶段 6）** —— 由 `renpy.quit()` 里的 `if has_label("quit"): call_in_new_context("quit")` 调起（第 21.5 节）。

**如何观察每一条回路**：

| 操作 | 你会看到 | 对应机制 |
| --- | --- | --- |
| 启动游戏 | 黑底、白字 logo 淡入淡出，再转场进主菜单 | `splashscreen` 只播一次 |
| 每次回到主菜单 | “主菜单打开次数”递增 | `before_main_menu` + `persistent` |
| 点【开始游戏】 | 几乎立刻进入剧情（无重启感） | `Start()` → `JumpOutException` |
| 游戏里点【返回主菜单】 | 转场后回到主菜单，**不再播 logo** | `full_restart()` → `FullRestartException`，`_restart` 被消费 |
| 在游戏里读一个档 | 弹出“读档完成，存档版本：1” | `after_load` |
| 点【退出】 | 记录 `persistent.last_quit` 后退出 | `quit` label |

这个示例把“看不见的引擎骨架”变成了“看得见的阶段信号”。把源码与现象对照着跑一遍，第 21 章讲的一切就都落地了。

---

## 21.8 本章小结与实践

**小结表**

| 知识点 | 要点 |
| --- | --- |
| 生命周期骨架 | `main.py` 里一个 `while True`；每轮 `run(restart)`，`restart` 初值为 `None`，由 `FullRestartException.reason` 更新 |
| `_start` 的六件事 | default/语言 → 预热主菜单 → warp/重载/自动读档 → 停通道 → splashscreen → 主菜单 BGM 与最后分岔 |
| `splashscreen` | 只在 `not _restart` 时播一次；`_splashscreen` 用 `renpy.dynamic` 临时关 overlay 与自动存档 |
| 主菜单从哪来 | `_invoke_main_menu` → `call_in_new_context("_main_menu")` → `_main_menu_screen` 四级接管链 |
| 四级接管链 | `before_main_menu`（call）→ `main_menu`（jump）→ `main_menu_screen`（jump）→ `_library_main_menu`（jump）→ 全无则 return |
| `layout.defaults()` | 只有 `gui.init()` 或主题函数会调它；不调它则 `_main_menu_screen` 全落空、主菜单被跳过 |
| `Start()` | `jump_out_of_context` → `JumpOutException` → 被 `call_in_new_context` 转成 `JumpException`；同一轮内跳 label |
| `MainMenu()`/`full_restart()` | 抛 `FullRestartException((transition, label, target))` → 新开一轮回主菜单；`_restart` 在 `_start` 与 `_invoke_main_menu` 两处被消费 |
| `utter_restart()` | 连脚本重载、重跑 `init`；开发用（shift+R 链路，第 23 章） |
| `renpy.quit()` | 若有 `quit` label 先在新上下文里执行它，再抛 `QuitException` 退出 |
| 读档两阶段 | `_before_load`（旧状态、新上下文）+ `_after_load`（新状态，`unfreeze_core → rollback_core` 调起） |
| default 与迁移 | `_defaults_set` 随存档保存 → 已有变量不重置、新增 `default` 自动补值；结构/含义变化才写 `after_load` |

**实践题**

1. **改一条回路。** 把 `19_lifecycle` 主菜单的【开始游戏】改成从 `chapter_two` 标签开始（提示：`Start("chapter_two")`，并补一个 `label chapter_two` 直接 `return` 回主菜单）。观察“同一轮内跳转”与“`full_restart` 开新一轮”在现象上的差别——具体说，哪一种会让“主菜单打开次数”增加？

2. **让 splash 可控重播。** 现在 `splashscreen` 只在首次启动时播。请设计一种方法，让玩家在设置里开启“每次启动都播开场动画”后，`full_restart` 回来也能再看到它。（提示：`_restart` 非 `None` 时 `_start` 会 `jump(_restart[1])` 跳过 splash。你可以让某个 Action 不用 `full_restart` 而改用 `renpy.jump_out_of_context` 之外的方式……想一想，真正要让 splash 再播，应该改哪一处？）

3. **写一次真实迁移。** 假设你的游戏 v1 里分数是 `default score = 0`（整数），v2 改成用 `default score = 0.0`（浮点）并表示百分比。请写一个 `after_load`，把老存档里的整数分数安全地转成新表示；再解释为什么**仅靠 `default` 语句**无法完成这次迁移。

---

上一章：[20 画廊、音乐室与回放](ch20-gallery-music-replay.md) · 下一章：[22 项目组织与配置：从目录到 settings](ch22-project-and-config.md)
