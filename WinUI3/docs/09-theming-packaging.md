# 9. 主题资源与应用交付

前半篇讲 Fluent Design 在工程上如何落地（主题资源系统），后半篇讲应用怎么打包交付（Assets、Manifest、MSIX、打包/非打包两种形态）。

## 9.1 主题系统：换的是资源，不是控件

主题系统的本质：**颜色、字体、间距不写在控件上，而是定义成资源；控件只按键引用；主题切换时换资源值，控件结构不动**。

反例（写死颜色）：

```xml
<Button Background="#F3F3F3" Foreground="#000000" />
```

深色主题下这块灰白按钮就成了刺眼的一块。正确做法是引用框架的主题资源：

```xml
<Grid Background="{ThemeResource ApplicationPageBackgroundThemeBrush}">
    <TextBlock Foreground="{ThemeResource TextFillColorPrimaryBrush}" />
</Grid>
```

这些键是框架预定义的（`ApplicationPageBackgroundThemeBrush`、`TextFillColorPrimaryBrush`、`CardBackgroundFillColorDefaultBrush`、`AccentFillColorDefaultBrush`……），每个主题（Light/Dark/HighContrast）下各有一套值。**控件只依赖键名，永远不感知当前主题是什么。**

## 9.2 ThemeResource 与 StaticResource

```xml
<Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" />
<Border Background="{StaticResource MyPageBrush}" />
```

| | `StaticResource` | `ThemeResource` |
|---|---|---|
| 求值时机 | 加载时查一次，缓存结果 | 同样缓存，但**主题切换时重新求值** |
| 适用 | 自己定义的、与主题无关的资源 | 任何随深浅色/高对比度变化的资源 |

工程纪律：**凡是颜色/画刷类资源一律 `ThemeResource`**，即使当前看着"用不上"——高对比度模式、深浅色切换都不需要你写任何代码。自己定义的画刷也应该做成主题资源，在资源字典里为每个主题给值：

```xml
<ResourceDictionary
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <ResourceDictionary.ThemeDictionaries>
        <ResourceDictionary x:Key="Light">
            <SolidColorBrush x:Key="BrandBrush" Color="#0063B1" />
        </ResourceDictionary>
        <ResourceDictionary x:Key="Dark">
            <SolidColorBrush x:Key="BrandBrush" Color="#4CC2FF" />
        </ResourceDictionary>
    </ResourceDictionary.ThemeDictionaries>
</ResourceDictionary>
```

## 9.3 资源分层与合并字典

查找顺序（[03 篇](./03-xaml.md) 3.7）决定了资源放哪一层：

```text
控件 Resources        —— 只在这个实例用
  ↓
Page Resources        —— 本页面复用（局部样式）
  ↓
App.xaml Application.Resources —— 全局
  ↓
框架主题资源           —— 兜底
```

全局资源多了以后拆分成独立字典文件，在 `App.xaml` 合并：

```xml
<!-- App.xaml -->
<Application ...>
    <Application.Resources>
        <ResourceDictionary>
            <ResourceDictionary.MergedDictionaries>
                <XamlControlsResources xmlns="using:Microsoft.UI.Xaml.Controls" />
                <ResourceDictionary Source="ms-appx:///Styles/CardStyles.xaml" />
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Application.Resources>
</Application>
```

- `XamlControlsResources`：WinUI 3 控件的默认样式与主题资源，**必须保留在最前**
- 自己的字典按域拆文件（`Styles/`、`Themes/`），后合并的键覆盖先合并的

一个典型的页面级样式：

```xml
<!-- Styles/CardStyles.xaml -->
<ResourceDictionary ...>
    <Style x:Key="CardStyle" TargetType="Border">
        <Setter Property="Background" Value="{ThemeResource CardBackgroundFillColorDefaultBrush}" />
        <Setter Property="CornerRadius" Value="8" />
        <Setter Property="Padding" Value="12" />
        <Setter Property="BorderThickness" Value="1" />
        <Setter Property="BorderBrush" Value="{ThemeResource CardStrokeColorDefaultBrush}" />
    </Style>
</ResourceDictionary>
```

```xml
<!-- 使用 -->
<Border Style="{StaticResource CardStyle}">
    <TextBlock Text="Project overview" />
</Border>
```

## 9.4 主题切换

```cpp
// 启动前：在 App 构造函数里设默认主题（此后 Application::RequestedTheme 不可再改）
App::App()
{
    InitializeComponent();
    // RequestedTheme(ApplicationTheme::Dark);  // 可选：强制默认主题
}

// 运行期：改根元素的 RequestedTheme（整棵树跟随）
void MainWindow::ApplyTheme(winrt::Microsoft::UI::Xaml::ElementTheme theme)
{
    this->Content().as<winrt::Microsoft::UI::Xaml::FrameworkElement>()
        .RequestedTheme(theme);
    // ElementTheme::Light / Dark / Default（Default = 跟随系统）
}
```

要点：

- `Application.RequestedTheme` 只能在 App 构造时设置一次；运行期切换靠**根元素**（或任意子树）的 `FrameworkElement.RequestedTheme`
- `ElementTheme::Default` 表示跟随系统设置
- 切换时所有 `ThemeResource` 自动重新求值——这就是 9.1 说的"换资源不换控件"

## 9.5 应用资源：Assets 与 Package.appxmanifest

图标、Logo、启动图不是页面资源，是**应用资源**，放工程根的 `Assets/`：

```text
MyApp/
├── Assets/
│   ├── Square44x44Logo.png
│   ├── Square150x150Logo.png
│   ├── Wide310x150Logo.png
│   ├── StoreLogo.png
│   └── SplashScreen.png
└── Package.appxmanifest
```

manifest 在 Visual Studio 里是图形编辑器，底层是 XML。视觉元素的声明段：

```xml
<uap:VisualElements
    DisplayName="MyApp"
    Square150x150Logo="Assets\Square150x150Logo.png"
    Square44x44Logo="Assets\Square44x44Logo.png"
    BackgroundColor="transparent"
    Description="My WinUI 3 App"
    AppListEntry="default" />
```

路径写错或文件缺失 → 安装后图标显示异常。这些文件会被打进安装包，必须纳入版本控制。

## 9.6 交付：MSIX 与两种部署形态

### 9.6.1 生成 MSIX（打包应用）

Visual Studio 流程：

1. 解决方案里加入 **Windows Application Packaging Project**（模板工程默认已含）
2. 配置签名（测试用自签证书，发布用受信证书）、版本号、显示名
3. 选 Release + 目标架构（x64 / arm64）
4. **Project → Store → Create App Packages**，或生成解决方案后在 `AppPackages/` 输出找到 `.msix`

本机安装/卸载：

```powershell
Add-AppxPackage -Path .\MyApp_1.0.0.0_x64.msix
Get-AppxPackage *MyApp*          # 查包全名
Remove-AppxPackage <PackageFullName>
```

MSIX 包的内容：可执行文件 + 依赖 + Assets + manifest + 签名。它是"可安装、可卸载、可更新"的完整应用单元，Store 和企业侧载都用它。

### 9.6.2 打包 vs 非打包

| | 打包（MSIX） | 非打包（unpackaged） |
|---|---|---|
| 运行形态 | 有包身份，系统管理安装/卸载/更新 | 直接跑 exe，绿色便携 |
| Windows App SDK 运行时 | 系统自动解析 | 需要 bootstrapper 自动初始化（工程默认已配置）或随包自包含分发 |
| 能力限制 | 无 | 个别需要包身份的 API 不可用 |
| 典型用途 | 商店分发、企业部署 | 开发调试、内部工具 |

模板工程的属性页（**Configuration Properties → Deployment**）里有 `Windows Package Type` 开关，两种形态可随时切换，工程代码完全不变。

---

上一篇：[08-binding-mvvm.md](./08-binding-mvvm.md) ｜ 下一篇：[10-os-integration.md](./10-os-integration.md)
