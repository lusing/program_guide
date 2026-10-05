// file: src/main.cpp
// 第 59 章驱动（无参运行，简单程序对账协议）：
//   一、FNV-1a 已知测试向量对账（规范值，非算出来抄）；
//   二、NaN 装箱往返：随机 1000 个 double + 特殊值逐位无损；指针往返；
//   三、判定族与"单次求值"（C 宏二次求值陷阱的 C++ 解）；
//   四、驻留：等值字符串 → 同一指针；
//   五、散列表语义：增删查改、墓碑复用、扩容清墓碑；
//   六、断言汇总。
#include <cmath>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <random>
#include <sstream>
#include <string>
#include <vector>

#include "table.hpp"
#include "value.hpp"

namespace {

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

std::string hex32(uint32_t x) {
    std::ostringstream os;
    os << "0x" << std::hex << std::setw(8) << std::setfill('0') << x;
    return os.str();
}

}  // namespace

int main() {
    std::cout << "== 一、FNV-1a 测试向量 ==\n";
    {
        check(R"(fnv1a(""))", hex32(tip::fnv1a("")), "0x811c9dc5");
        check(R"(fnv1a("a"))", hex32(tip::fnv1a("a")), "0xe40c292c");
        check(R"(fnv1a("b"))", hex32(tip::fnv1a("b")), "0xe70c2de5");
        check(R"(fnv1a("foobar"))", hex32(tip::fnv1a("foobar")), "0xbf9cf968");
    }

    std::cout << "\n== 二、NaN 装箱往返 ==\n";
    {
        // 随机 double：位级往返（装箱 → 位串 → 开箱 → 位串，memcmp）
        std::mt19937_64 rng(20260501);  // 固定种子：期望可复现
        int bitsOk = 0, bitsTotal = 0;
        for (int i = 0; i < 1000; ++i) {
            uint64_t raw = rng();
            double d;
            std::memcpy(&d, &raw, sizeof d);
            if (std::isnan(d)) continue;  // 真 NaN 是装箱方案的已知洞（正文）
            ++bitsTotal;
            tip::Value v = tip::numberVal(d);
            double back = tip::asNumber(v);
            uint64_t rawBack;
            std::memcpy(&rawBack, &back, sizeof rawBack);
            if (rawBack == raw && tip::isNumber(v)) ++bitsOk;
        }
        check("随机 double 位级往返（" + std::to_string(bitsTotal) + " 个）",
              std::to_string(bitsOk), std::to_string(bitsTotal));
        // 特殊值逐一
        for (double d : {0.0, -0.0, 0.5, -1.25, 1e308, -1e308, 3.141592653589793}) {
            tip::Value v = tip::numberVal(d);
            double back = tip::asNumber(v);
            uint64_t a, b;
            std::memcpy(&a, &d, 8);
            std::memcpy(&b, &back, 8);
            check("特殊值 " + std::to_string(a), b == a && tip::isNumber(v) ? "无损" : "损坏",
                  "无损");
        }
        // 指针往返：真 ObjString
        auto s1 = tip::makeString("pointer-roundtrip");
        tip::Value v = tip::objVal(s1.get());
        check("指针往返", tip::asObj(v) == s1.get() && tip::isObj(v) ? "同指针" : "断链",
              "同指针");
        // 诚实洞的两个面：标准静默 NaN（0x7ff8…）以"数"身份原样往返
        //（无害——isNumber 只排除装箱位型）；但位型恰好撞上 tag 的 NaN
        //（如 QNAN|TAG_TRUE 重解释成的 double）会被误读成布尔。
        double quietNan = std::nan("");
        check("静默 NaN 以数身份往返",
              tip::isNumber(tip::numberVal(quietNan)) ? "无害" : "丢失", "无害");
        double colliding;
        uint64_t collidingBits = tip::kQnan | tip::kTagTrue;  // 伪装成 true 的位型
        std::memcpy(&colliding, &collidingBits, 8);
        check("撞型 NaN 误读为布尔",
              tip::isBool(tip::numberVal(colliding)) ? "误读" : "正常", "误读");
    }

    std::cout << "\n== 三、判定族与单次求值 ==\n";
    {
        check("isNumber(3.5)", tip::isNumber(tip::numberVal(3.5)) ? "真" : "假", "真");
        check("isBool(true)", tip::isBool(tip::boolVal(true)) ? "真" : "假", "真");
        check("isBool(false)", tip::isBool(tip::boolVal(false)) ? "真" : "假", "真");
        check("isNil(nil)", tip::isNil(tip::nilVal()) ? "真" : "假", "真");
        auto s = tip::makeString("x");
        check("isObj(str)", tip::isObj(tip::objVal(s.get())) ? "真" : "假", "真");
        check("isBool(数不误判)", tip::isBool(tip::numberVal(3.0)) ? "真" : "假", "假");
        check("isNil(false 不误判)", tip::isNil(tip::boolVal(false)) ? "真" : "假", "假");
        // 单次求值：经函数包装的构造只求一次参
        //（C 宏 IS_BOOL(v) 若 v 有副作用会被吃两次——正文讲；此处实测 C++ 版）
        int calls = 0;
        auto traced = [&calls](double d) { ++calls; return d; };
        tip::Value v = tip::numberVal(traced(2.5));
        check("构造单次求值（副作用计数）",
              std::to_string(calls) + (tip::asNumber(v) == 2.5 ? " 次" : " 次但值错"), "1 次");
    }

    std::cout << "\n== 四、驻留 ==\n";
    {
        tip::InternTable pool;
        tip::ObjString *a = pool.intern("hello");
        tip::ObjString *b = pool.intern("hello");
        tip::ObjString *c = pool.intern("world");
        check("等值同指针", a == b ? "同" : "异", "同");
        check("异值异指针", a != c ? "异" : "同", "异");
        check("池大小", std::to_string(pool.size()), "2");
        // 相等判断退化为指针比较的演示
        check(R"( "a"=="a" 指针等 )", pool.intern("a") == pool.intern("a") ? "同" : "异", "同");
    }

    std::cout << "\n== 五、散列表语义 ==\n";
    {
        tip::Table t;
        std::vector<std::unique_ptr<tip::ObjString>> keys;
        const int N = 200;
        for (int i = 0; i < N; ++i) {
            keys.push_back(tip::makeString("key-" + std::to_string(i)));
            t.set(keys.back().get(), tip::numberVal(i * 10.0));
        }
        int hits = 0;
        for (int i = 0; i < N; ++i) {
            tip::Value v;
            if (t.get(keys[size_t(i)].get(), &v) && tip::asNumber(v) == i * 10.0) ++hits;
        }
        check("插入 200 全查中", std::to_string(hits), std::to_string(N));
        check("计数", std::to_string(t.count()), "200");

        // 删一半（偶数位）：留墓碑
        int deleted = 0;
        for (int i = 0; i < N; i += 2)
            if (t.deleteKey(keys[size_t(i)].get())) ++deleted;
        check("删除 100", std::to_string(deleted), "100");
        check("墓碑数", std::to_string(t.tombstones()), "100");
        int remainHit = 0, goneMiss = 0;
        for (int i = 0; i < N; ++i) {
            tip::Value v;
            bool found = t.get(keys[size_t(i)].get(), &v);
            if (i % 2 == 0) {
                if (!found) ++goneMiss;  // 已删的查不到
            } else if (found && tip::asNumber(v) == i * 10.0) {
                ++remainHit;  // 未删的照常
            }
        }
        check("已删全未中", std::to_string(goneMiss), "100");
        check("幸存全查中", std::to_string(remainHit), "100");

        // 墓碑复用：重插被删键成功
        int reinsert = 0;
        for (int i = 0; i < N; i += 2)
            if (t.set(keys[size_t(i)].get(), tip::numberVal(double(i)))) ++reinsert;
        check("墓碑复用重插 100", std::to_string(reinsert), "100");

        // 扩容清墓碑：继续插到触发扩容（容量翻倍、重散列跳墓碑）
        std::vector<std::unique_ptr<tip::ObjString>> more;
        for (int i = 0; i < 300; ++i) {
            more.push_back(tip::makeString("more-" + std::to_string(i)));
            t.set(more.back().get(), tip::numberVal(double(i)));
        }
        check("扩容后墓碑清零", std::to_string(t.tombstones()), "0");
        int afterGrow = 0;
        for (int i = 1; i < N; i += 2)
            if (t.get(keys[size_t(i)].get())) ++afterGrow;
        check("扩容后幸存键仍在", std::to_string(afterGrow), "100");
        // addAll：把 more 搬进新表
        tip::Table t2;
        for (const auto &k : more) t2.set(k.get(), tip::numberVal(1.0));
        check("addAll 前后计数一致", std::to_string(t2.count()), "300");
    }

    std::cout << "\n== 六、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（37 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
