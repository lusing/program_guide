// 20 动画（F# 版）：与 csharp/ 版功能一致（含教材 8.2.3 路径动画）。
// XAML 的 Storyboard.TargetName 在代码里换成 Storyboard.SetTarget(动画, 目标对象)；
// 加载即播的用 window.Loaded 事件里 sb.Begin()。
module AnimationDemoFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Media
open System.Windows.Media.Animation
open System.Windows.Shapes

let brushFromHex (hex: string) =
    ColorConverter.ConvertFromString hex :?> Color |> SolidColorBrush

let header (t: string) = TextBlock(Text = t, FontWeight = FontWeights.Bold, Margin = Thickness(0., 18., 0., 8.))

[<EntryPoint; STAThread>]
let main _ =
    let window = Window(Title = "动画实验室 (F#)", Height = 640., Width = 540.)

    // ① 点击按钮自身变宽（Width 是布局属性，动画它会有重排开销）
    let widenBtn = Button(Content = "点我变宽", Width = 120., Height = 38., HorizontalAlignment = HorizontalAlignment.Left)
    let wa = DoubleAnimation(From = Nullable 120., To = Nullable 260., Duration = Duration(TimeSpan.FromSeconds 0.4))
    Storyboard.SetTarget(wa, widenBtn)
    Storyboard.SetTargetProperty(wa, PropertyPath(Button.WidthProperty))
    let widenSb = Storyboard()
    widenSb.Children.Add wa |> ignore
    widenBtn.Click.Add(fun _ -> widenSb.Begin())

    // ② 同样的效果动画 ScaleTransform——不触发布局，性能更好
    let growScale = ScaleTransform()
    let growBtn = Button(Content = "点我放大", Width = 120., Height = 38.,
                         HorizontalAlignment = HorizontalAlignment.Left, RenderTransformOrigin = Point(0.5, 0.5))
    growBtn.RenderTransform <- growScale
    let growSb = Storyboard()
    for prop in [ ScaleTransform.ScaleXProperty; ScaleTransform.ScaleYProperty ] do
        let a = DoubleAnimation(From = Nullable 1., To = Nullable 2., Duration = Duration(TimeSpan.FromSeconds 0.4))
        Storyboard.SetTarget(a, growScale)
        Storyboard.SetTargetProperty(a, PropertyPath prop)
        growSb.Children.Add a |> ignore
    growBtn.Click.Add(fun _ -> growSb.Begin())

    // ③ 缓动函数对比
    let ballColumn (hex: string) (caption: string) (margin: bool) =
        let move = TranslateTransform()
        let ball = Ellipse(Width = 26., Height = 26., Fill = brushFromHex hex,
                           HorizontalAlignment = HorizontalAlignment.Center, RenderTransform = move)
        let sideMargin = if margin then Thickness(0., 0., 6., 0.) else Thickness()   // 先 let 再传——命名实参里不写 if
        let stage = Border(Height = 200., BorderBrush = brushFromHex "#CBD5E1", BorderThickness = Thickness 1.,
                           Margin = sideMargin, Child = ball)
        let col = StackPanel()
        col.Children.Add stage |> ignore
        col.Children.Add(TextBlock(Text = caption, HorizontalAlignment = HorizontalAlignment.Center,
                                   Margin = Thickness(0., 4., 0., 0.))) |> ignore
        col, move
    let col1, moveLinear = ballColumn "#3B82F6" "Linear 匀速" true
    let col2, moveBounce = ballColumn "#10B981" "Bounce 弹跳" true
    let col3, moveElastic = ballColumn "#EF4444" "Elastic 弹簧" false
    let stages = Grid()
    for _ in 1..3 do stages.ColumnDefinitions.Add(ColumnDefinition()) |> ignore
    Grid.SetColumn(col1, 0); Grid.SetColumn(col2, 1); Grid.SetColumn(col3, 2)
    stages.Children.Add col1 |> ignore
    stages.Children.Add col2 |> ignore
    stages.Children.Add col3 |> ignore

    let dropBtn = Button(Content = "放手", Width = 90., HorizontalAlignment = HorizontalAlignment.Left,
                         Margin = Thickness(0., 0., 0., 8.))
    let drop (move: TranslateTransform) (easing: IEasingFunction) =
        // 纯代码动画：Storyboard 并不神秘，最终都是对依赖属性调 BeginAnimation
        let anim = DoubleAnimation(0., 150., Duration(TimeSpan.FromSeconds 1.6), EasingFunction = easing)
        move.BeginAnimation(TranslateTransform.YProperty, anim)
    dropBtn.Click.Add(fun _ ->
        drop moveLinear null
        drop moveBounce (BounceEase(Bounces = 3, Bounciness = 1.8))
        drop moveElastic (ElasticEase(Oscillations = 3, Springiness = 2.)))

    // ④ 永续动画：加载圈 + 心跳点
    let spinAngle = RotateTransform()
    let ring = Ellipse(Stroke = brushFromHex "#3B82F6", StrokeThickness = 5.,
                       StrokeDashArray = DoubleCollection([ 40.; 100. ]),
                       RenderTransformOrigin = Point(0.5, 0.5))
    ring.RenderTransform <- spinAngle
    let spinner = Grid(Width = 48., Height = 48., Margin = Thickness(0., 0., 24., 0.))
    spinner.Children.Add(Ellipse(Stroke = brushFromHex "#E2E8F0", StrokeThickness = 5.)) |> ignore
    spinner.Children.Add ring |> ignore
    let pulseDot = Ellipse(Width = 18., Height = 18., Fill = brushFromHex "#10B981",
                           VerticalAlignment = VerticalAlignment.Center)
    let foreverRow = StackPanel(Orientation = Orientation.Horizontal)
    foreverRow.Children.Add spinner |> ignore
    foreverRow.Children.Add pulseDot |> ignore
    foreverRow.Children.Add(TextBlock(Text = "录制中…", VerticalAlignment = VerticalAlignment.Center,
                                      Margin = Thickness(8., 0., 0., 0.))) |> ignore

    let foreverSb = Storyboard()
    let spinAnim = DoubleAnimation(From = Nullable 0., To = Nullable 360., Duration = Duration(TimeSpan.FromSeconds 1.2),
                                   RepeatBehavior = RepeatBehavior.Forever)
    Storyboard.SetTarget(spinAnim, spinAngle)
    Storyboard.SetTargetProperty(spinAnim, PropertyPath(RotateTransform.AngleProperty))
    foreverSb.Children.Add spinAnim |> ignore
    let pulseAnim = DoubleAnimation(From = Nullable 1., To = Nullable 0.3, Duration = Duration(TimeSpan.FromSeconds 0.7),
                                    AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever)
    Storyboard.SetTarget(pulseAnim, pulseDot)
    Storyboard.SetTargetProperty(pulseAnim, PropertyPath(Ellipse.OpacityProperty))
    foreverSb.Children.Add pulseAnim |> ignore

    // ⑤ 路径动画（教材 8.2.3）
    let pathMove = TranslateTransform()
    let pathBall = Ellipse(Width = 22., Height = 22., Fill = brushFromHex "#F59E0B", RenderTransform = pathMove)
    let track = Path(Data = Geometry.Parse("M 20,100 C 120,10 240,180 460,60"),
                     Stroke = brushFromHex "#CBD5E1")
    track.StrokeDashArray <- DoubleCollection([ 4.; 3. ])
    let pathStage = Canvas()
    pathStage.Children.Add track |> ignore
    pathStage.Children.Add pathBall |> ignore
    let pathHost = Border(BorderBrush = brushFromHex "#CBD5E1", BorderThickness = Thickness 1., Height = 140.,
                          ClipToBounds = true, Child = pathStage)
    let runPathBtn = Button(Content = "沿线跑一圈", Width = 110., HorizontalAlignment = HorizontalAlignment.Left,
                            Margin = Thickness(0., 8., 0., 0.))
    runPathBtn.Click.Add(fun _ ->
        // X/Y 各挂一个 DoubleAnimationUsingPath，Source 指明用路径的哪个坐标
        let path = PathGeometry()
        let fig = PathFigure(StartPoint = Point(20., 100.))
        fig.Segments.Add(BezierSegment(Point(120., 10.), Point(240., 180.), Point(460., 60.), true)) |> ignore
        path.Figures.Add fig |> ignore
        let dur = Duration(TimeSpan.FromSeconds 3.)
        let ax = DoubleAnimationUsingPath(PathGeometry = path, Source = PathAnimationSource.X, Duration = dur)
        let ay = DoubleAnimationUsingPath(PathGeometry = path, Source = PathAnimationSource.Y, Duration = dur)
        pathMove.BeginAnimation(TranslateTransform.XProperty, ax)
        pathMove.BeginAnimation(TranslateTransform.YProperty, ay))

    // 总装
    let panel = StackPanel(Margin = Thickness 16.)
    let ui (x: #UIElement) = x :> UIElement
    for c in [ ui (header "① 点击按钮自身变宽（Width 是布局属性，动画它会有重排开销）"); ui widenBtn
               ui (header "② 同样的效果动画 ScaleTransform——不触发布局，性能更好"); ui growBtn
               ui (header "③ 缓动函数对比：三个球下落 1.6 秒，手感完全不同（点「放手」）"); ui dropBtn; ui stages
               ui (header "④ 永续动画：加载圈与心跳点（窗口 Loaded 时启动，Forever 循环）"); ui foreverRow
               ui (header "⑤ 路径动画（教材 8.2.3）：DoubleAnimationUsingPath 让小球沿贝塞尔线走")
               ui pathHost; ui runPathBtn ] do
        panel.Children.Add c |> ignore

    window.Content <- ScrollViewer(VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Content = panel)
    window.Loaded.Add(fun _ -> foreverSb.Begin())
    Application().Run window
