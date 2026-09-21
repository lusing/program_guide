# 19 · 打印与打印预览

> 对应示例：`examples/19_printing`

> **本章你将学会**：打印流程的五个重写点、怎么让屏幕和打印共用一份绘制逻辑、分页怎么算、以及 `CPreviewView` 预览的工作方式。
> **前置知识**：第 15 章的 Doc/View、第 18 章的 DC 与字体。

## 1. 打印为什么看起来复杂

打印的本质只有一句话：**在打印机 DC 上重放一遍绘制逻辑**。GDI 是设备无关的——同一套 `TextOut`/`Rectangle`，画到窗口 DC 就是屏幕，画到打印机 DC 就是纸。难的不是"画"，是两件屏幕上没有的事：

- **分页**：屏幕没有"页"的概念，纸有——数据放不下就得切
- **度量差异**：打印机 DPI 通常 600+，屏幕 96——字号、行高按像素写死就全错

MFC 把整个流程模板化，用 `CPrintInfo` 串起来：

```text
用户点"打印"（ID_FILE_PRINT）
   │
   ▼
OnPreparePrinting ──── DoPreparePrinting：弹打印对话框，选定打印机
   │                     （这一步之后才有打印机 DC）
   ▼
OnBeginPrinting ────── 一次性准备：建打印字体、算总页数 SetMaxPage
   │
   ▼
OnPrint × N 页 ───────  每页调一次：m_nCurPage = 1..N，
   │                     m_rectDraw = 该页可打印区域
   ▼
OnEndPrinting ────────  释放 OnBeginPrinting 建的东西
```

`ID_FILE_PRINT`/`ID_FILE_PRINT_DIRECT`/`ID_FILE_PRINT_PREVIEW` 三个命令 **CView 的消息映射自带标准处理**——菜单摆上 ID 就能用，一行映射都不用写。

## 2. 五个重写点

```cpp
class CReportView : public CView {
    // 屏幕：正常绘制（预览模式不调它）
    void OnDraw(CDC* pDC) override;

    // ① 必须实现：弹打印对话框。直接 return DoPreparePrinting(pInfo)
    BOOL OnPreparePrinting(CPrintInfo* pInfo) override {
        return DoPreparePrinting(pInfo);
    }

    // ② 打印开始（一次）：建打印专用字体、算总页数
    void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo) override;

    // ③ 每页一次：pInfo->m_rectDraw 是该页可打印区域
    //              pInfo->m_nCurPage 是当前页号（1 起）
    void OnPrint(CDC* pDC, CPrintInfo* pInfo) override;

    // ④ 打印结束（一次）：释放 ② 建的资源
    void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo) override;
};
```

为什么字体要在 `OnBeginPrinting` 建、用打印机 DC 建？`CFont::CreatePointFont(90, _T("宋体"), pDC)` 传了 DC 就按**那个 DC 的 DPI** 换算字号——9 磅在 600 DPI 打印机上是几百像素，在 96 DPI 屏幕上是 12 像素。用屏幕字体打印，字号缩成一小团；用打印机 DC 建的字体，纸上的物理尺寸才对。

总页数也在 `OnBeginPrinting` 算——**打印机 DC 此时才存在**（`OnPreparePrinting` 阶段用户还没确认打印机），`pDC->GetDeviceCaps(VERTRES)` 给出可打印高度，加上行高就能算每页行数：

```cpp
void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo) override {
    m_pPrintFont = new CFont;
    m_pPrintFont->CreatePointFont(90, _T("宋体"), pDC);

    const int nRows   = GetDoc()->m_rows.GetSize();
    const int perPage = RowsPerPage(*pDC, pDC->GetDeviceCaps(VERTRES));
    pInfo->SetMaxPage((nRows + perPage - 1) / perPage);   // 不设 = 只打一页
}
```

`SetMaxPage` 不设的话 `CPrintInfo` 默认只打一页——这是"数据丢了"类 bug 的头号来源。

## 3. 屏幕与打印共用绘制逻辑

本章最重要的一个重构：把"画一页报表"抽成**纯函数**：

```cpp
void DrawPage(CDC& dc, const CRect& rc, int page) {
    const int rowH = dc.GetDeviceCaps(LOGPIXELSY) / 4;   // 行高 = 1/4 英寸
    //  标题、表格行、页脚 —— 全部用 dc 画，全部按 dc 的 DPI 度量
}

void OnDraw(CDC* pDC) override {              // 屏幕：画第 1 页
    CRect rc; GetClientRect(&rc);
    DrawPage(*pDC, rc, 1);
}

void OnPrint(CDC* pDC, CPrintInfo* pInfo) override {   // 打印/预览：画第 N 页
    DrawPage(*pDC, pInfo->m_rectDraw, pInfo->m_nCurPage);
}
```

三个要点：

- **所有度量问 DC 自己**：`GetDeviceCaps(LOGPIXELSY)` 在屏幕 DC 上返回 96，在打印机 DC 上返回 600+——同一行代码，两边各自正确。行高用"1/4 英寸"这种物理单位表达，就是第 14 章 DPI 那套思想在打印上的翻版。
- **`dc.IsPrinting()` 区分场合**：屏幕用彩色标题、打印用黑白，就在这里分支。预览时它也返回 TRUE（预览模拟的是打印机）。
- **`DrawPage` 必须是纯的**：只读文档、只画、不改成员。原因见下一节——预览会反复调它。

## 4. 分页计算

可打印区域不是整张纸：`pInfo->m_rectDraw` 是框架按打印机边距算好的**该页可打印矩形**。每页行数、起始行号都从它推：

```cpp
// 每页行数：页高减去标题行和页脚行，除以行高
static int RowsPerPage(CDC& dc, int pageH) {
    const int rowH = dc.GetDeviceCaps(LOGPIXELSY) / 4;
    return rowH > 0 ? (pageH - 2 * rowH) / rowH : 0;
}

// DrawPage 内部：第 page 页画哪些行
const int rowsPerPage = RowsPerPage(dc, rc.Height());
const int first = (page - 1) * rowsPerPage;
for (int i = 0; i < rowsPerPage && first + i < GetDoc()->m_rows.GetSize(); ++i)
    dc.TextOut(..., GetDoc()->m_rows[first + i]);
```

`RowsPerPage` 在 `OnBeginPrinting`（算总页数）和 `DrawPage`（取数）两处共用——**同一个公式**，页数才对得上。示例里算页数用 `GetDeviceCaps(VERTRES)`、画页用 `m_rectDraw`，两者在标准打印机上一致；若驱动报的边距特殊，以 `m_rectDraw` 为准重算即可。

别在 `OnPrint` 里现算总页数——那是每页都跑的路径，页数属于"打印开始前就知道"的信息，放 `OnBeginPrinting` 一次算好。

## 5. 打印预览

预览是免费午餐——**一行代码都不用写**。菜单里摆上 `ID_FILE_PRINT_PREVIEW`，`CView` 的标准处理接手后进入预览模式：MFC 的 `CPreviewView` 把"打印机 DC"重定向到一个模拟 DC（缩放显示在屏幕上），于是 `OnPrint` 被照常调用，你看到的预览就是"如果没有打印机，它会把纸画成这样"。

预览模式下 `OnPrint` 会被**反复调用**：翻页一次、缩放一次、窗口移动一次都全量重画。这就是 3 节"DrawPage 必须是纯函数"的原因——如果 `OnPrint` 里顺手改了数据（计数、推进迭代器），预览里每动一下鼠标数据就被改一次，打印出来和预览对不上。

预览工具条上的命令是 `AFX_ID_PREVIEW_PRINT`/`AFX_ID_PREVIEW_NEXT` 等标准 ID，由 `CPreviewView` 内部处理；你的视图只在 `OnPreparePrinting`→`OnBeginPrinting`→`OnPrint` 这条链上被普通地调用。

## 常见坑

1. **在 `OnPrint` 里做有副作用的操作**
   预览模式下 `OnPrint` 每次缩放/翻页都会重跑，计数器被加多次、临时对象被反复创建。`OnPrint` 只画不改；状态推进放命令处理函数里。

2. **用屏幕字体打印**
   字号按 96 DPI 建的字体放到 600 DPI 的打印机上只有原来 1/6 大小。打印字体必须在 `OnBeginPrinting` 里用打印机 DC `CreatePointFont`。

3. **`OnPreparePrinting` 忘记 `return DoPreparePrinting(pInfo)`**
   写成调用完不返回（或返回 TRUE），打印对话框不弹、打印机 DC 也没建，后面全空转。就一句：`return DoPreparePrinting(pInfo);`。

4. **不调 `SetMaxPage`**
   `CPrintInfo` 默认 1 页，多页数据全被吞——用户以为打印成功了，纸上只有第一页。页数在 `OnBeginPrinting` 算完立刻 `SetMaxPage`。

5. **总页数和分页公式不一致**
   `OnBeginPrinting` 用一套行高、`DrawPage` 用另一套，最后一页内容跨页错行。分页公式抽成静态函数两处共用（示例的 `RowsPerPage`）。

6. **打印资源在 `OnPrint` 里建**
   每页 new 一个 `CFont`，几十页就是几十次创建/销毁。一次性资源在 `OnBeginPrinting` 建、`OnEndPrinting` 删，`OnPrint` 只用。

## 实战建议

- **先把 `DrawPage` 写纯**（只读数据、只画、无副作用），屏幕绘制、打印、预览三个功能就同时成立——这是打印功能的唯一架构决策，其余都是填空
- 行高、边距用**物理单位**（英寸/毫米）× `GetDeviceCaps` 换算，和第 14 章的 `Scale()` 思路一脉相承：96 DPI 的设计值不要出现在打印代码里
- 页数在 `OnBeginPrinting` 一次算好；`OnPrint` 里只做"第 m_nCurPage 页画什么"的映射
- 打印机纸张方向/纸盒由 `CPrintDialog`（`pInfo->m_pPD`）管，用户在打印对话框里选，不要在代码里硬抢
- 无打印机环境下自测：打印预览就是离线的"打印结果模拟器"，预览对 = 打印对（字体是按打印机 DC 建的，预览同样走 `OnBeginPrinting`）

## 自测

1. **打印的五个重写点各负责什么？哪个每页调一次？**
   —— `OnPreparePrinting`（弹对话框，`return DoPreparePrinting`）、`OnBeginPrinting`（建打印字体 + `SetMaxPage`，此时才有打印机 DC）、`OnPrint`（**每页一次**，画 `m_nCurPage` 页）、`OnEndPrinting`（释放）、`OnDraw`（屏幕）。资源在 ② 建 ④ 删，③ 只画。

2. **为什么打印字体要在 `OnBeginPrinting` 里用打印机 DC 创建？**
   —— `CreatePointFont` 传了 DC 就按该 DC 的 DPI 换算字号。打印机 600 DPI、屏幕 96 DPI，同一"9 磅"在两边像素数差 6 倍；用屏幕字体打印，纸上字缩小到 1/6。

3. **屏幕和打印怎么共用绘制逻辑？靠什么区分场合？**
   —— 把"画一页"抽成纯函数 `DrawPage(CDC&, CRect, int page)`：`OnDraw` 传客户区和第 1 页，`OnPrint` 传 `m_rectDraw` 和 `m_nCurPage`。所有度量问 `dc.GetDeviceCaps`，场合用 `dc.IsPrinting()` 区分。

4. **预览模式下 `OnPrint` 为什么必须无副作用？**
   —— 预览的翻页/缩放/移动都会全量重跑 `OnPrint`，有副作用的数据会被改多次，预览和实际打印结果对不上。打印页数等信息在 `OnBeginPrinting` 一次算好。

5. **总页数在哪算、怎么设？漏了会怎样？**
   —— `OnBeginPrinting` 里用打印机 DC 的 `VERTRES` 和行高算出，`pInfo->SetMaxPage(n)` 设进 `CPrintInfo`。漏设默认 1 页，多页数据只打第一页。

---
上一章：[18 GDI 绘图与双缓冲](18-gdi.md) ｜ 下一章：[20 多线程与后台任务](20-threads.md)
