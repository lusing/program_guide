using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;

namespace AnimationDemo;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    // 纯 C# 动画：Storyboard 并不神秘，最终都是对依赖属性调 BeginAnimation
    private void Drop_Click(object sender, RoutedEventArgs e)
    {
        Drop(BallLinear, null);                       // 匀速：不设缓动
        Drop(BallBounce, new BounceEase { Bounces = 3, Bounciness = 1.8 });
        Drop(BallElastic, new ElasticEase { Oscillations = 3, Springiness = 2 });
    }

    private static void Drop(TranslateTransform move, IEasingFunction? easing)
    {
        var anim = new DoubleAnimation(0, 150, TimeSpan.FromSeconds(1.6))
        {
            EasingFunction = easing,
        };
        move.BeginAnimation(TranslateTransform.YProperty, anim);
    }

    // 路径动画（教材 8.2.3）：X/Y 各挂一个 DoubleAnimationUsingPath，Source 指明用路径的哪个坐标
    private void RunPath_Click(object sender, RoutedEventArgs e)
    {
        var path = new PathGeometry();
        var fig = new PathFigure { StartPoint = new Point(20, 100) };
        fig.Segments.Add(new BezierSegment(new Point(120, 10), new Point(240, 180), new Point(460, 60), true));
        path.Figures.Add(fig);

        var dur = new System.Windows.Duration(TimeSpan.FromSeconds(3));   // 裸 Duration 会被成员查找劫持（CS1955）
        var ax = new DoubleAnimationUsingPath { PathGeometry = path, Source = PathAnimationSource.X, Duration = dur };
        var ay = new DoubleAnimationUsingPath { PathGeometry = path, Source = PathAnimationSource.Y, Duration = dur };
        PathMove.BeginAnimation(TranslateTransform.XProperty, ax);
        PathMove.BeginAnimation(TranslateTransform.YProperty, ay);
    }
}
