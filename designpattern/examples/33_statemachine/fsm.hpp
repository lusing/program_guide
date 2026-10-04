#pragma once
// 33 状态机实战：一张 constexpr 转移表，编译期验证与运行期解释共用。
// 第 25 章状态模式是"状态即对象"，这里是"状态即数据"——表驱动版。
#include <optional>
#include <span>
#include <vector>

namespace dp {

enum class Ev { coin, crank, reset };
enum class St { idle, paid, dispensing };

struct Trans { St from; Ev ev; St to; };

// 全局转移表：constexpr——既供运行期解释，也供编译期断言。
inline constexpr Trans kTable[] = {
    {St::idle,       Ev::coin,  St::paid},
    {St::paid,       Ev::crank, St::dispensing},
    {St::paid,       Ev::reset, St::idle},
    {St::dispensing, Ev::reset, St::idle},
};

// 查表：from+ev 唯一定位一条转移；查不到 = 非法事件，返 nullopt。
constexpr std::optional<St> find_next(std::span<const Trans> table, St from, Ev ev) {
    for (const auto& t : table)
        if (t.from == from && t.ev == ev) return t.to;
    return std::nullopt;
}

// 编译期验证两条主转移——表错了在编译期就报，不用等运行。
static_assert(find_next(kTable, St::idle, Ev::coin) == St::paid);
static_assert(find_next(kTable, St::paid, Ev::crank) == St::dispensing);
static_assert(!find_next(kTable, St::idle, Ev::crank).has_value());   // 非法转移也编译期可验

// 运行期解释器：按事件序列走表。非法事件 = 拒绝，停原地（path 少记一站）。
inline std::vector<St> walk(std::span<const Trans> table, St init, std::span<const Ev> evs) {
    std::vector<St> path{init};
    St cur = init;
    for (const Ev ev : evs) {
        if (auto next = find_next(table, cur, ev)) {
            cur = *next;
            path.push_back(cur);
        }   // 非法：不前进、不记录——拒绝次数 = evs 数 - 消耗数
    }
    return path;
}

constexpr const char* name(St s) {
    switch (s) {
        case St::idle:       return "idle";
        case St::paid:       return "paid";
        case St::dispensing: return "dispensing";
    }
    return "?";
}

constexpr const char* name(Ev e) {
    switch (e) {
        case Ev::coin:  return "coin";
        case Ev::crank: return "crank";
        case Ev::reset: return "reset";
    }
    return "?";
}

}  // namespace dp
