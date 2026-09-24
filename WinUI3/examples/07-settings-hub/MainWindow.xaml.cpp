#include "pch.h"
#include "MainWindow.xaml.h"
#include "winrt/Microsoft.UI.Input.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::SettingsHub::implementation
{
    static hstring const kPages[3][2] = {
        { L"appearance",   L"Appearance" },
        { L"notifications", L"Notifications" },
        { L"preferences",  L"Preferences" },
    };

    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"Settings Hub");
        if (auto appWindow = AppWindow())
        {
            // 1080x700 逻辑 = 1890x1225 物理 @175%，正好装进 2194x1234 的屏；
            // 超屏窗口会被系统钳制，而外部再 Resize 会把岛的输入变换打烂
            //（渲染照旧、命中错位——冒烟点击全灭的元凶）
            appWindow.Resize({ 1080, 700 });
        }
        // 主题恢复由窗口自理：构造链里 App 还没拿到本窗口引用，页面侧恢复会踩空引用（实测崩）
        // hstring theme = SettingsStore::Get(L"theme", L"default");
        // if (auto root = Content().try_as<FrameworkElement>())
        // {
        //     root.RequestedTheme(theme == L"dark"  ? ElementTheme::Dark
        //                               : theme == L"light" ? ElementTheme::Light
        //                                                    : ElementTheme::Default);
        // }
        ContentFrame().Navigate(xaml_typename<SettingsHub::AppearancePage>());
    }

    void MainWindow::ShowSaved()
    {
        SavedBar().IsOpen(true);   // 25 章：保存反馈真的出现
    }

    // SMOKE 诊断（临时）：窗口级指针落点 + 命中目标镜像到标题，反解注入点击映射
    void MainWindow::OnRootPointer(Windows::Foundation::IInspectable const&,
        Microsoft::UI::Xaml::Input::PointerRoutedEventArgs const& e)
    {
        auto pos = e.GetCurrentPoint(Content()).Position();
        hstring target = winrt::get_class_name(e.OriginalSource());
        if (auto fe = e.OriginalSource().try_as<FrameworkElement>())
        {
            if (!fe.Name().empty()) { target = target + L" '" + fe.Name() + L"'"; }
        }
        wchar_t buffer[160]{};
        swprintf(buffer, 160, L"hit %.0f,%.0f -> %s", pos.X, pos.Y, target.c_str());
        Title(buffer);
    }

    // SMOKE 诊断（临时）：TAB 链逐站镜像到标题
    void MainWindow::OnRootFocus(Windows::Foundation::IInspectable const&,
        Microsoft::UI::Xaml::RoutedEventArgs const& e)
    {
        hstring target = winrt::get_class_name(e.OriginalSource());
        if (auto fe = e.OriginalSource().try_as<FrameworkElement>())
        {
            if (!fe.Name().empty()) { target = target + L" '" + fe.Name() + L"'"; }
        }
        Title(L"focus -> " + target);
    }

    void MainWindow::OnNavSelectionChanged(IInspectable const&,
        NavigationViewSelectionChangedEventArgs const& args)
    {
        if (auto item = args.SelectedItem().try_as<NavigationViewItem>())
        {
            NavigateTo(unbox_value<hstring>(item.Tag()));
        }
    }

    // 15 章内建搜索位：TextChanged 过滤导航项（Reason 防重入，15.2 的机制在这里是真功能）
    void MainWindow::OnSearchChanged(IInspectable const&,
        AutoSuggestBoxTextChangedEventArgs const& args)
    {
        if (args.Reason() != AutoSuggestionBoxTextChangeReason::UserInput) { return; }
        auto box = Nav().AutoSuggestBox();
        std::wstring_view query(box.Text());
        auto hits = single_threaded_vector<IInspectable>();
        for (auto const& page : kPages)
        {
            std::wstring_view label(page[1]);
            if (query.empty() ||
                label.find(query) != std::wstring_view::npos ||
                query.find(label) != std::wstring_view::npos)
            {
                hits.Append(box_value(page[1] + L"|" + page[0]));
            }
        }
        box.ItemsSource(hits);
    }

    void MainWindow::OnSearchChosen(IInspectable const&,
        AutoSuggestBoxSuggestionChosenEventArgs const& args)
    {
        // 建议格式 "Label|tag"：选了真的跳转对应分区（hstring 无 find/substr，用 wstring_view）
        std::wstring_view text(args.SelectedItem().as<hstring>());
        size_t bar = text.find(L'|');
        if (bar != std::wstring_view::npos)
        {
            NavigateTo(hstring(text.substr(bar + 1)));
        }
    }

    void MainWindow::NavigateTo(hstring const& tag)
    {
        if (tag == L"appearance") ContentFrame().Navigate(xaml_typename<SettingsHub::AppearancePage>());
        if (tag == L"notifications") ContentFrame().Navigate(xaml_typename<SettingsHub::NotificationsPage>());
        if (tag == L"preferences") ContentFrame().Navigate(xaml_typename<SettingsHub::PreferencesPage>());
        // 每章任务追加分支
    }
}
