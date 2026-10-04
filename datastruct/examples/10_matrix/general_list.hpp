#ifndef DS_GENERAL_LIST_HPP
#define DS_GENERAL_LIST_HPP

#include <cctype>
#include <cstddef>
#include <stdexcept>
#include <string_view>
#include <vector>

namespace ds {

// 广义表：元素要么是原子（一个 double），要么是子表；表可以多层嵌套。
// 节点存于 arena、用整数下标互引；拷贝 arena 时下标仍然有效，
// 因此编译器默认的拷贝语义即是深拷贝。
class GeneralList {
public:
    // 解析形如 (a,(b,(c)),d) 的串；原子为单个字母，按其字符编码存为 double。
    static GeneralList parse(std::string_view s) {
        GeneralList g;
        size_t pos = 0;
        g.root_ = g.parse_list_(s, pos);
        return g;
    }

    // 表长：顶层元素的个数。
    int length() const {
        return static_cast<int>(nodes_[static_cast<size_t>(root_)].children.size());
    }

    // 深度：表的深度为 1 + 各元素深度的最大值；原子深度记 0。
    int depth() const {
        return depth_(root_);
    }

    // 展开：按书写顺序取出全部原子（深度优先）。
    std::vector<double> flatten() const {
        std::vector<double> out;
        flatten_(root_, out);
        return out;
    }

private:
    struct Node {
        int tag;  // 0 原子，1 子表
        double atom = 0.0;
        std::vector<int> children;
    };

    std::vector<Node> nodes_;
    int root_ = -1;

    int new_atom_(double v) {
        const int id = static_cast<int>(nodes_.size());
        nodes_.push_back(Node{0, v, {}});
        return id;
    }

    int new_list_() {
        const int id = static_cast<int>(nodes_.size());
        nodes_.push_back(Node{1, 0.0, {}});
        return id;
    }

    static void skip_spaces_(std::string_view s, size_t& pos) {
        while (pos < s.size()
               && std::isspace(static_cast<unsigned char>(s[pos])) != 0) {
            ++pos;
        }
    }

    static bool is_atom_char_(char ch) {
        return std::isalpha(static_cast<unsigned char>(ch)) != 0;
    }

    // list := '(' [element (',' element)*] ')'
    int parse_list_(std::string_view s, size_t& pos) {
        skip_spaces_(s, pos);
        if (pos >= s.size() || s[pos] != '(') {
            throw std::invalid_argument("GeneralList::parse: expected '('");
        }
        ++pos;
        const int id = new_list_();

        skip_spaces_(s, pos);
        if (pos < s.size() && s[pos] == ')') {  // 空表
            ++pos;
            return id;
        }

        for (;;) {
            skip_spaces_(s, pos);
            if (pos >= s.size()) {
                throw std::invalid_argument("GeneralList::parse: unterminated list");
            }
            // 注意：必须先把子节点编号算出来再 push_back：new_*/parse_list_
            // 会向 nodes_ 追加、可能触发重分配；若在同一条表达式里先取了
            // nodes_[id].children 的引用，重分配后引用悬空，push 会丢失。
            int child;
            if (s[pos] == '(') {
                child = parse_list_(s, pos);
            } else if (is_atom_char_(s[pos])) {
                const double v = static_cast<double>(s[pos]);
                ++pos;
                child = new_atom_(v);
            } else {
                throw std::invalid_argument("GeneralList::parse: bad element");
            }
            nodes_[static_cast<size_t>(id)].children.push_back(child);

            skip_spaces_(s, pos);
            if (pos < s.size() && s[pos] == ',') {
                ++pos;
                continue;
            }
            if (pos < s.size() && s[pos] == ')') {
                ++pos;
                break;
            }
            throw std::invalid_argument("GeneralList::parse: expected ',' or ')'");
        }
        return id;
    }

    int depth_(int id) const {
        const Node& n = nodes_[static_cast<size_t>(id)];
        if (n.tag == 0) {
            return 0;
        }
        int best = 0;
        for (int child : n.children) {
            const int d = depth_(child);
            if (d > best) {
                best = d;
            }
        }
        return 1 + best;
    }

    void flatten_(int id, std::vector<double>& out) const {
        const Node& n = nodes_[static_cast<size_t>(id)];
        if (n.tag == 0) {
            out.push_back(n.atom);
            return;
        }
        for (int child : n.children) {
            flatten_(child, out);
        }
    }
};

}  // namespace ds

#endif  // DS_GENERAL_LIST_HPP
