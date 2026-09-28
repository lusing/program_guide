// 37_seh_toolkit —— 第 3 章：SEH 三部曲现场演示
// ① __try/__finally 与 __leave  ② 过滤器分诊 + 异常现场(EXCEPTION_POINTERS)
// ③ 软件异常 RaiseException   ④ 栈溢出的一次性恢复（独立线程）
// ⑤ 未处理异常过滤器（装在最后，触发后进程以 77 退出）
#include <windows.h>
#include <stdio.h>

// ---------- ②/③ 统一分诊过滤器：GetExceptionInformation 的用法 ----------
static LONG Classify(EXCEPTION_POINTERS* ep) {
    DWORD code = ep->ExceptionRecord->ExceptionCode;
    const char* what = "未知异常";
    if (code == STATUS_ACCESS_VIOLATION)      what = "访问违例（读写非法地址）";
    else if (code == STATUS_INTEGER_DIVIDE_BY_ZERO) what = "整数除零";
    else if (code == 0xE0000001)              what = "应用自定义软件异常";

    printf("  [过滤器] code=%08lX (%s) 事发 RIP=%p",
           code, what, (void*)ep->ContextRecord->Rip);
    if (code == STATUS_ACCESS_VIOLATION)      // 访问违例的参数[0]=读/写 [1]=目标地址
        printf("  %s地址 %p",
               ep->ExceptionRecord->ExceptionInformation[0] ? "写" : "读",
               (void*)ep->ExceptionRecord->ExceptionInformation[1]);
    printf("\n");
    return EXCEPTION_EXECUTE_HANDLER;
}

static int GuardedDiv(int a, int b, BOOL* ok) {   // C2712 规避：SEH 独立小函数
    __try { *ok = TRUE;  return a / b; }
    __except (Classify(GetExceptionInformation())) { *ok = FALSE; return -1; }
}

static int GuardedRead(volatile int* p, BOOL* ok) {
    __try { *ok = TRUE;  return *p; }
    __except (Classify(GetExceptionInformation())) { *ok = FALSE; return -1; }
}

// ---------- ① finally：无论怎么出去都会执行 ----------
static void DemoFinally() {
    printf("① __try/__finally：\n");
    for (int exitKind = 0; exitKind < 2; ++exitKind) {
        printf("  - 出口=%s -> ", exitKind ? "提前 return" : "__leave");
        __try {
            if (exitKind == 0) __leave;            // 零成本跳到 finally
            return;                                // 触发局部展开（贵），finally 仍执行
        }
        __finally {
            printf("finally 执行（AbnormalTermination=%d）\n", AbnormalTermination());
        }
    }
}

// ---------- ③ 软件异常 ----------
constexpr DWORD MYAPP_ERR_PARSE = 0xE0000001;

static void DoParse() { RaiseException(MYAPP_ERR_PARSE, EXCEPTION_NONCONTINUABLE, 0, nullptr); }

static void DemoFilterAndSoftware() {
    printf("② 过滤器分诊 + 异常现场：\n");
    BOOL ok;
    GuardedRead((volatile int*)0x00000010, &ok);          // 空指针读
    printf("  -> GuardedRead 结果 ok=%d\n", ok);

    int q = GuardedDiv(10, 0, &ok);                       // 除零
    printf("  -> GuardedDiv 结果 ok=%d 值=%d\n", ok, q);

    printf("③ 软件异常 RaiseException：\n");
    __try { DoParse(); }
    __except (Classify(GetExceptionInformation())) { printf("  -> 捕获自定义异常\n"); }
}

// ---------- ④ 栈溢出：每线程只有一次优雅机会 ----------
static DWORD WINAPI SumThread(LPVOID n) {
    unsigned sum = 0;
    __try {
        // 深递归吃栈：只有放在独立线程里才安全（主线程栈崩了全完）
        struct R { static unsigned Go(unsigned x, int d) { volatile char pad[1024]; pad[0] = 1; return x + Go(x, d + 1); } };
        sum = R::Go(1, 0);
    }
    __except (GetExceptionCode() == STATUS_STACK_OVERFLOW
                  ? EXCEPTION_EXECUTE_HANDLER : EXCEPTION_CONTINUE_SEARCH) {
        printf("④ 栈溢出：EXCEPTION_STACK_OVERFLOW 被捕获（0xC00000FD），线程优雅退出\n");
        return UINT_MAX;                                  // 告诉父线程：栈爆了
    }
    return sum;
}

// ---------- ⑤ 未处理异常过滤器（进程级兜底） ----------
static LONG WINAPI LastWords(EXCEPTION_POINTERS* ep) {
    printf("⑤ 未处理异常过滤器：code=%08lX RIP=%p —— 现场已记录，进程将退出\n",
           ep->ExceptionRecord->ExceptionCode, (void*)ep->ContextRecord->Rip);
    return EXCEPTION_EXECUTE_HANDLER;                     // 之后进程终止，退出码 77
}

static DWORD WINAPI CrashThread(LPVOID) {
    Sleep(200);                                           // 确保主线程的提示先打印
    volatile int* p = nullptr; *p = 1;                    // 未捕获 → 走 LastWords
    return 0;
}

int wmain() {
    setvbuf(stdout, nullptr, _IONBF, 0);   // 崩溃收尾路径也要能刷出已打印的内容
    DemoFinally();
    DemoFilterAndSoftware();

    HANDLE h = CreateThread(nullptr, 0, SumThread, nullptr, 0, nullptr);
    WaitForSingleObject(h, INFINITE);
    DWORD rc = 0; GetExitCodeThread(h, &rc);
    printf("  -> SumThread 退出码 %s\n", rc == UINT_MAX ? "UINT_MAX（确认爆栈后优雅退出）" : "(正常)");
    CloseHandle(h);

    SetUnhandledExceptionFilter(LastWords);
    printf("即将触发未处理异常（观察上面 ⑤ 的输出）……\n");
    HANDLE c = CreateThread(nullptr, 0, CrashThread, nullptr, 0, nullptr);
    WaitForSingleObject(c, INFINITE);
    // 通常到不了这里：过滤器返回后进程就终止了
    return 0;
}
