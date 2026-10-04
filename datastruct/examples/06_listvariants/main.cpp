#include <cassert>
#include <print>
#include <vector>

#include "indirect_list.hpp"
#include "polynomial.hpp"
#include "static_list.hpp"
#include "union_find.hpp"

// 06 线性表的变种：静态链表（模拟指针）、间接表、并查集、稀疏多项式

int main() {
    // ═══ 静态链表：槽位必须被复用 ═══
    ds::StaticList<int, 8> sl;
    const int first = sl.push_front(7);
    assert(first == 0);
    sl.pop_front();                          // 槽 0 被还回 freelist
    const int reused = sl.alloc_node(9);     // 暂取一个未挂链的节点验证复用
    assert(reused == first);                 // 再分配拿到同一个槽号
    sl.free_node(reused);                    // 还回，供下面正式建表时再次取用
    std::println("静态链表：释放槽号 {}，再分配得到槽号 {}（同一槽位复用）",
                 first, reused);
    const int s1 = sl.push_front(3);
    const int s2 = sl.push_front(1);
    const int s3 = sl.push_front(4);
    assert(s1 == first && s2 > s1 && s3 > s2);  // 头插再次取回槽 0，其余顺延
    std::vector<int> chain;
    for (int cur = sl.head(); cur != -1; cur = sl.next(cur)) {
        chain.push_back(sl.value(cur));
    }
    assert((chain == std::vector<int>{4, 1, 3}));
    std::println("  沿 next 遍历：{}（头槽 {}）", chain, sl.head());

    // ═══ 间接表：排序只动指针，不动数据 ═══
    struct Item {
        int key;
        int id;
        bool operator<(const Item& other) const { return key < other.key; }
        bool operator==(const Item&) const = default;
    };
    const std::vector<Item> items{
        {30, 0}, {10, 1}, {40, 2}, {20, 3}, {50, 4},
    };
    ds::IndirectList<Item> il(items);
    auto id_order = [&] {
        std::vector<int> ids;
        for (std::size_t i = 0; i < il.size(); ++i) {
            ids.push_back(il.pointer_at(i)->id);
        }
        return ids;
    };
    const std::vector<int> before = id_order();
    assert((before == std::vector<int>{0, 1, 2, 3, 4}));
    il.sort();
    const std::vector<int> after = id_order();
    assert((after == std::vector<int>{1, 3, 0, 2, 4}));  // 按 key: 10,20,30,40,50
    assert(before != after);
    assert(il.data_untouched());
    std::vector<int> sorted_keys;
    for (std::size_t i = 0; i < il.size(); ++i) {
        sorted_keys.push_back(il.at(i).key);
    }
    std::println("间接表：排序后指针所指对象编号序 {}，键序 {}", after, sorted_keys);
    std::println("  数据对象本身未被搬动或改写：{}", il.data_untouched());

    // ═══ 并查集：两次 unite 后的根与大小 ═══
    ds::UnionFind uf(5);
    assert(uf.unite(0, 1));
    assert(uf.unite(2, 3));
    assert(uf.find(0) == uf.find(1));
    assert(uf.find(2) == uf.find(3));
    assert(uf.find(0) != uf.find(2));
    assert(uf.size(0) == 2 && uf.size(2) == 2 && uf.size(4) == 1);
    assert(uf.count() == 3);
    assert(!uf.unite(1, 0));               // 已同集：false
    assert(uf.unite(1, 3));               // 再合并两大集合
    assert(uf.find(3) == uf.find(0));
    assert(uf.size(0) == 4 && uf.size(4) == 1);
    assert(uf.count() == 2);
    std::println("并查集：合并后根为 {}，集合大小 {}，等价类数 {}",
                 uf.find(3), uf.size(0), uf.count());

    // ═══ 稀疏多项式：零项消失 ═══
    const ds::Polynomial p{{1, 1}, {1, 0}};   // x + 1
    const ds::Polynomial q{{1, 1}, {-1, 0}};  // x - 1
    const ds::Polynomial sum = p + q;
    const ds::Polynomial prod = p * q;
    assert(sum.term_count() == 1);
    assert(sum.term(0) == ds::Term(2.0, 1));
    assert(prod.term_count() == 2);
    assert(prod.term(0) == ds::Term(1.0, 2));
    assert(prod.term(1) == ds::Term(-1.0, 0));
    std::println("多项式：({}) + ({}) = {}", p.to_string(), q.to_string(),
                 sum.to_string());
    std::println("  （{}项，恰为 2x）", sum.term_count());
    std::println("多项式：({}) * ({}) = {}", p.to_string(), q.to_string(),
                 prod.to_string());
    std::println("  （{}项，常数抵消后恰为 x^2 与 -1）", prod.term_count());

    std::println("自检通过");
}
