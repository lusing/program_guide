# 第 24 章 构建与发布

前两章解决的是「写对」和「测对」。这一章解决最后一公里：**把你的工程打包成玩家能双击运行的成品，并且为将来的更新留好后路。**

## 24.1 构建系统做了什么

官方文档（*Building Distributions*）开头这样描述：

> Ren'Py includes support for building game distributions. Upon choosing "Build Distributions" in the launcher, Ren'Py will scan itself and the project to determine the files to include in the distribution, will create any archives that are necessary, and will build package and update files.

也就是三步：

1. **扫描**：分别扫 Ren'Py 引擎自身与**你的工程**，决定哪些文件进哪个包；
2. **归档**：按需把文件塞进 `.rpa` 归档（见 24.6）；
3. **产出包与更新文件**：生成 zip/tar.bz2/dmg/目录等，以及供联网更新器使用的差量更新文件。

而且——**什么都不配置也能打包**。官方紧接着列出了默认能产出的包：

> **PC: Windows and Linux** — A zip file targeting Windows x86_64 and Linux x86_64
>
> **Linux** — A tar.bz2 file targeting Linux x86_64. This will also include the 32-bit and 64-bit ARM version of Ren'Py, if present. (These are found in the `sdkarm` Ren'Py package.)
>
> **Macintosh** — A zip file containing a Macintosh application targeting macOS on Intel and Apple Silicon processors. Game data will be included inside the application, which appears to the user as a single file. **The updater does not work with this package.**
>
> **Windows** — A zip file targeting Windows x86_64.
>
> **Windows, Mac, and Linux for Markets** — A distribution that contains the information required to run on software markets like itch.io and Steam. This isn't meant to be run directly (and probably won't work on the Mac), but should be fed to the app store upload process.

两个要点值得单独强调：

- **Mac 包把游戏数据塞进 `.app` 内部**，对用户呈现为「一个文件」；代价是**联网更新器对它无效**。
- **Markets 包不是给你自己运行的**，它是喂给 itch.io/Steam 这类平台的上传流程用的。

还有一个容易被忽视的坑（官方 Warning）：

> The zip and tar.bz2 files that Ren'Py produces contain permissions information that must be present for Ren'Py to run on Linux and Macintosh. **Unpacking and re-packing a zip file on Windows and then running it on Linux or Macintosh is not supported.**

所以：**不要在 Windows 上解包再重新打包 Linux/Mac 的发行包**，权限位会丢。

### 24.1.1 从启动器打包

启动器选中项目后，**Build Distributions** 一栏里勾选要生成的包类型，点 **Build** 即可。产出目录默认在工程**上一级**，名字形如 `<directory_name>-dists`。

### 24.1.2 从命令行打包

CLI 文档（*Distribute*）：

> Builds distributions of the game for Windows, macOS, and Linux.

```bash
# Linux / macOS
./renpy.sh launcher distribute <basedir> [options...]
```

```bat
:: Windows
.\lib\py3-windows-x86_64\python.exe renpy.py launcher distribute <basedir> [options...]
```

注意这里必须是 `renpy.sh launcher distribute`——**先启动 `launcher`，再给它一个 `distribute` 命令**，因为打包逻辑住在启动器里。选项：

| 选项 | 作用 |
| --- | --- |
| `--destination <directory>` | 指定输出目录；默认是当前目录下名为 `name-version-dists` 的目录，名字取自 `build.name` 与 `build.version` |
| `--format <format>` | 强制使用该格式 |
| `--macapp <app>` | 指定用于**签名** mac 包的 macapp 路径，代替 Ren'Py 自带的那个 |
| `--no-archive` | 不把文件加入归档（`.rpa`） |
| `--no-update` | 不构建更新文件（即关闭「HTTPS/HTTP Updater」所需文件） |
| `--package <package>` | 指定要构建的包名（如 `pc`、`mac`、`markets`）；可重复给出以构建多个；默认构建全部 |
| `--packagedest <package>` | 指定某个包的输出名（不带扩展名）；**要求恰好指定一个 `--package`** |

例：只打 Windows 包，输出目录改到桌面的 `build` 文件夹：

```bash
./renpy.sh launcher distribute /path/to/mygame \
  --package windows --destination ~/Desktop/build
```

## 24.2 基础配置：三个核心变量

官方原文明确了一件事：

> The build process can be configured by setting variables and calling function that live in the `build` namespace. **This must be done from inside an `init python` block.** The default settings for these configurations are set in `options.rpy`.

**所有 `build.*` 设置都必须写在 `init python`（或 `python early` 之外的初始化 Python）块里**；Ren'Py 默认把这些设置放在 `game/options.rpy` 中。绝大多数工程只需要碰下面三个变量。

### 24.2.1 `build.name`

> This is used to automatically generate `build.directory_name` and `build.executable_name`, if neither is set. **This should not contain spaces, colons, or semicolons.**

`build.name` 是总源头：只设它，另两个名字会自动派生。**不能含空格、冒号、分号。**

```renpy
init python:
    build.name = "mygame"
```

### 24.2.2 `build.directory_name`

> This is used to create the names of directories in the archive files. For example, if this is set to `"mygame-1.0"`, the Linux version of the project will unpack to `"mygame-1.0-linux"`.
>
> This is also used to determine the name of the directory in which the package files are placed. For example, if you set `build.directory_name` to `mygame-1.0`, the archive files will be placed in `mygame-1.0-dists` in the directory above the base directory.
>
> This variable should not contain special characters like spaces, colons, and semicolons. **If not set, it defaults to `build.name`, a dash, and the version.** The version is taken from `build.version`, if set, or `config.version`.

一句话：**它决定「解压出来的文件夹叫什么」和「产物放在哪个 dists 目录」**。规则是 `<build.name>-<version>`（未显式设置时）。

### 24.2.3 `build.executable_name`

> This variable controls the name of the executables that the user clicks on to start the game.
>
> This variable should not contain special characters like spaces, colons, and semicolons. **If not set, it defaults to `build.name`.** For example, if this is set to `"mygame"`, the user will be able to run `mygame.exe` on Windows, `mygame.app` on Macintosh, and `mygame.sh` on Linux.

这就是玩家双击的那个文件名。三者合起来的典型写法（放在 `game/options.rpy` 里）：

```renpy
init python:
    # 总名：会自动派生出目录名与可执行文件名
    build.name = "mygame"

    # 显式覆盖：目录名（也会决定 dists 目录名）
    build.directory_name = "mygame-1.0"

    # 显式覆盖：可执行文件名
    build.executable_name = "mygame"
```

> 三者都不要含空格/冒号/分号——它们会直接变成文件与目录名，含特殊字符会在跨平台时出问题。尤其注意 `build.name`：它还会被用到 itch.io 上传等地方。

## 24.3 特殊文件：图标

> **`icon.ico`** — The icon that is used on Windows.
>
> **`icon.icns`** — The icon that is used on Macintosh.
>
> These icon files must be in specific formats. You'll need to use a program or web service to convert them.

把 `icon.ico` 与 `icon.icns` 放在**工程的 base 目录**（即 `game/` 的同级，不是 `game/` 里面），Windows 与 Mac 的成品就会用上你的图标。格式必须对：`.ico` 用于 Windows，`.icns` 用于 Mac。可以先用 PNG 设计，再用在线转换服务（官方提到 anyconv 的 png-to-ico / png-to-icns 转换器）转成这两种格式。

> Linux 不使用这两个文件（Linux 桌面环境一般从 `.desktop` 文件取图标）。

## 24.4 文件分类：`build.classify` 与七个文件列表

这是构建系统的心脏，也是最容易配错的地方。

### 24.4.1 原理

> The build process works by first **classifying files** in the Ren'Py distribution and your game **into file lists**. These file lists are then added to package files.

即：先把每个文件**归类**到若干「文件列表（file list）」里，各个包再由这些列表组合而成。

分类靠 `build.classify(pattern, file_list)`：

> Classifies files that match pattern into file_list, which can also be an archive name.
> If the name given as file_list doesn't exist as an archive or file list name, **it is created** and added to the set of valid file lists.

注意最后一句：**列表名不是固定枚举，你在 `classify` 里写个新名字，它就自动成为一个新列表**（可以被 `build.package` 引用）。

### 24.4.2 通配符

> * The directory separator `/`.
> * `*` Matches all characters **except** for the directory separator.
> * `**` Matches all characters (including `/`).

例子：

> `**.txt` — Matches all txt files.
> `game/*.txt` — Matches txt files in the game directory.

再补两条关键规则：

> Patterns are matched **from first to last, with the first match taking precedence** (even if a more-specific pattern follows.) Patterns are matched **with and without a leading `/`**.

也就是说：

1. **先写的规则优先**，不是「更具体的优先」。所以排除规则要写在包含规则**之前**（或之后，取决于你的意图——总之顺序决定结果）。
2. 匹配时**带不带前导 `/` 都会试**，所以 `game/*.txt` 与 `/game/*.txt` 等效。

### 24.4.3 七个默认文件列表

> There are **seven file lists** that files can be classified into by default. (Ren'Py places its own files into the first six of these.)

| 列表名 | 含义 |
| --- | --- |
| `all` | 所有包都包含，Android 构建也包含 |
| `linux` | 面向 Linux 的包 |
| `mac` | 面向 Macintosh 的包 |
| `windows` | 面向 Windows 的包 |
| `renpy` | 需要 Ren'Py 引擎文件的包（Linux、Mac、Windows）——**即引擎自身的文件** |
| `android` | Android 构建 |
| `archive` | 进入 `archive.rpa` 归档的文件（见 24.6） |

> Files that are not otherwise classified are placed in the `"all"` file list.

**没被任何规则命中的文件，默认进 `all`。** 这一点很重要：这意味着**你不写任何 `classify`，工程里的所有文件也都会被包含进去**。

### 24.4.4 排除文件

> To exclude files from distribution, classify them as `None` or the empty string. In this case, **`*` and `**` at the end of the pattern must match at least one character.**

官方给的完整例子：

```renpy
# Include README.txt
build.classify("README.txt", "all")

# But exclude all other txt files.
build.classify("**.txt", None)

# Add png and jpg files in the game directory into an archive.
build.classify("game/**.png", "archive")
build.classify("game/**.jpg", "archive")
```

逐条读：

1. 先把 `README.txt` 归入 `all`（会被所有包包含）。
2. 再把**其余所有 `.txt`** 排除掉（`None`）。因为 `README.txt` 已经在第 1 条里被归类过、而规则是「先匹配先赢」，所以它不会被第 2 条排除。**这正是「顺序即优先级」的实战意义。**
3. 把 `game/` 下所有 png、jpg 归入 `archive` 列表——于是它们会被打进 `archive.rpa`。

最后一个细节：`None` 排除时，模式末尾的 `*` / `**` **必须至少匹配一个字符**。也就是说 `game/*` 不会把 `game` 目录本身排除掉，只会排除它下面的条目。这是为了避免你误把整个目录「连根拔掉」。

`build.clear()` 用来清空现有的全部分类规则：

> Clears the list of patterns used to classify files.

一般只在你要**完全接管**分类、不想要 Ren'Py 默认规则时使用。

## 24.5 文档与可执行标记

两个特殊函数：

**`build.documentation(pattern)`**

> Declares a pattern that matches documentation. In a mac app build, files matching the documentation pattern are stored **twice** - once inside the app package, and again outside of it.

Mac 应用会把文档**同时**放在 `.app` 内部和外部（方便用户不进入 app 就能看到 README、许可协议等）。例：

```renpy
init python:
    build.documentation("*.txt")
    build.documentation("*.html")
```

**`build.executable(pattern)`**

> Adds a pattern marking files as executable on platforms that support it. (Linux and Macintosh)

给匹配的文件打上「可执行」位（Linux/Mac 用）。例如你打包了一个辅助脚本 `game/tools/run_helper.sh`：

```renpy
init python:
    build.executable("game/tools/*.sh")
```

## 24.6 归档：`build.archive`

### 24.6.1 归档是什么

> Ren'Py supports combining files into a simple archive format. While **not very secure**, this protects files from casual copying.

归档格式是 `.rpa`——它**不是加密**，只是把文件合并、顺手挡住「随手复制」。默认情况下：

> By default, all files classified into the `"archive"` file list will be placed in an `archive.rpa` archive, which is included in the `all` file list.

也就是：**你在 24.4.4 里 `classify(..., "archive")` 的那些 png/jpg，会自动进 `archive.rpa`。**

### 24.6.2 自定义归档

`build.archive(name, file_list='all')`：

> Declares the existence of an archive, whose name is added to the list of available archive names, which can be passed to `build.classify()`.
> If one or more files are classified with `name`, `name.rpa` is built as an archive, and then distributed in packages including the `file_list` given here.

例：

```renpy
init python:
    build.archive("secret", "windows")
```

> If any file is included in the `"secret"` archive using the `build.classify()` function, the file will be included inside the `secret.rpa` archive in the windows builds.
>
> As with the `build.classify()` function, if the name given as file_list doesn't exist as a file list name, it is created and added to the set of valid file lists.

官方给的「双归档」例子（脚本一个、图片一个）：

```renpy
# Declare two archives.
build.archive("scripts", "all")
build.archive("images", "all")

# Put script files into the scripts archive.
build.classify("game/**.rpy", "scripts")
build.classify("game/**.rpyc", "scripts")

# Put images into the images archive.
build.classify("game/**.jpg", "images")
build.classify("game/**.png", "images")
```

两条补充：

> If an archive file is empty, it will not be built.

空的归档不会生成——这很方便，你不用为「这个包可能没有图片」写特判。

> Please **think twice about archiving your game**. Keeping files open will help others run your game on future platforms – platforms that may not exist until after you're gone.

这句是官方的**劝阻**：归档会让未来平台（甚至还没出现的平台）更难运行你的游戏，因为文件被合进了一个不透明的容器。所以——**除非有明确理由（比如减少文件数、避免随手复制），否则不要归档。** 官方自己也说 `.rpa` 并不安全（人家要提取还是能提取）。

## 24.7 自定义包：`build.package`

`build.package` 允许你**新造一种包**：

**签名**

```python
build.package(name, format, file_lists, description=None,
              update=True, dlc=False, hidden=False, update_only=False)
```

| 参数 | 含义 |
| --- | --- |
| `name` | 包名 |
| `format` | 格式字符串（空格分隔多个），取值见下表 |
| `file_lists` | 要包含进来的文件列表（空格分隔的字符串） |
| `description` | 可选，包的描述 |
| `update` | 若为真且正在构建更新，则为本包构建更新文件 |
| `dlc` | 若为真，zip/tar.bz2 会以**独立 DLC 模式**构建，不含 update 目录 |
| `hidden` | 若为真，在启动器的包列表里隐藏它 |
| `update_only` | 只构建更新 |

**`format` 的取值**（官方原文）：

| 格式 | 说明 |
| --- | --- |
| `zip` | 一个 zip 文件 |
| `tar.bz2` | 一个 tar.bz2 文件 |
| `directory` | 一个装着这些文件的目录 |
| `dmg` | 一个包含这些文件的 Macintosh DMG |
| `app-zip` | 含 mac 应用的 zip。**不支持更新器** |
| `app-directory` | 含 mac 应用的目录。**不支持更新器** |
| `app-dmg` | 含 mac 应用的 DMG（仅 Mac）。**不支持更新器** |
| `bare-zip` | 不前置 `build.directory_name` 的 zip |
| `bare-tar.bz2` | 不前置 `build.directory_name` 的 tar.bz2 |
| `null` | 只产出更新，不产出主包 |
| 空字符串 `""` | 不产出任何格式的主包（这让纯 `dlc` 成为可能） |

其中 `zip`/`tar.bz2`/`directory` 是最常用的三种；`app-*` 系列是 mac 专用，且都**不支持更新器**；`bare-*` 就是「解压出来不套一层目录」；`null` 与 `""` 是给「只要更新文件」和「纯 DLC」这类特殊场景用的。

官方完整示例——一个普通版，加一个含额外素材的「premium」版：

```renpy
# Declare a new archive belonging to a new "bonus" file list.
build.archive("bonus_archive", "bonus")

# Put the bonus files into the new archive.
build.classify("game/bonus/**", "bonus_archive")

# Declare the package.
build.package("all-premium", "zip", "windows mac linux renpy all bonus")
```

读一遍就明白三件事：

1. `build.archive("bonus_archive", "bonus")` 声明了一个归档，同时**顺带创建了名为 `bonus` 的文件列表**；
2. `build.classify("game/bonus/**", "bonus_archive")` 把 `game/bonus/` 下的内容归入该归档；
3. `build.package("all-premium", "zip", "windows mac linux renpy all bonus")` 造出一个 zip 包，把六个文件列表都装进去。

`file_lists` 这里用空格分隔——**顺序无所谓，内容才重要**。注意 `renpy` 这个列表代表引擎文件；面向桌面平台的包基本都要带上它，否则玩家拿到的是一个没有引擎的「空壳」。

## 24.8 构建信息：`build.time` 与 `build.info`

这两个变量把信息写进 `game/cache/build_info.json`，游戏启动时会加载它。

**`build.time = None`**

> This variable defaults to `None`, but if your game has been built, it will be set to **the time the game was built**, in seconds since January 1, 1970.

构建时会自动填上「构建时间」（Unix 时间戳）。开发环境（未构建）下是 `None`。

**`build.info = { }`**

> This variable lets you store information that will be placed into the `game/cache/build_info.json` file in the built game. When the built game starts, `game/cache/build_info.json` is loaded and the contents placed into this variable.
>
> Generally, you'll want to check that a field does not exist, and set it, using `setdefault`.

官方例子：

```renpy
python hide:
    import socket
    build.info.setdefault("build_host", socket.gethostname())
```

> The information in this variable needs to be of types that can be placed in JSON files. (That is, `None`, booleans, strings, numbers, lists, and dictionaries)

用途举例：把「构建主机名」「CI 编号」「git 短哈希」写进 `build.info`，然后在游戏里读 `build.info` 显示在「关于」界面，出问题时能一眼看出玩家装的是哪一次构建。**注意 `build.info` 的值必须能 JSON 序列化**（None/布尔/字符串/数字/列表/字典）。

## 24.9 高级配置变量全表

以下是官方 *Advanced Configuration* 里列出的全部变量及默认值。

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `build.allow_integrated_gpu` | `True` | 允许在同时有集显与独显的平台上使用集显；目前仅 Mac OS X 支持 |
| `build.destination` | `"{directory_name}-dists"` | 产物输出目录；可用 `{directory_name}`/`{executable_name}`/`{version}` 占位（Python `str.format`）。相对路径视为相对 **projects 目录** |
| `build.change_icon_i686` | `True` | 若为真且存在 `icon.ico`，会改 32 位 Windows 可执行文件的图标。设为 `False` 可避免某些杀毒软件误报 |
| `build.exclude_empty_directories` | `True` | 从生成的包中移除空目录（含因归档而变空的目录） |
| `build.game_only_update` | `False` | 若为真且 `build.include_update` 已启用，会出现「Game-Only Update for Mobile」包 |
| `build.include_i686` | `True` | 是否把 32 位 x86 运行所需文件放进 Linux 与 Mac 包 |
| `build.include_old_themes` | `True` | 是否包含 Ren'Py 6.99.9 之前的旧主题所需文件。**`gui.init()` 被调用时会被设为 `False`** |
| `build.include_update` | `False` | 若为真，Ren'Py 会产出联网更新器所需的文件 |
| `build.itch_project` | `None` | 设为 itch.io 上的项目名（如 `"renpytom/the-question"`）后，启动器就能把构建好的包上传到 itch.io |
| `build.itch_channels` | 见下 | 把文件名模式（如 `*-win.zip`）映射到 itch channel |
| `build.mac_info_plist` | `{}` | 字符串到字符串的字典，用于新增/覆盖 mac 的 `Info.plist` 键 |
| `build.update_formats` | `["rpu"]` | 更新器构建的格式。默认 `"rpu"`（Ren'Py 7.7 / 8.2 起支持）。若要支持更早的 zsync 更新，把 `"zsync"` 加进列表 |
| `build.version` | `None` | 构建所用的版本；为 `None` 时取 `config.version`。主要用途是让 `config.version` 能包含「在文件名里非法」的字符 |

其中 `build.itch_channels` 的默认值：

```python
build.itch_channels = {
    "*-all.zip"       : "win-osx-linux",
    "*-market.zip"    : "win-osx-linux",
    "*-pc.zip"        : "win-linux",
    "*-win.zip"       : "win",
    "*-mac.zip"       : "osx",
    "*-linux.tar.bz2" : "linux",
    "*-release.apk"   : "android",
}
```

`build.include_old_themes` 那条有个实用含义：**只要你调用了 `gui.init()`（现代 GUI 模板都会调），它就自动是 `False`**，旧主题文件不会被打包——这正是你想要的（省体积）。只有在你确实要兼容 6.99 之前的老主题时才手动置回 `True`。

一个「把构建元信息写进包」的组合示例：

```renpy
init python:
    build.name = "mygame"
    build.version = "1.0"
    build.include_update = True          # 产出更新器所需文件
    build.mac_info_plist = {"NSHumanReadableCopyright": "© 2026 Me"}

python hide:
    import subprocess
    try:
        sha = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"]).decode().strip()
    except Exception:
        sha = "unknown"
    build.info.setdefault("git_sha", sha)
```

## 24.10 `old-game` 目录：让更新不坏档

这一节承接 23.7——`from` 子句管的是**调用栈**的兼容，`old-game` 管的是**每一句台词/场景的唯一 ID** 的兼容。两者合起来才是完整的「更新不坏档」。

### 24.10.1 问题出在 `.rpyc`

官方原文：

> Ren'Py uses compiled script files (called `.rpyc` files) to run your game quickly. These files also store important details, like **unique IDs for each line of dialogue or scene, that save files rely on**. When a game is updated and `.rpy` scripts change, Ren'Py updates or creates accompanying `.rpyc` files when the game is launched.
>
> This updating nature of `.rpyc` files can create a challenge for developers who are making multiple releases... it's easy to make a series of changes to an `.rpy` file that causes the resulting `.rpyc` file to have **different IDs** than the ones used in your current stable release.

要点：

1. `.rpyc` 里存着**每句台词、每个场景的唯一 ID**；
2. **存档依赖这些 ID**（存档里记的是「我停在第几号台词」，而不是「第几行」）；
3. 你改了 `.rpy`，重新生成的 `.rpyc` 里 ID 就可能变了；
4. ID 一变，玩家用旧存档读档时，就找不到「那句话」了。

如果每次都把 `.rpyc` 保留下来（不改动这些行的地方 ID 也不变），就不会出问题——但多人协作、早期访问式频繁发版时，很难保证。

### 24.10.2 解法：`old-game` 目录

> To keep these changes from breaking save game compatibility, developers can use the **`old-game` directory**. This special folder, which sits **next to the `game` directory** in your project folder, lets you save a copy of the `.rpyc` files from your previous release.
>
> Its structure should match the `game` directory. For example, move `game/scripts/day1.rpyc` to `old-game/scripts/day1.rpyc`. Files in `old-game` that aren't `.rpyc` files are ignored.
>
> When you have an `old-game` directory with `.rpyc` files from your last release, Ren'Py uses them to help create new `.rpyc` files for changed `.rpy` scripts. **It keeps the same IDs for parts of your script that haven't changed**, so older save files can still load properly.

目录长得是这样：

```
mygame/
├── game/
│   └── scripts/day1.rpy
│   └── scripts/day1.rpyc
└── old-game/                 ← 与 game 同级
    └── scripts/day1.rpyc     ← 上一次发布时那份 .rpyc 的副本
```

注意三点：

1. `old-game` 与 `game` **同级**；
2. 内部结构与 `game` **完全对应**（`game/scripts/day1.rpyc` → `old-game/scripts/day1.rpyc`）；
3. **非 `.rpyc` 文件会被忽略**，所以不用担心多放了别的东西。

### 24.10.3 最佳实践三步（官方 How to make the most of the `old-game` directory）

> 1. **When launching the game**, if an `.rpy` file has changed and there's a matching `.rpyc` file in `old-game`, Ren'Py uses that `.rpyc` file to update the one in `game`. This keeps its IDs consistent with your last release for maximum save compatibility.
> 2. **Before building a new release**, enable "Force Recompile" on the build-page of the Ren'Py SDK, and click "Update old-game" before pressing "Build". This recompiles all `.rpyc` files using the ones in `old-game` as a starting point, then updates `old-game` with these new, stable `.rpyc` files for your next release.
> 3. **If you've already released your game**, you can still benefit from `old-game` by copying the `.rpyc` files from your latest release's `game` directory into your project's `old-game` directory, matching the same folder structure.

翻译成操作清单：

1. **日常开发**：改了 `.rpy` 后启动游戏，Ren'Py 会自动拿 `old-game` 里的 `.rpyc` 作为参考来生成新的 `.rpyc`，从而保住没变部分的 ID。你什么都不用手动做。
2. **发布前**：在启动器 **Build** 页勾选 **Force Recompile**，点 **Update old-game**，再点 **Build**。这一步会用 `old-game` 起步重编**所有** `.rpyc`，并把新的、稳定的 `.rpyc` 写回 `old-game`，供下一次发布使用。
3. **已经发过游戏才想起来**：赶紧把**最新一版发布包**里 `game/` 下的 `.rpyc` 按相同结构复制进工程的 `old-game/`，从下一次发布起就受保护了。

> 与 23.7 的 `add_from` 配合起来看：`add_from` 保护**调用栈**的返回位置，`old-game` 保护**台词/场景**的 ID。**两者都是「发布前必做」，缺一个都可能在更新后弄坏玩家存档。**

## 24.11 目标平台的最低要求

有些商店会要求你填「运行环境要求」。官方给了一份通用视觉小说的最小值（*Requirements*）：

| 平台 | 版本 | CPU | 内存 | 图形 |
| --- | --- | --- | --- | --- |
| Windows | Windows 10 或更高 | 2.0 GHz 64 位 Intel 兼容 | 2.0 GB | OpenGL 3.0 或 DirectX 11 |
| macOS | 10.10+ | 2.0 GHz 64 位 Intel 兼容 或 M1+ | 2.0 GB | OpenGL 3.0 |
| Linux | Ubuntu 20.04+ | 2.0 GHz 64 位 Intel 兼容 | 2.0 GB | OpenGL 3.0 |

> The amount of disk space required is entirely determined by the assets in your game, and the amount of CPU and RAM needed may also vary. Ren'Py will also run under OpenGL 2 with certain extensions available.

补充：磁盘占用完全由你的素材决定；内存/CPU 也可能更高；在具备相应扩展的情况下 Ren'Py 也能跑在 OpenGL 2 上。

## 24.12 发布前清单

把第 23、24 章的内容收成一张可执行的清单：

| # | 动作 | 命令 / 位置 |
| --- | --- | --- |
| 1 | Lint 无错 | `./renpy.sh <proj> lint --error-code` |
| 2 | 自动化测试通过 | `./renpy.sh <proj> test --hide-execution all` |
| 3 | 给所有 `call` 补 `from` | `./renpy.sh <proj> add_from`（会改脚本） |
| 4 | 设置好 `build.name` / `version` / 图标 | `game/options.rpy`、`icon.ico`/`icon.icns` |
| 5 | 勾选 Force Recompile，点 Update old-game | 启动器 Build 页 |
| 6 | 检查 `.rpyc` 与 `.rpy` 一起发布 | 见 24.10 |
| 7 | 构建发行包 | 启动器 Build 或 `renpy.sh launcher distribute` |
| 8 | 在**干净**的机器/虚拟机上试运行一次 | 手动 |

第 6 条要特别说明：**不要只发布 `.rpy`**。有人为了「保护源码」删掉 `.rpyc`，结果玩家每次启动都要重编译、启动变慢，而且 `old-game` 机制也失效了。**正确做法是 `.rpy` 与 `.rpyc` 一起给**（想保护源码请用 24.6 的归档，或另想办法，但不要靠删 `.rpyc`）。反过来，命令行有个 `--keep-orphan-rpyc` 全局选项，用于保留那些「已经没有对应 `.rpy`」的孤立 `.rpyc`（详见 23.5 的全局选项表）。

## 24.13 其他平台

### 24.13.1 Web / HTML5

Ren'Py 通过把引擎编译成 **WebAssembly** 来在浏览器里跑游戏（官方 *Web / HTML5*）。它能用，但限制不少，最好一开始就为它设计。

**主要限制（官方原文归纳）：**

- 视频用浏览器内置播放，因此只能放浏览器支持的格式，且**只支持 `renpy.movie_cutscene()`**；
- 音频有两种播放方式：浏览器的 WebAudio（快，但 Safari 不支持 OGG）或 Ren'Py 内置播放（慢，但格式多）；由 `config.webaudio_required_types` 决定用哪种，例如只用 mp3 时：
  ```renpy
  define config.webaudio_required_types = [ "audio/mpeg" ]
  ```
- **不支持多线程**，所以 `renpy.invoke_in_thread()` 与 Python 的 `threading` 模块不可用；也无法在后台预载图片，**图片加载可能造成掉帧**；
- **不支持联网**——浏览器沙箱会拦住任意网络请求，`socket`、`requests` 都会报错；
- **不支持 Live2D**；
- 宿主限制：有的托管方限制包体积与文件数（官方点名 itch.io 有文档说明）；浏览器**大于 50MB 的文件不会被缓存**，于是大文件每次都要重新下载。

**打包方式**：启动器 **Web (Beta)** 区有四个入口——*Build Web Application*（产出 `web.zip` 与一个散文件目录）、*Build and Open in Browser*（构建并本地起服务器打开，**日常测试用这个**）、*Open in Browser*（不构建，直接开）、*Open build Directory*（打开产物目录）。

**命令行**（CLI *Web Build*）：

```bash
./renpy.sh launcher web_build <basedir> [--destination <dir>] [--launch]
```

**产物位置**：若工程在 `.../main/yourproject`，则产物在 `.../main/yourproject-1.0-dists/`，里面有 `yourproject-1.0-web/` 目录和 `yourproject-1.0-web.zip`。

**上传**：给 itch.io 这类平台上传 **`web.zip`**；自己托管则需上传 web 目录里的**每一个文件**，并确保服务器用 `application/wasm` MIME 类型返回 `.wasm`（否则会有警告且加载变慢）。若托管方拒收 `game.zip`，改名成 `game.data` 并编辑 `index.html` 把 `game.zip` 改成 `game.data`。

**presplash 与图标**：放一张名为 `web-presplash` 的图（`.jpg`/`.png`/`.webp`；`.webp` 可做动态 presplash）；页面图标放 `web-icon.png` 在**base 目录**，最小 512×512、宽高相等。

**渐进下载**：编辑 base 目录下的 `progressive_download.txt`（首次打包时会自动生成）。默认内容：

```
# RenPyWeb progressive download rules - first match applies"
# '+' = progressive download, '-' = keep in game.data (default)
#
# +/- type path
- image game/gui/**
+ image game/**
+ music game/audio/**
+ voice game/voice/**
```

规则：`#` 开头是注释；`-` 的行表示**游戏开始前就下载**（一般是开场界面用到的资源）；`+` 的行表示**按需下载**。第二列是文件类型（`image` 会先用像素化缩略图占位、加载完替换；`music`/`voice` 先用静音占位、加载完再播）。第三列是匹配路径。

**音频/视频的浏览器限制**：受「浏览器禁止自动出声」限制，**玩家至少点击一次游戏画面后**声音才会响。视频播放另有两个变量：`config.web_video_base`（视频 URL 前缀，可指向另一台服务器）与 `config.web_video_prompt`（iOS Safari 上提示玩家点击以播放带声音视频的文案）。Safari 不支持 webm，Ren'Py 有回退机制：会尝试把扩展名换成 `.mp4` 再试一次。

**JavaScript 互操作**：Web 平台下 `renpy.emscripten` 可用（非 Web 平台它是 `False`），提供三个函数：

| 函数 | 作用 |
| --- | --- |
| `renpy.emscripten.run_script(script)` | 执行给定 JS，不返回结果 |
| `renpy.emscripten.run_script_int(script)` | 执行并返回整数结果 |
| `renpy.emscripten.run_script_string(script)` | 执行并返回字符串结果 |

反过来，JS 可以通过 `window.renpy_exc` / `window.renpy_get` / `window.renpy_set` 调回 Ren'Py（细节见工程里生成的 `web/renpy-pre.js`）。注意 `web/index.html` **可能被 Ren'Py 升级时替换**，改动要留意。

**汉堡菜单**：Web 版左上角有一个菜单，含 *Import saves*（把存档与 persistent 导入浏览器）、*Export saves*（导出为 zip）、*Ren'Py log*（下载日志）三项。

### 24.13.2 Android

官方 *Android Packaging* 页已并入 *Building Android Applications*。命令行入口在 CLI 文档的 *Android Build*：

> This builds a release of the game for Android. It's assumed that **the launcher has been used to install the Android SDK, generate keys, and configure the project.**

```bash
./renpy.sh launcher android_build <basedir> [options...]
```

| 选项 | 作用 |
| --- | --- |
| `--destination <directory>` | 输出目录（默认 `name-version-dists`） |
| `--bundle` | 产出 `.aab`（用于 Play Store）；不给则产出 `.apk` |
| `--install` | 把 `.apk`/`.aab` 安装到已连接设备 |
| `--launch` | 在已连接设备上启动游戏（隐含 `--install`） |
| `--package <package>` | 指定要构建的包；默认构建 `android` 包 |

所以完整流程是：**先在启动器里装好 Android SDK、生成签名密钥、配置工程**，之后才能用命令行打包。日常调试记得用 `--launch`。

### 24.13.3 iOS

**只能在 Mac 上做**（官方 *iOS*）：

> Ren'Py supports creating iOS apps that run on iPhone and iPad devices. As creating an iOS app requires Apple-developed programs (like the Xcode IDE), **iOS apps can only be created on Macintosh computers.**

要点：

1. **需要 Xcode**：先在 Mac 上装 Xcode、加入 Apple 开发者计划、创建 provisioning profile（官方建议先照 Apple 的 *App Distribution Quick Start* 走一遍，甚至先打一个模板 app 练手）。
2. **创建 Xcode 工程**：启动器 iOS 菜单里选 **Create Xcode Project**；工程名取自启动器里显示的项目名，之后可以在 Xcode 里改。
3. **工程与 Ren'Py 版本绑定**：**每次升级 Ren'Py 都要重新创建 Xcode 工程并重做定制**。
4. **用 Xcode 构建**：启动器里选 **Launch Xcode** 打开工程，再在 Xcode 里构建并安装到设备。
5. **更新工程**：**Update Xcode Project** 会把最新的游戏内容拷进已有的 Xcode 工程。
6. **模拟测试**：启动器 iOS 界面提供两种模拟模式——iPhone 与 Tablet（模拟触屏，事件只在鼠标按下时才送达游戏）。**模拟器不能替代真机**（例如手指大小这类人因问题它测不出来）。
7. **许可提示**：iOS 上 Ren'Py 用到 LGPL 许可的库，官方给出了一段建议写进 app 描述的文案，并要求你自行找律师确认。
8. **合规警示**：官方坦言 iOS 支持仍在完善中，**默认 Ren'Py 界面不符合 Apple 的规范，需要改造**。

命令行对应命令：

```bash
# 创建 Xcode 工程
./renpy.sh launcher ios_create <basedir> <destination>

# 把游戏内容拷进已有 Xcode 工程（用于更新）
./renpy.sh launcher ios_populate <basedir> <destination>
```

### 24.13.4 关于 `build.sh` / `build.ps1`

在本仓库早期的 `renpy/` 目录里存在过一份 `build.ps1`（Windows 构建脚本）。需要说明的是：**Ren'Py 官方文档中并没有 `build.sh` / `build.ps1` 这样的标准构建脚本模板**——官方提供的构建路径只有两条：**启动器的 Build 页**，或**命令行 `renpy.sh launcher distribute`**（见 24.1.2）。本仓库的 `build.sh` / `build.ps1` 只是把命令行调用封装起来的便捷脚本，内容见附录 A。

## 24.14 本章小结与实践

### 24.14.1 小结

| 主题 | 关键结论 |
| --- | --- |
| **构建三步** | 扫描分类 → 归档 → 产出包与更新文件；不配置也能打包 |
| **核心变量** | `build.name`（源头）→ 派生 `directory_name`、`executable_name`；都不能含空格/冒号/分号 |
| **图标** | `icon.ico`（Win）、`icon.icns`（Mac），放 base 目录 |
| **文件列表** | 七个默认列表 `all`/`linux`/`mac`/`windows`/`renpy`/`android`/`archive`；未分类默认进 `all` |
| **分类规则** | `build.classify(pattern, list)`；`*` 不跨目录、`**` 跨目录；**先匹配先赢**；`None`/`""` 表示排除 |
| **归档** | `build.archive(name, file_list)`；默认 `archive` → `archive.rpa`；空归档不生成；**官方不建议随便归档** |
| **自定义包** | `build.package(name, format, file_lists, ...)`；格式含 `zip`/`tar.bz2`/`directory`/`dmg`/`app-*`/`bare-*`/`null`/`""` |
| **构建信息** | `build.time`（时间戳）、`build.info`（JSON 可序列化的字典，进 `cache/build_info.json`） |
| **高级变量** | `destination`/`include_update`/`update_formats`/`itch_project`/`mac_info_plist` 等，见 24.9 全表 |
| **存档兼容** | 调用栈用 `from`（23.7）；台词/场景 ID 用 `old-game/` 目录（24.10）；**`.rpyc` 必须随包发布** |
| **平台** | Web 有诸多限制（无多线程/无联网/无 Live2D）；Android 需先装 SDK 与密钥；iOS 只能在 Mac 上做 |
| **发布前** | 见 24.12 清单 |

### 24.14.2 实践题

1. **打一个完整包。** 用 `examples/16_full_project`，在 `options.rpy` 里设好 `build.name` 与 `build.version = "1.0"`，然后跑 `./renpy.sh launcher distribute <basedir>`；到 `<directory_name>-dists` 里检查产出了哪几个包，并分别在 Windows/macOS/Linux 上（或虚拟机里）试运行。
2. **写一套分类规则。** 在工程里放一个 `README.md`（要进包）与一批 `*.psd` 源文件（不进包），用 `build.classify` 让前者进 `all`、后者被排除；再跑一次构建确认 `.psd` 确实没进包。
3. **自定义一个 DLC 包。** 仿照 24.7 的 premium 例子，用 `build.archive` + `build.classify` + `build.package` 造一个只含 `game/bonus/` 内容的 zip 包。
4. **做一次「坏档」实验。** 给一个已有存档的工程写几行 `call`（不写 `from`），存档后修改脚本，再读档观察 `return` 是否跑偏；然后运行 `add_from`、重建 `old-game`，重复实验，确认问题消失。

---

上一章：[23 调试与自动化测试](ch23-debug-and-testing.md) · 下一章：[附录 A 示例集总览与构建方法](appendix-a-examples.md)
