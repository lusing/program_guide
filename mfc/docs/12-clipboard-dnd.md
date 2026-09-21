# 12 · 剪贴板与拖放

> 对应示例：`examples/12_clipboard_dnd`

> **本章你将学会**：剪贴板"格式 → 全局内存句柄"的数据模型、`SetClipboardData` 的所有权移交规则、OLE 拖放四个回调各自该返回什么、`OnDrop` 为什么偏偏返回 `BOOL`，以及怎么把数据从自己的窗口拖出去。
> **前置知识**：第 06 章的模态对话框、第 09 章的 `AfxRegisterWndClass` 与自绘子窗口。

## 1. 剪贴板的数据模型

剪贴板本质上是一张**「格式 → 全局内存句柄」的表**。同一份数据可以同时以多种格式放上去（比如一段文字同时提供 `CF_UNICODETEXT` 和 `CF_TEXT`），粘贴方挑自己认识的格式取。

| 格式 | 值 | 内容 |
|---|---|---|
| `CF_TEXT` | 1 | ANSI 文本，以 `\0` 结尾 |
| `CF_BITMAP` | 2 | 位图句柄（`HBITMAP`） |
| `CF_UNICODETEXT` | 13 | **UTF-16 文本**，以 `\0` 结尾 |
| `CF_HDROP` | 15 | 文件列表（`HDROP` 句柄） |
| `CF_DIB` | 8 | 设备无关位图 |

**Unicode 工程一律用 `CF_UNICODETEXT`**。放 `CF_TEXT` 出去，中文在别的程序里就是乱码。

所有权流转是这样的：

```text
你的进程                     系统剪贴板                另一个进程
────────                     ──────────                ──────────
GlobalAlloc(GMEM_MOVEABLE)
  ↓ 填数据
SetClipboardData(fmt, h)
  ↓ ──────── 所有权移交 ─────→ 持有 h
  ↓                            ↓
  ✗ 不能再 GlobalFree          │  GetClipboardData(fmt) → h
                               │  GlobalLock / 读 / GlobalUnlock
                               │  ✗ 不能 GlobalFree（不是它的）
                               ↓
                          你退出后数据仍在（系统已接管）
```

两个方向都有"不能释放"：交出去之后你不能再碰；取回来之后你也不能释放。

**为什么必须 `GMEM_MOVEABLE`**：系统接管后，在需要时可能把这块内存**移动**（甚至换页出去），所以它必须是可以移动的全局内存块。`GMEM_FIXED` 的块地址固定，系统无法搬动，`SetClipboardData` 会失败。

## 2. 文本剪贴板：写与读

**写**：

```cpp
::EmptyClipboard();                       // ① 先清空所有旧格式
const size_t bytes = (len + 1) * sizeof(wchar_t);
HGLOBAL h = ::GlobalAlloc(GMEM_MOVEABLE, bytes);
void* p = ::GlobalLock(h);
memcpy(p, text, bytes);
::GlobalUnlock(h);

if (!::SetClipboardData(CF_UNICODETEXT, h)) {
    ::GlobalFree(h);                      // ② 只有失败时还归我们
    return false;
}
// ③ 成功之后所有权归系统，绝不能再 GlobalFree
```

三步的所有权规则各不相同，这是本节最容易出错的地方。写成"先 `SetClipboardData` 再无条件 `GlobalFree`"就是**双重释放**——而且症状很隐蔽：剪贴板内容损坏、粘贴到别的程序时崩溃，你自己的进程却好好的。

**读**：

```cpp
if (!::IsClipboardFormatAvailable(CF_UNICODETEXT))
    return false;
// ... OpenClipboard ...
HANDLE h = ::GetClipboardData(CF_UNICODETEXT);
const wchar_t* p = (const wchar_t*)::GlobalLock(h);
out = p;
::GlobalUnlock(h);                        // 只解锁，不释放
```

**`OpenClipboard` 必须检查返回值**。剪贴板是全局唯一资源，同一时刻只有一个进程能打开——你点"复制"的瞬间，别的程序可能正开着它。所以标准做法是**重试几次**，而不是失败就直接放弃：

```cpp
class CClipboardLock {                    // RAII：保证任何分支都会 Close
public:
    explicit CClipboardLock(HWND owner = nullptr) {
        for (int i = 0; i < 10; ++i) {
            if (::OpenClipboard(owner)) { m_open = true; return; }
            ::Sleep(20);
        }
    }
    ~CClipboardLock() { if (m_open) ::CloseClipboard(); }
    bool IsOpen() const { return m_open; }
    CClipboardLock(const CClipboardLock&) = delete;
    CClipboardLock& operator=(const CClipboardLock&) = delete;
private:
    bool m_open = false;
};
```

做成 RAII 的理由和 `CPaintDC` 一样：写剪贴板的函数有四五条提前 `return` 的分支，靠手工 `CloseClipboard` 迟早漏一条——**漏掉的那次会让整个系统的剪贴板卡住**，直到你的进程退出。

`EmptyClipboard` 会把**所有**格式一起清掉，不只是文本。如果你的程序同时放了文本和位图，一次 `EmptyClipboard` 两者都没了。

## 3. 拖放：OLE 而不是 WM_DROPFILES

Windows 上接拖放有两条路：

| | `DragAcceptFiles` + `WM_DROPFILES` | `COleDropTarget` |
|---|---|---|
| 代码量 | 三行 | 一个派生类 + 四个回调 |
| 能接什么 | **只能接文件** | 任意格式（文本、图片、自定义格式） |
| 能否拖出 | **不能** | 能（`COleDataSource`） |
| 视觉反馈 | 无（只有系统光标） | 自己控制（`OnDragOver` 里高亮） |
| 依赖 | 无 | 必须 `AfxOleInit()` |

**只做"接受用户拖文件进来"，`WM_DROPFILES` 就够了**：

```cpp
::DragAcceptFiles(m_hWnd, TRUE);
// 然后处理 WM_DROPFILES 消息，用 DragQueryFile 取路径
```

**要接任意格式、或者要支持拖出，就得上 OLE 拖放。** 本章示例走的是这条路。

`AfxOleInit()` 是硬性前提——它在 `afxdisp.h` 里声明，而 `<afxole.h>` 已经包含了 `afxdisp.h`，所以 `#include <afxole.h>` 之后直接调即可。忘了它，`Register()` 会返回 `FALSE`，**拖放完全不工作而且不报错**：

```cpp
BOOL CClipApp::InitInstance() {
    if (!AfxOleInit())          // 拖放必需
        return FALSE;
    ...
}
```

## 4. COleDropTarget 的四个回调

```cpp
class CDropTarget : public COleDropTarget {
public:
    DROPEFFECT OnDragEnter(CWnd*, COleDataObject* pData, DWORD, CPoint) override;
    DROPEFFECT OnDragOver (CWnd*, COleDataObject* pData, DWORD, CPoint) override;
    void       OnDragLeave(CWnd*) override;
    BOOL       OnDrop     (CWnd*, COleDataObject* pData, DROPEFFECT, CPoint) override;
};
```

| 回调 | 时机 | 返回 | 语义 |
|---|---|---|---|
| `OnDragEnter` | 拖进窗口 | `DROPEFFECT` | 这里**允许**什么操作 |
| `OnDragOver` | 在窗口内移动 | `DROPEFFECT` | 同上，会被反复调用 |
| `OnDragLeave` | 拖出窗口 | `void` | 清理视觉状态 |
| `OnDrop` | 松手 | **`BOOL`** | 我**处理了**没有 |

**注意 `OnDrop` 返回 `BOOL` 而不是 `DROPEFFECT`**，其余三个返回 `DROPEFFECT`。写成 `DROPEFFECT OnDrop(...)` 会直接编译失败：

```text
error C2555: “CDropTarget::OnDrop”: 重写虚函数返回类型有差异，
且不是“COleDropTarget::OnDrop”的协变
```

这个设计其实有道理：**`DROPEFFECT` 回答"允许什么"（拖动过程中反复问），`BOOL` 回答"做完了没有"（松手只问一次）**。混用类型等于把两个不同的问题塞进一个返回值。

两个回调的返回值决定光标：

```cpp
DROPEFFECT CDropTarget::OnDragEnter(CWnd*, COleDataObject* pData, DWORD, CPoint) {
    const BOOL ok = pData->IsDataAvailable(CF_HDROP);   // 只接文件
    m_zone->SetHot(ok != FALSE);                        // 自己的高亮反馈
    return ok ? DROPEFFECT_COPY : DROPEFFECT_NONE;      // NONE = 禁止光标
}
```

返回 `DROPEFFECT_NONE`，系统光标会变成"禁止"图标。**先判断格式再返回**是基本礼貌——不然用户拖个图片进来，光标显示"可以放"，松手却什么都不发生。

`OnDragOver` 会被高频调用（鼠标每移动一点就一次），所以**只做轻量的判断**，别在里面读文件、查数据库。

### 取文件列表

```cpp
HGLOBAL h = pData->GetGlobalData(CF_HDROP);
HDROP hDrop = (HDROP)h;
const UINT n = ::DragQueryFile(hDrop, 0xFFFFFFFF, nullptr, 0);   // 0xFFFFFFFF = 取个数
for (UINT i = 0; i < n; ++i) {
    TCHAR path[MAX_PATH] = { 0 };
    ::DragQueryFile(hDrop, i, path, MAX_PATH);
    Use(path);
}
::GlobalFree(h);      // GetGlobalData 返回的句柄归调用方
```

`DragQueryFile` 的第一个参数传 `0xFFFFFFFF` 时返回文件个数，传下标时把路径填进缓冲区——**比自己解析 `DROPFILES` 结构安全得多**。`DragQueryFile` 不需要额外链接库：`afx.h` 已经 `#pragma comment(lib, "shell32.lib")`，而 `afxwin.h` 也包含了 `<shellapi.h>`。

> `GetGlobalData` 返回的句柄**归调用方**，用完要 `GlobalFree`。这一点在 MFC 源码里有两个分支（`oledobj1.cpp`）：源对象的 `pUnkForRelease` 为 `NULL` 时直接把原始句柄交给你（按 COM 规则这就是所有权转移）；不为 `NULL` 时 MFC 先复制一份再把原句柄 `ReleaseStgMedium` 掉。**两条路的结果一样：拿到手的句柄由你负责释放。**

## 5. 把数据拖出去

拖出用 `COleDataSource`：

```cpp
HGLOBAL h = ::GlobalAlloc(GMEM_MOVEABLE, bytes);
// ... 填数据 ...

COleDataSource src;
src.CacheGlobalData(CF_UNICODETEXT, h);   // 数据源接管 h，之后不能再碰
const DROPEFFECT de = src.DoDragDrop(DROPEFFECT_COPY);
```

`CacheGlobalData` **不复制**这块内存，而是把 `hGlobal` 直接存进缓存条目（`oledobj2.cpp` 里 `pEntry->m_stgMedium.hGlobal = hGlobal`，`pUnkForRelease = NULL`）。`COleDataSource` 析构时走 `Empty()` → `::ReleaseStgMedium(...)`，由系统把这块内存 `GlobalFree` 掉。所以**成功调用之后不能再自己释放 `h`**——又是一次双重释放。

`DoDragDrop` 是**阻塞**的：它内部自己跑一个消息循环来驱动拖放，函数返回时拖放已经结束。返回值告诉你对方接受了什么：

| 返回值 | 含义 |
|---|---|
| `DROPEFFECT_COPY` | 对方复制走了 |
| `DROPEFFECT_MOVE` | 对方移走了（源数据应当删除） |
| `DROPEFFECT_NONE` | **对方拒收** |

`DROPEFFECT_NONE` 是常态，不是错误——用户把文字拖到桌面上就是 `NONE`。用它给用户一句反馈（"对方没有接收"）比静默强。

## 6. 常见坑

1. **`OnDrop` 写成返回 `DROPEFFECT`**
   基类是 `BOOL`，返回类型不一致且非协变，编译直接报 **C2555**。记住：`DROPEFFECT` 答"允许什么"，`BOOL` 答"做完了没有"。

2. **忘了 `AfxOleInit()`**
   `m_drop.Register(&wnd)` 返回 `FALSE`，拖放**完全不工作且不报错**——窗口不接收任何拖放，也没有任何提示。`InitInstance` 里第一件事就调它。

3. **`SetClipboardData` 成功后又 `GlobalFree`**
   所有权已经移交给系统，再释放就是双重释放。症状是剪贴板内容损坏、别的程序粘贴时崩溃，你自己的进程看不出来。`CacheGlobalData` 之后同理。

4. **`OpenClipboard` 不检查返回值**
   剪贴板同一时刻只允许一个进程打开。不检查就往下走，`EmptyClipboard` / `GetClipboardData` 全部失败，表现为"偶尔复制不生效"这种最难查的间歇性 bug。标准做法是重试若干次。

5. **拖放目标窗口没调用 `Register`**
   `COleDropTarget` 必须绑定到一个具体窗口（`Register(&wnd)`），而且这个对象要活得比窗口久——做成对话框的成员变量。用局部变量，函数一返回对象析构，窗口还在但拖放已经失效。

6. **自己构造 `CF_HDROP` 时文件列表忘了双 `\0` 结尾**
   格式是 `DROPFILES` 结构 + `路径1\0路径2\0\0`。少最后那个 `\0`，接收方会一直往后读到越界。**读的时候一律用 `DragQueryFile`**，别手工解析。

7. **`EmptyClipboard` 之后以为只是清了文本**
   它清掉的是**所有**格式。同时放了文本和位图的程序，一次 `EmptyClipboard` 两者都没了，需要重新全部放一遍。

8. **在 `OnDragOver` 里做重活**
   鼠标每移动一点就调一次。在里面读文件、查数据库、刷新整个界面，会让拖拽明显卡顿。它只该做"看一眼格式、返回一个 DROPEFFECT"。

## 实战建议

- **剪贴板操作一律包 RAII 小类**：写剪贴板的函数有四五条提前 `return` 的分支，漏一次 `CloseClipboard` 会卡住**整个系统**的剪贴板直到你的进程退出
- **拖放时给实时视觉反馈**：`OnDragEnter`/`OnDragOver` 里改状态栏文字或高亮接收区，用户才知道"这里能放"。示例里接收区在悬停时变绿并显示"松手即接收"
- **`OnDragEnter` 就先判断格式**，不支持的直接返回 `DROPEFFECT_NONE`，让光标一开始就显示"禁止"，比松手后没反应友好得多
- **跨进程拖大数据用延迟渲染**（`DelayRenderData` + 重写 `OnRenderGlobalData`）：数据只在对方真的要时才生成。本章只讲即时渲染（`CacheGlobalData`），够覆盖绝大多数场景

## 自测

1. **`SetClipboardData` 成功之后，为什么不能再 `GlobalFree` 那个句柄？失败时为什么又要释放？**
   —— 成功时所有权已经移交给系统剪贴板，句柄不再属于调用方，再释放就是双重释放（会损坏剪贴板内容）。失败时系统没有接管，内存仍归调用方，不释放就是泄漏。这也是为什么必须判断 `SetClipboardData` 的返回值。

2. **`COleDropTarget` 的四个回调里，哪一个返回类型和其他三个不同？为什么这样设计？**
   —— `OnDrop` 返回 `BOOL`，其余三个返回 `DROPEFFECT`。`DROPEFFECT` 回答的是"允许什么操作"（拖动过程中会被反复问），`BOOL` 回答的是"我处理完了没有"（松手只问一次）。写错返回类型会报 C2555。

3. **只接文件、不需要拖出，用 `WM_DROPFILES` 还是 `COleDropTarget`？**
   —— 用 `DragAcceptFiles` + `WM_DROPFILES`，三行代码就够，也不需要 `AfxOleInit()`。只有需要接收任意格式（文本、图片、自定义格式）或需要支持拖出时，才值得上 OLE 拖放那一套。

4. **为什么 `OpenClipboard` 失败时应该重试而不是直接返回？**
   —— 剪贴板是全局唯一资源，同一时刻只允许一个进程打开。别的程序可能正好开着它，直接返回会表现为"偶尔复制不生效"这种间歇性故障。标准做法是重试若干次（每次间隔几十毫秒）。

5. **`DoDragDrop` 返回 `DROPEFFECT_NONE` 说明出错了么？**
   —— 不是错误，是"对方拒收"。用户把文字拖到桌面、或者拖到一个不接受文本的程序上，都会返回 `NONE`。它是常见结果，值得用它给用户一句反馈而不是静默处理。

---
上一章：[11 工具栏与状态栏](11-toolbars.md) ｜ 下一章：[13 系统集成：文件系统、最近文件与配置](13-shell-integration.md)
