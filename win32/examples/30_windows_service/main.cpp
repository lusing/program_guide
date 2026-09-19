// 30_windows_service — 最小服务 + 事件日志 + 控制台/list 双模式
//
// 对应教程：docs/27-Windows服务与事件日志.md
// 控制台程序；console/list 模式标准用户可跑；install/remove/start/stop 需管理员
#include <windows.h>
#include <stdio.h>
#include <locale.h>

static const wchar_t* kSvcName = L"GuideDemoSvc";
static const wchar_t* kSvcDisplay = L"Guide Win32 教程演示服务";

static SERVICE_STATUS        g_status = {};
static SERVICE_STATUS_HANDLE g_statusHandle = nullptr;
static HANDLE g_stopEvent = nullptr;

static void ReportState(DWORD state, DWORD waitHint = 0) {
    g_status.dwCurrentState = state;
    g_status.dwWaitHint = waitHint;
    g_status.dwCheckPoint = (state == SERVICE_START_PENDING) ? 1 : 0;
    SetServiceStatus(g_statusHandle, &g_status);
}

static void LogEvent(WORD type, const wchar_t* msg) {
    HANDLE hLog = RegisterEventSourceW(nullptr, kSvcName);
    if (hLog) {
        const wchar_t* strings[] = { msg };
        ReportEventW(hLog, type, 0, 1, nullptr, 1, 0, strings, nullptr);
        DeregisterEventSource(hLog);
    }
}

// 服务主体：真正"干活"的循环（服务/控制台共用，便于先本地验证）
static void RunServiceCore(bool asService) {
    int tick = 0;
    while (WaitForSingleObject(g_stopEvent, 1000) == WAIT_TIMEOUT) {
        wchar_t buf[128];
        swprintf_s(buf, L"第 %d 次心跳（%s模式）", ++tick,
                   asService ? L"服务" : L"控制台");
        if (asService) LogEvent(EVENTLOG_INFORMATION_TYPE, buf);
        else           wprintf(L"    %s\n", buf);
        if (!asService && tick >= 3) break;   // 控制台模式 3 拍即收
    }
}

static DWORD WINAPI HandlerEx(DWORD control, DWORD, LPVOID, LPVOID) {
    if (control == SERVICE_CONTROL_STOP) {
        ReportState(SERVICE_STOP_PENDING, 2000);
        SetEvent(g_stopEvent);                // 通知主循环退出
    }
    return NO_ERROR;
}

static void WINAPI ServiceMain(DWORD, LPWSTR*) {
    g_statusHandle = RegisterServiceCtrlHandlerExW(kSvcName, HandlerEx, nullptr);
    if (!g_statusHandle) return;

    g_status.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
    g_status.dwControlsAccepted = SERVICE_ACCEPT_STOP;
    ReportState(SERVICE_START_PENDING, 2000);

    g_stopEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    ReportState(SERVICE_RUNNING);
    LogEvent(EVENTLOG_INFORMATION_TYPE, L"服务已启动");

    RunServiceCore(true);                     // 阻塞到收到停止

    ReportState(SERVICE_STOPPED);
    LogEvent(EVENTLOG_INFORMATION_TYPE, L"服务已停止");
    CloseHandle(g_stopEvent);
}

static int Install() {
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CREATE_SERVICE);
    if (!scm) {
        wprintf(L"OpenSCManager 失败 %lu（需要管理员）\n", GetLastError());
        return 1;
    }
    wchar_t path[MAX_PATH];
    GetModuleFileNameW(nullptr, path, MAX_PATH);
    SC_HANDLE svc = CreateServiceW(scm, kSvcName, kSvcDisplay,
        SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS, SERVICE_DEMAND_START,
        SERVICE_ERROR_NORMAL, path, nullptr, nullptr, nullptr, nullptr, nullptr);
    if (!svc) {
        wprintf(L"CreateService 失败 %lu\n", GetLastError());
        CloseServiceHandle(scm);
        return 1;
    }
    wprintf(L"已安装 %s（手动启动）。管理员执行：30_windows_service.exe start\n", kSvcName);
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 0;
}

static int RemoveSvc() {
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ALL_ACCESS);
    SC_HANDLE svc = scm ? OpenServiceW(scm, kSvcName, DELETE) : nullptr;
    if (!svc) {
        wprintf(L"打开服务失败（不存在或需要管理员）\n");
        if (scm) CloseServiceHandle(scm);
        return 1;
    }
    DeleteService(svc);
    wprintf(L"已标记删除 %s\n", kSvcName);
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 0;
}

static int StartSvc() {
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ALL_ACCESS);
    SC_HANDLE svc = scm ? OpenServiceW(scm, kSvcName, SERVICE_START) : nullptr;
    if (!svc) {
        wprintf(L"打开服务失败（未安装或需要管理员）\n");
        if (scm) CloseServiceHandle(scm);
        return 1;
    }
    BOOL ok = StartServiceW(svc, 0, nullptr);
    wprintf(L"%s\n", ok ? L"已发出启动请求" : L"启动失败（可能已在运行）");
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return ok ? 0 : 1;
}

static int StopSvc() {
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ALL_ACCESS);
    SC_HANDLE svc = scm ? OpenServiceW(scm, kSvcName, SERVICE_STOP) : nullptr;
    if (!svc) {
        wprintf(L"打开服务失败（未安装或需要管理员）\n");
        if (scm) CloseServiceHandle(scm);
        return 1;
    }
    SERVICE_STATUS st = {};
    ControlService(svc, SERVICE_CONTROL_STOP, &st);
    wprintf(L"已发出停止请求\n");
    CloseServiceHandle(svc);
    CloseServiceHandle(scm);
    return 0;
}

static int ListServices() {   // 只需要枚举权限，标准用户可跑
    SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ENUMERATE_SERVICE);
    if (!scm) {
        wprintf(L"OpenSCManager 失败 %lu\n", GetLastError());
        return 1;
    }
    DWORD need = 0, count = 0, resume = 0;
    EnumServicesStatusW(scm, SERVICE_WIN32_OWN_PROCESS, SERVICE_STATE_ALL,
                        nullptr, 0, &need, &count, &resume);
    need += 4096;
    LPENUM_SERVICE_STATUSW buf = (LPENUM_SERVICE_STATUSW)LocalAlloc(LMEM_FIXED, need);
    if (!EnumServicesStatusW(scm, SERVICE_WIN32_OWN_PROCESS, SERVICE_STATE_ALL,
                             buf, need, &need, &count, &resume)) {
        wprintf(L"EnumServicesStatus 失败 %lu\n", GetLastError());
        LocalFree(buf);
        CloseServiceHandle(scm);
        return 1;
    }
    wprintf(L"系统内自有进程服务共 %lu 个，前 8 个：\n", (unsigned long)count);
    for (DWORD i = 0; i < count && i < 8; ++i) {
        wprintf(L"    %-24s [%s]\n", buf[i].lpServiceName,
                buf[i].ServiceStatus.dwCurrentState == SERVICE_RUNNING
                    ? L"运行中" : L"未运行");
    }
    LocalFree(buf);
    CloseServiceHandle(scm);
    return 0;
}

int wmain(int argc, wchar_t** argv) {
    _wsetlocale(LC_ALL, L"");
    if (argc >= 2) {
        if (wcscmp(argv[1], L"install") == 0) return Install();
        if (wcscmp(argv[1], L"remove")  == 0) return RemoveSvc();
        if (wcscmp(argv[1], L"start")   == 0) return StartSvc();
        if (wcscmp(argv[1], L"stop")    == 0) return StopSvc();
        if (wcscmp(argv[1], L"list")    == 0) return ListServices();
        if (wcscmp(argv[1], L"console") == 0) {
            g_stopEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
            wprintf(L"控制台模式：服务逻辑就地跑 3 拍（无需安装验证）\n");
            RunServiceCore(false);
            CloseHandle(g_stopEvent);
            return 0;
        }
    }
    // 无参数：由 SCM 调度（用户直接双击会得到提示）
    SERVICE_TABLE_ENTRYW table[] = {
        { (LPWSTR)kSvcName, ServiceMain }, { nullptr, nullptr }
    };
    if (!StartServiceCtrlDispatcherW(table)) {
        wprintf(L"可用动词：console / list / install / remove / start / stop\n");
        return 1;
    }
    return 0;
}
