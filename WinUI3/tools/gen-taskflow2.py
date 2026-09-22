#!/usr/bin/env python3
"""TaskFlow part 2: pages + vcxproj."""
import io
import os

BASE = os.path.join(os.path.dirname(__file__), '..', 'examples', '35-taskflow')


def w(name, content):
    with io.open(os.path.join(BASE, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)


# App.idl gains SetMica (SettingsPage needs it through the projection)
w('App.idl', '''namespace TaskFlow
{
    [default_interface]
    runtimeclass App : Microsoft.UI.Xaml.Application
    {
        App();
        void SetMica(Boolean on);
    }
}
''')

w('SettingsPage.idl', '''namespace TaskFlow
{
    [default_interface]
    runtimeclass SettingsPage : Microsoft.UI.Xaml.Controls.Page
    {
        SettingsPage();
    }
}
''')
w('SettingsPage.xaml', '''<Page
    x:Class="TaskFlow.SettingsPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="14" MaxWidth="440">
            <TextBlock Text="Settings" FontSize="24" FontWeight="Bold"/>

            <!-- 31 章背景材质经 App 落到主窗口 -->
            <ToggleSwitch Header="Backdrop" OnContent="Mica" OffContent="Acrylic"
                          IsOn="True" Toggled="OnBackdropToggled"/>

            <TextBlock TextWrapping="Wrap" Opacity="0.7"
                       Text="任务数据保存在 %LOCALAPPDATA%\\TaskFlow\\tasks.json（非打包进程不能依赖 ApplicationData，34 章）。"/>
        </StackPanel>
    </Grid>
</Page>
''')
w('SettingsPage.xaml.h', '''#pragma once
#include "SettingsPage.g.h"

namespace winrt::TaskFlow::implementation
{
    struct SettingsPage : SettingsPageT<SettingsPage>
    {
        SettingsPage();

        void OnBackdropToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::TaskFlow::factory_implementation
{
    struct SettingsPage : SettingsPageT<SettingsPage, implementation::SettingsPage>
    {
    };
}
''')
w('SettingsPage.xaml.cpp', '''#include "pch.h"
#include "SettingsPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::TaskFlow::implementation
{
    SettingsPage::SettingsPage()
    {
        InitializeComponent();
    }

    void SettingsPage::OnBackdropToggled(IInspectable const&, RoutedEventArgs const&)
    {
        // 经投影的 App 接口把选择落到主窗口（SetMica 在 App.idl 里声明过）
        auto app = Microsoft::UI::Xaml::Application::Current().as<TaskFlow::App>();
        app.SetMica(true);
    }
}
''')

w('TaskListPage.xaml', '''<Page
    x:Class="TaskFlow.TaskListPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24" x:Name="rootPanel">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Spacing="12">
            <TextBlock Text="Tasks" FontSize="24" FontWeight="Bold" VerticalAlignment="Center"/>
            <TextBlock Text="{x:Bind ViewModel.Count, Mode=OneWay}" Opacity="0.6" VerticalAlignment="Center"/>
        </StackPanel>

        <TextBlock Grid.Row="1" Text="{x:Bind ViewModel.Status, Mode=OneWay}" Opacity="0.8" Margin="0,6,0,10"/>

        <Grid Grid.Row="2" RowDefinitions="Auto,*">
            <StackPanel Orientation="Horizontal" Spacing="8" Margin="0,0,0,10">
                <Button Content="Add task" Click="OnAddClicked" Style="{ThemeResource AccentButtonStyle}"/>
            </StackPanel>

            <ListView Grid.Row="1" x:Name="TaskList"
                      ItemsSource="{x:Bind ViewModel.Tasks, Mode=OneWay}">
                <ListView.ItemTemplate>
                    <DataTemplate x:DataType="local:Task">
                        <StackPanel Orientation="Horizontal" Spacing="10">
                            <CheckBox IsChecked="{x:Bind Done, Mode=TwoWay}"
                                      Checked="OnRowToggled" Unchecked="OnRowToggled"
                                      MinWidth="20"/>
                            <TextBlock Text="{x:Bind Title, Mode=OneWay}" VerticalAlignment="Center"/>
                            <Button Content="Remove" Click="OnRemoveClicked" MinWidth="10"
                                    Background="Transparent" BorderThickness="0" Opacity="0.6"
                                    VerticalAlignment="Center"/>
                        </StackPanel>
                    </DataTemplate>
                </ListView.ItemTemplate>
            </ListView>
        </Grid>
    </Grid>
</Page>
''')
w('TaskListPage.xaml.h', '''#pragma once
#include "TaskListPage.g.h"

namespace winrt::TaskFlow::implementation
{
    struct TaskListPage : TaskListPageT<TaskListPage>
    {
        TaskListPage();

        TaskFlow::TaskViewModel ViewModel();

        void OnAddClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRowToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRemoveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        TaskFlow::TaskViewModel m_viewModel{ nullptr };
        Windows::Foundation::IAsyncAction ShowAddDialogAsync();
    };
}

namespace winrt::TaskFlow::factory_implementation
{
    struct TaskListPage : TaskListPageT<TaskListPage, implementation::TaskListPage>
    {
    };
}
''')
w('TaskListPage.xaml.cpp', '''#include "pch.h"
#include "TaskListPage.xaml.h"
#include "TaskViewModel.h"
#include "Task.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::TaskFlow::implementation
{
    TaskListPage::TaskListPage()
    {
        InitializeComponent();
        m_viewModel = make<TaskViewModel>();
        m_viewModel.Load();
    }

    TaskFlow::TaskViewModel TaskListPage::ViewModel() { return m_viewModel; }

    void TaskListPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
    {
        (void)ShowAddDialogAsync();
    }

    Windows::Foundation::IAsyncAction TaskListPage::ShowAddDialogAsync()
    {
        // 24 章模式：ContentDialog 承载自定义表单（TextBox + 重要标记）
        TextBox input;
        input.Header(box_value(L"Task title"));
        input.PlaceholderText(L"what needs doing?");
        CheckBox important;
        important.Content(box_value(L"Important (adds !)"));

        StackPanel form;
        form.Spacing(12);
        form.Margin({ 0, 8, 0, 0 });
        form.Children().Append(input);
        form.Children().Append(important);

        ContentDialog dialog;
        dialog.Title(box_value(L"Add task"));
        dialog.Content(form);
        dialog.PrimaryButtonText(L"Add");
        dialog.CloseButtonText(L"Cancel");
        dialog.DefaultButton(ContentDialogButton::Primary);
        dialog.XamlRoot(rootPanel().XamlRoot());

        auto result = co_await dialog.ShowAsync();
        if (result == ContentDialogResult::Primary)
        {
            m_viewModel.Add(input.Text(), important.IsChecked().Value());
        }
    }

    void TaskListPage::OnRowToggled(IInspectable const& sender, RoutedEventArgs const&)
    {
        // 行内勾选变化：TwoWay 绑定已改 Task.Done，这里只负责持久化
        if (m_viewModel) { (void)m_viewModel.SaveAsync(); }
    }

    void TaskListPage::OnRemoveClicked(IInspectable const& sender, RoutedEventArgs const&)
    {
        auto item = sender.as<FrameworkElement>().DataContext().as<TaskFlow::Task>();
        m_viewModel.Remove(item);
    }
}
''')

# fix: the DataTemplate x:DataType uses "local:Task" but no xmlns:local -- switch to TaskFlow.Task via xmlns
s = io.open(os.path.join(BASE, 'TaskListPage.xaml'), encoding='utf-8').read()
s = s.replace('''    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
''', '''    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:local="using:TaskFlow">
''')
io.open(os.path.join(BASE, 'TaskListPage.xaml'), 'w', encoding='utf-8', newline='\n').write(s)

# vcxproj: clone the 07 gallery project shape
src = io.open(os.path.join(os.path.dirname(__file__), '..', 'examples', '07-controls-basic', 'BasicGallery.vcxproj'), encoding='utf-8').read()
import re
src = re.sub(r'    <ClInclude Include="\w+\.xaml\.h" />\n', '', src)
src = re.sub(r'    <ClCompile Include="\w+\.xaml\.cpp" />\n', '', src)
src = re.sub(r'    <Midl Include="\w+\.idl" />\n', '', src)
src = re.sub(r'    <Page Include="\w+\.xaml" />\n', '', src)
src = src.replace('{07a1b2c3-4d5e-4f60-8a9b-0c1d2e3f4a07}', '{35a1b2c3-4d5e-4f60-8a9b-0c1d2e3f4a35}')
src = src.replace('<RootNamespace>BasicGallery</RootNamespace>', '<RootNamespace>TaskFlow</RootNamespace>')
src = src.replace('    <ClInclude Include="pch.h" />', '''    <ClInclude Include="pch.h" />
    <ClInclude Include="MainWindow.xaml.h" />
    <ClInclude Include="TaskListPage.xaml.h" />
    <ClInclude Include="SettingsPage.xaml.h" />
    <ClInclude Include="Task.h" />
    <ClInclude Include="TaskViewModel.h" />
    <ClInclude Include="Storage.h" />''')
src = src.replace('    <ClCompile Include="App.xaml.cpp" />', '''    <ClCompile Include="App.xaml.cpp" />
    <ClCompile Include="MainWindow.xaml.cpp" />
    <ClCompile Include="TaskListPage.xaml.cpp" />
    <ClCompile Include="SettingsPage.xaml.cpp" />
    <ClCompile Include="Task.cpp" />
    <ClCompile Include="TaskViewModel.cpp" />
    <ClCompile Include="Storage.cpp" />''')
src = src.replace('    <Midl Include="App.idl" />', '''    <Midl Include="App.idl" />
    <Midl Include="MainWindow.idl" />
    <Midl Include="SettingsPage.idl" />
    <Midl Include="TaskFlow.idl" />''')
src = src.replace('    <Page Include="MainWindow.xaml" />', '''    <Page Include="MainWindow.xaml" />
    <Page Include="TaskListPage.xaml" />
    <Page Include="SettingsPage.xaml" />''')
w('TaskFlow.vcxproj', src)

print('part 2 written (pages + vcxproj)')
