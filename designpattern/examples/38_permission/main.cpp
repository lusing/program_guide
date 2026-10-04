// 38 权限校验管道：三关（auth/role/time）按序过闸，拒因与放行全部可断言。
#include <cassert>
#include <print>
#include <string>

#include "pipeline.hpp"

int main() {
    using namespace dp;

    Api api;
    api.add_guard(auth_guard());
    api.add_guard(role_guard());
    api.add_guard(time_guard());   // 管道顺序 = add 顺序：auth -> role -> time

    // anon+write：第一关 auth 拒（why 首字符 'a'）
    auto v1 = api.check({"anon", "write", false, 9});
    assert(!v1.allow);
    assert(v1.why[0] == 'a');
    std::println("auth线: anon+write 被第一关拒，why=auth");

    // admin+write@9：三关全过，allow
    auto v2 = api.check({"root", "write", true, 9});
    assert(v2.allow && v2.why == "ok");
    std::println("放行线: admin+write@9 三关全过");

    // user+read@9：auth 过、role 过（read 放行非 admin）、time 过
    auto v3 = api.check({"tom", "read", false, 9});
    assert(v3.allow && v3.why == "ok");
    std::println("放行线: user+read@9 三关全过");

    // user+write@23：按管道顺序 role 先拒（why 首字符 'r'）
    auto v4 = api.check({"tom", "write", false, 23});
    assert(!v4.allow);
    assert(v4.why[0] == 'r');
    std::println("role线: user+write@23 被第二关拒（管道顺序决定拒因）");

    // admin+write@23：role 过（admin），time 拒（why 首字符 't'）
    auto v5 = api.check({"root", "write", true, 23});
    assert(!v5.allow);
    assert(v5.why[0] == 't');
    std::println("time线: admin+write@23 被第三关拒");

    // 只挂一关：管道可裁剪——同一规则库按需组合
    Api thin;
    thin.add_guard(auth_guard());
    auto v6 = thin.check({"anon", "read", false, 9});
    assert(!v6.allow && v6.why[0] == 'a');
    std::println("裁剪线: 只挂 auth 的管道同样工作");

    std::println("自检通过");
}
