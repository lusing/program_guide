#!/usr/bin/env python3
"""Generates the SettingsHub functional app (chapters 7/8/10-16/22/25)."""
import io
import os

BASE = os.path.join(os.path.dirname(__file__), '..', 'examples', '07-settings-hub')
NS = 'SettingsHub'
os.makedirs(os.path.join(BASE, 'Themes'), exist_ok=True)  # keep dir unused-safe
os.makedirs(BASE, exist_ok=True)


def w(name, content):
    with io.open(os.path.join(BASE, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)


# ---------- App / main / pch ----------
w('App.idl', '''namespace SettingsHub
{
    [default_interface]
    runtimeclass App : Microsoft.UI.Xaml.Application
    {
        App();
        void ApplyTheme(hstring theme);   // "light" / "dark" / "default" -- pages call through the projection
    }
}
''')
w('App.xaml', '''<Application
    x:Class="SettingsHub.App"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Application.Resources>
        <ResourceDictionary>
            <ResourceDictionary.MergedDictionaries>
                <XamlControlsResources xmlns="using:Microsoft.UI.Xaml.Controls" />
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Application.Resources>
</Application>
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

    private:
        Microsoft::UI::Xaml::Window m_window{ nullptr };
    };
}
''')
w('App.xaml.cpp', '''#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"
#include "SettingsStore.h"

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
        // RequestedTheme on the content root actually re-skins the whole tree (10 章 RadioButton 的真 payoff)
        if (auto root = m_window.Content().try_as<FrameworkElement>())
        {
            ElementTheme value = theme == L"dark"  ? ElementTheme::Dark
                               : theme == L"light" ? ElementTheme::Light
                                                    : ElementTheme::Default;
            root.RequestedTheme(value);
        }
    }
}
''')
w('main.cpp', '''#include <windows.h>
#include "App.xaml.h"
#include <winrt/Microsoft.UI.Xaml.h>

int __stdcall wWinMain(HINSTANCE, HINSTANCE, PWSTR, int showCommand)
{
    winrt::init_apartment();
    winrt::Microsoft::UI::Xaml::Application::Start(
        [](auto&&) { winrt::make<winrt::SettingsHub::implementation::App>(); });
    return 0;
}
''')
w('pch.h', '''#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <unknwn.h>
#include <restrictederrorinfo.h>
#include <hstring.h>

#undef GetCurrentTime

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Data.Json.h>
#include <winrt/Microsoft.UI.Dispatching.h>
#include <winrt/Microsoft.UI.Xaml.h>
#include <winrt/Microsoft.UI.Xaml.Controls.h>
#include <winrt/Microsoft.UI.Xaml.Controls.Primitives.h>
#include <winrt/Microsoft.UI.Xaml.Data.h>
#include <winrt/Microsoft.UI.Xaml.Interop.h>
#include <winrt/Microsoft.UI.Xaml.Markup.h>
#include <winrt/Microsoft.UI.Xaml.Media.h>
#include <winrt/Microsoft.UI.Xaml.Navigation.h>
#include <winrt/Microsoft.UI.Windowing.h>
#include <winrt/Windows.Graphics.h>

#include "App.xaml.h"
#include "MainWindow.xaml.h"
#include "SettingsStore.h"
#include "AppearancePage.xaml.h"
#include "NotificationsPage.xaml.h"
#include "PreferencesPage.xaml.h"
''')
w('pch.cpp', '#include "pch.h"\n')

# ---------- SettingsStore ----------
w('SettingsStore.h', '''// Services/SettingsStore.h -- %LOCALAPPDATA%\\SettingsHub\\settings.json (34 章路线)
#pragma once
#include <string>

namespace winrt::SettingsHub::implementation
{
    // 极简键值存取：教学用，够小够直白
    struct SettingsStore
    {
        static hstring Get(hstring const& key, hstring const& fallback);
        static void Put(hstring const& key, hstring const& value);
        static void Save();

    private:
        static std::wstring Path();
        static Windows::Data::Json::JsonObject Load();
        static Windows::Data::Json::JsonObject m_cache;
        static bool m_dirty;
    };
}
''')
w('SettingsStore.cpp', '''#include "pch.h"
#include "SettingsStore.h"

using namespace winrt;

namespace winrt::SettingsHub::implementation
{
    Windows::Data::Json::JsonObject SettingsStore::m_cache{ nullptr };
    bool SettingsStore::m_dirty{ false };

    std::wstring SettingsStore::Path()
    {
        wchar_t buffer[MAX_PATH]{};
        ::GetEnvironmentVariableW(L"LOCALAPPDATA", buffer, MAX_PATH);
        std::wstring dir = std::wstring(buffer) + L"\\\\SettingsHub";
        ::CreateDirectoryW(dir.c_str(), nullptr);
        return dir + L"\\\\settings.json";
    }

    Windows::Data::Json::JsonObject SettingsStore::Load()
    {
        if (m_cache) { return m_cache; }
        m_cache = Windows::Data::Json::JsonObject();
        HANDLE file = ::CreateFileW(Path().c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return m_cache; }
        std::string json;
        char chunk[4096];
        DWORD read = 0;
        while (::ReadFile(file, chunk, sizeof(chunk), &read, nullptr) && read > 0)
        {
            json.append(chunk, read);
        }
        ::CloseHandle(file);
        try
        {
            m_cache = Windows::Data::Json::JsonObject::Parse(to_hstring(json));
        }
        catch (hresult_error const&)
        {
            m_cache = Windows::Data::Json::JsonObject();   // 坏文件当空 (35 章 Storage 同款纪律)
        }
        return m_cache;
    }

    hstring SettingsStore::Get(hstring const& key, hstring const& fallback)
    {
        auto doc = Load();
        if (doc.HasKey(key))
        {
            return doc.GetNamedString(key);
        }
        return fallback;
    }

    void SettingsStore::Put(hstring const& key, hstring const& value)
    {
        Load();
        m_cache.Insert(key, Windows::Data::Json::JsonValue::CreateStringValue(value));
        m_dirty = true;
    }

    void SettingsStore::Save()
    {
        if (!m_dirty || !m_cache) { return; }
        auto text = m_cache.Stringify();
        HANDLE file = ::CreateFileW(Path().c_str(), GENERIC_WRITE, 0, nullptr,
            CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return; }
        std::string utf8;
        for (wchar_t ch : std::wstring_view(text))
        {
            if (ch < 0x80) { utf8.push_back(static_cast<char>(ch)); }
            else { utf8.push_back('?'); }
        }
        DWORD written = 0;
        ::WriteFile(file, utf8.data(), static_cast<DWORD>(utf8.size()), &written, nullptr);
        ::CloseHandle(file);
        m_dirty = false;
    }
}
''')

# ---------- MainWindow (shell + search + save feedback) ----------
w('MainWindow.idl', '''namespace SettingsHub
{
    [default_interface]
    runtimeclass MainWindow : Microsoft.UI.Xaml.Window
    {
        MainWindow();
        void ShowSaved();   // 各设置页保存后的全局反馈 (InfoBar)
    }
}
''')
w('MainWindow.xaml', '''<Window
    x:Class="SettingsHub.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- 22 章：NavigationView 外壳 + 15 章内建设置搜索位 -->
        <NavigationView x:Name="Nav" Grid.Row="0" IsBackButtonVisible="Collapsed"
                        PaneDisplayMode="Left" IsPaneOpen="True" OpenPaneLength="210"
                        SelectionChanged="OnNavSelectionChanged">
            <NavigationView.AutoSuggestBox>
                <AutoSuggestBox QueryIcon="Find" PlaceholderText="Search settings..."
                                TextChanged="OnSearchChanged"
                                SuggestionChosen="OnSearchChosen"/>
            </NavigationView.AutoSuggestBox>
            <NavigationView.MenuItems>
                <NavigationViewItem Content="Appearance" Tag="appearance">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE790;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                <NavigationViewItem Content="Notifications" Tag="notifications">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xEA8F;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                <NavigationViewItem Content="Preferences" Tag="preferences">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE713;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                <!-- 每章任务在此追加一个导航项 -->
            </NavigationView.MenuItems>
            <Frame x:Name="ContentFrame"/>
        </NavigationView>

        <!-- 25 章 InfoBar：保存反馈常驻条 -->
        <InfoBar x:Name="SavedBar" Grid.Row="1" IsOpen="False" IsClosable="True"
                 Severity="Success" Title="Saved"
                 Message="Your changes are written to %LOCALAPPDATA%\\SettingsHub\\settings.json"/>
    </Grid>
</Window>
''')
w('MainWindow.xaml.h', '''#pragma once
#include "MainWindow.g.h"

namespace winrt::SettingsHub::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void ShowSaved();

        void OnNavSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args);
        void OnSearchChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::AutoSuggestBoxTextChangedEventArgs const& args);
        void OnSearchChosen(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::AutoSuggestBoxSuggestionChosenEventArgs const& args);

    private:
        void NavigateTo(winrt::hstring const& tag);
        Windows::Foundation::Collections::IVector<Windows::Foundation::IInspectable> m_searchItems{ nullptr };
    };
}

namespace winrt::SettingsHub::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
''')
w('MainWindow.xaml.cpp', '''#include "pch.h"
#include "MainWindow.xaml.h"

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
            appWindow.Resize({ 1080, 800 });
        }
        ContentFrame().Navigate(xaml_typename<SettingsHub::AppearancePage>());
        Nav().SelectedItem(Nav().MenuItems().GetAt(0));
    }

    void MainWindow::ShowSaved()
    {
        SavedBar().IsOpen(true);   // 25 章：保存反馈真的出现
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
        hstring query = box.Text();
        auto hits = single_threaded_vector<IInspectable>();
        for (auto const& page : kPages)
        {
            std::wstring_view label(page[1]);
            if (query.empty() ||
                std::wstring_view(query).find(label) != std::wstring_view::npos ||
                label.find(std::wstring_view(query)) != std::wstring_view::npos)
            {
                hits.Append(box_value(page[1] + L"|" + page[0]));
            }
        }
        box.ItemsSource(hits);
    }

    void MainWindow::OnSearchChosen(IInspectable const&,
        AutoSuggestBoxSuggestionChosenEventArgs const& args)
    {
        // 建议格式 "Label|tag"：选了真的跳转对应分区
        auto text = args.SelectedItem().as<hstring>();
        uint32_t bar = static_cast<uint32_t>(text.find(L'|'));
        if (bar != std::wstring::npos)
        {
            NavigateTo(text.substr(bar + 1));
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
''')

print('settings-hub part 1 written')
