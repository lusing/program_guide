# 第 23 章 COM 实战：调用系统组件

> **本章回答的问题**：使用 COM 的标准骨架是什么？`CoCreateInstance` 五个参数各说什么？`IFileOpenDialog` 怎么用？组件给的内存怎么释放？系统里有哪些现成 COM 组件可白嫖？
>
> **前置章节**：第 22 章（接口/引用计数/ComPtr/套间——本章全部用上）。
>
> **你将做出什么**：一个 COM 版文件选择器（`examples/26_com_file_dialog`）——二十行核心代码替换掉第 10 章的通用对话框全家桶。

本章示例：`examples/26_com_file_dialog/main.cpp`。

## 23.1 使用 COM 的五步骨架

任何"调用 COM 组件"的代码都是这五步，先背下来再看细节：

```text
① CoInitializeEx(套间)          开场白：本线程声明套间（每线程一次）
        │
② CoCreateInstance(CLSID, ...)  按 CLSID 找到组件、造出对象、拿到接口指针
        │                        （指针已 AddRef——你拥有它）
③ p->方法() / QI 换接口          用接口干活
        │
④ p->Release()                  归还引用（ComPtr 则自动）
        │
⑤ CoUninitialize()              收场白（与 ① 配对）
```

配对纪律表（漏一个就是泄漏或未定义）：

| 开 | 收 |
|----|----|
| `CoInitializeEx` | `CoUninitialize` |
| `CoCreateInstance` / `QI` 拿到的每个指针 | `Release`（或 ComPtr 析构） |
| 组件返回的内存（字符串、数组） | `CoTaskMemFree` |

## 23.2 `CoCreateInstance` 逐参数讲

```cpp
ComPtr<IFileOpenDialog> dlg;
HRESULT hr = CoCreateInstance(
    CLSID_FileOpenDialog,     // ① 要谁（类 ID，头文件里的常量）
    nullptr,                  // ② 聚合用，几乎总是 nullptr（22 章"不支持聚合"）
    CLSCTX_INPROC_SERVER,     // ③ 在哪儿运行：进程内 DLL / 本地 EXE / 远程
    IID_PPV_ARGS(&dlg));      // ④+⑤ 要什么接口 + 接收指针的地址
```

**CLSID 从哪来**：SDK 头文件常量（`CLSID_FileOpenDialog`）、注册表反查（`CLSIDFromProgID(L"Excel.Application")`）、文档抄录。**③ 上下文**：`CLSCTX_INPROC_SERVER`（进程内 DLL，绝大多数场景）为主，了解 `CLSCTX_LOCAL_SERVER`（独立 EXE 进程，如 Word 自动化——调用透明地跨了进程，代理在中间排队，22.7 的套间机制在干活）。**`IID_PPV_ARGS(&p)`** 是"IID 与取地址"二合一宏，避免类型手滑——新代码一律用它。

## 23.3 实战：`IFileOpenDialog` 全解剖

`examples/26_com_file_dialog` 的核心二十行，逐段注释：

```cpp
// ② 创建：CLSID_FileOpenDialog 是 Shell 自带的文件打开对话框组件
ComPtr<IFileOpenDialog> dlg;
CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                 CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dlg));

// ③a 配置：读现有选项 → 位或上新标志（先读后写的惯例，别直接覆盖）
FILEOPENDIALOGOPTIONS opts = 0;
dlg->GetOptions(&opts);
dlg->SetOptions(opts | FOS_FORCEFILESYSTEM | FOS_ALLOWMULTISELECT);

// ③b 显示：模态；内部自己转消息循环（STA 的隐藏窗口机制在干活，22.7）
HRESULT hr = dlg->Show(hwnd);
if (FAILED(hr)) {
    if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        // 用户取消是"失败的 HRESULT"但不是错误——第 3 章语义课的现场
    }
    return;
}

// ③c 取结果：GetResult 给出 IShellItem（Shell 对"一个文件"的抽象）
ComPtr<IShellItem> item;
dlg->GetResult(&item);
PWSTR path = nullptr;
item->GetDisplayName(SIGDN_FILESYSPATH, &path);   // 要"文件系统完整路径"形态
// ... 用 path ...
CoTaskMemFree(path);      // ★ 组件分配的内存：CoTaskMemFree，不是 free/delete
```

四个可迁移的要点：

1. **"先 GetOptions 再 SetOptions"**：标志位 API 的通用惯例，直接覆盖会把默认位抹掉；
2. **取消的处理**：`ERROR_CANCELLED` 打包成 HRESULT 返回——失败码≠错误的活例；
3. **`CoTaskMemFree`**：跨模块内存的官方答案（COM 统一分配器 `IMalloc` 的快捷封装）——第 20 章"内存不跨界"原则在 COM 世界的落地；
4. **`SIGDN_FILESYSPATH`**：同一个 `IShellItem` 能以多种名字形态自述（显示名/解析名/URL），按需选。

## 23.4 与 `GetOpenFileNameW` 对比：该用哪个

| | `GetOpenFileNameW`（第 10 章） | `IFileOpenDialog` |
|---|---|---|
| 出现年代 | Win95 | Vista |
| 外观 | 老式对话框（系统自动套壳） | 现代资源管理器风格 |
| 多选/自定义位置栏/元数据 | 弱 | 强 |
| 代码量 | 少（一个结构体） | 稍多（COM 骨架） |
| 扩展性 | 无 | 可加自定义控件（IFileDialogCustomize） |

新代码建议直接 `IFileOpenDialog`；读老代码认识 `GetOpenFileNameW` 即可。

## 23.5 系统里的 COM 组件地图

学会骨架后，整个 Windows 的组件库向你敞开（都是"查 CLSID → CoCreateInstance →调方法"同一套）：

| 领域 | 组件 | 用途 |
|------|------|------|
| Shell | `IFileOpenDialog`/`IFileSaveDialog`、`IShellItem` | 文件选择、Shell 命名空间 |
| 任务栏 | `ITaskbarList3` | 进度条入任务栏、缩略图按钮（第 28 章） |
| 拖放 | `IDropTarget`/`DoDragDrop` | OLE 拖放（第 29 章） |
| 图形 | Direct2D/DirectWrite 全家（第 25 章） | 现代渲染——COM 接口的天下 |
| 自动化 | `IDispatch` | 脚本调用（VBScript/JS 时代的地基） |
| 新世界 | WinRT 投影（第 26 章） | C++/WinRT 内部就是 COM |

## 23.6 常见坑

- **工作线程忘初始化**：`CoCreateInstance` 在没 `CoInitializeEx` 的线程上返回 `CO_E_NOTINITIALIZED`——每个用 COM 的线程都要开场白；
- **STA 里长活阻塞消息泵**：STA 线程要能收消息，长期忙循环会让跨套间调用排队超时；
- **老系统 IID 缺失**：新接口在老 Windows 上 QI 失败——按 `E_NOINTERFACE` 降级，别崩；
- **`GetResult` 在取消后调用**：取消时没有结果，`GetResult` 返回失败——先判 `Show` 的返回值再取。

## 23.7 完整示例解剖

`examples/26_com_file_dialog`：`wWinMain` 开场白（`CoInitializeEx` STA）→ 按钮触发创建对话框 → 配置/显示/取消处理/取结果 → 窗口里显示所选路径 → 收场白（`CoUninitialize`）。GUI 程序，编译验证 + 手动运行：选一个文件，看静态文本变成完整路径。

## 23.8 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| `CO_E_NOTINITIALIZED` | 该线程没 `CoInitializeEx` | 23.1 骨架 |
| 对话框秒退/不显示 | `Show` 的返回没判（取消当成 bug） | 区分取消与失败（23.3） |
| 路径显示乱码后崩溃 | `GetDisplayName` 的内存用 `free` 释放 | `CoTaskMemFree` |
| 选项设置无效 | 直接 `SetOptions(新值)` 抹掉了默认位 | 先 Get 后或（23.3） |
| 多选只拿到一个 | 没设 `FOS_ALLOWMULTISELECT`；多选要用 `GetResults` | 查文档换方法 |
| 工作线程创建组件挂起 | MTA/STA 与组件模型不匹配 | 看组件文档的 ThreadingModel |

## 23.9 小结

1. 五步骨架：初始化 → 创建 → 调用 → 释放 → 收尾，配对纪律表背熟。
2. `CoCreateInstance(CLSID, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&p))` 是万用创建句式。
3. `IFileOpenDialog` 实战四要点：选项先读后或、取消是失败码、`CoTaskMemFree` 还内存、`SIGDN` 选名字形态。
4. 新代码用 COM 对话框，认识老的即可。
5. 系统组件地图打开后，COM 是"白嫖系统功能"的最大入口。

## 23.10 动手练习

1. 改造成 `IFileSaveDialog`：加"覆盖确认"（默认有）、文件类型过滤（`SetFileTypes` + `COMDLG_FILTERSPEC` 数组）。
2. 多选版：`FOS_ALLOWMULTISELECT` + `GetResults`（返回 `IShellItemArray`，`GetCount/GetItemAt` 遍历）把所有路径列进一个 ListBox（第 5 章）。
3. 概念验证：故意注释掉 `CoInitializeEx`，观察错误码——把 23.8 第一行亲手踩一遍。

---

**下一章**：[第 24 章 COM 实现](24-COM实现.md)——亲手写一个进程内 COM 服务器。
