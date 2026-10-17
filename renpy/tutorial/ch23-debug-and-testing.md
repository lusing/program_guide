# 第 23 章 调试与自动化测试

> [← 第 22 章 项目组织与配置：从目录到 settings](ch22-project-and-config.md) ｜ [目录](index.md) ｜ [第 24 章 构建与发布 →](ch24-build-and-distribution.md)

写代码的绝大部分时间不是在“写”，而是在“找为什么没按预想运行”。这一章把 Ren’Py 提供的调试武器一次讲全：开发者模式与快捷键、控制台、lint 静态检查、命令行工具、以及自动化测试框架。

## 23.1 开发者模式：先打开总开关

前面所有调试功能都建立在 `config.developer` 为真之上。它的默认值是 `"auto"`：

```renpy
define config.developer = "auto"
```

三种取值的行为（出自 [Configuration Variables](https://www.renpy.org/doc/html/config.html)）：

| 取值 | 行为 |
| --- | --- |
| `True` | 强制开启开发者模式 |
| `False` | 强制关闭 |
| `"auto"` | 工程里存在 `.rpy` 源文件时开启；只发 `.rpyc` 时关闭 |

`"auto"` 的妙处在于**你什么都不用改**：开发时你在本机有 `.rpy`，开发者模式自动打开；发布时构建流程不打包 `.rpy`（第 24 章），玩家的游戏里自动关闭。所以除非有特殊需求，**保持 `"auto"`**。

开发者模式打开后，你会额外获得：

- 错误发生时**直接在屏幕上显示报错页**（含 traceback），而不是静默退出；
- 一整套调试快捷键（23.2）；
- 控制台（23.3）；
- 一些界面上的辅助标记（如文本溢出提示 `config.debug_text_overflow`）。

另外 `renpy.is_init_phase()` 之类的检查在开发模式下更严格——比如 `gui.init()` 若在 `init` 阶段之外被调用，开发模式下会直接 **raise** 报错，帮你尽早发现误用。

---

## 23.2 开发者快捷键：一张必须记住的表

Ren’Py 的调试快捷键都定义在引擎的 keymap 里，对应 [Keymap](https://www.renpy.org/doc/html/keymap.html) 文档（该页当前标注的版本是 8.4.0，但默认键位在 8.5.x 未变）。下表是**从默认 keymap 里逐条核对过的**：

| 键位 | 名称 | 作用 |
| --- | --- | --- |
| `Shift+O` | `console` | 打开/关闭**控制台**（23.3） |
| `Shift+E` | `launch_editor` | 用外部编辑器打开**当前正在执行的语句**所在文件并定位 |
| `Shift+D` | `developer` | 打开**开发者菜单**（跳转标签、查看变量、重载等） |
| `Shift+R` | `reload_game` | **保存并重载脚本**（见下方说明） |
| `Shift+I` | `inspector` | 打开**样式检查器**（查看鼠标所指元素的样式） |
| `Alt+Shift+I` | `full_inspector` | 完整检查器 |
| `>` | `fast_skip` | 按住时**快速跳过**（比普通 skip 更快） |
| `Tab` | `toggle_skip` | 切换“跳过”模式 |
| `F3` | `performance` | 性能信息面板 |
| `F4` | `image_load_log` | 图像加载日志 |
| `F7` | `memory_profile` | 内存占用快照 |
| `F8` | `profile_once` | 采一次性能剖析 |
| `F1` | `help` | 帮助 |
| `F2` | `progress_screen` | 进度/剧情流程画面 |
| `Esc` / 鼠标右键 | `game_menu` | 打开游戏菜单 |

关于 **`Shift+R`（保存并重载脚本）**，有几条重要规则（出自 [Developer Tools](https://www.renpy.org/doc/html/developer_tools.html)）：

1. 它会把**改动过的脚本重新加载**，并**回到当前语句附近**继续运行——这是最常用的“改一行、马上看效果”手段，省去重启。
2. **第一次按 `Shift+R` 之后，引擎进入 autoreload 模式**：此后你在外部编辑器里改动任何 `.rpy`，Ren’Py 检测到变化会**自动重载**，不需要再按。
3. **在 replay（回放）期间不工作。** 这一点和 `utter_restart`/`reload_script` 的源码逻辑一致（第 21.5 节：`if renpy._in_replay: return`）。

再强调一遍**不要凭空记快捷键**：像 `Shift+M`、`Shift+U`、`Ctrl+O` 这类组合，**在当前默认 keymap 中并不存在**。要查某个功能的实际键位，最可靠的办法是：

- 打开控制台（`Shift+O`）输入 `config.keymap["<动作名>"]` 查看；
- 或在脚本里 `init python: print(config.keymap)` 打印整张表。

你也可以在 `options.rpy`（或任一脚本）里**覆盖**某个键位：

```renpy
init python:
    # 把“打开控制台”改成只用 Ctrl+O（自定义，非默认）
    config.keymap["console"] = ["ctrl_K_o"]
```

---

## 23.3 控制台：运行中的“Python 交互式窗口”

按 `Shift+O` 打开的就是**控制台**。它需要 `config.developer` 为真；若想发布版也带控制台（不建议），把 `config.console` 设为 `True`。

控制台本质上是一个**在游戏当前状态下运行的交互式解释器**：你敲进去的 Python 立即在当前 `store` 里执行，和游戏共享同一份变量。它是排查“运行时到底怎么了”的第一利器。

### 23.3.1 它可以做什么

- **查看/修改变量**：输入 `hp` 回车看值，输入 `hp = 999` 直接改（改完游戏里立刻生效）。
- **调用函数**：`renpy.notify("hi")`、`renpy.full_restart()` 等直接在真机上试。
- **跳转**：`jump chapter_two` 直接跳到某个 label。
- **跑 Ren’Py 语句**：不只是 Python，**Ren’Py 语句也能直接输入**（例如 `show eileen happy`、`scene bg`），控制台会按当前上下文执行。
- **看调用栈**：`stack`。

### 23.3.2 内置命令清单

控制台自己实现了一批以“不带括号”形式输入的命令（与 Python 表达式区分）。**完整清单**如下（出自 [Developer Tools](https://www.renpy.org/doc/html/developer_tools.html)）：

| 命令 | 作用 |
| --- | --- |
| `clear` | 清屏 |
| `escape` | 把提示符切到“纯 Python 模式”（之后输入按 Python 处理） |
| `unescape` | 退出纯 Python 模式 |
| `exit` | 关闭控制台 |
| `help` | 显示帮助 |
| `help <expr>` | 对给定表达式显示帮助（如 `help renpy.notify`） |
| `jump <label>` | 跳转到指定 label |
| `load <slot>` | 读取指定存档槽 |
| `save <slot>` | 保存到指定存档槽 |
| `reload` | 重载脚本（相当于 `Shift+R`） |
| `long` | 让结果显示“长形式”（不截断、展开对象） |
| `short` | 让结果显示“短形式”（默认） |
| `stack` | 打印当前调用栈 |
| `watch <expression>` | 监视表达式，值变化时提示（调试“谁改了我的变量”） |
| `watch short <expression>` | 监视并只显示简略信息 |
| `watch long <expression>` | 监视并显示详细信息 |
| `unwatch <expression>` | 取消对某表达式的监视 |
| `unwatchall` | 取消所有监视 |

除这些命令外，你输入的任何内容都会**先尝试作为 Ren’Py 语句解析，再作为 Python 表达式求值**——所以 `show eileen happy` 和 `hp + 1` 都能直接敲。

### 23.3.3 实战：用 `watch` 抓“谁改了变量”

想象一个 bug：剧情里好感度 `affection` 莫名其妙变小了，但代码里到处都在改它。做法：

1. `Shift+O` 打开控制台，输入 `watch affection`。
2. 关闭控制台，正常推进剧情。
3. 每当 `affection` 的值发生变化，控制台会提示你，并给出发生改变的语句位置——顺着它就能定位到那一行。

这比到处 `print` 高效得多。用完 `unwatch affection` 或 `unwatchall` 关掉即可。

---

## 23.4 Lint：不运行游戏就能发现的问题

**Lint** 是 Ren’Py 的静态检查器：它**不启动游戏**，只把脚本过一遍，报告诸如“定义了什么角色、用了哪些图像/音频、引用了不存在的标签、有未翻译的字符串”等问题。它的最大价值是——**把“游戏跑到一半才崩”的问题提前到发布前发现**。

### 23.4.1 怎么运行

在命令行里：

```bash
./renpy.sh /path/to/my_game lint
```

形式是 `./renpy.sh <basedir> lint [<filename>] [options]`。其中 `<basedir>` 是**工程根目录**（`game/` 的上一级）。

**常用选项**（出自 [Command Line Interface](https://www.renpy.org/doc/html/cli.html) 与 [Developer Tools](https://www.renpy.org/doc/html/developer_tools.html)）：

| 选项 | 作用 |
| --- | --- |
| `--error-code` | 若发现错误，**以退出码 1 结束**——CI 里判断“这次提交是否通过”就靠它 |
| `--no-orphan-tl` | 不检查“孤儿翻译条目” |
| `--reserved-parameters` | 报告使用了保留参数名的问题 |
| `--by-character` | 按角色汇总统计 |
| `--check-unclosed-tags` | 检查未闭合的文本标签（如 `{b}` 没配 `{/b}`） |
| `--all-problems` | 报告所有问题（不省略） |

> **防混淆**：`--warnings` 与 `--check-python` **不存在**于当前文档中。别把它们写进脚本，否则命令行会直接报错。

### 23.4.2 相关的配置项

| 配置 | 默认值 | 作用 |
| --- | --- | --- |
| `config.lint_character_statistics` | `True` | 是否统计每个角色的台词量 |
| `config.lint_show_names` | `False` | 是否在 lint 输出里显示内部名字 |
| `config.lint_hooks` | `[...]` | 一组钩子函数，lint 时逐个调用，可以在其中写自己的检查 |

如果写了自定义的**创作者自定义语句**（CDS），务必也给它实现 lint 支持，否则 lint 可能无法正确解析你的语句——这是官方明确提醒的一点。

### 23.4.3 lint 能抓到什么、抓不到什么

**能抓到：**

- 引用了不存在的 `label`（`call` / `jump` 目标缺失）；
- `image` / `audio` 名字拼错（找不到对应文件）；
- 角色未定义或重复定义；
- 文本标签未闭合；
- 翻译缺失/多余的条目；
- 一些明显的表达式书写错误。

**抓不到：**

- 运行时的逻辑错误（如除零、`None` 属性访问）；
- 只在特定分支才走的坏路径；
- 界面（screen）在特定数据下才出现的布局问题。

**抓不到的那部分，靠 23.6 的自动化测试来补。**

lint 的典型用法是**每次提交前跑一遍**，并配合 `--error-code` 让 CI 在出错时红灯。

---

## 23.5 命令行工具：`renpy.sh` 的全貌

Ren’Py SDK 里那个 `renpy.sh`（Windows 上是 `renpy.exe`）不只能启动游戏，它是一个完整的命令行入口。掌握它，才能把 Ren’Py 接进自动化流程。

### 23.5.1 通用语法

```bash
./renpy.sh [全局选项] [<basedir>] [<命令>] [命令选项]
```

- **`<basedir>`**：工程根目录。省略时进入启动器/默认行为。
- **`<命令>`**：要执行的操作，如 `lint`、`compile`、`test`、`run`。
- **全局选项**放在最前面。

### 23.5.2 全局选项（出自 [CLI](https://www.renpy.org/doc/html/cli.html)）

| 选项 | 作用 |
| --- | --- |
| `--savedir <dir>` | 指定存档目录（覆盖默认存档位置，便于隔离测试） |
| `--trace <level>` | 打开跟踪输出：`1` = 每次调用，`2` = 逐行 |
| `--version` | 打印版本号后退出 |
| `--compile` | 只编译，不启动 |
| `--compile-python` | 编译 Python 部分 |
| `--keep-orphan-rpyc` | 保留“孤儿” `.rpyc`（无对应 `.rpy` 的编译产物） |
| `--errors-in-editor` | 出错时在编辑器里打开出错文件 |
| `--safe-mode` | 安全模式：跳过可能出错的用户 `init` 代码启动 |
| `--help` / `-h` | 帮助 |
| `--json-dump <file>` | 把脚本结构导出为 JSON（工具链集成用） |
| `--json-dump-private` | JSON 导出时包含私有信息 |
| `--json-dump-common` | JSON 导出时包含 `renpy/common` 部分 |

### 23.5.3 子命令一览

| 命令 | 作用 |
| --- | --- |
| `run` | 运行游戏。选项：`--profile-display <file>`、`--debug-image-cache`、`--warp <文件:行号>` |
| `quit` | 让当前运行中的实例退出 |
| `compile` | 编译脚本（`.rpy → .rpyc`）。选项 `--keep-orphan-rpyc` |
| `director` | 启动“导演模式”（早期辅助工具） |
| `rmpersistent` | 删除 persistent 数据（跨语言/测试常用） |
| `update <url>` | 从指定 URL 做增量更新 |
| `lint` | 静态检查（23.4） |
| `test` | 自动化测试（23.6） |
| `add_from` | 为缺失 `from` 的 `call` 补 `from` 子句（23.7） |
| `distribute` | **打包发布**——注意它实际以 `launcher distribute` 形式调用（第 24 章） |
| `android_build` | 构建 Android 包 |
| `ios_create` / `ios_populate` | 创建/填充 iOS Xcode 工程 |
| `web_build` | 构建 Web（浏览器）版本 |
| `translate` | 翻译相关批处理 |
| `dialogue` | 导出对话文本 |
| `extract_strings` | 抽取待翻译字符串 |
| `merge_strings` | 合并翻译字符串 |
| `generate_gui` | 重新生成 GUI |
| `gui_images` | 生成 GUI 图像 |
| `get_projects_directory` | 读取“工程目录”设置 |
| `set_projects_directory <dir>` | 设置“工程目录” |
| `set_project <dir>` | 设置当前工程 |
| `update_old_game` | 更新旧游戏到新版引擎结构 |

其中几个**本课程会用到**的：`compile`（编译验证）、`lint`（静态检查）、`test`（自动化测试）、`web_build`/`android_build`（第 24 章会结合起来讲）。

### 23.5.4 注册你自己的子命令

引擎允许你**扩展**这套 CLI——用 `renpy.arguments.register_command()`：

```renpy
init python:
    def my_command(args):
        # 这里写你的逻辑，args 是命令行参数对象
        print("hello from my_command", args)

    renpy.arguments.register_command("my_command", my_command,
                                     uses_display=False)
```

注册后即可用 `./renpy.sh <basedir> my_command` 调用。`uses_display=False` 表示这个命令**不需要图形界面**——在无头服务器/CI 里跑的命令应当设成 `False`。

> **注意**：早期资料里常提到的 `renpy.sh <proj> has_label <label>` 子命令，**在当前 CLI 文档中并不存在**。要在脚本里判断标签存在与否，用第 21 章反复出现的运行期函数 `renpy.has_label("...")`，而不是命令行子命令。

---

## 23.6 自动化测试：让游戏自己走一遍

lint 只能做静态检查，抓不到“点下这个按钮到底会不会崩”。**自动化测试**就是用来补这一块的：你写一段“剧本”，让引擎模拟点击、按键、推进对话，最后用断言检查状态。它对应官方 [Automated Testing](https://www.renpy.org/doc/html/testcases.html) 一页。

两个核心语句：**`testcase`**（一条测试）与 **`testsuite`**（一组测试）。测试是**跑在真实游戏里**的——它们能看见界面、能读 `store` 变量，因此能验证真实行为。

### 23.6.1 官方快速上手：完整可运行示例

官方给了一个最小但完整的例子。它由两部分组成：**被测的游戏代码**与**测试代码**。

先是**被测代码**（放进你的游戏脚本，比如 `script.rpy`）：

```renpy
screen quickstart_popup():
    modal True

    frame:
        xalign 0.5
        yalign 0.5

        vbox:
            spacing 12
            text "Quick Start Popup"

            textbutton "Close":
                id "quickstart_close"
                action Hide("quickstart_popup")

label quickstart_demo:
    "Welcome to the testcase quick start demo."

    show screen quickstart_popup
    "Close the popup to continue."

    menu:
        "Take the map":
            "You picked the map."
        "Leave it":
            "You left the map behind."

    "End of demo."
    return
```

然后是**测试代码**（可放在同一文件，也可单独放 `testcases.rpy`）：

```renpy
testsuite quick_start:
    before testcase:
        run Jump("quickstart_demo")
        advance until screen "quickstart_popup"

    testcase choose_map:
        pause 0.5
        click id "quickstart_close" until not screen "quickstart_popup"
        pause 0.5
        advance until screen "choice"
        click "Take the map"
        advance until "You picked the map."
        pause 0.5

    testcase leave_map:
        pause 0.5
        click id "quickstart_close" until not screen "quickstart_popup"
        pause 0.5
        advance until screen "choice"
        click "Leave it"
        advance until "You left the map behind."
        pause 0.5
```

**逐行拆解这段测试**：

- `testsuite quick_start:` —— 定义一个测试组 `quick_start`。
- `before testcase:` —— 一个**钩子**，在组里**每个** testcase 之前执行。
  - `run Jump("quickstart_demo")` —— `run` 执行一个 Action。这里用 `Jump` 从已知的 label 出发，避免测试依赖“游戏恰好停在哪”。
  - `advance until screen "quickstart_popup"` —— 反复推进对话，直到名为 `quickstart_popup` 的屏幕出现。
- `testcase choose_map:` —— 第一条测试。
  - `pause 0.5` —— 等 0.5 秒（官方说明：示例里的 `pause` 只是为了让过程看得清，真实测试可去掉）。
  - `click id "quickstart_close" until not screen "quickstart_popup"` —— 反复点击 `id` 为 `quickstart_close` 的元素，直到该屏幕消失。
  - `advance until screen "choice"` —— 推进到出现选择菜单（`choice` 是引擎默认菜单屏幕名）。
  - `click "Take the map"` —— 按**按钮文字**点击“Take the map”。
  - `advance until "You picked the map."` —— 推进到屏幕上出现这段文字。
- `testcase leave_map:` —— 第二条测试，走另一个分支。

> 官方特别提醒：**`pause` 只是为了肉眼观察，真实测试应去掉以加速**。

### 23.6.2 运行测试

**方式一：从启动器运行。** 在启动器里选中工程，点 **"Run Testcases"** 按钮。若看不到该按钮：

1. 确保工程里**至少定义了一个 testcase**；
2. 先正常点 **"Launch Project"** 启动过一次游戏；
3. 回到启动器点 **"Refresh"**。

不指定测试名时，跑的是默认的 **`global` 测试组**。

**方式二：命令行。**

```bash
cd /path/to/renpy
./renpy.sh <basedir> test [<testcase>] [options...]
```

- `<basedir>`：工程路径。
- `<testcase>`：要跑的 testcase 或 testsuite 名；不给则跑 `global`。

**命令行选项**：

| 选项 | 作用 |
| --- | --- |
| `--enable_all` | 无视 `enabled` 属性，执行所有测试 |
| `--overwrite_screenshots` | 覆盖已存在的截图（配合 `screenshot` 语句） |
| `--hide-header` | 不显示测试开头的头部信息 |
| `--hide-execution {no\|hooks\|testcases\|all}` | 隐藏执行信息：`hooks` 隐藏钩子、`testcases` 连测试一起隐藏、`all` 全隐藏 |
| `--hide-summary` | 不显示结尾的汇总 |
| `--report-detailed` | 显示每条测试的详细信息 |
| `--report-skipped` | 显示被跳过的测试（需与 `--report-detailed` 同用） |

### 23.6.3 `testcase` 与 `testsuite` 语句

`testcase` 定义一个具名测试，内部是**测试语句**（不是 Ren’Py 语句，二者互斥）。它与 `label` 的三点不同：

- `label` 里是 Ren’Py 代码，`testcase` 里是测试语句；
- **没有** `return` 的对应物；
- 测试语句**只能出现在测试块内**（普通 Ren’Py 代码可以出现在 label 之外，测试语句不行）。

`testsuite` 用来**分组**：里面可以放 testcase、其他 testsuite、以及钩子。**默认测试组叫 `global`，由引擎自动创建**，若你没显式定义 `global`，它会包含所有顶层测试组与测试。

两者都支持这些**属性**：

| 属性 | 默认 | 含义 |
| --- | --- | --- |
| `description` | — | 字符串描述，显示在测试报告里 |
| `enabled` | `True` | 为 `False` 时**跳过**该测试 |
| `only` | `False` | 为 `True` 时**只跑**标了 `only True` 的测试 |
| `xfail` | `False` | 为 `True` 时表示“**预期会失败**”；真失败了记为 xfailed 而非 failed |
| `parameter` | — | 参数化测试的值（见 23.6.7） |

`enabled` 常用于平台判断：

```renpy
testcase windows:
    enabled renpy.windows
    # ... 只在 Windows 上跑

testcase not_on_mobile:
    enabled not renpy.mobile
    # ... 不在移动端跑
```

### 23.6.4 钩子与测试运行的生命周期

`testsuite` 里可以放六种钩子（出自官方 Hooks 一节）：

| 钩子 | 何时执行 |
| --- | --- |
| `setup` | 本组**开始时**执行一次，在所有测试之前 |
| `before testsuite` | 本组内的**每个子组**之前 |
| `before testcase` | 本组内的**每条测试**之前 |
| `after testcase` | 每条测试之后；**即使测试失败或抛异常也执行** |
| `after testsuite` | 每个子组之后；即使失败也执行 |
| `teardown` | 本组**全部结束**后执行一次；即使失败也执行 |

`before *` / `after *` 钩子可带 **`depth`** 属性：

- 对 **testcase** 型钩子，默认 `-1`，表示对**所有嵌套层级**的测试生效；
- 对 **testsuite** 型钩子，默认 `0`，表示只对**直接子组**生效。

想收窄 testcase 钩子的范围，把它设成 `0`：

```renpy
testsuite global:
    before testcase:
        depth 0
        $ print("Starting a testcase.")
```

官方给了一个完整例子，展示一个 `global` 组套 `basic` 与 `test_choices` 两个子组时的实际执行顺序：

```renpy
label test_demo:
    "This is a demo for testcases."
    "It has a few messages and a menu."
    menu:
        "First Choice":
            "Selected first choice."
        "Second Choice":
            "Selected second choice."
        "Third Choice":
            "Selected third choice."
    return

testsuite global:
    setup:
        $ print("global :: setup")
        skip until screen "main_menu"

    before testsuite:
        $ print("global :: before testsuite")
        if not screen "main_menu":
            run MainMenu(confirm=False)
        click "Start"

    before testcase:
        $ print("global :: before testcase")

    after testcase:
        $ print("global :: after testcase")

    after testsuite:
        $ print("global :: after testsuite")

    teardown:
        $ print("global :: teardown")
        exit

    testsuite basic:
        testcase first_testcase:
            $ print("basic :: first_testcase")
            advance

    testsuite test_choices:
        setup:
            $ print("test_choices :: setup")

        before testcase:
            $ print("test_choices :: before testcase")
            run Jump("test_demo")
            advance until screen "choice"

        after testcase:
            $ print("test_choices :: after testcase")
            # ...（略：这里补回主菜单，见官方原文）
```

> 上面最后一行注释处，官方原文继续写了 `run MainMenu(confirm=False)` 之类的“收尾”语句；本处省略处**不影响理解**生命周期——核心是下面这张顺序。

这段代码的执行顺序是（官方给的表）：

```
global :: setup
global :: before testsuite
global :: before testcase
basic :: first_testcase
global :: after testcase
global :: after testsuite
global :: before testsuite
test_choices :: setup
global :: before testcase
test_choices :: before testcase
test_choices :: choice1
test_choices :: after testcase
global :: after testcase
global :: before testcase
test_choices :: before testcase
test_choices :: choice3
test_choices :: after testcase
global :: after testcase
test_choices :: teardown
global :: after testsuite
global :: teardown
```

关键观察：**`global :: before testcase` 与 `global :: after testcase` 会在每一条测试前后都跑，即便那条测试在嵌套子组里**。这正是他们用默认 `depth -1` 的效果。

**两条重要提醒：**

1. **测试组跑完不会自动关游戏**——它会**把控制权还给玩家**，等玩家操作。想让测试跑完就退出，在 `teardown` 里用 `exit`：

```renpy
testsuite global:
    teardown:
        exit
```

2. **跳过测试的连锁反应**：某条 testcase 被跳过时，它的 `before/after testcase` 钩子**不执行**；若一个组里**所有**测试都被跳过，则 `setup`/`teardown` 也不执行，父组的 `before/after testsuite` 也不为它执行。

### 23.6.5 测试语句速查

测试语句分三类：**命令类**、**条件/选择器类**、**控制类**。

**基础命令**

| 语句 | 作用 |
| --- | --- |
| `advance` | 推进一行对话 |
| `exit` | 退出游戏，不弹确认框、不存档 |
| `pass` | 空操作，用来占位（让空 testcase 合法） |
| `pause [秒数]` | 暂停指定秒数；若后接 `until` 可省略秒数 |
| `run <action>` | 执行一个界面 Action（或 Action 列表） |
| `skip [fast]` | 开始跳过；`fast` 表示直接跳到下一个选择 |

示例：

```renpy
advance until screen "choice"
pause 5.0
pause until screen "inventory"
run Jump("chapter_3")
skip fast
skip until screen "choice"
```

**鼠标命令**

| 语句 | 形式 | 说明 |
| --- | --- | --- |
| `click` | `click [button (int)] [selector] [pos (x, y)]` | 模拟点击；`button` 默认 1（左键），2 右键、3 中键 |
| `drag` | `drag <[selector] [pos (x, y)]> to <[selector] [pos (x, y)]> [button] [steps]` | 模拟拖拽；`steps` 默认 10 |
| `move` | `move [selector] [pos (x, y)]` | 移动虚拟鼠标 |
| `scroll` | `scroll [amount (int)] [selector] [pos (x, y)]` | 滚轮；`amount` 默认 1，正数向下 |

```renpy
click "Start Game"
click id "start_button"
click pos (0.5, 0.5)
drag id "item_icon" to id "inventory_slot_3" button 1 steps 20
move id "back_btn" pos (0.5, 0.5)
scroll amount 10 id "inventory_scroll"
```

**键盘命令**

| 语句 | 说明 |
| --- | --- |
| `keysym <keysym> [selector] [pos]` | 模拟一次键事件（keysym 名如 `"skip"`、`"ctrl_K_a"`、`"K_BACKSPACE"`） |
| `type <string> [selector] [pos]` | 输入一段文本 |

```renpy
keysym "K_BACKSPACE" repeat 30
type "Hello, World!"
```

**条件与选择器**

| 语句 | 类型 | 说明 |
| --- | --- | --- |
| `eval <expression>` | 条件 | 求值一个 Python 表达式 |
| `label <labelname>` | 条件 | 判断该 label 自上次测试语句以来是否被到达过 |
| `screen <name>` | 条件+选择器 | 判断某屏幕是否显示 |
| `id <name>` | 选择器 | 按元素 `id` 定位 |
| `"<text>" [raw]` | 条件+选择器 | 按屏幕上的**文字**定位（不区分大小写，取最短匹配） |
| `expression <expr>` | 选择器 | 用表达式的结果作为要搜索的文本 |

条件支持 `not` / `and` / `or`，也支持字面量 `True` / `False`：

```renpy
assert eval (renpy.is_in_test() and screen "main_menu")
advance until "ask her right" or label "chapter_five"
click "Next" until not screen "choice"
```

**文字选择器**（`"<text>"`）值得单独说：它遍历屏幕上所有**可聚焦元素**（通常是按钮与主文本框），在它们的**文本与 alt 文本**里找匹配，**不区分大小写**且**取最短匹配**。官方例子：若屏幕上有 `CATALOG` 与 `illogical`，搜索 `"log"` 会命中 `CATALOG`。加 `raw` 表示在**翻译/插值之前**的原始文本上搜索：

```renpy
advance until "Hey, that's not fair!"
assert "Welcome, [player_name]!" raw
```

**控制语句**

| 语句 | 形式 | 说明 |
| --- | --- | --- |
| `assert` | `assert <condition> [timeout (float)] [xfail (bool)]` | 条件不满足就抛断言错误 |
| `if` | `if <condition>:` + `elif` / `else` | 条件执行一个测试块 |
| `repeat` | `<command> repeat <number> [timeout]` | 重复执行某条命令若干次 |
| `screenshot` | `screenshot <path> [max_pixel_difference] [crop (x,y,w,h)]` | 截图并与既有图比对 |
| `until` | `<command> until <condition> [timeout]` | 反复执行某命令直到条件满足 |

```renpy
assert screen "main_menu"
assert id "start_button" timeout 5.0
click "+" repeat 3
screen:
screenshot "screens/main_menu.png"
advance until screen "choice"
```

`label` 条件的语义要小心——它判断的是“**自上一次测试语句以来**该 label 是否被到达过”。所以：

```renpy
run Jump("chapter_1")
assert label chapter_1   # 通过
assert label chapter_1   # 失败（期间没有再次到达）
```

**Python 块与美元行**：testcase 里可以写 python 块和 `$` 单行语句来执行任意 Python。与普通 Ren’Py 代码不同，这里的 python 块**不接收 `in` 子存储参数**，但接受 `hide` 关键字。`init python` 中定义的函数/类可以在测试里调用：

```renpy
init python in test:
    def afunction():
        if renpy.is_in_test():
            return "test"
        return "not test"

testcase default:
    $ print(test.afunction())   # 输出到控制台
```

### 23.6.6 参数化测试：一份测试跑多组数据

`parameter` 让你**用一份测试跑多组值**。基本形式：

```renpy
testcase click_buttons:
    parameter button_name = ["Load", "Save"]
    click expression button_name
```

这会跑两次：先点 “Load”，再点 “Save”。注意 `click expression button_name`——用 `expression` 把参数值当作文本来选择按钮。

**成组参数**：

```renpy
testcase addition:
    parameter (x, y, z) = [ (1, 2, 3), (2, 3, 5), (3, 5, 8) ]
    assert eval (x + y == z)
```

会跑三组：`(1,2,3)`、`(2,3,5)`、`(3,5,8)`。

**多组参数自动笛卡尔积**：

```renpy
testcase combinations:
    parameter a = [1, 2]
    parameter b = [3, 4]
    parameter c = [5, 6]

    assert eval (a + b + c in [9, 10, 11, 12])
```

会跑 8 次（`a`×`b`×`c` 的全组合）。

参数还能用在任何“接受表达式”的测试属性里，比如让测试对某一组值**预期失败**：

```renpy
testcase choice_test:
    parameter x = [0, 1, 2]
    xfail x == 2

    assert eval (x < 2)
```

参数也可传给**整个测试组**，此时组内所有钩子与测试都会对每组参数跑一遍：

```renpy
testsuite math_tests:
    parameter (x, y, z) [ (1, 2, 3), (2, 3, 5), (3, 5, 8) ]

    setup:
        $ print(f"Running math tests with x={x}, y={y}, z={z}")

    testcase addition:
        assert eval (x + y == z)
```

> **警告（官方原文）**：参数是**按引用传递**的。若你修改了可变参数（如列表/字典），**所有共享该对象的测试都会受影响**。

### 23.6.7 测试设置：`_test.*`

有一组 `_test.*` 变量用来调整测试框架行为（可在 `init python` 里设）：

| 变量 | 默认值 | 作用 |
| --- | --- | --- |
| `_test.maximum_framerate` | `True` | 测试期间是否用最高帧率（尽量跑得比屏幕刷新率还快） |
| `_test.timeout` | `10.0` | 单条测试语句等待条件的**最长秒数**（可被语句级 `timeout` 覆盖） |
| `_test.force` | `False` | 即使 `config.suppress_underlay` 为真也强制执行测试 |
| `_test.transition_timeout` | `5.0` | 等一个转场完成的最长秒数，超时则跳过转场继续 |
| `_test.focus_trials` | `100` | 用选择器但不给位置时，尝试寻找可聚焦点的次数 |
| `_test.screenshot_directory` | `"tests/screenshots"` | 截图存放目录 |
| `_test.vc_revision` | — | 当前源码树的版本控制（通常是 git）修订号；默认取环境变量 `RENPY_TEST_VC_REVISION`，未设则为空串 |

例如想让测试在条件不满足时多等一会儿：

```renpy
init python:
    _test.timeout = 20.0
```

### 23.6.8 结果与报告

每条测试的结果可能是：

| 结果 | 含义 |
| --- | --- |
| **Passed** | 成功执行，无错误 |
| **Failed** | 执行了，但有语句失败 |
| **XFailed** | 预期失败（`xfail` 为真），果然失败 |
| **XPassed** | 预期失败，却**通过**了 |
| **Skipped** | 被跳过（`enabled` 为假，或存在 `only True` 的其他测试） |

**一般把 Passed 与 XFailed 视为“成功”，Failed 与 XPassed 视为“不成功”。** 注意 `XPassed` 也算不成功——因为你标了“预期失败”，它却通过了，说明你的预期过时了，应当更新。

测试跑完后会打印报告；加 `--report-detailed` 可得到每条测试的详细信息。

### 23.6.9 失败时的行为

若某条 **testcase** 里出错：

1. 该 testcase **立即停止**；
2. 所在组的 `after testcase` 钩子执行；
3. 若还有后续 testcase，继续执行（含 `before testcase` 钩子）；
4. 若没有更多 testcase，执行该组的 `after` 钩子。

若**钩子里**出错（如 `before testcase`）：

1. 该测试组**立即停止**；
2. 若它由父组调用，父组继续执行；
3. 若无父组，**测试运行结束**。

### 23.6.10 在 CI 里跑测试

把 23.4 与 23.6 串起来，就是一个最小的持续集成检查：

```bash
# 1) 静态检查：有错就以退出码 1 结束
./renpy.sh "$PROJECT" lint --error-code

# 2) 自动化测试：跑 global 组，隐藏执行噪声
./renpy.sh "$PROJECT" test --hide-execution all
```

注意测试需要图形环境（会真的开窗口）；在无头服务器上跑要用虚拟显示（如 Linux 下 `xvfb-run`）。`renpy.is_in_test()` 可以用来在“测试模式”下改变行为——比如跳过一些真实玩家才需要的等待。

---

## 23.7 `add_from`：给 `call` 补上 `from` 子句

这是发布前**必做**的一件事，而且它属于「测试与收尾」的范畴，所以放在第 23 章讲。

### 23.7.1 `from` 子句是什么

先把官方对 `call` 语句的原文摆出来（*Label & Control Flow → Call Statement*）：

> The `call` statement is used to transfer control to the given label. It also pushes the next statement onto the call stack, allowing the `return` statement to return control to the statement following the call.
>
> If the optional **`from` clause** is present, it has the effect of including a label statement with the given name as the statement immediately following the call statement. An explicit label helps to ensure that saved games with return stacks can return to the proper place **when loaded on a changed script**.

翻译并展开：

- `call` 会做两件事：把控制权交给目标 label；同时把「下一条语句」压入**调用栈（call stack）**。
- 目标 label 里的 `return` 会弹出调用栈顶，回到 `call` 的下一句。
- 存档时，调用栈**一起被存下来**。
- 如果你的游戏发布后又改了脚本（改了行号、增删了内容），玩家用旧存档读档时，调用栈里记录的那个「位置」可能已经对不上了，`return` 就会回到错误的地方。
- `from` 子句的作用，就是在 `call` 后面**插入一条有名字的 label**，把这个「返回点」变成一个**有稳定名字的锚点**。这个锚点名字由 Ren'Py 生成、在改脚本后依然不变，于是 return 总能找到正确的位置。

具体到代码，`from` 长这样：

```renpy
label start:
    e "我先调用一个子程序。"
    call subroutine from _call_subroutine_1
    e "子程序回来了。"
    return

label subroutine:
    e "这是子程序内部。"
    return
```

`from _call_subroutine_1` 就是那条插入的锚点 label。你不必自己去编这个名字——Ren'Py 有专门的工具来批量生成。

> 官方在文档里对此有一句警告（*Call Statement* 的 Warning）：
>
> > Publishing a game without `from` clauses for each `call` statement is dangerous, if you intend to publish updates of the game later on. If no such clauses are added, and if you edit the file containing the `call` instruction, there is a potential risk for saves made inside the called label to become broken.
>
> 也就是：**如果你打算后续更新游戏，却让 `call` 没有 `from`，那么只要改动相关脚本，玩家在子程序里存的档就可能损坏。** 官方给出的解决办法就叫 "Add from clauses to calls"，也就是下面这个命令。

### 23.7.2 命令用法

官方 CLI 文档（*Add From To Calls*）：

> Adds a `from` clause to each `call` statement that does not have one. Generally, this should be done **before a release**, to help Ren'Py locate the return point of calls in a modified game.
> **Implies `--compile`.**

命令（Linux / macOS）：

```bash
./renpy.sh <basedir> add_from
```

Windows：

```bat
.\lib\py3-windows-x86_64\python.exe renpy.py <basedir> add_from
```

要点：

1. **它会直接改写你的脚本文件**（官方原文的 Warning：*This will modify your game's script files.*）。所有原本没有 `from` 的 `call` 会被就地加上 `from _call_..._N`。
2. **执行前务必确保工程已在版本控制（git）下**，这样才能看清它到底改了哪些行，也便于回退。
3. **隐含 `--compile`**：执行完会顺带把 `.rpy` 重新编译成 `.rpyc`。
4. 只要给一个 `<basedir>`，不需要额外参数；没有「只处理某个文件」的选项，它是全工程扫描。

在本仓库示例 16_full_project 上跑一次的样子（示意）：

```bash
cd /path/to/renpy-sdk
./renpy.sh /Volumes/mac004/code/programming/renpy/examples/16_full_project add_from
git -C /Volumes/mac004/code/programming/renpy diff   # 查看被改动的 call
```

改完后，凡是原本写作 `call helper` 的地方都会变成 `call helper from _call_helper_1`（名字由引擎生成）。

### 23.7.3 在启动器里做同样的事

在 Ren'Py 启动器里，选择项目后，**Build** 页上有一项 **"Add from clauses to calls"**；勾选后在构建发布包时会一并执行。命令行与启动器二选一即可，效果相同。

> 到这里，你已经有了完整的「发布前清单」的前两项：**`add_from`**（本节）与 **Lint**（23.4）。第三项——保留 `.rpyc`、维护 `old-game/`——留到第 24 章「构建与发布」里连同打包一起讲，因为它和 `.rpyc` 的生成过程直接相关。

---

## 23.8 本章小结与实践

### 23.8.1 小结

| 主题 | 关键结论 | 触发方式 |
| --- | --- | --- |
| **开发者模式** | `config.developer` 可取 `True`/`False`/`"auto"`，`"auto"` 表示「发布版关、开发时开」 | `options.rpy` |
| **开发者快捷键** | `Shift+O` 控制台、`Shift+E` 外部编辑器、`Shift+D` 开发者菜单、`Shift+R` 保存并重载脚本、`Shift+I` 检查器 | 仅开发模式生效 |
| **控制台** | 可执行任意 Python；内置 `jump`/`load`/`save`/`watch`/`unwatch`/`reload`/`stack` 等命令 | `Shift+O` |
| **Lint** | 静态检查：找不到的 label/图像、未闭合标签、拼写等；CI 用 `--error-code` | `./renpy.sh <proj> lint` |
| **命令行工具** | 统一的 `[全局选项] <basedir> <命令> [命令选项]` 结构；可用 `renpy.arguments.register_command()` 自建 | `./renpy.sh` |
| **`add_from`** | 给所有无 `from` 的 `call` 补锚点，保证改脚本后旧存档能 `return` 回正确位置；**发布前必做** | `./renpy.sh <proj> add_from` |
| **自动化测试** | `testcase`/`testsuite` + 六种钩子 + 测试语句；`_test.*` 调参 | `./renpy.sh <proj> test` |
| **测试结果** | Passed / Failed / XFailed / XPassed / Skipped；Passed 与 XFailed 算成功 | 测试报告 |
| **CI 组合** | `lint --error-code` 与 `test --hide-execution all` 串联 | 见 23.6.10 |

### 23.8.2 实践题

1. **给示例加一条测试。** 打开 `examples/13_special_screens`，为它写一个 `testsuite`：进入游戏、点击一次推进、断言某句台词出现、退出。分别用 `./renpy.sh <proj> test` 与启动器的 **Run Testcases** 跑通。
2. **制造一次 `add_from` 前后对比。** 新建一个工程，写两个 `call`（都**不写** `from`），用 `git init` 提交；再运行 `add_from`，用 `git diff` 观察引擎插入的 `from _call_...` 名字；然后故意在子程序中间插入几行对话，用旧存档读档，观察有 `from` 时能正确返回。
3. **写一条参数化测试。** 让同一段测试用 `("开始","继续","设置")` 三个不同按钮文本各跑一遍，体会 23.6.6 里「成组参数」与「按引用传递」的语义。
4. **建一条本地 CI 脚本。** 写一个 `check.sh`：依次执行 `compile`、`lint --error-code`、`test --hide-execution all`；哪一步失败就立刻 `exit 1`。这会是附录 A 里构建流程的一个环节。

---

> [← 第 22 章 项目组织与配置：从目录到 settings](ch22-project-and-config.md) ｜ [目录](index.md) ｜ [第 24 章 构建与发布 →](ch24-build-and-distribution.md)
