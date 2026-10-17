# 第 1 章 认识 Ren'Py

> [← 教程首页](index.md) ｜ [目录](index.md) ｜ [第 2 章 安装、启动器与命令行 →](ch02-install-launcher-cli.md)

Ren'Py 是一个用 Python 编写、专为**视觉小说（visual novel）与叙事型游戏**设计的开源引擎。它解决的核心问题是：把"讲故事"这件事的门槛降到接近写剧本，同时保留用 Python 扩展出任何玩法系统的能力。

它有几个鲜明的特点：

1. **剧本即代码。** Ren'Py 脚本语言（.rpy 文件）里的每一行对话、每一个选择分支，本身就是引擎的可执行语句。写完就能跑，不需要先学游戏引擎的节点编辑器。
2. **内置视觉小说的全套基础设施。** 对话框、历史记录、存档/读档、回滚（鼠标滚轮撤销操作）、快进、自动播放、设置菜单、多语言翻译、无障碍自述（self-voicing）——这些都是引擎默认提供的能力，你写的是"内容"，引擎负责"播放器"。
3. **与 Python 3 深度融合。** Ren'Py 8.x（本指南的基准版本）运行在 Python 3 之上（旧版 Ren'Py 7.x 基于 Python 2.7，已属遗留版本，新项目不应使用）。你可以在剧本中直接写 Python，也可以把复杂逻辑写成 Python 模块。
4. **一套脚本，多平台发布。** Windows、macOS、Linux、Android、iOS、Web（HTML5/WebAssembly）都可以从同一个工程构建。

Ren'Py 并不限于"纯视觉小说"。官方生态里有把 Ren'Py 做成养成、卡牌、密室逃脱、模拟经营的作品；引擎提供的 screen 系统、拖放系统、creator-defined displayable/statement 等机制，足以支撑超出"点点看看"范畴的玩法。但要注意它的舒适区始终是**以叙事为主轴**的游戏——如果你的游戏是动作或强实时玩法，应该考虑 Godot/Unity 这类通用引擎。

## 1.1 版本与兼容性口径

- 本指南基于 **Ren'Py 8.5.x**（官方在线文档当前为 8.5.x 系列；本仓库示例以 **8.5.3 SDK** 编译验证）。
- Ren'Py 8 对应 **Python 3**。官方 quickstart 页面上偶见"Ren'Py supports Python 2.7"的陈旧表述，那是针对 Ren'Py 7 的遗留句子，以 Incompatible Changes 页的"the Python 3 powered Ren'Py 8"为准。
- 8.x 相对旧版有若干不兼容变化（如 Python 3 语义、`init offset` 章节调整、音频滤镜等 8.4/8.5 新特性）。接手老项目时，先查官方 *Incompatible Changes* 页与 *Changelog*。

## 1.2 本指南与示例集

每一章都遵循同一个结构：**概念 → 完整代码（逐行讲解）→ 运行效果 → 工程实践建议**。与指南配套，`examples/` 下有 19 个可独立编译运行的示例工程（总览见附录 A），从第 3 章开始逐章对应。示例刻意不依赖任何图片/音频素材文件（用引擎内建的纯色 `Solid`、静音片段 `<silence>` 代替），因此 clone 后即可编译，无需下载素材。

---

> [← 教程首页](index.md) ｜ [目录](index.md) ｜ [第 2 章 安装、启动器与命令行 →](ch02-install-launcher-cli.md)
