#include <array>
#include <cassert>
#include <print>
#include <vector>

// 01 绪论：同一个逻辑结构（线性表），两种存储结构的对照

int main() {
    const std::array<int, 5> data{3, 1, 4, 1, 5};

    // ═══ 存储一：顺序存储——元素住在连续内存里，靠下标直接定位 ═══
    int sequential[5];
    for (int i = 0; i < 5; ++i) {
        sequential[i] = data[static_cast<size_t>(i)];
    }

    // ═══ 存储二：链接存储——每个节点自带"下一个人在哪"的线索 ═══
    struct Node {
        int value;
        Node* next;
    };
    Node nodes[5];
    for (int i = 0; i < 5; ++i) {
        nodes[i] = Node{data[static_cast<size_t>(i)], nullptr};
        if (i > 0) {
            nodes[i - 1].next = &nodes[i];
        }
    }

    // 两种存储表达的是同一份逻辑内容：顺着线索走一遍，逐项相等
    Node* cur = &nodes[0];
    for (int i = 0; i < 5; ++i) {
        assert(sequential[i] == cur->value);
        cur = cur->next;
    }
    assert(cur == nullptr);

    std::println("逻辑结构四类：集合、线性、树形、图形");
    std::println("存储结构四类：顺序、链接、索引、散列");
    std::println("同一线性表的两种存储：逐项一致（共 {} 个元素）", data.size());
    std::println("自检通过");
}
