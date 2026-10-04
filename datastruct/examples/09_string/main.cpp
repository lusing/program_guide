#include <cassert>
#include <print>
#include <string_view>
#include <vector>

#include "string_index.hpp"
#include "string_match.hpp"

// 09 串：BF/KMP 模式匹配 + 单词索引

int main() {
    using std::string_view;
    constexpr string_view text = "data structure is about data and how data is stored";

    // ═══ KMP 的 pi 表：手工值 [0,0,1,2,3,0,1] ═══
    const std::vector<size_t> pi = ds::build_pi("ababaca");
    const std::vector<size_t> pi_expected{0, 0, 1, 2, 3, 0, 1};
    assert(pi == pi_expected);
    std::println("build_pi(\"ababaca\") = [0,0,1,2,3,0,1]");

    // ═══ BF 与 KMP 命中位置一致；起始偏移 pos 生效 ═══
    assert(ds::bf_find(text, "data") == 0);
    assert(ds::kmp_find(text, "data") == 0);
    assert(ds::bf_find(text, "data", 1) == 24);
    assert(ds::kmp_find(text, "data", 1) == 24);
    assert(ds::bf_find(text, "data", 25) == 37);
    assert(ds::kmp_find(text, "data", 25) == 37);
    assert(ds::bf_find(text, "structure") == 5);
    assert(ds::kmp_find(text, "stored") == 45);
    std::println("\"data\" 各次出现起点：0、24、37（BF 与 KMP 一致）");
    std::println("pos 偏移：从头找 \"data\" 得 0，从 1 起得 24，从 25 起得 37");

    // ═══ 未命中与边界：空文本、空模式、模式超长 ═══
    assert(ds::bf_find(text, "trie") == ds::npos);
    assert(ds::kmp_find(text, "trie") == ds::npos);
    assert(ds::bf_find(text, "datamining") == ds::npos);
    assert(ds::kmp_find("", "a") == ds::npos);
    assert(ds::bf_find("", "") == 0);
    assert(ds::bf_find(text, "", 5) == 5);
    assert(ds::bf_find(text, "", 1000) == text.size());
    assert(ds::build_pi("").empty());
    assert(ds::build_pi("a") == std::vector<size_t>{0});
    std::println("未命中返回 npos；空文本/空模式/超长模式边界正确");

    // ═══ 单词索引：去重、按词排序、二分查词 ═══
    const std::vector<ds::WordPos> idx = ds::build_index(text);
    const std::vector<std::string> words{
        "about", "and", "data", "how", "is", "stored", "structure",
    };
    assert(idx.size() == words.size());
    for (size_t i = 0; i < idx.size(); ++i) {
        assert(idx[i].word == words[i]);
    }
    const ds::WordPos* p_data = ds::lookup(idx, "data");
    assert(p_data != nullptr && p_data->pos == 0);
    const ds::WordPos* p_structure = ds::lookup(idx, "structure");
    assert(p_structure != nullptr && p_structure->pos == 5);
    assert(ds::lookup(idx, "missing") == nullptr);
    std::println("索引共 {} 个不同词，lookup(\"data\") 首次出现于位置 0，未登录词返回 nullptr",
                 idx.size());

    std::println("自检通过");
}
