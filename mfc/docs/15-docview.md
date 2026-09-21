# 15 · Doc/View 架构

> 对应示例：`examples/15_docview`

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

三个类都要能被框架动态创建（宏成对出现）：

```cpp
class CNoteDoc : public CDocument {
    DECLARE_DYNCREATE(CNoteDoc)
public:
    CNoteDoc() = default;             // 构造必须 public（框架反射创建）
    ...
};
IMPLEMENT_DYNCREATE(CNoteDoc, CDocument)
```

`IDR_MAINFRAME` 的字符串表有严格的 9 字段格式（`\n` 分隔），框架靠它取窗口标题、文件过滤器和扩展名：

```rc
STRINGTABLE
BEGIN
    IDR_MAINFRAME "MFC 笔记\n笔记\n笔记\n文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||\n.note\nNote.Document\n笔记文档\n笔记"
END
```

字段依次是：窗口标题、文档名、新建默认名、过滤器名、过滤器、默认扩展名、注册表类型 ID、注册表类型名、新文件过滤器名。

## 3. 免费得到的命令

文档模板装配好之后，这些菜单命令**不用写一行处理代码**：

| 命令 ID | 框架行为 |
|---|---|
| `ID_FILE_NEW` | 清空当前文档（`OnNewDocument`），标题变"未命名" |
| `ID_FILE_OPEN` | 按 9 字段串里的过滤器弹打开框，读文件走 `Serialize` |
| `ID_FILE_SAVE` | 有名字直接写；没名字转另存为 |
| `ID_FILE_SAVE_AS` | 弹另存框 |
| `ID_APP_EXIT` | 若脏则提示保存，然后退出 |

你只需要在 `Serialize` 里写真正的读写逻辑——文件对话框、脏检查提示（标题带 `*`、关闭询问）全部由框架驱动。

## 4. Serialize：文档与文件的唯一通道

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

脏标记驱动一切：修改内容后调 `SetModifiedFlag()`，框架自动给标题加 `*`、关闭/退出时询问保存、保存后自动清标志。

## 5. 视图侧：OnDraw 与 OnUpdate

```cpp
class CNoteView : public CView {
    CNoteDoc* GetDoc() const { return static_cast<CNoteDoc*>(m_pDocument); }

    void OnDraw(CDC* pDC) override {
        // CView 的纯虚函数必须实现；绘图型视图在这里渲染数据
        // 编辑器型视图显示交给子控件，这里留空
    }

    void OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint) override {
        // 文档广播（新建/打开/UpdateAllViews）时到达：同步到界面
        m_updating = true;                       // 防回环！
        m_edit.SetWindowText(GetDoc()->m_text);
        m_updating = false;
    }

    afx_msg void OnEditChange() {
        if (m_updating) return;
        m_edit.GetWindowText(GetDoc()->m_text);
        GetDoc()->SetModifiedFlag();
    }
};
```

**双向同步要防回环**：`OnUpdate` 里 `SetWindowText` 会触发 `EN_CHANGE`，不挡住就无限递归。用一个 `m_updating` 布尔守卫。

编辑器型应用有个捷径：继承 `CEditView` 而不是 `CView`，它自带编辑框、剪贴板和默认序列化，向导生成的记事本类程序就是这么做的。

## 6. SDI / MDI / 对话框式

| 模板 | 场景 | 差异 |
|---|---|---|
| `CSingleDocTemplate` | 记事本（一次一个文档） | 本章 |
| `CMultiDocTemplate` | Photoshop 式多文档 | 多个 `CChildFrame`，窗口管理框架全包 |
| 无模板（对话框为主） | 小工具 | 前几章的方式 |

## 7. 常见坑

**三个类忘了 DYNCREATE 宏**：模板反射创建时断言/崩溃。宏必须成对（DECLARE 在头、IMPLEMENT 在 cpp），构造函数必须 public。

**字符串表字段数不对**：过滤器解析错位，打开/保存对话框拿不到正确的文件类型。数 `\n`，9 个字段。

**在视图里复制了一份文档数据**：违反"数据只在文档"原则，很快就会同步丢失。视图只留 UI 状态（滚动位置、选中项）。

**Serialize 里做了 UI 操作**：Serialize 可能由框架在任意时机调用，保持纯数据；界面刷新走 `UpdateAllViews`。

## 8. 实战建议

- 简单工具不必硬上 Doc/View；一旦出现"打开/保存 + 多视图 + 脏标记"，Doc/View 立刻回本
- `UpdateAllViews(nullptr, hint, pHint)` 的 hint 参数是视图间精准刷新的通道：传 `HINT_LINE_CHANGED` 之类枚举比无脑全刷高效
- 文档数据模型要能独立于 UI 测试：Serialize 逻辑写成"纯数据进出"，单测不用启动界面

---
上一章：[11 工具栏与状态栏](11-toolbars.md) ｜ 下一章：[18 GDI 绘图](18-gdi.md)
