# 07 · 文档/视图与线程

> 对应示例：[examples/07_wx_docview_thread.cpp](../examples/07_wx_docview_thread.cpp)

wx 部分收官章，两个主题拼成一个"小编辑器骨架"。上半是**文档/视图框架**：数据（文档）与呈现（视图）分离，由管理器和模板胶合，序列化钩子管存取。下半是**后台线程**：耗时活交给 worker 线程，进度经 `wxQueueEvent` 投回主线程更新进度条——UI 线程之外禁止碰控件，这条铁律贯穿始终。08 章起进入 Dear ImGui，范式从保留模式切换到即时模式。

## 7.1 文档/视图：四个角色怎么分工

- **wxDocument**：数据 + 序列化（SaveObject/LoadObject）+ 脏标记（Modify/IsModified）。
- **wxView**：呈现，核心是 `OnDraw(wxDC*)` 回调；一个文档可以挂多个视图（改一处、处处刷新）。
- **wxDocManager**：调度中枢——新建/打开/关闭文档的全流程、"未保存要不要存"的询问链。
- **wxDocTemplate**：登记"文件类型 → 文档类 + 视图类"的配对，框架据此反射创建对象。

本例是最小配置：一个文档类、一个视图类、一个模板。

## 7.2 装配：管理器、模板与反射

```cpp
// ═══ 7.1 DocManager + DocTemplate + CLASSINFO ═══
m_docMgr = new wxDocManager;
auto* tpl = new wxDocTemplate(m_docMgr, "Text", "*.t7txt", "", "t7txt",
                              "Text Doc", "Text Doc/View",
                              CLASSINFO(MyDocument), CLASSINFO(MyView));
```

`wxDocTemplate` 的参数串依次是：管理器、类型可见名、文件通配符、目录、扩展名、几个描述，最后两个是重点——`CLASSINFO(文档类)` 与 `CLASSINFO(视图类)`。框架"按类信息"new 出文档与视图对象，靠的是类里的动态类声明/实现这对宏：

```cpp
// ═══ 7.2 反射三件套：声明 + 实现 + 使用 ═══
private:
    wxDECLARE_DYNAMIC_CLASS(MyDocument);         // CLASSINFO 反射创建所需
...
wxIMPLEMENT_DYNAMIC_CLASS(MyDocument, wxDocument);
```

少这组宏，`CLASSINFO` 拿不到运行期类信息，`CreateDocument` 返回 nullptr——编译期不报错，运行期静默失败，是 docview 的头号新手坑（详见坑位清单）。

## 7.3 文档：流式序列化钩子

```cpp
// ═══ 7.3 SaveObject/LoadObject：std 流签名（本构建）═══
class MyDocument : public wxDocument
{
public:
    wxString m_text = "hello docview";

    std::ostream& SaveObject(std::ostream& stream) override
    {
        wxDocument::SaveObject(stream);          // 基类存文档头
        stream << m_text.utf8_str();             // 自定义内容随后
        return stream;
    }
    std::istream& LoadObject(std::istream& stream) override
    {
        wxDocument::LoadObject(stream);
        std::string s;
        stream >> s;                             // 与 Save 对称：读一个词
        m_text = wxString::FromUTF8(s.c_str());
        return stream;
    }
```

钩子签名有**两套**——`wxOutputStream&`/`wxInputStream&` 版与 `std::ostream&`/`std::istream&` 版，取决于库构建时 `wxUSE_STD_IOSTREAM` 的取值；本构建（默认）走 std 版。重写时签名对错全靠 `override` 关键字把关：不加 override 而签名又不匹配，编译器不报错，你只是"新写了个函数"、基类钩子没人调——存盘出来是空文档。钩子体先调基类（框架写文档头），自定义内容随后，Save 与 Load 严格对称。

## 7.4 视图：挂靠主窗口、被 paint 委托

```cpp
// ═══ 7.4 OnCreate：视图不建窗口，挂靠主 frame 的画布 ═══
bool MyView::OnCreate(wxDocument* doc, long WXUNUSED(flags))
{
    m_frame = static_cast<MyFrame*>(wxTheApp->GetTopWindow());
    m_frame->m_view = this;                      // 挂靠：画布 paint 会来找我
    SetFrame(m_frame);
    Activate(true);
    m_frame->m_canvas->Refresh();
    return true;
}

// ═══ 7.5 OnDraw：视图的呈现本体 ═══
void MyView::OnDraw(wxDC* dc)
{
    ++m_drawCalls;
    auto* doc = static_cast<MyDocument*>(GetDocument());
    dc->SetFont(wxFontInfo(14).Bold());
    dc->DrawText("doc: " + doc->m_text, 16, 16);
    dc->SetFont(wxFontInfo(10));
    dc->DrawText(wxString::FromUTF8("视图负责呈现文档（文档/视图分离）"), 16, 44);
}
```

框架创建视图后回调 `OnCreate`。本例视图不创建自己的窗口，而是"挂靠"：`m_frame->m_view = this` 存下反向指针，主窗口画布的 paint 处理器直接委托给视图：

```cpp
// ═══ 7.6 frame 侧：paint 委托给视图 ═══
void MyFrame::OnViewPaint(wxPaintEvent&)
{
    wxPaintDC dc(m_canvas);                      // 【坑】必须无条件创建
    dc.Clear();
    if (m_view)
        m_view->OnDraw(&dc);                     // 委托给视图：文档的呈现
}
```

06 章的 paint DC 铁律在这里复现。`OnDraw` 里 `GetDocument()` 拿到所属文档（基类维护的关联），视图只管呈现、不持数据副本。`OnClose` 里先走 `GetDocument()->Close()`（文档关闭链，脏文档会触发保存询问），再摘掉挂靠指针、`Activate(false)` 通知管理器失活。脏标记由框架跟踪：`doc->Modify(true)` 置脏，`IsModified()` 可查。

## 7.5 worker 线程：Entry 与协作式取消

```cpp
// ═══ 7.7 DETACHED worker：进度经事件投递 ═══
class WorkerThread : public wxThread
{
public:
    WorkerThread(wxEvtHandler* sink, int id, int steps)
        : wxThread(wxTHREAD_DETACHED), m_sink(sink), m_id(id), m_steps(steps) {}

protected:
    ExitCode Entry() override
    {
        for (int i = 1; i <= m_steps; ++i)
        {
            wxMilliSleep(6);                     // 模拟耗时
            auto* e = new wxThreadEvent(wxEVT_THREAD, m_id);
            e->SetInt(i);                        // 载荷：进度
            wxQueueEvent(m_sink, e);             // 线程→主线程唯一通路
            if (TestDestroy()) return nullptr;
        }
        auto* done = new wxThreadEvent(wxEVT_THREAD, m_id + 1000);
        wxQueueEvent(m_sink, done);
        return nullptr;
    }
```

`wxThread` 派生只需重写 `Entry()`（线程体）。构造参数 `wxTHREAD_DETACHED` 选的是"分离"形态：`Run()` 之后线程自管生死、Entry 返回即自毁（另一形态 JOINABLE 需要调用方 Wait/delete）。事件设计用 ID 分段编码：进度事件 id = 100 + 工人号，完成事件 id = 1100 + 工人号，主线程按段分派（当然也可以用 `SetInt` 之外的载荷字段）。`TestDestroy()` 是协作式取消检查点——线程在安全位置自查"外部是否请求了停止"，请求退出就自己返回。

## 7.6 wxQueueEvent：线程到 UI 的唯一通路

```cpp
// ═══ 7.8 主线程接收：按事件 id 分派 ═══
void MyFrame::OnThread(wxThreadEvent& e)
{
    int which = e.GetId() - 100;
    if (which >= 0 && which < 2)
    {
        int v = e.GetInt();
        m_gauge[which]->SetValue(v);             // 主线程里才能碰控件
        m_label[which]->SetLabel(wxString::Format("worker %d: %d/%d", which, v, m_steps));
    }
    else if (e.GetId() >= 1100)
    {
        int w = e.GetId() - 1100;
        m_label[w]->SetLabel(wxString::Format("worker %d: done", w));
        Log("worker %d done（wxEVT_THREAD 完成信号）\n", w);
        m_worker[w] = nullptr;                   // DETACHED 线程自毁
        if (++m_doneCount == 2 && g_selftest)
        {
            Log("gauges: %d/%d, %d/%d\n",
                m_gauge[0]->GetValue(), m_steps, m_gauge[1]->GetValue(), m_steps);
            Close(true);
        }
    }
}
```

铁律（源码头注释原话）：**UI 线程之外禁止碰控件**——worker 里直接 `SetValue` 是向别的线程的窗口句柄发消息，未定义行为。正道只有一条：`new wxThreadEvent`（队列接管所有权，所以必须堆分配）、`wxQueueEvent(sink, e)` 投给主线程的事件循环，主线程在 `OnThread` 里碰控件。完成分支把 `m_worker[w]` 置 nullptr 而不 delete——DETACHED 线程已自毁，这个指针只是"还在跑吗"的状态位，关窗守卫靠它：

```cpp
// ═══ 7.9 关窗守卫：线程在跑就 Veto ═══
void MyFrame::OnCloseWindow(wxCloseEvent& e)
{
    // 线程在跑就先拒绝（教学示例：线程 ~300ms 自然结束，稍后再关即可）
    for (int i = 0; i < 2; ++i)
        if (m_worker[i]) { e.Veto(); return; }
    e.Skip(true);
}
```

`wxEVT_CLOSE_WINDOW` 里 `e.Veto()` 拒绝本次关闭——比在析构里赌时序安全得多。

## 7.7 运行与输出

selftest 流程：OnInit 里用模板直建文档（连视图一起）、900ms 定时器到点后启动双 worker、两个完成信号到齐后关窗。

```cpp
// ═══ 7.10 模板直建：绕开选模板对话框 ═══
MyDocument* doc = static_cast<MyDocument*>(tpl->CreateDocument("", wxDOC_NEW));
Log("CreateDocument: doc non-null=%d, view attached=%d\n",
    (int)(doc != nullptr), (int)(frame->m_view != nullptr));
if (!doc) { Log("模板创建失败\n"); return true; }
doc->Modify(true);
Log("doc modified=%d（脏标记由框架跟踪）\n", (int)doc->IsModified());
```

selftest 实测输出（sidecar 文件 `build/docs-ref/07_wx_docview_thread.sidecar` 摘录；块内只引**逐跑恒定**的骨架行，两条 worker 完成行在块外说明——见下）：

```text
==== 07 wx docview+线程 开始 ====
CreateDocument: doc non-null=1, view attached=1
doc modified=1（脏标记由框架跟踪）
view OnDraw calls=1（画布 paint 已驱动视图绘制）
gauges: 40/40, 40/40
==== 07 wx docview+线程 结束 ====
```

逐行对应：`doc non-null=1` 与 `view attached=1` 说明 `CreateDocument` 走完"建文档 → 建视图 → OnCreate 挂靠"全链；`modified=1` 是脏标记置位回读；`OnDraw calls=1` 画布 paint 已驱动视图绘制（挂靠生效）；末尾两个 worker 各 40 步、进度条双双 40/40。两条 `worker N done（wxEVT_THREAD 完成信号）` 夹在 OnDraw 与 gauges 行之间——两个线程并发做 6ms 步进，完成序逐跑不定（实测三次里两次 1 先、一次 0 先）是**预期行为**，selftest 判定也只认"两个都到齐、终值 40/40"不认顺序，故不引固定顺序入块。同理，日志只打 `doc non-null=1` 这类稳定事实、不打堆指针——指针逐跑不同，进了输出就没法做逐字节对账（本教程文档对账的硬约束，check_docs 五关之一）。

## 坑位清单

- **docview 类缺 wxDECLARE_DYNAMIC_CLASS → CreateDocument 返 nullptr**：`CLASSINFO` 反射查不到类信息，运行期静默失败、不报编译错——文档类与视图类都要"声明 + wxIMPLEMENT_DYNAMIC_CLASS 实现"成对出现（ae14a03 实测坑位，源码注释"CLASSINFO 反射创建所需"）。
- **CreateDocument 非 SILENT 会弹选模板框**：多模板时框架弹对话框让用户选类型，无人值守就挂起——selftest 改走 `tpl->CreateDocument("", wxDOC_NEW)` 直建（等价 File→New 确认后的路径），或配 `wxDOC_SILENT` 标志（源码【坑】注释）。
- **SaveObject/LoadObject 有两套签名**：随库构建的 `wxUSE_STD_IOSTREAM` 分支，`std::ostream&` 与 `wxOutputStream&` 二选一；签名对不上又没写 `override`，就是静默重载了一个谁也不调的新函数——docview 的序列化钩子务必带 override（源码【实测坑位】注释）。
- **UI 线程外禁碰控件**：worker 里直接 `m_gauge->SetValue` 是跨线程操纵窗口句柄，未定义行为；`wxQueueEvent` + `wxEVT_THREAD` 是唯一安全通路，事件必须 new（队列接管所有权）（源码铁律注释）。
- **DETACHED 线程指针是状态位不是句柄**：Entry 返回后线程自毁，完成时只能把指针置 nullptr，再 delete/Wait 都是悬垂事故；关窗前用 `wxEVT_CLOSE_WINDOW` + `Veto()` 拦住"线程还在跑"的窗口，等它自然结束（源码注释：~300ms 自然结束，稍后再关）。
- **OnExit 里别 delete 文档管理器**：退出期顶层窗口可能已销毁，文档关闭链会触碰悬垂 frame 指针——教学示例以进程退出兜底收尾（源码注释原话）。

---

上一章：[06 · DC 绘图：双缓冲与抗锯齿](06-wx-drawing.md) ｜ 下一章：[08 · Dear ImGui 骨架：即时模式与双后端](08-imgui-hello.md)（第二部分开始） ｜ 返回：[README](../README.md)
