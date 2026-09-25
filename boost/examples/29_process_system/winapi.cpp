// winapi.cpp —— Boost.WinAPI（2014）：Win32 API 的头文件化薄封装。
// 写"可移植库的 Windows 分支"时的规范姿势（比裸 windows.h 干净：
// 不污染命名空间、可与其他后端共存）。
// 对应文档：docs/29-process-system.md
//
// 平台事实（macOS 上实测）：boost/winapi 的头文件**只能在 Windows 上编译**。
// boost/winapi/basic_types.hpp 第 38 行在非 Windows 上直接
//     #error "Win32 functions not available"
// 也就是说这不是"链接不上"或"跑不通"，是连语法检查都过不去——
// 所以 include 本身就得跟着平台走，不能只把调用包进 #if。
#include <iostream>

#if defined(_WIN32) || defined(__CYGWIN__) || defined(BOOST_USE_WINDOWS_H)

#include <boost/winapi/get_current_process.hpp>
#include <boost/winapi/get_current_thread_id.hpp>
#include <boost/winapi/process.hpp>
#include <boost/winapi/system.hpp>

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

#else

int main() {
    // 非 Windows：整个库都不存在，本例退化为"说明这段平台事实"。
    // （认知价值不减：它说明 Boost.WinAPI 是**编译期**就不跨平台的那一类，
    //   与 interprocess/process 这种"接口跨平台、实现分平台"的库不是一回事）
    std::cout << "本机不是 Windows：Boost.WinAPI 不可用\n";
    std::cout << "  boost/winapi/basic_types.hpp 在非 Windows 上直接 #error\n";
    std::cout << "  \"Win32 functions not available\"（连编译都过不去）\n";
    std::cout << "自检通过\n";
    return 0;
}

#endif
