# =============================================================
# 第 18 章 多文件工程示例：options.rpy
# -------------------------------------------------------------
# 本文件只设置少量全局配置，刻意不涉及任何 gui / 主题设置，
# 因此不需要 gui.rpy 也能正常工作。
# =============================================================

# _() 是引擎内置的翻译函数（见 renpy/minstore.py）。
# config.name 出现在窗口标题等处（见 renpy/common/00library.rpy）。
define config.name = _("多文件工程示例")

# config.version 是游戏版本号，也会被记录进存档信息。
define config.version = "1.0"

# config.save_directory 指定存档目录名，用于隔离不同游戏的存档。
define config.save_directory = "renpy_example_16_full_project"

# build.name 是打包系统使用的基础名（见 renpy/common/00build.rpy）。
define build.name = "full_project"
