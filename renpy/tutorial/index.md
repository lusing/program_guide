# Ren'Py 开发指南

> 本指南依据 Ren'Py 官方文档（https://www.renpy.org/doc/html/ ，8.5.x 系列）全面重写，覆盖从第一个脚本到构建发布的完整流程。全部示例代码都在正文中逐段引用并讲解，不需要读者翻看其他文件；每个主题都配有可直接编译运行的本仓库示例工程（`examples/` 目录，详见附录 A），并已在 Ren'Py 8.5.3 SDK 上通过 `compile` 与 `lint` 验证。
>
> 阅读约定：代码块中的 Ren'Py 脚本均可直接放入 `game/script.rpy` 运行；正文中的行内代码（如 `label`、`default`）指语言关键字或引擎变量；带编号的小节中出现的"示例 03"等字样指本仓库 `renpy/examples/` 下对应的示例工程。

---

## 如何使用本教程

本教程按章拆分在 `tutorial/` 目录下：每章一个 Markdown 文件，章末页脚带「上一章 · 下一章」导航；下面的[目录](#目录)展开到每一节，可带锚点直达。

配套资源：

- 示例工程：[`../examples/`](../examples/) 下与各章一一对应的 19 个可运行 Ren'Py 工程；总览见 [附录 A](appendix-a-examples.md)，批量校验方法见 [附录 A.4 批量脚本](appendix-a-examples.md#a4-批量脚本)。
- 仓库说明：[`../README.md`](../README.md)。

本教程依据 Ren'Py 官方文档（https://www.renpy.org/doc/html/ ，8.5.x 系列）编写，所有示例均在 Ren'Py 8.5.3 SDK 上通过 `compile` 与 `lint` 校验。

---

## 目录

### 第一部分 入门篇

- [第 1 章 认识 Ren'Py](ch01-what-is-renpy.md)
  - [1.1 版本与兼容性口径](ch01-what-is-renpy.md#11-版本与兼容性口径)
  - [1.2 本指南与示例集](ch01-what-is-renpy.md#12-本指南与示例集)
- [第 2 章 安装、启动器与命令行](ch02-install-launcher-cli.md)
  - [2.1 获取 SDK](ch02-install-launcher-cli.md#21-获取-sdk)
  - [2.2 启动器（Launcher）](ch02-install-launcher-cli.md#22-启动器launcher)
  - [2.3 命令行接口（CLI）](ch02-install-launcher-cli.md#23-命令行接口cli)
  - [2.4 创建项目与模板文件](ch02-install-launcher-cli.md#24-创建项目与模板文件)
- [第 3 章 第一个游戏：对话与角色](ch03-first-game.md)
  - [3.1 最小可运行游戏](ch03-first-game.md#31-最小可运行游戏)
  - [3.2 对话的四种写法与转义](ch03-first-game.md#32-对话的四种写法与转义)
  - [3.3 Character 对象](ch03-first-game.md#33-character-对象)
  - [3.4 完整的第一个游戏（示例 01）](ch03-first-game.md#34-完整的第一个游戏示例-01)
- [第 4 章 图像与舞台](ch04-images-and-stage.md)
  - [4.1 图像名：tag 与 attribute](ch04-images-and-stage.md#41-图像名tag-与-attribute)
  - [4.2 自动图像定义与 image 语句](ch04-images-and-stage.md#42-自动图像定义与-image-语句)
  - [4.3 show / scene / hide：舞台三剑客](ch04-images-and-stage.md#43-show--scene--hide舞台三剑客)
  - [4.4 show 的完整子句](ch04-images-and-stage.md#44-show-的完整子句)
  - [4.5 位置：at 与预定义位置](ch04-images-and-stage.md#45-位置at-与预定义位置)
  - [4.6 层（layers）与 camera](ch04-images-and-stage.md#46-层layers与-camera)
  - [4.7 小结与实践](ch04-images-and-stage.md#47-小结与实践)

### 第二部分 剧本语言篇

- [第 5 章 标签与控制流](ch05-labels-and-flow.md)
  - [5.1 label：剧本的路标](ch05-labels-and-flow.md#51-label剧本的路标)
  - [5.2 jump 与 call：单程票与往返票](ch05-labels-and-flow.md#52-jump-与-call单程票与往返票)
  - [5.3 call ... from：给返回点起一个稳定的名字](ch05-labels-and-flow.md#53-call--from给返回点起一个稳定的名字)
  - [5.4 call 带参数与 expression 跳转](ch05-labels-and-flow.md#54-call-带参数与-expression-跳转)
  - [5.5 pass：什么都不做的语句](ch05-labels-and-flow.md#55-pass什么都不做的语句)
  - [5.6 while：剧本里唯一的循环](ch05-labels-and-flow.md#56-while剧本里唯一的循环)
  - [5.7 特殊 label 一览](ch05-labels-and-flow.md#57-特殊-label-一览)
  - [5.8 小结与实践](ch05-labels-and-flow.md#58-小结与实践)
- [第 6 章 菜单、变量与分支](ch06-menus-and-variables.md)
  - [6.1 menu 语句的完整形态](ch06-menus-and-variables.md#61-menu-语句的完整形态)
  - [6.2 条件项与灰显](ch06-menus-and-variables.md#62-条件项与灰显)
  - [6.3 选项块里能做什么，以及"汇合"写法](ch06-menus-and-variables.md#63-选项块里能做什么以及汇合写法)
  - [6.4 set：让选项只出现一次](ch06-menus-and-variables.md#64-set让选项只出现一次)
  - [6.5 define、default、$：三种赋值，三种命运](ch06-menus-and-variables.md#65-definedefault三种赋值三种命运)
  - [6.6 综合示例：三题问答](ch06-menus-and-variables.md#66-综合示例三题问答)
  - [6.7 小结与实践](ch06-menus-and-variables.md#67-小结与实践)
- [第 7 章 对话进阶与文本](ch07-text-and-dialogue.md)
  - [7.1 Character 的进阶参数](ch07-text-and-dialogue.md#71-character-的进阶参数)
  - [7.2 say 附加参数（say with arguments）](ch07-text-and-dialogue.md#72-say-附加参数say-with-arguments)
  - [7.3 extend：接着上一句说](ch07-text-and-dialogue.md#73-extend接着上一句说)
  - [7.4 Monologue：三引号多段独白](ch07-text-and-dialogue.md#74-monologue三引号多段独白)
  - [7.5 文本插值与转换旗标](ch07-text-and-dialogue.md#75-文本插值与转换旗标)
  - [7.6 文本标签（text tags）](ch07-text-and-dialogue.md#76-文本标签text-tags)
  - [7.7 转义：\[\[、{{、%%](ch07-text-and-dialogue.md#77-转义)
  - [7.8 screen 里的文本（预告）](ch07-text-and-dialogue.md#78-screen-里的文本预告)
  - [7.9 小结与实践](ch07-text-and-dialogue.md#79-小结与实践)
- [第 8 章 NVL 模式](ch08-nvl-mode.md)
  - [8.1 两种呈现：ADV 与 NVL](ch08-nvl-mode.md#81-两种呈现adv-与-nvl)
  - [8.2 定义 NVL 角色](ch08-nvl-mode.md#82-定义-nvl-角色)
  - [8.3 nvl clear：翻页](ch08-nvl-mode.md#83-nvl-clear翻页)
  - [8.4 NVL 菜单](ch08-nvl-mode.md#84-nvl-菜单)
  - [8.5 ADV 与 NVL 混用](ch08-nvl-mode.md#85-adv-与-nvl-混用)
  - [8.6 小结与实践](ch08-nvl-mode.md#86-小结与实践)

### 第三部分 演出篇

- [第 9 章 音频与视频](ch09-audio-and-video.md)
  - [9.1 通道模型与三大语句](ch09-audio-and-video.md#91-通道模型与三大语句)
  - [9.2 audio namespace：给音频起名字](ch09-audio-and-video.md#92-audio-namespace给音频起名字)
  - [9.3 播放列表、静音与播放位置](ch09-audio-and-video.md#93-播放列表静音与播放位置)
  - [9.4 音频滤镜（8.4+）](ch09-audio-and-video.md#94-音频滤镜84)
  - [9.5 视频](ch09-audio-and-video.md#95-视频)
  - [9.6 小结与实践](ch09-audio-and-video.md#96-小结与实践)
- [第 10 章 ATL 与 transform](ch10-atl-and-transform.md)
  - [10.1 ATL 是什么](ch10-atl-and-transform.md#101-atl-是什么)
  - [10.2 最小示例与逐行解读](ch10-atl-and-transform.md#102-最小示例与逐行解读)
  - [10.3 warper：运动的"缓动曲线"](ch10-atl-and-transform.md#103-warper运动的缓动曲线)
  - [10.4 常用变换属性](ch10-atl-and-transform.md#104-常用变换属性)
  - [10.5 复合结构：parallel、choice、on、time、function](ch10-atl-and-transform.md#105-复合结构parallelchoiceontimefunction)
  - [10.6 ATL 定义 image：帧动画](ch10-atl-and-transform.md#106-atl-定义-image帧动画)
  - [10.7 小结与实践](ch10-atl-and-transform.md#107-小结与实践)
- [第 11 章 转场](ch11-transitions.md)
  - [11.1 with 语句与预定义转场](ch11-transitions.md#111-with-语句与预定义转场)
  - [11.2 绑定规则：with 属于"它前面的变化"](ch11-transitions.md#112-绑定规则with-属于它前面的变化)
  - [11.3 转场类：定制你自己的过渡](ch11-transitions.md#113-转场类定制你自己的过渡)
  - [11.4 字典转场：一层一个效果](ch11-transitions.md#114-字典转场一层一个效果)
  - [11.5 转场与交互](ch11-transitions.md#115-转场与交互)
  - [11.6 小结与实践](ch11-transitions.md#116-小结与实践)
- [第 12 章 Layered Images 立绘系统](ch12-layered-images.md)
  - [12.1 问题：立绘是零件的组合](ch12-layered-images.md#121-问题立绘是零件的组合)
  - [12.2 基本语法](ch12-layered-images.md#122-基本语法)
  - [12.3 if 条件图层与 multiple](ch12-layered-images.md#123-if-条件图层与-multiple)
  - [12.4 与对话属性联动：立绘自动切换](ch12-layered-images.md#124-与对话属性联动立绘自动切换)
  - [12.5 免素材演示：attribute 直接挂 displayable](ch12-layered-images.md#125-免素材演示attribute-直接挂-displayable)
  - [12.6 小结与实践](ch12-layered-images.md#126-小结与实践)

### 第四部分 界面篇

剧本语言回答的是"什么时候说什么话、什么时候切场景"，而界面的部分——主菜单、存读档、设置页、提示气泡、游戏内 HUD——则交给 **screen 语言**。screen 语言是 Ren'Py 里最像"真正的编程语言"的一块：它是**声明式**的。你不再按顺序指挥引擎"先画这个、再画那个"，而是描述"界面上此刻应该有什么"；引擎在每一帧、每次变量变化之后自动重新计算并绘制。也正因为如此，当某个变量改变时，界面会自动刷新——你不需要、也不应该手写任何"刷新界面"的代码。

- [第 13 章 Screen 语言基础](ch13-screen-basics.md)
  - [13.1 第一个 screen：一块会自己更新的面板](ch13-screen-basics.md#131-第一个-screen一块会自己更新的面板)
  - [13.2 call screen：让界面成为一次"提问"](ch13-screen-basics.md#132-call-screen让界面成为一次提问)
  - [13.3 容器与定位：fixed、hbox、vbox、grid、frame](ch13-screen-basics.md#133-容器与定位fixedhboxvboxgridframe)
  - [13.4 常用显示物一览](ch13-screen-basics.md#134-常用显示物一览)
  - [13.5 screen 的参数与屏幕作用域](ch13-screen-basics.md#135-screen-的参数与屏幕作用域)
  - [13.6 use 与 transclude：把 screen 当组件拼装](ch13-screen-basics.md#136-use-与-transclude把-screen-当组件拼装)
  - [13.7 if 与 for：随数据生长的界面](ch13-screen-basics.md#137-if-与-for随数据生长的界面)
  - [13.8 screen 语句的修饰参数](ch13-screen-basics.md#138-screen-语句的修饰参数)
  - [13.9 综合实战：一张活着的 HUD](ch13-screen-basics.md#139-综合实战一张活着的-hud)
  - [13.10 小结与实践](ch13-screen-basics.md#1310-小结与实践)
- [第 14 章 Screen 动作与数据绑定](ch14-screen-actions.md)
  - [14.1 action 是按钮的灵魂：三态模型](ch14-screen-actions.md#141-action-是按钮的灵魂三态模型)
  - [14.2 流程动作：让按钮指挥剧本](ch14-screen-actions.md#142-流程动作让按钮指挥剧本)
  - [14.3 场景动作：Show / Hide / ShowTransient](ch14-screen-actions.md#143-场景动作show--hide--showtransient)
  - [14.4 数据动作：一行改一个变量](ch14-screen-actions.md#144-数据动作一行改一个变量)
  - [14.5 Function 动作：点击时执行任意 Python 函数](ch14-screen-actions.md#145-function-动作点击时执行任意-python-函数)
  - [14.6 存读档动作：自建一个存档界面](ch14-screen-actions.md#146-存读档动作自建一个存档界面)
  - [14.7 Preference 动作：接住玩家的偏好设置](ch14-screen-actions.md#147-preference-动作接住玩家的偏好设置)
  - [14.8 动作修饰器：SelectedIf、SensitiveIf、InvertSelected](ch14-screen-actions.md#148-动作修饰器selectedifsensitiveifinvertselected)
  - [14.9 悬浮提示：tooltip 属性与 GetTooltip](ch14-screen-actions.md#149-悬浮提示tooltip-属性与-gettooltip)
  - [14.10 综合实战：道具商店](ch14-screen-actions.md#1410-综合实战道具商店)
  - [14.11 小结与实践](ch14-screen-actions.md#1411-小结与实践)
- [第 15 章 特殊屏幕与菜单定制](ch15-special-screens.md)
  - [15.1 十三个特殊屏幕总览](ch15-special-screens.md#151-十三个特殊屏幕总览)
  - [15.2 say 屏幕：每句对话都从这过](ch15-special-screens.md#152-say-屏幕每句对话都从这过)
  - [15.3 choice 屏幕：选项按钮的生产线](ch15-special-screens.md#153-choice-屏幕选项按钮的生产线)
  - [15.4 input 屏幕：renpy.input 的前台](ch15-special-screens.md#154-input-屏幕renpyinput-的前台)
  - [15.5 notify 屏幕：两秒钟的轻反馈](ch15-special-screens.md#155-notify-屏幕两秒钟的轻反馈)
  - [15.6 skip_indicator 与 ctc：快进指示与点击继续](ch15-special-screens.md#156-skip_indicator-与-ctc快进指示与点击继续)
  - [15.7 主菜单、导航栏与游戏菜单框架](ch15-special-screens.md#157-主菜单导航栏与游戏菜单框架)
  - [15.8 存读档界面：save、load 与 file_slots](ch15-special-screens.md#158-存读档界面saveload-与-file_slots)
  - [15.9 confirm：确认对话框](ch15-special-screens.md#159-confirm确认对话框)
  - [15.10 界面样式基础：style 语句与 gui 变量体系](ch15-special-screens.md#1510-界面样式基础style-语句与-gui-变量体系)
  - [15.11 本章小结与示例工程](ch15-special-screens.md#1511-本章小结与示例工程)

### 第五部分 状态篇

- [第 16 章 变量、存档与回滚](ch16-save-and-rollback.md)
  - [16.1 变量的家：store 命名空间](ch16-save-and-rollback.md#161-变量的家store-命名空间)
  - [16.2 存档到底存了什么](ch16-save-and-rollback.md#162-存档到底存了什么)
  - [16.3 直接操作存档的 Python API](ch16-save-and-rollback.md#163-直接操作存档的-python-api)
  - [16.4 存档的边界：什么存不进去](ch16-save-and-rollback.md#164-存档的边界什么存不进去)
  - [16.5 回滚：时间倒流是怎么实现的](ch16-save-and-rollback.md#165-回滚时间倒流是怎么实现的)
  - [16.6 综合实战：带“剧情存档”的章节推进](ch16-save-and-rollback.md#166-综合实战带剧情存档的章节推进)
  - [16.7 小结与实践](ch16-save-and-rollback.md#167-小结与实践)
- [第 17 章 持久化：persistent 与跨周目数据](ch17-persistent.md)
  - [17.1 persistent 对象的基本用法](ch17-persistent.md#171-persistent-对象的基本用法)
  - [17.2 已读系统：文本跳过与解锁检查](ch17-persistent.md#172-已读系统文本跳过与解锁检查)
  - [17.3 偏好设置的存放处：persistent._preferences](ch17-persistent.md#173-偏好设置的存放处persistent_preferences)
  - [17.4 MultiPersistent：跨游戏共享数据](ch17-persistent.md#174-multipersistent跨游戏共享数据)
  - [17.5 综合实战：结局收集与标题界面联动](ch17-persistent.md#175-综合实战结局收集与标题界面联动)
  - [17.6 小结与实践](ch17-persistent.md#176-小结与实践)
- [第 18 章 Python 语句与引擎 API](ch18-python-and-engine-api.md)
  - [18.1 四种 Python 代码的执行时机](ch18-python-and-engine-api.md#181-四种-python-代码的执行时机)
  - [18.2 剧本里调用引擎：API 分区地图](ch18-python-and-engine-api.md#182-剧本里调用引擎api-分区地图)
  - [18.3 屏幕与 Python 的边界面](ch18-python-and-engine-api.md#183-屏幕与-python-的边界面)
  - [18.4 随机数与回滚：确定性随机](ch18-python-and-engine-api.md#184-随机数与回滚确定性随机)
  - [18.5 存档安全的 Python 写法](ch18-python-and-engine-api.md#185-存档安全的-python-写法)
  - [18.6 综合实战：事件驱动的属性系统](ch18-python-and-engine-api.md#186-综合实战事件驱动的属性系统)
  - [18.7 小结与实践](ch18-python-and-engine-api.md#187-小结与实践)

### 第六部分 专题篇

前五部分教你的是“零件”：label、屏幕、样式、动作、存档、持久化。第六部分开始把这些零件组装成玩家真正叫得出名字的“成品功能”：

- 第 19 章 输入与对话历史——玩家输入名字、翻看之前的对话；
- 第 20 章 画廊、音乐室与回放——通关后的收集要素；
- 第 21 章 开场动画与游戏生命周期——从双击图标到进入游戏之间发生的一切。

这些功能没有一样需要新语法，它们全部由你已经掌握的东西拼成：屏幕 + 动作 + persistent + 特殊 label。学完本章你应该能感觉到：Ren'Py 的“功能”和“积木”之间没有界限。

- [第 19 章 输入与对话历史](ch19-input-and-history.md)
  - [19.1 renpy.input：一行代码要来一个名字](ch19-input-and-history.md#191-renpyinput一行代码要来一个名字)
  - [19.2 输入的幕后：交互、回滚与 show_ 前缀](ch19-input-and-history.md#192-输入的幕后交互回滚与-show_-前缀)
  - [19.3 InputValue：屏幕里的常驻输入框](ch19-input-and-history.md#193-inputvalue屏幕里的常驻输入框)
  - [19.4 对话历史的数据：_history_list 与 HistoryEntry](ch19-input-and-history.md#194-对话历史的数据_history_list-与-historyentry)
  - [19.5 history 屏幕：官方模板逐行拆解](ch19-input-and-history.md#195-history-屏幕官方模板逐行拆解)
  - [19.6 三种常见改造](ch19-input-and-history.md#196-三种常见改造)
  - [19.7 综合实战：角色登记表单](ch19-input-and-history.md#197-综合实战角色登记表单)
  - [19.8 小结与实践](ch19-input-and-history.md#198-小结与实践)
- [第 20 章 画廊、音乐室与回放](ch20-gallery-music-replay.md)
  - [20.1 回放：Replay 与 EndReplay](ch20-gallery-music-replay.md#201-回放replay-与-endreplay)
  - [20.2 音乐室：MusicRoom 类](ch20-gallery-music-replay.md#202-音乐室musicroom-类)
  - [20.3 画廊：persistent 集合 + 分页网格](ch20-gallery-music-replay.md#203-画廊persistent-集合--分页网格)
  - [20.4 综合实战：收集品菜单（extras）](ch20-gallery-music-replay.md#204-综合实战收集品菜单extras)
  - [20.5 小结与实践](ch20-gallery-music-replay.md#205-小结与实践)
- [第 21 章 开场动画与游戏生命周期](ch21-splash-and-lifecycle.md)
  - [21.1 生命周期的引擎骨架：一个 `while True`](ch21-splash-and-lifecycle.md#211-生命周期的引擎骨架一个-while-true)
  - [21.2 `_start`：每一轮的零点](ch21-splash-and-lifecycle.md#212-_start每一轮的零点)
  - [21.3 splashscreen：只播一次的开机画面](ch21-splash-and-lifecycle.md#213-splashscreen只播一次的开机画面)
  - [21.4 主菜单：从 `_invoke_main_menu` 到你写的屏幕](ch21-splash-and-lifecycle.md#214-主菜单从-_invoke_main_menu-到你写的屏幕)
  - [21.5 Start、MainMenu 与 `_restart`：四条回路](ch21-splash-and-lifecycle.md#215-startmainmenu-与-_restart四条回路)
  - [21.6 读档：两个阶段、一次上下文切换](ch21-splash-and-lifecycle.md#216-读档两个阶段一次上下文切换)
  - [21.7 综合实战：`19_lifecycle` 生命周期演示](ch21-splash-and-lifecycle.md#217-综合实战19_lifecycle-生命周期演示)
  - [21.8 本章小结与实践](ch21-splash-and-lifecycle.md#218-本章小结与实践)

### 第七部分 工程篇

第六部分把零件组装成了“成品功能”；第七部分回到工程视角：当代码越写越多，你面对的不再是一个 `script.rpy`，而是目录结构、初始化顺序、配置项、调试工具与发布流水线。本部分按“组织 → 调试 → 发布”的顺序，把一个 Ren'Py 工程从源码目录一路带到玩家手里的安装包。

- [第 22 章 项目组织与配置：从目录到 settings](ch22-project-and-config.md)
  - [22.1 一个工程的目录结构](ch22-project-and-config.md#221-一个工程的目录结构)
  - [22.2 init 与执行顺序：谁先谁后，由什么决定](ch22-project-and-config.md#222-init-与执行顺序谁先谁后由什么决定)
  - [22.3 目录与文件：哪些是自动的，哪些是你必须管的](ch22-project-and-config.md#223-目录与文件哪些是自动的哪些是你必须管的)
  - [22.4 options.rpy：一个工程的设置中心](ch22-project-and-config.md#224-optionsrpy一个工程的设置中心)
  - [22.5 本章小结与实践](ch22-project-and-config.md#225-本章小结与实践)
- [第 23 章 调试与自动化测试](ch23-debug-and-testing.md)
  - [23.1 开发者模式：先打开总开关](ch23-debug-and-testing.md#231-开发者模式先打开总开关)
  - [23.2 开发者快捷键：一张必须记住的表](ch23-debug-and-testing.md#232-开发者快捷键一张必须记住的表)
  - [23.3 控制台：运行中的“Python 交互式窗口”](ch23-debug-and-testing.md#233-控制台运行中的python-交互式窗口)
  - [23.4 Lint：不运行游戏就能发现的问题](ch23-debug-and-testing.md#234-lint不运行游戏就能发现的问题)
  - [23.5 命令行工具：`renpy.sh` 的全貌](ch23-debug-and-testing.md#235-命令行工具renpysh-的全貌)
  - [23.6 自动化测试：让游戏自己走一遍](ch23-debug-and-testing.md#236-自动化测试让游戏自己走一遍)
  - [23.7 `add_from`：给 `call` 补上 `from` 子句](ch23-debug-and-testing.md#237-add_from给-call-补上-from-子句)
  - [23.8 本章小结与实践](ch23-debug-and-testing.md#238-本章小结与实践)
- [第 24 章 构建与发布](ch24-build-and-distribution.md)
  - [24.1 构建系统做了什么](ch24-build-and-distribution.md#241-构建系统做了什么)
  - [24.2 基础配置：三个核心变量](ch24-build-and-distribution.md#242-基础配置三个核心变量)
  - [24.3 特殊文件：图标](ch24-build-and-distribution.md#243-特殊文件图标)
  - [24.4 文件分类：`build.classify` 与七个文件列表](ch24-build-and-distribution.md#244-文件分类buildclassify-与七个文件列表)
  - [24.5 文档与可执行标记](ch24-build-and-distribution.md#245-文档与可执行标记)
  - [24.6 归档：`build.archive`](ch24-build-and-distribution.md#246-归档buildarchive)
  - [24.7 自定义包：`build.package`](ch24-build-and-distribution.md#247-自定义包buildpackage)
  - [24.8 构建信息：`build.time` 与 `build.info`](ch24-build-and-distribution.md#248-构建信息buildtime-与-buildinfo)
  - [24.9 高级配置变量全表](ch24-build-and-distribution.md#249-高级配置变量全表)
  - [24.10 `old-game` 目录：让更新不坏档](ch24-build-and-distribution.md#2410-old-game-目录让更新不坏档)
  - [24.11 目标平台的最低要求](ch24-build-and-distribution.md#2411-目标平台的最低要求)
  - [24.12 发布前清单](ch24-build-and-distribution.md#2412-发布前清单)
  - [24.13 其他平台](ch24-build-and-distribution.md#2413-其他平台)
  - [24.14 本章小结与实践](ch24-build-and-distribution.md#2414-本章小结与实践)

### 附录

- [附录 A 示例集总览与构建方法](appendix-a-examples.md)
  - [A.1 示例一览](appendix-a-examples.md#a1-示例一览)
  - [A.2 最小工程为什么能跑起来](appendix-a-examples.md#a2-最小工程为什么能跑起来)
  - [A.3 编译与验证](appendix-a-examples.md#a3-编译与验证)
  - [A.4 批量脚本](appendix-a-examples.md#a4-批量脚本)
