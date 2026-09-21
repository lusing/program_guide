# 13 · 系统集成：文件系统、最近文件与配置

> 对应示例：`examples/13_shell_integration`

> **本章你将学会**：`CFileFind` 的正确循环写法与"为什么最后那个文件不会被漏掉"、`CRecentFileList` 的构造参数与不自动持久化的陷阱、`SetRegistryKey` 之后的配置到底写到注册表哪里，以及用命名互斥体做单实例程序。
> **前置知识**：第 10 章的文件 IO、第 02 章的 `InitInstance`。

## 1. 遍历文件系统：CFileFind

```cpp
CFileFind finder;
BOOL working = finder.FindFile(_T("C:\\some\\dir\\*"));
while (working) {
    working = finder.FindNextFile();
    if (finder.IsDots())            // "." 和 ".."
        continue;
    if (finder.IsDirectory()) { ... } else { ... }
    ULONGLONG len = finder.GetLength();
    CString path = finder.GetFilePath();
}
```

**这个循环形状是硬性要求**，不能改成 `while (finder.FindNextFile()) { 处理 }`——那样会**漏掉最后一个文件**。

为什么，MFC 源码（`filefind.cpp`）说得比文档清楚：`FindNextFile` 内部是**双缓冲交换**——先把上次预取的条目挪进"当前"槽，再调 Win32 的 `::FindNextFile` 预取下一个：

```cpp
void* pTemp = m_pFoundInfo;
m_pFoundInfo = m_pNextInfo;     // 上次预取的变成"当前"
m_pNextInfo = pTemp;
return ::FindNextFile(m_hContext, (LPWIN32_FIND_DATA) m_pNextInfo);
```

最后一条记录被取到"当前"槽时，预取已经失败、返回 `FALSE`——但**这条记录是有效的**。标准写法在返回 `FALSE` 之前就把它处理掉了；而 `while (FindNextFile()) { 处理 }` 的形状在 `FALSE` 时直接退出循环，最后一条就漏了。

另一个含义：`FindFile` 之后**必须先 `FindNextFile` 一次**才能读属性——`FindFile` 只发起搜索，"当前"槽还是空的。

递归遍历加两个保险：

```cpp
static void ScanDir(LPCTSTR root, int& files, ULONGLONG& bytes,
                    CString& biggest, ULONGLONG& biggestLen,
                    CStringArray& out, int depth) {
    if (depth > 20)          // ① 深度上限：junction/符号链接可能成环
        return;
    CFileFind finder;
    BOOL working = finder.FindFile(CString(root) + _T("\\*"));
    while (working) {
        working = finder.FindNextFile();
        if (finder.IsDots())
            continue;
        if (finder.IsDirectory()) {          // ② 先判目录再决定递归还是统计
            ScanDir(finder.GetFilePath(), ..., depth + 1);
            continue;
        }
        ++files;
        bytes += finder.GetLength();         // ULONGLONG，别用 DWORD 累加
    }
}
```

**累加大目录的字节数必须用 `ULONGLONG`**——`DWORD` 在 4 GB 就溢出了，一个现代目录轻轻松松超。

## 2. 最近文件列表：CRecentFileList

```cpp
//                          命令 ID 起点    注册表节名        条目名格式   保留几条
CRecentFileList m_mru(5001, _T("Recent Files"), _T("File%d"), 8);
```

| 参数 | 含义 |
|---|---|
| `nStart` | MRU 菜单项的起始命令 ID（接进菜单时每条占一个 ID） |
| `lpszSection` | 持久化到注册表/INI 的**节名** |
| `lpszEntryFormat` | 条目名模板，`%d` 被替换成 1、2、3… |
| `nSize` | 保留条数（实战取 4~16） |

核心操作：

```cpp
m_mru.Add(path);        // 去重 + 移到队首；不存在则插入
m_mru.WriteList();      // ← Add 不会自动持久化，必须自己调
m_mru.ReadList();       // 启动时读回

CString name;
if (m_mru.GetDisplayName(name, i, _T(""), 0))   // 缩写显示名
    box.AddString(name);
```

三个容易踩的点（都是对着 MFC 源码 `filelist.cpp` 验证的）：

- **`Add` 不写盘**。它只改内存列表（顺带调一次 `SHAddToRecentDocs`，让文件出现在系统的"最近使用"里）。要持久化必须自己调 `WriteList()`——忘了的话程序重开 MRU 就空了。
- **`GetDisplayName` 的第 3 个参数传 `NULL` 会直接返回 `FALSE`**（源码第一道判断就是 `if (lpszCurDir == NULL …) return FALSE`）。不想做"同目录只显示文件名"的缩写，传空串和 0。
- `ReadList` / `WriteList` 走的就是 `AfxGetApp()->GetProfileString` / `WriteProfileString`——**MRU 的持久化和 Profile 配置是同一套机制**，第 3 节配好注册表它就跟着进注册表。

把 MRU 接进菜单的标准做法是 `UpdateMenu(pCmdUI)`（替你把菜单项一条条填上）；不想动菜单结构的程序（比如对话框应用）就自己取显示名填进列表框，本章示例用的是后者。

## 3. 配置持久化：注册表还是 INI

```cpp
BOOL CShellApp::InitInstance() {
    SetRegistryKey(_T("GuideTutorials"));   // ① 必须在第一次 Profile 调用之前
    ...
}

AfxGetApp()->WriteProfileString(_T("ShellDemo"), _T("LastFolder"), m_folder);
AfxGetApp()->WriteProfileInt(_T("ShellDemo"), _T("ScanCount"), m_scanCount);
CString folder = AfxGetApp()->GetProfileString(_T("ShellDemo"), _T("LastFolder"), _T(""));
```

调了 `SetRegistryKey` 之后，上面三行的落点是**确定的**（`appui3.cpp` 的 `GetAppRegistryKey`）：

```text
HKEY_CURRENT_USER\Software\GuideTutorials\ShellIntegration\ShellDemo
                       └─固定─┘ └─公司名─┘└─应用名──┘└─节名─┘
```

应用名取自 `m_pszAppName`——也就是 `CWinApp` 构造函数里给的那个字符串（示例显式传了 `_T("ShellIntegration")`，路径就不会跟着 exe 改名变）。

**不调 `SetRegistryKey` 会怎样？** 常见的说法是"落到 exe 同目录的 .ini"。**这是错的**，源码里不是这样：

```cpp
// appinit.cpp：没设注册键时
m_pszProfileName = _tcsdup(szExeName + ".INI");    // 只有文件名，没有路径！

// appui3.cpp：Profile 系列函数的 else 分支
::WritePrivateProfileString(lpszSection, lpszEntry, value, m_pszProfileName);
```

`WritePrivateProfileString` 拿到一个**没有路径**的文件名时，会去 **Windows 目录**（`%WINDIR%`）找这个文件——普通权限根本写不进去。所以"不调 `SetRegistryKey` 就自动用 exe 旁边的 INI"在现代 Windows 上是**静默失败**的坑；真要写 INI 文件，用 `CStdioFile` 自己写（第 10 章），别指望 Profile 机制。

| | 调了 `SetRegistryKey` | 没调 |
|---|---|---|
| 落点 | `HKCU\Software\公司\应用\节` | `%WINDIR%\<应用>.INI`（基本必失败） |
| 多用户 | 每用户独立 | — |
| 卸载清理 | 删一个键即可 | — |

为什么写 `HKCU` 而不是 `HKLM`：写 `HKLM` 需要管理员权限，普通账户下要么直接失败、要么被 UAC **虚拟化**（写进了 VirtualStore 的副本，程序自己下次读都读不到）。配置是每用户数据，落 `HKCU` 是唯一正确选择。

`SetRegistryKey` **只能调一次**——源码第一行就是 `ASSERT(m_pszRegistryKey == NULL)`，跟第 11 章的 `LoadAccelTable` 一个脾气。

## 4. 单实例程序

```cpp
HANDLE hMutex = ::CreateMutex(nullptr, FALSE, _T("Guide.Mfc.ShellIntegration"));
if (hMutex == nullptr)
    return FALSE;

if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    ::CloseHandle(hMutex);
    AfxMessageBox(_T("程序已经在运行了。"));
    return FALSE;
}
// 正常路径：不要 CloseHandle(hMutex) —— 互斥体要撑到进程结束。
// 进程退出时操作系统自动回收，这里刻意"泄漏"是标准做法。
```

原理：命名互斥体是**内核对象**，全系统同名唯一。第一个进程创建它，第二个进程 `CreateMutex` 同名对象时同样成功，但 `GetLastError` 会是 `ERROR_ALREADY_EXISTS`——这就是"已有实例"的信号。判断和创建是**原子的**，两个进程同时启动也只有一个能赢。

三个要点：

- **句柄要一直开着**。内核对象靠句柄引用计数存活，句柄全部关闭（或进程退出）对象就销毁，单实例保护随之失效。所以正常路径上不 `CloseHandle`，让它"漏"到进程结束。
- **互斥体名别用 `Global\` 前缀**，除非确实需要跨用户会话唯一（比如写服务程序）。`Global\` 意味着所有用户会话共享一个名字，还会碰到权限问题；单实例保护只要本会话内唯一，用默认的 `Local\`（不写前缀就是它）就够。
- **为什么不用 `FindWindow(_T("SomeClass"), NULL)`**：窗口类名和标题都能被伪造（任何一个程序都可以注册同名窗口类），还可能撞上别的程序的窗口；而且用 `FindWindow` 找到窗口后想把它拉到前台，还得处理前台权限。真要做"第二个实例唤起第一个"，标准组合是：新实例用 `AllowSetForegroundWindow` 授权后发一条**自定义广播消息**，老实例收到后 `SetForegroundWindow` + `RestoreWindow`。这是进阶话题，先把互斥体判断做对。

## 常见坑

1. **`CFileFind` 写成 `while (finder.FindNextFile())`**
   漏掉最后一个文件。`FindNextFile` 返回 `FALSE` 时最后一条已经进了"当前"槽，必须在退出循环前处理它。惯用法是 `working = FindNextFile(); 处理;`。

2. **`FindFile` 之后直接读属性**
   `FindFile` 只发起搜索，"当前"槽是空的，属性读取的结果无效。先 `FindNextFile` 一次。

3. **递归不判 `IsDirectory` 就下钻**
   对文件调 `FindFile("文件名\\*")` 找不到任何东西，白跑一趟还可能叠出超长路径。先 `IsDirectory()`、再 `IsDots()`、再递归，顺序不能乱。

4. **`SetRegistryKey` 在 `WriteProfileString` 之后调**
   之前的写入已经走错了落点（Windows 目录的 INI，多半已失败）。它必须在 `InitInstance` 里、第一次 Profile 调用之前。而且只能调一次（`ASSERT(m_pszRegistryKey == NULL)`）。

5. **以为不调 `SetRegistryKey` 会落到 exe 同目录**
   实际是 `%WINDIR%` 下的 `<应用>.INI`，普通权限写不进去且**不报错**。要 INI 就自己用 `CStdioFile` 写。

6. **单实例的互斥体句柄提前关闭**
   正常路径上 `CloseHandle` 互斥体，保护立刻失效（第二个实例能正常启动）。让它撑到进程结束，操作系统退出时自动回收。

7. **用 `FindWindow` 做单实例判断**
   窗口类名/标题可被伪造，也可能撞上别人的窗口；创建即判断的命名互斥体是原子的，没有这些问题。

8. **`GetDisplayName` 第 3 参传 `NULL`**
   直接返回 `FALSE`，列表框就是空的。不想缩写就传 `_T("")` 和 `0`。

## 实战建议

- **`SetRegistryKey(_T("公司名"))` 在 `InitInstance` 第一行调用**，一次就够；应用名用 `CWinApp` 构造参数显式指定，别让它跟着 exe 文件名漂移
- **配置读写包成 `LoadConfig` / `SaveConfig` 两个函数**，节名、键名收敛在函数内部，调用方只传值——键名散落在十几个消息处理函数里之后，谁也说不清配置里都存了什么
- **MRU 条数取 4~16**：太少没有意义，太多则注册表和菜单都臃肿；`Add` 之后记得 `WriteList`
- **递归扫描一定要有深度上限**，哪怕只挡到 20 层——用户目录里的 junction、网盘的虚拟目录都可能成环，没有上限的程序会假死

## 自测

1. **为什么 `while (finder.FindNextFile())` 会漏掉最后一个文件？正确写法是什么？**
   —— `FindNextFile` 内部先把上次预取的条目挪进"当前"槽、再预取下一个。最后一条进"当前"槽的那次调用返回 `FALSE`，直接退出循环就漏了它。正确写法：`working = FindNextFile(); 处理;` 放在循环体内，返回 `FALSE` 前最后一次数据已被处理。

2. **`CRecentFileList::Add` 之后为什么要再调 `WriteList`？**
   —— `Add` 只修改内存列表（去重、移到队首，顺带调 `SHAddToRecentDocs`），不落盘。不调 `WriteList`，程序下次启动时 `ReadList` 读回的就是空列表。

3. **调了 `SetRegistryKey(_T("GuideTutorials"))` 后，`WriteProfileString("Cfg", "Name", v)` 写到哪里？没调呢？**
   —— `HKCU\Software\GuideTutorials\<应用名>\Cfg`（应用名取自 `m_pszAppName`）。没调的话走 `WritePrivateProfileString`，文件名只有 `<exe名>.INI` 没有路径，Windows 去 `%WINDIR%` 找它——普通权限写不进去，静默失败。

4. **单实例判断为什么用命名互斥体而不是 `FindWindow`？句柄要不要关？**
   —— 互斥体的"创建+判存"是内核级原子操作，窗口类名可被伪造且 `FindWindow` 可能撞上别的程序。正常路径上**不关**：句柄全关内核对象就销毁，保护失效；进程退出时系统自动回收。

5. **配置为什么写 `HKCU` 而不写 `HKLM`？**
   —— `HKLM` 需要管理员权限；普通账户下要么失败、要么被 UAC 虚拟化写到 VirtualStore，程序自己下次都读不到。配置是每用户数据，`HKCU` 每用户独立、免管理员。

---
上一章：[12 剪贴板与拖放](12-clipboard-dnd.md) ｜ 下一章：[14 DPI 感知与深色模式](14-dpi-darkmode.md)
