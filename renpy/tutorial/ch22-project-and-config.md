# 第 22 章 项目组织与配置：从目录到 settings

> [← 第 21 章 开场动画与游戏生命周期](ch21-splash-and-lifecycle.md) ｜ [目录](index.md) ｜ [第 23 章 调试与自动化测试 →](ch23-debug-and-testing.md)

本章从“一个 Ren'Py 工程到底有哪些文件、谁先谁后”讲起，把 `game/` 目录的组织、`init` 的执行顺序、`options.rpy` 的常用配置一次性讲清。

## 22.1 一个工程的目录结构

一个可运行（甚至可发布）的 Ren'Py 工程，最小结构是：

```
my_game/
├── game/                    # 所有游戏内容都在这里
│   ├── script.rpy           # 主剧本（至少要有 label start）
│   ├── options.rpy          # 配置
│   ├── screens.rpy          # 屏幕（GUI）
│   ├── gui.rpy              # GUI 初始化与配色
│   ├── images/              # 图片素材
│   ├── audio/               # 音频素材
│   └── ...
└── ...
```

`game/` 之外的文件（如 `lib/`、`renpy/` 是 SDK 自带；项目根目录的图标等）不属于本章重点。**你写的所有 `.rpy` 都会被引擎自动加载**——不需要在某个“入口文件”里 `import`。引擎在启动时扫描 `game/`（含子目录）下的所有 `.rpy` / `.rpym`，把它们一起编译。

这里有一个初学者最常见的困惑：**既然所有 `.rpy` 都会被加载，那“执行顺序”由什么决定？** 答案是 `init`。

---

## 22.2 init 与执行顺序：谁先谁后，由什么决定

这是全篇最容易“踩坑”又最难自查的一节。很多莫名其妙的错误——变量被覆盖、图像没定义、屏幕里引用了一个还不存在的类——根因都是**初始化顺序**。官方文档把它拆在 [Lifecycle and Code Execution](https://www.renpy.org/doc/html/lifecycle.html) 和 [Python Statements](https://www.renpy.org/doc/html/python.html) 两页里。本节把这两页的规则提炼成一条可以实际操作的“排序算法”。

### 22.2.1 两大阶段：Boot Time 与 Script Execution

引擎的启动分两个阶段，务必区分开：

1. **Boot Time（引导阶段）**：引擎自身初始化——读取配置、建立显示、准备渲染器、加载 `renpy/common/` 里的引擎脚本。这个阶段**你的游戏脚本还没被解析**。
2. **Script Execution（脚本执行阶段）**：解析并编译 `game/` 下的所有脚本，然后运行 `init` 块，之后才进入 `_start`、主菜单、剧情。

你要关心的几乎全部是第二阶段。第二阶段内部又可以细分为：

```
① 收集并读取所有 .rpy/.rpyc
② 对每个文件：解析 → 执行该文件里的 python early 块
③ 所有文件读完后：按优先级依次执行所有 init 块
④ init 全部结束后：进入 _start（第 21 章），default 语句在此时才有意义
```

**②和③分开，是理解顺序的关键**：`python early` 与 `init` 不在同一时刻执行。

### 22.2.2 文件读取顺序：Unicode 全路径排序

引擎收集脚本时，会遍历 `game/`（递归所有子目录），得到一份文件清单。这份清单的排序规则是：**按文件的完整路径做 Unicode 排序**。

文档给的原例非常直观：

- `game/animals/zebra.rpy` 会排在 `game/plants/aloe.rpy` **之前**——因为比较到第一个不同字符时 `a`（animals）`<` `p`（plants），**子目录名先于文件名参与比较**。
- 同一目录下，`00definitions.rpy` 会排在 `script.rpy` 之前（字符 `0` < `s`）。

这就解释了几个常见现象：

- 为什么引擎自带文件都叫 `00xxx.rpy`？——为了让它们**排在最前面**，把基础的类、函数、默认值先定义好。
- 为什么你自己写的文件随便起名通常也没事？——因为 `init` 才是真正的执行顺序控制点，文件读取顺序只决定**同一优先级内的顺序**（见 22.2.4）。

> **命名注意**：引擎保留了 `00` 开头的文件名。你的脚本**不要**用 `00` 开头，否则会与引擎自带文件冲突或产生难以排查的加载问题。这条在官方 [Language Basics](https://www.renpy.org/doc/html/language_basics.html) 里明确提到。

### 22.2.3 `python early`：在解析阶段就执行

普通的 `init python` 是**脚本执行阶段、所有文件解析完之后**统一跑的。但有一类需求不能等那么久——比如你正在**发明一套新的语句**（CDS，“创作者自定义语句”），那么当你写这个新语句时，解析器必须**当时就知道它怎么解析**。这就是 `python early` 的用武之地。

官方文档的描述是：`python early` 块在**文件被解析之后、下一个文件被读取之前**执行。也就是说，若 `a.rpy` 里定义了 `python early`，它会在 `a.rpy` 解析完、`b.rpy` 还没开始读的时候运行。

```renpy
# a.rpy
python early:
    # 在这里注册自定义语句 / 自定义 warper 等，
    # 使得同一文件（以及后面的文件）可以立即使用它们
    def my_warp(t):
        return t * t

    renpy.register_statement("mystatement", ...)
```

因为它是“逐文件、边解析边执行”，所以 `python early` **不能**依赖排在它后面文件里的东西。反过来，`init python` 里可以放心引用 `python early` 注册的内容。

补充一条官方说明：`init python early` 是**冗余也不推荐**的写法——`python early` 本身已经是“早期”，不需要也不能再套 `init`。

### 22.2.4 `init` 块与优先级（epoch）

现在到最核心的规则。`init` 块可以带一个**优先级（priority）**：

```renpy
init python:
    # 优先级 0（默认）
    ...

init -1 python:
    # 优先级 -1，比上面的早
    ...

init 100 python:
    # 优先级 100，比默认的晚
    ...
```

**执行顺序的完整排序算法**：

1. **先比优先级**，数值小的先执行（`-1` 在 `0` 之前，`0` 在 `100` 之前）。
2. **优先级相同时**，按 22.2.2 的**文件 Unicode 全路径顺序**。
3. **同一文件内**，按**自上而下**的出现顺序。

三者组合起来，得到一个全序，引擎严格按它执行。

**优先级的取值范围**，官方给了社区约定：

| 区间 | 用途 |
| --- | --- |
| `-99` ~ `99` | 普通游戏作者使用（默认 0） |
| `-999` ~ `-100` 与 `100` ~ `999` | 库、模组（mod）使用 |
| `-999` ~ `999` 之外 | **引擎保留**，不要用 |

也就是说，你自己写代码时，**用到 `-99~99` 就足够了**；不需要为了“保险”写 `init -1000`——那个区间是给引擎的，越界可能产生意外。

### 22.2.5 `init offset` 语句：给一整个文件改默认优先级

如果一个文件里所有 `init` 都想用同一个优先级，逐个加数字很啰嗦。`init offset` 语句解决这个问题：**它会改变其后所有 init 语句（含其内部的子块）的默认优先级，直到遇到下一个 `init offset`**。

```renpy
# 文件顶部声明：本文件所有 init 语句的默认优先级变成 -2
init offset = -2

init python:
    # 实际优先级 = -2 + 0 = -2
    ...

init 5 python:
    # 实际优先级 = -2 + 5 = 3
    ...
```

注意 `init offset` 是**偏移量**而非绝对值：它加在该语句自身带的优先级之上。第 21.7 节的 `19_lifecycle/gui.rpy` 顶部用了 `init offset = -2`，就是为了让 `gui.init()` 比普通 `init 0` 更早执行——因为 GUI 初始化会调用 `layout.defaults()`，必须**先于**其他引用屏幕布局的代码。

### 22.2.6 `image` 与图像目录的“隐形优先级”

有两个容易被忽略、但排错时至关重要的默认优先级：

- **`image` 语句的默认优先级是 500**（不是 0）。它是在 0 的基础上**加 500** 得到的，所以 `image` 定义天然排得**很晚**。
- **`game/images/` 等图像目录自动定义的图像，优先级是 0**（所以比显式 `image` 语句早）。

为什么这样设计？因为**图像目录里的文件会自动变成图像名**（见 22.3.3），而“显式 `image` 语句应当能覆盖自动定义”。把 `image` 语句放到 500，就保证了无论你的图像目录扫描结果如何，手写的 `image` 定义总是最后生效、说了算。

如果你在同一优先级里又写了 `init offset`，记住 `image` 语句的 500 是**相对默认**的（会被 offset 加减）。

### 22.2.7 `define` 与 `default` 的时机差异

这两个语句看起来都在“声明变量”，实际时机完全不同：

- **`define`**：在 **`init` 阶段**执行（等价于 `init python: x = ...`）。它定义的被视为**常量**，**不保存进存档、不参与回滚**。所以 `define` 只适合真正的常量——配置项、颜色、字号、函数引用。
- **`default`**：**不在 `init` 阶段执行**。它在“游戏开始或新游戏载入后、如果变量尚未定义”时赋值（见 22.2.8）。它定义的是**游戏状态**，会**保存进存档、参与回滚**。

一个典型的判断口诀：**“这个东西会不会随玩而变？”** 会变（分数、好感度、是否见过某角色）→ `default`；不会变（字体大小、界面颜色）→ `define`。

> 第 21.6 节已经论证过：`default` 变量是否被重置，取决于存档里的 `_defaults_set`。新增的 `default` 变量在读档时会自动补默认值，已存在的不会。所以“加字段靠 `default`”，这与本节“`default` 不在 init 执行”并不矛盾——它是在另一个时机补值的。

### 22.2.8 `default` 到底什么时候跑

官方 [Python Statements](https://www.renpy.org/doc/html/python.html) 与 [Lifecycle](https://www.renpy.org/doc/html/lifecycle.html) 的说法可以合并成一串时机：

1. **游戏开始时**（`_start` 之后、splashscreen 与主菜单运行之前）；
2. **每次新游戏/读档载入后**；
3. **每次回滚后**；
4. **运行 lint 前**；
5. 以及文档所说的“**可能存在的其他时机**”。

“赋值的实际点，在 splashscreen 与主菜单运行之前”。所以你在 `splashscreen` label 里读一个 `default` 变量，读到的是它已经赋过的默认值——这一点比“主菜单从哪来”更容易搞错，值得记住。

`config.after_default_callbacks` 里注册的回调会在所有 default 赋值后运行，适合做“依赖 default 值的初始化”。

### 22.2.9 一张排错用的顺序表

把 22.2 的全部规则压成一张查表：

| 问题现象 | 大概率原因 | 检查点 |
| --- | --- | --- |
| 我的 `init` 里读到的变量是旧值/被覆盖 | 优先级或文件顺序不对 | 给关键的 `init` 加更低的优先级（如 `-1`） |
| 屏幕里 `screen X` 报未定义 | 定义在更晚的文件里 | 把 screen 定义提到靠前文件，或降优先级 |
| `image` 被图像目录“顶掉” | 图像目录（优先级 0）比你的 `init python`（0）还早 | 显式用 `image` 语句（优先级 500）覆盖 |
| 自定义语句在解析时就不认识 | 该注册没写在 `python early` 里 | 挪到 `python early` |
| `default` 变量在 `init` 里读为 `None` | `default` 不在 init 执行 | 改在 `splashscreen`/`start` 里读 |

---

## 22.3 目录与文件：哪些是自动的，哪些是你必须管的

上一节讲了“谁先执行”，这一节讲“放哪儿、叫什么名字会有副作用”。Ren’Py 有一套**约定优于配置**的设计：很多目录和文件名本身就是配置。

### 22.3.1 `.rpy`、`.rpyc` 与 `.rpym`

三种扩展名的分工：

| 扩展名 | 是什么 | 你要不要管 |
| --- | --- | --- |
| `.rpy` | 你手写的**源脚本** | 要。这是你写代码的地方 |
| `.rpyc` | 引擎编译 `.rpy` 后生成的**字节码** | 通常不管。启动时若 `.rpyc` 比 `.rpy` 新，就直接用 `.rpyc`，跳过重新编译 |
| `.rpym` | 一种“模块化脚本”扩展名，主要用于翻译等场景 | 极少手写 |

关于 `.rpyc`，官方 [Language Basics](https://www.renpy.org/doc/html/language_basics.html) 里有两条**必须知道**的规则：

1. **`.rpyc` 没有对应 `.rpy` 时仍会被执行。** 这意味着：如果你删掉了某个 `.rpy` 但忘了删它的 `.rpyc`，旧代码**依然在跑**——你会看到“删了代码却还生效”的诡异现象。
2. **因此，删除一个脚本时，必须把 `.rpy` 和 `.rpyc` 一起删掉**（或删掉所有 `.rpyc` 后重新启动让引擎重编）。

发布时则相反：**建议把编译好的 `.rpyc` 一起打包**（第 24 章会讲原因：玩家换了引擎版本或缺少编译环境时，`.rpyc` 是保底）。这与“源码 `.rpy` 是否随包发布”是两个独立问题。

### 22.3.2 脚本的扫描范围：`game/` 递归全部

引擎会**递归扫描 `game/` 及其所有子目录**，把找到的 `.rpy` / `.rpyc` 合成一份脚本。注意两个细节：

- **子目录里的脚本同样会被加载**，你用的是哪个子目录只影响 22.2.2 的排序，不影响“是否加载”。
- 打包文件（`.rpa`）如果存在，引擎会自动读取并使用；你用启动器“归档”功能把素材打进 `.rpa` 后，不必改任何代码。

所以你完全可以用子目录来组织工程：

```
game/
├── script.rpy              # 入口：label start
├── options.rpy             # 配置
├── screens.rpy / gui.rpy   # 界面
├── chapters/               # 章节剧本
│   ├── ch01.rpy
│   └── ch02.rpy
├── characters.rpy          # 角色定义
├── images/                 # 图像素材（见 22.3.3）
├── audio/                  # 音频素材（见 22.3.4）
└── tl/                     # 翻译（见 22.3.5）
```

> 子目录名参与 Unicode 排序（22.2.2）。所以 `chapters/` 里的脚本会排在根目录 `script.rpy` 之前（`c` < `s`）。这通常无害——因为真正的顺序仍由 `init` 优先级控制——但如果你在 `chapters/ch01.rpy` 的 `init python` 里定义了一个类，而 `script.rpy` 的 `init python` 要用它，就要小心：两者都是 `init 0`，于是按文件顺序，`chapters/ch01.rpy` 先——运气好时能用，一旦重命名目录就可能崩。**正确做法是显式指定优先级**，不要依赖目录名。

### 22.3.3 图像目录：文件名即图像名

这是 Ren’Py 最省事的设计之一。把图片放进 `game/images/`（含子目录），引擎会自动把**文件名**变成图像名：

- 去掉扩展名；
- 转成小写；
- 若该名字尚未被 `image` 语句定义，就用它作为图像名。

支持的扩展名由 `config.image_extensions` 决定，默认为：

```renpy
define config.image_extensions = [ ".jpg", ".jpeg", ".png", ".webp", ".avif", ".svg" ]
```

若干规则要记住（出自 [Displaying Images](https://www.renpy.org/doc/html/displaying_images.html)）：

- **子目录名被忽略**。`game/images/bg/forest.png` 和 `game/images/forest.png` 得到的图像名都是 `forest`（只有文件名参与）。因此**不同子目录里不要放同名文件**，否则会互相覆盖（而且是按文件顺序，谁后定义谁赢，难以预测）。
- **下划线是惯例**。文件名 `eileen_happy.png` → 图像名 `eileen_happy`。这是“角色_表情”的常用写法。
- **显式 `image` 语句优先**。因为 `image` 语句优先级 500 高于自动定义的 0（22.2.6）。所以你想让 `image eileen happy = "custom.png"` 覆盖自动扫描，直接写即可。
- 图像目录本身由 `config.image_directories` 控制，默认是：

```renpy
define config.image_directories = [ "images" ]
```

也就是说，**只有 `game/images/` 这个子目录**参与自动定义。若你想再加一个 `game/sprites/`，需要把它加进这个列表。

### 22.3.4 音频目录与 audio 命名空间

音频素材放 `game/audio/`。与图像不同，音频默认**不会**自动生成可直接 `play` 的名字；它由 `config.audio_directories` 指定：

```renpy
define config.audio_directories = [ 'audio' ]
```

这个配置的作用是：把这些目录里的音频**注册到 `audio` 命名空间**，于是你可以用路径化的名字来播放，而不用记完整文件名。例如 `game/audio/bgm/theme.ogg` 可以用 `audio.bgm.theme` 这样的名字引用（具体形式取决于引擎的文件名规范化）。最稳妥、最可读的写法仍然是显式 `define`：

```renpy
define audio.theme = "audio/bgm/theme.ogg"
...
play music theme
```

### 22.3.5 翻译目录 `tl/`

多语言翻译放在 **`game/tl/<language>/`** 下，详见 [Translation](https://www.renpy.org/doc/html/translation.html)。要点：

- **语言名必须是合法的 Python 标识符**（字母/数字/下划线，不能有连字符或空格）。`game/tl/chinese/` 合法，`game/tl/zh-CN/` **不合法**。
- **主语言本身用 `None` 表示**，对应目录 `game/tl/None/`。引擎自带的翻译也放在 `game/tl/None/common.rpym`。
- 翻译文件里通常**只包含 `translate` 块**。引擎提供 `config.defer_tl_scripts = True`（默认即如此），它阻止 `tl/` 下的脚本在普通 `init` 阶段被加载——如果这些文件里混进了别的代码，行为会变得不可预期。**不要在 `tl/` 里写游戏逻辑。**

### 22.3.6 一个自查清单

| 你想做的事 | 放哪里 / 怎么写 |
| --- | --- |
| 加一张背景图并直接用 | 丢进 `game/images/`，用文件名（小写）当图像名 |
| 让某张图用特殊定义 | 用 `image` 语句（优先级 500，覆盖自动定义） |
| 加 BGM | 丢进 `game/audio/`，或 `define audio.xxx = "audio/..."` |
| 加一章剧本 | 新建 `game/chapters/ch03.rpy`，无需注册 |
| 删一章剧本 | 删 `.rpy` **和** `.rpyc` |
| 加翻译 | `game/tl/<语言名>/xxx.rpy`，只放 `translate` 块 |
| 加新的图像扫描目录 | 改 `config.image_directories` |

---

## 22.4 options.rpy：一个工程的设置中心

新建工程时，启动器会生成一个 `game/options.rpy`。它不是引擎的“特殊文件”——`game/` 下任何 `.rpy` 都会被加载——但它**约定俗成**地放在这里，集中写所有 `config.*` 配置。本节逐组讲解最常用的配置项。

先给出一个**自包含、可直接跑**的 `options.rpy` 骨架，后面逐条解释：

```renpy
# ===========================================================================
# game/options.rpy —— 工程级配置
# 说明：这些大多用 define（常量，不存档），少数（如 preferences）用 default。
# ===========================================================================

## 基本标识 ----------------------------------------------------------------

# 游戏名。显示在窗口标题、存档描述等处。
define config.name = _("我的游戏")

# 版本号。会显示在关于界面，也影响 build.version 的默认取值（第 24 章）。
define config.version = "1.0"

# 窗口标题。为 None 时自动使用 config.name。
define config.window_title = None

## 存档 --------------------------------------------------------------------

# 存档目录名。必须唯一，避免不同游戏互相覆盖存档。
# 注意：必须在 define 或 python early 中设置；不要设成 None（会退化到 game/ 下）。
define config.save_directory = "mygame-1"

# 存档时是否附一份可读的调试信息（体积会明显变大，正式发布建议 False）。
define config.save_dump = False

## 声音开关 ----------------------------------------------------------------

define config.has_sound = True
define config.has_music = True
define config.has_voice = True

## 主菜单音乐 --------------------------------------------------------------

# 主菜单 BGM。可以直接填音频文件名；用 "<silence 30.0>" 表示“静默 30 秒”。
define config.main_menu_music = None

# 主菜单 BGM 淡入时长（秒）；0 表示不淡入。
define config.main_menu_music_fadein = 0.0

## 文本显示速度 ------------------------------------------------------------

# 用 preferences（玩家偏好）而不是 config —— 这样玩家能在设置界面里改。
default preferences.text_cps = 0        # 每秒钟显示字符数；0 = 立即全显
default preferences.afm_time = 15       # 自动前进等待时间
default preferences.afm_enable = False  # 是否默认开启自动前进

## 回滚 --------------------------------------------------------------------

# 是否允许回滚（滚轮上推/PageUp 回到之前）。
define config.rollback_enabled = True

# 硬回滚上限：一次“回滚链”最多能回退多少个操作。
define config.hard_rollback_limit = 100

# 保留的回滚日志长度（越大越占内存，但能回退更远）。
define config.rollback_length = 128

## 自动存档 ----------------------------------------------------------------

# 每多少“操作”自动存一次档（0 表示关闭）。
define config.autosave_frequency = 200

# 退出游戏时是否自动存档。
define config.autosave_on_quit = True

# 自动存档槽位数。
define config.autosave_slots = 10

## 窗口与分辨率 ------------------------------------------------------------

# 窗口图标（.ico / .png）。None 表示用默认图标。
define config.window_icon = None

# 分辨率。默认 800x600；GUI 模板会在 gui.rpy 里用 gui.init() 覆盖为 1280x720。
define config.screen_width = 800
define config.screen_height = 600

## 开发者与调试 ------------------------------------------------------------

# 开发者模式：True / False / "auto"（"auto" 表示有 .rpy 源文件时才开）。
define config.developer = "auto"

# 是否允许 Shift+O 调出控制台（第 23 章）。
define config.console = False

## 语言 --------------------------------------------------------------------

# 默认语言（None = 主语言）。
define config.default_language = None

## 鼠标与音频淡出 ----------------------------------------------------------

# 自定义鼠标光标（一个“光标名 -> 图片”的字典），None 表示用系统光标。
define config.mouse = None

# 停止音频时的淡出时长，避免“啪”的爆音。
define config.fadeout_audio = 0.016

## 日志（log.txt） ---------------------------------------------------------

# 是否把错误/日志写入 log.txt（None 表示用默认行为）。
define config.log = None

# 日志每行宽度。
define config.log_width = 78
```

下面分组讲解。**每条都给出默认值**——你不需要把上面全部写进自己的工程；只写你真正要改的即可，其余保持引擎默认。

### 22.4.1 游戏标识：name / version / window_title

| 配置 | 默认值 | 作用 |
| --- | --- | --- |
| `config.name` | `""` | 游戏名。显示在窗口标题、存档信息、关于界面 |
| `config.version` | `""` | 版本号。`build.version` 为 `None` 时会取它（第 24 章） |
| `config.window_title` | `None` | 窗口标题。`None` 时取 `config.name` |

一个常见困惑是“我改了 `config.name` 但窗口标题没变”。原因通常是 `config.window_title` 被设成了别的值——它一旦非 `None` 就**优先于** `config.name`。另外这些值若在 `init` 之后才改，界面可能来不及刷新，所以**用 `define` 写在 `init` 阶段**最保险。

### 22.4.2 存档：save_directory 与 save_dump

`config.save_directory` 是**最容易出事**的一项，务必按以下三条来：

1. **必须唯一**。存档默认存在用户目录下以这个名字命名的文件夹里。两个游戏同名目录 → 存档互相覆盖。
2. **不要设为 `None`**。设为 `None` 时引擎会把存档留在 `game/` 下的 `saves/` 里（官方明确“不推荐”——这样存档会混进游戏目录、难以跨版本管理）。
3. **必须在 `define` 或 `python early` 中设置**。因为引擎在很早的阶段就要用它来定位存档目录，晚于 init 的设置可能来不及生效。

`config.save_dump`（默认 `False`）：设为 `True` 时，存档里会附一份可读的调试转储。排错时很有用，但会让存档文件显著变大，正式发布保持 `False`。

### 22.4.3 声音开关与主菜单音乐

`config.has_sound` / `has_music` / `has_voice` 默认都是 `True`。它们控制**设置界面里是否显示对应的音量滑条**。做成纯阅读、无音乐的电子小说时可以关掉 music 一项，界面会更干净。

主菜单 BGM 有两个：

- `config.main_menu_music`（默认 `None`）：填音频文件名。**它支持特殊的“伪文件名”**——引擎里把 `"<silence 秒数>"` 解释为一段静音（源码见 `renpy/audio/audio.py`：当子句是 `silence` 时，内部映射到 `_silence.ogg`）。第 21.7 节的示例就用 `"<silence 30.0>"` 占位，避免依赖真实音频素材。
- `config.main_menu_music_fadein`（默认 `0.0`）：淡入秒数。

还有一个在第 21 章讲过的细节值得在此重复：返回主菜单时被停掉的通道是 `config.main_menu_stop_channels`，**默认含 `sound`、`voice`、`movie`，但不含 `music`**。这就是为什么“主菜单 BGM 从剧情回到主菜单后还在放”——如果你希望回主菜单时切换音乐，需要自己处理。

### 22.4.4 文本速度与自动前进：用 preferences，不用 config

这是本次修订**必须纠正**的一个历史遗留点。老教程里常见的 `config.default_text_cps`、`config.default_afm_time`、`config.default_afm_enable`，在**当前官方文档中已不存在**。现行做法是直接给玩家的 `preferences` 设默认值：

```renpy
default preferences.text_cps = 0        # 每秒字符数，0 = 不过渡、整段立即显示
default preferences.afm_time = 15       # 自动前进的等待时间
default preferences.afm_enable = False  # 默认是否开自动前进
```

为什么用 `default` 而不是 `define`？因为这些是**玩家偏好**：它们会存进 `persistent`（第 15 章）并由设置界面修改，属于“会变的状态”。用 `default` 才符合它的语义，也能被玩家在界面上改。

> 说明：如果你在别处（如老书）看到 `config.default_text_cps`，可以理解为那是**早期版本**的写法；新工程请统一用上面的 `preferences.*` 形式。

### 22.4.5 回滚三项

| 配置 | 默认值 | 作用 |
| --- | --- | --- |
| `config.rollback_enabled` | `True` | 是否允许回滚 |
| `config.hard_rollback_limit` | `100` | 一次回滚链最多回退多少个操作 |
| `config.rollback_length` | `128` | 保留的回滚日志条数 |

第 14 章讲过回滚的机制。这里补充一个实践建议：**视觉小说通常保持默认即可**；但如果你做了“时间回溯”类玩法需要精确控制回滚边界，就要动 `rollback_length`——调大能回到更远，代价是内存占用上升。

### 22.4.6 自动存档三项

| 配置 | 默认值 | 作用 |
| --- | --- | --- |
| `config.autosave_frequency` | `200` | 每 200 个操作自动存一次（0 = 关闭） |
| `config.autosave_on_quit` | `True` | 退出时自动存档 |
| `config.autosave_slots` | `10` | 自动存档槽位数 |

`config.autosave_on_quit` 与第 21.5 节的 `MainMenu()` 动作相配合：从游戏内点“返回主菜单”时，如果开启了它，引擎会先强制自动存档，再弹确认框（`MainMenu` 源码里那段 `if config.autosave_on_quit: renpy.force_autosave()`）。所以“回主菜单会不会丢进度”其实由这一项决定。

### 22.4.7 窗口、分辨率与图标

`config.screen_width` / `config.screen_height` 默认是 `800` / `600`。但**GUI 模板工程会在 `gui.rpy` 里调用 `gui.init(1280, 720)`，从而覆盖这两个值**——所以你在 `options.rpy` 里写的宽高，若工程用了 GUI，实际会被 `gui.init` 的参数覆盖。想改分辨率，认准 `gui.init()` 的参数，而不是 `config.screen_width`。

`config.window_icon`（默认 `None`）设置窗口/任务栏图标，通常给一个 `.ico`（Windows）或 `.png`。

### 22.4.8 开发者模式与调试开关

- `config.developer`（默认 `"auto"`）：可取 `True` / `False` / `"auto"`。`"auto"` 表示“当工程里存在 `.rpy` 源文件时自动开启开发者模式”。发布正式版（只发 `.rpyc`）时会自动变 `False`，非常方便。第 23 章讲的调试功能都依赖它是真值。
- `config.console`（默认 `False`）：是否允许打开控制台。设为 `True` 后任意时刻可按 `Shift+O` 调出（第 23 章）。

### 22.4.9 语言、鼠标、音频淡出

- `config.default_language`（默认 `None`）：默认语言。`None` 表示主语言（对应 `tl/None/`）。
- `config.mouse`（默认 `None`）：自定义光标。给一个字典，例如 `{"default": [("cursor.png", 0, 0)]}`；`None` 表示使用系统光标。
- `config.fadeout_audio`（默认 `0.016`）：停止音频时的淡出秒数。别设成 0——那会产生爆音。

### 22.4.10 日志：定位 log.txt

排错时你会反复找 `log.txt`。相关配置：

| 配置 | 默认值 | 作用 |
| --- | --- | --- |
| `config.basedir` | （只读） | 工程的基准目录，通常是 `game/` 的上一级；`log.txt` 一般就生成在这里 |
| `config.log` | `None` | 日志文件名；`None` 用默认行为 |
| `config.log_width` | `78` | 日志每行宽度 |

出问题时，先看工程根目录（`game/` 的同级）下的 `log.txt` 与 `errors.txt`——这是最直接的第一手现场。`config.developer` 为真时，错误还会直接弹到屏幕上（第 23 章会细讲开发者工具的用法）。

---

## 22.5 本章小结与实践

**小结表**

| 知识点 | 要点 |
| --- | --- |
| 两大阶段 | Boot Time（引擎自身）与 Script Execution（解析脚本 → 执行 init → 进入 `_start`） |
| 文件读取顺序 | `game/` 递归扫描，按**完整路径 Unicode 排序**；子目录名先于文件名参与比较 |
| `python early` | 在“本文件解析完、下一文件开始前”执行；用于注册自定义语句/ warper；`init python early` 是冗余写法 |
| init 排序算法 | ① 比优先级（小者先）② 同优先级按文件 Unicode 路径 ③ 文件内自上而下 |
| 优先级区间 | 作者用 `-99~99`；库/模组用 `-999~-100` 与 `100~999`；其余保留给引擎 |
| `init offset` | 改变其后所有 init 的**默认优先级**（偏移量，非绝对值），直到下一个 `init offset` |
| `image` 优先级 | 默认 **500**；图像目录自动定义在 **0**——所以显式 `image` 语句总赢 |
| `define` vs `default` | `define` 在 init 执行、是常量、不存档；`default` 不在 init 执行、是状态、会存档 |
| `default` 时机 | 游戏开始/载入后、读档后、回滚后、lint 前；实际赋值点在 splash 与主菜单**之前** |
| `.rpyc` 陷阱 | 无 `.rpy` 的 `.rpyc` 仍会执行；删脚本要 `.rpy` 与 `.rpyc` 一起删 |
| 文件名约定 | **不要用 `00` 开头**（引擎保留）；`images/` 下文件名自动成为图像名（小写、忽略子目录） |
| 翻译目录 | `game/tl/<语言名>/`，语言名须为合法 Python 标识符；主语言用 `None` |
| 分辨率 | GUI 工程认 `gui.init(w, h)`，它会覆盖 `config.screen_width/height` |
| 文本速度 | 用 `preferences.text_cps / afm_time / afm_enable`，**不存在** `config.default_text_cps` 等 |

**实践题**

1. **制造并修复一个顺序错误。** 新建两个文件 `a_late.rpy` 与 `b_early.rpy`。在 `a_late.rpy` 里写 `init python: VALUE = 1`，在 `b_early.rpy` 里写 `init python: print(VALUE)`（或 `init python: store.X = VALUE`）。先观察谁先执行（提示：按文件路径 `a` < `b`，所以 `a_late` 先），再把 `b_early.rpy` 的 init 改成 `init -1 python:`，看顺序如何被优先级翻转。这题的目的，是让你亲手确认“文件顺序只在同优先级内起作用”。

2. **验证 `default` 的赋值时机。** 写 `default hp = 100`，然后在 `label splashscreen` 里 `"[hp]"`，再在 `label start` 里 `"[hp]"`。两处都能读出 100 吗？再用 `init python: store.hp2 = hp` 试试——它会不会报 `NameError`？解释你看到的现象。

3. **覆盖一张自动图像。** 在 `game/images/` 放一张名为 `bg.png` 的图（随便什么图都行），于是会自动得到图像名 `bg`。然后在脚本里写 `image bg = Solid("#123456")` 并 `scene bg`。你看到的是图片还是纯色？为什么？（提示：回到 22.2.6 的优先级。）

4. **给 `16_full_project` 换一套设置。** 打开第 16 章的完整工程示例，把 `config.name`、`config.version`、`config.save_directory` 改成你自己的值；再把文本速度默认改成 `preferences.text_cps = 30`（每秒 30 字）。启动后在设置界面确认滑条位置与你设的默认一致。

---

> [← 第 21 章 开场动画与游戏生命周期](ch21-splash-and-lifecycle.md) ｜ [目录](index.md) ｜ [第 23 章 调试与自动化测试 →](ch23-debug-and-testing.md)
