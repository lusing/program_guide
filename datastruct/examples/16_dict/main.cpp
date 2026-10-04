#include <cassert>
#include <optional>
#include <print>
#include <string>
#include <string_view>

#include "hash_chained.hpp"
#include "hash_open.hpp"
#include "skip_list.hpp"

// 16 字典：跳表、链地址哈希、开放定址哈希

namespace {

// 给跳表灌入同一份固定数据（顺序也相同），保证两次"掷硬币"序列可比。
template <class Table>
void fill_skip(Table& t) {
    t.insert(3, "three");
    t.insert(1, "one");
    t.insert(4, "four");
    t.insert(5, "five");
    t.insert(9, "nine");
    t.insert(2, "two");
    t.insert(6, "six");
    t.insert(3, "three");  // 重复键：只更新，不加节点
}

// 两种哈希表共用同一套验收：30 键 → 删 10 键 → rehash。
template <class Hash>
void test_hash(Hash& h, std::string_view name) {
    for (int i = 0; i < 30; ++i) {
        h.insert(i, i * i);
    }
    for (int i = 0; i < 30; ++i) {
        assert(h.get(i) == i * i);
    }
    for (int i = 0; i < 10; ++i) {
        assert(h.erase(i));
    }
    for (int i = 10; i < 30; ++i) {
        assert(h.get(i) == i * i);  // 其余键不受删除影响
    }
    for (int i = 0; i < 10; ++i) {
        assert(!h.get(i).has_value());
    }
    h.rehash(67);
    assert(h.size() == 20);
    for (int i = 10; i < 30; ++i) {
        assert(h.get(i) == i * i);  // rehash 只搬位置、内容不变
    }
    std::println("{}：30 键全部命中；删除 10 键后其余仍中；rehash 后内容一致", name);
}

}  // namespace

int main() {
    // ═══ 跳表：插入、遍历、更新、删除 ═══
    ds::SkipList<int, std::string> sk;
    fill_skip(sk);
    assert(sk.size() == 7);
    for (const auto& [k, v] : sk.sorted_entries()) {
        assert(sk.get(k) == v);
    }
    const std::vector<int> key_order{1, 2, 3, 4, 5, 6, 9};
    std::vector<int> got_keys;
    for (const auto& [k, v] : sk.sorted_entries()) {
        got_keys.push_back(k);
    }
    assert(got_keys == key_order);  // 底层链严格升序
    assert(sk.erase(4));
    assert(!sk.contains(4));
    assert(sk.get(4) == std::nullopt);
    assert(sk.size() == 6);
    std::println("跳表：7 键全部命中，底层按键升序；重复键只更新；删除 4 后未命中");

    // ═══ 确定性：同样数据独立灌两遍，层数统计必须逐字节相同 ═══
    ds::SkipList<int, std::string> a;
    ds::SkipList<int, std::string> b;
    fill_skip(a);
    fill_skip(b);
    assert(a.size() == b.size());
    assert(a.level() == b.level());
    assert(a.total_levels() == b.total_levels());
    std::println("跳表确定性：两份独立表的层数、层级总数完全一致（固定种子 5489）");

    // ═══ 两种哈希表：同一套验收 ═══
    ds::ChainedHash<int, int> chained;
    ds::OpenAddressHash<int, int> open;
    test_hash(chained, "链地址哈希");
    test_hash(open, "开放定址哈希");

    // ═══ 4 桶小表：同余键 0/4/8 必须各自独立、互不覆盖 ═══
    ds::ChainedHash<int, int> c4(4);
    ds::OpenAddressHash<int, int> o4(4);
    for (const auto& [k, v] :
         std::initializer_list<std::pair<int, int>>{{0, 100}, {4, 200}, {8, 300}}) {
        c4.insert(k, v);
        o4.insert(k, v);
    }
    assert(c4.get(0) == 100 && c4.get(4) == 200 && c4.get(8) == 300);
    assert(o4.get(0) == 100 && o4.get(4) == 200 && o4.get(8) == 300);
    std::println("4 桶小表：同余键 0/4/8 互不覆盖（值 100/200/300 均可独立取回）");

    std::println("自检通过");
}
