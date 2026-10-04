#include <cassert>
#include <functional>
#include <print>
#include <stdexcept>
#include <vector>

#include "leftist_tree.hpp"
#include "winner_tree.hpp"

// 14 左高树与竞赛树：最小/最大左高树的合并与弹出、赢者树 k 路归并

int main() {
    // ═══ 最小左高树：两棵小树分别构造，再 meld 成一棵 ═══
    ds::LeftistTree<int> a;
    a.push(10);
    a.push(5);
    a.push(15);
    ds::LeftistTree<int> b;
    b.push(3);
    b.push(7);

    a.meld(b);
    assert(a.size() == 5);
    assert(b.empty() && b.size() == 0);   // other 被掏空
    assert(a.property_ok());
    assert(a.root_s() == 2);              // 手工推演：根 3，s=2
    std::vector<int> asc;
    while (!a.empty()) {
        asc.push_back(a.top());
        a.pop();
    }
    assert((asc == std::vector<int>{3, 5, 7, 10, 15}));
    std::println("最小左高树 meld 后性质完好（根 s={}），弹出升序：3 5 7 10 15", 2);

    // ═══ 最大左高树：std::greater 定序，弹出降序 ═══
    ds::LeftistTree<int, std::greater<int>> mx;
    for (int v : {10, 5, 15, 3, 7}) {
        mx.push(v);
    }
    assert(mx.property_ok());
    std::vector<int> desc;
    while (!mx.empty()) {
        desc.push_back(mx.top());
        mx.pop();
    }
    assert((desc == std::vector<int>{15, 10, 7, 5, 3}));
    std::println("最大左高树弹出降序：15 10 7 5 3");

    // ═══ 空树 pop/top 抛异常 ═══
    {
        ds::LeftistTree<int> empty;
        bool pop_threw = false;
        bool top_threw = false;
        try {
            empty.pop();
        } catch (const std::runtime_error&) {
            pop_threw = true;
        }
        try {
            (void)empty.top();
        } catch (const std::runtime_error&) {
            top_threw = true;
        }
        assert(pop_threw && top_threw);
        std::println("空左高树 pop、top 均抛异常");
    }

    // ═══ 拷贝独立、移动掏空 ═══
    {
        ds::LeftistTree<int> src;
        for (int v : {4, 1, 3}) {
            src.push(v);
        }
        ds::LeftistTree<int> cp = src;
        assert(cp.property_ok() && src.property_ok());
        cp.pop();                          // 只动副本
        assert(src.size() == 3 && cp.size() == 2);

        ds::LeftistTree<int> moved = std::move(src);
        assert(src.empty());
        assert(moved.size() == 3);
        std::println("拷贝副本与原件独立；移动后源对象为空");
    }

    // ═══ 赢者树 k 路归并：三个有序段 ═══
    std::vector<std::vector<int>> runs{{1, 4, 7}, {2, 5, 8}, {3, 6, 9}};
    std::vector<std::vector<int>> run_storage{
        {1, 3, 8}, {3, 4}, {2, 3, 9}};  // 含跨段平局

    auto merged = ds::kway_merge(std::span<const std::vector<int>>{runs});
    assert((merged == std::vector<int>{1, 2, 3, 4, 5, 6, 7, 8, 9}));
    assert(merged.size() == 9);

    auto merged2 = ds::kway_merge(std::span<const std::vector<int>>{run_storage});
    assert((merged2 == std::vector<int>{1, 2, 3, 3, 3, 4, 8, 9}));
    assert(merged2.size() == 8);
    std::println("赢者树三路归并：1..9（长度守恒 9）；含平局例：1 2 3 3 3 4 8 9");

    std::println("自检通过");
}
