# =============================================================
# 第 16 章 示例工程 14：变量、存档与回滚
# -------------------------------------------------------------
# 本工程演示：
#   - default 变量
#   - 回滚（rollback）对变量的影响
#   - 不依赖任何内置 UI 的直接存档 / 读档 API
#     （renpy.save / renpy.load / renpy.list_saved_games / renpy.can_load）
#   - 自制的存档槽屏幕 screen save_slots（使用 FileSave / FileLoad 动作）
#   - renpy.checkpoint() / renpy.block_rollback() / config.rollback_enabled
#
# 本工程只有 game/script.rpy 一个文件，不使用任何 gui.* 变量与素材。
# =============================================================

# -------------------------------------------------------------
# 1. default 变量
# -------------------------------------------------------------
# default 声明的变量会随「新游戏」被重新初始化。
# 它们也会被写进存档，因此读档时会恢复成存档时的值。

default affinity = 0
default player_name = "旅行者"
default visited_library = False

define narrator = Character(None, what_style="say_dialogue")
define e = Character("旁白", who_style="say_label", what_style="say_dialogue")

# -------------------------------------------------------------
# 2. 自制存档槽屏幕（不依赖任何内置 save / load 屏幕）
# -------------------------------------------------------------
# 本引擎环境没有内置的存档 UI，所以这里完全自己写一个：
#   - 用 renpy.list_saved_games(fast=False) 列出已有存档
#   - 用 FileSave(name, slot=True) / FileLoad(name, slot=True) 执行存/读
#
# 说明：FileSave / FileLoad 的 slot=True 表示把 name 当作「完整的槽名」直接用，
# 这样可以精确对应 renpy.save("1-1") 写出的 "1-1" 槽。
# 参考 renpy/common/00action_file.rpy 中 __slotname() 的实现。

screen save_slots():

    # 纯色背景铺满整屏
    add Solid("#0d0d18")

    vbox:
        xalign 0.5
        yalign 0.5
        spacing 12

        text "存档槽" size 36 xalign 0.5 color "#ffffff"

        # 已有存档列表：每个元素是 (槽名, 附加信息, 时间, 截图显示体)
        text "（已有存档）" size 20 xalign 0.5 color "#9099b0"
        for name, extra_info, save_time, screenshot in renpy.list_saved_games(fast=False):
            # name 是形如 "1-1" 的完整槽名，故直接传给 FileLoad 并置 slot=True
            textbutton "[name]  [extra_info]" action FileLoad(name, slot=True)

        text "（存到固定槽）" size 20 xalign 0.5 color "#9099b0"

        # 两个固定的存档槽：1-1 与 1-2
        hbox:
            xalign 0.5
            spacing 16
            text "1-1" color "#ffffff" yalign 0.5
            textbutton "保存" action FileSave("1-1", slot=True)
            textbutton "读取" action FileLoad("1-1", slot=True)

        hbox:
            xalign 0.5
            spacing 16
            text "1-2" color "#ffffff" yalign 0.5
            textbutton "保存" action FileSave("1-2", slot=True)
            textbutton "读取" action FileLoad("1-2", slot=True)

        # 关闭屏幕：Return() 结束 call screen
        textbutton "关闭" action Return() xalign 0.5

# -------------------------------------------------------------
# 3. 剧情：走一遍变量、回滚与存档
# -------------------------------------------------------------

label start:

    "第 16 章示例：变量、存档与回滚。"

    e "我们先看看 default 变量的值。"

    $ affinity += 1
    "affinity 现在是 [affinity]（初始 0，加 1 后为 [affinity]）。"

    # ------ 回滚说明 ------
    # Ren'Py 默认允许回滚：玩家用鼠标滚轮向上滚，或使用 Rollback 动作，
    # 就能回到上一句台词。回滚会同时把「变量」恢复到那个时间点的值——
    # 也就是说，下面这个选项对 affinity 的修改，会被回滚一并撤销。
    menu:
        "要给 affinity 再加 2 点吗？"

        "加":
            $ affinity += 2
            "affinity 现在是 [affinity]。"

        "不加":
            "affinity 保持 [affinity]。"

    "此时你先别急着往下滚——试着用滚轮向上回滚，会发现 affinity 也退回去了。"

    # ------ 手动打存档点 ------
    # renpy.checkpoint() 会在此处建立一个回滚检查点，
    # 让玩家可以稳定地回滚到这一行。
    $ renpy.checkpoint()
    "刚刚手动建立了一个 rollback 检查点（renpy.checkpoint()）。"

    # ------ 直接存档 API（完全绕过 UI）------
    # renpy.save(slotname, extra_info=...) 把当前进度写入槽 "1-1"。
    # 注意它接收的是「原始槽名」，和 FileSave 的 slot=True 用法一致。
    $ renpy.save("1-1", extra_info="第16章演示存档")
    "已用 renpy.save(\"1-1\") 保存了一个存档。"

    # 用一句 $ 语句列出所有存档槽
    python:
        slot_list = renpy.list_saved_games(fast=True)
        slot_text = "、".join(slot_list) if slot_list else "（暂无）"
    "当前存在的存档槽：[slot_text]"

    # renpy.can_load(slotname) 判断某个槽是否可读取
    $ can = renpy.can_load("1-1")
    if can:
        "renpy.can_load(\"1-1\") 返回 True：这个槽可以读取。"
    else:
        "renpy.can_load(\"1-1\") 返回 False：这个槽暂时读不了。"

    # ------ 打开自制存档屏幕 ------
    "下面打开我们自制的存档屏幕，你可以在里面存 / 读。"
    call screen save_slots
    "你已经关闭了存档屏幕。"

    # renpy.load(slotname) 会真正读取存档并跳回保存时的进度，
    # 这里放到一个可选的菜单选项里，由玩家决定是否触发。
    menu:
        "要读取刚才那个存档吗？（会跳回保存时的进度）"

        "读取":
            $ renpy.load("1-1")

        "算了":
            "好的，继续。"

    # ------ block_rollback 与 config.rollback_enabled ------
    # renpy.block_rollback() 会禁止从这一行起继续向前回滚。
    # config.rollback_enabled 是全局开关，默认为 True。
    $ renpy.block_rollback()
    $ enabled = config.rollback_enabled
    "已调用 renpy.block_rollback()：从现在起不能再向前回滚了。"
    "同时 config.rollback_enabled 当前为 [enabled]（True 表示全局允许回滚）。"

    "本示例到此结束。"
    return
