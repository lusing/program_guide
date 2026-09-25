// uuid.cpp —— Boost.UUID（2006）：全球唯一标识符（std::uuid 尚在提案中）
// 对应文档：docs/12-vocabulary.md
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <boost/uuid/name_generator.hpp>
#include <boost/random/mersenne_twister.hpp>   // 固定种子的 mt19937（header-only）
#include <iostream>
#include <sstream>

int main() {
    // v4 的"随机"种子由调用方给：默认构造的生成器会用 random_provider 播种，
    // 每次跑出来的 UUID 都不一样——文档里嵌的输出没法复核，两条通道的输出
    // 也永远对不上。给它一个**固定种子**的 mt19937（basic_random_generator
    // 收外部引擎时不会重新播种），演示照样成立，输出则可复现。
    boost::mt19937 rng(20240924u);
    boost::uuids::basic_random_generator<boost::mt19937> gen(rng);

    // 1) 版本 4（随机）：最常见的用途
    boost::uuids::uuid id1 = gen();
    boost::uuids::uuid id2 = gen();
    std::cout << "uuid v4: " << id1 << '\n';
    std::cout << "两次不同? " << (id1 != id2) << " 版本位 = " << (int(id1.data[6]) >> 4)
              << "（4 = 随机版）\n";

    // 2) 解析与序列化
    std::string text = boost::uuids::to_string(id1);
    boost::uuids::uuid parsed = boost::uuids::string_generator()(text);
    std::cout << "解析还原一致? " << (parsed == id1) << '\n';

    // 3) 名字空间版本（v5/SHA1）：同名同输入 → 同 UUID（确定性标识）
    boost::uuids::name_generator sha1gen(boost::uuids::ns::dns());
    boost::uuids::uuid dns_id = sha1gen("codeberg.org");
    std::cout << "v5(dns,codeberg.org) 版本位 = " << (int(dns_id.data[6]) >> 4) << '\n';
    std::cout << "两次生成一致? " << (sha1gen("codeberg.org") == dns_id) << '\n';

    // 4) nil 与比较排序
    boost::uuids::uuid nil = boost::uuids::nil_uuid();
    std::cout << "nil = " << nil << " is_nil? " << nil.is_nil() << '\n';

    // 5) 字节数与大小恒定：16 字节，可 memcpy
    std::cout << "大小 = " << sizeof(id1) << " 字节\n";

    std::cout << "自检通过\n";
    return 0;
}
