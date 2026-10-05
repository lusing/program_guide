#include "lattice_demo.hpp"

#include <map>
#include <optional>
#include <set>
#include <sstream>
#include <string>
#include <tuple>

#include "lattice.hpp"
#include "sign.hpp"

namespace tip {
namespace {

std::string optShow(const std::optional<int> &o) {
    return o.has_value() ? signShow(*o) : "⊥";
}

std::string pairShow(const std::tuple<int, int> &t) {
    return "(" + signShow(std::get<0>(t)) + "," + signShow(std::get<1>(t)) + ")";
}

std::string mapShow(const std::map<std::string, int> &m) {
    std::string r = "{";
    bool first = true;
    for (const auto &[k, v] : m) {
        if (!first) r += ",";
        r += k + "=" + signShow(v);
        first = false;
    }
    return r + "}";
}

std::string setShow(const std::set<std::string> &s) {
    std::string r = "{";
    bool first = true;
    for (const std::string &k : s) {
        if (!first) r += ",";
        r += k;
        first = false;
    }
    return r + "}";
}

}  // namespace

std::string latticeDemo() {
    std::ostringstream out;
    out << "lattice constructors over the sign domain (fixed join examples):\n";

    Lattice<int> sign = signLatticeDomain();

    // lift：新底 ⊥ 与符号元素的 join。
    Lattice<std::optional<int>> lifted = lift(sign);
    std::optional<int> none, plus = SPLUS, zero = SZERO, minus = SMINUS;
    out << "lift(sign): join(⊥,+) = " << optShow(lifted.join(none, plus)) << '\n';
    out << "lift(sign): join(0,−) = " << optShow(lifted.join(zero, minus)) << '\n';

    // 积：两个符号分量分别 join，0⊔+=⊤，+⊔−=⊤。
    Lattice<std::tuple<int, int>> prod = product(sign, sign);
    auto a = std::make_tuple(SZERO, SPLUS);
    auto b = std::make_tuple(SPLUS, SMINUS);
    out << "product(sign,sign): join((0,+),(+,−)) = " << pairShow(prod.join(a, b)) << '\n';

    // 映射：两变量状态逐变量 join。
    Lattice<std::map<std::string, int>> stateLat =
        maps<std::string, int>(sign, {"x", "y"});
    std::map<std::string, int> s1{{"x", SZERO}, {"y", SBOT}};
    std::map<std::string, int> s2{{"x", SPLUS}, {"y", SPLUS}};
    out << "maps{x,y}->sign: join({x=0,y=⊥},{x=+,y=+}) = "
        << mapShow(stateLat.join(s1, s2)) << '\n';

    // 幂集：并集（第 26 章四大 DFA 的格）。
    Lattice<std::set<std::string>> powLat = powerset<std::string>();
    std::set<std::string> one{"a"}, two{"b"};
    out << "powerset: join({a},{b}) = " << setShow(powLat.join(one, two)) << '\n';

    return out.str();
}

}  // namespace tip
