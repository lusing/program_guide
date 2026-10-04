#ifndef DS_HUFFMAN_HPP
#define DS_HUFFMAN_HPP

#include <cstddef>
#include <memory>
#include <queue>
#include <span>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace ds {

// 一个字符对应的二进制码字。
struct HuffCode {
    char ch;
    std::string bits;

    bool operator==(const HuffCode&) const = default;
};

// 霍夫曼变长前缀码。
//
// 构造：给出字母表中每个字符的出现次数（必须为正、字符不重复）。
// 建树：每次取权重最小的两棵树合并，新树权重为两者之和；共 n−1 次合并。
// 平局规则：堆元素按 (权重, id) 排序，叶子 id 取输入位置，内部节点 id
// 取两子 id 的较小值 —— 于是码字与遍历序列在任何机器上都逐字节确定。
class Huffman {
    // 树节点定义在前：构造函数中的局部比较器立即可见完整类型。
    struct Node {
        int freq;
        char ch;                       // 仅叶子有效，内部节点为 '\0'
        std::unique_ptr<Node> left;
        std::unique_ptr<Node> right;

        Node(int f, char c, std::unique_ptr<Node> l = nullptr,
             std::unique_ptr<Node> r = nullptr)
            : freq(f), ch(c), left(std::move(l)), right(std::move(r)) {}
    };

public:
    explicit Huffman(std::span<const std::pair<char, int>> freqs) {
        if (freqs.empty()) {
            throw std::invalid_argument("Huffman: 字母表不能为空");
        }
        order_.reserve(freqs.size());

        struct HeapEntry {
            Node* node;
            int id;
        };
        struct Cmp {
            bool operator()(const HeapEntry& a, const HeapEntry& b) const {
                if (a.node->freq != b.node->freq) {
                    return a.node->freq > b.node->freq;  // 权重大的沉底
                }
                return a.id > b.id;
            }
        };
        std::priority_queue<HeapEntry, std::vector<HeapEntry>, Cmp> heap;

        for (size_t i = 0; i < freqs.size(); ++i) {
            const char ch = freqs[i].first;
            const int weight = freqs[i].second;
            if (weight <= 0) {
                throw std::invalid_argument("Huffman: 频率必须为正");
            }
            if (code_of_.find(ch) != code_of_.end()) {
                throw std::invalid_argument("Huffman: 字符重复");
            }
            order_.push_back(ch);
            auto node = std::make_unique<Node>(weight, ch);
            Node* raw = node.get();
            all_nodes_.push_back(std::move(node));
            heap.push({raw, static_cast<int>(i)});
        }

        // 不断合并最小的两棵树：先弹出者为左孩子（码字补 0）。
        while (heap.size() > 1) {
            const HeapEntry x = heap.top();
            heap.pop();
            const HeapEntry y = heap.top();
            heap.pop();

            // all_nodes_ 持有 x/y 的 unique_ptr，取走后再以子节点身份装入新节点。
            std::unique_ptr<Node> lx;
            std::unique_ptr<Node> ry;
            for (auto& up : all_nodes_) {
                if (up.get() == x.node) {
                    lx = std::move(up);
                } else if (up.get() == y.node) {
                    ry = std::move(up);
                }
            }
            auto merged = std::make_unique<Node>(
                x.node->freq + y.node->freq, '\0', std::move(lx), std::move(ry));
            Node* raw = merged.get();
            all_nodes_.push_back(std::move(merged));
            heap.push({raw, std::min(x.id, y.id)});
        }

        root_ = heap.top().node;
        fill_codes(root_, "");
    }

    // 按构造顺序返回每个字符的码字。
    [[nodiscard]] std::vector<HuffCode> codes() const {
        std::vector<HuffCode> result;
        result.reserve(order_.size());
        for (char ch : order_) {
            result.push_back({ch, code_of_.at(ch)});
        }
        return result;
    }

    // 把文本编码成 0/1 位串；字母表外的字符抛 invalid_argument。
    [[nodiscard]] std::string encode(std::string_view text) const {
        std::string bits;
        for (char ch : text) {
            const auto it = code_of_.find(ch);
            if (it == code_of_.end()) {
                throw std::invalid_argument("Huffman::encode: 字母表外字符");
            }
            bits += it->second;
        }
        return bits;
    }

    // 位串还原为文本；位串在某个内部节点处结束抛 invalid_argument。
    [[nodiscard]] std::string decode(std::string_view bits) const {
        std::string text;
        const Node* cur = root_;
        for (char bit : bits) {
            if (!root_->left) {
                break;  // 单字符字母表：码字为空，无位可走
            }
            cur = (bit == '0') ? cur->left.get() : cur->right.get();
            if (!cur) {
                throw std::invalid_argument("Huffman::decode: 非法位串");
            }
            if (!cur->left) {
                text.push_back(cur->ch);
                cur = root_;
            }
        }
        if (cur != root_) {
            throw std::invalid_argument("Huffman::decode: 位串在内部节点截断");
        }
        return text;
    }

private:
    // 递归 DFS 收集码字：向左补 0、向右补 1，到叶子登记。
    void fill_codes(const Node* node, const std::string& bits) {
        if (!node->left) {
            code_of_[node->ch] = bits;
            return;
        }
        fill_codes(node->left.get(), bits + '0');
        fill_codes(node->right.get(), bits + '1');
    }

    std::vector<std::unique_ptr<Node>> all_nodes_;
    Node* root_ = nullptr;
    std::vector<char> order_;
    std::unordered_map<char, std::string> code_of_;
};

}  // namespace ds

#endif  // DS_HUFFMAN_HPP
