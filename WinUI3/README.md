# WinUI 3 C++/WinRT 编程指南

## 目录

1. [简介](#简介)
2. [环境与工具链](#环境与工具链)
3. [示例目录结构](#示例目录结构)
4. [编译验证](#编译验证)
5. [章节与源码索引](#章节与源码索引)
6. [常见模式（全部 C++）](#常见模式全部-c)
7. [后续扩展建议](#后续扩展建议)

---

## 简介

本指南已统一为 **C++ 示例**。  
WinUI 3 的界面层通常使用 XAML，而业务逻辑、状态管理、命令、异步流程可以用 C++/WinRT 组织。

本目录不再保留 C# 示例工程，所有可编译代码都在 `cpp_examples/` 下。

---

## 环境与工具链

- Visual Studio: `G:\Program Files\Microsoft Visual Studio\18\Community`
- C++ 编译器：MSVC `cl.exe`
- 初始化脚本：`VC\Auxiliary\Build\vcvars64.bat`

---

## 示例目录结构

```text
WinUI3/
├── README.md
├── build.ps1
├── cpp_examples/
│   ├── 01_hello_event/
│   ├── 02_mvvm_command/
│   ├── 03_navigation_state/
│   ├── 04_async_dispatch/
│   ├── 05_resource_dictionary/
│   ├── 06_collection_binding/
│   ├── 07_dependency_injection/
│   └── 08_lifecycle_events/
└── build/
    └── cpp_obj/
```

---

## 编译验证

在 [WinUI3/](G:/code/guide/WinUI3/) 执行：

```powershell
.\build.ps1
```

清理输出：

```powershell
.\build.ps1 -Clean
```

---

## 章节与源码索引

1. 事件处理与窗口交互  
   - [hello_event.cpp](G:/code/guide/WinUI3/cpp_examples/01_hello_event/hello_event.cpp)
2. MVVM 命令模式  
   - [mvvm_command.cpp](G:/code/guide/WinUI3/cpp_examples/02_mvvm_command/mvvm_command.cpp)
3. 页面导航与状态切换  
   - [navigation_state.cpp](G:/code/guide/WinUI3/cpp_examples/03_navigation_state/navigation_state.cpp)
4. 异步任务与 UI 调度  
   - [async_dispatch.cpp](G:/code/guide/WinUI3/cpp_examples/04_async_dispatch/async_dispatch.cpp)
5. 资源字典与主题色  
   - [resource_dictionary.cpp](G:/code/guide/WinUI3/cpp_examples/05_resource_dictionary/resource_dictionary.cpp)
6. 集合绑定模型  
   - [collection_binding.cpp](G:/code/guide/WinUI3/cpp_examples/06_collection_binding/collection_binding.cpp)
7. 依赖注入与服务组织  
   - [dependency_injection.cpp](G:/code/guide/WinUI3/cpp_examples/07_dependency_injection/dependency_injection.cpp)
8. 应用生命周期事件  
   - [lifecycle_events.cpp](G:/code/guide/WinUI3/cpp_examples/08_lifecycle_events/lifecycle_events.cpp)

---

## 常见模式（全部 C++）

### 1) 事件处理

```cpp
void on_say_hello_click(const MainWindowViewModel& vm, std::string_view name)
{
    std::cout << vm.build_greeting(name) << '\n';
}
```

### 2) 命令封装（RelayCommand）

```cpp
class RelayCommand {
public:
    explicit RelayCommand(std::function<void()> execute)
        : execute_(std::move(execute)) {}
    void execute() const { execute_(); }
private:
    std::function<void()> execute_;
};
```

### 3) 导航状态机

```cpp
enum class PageId { Home, Settings, About };
```

### 4) 后台线程 + 调度队列

```cpp
std::jthread worker([&](std::stop_token) {
    for (int i = 1; i <= 5; ++i) {
        std::this_thread::sleep_for(10ms);
        ui_dispatcher.try_enqueue([&progress, i]() { progress = i * 20; });
    }
});
```

### 5) 资源字典

```cpp
colors_.emplace("PrimaryColor", Color{0x00, 0x78, 0xD4});
```

---

## 后续扩展建议

可以继续增加以下 C++ 章节并保持可编译验证：

- WinRT 事件退订（RAII / revoker）
- 多页面导航栈与参数传递
- 本地配置存储（JSON）
- 网络请求封装（WinHTTP/WinRT HttpClient）
- 单元测试友好的 ViewModel 划分

