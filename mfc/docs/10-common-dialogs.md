# 10 · 通用对话框与文件 IO

> 对应示例：`examples/10_common_dialogs`

## 1. 通用对话框家族

Windows 系统自带一组标准对话框（定义在 `afxdlgs.h`），用法都是"构造 → 配置 → DoModal → 取结果"：

| 类 | 用途 | 取结果 |
|---|---|---|
| `CFileDialog` | 打开/保存文件 | `GetPathName()` |
| `CColorDialog` | 选颜色 | `GetColor()` |
| `CFontDialog` | 选字体 | `GetCurrentFont()` / `m_cf` |
| `CFindReplaceDialog` | 查找替换（非模态） | 消息驱动，特殊 |
| `CPrintDialogEx` | 打印 | `GetDevMode()` |
| `AfxMessageBox` | 消息框（最常用） | 返回按钮 ID |

## 2. CFileDialog 详解

```cpp
// 打开
CFileDialog dlg(TRUE,                    // TRUE=打开，FALSE=保存
                _T("txt"),               // 默认扩展名
                nullptr,                 // 初始文件名
                OFN_FILEMUSTEXIST | OFN_HIDEREADONLY,
                _T("文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||"),
                this);
if (dlg.DoModal() != IDOK)
    return;
CString path = dlg.GetPathName();        // 完整路径
```

**过滤器字符串格式是考试重点**：`显示文本|匹配模式|显示文本|匹配模式|`，最后以 `||` 结尾（双管道 = 空终止）：

```text
文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||
```

保存对话框的必备标志：

- `OFN_OVERWRITEPROMPT`：覆盖已有文件时弹确认
- `OFN_PATHMUSTEXIST`：路径必须存在
- `OFN_ALLOWMULTISELECT`：多选（配 `GetNextPathName` 遍历）

经验：**保存时先判断"有没有地方可存"**——比如编辑器第一次保存时文件名为空，先弹保存对话框要路径，之后的保存静默覆盖（第 25 章实战项目就是这个逻辑）。

## 3. CFile：字节级读写

`CFile` 是 MFC 文件操作的地基：

```cpp
CFile file;
if (!file.Open(path, CFile::modeRead | CFile::shareDenyWrite)) {
    // 打开失败（文件被占用/不存在），CFile 不抛异常版本可判断返回值
    return FALSE;
}
UINT len = (UINT)file.GetLength();
file.Read(buf, len);
file.Close();            // 忘了 Close 就等到析构，锁会多留一会儿
```

常用打开标志组合：

| 场景 | 标志 |
|---|---|
| 读 | `modeRead \| shareDenyWrite` |
| 覆盖写 | `modeCreate \| modeWrite \| shareExclusive` |
| 追加 | `modeCreate \| modeWrite \| modeNoTruncate` + `SeekToEnd()` |
| 二进制读全部 | `modeRead \| typeBinary` |

## 4. 文本编码：必须自己懂的一节

Unicode 工程里 `CString` 是 UTF-16。落到磁盘时遇到三种常见编码：

| 编码 | 识别特征 |
|---|---|
| UTF-8 带 BOM | 文件头 `EF BB BF` |
| UTF-16 LE | 文件头 `FF FE` |
| ANSI（简中系统=GBK） | 无 BOM |

**`CStdioFile::ReadString` 在 Unicode 工程里按 ANSI 读**，遇到 UTF-8 的中文直接乱码。所以通用文本 IO 推荐自管编码：二进制读入 → 看 BOM → `MultiByteToWideChar` 转成 CString。

读：

```cpp
UINT codePage = CP_ACP;
int offset = 0;
if (len >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
    codePage = CP_UTF8;  offset = 3;
} else if (len >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
    content = CString((const wchar_t*)(data + 2), (len - 2) / 2);
    return TRUE;
}
int wlen = MultiByteToWideChar(codePage, 0, (const char*)(data + offset),
                               len - offset, nullptr, 0);
MultiByteToWideChar(codePage, 0, (const char*)(data + offset),
                    len - offset, content.GetBuffer(wlen), wlen);
content.ReleaseBuffer(wlen);
```

写（统一 UTF-8 + BOM，记事本/VS 都认）：

```cpp
CT2A utf8(content, CP_UTF8);        // ATL 转换宏：CString → UTF-8 窄串
const BYTE bom[] = { 0xEF, 0xBB, 0xBF };
file.Write(bom, 3);
file.Write((LPCSTR)utf8, (UINT)strlen((LPCSTR)utf8));
```

`CT2A`/`CA2T` 这组 ATL 转换宏（`CA2W` 宽→…，`CW2A`…）是编码转换最省事的工具，作用域结束时自动释放，别 `new` 它。

## 5. OnCtlColor：控件自绘颜色的唯一挂点

编辑框、静态文本的文字/背景颜色**不能**在 OnPaint 里改（控件自绘自己的客户区），正确位置是 `OnCtlColor`：

```cpp
ON_WM_CTLCOLOR()

afx_msg HBRUSH OnCtlColor(CDC* pDC, CWnd* pWnd, UINT nCtlColor) {
    HBRUSH hbr = CFrameWnd::OnCtlColor(pDC, pWnd, nCtlColor);
    if (pWnd->GetSafeHwnd() == m_edit.GetSafeHwnd()) {
        pDC->SetTextColor(m_textColor);      // 只影响这个编辑框
    }
    return hbr;
}
```

改了颜色后 `m_edit.Invalidate()` 触发重刷。

## 6. 常见坑

**大文件 Read 一次读完**：`CFile::Read` 单次有上限（65535 字节级别），大文件要循环读或分块。小配置文件一次读没问题。

**CFile::Open 失败没处理**：返回 FALSE 不抛异常（除非用 `CFileException` 出参），不判断就 `Read` 是空指针行为。

**GetBuffer/ReleaseBuffer 不配对**：`GetBuffer(n)` 之后指针直接写，`ReleaseBuffer` 会重新计算长度，忘记调用则 CString 长度错乱。

**追加写用 modeCreate 忘了 modeNoTruncate**：`modeCreate` 会清空已有文件，追加场景必须带 `modeNoTruncate`。

**编码"猜"**：无 BOM 的 UTF-8 和 GBK 无法可靠区分。产品化做法：优先 BOM；无 BOM 时让用户选，或按内容启发式（如 `IsTextUnicode`）。

## 7. 实战建议

- 把"读任意编码 → CString"和"CString → UTF-8 写出"封装成两个自由函数，全项目复用（第 25 章就是这么干的）
- 打开文件的错误提示要带路径和原因，`GetLastError()` 转成文字比"打开失败"有用得多
- 频繁写日志用 `CStdioFile`（带缓冲）而不是 `CFile` 每次开关

---
上一章：[07 常用控件深入](07-controls.md) ｜ 下一章：[11 工具栏与状态栏](11-toolbars.md)
