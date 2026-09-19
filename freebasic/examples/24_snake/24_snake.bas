' 24_snake.bas —— 实战收官：贪吃蛇（GFX 动画 + 确定性演示 AI + 双模式 + 最高分文件 + 自测）
' 编译：fbc -w all -g -exx 24_snake.bas -x 24_snake.exe
#Include Once "fbgfx.bi"            ' SC_LEFT 等键码常量
Using FB                             ' ⚠ fbgfx.bi 的常量包在 namespace FB 里（实测坑）

' 默认 = 演示模式：种子固定、AI 自动觅食、吃完 8 个食物或到帧上限自动退出（验证友好）
'   24_snake.exe --play   交互模式：方向键/WASD 操控

Const GW As Integer = 24              ' 网格列数
Const GH As Integer = 18              ' 网格行数
Const CELL As Integer = 16            ' 像素/格
Const TARGET_FOOD As Integer = 8      ' 演示模式吃够几个收工
Const MAX_FRAMES As Integer = 500     ' 帧上限（防挂死）
Const DEMO_SEED As Integer = 7        ' 确定性种子：同种子 = 同局
Const HIGHSCORE_FILE As String = "fb_snake_high.txt"

Enum Dir
    D_UP
    D_DOWN
    D_LEFT
    D_RIGHT
End Enum

' ---- 蛇身：环形缓冲（定长数组 + 头尾指针，避免每步搬移）----
Type Game
    bodyX(0 To GW * GH - 1) As Integer
    bodyY(0 To GW * GH - 1) As Integer
    headIdx As Integer                ' 头在环形缓冲里的下标
    length_ As Integer
    dir_ As Integer
    foodX As Integer
    foodY As Integer
    eaten As Integer
    alive As Boolean
    frames As Integer
End Type

Dim Shared As Integer con             ' 控制台输出通道（gfx 模式 Print 不进控制台）

Sub gInit(ByRef g As Game, startDir As Integer)
    g.length_ = 4
    g.headIdx = g.length_ - 1
    For i As Integer = 0 To g.length_ - 1
        g.bodyX(g.headIdx - i) = 8 - i     ' 头在 (8, 9)，向右
        g.bodyY(g.headIdx - i) = 9
    Next
    g.dir_ = startDir
    g.eaten = 0
    g.alive = True
    g.frames = 0
End Sub

' ---- 食物：只依赖 Rnd —— 种子固定则整局确定 ----
Sub placeFood(ByRef g As Game)
    Do
        Var fx = Int(Rnd * GW)
        Var fy = Int(Rnd * GH)
        Var onBody = False
        For i As Integer = 0 To g.length_ - 1
            Var idx = (g.headIdx - i + GW * GH) Mod (GW * GH)
            If g.bodyX(idx) = fx AndAlso g.bodyY(idx) = fy Then onBody = True
        Next
        If onBody = False Then
            g.foodX = fx : g.foodY = fy
            Exit Do
        End If
    Loop
End Sub

Function onBody(ByRef g As Game, x As Integer, y As Integer) As Boolean
    For i As Integer = 0 To g.length_ - 1
        Var idx = (g.headIdx - i + GW * GH) Mod (GW * GH)
        If g.bodyX(idx) = x AndAlso g.bodyY(idx) = y Then Return True
    Next
    Return False
End Function

' ---- 一步前进（含吃食/撞己判定）；边界环绕 ----
Sub gStep(ByRef g As Game)
    Dim nx As Integer = g.bodyX(g.headIdx)
    Dim ny As Integer = g.bodyY(g.headIdx)
    Select Case g.dir_
    Case D_UP    : ny = (ny + GH - 1) Mod GH
    Case D_DOWN  : ny = (ny + 1) Mod GH
    Case D_LEFT  : nx = (nx + GW - 1) Mod GW
    Case D_RIGHT : nx = (nx + 1) Mod GW
    End Select

    If onBody(g, nx, ny) Then          ' 撞到自己（尾巴即将让位的那格除外）
        g.alive = False
        Return
    End If

    g.headIdx = (g.headIdx + 1) Mod (GW * GH)
    g.bodyX(g.headIdx) = nx
    g.bodyY(g.headIdx) = ny

    If nx = g.foodX AndAlso ny = g.foodY Then
        g.length_ += 1
        g.eaten += 1
        Print #con, "  吃到第 "; g.eaten; " 个食物 @ ("; nx; ","; ny; ")"
        If g.eaten < GW * GH Then placeFood(g)
    End If
End Sub

' ---- 演示 AI：包边距离贪心 + 撞体回避 ----
Function wrapDelta(d As Integer, n As Integer) As Integer
    If d > n \ 2 Then d -= n
    If d < -(n \ 2) Then d += n
    Return d
End Function

Sub demoThink(ByRef g As Game)
    Dim As Integer hx = g.bodyX(g.headIdx), hy = g.bodyY(g.headIdx)
    Var dx = wrapDelta(g.foodX - hx, GW)
    Var dy = wrapDelta(g.foodY - hy, GH)

    Dim cand(0 To 2) As Integer        ' 贪心主方向、备选轴、维持原向
    If Abs(dx) >= Abs(dy) Then
        cand(0) = Iif(dx > 0, D_RIGHT, D_LEFT)
        cand(1) = Iif(dy > 0, D_DOWN, D_UP)
    Else
        cand(0) = Iif(dy > 0, D_DOWN, D_UP)
        cand(1) = Iif(dx > 0, D_RIGHT, D_LEFT)
    End If
    cand(2) = g.dir_

    Dim As Integer nx = hx, ny = hy
    For c As Integer = 0 To 2
        Select Case cand(c)
        Case D_UP    : ny = (hy + GH - 1) Mod GH : nx = hx
        Case D_DOWN  : ny = (hy + 1) Mod GH      : nx = hx
        Case D_LEFT  : nx = (hx + GW - 1) Mod GW : ny = hy
        Case D_RIGHT : nx = (hx + 1) Mod GW      : ny = hy
        End Select
        ' 反向不掉头（长度 > 1 时）
        If g.length_ > 1 Then
            Var neck = (g.headIdx - 1 + GW * GH) Mod (GW * GH)
            If g.bodyX(neck) = nx AndAlso g.bodyY(neck) = ny Then Continue For
        End If
        If onBody(g, nx, ny) = False Then
            g.dir_ = cand(c)
            Return
        End If
    Next
    ' 无路可走：保持原向（认命）
End Sub

' ---- 渲染：离屏缓冲一帧画完再上屏（无闪烁）----
Sub drawFrame(ByRef g As Game, back As Any Ptr)
    Line back, (0, 0)-(GW * CELL - 1, GH * CELL - 1), RGB(12, 14, 20), bf
    For x As Integer = 0 To GW
        Line back, (x * CELL, 0)-Step(0, GH * CELL), RGB(24, 26, 34)
    Next
    For y As Integer = 0 To GH
        Line back, (0, y * CELL)-Step(GW * CELL, 0), RGB(24, 26, 34)
    Next
    ' 食物
    Line back, (g.foodX * CELL + 3, g.foodY * CELL + 3)-Step(CELL - 7, CELL - 7), RGB(255, 60, 60), bf
    ' 蛇（头亮尾暗）
    For i As Integer = 0 To g.length_ - 1
        Var idx = (g.headIdx - i + GW * GH) Mod (GW * GH)
        Var shade = 200 - (i * 160 \ 40)
        If shade < 60 Then shade = 60
        Line back, (g.bodyX(idx) * CELL + 1, g.bodyY(idx) * CELL + 1)-Step(CELL - 3, CELL - 3), RGB(0, shade, 120), bf
    Next
    Put (0, 0), back, PSet
End Sub

' ---- 最高分：写、读回、校验、清理（16 章文件 IO 的回马枪）----
Function highscoreRoundtrip(score As Integer) As Boolean
    Dim As Integer h = FreeFile()
    If Open(HIGHSCORE_FILE For Output As #h) <> 0 Then Return False
    Print #h, Str(score)
    Close #h

    Dim As String line_
    h = FreeFile()
    If Open(HIGHSCORE_FILE For Input As #h) <> 0 Then Return False
    Line Input #h, line_
    Close #h

    Kill HIGHSCORE_FILE
    Return (ValInt(line_) = score)
End Function

' ================= 主流程 =================
con = FreeFile()
Open Cons For Output As #con

Dim demoMode As Boolean = True
For i As Integer = 1 To __FB_ARGC__ - 1
    If *__FB_ARGV__[i] = "--play" Then demoMode = False
Next

Randomize DEMO_SEED                   ' 确定性的根：种子固定 → Rnd 序列固定 → 整局固定

ScreenRes GW * CELL, GH * CELL, 32
WindowTitle Iif(demoMode, "贪吃蛇（演示：自动觅食）", "贪吃蛇（方向键/WASD 操控）")
Dim back As Any Ptr = ImageCreate(GW * CELL, GH * CELL)

Dim As Game g
gInit(g, D_RIGHT)
placeFood(g)

Do While g.alive AndAlso g.eaten < TARGET_FOOD AndAlso g.frames < MAX_FRAMES
    If demoMode Then
        demoThink(g)
    Else
        If MultiKey(SC_LEFT)  AndAlso g.dir_ <> D_RIGHT Then g.dir_ = D_LEFT
        If MultiKey(SC_RIGHT) AndAlso g.dir_ <> D_LEFT  Then g.dir_ = D_RIGHT
        If MultiKey(SC_UP)    AndAlso g.dir_ <> D_DOWN  Then g.dir_ = D_UP
        If MultiKey(SC_DOWN)  AndAlso g.dir_ <> D_UP    Then g.dir_ = D_DOWN
    End If
    gStep(g)
    g.frames += 1
    drawFrame(g, back)
    Sleep Iif(demoMode, 15, 60)
Loop

ImageDestroy back
Screen 0

Print #con, "== 局终 =="
Print #con, "存活 ="; g.alive; "  吃到 ="; g.eaten; "  帧数 ="; g.frames; "  蛇长 ="; g.length_
If demoMode Then
    Assert(g.eaten = TARGET_FOOD)     ' 确定性回放：AI 必须吃满 8 个
    Print #con, "确定性回放校验通过（种子 "; DEMO_SEED; "）"
End If

Var hsOk = highscoreRoundtrip(g.eaten * 100 + g.frames)
Print #con, "最高分文件往返 ="; hsOk
Assert(hsOk)

Print #con, "[OK] 24_snake"
Close #con
End 0
