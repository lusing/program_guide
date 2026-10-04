// 18 责任链。
#include <cassert>
#include <functional>
#include <memory>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <vector>

#include "chain.hpp"

int main() {
    using namespace dp;

    // ---- 组装链：Manager -> Director -> Ceo（权限递增） ----
    auto chain = std::make_unique<Manager>();
    auto dir = std::make_unique<Director>();
    auto ceo = std::make_unique<Ceo>();
    dir->set_next(std::move(ceo));
    chain->set_next(std::move(dir));

    // ---- 三档金额各归其主 ----
    assert(chain->handle(900) == "manager");     // ≤1000
    assert(chain->handle(3000) == "director");   // 1001..5000
    assert(chain->handle(99999) == "ceo");       // 5001..100000
    std::println("链: 900->manager, 3000->director, 99999->ceo");

    // ---- 超出全链权限：默认拒绝 ----
    assert(chain->handle(200000) == "rejected");
    std::println("链: 200000 -> rejected（无人可接）");

    // ---- 表驱动版：同语义，无继承 ----
    std::vector<std::function<std::optional<std::string>(int)>> table = {
        [](int a) -> std::optional<std::string> {
            return a <= 1000 ? std::optional{"manager"} : std::nullopt;
        },
        [](int a) -> std::optional<std::string> {
            return a <= 5000 ? std::optional{"director"} : std::nullopt;
        },
        [](int a) -> std::optional<std::string> {
            return a <= 100000 ? std::optional{"ceo"} : std::nullopt;
        },
    };
    assert(handle_with_table(table, 900) == "manager");
    assert(handle_with_table(table, 3000) == "director");
    assert(handle_with_table(table, 99999) == "ceo");
    assert(handle_with_table(table, 200000) == "rejected");
    std::println("表: 三档与超限结果与链版完全一致");

    std::println("自检通过");
}
