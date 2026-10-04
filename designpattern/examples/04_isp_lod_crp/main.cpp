// 04 接口隔离 + 迪米特 + 合成复用。
#include <cassert>
#include <memory>
#include <print>

#include "crp.hpp"
#include "isp.hpp"
#include "lod.hpp"

int main() {
    using namespace dp;

    // ---- ISP：客户端只看见自己需要的小接口 ----
    OldPrinter old_p;
    assert(old_p.print("hi") == "print(hi)");
    MultiMachine mm;
    Printable& as_printer = mm;   // 当打印机用
    Faxable& as_fax = mm;         // 当传真机用
    assert(as_printer.print("doc") == "print(doc)");
    assert(as_fax.fax("doc") == "fax(doc)");
    std::println("ISP: {} / {}", as_printer.print("doc"), as_fax.fax("doc"));

    // ---- LoD：收银员只问"够不够"，不摸钱包 ----
    Customer rich{100};
    Customer poor{5};
    Checkout co;
    assert(co.scan(rich, 30) == true);
    assert(co.scan(poor, 30) == false);
    assert(rich.pay(30) && rich.cash() == 70);
    std::println("LoD: pay(30) 后 cash={}", rich.cash());

    // ---- 合成复用：武器运行期可换 ----
    Player p{std::make_unique<Sword>()};
    assert(p.armed_with() == "sword" && p.strike() == 10);
    p.rearm(std::make_unique<Axe>());
    assert(p.armed_with() == "axe" && p.strike() == 25);
    std::println("CRP: {} -> strike={}", p.armed_with(), p.strike());

    std::println("自检通过");
}
