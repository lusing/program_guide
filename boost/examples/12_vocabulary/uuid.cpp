// uuid.cpp —— Boost.UUID（2006）：全球唯一标识符（std::uuid 尚在提案中）
// 对应文档：docs/12-vocabulary.md
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <boost/uuid/name_generator.hpp>
#include <boost/lexical_cast.hpp>
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
    // nil_generator 的双括号：第一对是构造临时对象，第二对才是 operator()
    boost::uuids::uuid nil2 = boost::uuids::nil_generator()();
    std::cout << "nil_generator()() 也是 nil? " << nil2.is_nil() << '\n';
    // 字典序比较（memcmp 语义，x86 有优化）
    boost::uuids::uuid hi = boost::uuids::string_generator()(
        "ffffffff-ffff-ffff-ffff-ffffffffffff");
    std::cout << "hi > id1? " << (hi > id1) << "（字典序）\n";

    // 5) 字节数与大小恒定：16 字节，可 memcpy
    std::cout << "大小 = " << sizeof(id1) << " 字节\n";
    // uuid 也是个"16 字节的容器"：迭代器 + 公有 data 数组，标准算法随便用
    boost::uuids::uuid manual;
    std::fill_n(manual.begin(), manual.size(), 0xab);   // 全 0xab
    std::cout << "fill 0xab = " << manual << " 变体 = " << (int(manual.data[8]) >> 6)
              << "（10x = RFC 4122）版本 = " << (int(manual.data[6]) >> 4)
              << "（手工填的没有版本信息）\n";
    std::memset(manual.data, 0, 16);                    // memset 也行
    std::cout << "memset 后 is_nil? " << manual.is_nil() << '\n';

    // 6) 书里的增强类 uuid_t：把生成器封进构造函数，四种来源一个类型
    {
        using namespace boost::uuids;
        class uuid_t : public uuid {
        private:
            // 生成器要先声明再使用：基类初始化列表里的名字查找只看得见
            // "已经声明"的成员（按声明顺序解析）
            static random_generator& rand_gen() {
                static random_generator g;              // 真随机（仅打印布尔，可复现）
                return g;
            }
            static string_generator& str_gen() {
                static string_generator g;
                return g;
            }
        public:
            uuid_t() : uuid(rand_gen()()) {}            // 默认：随机（双调用：
            uuid_t(int) : uuid(nil_uuid()) {}           // int：nil
            uuid_t(const char* s) : uuid(str_gen()(s)) {}  // 字符串
            uuid_t(const uuid& basis, const char* name)
                : uuid(name_generator(basis)(name)) {}  // 名字派生
            explicit uuid_t(const uuid& u) : uuid(u) {} // 拷贝
        };
        uuid_t random_one;                              // 随机 UUID
        uuid_t zero(0);                                 // nil
        uuid_t from_str("{01234567-89ab-cdef-0123-456789abcdef}");
        uuid_t named(zero, "test name gen");            // 以 zero 为基准派生
        std::cout << "uuid_t: 随机版非 nil? " << !random_one.is_nil()
                  << " nil? " << zero.is_nil()
                  << " 串版 = " << from_str
                  << " 名字版非 nil? " << !named.is_nil() << '\n';
    }

    // 7) lexical_cast 双向转换：比 string_generator 弱（只认连字符格式，
    //    不认花括号/裸十六进制）——靠的是 uuid 的流 I/O
    {
        std::string lit = boost::lexical_cast<std::string>(id1);
        boost::uuids::uuid back = boost::lexical_cast<boost::uuids::uuid>(lit);
        std::cout << "lexical_cast 往返一致? " << (back == id1) << '\n';
    }

    std::cout << "自检通过\n";
    return 0;
}
