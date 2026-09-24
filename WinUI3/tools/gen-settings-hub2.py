#!/usr/bin/env python3
"""SettingsHub part 2: the three settings pages + vcxproj (revised)."""
import io
import os

BASE = os.path.join(os.path.dirname(__file__), '..', 'examples', '07-settings-hub')


def w(name, content):
    with io.open(os.path.join(BASE, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)


# ---------- App gains ShowSavedBar (pages -> window InfoBar via projection) ----------
w('App.idl', '''namespace SettingsHub
{
    [default_interface]
    runtimeclass App : Microsoft.UI.Xaml.Application
    {
        App();
        void ApplyTheme(hstring theme);   // "light" / "dark" / "default"
        void ShowSavedBar();              // green InfoBar feedback at the window bottom
    }
}
''')
w('App.xaml.h', '''#pragma once
#include "App.g.h"

namespace winrt::SettingsHub::implementation
{
    struct App : AppT<App>
    {
        App();

        void OnLaunched(Microsoft::UI::Xaml::LaunchActivatedEventArgs const&);
        void ApplyTheme(hstring const& theme);
        void ShowSavedBar();

    private:
        Microsoft::UI::Xaml::Window m_window{ nullptr };
    };
}
''')
w('App.xaml.cpp', '''#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::SettingsHub::implementation
{
    App::App()
    {
        InitializeComponent();
    }

    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        m_window = make<MainWindow>();
        m_window.Activate();
    }

    void App::ApplyTheme(hstring const& theme)
    {
        // RequestedTheme on the content root re-skins the whole tree (10 章 RadioButton 的真 payoff)
        if (auto root = m_window.Content().try_as<FrameworkElement>())
        {
            ElementTheme value = theme == L"dark"  ? ElementTheme::Dark
                               : theme == L"light" ? ElementTheme::Light
                                                    : ElementTheme::Default;
            root.RequestedTheme(value);
        }
    }

    void App::ShowSavedBar()
    {
        if (auto main = m_window.as<SettingsHub::MainWindow>())
        {
            main.ShowSaved();
        }
    }
}
''')

# ---------- AppearancePage ----------
w('AppearancePage.idl', '''namespace SettingsHub
{
    [default_interface]
    runtimeclass AppearancePage : Microsoft.UI.Xaml.Controls.Page
    {
        AppearancePage();
    }
}
''')
w('AppearancePage.xaml', '''<Page
    x:Class="SettingsHub.AppearancePage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <ScrollViewer>
        <StackPanel Spacing="18" Margin="24,18" MaxWidth="620">

            <!-- 8 章 TextBlock 的真实角色：区块标题与说明文案 -->
            <StackPanel Spacing="4">
                <TextBlock Text="Appearance" FontSize="26" FontWeight="Bold"/>
                <TextBlock Text="Theme, density and translucency apply immediately and are remembered."
                           TextWrapping="Wrap" Opacity="0.7"/>
            </StackPanel>

            <!-- 10 章 RadioButton：点选真的切换整窗主题 -->
            <TextBlock Text="App theme" FontWeight="SemiBold"/>
            <StackPanel Orientation="Horizontal" Spacing="16">
                <RadioButton x:Name="LightRadio" Content="Light" GroupName="Theme" Checked="OnThemeChecked"/>
                <RadioButton x:Name="DarkRadio" Content="Dark" GroupName="Theme" Checked="OnThemeChecked"/>
                <RadioButton x:Name="SystemRadio" Content="Follow system" GroupName="Theme" IsChecked="True" Checked="OnThemeChecked"/>
            </StackPanel>

            <!-- 14 章 ComboBox：密度选择真的改预览列表行距 -->
            <TextBlock Text="Panel density" FontWeight="SemiBold"/>
            <ComboBox x:Name="DensityBox" Header="List spacing" Width="220"
                      SelectedIndex="0" SelectionChanged="OnDensityChanged">
                <x:String>Comfortable</x:String>
                <x:String>Compact</x:String>
            </ComboBox>

            <!-- 12 章 Slider：透明度实时改预览条 -->
            <TextBlock Text="Preview translucency" FontWeight="SemiBold"/>
            <Slider x:Name="OpacitySlider" Header="Opacity" Minimum="20" Maximum="100" Value="100"
                    Width="320" ValueChanged="OnOpacityChanged"/>

            <!-- 预览区：三个设置的真实可见结果 -->
            <StackPanel Spacing="8">
                <TextBlock Text="Preview" FontWeight="SemiBold"/>
                <Border x:Name="PreviewBar" Background="{ThemeResource AccentFillColorDefaultBrush}"
                        CornerRadius="6" Padding="14,10" Width="320">
                    <TextBlock Text="accent preview bar"
                               Foreground="{ThemeResource TextOnAccentFillColorDefaultBrush}"/>
                </Border>
                <ListView x:Name="PreviewList" Width="320">
                    <ListView.ItemTemplate>
                        <DataTemplate x:DataType="x:String">
                            <TextBlock Text="{Binding}" Margin="8,4"/>
                        </DataTemplate>
                    </ListView.ItemTemplate>
                </ListView>
            </StackPanel>

            <!-- 7 章 Button：命令入口（保存走强调样式） -->
            <StackPanel Orientation="Horizontal" Spacing="10">
                <Button Content="Save appearance" Style="{ThemeResource AccentButtonStyle}"
                        Click="OnSaveClicked"/>
                <Button Content="Reset" Click="OnResetClicked"/>
            </StackPanel>
            <TextBlock x:Name="StatusText" Text="" Opacity="0.7"/>

        </StackPanel>
    </ScrollViewer>
</Page>
''')
w('AppearancePage.xaml.h', '''#pragma once
#include "AppearancePage.g.h"

namespace winrt::SettingsHub::implementation
{
    struct AppearancePage : AppearancePageT<AppearancePage>
    {
        AppearancePage();

        void OnThemeChecked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnDensityChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnOpacityChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::Primitives::RangeBaseValueChangedEventArgs const& args);
        void OnSaveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnResetClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::SettingsHub::factory_implementation
{
    struct AppearancePage : AppearancePageT<AppearancePage, implementation::AppearancePage>
    {
    };
}
''')
w('AppearancePage.xaml.cpp', '''#include "pch.h"
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
        // 启动恢复上次设置（真的从 JSON 读回并应用）
        hstring theme = SettingsStore::Get(L"theme", L"default");
        if (theme == L"dark") { DarkRadio().IsChecked(true); }
        else if (theme == L"light") { LightRadio().IsChecked(true); }
        hstring density = SettingsStore::Get(L"density", L"Comfortable");
        if (density == L"Compact") { DensityBox().SelectedIndex(1); }
        hstring opacity = SettingsStore::Get(L"opacity", L"100");
        try { OpacitySlider().Value(std::stod(std::wstring(opacity))); }
        catch (...) { OpacitySlider().Value(100.0); }
    }

    void AppearancePage::OnThemeChecked(IInspectable const& sender, RoutedEventArgs const&)
    {
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
            double gap = density == L"Compact" ? 1.0 : 8.0;

            Style spacing;
            spacing.TargetType(xaml_typename<ListViewItem>());
            Setter padding(ListViewItem::PaddingProperty(),
                box_value(Thickness{ 8, gap, 8, gap }));
            spacing.Setters().Append(padding);
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
''')

# ---------- NotificationsPage ----------
w('NotificationsPage.idl', '''namespace SettingsHub
{
    [default_interface]
    runtimeclass NotificationsPage : Microsoft.UI.Xaml.Controls.Page
    {
        NotificationsPage();
    }
}
''')
w('NotificationsPage.xaml', '''<Page
    x:Class="SettingsHub.NotificationsPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <StackPanel Spacing="18" Margin="24,18" MaxWidth="620">

        <StackPanel Spacing="4">
            <TextBlock Text="Notifications" FontSize="26" FontWeight="Bold"/>
            <TextBlock Text="The master switch disables every channel below it."
                       TextWrapping="Wrap" Opacity="0.7"/>
        </StackPanel>

        <!-- 11 章 ToggleSwitch：总闸，关掉真的禁用整组渠道 -->
        <ToggleSwitch x:Name="MasterSwitch" Header="Notifications"
                      OnContent="On" OffContent="Off" IsOn="True"
                      Toggled="OnMasterToggled"/>

        <!-- 10 章 CheckBox：渠道组，IsEnabled 跟随总闸 -->
        <StackPanel x:Name="ChannelBox" Spacing="8" Margin="0,4,0,0">
            <CheckBox x:Name="ToastCheck" Content="Toast banners" IsChecked="True"
                      Checked="OnChannelChanged" Unchecked="OnChannelChanged"/>
            <CheckBox x:Name="SoundCheck" Content="Sounds"/>
            <CheckBox x:Name="MailCheck" Content="Email digest"/>
        </StackPanel>

        <!-- 25 章 TeachingTip：首次进入本页才出现的引导 -->
        <Button x:Name="TipAnchor" Content="What is this page?" Click="OnTipClicked"
                HorizontalAlignment="Left"/>
        <TeachingTip x:Name="FirstRunTip"
                     Title="Notification channels"
                     Subtitle="Each channel can be turned on individually while the master switch is on."
                     CloseButtonContent="Got it"
                     Target="{x:Bind TipAnchor}"
                     PreferredPlacement="Bottom"
                     CloseButtonClick="OnTipClosed"/>

        <Button Content="Save notifications" Style="{ThemeResource AccentButtonStyle}"
                Click="OnSaveClicked" HorizontalAlignment="Left"/>
        <TextBlock x:Name="StatusText" Text="" Opacity="0.7"/>
    </StackPanel>
</Page>
''')
w('NotificationsPage.xaml.h', '''#pragma once
#include "NotificationsPage.g.h"

namespace winrt::SettingsHub::implementation
{
    struct NotificationsPage : NotificationsPageT<NotificationsPage>
    {
        NotificationsPage();

        void OnMasterToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnChannelChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTipClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTipClosed(
            Windows::Foundation::IInspectable const& sender,
            Windows::Foundation::IInspectable const& args);
        void OnSaveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::SettingsHub::factory_implementation
{
    struct NotificationsPage : NotificationsPageT<NotificationsPage, implementation::NotificationsPage>
    {
    };
}
''')
w('NotificationsPage.xaml.cpp', '''#include "pch.h"
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
        ChannelBox().IsEnabled(on);
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
''')

# ---------- PreferencesPage ----------
w('PreferencesPage.idl', '''namespace SettingsHub
{
    [default_interface]
    runtimeclass PreferencesPage : Microsoft.UI.Xaml.Controls.Page
    {
        PreferencesPage();
    }
}
''')
w('PreferencesPage.xaml', '''<Page
    x:Class="SettingsHub.PreferencesPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <StackPanel Spacing="18" Margin="24,18" MaxWidth="620">

        <StackPanel Spacing="4">
            <TextBlock Text="Preferences" FontSize="26" FontWeight="Bold"/>
            <TextBlock Text="Task defaults consumed by the TaskFlow app (chapter 35)."
                       TextWrapping="Wrap" Opacity="0.7"/>
        </StackPanel>

        <!-- 13 章 NumberBox：空输入 = NaN = 无限制（真实业务语义） -->
        <NumberBox x:Name="DefaultCount" Header="Default task count (empty = unlimited)"
                   PlaceholderText="no limit" Minimum="0" Maximum="99"
                   SpinButtonPlacementMode="Inline" SmallChange="1" LargeChange="5"
                   ValueChanged="OnCountChanged"/>

        <!-- 16 章 DatePicker/TimePicker -->
        <DatePicker x:Name="WeekStart" Header="Week starts on" DateChanged="OnWeekStartChanged"/>
        <TimePicker x:Name="ReminderTime" Header="Daily reminder at" MinuteIncrement="15"/>

        <Button Content="Save preferences" Style="{ThemeResource AccentButtonStyle}"
                Click="OnSaveClicked" HorizontalAlignment="Left"/>

        <!-- 12 章 ProgressBar：保存时真的分帧走完 -->
        <ProgressBar x:Name="SaveProgress" Minimum="0" Maximum="100" Value="0" Width="320"/>
        <TextBlock x:Name="StatusText" Text="" Opacity="0.7"/>
    </StackPanel>
</Page>
''')
w('PreferencesPage.xaml.h', '''#pragma once
#include "PreferencesPage.g.h"

namespace winrt::SettingsHub::implementation
{
    struct PreferencesPage : PreferencesPageT<PreferencesPage>
    {
        PreferencesPage();

        void OnCountChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NumberBoxValueChangedEventArgs const& args);
        void OnWeekStartChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::DatePickerValueChangedEventArgs const& args);
        void OnSaveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        Windows::Foundation::IAsyncAction AnimateSaveAsync();
    };
}

namespace winrt::SettingsHub::factory_implementation
{
    struct PreferencesPage : PreferencesPageT<PreferencesPage, implementation::PreferencesPage>
    {
    };
}
''')
w('PreferencesPage.xaml.cpp', '''#include "pch.h"
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
}
''')

# vcxproj: clone 06-layout and swap
src = io.open(os.path.join(os.path.dirname(__file__), '..', 'examples', '06-layout', 'LayoutApp.vcxproj'), encoding='utf-8').read()
src = src.replace('{06a1b2c3-4d5e-4f60-8a9b-0c1d2e3f4a06}', '{07b1b2c3-4d5e-4f60-8a9b-0c1d2e3f4b07}')
src = src.replace('<RootNamespace>LayoutApp</RootNamespace>', '<RootNamespace>SettingsHub</RootNamespace>')
src = src.replace('''    <ClInclude Include="pch.h" />
    <ClInclude Include="App.xaml.h" />
    <ClInclude Include="MainWindow.xaml.h" />''', '''    <ClInclude Include="pch.h" />
    <ClInclude Include="App.xaml.h" />
    <ClInclude Include="MainWindow.xaml.h" />
    <ClInclude Include="SettingsStore.h" />
    <ClInclude Include="AppearancePage.xaml.h" />
    <ClInclude Include="NotificationsPage.xaml.h" />
    <ClInclude Include="PreferencesPage.xaml.h" />''')
src = src.replace('''    <ClCompile Include="App.xaml.cpp" />
    <ClCompile Include="MainWindow.xaml.cpp" />''', '''    <ClCompile Include="App.xaml.cpp" />
    <ClCompile Include="MainWindow.xaml.cpp" />
    <ClCompile Include="SettingsStore.cpp" />
    <ClCompile Include="AppearancePage.xaml.cpp" />
    <ClCompile Include="NotificationsPage.xaml.cpp" />
    <ClCompile Include="PreferencesPage.xaml.cpp" />''')
src = src.replace('''    <Midl Include="App.idl" />
    <Midl Include="MainWindow.idl" />''', '''    <Midl Include="App.idl" />
    <Midl Include="MainWindow.idl" />
    <Midl Include="AppearancePage.idl" />
    <Midl Include="NotificationsPage.idl" />
    <Midl Include="PreferencesPage.idl" />''')
src = src.replace('''    <ApplicationDefinition Include="App.xaml" />
    <Page Include="MainWindow.xaml" />''', '''    <ApplicationDefinition Include="App.xaml" />
    <Page Include="MainWindow.xaml" />
    <Page Include="AppearancePage.xaml" />
    <Page Include="NotificationsPage.xaml" />
    <Page Include="PreferencesPage.xaml" />''')
w('SettingsHub.vcxproj', src)

print('settings-hub part 2 written')
