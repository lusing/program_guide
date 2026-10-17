# Ren'Py 开发指南示例集

本目录是《Ren'Py 开发指南》的配套示例集，结构为“分章版教程 + 可独立运行的示例工程 + 构建脚本”。

- 教程正文：[`tutorial/`](./tutorial/index.md)，`index.md` 为目录页，正文按章拆为 `ch01`–`ch24` 共 24 个文件外加 `appendix-a-examples.md`；每个文件页首与页尾都带「上一章 ｜ 目录 ｜ 下一章」导航。
- 示例工程：`examples/` 下 **19 个**可独立 `compile` / `lint` / `run` 的 Ren'Py 工程，与正文章节一一对应。
- 构建脚本：`build.sh`（Linux/macOS）与 `build.ps1`（Windows），用于批量编译与静态校验。

## 目录结构

```text
renpy/
├── README.md
├── tutorial/                 # 教程正文：index.md + ch01–ch24 + appendix-a-examples.md
├── build.sh                     # Linux/macOS 批量校验脚本
├── build.ps1                    # Windows 批量校验脚本
└── examples/
    ├── 01_first_game/           # 第 3 章  对话与角色
    ├── 02_images_and_stage/     # 第 4 章  图像与舞台
    ├── 03_labels_and_flow/      # 第 5 章  标签与控制流
    ├── 04_menus_and_variables/  # 第 6 章  菜单、变量与分支
    ├── 05_text_and_dialogue/    # 第 7 章  对话进阶与文本
    ├── 06_nvl_mode/             # 第 8 章  NVL 模式
    ├── 07_audio_and_video/      # 第 9 章  音频与视频
    ├── 08_atl_and_transform/    # 第 10 章 ATL 与 transform
    ├── 09_transitions/          # 第 11 章 转场
    ├── 10_layeredimage/         # 第 12 章 Layered Images
    ├── 11_screens/              # 第 13 章 Screen 语言基础
    ├── 12_actions/              # 第 14 章 Screen 动作与数据绑定
    ├── 13_special_screens/      # 第 15 章 特殊 screen、菜单定制与样式
    ├── 14_save_rollback/        # 第 16 章 变量、存档与回滚
    ├── 15_persistent/           # 第 17 章 持久化数据
    ├── 16_full_project/         # 第 18 章 Python 语句与多文件工程
    ├── 17_input_history/        # 第 19 章 玩家输入、对话历史与通知
    ├── 18_extras/               # 第 20 章 画廊、音乐室与剧情回放
    └── 19_lifecycle/            # 第 21 章 开场动画与游戏生命周期
```

每个示例工程都只有 `game/` 目录下的 `.rpy` 源文件，绝大多数仅含一个 `game/script.rpy`；`16_full_project` 额外拆出 `characters.rpy` 与 `options.rpy`，用来演示多文件工程的组织方式。

## 关于示例工程的几个事实

这些示例刻意做成“零素材、零模板文件”，因此需要读者了解它的两点非典型之处（正文附录 A.2 有完整解释）：

1. **没有 `gui.rpy` / `screens.rpy` / `options.rpy`。** 示例不依赖启动器生成的那套模板；需要界面时，示例会在自己的 `script.rpy` 里定义 `screen`。
2. **默认没有主菜单。** 当工程里不存在 `main_menu` / `main_menu_screen` 这类特殊 label 时，Ren'Py 会跳过主菜单、直接从 `start` 开始演。这正是示例“运行即开演”的原因；`13_special_screens` 与 `19_lifecycle` 会自行定义 `label main_menu` 来演示主菜单与生命周期钩子。

所有图像与音频都用引擎内建构造代替真实素材：图像用 `Solid` / `Composite` / `Text` / `Transform`，音频用静音片段如 `"<silence 2.0>"`。因此每个示例都不需要任何图片或音频文件即可运行。

## 构建工具链

- Ren'Py SDK：本例集按 **Ren'Py 8.5.x** 编写与验证（开发时使用 `Ren'Py 8.5.3.26051504`；8.5.4 亦可）。
- SDK 里的命令行入口：`renpy.sh`（macOS/Linux）、`renpy.exe`（Windows）。

### 定位 SDK

`build.sh` 与 `build.ps1` 会按以下顺序自动查找 SDK：

- `build.sh`（macOS/Linux）：`$RENPY` 环境变量 → 仓库根目录下的 `renpy.sh` → `/Applications/renpy*/renpy.sh` → `~/renpy*-sdk/renpy.sh` → `~/renpy-sdk/renpy.sh` → `/opt/renpy/renpy.sh` → `PATH` 中的 `renpy.sh`。
- `build.ps1`（Windows）：`-RenpyPath` 参数 → 仓库根目录下的 `renpy.exe` / `renpy.sh` → `%USERPROFILE%\scoop\apps\renpy\current\renpy.exe` → `%USERPROFILE%\renpy-8.5.4-sdk\renpy.exe` → `C:\renpy\renpy.exe` → `PATH` 中的 `renpy.exe`。

若都找不到，显式指定即可：

```bash
RENPY=/path/to/renpy-8.5.x-sdk/renpy.sh ./build.sh
```

```powershell
.\build.ps1 -RenpyPath "C:\path\to\renpy-8.5.x-sdk\renpy.exe"
```

## 编译与验证

### 批量校验（推荐）

```bash
cd renpy
./build.sh                 # 编译 + lint 校验全部 19 个示例
./build.sh 12_actions      # 只校验单个示例
./build.sh --compile-only  # 只编译，不跑 lint
./build.sh --clean         # 清理各示例的 cache / saves / *.rpyc / log.txt
```

```powershell
cd renpy
.\build.ps1                       # 编译 + lint 校验全部示例
.\build.ps1 -Project 12_actions    # 只校验单个示例
.\build.ps1 -CompileOnly           # 只编译，不跑 lint
.\build.ps1 -Clean                 # 清理各示例的编译产物与运行日志
```

验收标准：**全部 19 个示例都能通过 `compile` 与 `lint --error-code`（退出码 0）**。

### 手动逐步验证

```bash
SDK=/path/to/renpy-8.5.x-sdk

# 1) 编译（等价于启动器的 Force Recompile）
"$SDK/renpy.sh" examples/01_first_game compile

# 2) 静态检查（有错时退出码非 0）
"$SDK/renpy.sh" examples/01_first_game lint --error-code

# 3) 运行（需要图形界面）
"$SDK/renpy.sh" examples/01_first_game run

# 4) 跑自动化测试（仅对写了 testsuite 的工程有意义）
"$SDK/renpy.sh" examples/01_first_game test --hide-execution all
```

## 说明

- Ren'Py 是面向视觉小说与交互式叙事的脚本引擎，适合剧情驱动游戏、文字冒险与小说式游戏开发。
- 本仓库用 `compile` + `lint` 做无界面验证，确保每个示例都能被当前本机引擎正确编译与静态检查通过。
- `build.sh` / `build.ps1` 是**本书自带的便捷脚本，不属于 Ren'Py 官方文档的一部分**；官方对构建的标准入口是启动器的 Build 页与 `renpy.sh launcher distribute`。
