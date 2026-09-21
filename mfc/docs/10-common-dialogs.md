# 10 · 通用对话框与文件 IO

> 对应示例：`examples/10_common_dialogs`

> **本章你将学会**：`CFileDialog` 每个参数的含义与多选后的遍历方式、`CFile` 与 `CStdioFile` 的分工、Unicode 工程里读写文本为什么必须自己管编码、`CColorDialog`/`CFontDialog` 的结果怎么应用到控件，以及 `OnCtlColor` 为什么是改控件颜色的唯一挂点。
> **前置知识**：第 06 章的模态对话框与 `DoModal`、第 04 章的字符串表。

## 1. 通用对话框家族

Windows 系统自带一组标准对话框（定义在 `afxdlgs.h`），用法都是"构造 → 配置 → `DoModal` → 取结果"：

| 类 | 用途 | 取结果 |
|---|---|---|
| `CFileDialog` | 打开/保存文件 | `GetPathName()` |
| `CColorDialog` | 选颜色 | `GetColor()` |
| `CFontDialog` | 选字体 | `GetCurrentFont()` / `m_cf` |
| `CFindReplaceDialog` | 查找替换（非模态） | 消息驱动，特殊 |
| `CPrintDialogEx` | 打印 | `GetDevMode()` |
| `AfxMessageBox` | 消息框（最常用） | 返回按钮 ID |

它们的好处是**免费获得系统的全部能力**：最近访问位置、库文件夹、网络位置、搜索、面包屑导航，还有系统语言下的全部文案。自己搭一个文件选择界面，这些东西一样都做不出来。

## 2. CFileDialog：五个参数逐个说

```cpp
CFileDialog dlg(TRUE,                    // ① bOpenFileDialog
                _T("txt"),               // ② lpszDefExt
                nullptr,                 // ③ lpszFileName
                OFN_FILEMUSTEXIST | OFN_HIDEREADONLY,   // ④ dwFlags
                _T("文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||"),  // ⑤ lpszFilter
                this);                   // ⑥ 父窗口
if (dlg.DoModal() != IDOK)
    return;
CString path = dlg.GetPathName();        // 完整路径
```

| 参数 | 含义 | 注意 |
|---|---|---|
| `bOpenFileDialog` | `TRUE` = 打开，`FALSE` = 保存 | 同一个类，两套界面 |
| `lpszDefExt` | 用户没输扩展名时自动补的 | 不含点，写 `"txt"` 不是 `".txt"` |
| `lpszFileName` | 初始文件名 | 传 `nullptr` 表示空 |
| `dwFlags` | 行为开关，见下 | 打开和保存各有常用组合 |
| `lpszFilter` | 过滤器，见下 | **格式最容易写错** |
| `pParentWnd` | 父窗口 | 传 `this` 才有正确的模态行为 |

### 2.1 过滤器字符串

格式是 `显示文本|匹配模式|显示文本|匹配模式|`，**最后必须以 `||` 结尾**（双管道 = 空终止）：

```text
文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||
```

结尾少一个 `|`，Windows 会继续往后读到字符串末尾之外的内存去找下一个过滤器——运气好只是过滤项显示不全，运气差直接崩。

### 2.2 常用标志

打开对话框：

- `OFN_FILEMUSTEXIST`：只允许选已存在的文件
- `OFN_HIDEREADONLY`：隐藏"只读"复选框
- `OFN_ALLOWMULTISELECT`：允许多选

保存对话框：

- `OFN_OVERWRITEPROMPT`：覆盖已有文件时弹确认（保存必备）
- `OFN_PATHMUSTEXIST`：路径必须存在

`OFN_EXPLORER` 是 Vista 之后的新式外观。**现代 MFC 默认就用它**，不用手动加；只有要兼容极老的系统或依赖旧式行为时才需要显式控制。

### 2.3 多选之后怎么遍历

勾了 `OFN_ALLOWMULTISELECT` 之后，`GetPathName()` 只返回**第一个**文件。要拿全部，得用这两个函数：

```cpp
CFileDialog dlg(TRUE, nullptr, nullptr,
                OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT, filter, this);

// 缓冲区必须自己给，且要够大 —— 默认的 260 字符装不下多个长路径
const int kBufSize = 32768;
dlg.m_ofn.lpstrFile = new TCHAR[kBufSize];
dlg.m_ofn.lpstrFile[0] = _T('\0');
dlg.m_ofn.nMaxFile = kBufSize;

if (dlg.DoModal() == IDOK) {
    POSITION pos = dlg.GetStartPosition();
    while (pos) {
        CString path = dlg.GetNextPathName(pos);   // 每次拿一个完整路径
        Use(path);
    }
}
delete[] dlg.m_ofn.lpstrFile;   // 自己分配的，自己释放
```

**`m_ofn.lpstrFile` 里的原始内容格式很反直觉**：多选时它是"目录 `\0` 文件1 `\0` 文件2 `\0\0`"——**首段是目录，后面才是文件名，都不是完整路径**。所以别去手工解析它，用 `GetStartPosition` / `GetNextPathName` 让 MFC 拼给你。

### 2.4 与 Win32 现代 API 的关系

`CFileDialog` 底下包的是 Win32 的 `GetOpenFileName` / `GetSaveFileName`（`comdlg32.dll`）。Vista 起微软提供了新的 COM 接口 `IFileOpenDialog` / `IFileSaveDialog`，多了"自定义侧边栏位置""设置默认文件夹"等能力。日常开发用 `CFileDialog` 完全够；需要那些新能力时再考虑 COM 接口（第 22 章的现代 API 一节会提到）。

## 3. CFile 与 CStdioFile

`CFile` 是**字节级**的地基，`CStdioFile` 在它之上加了一层按行读写。

| | `CFile` | `CStdioFile` |
|---|---|---|
| 读写单位 | 字节（`Read`/`Write`） | 行（`ReadString`/`WriteString`） |
| 缓冲 | 无 | 有（stdio 缓冲） |
| 文本/二进制 | 由 `typeText`/`typeBinary` 决定 | 通常按文本 |
| 适合 | 二进制文件、自己管编码 | 逐行读配置、写日志 |

```cpp
CFile file;
if (!file.Open(path, CFile::modeRead | CFile::shareDenyWrite)) {
    // 打开失败（文件被占用/不存在）
    return FALSE;
}
ULONGLONG len = file.GetLength();
file.Read(buf, (UINT)len);
file.Close();            // 忘了 Close 就等到析构，锁会多留一会儿
```

常用打开标志组合：

| 场景 | 标志 |
|---|---|
| 读 | `modeRead \| shareDenyWrite` |
| 覆盖写 | `modeCreate \| modeWrite \| shareExclusive` |
| 追加 | `modeCreate \| modeWrite \| modeNoTruncate` + `SeekToEnd()` |
| 二进制读全部 | `modeRead \| typeBinary` |

**`CFile::Read` 单次有上限**（约 65535 字节级别），大文件必须循环读或分块。`GetLength()` 返回 `ULONGLONG`，别随手截成 `UINT`。

出错时用 `CFileException` 出参版本才能拿到原因：

```cpp
CFileException e;
if (!file.Open(path, CFile::modeRead, &e)) {
    TCHAR msg[256];
    e.GetErrorMessage(msg, 256);      // "拒绝访问" / "找不到文件" 这类可读文案
    AfxMessageBox(msg);
}
```

**没有 `CFileException*` 出参的重载返回 `FALSE` 而不抛异常**——两个版本的错误处理方式完全不同，别搞混。

## 4. 文本编码：必须自己懂的一节

Unicode 工程里 `CString` 是 UTF-16。落到磁盘时遇到三种常见编码：

| 编码 | 识别特征 |
|---|---|
| UTF-8 带 BOM | 文件头 `EF BB BF` |
| UTF-16 LE | 文件头 `FF FE` |
| ANSI（简中系统 = GBK） | 无 BOM |

**`CStdioFile::ReadString` 在 Unicode 工程里按 ANSI 读**——遇到 UTF-8 的中文直接乱码。所以通用文本 IO 推荐自管编码：二进制读入 → 看 BOM → `MultiByteToWideChar` 转成 `CString`。

```cpp
UINT codePage = CP_ACP;
int offset = 0;
if (len >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
    codePage = CP_UTF8;  offset = 3;
} else if (len >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
    content = CString((const wchar_t*)(data + 2), (len - 2) / 2);   // UTF-16 直接就是 CString
    return TRUE;
}
int wlen = MultiByteToWideChar(codePage, 0, (const char*)(data + offset),
                               len - offset, nullptr, 0);
MultiByteToWideChar(codePage, 0, (const char*)(data + offset),
                    len - offset, content.GetBuffer(wlen), wlen);
content.ReleaseBuffer(wlen);
```

写出统一用 **UTF-8 + BOM**（记事本、VS、浏览器都认）：

```cpp
CT2A utf8(content, CP_UTF8);        // ATL 转换宏：CString → UTF-8 窄串
const BYTE bom[] = { 0xEF, 0xBB, 0xBF };
file.Write(bom, 3);
file.Write((LPCSTR)utf8, (UINT)strlen((LPCSTR)utf8));
```

`CT2A` / `CA2T` / `CA2W` / `CW2A` 这组 ATL 转换宏是编码转换最省事的工具，作用域结束时自动释放转换缓冲区——**别 `new` 它**。

## 5. 颜色与字体对话框

```cpp
CColorDialog dlg(m_textColor);            // 传入当前色作为初始值
if (dlg.DoModal() == IDOK) {
    m_textColor = dlg.GetColor();          // COLORREF
    m_edit.Invalidate();                   // 改完要重刷
}
```

`COLORREF` 是 `0x00BBGGRR` 排列（**不是 RGB 顺序**），所以永远用 `RGB(r, g, b)` 宏构造、用 `GetRValue` / `GetGValue` / `GetBValue` 取值，别手工拼字节。

字体对话框返回的是一个 `LOGFONT` 结构（字面名、字号、粗斜体、字符集全在里面）：

```cpp
LOGFONT lf = { 0 };
CFontDialog dlg(&lf);                      // 传入当前字体作为初始值
if (dlg.DoModal() == IDOK) {
    dlg.GetCurrentFont(&lf);
    m_font.DeleteObject();                 // 换字体前先释放旧的
    m_font.CreateFontIndirect(&lf);
    m_edit.SetFont(&m_font);               // 或发 WM_SETFONT
}
```

**`CFont` 对象必须比用到它的控件活得久**。做成对话框的成员变量是最省心的；做成局部变量，函数一返回字体就没了，控件会画成乱码。

## 6. OnCtlColor：控件自绘颜色的唯一挂点

编辑框、静态文本的文字/背景颜色**不能**在 `OnPaint` 里改——控件自己画自己的客户区，你的 `OnPaint` 根本没机会。正确位置是父窗口的 `OnCtlColor`：

```cpp
ON_WM_CTLCOLOR()

afx_msg HBRUSH OnCtlColor(CDC* pDC, CWnd* pWnd, UINT nCtlColor) {
    HBRUSH hbr = CFrameWnd::OnCtlColor(pDC, pWnd, nCtlColor);
    if (pWnd->GetSafeHwnd() == m_edit.GetSafeHwnd()) {
        pDC->SetTextColor(m_textColor);    // 只影响这一个编辑框
    }
    return hbr;                            // 返回的刷子用来涂背景
}
```

改完颜色调 `m_edit.Invalidate()` 触发重刷。想连背景一起改，就返回自己的 `HBRUSH`（成员变量，别在函数里造临时刷子）。

## 常见坑

1. **`lpszFilter` 结尾少写一个 `|`**
   必须以 `||` 结尾（双管道 = 空终止）。少一个，Windows 会越界往后读找下一个过滤器，轻则过滤项显示不全，重则崩溃。

2. **多选之后直接解析 `m_ofn.lpstrFile`**
   它的格式是"目录 `\0` 文件1 `\0` 文件2 `\0\0`"，**首段是目录、后面是文件名，都不是完整路径**。用 `GetStartPosition` / `GetNextPathName` 让 MFC 拼。另外缓冲区要自己给足（多个长路径 260 字符装不下）。

3. **`CFile::Open` 失败不抛异常**
   不带 `CFileException*` 出参的重载返回 `FALSE`。不判断就 `Read` 是空指针行为。想要可读的错误原因，用带出参的版本 + `GetErrorMessage`。

4. **追加写用 `modeCreate` 忘了 `modeNoTruncate`**
   `modeCreate` 会**清空**已有文件。追加场景必须 `modeCreate | modeWrite | modeNoTruncate`，否则每次"追加"都变成"覆盖"。

5. **忘记 `Close` 导致文件句柄泄漏**
   不 `Close` 就得等对象析构才释放，期间文件一直被锁着，别的程序打不开。局部 `CFile` 作用域结束时虽然会析构，但一个长循环里反复开关文件就会耗尽句柄。

6. **`GetBuffer` / `ReleaseBuffer` 不配对**
   `GetBuffer(n)` 之后直接往指针里写，`ReleaseBuffer()` 会重新计算长度。忘记调用，`CString` 的长度就是错的，后续拼接、比较全乱。

7. **`COLORREF` 手工拼字节**
   它是 `0x00BBGGRR`，不是 `RRGGBB`。一律用 `RGB()` 构造、`GetRValue`/`GetGValue`/`GetBValue` 拆解。

8. **编码靠"猜"**
   无 BOM 的 UTF-8 和 GBK 无法可靠区分（同样的字节序列在两种编码下都是合法文本）。产品化做法：优先认 BOM；无 BOM 时让用户选，或按内容启发式（如 `IsTextUnicode`）并允许用户覆盖。

## 实战建议

- 把"读任意编码 → `CString`"和"`CString` → UTF-8 写出"封装成两个自由函数，全项目复用（第 25 章就是这么干的）
- 打开文件的错误提示要带**路径和原因**：`GetErrorMessage` 转出来的"拒绝访问"比"打开失败"有用得多
- **频繁写日志用 `CStdioFile`**（带缓冲）而不是 `CFile` 每次开关；反过来，二进制数据一律 `CFile` + `typeBinary`
- 保存逻辑做成"**有路径就静默存，没路径才弹对话框**"：编辑器每次保存都弹一次文件对话框是很烦人的体验（第 25 章实战项目的做法）

## 自测

1. **`CFileDialog` 的过滤器字符串为什么必须以 `||` 结尾？**
   —— 它用空字符串作为过滤器列表的终止标记，`||` 就是"空的那一项"。少一个 `|`，Windows 会继续往后读内存找下一个过滤器，导致过滤项显示不全甚至崩溃。

2. **多选文件后 `GetPathName()` 返回什么？正确的遍历方式是什么？**
   —— 只返回第一个文件。要拿全部，用 `GetStartPosition()` + `GetNextPathName(pos)` 循环；别手工解析 `m_ofn.lpstrFile`，它的格式是"目录 `\0` 文件名 `\0` … `\0\0`"，首段是目录而不是完整路径。

3. **Unicode 工程里为什么不能直接用 `CStdioFile::ReadString` 读 UTF-8 文件？**
   —— 它在 Unicode 工程里按 ANSI（简中系统上是 GBK）解释字节，UTF-8 的中文会乱码。通用做法是二进制读入、看 BOM 判断编码，再用 `MultiByteToWideChar` 显式转换。

4. **`CFile::Open` 失败时怎么拿到可读的错误原因？**
   —— 用带 `CFileException*` 出参的重载；失败时用 `e.GetErrorMessage(msg, n)` 转成"拒绝访问""找不到文件"这类文案。不带出参的重载只返回 `FALSE`，拿不到原因。

5. **改编辑框的文字颜色该在哪里做？为什么不能在 `OnPaint` 里做？**
   —— 在父窗口的 `OnCtlColor` 里（`pDC->SetTextColor(...)`，返回背景刷）。编辑框自己绘制自己的客户区，父窗口的 `OnPaint` 根本画不到它上面。

---
上一章：[09 自绘控件与自定义控件](09-custom-controls.md) ｜ 下一章：[11 工具栏与状态栏](11-toolbars.md)
