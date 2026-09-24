#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::UI::Xaml::Media;
using namespace Microsoft::UI::Xaml::Shapes;
namespace anim = Microsoft::UI::Xaml::Media::Animation;

namespace winrt::ThemeLab::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"Theme Lab");
        // 自定位（AppWindow 系实测按逻辑单位）：1000x620 逻辑 = 1750x1085 物理
        if (auto appWindow = AppWindow())
        {
            appWindow.MoveAndResize(Windows::Graphics::RectInt32{ 30, 30, 1000, 620 });
        }

        // 预设列表：结构体喂逻辑，runtimeclass 喂绑定
        m_presets = Presets::All();
        auto rows = single_threaded_observable_vector<ThemeLab::PresetInfo>();
        for (auto const& preset : m_presets)
        {
            rows.Append(make<ThemeLab::implementation::PresetInfo>(preset.Name,
                Windows::UI::Color{ 0xFF, preset.R, preset.G, preset.B }));
        }
        PresetList().ItemsSource(rows);

        BuildChart();
    }

    void MainWindow::ApplyAccent(Windows::UI::Color const& color)
    {
        // 26 章核心：往 Application.Resources 里盖一层 accent 键，
        // 全树 {ThemeResource Accent*} 引用立即跟着走（运行时改资源的正路）
        auto resources = Application::Current().Resources();
        auto brush = SolidColorBrush(color);
        resources.Insert(box_value(L"AccentFillColorDefaultBrush"), brush);
        resources.Insert(box_value(L"AccentFillColorSecondaryBrush"), SolidColorBrush(Windows::UI::Color{
            0xFF,
            static_cast<uint8_t>(color.R * 0.8f),
            static_cast<uint8_t>(color.G * 0.8f),
            static_cast<uint8_t>(color.B * 0.8f) }));
        for (auto&& bar : m_bars) { bar.Fill(SolidColorBrush(color)); }
        AccentStatus().Text(std::wstring(L"accent = #")
            + std::to_wstring(color.R) + L"," + std::to_wstring(color.G) + L"," + std::to_wstring(color.B));
    }

    void MainWindow::OnPresetSelected(IInspectable const&, SelectionChangedEventArgs const& args)
    {
        if (args.AddedItems().Size() == 0) { return; }
        auto info = args.AddedItems().GetAt(0).as<ThemeLab::PresetInfo>();
        int index = 0;
        for (int i = 0; i < static_cast<int>(m_presets.size()); ++i)
        {
            if (m_presets[i].Name == info.Name()) { index = i; break; }
        }
        Preset const& preset = m_presets[index];

        ApplyAccent(Windows::UI::Color{ 0xFF, preset.R, preset.G, preset.B });
        // 预设的明暗主题：双赋值触发 ThemeResource 重估（实测坑）
        if (auto root = Content().try_as<FrameworkElement>())
        {
            root.RequestedTheme(preset.Dark ? ElementTheme::Dark : ElementTheme::Light);
        }
        PlaySkinTransition();
        PresetStatus().Text(std::wstring(L"preset '") + std::wstring(preset.Name)
            + (preset.Dark ? L"' (dark shell)" : L"' (light shell)"));
    }

    void MainWindow::OnAccentChanged(Controls::ColorPicker const&, Controls::ColorChangedEventArgs const& args)
    {
        ApplyAccent(args.NewColor());
    }

    void MainWindow::BuildChart()
    {
        // 30 章：Shape 当绘图原语——七根矩形按数据立起来，填充走 accent 资源
        static const double week[7] = { 42, 68, 55, 81, 74, 96, 88 };
        auto columns = Grid().ColumnDefinitions();
        for (int i = 0; i < 7; ++i)
        {
            ColumnDefinition column;
            column.Width(GridLength(1.0, GridUnitType::Star));
            columns.Append(column);
        }

        double chartHeight = 190.0;
        double max = *std::max_element(week, week + 7);
        for (int i = 0; i < 7; ++i)
        {
            double barHeight = chartHeight * week[i] / max;

            StackPanel column;
            column.VerticalAlignment(VerticalAlignment::Bottom);
            column.Spacing(2);

            Microsoft::UI::Xaml::Shapes::Rectangle bar;
            bar.Height(barHeight);
            bar.RadiusX(4); bar.RadiusY(4);
            bar.Margin({ 10, 0, 10, 0 });
            // 主题资源字典在 XamlControlsResources 里，代码 TryLookup 拿不到：
            // 柱子登记进 m_bars，ApplyAccent 每次全量重刷（真·跟随）
            m_bars.push_back(bar);
            TextBlock label;
            label.Text(std::wstring(L"MTWTFSS").substr(i, 1));
            label.HorizontalAlignment(HorizontalAlignment::Center);
            label.Opacity(0.6);

            column.Children().Append(bar);
            column.Children().Append(label);
            Chart().Children().Append(column);
            Chart().SetColumn(column, i);
        }
    }

    void MainWindow::PlaySkinTransition()
    {
        // 28 章：换肤过渡动画。CppWinRTOptimized 会裁掉 Storyboard 的快捷
        // 名字（画廊实测坑），一律全限定命名空间
        anim::Storyboard storyboard;

        anim::DoubleAnimation fade;
        fade.From(0.2);
        fade.To(1.0);
        fade.Duration(Microsoft::UI::Xaml::Duration(Windows::Foundation::TimeSpan{ std::chrono::milliseconds(450) }));
        anim::Storyboard::SetTarget(fade, Dashboard());
        anim::Storyboard::SetTargetProperty(fade, L"Opacity");
        storyboard.Children().Append(fade);

        anim::DoubleAnimation slide;
        slide.From(18.0);
        slide.To(0.0);
        slide.Duration(Microsoft::UI::Xaml::Duration(Windows::Foundation::TimeSpan{ std::chrono::milliseconds(450) }));
        anim::Storyboard::SetTarget(slide, Dashboard());
        anim::Storyboard::SetTargetProperty(slide, L"(UIElement.RenderTransform).(TranslateTransform.Y)");
        storyboard.Children().Append(slide);

        // XAML 里没有 RenderTransform 占位，代码里补一个再动它
        Dashboard().RenderTransform(Microsoft::UI::Xaml::Media::TranslateTransform());

        storyboard.Begin();
    }
}
