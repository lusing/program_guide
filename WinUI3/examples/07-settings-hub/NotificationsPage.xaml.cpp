#include "pch.h"
#include "NotificationsPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::SettingsHub::implementation
{
    NotificationsPage::NotificationsPage()
    {
        InitializeComponent();
        MasterSwitch().IsOn(SettingsStore::Get(L"notify", L"on") == L"on");
        ToastCheck().IsChecked(SettingsStore::Get(L"toast", L"true") == L"true");
        // 25 章：只在第一次进入时弹引导（状态来自 JSON，重启不再打扰）
        if (SettingsStore::Get(L"seenTip", L"false") != L"true")
        {
            FirstRunTip().IsOpen(true);
        }
    }

    void NotificationsPage::OnMasterToggled(IInspectable const&, RoutedEventArgs const&)
    {
        if (!ChannelBox() || !StatusText()) { return; }
        bool on = MasterSwitch().IsOn();
        // Panel 没有 IsEnabled（那是 Control 的属性）：逐个禁用渠道 CheckBox
        for (auto&& child : ChannelBox().Children())
        {
            if (auto control = child.try_as<Control>())
            {
                control.IsEnabled(on);
            }
        }
        SettingsStore::Put(L"notify", on ? L"on" : L"off");
        StatusText().Text(on ? L"notifications on: channels enabled"
                             : L"notifications off: channels disabled");
    }

    void NotificationsPage::OnChannelChanged(IInspectable const&, RoutedEventArgs const&)
    {
        if (!ToastCheck() || !StatusText()) { return; }
        SettingsStore::Put(L"toast", ToastCheck().IsChecked().Value() ? L"true" : L"false");
        StatusText().Text(ToastCheck().IsChecked().Value() ? L"toast banners on" : L"toast banners off");
    }

    void NotificationsPage::OnTipClicked(IInspectable const&, RoutedEventArgs const&)
    {
        FirstRunTip().IsOpen(!FirstRunTip().IsOpen());
    }

    void NotificationsPage::OnTipClosed(IInspectable const&, IInspectable const&)
    {
        SettingsStore::Put(L"seenTip", L"true");
        SettingsStore::Save();
    }

    void NotificationsPage::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
    {
        SettingsStore::Save();
        StatusText().Text(L"saved");
        Application::Current().as<SettingsHub::App>().ShowSavedBar();
    }
}
