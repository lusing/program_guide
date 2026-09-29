// 43_cross_process —— 第 35 章：跨进程内存读写 + 低级键盘钩子
// 三模式单 exe：
//   无参数   = 修改器：CreateProcess 起自己的 -target 靶子，VirtualQueryEx 行走地址空间、
//              扫描 8 字节哨兵、等靶子自己改值后迭代收窄到唯一、WriteProcessMemory 改写、
//              靶子回报确认（张铮《Windows程序设计》"游戏内存修改器"的自动化复刻）
//   -target  = 靶子：四个哨兵变量定时漂移，被改写时打印确认并退出
//   -hook    = WH_KEYBOARD_LL 低级键盘钩子自观测 6 秒（免 DLL 的现代钩子写法）
// 验证：直接运行看全链路输出；-hook 单独跑看安装/卸载。
#include <windows.h>
#include <stdio.h>

// ---------- 靶子与修改器的约定 ----------
// 哨兵值由靶子在运行时随机生成（不写任何字面常量——否则常量会进自己的映像，
// 扫描时会冒出"永不变化的假命中"，本项目第一版正是这样翻车的）。
// 修改器从靶子的标准输出里解析它看到的值——就像玩家从游戏画面上读金钱数。
static const ULONGLONG GOLD_FINAL = 0x00DEADBEEFCAFE00ULL;   // 修改器最终写入的值（在修改器映像里，无害）

// ============ 靶子模式：把值摆在内存里，等着被找到、被改写 ============
static int RunTarget() {
    // 五个同值来源：三个全局 + 一个堆 + 一个栈。值 v0 运行时生成。
    // 第 4 拍"游戏逻辑"把金库花掉一些（v1 = v0 - 0x100）——真实修改器正是
    // 靠"重扫变化后的新值、并与旧地址列表求交"来收窄（张铮 FindNext 的语义）。
    // 诱饵们从第 5/8 拍起各自漂移成别的值，永远变不成 v1。
    ULONGLONG v0 = 0x0010000000000000ULL | (GetTickCount64() & 0xFFFF);
    ULONGLONG v1 = v0 - 0x100;
    static volatile ULONGLONG g_gold, g_decoy1, g_decoy2;
    volatile ULONGLONG on_stack;
    g_gold = v0; g_decoy1 = v0; g_decoy2 = v0; on_stack = v0;
    ULONGLONG* on_heap = (ULONGLONG*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, 4096);
    *on_heap = v0;

    printf("[靶子] PID=%lu\n", GetCurrentProcessId());
    printf("[靶子] 屏幕上显示：金钱 V=0x%016llx\n", (unsigned long long)v0);
    printf("[靶子] 变量布局（玩家看不到，扫描器更看不到）：\n");
    printf("  金库   g_gold   @ %p（第 4 拍花钱变 v1）\n", (void*)&g_gold);
    printf("  诱饵 1 g_decoy1 @ %p（第 5 拍起漂移）\n", (void*)&g_decoy1);
    printf("  诱饵 2 g_decoy2 @ %p（第 8 拍起漂移）\n", (void*)&g_decoy2);
    printf("  诱饵 3 on_stack @ %p（第 5 拍起漂移）\n", (void*)&on_stack);
    printf("  诱饵 4 on_heap  @ %p（第 8 拍起漂移）\n", (void*)on_heap);

    for (int tick = 1; tick <= 60; ++tick) {
        if (tick == 4) {
            g_gold = v1;
            printf("[靶子] 屏幕上显示：金钱 V=0x%016llx（花掉了一点）\n", (unsigned long long)v1);
        }
        if (tick > 5) { g_decoy1 = v0 + (ULONGLONG)tick; on_stack = v0 ^ (ULONGLONG)tick; }
        if (tick > 8) { g_decoy2 = v0 + (ULONGLONG)tick * 2; *on_heap = v0 ^ 0x5555ULL; }
        if (g_gold != v0 && g_gold != v1) {          // 值既不是初值也不是自己改的——被外部改写
            printf("[靶子] 检测到金库被改写：0x%016llx -> 0x%016llx（跨进程写入成功！）\n",
                   (unsigned long long)v1, (unsigned long long)g_gold);
            HeapFree(GetProcessHeap(), 0, on_heap);
            return 0;
        }
        Sleep(500);
    }
    printf("[靶子] 超时未被改写，退出\n");
    HeapFree(GetProcessHeap(), 0, on_heap);
    return 1;
}

// ============ 修改器：扫描 → 收窄 → 改写 三部曲 ============

// 按值扫描：VirtualQueryEx 行走靶子地址空间，只读"已提交且可读"的区域
static int ScanForValue(HANDLE hProc, ULONGLONG value, ULONGLONG* hits, int maxHits) {
    int nHits = 0;
    MEMORY_BASIC_INFORMATION mbi;
    ULONGLONG addr = 0x10000;                        // 前 64KB 永不可提交
    while (VirtualQueryEx(hProc, (LPCVOID)addr, &mbi, sizeof(mbi)) == sizeof(mbi)) {
        ULONGLONG regionEnd = (ULONGLONG)mbi.BaseAddress + mbi.RegionSize;
        BOOL readable =
            mbi.State == MEM_COMMIT &&
            !(mbi.Protect & PAGE_GUARD) &&
            (mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                            PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE));
        if (readable && mbi.RegionSize >= sizeof(ULONGLONG)) {
            SIZE_T size = mbi.RegionSize;
            ULONGLONG* buf = (ULONGLONG*)HeapAlloc(GetProcessHeap(), 0, size);
            SIZE_T got = 0;
            if (buf && ReadProcessMemory(hProc, mbi.BaseAddress, buf, size, &got)) {
                for (SIZE_T i = 0; i + 1 <= got / sizeof(ULONGLONG); ++i) {
                    if (buf[i] == value) {
                        if (nHits < maxHits) hits[nHits] = (ULONGLONG)mbi.BaseAddress + i * sizeof(ULONGLONG);
                        ++nHits;
                    }
                }
            }
            HeapFree(GetProcessHeap(), 0, buf);
        }
        addr = regionEnd;
        if (addr >= 0x00007FFFFFFEFFFF) break;       // x64 用户空间上限
    }
    return nHits;
}

// 修改器的"看屏幕"状态：转发线程从靶子输出里解析最新的 V= 值（volatile 供跨线程读）
static volatile ULONGLONG g_seenValue = 0;

// 在已排序的旧地址列表里二分查找（ScanForValue 按地址升序产出，天然有序）
static bool InList(const ULONGLONG* list, int n, ULONGLONG v) {
    int lo = 0, hi = n - 1;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (list[mid] == v) return true;
        if (list[mid] < v) lo = mid + 1; else hi = mid - 1;
    }
    return false;
}

static int RunModifier() {
    printf("=== 跨进程内存修改器（张铮《Windows程序设计》『游戏内存修改器』的自动化版） ===\n\n");

    // ① 起靶子：自己的 -target 模式，stdout 接管道由本进程转发（16 章的重定向手法）
    wchar_t exe[MAX_PATH];
    wchar_t cmd[MAX_PATH + 32];
    GetModuleFileNameW(nullptr, exe, MAX_PATH);
    swprintf_s(cmd, L"\"%ls\" -target", exe);

    SECURITY_ATTRIBUTES sa = { sizeof(sa), nullptr, TRUE };
    HANDLE pipeR = nullptr, pipeW = nullptr;
    CreatePipe(&pipeR, &pipeW, &sa, 0);
    SetHandleInformation(pipeR, HANDLE_FLAG_INHERIT, 0);   // 读端不遗传

    STARTUPINFOW si = { sizeof(si) };
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdOutput = pipeW; si.hStdError = pipeW; si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    PROCESS_INFORMATION pi = {};
    if (!CreateProcessW(exe, cmd, nullptr, nullptr, TRUE, CREATE_NO_WINDOW,
                        nullptr, nullptr, &si, &pi)) {
        printf("CreateProcess 失败 %lu\n", GetLastError());
        return 1;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pipeW);                              // 我们不留写端，靶子退出后管道断

    HANDLE hProc = pi.hProcess;                      // CreateProcess 直接给了(全权)句柄

    // 转发线程：把靶子的输出原样搬过来；顺带解析"金钱 V=0x…"行（= 玩家看屏幕）
    HANDLE hReader = CreateThread(nullptr, 0, [](LPVOID p) -> DWORD {
        HANDLE pipeR = (HANDLE)p;
        char line[512]; int len = 0; char ch; DWORD n = 0;
        while (ReadFile(pipeR, &ch, 1, &n, nullptr) && n) {   // 按字节读以便逐行解析
            if (ch != '\n' && len < (int)sizeof(line) - 1) { line[len++] = ch; continue; }
            line[len] = '\0'; len = 0;
            fputs(line, stdout); fputc('\n', stdout); fflush(stdout);
            ULONGLONG v = 0;
            if (sscanf_s(line, "[靶子] 屏幕上显示：金钱 V=0x%016llx", &v) == 1)
                g_seenValue = v;                     // 玩家看到了新数值
        }
        return 0;
    }, pipeR, 0, nullptr);

    // ② 等靶子亮出初值，第一次扫描
    while (g_seenValue == 0) Sleep(100);
    ULONGLONG v0 = g_seenValue;
    ULONGLONG hits1[256];
    int n1 = ScanForValue(hProc, v0, hits1, 256);
    printf("\n[修改器] 看到金钱 = 0x%016llx，第一次扫描：%d 处命中（5 个变量 + 零星巧合）\n",
           (unsigned long long)v0, n1);

    // ③ 等游戏逻辑花钱（值变化），扫新值并与旧地址列表求交——FindNext 的语义
    for (int guard = 0; g_seenValue == v0 && guard < 100; ++guard) Sleep(100);
    if (g_seenValue == v0) { printf("[修改器] 没等到值变化，演示中止\n"); TerminateProcess(hProc, 1); return 1; }
    ULONGLONG v1 = g_seenValue;
    Sleep(600);                                      // 等 printf 之外的诱饵漂移稳定
    ULONGLONG hits2[256];
    int n2 = ScanForValue(hProc, v1, hits2, 256);
    printf("[修改器] 看到金钱变为 0x%016llx，重扫 + 与旧列表求交：\n", (unsigned long long)v1);
    ULONGLONG final[256]; int nFinal = 0;
    for (int i = 0; i < n2 && nFinal < 256; ++i)
        if (InList(hits1, n1, hits2[i])) final[nFinal++] = hits2[i];
    printf("        新值 %d 处命中 ∩ 旧列表 %d 处 = %d 处%s\n", n2, n1, nFinal,
           nFinal == 1 ? "——收窄到唯一，这就是金库" : "");
    if (nFinal != 1) {
        printf("[修改器] 未收窄到唯一，演示中止（靶子已终止）\n");
        TerminateProcess(hProc, 1);
        return 1;
    }

    // ④ 改写：WriteProcessMemory 把金库换成最终值
    ULONGLONG gold = final[0];
    printf("[修改器] 对 %p 写入 0x%016llx ...\n", (void*)gold, (unsigned long long)GOLD_FINAL);
    SIZE_T written = 0;
    if (WriteProcessMemory(hProc, (LPVOID)gold, &GOLD_FINAL, sizeof(GOLD_FINAL), &written))
        printf("[修改器] 写入成功（%zu 字节）——等靶子确认 ...\n", written);
    else
        printf("[修改器] 写入失败 %lu\n", GetLastError());

    WaitForSingleObject(pi.hProcess, 15000);
    DWORD exitCode = 0; GetExitCodeProcess(pi.hProcess, &exitCode);
    printf("\n靶子退出码 %lu（0 = 它亲眼看到金库被改写）。\n", exitCode);
    printf("复盘：OpenProcess 拿句柄（本例句柄来自 CreateProcess）→ VirtualQueryEx 行走地址空间\n");
    printf("     → ReadProcessMemory 扫描 → 值变化后重扫求交收窄 → WriteProcessMemory 改写。\n");
    printf("     对系统/高完整性进程，第一步 OpenProcess 就会被拒——这就是边界（35.1 / 20 章）。\n");
    CloseHandle(pi.hProcess);
    WaitForSingleObject(hReader, 3000);
    CloseHandle(pipeR);
    CloseHandle(hReader);
    return 0;
}

// ============ 低级键盘钩子：免 DLL 的现代钩子（WH_KEYBOARD_LL） ============
static HHOOK g_hook = nullptr;

static LRESULT CALLBACK LowLevelKbProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION) {
        const KBDLLHOOKSTRUCT* k = (const KBDLLHOOKSTRUCT*)lParam;
        if (wParam == WM_KEYDOWN)
            printf("  [钩子] 按下 vk=0x%02lX%s%s\n", k->vkCode,
                   k->flags & LLKHF_INJECTED ? "（注入的）" : "",
                   k->flags & LLKHF_UP ? "（抬起）" : "");
    }
    return CallNextHookEx(g_hook, nCode, wParam, lParam);   // 钩子链纪律：永远传下去
}

static int RunHookDemo() {
    printf("=== WH_KEYBOARD_LL 低级键盘钩子自观测（6 秒） ===\n");
    printf("安装全局低级钩子（不需要 DLL，回调跑在本进程）……这 6 秒里随便敲键盘试试。\n");
    g_hook = SetWindowsHookExW(WH_KEYBOARD_LL, LowLevelKbProc, GetModuleHandleW(nullptr), 0);
    if (!g_hook) { printf("SetWindowsHookEx 失败 %lu\n", GetLastError()); return 1; }

    // 低级钩子的回调经由安装线程的消息队列投递——本线程必须泵消息（35.5 的关键纪律）
    DWORD start = GetTickCount64();
    MSG msg;
    while (GetTickCount64() - start < 6000) {
        while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
        Sleep(30);
    }
    UnhookWindowsHookEx(g_hook);
    printf("钩子已卸载。低级钩子回调在本进程执行、不注入任何 DLL——与老式 WH_KEYBOARD 全局钩子（必须 DLL）的区别见 35.4/35.5。\n");
    return 0;
}

int wmain(int argc, wchar_t** argv) {
    setvbuf(stdout, nullptr, _IONBF, 0);            // 靶子经管道转发 + 可能被强杀：无缓冲
    if (argc > 1 && wcscmp(argv[1], L"-target") == 0) return RunTarget();
    if (argc > 1 && wcscmp(argv[1], L"-hook") == 0) return RunHookDemo();
    return RunModifier();
}
