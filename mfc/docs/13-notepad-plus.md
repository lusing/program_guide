# 13 · 实战项目：记事本+

> 对应示例：`examples/12_notepad_plus`——把全书知识串成的一个完整应用。

## 1. 功能清单与知识点映射

| 功能 | 用到的章节 |
|---|---|
| 菜单 + 加速键 + 对话框模板（.rc） | 04 |
| 高 DPI 感知 | 01（Per-Monitor V2 声明） |
| 框架窗口 + 编辑区自适应布局 + 工具栏/状态栏让位 | 05、09 |
| 文件打开/保存（UTF-8/UTF-16/GBK 编码识别） | 08 |
| 最近文件列表（动态菜单） | 04、09（`ON_COMMAND_RANGE` + `CCmdUI::SetText`） |
| 编辑命令转发（撤销/剪切/复制/粘贴） | 03（命令路由） |
| 设置对话框（DDX + DDV，Tab 宽度/自动换行） | 06 |
| 统计面板（非模态 + CListCtrl） | 06、07 |
| 后台统计线程 + 结果回传 | 12 |
| 脏标记与退出确认 | 02、09 |

## 2. 工程结构

```text
12_notepad_plus/
├── resource.h        # 全部资源 ID
├── notepad.rc        # 菜单、加速键、3 个对话框、工具栏位图
├── toolbar.bmp       # 工具栏图标（16x15 x 3 格）
├── main.cpp          # App + 主框架 + 设置对话框（~450 行）
└── stats.h/.cpp      # 统计面板：非模态对话框 + worker 线程（自包含模块）
```

这个划分本身就是实践建议：**界面壳（main.cpp）和数据加工模块（stats.cpp）分开**，stats 模块只依赖"一份文本快照"，不直接碰编辑器——它可以单独测试、单独替换。

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

`CMainFrame::OnCreate` 按依赖顺序装配：工具栏 → 状态栏 → 编辑框。`OnSize` 里用 `RepositionBars(reposQuery)` 拿到控制条让位后的矩形，编辑框铺满剩余空间（第 09 章的标准写法）。

`LoadFrame(IDR_MAINFRAME, WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE)` 一次拿到菜单 + 加速键 + 标题串，比手工 `Create` + `LoadMenu` 干净——SDI 框架窗口的首选创建方式。

## 4. 编辑命令：框架转发模式

菜单里的"撤销/剪切/复制/粘贴"命令 ID 是自定义的（`IDM_EDIT_*`），处理函数薄薄一层转发：

```cpp
afx_msg void OnEditUndo()  { m_edit.Undo(); }
afx_msg void OnUpdateEditUndo(CCmdUI* pCmdUI) {
    pCmdUI->Enable(m_edit.CanUndo());     // 撤销栈空则菜单自动置灰
}
```

这就是第 03 章说的"命令处理函数保持薄"。加速键 Ctrl+Z 在 LoadFrame 加载的加速键表里，翻译成 `IDM_EDIT_UNDO` 后走同一条路由——**一套命令三处入口（菜单/快捷键/以后加工具栏按钮）**。

## 5. 文件读写与编码

`LoadFile` / `SaveFile` 是第 08 章编码方案的直接复用：二进制读入 → `EF BB BF` = UTF-8、`FF FE` = UTF-16LE、无 BOM 按 ANSI → 转成 CString 显示；保存统一 UTF-8 + BOM。

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

实战里这就是"数据变化 → 广播刷新"的手工版本。更系统的做法是第 10 章的 Doc/View `UpdateAllViews`。

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

`AddRecent` 保证"最近用过的在最上、去重、最多 4 条"。真实项目可换成 `CRecentFileList`（配合 `LoadStdProfileSettings`，自动持久化到注册表）——原理相同。

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

线程模型（第 12 章模式的完整落地）：

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

不声明的话系统按 96 DPI 渲染再拉伸，文字发糊。声明之后窗口得到真实物理像素——本项目的布局都是客户区尺寸比例计算，天然适配。彻底的 DPI 适配（字体随 DPI 缩放、位图多版本）超出本书范围，从"声明感知 + 字号用 CreatePointFont"起步已是正确方向。

## 10. 可以继续做的事

把这个项目当练习基地，按难度递增：

1. 查找/替换对话框（`CFindReplaceDialog` 或自建，加"区分大小写"选项）
2. 状态栏加行列号窗格（`EN_SELCHANGE` + `LineFromChar/LineIndex`）
3. 编辑命令接入撤销提示、保存后清撤销栈语义
4. 把编辑区换成 Doc/View（第 10 章），支持多标签或 MDI
5. 拖放打开文件（`DragAcceptFiles` + `WM_DROPFILES`）
6. 用虚拟列表重构统计面板的数据源

---
上一章：[12 多线程与后台任务](12-threads.md) ｜ 返回：[README](../README.md)
