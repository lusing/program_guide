# 25 · 实战项目：记事本+

> 对应示例：`examples/25_notepad_plus`——把全书知识串成的一个完整应用。

> **本章你将学会**：怎么把散在各章的技术组装成完整程序（模块划分、装配顺序、数据流）、实战项目的知识点总索引，以及继续扩展的方向。
> **前置知识**：全书。本篇是收束章，遇到不熟的点按下面的索引表回跳。

## 1. 功能清单与全书知识点索引

| 功能 | 用到的章节 |
|---|---|
| 菜单 + 加速键 + 对话框模板（.rc 资源） | 04 |
| 框架窗口 + 编辑区自适应布局 | 05 |
| 工具栏 + 状态栏（`RepositionBars` 让位布局） | 11 |
| 文件打开/保存（UTF-8/UTF-16/GBK 编码识别） | 10 |
| 最近文件列表（`ON_COMMAND_RANGE` 动态菜单；对应物是第 13 章 `CRecentFileList`） | 03、13 |
| 编辑命令转发（撤销/剪切/复制/粘贴 + CCmdUI 置灰） | 03 |
| 设置对话框（DDX + DDV，Tab 宽度/自动换行） | 06 |
| 统计面板（非模态 + `CListCtrl` 报表） | 06、07 |
| 后台统计线程 + `PostMessage` 结果回传 | 20 |
| 脏标记与退出确认（`m_dirty` 手工版；对应物是第 15 章 `SetModifiedFlag`） | 02、15 |
| 高 DPI 感知（Per-Monitor V2） | 14 |
| 单实例、配置持久化（对应第 13 章的注册表 profile） | 13 |
| 发布形态（`build.ps1 -Static` 两套构建，见第 23 章实测数据） | 23 |

这张表是全书收束的核心：**每个功能都是前面某一章的"最小可用版本"，忘了怎么写就回跳**。

## 2. 项目结构与模块划分

```text
25_notepad_plus/
├── resource.h        # 全部资源 ID
├── notepad.rc        # 菜单、加速键、3 个对话框、工具栏位图
├── toolbar.bmp       # 工具栏图标
├── main.cpp          # App + 主框架 + 设置对话框（界面壳）
└── stats.h/.cpp      # 统计面板：非模态对话框 + worker 线程（自包含模块）
```

这个划分本身就是第 24 章主张的落地：**界面壳（main.cpp）和数据加工模块（stats.cpp）分开**。stats.cpp 里没有一行 MFC 依赖——文本用 `std::wstring`、结果用 `std::vector`，只吃"一份文本快照"，可以脱离界面单独测试、单独替换。main.cpp 在边界处做 `CString ↔ std::wstring` 的翻译。

## 3. 主框架的装配顺序

```cpp
BOOL CMyApp::InitInstance() {
    EnableHighDpi();                       // ① 先声明 DPI 感知（窗口创建前！）
    m_pMainWnd = new CMainFrame();         // ② LoadFrame 加载菜单/加速键/标题
    m_pMainWnd->ShowWindow(m_nCmdShow);
    m_pMainWnd->UpdateWindow();
    return TRUE;
}
```

`CMainFrame::OnCreate` 按依赖顺序装配：工具栏 → 状态栏 → 编辑框。`OnSize` 里用 `RepositionBars(reposQuery)` 拿到控制条让位后的矩形，编辑框铺满剩余空间（第 11 章的标准写法）。

`LoadFrame(IDR_MAINFRAME, WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE)` 一次拿到菜单 + 加速键 + 标题串，比手工 `Create` + `LoadMenu` 干净——SDI 框架窗口的首选创建方式。

## 4. 编辑命令：框架转发模式

菜单里的"撤销/剪切/复制/粘贴"命令 ID 是自定义的（`IDM_EDIT_*`），处理函数薄薄一层转发：

```cpp
afx_msg void OnEditUndo()  { m_edit.Undo(); }
afx_msg void OnUpdateEditUndo(CCmdUI* pCmdUI) {
    pCmdUI->Enable(m_edit.CanUndo());     // 撤销栈空则菜单自动置灰
}
```

这就是第 03 章说的"命令处理函数保持薄"。加速键 Ctrl+Z 在 LoadFrame 加载的加速键表里，翻译成 `IDM_EDIT_UNDO` 后走同一条路由——**一套命令三处入口（菜单/快捷键/工具栏按钮）**。

## 5. 文件读写与编码

`LoadFile` / `SaveFile` 是第 10 章编码方案的直接复用：二进制读入 → `EF BB BF` = UTF-8、`FF FE` = UTF-16LE、无 BOM 按 ANSI → 转成 CString 显示；保存统一 UTF-8 + BOM。

打开文件后的完整动作链值得注意——**改数据的地方要触发所有依赖它的 UI**：

```cpp
m_edit.SetWindowText(content);
m_filePath = path;
m_dirty = false;
AddRecent(path);        // 最近文件列表
UpdateTitle();          // 标题栏
SetPaneText(...);       // 状态栏
PushStats();            // 统计面板（若开着）
```

实战里这就是"数据变化 → 广播刷新"的手工版本。依赖的 UI 一多，手工广播就会漏——更系统的做法是第 15 章的 Doc/View `UpdateAllViews`（数据只进文档，刷新交给框架广播）。

## 6. 最近文件列表：动态菜单

菜单里预留 4 个槽位（`IDM_MRU_1..4`，**连续 ID 便于区间映射**），显示与启用状态在 UI 更新回调里动态决定：

```cpp
ON_COMMAND_RANGE(IDM_MRU_1, IDM_MRU_4, OnOpenRecent)
ON_UPDATE_COMMAND_UI_RANGE(IDM_MRU_1, IDM_MRU_4, OnUpdateRecent)

afx_msg void OnUpdateRecent(CCmdUI* pCmdUI) {
    int index = pCmdUI->m_nID - IDM_MRU_1;
    if (index < m_recentCount) {
        pCmdUI->SetText(取文件名(m_recent[index]));   // 菜单项文字动态改
        pCmdUI->Enable(TRUE);
    } else {
        pCmdUI->Enable(FALSE);                        // 空槽位置灰
    }
}
```

`AddRecent` 保证"最近用过的在最上、去重、最多 4 条"。真实项目可换成第 13 章的 `CRecentFileList`（配合 `LoadStdProfileSettings`，自动持久化到注册表）——原理相同，本例手写是为了展示区间映射机制。

## 7. 设置对话框：DDX 进出站

```cpp
class CSettingsDialog : public CDialog {
public:
    int  m_tabSize = 4;
    BOOL m_wrap = TRUE;
    void DoDataExchange(CDataExchange* pDX) override {
        CDialog::DoDataExchange(pDX);
        DDX_Text(pDX, IDC_TAB_SIZE, m_tabSize);
        DDV_MinMaxInt(pDX, m_tabSize, 1, 32);     // 越界自动弹提示
        DDX_Check(pDX, IDC_WRAP, m_wrap);
    }
};
```

调用方（主框架）只面对成员变量：

```cpp
CSettingsDialog dlg(this);
dlg.m_tabSize = m_tabSize;      // 传入当前值
dlg.m_wrap = m_wrap;
if (dlg.DoModal() != IDOK) return;
m_tabSize = dlg.m_tabSize;      // 取回新值
m_wrap = dlg.m_wrap;
ApplySettings();
```

`ApplySettings` 里有一个通用经验：**窗口样式创建后不可改**——自动换行要增删 `WS_HSCROLL|ES_AUTOHSCROLL`，只能"保存内容 → DestroyWindow → 按新样式重建 → 恢复内容"。改不了样式就重建控件，别跟系统较劲。

## 8. 统计面板：非模态 + 后台线程（stats.cpp）

模块对外只有两个接口：

```cpp
CStatsDialog(CWnd* parent);                                // Create + ShowWindow
void UpdateText(std::shared_ptr<std::wstring> text);       // 推一份文本快照
```

线程模型（第 20 章模式的完整落地）：

```text
UI 线程                                worker 线程
----------                             -----------
UpdateText(快照) ──AfxBeginThread──> StatsThreadProc
    │                                   纯计算（字符/单词/行/段落）
    │  <──PostMessage(WM_APP_STATS_DONE, 结果堆指针)──
OnStatsDone：
    unique_ptr 接管结果 → 更新 CListCtrl
    m_dirty？→ 再补跑一轮（统计期间文本又变了）
```

三个设计细节：

1. **shared_ptr 快照**：UI 线程把当前文本拷进堆上的 `std::wstring`，worker 只读快照——没有锁、没有竞争
2. **合并旧请求**：计算期间来了新文本只更新 `m_pending` 标志，完成后补跑一轮，而不是盲目排队 N 次
3. **自毁生命周期**：`PostNcDestroy → 通知主窗口清指针 → delete this`（第 06 章的非模态套路），主窗口的 `m_stats` 永不悬挂

统计结果用 `CListCtrl` 报表展示（指标/数值两列），就是第 07 章的最小应用。

## 9. 高 DPI 的基本姿势

```cpp
// InitInstance 最前面：声明 Per-Monitor V2 感知
SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
```

不声明的话系统按 96 DPI 渲染再拉伸，文字发糊。声明之后窗口得到真实物理像素——本项目的布局都是客户区尺寸比例计算，天然适配。彻底的 DPI 适配（布局过 `Scale()`、`WM_DPICHANGED` 重排、深色模式）是第 14 章的完整篇目。

## 10. 常见坑

1. **工具栏位图与按钮 ID 不匹配**
   `toolbar.bmp` 的图格数、`notepad.rc` 里 TBBUTTON 数组、`Create` 传入的按钮数三者必须一致——错位的表现是"图标和功能对不上"或尾部空白（第 11 章）。

2. **统计线程直接更新状态栏/控件**
   worker 里碰 `CWnd*` 是第 20 章的头号铁律禁区。本项目把结果 `PostMessage` 回 UI 线程后才碰 `CListCtrl`——实战项目里这是最容易"顺手写错"的地方。

3. **字符串表的字段数不对**
   `notepad.rc` 里 IDR_MAINFRAME 的标题串、过滤器串按用途分开写；若改造成 Doc/View（第 15 章），9 字段串差一个 `\n` 过滤器就整体错位。

4. **改了样式没重建控件**
   自动换行开关切换后没效果——`ES_AUTOHSCROLL` 创建后改不动，必须重建编辑框（第 7 节）。

5. **退出时统计线程没收尾**
   主窗口销毁时统计线程可能还在跑。项目里靠"worker 只读快照 + 发消息前判窗口句柄"保证安全；更严谨的收尾见第 20 章第 5 节。

## 11. 实战建议

- **先定模块边界，再写界面**：像 stats.cpp 这样"逻辑层零框架依赖"的划分，越早定越省事——等 CString 渗透进每个文件再拆就难了（第 24 章）
- **装配顺序按依赖来**：工具栏/状态栏在编辑框之前创建（`RepositionBars` 要靠它们算剩余空间），DPI 声明在任何窗口之前
- **每加一个功能就回填知识点索引表**：这张表既是读者回跳的地图，也是你自己"这个项目还缺什么"的清单
- **把数据变化的广播动作收敛成一个函数**：打开/另存/设置变更都调它，别散落——将来换 Doc/View 时要改的就是这一个函数（第 15 章）
- **构建即验证**：每改一处就 `build.ps1 -File 25_notepad_plus`，`smoke.ps1` 的 23 个存活示例是全书的安全网

## 12. 还能怎么继续做

把这个项目当练习基地，每条都指向对应章节：

1. **多标签页 / MDI**：编辑区换成 Doc/View，支持多文档（第 15、16 章）
2. **语法高亮**：`OnPaint` 自绘或换 RichEdit，关键词上色从 GDI 起步、追求效果上 GDI+/D2D（第 18、22 章）
3. **正则查找替换**：逻辑层用 `std::regex`/`std::wstring_view` 实现，界面只做输入输出（第 24 章的分层主张）
4. **编码自动探测加强**：BOM 之外加 UTF-8 校验、GBK 高频字启发式（第 10 章）
5. **打印**：视图实现五个打印重写点，`DrawPage` 与屏幕共用（第 19 章）
6. **撤销栈增强、虚拟列表统计面板**：控件进阶（第 07 章）与自绘（第 09 章）

## 自测

1. **项目为什么把统计逻辑拆到独立的 stats.cpp？它依赖什么、不依赖什么？**
   —— 界面壳与数据加工分离：stats.cpp 是纯 C++（`std::wstring`/`std::vector`，零 MFC 依赖），只吃一份文本快照，能脱离界面单测；main.cpp 在边界处做 CString↔std::wstring 翻译（第 24 章的分层主张）。

2. **打开文件后主框架做了哪一串动作？对应 Doc/View 的什么机制？**
   —— 写编辑框、记路径、清脏标记、刷最近文件/标题/状态栏/统计面板——手工广播。Doc/View 把数据收进文档、用 `UpdateAllViews` 统一广播，依赖多了之后不容易漏（第 15 章）。

3. **最近文件菜单的"动态文字 + 空槽置灰"是怎么实现的？**
   —— 4 个连续 ID 槽位 + `ON_UPDATE_COMMAND_UI_RANGE`：有数据的槽 `SetText` 显示文件名并启用，空槽置灰；`ON_COMMAND_RANGE` 把 4 个槽路由到同一个处理函数，按 `m_nID` 区分。

4. **统计面板的线程模型里，为什么用 `shared_ptr` 快照而不是锁？**
   —— UI 线程拷一份文本快照推给 worker，worker 只读快照——数据不共享就没有竞争，天然免锁。计算期间文本又变了只置 `m_pending` 标志，完成后补跑一轮（第 20 章）。

5. **想给这个项目加"打印"和"多标签 MDI"，分别该读哪两章、动哪里？**
   —— 打印：第 19 章，给视图实现 `OnPreparePrinting/OnBeginPrinting/OnPrint/OnEndPrinting`，绘制抽成 `DrawPage` 与屏幕共用；多标签/MDI：第 15、16 章，编辑区换成 Doc/View（`CSingleDocTemplate` → `CMultiDocTemplate`）。

---
上一章：[24 MFC 与现代 C++](24-modern-cpp.md) ｜ 返回：[README](../README.md)
