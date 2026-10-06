// file: src/asmcheck.cpp
#include "asmcheck.hpp"

#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <regex>
#include <stdexcept>
#include <sstream>

namespace fs = std::filesystem;

namespace rc {

namespace {

// 运行一条命令（输出重定向到文件由调用方拼进命令串）；返回退出码。
int run(const std::string &cmd) {
    return std::system(cmd.c_str());
}

// 从 .s 文本统计：指令行 = 以空白开头且含字母的行（gas 的指令缩进、标号顶格）。
size_t countInsns(const std::vector<std::string> &lines) {
    size_t n = 0;
    for (const auto &l : lines) {
        if (l.empty()) continue;
        if (l[0] != ' ' && l[0] != '\t') continue;   // 标号/节名顶格
        if (l.find_first_not_of(" \t") == std::string::npos) continue;
        if (l.find(".cfi") != std::string::npos) continue;   // 调试伪指令不算
        if (l.find(".seh") != std::string::npos) continue;
        if (l.find('.') == l.find_first_not_of(" \t")) continue;   // 伪指令行
        ++n;
    }
    return n;
}

}  // namespace

std::vector<Pattern> defaultPatterns() {
    return {
        {"frame-push", R"(pushq?\s+%r?bp)"},
        {"frame-mov", R"(movq?\s+%r?sp,\s*%r?bp)"},
        {"rbp-loc", R"(-\d+\(%r?bp\))"},
        {"lea", R"(\bleaq?\b)"},
        {"scale-addr", R"(,\s*%\w+,\s*4\s*\))"},   // 比例寻址：基(%变址,4)
        {"call", R"(\bcallq?\b)"},
        {"ret", R"(\bret\b)"},
        {"argreg", R"(%(ecx|edx|rcx|rdx|r8d|r9d|r8|r9)\b)"},   // Win64 传参寄存器（含 32 位形态）
    };
}

std::vector<FuncReport> checkAll(const std::vector<std::string> &funcs,
                                 const std::vector<Pattern> &pats,
                                 const std::string &opt) {
    // 工作目录：系统临时目录下的 rcgen（幂等创建）。
    fs::path dir = fs::temp_directory_path() / "rcgen";
    std::error_code ec;
    fs::create_directories(dir, ec);

    std::vector<std::regex> res;
    for (const auto &p : pats) res.emplace_back(p.re);
    std::vector<FuncReport> out;
    for (const auto &fn : funcs) {
        FuncReport rep;
        rep.func = fn;
        rep.opt = opt;
        std::string src = fn + ".c", asmf = fn + ".s";
        // 源文件来自 snippets() 的 body —— 这里由 main 先落盘（见 main.cpp 的 prepare()）。
        std::string cmd = "gcc " + opt + " -S -o " + (dir / asmf).string() + " " +
                          (dir / src).string() + " 2>" + (dir / "err.txt").string();
        if (run(cmd) != 0) {
            std::ifstream ef(dir / "err.txt");
            std::stringstream ss;
            ss << ef.rdbuf();
            throw std::runtime_error("gcc -S failed for " + fn + ": " + ss.str());
        }
        std::ifstream sf(dir / asmf);
        std::vector<std::string> lines;
        {
            std::string l;
            while (std::getline(sf, l)) lines.push_back(l);
        }
        if (lines.empty()) throw std::runtime_error("empty asm for " + fn);
        rep.insns = countInsns(lines);
        for (size_t k = 0; k < pats.size(); ++k) {
            int hits = 0;
            std::string first;
            for (const auto &l : lines) {
                if (std::regex_search(l, res[k])) {
                    ++hits;
                    if (first.empty()) first = l;
                }
            }
            rep.hits[pats[k].name] = hits;
            if (!first.empty()) rep.keyLines.push_back("[" + pats[k].name + "] " + first);
        }
        out.push_back(std::move(rep));
    }
    return out;
}

}  // namespace rc
