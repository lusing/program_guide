# 38. Fluent 设计系统：原则、排版与材质

> 对应《Learn WinUI 3》第 7 章。本章是"设计观"章：Fluent 是什么、WinUI 控件默认继承了什么、你能改什么。窗口级材质（Mica/Acrylic 的 SystemBackdrop API）在 [31.3](31-window-shell.md) 已实测过三态切换，这里补齐**元素级亚克力画刷**与设计原则层；主题资源系统本身见 [33 章](33-theming-packaging.md)。

## 38.1 Fluent 是什么

Fluent 是微软的跨平台设计系统（fluent2.microsoft.design），Windows 版是 WinUI 控件的**隐式样式来源**——你写一个裸 `<Button/>` 得到的圆角、悬停光效、按压动画全是 Fluent。书 7.1 的三原则：

- **自然**：软件适配设备（PC/平板/掌机/VR），而不是反过来
- **直觉**：UI 预判用户意图，交互不解释自明
- **沉浸**：光、深度、材质营造层次

对开发者的实际含义是一条纪律：**改控件外观前先问默认样式为什么不满足**。33/26 章的主题资源体系已经把"跟随系统强调色/深浅色"做成了零成本，自定义通常是在放弃这些免费的自适应。

## 38.2 控件之外的 Fluent 面

书 7.1.4-7.1.6 巡了 Fluent 的几个维度，C++ 侧对应物：

| 维度 | 做法 | 本教程章节 |
|---|---|---|
| 布局自适应 | VisualState + AdaptiveTrigger | [28 章](28-vsm-adaptive.md) |
| 模式（搜索/表单/列表详情） | 控件组合，无新 API | [15](15-autosuggestbox.md)/[24](24-dialogs-flyouts.md)/[17](17-listview.md) |
| 排版 | 字体斜坡静态资源（见下） | — |
| 间距 | 8px 网格 + 控件 `Spacing` 属性 | [06](06-layout.md) |
| 图标 | FontIcon/SymbolIcon（Segoe Fluent Icons） | [23 章](23-commandbar-menus.md) |
| 颜色 | ThemeResource 系统色 | [33 章](33-theming-packaging.md) |
| 材质 | Mica/Acrylic（本章 + 31.3） | — |

### 排版：字体斜坡（type ramp）

书 7.2.2 把硬编码 FontSize/FontWeight 换成斜坡资源，这是最便宜的一条 Fluent 化改造：

```xml
<TextBlock Text="Home" Style="{StaticResource SubheaderTextBlockStyle}"/>
<TextBlock Text="Media Type:" Style="{StaticResource SubtitleTextBlockStyle}"/>
```

WinUI 内置斜坡（Caption/Body/BodyStrong/Subtitle/Title/LargeTitle/DisplayTitle）让层级靠字号阶梯传达而不是加粗。**默认 TextBlock 样式是 Body**——所有"说明文字"其实一行样式都不用写。

### 间距密度

`Standard` 与 `Compact` 两档由资源键 `DensityStyle` 切换，数据密集界面（[20 章](20-datagrid-itemsrepeater.md)的自制表格）值得提供切换。

## 38.3 材质一：窗口背景（Mica/Acrylic Backdrop）

[31.3](31-window-shell.md) 已有完整实测（31 例三按钮切换），这里只放结论卡：

```cpp
SystemBackdrop(MicaBackdrop{});              // 云母：不透明，取桌面壁纸染色
SystemBackdrop(DesktopAcrylicBackdrop{});   // 亚克力：半透明模糊
SystemBackdrop(nullptr);                    // 退回纯色
```

三条硬约束（书 7.5 + 实测）：

1. **Mica 仅 Windows 11**；Win10 上静默退化为纯色——不能假设用户看到的就是云母。
2. **页面根不能有不透明 Background**，否则材质被完全遮住（书 7.5.1 步骤 2 专门强调）。31 例的页面用透明根。
3. **标题栏不吃材质**——想吃进标题栏要 `ExtendsContentIntoTitleBar`（[31.2](31-window-shell.md) 自绘标题栏路线）。

## 38.4 材质二：元素级亚克力画刷

书 7.4 的重点是**亚克力不只能做窗口背景，还能做元素画刷**，且分两种资源键：

```xml
<!-- 应用内亚克力：采样应用自己后面的内容 -->
<Rectangle Fill="{ThemeResource AcrylicInAppFillColorDefaultBrush}"/>

<!-- 背景亚克力：采样桌面/其它窗口（更贵，浮层语义） -->
<Rectangle Fill="{ThemeResource AcrylicBackgroundFillColorDefaultBrush}"/>
```

两者是**资源字典里的现成画刷**，不是要你自己 new `AcrylicBrush`。区别在采样源与性能：Background 版要走窗口合成，代价高，语义上属于"悬浮在内容之上"的东西（浮层、命令栏）；In-app 版便宜，适合页面内的分区。

要自定义参数时才直接构造画刷（代码路线）：

```cpp
auto acrylic = Microsoft::UI::Xaml::Media::AcrylicBrush();
acrylic.TintColor(Windows::UI::Color{ 0xFF, 0x20, 0x20, 0x20 });
acrylic.TintOpacity(0.8);
acrylic.FallbackColor(Windows::UI::Color{ 0xFF, 0x2B, 0x2B, 0x2B });  // 降级纯色
someElement.Background(acrylic);
```

`FallbackColor` 不是可选项：**节省模式/老 GPU/远程会话下系统会直接停用亚克力**，没有 fallback 就是黑块。26 章 ThemeLab 的 accent 追随实测还证明一条：运行时代码 `TryLookup` 拿不到 `XamlControlsResources` 里的系统亚克力键——要"跟随系统材质再改色"得手动遍历重刷（[26 章实战节](26-styles-templates.md)）。

### 去哪预览

书 7.4/7.5 推荐在 **WinUI 3 Gallery**（商店应用）里调参数看效果再抄——Gallery 的 Mica/Acrylic/AcrylicBrush 三页有实时滑杆，比盲改快一个数量级。Gallery 本身也是 WinUI 写的，等于一份可运行的样式参考书。

## 38.5 Fluent XAML 主题编辑器

书 7.3 的工具推荐：**Fluent XAML Theme Editor**（微软开源，商店可装）可视化调色/圆角/边框粗细，导出成 ResourceDictionary 贴进工程。两点提醒：

- 它为 UWP 控件样式而生，导出的资源键对 WinUI 3 **大体兼容但不逐键对齐**——贴进来后个别控件可能回落默认样式，以 33 章的资源查找链排查。
- 书的劝告值得抄录：**除非有充分理由（品牌），否则让应用跟随用户的系统强调色**。自定义主题是设计团队决策，不是开发者的默认动作。26 章 ThemeLab 是"教学如何换肤"，不是"建议你换肤"。

## 38.6 设计资源

书 7.6 列的设计工具包（Figma/Sketch/Adobe XD/Illustrator/Inkscape/Photoshop）下载点统一在 `learn.microsoft.com/windows/apps/design/downloads/`。C++ 工程师最常用的两个免费入口：

- **WinUI 3 Gallery**：每个控件的实时参数试验场
- **Segoe Fluent Icons 字体表**：图标字形查询（FontIcon 的 Glyph 值来源）

## 38.7 实测坑位（本章新增）

1. **AcrylicBrush 必须设 FallbackColor**（节电/降级路径无提示直换）——资源键版已内置，代码构造版是你的责任。
2. **In-app 与 Background 亚克力用错语义 = 白付性能**：页面分区用 Background 版会在低配机上拖滚动帧率。
3. **Mica 页面根的不透明 Background 是静默杀手**：不报错、不警告，材质就是不出来（31 例调试实录）。
4. **深浅模式下亚克力的观感不对称**：暗色下 TintOpacity 需要更高才不"糊"——用 ThemeResource 双份画刷而不是一套参数走两主题。
5. Fluent 斜坡资源是 `StaticResource` 引用（不是 ThemeResource）——它们不随主题换值，别套错标记扩展。

## 38.8 练习与思考

1. 给 [07-settings-hub](../examples/07-settings-hub/README.md) 的导航区加 In-app 亚克力背景，验证暗色主题下的可读性。
2. 把 37 章 MediaLibrary 的标题行从硬编码字号换成 `SubtitleTextBlockStyle`，对比前后层级感。
3. 做一个三态材质切换页（None/Mica/Acrylic）放到 31 例——如果已经有（31.3），读它的实现并解释为什么页面根不能有 Background。
4. 思考：为什么"跟随系统强调色"在 WinUI 里几乎是免费的（零代码），而自定义品牌色要付"重刷所有主题资源"的代价（26 章 ThemeLab 的 ApplyAccent 手动遍历）？（提示：资源查找链的方向。）
