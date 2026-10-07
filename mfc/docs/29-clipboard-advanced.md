# 29 · 剪贴板深入：多格式、DIB、延迟渲染与文件列表

> 对应示例：`examples/29_clipboard_advanced`

> **本章你将学会**：注册自定义剪贴板格式、手工构造 CF_DIB 位图数据、延迟渲染（按需生成）的完整回调链、往剪贴板放文件列表（CF_HDROP）。
> **前置知识**：第 12 章的剪贴板基础（Open/Empty/Set/Close 与 GMEM_MOVEABLE 所有权）和 OLE 拖放。

第 12 章解决了“文本怎么进出剪贴板”和“怎么拖放”。《Visual C++ MFC 编程实例》第 14 章走得更远：例 74 最小化文本、例 75 **定制格式数据**、例 76 图像数据、例 78 复制列表数据、例 77 **回调函数（延迟渲染的思想源头）**。加上 Windows 后来增强的 CF_HDROP，这章把剪贴板从“字符串中转站”升级成“结构化数据总线”。

## 1. 自定义注册格式：结构体的官方通道

`RegisterClipboardFormat` 给你的私有格式发一个**全局唯一**的格式 ID（按格式名去重——两个程序用同一个字符串就拿到同一个 UINT）：

```cpp
static UINT ScoreFormat() {
    static UINT fmt = ::RegisterClipboardFormat(_T("MFC-Guide-ScoreCard"));
    return fmt;
}
```

之后按第 12 章的老流程写入结构体二进制：

```cpp
struct ScoreCard {
    int      magic;          // 版本/魔数：读回来先验，防串台
    wchar_t  name[24];
    int      score;
    FILETIME stamped;
};
```

三条工程纪律：

1. **定长 + 显式成员**：别放指针（指向的内存不随 HGLOBAL 走）；变长数据用“容量 + 实长”或单独分配后拷进同一块。
2. **加 magic/版本头**：格式名撞车或格式演进时，读端能拒收而不是崩（示例 29 读回先验 `magic == 0x5343`）。
3. **同时放一份文本格式**：粘贴端按能力协商。记事本只认 CF_UNICODETEXT，你的程序优先取自定义格式——这就是“多格式协商”：`SetClipboardData` 可以连续放多种格式，各有各的数据。

读端枚举对面有什么：`EnumClipboardFormats` 从 0 开始循环（示例 29 的“粘贴并枚举”按钮），`GetClipboardFormatName` 把注册格式翻译回名字。

## 2. CF_DIB：手工拼设备无关位图

把一张自绘图像放进剪贴板，标准载体是 **CF_DIB**（`BITMAPINFOHEADER` + 像素阵列，不带文件头）。不用 GDI 句柄——`CF_BITMAP`（HBITMAP）也合法，但 DIB 是“数据”，任何程序都能不依赖你的 DC 处理它：

```cpp
// 24bpp、自底向上 DIB
const DWORD pixBytes = (DWORD)W * 3;                    // 200*3=600，天然 4 字节对齐
const DWORD total = sizeof(BITMAPINFOHEADER) + pixBytes * H;
HGLOBAL hg = ::GlobalAlloc(GMEM_MOVEABLE, total);
BYTE* p = (BYTE*)::GlobalLock(hg);
BITMAPINFOHEADER* bi = (BITMAPINFOHEADER*)p;
bi->biSize        = sizeof(*bi);
bi->biWidth       = W;
bi->biHeight      = H;          // 正数 = 自底向上（原点在左下角！）
bi->biPlanes      = 1;
bi->biBitCount    = 24;
bi->biCompression = BI_RGB;
bi->biSizeImage   = pixBytes * H;
BYTE* pixels = p + sizeof(BITMAPINFOHEADER);
// ... 填像素：BGR 序、行按 4 字节对齐 ...
::GlobalUnlock(hg);
::SetClipboardData(CF_DIB, hg);   // 成功后 hg 归剪贴板，别再碰
```

三个被老书反复强调、今天依然坑人的点：

- **行序翻转**：正高度 = 自底向上，视觉上的“第一行”在缓冲区**末尾**。忘了翻转，画出来的是倒影。
- **行对齐**：每行字节数向上取整到 4 的倍数。24bpp 宽度不是 4 像素倍数时（比如 201×3=603 字节），必须补 padding，否则斜纹。
- **读端渲染**：`SetDIBitsToDevice` 一步从 DIB 画到 DC（示例 29 预览控件的画法），注意传 `abs(biHeight)` 行数。

## 3. 延迟渲染：先占坑，后交货

昂贵数据（大图、需压缩的档案）大多数粘贴根本轮不到——**延迟渲染**让“生成”推迟到对方真正要的那一刻：

```cpp
// 占坑：SetClipboardData 传 NULL，等于承诺“要的时候我现做”
::SetClipboardData(CF_DIB, nullptr);
::SetClipboardData(CF_UNICODETEXT, nullptr);   // 可以占多个坑
```

承诺的兑现走两个窗口消息：

```cpp
// 某程序真的要这个格式了 —— 此刻必须交货
afx_msg void OnRenderFormat(UINT fmt) {
    if (fmt == CF_DIB) {
        // 现场生成 HGLOBAL ...
        ::SetClipboardData(fmt, hg);      // 这才是交货
    }
}

// 本程序要退了，剪贴板上还挂着没兑现的延迟格式 —— 全部补齐，
// 否则数据随窗口消亡
afx_msg void OnRenderAllFormats() { /* 同上，逐格式补 */ }
```

延迟渲染最容易翻车的地方：

1. **退出前忘了 `WM_RENDERALLFORMATS`**：用户复制了你的大图没粘贴，然后关了你的程序——剪贴板上的占坑变死数据，别处一粘贴就是空的。必须补。
2. **渲染回调里 UI 状态**：回调可能在你的消息循环空隙到达，别假设用户刚点过什么按钮——数据从“当前文档状态”取，与交互无关。
3. **耗时太长的生成**会卡住请求方（同步协议）——延迟渲染省的是“从不粘贴的那 90%”，不是生成时间本身。

OLE 路线（第 12 章的 `COleDataSource`）有对应的 `DelayRenderData` + `OnRenderGlobalData` 虚函数，语义相同、封装更 C++；裸 API 版本（示例 29）展示的是协议本体。

## 4. CF_HDROP：文件列表进剪贴板

把“文件们”放进剪贴板，资源管理器、邮件客户端都能粘贴。载体是 `DROPFILES` 头 + 双 null 结尾的路径串：

```cpp
size_t total = sizeof(DROPFILES) + nameChars * sizeof(wchar_t);
HGLOBAL hg = ::GlobalAlloc(GMEM_MOVEABLE, total);
DROPFILES* df = (DROPFILES*)::GlobalLock(hg);
df->pFiles = sizeof(DROPFILES);   // 路径串的偏移
df->fWide  = TRUE;                // 路径是 UTF-16
wchar_t* names = (wchar_t*)((BYTE*)df + df->pFiles);
// 逐个 lstrcpyn，串间 \0，末尾再补一个 \0
::GlobalUnlock(hg);
::SetClipboardData(CF_HDROP, hg);
```

反过来读（第 12 章 DragAcceptFiles 收到的是**同一种结构**）：`DragQueryFile(hDrop, i, buf, cch)` 逐个取路径，`DragQueryFile(hDrop, 0xFFFFFFFF, nullptr, 0)` 问个数。

一个语义细节：CF_HDROP 放的是**路径字符串**不是文件内容——文件被删了，粘贴方跟着报错。跨程序搬大数据的现代替代是虚拟文件（CFSTR_FILEDESCRIPTOR 等 shell 机制），需要时再深入。

## 5. 格式优先级与枚举

一个剪贴板快照可以同时挂多种格式。惯例的放置顺序（先放的优先）：

1. 你的私有格式（信息最全）
2. CF_DIB / CF_ENHMETAFILE（图像）
3. CF_UNICODETEXT（兜底）

粘贴方 `IsClipboardFormatAvailable` 按自己的口味挑；讲究的用 `GetPriorityClipboardFormat`（传格式数组，返回第一个命中的）。示例 29 的“粘贴并枚举”把 `EnumClipboardFormats` + `GetClipboardFormatName` 组合起来——调试剪贴板问题的第一件事永远是“对面到底放了什么格式”。

## 实战建议

- 封装一对 `WriteHGlobal/ReadHGlobal`（像示例 29 那样）把“锁内存/拷贝/释放”收拢，别让 Open/Close 散落各处。
- 自定义格式的结构体加 `static_assert(sizeof(ScoreCard) == N)`：跨版本对齐一旦变了，旧数据读回来就是垃圾。
- 测试延迟渲染最快的办法：DbgView 里看 `WM_RENDERFORMAT` 到达的时刻——复制完不动它，回调不来；一粘贴，日志出现。
- 剪贴板是**全系统共享**的单例：调试期间断点停在 OpenClipboard 里，别的程序会开始报“打不开剪贴板”——尽快 Close。

## 常见坑（实测）

1. **`SetClipboardData` 之后还写那块内存**：所有权已转移，写入是未定义行为（多半没事，偶尔堆损坏）。
2. **延迟渲染占坑后销毁窗口**：见上文 WM_RENDERALLFORMATS——数据“看着在，粘出来空”。
3. **DIB 行序/对齐错**：图像倒立或呈斜条纹——两个症状都能直接反推是哪个。
4. **DROPFILES 的 `fWide` 忘了置 TRUE**：现代系统按 ANSI 解释路径串，中文路径立刻乱码。
5. **`GetClipboardData` 返回的内存直接改**：它是剪贴板的，只读；要改先复制（示例 29 的 `ReadHGlobal` 就是复制语义）。

---

上一章：[28 控制条家族：CDialogBar、CReBar 与停靠体系](28-control-bars.md) · 下一章：[30 进程间通信：WM_COPYDATA、邮槽、命名管道、共享内存](30-ipc.md)
