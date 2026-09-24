# 35. TaskFlow 实战：把全书串起来

上一篇：[34 OS 集成](./34-os-integration.md) ｜ 返回 [目录](../README.md)

最后一章没有新控件——它把前面所有章的模式装进一个真实应用：**TaskFlow**，一个带持久化的任务管理器。本章按文件走一遍，每个环节标注出处章号。

## 35.1 应用长什么样

```text
┌─────────┬──────────────────────────┐
│ Tasks   │ Tasks  2                  │
│ Settings│ Loaded 2 tasks            │
│         │ [Add task]                │
│ (Mica)  │ ☐ buy milk      [Remove]  │
│         │ ☐ walk dog      [Remove]  │
└─────────┴──────────────────────────┘
```

左侧 NavigationView（22 章）+ Mica 背景（31 章）+ 任务列表（17 章）+ 添加对话框（24 章）+ JSON 持久化（34 章）。加任务 → 勾完成 → 删任务，每次变更都落盘，重启原样回来。

## 35.2 文件清单与出处

```text
examples/35-taskflow/
├── App.*                 应用入口 + SetMica（Settings 经投影接口调主窗口）      04 章
├── MainWindow.*          NavigationView 外壳 + Frame 分发 + Mica/Acrylic       22/31 章
├── TaskListPage.*        列表页：x:Bind 到 ViewModel + 添加对话框 + 行内操作    17/24/32 章
├── SettingsPage.*        背景材质开关（经 App 落到主窗口）                      31 章
├── TaskFlow.idl          Task + TaskViewModel + TaskListPage 同文件             （MIDL2011 规则）
├── Task.h/cpp            Model：INPC 的 Title/Done                              32.2 节
├── TaskViewModel.h/cpp   VM：可观察集合 + Count + Load/SaveAsync                32.3/32.4/32.7 节
└── Storage.h/cpp         Service：%LOCALAPPDATA%\TaskFlow\tasks.json 读写        34 章
```

分层就是 05 章的图：View（页面）→ ViewModel（状态与命令）→ Model（Task）→ Service（Storage）。依赖单向向下。

## 35.3 数据层：Task 与持久化

`Task` 是最朴素的 INPC 模型（32.2 的模板逐字套用）。`Storage` 用 Win32 环境变量定位目录（34 章实测：非打包进程 `ApplicationData` 全家抛异常）、`Windows.Data.Json` 序列化：

```cpp
std::wstring Storage::TasksFilePath()
{
    wchar_t buffer[MAX_PATH]{};
    ::GetEnvironmentVariableW(L"LOCALAPPDATA", buffer, MAX_PATH);
    std::wstring dir = std::wstring(buffer) + L"\\TaskFlow";
    ::CreateDirectoryW(dir.c_str(), nullptr);   // 已存在则失败，无害
    return dir + L"\\tasks.json";
}
```

读回走 `JsonArray::Parse`，坏文件按空处理（`catch (hresult_error)`）——**持久化代码必须假设文件是坏的**。

## 35.4 ViewModel：集合、计数与异步保存

```cpp
void TaskViewModel::Add(hstring const& title, boolean important)
{
    if (title.empty()) { return; }
    hstring finalTitle = important ? title + L" !" : title;
    m_tasks.Append(make<Task>(finalTitle));
    RaisePropertyChanged(L"Count");
    Status(L"Added: " + finalTitle);
    (void)SaveAsync();
}
```

- `Count` 是**派生属性**：集合内容变化不会自动通知它，每次增删显式 `RaisePropertyChanged(L"Count")`（32.4 的"集合通知只跟内容增删"规则）。
- `SaveAsync` 的线程纪律（32.7 标准模式）：**UI 线程拷贝标题快照 → `co_await resume_background()` → 写文件**。IObservableVector 不能跨线程碰，快照先行。

`Load()` 刻意走同步路径：启动时在 UI 线程读一个极小文件，比后台协程 + 切回的完整仪式更合适——**32 章给了异步的完整形态，35 章示范"什么时候不用它"**。这是工程判断，不是偷懒。

## 35.5 页面：对话框表单与行内操作

```cpp
Windows::Foundation::IAsyncAction TaskListPage::ShowAddDialogAsync()
{
    TextBox input;
    input.Header(box_value(L"Task title"));
    CheckBox important;
    important.Content(box_value(L"Important (adds !)"));
    StackPanel form;
    form.Children().Append(input);
    form.Children().Append(important);

    ContentDialog dialog;
    dialog.Title(box_value(L"Add task"));
    dialog.Content(form);                       // Content 收任意元素树（24 章）
    dialog.PrimaryButtonText(L"Add");
    dialog.CloseButtonText(L"Cancel");
    dialog.DefaultButton(ContentDialogButton::Primary);
    dialog.XamlRoot(rootPanel().XamlRoot());    // 24 章核心坑
    auto result = co_await dialog.ShowAsync();
    if (result == ContentDialogResult::Primary)
    {
        m_viewModel.Add(input.Text(), important.IsChecked().Value());
    }
}
```

对话框 UI 用代码拼（TextBox/CheckBox/StackPanel 直接构造）——ContentDialog 的表单不一定要 XAML 文件。行内的 Remove 按钮从 `sender.as<FrameworkElement>().DataContext()` 拿到行对应的 Task（17 章模板上下文）。

## 35.6 IDL 组织（全教程规则的合流)

- `TaskFlow.idl` 一个文件装 **Task + TaskViewModel + TaskListPage**——x:Bind 路径跨了三层引用，MIDL 只在同文件解析（MIDL2011）。
- 构造参数写 `String` 不写 `hstring`（27 章实测：命名空间内 `hstring` 触发 MIDL2011）。
- 纯代码构造的类型（无 x:Bind 引用）不需要 IDL 成员声明——按名字挂的事件处理器照旧免进 IDL（04 章）。

## 35.7 全书坑位总表（按主题归档）

35 个章节撞出来的实测坑，按主题归档速查（每条后括号是首发现章节）：

**事件与解析期**

| 坑 | 症状 | 解法 |
|---|---|---|
| XAML 预置状态触发解析期事件 | IsChecked/SelectedIndex/Value 预置 → 启动即崩 0xC000027B | XAML 放结构、ctor 放状态；handler 首行判空（10.6.1/12.5/14.5.1） |
| ValueChanged 析构期再触发 | 关窗口时 handler 访问半销毁控件 = AV | null 守卫 + 声明顺序（12.5） |
| SelectionChanged 空 AddedItems | 过滤 Clear 触发、GetAt(0) 抛 | 取前查 Size()（17.6.4） |
| AutoSuggest 重入 | 设 ItemsSource 再触发 TextChanged 死循环 | Reason() 过滤 UserInput（15.2） |

**IDL 与投影**

| 坑 | 症状 | 解法 |
|---|---|---|
| IDL 注释非 ASCII | MIDL2025 语法错（位置漂移） | 注释纯英文（27.2.1） |
| MIDL2011 跨 .idl/namespace 内 hstring | 解析成工程命名空间类型 | 同文件声明；String 代 hstring（04/27） |
| CppWinRTOptimized 裁投影 | Storyboard 等冷门类型命名空间消失 | 关掉或全限定名（27.4） |
| runtimeclass 静态成员 | MIDL2025 | XXXProperty 静态留 C++（27.2） |
| GetText 两参/TextGetOptions 在 Microsoft.UI.Text | C2660/C2665 一串 | (options, hstring&) 双参 + 正确命名空间（9.9.3） |

**依赖属性与自定义控件**

| 坑 | 症状 | 解法 |
|---|---|---|
| DP 无默认值 | x:Bind 解析期取值 unbox null 崩 | PropertyMetadata(box_value(L""))（27.2.1 坑①） |
| getter 直用未注册字段 | GetValue(nullptr) 崩 | 先经 XXXProperty() 惰性注册（27.2.1 坑②） |
| DefaultStyleKey 收装箱对象 | C2665 | box_value(类名串)（27.3） |

**布局与窗口**

| 坑 | 症状 | 解法 |
|---|---|---|
| NavigationView Auto 自折叠 | 高 DPI 窄窗面板变汉堡条 | PaneDisplayMode=Left 钉死（22.2） |
| AppWindow 系按逻辑单位 | Resize({1080,700}) 得 1890 物理宽 | 按逻辑传参（31.5.1） |
| 级联出屏吃注入点击 | 底部出屏的窗口按钮点不动 | 构造期自定位完整在屏（31.5.2） |
| 外部 SetWindowPos 打烂岛输入 | 渲染正常、命中错位 | 应用自己动窗口，外部工具绝不动（31.5.3） |

**输入与自动化**

| 坑 | 症状 | 解法 |
|---|---|---|
| 注入鼠标点击 ButtonBase 不闭合 | press 命中但 Click 不完成 | 触摸注入 InjectTouchInput（README 战争实录） |
| 注入输入启动抽奖 | 同一流程时通时不通 | 帧哈希检测 + 整进程重试（tap.ps1） |
| UIA3 树不可见 | 非打包应用 provider 缺失 | 无解（留档）；驱动走输入注入 |
| 视觉读坐标网格不可靠 | 三轮三套数 | 像素连通域扫描 find-blob.ps1 |

**资源与主题**

| 坑 | 症状 | 解法 |
|---|---|---|
| RequestedTheme 同值连设不重估 | 换肤无效但读回值对 | 先 Default 再目标（26.6.1） |
| 代码 TryLookup 拿不到主题资源 | 返回空 | 登记元素手动重刷（26.6.3） |
| 动画 Duration 直传 TimeSpan | C2665 | 包 Xaml::Duration（29.5 细节2） |
| x:Bind+Converter 需 FrameworkElement 根 | Window 根工程编不过 | 走 {Binding Converter}（32.8） |

## 35.8 运行时验证

| 流程 | 证据 |
|------|------|
| 启动加载 | `.smoke/35-taskflow/load/click-1.png`——预置 JSON 两项 → 列表渲染、状态行 "Loaded 2 tasks"、计数 2；同帧可见 Add 对话框弹出（ContentDialog + 表单）与 Mica 背景 |
| 勾选完成 | `.smoke/35-taskflow/toggle/click-1.png`——点击首行复选框，勾选生效、状态行 "finished a task"、次行未受影响 |
| 持久化闭环 | `tasks.json` 内容回读 + `.smoke/35-taskflow/persist/before.png`——**重启后**列表照旧加载两项，"Loaded 2 tasks" |

设置页的材质开关与 Add 对话框的完整输入流（键入→Add）在自动化边界外：对话框键盘焦点时序由 DefaultButton 管理，合成键盘流不做断言（诚实边界；编译与弹出已验证）。

## 35.9 从这里去哪

- 把 Add 对话框换成 24 章的 Closing 校验（空标题拦截）。
- 给列表加 20 章的自制表格（优先级列）。
- 用 32.8 的转换器把 Done 渲染成删除线（Page 根工程可直接 x:Bind+Converter）。
- 打包成 MSIX（33 章）后，把 Storage 换回 `ApplicationData`（34 章的正路）。
- 接 34 章的通知：任务到期弹 `AppNotificationBuilder`。

### 35.9 TaskFlow 与四个功能工程的血缘

TaskFlow 不是孤岛——它是全书四个功能工程的汇流点：

- **设置中心**（07）写的偏好（`default count`、`reminder`）就是 TaskFlow 的配置输入——PreferencesPage 的 Header 明说 "Task defaults consumed by the TaskFlow app"。两个应用共享 `%LOCALAPPDATA%` 下的 JSON 持久化模式（SettingsStore 的读写纪律，34 章同款）。
- **编辑器**（09）的未保存确认（ContentDialog + 脏标记）在 TaskFlow 的行内编辑里复用——改任务标题未提交就导航离开，同一套确认时序。
- **数据浏览器**（17）的过滤管线（多输入归一 ApplyFilters）就是 TaskFlow"按状态筛选任务列表"的模板——单选按钮组当 TreeView 用，计数行同款。
- **主题实验室**（26）的 accent 覆盖在 TaskFlow 的强调色（今日焦点任务）上兑现——`{ThemeResource AccentFillColorDefaultBrush}` 引用让用户在主题实验室调的色对 TaskFlow 生效（同一台机器同一应用资源系统）。

**教程的收束结构**：01-06 打地基，7-30 每个控件在功能工程里干真活，31-34 补窗口与系统边界，35 把四条线索拧回一根——你在这本书里没有学过"控件"，你学过的是四个能用的应用，TaskFlow 是第五个。

### 35.10 从 TaskFlow 到你的应用

抄走 TaskFlow 骨架后的自然扩展（按复杂度排序）：**到期提醒**（16 章 TimePicker 的 reminder 值喂 `DispatcherQueueTimer`，到点 ToastNotification——34 章）、**多列表**（21 章 TabView 每列表一页签，持久化结构升级）、**统计视图**（30 章 Shape 柱状图渲染完成趋势）、**云同步**（34 章的 JSON 序列化对接任意后端）。每一项都只差"最后一块板"——地基在这本书里已经打完。

## 35.9 小结

全书 34 章的内容在这一个工程里各就各位：**外壳（22/31）→ 列表（17/20）→ 对话框（24）→ 状态与集合（32）→ 持久化（34）→ IDL 组织（04/27）**。读懂这个工程的每一行为什么这么写，教程的产出就真正归你了。

---

上一篇：[34 OS 集成](./34-os-integration.md) ｜ 返回 [目录](../README.md)
