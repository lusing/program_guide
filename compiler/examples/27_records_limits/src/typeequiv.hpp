// file: src/typeequiv.hpp
// 类型等价的两大学说（L 书 §6.4.3）：结构等价（树同构）与名字等价（声明身份）。
// 自带迷你类型图（含递归类型）——不依赖本章其余件，正文按对照面讲解。
#ifndef TIP_TYPEEQUIV_HPP
#define TIP_TYPEEQUIV_HPP

#include <set>
#include <string>
#include <utility>
#include <vector>

namespace teq {

// 类型图：节点池 + 下标引用。递归类型（record 里引用自己）靠下标成环。
struct Graph {
    struct Node {
        enum class Kind { Int, Named, Record, Arrow } kind = Kind::Int;
        std::string name;                              // Named 的声明名
        std::vector<std::pair<std::string, int>> fields;   // Record: 字段名 → 类型下标
        int from = -1, to = -1;                        // Arrow 的两腿
    };
    std::vector<Node> nodes;
    int addInt() {
        Node nd;
        nd.kind = Node::Kind::Int;
        nodes.push_back(nd);
        return (int)nodes.size() - 1;
    }
    int addNamed(const std::string &n) {
        Node nd;
        nd.kind = Node::Kind::Named;
        nd.name = n;
        nodes.push_back(nd);
        return (int)nodes.size() - 1;
    }
    int addRecord(std::vector<std::pair<std::string, int>> fs) {
        Node nd;
        nd.kind = Node::Kind::Record;
        nd.fields = std::move(fs);
        nodes.push_back(std::move(nd));
        return (int)nodes.size() - 1;
    }
    int addArrow(int a, int b) {
        Node nd;
        nd.kind = Node::Kind::Arrow;
        nd.from = a;
        nd.to = b;
        nodes.push_back(std::move(nd));
        return (int)nodes.size() - 1;
    }
};

// 名字等价：同一声明（同一节点）才算等——别名传递性依实现而异，本版"同节点即等"。
bool nameEq(int a, int b);

// 结构等价：树同构递归；环用假设集（coinduction 的操作面）——
// (a,b) 进栈时先假设相等，回到同一对即判等（步数计数供正文对账）。
bool structEq(const Graph &g, int a, int b, long long *steps = nullptr);

}  // namespace teq

#endif  // TIP_TYPEEQUIV_HPP
