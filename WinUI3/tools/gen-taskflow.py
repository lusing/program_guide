#!/usr/bin/env python3
"""Generates the TaskFlow capstone project (chapter 35)."""
import io
import os

BASE = os.path.join(os.path.dirname(__file__), '..', 'examples', '35-taskflow')
NS = 'TaskFlow'
os.makedirs(BASE, exist_ok=True)


def w(name, content):
    with io.open(os.path.join(BASE, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)


# ---------- App / main / pch ----------
w('App.idl', '''namespace TaskFlow
{
    [default_interface]
    runtimeclass App : Microsoft.UI.Xaml.Application
    {
        App();
    }
}
''')
w('App.xaml', '''<Application
    x:Class="TaskFlow.App"
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

namespace winrt::TaskFlow::implementation
{
    struct App : AppT<App>
    {
        App();

        void OnLaunched(Microsoft::UI::Xaml::LaunchActivatedEventArgs const&);

        // 35 章：SettingsPage 经此开关主窗口背景材质（窗口归 App 持有，04 章模式）
        void SetMica(bool on);

    private:
        Microsoft::UI::Xaml::Window window{ nullptr };
    };
}
''')
w('App.xaml.cpp', '''#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::TaskFlow::implementation
{
    App::App()
    {
        InitializeComponent();
    }

    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        window = make<MainWindow>();
        window.Activate();
    }

    void App::SetMica(bool on)
    {
        if (auto main = window.as<MainWindow>())
        {
            main.SetBackdrop(on);
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
        [](auto&&) { winrt::make<winrt::TaskFlow::implementation::App>(); });
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
#include <winrt/Windows.Storage.h>
#include <winrt/Microsoft.UI.Composition.h>
#include <winrt/Microsoft.UI.Dispatching.h>
#include <winrt/Microsoft.UI.Xaml.h>
#include <winrt/Microsoft.UI.Xaml.Controls.h>
#include <winrt/Microsoft.UI.Xaml.Controls.Primitives.h>
#include <winrt/Microsoft.UI.Xaml.Data.h>
#include <winrt/Microsoft.UI.Xaml.Interop.h>
#include <winrt/Microsoft.UI.Xaml.Markup.h>
#include <winrt/Microsoft.UI.Xaml.Media.h>
#include <winrt/Microsoft.UI.Xaml.Navigation.h>
#include <winrt/Microsoft.UI.Xaml.Shapes.h>
#include <winrt/Microsoft.UI.Windowing.h>
#include <winrt/Windows.Graphics.h>

// XamlTypeInfo names every x:Class type through this header.
#include "App.xaml.h"
#include "MainWindow.xaml.h"
#include "TaskListPage.xaml.h"
#include "SettingsPage.xaml.h"
#include "Task.h"
#include "TaskViewModel.h"
#include "Storage.h"
''')
w('pch.cpp', '#include "pch.h"\n')

# ---------- MainWindow (NavigationView shell) ----------
w('MainWindow.idl', '''namespace TaskFlow
{
    [default_interface]
    runtimeclass MainWindow : Microsoft.UI.Xaml.Window
    {
        MainWindow();
        void SetBackdrop(Boolean mica);
    }
}
''')
w('MainWindow.xaml', '''<Window
    x:Class="TaskFlow.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <NavigationView x:Name="Nav" IsBackButtonVisible="Collapsed"
                    PaneDisplayMode="Left" IsPaneOpen="True" OpenPaneLength="190"
                    SelectionChanged="OnNavSelectionChanged">
        <NavigationView.MenuItems>
            <NavigationViewItem Content="Tasks" Tag="tasks" IsSelected="True"/>
            <NavigationViewItem Content="Settings" Tag="settings"/>
        </NavigationView.MenuItems>
        <Frame x:Name="ContentFrame"/>
    </NavigationView>
</Window>
''')
w('MainWindow.xaml.h', '''#pragma once
#include "MainWindow.g.h"

namespace winrt::TaskFlow::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void SetBackdrop(bool mica);

        void OnNavSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args);

    private:
        void NavigateTo(winrt::hstring const& tag);
    };
}

namespace winrt::TaskFlow::factory_implementation
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
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::TaskFlow::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"TaskFlow");
        if (auto appWindow = AppWindow())
        {
            appWindow.Resize({ 1100, 800 });
        }
        // 31 章：内容延伸进标题栏之外，Mica 贯通（此处保持系统标题栏，简化）
        SystemBackdrop(MicaBackdrop());
        ContentFrame().Navigate(xaml_typename<TaskFlow::TaskListPage>());
    }

    void MainWindow::SetBackdrop(bool mica)
    {
        SystemBackdrop(mica ? Microsoft::UI::Xaml::Media::MicaBackdrop()
                            : Microsoft::UI::Xaml::Media::DesktopAcrylicBackdrop());
    }

    void MainWindow::OnNavSelectionChanged(IInspectable const&,
        NavigationViewSelectionChangedEventArgs const& args)
    {
        if (auto item = args.SelectedItem().try_as<NavigationViewItem>())
        {
            NavigateTo(winrt::unbox_value<winrt::hstring>(item.Tag()));
        }
    }

    void MainWindow::NavigateTo(winrt::hstring const& tag)
    {
        if (tag == L"tasks") ContentFrame().Navigate(xaml_typename<TaskFlow::TaskListPage>());
        if (tag == L"settings") ContentFrame().Navigate(xaml_typename<TaskFlow::SettingsPage>());
    }
}
''')

# ---------- Task model + TaskViewModel (idl shared with TaskListPage) ----------
w('TaskFlow.idl', '''// Model + ViewModel + page live in ONE idl: TaskListPage's x:Bind paths reference
// TaskViewModel/Task, and MIDL only resolves within the same file (MIDL2011).
namespace TaskFlow
{
    [default_interface]
    runtimeclass Task : Microsoft.UI.Xaml.Data.INotifyPropertyChanged
    {
        Task(hstring title);
        String Title;
        Boolean Done;
    }

    [default_interface]
    runtimeclass TaskViewModel : Microsoft.UI.Xaml.Data.INotifyPropertyChanged
    {
        TaskViewModel();

        String Status;
        Int32 Count { get; };
        Windows.Foundation.Collections.IObservableVector<TaskFlow.Task> Tasks { get; };

        void Add(hstring title, boolean important);
        void Toggle(TaskFlow.Task item);
        void Remove(TaskFlow.Task item);
        void Load();
        Windows.Foundation.IAsyncAction SaveAsync();
    }

    [default_interface]
    runtimeclass TaskListPage : Microsoft.UI.Xaml.Controls.Page
    {
        TaskListPage();
        TaskFlow.TaskViewModel ViewModel { get; };
    }
}
''')
w('Task.h', '''// Models/Task.h -- INPC model, see docs/32-binding-mvvm.md 32.2
#pragma once
#include "Task.g.h"

namespace winrt::TaskFlow::implementation
{
    struct Task : TaskT<Task>
    {
        Task() = default;
        Task(hstring const& title);

        hstring Title();
        void Title(hstring const& value);
        bool Done();
        void Done(bool value);

        winrt::event_token PropertyChanged(
            Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler);
        void PropertyChanged(winrt::event_token const& token);

    private:
        hstring m_title;
        bool m_done{ false };
        winrt::event<Microsoft::UI::Xaml::Data::PropertyChangedEventHandler> m_propertyChanged;

        void RaisePropertyChanged(hstring const& name);
    };
}

namespace winrt::TaskFlow::factory_implementation
{
    struct Task : TaskT<Task, implementation::Task>
    {
    };
}
''')
w('Task.cpp', '''#include "pch.h"
#include "Task.h"

namespace winrt::TaskFlow::implementation
{
    Task::Task(hstring const& title) : m_title(title) {}

    hstring Task::Title() { return m_title; }
    void Task::Title(hstring const& value)
    {
        if (m_title != value) { m_title = value; RaisePropertyChanged(L"Title"); }
    }

    bool Task::Done() { return m_done; }
    void Task::Done(bool value)
    {
        if (m_done != value) { m_done = value; RaisePropertyChanged(L"Done"); }
    }

    winrt::event_token Task::PropertyChanged(
        Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler)
    {
        return m_propertyChanged.add(handler);
    }
    void Task::PropertyChanged(winrt::event_token const& token)
    {
        m_propertyChanged.remove(token);
    }

    void Task::RaisePropertyChanged(hstring const& name)
    {
        m_propertyChanged(*this, Microsoft::UI::Xaml::Data::PropertyChangedEventArgs(name));
    }
}
''')
w('TaskViewModel.h', '''// ViewModels/TaskViewModel.h -- see docs/32-binding-mvvm.md 32.3 / 32.4 / 32.7
#pragma once
#include "TaskViewModel.g.h"
#include "Storage.h"

namespace winrt::TaskFlow::implementation
{
    struct TaskViewModel : TaskViewModelT<TaskViewModel>
    {
        TaskViewModel();

        hstring Status();
        void Status(hstring const& value);
        int32_t Count();

        Windows::Foundation::Collections::IObservableVector<TaskFlow::Task> Tasks();

        void Add(hstring const& title, boolean important);
        void Toggle(TaskFlow::Task const& item);
        void Remove(TaskFlow::Task const& item);
        void Load();
        Windows::Foundation::IAsyncAction SaveAsync();

        winrt::event_token PropertyChanged(
            Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler);
        void PropertyChanged(winrt::event_token const& token);

    private:
        winrt::event<Microsoft::UI::Xaml::Data::PropertyChangedEventHandler> m_propertyChanged;
        Windows::Foundation::Collections::IObservableVector<TaskFlow::Task> m_tasks{ nullptr };
        hstring m_status;

        void RaisePropertyChanged(hstring const& name);
    };
}

namespace winrt::TaskFlow::factory_implementation
{
    struct TaskViewModel : TaskViewModelT<TaskViewModel, implementation::TaskViewModel>
    {
    };
}
''')
w('TaskViewModel.cpp', '''#include "pch.h"
#include "TaskViewModel.h"
#include "Task.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::TaskFlow::implementation
{
    TaskViewModel::TaskViewModel()
    {
        m_tasks = single_threaded_observable_vector<TaskFlow::Task>();
        Status(L"Ready");
    }

    hstring TaskViewModel::Status() { return m_status; }
    void TaskViewModel::Status(hstring const& value)
    {
        if (m_status != value) { m_status = value; RaisePropertyChanged(L"Status"); }
    }

    int32_t TaskViewModel::Count() { return static_cast<int32_t>(m_tasks.Size()); }

    Windows::Foundation::Collections::IObservableVector<TaskFlow::Task> TaskViewModel::Tasks()
    {
        return m_tasks;
    }

    void TaskViewModel::Add(hstring const& title, boolean important)
    {
        if (title.empty()) { return; }
        hstring finalTitle = important ? title + L" !" : title;
        m_tasks.Append(make<Task>(finalTitle));
        RaisePropertyChanged(L"Count");
        Status(L"Added: " + finalTitle);
        (void)SaveAsync();
    }

    void TaskViewModel::Toggle(TaskFlow::Task const& item)
    {
        item.Done(!item.Done());
        Status(item.Done() ? L"finished a task" : L"reopened a task");
        (void)SaveAsync();
    }

    void TaskViewModel::Remove(TaskFlow::Task const& item)
    {
        uint32_t index = 0;
        if (m_tasks.IndexOf(item, index))
        {
            m_tasks.RemoveAt(index);
            RaisePropertyChanged(L"Count");
            Status(L"removed a task");
            (void)SaveAsync();
        }
    }

    void TaskViewModel::Load()
    {
        // 启动路径的同步读盘（文件极小）；异步后台模式已在 32 章工程完整演示，
        // 这里刻意走简单路径，35 章只关注"持久化闭环"本身
        for (auto const& title : Storage::LoadTitles())
        {
            m_tasks.Append(make<Task>(title));
        }
        RaisePropertyChanged(L"Count");
        Status(L"Loaded " + to_hstring(m_tasks.Size()) + L" tasks");
    }

    Windows::Foundation::IAsyncAction TaskViewModel::SaveAsync()
    {
        auto strong = get_strong();
        // 在 UI 线程拷贝标题快照（IObservableVector 不能跨线程碰）
        std::vector<hstring> titles;
        titles.reserve(m_tasks.Size());
        for (auto const& t : m_tasks) { titles.push_back(t.Title()); }

        co_await winrt::resume_background();
        Storage::SaveTitles(titles);
        co_return;
    }

    winrt::event_token TaskViewModel::PropertyChanged(
        Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler)
    {
        return m_propertyChanged.add(handler);
    }
    void TaskViewModel::PropertyChanged(winrt::event_token const& token)
    {
        m_propertyChanged.remove(token);
    }

    void TaskViewModel::RaisePropertyChanged(hstring const& name)
    {
        m_propertyChanged(*this, Microsoft::UI::Xaml::Data::PropertyChangedEventArgs(name));
    }
}
''')

# ---------- Storage (JSON + LOCALAPPDATA) ----------
w('Storage.h', '''// Services/Storage.h -- JSON persistence under %LOCALAPPDATA%\\TaskFlow
// (34 章：非打包进程不能依赖 ApplicationData，退回 Win32 环境变量)
#pragma once
#include <string>
#include <vector>

namespace winrt::TaskFlow::implementation
{
    struct Storage
    {
        static std::wstring TasksFilePath();
        static std::vector<winrt::hstring> LoadTitles();
        static void SaveTitles(std::vector<winrt::hstring> const& titles);
    };
}
''')
w('Storage.cpp', '''#include "pch.h"
#include "Storage.h"

#include <shlwapi.h>

using namespace winrt;

namespace winrt::TaskFlow::implementation
{
    std::wstring Storage::TasksFilePath()
    {
        wchar_t buffer[MAX_PATH]{};
        ::GetEnvironmentVariableW(L"LOCALAPPDATA", buffer, MAX_PATH);
        std::wstring dir = std::wstring(buffer) + L"\\\\TaskFlow";
        ::CreateDirectoryW(dir.c_str(), nullptr);   // 已存在则失败，无害
        return dir + L"\\\\tasks.json";
    }

    std::vector<hstring> Storage::LoadTitles()
    {
        std::vector<hstring> titles;
        auto path = TasksFilePath();
        HANDLE file = ::CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return titles; }

        std::string json;
        char chunk[4096];
        DWORD read = 0;
        while (::ReadFile(file, chunk, sizeof(chunk), &read, nullptr) && read > 0)
        {
            json.append(chunk, read);
        }
        ::CloseHandle(file);

        // Windows.Data.Json 解析（34 章 JSON 一节同款）；坏文件当空处理
        try
        {
            auto arr = Windows::Data::Json::JsonArray::Parse(to_hstring(json));
            for (auto&& v : arr)
            {
                titles.push_back(v.GetString());
            }
        }
        catch (winrt::hresult_error const&)
        {
        }
        return titles;
    }

    void Storage::SaveTitles(std::vector<hstring> const& titles)
    {
        auto path = TasksFilePath();
        auto arr = Windows::Data::Json::JsonArray();
        for (auto const& t : titles) { arr.Append(Windows::Data::Json::JsonValue::CreateStringValue(t)); }
        auto content = arr.Stringify();

        HANDLE file = ::CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr,
            CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return; }
        auto wide = std::wstring(content);
        std::string utf8;
        for (wchar_t ch : wide)
        {
            if (ch < 0x80) { utf8.push_back(static_cast<char>(ch)); }
            else { utf8.push_back('?'); }   // 教学工程：标题按 ASCII 存放
        }
        DWORD written = 0;
        ::WriteFile(file, utf8.data(), static_cast<DWORD>(utf8.size()), &written, nullptr);
        ::CloseHandle(file);
    }
}
''')

