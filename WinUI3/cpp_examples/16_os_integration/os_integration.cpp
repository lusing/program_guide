#include <windows.h>
#include <psapi.h>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

namespace winui3_guide::os_integration {

struct ProcessInfo {
    DWORD pid = 0;
    std::wstring image_name;
};

bool launch_notepad()
{
    STARTUPINFOW si{};
    PROCESS_INFORMATION pi{};

    std::wstring command = L"notepad.exe";
    BOOL ok = CreateProcessW(
        nullptr,
        command.data(),
        nullptr,
        nullptr,
        FALSE,
        0,
        nullptr,
        nullptr,
        &si,
        &pi);

    if (!ok) {
        return false;
    }

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return true;
}

std::vector<ProcessInfo> snapshot_processes()
{
    std::vector<ProcessInfo> processes;

    DWORD pids[1024] = {};
    DWORD needed = 0;
    if (!EnumProcesses(pids, sizeof(pids), &needed)) {
        return processes;
    }

    const DWORD count = needed / sizeof(DWORD);
    for (DWORD i = 0; i < count; ++i) {
        if (pids[i] == 0) {
            continue;
        }

        HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pids[i]);
        if (!process) {
            continue;
        }

        wchar_t buffer[MAX_PATH] = {};
        DWORD size = MAX_PATH;
        if (QueryFullProcessImageNameW(process, 0, buffer, &size)) {
            processes.push_back(ProcessInfo{ pids[i], buffer });
        }

        CloseHandle(process);
    }

    return processes;
}

void worker_task(std::vector<int>& data)
{
    for (int i = 0; i < 5; ++i) {
        data.push_back(i * 10);
    }
}

void demo_threading()
{
    std::vector<int> values;
    std::thread worker(worker_task, std::ref(values));
    worker.join();

    std::cout << "Thread produced: ";
    for (int value : values) {
        std::cout << value << ' ';
    }
    std::cout << '\n';
}

void CALLBACK fiber_work(void* param)
{
    auto* value = static_cast<int*>(param);
    *value += 1;
}

void demo_fiber()
{
    int value = 0;
    auto main_fiber = ConvertThreadToFiber(nullptr);
    auto worker_fiber = CreateFiber(0, fiber_work, &value);

    SwitchToFiber(worker_fiber);
    DeleteFiber(worker_fiber);
    ConvertFiberToThread();

    std::cout << "Fiber final value: " << value << '\n';
    (void)main_fiber;
}

} // namespace winui3_guide::os_integration

int main()
{
    bool ok = winui3_guide::os_integration::launch_notepad();
    std::cout << "Launch notepad: " << (ok ? "success" : "failed") << '\n';

    auto processes = winui3_guide::os_integration::snapshot_processes();
    std::cout << "Visible processes: " << processes.size() << '\n';

    winui3_guide::os_integration::demo_threading();
    winui3_guide::os_integration::demo_fiber();

    return 0;
}
