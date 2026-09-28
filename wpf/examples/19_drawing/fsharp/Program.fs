// 19 绘图与变换（F# 版）：与 csharp/ 版功能一致（含教材 7.3 的 3D 一瞥）。
// XAML 的 Path Data="M ... Q ..." 字符串在代码里两条路：Geometry.Parse（字符串原样）
// 或 StreamGeometry 手工 Build——这里用 Parse 保持与 XAML 同源。
module DrawingDemoFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Media
open System.Windows.Media.Media3D   // Viewport3D / MeshGeometry3D / Point3D 全在这
open System.Windows.Shapes

let brushFromHex (hex: string) =
    ColorConverter.ConvertFromString hex :?> Color |> SolidColorBrush

let header (t: string) = TextBlock(Text = t, FontWeight = FontWeights.Bold)
let hint (t: string) = TextBlock(Text = t, Foreground = brushFromHex "#555555", FontSize = 11.)

[<EntryPoint; STAThread>]
let main _ =
    let window = Window(Title = "绘图与变换 (F#)", Height = 680., Width = 600.)

    // ── ① Shape 全家福 ──
    let canvas = Canvas(Width = 540., Height = 230., Background = brushFromHex "#F8FAFC")

    let hill = Path(Fill = brushFromHex "#BBF7D0",
                    Data = Geometry.Parse("M 0,200 Q 135,130 270,200 T 540,200 L 540,230 L 0,230 Z"))
    canvas.Children.Add hill |> ignore

    let sun = Ellipse(Width = 70., Height = 70.)
    Canvas.SetLeft(sun, 400.); Canvas.SetTop(sun, 26.)
    let sunBrush = RadialGradientBrush(GradientOrigin = Point(0.4, 0.4))
    sunBrush.GradientStops.Add(GradientStop(Color.FromRgb(0xFEuy, 0xF9uy, 0xC3uy), 0.)) |> ignore
    sunBrush.GradientStops.Add(GradientStop(Color.FromRgb(0xFBuy, 0xBFuy, 0x24uy), 1.)) |> ignore
    sun.Fill <- sunBrush
    canvas.Children.Add sun |> ignore

    let body = Rectangle(Width = 150., Height = 95., Stroke = brushFromHex "#7C2D12", StrokeThickness = 1.5)
    Canvas.SetLeft(body, 120.); Canvas.SetTop(body, 100.)
    let wallBrush = LinearGradientBrush(StartPoint = Point(0., 0.), EndPoint = Point(1., 0.))
    wallBrush.GradientStops.Add(GradientStop(Color.FromRgb(0xFDuy, 0xE6uy, 0x8Auy), 0.)) |> ignore
    wallBrush.GradientStops.Add(GradientStop(Color.FromRgb(0xF5uy, 0x9Euy, 0x0Buy), 1.)) |> ignore
    body.Fill <- wallBrush
    canvas.Children.Add body |> ignore

    let roof = Polygon(Fill = brushFromHex "#B91C1C", Points = PointCollection([ Point(108., 100.); Point(282., 100.); Point(195., 44.) ]))
    canvas.Children.Add roof |> ignore

    let door = Rectangle(Width = 32., Height = 53., Fill = brushFromHex "#78350F")
    Canvas.SetLeft(door, 180.); Canvas.SetTop(door, 142.)
    canvas.Children.Add door |> ignore
    let mkWindow (x: float) =
        let r = Rectangle(Width = 26., Height = 26., Fill = brushFromHex "#E0F2FE", Stroke = brushFromHex "#0369A1")
        Canvas.SetLeft(r, x); Canvas.SetTop(r, 118.)
        r
    canvas.Children.Add(mkWindow 138.) |> ignore
    canvas.Children.Add(mkWindow 228.) |> ignore

    let mkFence (x: float) =
        let l = Line(X1 = x, Y1 = 195., X2 = x, Y2 = 165., Stroke = brushFromHex "#92400E", StrokeThickness = 3.)
        l
    for x in [ 330.; 350.; 370. ] do canvas.Children.Add(mkFence x) |> ignore
    let rail = Line(X1 = 322., Y1 = 172., X2 = 378., Y2 = 172., Stroke = brushFromHex "#92400E", StrokeThickness = 2.)
    canvas.Children.Add rail |> ignore

    let scene = Border(BorderBrush = brushFromHex "#CBD5E1", BorderThickness = Thickness 1.,
                       CornerRadius = CornerRadius 8., ClipToBounds = true, Child = canvas)

    // ── ② 三种画刷 ──
    let gradientBlock hex1 hex2 =
        let r = Rectangle(Width = 150., Height = 44., RadiusX = 6., RadiusY = 6.)
        let b = LinearGradientBrush(StartPoint = Point(0., 0.), EndPoint = Point(1., 0.))
        b.GradientStops.Add(GradientStop(ColorConverter.ConvertFromString hex1 :?> Color, 0.)) |> ignore
        b.GradientStops.Add(GradientStop(ColorConverter.ConvertFromString hex2 :?> Color, 1.)) |> ignore
        r.Fill <- b
        r
    let radialBlock hex1 hex2 =
        let r = Rectangle(Width = 150., Height = 44., RadiusX = 6., RadiusY = 6.)
        let b = RadialGradientBrush()
        b.GradientStops.Add(GradientStop(ColorConverter.ConvertFromString hex1 :?> Color, 0.)) |> ignore
        b.GradientStops.Add(GradientStop(ColorConverter.ConvertFromString hex2 :?> Color, 1.)) |> ignore
        r.Fill <- b
        r
    let caption (t: string) = TextBlock(Text = t, FontSize = 11., Margin = Thickness(0., 4., 0., 0.))
    let brushDemo = StackPanel(Orientation = Orientation.Horizontal)
    let demo1 = StackPanel(Margin = Thickness(0., 0., 12., 0.))
    demo1.Children.Add(Rectangle(Width = 150., Height = 44., Fill = brushFromHex "#3B82F6", RadiusX = 6., RadiusY = 6.)) |> ignore
    demo1.Children.Add(caption "SolidColorBrush 纯色") |> ignore
    let demo2 = StackPanel(Margin = Thickness(0., 0., 12., 0.))
    demo2.Children.Add(gradientBlock "#3B82F6" "#10B981") |> ignore
    demo2.Children.Add(caption "LinearGradient 线性渐变") |> ignore
    let demo3 = StackPanel()
    demo3.Children.Add(radialBlock "#FDE047" "#EA580C") |> ignore
    demo3.Children.Add(caption "RadialGradient 径向渐变") |> ignore
    for d in [ demo1; demo2; demo3 ] do brushDemo.Children.Add d |> ignore

    // ── ③ 变换 ──
    let starRotate = RotateTransform()
    let starScale = ScaleTransform()
    let starGroup = TransformGroup()
    starGroup.Children.Add starRotate |> ignore
    starGroup.Children.Add starScale |> ignore
    let star = Polygon(Fill = brushFromHex "#F59E0B", Stroke = brushFromHex "#B45309", StrokeThickness = 1.5,
                       RenderTransformOrigin = Point(0.5, 0.5), Margin = Thickness 20.,
                       Points = PointCollection([ for (x, y) in [ 60.,20.; 69.,47.; 98.,48.; 75.,65.; 84.,92.; 60.,76.; 37.,92.; 45.,65.; 22.,48.; 51.,47. ] -> Point(x, y) ]),
                       RenderTransform = starGroup)
    let rotateBtn = Button(Content = "旋转 30°", Width = 110., Margin = Thickness(0., 0., 0., 8.))
    rotateBtn.Click.Add(fun _ -> starRotate.Angle <- starRotate.Angle + 30.)
    let scaleBtn = Button(Content = "放大 1.2×", Width = 110., Margin = Thickness(0., 0., 0., 8.))
    scaleBtn.Click.Add(fun _ ->
        starScale.ScaleX <- starScale.ScaleX * 1.2
        starScale.ScaleY <- starScale.ScaleY * 1.2)
    let resetBtn = Button(Content = "重置", Width = 110.)
    resetBtn.Click.Add(fun _ ->
        starRotate.Angle <- 0.
        starScale.ScaleX <- 1.
        starScale.ScaleY <- 1.)
    let transformCtl = StackPanel(VerticalAlignment = VerticalAlignment.Center, Margin = Thickness(20., 0., 0., 0.))
    for b in [ rotateBtn; scaleBtn; resetBtn ] do transformCtl.Children.Add b |> ignore
    let transformRow = StackPanel(Orientation = Orientation.Horizontal)
    transformRow.Children.Add star |> ignore
    transformRow.Children.Add transformCtl |> ignore

    // ── ④ 3D 一瞥（教材 7.3）：四棱锥 + 自旋 ──
    let spin = AxisAngleRotation3D(Axis = Vector3D(0., 1., 0.), Angle = 0.)
    let mesh = MeshGeometry3D()
    for (x, y, z) in [ 0.,1.,0.; -1.,0.,1.; 1.,0.,1.; 1.,0.,-1.; -1.,0.,-1. ] do
        mesh.Positions.Add(Point3D(x, y, z)) |> ignore
    for i in [ 0;1;2; 0;2;3; 0;3;4; 0;4;1 ] do
        mesh.TriangleIndices.Add i |> ignore
    let pyramid =
        GeometryModel3D(Geometry = mesh,
                        Material = DiffuseMaterial(Brush = Brushes.SteelBlue),
                        BackMaterial = DiffuseMaterial(Brush = Brushes.LightSteelBlue))
    let group = Model3DGroup()
    group.Children.Add(AmbientLight(Color.FromRgb(0x44uy, 0x44uy, 0x44uy))) |> ignore
    group.Children.Add(DirectionalLight(Color = Colors.White, Direction = Vector3D(-1., -1., -3.))) |> ignore
    group.Children.Add pyramid |> ignore
    let visual = ModelVisual3D(Content = group)
    visual.Transform <- RotateTransform3D(Rotation = spin)
    let viewport = Viewport3D()
    viewport.Camera <- PerspectiveCamera(Position = Point3D(2.4, 2.2, 3.), LookDirection = Vector3D(-2.4, -2.2, -3.),
                                         UpDirection = Vector3D(0., 1., 0.), FieldOfView = 45.)
    viewport.Children.Add visual |> ignore
    let spinBtn = Button(Content = "旋转 45°", Width = 110.)
    spinBtn.Click.Add(fun _ -> spin.Angle <- spin.Angle + 45.)
    let spinRow = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 8., 0., 0.))
    spinRow.Children.Add spinBtn |> ignore
    spinRow.Children.Add(TextBlock(Text = "改变 AxisAngleRotation3D.Angle 即重渲染——与 2D 的 RenderTransform 同一思路",
                                   Foreground = brushFromHex "#555555", FontSize = 11.,
                                   VerticalAlignment = VerticalAlignment.Center, Margin = Thickness(12., 0., 0., 0.))) |> ignore

    // ── 总装 ──
    let panel = StackPanel(Margin = Thickness 16.)
    let ui (x: #UIElement) = x :> UIElement
    for c in [ ui (header "① Shape 全家福：Canvas 上用绝对坐标拼一张小场景"); ui scene
               TextBlock(Text = "Canvas.Left / Canvas.Top 是附加属性——只在 Canvas 里生效，子元素坐标完全由你指定",
                         Foreground = brushFromHex "#555555", FontSize = 11., Margin = Thickness(0., 6., 0., 0.)) :> UIElement
               ui (header "② 三种画刷"); ui brushDemo
               ui (header "③ 变换：RenderTransform 不改布局尺寸，只改渲染结果"); ui transformRow
               ui (header "④ 3D 一瞥（教材 7.3）：Viewport3D + 网格 + 材质 + 灯光 + 相机")
               ui (Border(BorderBrush = brushFromHex "#CBD5E1", BorderThickness = Thickness 1., Height = 220., Child = viewport))
               ui spinRow ] do
        panel.Children.Add c |> ignore

    window.Content <- ScrollViewer(VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Content = panel)
    Application().Run window
