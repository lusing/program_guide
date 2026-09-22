#!/usr/bin/env python3
"""Generates Home + the five chapter pages (26-30) of the customization gallery."""
import io
import os

BASE = os.path.join(os.path.dirname(__file__), '..', 'examples', '26-customization')
NS = 'CustomGallery'


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
    x:Class="CustomGallery.HomePage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24" RowDefinitions="Auto,*">
        <TextBlock Text="Customization Gallery" FontSize="28" FontWeight="Bold"/>
        <TextBlock Grid.Row="1" VerticalAlignment="Center" HorizontalAlignment="Center"
                   TextAlignment="Center" FontSize="16" Opacity="0.7" TextWrapping="Wrap">
            样式模板 / 自定义控件 / VSM 自适应 / 动画 / 图形媒体五章的演示页。
        </TextBlock>
    </Grid>
</Page>
''')
w('HomePage.xaml.h', '''#pragma once
#include "HomePage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct HomePage : HomePageT<HomePage>
    {
        HomePage();
    };
}

namespace winrt::CustomGallery::factory_implementation
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

namespace winrt::CustomGallery::implementation
{
    HomePage::HomePage()
    {
        InitializeComponent();
    }
}
''')

# ---------- StylesPage (ch26) ----------
w('StylesPage.idl', idl('StylesPage'))
w('StylesPage.xaml', '''<Page
    x:Class="CustomGallery.StylesPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

        <StackPanel Grid.Row="1" Spacing="16" MaxWidth="520" Margin="0,16,0,0">
            <!-- 26.2 隐式样式：无 key，作用于本页所有 Button -->
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <StackPanel Spacing="16">
                <Button Content="Implicit styled #1" Click="OnStyledClicked"/>
                <Button Content="Implicit styled #2" Click="OnStyledClicked"/>

                <!-- 26.3 显式 keyed 样式 + BasedOn 继承 -->
                <Button Content="Explicit accent" Style="{StaticResource AccentBtn}"/>
                <Button Content="Unstyled default" Style="{StaticResource DefaultBtn}"/>

                <!-- 26.4 ControlTemplate：模板重造的按钮（交互能力保留） -->
                <Button Content="Templated round" Click="OnTemplatedClicked">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="PART_Border" CornerRadius="18"
                                    Background="{ThemeResource AccentFillColorDefaultBrush}"
                                    Padding="20,10" BorderThickness="1">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                                  TextElement.Foreground="{ThemeResource TextOnAccentFillColorDefaultBrush}"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <!-- WinUI 3 无 Triggers；hover 态在 28 章 VSM 里做 -->
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </StackPanel>
        </StackPanel>
    </Grid>

    <Page.Resources>
        <!-- 隐式样式：TargetType 即作用域（无 x:Key） -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="{ThemeResource CardBackgroundFillColorSecondaryBrush}"/>
            <Setter Property="BorderBrush" Value="{ThemeResource AccentFillColorDefaultBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="CornerRadius" Value="6"/>
        </Style>

        <!-- 显式样式 + BasedOn（继承上面的隐式再改） -->
        <Style x:Key="AccentBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="{ThemeResource AccentFillColorDefaultBrush}"/>
            <Setter Property="Foreground" Value="{ThemeResource TextOnAccentFillColorDefaultBrush}"/>
        </Style>
        <!-- 回到控件默认模板主题样式的路线 -->
        <Style x:Key="DefaultBtn" TargetType="Button"/>
    </Page.Resources>
</Page>
''')
w('StylesPage.xaml.h', '''#pragma once
#include "StylesPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct StylesPage : StylesPageT<StylesPage>
    {
        StylesPage();

        void OnStyledClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTemplatedClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct StylesPage : StylesPageT<StylesPage, implementation::StylesPage>
    {
    };
}
''')
w('StylesPage.xaml.cpp', '''#include "pch.h"
#include "StylesPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::CustomGallery::implementation
{
    StylesPage::StylesPage()
    {
        InitializeComponent();
    }

    void StylesPage::OnStyledClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"styled button works");
    }

    void StylesPage::OnTemplatedClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"templated button works");
    }
}
''')

# ---------- CustomControlPage (ch27) ----------
w('CustomControlPage.idl', '''// Chapter 27: page + templated custom control LabeledValueControl live in this one
// .idl because the page's x:Bind path references the control type (MIDL2011 guard).
namespace CustomGallery
{
    [default_interface]
    runtimeclass CustomControlPage : Microsoft.UI.Xaml.Controls.Page
    {
        CustomControlPage();
    }

    [default_interface]
    runtimeclass LabeledValueControl : Microsoft.UI.Xaml.Controls.Control
    {
        LabeledValueControl();

        Windows.Foundation.IReference<hstring> Label;
        Windows.Foundation.IReference<hstring> Value;
    }
}
''')
w('CustomControlPage.xaml', '''<Page
    x:Class="CustomGallery.CustomControlPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:local="using:CustomGallery">

    <Grid Margin="24">
        <StackPanel Spacing="16" MaxWidth="520">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 27.2 UserControl：组合现成控件 -->
            <local:TitleRow x:Name="Row" Title="Tasks done" Value="7"/>

            <!-- 27.3 templated control：默认样式来自 Generic.xaml -->
            <local:LabeledValueControl x:Name="Meter" Label="progress" Value="0"/>
            <StackPanel Orientation="Horizontal" Spacing="12">
                <Button Content="Bump value" Click="OnBumpClicked"/>
                <Button Content="Read title row" Click="OnReadRowClicked"/>
            </StackPanel>
        </StackPanel>
    </Grid>
</Page>
''')
w('CustomControlPage.xaml.h', '''#pragma once
#include "CustomControlPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct CustomControlPage : CustomControlPageT<CustomControlPage>
    {
        CustomControlPage();

        void OnBumpClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnReadRowClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        int m_value{ 0 };
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct CustomControlPage : CustomControlPageT<CustomControlPage, implementation::CustomControlPage>
    {
    };
}
''')
w('CustomControlPage.xaml.cpp', '''#include "pch.h"
#include "CustomControlPage.xaml.h"
#include "LabeledValueControl.xaml.h"
#include "TitleRow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::CustomGallery::implementation
{
    CustomControlPage::CustomControlPage()
    {
        InitializeComponent();
    }

    void CustomControlPage::OnBumpClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Meter() || !StatusText()) return;
        Meter().Value(box_value(to_hstring(m_value += 1)));
        StatusText().Text(L"value = " + to_hstring(m_value));
    }

    void CustomControlPage::OnReadRowClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Row() || !StatusText()) return;
        StatusText().Text(L"title row = " + Row().Title() + L" / " + Row().Value());
    }
}
''')
# tiny member for the page
extra = '''
'''
w('CustomControlPage.xaml.h.extra', extra)

# LabeledValueControl (templated control)
w('LabeledValueControl.xaml.h', '''#pragma once
#include "LabeledValueControl.g.h"

namespace winrt::CustomGallery::implementation
{
    struct LabeledValueControl : LabeledValueControlT<LabeledValueControl>
    {
        LabeledValueControl();

        static Microsoft::UI::Xaml::DependencyProperty LabelProperty();
        static Microsoft::UI::Xaml::DependencyProperty ValueProperty();

        Windows::Foundation::IReference<hstring> Label();
        void Label(Windows::Foundation::IReference<hstring> const& value);
        Windows::Foundation::IReference<hstring> Value();
        void Value(Windows::Foundation::IReference<hstring> const& value);

    protected:
        void OnApplyTemplate();
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct LabeledValueControl : LabeledValueControlT<LabeledValueControl, implementation::LabeledValueControl>
    {
    };
}
''')
w('LabeledValueControl.xaml.cpp', '''#include "pch.h"
#include "LabeledValueControl.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::CustomGallery::implementation
{
    static Microsoft::UI::Xaml::DependencyProperty s_labelProperty{ nullptr };
    static Microsoft::UI::Xaml::DependencyProperty s_valueProperty{ nullptr };

    LabeledValueControl::LabeledValueControl()
    {
        // 27.3 的接线：默认样式键指向 Generic.xaml 里的 Style
        DefaultStyleKey(winrt::xaml_typename<CustomGallery::LabeledValueControl>());
    }

    Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::LabelProperty()
    {
        if (!s_labelProperty)
        {
            s_labelProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
                L"Label", xaml_typename<Windows::Foundation::IInspectable>(),
                xaml_typename<CustomGallery::LabeledValueControl>(), nullptr);
        }
        return s_labelProperty;
    }

    Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::ValueProperty()
    {
        if (!s_valueProperty)
        {
            s_valueProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
                L"Value", xaml_typename<Windows::Foundation::IInspectable>(),
                xaml_typename<CustomGallery::LabeledValueControl>(), nullptr);
        }
        return s_valueProperty;
    }

    Windows::Foundation::IReference<hstring> LabeledValueControl::Label()
    {
        return GetValue(LabelProperty()).try_as<Windows::Foundation::IReference<hstring>>();
    }
    void LabeledValueControl::Label(Windows::Foundation::IReference<hstring> const& value)
    {
        SetValue(LabelProperty(), value ? box_value(value.Value()) : nullptr);
    }
    Windows::Foundation::IReference<hstring> LabeledValueControl::Value()
    {
        return GetValue(ValueProperty()).try_as<Windows::Foundation::IReference<hstring>>();
    }
    void LabeledValueControl::Value(Windows::Foundation::IReference<hstring> const& value)
    {
        SetValue(ValueProperty(), value ? box_value(value.Value()) : nullptr);
    }

    void LabeledValueControl::OnApplyTemplate()
    {
        base_type::OnApplyTemplate();
        // TemplatePart 约定：模板就位后取部件（27.3）
        if (auto part = GetTemplateChild(L"PART_ValueText").try_as<TextBlock>())
        {
            part.Text((Value() ? Value().Value() : L"-"));
        }
    }
}
''')

# TitleRow UserControl
w('TitleRow.xaml', '''<UserControl
    x:Class="CustomGallery.TitleRow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
            BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
            BorderThickness="1" CornerRadius="8" Padding="16,10">
        <StackPanel Orientation="Horizontal" Spacing="12">
            <TextBlock Text="{x:Bind Title, Mode=OneWay}" FontWeight="SemiBold" VerticalAlignment="Center"/>
            <TextBlock Text="{x:Bind Value, Mode=OneWay}" Opacity="0.7" VerticalAlignment="Center"/>
        </StackPanel>
    </Border>
</UserControl>
''')
w('TitleRow.xaml.h', '''#pragma once
#include "TitleRow.g.h"

namespace winrt::CustomGallery::implementation
{
    struct TitleRow : TitleRowT<TitleRow>
    {
        TitleRow();

        hstring Title();
        void Title(hstring const& value);
        hstring Value();
        void Value(hstring const& value);

    private:
        hstring m_title;
        hstring m_value;
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct TitleRow : TitleRowT<TitleRow, implementation::TitleRow>
    {
    };
}
''')
w('TitleRow.xaml.cpp', '''#include "pch.h"
#include "TitleRow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::CustomGallery::implementation
{
    TitleRow::TitleRow()
    {
        InitializeComponent();
    }

    hstring TitleRow::Title() { return m_title; }
    void TitleRow::Title(hstring const& value) { m_title = value; }
    hstring TitleRow::Value() { return m_value; }
    void TitleRow::Value(hstring const& value) { m_value = value; }
}
''')

# Generic.xaml default style for LabeledValueControl
os.makedirs(os.path.join(BASE, 'Themes'), exist_ok=True)
w('Themes/Generic.xaml', '''<ResourceDictionary
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:local="using:CustomGallery">

    <Style TargetType="local:LabeledValueControl">
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="local:LabeledValueControl">
                    <Border Background="{ThemeResource CardBackgroundFillColorSecondaryBrush}"
                            BorderBrush="{ThemeResource AccentFillColorDefaultBrush}"
                            BorderThickness="1" CornerRadius="8" Padding="14,10">
                        <StackPanel Orientation="Horizontal" Spacing="10">
                            <TextBlock Text="{TemplateBinding Label}" Opacity="0.7" VerticalAlignment="Center"/>
                            <TextBlock x:Name="PART_ValueText" FontWeight="SemiBold" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Border>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
</ResourceDictionary>
''')

# ---------- VsmPage (ch28) ----------
w('VsmPage.idl', idl('VsmPage'))
w('VsmPage.xaml', '''<Page
    x:Class="CustomGallery.VsmPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="16">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <StackPanel Orientation="Horizontal" Spacing="12">
                <Button Content="Force narrow" Click="OnForceNarrow"/>
                <Button Content="Force wide" Click="OnForceWide"/>
            </StackPanel>

            <!-- 28.2 VisualStateGroups：Narrow/Wide 两态 + AdaptiveTrigger 自动切换 -->
            <Grid>
                <VisualStateManager.VisualStateGroups>
                    <VisualStateGroup x:Name="WidthStates">
                        <VisualState x:Name="WideState">
                            <VisualState.StateTriggers>
                                <AdaptiveTrigger MinWindowWidth="900"/>
                            </VisualState.StateTriggers>
                            <VisualState.Setters>
                                <Setter Target="LayoutPanel.Orientation" Value="Horizontal"/>
                                <Setter Target="SideBlock.Visibility" Value="Visible"/>
                            </VisualState.Setters>
                        </VisualState>
                        <VisualState x:Name="NarrowState">
                            <VisualState.StateTriggers>
                                <AdaptiveTrigger MinWindowWidth="0"/>
                            </VisualState.StateTriggers>
                            <VisualState.Setters>
                                <Setter Target="LayoutPanel.Orientation" Value="Vertical"/>
                                <Setter Target="SideBlock.Visibility" Value="Collapsed"/>
                            </VisualState.Setters>
                        </VisualState>
                    </VisualStateGroup>
                </VisualStateManager.VisualStateGroups>

                <StackPanel x:Name="LayoutPanel" Spacing="12" Orientation="Vertical">
                    <Border Background="{ThemeResource AccentFillColorDefaultBrush}" CornerRadius="8"
                            Width="220" Height="60">
                        <TextBlock Text="main block" Foreground="{ThemeResource TextOnAccentFillColorDefaultBrush}"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <Border x:Name="SideBlock" Background="{ThemeResource CardBackgroundFillColorSecondaryBrush}"
                            BorderThickness="1" BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                            CornerRadius="8" Width="220" Height="60">
                        <TextBlock Text="side block (wide only)" HorizontalAlignment="Center" VerticalAlignment="Center" Opacity="0.7"/>
                    </Border>
                </StackPanel>
            </Grid>
        </StackPanel>
    </Grid>
</Page>
''')
w('VsmPage.xaml.h', '''#pragma once
#include "VsmPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct VsmPage : VsmPageT<VsmPage>
    {
        VsmPage();

        void OnForceNarrow(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnForceWide(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct VsmPage : VsmPageT<VsmPage, implementation::VsmPage>
    {
    };
}
''')
w('VsmPage.xaml.cpp', '''#include "pch.h"
#include "VsmPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::CustomGallery::implementation
{
    VsmPage::VsmPage()
    {
        InitializeComponent();
    }

    void VsmPage::OnForceNarrow(IInspectable const&, RoutedEventArgs const&)
    {
        // 手动 GoToState：确定性切换（自动化验证路径；AdaptiveTrigger 是 resize 自动）
        bool used{};
        VisualStateManager::GoToState(*this, L"NarrowState", false);
        StatusText().Text(L"state = narrow (manual)");
    }

    void VsmPage::OnForceWide(IInspectable const&, RoutedEventArgs const&)
    {
        VisualStateManager::GoToState(*this, L"WideState", false);
        StatusText().Text(L"state = wide (manual)");
    }
}
''')

# ---------- AnimationPage (ch29) ----------
w('AnimationPage.idl', idl('AnimationPage'))
w('AnimationPage.xaml', '''<Page
    x:Class="CustomGallery.AnimationPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="16">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <Grid Width="360" Height="80">
                <Rectangle x:Name="Bar" Width="40" Height="40" RadiusX="8" RadiusY="8"
                           Fill="{ThemeResource AccentFillColorDefaultBrush}"
                           HorizontalAlignment="Left"/>
            </Grid>

            <StackPanel Orientation="Horizontal" Spacing="12">
                <Button Content="Animate" Click="OnAnimateClicked"/>
            </StackPanel>

            <!-- 29.4 Transitions：隐式过场（出现时淡入） -->
            <Border x:Name="FadeBox" Background="{ThemeResource CardBackgroundFillColorSecondaryBrush}"
                    BorderThickness="1" CornerRadius="8" Padding="14" Visibility="Collapsed">
                <Border.Transitions>
                    <TransitionCollection>
                        <ContentThemeTransition/>
                    </TransitionCollection>
                </Border.Transitions>
                <TextBlock Text="transitions demo"/>
            </Border>
            <Button Content="Toggle fade box" Click="OnToggleFadeClicked"/>
        </StackPanel>
    </Grid>
</Page>
''')
w('AnimationPage.xaml.h', '''#pragma once
#include "AnimationPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct AnimationPage : AnimationPageT<AnimationPage>
    {
        AnimationPage();

        void OnAnimateClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnToggleFadeClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        int m_shots{ 0 };
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct AnimationPage : AnimationPageT<AnimationPage, implementation::AnimationPage>
    {
    };
}
''')
w('AnimationPage.xaml.cpp', '''#include "pch.h"
#include "AnimationPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Media.Animation;
using namespace std::chrono_literals;

namespace winrt::CustomGallery::implementation
{
    AnimationPage::AnimationPage()
    {
        InitializeComponent();
    }

    void AnimationPage::OnAnimateClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Bar() || !StatusText()) return;
        ++m_shots;

        // Storyboard：Width 40 -> 320（1s，结束保持）
        Storyboard sb;
        DoubleAnimation widthAnim;
        widthAnim.From(40.0);
        widthAnim.To(320.0);
        widthAnim.Duration(TimeSpan{ 1s });
        Storyboard::SetTarget(widthAnim, Bar());
        Storyboard::SetTargetProperty(widthAnim, L"Width");
        sb.Children().Append(widthAnim);
        sb.Begin();

        StatusText().Text(L"animated, shots = " + to_hstring(m_shots));
    }

    void AnimationPage::OnToggleFadeClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!FadeBox() || !StatusText()) return;
        bool visible = FadeBox().Visibility() == Visibility::Visible;
        FadeBox().Visibility(visible ? Visibility::Collapsed : Visibility::Visible);
        StatusText().Text(visible ? L"fade box hidden" : L"fade box shown");
    }
}
''')

# ---------- DrawingPage (ch30) ----------
w('DrawingPage.idl', idl('DrawingPage'))
w('DrawingPage.xaml', '''<Page
    x:Class="CustomGallery.DrawingPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="16">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 30.2 Shape 家族 -->
            <StackPanel Orientation="Horizontal" Spacing="14">
                <Ellipse Width="60" Height="60" Stroke="{ThemeResource AccentFillColorDefaultBrush}" StrokeThickness="2"/>
                <Rectangle Width="70" Height="60" RadiusX="6" RadiusY="6" Fill="{ThemeResource AccentFillColorSecondaryBrush}"/>
                <Line X1="0" Y1="30" X2="60" Y2="0" Stroke="{ThemeResource TextFillColorPrimaryBrush}" StrokeThickness="2"/>
                <Polygon Points="0,40 30,0 60,40" Fill="{ThemeResource SystemFillColorSuccessBrush}" Stroke="Black" StrokeThickness="1"/>
            </StackPanel>

            <!-- 30.2 Path 迷你语法 + 渐变笔刷 -->
            <Path Stroke="{ThemeResource AccentFillColorDefaultBrush}" StrokeThickness="3" Fill="{ThemeResource AccentFillColorSecondaryBrush}"
                  Data="M 10,60 C 30,0 70,0 90,60 Z"/>

            <!-- 30.3 ColorPicker 联动 shape -->
            <StackPanel Orientation="Horizontal" Spacing="16">
                <ColorPicker x:Name="ShapeColor" IsAlphaEnabled="False" IsColorPreviewVisible="True"
                             ColorChanged="OnColorChanged"/>
                <StackPanel Spacing="12" VerticalAlignment="Center">
                    <Ellipse x:Name="LiveDot" Width="70" Height="70" Fill="{ThemeResource AccentFillColorDefaultBrush}" Stroke="Black" StrokeThickness="1"/>
                    <TextBlock Text="pick a color" Opacity="0.6"/>
                </StackPanel>
            </StackPanel>
        </StackPanel>
    </Grid>
</Page>
''')
w('DrawingPage.xaml.h', '''#pragma once
#include "DrawingPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct DrawingPage : DrawingPageT<DrawingPage>
    {
        DrawingPage();

        void OnColorChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::ColorChangedEventArgs const& args);
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct DrawingPage : DrawingPageT<DrawingPage, implementation::DrawingPage>
    {
    };
}
''')
w('DrawingPage.xaml.cpp', '''#include "pch.h"
#include "DrawingPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::CustomGallery::implementation
{
    DrawingPage::DrawingPage()
    {
        InitializeComponent();
    }

    void DrawingPage::OnColorChanged(IInspectable const&, ColorChangedEventArgs const& args)
    {
        if (!LiveDot() || !StatusText()) return;
        // ColorPicker 选色 -> 驱动 Ellipse 的 Fill（SolidColorBrush 直写）
        auto color = args.NewColor();
        LiveDot().Fill(SolidColorBrush(color));
        StatusText().Text(L"color = " + to_hstring(color.R) + L"," + to_hstring(color.G) + L"," + to_hstring(color.B));
    }
}
''')

print('custom pages written')
