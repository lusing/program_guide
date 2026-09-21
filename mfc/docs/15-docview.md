# 15 · Doc/View 架构

> 对应示例：`examples/15_docview`

> **本章你将学会**：`CRuntimeClass` 反射创建为什么是 Doc/View 的地基、`UpdateAllViews` 三种调用形态怎么选、`OnInitialUpdate` 与 `OnUpdate` 的时机差异，以及脏标记如何驱动"标题加 `*`"和"关闭询问"。
> **前置知识**：第 02 章的应用生命周期、第 10 章的文件编码。

## 1. 为什么有 Doc/View

前几章的程序都是"窗口 + 控件 + 散落的成员变量"。数据一多（多文档、多视图、撤销栈），窗口类会膨胀成上帝类。MFC 的 Doc/View 把职责拆成三块：

```text
CWinApp  ──── 持有文档模板列表
             │
CSingleDocTemplate ──── 绑定 [资源ID + 文档类 + 框架类 + 视图类]
             │
   CDocument（数据）←──→ CView（显示/编辑）
             ↑
        CFrameWnd（容器壳）
```

| 类 | 职责 | 你写的核心函数 |
|---|---|---|
| `CDocument` | 数据 + 文件读写 + 脏标记 | `Serialize`、`OnNewDocument` |
| `CView` | 显示数据、响应用户编辑 | `OnDraw`、`OnUpdate` |
| `CFrameWnd` | 窗口壳、菜单/工具栏 | 一般不用改 |
| `CDocTemplate` | 四者的绑定关系和创建逻辑 | 只需声明 |

**核心原则：数据只在 Document 里，视图只是数据的投影。** 视图需要数据就 `GetDocument()`；数据变了文档调 `UpdateAllViews()` 广播，各视图在 `OnUpdate` 里刷新。

## 2. SDI 全流程（CSingleDocTemplate）

单文档界面（SDI）在 `InitInstance` 里装配：

```cpp
auto* pTemplate = new CSingleDocTemplate(
    IDR_MAINFRAME,                    // 菜单 + 加速键 + 标题串
    RUNTIME_CLASS(CNoteDoc),          // 文档类
    RUNTIME_CLASS(CMainFrame),        // 框架类
    RUNTIME_CLASS(CNoteView));        // 视图类
AddDocTemplate(pTemplate);

CCommandLineInfo cmdInfo;
ParseCommandLine(cmdInfo);            // 支持拖文件到 exe 图标直接打开
if (!ProcessShellCommand(cmdInfo))
    return FALSE;                     // 创建初始文档 + 框架 + 视图
m_pMainWnd->ShowWindow(m_nCmdShow);
```

`IDR_MAINFRAME` 的字符串表有严格的 9 字段格式（`\n` 分隔），框架靠它取窗口标题、文件过滤器和扩展名：

```rc
STRINGTABLE
BEGIN
    IDR_MAINFRAME "MFC 笔记\n笔记\n笔记\n文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||\n.note\nNote.Document\n笔记文档\n笔记"
END
```

字段依次是：窗口标题、文档名、新建默认名、过滤器名、过滤器、默认扩展名、注册表类型 ID、注册表类型名、新文件过滤器名。

## 3. 文档模板与运行时类信息

模板为什么只拿三个 `RUNTIME_CLASS(...)` 就能造出整个界面？因为框架要在**不知道你的类名**的情况下创建它们——`CSingleDocTemplate` 的代码在 MFC 库里写死了，不可能出现 `new CNoteDoc`。它需要的是 C++ 没有原生提供的能力：**反射**。

MFC 用一套宏手工实现了它：

```cpp
class CNoteDoc : public CDocument {
    DECLARE_DYNCREATE(CNoteDoc)       // 头文件：声明静态成员 + 虚函数
public:
    CNoteDoc() = default;
    ...
};
// cpp 文件：定义上面的静态成员，展开出一个"给我一块内存就能造出对象"的函数
IMPLEMENT_DYNCREATE(CNoteDoc, CDocument)
```

`IMPLEMENT_DYNCREATE` 展开后，每个类都带一个静态的 `CRuntimeClass` 结构（类名、大小、**创建函数指针**、基类的 `CRuntimeClass` 链）。`RUNTIME_CLASS(CNoteDoc)` 返回的就是这个结构的地址：

```text
CDocTemplate
   │  m_pDocClass / m_pFrameClass / m_pViewClass（三个 CRuntimeClass*）
   │
   │  ProcessShellCommand / OpenDocumentFile(...)
   ▼
CRuntimeClass::CreateObject()  ──►  new CNoteDoc()   （文档：数据）
CRuntimeClass::CreateObject()  ──►  new CMainFrame() （框架：窗口壳）
CRuntimeClass::CreateObject()  ──►  new CNoteView()  （视图：显示）
   │
   ▼
框架再把三者"缝合"：视图挂进框架，文档接给视图（OnInitialUpdate）
```

对写代码的三条硬性要求，都源自"框架替你 `new`"这件事：

- **构造函数必须 `public`**。写成 `private`/`protected`，`CreateObject` 里的 `new` 编译不过——这是 Doc/View 程序里最反直觉的一条（普通 C++ 里用工厂时构造常是 `private`，这里相反）。
- **DECLARE 和 IMPLEMENT 必须成对**。`DECLARE_DYNCREATE` 在头文件里声明静态成员，`IMPLEMENT_DYNCREATE` 在 **cpp** 里定义它——只写 DECLARE，链接时报 `unresolved external`。
- **必须有无参构造路径**（成员用默认初始化）。框架 `new` 完不会再调你的初始化函数，文档自己的初始化写在 `OnNewDocument` 里。

## 4. 免费得到的命令

文档模板装配好之后，这些菜单命令**不用写一行处理代码**：

| 命令 ID | 框架行为 |
|---|---|
| `ID_FILE_NEW` | 清空当前文档（`OnNewDocument`），标题变"未命名" |
| `ID_FILE_OPEN` | 按 9 字段串里的过滤器弹打开框，读文件走 `Serialize` |
| `ID_FILE_SAVE` | 有名字直接写；没名字转另存为 |
| `ID_FILE_SAVE_AS` | 弹另存框 |
| `ID_APP_EXIT` | 若脏则提示保存，然后退出 |

你只需要在 `Serialize` 里写真正的读写逻辑——文件对话框、脏检查提示（标题带 `*`、关闭询问）全部由框架驱动。

## 5. Serialize：文档与文件的唯一通道

```cpp
void CNoteDoc::Serialize(CArchive& ar) override {
    if (ar.IsStoring()) {
        ar << m_text;          // 保存：对象 → 文件
    } else {
        ar >> m_text;          // 加载：文件 → 对象
    }
}
```

`CArchive` 支持 `<<`/`>>` 的类型：CString、基本类型、`CObject*` 派生（配合 `IMPLEMENT_SERIAL`）、字节数组等。

注意：`ar << CString` 写的是 **MFC 二进制格式**，记事本打不开。想让文件是纯文本就绕过序列化、用 `ar.GetFile()` 直接写字节（示例 15 写的是 UTF-8 带 BOM，与第 10 章的编码函数一致）：

```cpp
CFile* f = ar.GetFile();
if (ar.IsStoring()) {
    CT2A utf8(m_text, CP_UTF8);
    const BYTE bom[] = { 0xEF, 0xBB, 0xBF };
    f->Write(bom, sizeof(bom));
    f->Write((LPCSTR)utf8, (UINT)strlen((LPCSTR)utf8));
} else {
    // 二进制读入 → 看 BOM → MultiByteToWideChar（同第 10 章）
}
```

**`Serialize` 里别调 `UpdateAllViews`**——加载过程是"边读边改文档"，中途广播会让视图去读半成品数据。加载完成由框架统一触发刷新。

## 6. 多视图与数据同步

文档变了，通知视图的通道是：

```cpp
void CNoteDoc::OnSomethingChanged() {
    UpdateAllViews(nullptr, HINT_TEXT_CHANGED, nullptr);
}
```

三个参数的三种用法：

| 调用 | 效果 |
|---|---|
| `UpdateAllViews(nullptr)` | 广播给**所有**视图，无提示 —— 全量刷新 |
| `UpdateAllViews(this)` | **排除发送者自己** —— 常用于"我改完了，别的视图跟上" |
| `UpdateAllViews(nullptr, lHint, pHint)` | 带提示：`lHint` 传个枚举，`pHint` 传自定义结构 |

`lHint`/`pHint` 是精准刷新的通道——收到提示的视图在 `OnUpdate` 里只重画受影响的区域，而不是整个重画：

```cpp
void CNoteView::OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint) {
    if (lHint == HINT_LINE_CHANGED && pHint) {
        auto* p = static_cast<LineHint*>(pHint);
        InvalidateLine(p->nLine);          // 只刷那一行
        return;
    }
    // 没有提示：全量同步（新建/打开文档都会走这里）
    m_updating = true;
    m_edit.SetWindowText(GetDoc()->m_text);
    m_updating = false;
}
```

两个时机要分清：

| | 调用时机 | 次数 |
|---|---|---|
| `OnInitialUpdate` | 视图被接到文档上之后、窗口显示之前 | 每次挂到新文档调一次 |
| `OnUpdate` | 文档 `UpdateAllViews`，以及框架在新建/打开文档后 | 每次"文档可能变了"都调 |

注意**新建/打开文档时框架也会调 `OnUpdate`**（此时 `pSender == nullptr`）——所以初始化逻辑放 `OnInitialUpdate`，数据同步放 `OnUpdate`，后者天然覆盖前者要处理的场景，别在两处重复写同步代码。

**双向同步要防回环**：`OnUpdate` 里 `SetWindowText` 会触发 `EN_CHANGE`，不挡住就无限递归。用一个 `m_updating` 布尔守卫（上面代码里的写法），编辑回调里先查它。

## 7. 脏标记与关闭确认

脏标记是 `CDocument` 里的一个位，驱动着所有"要不要保存"的交互：

```cpp
void CNoteView::OnEditChange() {
    if (m_updating) return;
    m_edit.GetWindowText(GetDoc()->m_text);
    GetDoc()->SetModifiedFlag();     // 标脏：标题加 *，关闭时询问
}

// 文档侧：新建/加载完成时必须显式清脏
BOOL CNoteDoc::OnNewDocument() {
    if (!CDocument::OnNewDocument())
        return FALSE;
    m_text.Empty();                  // 清数据
    SetModifiedFlag(FALSE);          // 清脏标记（新建 ≠ 脏）
    return TRUE;
}
```

联动行为全部由框架实现：

- `SetModifiedFlag()` 之后，**标题自动加 `*`**（`SetTitle` + `UpdateFrameCounts`）
- 关闭窗口 / `ID_APP_EXIT` / 新建覆盖文档前，框架调 `CDocument::SaveModified`：脏则弹"保存更改吗？"三选一（是/否/**取消**）
- `SaveModified` 返回 `FALSE` 的唯一情形是用户选了取消——此时**整个操作中止**（不关窗口、不退出、不新建）。所以"关闭前清理自己资源"的逻辑**不能放在文档析构里赌它一定跑**，要在确认保存之后的时机做
- `ID_FILE_SAVE` 成功后框架自动清脏标记

`IsModified()` 也给你的业务逻辑用：比如"没有未保存修改时退出不问"，或者自己实现自动保存时跳过干净文档。

## 8. 视图侧：OnDraw 与 OnUpdate

```cpp
class CNoteView : public CView {
    CNoteDoc* GetDoc() const { return static_cast<CNoteDoc*>(m_pDocument); }

    void OnDraw(CDC* pDC) override {
        // CView 的纯虚函数必须实现；绘图型视图在这里渲染数据
        // 编辑器型视图显示交给子控件，这里留空
    }
    ...
};
```

编辑器型应用有个捷径：继承 `CEditView` 而不是 `CView`，它自带编辑框、剪贴板和默认序列化，向导生成的记事本类程序就是这么做的。

## 9. SDI / MDI / 对话框式

| 模板 | 场景 | 差异 |
|---|---|---|
| `CSingleDocTemplate` | 记事本（一次一个文档） | 本章 |
| `CMultiDocTemplate` | Photoshop 式多文档 | 多个 `CChildFrame`，窗口管理框架全包（第 16 章） |
| 无模板（对话框为主） | 小工具 | 前几章的方式 |

## 常见坑

1. **三个类忘了 DYNCREATE 宏**
   模板反射创建时断言/崩溃。宏必须成对：`DECLARE_DYNCREATE` 在头文件、`IMPLEMENT_DYNCREATE` 在 **cpp**——只写 DECLARE 的话，链接时报 `unresolved external`。

2. **构造函数写成 `private`**
   框架要通过 `CRuntimeClass::CreateObject` 反射 `new` 你的类，构造必须 `public`。普通 C++ 工厂模式里构造常是 `private`，Doc/View 里相反。

3. **字符串表字段数不对**
   过滤器解析错位，打开/保存对话框拿不到正确的文件类型。数 `\n`，9 个字段。

4. **在视图里复制了一份文档数据**
   违反"数据只在文档"原则，很快就会同步丢失。视图只留 UI 状态（滚动位置、选中项）。

5. **`Serialize` 里做了 UI 操作或 `UpdateAllViews`**
   Serialize 可能由框架在任意时机调用（保存、另存、自动保存），保持纯数据。加载中途广播会让视图读到半成品数据；界面刷新由框架在加载完成后统一触发。

6. **`OnUpdate` 里忘了防回环**
   `SetWindowText` 触发 `EN_CHANGE`、`EN_CHANGE` 里又写文档、文档又广播——无限递归。入口处 `m_updating` 守卫，出口处复位。

7. **把初始化写在构造函数里**
   构造时文档还没有挂上视图、文件名也还是空的。文档初始化放 `OnNewDocument`，视图初始化放 `OnInitialUpdate`——框架会在正确的时机调它们。

## 实战建议

- 简单工具不必硬上 Doc/View；一旦出现"打开/保存 + 多视图 + 脏标记"，Doc/View 立刻回本
- `UpdateAllViews(nullptr, hint, pHint)` 的 hint 参数是视图间精准刷新的通道：传 `HINT_LINE_CHANGED` 之类枚举比无脑全刷高效
- 文档数据模型要能独立于 UI 测试：Serialize 逻辑写成"纯数据进出"，单测不用启动界面
- 自定义命令（如"全选"）也走文档广播：先改文档数据，再 `UpdateAllViews`，让同步只有一个入口

## 自测

1. **`CDocTemplate` 为什么需要 `RUNTIME_CLASS` 而不是直接 `new` 文档类？**
   —— 模板代码在 MFC 库里，编译时不认识你的类，只能靠 `CRuntimeClass` 里记录的创建函数指针反射创建。这要求三个类都有 `DECLARE_DYNCREATE`/`IMPLEMENT_DYNCREATE`（成对、IMPLEMENT 在 cpp）、构造函数 `public`。

2. **`UpdateAllViews(this)` 和 `UpdateAllViews(nullptr, hint, pHint)` 各适合什么场景？**
   —— 前者排除发送者，用于"我改完了，其他视图跟上"；后者广播给所有视图并携带提示，视图在 `OnUpdate` 里按 `lHint` 枚举做局部刷新，避免全量重画。

3. **`OnInitialUpdate` 和 `OnUpdate` 的调用时机差异是什么？**
   —— `OnInitialUpdate` 在视图挂到文档后、显示前调一次；`OnUpdate` 在每次"文档可能变了"时调，而且新建/打开文档时框架也会调它。所以初始化放前者、同步放后者，后者天然覆盖前者的场景。

4. **用户在"保存更改吗？"里选了取消，会发生什么？**
   —— `SaveModified` 返回 `FALSE`，整个操作中止：不关窗口、不退出、不新建文档。因此依赖"文档一定被销毁"的清理逻辑不能放在析构里赌执行。

5. **为什么不能在 `Serialize` 里调 `UpdateAllViews`？**
   —— 加载是边读边改文档的过程，中途广播会让视图读到半成品数据。界面刷新由框架在加载完成后统一触发（会调 `OnUpdate`）。

---
上一章：[14 DPI 感知与深色模式](14-dpi-darkmode.md) ｜ 下一章：[16 MDI 多文档与分割窗口](16-mdi-splitter.md)
