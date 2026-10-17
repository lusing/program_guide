# 第 9 章 音频与视频

> [← 第 8 章 NVL 模式](ch08-nvl-mode.md) ｜ [目录](index.md) ｜ [第 10 章 ATL 与 transform →](ch10-atl-and-transform.md)

## 9.1 通道模型与三大语句

Ren'Py 的音频建立在**通道**之上：内置通道有 `music`（默认循环的背景音乐）、`sound`（一次性音效）、`voice`（语音）、`movie`（影片音轨），你也可以建自定义通道。操作通道的是三个语句：

```renpy
label start:
    play music "audio/main_theme.ogg" fadein 2.0 fadeout 1.0
    play sound "audio/click.wav"
    queue music "audio/next_theme.ogg"
    stop music fadeout 2.0
    return
```

- `play` 立即播放，同通道原有音频被替换；
- `queue` 排队：当前曲目播完后接上队列中的下一首（做"曲单连播"的标准方式）；
- `stop` 停止，`fadeout` 子句让它优雅淡出而非戛然而止。

常用子句一览：`fadein N` / `fadeout N`（秒）、`loop` / `noloop`（music 通道默认循环，sound 默认不循环）、`if_changed`（**要播放的曲目与当前相同就不重启**——场景切换时保留 BGM 不被打断的关键子句）、`volume 0.5`（0~1 相对音量）、`channel "自定义通道名"`（临时换通道）。

## 9.2 audio namespace：给音频起名字

```renpy
define audio.treasure = "audio/bgm_treasure.ogg"
define audio.click = "audio/sfx_click.wav"

label start:
    play music treasure fadein 1.0
    play sound click
    return
```

`define audio.名字 = "路径"` 把音频注册进 `audio` 命名空间，此后 `play`/`queue` 直接写名字。工程里几十处 `play music "audio/..."` 的路径字符串被收敛为一次定义——文件挪位置时只改一行。`audio.*` 还能用于自定义通道（`define audio.sfx2 = ...` 会顺带注册 `sfx2` 通道）。

## 9.3 播放列表、静音与播放位置

`play` 后面可以直接给**文件列表**，以及形如 `<...>` 的内嵌控制指令：

```renpy
label start:
    play music ["audio/intro.ogg", "<silence 2.0>", "audio/loop_part.ogg"]
    play music "<from 5 to 15.5>audio/highlight.ogg"
    play music "<loop 3.542>audio/seamless.ogg"
    return
```

- 列表按顺序连播；`<silence 2.0>` 在曲目之间插 2 秒静音；
- `<from 5 to 15.5>` 只播放该文件 5 秒到 15.5 秒之间的部分；
- `<loop 3.542>` 指定循环回跳点：曲目每次播到结尾都跳回 3.542 秒处——**做无缝循环 BGM 的标准手法**（3.542 之前是前奏，之后是主循环体）。

## 9.4 音频滤镜（8.4+）

8.4 起，`play`/`queue` 支持 `filter` 子句，配合 `renpy.audio.filters` 命名空间里的 Reverb、Eq 等滤镜类可以做实时混响、均衡。滤镜链的构建细节建议按需查阅官方 "Audio Filters" 文档，基础游戏用不到。

## 9.5 视频

```renpy
image fly_movie = Movie(size=(1280, 720), xalign=0.5, yalign=0.5)

label start:
    play movie "video/fly.webm"
    show fly_movie
    "（影片播放中……）"
    stop movie
    hide fly_movie
    return
```

- `Movie(size=...)` 定义影片 displayable：`size` 声明影片尺寸（引擎用它做占位与缓冲），可附加位置属性；
- `play movie` 把影片送入 `movie` 通道（音轨+画面缓冲），`show` 负责把画面呈现在舞台上；
- `stop movie` 停止播放。编码推荐 WebM（VP9/Vorbis），全平台兼容。

## 9.6 小结与实践

- `play`/`queue`/`stop` + 通道是全部心智模型；`if_changed` 防止 BGM 重启；
- 音频资产进 `audio namespace`，路径只写一次；
- `<loop N>` 做无缝循环；`Movie` + `play movie` 播视频；
- 示例工程 `07_audio_and_video`（音频用程序生成的静音与 `<silence>` 演示结构）。

---

> [← 第 8 章 NVL 模式](ch08-nvl-mode.md) ｜ [目录](index.md) ｜ [第 10 章 ATL 与 transform →](ch10-atl-and-transform.md)
