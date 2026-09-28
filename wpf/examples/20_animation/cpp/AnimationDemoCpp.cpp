// 20 动画（C++/CLI 版）：与 csharp/ 版功能一致（含教材 8.2.3 路径动画）。
// XAML 的 Storyboard.TargetName → 代码里 Storyboard::SetTarget(动画, 目标对象)。
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Media;
using namespace System::Windows::Media::Animation;
using namespace System::Windows::Shapes;

namespace AnimationDemoCpp {

    public ref class MainWindow : public Window
    {
    private:
        TranslateTransform^ _moveLinear;
        TranslateTransform^ _moveBounce;
        TranslateTransform^ _moveElastic;
        TranslateTransform^ _pathMove;
        Storyboard^ _foreverSb;

        static SolidColorBrush^ BrushFromHex(String^ hex)
        {
            Color c = (Color)ColorConverter::ConvertFromString(hex);
            return gcnew SolidColorBrush(c);
        }

        static TextBlock^ Header(String^ text)
        {
            TextBlock^ t = gcnew TextBlock();
            t->Text = text; t->FontWeight = FontWeights::Bold;
            t->Margin = Thickness(0, 18, 0, 8);
            return t;
        }

        // 纯代码动画：Storyboard 不神秘，最终都是对依赖属性调 BeginAnimation
        static void Drop(TranslateTransform^ move, IEasingFunction^ easing)
        {
            DoubleAnimation^ anim = gcnew DoubleAnimation(0, 150, Duration(TimeSpan::FromSeconds(1.6)));
            anim->EasingFunction = easing;
            move->BeginAnimation(TranslateTransform::YProperty, anim);
        }

    public:
        MainWindow()
        {
            Title = L"动画实验室 (C++/CLI)";
            Width = 540; Height = 640;

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(16);

            // ① 点击按钮自身变宽
            Button^ widenBtn = gcnew Button();
            widenBtn->Content = L"点我变宽";
            widenBtn->Width = 120; widenBtn->Height = 38;
            widenBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            DoubleAnimation^ wa = gcnew DoubleAnimation(120, 260, Duration(TimeSpan::FromSeconds(0.4)));
            Storyboard::SetTarget(wa, widenBtn);
            Storyboard::SetTargetProperty(wa, gcnew PropertyPath(Button::WidthProperty));
            Storyboard^ widenSb = gcnew Storyboard();
            widenSb->Children->Add(wa);
            widenBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnWiden);

            // ② ScaleTransform
            ScaleTransform^ growScale = gcnew ScaleTransform();
            Button^ growBtn = gcnew Button();
            growBtn->Content = L"点我放大";
            growBtn->Width = 120; growBtn->Height = 38;
            growBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            growBtn->RenderTransformOrigin = Point(0.5, 0.5);
            growBtn->RenderTransform = growScale;
            Storyboard^ growSb = gcnew Storyboard();
            array<DependencyProperty^>^ props = { ScaleTransform::ScaleXProperty, ScaleTransform::ScaleYProperty };
            for each (DependencyProperty^ prop in props)
            {
                DoubleAnimation^ a = gcnew DoubleAnimation(1, 2, Duration(TimeSpan::FromSeconds(0.4)));
                Storyboard::SetTarget(a, growScale);
                Storyboard::SetTargetProperty(a, gcnew PropertyPath(prop));
                growSb->Children->Add(a);
            }
            growBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnGrow);

            // ③ 缓动函数对比
            _moveLinear = gcnew TranslateTransform();
            _moveBounce = gcnew TranslateTransform();
            _moveElastic = gcnew TranslateTransform();
            Grid^ stages = gcnew Grid();
            for (int i = 0; i < 3; i++) stages->ColumnDefinitions->Add(gcnew ColumnDefinition());

            array<String^>^ hexes = { L"#3B82F6", L"#10B981", L"#EF4444" };
            array<String^>^ captions = { L"Linear 匀速", L"Bounce 弹跳", L"Elastic 弹簧" };
            array<TranslateTransform^>^ moves = { _moveLinear, _moveBounce, _moveElastic };
            for (int i = 0; i < 3; i++)
            {
                Ellipse^ ball = gcnew Ellipse();
                ball->Width = 26; ball->Height = 26;
                ball->Fill = BrushFromHex(hexes[i]);
                ball->HorizontalAlignment = System::Windows::HorizontalAlignment::Center;
                ball->RenderTransform = moves[i];
                Border^ stage = gcnew Border();
                stage->Height = 200;
                stage->BorderBrush = BrushFromHex(L"#CBD5E1");
                stage->BorderThickness = Thickness(1);
                if (i < 2) stage->Margin = Thickness(0, 0, 6, 0);
                stage->Child = ball;
                StackPanel^ col = gcnew StackPanel();
                col->Children->Add(stage);
                TextBlock^ cap = gcnew TextBlock();
                cap->Text = captions[i];
                cap->HorizontalAlignment = System::Windows::HorizontalAlignment::Center;
                cap->Margin = Thickness(0, 4, 0, 0);
                col->Children->Add(cap);
                Grid::SetColumn(col, i);
                stages->Children->Add(col);
            }

            Button^ dropBtn = gcnew Button();
            dropBtn->Content = L"放手"; dropBtn->Width = 90;
            dropBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            dropBtn->Margin = Thickness(0, 0, 0, 8);
            dropBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnDrop);

            // ④ 永续动画
            RotateTransform^ spinAngle = gcnew RotateTransform();
            Ellipse^ ring = gcnew Ellipse();
            ring->Stroke = BrushFromHex(L"#3B82F6");
            ring->StrokeThickness = 5;
            ring->StrokeDashArray = gcnew DoubleCollection();
            ring->StrokeDashArray->Add(40);
            ring->StrokeDashArray->Add(100);
            ring->RenderTransformOrigin = Point(0.5, 0.5);
            ring->RenderTransform = spinAngle;
            Grid^ spinner = gcnew Grid();
            spinner->Width = 48; spinner->Height = 48;
            spinner->Margin = Thickness(0, 0, 24, 0);
            Ellipse^ trackRing = gcnew Ellipse();
            trackRing->Stroke = BrushFromHex(L"#E2E8F0");
            trackRing->StrokeThickness = 5;
            spinner->Children->Add(trackRing);
            spinner->Children->Add(ring);
            Ellipse^ pulseDot = gcnew Ellipse();
            pulseDot->Width = 18; pulseDot->Height = 18;
            pulseDot->Fill = BrushFromHex(L"#10B981");
            pulseDot->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            TextBlock^ rec = gcnew TextBlock();
            rec->Text = L"录制中…";
            rec->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            rec->Margin = Thickness(8, 0, 0, 0);
            StackPanel^ foreverRow = gcnew StackPanel();
            foreverRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            foreverRow->Children->Add(spinner);
            foreverRow->Children->Add(pulseDot);
            foreverRow->Children->Add(rec);

            _foreverSb = gcnew Storyboard();
            DoubleAnimation^ spinAnim = gcnew DoubleAnimation(0, 360, Duration(TimeSpan::FromSeconds(1.2)));
            spinAnim->RepeatBehavior = RepeatBehavior::Forever;
            Storyboard::SetTarget(spinAnim, spinAngle);
            Storyboard::SetTargetProperty(spinAnim, gcnew PropertyPath(RotateTransform::AngleProperty));
            _foreverSb->Children->Add(spinAnim);
            DoubleAnimation^ pulseAnim = gcnew DoubleAnimation(1, 0.3, Duration(TimeSpan::FromSeconds(0.7)));
            pulseAnim->AutoReverse = true;
            pulseAnim->RepeatBehavior = RepeatBehavior::Forever;
            Storyboard::SetTarget(pulseAnim, pulseDot);
            Storyboard::SetTargetProperty(pulseAnim, gcnew PropertyPath(Ellipse::OpacityProperty));
            _foreverSb->Children->Add(pulseAnim);

            // ⑤ 路径动画（教材 8.2.3）
            _pathMove = gcnew TranslateTransform();
            Ellipse^ pathBall = gcnew Ellipse();
            pathBall->Width = 22; pathBall->Height = 22;
            pathBall->Fill = BrushFromHex(L"#F59E0B");
            pathBall->RenderTransform = _pathMove;
            Path^ track = gcnew Path();
            track->Data = Geometry::Parse(L"M 20,100 C 120,10 240,180 460,60");
            track->Stroke = BrushFromHex(L"#CBD5E1");
            track->StrokeDashArray = gcnew DoubleCollection();
            track->StrokeDashArray->Add(4);
            track->StrokeDashArray->Add(3);
            Canvas^ pathStage = gcnew Canvas();
            pathStage->Children->Add(track);
            pathStage->Children->Add(pathBall);
            Border^ pathHost = gcnew Border();
            pathHost->BorderBrush = BrushFromHex(L"#CBD5E1");
            pathHost->BorderThickness = Thickness(1);
            pathHost->Height = 140;
            pathHost->ClipToBounds = true;
            pathHost->Child = pathStage;
            Button^ runPathBtn = gcnew Button();
            runPathBtn->Content = L"沿线跑一圈"; runPathBtn->Width = 110;
            runPathBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            runPathBtn->Margin = Thickness(0, 8, 0, 0);
            runPathBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnRunPath);

            panel->Children->Add(Header(L"① 点击按钮自身变宽（Width 是布局属性，动画它会有重排开销）"));
            panel->Children->Add(widenBtn);
            panel->Children->Add(Header(L"② 同样的效果动画 ScaleTransform——不触发布局，性能更好"));
            panel->Children->Add(growBtn);
            panel->Children->Add(Header(L"③ 缓动函数对比：三个球下落 1.6 秒，手感完全不同（点「放手」）"));
            panel->Children->Add(dropBtn);
            panel->Children->Add(stages);
            panel->Children->Add(Header(L"④ 永续动画：加载圈与心跳点（窗口 Loaded 时启动，Forever 循环）"));
            panel->Children->Add(foreverRow);
            panel->Children->Add(Header(L"⑤ 路径动画（教材 8.2.3）：DoubleAnimationUsingPath 让小球沿贝塞尔线走"));
            panel->Children->Add(pathHost);
            panel->Children->Add(runPathBtn);

            ScrollViewer^ scroll = gcnew ScrollViewer();
            scroll->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;
            scroll->Content = panel;
            Content = scroll;

            Loaded += gcnew RoutedEventHandler(this, &MainWindow::OnLoadedPlay);
        }

    private:
        void OnLoadedPlay(Object^ sender, RoutedEventArgs^ e) { _foreverSb->Begin(); }
        void OnWiden(Object^ sender, RoutedEventArgs^ e)
        {
            // widenSb 在 OnWiden 里不可见——重建等价动画最省事（教学取舍注释见 docs/20）
            DoubleAnimation^ wa = gcnew DoubleAnimation(120, 260, Duration(TimeSpan::FromSeconds(0.4)));
            Storyboard::SetTarget(wa, safe_cast<Button^>(sender));
            Storyboard::SetTargetProperty(wa, gcnew PropertyPath(Button::WidthProperty));
            Storyboard^ sb = gcnew Storyboard();
            sb->Children->Add(wa);
            sb->Begin();
        }
        void OnGrow(Object^ sender, RoutedEventArgs^ e)
        {
            Button^ btn = safe_cast<Button^>(sender);
            ScaleTransform^ scale = safe_cast<ScaleTransform^>(btn->RenderTransform);
            Storyboard^ sb = gcnew Storyboard();
            array<DependencyProperty^>^ props = { ScaleTransform::ScaleXProperty, ScaleTransform::ScaleYProperty };
            for each (DependencyProperty^ prop in props)
            {
                DoubleAnimation^ a = gcnew DoubleAnimation(1, 2, Duration(TimeSpan::FromSeconds(0.4)));
                Storyboard::SetTarget(a, scale);
                Storyboard::SetTargetProperty(a, gcnew PropertyPath(prop));
                sb->Children->Add(a);
            }
            sb->Begin();
        }
        void OnDrop(Object^ sender, RoutedEventArgs^ e)
        {
            Drop(_moveLinear, nullptr);   // 匀速：不设缓动
            BounceEase^ bounce = gcnew BounceEase();
            bounce->Bounces = 3; bounce->Bounciness = 1.8;
            Drop(_moveBounce, bounce);
            ElasticEase^ elastic = gcnew ElasticEase();
            elastic->Oscillations = 3; elastic->Springiness = 2;
            Drop(_moveElastic, elastic);
        }
        void OnRunPath(Object^ sender, RoutedEventArgs^ e)
        {
            // X/Y 各挂一个 DoubleAnimationUsingPath，Source 指明用路径的哪个坐标
            PathGeometry^ path = gcnew PathGeometry();
            PathFigure^ fig = gcnew PathFigure();
            fig->StartPoint = Point(20, 100);
            fig->Segments->Add(gcnew BezierSegment(Point(120, 10), Point(240, 180), Point(460, 60), true));
            path->Figures->Add(fig);

            Duration dur = Duration(TimeSpan::FromSeconds(3.0));
            DoubleAnimationUsingPath^ ax = gcnew DoubleAnimationUsingPath();
            ax->PathGeometry = path;
            ax->Source = PathAnimationSource::X;
            ax->Duration = dur;
            DoubleAnimationUsingPath^ ay = gcnew DoubleAnimationUsingPath();
            ay->PathGeometry = path;
            ay->Source = PathAnimationSource::Y;
            ay->Duration = dur;
            _pathMove->BeginAnimation(TranslateTransform::XProperty, ax);
            _pathMove->BeginAnimation(TranslateTransform::YProperty, ay);
        }
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
