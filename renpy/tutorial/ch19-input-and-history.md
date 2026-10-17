# 第 19 章 输入与对话历史

本章解决两件玩家每天都在做、开发者却常常糊里糊涂的事：

1. **要玩家输入文字**——主角叫什么名字？密代号是多少？
2. **让玩家回看对话**——刚才那段剧情说了什么？“历史”屏幕里滚动的那些条目从哪来？

第一件事的官方入口是 `renpy.input()`；第二件事的核心是一个你从没赋值过、引擎却一直在维护的变量 `_history_list`。两件事在底层共享同一套机制——它们都会创建一次“交互”（interaction），而交互正是第 13 章讲过的 Ren'Py 心跳。

## 19.1 renpy.input：一行代码要来一个名字

先看签名。以下摘自 SDK 源码 `renpy/exports/inputexports.py`：

```python
def input(
    prompt,
    default="",
    allow=None,
    exclude="{}",
    length=None,
    with_none=None,
    pixel_width=None,
    screen="input",
    mask=None,
    copypaste=True,
    multiline=False,
    **kwargs,
):
    """
    :doc: input
    :args: (default='', allow=None, exclude='{}', length=None, pixel_width=None, screen="input", mask=None, copypaste=True, multiline=False, **kwargs)

    Calling this function pops up a window asking the player to enter some
    text. It returns the entered text.
    """
```

注意 `:args:` 这一行——它才是文档对外公布的参数表，`prompt` 不在其中，因为它没有默认值，必须给。逐个拆解参数的含义与典型用法：

- **`prompt`**：显示给玩家的问题文字，比如 `"你叫什么名字？"`。
- **`default`**：输入框里预先填好的文字。最常见的是从 persistent 里取上次的名字，实现“下次启动还记得”。
- **`allow`**：白名单字符串。设了它之后，玩家打不进白名单以外的任何字符。例如 `allow="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"` 就只允许英文字母。
- **`exclude`**：黑名单字符串，默认值是 `"{}"`——注意这不是空集合，而是两个“需要转义的字符”：花括号 `{` 和 `}`。这样设计是因为花括号在 Ren'Py 里是文本标签的起止符，绝不能让玩家输入进去（否则玩家输入 `{w}` 之类的字符串会直接破坏演出）。这正是默认值替你挡下的第一个坑。
- **`length`**：最大字符数。`length=10` 之后，第 11 个字符打不进去。
- **`pixel_width`**：换一种限制方式——不管几个字符，显示宽度超过这个像素数就打不进去。对中文这种“一个字就挺宽”的语言，`pixel_width` 往往比 `length` 更公平。
- **`screen`**：接收输入的屏幕名，默认 `"input"`（这个屏幕在 15.4 拆解过）。想换输入界面时，写一个自己的屏幕再把名字传进来。
- **`mask`**：单字符字符串，把所有输入显示成这个字符。`mask="*"` 就是密码框。
- **`copypaste`**：是否允许复制粘贴，默认允许。防止玩家粘贴一屏表情包就把 `length` 和 `allow` 都设上——它们对粘贴的内容同样生效。
- **`multiline`**：允许回车换行（默认回车就是“确认”）。
- **`with_none`**：转场细节，照默认即可。

最基本的用法长这样，直接写在剧本里：

```renpy
label start:

    $ player_name = renpy.input("你叫什么名字？", length=12)
    $ player_name = player_name.strip() or "玲"

    "欢迎，[player_name]。"
```

第二行的 `strip() or "玲"` 是输入处理的黄金搭档：`strip()` 去掉首尾空白，`or "玲"` 在玩家什么都没打（空字符串在 Python 里是假值）时给出兜底名字。没有这一行，玩家按住回车就能变成“无名氏”，后续所有 `[player_name]` 插值都会显示空白。

再看几个参数组合的例子，感受一下“限制”怎么写：

```renpy
# 密码框：显示星号，只允许字母数字，最长 8 位
$ code = renpy.input("请输入机房门禁密码", allow="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", length=8, mask="*")

# 中文昵称：不能限制字符集（中文没法列白名单），改用像素宽度
$ nick = renpy.input("取一个昵称", pixel_width=300)

# 记住上次的名字：default 从 persistent 取
$ name = renpy.input("你叫什么名字？", default=persistent.last_name or "", length=12)
$ persistent.last_name = name
```

中文输入是一个高频疑问：`allow` 白名单对中文不可行（你没法枚举所有汉字），所以中文场景用 `length` 或 `pixel_width` 限长即可；另外文档明确指出，受底层库限制，**Android 与 Web 平台的输入只支持字母字符**——如果你的游戏要发这两个平台，输入环节要设计成“选名字”而不是“打名字”（给一组预设名字让玩家点选）。

## 19.2 输入的幕后：交互、回滚与 show_ 前缀

`renpy.input()` 不是魔法，它做了一次标准的“显示屏幕 → 等待交互 → 返回结果”。从源码里挑三段关键代码看，还是 `renpy/exports/inputexports.py`。

第一段，回滚复用。函数开头处：

```python
    roll_forward = renpy.exports.roll_forward_info()
    if not isinstance(roll_forward, str):
        roll_forward = None

    # use previous data in rollback
    if roll_forward is not None:
        default = roll_forward
```

`roll_forward_info()` 在第 16.5 节见过：它取“回滚前那次交互的返回值”。玩家输入过一次名字、又往回滚，重新走到这条输入语句时，输入框里会预先填上他上次输的内容——不是空白，而是他自己的历史答案。这就是输入语句可以安全回滚的原因。

第二段，交互结束后做检查点并返回：

```python
    rv = renpy.ui.interact(mouse="prompt", type="input", roll_forward=roll_forward)
    renpy.exports.checkpoint(rv)
```

`checkpoint(rv)` 把输入结果登记为回滚锚点（16.5 讲过），这就是“回滚复用”能闭环的原因。同时注意 19.1 没提的一个细节在源码里：

```python
    if renpy.config.autosave_on_input and not renpy.game.after_rollback:
        renpy.loadsave.force_autosave(True)
```

输入完成时会**强制自动存档一次**。这是引擎替你考虑的体贴：玩家花力气打了名字，如果这一刻游戏崩了或被误关，名字不该丢。`config.autosave_on_input` 默认为 True，一般不要关。

第三段，`show_` 前缀。函数体中部：

```python
    # put arguments with show_ prefix aside
    show_properties, kwargs = renpy.easy.split_properties(kwargs, "show_", "")
```

任何以 `show_` 开头的关键字参数都会剥掉前缀、当作屏幕属性传给输入屏幕。也就是说你可以这样调用：

```renpy
$ player_name = renpy.input("你叫什么名字？", length=12, show_xalign=0.5)
```

`show_xalign=0.5` 最终变成输入屏幕上某个显示组件的 `xalign 0.5`。这是 13.9 讲过的“属性传递”惯例在 API 层的再现：`show_` 给屏幕，普通参数给函数自己。

`screen` 参数则给了你完全的排版自由：写一个自己的屏幕，里面放一个带 `value` 的 `input` 显示组件（下一节讲 value），再把它传给 `screen="我的输入屏"`。引擎会照 15.4 讲过的惯例，把 `prompt` 作为作用域变量传入，并把输入相关的参数挂到名为 `input` 的显示组件上。

## 19.3 InputValue：屏幕里的常驻输入框

`renpy.input()` 是**阻塞式**的——整个游戏停下来等玩家打完回车。但很多界面需要**不阻塞**的输入框：存档页的页码改名（15.8 的 `FilePageNameInputValue`）、设置页的起播位置、聊天框……这些框就住在普通屏幕里，玩家可以边看别的内容边打字。

支撑这类输入框的是一组类，统称 InputValue 家族。基类在 SDK 源码 `renpy/common/00inputvalues.rpy`，先看全文：

```python
    @renpy.pure
    class InputValue(renpy.object.Object):
        """
        Subclassable by creators, documented in Sphinx.
        """

        default = True
        editable = True
        returnable = False

        def get_text(self):
            raise NotImplementedError

        def set_text(self, s):
            raise NotImplementedError

        def enter(self):
            if self.returnable:
                return self.get_text()
            else:
                return None

        def Enable(self):
            if self.editable:
                return _InputValueAction(self, "enable")
            else:
                return None

        def Disable(self):
            if self.editable:
                return _InputValueAction(self, "disable")
            else:
                return None

        def Toggle(self):
            if self.editable:
                return _InputValueAction(self, "toggle")
            else:
                return None
```

逐条拆：

- **`get_text()` / `set_text(s)`** 是这个抽象的核心：屏幕上的 `input` 显示组件每次重算时问 `get_text()`“现在该显示什么”，玩家每敲一个键就调 `set_text()`“把新内容存回去”。输入框自己不存任何文字——文字永远存在 InputValue 指向的那个地方（屏幕变量、对象字段、store 变量或字典里）。这就是为什么 13 章反复强调“屏幕是重算的”：输入框只是变量的一面镜子。
- **`enter()`**：玩家按回车时被调用。`returnable` 为 True 时把当前文字作为这次交互的返回值交出去，False 时返回 None（回车只是确认，不结束交互）。
- **三个类变量**是默认行为开关：`default = True` 表示“屏幕出现时这个框自动获得焦点”；`editable = True` 表示“可以打字”；`returnable = False` 表示“回车不结束交互”。
- **`Enable()` / `Disable()` / `Toggle()`** 返回三个动作，用来控制这个框是否可编辑。`Toggle()` 你在 15.8 已经见过——`FilePageNameInputValue` 那段代码里，页码按钮的动作就是 `page_name_value.Toggle()`：点一下进入编辑，再点一下退出编辑。

基类自己不会读写任何东西（两个方法都只是 `raise NotImplementedError`），真正干活的是四个子类。一个一个看。

**ScreenVariableInputValue**——读写屏幕作用域里的变量：

```python
    class ScreenVariableInputValue(__GenericInputValue):
        r"""
        :doc: input_value
        :args: {args}

        An input value that updates a variable in a screen.

        In a ``use``\ d screen, this targets a variable in the context of the
        screen containing the ``use``\ d one(s). To target variables within a
        ``use``\ d screen, and only in that case, use
        :func:`LocalVariableInputValue` instead.

        `variable`
            A string giving the name of the variable to update.
        """

        identity_fields = ("screen",)
        equality_fields = __GenericInputValue.equality_fields+("variable",)

        def __init__(self, variable, *args, **kwargs):
            super(ScreenVariableInputValue, self).__init__(*args, **kwargs)
            self.variable = variable
            self.screen = renpy.current_screen()

        def get_text(self):
            cs = self.screen
            return cs.scope[self.variable]

        def set_text(self, s):
            cs = self.screen
            cs.scope[self.variable] = s
            renpy.restart_interaction()
```

两个要点。第一，`__init__` 里 `self.screen = renpy.current_screen()`——它在**构造那一刻**记住当前屏幕，之后所有读写都发生在那张屏幕的 `scope` 里。所以 `ScreenVariableInputValue("player_name")` 必须写在目标屏幕自己的代码里（通常通过 `input value ScreenVariableInputValue("player_name")` 一行），不能在别的屏幕里构造好再传进来——那它会绑到错误的屏幕上。第二，`set_text` 末尾的 `renpy.restart_interaction()`：每敲一个键就重启一次交互，让屏幕重算、光标位置刷新、依赖该变量的其他组件（比如“剩余字数”计数器）同步更新。你在 14 章见过 `restart_interaction` 是动作体系的刷新信号，这里是它的一个内建消费者。

**FieldInputValue**——读写任意对象的字段：

```python
    @renpy.pure
    class FieldInputValue(__GenericInputValue):
        """
        :doc: input_value
        :args: {args}

        An input value that updates `field` on `object`.

        `field`
            A string giving the name of the field.
        """

        identity_fields = ("object",)
        equality_fields = __GenericInputValue.equality_fields+("field",)

        kind = "field"

        def __init__(self, object, field, *args, **kwargs):
            super(FieldInputValue, self).__init__(*args, **kwargs)
            self.object = object
            self.field = field

        def get_text(self):
            return _get_field(self.object, self.field, self.kind)

        def set_text(self, s):
            _set_field(self.object, self.field, s, self.kind)
            renpy.restart_interaction()
```

它把读写目标从“屏幕变量”换成了“`object.field`”。它标了 `@renpy.pure`（14.3 讲过：纯动作可以参与屏幕预测、存档后重建），意味着把它绑到一个存档里的对象上也安全——回滚和读档后它照常工作。

**VariableInputValue**——读写 store（或深层路径）里的全局变量：

```python
    @renpy.pure
    class VariableInputValue(FieldInputValue):
        """
        :doc: input_value
        :args: {args}

        An input value that updates `variable`.

        `variable`
            A string giving the name of the variable to update.

            The `variable` parameter must be a string, and can be a simple name like "strength", or
            one with dots separating the variable from fields, like "hero.strength"
            or "persistent.show_cutscenes".
        """

        __version__ = 1

        kind = "variable"

        def after_upgrade(self, version):
            if version < 1:
                self.field = self.variable
                self.object = store
                del self.variable

        def __init__(self, variable, *args, **kwargs):
            super(VariableInputValue, self).__init__(store, variable, *args, **kwargs)
```

看构造函数最后一行就明白了：`VariableInputValue` 是 `FieldInputValue(object=store, field=变量名)` 的快捷方式。文档字符串里那句重点值得抄一遍：变量名可以是带点号的路径，比如 `"hero.strength"` 甚至 `"persistent.show_cutscenes"`——直接把输入框焊到持久化数据上。至于 `after_upgrade` 那段，是引擎自己的存档兼容代码（老版本对象升级），你不用管。

**DictInputValue**——读写字典或列表元素：

```python
    @renpy.pure
    class DictInputValue(__GenericInputValue):
        """
        :doc: input_value
        :args: {args}

        An input value that updates ``dict[key]``.

        `dict`
            May be a dict object or a list.
        """

        identity_fields = ("dict",)
        equality_fields = __GenericInputValue.equality_fields+("key",)

        def __init__(self, dict, key, *args, **kwargs):
            super(DictInputValue, self).__init__(*args, **kwargs)
            self.dict = dict
            self.key = key

        def get_text(self):
            return self.dict[self.key]
```

`get_text` 读 `dict[key]`，`set_text` 对称地写 `dict[key] = s` 后重启交互。文档明说 `dict` 也可以传列表——此时 `key` 是下标。

四个子类怎么选？一张表记住：

| 你的输入内容想存到哪 | 用哪个类 |
| --- | --- |
| 本屏幕的作用域变量 | `ScreenVariableInputValue("变量名")` |
| 某对象的字段（如存档里的对象） | `FieldInputValue(对象, "字段名")` |
| store 全局变量 / 持久化数据 | `VariableInputValue("变量名")` |
| 字典或列表的某一项 | `DictInputValue(字典, 键)` |

在屏幕里使用它们的方式统一到惊人的程度——`input` 显示组件有一个 `value` 属性，接一个 InputValue 就行：

```renpy
screen note_editor():
    default draft = ""

    frame:
        vbox:
            spacing 10

            label "便签"

            input:
                value ScreenVariableInputValue("draft")
                length 60
                style_prefix "note_input"

            text "当前内容：[draft]" color "#888"
```

注意 `default draft = ""`（13.3 讲过：屏幕局部变量的默认值）——InputValue 需要读写的那块“地”必须先存在。玩家每敲一个键，`draft` 就更新一次，底下的预览文本跟着重算刷新。**回车不提交任何东西**——因为 `returnable` 默认 False，文字早就实时存进 `draft` 了，回车只是回车。

如果想要“回车即提交”的阻塞式行为（比如确认门禁密码），把 `returnable=True` 传给构造函数：

```renpy
screen code_gate():
    input:
        value ScreenVariableInputValue("code", returnable=True)
        mask "*"
```

此时回车会让这个屏幕的 `call_screen` 返回 `code` 的当前值，配合 `call screen` 就是自制版 `renpy.input`。

最后回望 15.8 那个 `FilePageNameInputValue(pattern=_("Page {}"))`——现在你能完整读懂它了：它是 InputValue 家族的又一位成员（引擎为存档页定制），读写“当前页码”，`pattern` 让显示时自动套上“第 N 页”的壳，`Toggle()` 负责在“显示页码”和“编辑页码”之间切换。整个家族同一套骨架，只是读写目标不同。

## 19.4 对话历史的数据：_history_list 与 HistoryEntry

打开游戏内建的“历史”屏幕，你看到的一页页对话，来自一个你从未赋值过的变量：`_history_list`。它是引擎自动维护的对话日志，记录规则全部浓缩在 `renpy/character.py` 的 `add_history` 方法里。先看类，再看记录逻辑。

`HistoryEntry` 的定义：

```python
class HistoryEntry(renpy.object.Object):
    """
    Instances of this object are used to represent history entries in
    _history_list.
    """

    # See ADVCharacter.add_history for the fields.

    multiple = None
    who = None
    what = None

    def __eq__(self, other):
        if isinstance(other, type(self)):
            return self.__dict__ == other.__dict__
        else:
            return False

    def __hash__(self):
        return hash(tuple(sorted(self.__dict__.items())))
```

类本身只声明了三个字段的默认值：`who`（说话人显示名）、`what`（台词内容）、`multiple`（并排多台词模式 3.8 用到的编号）。但注意注释 "See ADVCharacter.add_history for the fields"——完整字段是在记录时动态挂上去的。

记录逻辑，`add_history` 全文：

```python
    def add_history(self, kind, who, what, multiple=None, **kwargs):
        """
        This is intended to be called by subclasses of ADVCharacter to add
        History entries to _history_list.
        """

        history_length = renpy.config.history_length

        if history_length is None:
            return

        if not renpy.store._history:
            return

        history = renpy.store._history_list

        h = HistoryEntry()

        h.kind = kind

        h.who = who
        h.what = what

        h.who_args = self.who_args
        h.what_args = self.what_args
        h.window_args = self.window_args
        h.show_args = self.show_args

        h.image_tag = self.image_tag

        h.multiple = multiple

        if renpy.game.context().rollback:
            h.rollback_identifier = renpy.game.log.current.identifier
        else:
            h.rollback_identifier = None

        for k, v in kwargs.items():
            setattr(h, k, v)

        for i in renpy.config.history_callbacks:
            i(h)

        history.append(h)

        while len(history) > history_length:
            history.pop(0)
```

每说一句台词，Character 对象就调一次它。这段代码里藏着六个关键事实：

1. **`config.history_length` 是总开关，默认 None（不记录）**。开头两行判断：长度为 None 直接 return。所以裸引擎没有历史功能，是项目模板用一行配置打开的——`gui/game/gui.rpy` 第 341 行：

   ```renpy
   define config.history_length = 250
   ```

   250 条上限，超过就从头部丢弃（最后的 `while len(history) > history_length: history.pop(0)`）。想存更多就调大这个数，代价是内存与存档体积。
2. **`_history` 开关**：`store._history` 为 False 时同样不记录。引擎在 15.7 见过它的用途——开场 splash 期间被临时设为 False，开机动画不进历史。
3. **记录的是“显示内容”而非“原始变量”**：`who` 存的是角色显示名（即 `Character("名字")` 那个参数，含 who_prefix/suffix 处理后的样子），`what` 存的是 what_prefix/suffix 处理后的最终台词。历史屏幕直接展示这两个字段就能和当时玩家看到的完全一致。
4. **样式参数一起存档**：`who_args`/`what_args`/`window_args`/`show_args` 是 Character 的四组原始样式参数。历史屏幕稍后要用 `h.who_args["color"]` 恢复说话人名字的颜色——数据在这。
5. **`rollback_identifier`**：如果这句话是在可回滚状态下说的，记录当时的回滚标识符。这是给高级功能用的（比如“跳回这句话”），默认模板不用它。
6. **`config.history_callbacks` 钩子**：记录最后、截断之前，列表里的每个回调都会拿到这个条目。这是你给历史条目**附加自定义字段**的官方入口——19.6 会用到。

还有一个隐含事实：`_history_list` 在 store 里，而第 16 章讲过“运行时被改动过的变量才进存档”——引擎运行时一直在往它 append，所以它天然进存档、随存读档与回滚一起伸缩。玩家读档后翻历史，看到的正是那个时间点的对话记录，不多不少。

## 19.5 history 屏幕：官方模板逐行拆解

数据有了，展示它的屏幕才是玩家看到的东西。官方模板的 history 屏幕在 `gui/game/screens.rpy`，全文如下：

```renpy
screen history():

    tag menu

    ## Avoid predicting this screen, as it can be very large.
    predict False

    use game_menu(_("History"), scroll=("vpgrid" if gui.history_height else "viewport"), yinitial=1.0, spacing=gui.history_spacing):

        style_prefix "history"

        for h in _history_list:

            window:

                ## This lays things out properly if history_height is None.
                has fixed:
                    yfit True

                if h.who:

                    label h.who:
                        style "history_name"
                        substitute False

                        ## Take the color of the who text from the Character, if set.
                        if "color" in h.who_args:
                            text_color h.who_args["color"]

                $ what = renpy.filter_text_tags(h.what, allow=gui.history_allow_tags)
                text what:
                    substitute False

        if not _history_list:
            label _("The dialogue history is empty.")


## This determines what tags are allowed to be displayed on the history
## screen.

define gui.history_allow_tags = { "alt", "noalt", "rt", "rb", "art" }
```

这段模板每一行都有讲究，逐块拆：

**外框与性能。** `tag menu` 让它与保存/读取等页面互斥（15.7 讲过 menu 标签组）。`predict False` 是这个屏幕最独特的一行：屏幕预测（13 章讲过，引擎会提前渲染看不见的屏幕以消除卡顿）对历史屏幕是灾难——250 条对话、每条一个窗口，预测它等于偷偷渲染一整个页面。所以模板明确关掉它的预测，宁可打开时多等一帧。

**容器选择是个三元表达式。**

```renpy
use game_menu(_("History"), scroll=("vpgrid" if gui.history_height else "viewport"), yinitial=1.0, spacing=gui.history_spacing):
```

15.7 拆解 game_menu 时见过 `scroll` 参数的三个分支，这里传值的方式很聪明：`gui.history_height` 是“每条历史窗口的固定高度”（模板 gui.rpy 里 `define gui.history_height = gui.scale(140)`）。**如果给了固定高度**，所有条目尺寸一致，用 `vpgrid`（网格视口，一行多个、渲染更省）；**如果是 None**（条目高度随文字长短浮动），网格没法用，退回 `viewport`（普通纵向滚动）。`yinitial=1.0` 表示滚动条初始在最底部——对话历史永远先看最新的。

**条目循环与那个 fixed 机关。** `for h in _history_list` 逐条渲染。每个条目是个 `window`，里面的第一行却是：

```renpy
has fixed:
    yfit True
```

`has` 是 13 章讲过的“把容器换成别的”语句；`fixed` 默认让子组件叠在一起且不占空间，但 `yfit True` 让它高度收缩到正好包住内容。注释说得很直白：这是为 `history_height` 为 None 的情况兜底——没有固定高度时，用 yfit 的 fixed 把“名字标签 + 正文”两块垂直排好并撑起窗口高度。加上第 4 小节说过的 `history_window` 样式里有 `ysize gui.history_height`（有固定高度时生效），两种模式都收口了。

**说话人与颜色还原。**

```renpy
if h.who:

    label h.who:
        style "history_name"
        substitute False

        ## Take the color of the who text from the Character, if set.
        if "color" in h.who_args:
            text_color h.who_args["color"]
```

三个细节。第一，`if h.who` 先判空——旁白（narrator）的 `who` 是 None，没有名字标签可渲染。第二，`substitute False` 关掉文本插值（12.1 的 `[变量]` 展开机制）：`what` 是玩家当时看到的最终文本，里面可能合法地包含字面方括号内容，历史屏幕不该再对它做一轮插值。第三，颜色还原的写法：`h.who_args` 是角色定义时的原始参数字典，`if "color" in h.who_args` 之后 `text_color h.who_args["color"]` 把爱丽丝的粉色还给爱丽丝。这就是 19.4 第 4 条“样式参数一起存档”的兑现处——历史里的名字颜色不用你做任何映射，Character 的参数原样回来。

**文本标签过滤。** 渲染正文前有一行 Python：

```renpy
$ what = renpy.filter_text_tags(h.what, allow=gui.history_allow_tags)
text what:
    substitute False
```

台词里可能带有各种文本标签：`{w}`（等待）、`{nw}`（不等待）、`{fast}`/`{cps}`（打字机控制）……这些是**演出指令**，在历史这种静态列表里毫无意义甚至有害。`renpy.filter_text_tags` 按“白名单”清洗文本，只保留 `gui.history_allow_tags` 集合里的标签：

```renpy
define gui.history_allow_tags = { "alt", "noalt", "rt", "rb", "art" }
```

白名单里的五个都是“信息类”标签：`alt`/`noalt` 是无障碍替代文本开关，`rt`/`rb` 是注音（Furigana/Ruby），`art` 是艺术字替代。演出类标签（等待、速度、字体切换等）全部剥掉。这个函数的实现值得看一眼，`renpy/text/extras.py`：

```python
def filter_text_tags(s, allow=None, deny=None):
    """
    :doc: text_utility

    Returns a copy of `s` with the text tags filtered. Exactly one of the `allow` and `deny` keyword
    arguments must be given.

    `allow`
        A set of tags that are allowed. If a tag is not in this list, it is removed.

    `deny`
        A set of tags that are denied. If a tag is not in this list, it is kept in the string.
    """

    if (allow is None) and (deny is None):
        raise Exception("Only one of the allow and deny keyword arguments should be given to filter_text_tags.")

    if (allow is not None) and (deny is not None):
        raise Exception("Only one of the allow and deny keyword arguments should be given to filter_text_tags.")

    tokens = textsupport.tokenize(str(s))

    rv = []

    for tokentype, text in tokens:
        if tokentype == PARAGRAPH:
            rv.append("\n")
        elif tokentype == TAG:
            kind = text.partition("=")[0]
            kind = kind.partition(":")[0]

            if kind and (kind[0] == "/"):
                kind = kind[1:]

            if allow is not None:
                if kind in allow:
                    rv.append("{" + text + "}")
            else:
                if kind not in deny:
                    rv.append("{" + text + "}")
        else:
            rv.append(text.replace("{", "{{"))

    return "".join(rv)
```

思路是“先分词再裁决”：`textsupport.tokenize` 把字符串切成段落、标签、普通文本三类 token；标签 token 取 `{` 后、`=` 或 `:` 前的部分作为标签名（闭合标签去掉 `/`），在 `allow` 集合里就保留、否则丢弃；普通文本里的 `{` 统一双写为 `{{` 转义（防止玩家输入的花括号——19.1 说过 `exclude="{}"` 挡过一手——被误当标签）。`allow` 与 `deny` 必须二选一，函数开头两个 if 就是这个约束。你在别处（比如想做一个“纯文本导出对话”功能）也可以直接用这个函数。

**空状态。** 最后：

```renpy
if not _history_list:
    label _("The dialogue history is empty.")
```

新开游戏直接翻历史，给一句“对话历史为空”。空状态是任何列表屏幕的必修课，15.8 的空存档槽、这里的历史，逻辑相同。

**配套样式**紧跟在模板里，摘出主干：

```renpy
style history_window is empty

style history_name is gui_label
style history_name_text is gui_label_text
style history_text is gui_text

style history_label is gui_label
style history_label_text is gui_label_text

style history_window:
    xfill True
    ysize gui.history_height

style history_name:
    xpos gui.history_name_xpos
    xanchor gui.history_name_xalign
    ypos gui.history_name_ypos
    xsize gui.history_name_width

style history_name_text:
    min_width gui.history_name_width
    textalign gui.history_name_xalign

style history_text:
    xpos gui.history_text_xpos
    ypos gui.history_text_ypos
    xanchor gui.history_text_xalign
    xsize gui.history_text_width
    min_width gui.history_text_width
    textalign gui.history_text_xalign
    layout ("subtitle" if gui.history_text_xalign else "tex")
```

没有新知识，全是 15.10 讲过的机制在列队：`style_prefix "history"` 把屏幕里的 `window`/`label`/`text` 分别映射到 `history_window`/`history_name`/`history_text`（以及 label 内部文本走 `history_name_text`）。两个样式值得一提：`history_name` 用 `xsize gui.history_name_width` + `history_name_text` 用 `min_width` + `textalign` 实现左列名字右列正文的“表格式”对齐；`history_text` 最后一行 `layout ("subtitle" if gui.history_text_xalign else "tex")` 是个开关——正文对齐设为 0 时用普通排版 `tex`，设为非 0 时用 `subtitle`（两端对齐、支持首行缩进的排版模式），这就是模板注释里“两端对齐的对话历史”选项的机关。

## 19.6 三种常见改造

模板直接可用，但有三个需求几乎每个项目都会遇到。逐个给出改法，全部基于你已经掌握的机制。

**改造一：想让历史里显示菜单选择。** 玩家在关键选项里选了什么，历史里看不到（`add_history` 只记录 say 语句）。标准解法是手动塞记录——`_history_list` 就是个普通列表，往里 append 一个 HistoryEntry 风格的对象即可：

```renpy
menu:
    "去海边":
        $ history_who = "我"
        $ history_what = "（选择了：去海边）"
        jump route_sea

    "去山上":
        $ history_who = "我"
        $ history_what = "（选择了：去山上）"
        jump route_mountain
```

每条分支的 `$` 里先准备好 who/what，然后统一补一句：

```renpy
python:
    h = renpy.store.HistoryEntry()
    h.who = history_who
    h.what = history_what
    _history_list.append(h)
```

`HistoryEntry` 就在 store 命名空间里（19.4 讲过它在 `renpy.character` 定义、引擎会导出到 store），直接实例化、填 `who`/`what` 两个字段、append 进去，历史屏幕的 `for h in _history_list` 会把它当正常条目渲染。习惯上把这三行封装成一个函数：

```renpy
init python:
    def log_choice(text):
        h = renpy.store.HistoryEntry()
        h.who = "我"
        h.what = "（选择了：" + text + "）"
        renpy.store._history_list.append(h)
```

之后每个菜单分支一行 `$ log_choice("去海边")` 即可。

**改造二：给历史条目附加自定义数据。** 19.4 第 6 条提过 `config.history_callbacks`——每条历史记录生成后、进入列表前，回调列表里的每个函数都会被调用。用它给条目盖上“章节号”：

```renpy
default current_chapter = "序章"

init python:
    def add_chapter(h):
        h.chapter = current_chapter

    config.history_callbacks.append(add_chapter)
```

回调拿到的 `h` 就是正在生成的 HistoryEntry（`add_history` 源码里 `for i in renpy.config.history_callbacks: i(h)` 那一步），随手挂一个 `h.chapter` 属性。之后历史屏幕里想显示章节就自由了：

```renpy
for h in _history_list:

    window:

        has fixed:
            yfit True

        if h.who:
            label h.who:
                style "history_name"
                substitute False
                if "color" in h.who_args:
                    text_color h.who_args["color"]

        $ what = renpy.filter_text_tags(h.what, allow=gui.history_allow_tags)
        text what:
            substitute False

        if "chapter" in h.__dict__:
            text h.chapter size 16 color "#999999" xpos 1.0 xanchor 1.0
```

最后三行是新增的：用 `"chapter" in h.__dict__` 判断这个条目有没有章节字段（旧存档恢复出来的老条目没有），有就右下角灰字标注。**用 `__dict__` 判字段存在**是处理 HistoryEntry 的惯用法，因为类上只预定义了三个字段，其余都是动态挂的。

**改造三：换掉过滤白名单 / 历史里也显示思考。** 白名单就是那个 define，改一行：

```renpy
define gui.history_allow_tags = { "alt", "noalt", "rt", "rb", "art", "color", "i", "b" }
```

加了 `color`/`i`/`b` 之后，台词里的强调样式会保留到历史里。注意别把演出类标签加进来——`{w}` 在静态列表里不可见但会造成困惑，`{image=...}` 则可能让历史屏幕意外加载大量图片。

## 19.7 综合实战：角色登记表单

把本章的两半拼成一个完整的实战：玩家创建角色——屏幕上实时填**姓名**与**称号**（不阻塞的 InputValue 输入框，带字数预览），确认后进入剧情；剧情第一句用阻塞式 `renpy.input` 问座右铭；最后做一个支持章节标注的自定义历史屏幕。对应示例工程 `17_input_history`。

先写表单屏幕：

```renpy
default player_name = ""
default player_title = ""

screen character_creator():

    modal True

    frame:
        xfill True
        yfill True
        background "#202020"

        vbox:
            xalign 0.5
            yalign 0.5
            spacing 16

            label "角色登记" style_prefix "creator_title"

            hbox:
                spacing 10
                text "姓名：" min_width 120
                input:
                    value ScreenVariableInputValue("player_name")
                    length 12
                    pixel_width 320

            hbox:
                spacing 10
                text "称号：" min_width 120
                input:
                    value ScreenVariableInputValue("player_title")
                    length 8
                    pixel_width 200

            text "预览：{b}[player_name]{/b} · [player_title]" color "#aaaaaa"

            hbox:
                spacing 20
                xalign 0.5

                textbutton "随机一个" action Function(randomize_identity)

                textbutton "就这样吧" action Return(("ok", player_name.strip(), player_title.strip())) sensitive (player_name.strip() != "")
```

拆解：两个 `input` 各绑一个 `ScreenVariableInputValue`，读写屏幕作用域里的 `player_name`/`player_title`（顶部 `default` 准备好“地”）；`length` 限字数、`pixel_width` 兜住中英文宽度差；“预览”一行演示敲键实时刷新（重算模型）；确认按钮 `sensitive (player_name.strip() != "")`——名字为空不可确认；`Return(("ok", ...))` 把元组交还给 `call_screen`，随机按钮 `Function(randomize_identity)` 直接改作用域变量，屏幕立刻重算。

配套的随机函数与主流程：

```renpy
init python:
    def randomize_identity():
        names = ["玲", "雪见", "青行", "归尘"]
        titles = ["旅行者", "见习魔女", "夜行者", "守灯人"]
        renpy.store.player_name = renpy.random.choice(names)
        renpy.store.player_title = renpy.random.choice(titles)

label start:

    call screen character_creator

    $ result = _return
    if result[0] == "ok":
        $ player_name = result[1]
        $ player_title = result[2] or "无名之辈"

    $ motto = renpy.input("用一句话介绍你自己", default="我还在路上。", length=30, pixel_width=420)
    $ motto = motto.strip() or "我还在路上。"

    "登记完成。[player_name]·[player_title]，座右铭：{i}[motto]{/i}"
    $ log_choice("创建了角色 [player_name]")

    jump chapter_one
```

注意三处衔接：`call screen` 之后用 `_return`（13.6 讲过的返回值约定）取回元组；`renpy.input` 用在这里反而合适——一句座右铭，阻塞式正合适，`default` 给了兜底文案，回滚时 19.2 讲的复用机制自动生效；`log_choice` 是 19.6 改造一封装的函数，把“创建角色”这个关键选择也写进历史。

最后是带章节标注的历史屏幕——把模板整个抄下来，改四处：白名单加 `b`/`i`（19.6 改造三）、条目循环里加 19.6 改造二的章节行、`config.history_callbacks` 挂上章节回调（19.6 改造二）、`current_chapter` 在剧情里手动推进。完整代码：

```renpy
default current_chapter = "序章"

init python:
    def add_chapter(h):
        h.chapter = current_chapter

    config.history_callbacks.append(add_chapter)

define gui.history_allow_tags = { "alt", "noalt", "rt", "rb", "art", "b", "i" }

screen history():

    tag menu
    predict False

    use game_menu(_("History"), scroll=("vpgrid" if gui.history_height else "viewport"), yinitial=1.0, spacing=gui.history_spacing):

        style_prefix "history"

        for h in _history_list:

            window:

                has fixed:
                    yfit True

                if h.who:
                    label h.who:
                        style "history_name"
                        substitute False
                        if "color" in h.who_args:
                            text_color h.who_args["color"]

                $ what = renpy.filter_text_tags(h.what, allow=gui.history_allow_tags)
                text what:
                    substitute False

                if "chapter" in h.__dict__:
                    text h.chapter size 16 color "#999999" xpos 1.0 xanchor 1.0

        if not _history_list:
            label _("The dialogue history is empty.")
```

导航里加一个入口按钮 `textbutton _("历史") action ShowMenu("history")`（如果模板 navigation 里没有），整个系统就闭环了：创建 → 台词自动进历史 → 关键选择手动进历史 → 每条带章节角标。

## 19.8 小结与实践

本章知识点浓缩成一张表：

| 知识点 | 一句话 | 关键代码 |
| --- | --- | --- |
| `renpy.input()` | 阻塞式输入，返回字符串 | `$ name = renpy.input("问题", length=12)` |
| 输入兜底 | strip 后 or 默认值 | `$ name = name.strip() or "玲"` |
| `exclude` 默认值 | 挡花括号防标签注入 | 默认 `"{}"`，别改掉 |
| show_ 前缀 | 传屏幕属性 | `show_xalign=0.5` |
| InputValue 基类 | get_text/set_text/enter 三方法 | `@renpy.pure class InputValue` |
| 四个子类 | 屏幕/字段/全局/字典 | `ScreenVariableInputValue` 等 |
| 不阻塞输入框 | `input` 组件 + `value` | `input: value ScreenVariableInputValue("x")` |
| `returnable=True` | 回车交卷 | `ScreenVariableInputValue("x", returnable=True)` |
| 历史总开关 | 默认 None 不记录 | `define config.history_length = 250` |
| `_history_list` | 引擎维护的对话日志，随存档走 | `for h in _history_list` |
| HistoryEntry 字段 | who/what + who_args 等 | `h.who_args["color"]` 还原颜色 |
| 标签过滤 | `renpy.filter_text_tags` 白名单 | `allow=gui.history_allow_tags` |
| 自定义数据 | `config.history_callbacks` 回调 | `h.chapter = current_chapter` |

实践：

1. 给 `character_creator` 加第三个输入框“生日”，用 `allow="0123456789/"` 限制只能输入数字和斜杠，并加一个实时预览解析（`datetime.strptime` 试解析，失败显示红色提示——想想该放在屏幕的哪一层才算“纯计算”）。
2. 在 19.7 的历史屏幕基础上加“跳回这句”功能：每条历史上加一个小按钮，action 用 `RollbackToIdentifier(h.rollback_identifier)`（引擎为 `rollback_identifier` 准备的配套动作）——注意只有 `rollback_identifier` 非 None 的条目才显示按钮。
3. 把 `config.history_length` 临时改成 5，说 10 句话，确认历史里只剩最近 5 条——亲眼验证 `pop(0)` 截断逻辑。

---

上一章：[18 Python 语句与引擎 API](ch18-python-and-engine-api.md) · 下一章：[20 画廊、音乐室与回放](ch20-gallery-music-replay.md)
