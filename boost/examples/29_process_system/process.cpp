// process.cpp —— Boost.Process v2（1.86 起的现代接口）：子进程管理。
// 对应文档：docs/29-process-system.md
// 实测坑三条（Windows 侧）+ 两条（跨平台改造时新踩的）：
//  ① exe 路径要显式给 boost::filesystem::path——const char* 重载走
//     "命令行搜索"分支报"找不到文件"（system:2）
//  ② 演示别挑对参数敏感的系统工具（cmd.exe 的引号规则本身就是一个坑），
//     选无参工具最稳
//  ③ asio::readable_pipe + process_stdio 捕获组合在本机（MSVC 19.51 +
//     vc145 DLL）fail-fast 崩溃（0xC0000409，连 stderr 都来不及吐）——
//     需要捕获输出的老环境建议用 process v1 或重定向到文件
//  ④ 【跨平台】exe 路径**不能写死** C:/Windows/System32/hostname.exe ——
//     换到 macOS/Linux 连文件都没有。用 find_executable("hostname")
//     按 PATH 找：Windows 与 Unix 都有这个同名工具
//  ⑤ 【跨平台】"退出码传递"别去撞系统工具的失败分支：hostname 遇到非法
//     参数会往 stderr 打一行，本教程的"stderr 恒空"判定不放过子进程的输出。
//     改成跑自己：带 --exit-3 参数时直接 return 3，安静、可控、跨平台
#include <boost/asio.hpp>
#include <boost/process/v2/process.hpp>
#include <boost/process/v2/environment.hpp>
#include <boost/filesystem.hpp>
#include <iostream>
#include <string_view>

namespace proc = boost::process::v2;
namespace asio = boost::asio;

int main(int argc, char** argv) {
    // 子模式：被自己以 --exit-3 调用时直接返回 3（退出码传递演示用）
    if (argc > 1 && std::string_view(argv[1]) == "--exit-3") {
        return 3;
    }

    asio::io_context io;

    // 1) spawn + 等待（hostname：无参数、rc=0；其输出直接进本进程的 stdout）
    const boost::filesystem::path hostname =
        proc::environment::find_executable("hostname");
    std::cout << "找到 hostname? " << !hostname.empty() << '\n';
    if (hostname.empty()) {
        std::cout << "PATH 里没有 hostname，跳过子进程演示\n";
    } else {
        proc::process h(io, hostname, {});
        int rc1 = h.wait();
        std::cout << "hostname 退出码 = " << rc1 << "（预期 0）\n";
    }

    // 2) 退出码传递：让 fork 出去的那个"自己"退成 3
    const boost::filesystem::path self = boost::filesystem::absolute(argv[0]);
    proc::process child(io, self, {"--exit-3"});
    int rc2 = child.wait();
    std::cout << "自己 --exit-3 退出码 = " << rc2 << "（预期 3）\n";

    // 3) 环境变量
    boost::system::error_code ec;
    auto path = proc::environment::get("PATH", ec);
    std::cout << "PATH 非空? " << !path.empty() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
