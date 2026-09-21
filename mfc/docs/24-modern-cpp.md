# 24 · MFC 与现代 C++

> 对应示例：本章不新增示例工程，直接对照 `examples/13_shell_integration` 的源码，逐处给出"现代 C++ 改写版"。

> **本章你将学会**：MFC 惯用法的年代背景、怎么用 RAII 包装裸句柄、`unique_ptr` 和 MFC 对象所有权怎么配合不踩双杀、`CString` 与 `std::wstring` 的边界划分、C++20 特性能带进 MFC 工程什么，以及两套异常体系的共存规则。
> **前置知识**：第 13 章的系统集成（对照源码）、第 21 章的异常体系。

## 1. 为什么 MFC 代码容易"不现代"

MFC 诞生于 C++98 标准化之前：没有智能指针、没有移动语义、没有 lambda。所以它自己发明了一整套——`CString`、引用计数的 `CWnd` 句柄映射、`TRY/CATCH` 宏、`new` 出异常对象再手工 `Delete`。**这些在那个年代都是先进的**。

今天读 MFC 代码觉得"老气"，通常不是 MFC 的错，而是写法停在 1995 年。目标不是抛弃 MFC（框架、资源体系、消息映射仍然高效），而是：

> **在 MFC 边界上使用现代 C++**——框架交界处按 MFC 的规矩来，边界以内是你自己的现代 C++ 领地。

## 2. RAII 包装裸句柄

对照 `13_shell_integration` 的递归扫描：`CFileFind` 本身已是 RAII（析构关闭搜索句柄），但 Windows 层的裸句柄散落各处就危险了。典型反例（第 20 章的线程收尾代码里就有雏形）：

```cpp
// 改造前：任何提前 return / 抛异常都泄漏
HANDLE hFile = ::CreateFile(...);
if (出错) return;                 // ← 泄漏
... 读文件 ...
::CloseHandle(hFile);
```

```cpp
// 改造后：unique_ptr + 自定义 deleter，异常路径也安全
auto closer = [](HANDLE h) { if (h && h != INVALID_HANDLE_VALUE) ::CloseHandle(h); };
std::unique_ptr<void, decltype(closer)> hFile(::CreateFile(...), closer);
if (出错) return;                 // ← 析构自动 CloseHandle
... 读文件 ...
```

注意一个反直觉的实例：示例 13 的**单实例互斥体故意不 `CloseHandle`**——它要撑到进程结束才能挡住第二个实例：

```cpp
HANDLE hMutex = ::CreateMutex(nullptr, FALSE, _T("Guide.Mfc.ShellIntegration"));
// 注释明说：不要 CloseHandle —— 生命周期 = 进程，不是作用域
```

这正好点破 RAII 的本质：**包装的对象生命周期 = 所有权周期**。互斥体的周期是进程，不是函数作用域，硬套 RAII 反而错。先想清楚资源"活到什么时候"，再决定要不要包。

`CFile`/`CDC`/`CPen` 这类 MFC 类自己就是 RAII，不需要再包一层——要包的是它们没覆盖的裸 API 句柄（`HANDLE`、`HICON`、`HBITMAP` 之流）。

## 3. 智能指针与 MFC 对象所有权

`std::unique_ptr` 管理的对象必须"归它独占释放"。和 MFC 对象混用前先问：**谁负责 delete？**

| MFC 对象 | 所有权 | 能套 unique_ptr 吗 |
|---|---|---|
| `CFrameWnd`/`CDialog`（框架创建的） | 框架在窗口销毁后自动 delete | **不能**——双重释放 |
| 非 `PostNcDestroy` 的对话框，由你 `new` | 谁管？二选一：`unique_ptr` 或 MFC 的 `delete this` 惯用法 | 选一种，不能都做 |
| `CRuntimeClass::CreateObject` 造出的对象 | 归你 | 可以，且推荐 |
| `CDocument` 里的条目对象（第 17 章） | 归文档，`DeleteContents` 释放 | 容器内可以用，别再套第二层 |

第 17 章的读取循环就是现成的改造点：

```cpp
// 改造前：读到一半抛异常，已读对象靠 DeleteContents 兜底
CObject* p = nullptr;
ar >> p;
m_items.Add(static_cast<CItem*>(p));

// 改造后：unique_ptr 先接管，成功后才移交给容器 —— 中途异常也零泄漏
CObject* p = nullptr;
ar >> p;
std::unique_ptr<CItem> owner(static_cast<CItem*>(p));
if (ver < 2) owner->m_note = _T("（v1 文件）");
m_items.Add(owner.release());       // 所有权移交容器
```

`std::shared_ptr<CWnd>` 几乎总是错的：窗口的生命周期由消息体系（`WM_NCDESTROY`）决定，和引用计数**不同步**——计数归零时窗口可能还活着，窗口死了计数可能还挂着。共享所有权只用于纯数据对象。

## 4. CString 与 std::wstring 的边界

| 任务 | CString | std::wstring |
|---|---|---|
| 格式化 | `Format(_T("%d 项"), n)` | `std::format(L"{} 项", n)` |
| 截取 | `Mid`/`Left`/`Right`/`Find` | `substr`/`find`/`starts_with` |
| 修剪 | `Trim`/`TrimLeft` | 手写或 C++23 |
| 与 MFC API 交互 | 直接传（它就是 LPCTSTR） | 要 `c_str()` 转换 |

转换成本低：`CString` 取 `GetString()` 就是 `const wchar_t*`，喂给 `std::wstring_view`/`std::wstring` 构造函数即可；反向 `CString(s.c_str())`。

**建议的分界线：MFC 边界内用 `CString`，纯逻辑层用 `std::wstring`，转换只发生在边界。** 理由在第 25 章被实践验证——`stats.cpp` 的统计逻辑全用标准 C++（`std::wstring`/`std::vector`），不 include 任何 MFC 头，可以脱离界面单测；`main.cpp` 里才做 `CString ↔ std::wstring` 的翻译。

顺带：`/DUNICODE` 已是本书构建的默认，`_T()`/`TCHAR` 的双轨保护没有存在意义了——新代码直接 `L""` 和 `wchar_t`，少一层宏噪音。（本书为与旧示例风格一致保留 `_T()`，新项目不必跟。）

## 5. C++20 能带进来什么

`build.ps1` 的编译参数里 `/std:c++20` 已经在位——MFC 工程用现代 C++ 不需要任何额外配置，缺的只是习惯：

```cpp
// std::format：类型安全，不用记 %d/%s 的顺序
CString s(std::format(L"扫描 {} 个文件，共 {:.1f} MB", files, mb).c_str());

// std::span：缓冲区自带长度，不再传 (buf, sizeof(buf)) 双参数
BOOL ReadBlock(std::span<BYTE> buf);

// constexpr 常量表替代手写数组 + 长度
static constexpr std::array kExts{ L".txt", L".md", L".cpp" };

// wstring_view 做只读参数，省掉不必要的拷贝
bool IsMarkdown(std::wstring_view path);
```

两套格式化语法**不能混**：`CString::Format` 是 printf 家族（`%d`/`%s`），`std::format` 是占位符（`{}`/`{:.1f}`）。建议格式化逻辑统一收敛到 `std::format`，结果 `.c_str()` 进 `CString`。

## 6. 异常：两套体系怎么共存

第 21 章讲过：MFC 异常是**堆对象**（捕获后要 `Delete`），标准异常是**栈对象**（`catch` 引用）。共存规则一句话：

> **新代码抛标准异常；MFC 边界处捕获 `CException*`，翻成标准异常再往上传。**

```cpp
// 边界转换函数：把 MFC 异常翻译成标准异常，Delete 的责任就地了结
std::runtime_error Translate(const CException* e) {
    TCHAR buf[256] = _T("");
    e->GetErrorMessage(buf, 256);
    return std::runtime_error(CT2A(buf).GetBuffer());   // 或保留宽字符
}

void LoadConfig() {
    try {
        ... MFC 文件操作 ...        // 可能抛 CFileException*
    } catch (CException* e) {
        auto err = Translate(e);
        e->Delete();               // MFC 异常的生命周期到此为止
        throw err;                 // 之后的世界只有标准异常
    }
}
```

这样一来，业务代码里只有一套 catch 语法（引用捕获），MFC 异常被隔离在框架交界处——第 21 章"忘记 Delete"那类泄漏从结构上消失。

## 7. 迁移策略

对存量 MFC 工程，**不要重写**。渐进顺序：

1. **新增代码用现代 C++**（新文件不碰 `new`/`delete`、逻辑层不依赖 MFC）
2. **边界处加 RAII 包装**（裸句柄包成 `unique_ptr`，异常路径先安全）
3. **逐文件把裸资源换成 RAII**（每改一个文件就能编译能跑——本书的 `build.ps1` + `smoke.ps1` 就是安全网）
4. **最后才考虑字符串层降级**（`CString` 退出逻辑层，纯收益，动静也最大）

每一步都是独立可交付的改动，任何一步停下来工程都是完好的。

## 8. 常见坑

1. **给框架管理的 MFC 对象套 `unique_ptr`**
   `CFrameWnd`（LoadFrame/ProcessShellCommand 流程）销毁后框架自己 delete，你再管一次就是双重释放。先查所有权（第 3 节表），再决定谁管。

2. **`std::shared_ptr<CWnd>` 管窗口**
   引用计数与 `WM_NCDESTROY` 的生命周期脱节：计数没归零窗口已死，或窗口已死对象还占着。窗口对象要么框架管、要么 `unique_ptr` + 明确的销毁时序。

3. **`CString` 渗透进逻辑层**
   统计、解析、序列化代码里全是 `CString`，等于把 MFC 绑进每一个 `.cpp`——没法脱离界面单测（第 25 章 `stats.cpp` 是反例教材：纯 C++ 零 MFC 依赖）。

4. **两套格式化语法混用**
   `%d` 和 `{}` 各有各的引擎，`std::format` 的格式串喂给 `CString::Format` 轻则输出乱码重则崩溃（`{:.1f}` 被当成字面量，参数错位）。统一收敛到一种。

5. **`_T("")` 与 `L""` 混用**
   Unicode-only 工程里功能等价，但混用让字符类型语义混乱，切回 MBCS 配置时 `_T()` 的地方变 `char`、`L""` 的地方还是 `wchar_t`，编译错误成片。一个工程选一种（新工程选 `L""`）。

## 9. 实战建议

- **逻辑层写成不依赖 MFC 的普通 C++**（纯计算、解析、统计），可以脱离界面单测——这是第 25 章实战项目刻意演示的结构
- MFC 边界处用 RAII 把裸资源管起来：一个自定义 deleter 的 `unique_ptr` 就够，不必为每种句柄写包装类
- `/std:c++20` 已在 `build.ps1` 里，`std::format`/`std::span`/`constexpr` 直接可用；升级 `/std:c++latest` 还能尝鲜 C++23
- 存量代码按第 7 节顺序渐进，每步可编译可运行；把 `build.ps1 -All` + `smoke.ps1` 当迁移安全网

## 自测

1. **RAII 包装裸句柄的原则是什么？示例 13 的互斥体为什么故意不包？**
   —— 包装对象的生命周期必须等于资源的所有权周期：作用域内用完即放的包成 `unique_ptr` + 自定义 deleter；互斥体的生命周期是"进程结束"（提前关了就挡不住第二个实例），不是函数作用域，硬套 RAII 反而引入 bug。

2. **哪些 MFC 对象绝不能套 `unique_ptr`？判断依据是什么？**
   —— 框架接管的（`CFrameWnd`、模板创建的文档/子框架）：框架在 `WM_NCDESTROY` 后自动 delete。判断依据是"谁负责 delete"——所有权只有一个主人，两套管理机制并存必然双杀。

3. **`CString` 和 `std::wstring` 的建议分界线在哪？为什么？**
   —— MFC 边界内用 `CString`（API 直接吃 LPCTSTR），纯逻辑层用 `std::wstring`（不依赖 MFC 头、能独立单测），转换只发生在边界、成本低（`GetString()`/构造函数）。

4. **两套异常体系的共存规则是什么？**
   —— 新代码抛标准异常（栈对象、引用捕获）；MFC 边界处捕获 `CException*`，用 `GetErrorMessage` 翻译后 `Delete()`，再 `throw` 标准异常向上传。MFC 异常被隔离在框架交界处。

---
上一章：[23 部署与发布](23-deployment.md) ｜ 下一章：[25 实战项目：记事本+](25-notepad-plus.md)
