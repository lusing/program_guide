// winapi.cpp —— Boost.WinAPI（2014）：Win32 API 的头文件化薄封装。
// 写"可移植库的 Windows 分支"时的规范姿势（比裸 windows.h 干净：
// 不污染命名空间、可与其他后端共存）。
// 对应文档：docs/29-process-system.md
#include <boost/winapi/get_current_process.hpp>
#include <boost/winapi/get_current_thread_id.hpp>
#include <boost/winapi/process.hpp>
#include <boost/winapi/system.hpp>
#include <iostream>

int main() {
    // 1) 当前进程/线程身份
    boost::winapi::PROCESS_INFORMATION_ pseudo{};   // 结构体类型带下划线后缀
    (void)pseudo;
    boost::winapi::DWORD_ pid = boost::winapi::GetCurrentProcessId();
    boost::winapi::DWORD_ tid = boost::winapi::GetCurrentThreadId();
    std::cout << "PID = " << pid << " TID = " << tid << '\n';
    std::cout << "PID/TID 都非零? " << (pid != 0 && tid != 0) << '\n';

    // 2) 系统信息
    boost::winapi::SYSTEM_INFO_ info{};
    boost::winapi::GetSystemInfo(&info);
    std::cout << "逻辑处理器 = " << info.dwNumberOfProcessors << " 个\n";
    std::cout << "页大小 = " << info.dwPageSize << " 字节\n";

    // 3) 命名规律：API 同名（GetCurrentProcessId），类型/常量加 _ 后缀
    //    （DWORD_、HANDLE_、SYSTEM_INFO_）——类型安全的 windows.h 子集
    std::cout << "自检通过\n";
    return 0;
}
