' 18_gfx.bas —— 内置 GFX 图形库：开窗、绘图原语、离屏图、像素校验、自动退出
' 编译：fbc -w all -g -exx 18_gfx.bas -x 18_gfx.exe
' 运行会短暂弹出 320x200 图形窗口约 1.2 秒后自动关闭（验证友好设计）。
' 关键纪律：ScreenRes 之后 Print 进图形窗——要往真控制台输出用 Open Cons。

Const W As Integer = 320
Const H As Integer = 200

' ---- 0) 控制台输出通道先备好（文件号必须 >= 1，FreeFile 拿号）----
Dim As Integer con = FreeFile()
Open Cons For Output As #con

ScreenRes W, H, 32                     ' 32bpp 窗口模式
WindowTitle "FB GFX demo（自动关闭）"

' ---- 1) 基本原语：Cls / Line / Circle / PSet ----
Cls                                    ' 清屏（32bpp 下 Cls 的颜色参数实测不生效，清成黑）
Line (10, 10)-(100, 100), RGB(255, 0, 0), bf      ' 实心矩形（bf = box fill）
Line (10, 10)-(100, 100), RGB(255, 255, 255)      ' 无 B 后缀 = 对角线！不是边框
Line (10, 10)-(100, 100), RGB(0, 0, 0), B         ' B 才是矩形边框
Circle (160, 60), 40, RGB(0, 255, 0)              ' 圆
Circle (160, 60), 40, RGB(0, 200, 0), , , 0.5     ' 椭圆（纵横比参数）
PSet (55, 55), RGB(255, 255, 0)                   ' 单像素
Draw String (20, 150), "Hello GFX!", RGB(255, 255, 255)   ' 图形模式文字

' ---- 2) 像素校验：Point 读回颜色（32bpp 全线 0xAARRGGBB）----
Var c1 = Point(30, 70)                 ' 红色实心矩形内部（避开黑边框）
Var c2 = Point(160, 10)                ' 圆顶(y=20)之上 → Cls 黑底
Print #con, "Point(30,70)  = 0x"; Hex(c1)
Print #con, "Point(160,10) = 0x"; Hex(c2)
Print #con, "RGB(255,0,0)  = 0x"; Hex(CULng(RGB(255, 0, 0))); "（RGB 宏本身带 FF alpha）"
Assert(c1 = &hFFFF0000)                ' ARGB：不透明红
Assert(c2 = &hFF000000)                ' 不透明黑

' ---- 3) 离屏图：ImageCreate 画好再 Put 上屏 ----
Dim As Any Ptr img = ImageCreate(80, 60, RGB(0, 0, 0))
Circle img, (40, 30), 25, RGB(0, 128, 255), , , , F   ' 填充圆（F 后缀）
Line img, (5, 50)-(75, 50), RGB(255, 255, 255)
Put (220, 20), img, PSet               ' 贴到屏幕
' 离屏图上的 Point 用图像自身坐标系（第三参传 img）
Var c3 = Point(40, 30, img)
Print #con, "离屏图中心 Point(40,30,img) = 0x"; Hex(c3)
Assert(c3 = &hFF0080FF)                ' ARGB：不透明蓝 (0,128,255)
ImageDestroy img

' ---- 4) 键盘：Inkey 非阻塞（无人按键时返回空串）----
Var k = Inkey
Print #con, "Inkey（自动模式无按键）= ["; k; "]"
Assert(k = "")

Sleep 1200                             ' 展示 1.2 秒后自动退出（Sleep 毫秒不等人按键）
Screen 0                               ' 回文本模式（礼貌收尾）

Print #con, "[OK] 18_gfx"
Close #con
End 0
