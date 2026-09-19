// program_options.cpp —— Boost.ProgramOptions（2002）：命令行/配置文件
// 选项解析的老牌标准件。
// 对应文档：docs/29-process-system.md
#include <boost/program_options.hpp>
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
    (void)argc; (void)argv;
    std::cout << "自检通过\n";
    return 0;
}
