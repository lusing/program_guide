# 18 · ⭐GFX：内置图形库

> 对应示例：`examples/18_gfx/`（运行弹 320×200 窗口约 1.2 秒后自动关闭）

FB 的独门武器：**gfxlib2 内置图形库**——`ScreenRes` 一句开窗，画线画圆读像素，零第三方依赖、零安装、跨 Windows/Linux。这是"单文件 EXE 画出东西"的最短路径，也是很多人留在这门语言的理由。

## 18.1 开窗与控制台纪律 ⭐

```freebasic
ScreenRes 320, 200, 32              ' 宽、高、色深
WindowTitle "FB GFX demo"
...
Sleep 1200                           ' 展示 1.2 秒
Screen 0                             ' 回文本模式
```

**大坑：`ScreenRes` 之后 `Print` 不再进控制台**——输出进图形窗口自己的文字层（还会把画好的图顶掉一行）。要往真控制台写（日志、验证输出）：

```freebasic
Dim As Integer con = FreeFile()      ' 文件号必须 >= 1（0 是非法号，实测 runtime error 1）
Open Cons For Output As #con
Print #con, "这条到控制台"
Close #con
```

## 18.2 绘图原语

```freebasic
Cls                                          ' 清屏（实测：32bpp 下 Cls 的颜色参数不生效，清成黑）
Line (10,10)-(100,100), RGB(255,0,0), bf     ' 实心矩形（bf = box filled）
Line (10,10)-(100,100), RGB(0,0,0), B        ' B = 矩形边框
Line (10,10)-(100,100), RGB(255,255,255)     ' ⚠ 无 B = 对角线！不是边框
Circle (160,60), 40, RGB(0,255,0)            ' 圆
Circle (160,60), 40, RGB(0,200,0), , , 0.5   ' 椭圆（纵横比 0.5）
Circle img, (40,30), 25, col, , , , F        ' F = 填充（前缀 F 在参数末尾）
PSet (55,55), RGB(255,255,0)                 ' 单像素
Draw String (20,150), "文字", RGB(255,255,255) ' 图形模式文字（默认 8x8 字体）
```

## 18.3 颜色：全线 0xAARRGGBB ⭐

```freebasic
Print Hex(CULng(RGB(255,0,0)))       ' FFFF0000 —— RGB 宏自带 FF alpha
Var c = Point(30, 70)                ' 读像素：32bpp 返回 0xAARRGGBB
```

实测：**`RGB()` 宏返回的已经是 `0xAARRGGBB`（alpha=FF）**，`Point()` 读回的也是同一格式——比较时直接 `Assert(c = &hFFFF0000)`，不用关心字节序（网上老教程说的 0xBBGGRR 是 16bpp 时代的事）。

## 18.4 离屏图：ImageCreate / Put

```freebasic
Dim As Any Ptr img = ImageCreate(80, 60, RGB(0,0,0))
Circle img, (40,30), 25, RGB(0,128,255), , , , F   ' 画到离屏图
Put (220, 20), img, PSet                             ' 一次贴上屏
Var c = Point(40, 30, img)                           ' ⚠ 坐标是图像自己的坐标系
ImageDestroy img
```

精灵、双缓冲、图块缓存的标准套路：离屏画好，`Put` 上屏。`Point` 带第三参时坐标**相对图像左上角**——我拿屏幕坐标去读图像，直接越界返回 -1（亲踩）。

## 18.5 键盘与事件

```freebasic
Var k = Inkey        ' 非阻塞读键：无按键返回 ""，有则返回单/双字节串
Sleep                ' 无参 = 等任意键
Sleep 1000           ' 带 ms = 限时（到点或按键即续）
GetKey               ' 阻塞读一键（返回键码）
MultiKey(SC_LEFT)    ' 查询键按下状态（做连续移动，如贪吃蛇）
```

24 章贪吃蛇用 `MultiKey` 做非阻塞输入。

## 18.6 验证友好的 gfx 程序设计

自动化验证图形程序的三个纪律（本教程全部示例遵守）：

1. **限时自退**：`Sleep 固定毫秒` 而非等人按键；
2. **输出走 `Open Cons`**：判定脚本看得到结果；
3. **用 `Point` 做像素断言**：画了什么，读回什么，`Assert` 收尾。

窗口会在验证时一闪而过——这是特性不是 bug。

## 18.7 坑位清单（1.10.1 实测）

1. `ScreenRes` 后 `Print` 进图形窗——控制台输出必须 `Open Cons`。
2. **无 `B` 的 `Line (a)-(b), c` 画的是对角线**；矩形框要 `B`，实心要 `BF/bf`。
3. `RGB()` 与 `Point()` 统一 `0xAARRGGBB`（alpha FF），别信老教程的 BGR 说法（那是 16bpp）。
4. `Point(x, y, img)` 的坐标是**图像自身坐标系**。
5. `Cls` 的颜色参数在 32bpp 实测不生效——清成黑；要底色就画个满屏 `bf` 矩形。
6. 文件号从 `FreeFile()` 拿——`Dim h As Integer`（值 0）直接 `As #h` = runtime error 1。
7. `Sleep ms` 到点**或按键**即返回；纯限时不想被按键打断的场景自己记起止时间。
8. **Linux 上 gfxlib2 走 X11**（`DISPLAY` 必须有效；WSL2 需 WSLg，headless CI 用 `xvfb-run` 包一层）——WSLg 实测开窗/像素读写全过。
