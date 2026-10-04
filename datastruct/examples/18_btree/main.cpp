#include <cassert>
#include <print>
#include <stdexcept>
#include <vector>

#include "b_tree.hpp"
#include "bplus_tree.hpp"
#include "inverted_index.hpp"

// 18 B 树 / B+ 树 / 倒排索引

int main() {
    // ═══ 3 阶 B 树（2-3 树）：逐步插入 1..10，每步全部键必须恰为 1..i ═══
    ds::BTree<int> bt3;
    const std::vector<std::vector<int>> root_checks{
        {2},       // 插 3 后：叶分裂，2 上推，新根
        {2},       // 插 4 后：4 进右叶，根不变
        {2, 4},    // 插 5 后：右叶分裂，根吸收 4
        {4},       // 插 7 后：根分裂，4 成为新根
        {4},       // 插 9 后：下层分裂被内部节点吸收，根不变
        {4},       // 插 10 后
    };
    size_t check_idx = 0;
    for (int x = 1; x <= 10; ++x) {
        bt3.insert(x);
        std::vector<int> expected;
        for (int v = 1; v <= x; ++v) {
            expected.push_back(v);
        }
        assert(bt3.all_keys() == expected);
        if (x == 3 || x == 4 || x == 5 || x == 7 || x == 9 || x == 10) {
            assert(bt3.root_keys() == root_checks[check_idx++]);
        }
    }
    std::println("B 树（3 阶）：插入 1..10 每步全部键有序；分裂时刻根键依次为 "
                 "{{2}}、{{2}}、{{2,4}}、{{4}}、{{4}}、{{4}}");

    for (int x = 1; x <= 10; ++x) {
        assert(bt3.contains(x));
    }
    assert(!bt3.contains(0));
    assert(!bt3.contains(11));
    bool dup_threw = false;
    try {
        bt3.insert(5);
    } catch (const std::invalid_argument&) {
        dup_threw = true;
    }
    assert(dup_threw);
    std::println("B 树：contains 1..10 全中、0 与 11 未中；重复键抛异常");

    // ═══ 4 阶 B 树对照：计划所引"插 4 后根键 {3}"实为 4 阶行为 ═══
    ds::BTree<int> bt4{4};
    for (int x = 1; x <= 4; ++x) {
        bt4.insert(x);
    }
    assert(bt4.root_keys() == std::vector<int>{3});
    std::println("B 树（4 阶）对照：插 1..4 后根键 {{3}}（节点可容 3 键，第 4 键触发分裂）");

    // ═══ B+ 树：插入 1..10 ═══
    ds::BPlusTree bpt;
    for (int x = 1; x <= 10; ++x) {
        bpt.insert(x);
    }
    for (int x = 1; x <= 10; ++x) {
        assert(bpt.contains(x));
    }
    assert(!bpt.contains(11));
    std::println("B+ 树：插入 1..10 后 contains 全中、11 未中");

    const std::vector<int> rng = bpt.range(3, 7);
    assert((rng == std::vector<int>{3, 4, 5, 6, 7}));
    // 全范围扫描即整张叶链：不重不漏恰为 1..10
    assert((bpt.range(1, 10) == std::vector<int>{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}));
    assert((bpt.range(8, 12) == std::vector<int>{8, 9, 10}));
    std::println("B+ 树范围查询 [3,7]：3 4 5 6 7；叶链整体不重不漏为 1..10");

    bool bplus_dup_threw = false;
    try {
        bpt.insert(7);
    } catch (const std::invalid_argument&) {
        bplus_dup_threw = true;
    }
    assert(bplus_dup_threw);
    std::println("B+ 树：重复键抛异常");

    // ═══ 倒排索引：三篇固定文档 ═══
    ds::InvertedIndex index;
    index.add_doc(1, "data structure and algorithm");
    index.add_doc(2, "algorithm is data in motion");
    index.add_doc(3, "data is the new structure");
    assert(index.doc_count() == 3);
    assert((index.postings("data") == std::vector<int>{1, 2, 3}));
    assert((index.postings("algorithm") == std::vector<int>{1, 2}));
    assert((index.postings("structure") == std::vector<int>{1, 3}));
    assert((index.postings("is") == std::vector<int>{2, 3}));
    assert((index.postings("motion") == std::vector<int>{2}));
    assert(index.postings("tree").empty());
    std::println("倒排索引：data→1,2,3；algorithm→1,2；structure→1,3；未登录词为空");

    bool dup_doc_threw = false;
    try {
        index.add_doc(2, "duplicate id");
    } catch (const std::invalid_argument&) {
        dup_doc_threw = true;
    }
    assert(dup_doc_threw);
    std::println("倒排索引：重复文档 id 抛异常；共收录 3 篇");

    std::println("自检通过");
}
