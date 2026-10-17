# 第 20 章 画廊、音乐室与回放

通关后的“收集要素”——CG 画廊、音乐鉴赏、剧情回放——是视觉小说的标配。本章把它们一次讲完。你会发现三者的骨架惊人地一致：

1. **解锁数据**：某件事发生过（看过这张 CG / 听过这首曲子 / 走到过这个结局）；
2. **存储位置**：persistent（第 17 章）——因为收集进度必须跨周目、跨存档存在；
3. **展示屏幕**：网格 + 锁定遮罩（画廊）、曲目列表（音乐室）、入口按钮 + 特殊运行模式（回放）。

三块基石的分工一张表定下来：

| 收集类型 | 解锁判定 | 记录者 | 展示载体 |
| --- | --- | --- | --- |
| CG / 立绘 | 自己维护的 persistent 集合（或 `renpy.seen_image()`） | 你在展示 CG 的剧本处记录 | 自制画廊屏幕（20.4） |
| 音乐 | `renpy.seen_audio(文件名)` | **引擎自动**（20.3 详述） | `MusicRoom` 类（20.3） |
| 剧情回放 | `renpy.seen_label(label)` | 引擎自动（label 执行过即 seen） | `Replay` 动作（20.2） |

第 17.2 节已经写过最小画廊。本章在此基础上升级出三个“成品级”功能：回放系统、音乐室、分页画廊，最后合并成一个完整的“收集品”菜单。

## 20.1 回放：Replay 与 EndReplay

回放（Replay，文档里也叫 memory）的本质是：**在一条全新的执行上下文里，从指定 label 重新跑到指定结尾，然后原样回到你点击按钮的那个画面**。玩家在画廊里点“结局 A”，引擎把 store 清干净、开新上下文、跳到 `label end_a`，玩家看完，右键点“结束回放”，回到画廊——普通存档、回滚记录、周目进度一概不受影响。

这一切由两个动作驱动。`Replay` 的源码全文（`renpy/common/00action_other.rpy`）：

```python
    # Transitions used when entering and leaving replays.
    config.enter_replay_transition = None
    config.exit_replay_transition = None

    @renpy.pure
    class Replay(Action, DictEquality):
        """
        :doc: replay

        An action that starts `label` as a replay.

        `scope`
            A dictionary mapping variable name to value. These variables are set
            when entering the replay.

        `locked`
            If true, this action is insensitive and will not do anything when triggered.
            If false, it will behave normally. If None, it will be locked if the label
            has not been seen in any playthrough.
        """

        def __init__(self, label, scope={}, locked=None):
            self.label = label
            self.scope = scope
            self.locked = locked

        def __call__(self):

            if not self.get_sensitive():
                return

            if config.enter_replay_transition:
                renpy.transition(config.enter_replay_transition)

            renpy.call_replay(self.label, self.scope)

            if config.exit_replay_transition:
                renpy.transition(config.exit_replay_transition)

        def get_sensitive(self):
            if self.locked is not None:
                return not self.locked

            return renpy.seen_label(self.label)
```

逐条拆：

- **`locked` 参数的三态设计**是精妙之处。`locked=True`：永远不敏感（14 章的三态模型：按钮灰掉）；`locked=False`：永远可用；`locked=None`（默认）：**敏感度 = `renpy.seen_label(self.label)`**——这个 label 在任何一次游玩中执行过，按钮才可点。也就是说，默认行为就是“没解锁的结局自动变灰”，你不用写任何 if。这就是 20 开头表格里“回放的解锁判定是 seen_label”的全部实现。
- **`__call__`** 的三步：先再查一次敏感度（保险），进入转场（`config.enter_replay_transition` 默认 None，即无转场，想加淡入设它即可），然后 `renpy.call_replay()`——重活全在这个函数里，下面细看——出来后播放退出转场。
- **`scope` 参数**：进入回放时设置的变量初值。比如同一个结局 label 想按路线微调开场白，可以 `Replay("end_a", scope={"route": "sea"})`，回放里 `route` 变量开局就是 `"sea"`。
- 注意 `@renpy.pure`：Replay 是纯动作，可以安全出现在被预测的屏幕里。

按钮的另一半是 `EndReplay`——回放期间玩家用来退出的动作，源码紧接着 `Replay`：

```python
    @renpy.pure
    class EndReplay(Action, DictEquality):
        """
        :doc: replay

        Ends the current replay.

        `confirm`
            If true, prompts the user for confirmation before ending the
            replay.
        """
        def __init__(self, confirm=True):
            self.confirm = confirm

        def __call__(self):

            if not self.get_sensitive():
                return

            if self.confirm:
                layout.yesno_screen(layout.END_REPLAY, EndReplay(False))
            else:
                renpy.end_replay()

        def get_sensitive(self):
            return _in_replay
```

- **`get_sensitive` 返回 `_in_replay`**——一个 store 里的内置变量，不在回放中时是 None（假），回放中是当前回放的 label 名。回放结束的按钮只该在回放中存在，这一个表达式就是全部逻辑。
- **`confirm=True` 默认先弹确认框**（`layout.yesno_screen` 就是 15.9 拆过的 confirm 屏幕后端），确认后用 `confirm=False` 的副本真正退出——两段式提交，避免误触。
- `renpy.end_replay()` 的实现极其直白（`renpy/exports/contextexports.py`）：

  ```python
  def end_replay():
      """
      :doc: replay

      If we're in a replay, ends the replay immediately. Otherwise, does
      nothing.
      """

      if renpy.store._in_replay:
          raise renpy.game.EndReplay()
  ```

  抛出一个 `EndReplay` 异常！这个异常一路抛到 `call_replay` 的 except 里（马上看到），被接住后正常收尾。用异常做控制流，是引擎在“从任意深度随时退出”场景下的惯用法。

现在钻进 `renpy.call_replay()`（`renpy/game.py`）。这是回放的心脏，全文引用：

```python
def call_replay(label, scope={}):
    """
    :doc: replay

    Calls a label as a memory.

    The `scope` argument is used to set the initial values of variables in the
    memory context.
    """

    renpy.display.focus.clear_focus()

    renpy.game.log.complete()

    old_log = renpy.game.log
    renpy.game.log = renpy.python.RollbackLog()

    sb = renpy.python.StoreBackup()
    renpy.python.clean_stores()

    context = renpy.execution.Context(True)
    contexts.append(context)

    if renpy.display.interface is not None:
        renpy.display.interface.enter_context()

    # This has to be here, to ensure the scope stuff works.
    renpy.exports.execute_default_statement()

    for k, v in renpy.config.replay_scope.items():
        stores = k.split(".")
        current_obj = renpy.store

        for store in stores[:-1]:
            current_obj = getattr(current_obj, store)

        setattr(current_obj, stores[-1], v)

    for k, v in scope.items():
        stores = k.split(".")
        current_obj = renpy.store

        for store in stores[:-1]:
            current_obj = getattr(current_obj, store)

        setattr(current_obj, stores[-1], v)

    renpy.store._in_replay = label

    try:
        context.goto_label("_start_replay")
        renpy.execution.run_context(False)

    except EndReplay:
        pass

    finally:
        context.pop_all_dynamic()

        contexts.pop()
        renpy.game.log = old_log
        sb.restore()

        if interface and interface.restart_interaction and contexts:
            contexts[-1].scene_lists.focused = None

        renpy.config.skipping = None

    if renpy.config.after_replay_callback:
        renpy.config.after_replay_callback()
```

结合第 16 章的存档与回滚知识，这段代码可以完整读懂：

1. **备份并清洗 store**：`StoreBackup()` 拍快照，`clean_stores()` 把所有 store 变量清回初始——回放是从“干净的一周目”开始的，带不进任何当前进度（除了 scope 显式给的）。
2. **全新的回滚日志与上下文**：`renpy.game.log = RollbackLog()` 换新、`contexts.append(context)` 压新上下文。这就是“回放不影响正片”的机制层保证——回滚记录完全隔离。
3. **default 语句重新执行**：`execute_default_statement()` 让所有 `default` 变量在干净 store 上就位（16 章讲过 default 是兜底安全网，这里体现了它的价值：回放里不需要你手动初始化变量）。
4. **两轮 scope 注入**：先注入 `config.replay_scope`，再注入 `Replay` 的 `scope` 参数。而 `config.replay_scope` 的默认值非常值得抄下来（`renpy/config.py` 第 733 行）：

   ```python
   replay_scope = {"_game_menu_screen": "preferences"}
   ```

   `_game_menu_screen` 是 15.7 讲过的“右键呼出的屏幕名”。回放期间它被固定成 `preferences`——**玩家在回放里按右键只能进设置页，不能存档、不能读档、不能看历史**。这就是“回放里存档没意义”这句话在引擎层的落点：不是靠警告，而是直接把入口改掉。
5. **`_in_replay = label`**：现在你看到这个变量是谁设的了。它一设，`EndReplay` 变敏感、navigation 屏幕里 15.7 那句 `if _in_replay` 分支生效、你的剧本代码也能用它判断“我是否在回放中”。
6. **跳到 `_start_replay` 并跑起来**：`goto_label("_start_replay")`。这个 label 在 `renpy/common/00start.rpy`：

   ```renpy
   label _start_replay:

       call _start_store

       scene black

       $ _init_language()
       $ renpy.block_rollback(purge=True)

       jump expression _in_replay
   ```

   干净利落：初始化 store 状态（`_start_store` 里把 `main_menu` 等标志归位）、黑屏、**`block_rollback(purge=True)` 清掉回滚缓冲**（16.5 讲过 purge 版本连历史锚点一起清——回放开局不该能往回滚到引擎内部状态），然后 `jump` 进玩家指定的结局 label。
7. **退出靠异常，现场靠 finally**：结局剧本的任何地方调用 `EndReplay`（或玩家点确认框）→ `EndReplay` 异常抛出 → `except EndReplay: pass` 接住 → `finally` 里 `sb.restore()` 把 store 恢复成快照、旧回滚日志换回来、上下文弹出。画廊画面原封不动地回来了。`renpy.config.skipping = None` 顺手关掉快进状态。
8. **收尾回调**：`config.after_replay_callback` 若被设为函数，退出回放后调用一次——可以在这里刷新画廊（不过 persistent 解锁数据本来就是即时的，一般不需要）。

**一个必须知道的语义**：回放里修改 persistent **不会被回滚吞掉**。第 17 章讲过 persistent 脱离回滚系统，所以“在回放里看 CG 时顺手解锁画廊条目”这类设计天然成立。反过来这也意味着：回放里千万别让 persistent 记录“只该在正片发生”的事。

最后把使用方写全。结局 label 的正确姿势：

```renpy
label end_a:

    scene bg beach with fade

    "我们在海边看到了日出。"

    # 解锁画廊条目（persistent 不回滚，放心写）
    $ persistent.cg_seen.add("cg_sunrise")

    # 给玩家一个明确的出口
    menu:
        "结束回忆":
            $ EndReplay()

    return
```

两个要点：第一，`$ EndReplay()` 把动作当作函数调用（14 章讲过 `renpy.run` 之外直接调用的写法），它内部会弹确认框；结尾的 `return` 是保险——万一玩家不点菜单一路快进到结尾，return 会在回放上下文里自然结束（`call_replay` 的 `run_context` 返回，效果等同退出回放）。第二，label 名字就是 20 开头说的解锁判定——`Replay("end_a")` 的按钮灰不灰，取决于 `seen_label("end_a")`，而“seen”的定义是**这个 label 被执行过**。所以结局 label 应该设计成“一进就代表解锁”的形态：把解锁判定放在最开头，而不是结尾。

画廊入口（完整代码在 20.5 汇总）：

```renpy
textbutton "结局：海的尽头" action Replay("end_a")
textbutton "结局：山的那边" action Replay("end_b")
```

没解锁时自动灰色——这就是 `locked=None` 的默认语义在替你干活。

## 20.2 音乐室：MusicRoom 类

音乐室的解锁判定不是你记的 flag，而是 `renpy.seen_audio(文件名)`。这个函数查 `persistent._seen_audio` 字典，而填充它的代码在引擎音频模块里（`renpy/audio/audio.py`，`enqueue` 方法内）：

```python
        with lock:
            for filename in filenames:
                if renpy.exports.is_seen_allowed():
                    filename, _, _, _ = self.split_filename(filename, False)
                    renpy.game.persistent._seen_audio[str(filename)] = True
```

含义：**任何音频文件只要被入队播放过（在允许记录的场景下），就被永久标记为“已听过”**。跨周目、跨存档、自动完成。你什么都不用做——第 5 章里每一句 `play music xxx` 都在默默填充音乐室的解锁数据。需要手动标记时用 `renpy.mark_audio("文件名")`（16 章列过）。

展示层不用从零写：引擎提供了 `MusicRoom` 类（`renpy/common/00musicroom.rpy`），负责“曲库管理 + 解锁过滤 + 顺序/随机播放”。先看构造函数与 add：

```python
    class MusicRoom(object):
        """
        :doc: music_room class

        A music room that contains a series of songs that can be unlocked
        by the user, and actions that can play entries from the list in
        order.
        """

        loop = False

        loop_compat = False

        def __init__(self, channel="music", fadeout=0.0, fadein=0.0, loop=True, single_track=False, shuffle=False, stop_action=None):
            """
            `channel`
                The channel that this music room will operate on.

            `fadeout`
                The number of seconds it takes to fade out the old
                music when changing tracks.

            `fadein`
                The number of seconds it takes to fade in the new
                music when changing tracks.

            `loop`
                Determines if playback will loop or stop when it reaches
                the end of the playlist.

            `single_track`
                If true, only a single track will play. If loop is true,
                that track will loop. Otherwise, playback will stop when the
                track finishes.

            `shuffle`
                If true, the tracks are shuffled, and played in the shuffled
                order. If false, the tracks are played in the order they're
                added to the MusicRoom.

            `stop_action`
                An action to run when the music has stopped.

            Single_track and shuffle conflict with each other. Only one should
            be true at a time. (Actions that set single_track and shuffle
            enforce this.)
            """
```

参数逐个说：`channel` 用哪个音频通道（默认 music——第 6 章的通道体系在这里生效；想让鉴赏不影响背景音乐就开一个专用通道如 `"jukebox"` 并在 options 里注册）；`fadeout`/`fadein` 换曲淡入淡出秒数；`loop` 播完列表是否循环；`single_track` 只放单曲（配合 loop 就是单曲循环）；`shuffle` 随机顺序；`stop_action` 音乐停下的瞬间触发的动作（配合 `periodic` 机制实现“停止时切换画面”之类效果）。文档末句注意：`single_track` 与 `shuffle` 互斥。

解锁判定的核心方法：

```python
        def is_unlocked(self, filename):
            """
            :doc: music_room method

            Returns true if the filename has been unlocked (or is always
            unlocked), and false if it is still locked.
            """

            if filename in self.always_unlocked:
                return True

            return renpy.seen_audio(filename)
```

两行逻辑：`add()` 时传了 `always_unlocked=True` 的曲目永远解锁（主题曲、菜单曲通常如此），其余查 `seen_audio`。

曲库登记：

```python
        def add(self, filename, always_unlocked=False, action=None):
            """
            :doc: music_room method

            Adds the music file `filename` to this music room. The music room
            will play unlocked files in the order that they are added to the
            room.

            `always_unlocked`
                If true, the music file will be always unlocked. This allows
                the file to show up in the music room before it has been
                played in the game.

            `action`
                This is a action or the list of actions. these are called when this
                file is played.
            """

            self.playlist.append(filename)
            self.filenames.add(filename)

            if action:
                self.action[filename] = action

            if always_unlocked:
                self.always_unlocked.add(filename)
```

`add` 的 `action` 参数有个进阶玩法：播放某曲时触发的动作列表——比如播放“海的回忆”时把音乐室背景换成海边剪影。

然后是动作家族——你在屏幕上要用到的全部按钮动作，方法名与语义：

```python
        def Play(self, filename=None):
            """
            :doc: music_room method

            This action causes the music room to start playing. If `filename` is given, that
            file begins playing. Otherwise, the currently playing file starts
            over (if it's unlocked), or the first file starts playing.

            If `filename` is given, buttons with this action will be insensitive
            while `filename` is locked, and will be selected when `filename`
            is playing.
            """
```

`Play(filename)` 有两个内建行为值得高亮：**锁定曲目自动变灰**（内部走 `is_unlocked`，与 Replay 一个思路）和**正在播放的曲目按钮呈选中态**（14 章的 selected 机制）。完整动作清单：

| 动作 | 作用 |
| --- | --- |
| `mr.Play("track1.ogg")` | 播放指定曲目（锁定自动灰、播放中自动亮） |
| `mr.Play()` | 从当前曲目重播或从头开始 |
| `mr.Next()` / `mr.Previous()` | 下一首 / 上一首（只在解锁曲目间跳） |
| `mr.TogglePlay()` | 播放/停止切换（有音乐播放时呈选中态） |
| `mr.TogglePause()` | 暂停/继续（暂停时呈选中态） |
| `mr.Stop()` | 停止 |
| `mr.RandomPlay()` | 随机播放一首解锁曲目 |
| `mr.SetLoop(True)` / `SetSingleTrack(True)` / `SetShuffle(True)` | 三个播放模式开关（自动互斥管理） |

（源码方法逐个对应 00musicroom.rpy 437-548 行，这里不整段抄录，语义如上表。）

**MusicRoom 实例必须在 init 阶段创建**——它要参与屏幕预测与存档恢复（动作里持有它的引用），运行时才建会出现“读档后按钮失效”的诡异问题。标准写法：

```renpy
init python:
    jukebox = MusicRoom(channel="music", fadeout=1.0, fadein=1.0)

    jukebox.add("audio/title_theme.ogg", always_unlocked=True)
    jukebox.add("audio/sea_theme.ogg")
    jukebox.add("audio/mountain_theme.ogg")
    jukebox.add("audio/finale.ogg")
```

（示例工程里没有音频文件也能跑——20.5 的实战会用“虚拟曲目名 + 无声文件”处理，见下。）

**音乐室屏幕**。官方文档的推荐结构如下，逐行可读（每个组件都是你已经掌握的）：

```renpy
screen music_room():

    tag menu

    use game_menu(_("音乐鉴赏")):

        vbox:
            spacing 8

            hbox:
                xalign 0.5
                spacing 12

                textbutton "◀" action jukebox.Previous()
                textbutton "▶" action jukebox.Play()
                textbutton "■" action jukebox.Stop()
                textbutton "▶|" action jukebox.Next()

            hbox:
                xalign 0.5
                spacing 20

                textbutton "单曲循环" action jukebox.SetSingleTrack(True)
                textbutton "列表循环" action jukebox.SetLoop(True)
                textbutton "随机" action jukebox.SetShuffle(True)

            null height 20

            vbox:
                spacing 4

                textbutton "1. 主题旋律" action jukebox.Play("audio/title_theme.ogg")
                textbutton "2. 海之记忆" action jukebox.Play("audio/sea_theme.ogg")
                textbutton "3. 山之低语" action jukebox.Play("audio/mountain_theme.ogg")
                textbutton "4. 终章" action jukebox.Play("audio/finale.ogg")
```

注意这里没有写一行“锁定判断”——`jukebox.Play("audio/sea_theme.ogg")` 自己就是三态动作：没听过的曲子按钮自动灰、正在放的自动亮。框架层用 `game_menu` 包住（15.7），`tag menu` 与其他页面互斥。

**无音频素材的测试方案**：没有 ogg 文件时，用 Ren'Py 自带的静音占位——在 game 目录放一个几秒的静音 ogg（任何音频编辑器都能导出），或者临时用 `jukebox.add("click.ogg", always_unlocked=True)` 把 UI 音效当曲目测试解锁与选中逻辑。真机验证留到素材就位。

**离开音乐室别忘了恢复 BGM**：音乐室借用了 music 通道，玩家退出页面后原来的游戏 BGM 已经被切歌。两个方案：给导航的返回按钮加动作列表 `[Return(), Play("music", persistent.last_bgm)]`；或者干脆给音乐室开专用通道（`MusicRoom(channel="jukebox")` 并 `register_channel("jukebox")`），游戏 BGM 完全不受影响。后者更干净。

## 20.3 画廊：persistent 集合 + 分页网格

CG 画廊的解锁数据引擎帮不上忙——`seen_image` 判定的是“show 过这个 image 定义”（对画廊够用但语义偏窄，比如同一位图以不同 tag 展示就算不上 seen），实践中更常用一个**自己维护的 persistent 集合**：在展示 CG 的剧本处加一行 `$ persistent.cg_seen.add("cg_sunrise")`，语义最明确（17 章讲过 persistent 字段不用 default 声明、读不到就是 None，集合类字段约定在 init 阶段初始化一次）。

```renpy
init python:
    persistent.cg_seen = persistent.cg_seen or set()
```

（`or set()` 兜底：第一次运行时是 None，给个空集合；之后再启动，pickle 恢复出的集合原样保留。）

画廊屏幕的结构与 17.2 的最小版相比多两样东西：**分页**与**放大预览**。先给数据端约定：

```renpy
# 每个条目：id、原图 image 名、缩略图 image 名、标题
define gallery_items = [
    ("cg_sunrise",  "cg sunrise",      "thumb sunrise",  "海的日出"),
    ("cg_fireworks","cg fireworks",    "thumb fireworks","夏夜花火"),
    ("cg_farewell", "cg farewell",     "thumb farewell", "站台的告别"),
]
```

一个 tuple 四项：persistent 里的 id、完整图、缩略图、标题。**缩略图不是可选的**：直接把大图塞进网格，几十张图的画廊能把内存和滚动帧率一起拖垮；每个 CG 出一张 ~360px 宽的 thumb 是行业惯例。

分页屏幕（每页 9 格，页间用按钮切换）：

```renpy
screen gallery():

    tag menu
    predict False

    default page = 0
    default viewing = None

    use game_menu(_("CG 画廊")):

        if viewing is not None:

            # 放大预览层：点击任意处返回
            button:
                xfill True
                yfill True
                background "#000000e0"
                action SetScreenVariable("viewing", None)

                add gallery_items[viewing][1] xalign 0.5 yalign 0.5

        else:

            vpgrid:
                cols 3
                spacing 12
                scrollbars "vertical"
                mousewheel True

                for i in range(len(gallery_items)):

                    $ item = gallery_items[i]
                    $ unlocked = item[0] in persistent.cg_seen

                    button:
                        xysize (360, 203)

                        if unlocked:
                            background item[2]
                            action SetScreenVariable("viewing", i)

                            vbox:
                                yalign 1.0
                                text item[3] size 18 outlines [(1, "#000000", 0, 0)]
                        else:
                            background "#333333"

                            vbox:
                                yalign 1.0
                                text "？？？未解锁" size 18 color "#888888"
```

拆解要点：

- **`viewing` 是屏幕局部变量**（`default page/viewing`，13.3）：不是 None 时说明在看大图。预览层是一个全屏透明按钮（`background "#000000e0"`——8 位十六进制的最后两位是 alpha，12 章讲过颜色格式），点任意处 `SetScreenVariable("viewing", None)` 关闭。按钮套图片是“可点击的图”的标准做法。
- **`vpgrid` 一页放下全部**：条目不多时不需要手写分页——`cols 3` + 纵向滚动条就是最简单的“画廊分页”。只有条目多到滚动体验变差（比如 50 张以上）才值得做显式页码，做法照抄 15.8 的 file_slots 页码行（`FilePagePrevious/FilePageNext` 换成自制的 `SetScreenVariable("page", page-1)`）。
- **锁定态不用灰色大图，用占位底色 + “？？？未解锁”**：锁定条目绝不能引用原图（`background item[2]` 只在 unlocked 分支里）——图一加载就等于泄露。
- `predict False`：同 19.5 的理由，画廊图片多，别让引擎预测。

最后是**在剧本里解锁**。在展示对应 CG 的地方加一行：

```renpy
scene cg sunrise with fade
$ persistent.cg_seen.add("cg_sunrise")
```

顺序上先 scene 后 add 无妨（persistent 不参与回滚）；想连回滚里的时间点也精确无所谓，因为解锁本来就是“发生过即解锁”。

## 20.4 综合实战：收集品菜单（extras）

把三块功能挂进主菜单。目标结构：主菜单多一个“收集品”按钮，进入后一个三标签页屏幕（回放 / 音乐 / 画廊），对应示例工程 `18_extras`。

第一步，navigation 加按钮（15.7 拆过的那个屏幕，在 About 之前插一段）：

```renpy
screen navigation():

    vbox:
        style_prefix "navigation"
        xpos gui.navigation_xpos
        yalign 0.5

        spacing gui.navigation_spacing

        if main_menu:
            textbutton _("开始游戏") action Start()
        else:
            textbutton _("历史") action ShowMenu("history")
            textbutton _("保存") action ShowMenu("save")

        textbutton _("读取") action ShowMenu("load")
        textbutton _("收集品") action ShowMenu("extras")
        textbutton _("设置") action ShowMenu("preferences")
```

（完整 navigation 见 15.7，这里只示意新增行：`textbutton _("收集品") action ShowMenu("extras")`。）

第二步，extras 主屏幕用标签页切换。标签页的实现就是一对屏幕变量 + 条件渲染（13 章的 if）：

```renpy
init python:
    persistent.cg_seen = persistent.cg_seen or set()

    jukebox = MusicRoom(channel="music", fadeout=1.0, fadein=1.0)
    jukebox.add("audio/title_theme.ogg", always_unlocked=True)
    jukebox.add("audio/sea_theme.ogg")
    jukebox.add("audio/mountain_theme.ogg")

define gallery_items = [
    ("cg_sunrise", "cg sunrise", "thumb sunrise", "海的日出"),
    ("cg_fireworks", "cg fireworks", "thumb fireworks", "夏夜花火"),
]

define endings = [
    ("end_a", "结局 A：海的尽头"),
    ("end_b", "结局 B：山的那边"),
]

screen extras():

    tag menu
    predict False

    default tab = "replay"

    use game_menu(_("收集品")):

        hbox:
            spacing 8

            textbutton "回放" action SetScreenVariable("tab", "replay") selected (tab == "replay")
            textbutton "音乐" action SetScreenVariable("tab", "music") selected (tab == "music")
            textbutton "画廊" action SetScreenVariable("tab", "gallery") selected (tab == "gallery")

        null height 12

        if tab == "replay":
            use extras_replay
        elif tab == "music":
            use extras_music
        else:
            use extras_gallery
```

三个内容屏各自独立（`use` 组合，13.7 的 transclude 家族；这里不需要传参，纯拼装）：

```renpy
screen extras_replay():

    vbox:
        spacing 8

        $ progress = sum(1 for e in endings if renpy.seen_label(e[0]))
        $ total = len(endings)

        text "已解锁结局：[progress] / [total]" color "#aaaaaa"

        for e in endings:

            button:
                action Replay(e[0])
                xfill True

                hbox:
                    if renpy.seen_label(e[0]):
                        text e[1]
                    else:
                        text "？？？ 未解锁" color "#888888"
```

`sum(1 for e in endings if renpy.seen_label(e[0]))` 是生成器表达式——纯计算，符合屏幕 `$` 的重算模型（18.3 讲过边界）。锁定条目渲染“？？？ 未解锁”文字，按钮灰（Replay 的 `locked=None` 默认语义）；解锁条目显示标题，点击进回放。

```renpy
screen extras_music():

    vbox:
        spacing 8

        hbox:
            spacing 12
            textbutton "◀" action jukebox.Previous()
            textbutton "▶" action jukebox.Play()
            textbutton "■" action jukebox.Stop()
            textbutton "▶|" action jukebox.Next()

        hbox:
            spacing 16
            textbutton "单曲循环" action jukebox.SetSingleTrack(True)
            textbutton "列表循环" action jukebox.SetLoop(True)
            textbutton "随机" action jukebox.SetShuffle(True)

        null height 8

        for track in jukebox.playlist:

            $ n = jukebox.playlist.index(track) + 1

            textbutton "[n]. [track]" action jukebox.Play(track)
```

直接遍历 `jukebox.playlist`（MusicRoom 的公开字段，add 时维护的曲名列表）生成曲目行，动作 `jukebox.Play(track)` 自动处理灰/亮。

```renpy
screen extras_gallery():

    default viewing = None

    if viewing is not None:

        button:
            xfill True
            yfill True
            background "#000000e0"
            action SetScreenVariable("viewing", None)

            add gallery_items[viewing][1] xalign 0.5 yalign 0.5

    else:

        vpgrid:
            cols 3
            spacing 12
            scrollbars "vertical"
            mousewheel True

            for i in range(len(gallery_items)):

                $ item = gallery_items[i]
                $ unlocked = item[0] in persistent.cg_seen

                button:
                    xysize (360, 203)

                    if unlocked:
                        background item[2]
                        action SetScreenVariable("viewing", i)
                        vbox:
                            yalign 1.0
                            text item[3] size 18 outlines [(1, "#000000", 0, 0)]
                    else:
                        background "#333333"
                        vbox:
                            yalign 1.0
                            text "？？？未解锁" size 18 color "#888888"
```

20.3 的画廊原样内嵌。三屏合并完成。

第三步，结局 label（回放目的地）：

```renpy
label end_a:

    scene black
    "那是海的尽头——我们约好一起看日出。"

    menu:
        "结束回忆":
            $ EndReplay()

    return

label end_b:

    scene black
    "那是山的那边——风把告别吹得很远。"

    menu:
        "结束回忆":
            $ EndReplay()

    return
```

第四步，正片里埋解锁点：

```renpy
label route_sea_morning:

    scene cg sunrise with fade
    $ persistent.cg_seen.add("cg_sunrise")

    "日出的光把海面染成金色。"

    play music "audio/sea_theme.ogg" fadein 1.0
    "这首曲子，也已悄悄记入你的音乐室。"
```

不需要为音乐室做任何事——`play music` 执行的瞬间，引擎已把文件名写进 `persistent._seen_audio`（20.2 引用过 enqueue 的那行代码）。

到这里，完整闭环：正片推进 → CG/音乐/结局分别解锁 → 主菜单“收集品”三页展示 → 回放从画廊回到剧情。全部零件来自前五部分。

## 20.5 小结与实践

| 知识点 | 一句话 | 关键代码 |
| --- | --- | --- |
| `Replay(label)` | 回放动作，`locked=None` 时自动按 seen_label 解锁 | `textbutton "结局A" action Replay("end_a")` |
| `scope` / `replay_scope` | 回放开局变量注入；默认把右键菜单锁成设置页 | `Replay("end_a", scope={"route": "sea"})` |
| `EndReplay()` | 退出回放，默认带确认；敏感 iff `_in_replay` | `$ EndReplay()` |
| `_in_replay` | 回放中的 store 标志，值为回放 label | `if _in_replay:` |
| 回放隔离 | clean_stores + 新上下文 + 新回滚日志 | `renpy.call_replay()` |
| 回放里的 persistent | 不回滚，可放心解锁 | `$ persistent.cg_seen.add("cg_sunrise")` |
| 音乐自动解锁 | 音频入队播放即标记 | `persistent._seen_audio`（引擎写） |
| `MusicRoom` | 曲库 + 解锁过滤 + 播放控制，init 创建 | `jukebox = MusicRoom()` + `jukebox.add(...)` |
| `Play(track)` | 三态动作：锁定灰、播放亮 | `action jukebox.Play("a.ogg")` |
| 画廊数据 | 自己的 persistent 集合，展示处手动加 | `persistent.cg_seen.add("cg_x")` |
| 缩略图 | 画廊必须用小图，锁定条目别引用原图 | `("id", "cg x", "thumb x", "标题")` |
| 标签页 | 屏幕变量 + 条件渲染 + use 组合 | `default tab = "replay"` + `if tab == ...` |

实践：

1. 给 extras 加第四页“成就”：定义 `define achievements = [("first_save", "初次保存", "完成第一次存档"), ...]`，解锁条件用 17 章的 seen 系列 + 自定义 persistent 组合，页顶显示完成度进度条（`bar value progress`）。
2. 让回放支持“从画廊直接跳到结局后半段”：给 `end_a` 加参数 `scope`，`Replay("end_a", scope={"skip_intro": True})`，结局 label 开头 `if skip_intro: jump end_a_climax`。
3. 给音乐室换独立通道：`register_channel("jukebox", loop=False)` + `MusicRoom(channel="jukebox")`，验证退出收集品菜单后游戏 BGM 不受影响。

---

上一章：[19 输入与对话历史](ch19-input-and-history.md) · 下一章：[21 开场动画与游戏生命周期](ch21-splash-and-lifecycle.md)
