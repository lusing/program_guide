// 19 绘图与变换（C++/CLI 版）：与 csharp/ 版功能一致（含教材 7.3 的 3D 一瞥）。
// Path 的 Data 字符串用 Geometry::Parse 保持与 XAML 同源。
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Media;
using namespace System::Windows::Media::Media3D;
using namespace System::Windows::Shapes;

namespace DrawingDemoCpp {

    public ref class MainWindow : public Window
    {
    private:
        static SolidColorBrush^ BrushFromHex(String^ hex)
        {
            Color c = (Color)ColorConverter::ConvertFromString(hex);
            return gcnew SolidColorBrush(c);
        }

        static TextBlock^ Header(String^ text)
        {
            TextBlock^ t = gcnew TextBlock();
            t->Text = text; t->FontWeight = FontWeights::Bold;
            return t;
        }

        static TextBlock^ Hint(String^ text, bool marginTop)
        {
            TextBlock^ t = gcnew TextBlock();
            t->Text = text;
            t->Foreground = BrushFromHex(L"#555555");
            t->FontSize = 11;
            if (marginTop) t->Margin = Thickness(0, 6, 0, 0);
            return t;
        }

        RotateTransform^ _starRotate;
        ScaleTransform^ _starScale;
        AxisAngleRotation3D^ _spin;

    public:
        MainWindow()
        {
            Title = L"绘图与变换 (C++/CLI)";
            Width = 600; Height = 680;

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(16);

            // ── ① Shape 全家福 ──
            Canvas^ canvas = gcnew Canvas();
            canvas->Width = 540; canvas->Height = 230;
            canvas->Background = BrushFromHex(L"#F8FAFC");

            Path^ hill = gcnew Path();
            hill->Fill = BrushFromHex(L"#BBF7D0");
            hill->Data = Geometry::Parse(L"M 0,200 Q 135,130 270,200 T 540,200 L 540,230 L 0,230 Z");
            canvas->Children->Add(hill);

            Ellipse^ sun = gcnew Ellipse();
            sun->Width = 70; sun->Height = 70;
            Canvas::SetLeft(sun, 400); Canvas::SetTop(sun, 26);
            RadialGradientBrush^ sunBrush = gcnew RadialGradientBrush();
            sunBrush->GradientOrigin = Point(0.4, 0.4);
            sunBrush->GradientStops->Add(gcnew GradientStop(Color::FromRgb(0xFE, 0xF9, 0xC3), 0.0));
            sunBrush->GradientStops->Add(gcnew GradientStop(Color::FromRgb(0xFB, 0xBF, 0x24), 1.0));
            sun->Fill = sunBrush;
            canvas->Children->Add(sun);

            Rectangle^ body = gcnew Rectangle();
            body->Width = 150; body->Height = 95;
            body->Stroke = BrushFromHex(L"#7C2D12"); body->StrokeThickness = 1.5;
            Canvas::SetLeft(body, 120); Canvas::SetTop(body, 100);
            LinearGradientBrush^ wallBrush = gcnew LinearGradientBrush();
            wallBrush->StartPoint = Point(0, 0); wallBrush->EndPoint = Point(1, 0);
            wallBrush->GradientStops->Add(gcnew GradientStop(Color::FromRgb(0xFD, 0xE6, 0x8A), 0.0));
            wallBrush->GradientStops->Add(gcnew GradientStop(Color::FromRgb(0xF5, 0x9E, 0x0B), 1.0));
            body->Fill = wallBrush;
            canvas->Children->Add(body);

            Polygon^ roof = gcnew Polygon();
            roof->Fill = BrushFromHex(L"#B91C1C");
            roof->Points->Add(Point(108, 100));
            roof->Points->Add(Point(282, 100));
            roof->Points->Add(Point(195, 44));
            canvas->Children->Add(roof);

            Rectangle^ door = gcnew Rectangle();
            door->Width = 32; door->Height = 53;
            door->Fill = BrushFromHex(L"#78350F");
            Canvas::SetLeft(door, 180); Canvas::SetTop(door, 142);
            canvas->Children->Add(door);

            array<double>^ windowXs = { 138, 228 };
            for each (double x in windowXs)
            {
                Rectangle^ w = gcnew Rectangle();
                w->Width = 26; w->Height = 26;
                w->Fill = BrushFromHex(L"#E0F2FE");
                w->Stroke = BrushFromHex(L"#0369A1");
                Canvas::SetLeft(w, x); Canvas::SetTop(w, 118);
                canvas->Children->Add(w);
            }

            array<double>^ fenceXs = { 330, 350, 370 };
            for each (double x in fenceXs)
            {
                Line^ l = gcnew Line();
                l->X1 = x; l->Y1 = 195; l->X2 = x; l->Y2 = 165;
                l->Stroke = BrushFromHex(L"#92400E"); l->StrokeThickness = 3;
                canvas->Children->Add(l);
            }
            Line^ rail = gcnew Line();
            rail->X1 = 322; rail->Y1 = 172; rail->X2 = 378; rail->Y2 = 172;
            rail->Stroke = BrushFromHex(L"#92400E"); rail->StrokeThickness = 2;
            canvas->Children->Add(rail);

            Border^ scene = gcnew Border();
            scene->BorderBrush = BrushFromHex(L"#CBD5E1");
            scene->BorderThickness = Thickness(1);
            scene->CornerRadius = CornerRadius(8);
            scene->ClipToBounds = true;
            scene->Child = canvas;

            // ── ② 三种画刷 ──
            StackPanel^ brushDemo = gcnew StackPanel();
            brushDemo->Orientation = System::Windows::Controls::Orientation::Horizontal;

            StackPanel^ demo1 = gcnew StackPanel();
            demo1->Margin = Thickness(0, 0, 12, 0);
            Rectangle^ solid = gcnew Rectangle();
            solid->Width = 150; solid->Height = 44;
            solid->RadiusX = 6; solid->RadiusY = 6;
            solid->Fill = BrushFromHex(L"#3B82F6");
            demo1->Children->Add(solid);
            demo1->Children->Add(Hint(L"SolidColorBrush 纯色", false));

            StackPanel^ demo2 = gcnew StackPanel();
            demo2->Margin = Thickness(0, 0, 12, 0);
            Rectangle^ linear = gcnew Rectangle();
            linear->Width = 150; linear->Height = 44;
            linear->RadiusX = 6; linear->RadiusY = 6;
            LinearGradientBrush^ lb = gcnew LinearGradientBrush();
            lb->StartPoint = Point(0, 0); lb->EndPoint = Point(1, 0);
            lb->GradientStops->Add(gcnew GradientStop(Color::FromRgb(0x3B, 0x82, 0xF6), 0.0));
            lb->GradientStops->Add(gcnew GradientStop(Color::FromRgb(0x10, 0xB9, 0x81), 1.0));
            linear->Fill = lb;
            demo2->Children->Add(linear);
            demo2->Children->Add(Hint(L"LinearGradient 线性渐变", false));

            StackPanel^ demo3 = gcnew StackPanel();
            Rectangle^ radial = gcnew Rectangle();
            radial->Width = 150; radial->Height = 44;
            radial->RadiusX = 6; radial->RadiusY = 6;
            RadialGradientBrush^ rb = gcnew RadialGradientBrush();
            rb->GradientStops->Add(gcnew GradientStop(Color::FromRgb(0xFD, 0xE0, 0x47), 0.0));
            rb->GradientStops->Add(gcnew GradientStop(Color::FromRgb(0xEA, 0x58, 0x0C), 1.0));
            radial->Fill = rb;
            demo3->Children->Add(radial);
            demo3->Children->Add(Hint(L"RadialGradient 径向渐变", false));

            brushDemo->Children->Add(demo1);
            brushDemo->Children->Add(demo2);
            brushDemo->Children->Add(demo3);

            // ── ③ 变换 ──
            _starRotate = gcnew RotateTransform();
            _starScale = gcnew ScaleTransform();
            TransformGroup^ starGroup = gcnew TransformGroup();
            starGroup->Children->Add(_starRotate);
            starGroup->Children->Add(_starScale);

            Polygon^ star = gcnew Polygon();
            star->Fill = BrushFromHex(L"#F59E0B");
            star->Stroke = BrushFromHex(L"#B45309");
            star->StrokeThickness = 1.5;
            star->RenderTransformOrigin = Point(0.5, 0.5);
            star->Margin = Thickness(20);
            array<Point>^ starPts = {
                Point(60, 20), Point(69, 47), Point(98, 48), Point(75, 65), Point(84, 92),
                Point(60, 76), Point(37, 92), Point(45, 65), Point(22, 48), Point(51, 47) };
            for each (Point p in starPts) star->Points->Add(p);
            star->RenderTransform = starGroup;

            Button^ rotateBtn = gcnew Button();
            rotateBtn->Content = L"旋转 30°"; rotateBtn->Width = 110;
            rotateBtn->Margin = Thickness(0, 0, 0, 8);
            rotateBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnRotate);
            Button^ scaleBtn = gcnew Button();
            scaleBtn->Content = L"放大 1.2×"; scaleBtn->Width = 110;
            scaleBtn->Margin = Thickness(0, 0, 0, 8);
            scaleBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnScaleUp);
            Button^ resetBtn = gcnew Button();
            resetBtn->Content = L"重置"; resetBtn->Width = 110;
            resetBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnReset);

            StackPanel^ transformCtl = gcnew StackPanel();
            transformCtl->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            transformCtl->Margin = Thickness(20, 0, 0, 0);
            transformCtl->Children->Add(rotateBtn);
            transformCtl->Children->Add(scaleBtn);
            transformCtl->Children->Add(resetBtn);

            StackPanel^ transformRow = gcnew StackPanel();
            transformRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            transformRow->Children->Add(star);
            transformRow->Children->Add(transformCtl);

            // ── ④ 3D 一瞥（教材 7.3）：四棱锥 + 自旋 ──
            _spin = gcnew AxisAngleRotation3D(Vector3D(0, 1, 0), 0);
            MeshGeometry3D^ mesh = gcnew MeshGeometry3D();
            array<Point3D>^ positions = {
                Point3D(0, 1, 0), Point3D(-1, 0, 1), Point3D(1, 0, 1), Point3D(1, 0, -1), Point3D(-1, 0, -1) };
            for each (Point3D p in positions) mesh->Positions->Add(p);
            array<int>^ indices = { 0,1,2, 0,2,3, 0,3,4, 0,4,1 };
            for each (int i in indices) mesh->TriangleIndices->Add(i);

            GeometryModel3D^ pyramid = gcnew GeometryModel3D();
            pyramid->Geometry = mesh;
            DiffuseMaterial^ front = gcnew DiffuseMaterial();
            front->Brush = Brushes::SteelBlue;
            pyramid->Material = front;
            DiffuseMaterial^ back = gcnew DiffuseMaterial();   // 绕序画反也不至于黑屏
            back->Brush = Brushes::LightSteelBlue;
            pyramid->BackMaterial = back;

            Model3DGroup^ group = gcnew Model3DGroup();
            group->Children->Add(gcnew AmbientLight(Color::FromRgb(0x44, 0x44, 0x44)));
            group->Children->Add(gcnew DirectionalLight(Colors::White, Vector3D(-1, -1, -3)));
            group->Children->Add(pyramid);

            ModelVisual3D^ visual = gcnew ModelVisual3D();
            visual->Content = group;
            visual->Transform = gcnew RotateTransform3D(_spin);

            Viewport3D^ viewport = gcnew Viewport3D();
            viewport->Camera = gcnew PerspectiveCamera(
                Point3D(2.4, 2.2, 3), Vector3D(-2.4, -2.2, -3), Vector3D(0, 1, 0), 45);
            viewport->Children->Add(visual);

            Button^ spinBtn = gcnew Button();
            spinBtn->Content = L"旋转 45°"; spinBtn->Width = 110;
            spinBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnSpin);
            StackPanel^ spinRow = gcnew StackPanel();
            spinRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            spinRow->Margin = Thickness(0, 8, 0, 0);
            spinRow->Children->Add(spinBtn);
            TextBlock^ spinNote = gcnew TextBlock();
            spinNote->Text = L"改变 AxisAngleRotation3D.Angle 即重渲染——与 2D 的 RenderTransform 同一思路";
            spinNote->Foreground = BrushFromHex(L"#555555");
            spinNote->FontSize = 11;
            spinNote->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            spinNote->Margin = Thickness(12, 0, 0, 0);
            spinRow->Children->Add(spinNote);

            Border^ viewHost = gcnew Border();
            viewHost->BorderBrush = BrushFromHex(L"#CBD5E1");
            viewHost->BorderThickness = Thickness(1);
            viewHost->Height = 220;
            viewHost->Child = viewport;

            // ── 总装 ──
            panel->Children->Add(Header(L"① Shape 全家福：Canvas 上用绝对坐标拼一张小场景"));
            panel->Children->Add(scene);
            panel->Children->Add(Hint(L"Canvas.Left / Canvas.Top 是附加属性——只在 Canvas 里生效，子元素坐标完全由你指定", true));
            panel->Children->Add(Header(L"② 三种画刷"));
            panel->Children->Add(brushDemo);
            panel->Children->Add(Header(L"③ 变换：RenderTransform 不改布局尺寸，只改渲染结果"));
            panel->Children->Add(transformRow);
            panel->Children->Add(Header(L"④ 3D 一瞥（教材 7.3）：Viewport3D + 网格 + 材质 + 灯光 + 相机"));
            panel->Children->Add(viewHost);
            panel->Children->Add(spinRow);

            ScrollViewer^ scroll = gcnew ScrollViewer();
            scroll->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;
            scroll->Content = panel;
            Content = scroll;
        }

    private:
        void OnRotate(Object^ sender, RoutedEventArgs^ e) { _starRotate->Angle += 30; }
        void OnScaleUp(Object^ sender, RoutedEventArgs^ e)
        {
            _starScale->ScaleX *= 1.2;
            _starScale->ScaleY *= 1.2;
        }
        void OnReset(Object^ sender, RoutedEventArgs^ e)
        {
            _starRotate->Angle = 0;
            _starScale->ScaleX = 1;
            _starScale->ScaleY = 1;
        }
        void OnSpin(Object^ sender, RoutedEventArgs^ e) { _spin->Angle += 45; }
    };

    public ref class App
    {
    public:
        static void Run()
        {
            Application^ app = gcnew Application();
            app->Run(gcnew MainWindow());
        }
    };
}
