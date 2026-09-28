# 41. 调试与诊断：绑定失败、可视化树与 stowed exception

> 对应《Learn WinUI 3》第 11 章，并叠加本教程自己的战争史（12.5 的 ValueChanged 深坑、mspdbsrv 死锁、高 DPI 注入）。书里的工具（Live Visual Tree、XAML Binding Failures 窗口、热重载）**对 C++/WinRT 工程同样可用**——它们挂在 XAML 诊断基础设施上，不挑语言；个别窗口的行为差异在坑位表里标出。

本章分四层：**编译期**（x:Bind 报错）、**绑定运行期**（DebugSettings）、**UI 结构**（可视化树）、**崩溃**（stowed exception 的追凶法）。

## 41.1 编译期：x:Bind 是你的第一道防线

书 11.2 开头那句对 C++ 更成立：**x:Bind 表达式在编译期检查**，路径错、类型错、成员没进 IDL 全在构建输出里。C++ 工程里 `{Binding}`（运行期解析）用得越少，可调试面越窄。本教程的纪律（[32 章](32-binding-mvvm.md)）——新代码一律 x:Bind，`{Binding}` 只在 Converter + 非 FrameworkElement 根的角落出现——本质上是调试策略。

编译期诊断的三个入口：

- **XAML 编译器错误（WMCxxxx）**：类型/属性不存在、标记扩展误用（26/27 章的 `x:Type`、WMC0011 记录在案）。
- **x:Bind 生成的 `.g.hpp` 编译错**：错误定位在生成文件里，但**病根在你的 xaml.cpp 签名**——`SetConverterLookupRoot` 那次（32.8）就是生成文件先炸。
- **绑定代码在 `XamlBindingInfo.xaml.g.hpp`**：函数绑定签名不匹配报在这里，追到你的方法签名改。

## 41.2 绑定运行期：DebugSettings.BindingFailed

`{Binding}` 与部分延迟到运行期的绑定失败**默认静默**（控件显示空/默认值）。打开诊断开关只要两行，挂在 App 构造：

```cpp
// App.xaml.cpp —— 绑定失败进调试输出（DebugView / VS 输出窗口可见）
DebugSettings().BindingFailed(
    [](auto const&, DebugSettings const&,
       BindingFailedEventArgs const& args)
{
    OutputDebugStringW((std::wstring{ L"[binding] " } +
        std::wstring_view{ args.Message() } + L"\n").c_str());
});
```

`args.Message()` 给出路径与失败原因（书 11.2.2 的"BindingExpression path error"同款文案）。C++ 侧两个补充：

- **没有 VS 的"XAML Binding Failures"窗口吗？有，但只列 `{Binding}`**——x:Bind 编译期已消化。C++ 工程该窗口常常是空的，别指望它当主战场；`BindingFailed` + OutputDebugString 更普适（无调试器也能抓：DebugView）。
- 书 11.2.1 的常见错误清单在 C++ 的翻译：**忘了 `Mode=TwoWay`**（x:Bind 默认 OneTime）依然是第一名；**属性名与 INPC 通知名不一致**在 C++ 里没有 `nameof`，靠宏（32.2 的 `RAISE(name)`）把两个名字钉死在一起。

### 集合绑定的三条纪律（书 11.2.1 直译 + C++ 形态）

1. **不要整体替换可观察集合**——绑定还盯着旧集合。要换内容：Clear + 逐条 Append（37 章的 ReloadAsync），或替换后补 `RaisePropertyChanged`（32.4）。
2. **过滤不要"新集合再赋值"**——等价于替换。就地 Remove。
3. **静态列表别用可观察集合**——`IVector<T>` 一次给足更便宜（Categories 静态项的写法）。

## 41.3 UI 结构：实时可视化树与属性资源管理器

调试会话中 VS 的 **调试 → 窗口 → 实时可视化树**（Live Visual Tree）与**实时属性资源管理器**（Live Property Explorer）对 C++/WinRT 工程**可用**（书 11.3 的操作步骤原样照做）：

- 树里能看到你的 XAML 元素层级（"仅显示我的 XAML"过滤掉模板内部件），点选定位、右键"查看源"跳 XAML。
- 属性资源管理器按**设置来源分组**（本地/样式/模板/默认值），能改运行时值即时看效果（改不回写 XAML 文件）。
- 取消"仅显示我的 XAML"后能展开控件模板内部——**这是学习 ControlTemplate 结构最直观的方式**（26/27 章的模板自定义前置课）。

C++ 差异一处：**热重载（XAML Hot Reload）可用性不如 C#**——简单属性改动多数生效，但涉及 x:Bind 重新生成（`.g.hpp` 变化）的编辑要求 C++ 编辑并继续条件（64 位 Debug、无优化），实战中经常"保存了没反应"。**把它当锦上添花，不当工作流依赖**。

### 没有 VS 时的替代品

命令行构建流程（本教程 build.ps1 路线）没有 VS 调试器，两个平替：

- **LoggingFields + ETW / OutputDebugString + DebugView**：应用侧埋点。
- **代码侧遍历可视化树**：`VisualTreeHelper::GetParent/GetChildrenCount/GetChild` 三函数足够写个 10 行的树转储——12.5 的深坑定位就用过"运行时把树打印出来对结构"。

```cpp
void DumpTree(Microsoft::UI::Xaml::DependencyObject node, int depth)
{
    for (int i = 0; i < depth; ++i) { OutputDebugStringW(L"  "); }
    OutputDebugStringW((std::wstring{ L"* " } +
        std::wstring_view{ winrt::get_class_name(node) } + L"\n").c_str());
    for (int i = 0; i < Microsoft::UI::Xaml::Media::VisualTreeHelper::GetChildrenCount(node); ++i)
    {
        DumpTree(Microsoft::UI::Xaml::Media::VisualTreeHelper::GetChild(node, i), depth + 1);
    }
}
```

## 41.4 崩溃与 stowed exception：C++ 的主战场

WinUI 3 的异常行为有个专门名词：**stowed exception**——异常被 XAML 框架"收起来"，进程不立刻死，**在之后的某个无关时刻才爆 AV**。这是 C++/WinRT 调试最贵的坑，本教程有一次完整战争记录（[12.5](12-slider-progress.md)）：解析期触发的 `ValueChanged` 引用了尚未建立的相邻控件 → stowed → 1-3 秒后在渲染深处崩溃。追凶方法论四步，值得背下来：

1. **事件日志先看**：应用程序日志里的 AV 事件给故障模块与**偏移地址**（不是符号）。
2. **偏移换符号**：工程开 `<GenerateMapFile>true</GenerateMapFile>` 链接出 .map，按偏移查所属函数（工具方法见 12.5 附录；或用 `link /dump /disasm` 对照）。
3. **对照实验隔离**：注释掉嫌疑 handler → 不崩 → 定罪。单变量，别一次注释一片。
4. **修法双保险**：handler 判空 + XAML 声明序调整（被引用控件先声明），两个防线独立生效。

### C++ 侧的常规军火

| 手段 | 场合 |
|---|---|
| `winrt::check_hresult` / `try{...} catch (winrt::hresult_error)` | COM/WinRT 调用失败当场可见，不要吞 |
| `WINRT_ASSERT` / `<cassert>` | Debug 断言（FreeBASIC 教训：别用裸 assert 当 UI 校验） |
| VS 附加（调试 → 附加到进程 → 选你的 exe） | 已运行的实例；打包应用用"调试已安装的应用程序包"（书 11.1.1，C++ 同样可用） |
| **异常设置里勾 WinRT 异常中断**（仅托管） | C++ 侧等价物是 `_set_se_translator` 或调试器"仅我的代码"关掉 |
| WER 本地转储（注册表 LocalDumps） | 无调试器的现场崩溃收 minidump |

**`catch (...)` 纪律**：XAML 事件回调里最外层兜一个 `catch (winrt::hresult_error const&)` + OutputDebugString，能把 stowed 变成立即可见的日志——12.5 的最终修法之一。

### 41.4.1 无调试器的第一现场：App::UnhandledException 落盘

命令行构建流程（本教程形态）没有调试器，但 stowed exception 在进 WER 之前会先经过 `Application::UnhandledException`——**三行订阅把它变成你的私有崩溃日志**。37 章工程实装（首启白窗追凶的真实武器，保留为常驻代码）：

```cpp
// App 构造（examples/37-media-library/App.xaml.cpp）
UnhandledException([](auto const&, UnhandledExceptionEventArgs const& e)
{
    wchar_t line[1024];
    _snwprintf_s(line, _TRUNCATE, L"stowed 0x%08lX: %s\r\n",
        static_cast<unsigned long>(e.Exception().value), e.Message().c_str());
    // 追加写 %TEMP%\MediaLibrary-crash.log（完整代码见工程）
});
```

37 例的白窗案当场翻案：日志一行 `stowed 0x80070057: 参数错误` 直接给出 HRESULT 与消息，而事件日志只会给 Xaml.dll 的偏移地址。**先挂这条订阅再开始调试**，是 C++/WinRT 工程的"装烟雾报警器"。

## 41.5 构建级疑难（本教程档案）

调试 C++/WinRT 工程的一半问题发生在"跑起来之前"，档案移交：

- **mspdbsrv 死锁**：MSBuild 卡死不报错——杀 MSBuild/cl/mspdbsrv + 删 obj/x64 重编；build.ps1 的 `-nr:false` 是预防针（[04 章 4.8](04-first-app.md)）。
- **pch.h 变更 = 全量重编**（4-8 分钟）：加头文件优先加在具体 .cpp，pch 只放真共享的投影。
- **改 XAML 不生效**：清 `Generated Files` 重编（陈旧 .g.hpp 的锅）。
- **C4819（cp936 警告）**：源文件是 UTF-8 无 BOM 但没开 `/utf-8`——本教程全线 vcxproj 已带该开关。
- **.idl 中文注释**：MIDL 按本地码页解码会提前终止（MIDL2025）——idl 注释一律 ASCII（两度实测）。

## 41.6 Rapid XAML 与静态分析

书 11.1.4 的 Rapid XAML Toolkit 是 VS 扩展，提供 XAML 分析器（Grid.Row 越界 RXT101/102、硬编码字符串 RXT200、SelectedItem 应 TwoWay RXT160 等规则）。**它不挑项目语言**（分析 XAML 文本），C++/WinRT 工程装上即用——Grid 越界这类"编译器不查、运行时叠放"的错（书 11.1.3 的演示）正好是它的靶区。规则清单见书 11.1.4 列表；RXT160 在 C++ 同样值得开（OneTime 默认坑的静态防线）。

## 41.7 远程调试（书 11.1.2 概述）

"调试已安装的应用程序包"窗口的远程机器模式（书 11.1.2 步骤）对 C++ 工程同样成立：目标机装 VS 远程工具 + 开发者模式，连接类型改"远程机器"。典型用途：**只在新机型/缩放/多屏上复现的布局与 DPI 问题**——本教程高 DPI（175%）注入战争的教训反过来也说明：屏幕环境不可复现的 bug，远程调试到那台机器上抓，比在本机模拟省命。

## 41.8 排查决策树（把本章收成一张卡）

```
症状
├─ 编不过 → 41.1（x:Bind/WMC/MIDL）
├─ 编过，界面空白/数据不显示 → 41.2（BindingFailed + 三条集合纪律）
├─ 界面错位/叠放/模板不对 → 41.3（Live Visual Tree / 树转储）+ RXT101/102
├─ 运行几秒后崩 → 41.4（事件日志 → map 符号化 → 对照实验）
├─ 一启动就崩/黑窗 → stowed 的解析期变体：判空 + 声明序（12.5 双保险）
└─ 构建卡死/不生效 → 41.5（mspdbsrv / Generated Files / pch）
```

## 41.9 练习与思考

1. 给 37 例的 App 构造加 `BindingFailed` 埋点，然后故意把一个 x:Bind 路径改成不存在的属性——用 `{Binding}`（运行期）与 x:Bind（编译期）各试一次，记录两者暴露错误的时机差异。
2. 写一个 `OnLaunched` 里调用的 `DumpTree(window.Content(), 0)`，把输出贴到日志文件——对照 41.3 的 Live Visual Tree 截图，数一数模板把层级撑大了多少。
3. 把 32 例的 `OnCompleteAllExecute` 里塞一个 `throw winrt::hresult_error(...)`，观察异常去了哪（stowed 吗？应用死了吗？）；再用 41.4 的外层 catch 兜住它。
4. 思考：为什么"注释掉嫌疑代码 → 不崩 → 定罪"（12.5 第 3 步）在 stowed exception 场景特别有力，而在普通异常场景是多余的？（提示：普通异常有栈，stowed 没有。）
