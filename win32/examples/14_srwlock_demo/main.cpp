// 14_srwlock_demo — SRWLock（读写锁）+ 条件变量：生产者/消费者示例
//
// 对应教程：docs/08-进程与线程.md 第 8.8 节（现代同步原语）
// 编译：build.ps1 -File 14_srwlock_demo\main.cpp（控制台程序由 build.ps1 统一处理）
//
// 演示要点：
//   1. SRWLOCK / CONDITION_VARIABLE 的静态初始化（无需 Initialize/Destroy）
//   2. 写者持独占锁入队，读者持共享锁读计数、持独占锁出队
//   3. SleepConditionVariableSRW 的标准姿势：放锁 + 睡，醒来后必须 while 复查条件
//   4. 与 CRITICAL_SECTION 相比：SRWLock 支持多读者并发，读多写少时吞吐更高

#include <windows.h>
#include <stdio.h>
#include <locale.h>

// 静态初始化，不需要运行期 Initialize/Destroy 配对
static SRWLOCK          g_lock = SRWLOCK_INIT;
static CONDITION_VARIABLE g_itemReady = CONDITION_VARIABLE_INIT;

static int  g_queue[16];
static int  g_head = 0;     // 消费位置
static int  g_tail = 0;     // 生产位置（g_head==g_tail 表示空）
static bool g_producerDone = false;

static DWORD WINAPI Producer(LPVOID) {
    for (int i = 1; i <= 8; ++i) {
        Sleep(120);   // 模拟生产耗时

        AcquireSRWLockExclusive(&g_lock);
        g_queue[g_tail % 16] = i;
        ++g_tail;
        wprintf(L"[生产者] 入队 %d（队列长度 %d）\n", i, g_tail - g_head);
        ReleaseSRWLockExclusive(&g_lock);

        WakeConditionVariable(&g_itemReady);   // 叫醒一个等待的消费者
    }

    AcquireSRWLockExclusive(&g_lock);
    g_producerDone = true;
    ReleaseSRWLockExclusive(&g_lock);
    WakeAllConditionVariable(&g_itemReady);    // 通知所有消费者"收工"
    return 0;
}

static DWORD WINAPI Consumer(LPVOID param) {
    int id = (int)(INT_PTR)param;

    for (;;) {
        AcquireSRWLockExclusive(&g_lock);
        while (g_head == g_tail && !g_producerDone) {
            // ★ 标准四步：持锁进入 → while 复查（防虚假唤醒）→ 原子放锁并睡眠 → 醒来重查
            SleepConditionVariableSRW(&g_itemReady, &g_lock, INFINITE, 0);
        }
        if (g_head == g_tail) {                // 队列空且生产者已收工
            ReleaseSRWLockExclusive(&g_lock);
            wprintf(L"[消费者 %d] 队列空且生产结束，退出\n", id);
            return 0;
        }
        int item = g_queue[g_head % 16];
        ++g_head;
        ReleaseSRWLockExclusive(&g_lock);

        wprintf(L"[消费者 %d] 取出 %d\n", id, item);
        Sleep(200);   // 模拟消费耗时
    }
}

int wmain() {
    _wsetlocale(LC_ALL, L"");   // 让中文能正常输出到控制台

    HANDLE hProducer = CreateThread(nullptr, 0, Producer, nullptr, 0, nullptr);
    HANDLE hConsumer1 = CreateThread(nullptr, 0, Consumer, (LPVOID)(INT_PTR)1, 0, nullptr);
    HANDLE hConsumer2 = CreateThread(nullptr, 0, Consumer, (LPVOID)(INT_PTR)2, 0, nullptr);

    HANDLE threads[] = { hProducer, hConsumer1, hConsumer2 };
    WaitForMultipleObjects(3, threads, TRUE, INFINITE);   // TRUE = 等全部结束

    for (HANDLE h : threads) {
        CloseHandle(h);
    }

    // 对照提示：CRITICAL_SECTION 版本（examples/11_thread_sync_demo）读写不分；
    // 若消费逻辑只需"读"统计值，可改用 AcquireSRWLockShared 允许多读者并发。
    wprintf(L"演示结束\n");
    return 0;
}
