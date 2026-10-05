// file: src/instances.cpp
// 第 29 章配套：五个框架实例——四大经典 + 常量传播。
// 每个实例只填一张表；与第 25/26 章的专门实现同语义。
#include "instances.hpp"

#include <cctype>
#include <sstream>

namespace tip {

namespace {
bool isNum(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVar(const std::string &s) { return !s.empty() && !isNum(s); }

std::string exprOf(const Quad &q) {
    const char *op = nullptr;
    switch (q.op) {
    case TOp::Add: op = " + "; break;
    case TOp::Sub: op = " - "; break;
    case TOp::Mul: op = " * "; break;
    case TOp::Div: op = " / "; break;
    case TOp::Gt:  op = " > "; break;
    case TOp::Eq:  op = " == "; break;
    default: return "";
    }
    std::ostringstream os;
    os << q.a << op << q.b;
    return os.str();
}
bool sharesOp(const std::string &key, const std::string &var) {
    if (key.rfind(var + " ", 0) == 0) return true;
    size_t sp = key.rfind(" " + var);
    if (sp != std::string::npos && sp + 1 + var.size() == key.size()) return true;
    return key.find(" " + var + " ") != std::string::npos;
}
bool definesSomething(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
FVal unionMeet(const FVal &a, const FVal &b) {
    FVal out = a;
    out.insert(b.begin(), b.end());
    return out;
}
FVal interMeet(const FVal &a, const FVal &b) {
    FVal out;
    for (const auto &x : a)
        if (b.count(x)) out.insert(x);
    return out;
}
// 全域扫描：所有变量 / 所有表达式键
void scanUniverse(const std::vector<Quad> &code, FVal &vars, FVal &exprs) {
    for (const auto &q : code) {
        if (isVar(q.dst)) vars.insert(q.dst);
        if (isVar(q.a)) vars.insert(q.a);
        if (isVar(q.b)) vars.insert(q.b);
        std::string e = exprOf(q);
        if (!e.empty()) exprs.insert(e);
    }
}
}  // namespace

// ---------- 到达定值（前向 may；元素 "i:var"） ----------
Instance makeReaching(const std::vector<Quad> &code) {
    Instance inst;
    inst.name = "reaching";
    inst.dir = Dir::Forward;
    inst.meetFn = unionMeet;
    inst.boundary = {};
    inst.initTop = {};
    inst.transfer = [code](int i, const Quad &q, const FVal &in) {
        FVal out = in;
        if (!definesSomething(q)) return out;
        std::string v = q.dst;
        for (auto it = out.begin(); it != out.end();)
            if (it->substr(it->find(':') + 1) == v) it = out.erase(it);
            else ++it;
        out.insert(std::to_string(i) + ":" + v);
        return out;
    };
    return inst;
}

// ---------- 可用表达式（前向 must；元素 = 表达式键） ----------
Instance makeAvailable(const std::vector<Quad> &code) {
    Instance inst;
    inst.name = "available";
    inst.dir = Dir::Forward;
    inst.meetFn = interMeet;
    inst.boundary = {};   // 入口：无表达式可用（全集的补——must 的边界为空集）
    FVal vars, exprs;
    scanUniverse(code, vars, exprs);
    inst.initTop = exprs;   // 迭代从全集开始向下
    inst.transfer = [](int, const Quad &q, const FVal &in) {
        FVal out = in;
        std::string e = exprOf(q);
        if (!e.empty()) out.insert(e);
        if (isVar(q.dst)) {
            for (auto it = out.begin(); it != out.end();) {
                if (sharesOp(*it, q.dst)) it = out.erase(it);
                else ++it;
            }
        }
        return out;
    };
    return inst;
}

// ---------- 活跃变量（后向 may；元素 = 变量名） ----------
Instance makeLive(const std::vector<Quad> &code0) {
    (void)code0;
    Instance inst;
    inst.name = "live";
    inst.dir = Dir::Backward;
    inst.meetFn = unionMeet;
    inst.boundary = {};   // 出口：无活跃
    inst.initTop = {};
    inst.transfer = [](int, const Quad &q, const FVal &in) {
        FVal out = in;
        if (isVar(q.dst)) out.erase(q.dst);
        if (isVar(q.a)) { out.insert(q.a); }
        if (isVar(q.b)) { out.insert(q.b); }
        return out;
    };
    return inst;
}

// ---------- 非常忙表达式（后向 must；元素 = 表达式键） ----------
Instance makeVeryBusy(const std::vector<Quad> &code) {
    Instance inst;
    inst.name = "verybusy";
    inst.dir = Dir::Backward;
    inst.meetFn = interMeet;
    inst.boundary = {};
    FVal vars, exprs;
    scanUniverse(code, vars, exprs);
    inst.initTop = exprs;
    inst.transfer = [](int, const Quad &q, const FVal &in) {
        FVal out = in;
        // 先杀后生（后向扫描序）：x = x + 1 仍生成 "x + 1"
        if (isVar(q.dst)) {
            for (auto it = out.begin(); it != out.end();) {
                if (sharesOp(*it, q.dst)) it = out.erase(it);
                else ++it;
            }
        }
        std::string e = exprOf(q);
        if (!e.empty()) out.insert(e);
        return out;
    };
    return inst;
}

// ---------- 常量传播（前向；元素 "x=5" / "x=T"） ----------
namespace {
std::string constOf(const FVal &s, const std::string &v) {
    for (const auto &e : s)
        if (e.rfind(v + "=", 0) == 0) return e.substr(v.size() + 1);
    return "";
}
FVal constPropMeet(const FVal &a, const FVal &b) {
    FVal out;
    std::set<std::string> vars;
    for (const auto &e : a) vars.insert(e.substr(0, e.find('=')));
    for (const auto &e : b) vars.insert(e.substr(0, e.find('=')));
    for (const auto &v : vars) {
        std::string x = constOf(a, v), y = constOf(b, v);
        if (!x.empty() && !y.empty())
            out.insert(v + "=" + (x == y ? x : std::string("T")));
        else
            out.insert(v + "=T");   // 一侧缺失（⊥）一侧已知：保守取 ⊤
    }
    return out;
}
}  // namespace

Instance makeConstProp(const std::vector<Quad> &code0) {
    (void)code0;
    Instance inst;
    inst.name = "constprop";
    inst.dir = Dir::Forward;
    inst.meetFn = constPropMeet;
    inst.boundary = {};   // 入口：全部变量 ⊥（尚未定值）
    inst.initTop = {};    // ⊥ 起步（与 may 同形；⊤ 只在流动中出现）
    inst.transfer = [](int, const Quad &q, const FVal &in) {
        FVal out = in;
        auto rhsVal = [&](const std::string &s) -> std::string {
            if (isNum(s)) return s;
            std::string c = constOf(in, s);
            return c.empty() ? std::string("T") : c;
        };
        switch (q.op) {
        case TOp::Input:
            out.erase(q.dst + "=" + rhsVal(q.a));
            for (auto it = out.begin(); it != out.end();)
                if (it->rfind(q.dst + "=", 0) == 0) it = out.erase(it);
                else ++it;
            out.insert(q.dst + "=T");
            break;
        case TOp::Copy: {
            for (auto it = out.begin(); it != out.end();)
                if (it->rfind(q.dst + "=", 0) == 0) it = out.erase(it);
                else ++it;
            out.insert(q.dst + "=" + rhsVal(q.a));
            break;
        }
        case TOp::Add: case TOp::Sub: case TOp::Mul: case TOp::Div:
        case TOp::Gt: case TOp::Eq: {
            for (auto it = out.begin(); it != out.end();)
                if (it->rfind(q.dst + "=", 0) == 0) it = out.erase(it);
                else ++it;
            std::string l = rhsVal(q.a), r = rhsVal(q.b);
            if (l != "T" && r != "T") {
                int lv = std::atoi(l.c_str()), rv = std::atoi(r.c_str());
                int v = q.op == TOp::Add ? lv + rv
                        : q.op == TOp::Sub ? lv - rv
                        : q.op == TOp::Mul ? lv * rv
                        : q.op == TOp::Div ? lv / rv
                        : q.op == TOp::Gt ? (lv > rv ? 1 : 0)
                                          : (lv == rv ? 1 : 0);
                out.insert(q.dst + "=" + std::to_string(v));
            } else {
                out.insert(q.dst + "=T");
            }
            break;
        }
        default:
            break;
        }
        return out;
    };
    return inst;
}

}  // namespace tip
