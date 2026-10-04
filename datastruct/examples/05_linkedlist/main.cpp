#include <cassert>
#include <print>
#include <string_view>
#include <vector>

#include "singly_list.hpp"
#include "doubly_list.hpp"
#include "circular_list.hpp"

// 05 链表族：单向、双向、循环三种链表的操作对照

namespace {

void print_seq(std::string_view label, const std::vector<int>& seq) {
    std::print("{}：", label);
    for (size_t i = 0; i < seq.size(); ++i) {
        if (i > 0) {
            std::print(" ");
        }
        std::print("{}", seq[i]);
    }
    std::println("");
}

}  // namespace

int main() {
    // ═══ 单向链表：头插/尾插/定位插入/删除，最终序列 1,2,3 ═══
    ds::SinglyList<int> s;
    s.push_front(2);
    s.push_front(1);
    s.push_back(3);
    s.insert(1, 9);
    s.erase(1);
    assert((s == ds::SinglyList<int>{1, 2, 3}));
    int counted = 0;
    for (int x : s) {
        assert(x == (counted + 1));
        ++counted;
    }
    assert(counted == 3);
    std::vector<int> s_after;
    for (int x : s) {
        s_after.push_back(x);
    }
    print_seq("单向链表增删后", s_after);

    s.pop_front();
    s.reverse();
    assert((s == ds::SinglyList<int>{3, 2}));
    std::vector<int> s_reversed;
    for (int x : s) {
        s_reversed.push_back(x);
    }
    print_seq("头删后再反转", s_reversed);

    // ═══ 双向链表：正向、反向遍历；删除中部元素 2 ═══
    ds::DoublyList<int> d{1, 2, 3, 4};
    std::vector<int> forward;
    for (int x : d) {
        forward.push_back(x);
    }
    assert((forward == std::vector<int>{1, 2, 3, 4}));
    std::vector<int> backward;
    for (auto it = d.rbegin(); it != d.rend(); --it) {
        backward.push_back(*it);
    }
    assert((backward == std::vector<int>{4, 3, 2, 1}));
    print_seq("双向链表正向", forward);
    print_seq("双向链表反向", backward);

    d.erase(1);
    assert((d == ds::DoublyList<int>{1, 3, 4}));
    std::vector<int> after_erase;
    for (int x : d) {
        after_erase.push_back(x);
    }
    assert((after_erase == std::vector<int>{1, 3, 4}));
    print_seq("删除中部元素后", after_erase);

    // ═══ 有序链合并：结果有序完整，输入链保持完好 ═══
    ds::DoublyList<int> a{1, 4, 7};
    ds::DoublyList<int> b{2, 3, 8};
    ds::DoublyList<int> m = ds::merge_sorted(a, b);
    assert((m == ds::DoublyList<int>{1, 2, 3, 4, 7, 8}));
    assert(a.size() == 3);
    assert(b.size() == 3);
    std::vector<int> merged;
    for (int x : m) {
        merged.push_back(x);
    }
    print_seq("两有序链合并", merged);

    // ═══ 循环链表：旋转 n 步回到原状；拷贝析构不断环事故 ═══
    ds::CircularList<int> c{1, 2, 3, 4};
    const std::vector<int> original = c.to_vector();
    assert((original == std::vector<int>{1, 2, 3, 4}));
    for (int i = 0; i < 4; ++i) {
        c.rotate();
    }
    assert(c.to_vector() == original);
    assert(c.size() == 4);
    c.rotate();
    assert((c.to_vector() == std::vector<int>{2, 3, 4, 1}));
    print_seq("旋转一格后", c.to_vector());
    {
        ds::CircularList<int> copy = c;
        assert(copy.to_vector() == c.to_vector());
    }  // 副本在此析构：必须正确断环、不挂不死循环
    assert((c.to_vector() == std::vector<int>{2, 3, 4, 1}));
    print_seq("副本析构后原表完好", c.to_vector());

    std::println("自检通过");
}
