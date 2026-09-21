using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Animation;

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
}
