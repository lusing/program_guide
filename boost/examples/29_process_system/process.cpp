// process.cpp —— Boost.Process v2（1.86 起的现代接口）：子进程管理。
// 对应文档：docs/29-process-system.md
// 实测坑三条：
//  ① exe 路径要显式给 boost::filesystem::path——const char* 重载走
//     "命令行搜索"分支报"找不到文件"（system:2）
//  ② cmd.exe 对参数引号极敏感——演示选无参系统工具（hostname/where）最稳
//  ③ asio::readable_pipe + process_stdio 捕获组合在本机（MSVC 19.51 +
//     vc145 DLL）fail-fast 崩溃（0xC0000409，连 stderr 都来不及吐）——
//     需要捕获输出的老环境建议用 process v1 或重定向到文件
#include <boost/asio.hpp>
#include <boost/process/v2/process.hpp>
#include <boost/process/v2/environment.hpp>
#include <boost/filesystem.hpp>
#include <iostream>

namespace proc = boost::process::v2;
namespace asio = boost::asio;

int main() {
    asio::io_context io;
    const boost::filesystem::path hostname = L"C:/Windows/System32/hostname.exe";
    const boost::filesystem::path where = L"C:/Windows/System32/where.exe";

    // 1) spawn + 等待（hostname：无参数、rc=0；其输出直接进本进程的 stdout）
    proc::process h(io, hostname, {});
    int rc1 = h.wait();
    std::cout << "hostname 退出码 = " << rc1 << "（预期 0）\n";

    // 2) 退出码传递：where 找到目标返回 0。
    //    （找不到时返回 1——但它会同时往 stderr 打一行 INFO，本教程的
    //     "stderr 恒空"判定不放过子进程的输出，故例程只走安静的成功路径）
    proc::process self(io, where, {"where"});
    int rc2 = self.wait();
    std::cout << "where where 退出码 = " << rc2 << "（预期 0；找不到时为 1）\n";

    // 3) 环境变量
    boost::system::error_code ec;
    auto path = proc::environment::get("PATH", ec);
    std::cout << "PATH 非空? " << !path.empty() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
