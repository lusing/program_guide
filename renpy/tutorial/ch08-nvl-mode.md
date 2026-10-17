# 第 8 章 NVL 模式

## 8.1 两种呈现：ADV 与 NVL

默认的对话呈现叫 **ADV 模式**：一次一句，窗口底部随说话者切换内容。**NVL 模式**（"novel"）则把多句话**堆叠在一个整屏文本窗**里，像翻小说页一样推进。适合旁白叙事、书信体、系统播报、群聊记录。

## 8.2 定义 NVL 角色

用 `kind=nvl` 声明一个 NVL 版角色（`kind` 表示"以某个内置角色为模板"）：

```renpy
define e_nvl = Character("艾琳", kind=nvl, color="#c8ffc8")

label start:
    e_nvl "第一句出现在整屏窗口。"
    e_nvl "第二句接在下面，不会覆盖第一句。"
    return
```

引擎还预置了 NVL 旁白角色 `nvl_narrator`，以及把**默认旁白**整体改成 NVL 的写法：

```renpy
define narrator = Character(kind=nvl)

label start:
    "此后所有没有指定角色的旁白都进入 NVL 页面。"
    "直到你把它改回来。"
    return
```

## 8.3 nvl clear：翻页

NVL 页会无限堆叠，需要你主动翻页：

```renpy
label start:
    e_nvl "这一页堆了很多话……"
    e_nvl "写下一页之前："
    nvl clear
    e_nvl "这是干净的新一页。"
    return
```

`nvl clear` 清空当前 NVL 页。惯例是在**每个 NVL 页的末尾**写它，让存档点落在"整页已完成"的干净状态。另外，`scene` 语句会自动清空 NVL 页——切场景即翻页，不需要额外处理。

## 8.4 NVL 菜单

```renpy
define menu = nvl_menu

label start:
    e_nvl "在这个故事里，连选项都印在小说页上。"
    menu:
        "点头":
            e_nvl "你点了点头。"
        "摇头":
            e_nvl "你摇了摇头。"
    return
```

`define menu = nvl_menu` 把**所有** `menu` 语句重定向到 NVL 版菜单（选项叠加在当前 NVL 文本之下）。它是全局开关，建议只在整体采用 NVL 风格时使用；混合风格时保持默认菜单更稳。

## 8.5 ADV 与 NVL 混用

同一个工程里直接混用即可：ADV 角色说话时，NVL 窗口自动让位；需要显式控制对话窗显隐时用 `window` 语句：

```renpy
label start:
    e_nvl "NVL 的一段。"
    window hide
    pause 1.0
    window show
    e "ADV 的一段。"
    return
```

`window hide` / `window show` 立即隐藏/显示对话窗；默认的 `window auto` 交给引擎按语句类型自动管理（旁白与对话显示窗口，`scene` 后不残留）。

## 8.6 小结与实践

- `kind=nvl` 定义 NVL 角色，`define narrator = Character(kind=nvl)` 全局旁白 NVL 化；
- `nvl clear` 手动翻页，`scene` 自动翻页，页尾 `nvl clear` 是存档好习惯；
- `define menu = nvl_menu` 全局启用 NVL 菜单；
- 示例工程 `06_nvl_mode` 演示全部要点。

---

上一章：[07 对话进阶与文本](ch07-text-and-dialogue.md) · 下一章：[09 音频与视频](ch09-audio-and-video.md)
