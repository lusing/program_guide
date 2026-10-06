// file: src/tmasm.cpp
#include "tmasm.hpp"

#include <cctype>
#include <map>
#include <sstream>
#include <stdexcept>

namespace tmach {

const char *TmIns::name(Op o) {
    switch (o) {
    case Op::HALT: return "HALT";
    case Op::IN: return "IN";
    case Op::OUT: return "OUT";
    case Op::ADD: return "ADD";
    case Op::SUB: return "SUB";
    case Op::MUL: return "MUL";
    case Op::DIV: return "DIV";
    case Op::LD: return "LD";
    case Op::LDA: return "LDA";
    case Op::LDC: return "LDC";
    case Op::ST: return "ST";
    case Op::JLT: return "JLT";
    case Op::JLE: return "JLE";
    case Op::JGE: return "JGE";
    case Op::JGT: return "JGT";
    case Op::JEQ: return "JEQ";
    case Op::JNE: return "JNE";
    }
    return "?";
}

namespace {

const std::map<std::string, TmIns::Op> &opTable() {
    static const std::map<std::string, TmIns::Op> t = {
        {"HALT", TmIns::Op::HALT}, {"IN", TmIns::Op::IN}, {"OUT", TmIns::Op::OUT},
        {"ADD", TmIns::Op::ADD},   {"SUB", TmIns::Op::SUB}, {"MUL", TmIns::Op::MUL},
        {"DIV", TmIns::Op::DIV},   {"LD", TmIns::Op::LD},   {"LDA", TmIns::Op::LDA},
        {"LDC", TmIns::Op::LDC},   {"ST", TmIns::Op::ST},   {"JLT", TmIns::Op::JLT},
        {"JLE", TmIns::Op::JLE},   {"JGE", TmIns::Op::JGE}, {"JGT", TmIns::Op::JGT},
        {"JEQ", TmIns::Op::JEQ},   {"JNE", TmIns::Op::JNE},
    };
    return t;
}

// 把一行拆成（标号?、操作数们）——剥注释、去标号、按空白切。
struct Line {
    int lineno;
    std::string label;              // 可空
    std::vector<std::string> words; // [OP, 操作数...]
};

Line split(const std::string &raw, int lineno) {
    std::string s = raw;
    auto sc = s.find(';');
    if (sc != std::string::npos) s = s.substr(0, sc);
    Line out;
    out.lineno = lineno;
    // 标号：冒号在第一个空白之前
    auto colon = s.find(':');
    if (colon != std::string::npos) {
        bool ok = true;
        for (size_t k = 0; k < colon; ++k)
            if (std::isspace(static_cast<unsigned char>(s[k]))) { ok = false; break; }
        if (ok) {
            out.label = s.substr(0, colon);
            s = s.substr(colon + 1);
        }
    }
    std::istringstream is(s);
    std::string w;
    while (is >> w) out.words.push_back(w);
    return out;
}

int toInt(const std::string &w, int lineno) {
    try {
        return std::stoi(w);
    } catch (const std::exception &) {
        throw std::runtime_error("汇编第 " + std::to_string(lineno) + " 行：非法数字 '" + w + "'");
    }
}

// 把 "r,s,t" / "r,d(s)" 按逗号切成字段（最后一个字段可能是 d(s) 形态）。
std::vector<std::string> splitCommas(const std::string &operand, int ln) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : operand) {
        if (c == ',') { out.push_back(cur); cur.clear(); }
        else cur += c;
    }
    out.push_back(cur);
    if (out.size() != 2 && out.size() != 3)
        throw std::runtime_error("汇编第 " + std::to_string(ln) +
                                 " 行：操作数要 'r,s,t' 或 'r,d(s)'，得 '" + operand + "'");
    return out;
}

}  // namespace

std::string disasm(const TmIns &i) {
    std::ostringstream os;
    os << TmIns::name(i.op);
    if (i.isRO(i.op)) os << " " << i.r << "," << i.s << "," << i.t;
    else os << " " << i.r << "," << i.d << "(" << i.s << ")";
    return os.str();
}

std::vector<TmIns> Assembler::assemble(const std::string &tmText) {
    // ---------- 第一遍：剥注释/标号，记标号地址 ----------
    std::vector<Line> lines;
    std::map<std::string, int> labels;
    {
        std::istringstream is(tmText);
        std::string raw;
        int ln = 0;
        while (std::getline(is, raw)) {
            ++ln;
            Line l = split(raw, ln);
            if (l.words.empty()) {
                if (!l.label.empty())
                    labels[l.label] = static_cast<int>(lines.size());   // 空行标号指向下一条
                continue;
            }
            if (!l.label.empty()) labels[l.label] = static_cast<int>(lines.size());
            lines.push_back(std::move(l));
        }
    }
    // ---------- 第二遍：编码（d 位的标号 → 相对 7 的偏移） ----------
    std::vector<TmIns> out;
    out.reserve(lines.size());
    for (const auto &l : lines) {
        auto it = opTable().find(l.words[0]);
        if (it == opTable().end())
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：未知指令 '" + l.words[0] + "'");
        TmIns::Op op = it->second;
        if (l.words.size() != 2)
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：指令要 'OP r,s,t' 或 'OP r,d(s)' 形式");
        auto f = splitCommas(l.words[1], l.lineno);
        if (TmIns::isRO(op)) {
            if (f.size() != 3)
                throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                         " 行：RO 指令要 r,s,t");
            // TmIns 字段序是 (op, r, d, s, t)——RO 无 d，置 0 别错位
            out.push_back(TmIns{op, toInt(f[0], l.lineno), 0, toInt(f[1], l.lineno),
                                toInt(f[2], l.lineno)});
            continue;
        }
        // RM：r,d(s)——d 可以是标号（跳转目标，按 (7) 基址换算）
        if (f.size() != 2)
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：RM 指令要 r,d(s)");
        TmIns ins;
        ins.op = op;
        ins.r = toInt(f[0], l.lineno);
        std::string ds = f[1];   // 形如 -4(6) 或 label(7) 或 3(0)
        auto lp = ds.find('(');
        if (lp == std::string::npos || ds.back() != ')')
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：RM 第二操作数要 d(s) 形式，得 '" + ds + "'");
        std::string dpart = ds.substr(0, lp), spart = ds.substr(lp + 1, ds.size() - lp - 2);
        if (std::isdigit(static_cast<unsigned char>(dpart[0])) || dpart[0] == '-') {
            ins.d = toInt(dpart, l.lineno);
        } else {
            // 标号目标：绝对地址 addr → d = addr - (当前位置 + 1)（基址 7）
            if (spart != "7")
                throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                         " 行：标号目标只能以 (7) 为基址");
            auto li = labels.find(dpart);
            if (li == labels.end())
                throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                         " 行：未定义标号 '" + dpart + "'");
            ins.d = li->second - (static_cast<int>(out.size()) + 1);
        }
        ins.s = toInt(spart, l.lineno);
        if (ins.r < 0 || ins.r > 7 || ins.s < 0 || ins.s > 7)
            throw std::runtime_error("汇编第 " + std::to_string(l.lineno) +
                                     " 行：寄存器号须在 0..7");
        out.push_back(ins);
    }
    return out;
}

}  // namespace tmach
