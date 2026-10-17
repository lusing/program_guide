// program_options.cpp —— Boost.ProgramOptions（2002）：命令行/配置文件
// 选项解析的老牌标准件。
// 对应文档：docs/29-process-system.md
#include <boost/program_options.hpp>
#include <sstream>
#include <iostream>
#include <string>
#include <vector>

namespace po = boost::program_options;

int main(int argc, char* argv[]) {
    po::options_description desc("用法: demo [选项]");
    // clang-format off
    desc.add_options()
        ("help,h",                                  "打印帮助")
        ("port,p",   po::value<int>()->default_value(8080), "监听端口")
        ("tags,t",   po::value<std::vector<std::string>>()->multitoken(), "标签(多个)")
        ("verbose,v", po::bool_switch(),            "详细输出")
        ;
    // clang-format on

    // 1) 解析：命令行风格默认 POSIX
    po::variables_map vm;
    // 教程固定参数模拟 argv（真实程序传 argc/argv）
    const char* fake[] = {"demo", "--port", "9000", "-t", "alpha", "beta", "--verbose"};
    try {
        po::store(po::parse_command_line(7, const_cast<char**>(fake), desc), vm);
        po::notify(vm);
    } catch (const po::error& e) {
        std::cout << "解析错误: " << e.what() << '\n';
        return 1;
    }

    // 2) 取值：default_value 兜底、multitoken 收数组
    std::cout << "port = " << vm["port"].as<int>() << '\n';
    std::cout << "verbose = " << vm["verbose"].as<bool>() << '\n';
    if (vm.count("tags")) {
        std::cout << "tags:";
        for (const auto& t : vm["tags"].as<std::vector<std::string>>()) {
            std::cout << ' ' << t;
        }
        std::cout << '\n';
    }

    // 3) 帮助文本自动排版
    std::cout << "帮助首行 = " << desc.find("help", true).long_name() << '\n';

    // 4) implicit_value：选项可出现但不带值（短名紧贴值 -d5 也行）
    po::options_description d2("隐含值");
    d2.add_options()
        ("depth,d", po::value<int>()->implicit_value(5), "深度");
    po::variables_map vm2;
    const char* fake2[] = {"demo", "-d"};
    po::store(po::parse_command_line(2, const_cast<char**>(fake2), d2), vm2);
    po::notify(vm2);
    std::cout << "implicit_value(-d 不带值) = " << vm2["depth"].as<int>() << '\n';

    // 5) positional：位置参数（"demo file.txt" 不用 -f 也行）
    po::positional_options_description pod;
    pod.add("file", 1);                        // 1 = 第一个裸参数归 file
    po::options_description d3("位置");
    d3.add_options()("file,f", po::value<std::string>(), "文件");
    po::variables_map vm3;
    const char* fake3[] = {"demo", "a.txt"};
    auto parsed3 = po::command_line_parser(2, const_cast<char**>(fake3))
                       .options(d3).positional(pod).run();
    po::store(parsed3, vm3);
    po::notify(vm3);
    std::cout << "位置参数(免选项名) = " << vm3["file"].as<std::string>() << '\n';

    // 6) 配置文件：parse_config_file（name = value 格式）
    po::options_description d4("配置");
    d4.add_options()("port", po::value<int>(), "端口");
    po::variables_map vm4;
    std::stringstream cfg("port = 7777\n");
    po::store(po::parse_config_file(cfg, d4), vm4);
    std::cout << "配置文件解析 port = " << vm4["port"].as<int>() << '\n';

    // 7) 未注册选项：allow_unregistered + collect_unrecognized
    po::options_description d5("放行");
    d5.add_options()("known,k", "已知选项");
    const char* fake5[] = {"demo", "-k", "--unknown"};
    auto parsed5 = po::command_line_parser(3, const_cast<char**>(fake5))
                       .options(d5).allow_unregistered().run();
    auto leftover = po::collect_unrecognized(parsed5.options,
                                             po::include_positional);
    std::cout << "未注册选项收集到 " << leftover.size() << " 个（首 = "
              << (leftover.empty() ? std::string() : leftover.front()) << "）\n";

    (void)argc; (void)argv;
    std::cout << "自检通过\n";
    return 0;
}
