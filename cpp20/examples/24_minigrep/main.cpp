// 24 实战：迷你 grep —— 参数解析、目录递归、多线程搜索、高亮输出
#include "output.h"
#include "search.h"

#include <algorithm>
#include <atomic>
#include <cassert>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <print>
#include <string>
#include <thread>
#include <vector>

namespace fs = std::filesystem;

struct Options {
    fs::path dir;
    std::string pattern;
    bool ignore_case = false;
    int threads = 4;
};

// ═══ 24.1 参数解析：minigrep <dir> <pattern> [-i] [-t N] ═══
Options parse_args(int argc, char** argv) {
    if (argc < 3) {
        std::println("用法: minigrep <dir> <pattern> [-i] [-t N]");
        std::exit(2);
    }
    Options opt;
    opt.dir = argv[1];
    opt.pattern = argv[2];
    for (int i = 3; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-i") {
            opt.ignore_case = true;
        } else if (arg == "-t" && i + 1 < argc) {
            opt.threads = std::max(1, std::stoi(argv[++i]));
        }
    }
    return opt;
}

// ═══ 24.2 自检模式：内置样例目录验证核心行为（构建验证入口）═══
void run_self_test() {
    fs::path dir = fs::temp_directory_path() / "minigrep_selftest";
    fs::remove_all(dir);
    fs::create_directories(dir);
    {
        std::ofstream{dir / "alpha.txt"} << "normal line\n"
                                            "warning: disk almost full\n"
                                            "another WARNING here\n"
                                            "all good\n";
        std::ofstream{dir / "beta.md"} << "# notes\nthere is a Warning inside\n";
        std::ofstream{dir / "gamma.dat"} << "nothing to see\n";
    }
    auto hits_a = search_file(dir / "alpha.txt", "warning", true);
    auto hits_b = search_file(dir / "beta.md", "warning", true);
    auto hits_g = search_file(dir / "gamma.dat", "warning", true);
    assert(hits_a.size() == 2 && hits_a[0].line_no == 2 && hits_a[1].line_no == 3);
    assert(hits_b.size() == 1 && hits_b[0].line_no == 2);
    assert(hits_g.empty());
    assert(search_text("a\nbb\nabc\n", "ab", false).size() == 1);  // 恰好整段匹配
    fs::remove_all(dir);
    std::println("minigrep 自检通过");
}

// ═══ 24.3 多线程搜索：原子游标瓜分文件列表（线程池的极简形态）═══
int search_directory(const Options& opt) {
    std::vector<fs::path> files;
    for (const auto& e : fs::recursive_directory_iterator{opt.dir}) {
        if (e.is_regular_file()) {
            files.push_back(e.path());
        }
    }
    std::sort(files.begin(), files.end());  // 输出顺序稳定

    std::atomic<std::size_t> cursor{0};
    std::atomic<int> total{0};
    std::mutex print_mtx;  // 命中行整行打印，不许交错
    std::vector<std::jthread> team;
    for (int t = 0; t < opt.threads; ++t) {
        team.emplace_back([&] {
            std::size_t i;
            while ((i = cursor.fetch_add(1)) < files.size()) {  // 领下一个文件
                for (const auto& m : search_file(files[i], opt.pattern, opt.ignore_case)) {
                    {
                        std::lock_guard lock{print_mtx};
                        print_match(files[i], m, opt.pattern, opt.ignore_case);
                    }
                    total.fetch_add(1);
                }
            }
        });
    }
    for (auto& t : team) {
        t.join();
    }
    return total.load();
}

int main(int argc, char** argv) {
    if (argc < 2) {
        run_self_test();  // 无参数 = 自检（build.ps1 验证入口）
        return 0;
    }
    if (std::string_view{argv[1]} == "--self-test") {
        run_self_test();
        return 0;
    }
    Options opt = parse_args(argc, argv);
    int hits = search_directory(opt);
    std::println("共 {} 处命中", hits);
    return 0;
}
