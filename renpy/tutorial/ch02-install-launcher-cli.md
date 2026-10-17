# 第 2 章 安装、启动器与命令行

## 2.1 获取 SDK

从 https://www.renpy.org/latest.html 下载对应操作系统的 SDK（Windows 为 zip/exe，macOS 为 tar.bz2，Linux 为 tar.bz2）。当前 8.5 系列 SDK 约 350 MB。

macOS 用户注意：SDK 压缩包里的 mac 运行时二进制以 `.macho` 后缀存储（防止跨平台解压时丢失执行权限）。如果你在 Windows/Linux 上解压了 SDK 再拷到 mac，首次运行前需要把 `lib/py3-mac-universal/` 下的 `*.macho` 重命名去掉后缀并赋予执行权限：

```bash
cd <sdk>/lib/py3-mac-universal
for f in *.macho; do mv "$f" "${f%.macho}"; done
chmod +x *
```

官方推荐把 SDK 放在**不随系统只读镜像挂载**的位置（macOS 上不要直接从 dmg 里运行），否则启动器无法写入自己的配置。

## 2.2 启动器（Launcher）

SDK 根目录的 `renpy.exe`（Windows）、`renpy.app`（macOS）或 `renpy.sh`（Linux）就是**启动器**。启动器负责：

- 创建/管理项目（默认扫描一个 projects 目录，首次创建项目时会让你指定）；
- 用编辑器打开脚本（官方推荐 **Visual Studio Code**，启动器可代为安装）；
- 运行项目、强制重新编译、检查脚本（Lint）、构建发布包；
- 安装各平台支持（Android/iOS/Web）。

首次启动建议先跑通两个自带项目：**The Question**（官方示例游戏，quickstart 教程的完整实现）和 **Tutorial**（交互式教学游戏）。它们都在 SDK 目录下。

## 2.3 命令行接口（CLI）

除了图形启动器，Ren'Py 提供完整的命令行接口（CI 友好）。语法（以 macOS/Linux 为例，Windows 把 `./renpy.sh` 换成 `renpy.exe`）：

```bash
./renpy.sh [全局选项] <项目目录> [命令] [命令参数]
```

常用的全局选项：`--compile`（运行前强制重编译）、`--savedir <目录>`（指定存档位置）、`--version`（显示版本）。

最常用的命令：

```bash
# 运行项目
./renpy.sh /path/to/project run

# 编译：把所有 .rpy 编译为 .rpyc（等价于启动器的 Force Recompile）
./renpy.sh /path/to/project compile

# Lint：静态检查脚本错误并输出统计，CI 中可加 --error-code 让有错时退出码为 1
./renpy.sh /path/to/project lint --error-code

# 运行自动化测试（8.5 新增的 testcases 机制）
./renpy.sh /path/to/project test <testcase 名>

# 给所有不带 from 的 call 语句补 from 子句（发布前执行）
./renpy.sh /path/to/project add_from

# 构建发行包
./renpy.sh launcher distribute /path/to/project --destination /path/to/output

# 删除持久化数据（会清空成就/解锁记录，谨慎）
./renpy.sh /path/to/project rmpersistent
```

本仓库的 `build.ps1`（Windows）与 `build.sh`（macOS/Linux）就是对 `compile` + `lint` 的封装，用于一键验证全部示例（见附录 A）。注意 CLI 属于"非稳定接口"，跨版本可能微调，以 `./renpy.sh --help` 为准。

## 2.4 创建项目与模板文件

在启动器中点 **Create New Project**：选择 projects 目录 → 输入项目名 → 选择分辨率（官方教程使用 1280x720，是画质与体积的常见折中）→ 选主题色。生成的是一个**立刻可玩**的模板游戏：自带回滚、存读档、设置等完整界面。

模板 `game/` 目录的关键文件：

| 文件 | 作用 |
|---|---|
| `script.rpy` | 剧情脚本入口，`label start` 所在处；可自由增删任何 .rpy |
| `options.rpy` | 引擎配置（config 变量）、构建配置（build 变量） |
| `screens.rpy` | 全部界面 screen（主菜单、存档、设置等）的定制入口 |
| `gui.rpy` | GUI 变量（颜色、字体、尺寸），改主题先改这里 |
| `definitions.rpy`（部分模板） | 角色定义等公共定义 |
| `audio/`、`images/`、`gui/`、`tl/` | 音频、图片、GUI 图片、翻译目录 |
| `cache/` | 编译缓存，**不要手工编辑** |
| `*.rpyc` | .rpy 的编译产物，加快加载；**不要编辑**，删除某 .rpy 时要连同同名 .rpyc 一起删 |

**重要的心智模型**：`game/` 下所有 .rpy 文件在语义上等于**拼接成一个大文件**，文件名与剧情组织无关，任何文件里定义的 `label`、`image`、`screen` 都全局可见（同名冲突才受文件顺序影响）。因此项目长大后，你可以按任意逻辑拆分文件——第 22 章会给出推荐拆法。

---

上一章：[01 认识 Ren'Py](ch01-what-is-renpy.md) · 下一章：[03 第一个游戏：对话与角色](ch03-first-game.md)
