# Ren'Py 开发指南示例集

本目录按照 `guide` 统一标准整理为“教程文档 + 独立示例工程 + 构建脚本”的结构，便于在本机 Ren'Py 环境中实际编译和验证视觉小说与交互脚本。

## 目录结构

```text
renpy/
├── README.md
├── Renpy开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello/
│   │   └── game/
│   │       └── script.rpy
│   ├── 02_variables/
│   │   └── game/
│   │       └── script.rpy
│   ├── 03_labels_and_menu/
│   │   └── game/
│   │       └── script.rpy
│   ├── 04_dialogue_and_choices/
│   │   └── game/
│   │       └── script.rpy
│   ├── 05_story_loop/
│   │   └── game/
│   │       └── script.rpy
│   ├── 06_advanced_systems/
│   │   └── game/
│   │       └── script.rpy
│   ├── 07_visual_novel_structure/
│   │   └── game/
│   │       ├── script.rpy
│   │       ├── characters.rpy
│   │       ├── chapter1.rpy
│   │       └── gui.rpy
│   ├── 08_story_systems/
│   │   └── game/
│   │       ├── script.rpy
│   │       ├── endings.rpy
│   │       └── persistent_state.rpy
│   ├── 09_ui_and_audio/
│   │   └── game/
│   │       ├── script.rpy
│   │       ├── screens.rpy
│   │       └── audio.rpy
│   ├── 10_character_and_emotion/
│   │   └── game/
│   │       ├── script.rpy
│   │       ├── characters.rpy
│   │       └── emotions.rpy
│   └── 11_main_menu_and_pause/
│       └── game/
│           ├── script.rpy
│           ├── screens.rpy
│           └── options.rpy
└── build/
```

## 构建工具链

- Ren'Py：`G:\scoop\apps\renpy\current\renpy.exe`

## 编译与验证

```powershell
cd G:\code\guide\renpy
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -Project 02_variables
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- Ren'Py 是一个专门用于视觉小说与交互式叙事的脚本引擎，适合剧情驱动游戏、文字冒险和小说式游戏开发。
- 本目录使用 Ren'Py 的 `compile` 命令对每个示例项目做无界面编译验证，确保脚本在当前本机引擎中可被正确解释和编译。
- 示例覆盖了基础脚本、变量、标签、菜单、对话选择、故事循环，以及高级篇与真正视觉小说项目结构中的状态 HUD、分章组织和持久化存档机制。
