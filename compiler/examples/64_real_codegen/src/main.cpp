// file: src/main.cpp
// 第 64 章驱动（无参运行，走"简单程序"对账协议）：
//   S1 落盘片段 → gcc -O0/-O1 -S → 模式计数表；
//   S2 两档指令数对比（-O1 删了什么逐条讲）；
//   S3 关键行样本（帧建立 / 比例寻址 / Win64 传参寄存器 / call-ret 对）。
#include "asmcheck.hpp"
#include "snippets.hpp"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>

namespace fs = std::filesystem;

namespace {

// 把 snippets 落盘到临时目录（gcc 的工作区）。
fs::path prepare() {
    fs::path dir = fs::temp_directory_path() / "rcgen";
    std::error_code ec;
    fs::create_directories(dir, ec);
    for (const auto &s : rc::snippets()) {
        std::ofstream(dir / (std::string(s.name) + ".c")) << s.body << "\n";
    }
    return dir;
}

}  // namespace

int main() {
    fs::path dir = prepare();
    // 只打目录名——完整路径随系统 TMP 而变（跨环境对账会炸），目录名恒为 rcgen。
    std::cout << "[workdir] " << dir.filename().string() << "\n";
    std::vector<std::string> funcs;
    for (const auto &s : rc::snippets()) funcs.push_back(s.name);
    auto pats = rc::defaultPatterns();

    std::vector<rc::FuncReport> o0, o1;
    try {
        o0 = rc::checkAll(funcs, pats, "-O0");
        o1 = rc::checkAll(funcs, pats, "-O1");
    } catch (const std::exception &e) {
        std::cerr << "gcc 对账不可用: " << e.what() << "\n";
        return 1;
    }

    // ---------- S1 模式表 ----------
    std::cout << "== S1 pattern table (gcc -O0) ==\n";
    for (const auto &r : o0) {
        std::cout << "[" << r.func << "] insns=" << r.insns;
        for (const auto &p : pats)
            std::cout << " " << p.name << "=" << r.hits.at(p.name);
        std::cout << "\n";
    }

    // ---------- S2 两档指令数 ----------
    std::cout << "== S2 -O0 vs -O1 ==\n";
    for (size_t k = 0; k < funcs.size(); ++k) {
        std::cout << "[" << funcs[k] << "] O0=" << o0[k].insns << "  O1=" << o1[k].insns
                  << "  (O1/O0 = " << (o0[k].insns ? double(o1[k].insns) / o0[k].insns : 0.0)
                  << ")\n";
    }

    // ---------- S3 关键行样本 ----------
    std::cout << "== S3 key lines (O0) ==\n";
    for (const auto &r : o0) {
        std::cout << "-- " << r.func << " --\n";
        // 只印三族锚点：帧建立两条 + 比例寻址 + 传参寄存器（有的函数没有后两者）
        int shown = 0;
        for (const auto &l : r.keyLines) {
            bool want = l.find("frame-") != std::string::npos ||
                        l.find("scale-addr") != std::string::npos ||
                        l.find("argreg") != std::string::npos;
            if (!want) continue;
            if (l.find("frame-") != std::string::npos && shown >= 2) continue;
            std::cout << "    " << l << "\n";
            ++shown;
        }
    }

    // ---------- S4 断言摘要（机器证人的判词） ----------
    std::cout << "== S4 verdicts ==\n";
    auto cnt = [&](const rc::FuncReport &r, const std::string &p) { return r.hits.at(p); };
    std::cout << "[frame] e1 O0 push+mov >= 1 : "
              << (cnt(o0[0], "frame-push") >= 1 && cnt(o0[0], "frame-mov") >= 1 ? 1 : 0) << "\n";
    std::cout << "[rbp-loc] e2 O0 rbp 寻址 > 0 : " << (cnt(o0[1], "rbp-loc") > 0 ? 1 : 0) << "\n";
    std::cout << "[scale] e2 O0 比例寻址 > 0 : " << (cnt(o0[1], "scale-addr") > 0 ? 1 : 0) << "\n";
    std::cout << "[call/ret] cf O0 调用=1 返回=2 : "
              << (cnt(o0[5], "call") == 1 && cnt(o0[5], "ret") >= 1 ? 1 : 0) << "\n";
    std::cout << "[argreg] cf O0 Win64 寄存器传参 > 0 : "
              << (cnt(o0[5], "argreg") > 0 ? 1 : 0) << "\n";
    std::cout << "[opt] 全部函数 O1 <= O0 : "
              << ([&] {
                     for (size_t k = 0; k < funcs.size(); ++k)
                         if (o1[k].insns > o0[k].insns) return 0;
                     return 1;
                 }()
                  )
              << "\n";
    return 0;
}
