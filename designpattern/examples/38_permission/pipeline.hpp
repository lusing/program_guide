#pragma once
// 38 权限校验管道：职责链（Guard 序列，返 false 即终止）+ 策略（每个 guard 一条规则）
// + 代理（Api 是真服务的门面守卫）。Guard 是 std::function——第 30/31 章擦除件的复用。
#include <functional>
#include <string>
#include <utility>
#include <vector>

namespace dp {

struct Request {
    std::string user;
    std::string action;
    bool admin = false;
    int hour = 0;
};

struct Verdict {
    bool allow = false;
    std::string why;
};

// Guard：返 true = 通过、继续下一关；返 false = 拒绝、终止，why 必须已填。
using Guard = std::function<bool(Request&, Verdict&)>;

// 策略一：认证——匿名用户一律拒绝。
inline Guard auth_guard() {
    return [](Request& r, Verdict& v) {
        if (r.user == "anon") {
            v = {false, "auth: anonymous"};
            return false;
        }
        return true;
    };
}

// 策略二：角色——非 admin 只许 read。
inline Guard role_guard() {
    return [](Request& r, Verdict& v) {
        if (!r.admin && r.action != "read") {
            v = {false, "role: non-admin restricted to read"};
            return false;
        }
        return true;
    };
}

// 策略三：时段——8-22 点之外拒绝。
inline Guard time_guard() {
    return [](Request& r, Verdict& v) {
        if (r.hour < 8 || r.hour > 22) {
            v = {false, "time: outside 8-22"};
            return false;
        }
        return true;
    };
}

// 管道：按 add_guard 的顺序依次过闸，第一关拒绝即返回。
class Api {
public:
    void add_guard(Guard g) { guards_.push_back(std::move(g)); }

    Verdict check(Request r) {
        Verdict v{true, "ok"};
        for (const auto& g : guards_) {
            if (!g(r, v)) return v;   // 职责链：第一个否决终止整个管道
        }
        return v;
    }

private:
    std::vector<Guard> guards_;
};

}  // namespace dp
