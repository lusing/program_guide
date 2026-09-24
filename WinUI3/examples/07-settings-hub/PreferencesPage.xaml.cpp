#include "pch.h"
#include "PreferencesPage.xaml.h"

#include <cmath>
#include <string>

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::SettingsHub::implementation
{
    PreferencesPage::PreferencesPage()
    {
        InitializeComponent();
        hstring saved = SettingsStore::Get(L"count", L"");
        if (!saved.empty() && saved != L"nan")
        {
            try { DefaultCount().Value(std::stod(std::wstring(saved))); }
            catch (...) {}
        }
    }

    void PreferencesPage::OnNavigatedTo(Microsoft::UI::Xaml::Navigation::NavigationEventArgs const& e)
    {
        __super::OnNavigatedTo(e);
        SaveButton().Focus(Microsoft::UI::Xaml::FocusState::Programmatic);
    }

    void PreferencesPage::OnCountChanged(IInspectable const&,
        NumberBoxValueChangedEventArgs const& args)
    {
        if (!StatusText()) { return; }
        double v = args.NewValue();
        if (std::isnan(v))
        {
            SettingsStore::Put(L"count", L"nan");
            StatusText().Text(L"default count = unlimited");
        }
        else
        {
            SettingsStore::Put(L"count", to_hstring(static_cast<int>(v)));
            StatusText().Text(L"default count = " + to_hstring(static_cast<int>(v)));
        }
    }

    void PreferencesPage::OnWeekStartChanged(IInspectable const&,
        DatePickerValueChangedEventArgs const& args)
    {
        if (!StatusText()) { return; }
        // 16 章实测：NewDate() 是裸 DateTime，不是 IReference
        StatusText().Text(L"week start ticks = "
            + to_hstring(args.NewDate().time_since_epoch().count()));
    }

    // 12 章 ProgressBar + 32.7 协程纪律：resume_after 保持 UI 上下文逐帧推进
    Windows::Foundation::IAsyncAction PreferencesPage::AnimateSaveAsync()
    {
        auto strong = get_strong();   // 页面可能中途被导航销毁，先抓强引用
        SaveProgress().Value(0);
        for (int step = 1; step <= 4; ++step)
        {
            using namespace std::chrono_literals;
            co_await winrt::resume_after(90ms);   // 让出 UI 线程，进度分帧可见
            SaveProgress().Value(step * 25.0);
        }
        SettingsStore::Save();
        if (!StatusText()) { co_return; }
        StatusText().Text(L"preferences saved");
    }

    void PreferencesPage::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
    {
        SettingsStore::Put(L"reminder", to_hstring(ReminderTime().Time().count()));
        StatusText().Text(L"saving...");
        (void)AnimateSaveAsync();
        Application::Current().as<SettingsHub::App>().ShowSavedBar();
    }

    void PreferencesPage::OnSaveAccelerator(
        Microsoft::UI::Xaml::Input::KeyboardAccelerator const&,
        Microsoft::UI::Xaml::Input::KeyboardAcceleratorInvokedEventArgs const&)
    {
        // Ctrl+S 与点击同一条路径：真实应用里二者必须一致，冒烟只走一条
        OnSaveClicked(nullptr, nullptr);
    }
}
