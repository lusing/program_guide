#include "pch.h"
#include "AppearancePage.xaml.h"

#include <string>

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::SettingsHub::implementation
{
    AppearancePage::AppearancePage()
    {
        InitializeComponent();
        for (auto const& row : { L"first row", L"second row", L"third row" })
        {
            PreviewList().Items().Append(box_value(row));
        }
        // 主题恢复不在这里设 IsChecked：Checked 会在构造链里触发，而此刻
        // App 还没拿到窗口引用（12.5 坑的致命版，实测崩溃）——恢复由 MainWindow 自理
        hstring density = SettingsStore::Get(L"density", L"Comfortable");
        DensityBox().SelectedIndex(density == L"Compact" ? 1 : 0);   // 预选只能在 ctor：XAML 里 SelectedIndex 会在 Items 建立前应用而崩
        hstring opacity = SettingsStore::Get(L"opacity", L"100");
        try { OpacitySlider().Value(std::stod(std::wstring(opacity))); }
        catch (...) { OpacitySlider().Value(100.0); }
    }

    void AppearancePage::OnNavigatedTo(Microsoft::UI::Xaml::Navigation::NavigationEventArgs const& e)
    {
        __super::OnNavigatedTo(e);
        LightRadio().Focus(Microsoft::UI::Xaml::FocusState::Programmatic);
    }

    void AppearancePage::OnThemeChecked(IInspectable const& sender, RoutedEventArgs const&)
    {
        if (!IsLoaded() || !StatusText()) { return; }   // 解析期触发的 Checked 一律跳过（12.5 防护）
        hstring name = sender.as<RadioButton>().Content().as<hstring>();
        hstring key = name == L"Light" ? L"light" : name == L"Dark" ? L"dark" : L"default";
        Application::Current().as<SettingsHub::App>().ApplyTheme(key);
        SettingsStore::Put(L"theme", key);
        StatusText().Text(L"theme = " + name);
    }

    // 14 章：密度选择改 ListViewItem 的容器内边距（Style 在代码里的真实用武之地，26 章预告）
    void AppearancePage::OnDensityChanged(IInspectable const&, SelectionChangedEventArgs const&)
    {
        if (!PreviewList() || !StatusText()) { return; }
        if (auto item = DensityBox().SelectedItem())
        {
            hstring density = unbox_value<hstring>(item);
            double minHeight = density == L"Compact" ? 28.0 : 44.0;

            // 元数据实测：ListViewItem 没有静态 PaddingProperty——密度用
            // FrameworkElement::MinHeight 的容器样式实现（Style 在代码里的真实用武之地，26 章预告）
            // 注意：成员上下文里裸写 Style 会被 FrameworkElement::Style 属性遮蔽，必须全限定
            Microsoft::UI::Xaml::Style spacing;
            spacing.TargetType(xaml_typename<ListViewItem>());
            Microsoft::UI::Xaml::Setter height(FrameworkElement::MinHeightProperty(),
                box_value(minHeight));
            spacing.Setters().Append(height);
            PreviewList().ItemContainerStyle(spacing);

            SettingsStore::Put(L"density", density);
            StatusText().Text(L"density = " + density);
        }
    }

    void AppearancePage::OnOpacityChanged(IInspectable const&,
        Microsoft::UI::Xaml::Controls::Primitives::RangeBaseValueChangedEventArgs const& args)
    {
        if (!PreviewBar() || !StatusText()) { return; }
        double v = args.NewValue();
        PreviewBar().Opacity(v / 100.0);
        SettingsStore::Put(L"opacity", to_hstring(static_cast<int>(v)));
        StatusText().Text(L"opacity = " + to_hstring(static_cast<int>(v)) + L"%");
    }

    void AppearancePage::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
    {
        SettingsStore::Save();
        StatusText().Text(L"saved");
        Application::Current().as<SettingsHub::App>().ShowSavedBar();   // 25 章 InfoBar 真弹出
    }

    void AppearancePage::OnResetClicked(IInspectable const&, RoutedEventArgs const&)
    {
        SystemRadio().IsChecked(true);
        DensityBox().SelectedIndex(0);
        OpacitySlider().Value(100.0);
        StatusText().Text(L"reset to defaults");
    }
}
