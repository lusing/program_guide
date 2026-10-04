// file: src/isel.cpp
// 第 44 章配套：表达式树重建、Ershov 标号、maximal munch 指令选择、
// 迷你 RISC、窥孔清扫、RISC 解释器。
#include "isel.hpp"

#include <cctype>
#include <map>
#include <sstream>
#include <stdexcept>

namespace tip {

namespace {
bool isNumI(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarI(const std::string &s) { return !s.empty() && !isNumI(s); }
}  // namespace

// ---------- 树重建：把“临时只在下一处使用”的链重新长成树 ----------
std::vector<Tree> fuseTrees(const std::vector<Quad> &code, const Block &b) {
    // 使用计数（块内）
    std::map<std::string, int> uses;
    for (int i = b.begin; i < b.end; ++i) {
        if (isVarI(code[i].a)) ++uses[code[i].a];
        if (isVarI(code[i].b)) ++uses[code[i].b];
    }
    std::map<std::string, int> defAt;   // 名字 → 定义行（块内）
    for (int i = b.begin; i < b.end; ++i)
        if (!code[i].dst.empty()) defAt[code[i].dst] = i;
    // 递归取节点：叶子（常量/外部名）或独占定义的子树
    std::function<bool(const std::string &, int, TreeNode &)> grab =
        [&](const std::string &name, int before, TreeNode &out2) {
            if (isNumI(name)) {
                out2.kind = 'c';
                out2.value = std::atoi(name.c_str());
                return true;
            }
            auto it = defAt.find(name);
            if (it == defAt.end() || it->second >= before) {
                out2.kind = 'v';
                out2.name = name;
                return true;   // 外部流入（或定义在使用之后——按叶子处理，正常不出现）
            }
            int d = it->second;
            // 独占条件：块内只被用一次、且是临时
            if (name[0] != 't' || uses[name] != 1) {
                out2.kind = 'v';
                out2.name = name;
                return true;
            }
            const Quad &q = code[d];
            if (q.op == TOp::Copy) {
                // Copy 在链中同样穿透（ munch 不该见到单孩子节点）
                return grab(q.a, d, out2);
            }
            out2.kind = 'o';
            out2.op = q.op;
            TreeNode l, r;
            if (!grab(q.a, d, l)) return false;
            if (!grab(q.b, d, r)) return false;
            out2.l = std::make_unique<TreeNode>(std::move(l));
            out2.r = std::make_unique<TreeNode>(std::move(r));
            return true;
        };
    std::vector<Tree> out;
    // 从“定义行”直接建节点（Copy 穿透到源），供根与 grab 共用
    std::function<bool(int, TreeNode &)> grabAt = [&](int d, TreeNode &out2) {
        const Quad &q = code[d];
        if (q.op == TOp::Copy) return grab(q.a, d, out2);   // Copy 在根处穿透
        out2.kind = 'o';
        out2.op = q.op;
        TreeNode l, r;
        if (!grab(q.a, d, l)) return false;
        if (!grab(q.b, d, r)) return false;
        out2.l = std::make_unique<TreeNode>(std::move(l));
        out2.r = std::make_unique<TreeNode>(std::move(r));
        return true;
    };
    (void)grabAt;
    for (int i = b.begin; i < b.end; ++i) {
        const Quad &q = code[i];
        if (q.op != TOp::Copy && q.op != TOp::Add && q.op != TOp::Sub &&
            q.op != TOp::Mul && q.op != TOp::Div && q.op != TOp::Gt &&
            q.op != TOp::Eq)
            continue;
        // 只对“根”建树：目的不是临时（结果交给命名变量），或临时被多次用
        if (q.dst[0] == 't' && uses[q.dst] == 1) continue;
        Tree t;
        t.dst = q.dst;
        TreeNode root;
        if (!grabAt(i, root)) continue;
        t.root = std::move(root);
        out.push_back(std::move(t));
    }
    return out;
}

// ---------- Ershov 标号：求值该子树所需的最少寄存器数 ----------
int ershov(TreeNode &n) {
    if (n.kind != 'o') {
        n.ershov = 1;
        return 1;
    }
    int l = ershov(*n.l);
    int r = n.r ? ershov(*n.r) : 1;
    n.ershov = l == r ? l + 1 : std::max(l, r);
    return n.ershov;
}

// ---------- maximal munch：贪心覆盖 ----------
// 瓦片表（教学精选）：常量立即数乘、恒等加零/乘一折叠为 mov、二元运算。
static int riscN = 0;
std::string newReg() { return "r" + std::to_string(riscN++ % 8); }

std::vector<Risc> munchTree(TreeNode &n, std::vector<std::string> &notes) {
    std::vector<Risc> out;
    // 先试“大瓦片”：c1 op c2（两常量孩子）→ loadi
    if (n.kind == 'o' && n.l->kind == 'c' && n.r && n.r->kind == 'c') {
        int v = 0;
        int a = n.l->value, b2 = n.r->value;
        switch (n.op) {
        case TOp::Add: v = a + b2; break;
        case TOp::Sub: v = a - b2; break;
        case TOp::Mul: v = a * b2; break;
        case TOp::Div: v = a / b2; break;
        case TOp::Gt:  v = a > b2 ? 1 : 0; break;
        case TOp::Eq:  v = a == b2 ? 1 : 0; break;
        default: break;
        }
        std::string rd = newReg();
        out.push_back({"loadi", rd, std::to_string(v), -1});
        n.result = rd;
        notes.push_back("瓦片 [loadi c1 op c2] 命中");
        return out;
    }
    // 注：x+0 / x*1 这类恒等式刻意“不”设瓦片——留给窥孔（p2/p3 模式）去扫，
    // 正文 44.6 讲“瓦片管结构、窥孔兜底”的分工。
    // 叶子
    if (n.kind == 'c') {
        std::string rd = newReg();
        out.push_back({"loadi", rd, std::to_string(n.value), -1});
        n.result = rd;
        return out;
    }
    if (n.kind == 'v') {
        n.result = n.name;   // 变量视为已“在盒子里”——教学抽象
        return out;
    }
    // 一般二元：左右递归 + 一条指令
    std::vector<Risc> sub = munchTree(*n.l, notes);
    out.insert(out.end(), sub.begin(), sub.end());
    if (n.r) {
        sub = munchTree(*n.r, notes);
        out.insert(out.end(), sub.begin(), sub.end());
    }
    std::string rd = newReg();
    const char *mn = n.op == TOp::Add ? "add" : n.op == TOp::Sub ? "sub"
                       : n.op == TOp::Mul ? "mul" : n.op == TOp::Div ? "div"
                       : n.op == TOp::Gt ? "gt" : "eq";
    out.push_back({mn, rd, n.l->result + "," + n.r->result, -1});
    n.result = rd;
    return out;
}

std::string showRisc(const Risc &r) {
    std::ostringstream os;
    os << "  " << r.mnemonic << " " << r.rd;
    if (r.rs.find(',') != std::string::npos || !r.rs.empty())
        os << " " << r.rs;
    return os.str();
}

// ---------- 窥孔清扫 ----------
std::pair<std::vector<Risc>, std::map<std::string, int>> peephole(std::vector<Risc> in) {
    std::map<std::string, int> hits;
    auto isImm = [](const std::string &s) {
        return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
    };
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t i = 0; i < in.size(); ++i) {
            // p1: 自复制 mov rX rX 删除
            if (in[i].mnemonic == "mov" && in[i].rd == in[i].rs) {
                in.erase(in.begin() + i);
                ++hits["mov-self"];
                ch = true;
                break;
            }
            // p2: loadi rX 0 ; add rD A,rX → mov rD A（加零恒等；右源是刚载入的 0）
            if (i + 1 < in.size() && in[i].mnemonic == "loadi" && in[i].rs == "0" &&
                in[i + 1].mnemonic == "add" &&
                in[i + 1].rs.size() > in[i].rd.size() &&
                in[i + 1].rs.substr(in[i + 1].rs.size() - in[i].rd.size()) == in[i].rd) {
                in[i] = {"mov", in[i + 1].rd,
                         in[i + 1].rs.substr(0, in[i + 1].rs.size() - in[i].rd.size() - 1),
                         -1};
                in.erase(in.begin() + i + 1);
                ++hits["add-0"];
                ch = true;
                break;
            }
            // p3: loadi rX 1 ; mul rD A,rX → mov rD A（乘一恒等）
            if (i + 1 < in.size() && in[i].mnemonic == "loadi" && in[i].rs == "1" &&
                in[i + 1].mnemonic == "mul" &&
                in[i + 1].rs.size() > in[i].rd.size() &&
                in[i + 1].rs.substr(in[i + 1].rs.size() - in[i].rd.size()) == in[i].rd) {
                in[i] = {"mov", in[i + 1].rd,
                         in[i + 1].rs.substr(0, in[i + 1].rs.size() - in[i].rd.size() - 1),
                         -1};
                in.erase(in.begin() + i + 1);
                ++hits["mul-1"];
                ch = true;
                break;
            }
            (void)isImm;
        }
    }
    return {in, hits};
}

// ---------- RISC 解释器（对账证人） ----------
std::vector<int> riscRun(const std::vector<Risc> &code) {
    std::map<std::string, int> reg;
    std::vector<int> outputs;
    auto val = [&](const std::string &s) -> int {
        if (!s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1)))
            return std::atoi(s.c_str());
        return reg[s];
    };
    for (const auto &r : code) {
        if (r.mnemonic == "loadi") reg[r.rd] = std::atoi(r.rs.c_str());
        else if (r.mnemonic == "output") outputs.push_back(val(r.rd));
        else if (r.mnemonic == "mov") reg[r.rd] = val(r.rs);
        else {
            size_t comma = r.rs.find(',');
            std::string a = r.rs.substr(0, comma), b2 = r.rs.substr(comma + 1);
            int x = val(a), y = val(b2);
            if (r.mnemonic == "add") reg[r.rd] = x + y;
            else if (r.mnemonic == "sub") reg[r.rd] = x - y;
            else if (r.mnemonic == "mul") reg[r.rd] = x * y;
            else if (r.mnemonic == "div") reg[r.rd] = x / y;
            else if (r.mnemonic == "gt") reg[r.rd] = x > y ? 1 : 0;
            else if (r.mnemonic == "eq") reg[r.rd] = x == y ? 1 : 0;
        }
    }
    return outputs;
}

}  // namespace tip
