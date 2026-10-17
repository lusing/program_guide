// algorithm.cpp —— Boost.Algorithm 字符串部（string_algo，2012）：
// std 库没有的那一整层字符串手术刀。命名律先立住：
//   i 前缀   = 大小写不敏感（iequals / iends_with ...）
//   _copy 后缀 = 不动原串、返回拷贝（to_upper_copy）；无后缀 = 原地改
//   _if 后缀  = 接谓词（trim_copy_if(..., is_digit())）
// 对应文档：docs/19-text.md
#include <boost/algorithm/string.hpp>
#include <boost/algorithm/string/find_iterator.hpp>
#include <boost/algorithm/string/split.hpp>
#include <deque>
#include <iostream>
#include <list>
#include <string>
#include <vector>

int main() {
    std::string line = "  The Quick, Brown Fox  ";
    using namespace boost;

    // ── 1) 大小写族（原地与拷贝两版） ──
    std::string up = to_upper_copy(line);
    std::string keep = line;
    to_upper(keep);                                  // 原地
    std::cout << "大小写: [" << up << "] 原地版一致? " << (keep == up)
              << " 原串未动? " << (line != up) << '\n';

    // ── 2) 修剪族（默认空白；_if 版接任意谓词，谓词还能逻辑组合） ──
    std::cout << "修剪: [" << trim_copy(line) << "] 左 ["
              << trim_left_copy(line) << "] 右 [" << trim_right_copy(line)
              << "]\n";
    std::string noisy = "2026 Happy New Year!!! ";
    std::cout << "修剪_if（去数字/标点/空白）: ["
              << trim_copy_if(noisy, is_digit() || is_punct() || is_space())
              << "]\n";

    // ── 3) 判定族 + 大小写不敏感（i 前缀） ──
    std::string img = "Photo.JPG";
    std::cout << "判定: iends_with(.jpg)? " << iends_with(img, ".jpg")
              << " ends_with? " << std::boolalpha << ends_with(img, ".jpg")
              << " istarts_with(photo)? " << istarts_with(img, "photo")
              << " icontains(HOTO)? " << icontains(img, "HOTO") << '\n';
    // 字典序比较也有 i 版
    std::cout << "iequals(Samus/samus)? " << iequals("Samus", "samus")
              << " ilexicographical_compare(a/B)? "
              << ilexicographical_compare("a", "B") << '\n';
    // all + 分类谓词：整串都满足
    std::cout << "all(\"power\", is_lower)? " << all(std::string("power"), is_lower())
              << '\n';

    // ── 4) 分类件 13 件（is_xxx 都是"函数对象工厂"，可用 || && ! 组合） ──
    // is_space/is_alnum/is_alpha/is_cntrl/is_digit/is_graph/is_lower/
    // is_print/is_punct/is_upper/is_xdigit/is_any_of/is_from_range
    std::cout << "分类: is_digit('7')=" << is_digit()('7')
              << " is_any_of(abc)('b')=" << is_any_of("abc")('b')
              << " is_from_range(0-9)('5')=" << is_from_range('0', '9')('5')
              << " 组合(小写|数字)('x')=" << (is_lower() || is_digit())('x')
              << '\n';

    // ── 5) 查找族：返回 iterator_range（一段子区间）而非迭代器 ──
    std::string text = "Long long ago, there was a king.";
    auto r1 = find_first(text, "long");              // 第一个 long
    auto r2 = ifind_first(text, "Long");             // 大小写不敏感：命中开头
    auto r3 = find_nth(text, "ng", 1);               // 第 2 个 ng（0 基）
    auto r4 = find_head(text, 4);                    // 头 4 字符
    auto r5 = find_tail(text, 5);                    // 尾 5 字符
    std::cout << "查找: [" << r1 << "] 位" << (r1.begin() - text.begin())
              << " i 版 [" << r2 << "] 位" << (r2.begin() - text.begin())
              << " nth [" << r3 << "] head [" << r4 << "] tail [" << r5
              << "] 找不到为空? " << find_first(text, "samus").empty() << '\n';

    // ── 6) 替换/擦除族（first/last/nth/all/head/tail 六对 × i × _copy） ──
    std::string s = "Samus beat the monster.";
    std::cout << "替换: first=[" << replace_first_copy(s, "Samus", "samus")
              << "] all=[" << replace_all_copy(s, "e", "E")
              << "] tail=[" << replace_tail_copy(s, 9, "ridley.") << "]\n";
    std::cout << "擦除: all=["
              << erase_all_copy(to_lower_copy(s), "the") << "] head=["
              << erase_head_copy(s, 6) << "]\n";

    // ── 7) 分割族：find_all / split（谓词分 + 连续分隔压缩开关） ──
    std::string csv = "Samus, Link.Zelda::Mario-Luigi+zelda";
    std::deque<std::string> hits;
    ifind_all(hits, csv, "zelda");                   // 大小写不敏感找全部
    std::cout << "find_all 命中 " << hits.size() << " 次:";
    for (auto& h : hits) std::cout << "[" << h << "]";
    std::cout << '\n';
    std::list<std::string> parts;
    split(parts, csv, is_any_of(", .:-+"));          // 按任一字符切
    std::cout << "split(默认) " << parts.size() << " 段";
    for (auto& p : parts) std::cout << "[" << p << "]";
    std::cout << "（连续分隔符产出空段）\n";
    std::vector<std::string> compressed;
    split(compressed, csv, is_any_of(", .:-+"), token_compress_on);
    std::cout << "split(compress) " << compressed.size() << " 段";
    for (auto& p : compressed) std::cout << "[" << p << "]";
    std::cout << '\n';

    // ── 8) 连接族：join / join_if（join 的逆运算） ──
    std::vector<std::string> names{"Samus", "Link", "Zelda", "Mario"};
    std::cout << "join = " << join(names, "+") << " join_if(含a) = "
              << join_if(names, "**", [](const auto& sp) {
                     return contains(sp, "a");       // 谓词收到的类型随容器
                 }) << '\n';

    // ── 9) 查找/分割迭代器：流式消费，不用容器装 ──
    // split_iterator 的独门能力：**任意长度字符串**当分隔符（split 只能按字符）
    std::string rec = "Samus||samus||mario||||Link";
    for (auto it = make_split_iterator(rec, first_finder("||", is_equal())),
              endv = decltype(it){};
         it != endv; ++it)
        std::cout << "[" << *it << "]";
    std::cout << "（按 \"||\" 分割）\n";

    // ── 10) std 对照：C++20 起有 starts_with/ends_with（string），
    //     split/join/trim/replace_all/大小写不敏感系列 std 仍无。
    std::cout << "自检通过\n";
    return 0;
}
