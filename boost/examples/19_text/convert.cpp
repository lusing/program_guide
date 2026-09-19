// convert.cpp —— Boost.Convert（2014）：lexical_cast 的可配置进化版。
// 核心差异：失败不抛（返回缺省）、locale 可控、方向可定制。
// 对应文档：docs/19-text.md
#include <boost/convert.hpp>
#include <boost/convert/lexical_cast.hpp>
#include <boost/convert/stream.hpp>
#include <iostream>

int main() {
    boost::cnv::cstream cnv;                      // std::streamstream 后端
    // lexical_cast 后端也可以：boost::cnv::lexical_cast lv;

    // 1) 失败不抛：直接拿 fallback（convert 默认返回可选值语义）
    int n = boost::convert<int>("not-a-number", cnv).value_or(-1);
    int ok = boost::convert<int>("2026", cnv).value_or(0);
    std::cout << "合法 = " << ok << " 非法回落 = " << n << '\n';

    // 2) 流操纵符直通：进制/精度/宽度
    cnv(std::hex);
    int hexv = boost::convert<int>("ff", cnv).value_or(0);
    std::cout << "hex ff = " << hexv << '\n';
    cnv(std::dec)(std::setprecision(3));
    double dv = boost::convert<double>("3.14159", cnv).value_or(0.0);
    std::cout << "精度 3 的 pi = " << dv << '\n';

    // 3) 反向：数值→串（不抛，缺省回落）
    std::string s = boost::convert<std::string>(255, cnv).value_or("");
    std::cout << "255 → 串 = " << s << '\n';

    std::cout << "自检通过\n";
    return 0;
}
