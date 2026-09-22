#!/usr/bin/env python3
"""Generates Home + the five chapter pages (21-25) of the shell gallery."""
import io
import os

BASE = os.path.join(os.path.dirname(__file__), '..', 'examples', '21-controls-shell')
NS = 'ShellGallery'


def w(name, content):
    with io.open(os.path.join(BASE, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)


def idl(cls):
    return f'''namespace {NS}
{{
    [default_interface]
    runtimeclass {cls} : Microsoft.UI.Xaml.Controls.Page
    {{
        {cls}();
    }}
}}
'''


# ---------- HomePage ----------
w('HomePage.idl', idl('HomePage'))
w('HomePage.xaml', '''<Page
    x:Class="ShellGallery.HomePage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24" RowDefinitions="Auto,*">
        <TextBlock Text="Shell Controls Gallery" FontSize="28" FontWeight="Bold"/>
        <TextBlock Grid.Row="1" VerticalAlignment="Center" HorizontalAlignment="Center"
                   TextAlignment="Center" FontSize="16" Opacity="0.7" TextWrapping="Wrap">
            TabView / NavigationView / CommandBar / ContentDialog / 浮层五章的演示页。
        </TextBlock>
    </Grid>
</Page>
''')
w('HomePage.xaml.h', '''#pragma once
#include "HomePage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct HomePage : HomePageT<HomePage>
    {
        HomePage();
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct HomePage : HomePageT<HomePage, implementation::HomePage>
    {
    };
}
''')
w('HomePage.xaml.cpp', '''#include "pch.h"
#include "HomePage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::ShellGallery::implementation
{
    HomePage::HomePage()
    {
        InitializeComponent();
    }
}
''')

# ---------- TabViewPage (ch21) ----------
w('TabView.idl', idl('TabViewPage'))
w('TabViewPage.xaml', '''<Page
    x:Class="ShellGallery.TabViewPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="12" MaxWidth="560">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 21.2 TabView：文档页签 -->
            <TabView x:Name="Docs" Height="180"
                     SelectionChanged="OnTabSelectionChanged"
                     TabCloseRequested="OnTabCloseRequested"
                     AddTabButtonClick="OnAddTabClicked">
                <TabView.TabItems>
                    <TabViewItem Header="guide.md" IsClosable="False"/>
                    <TabViewItem Header="notes.md"/>
                    <TabViewItem Header="todo.md"/>
                </TabView.TabItems>
            </TabView>

            <!-- 21.3 Expander：折叠区 -->
            <Expander Header="Advanced options" Expanding="OnExpanderExpanding" Collapsed="OnExpanderCollapsed">
                <TextBlock Text="Options live here." Margin="8"/>
            </Expander>
        </StackPanel>
    </Grid>
</Page>
''')
w('TabViewPage.xaml.h', '''#pragma once
#include "TabViewPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct TabViewPage : TabViewPageT<TabViewPage>
    {
        TabViewPage();

        void OnTabSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnTabCloseRequested(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::TabViewTabCloseRequestedEventArgs const& args);
        void OnAddTabClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnExpanderExpanding(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnExpanderCollapsed(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct TabViewPage : TabViewPageT<TabViewPage, implementation::TabViewPage>
    {
    };
}
''')
w('TabViewPage.xaml.cpp', '''#include "pch.h"
#include "TabViewPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    TabViewPage::TabViewPage()
    {
        InitializeComponent();
    }

    void TabViewPage::OnTabSelectionChanged(IInspectable const&,
        SelectionChangedEventArgs const&)
    {
        if (!Docs() || !StatusText()) return;
        auto item = Docs().SelectedItem().as<TabViewItem>();
        StatusText().Text(L"tab = " + item.Header().as<hstring>());
    }

    void TabViewPage::OnTabCloseRequested(IInspectable const&,
        TabViewTabCloseRequestedEventArgs const& args)
    {
        // 关闭不自动发生：必须在这里真正移除 TabItems 里的那一项
        uint32_t index{};
        if (Docs().TabItems().IndexOf(args.Tab(), index))
        {
            Docs().TabItems().RemoveAt(index);
            StatusText().Text(L"closed a tab, left = " + to_hstring(Docs().TabItems().Size()));
        }
    }

    void TabViewPage::OnAddTabClicked(IInspectable const&, RoutedEventArgs const&)
    {
        TabViewItem item;
        item.Header(box_value(L"new " + to_hstring(Docs().TabItems().Size())));
        Docs().TabItems().Append(item);
        Docs().SelectedItem(item);
    }

    void TabViewPage::OnExpanderExpanding(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"expander expanding");
    }

    void TabViewPage::OnExpanderCollapsed(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"expander collapsed");
    }
}
''')

# ---------- NavPage (ch22) ----------
w('NavPage.idl', idl('NavPage'))
w('NavPage.xaml', '''<Page
    x:Class="ShellGallery.NavPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="12">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <StackPanel Orientation="Horizontal" Spacing="12">
                <Button Content="Left" Click="OnLeftClicked"/>
                <Button Content="Compact" Click="OnCompactClicked"/>
                <Button Content="Top" Click="OnTopClicked"/>
            </StackPanel>

            <!-- 22.2 页内第二个 NavigationView：外壳机制的活教材 -->
            <NavigationView x:Name="Embedded" Height="300" PaneDisplayMode="Left"
                            SelectionChanged="OnEmbeddedSelectionChanged">
                <NavigationView.MenuItems>
                    <NavigationViewItem Content="Inbox" Tag="inbox"/>
                    <NavigationViewItem Content="Sent" Tag="sent"/>
                    <NavigationViewItem Content="Drafts" Tag="drafts"/>
                </NavigationView.MenuItems>
                <TextBlock x:Name="EmbeddedContent" Text="(pick a pane item)"
                           HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </NavigationView>

            <!-- 22.4 SplitView：NavigationView 的底座 -->
            <SplitView x:Name="Split" Height="120" DisplayMode="Inline" OpenPaneLength="160"
                       PaneBackground="{ThemeResource LayerFillColorDefaultBrush}">
                <SplitView.Pane>
                    <TextBlock Text="pane" Margin="12"/>
                </SplitView.Pane>
                <TextBlock Text="content" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </SplitView>
            <Button Content="Toggle split pane" Click="OnToggleSplitClicked"/>
        </StackPanel>
    </Grid>
</Page>
''')
w('NavPage.xaml.h', '''#pragma once
#include "NavPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct NavPage : NavPageT<NavPage>
    {
        NavPage();

        void OnLeftClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnCompactClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTopClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnEmbeddedSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args);
        void OnToggleSplitClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct NavPage : NavPageT<NavPage, implementation::NavPage>
    {
    };
}
''')
w('NavPage.xaml.cpp', '''#include "pch.h"
#include "NavPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    NavPage::NavPage()
    {
        InitializeComponent();
    }

    void NavPage::OnLeftClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Embedded()) return;
        Embedded().PaneDisplayMode(NavigationViewPaneDisplayMode::Left);
        StatusText().Text(L"pane mode = Left");
    }

    void NavPage::OnCompactClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Embedded()) return;
        Embedded().PaneDisplayMode(NavigationViewPaneDisplayMode::LeftCompact);
        StatusText().Text(L"pane mode = LeftCompact");
    }

    void NavPage::OnTopClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Embedded()) return;
        Embedded().PaneDisplayMode(NavigationViewPaneDisplayMode::Top);
        StatusText().Text(L"pane mode = Top");
    }

    void NavPage::OnEmbeddedSelectionChanged(IInspectable const&,
        NavigationViewSelectionChangedEventArgs const& args)
    {
        if (!EmbeddedContent()) return;
        auto item = args.SelectedItem().as<NavigationViewItem>();
        EmbeddedContent().Text(L"section = " + unbox_value<hstring>(item.Tag()));
    }

    void NavPage::OnToggleSplitClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Split() || !StatusText()) return;
        Split().IsPaneOpen(!Split().IsPaneOpen());
        StatusText().Text(Split().IsPaneOpen() ? L"split pane open" : L"split pane closed");
    }
}
''')

# ---------- CommandBarPage (ch23) ----------
w('CommandBarPage.idl', idl('CommandBarPage'))
w('CommandBarPage.xaml', '''<Page
    x:Class="ShellGallery.CommandBarPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="12" MaxWidth="560">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 23.2 CommandBar：主命令 + 溢出 -->
            <CommandBar DefaultLabelPosition="Right" IsOpen="False">
                <AppBarButton Icon="Add" Label="Add" Click="OnAddClicked"/>
                <AppBarButton Icon="Save" Label="Save" Click="OnSaveClicked"/>
                <AppBarSeparator/>
                <AppBarToggleButton Icon="Favorite" Label="Pin" Click="OnPinClicked"/>
                <CommandBar.SecondaryCommands>
                    <AppBarButton Icon="Setting" Label="Settings" Click="OnSettingsClicked"/>
                </CommandBar.SecondaryCommands>
            </CommandBar>

            <!-- 23.3 MenuBar：经典菜单栏 -->
            <MenuBar>
                <MenuBarItem Title="File">
                    <MenuFlyoutItem Text="New" Click="OnMenuNew"/>
                    <MenuFlyoutSeparator/>
                    <MenuFlyoutItem Text="Exit" Click="OnMenuExit"/>
                </MenuBarItem>
                <MenuBarItem Title="View">
                    <ToggleMenuFlyoutItem Text="Show grid" IsChecked="True" Click="OnMenuGrid"/>
                </MenuBarItem>
            </MenuBar>

            <!-- 23.4 右键上下文菜单：AttachedFlyout 模式 -->
            <Border x:Name="CtxZone" Height="80" BorderThickness="1"
                    BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                    Background="{ThemeResource CardBackgroundFillColorSecondaryBrush}"
                    RightTapped="OnCtxZoneRightTapped">
                <TextBlock Text="right-click / long-press here" HorizontalAlignment="Center" VerticalAlignment="Center" Opacity="0.6"/>
                <FlyoutBase.AttachedFlyout>
                    <MenuFlyout>
                        <MenuFlyoutItem Text="Refresh" Click="OnMenuRefresh"/>
                        <MenuFlyoutItem Text="Delete" Click="OnMenuDelete"/>
                    </MenuFlyout>
                </FlyoutBase.AttachedFlyout>
            </Border>
        </StackPanel>
    </Grid>
</Page>
''')
w('CommandBarPage.xaml.h', '''#pragma once
#include "CommandBarPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct CommandBarPage : CommandBarPageT<CommandBarPage>
    {
        CommandBarPage();

        void OnAddClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSaveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnPinClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSettingsClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnMenuNew(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnMenuExit(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnMenuGrid(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnCtxZoneRightTapped(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Input::RightTappedRoutedEventArgs const& args);
        void OnMenuRefresh(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnMenuDelete(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct CommandBarPage : CommandBarPageT<CommandBarPage, implementation::CommandBarPage>
    {
    };
}
''')
w('CommandBarPage.xaml.cpp', '''#include "pch.h"
#include "CommandBarPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::UI::Xaml::Controls::Primitives;

namespace winrt::ShellGallery::implementation
{
    CommandBarPage::CommandBarPage()
    {
        InitializeComponent();
    }

    void CommandBarPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"command: add");
    }

    void CommandBarPage::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"command: save");
    }

    void CommandBarPage::OnPinClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"command: pin");
    }

    void CommandBarPage::OnSettingsClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"command: settings");
    }

    void CommandBarPage::OnMenuNew(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"menu: new");
    }

    void CommandBarPage::OnMenuExit(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"menu: exit");
    }

    void CommandBarPage::OnMenuGrid(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"menu: toggle grid");
    }

    void CommandBarPage::OnCtxZoneRightTapped(IInspectable const& sender,
        Input::RightTappedRoutedEventArgs const& args)
    {
        // 上下文菜单标准模式：AttachedFlyout + RightTapped + ShowAt(位置)
        auto element = sender.as<FrameworkElement>();
        FlyoutBase::GetAttachedFlyout(element).ShowAt(element, args.GetPosition(element));
        args.Handled(true);
        if (!StatusText()) return;
        StatusText().Text(L"context flyout shown");
    }

    void CommandBarPage::OnMenuRefresh(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"context: refresh");
    }

    void CommandBarPage::OnMenuDelete(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"context: delete");
    }
}
''')

# ---------- DialogsPage (ch24) ----------
w('DialogsPage.idl', idl('DialogsPage'))
w('DialogsPage.xaml', '''<Page
    x:Class="ShellGallery.DialogsPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24" x:Name="rootPanel">
        <StackPanel Spacing="12" MaxWidth="480">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <Button Content="Show dialog" Click="OnShowDialogClicked"/>

            <!-- 24.4 Button.Flyout 语法糖：轻浮层 -->
            <Button Content="Quick actions">
                <Button.Flyout>
                    <Flyout Placement="Bottom">
                        <StackPanel Spacing="8">
                            <Button Content="Retry" Click="OnRetryClicked"/>
                            <Button Content="Skip" Click="OnSkipClicked"/>
                        </StackPanel>
                    </Flyout>
                </Button.Flyout>
            </Button>
        </StackPanel>
    </Grid>
</Page>
''')
w('DialogsPage.xaml.h', '''#pragma once
#include "DialogsPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct DialogsPage : DialogsPageT<DialogsPage>
    {
        DialogsPage();

        void OnShowDialogClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRetryClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSkipClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        winrt::Windows::Foundation::IAsyncAction ShowDialogAsync();
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct DialogsPage : DialogsPageT<DialogsPage, implementation::DialogsPage>
    {
    };
}
''')
w('DialogsPage.xaml.cpp', '''#include "pch.h"
#include "DialogsPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    DialogsPage::DialogsPage()
    {
        InitializeComponent();
    }

    void DialogsPage::OnShowDialogClicked(IInspectable const&, RoutedEventArgs const&)
    {
        (void)ShowDialogAsync();
    }

    winrt::Windows::Foundation::IAsyncAction DialogsPage::ShowDialogAsync()
    {
        ContentDialog dialog;
        dialog.Title(box_value(L"Confirm removal"));
        dialog.Content(box_value(L"ContentDialog from a Page: XamlRoot still comes from the content tree root."));
        dialog.PrimaryButtonText(L"Remove");
        dialog.SecondaryButtonText(L"Keep");
        dialog.CloseButtonText(L"Cancel");
        dialog.DefaultButton(ContentDialogButton::Primary);

        // 24.2 核心坑：XamlRoot 从内容树根取（Window 自己没有这个成员）
        dialog.XamlRoot(rootPanel().XamlRoot());

        auto result = co_await dialog.ShowAsync();
        hstring verdict = result == ContentDialogResult::Primary ? L"primary: removed"
                       : result == ContentDialogResult::Secondary ? L"secondary: kept"
                                                                   : L"dismissed";
        if (!StatusText()) co_return;
        StatusText().Text(verdict);
    }

    void DialogsPage::OnRetryClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"flyout: retry");
    }

    void DialogsPage::OnSkipClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"flyout: skip");
    }
}
''')

# ---------- OverlaysPage (ch25) ----------
w('OverlaysPage.idl', idl('OverlaysPage'))
w('OverlaysPage.xaml', '''<Page
    x:Class="ShellGallery.OverlaysPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="12" MaxWidth="480">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 25.2 TeachingTip：非模态教学气泡 -->
            <Button x:Name="TipTarget" Content="Show teaching tip" Click="OnTipClicked"/>
            <TeachingTip x:Name="Tip"
                         Title="Did you know?"
                         Subtitle="TeachingTip is non-modal: the app keeps working."
                         CloseButtonContent="Got it"
                         Target="{x:Bind TipTarget}"
                         ActionButtonClick="OnTipAction"
                         Placement="Bottom"/>

            <!-- 25.3 InfoBar：常驻/自动消失的条状通知 -->
            <InfoBar x:Name="Notice" IsOpen="False" Title="Sync finished"
                     Message="Everything is up to date." Severity="Success"
                     IsClosable="True" CloseButtonClick="OnInfoBarClosed"/>

            <StackPanel Orientation="Horizontal" Spacing="12">
                <Button Content="Cycle severity" Click="OnCycleSeverityClicked"/>
            </StackPanel>

            <!-- 25.4 ToolTip：附加属性 + 富内容 -->
            <TextBlock Text="hover me for a rich tooltip">
                <ToolTipService.ToolTip>
                    <StackPanel MaxWidth="220" Spacing="4">
                        <TextBlock FontWeight="SemiBold" Text="Rich tooltip"/>
                        <TextBlock TextWrapping="Wrap" Opacity="0.7"
                                   Text="A ToolTip can host any element tree, not just text."/>
                    </StackPanel>
                </ToolTipService.ToolTip>
            </TextBlock>
        </StackPanel>
    </Grid>
</Page>
''')
w('OverlaysPage.xaml.h', '''#pragma once
#include "OverlaysPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct OverlaysPage : OverlaysPageT<OverlaysPage>
    {
        OverlaysPage();

        void OnTipClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTipAction(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnInfoBarClosed(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnCycleSeverityClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        int m_severity{ 1 };
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct OverlaysPage : OverlaysPageT<OverlaysPage, implementation::OverlaysPage>
    {
    };
}
''')
w('OverlaysPage.xaml.cpp', '''#include "pch.h"
#include "OverlaysPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    OverlaysPage::OverlaysPage()
    {
        InitializeComponent();
    }

    void OverlaysPage::OnTipClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Tip()) return;
        Tip().IsOpen(!Tip().IsOpen());
        StatusText().Text(Tip().IsOpen() ? L"tip open" : L"tip closed");
    }

    void OverlaysPage::OnTipAction(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"tip action clicked");
    }

    void OverlaysPage::OnInfoBarClosed(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"info bar closed");
    }

    void OverlaysPage::OnCycleSeverityClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Notice() || !StatusText()) return;
        // 严重度循环：Informational -> Success -> Warning -> Error
        static InfoBarSeverity const severities[]{
            InfoBarSeverity::Informational, InfoBarSeverity::Success,
            InfoBarSeverity::Warning, InfoBarSeverity::Error,
        };
        static hstring const names[]{ L"informational", L"success", L"warning", L"error" };
        m_severity = (m_severity + 1) % 4;
        Notice().Severity(severities[m_severity]);
        Notice().Title(names[m_severity]);
        Notice().IsOpen(true);
        StatusText().Text(L"severity = " + names[m_severity]);
    }
}
''')

print('shell pages written')
