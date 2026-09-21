# 21 · 异常处理、调试与内存诊断

> 对应示例：`examples/21_debugging`

> **本章你将学会**：`CException` 继承树与 `GetErrorMessage` 怎么写、MFC 异常宏和 C++ try/catch 的清理责任差别、`ASSERT`/`VERIFY`/`ASSERT_VALID` 三兄弟的 release 行为，以及 `_CrtMem` 三段式内存诊断。
> **前置知识**：第 10 章的文件异常场景、第 15 章的文档打开流程。

## 1. MFC 的异常体系

MFC 所有异常类都从 `CException : CObject` 派生——继承 `CObject` 是为了纳入 `CRuntimeClass` 体系（`IsKindOf` 校验、`Dump`、`AssertValid` 都能用）：

```text
CObject
 └─ CException                ← 所有异常的根：Delete() + GetErrorMessage()
     ├─ CArchiveException     ← 序列化失败（第 17 章的 badSchema 就在这）
     ├─ CFileException        ← 文件打开/读写失败
     └─ CSimpleException      ← 只带一条错误消息的轻量异常
         ├─ CMemoryException  ← 内存耗尽（new 失败）
         ├─ CNotSupportedException
         └─ CInvalidArgException
```

MFC 的框架代码在各处替你抛：`AfxThrowFileException`、`AfxThrowMemoryException`、`AfxThrowArchiveException`……所以不写一行 throw，第 10/15/17 章那些失败路径抛的都是 `CException` 派生对象。

自定义异常照葫芦画瓢：

```cpp
class CConfigException : public CException {
    DECLARE_DYNAMIC(CConfigException)
public:
    explicit CConfigException(LPCTSTR what) : m_what(what) {}

    // 重写 GetErrorMessage：基类版本只返回 FALSE（没有消息可给），
    // ReportError 和消息框展示全靠它
    BOOL GetErrorMessage(LPTSTR buf, UINT max, PUINT pHelp = NULL) const override {
        if (!buf || max == 0) return FALSE;
        _tcsncpy_s(buf, max, m_what, _TRUNCATE);
        return TRUE;
    }
    CString m_what;
};
IMPLEMENT_DYNAMIC(CConfigException, CException)
```

`GetErrorMessage(buf, n)` 返回 TRUE 表示写入了消息。给用户看的文字在这里定；技术细节（错误码、文件路径）留给日志。

## 2. TRY/CATCH 宏 vs C++ try/catch

MFC 异常宏是 C++ 异常的**历史包装**（现代 MFC 里 `TRY` 就是 `try` 外面多挂一个清理哨兵）：

| | MFC 宏 | C++ 原生 |
|---|---|---|
| 语法 | `TRY / CATCH(CFileException, e) / AND_CATCH(...) / END_CATCH` | `try / catch (CFileException* e)` |
| 捕获类型 | `CATCH(class, e)` 展开成 `catch (class* e)`，**按指针捕获** | 自己写，同样是指针 |
| 清理责任 | `AFX_EXCEPTION_LINK` 哨兵在作用域结束**自动 `Delete`**（`m_bAutoDelete=TRUE` 时） | **没人管**——必须自己 `e->Delete()` |
| 校验 | 宏里自带 `IsKindOf` 断言 | 无 |

MFC 异常是 `new` 出来的堆对象（跨 DLL 边界历史原因），捕获后由谁释放是这套体系的核心约定：

```cpp
// 形式一：MFC 宏 —— 哨兵托底，不用管释放
TRY {
    AfxThrowFileException(CFileException::fileNotFound, -1, _T("config.ini"));
}
CATCH(CFileException, e) {
    TCHAR buf[256];
    e->GetErrorMessage(buf, 256);
}
END_CATCH

// 形式二：C++ catch —— 没有 MFC 哨兵，必须自己 Delete
try {
    throw new CConfigException(_T("缺少 [database] 节"));
} catch (CException* e) {
    ...
    e->Delete();       // 忘了这行 = 每次异常泄漏一个对象
}
```

`CException::Delete()` 不是裸 `delete`——它看 `m_bAutoDelete` 标志（从框架里接来的异常可能是"不归你删"的），所以**统一调 `Delete()`，不要直接 `delete`**。

混用标准异常要小心：`std::bad_alloc`/`std::runtime_error` **不是** `CException`，`catch (CException*)` 接不住。MFC 代码库里的 catch 要么接 `CException*`、要么接 `catch (...)` 兜底，别指望一个 catch 抓两个体系。

## 3. 断言家族：ASSERT / VERIFY / ASSERT_VALID

| 宏 | _DEBUG 构建 | Release 构建 | 用途 |
|---|---|---|---|
| `ASSERT(expr)` | 假则中断进调试器 | **整个表达式被编译掉** | 内部不变式检查 |
| `VERIFY(expr)` | 同 ASSERT | **表达式仍求值**，只丢断言 | 调用必须发生、返回值顺带检查 |
| `ASSERT_VALID(pObj)` | 调 `pObj->AssertValid()` | 消失 | 检查对象自身一致性 |

`VERIFY` 的存在理由就一个：**release 下调用不能消失**：

```cpp
VERIFY(CountOne());    // release：函数照常执行，m_calls 照常 +1

// 若写成 ASSERT(CountOne())：release 下 CountOne 根本不会被调用！
```

推论是**断言里绝不能放有副作用的表达式**——`ASSERT(Release())` 在 release 版里资源永远不释放，逻辑悄悄变了。副作用调用写正文，断言只看结果。

`ASSERT_VALID` 配合 `CObject::AssertValid()`（可重写，里面检查成员状态），是 MFC 框架自检的入口；自定义 Doc/View 类重写它，调试版里能提前抓到悬空指针。

## 4. 跟踪输出：TRACE 与 afxDump

```cpp
TRACE(_T("打开文件：%s，大小 %d\n"), path, size);   // printf 风格
TRACE1(_T("计数 = %d\n"), n);                        // 带参数个数的变体 TRACE0~TRACE3
```

`TRACE` 只在 `_DEBUG` 构建下编译成输出调用，发到**调试器**（VS 输出窗口或 DebugView）；release 下整个消失。`afxDump << pObj` 走 `CObject::Dump`，把对象内部状态打到同一通道。

**本书示例是 release 构建（/MD），TRACE 看不到输出**——想看效果要用调试参数重新构建：`cl /D_DEBUG /MDd ...`（其余参数同 build.ps1）。`/MDd` 还会换用调试版 CRT，堆操作全走调试堆，下面的内存诊断才有实际数据。

## 5. 内存泄漏诊断：_CrtMem 三段式

CRT 调试堆提供"内存快照对比"：

```cpp
_CrtMemState s1, s2, s3;
_CrtMemCheckpoint(&s1);        // ① 起点快照
int* leak = new int[100];      //    可疑代码（示例故意泄漏 400 字节）
_CrtMemCheckpoint(&s2);        // ② 终点快照
if (_CrtMemDifference(&s3, &s1, &s2))     // ③ 返回非零 = 两点间有差异
    _CrtMemDumpStatistics(&s3);          //    差异统计打到调试器
```

另一档是"进程退出时自动盘点"——`InitInstance` 里开一次，泄漏清单（含分配位置的文件/行号，配 `_CrtSetBreakAlloc` 还能在分配处断下）在退出时自动 dump：

```cpp
#ifdef _DEBUG
    _CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif
```

**这些只在 `_DEBUG` 构建下有效**：release 版的 crtdbg.h 把 `_CrtMemCheckpoint` 等 `#define` 成 `((void)0)` 空宏——代码照样编译，什么也不发生（`_CrtMemDifference` 恒返回 0）。示例 21 用 `#ifdef _DEBUG` 把两套路径分开写，release 下明确告诉你"这里是空宏"，而不是让你以为"检查过没泄漏"。

## 常见坑

1. **C++ catch 接住 MFC 异常后忘记 `e->Delete()`**
   MFC 异常是堆对象，没有 MFC 宏哨兵托底时每次异常泄漏一个对象（低频路径看不见，高频路径慢慢涨死）。统一规则：宏体系自动清理，裸 `catch` 必须自己 `Delete()`。

2. **把有副作用的调用写进 `ASSERT`**
   `ASSERT(Release())` 在 release 下整个表达式消失——调用根本没发生，资源泄漏、计数错乱，而且 debug 版一切正常，发布后才发现。副作用进正文，断言只看结果；调用必须发生的场景用 `VERIFY`。

3. **在 release 构建里期待 `TRACE`/`_Crt*` 有输出**
   它们在 release 下是空宏，"没有输出"≠"没问题"。诊断构建（`/D_DEBUG /MDd`）和发布构建（`/MD`）分开做，别拿 release 版验证内存行为。

4. **内存快照把启动期的分配算进去**
   checkpoint 放得太早（全局对象初始化前），静态/框架的初始化分配全进了差异。三段式包住**可疑代码段本身**，别把进程一生的分配都框进来。

5. **只捕获 `CException*` 而漏掉标准异常**
   `std::bad_alloc`、自己代码里的 `std::runtime_error` 都不是 `CException`。边界层用 `catch (...)` 兜底打日志，别让异常穿透到消息循环外。

6. **异常当流程控制用**
   正常分支靠抛异常/捕获跳转，栈展开成本高且断言体系全被绕过。异常留给"真正异常"的失败路径（文件没了、内存尽了），可预期的分支用返回值。

## 实战建议

- **调试版和发布版分开构建**：调试版 `/D_DEBUG /MDd` 开满断言与内存诊断，发布版 `/MD` 收干净——同一份代码，两套验证
- 异常消息分层：`GetErrorMessage` 给用户看的一句话，错误码与上下文走 `TRACE`/日志，别把两者混在一条消息里
- 自定义异常一律配 `GetErrorMessage` 重写，否则 `ReportError` 弹出来是空框
- 排查泄漏先用 `_CrtMemDifference` 二分定位（在可疑区间前后各放一个 checkpoint），锁定后用 `_CrtSetDbgFlag` + 分配序号断点抓现行
- `ASSERT_VALID(this)` 可以在长函数的关键步骤插桩，调试版里第一时间暴露悬空文档/视图指针

## 自测

1. **MFC 异常为什么继承 `CObject`？自定义异常必须实现哪个函数？**
   —— 纳入 `CRuntimeClass` 体系，宏里的 `IsKindOf` 校验、`Dump`/`AssertValid` 才可用。自定义异常应重写 `GetErrorMessage`——基类版本只返回 FALSE，不实现就没有可读的错误消息。

2. **MFC `TRY/CATCH` 宏和裸 C++ `catch` 捕获 `CException*` 时，释放责任有什么不同？**
   —— 宏展开带 `AFX_EXCEPTION_LINK` 哨兵，作用域结束自动 `Delete`（`m_bAutoDelete=TRUE` 时）；裸 `catch` 没有哨兵，必须自己调 `e->Delete()`（不要裸 `delete`，要尊重 autoDelete 标志）。

3. **`ASSERT` 和 `VERIFY` 的 release 行为差别是什么？各举一个正确用法。**
   —— `ASSERT` 整个表达式被编译掉（调用不发生）；`VERIFY` 保留求值、只丢断言。检查纯条件用 `ASSERT`；调用必须发生、顺带查返回值用 `VERIFY`。有副作用的调用绝不能放进 `ASSERT`。

4. **为什么本书示例里 `_CrtMemDifference` 永远返回 0？怎么让它真正工作？**
   —— 示例是 release 构建，`_Crt*` 在 release 的 crtdbg.h 里被 `#define` 成空宏。用 `/D_DEBUG /MDd` 重新构建（调试 CRT + `_DEBUG`），三段式快照对比和退出时自动 dump 才有实际数据。

5. **`catch (CException* e)` 接得住 `std::bad_alloc` 吗？应该怎么兜底？**
   —— 接不住——标准异常不是 `CException`。MFC 代码的边界层加 `catch (...)` 打日志兜底，或者干脆统一自己代码的异常体系，别两套混抛。

---
上一章：[20 多线程与后台任务](20-threads.md) ｜ 下一章：[22 现代绘图：GDI+ 与 Direct2D](22-modern-drawing.md)
