# =============================================================
# 第 18 章 多文件工程示例：characters.rpy
# -------------------------------------------------------------
# 本文件负责「角色定义」与「初始化数据」。
# 同目录下所有 .rpy 文件在编译时会被合并为一个脚本，
# 因此这里的 define / init python 与 script.rpy 里的内容等价，
# 只是被拆分到不同文件以便维护。
# =============================================================

# -------------------------------------------------------------
# 1. 角色定义
# -------------------------------------------------------------
# who_style / what_style 使用引擎默认的样式名，无需 gui.rpy 即可运行。

define mc = Character("主角", who_style="say_label", what_style="say_dialogue")
define mentor = Character("导师", who_style="say_label", what_style="say_dialogue")

# -------------------------------------------------------------
# 2. 初始化数据与辅助函数（init python）
# -------------------------------------------------------------
# init python 块会在游戏启动时执行一次，适合放置数据与工具函数。

init python:

    # 一个小的数据结构：列表里每个元素是一个 dict
    stat_table = [
        {"name": "力量", "value": 3},
        {"name": "敏捷", "value": 5},
        {"name": "智力", "value": 4},
    ]

    def random_stat():
        """从 stat_table 里随机取一条属性，返回它的名字。"""
        # renpy.random 是引擎提供的随机数对象（见 renpy/exports/__init__.py）
        return renpy.random.choice(stat_table)["name"]
