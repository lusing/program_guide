// 格的统一接口与四类通用构造（spa 第 4 章）。
// 一个"格"只需提供：顶/底两个边界、相等判定、偏序、最小上界。
// 提升(lift)、积(product)、映射(maps)、幂集(powerset)能把简单格组装成
// 程序状态所需的复合格——抽象环境就是"变量集合 → 值格"的映射格。
#pragma once

#include <functional>
#include <map>
#include <optional>
#include <set>
#include <tuple>
#include <utility>

namespace tip {

template <class A>
struct Lattice {
    A topV;
    A botV;
    std::function<bool(const A &, const A &)> eqF;
    std::function<bool(const A &, const A &)> leqF;
    std::function<A(const A &, const A &)> joinF;

    const A &top() const { return topV; }
    const A &bot() const { return botV; }
    bool eq(const A &a, const A &b) const { return eqF(a, b); }
    bool leq(const A &a, const A &b) const { return leqF(a, b); }
    A join(const A &a, const A &b) const { return joinF(a, b); }
};

// ---- 提升：给 A 加一个新底 ⊥=nullopt（"还没有值"） ----
template <class A>
Lattice<std::optional<A>> lift(const Lattice<A> &l) {
    using O = std::optional<A>;
    return Lattice<O>{
        O{l.top()}, O{std::nullopt},
        [](const O &a, const O &b) { return a == b; },
        [l](const O &a, const O &b) {
            if (!b.has_value()) return a == b;        // ⊥ 最小
            if (!a.has_value()) return true;
            return l.leq(*a, *b);
        },
        [l](const O &a, const O &b) {
            if (!a.has_value()) return b;
            if (!b.has_value()) return a;
            return O{l.join(*a, *b)};
        }};
}

// ---- 积：分量各自取 join，序为逐分量序 ----
template <class T, std::size_t... Is, class LTuple>
T tupleJoin(std::index_sequence<Is...>, const LTuple &lats, const T &a, const T &b) {
    return T{std::get<Is>(lats).join(std::get<Is>(a), std::get<Is>(b))...};
}
template <class T, std::size_t... Is, class LTuple>
bool tupleLeq(std::index_sequence<Is...>, const LTuple &lats, const T &a, const T &b) {
    return (... && std::get<Is>(lats).leq(std::get<Is>(a), std::get<Is>(b)));
}

template <class... As>
Lattice<std::tuple<As...>> product(const Lattice<As> &... ls) {
    using T = std::tuple<As...>;
    auto lats = std::make_tuple(ls...);
    T topT{ls.top()...};
    T botT{ls.bot()...};
    return Lattice<T>{
        std::move(topT), std::move(botT),
        [](const T &a, const T &b) { return a == b; },
        [lats](const T &a, const T &b) {
            return tupleLeq<T>(std::make_index_sequence<sizeof...(As)>{}, lats, a, b);
        },
        [lats](const T &a, const T &b) {
            return tupleJoin<T>(std::make_index_sequence<sizeof...(As)>{}, lats, a, b);
        }};
}

// ---- 映射：固定键集上逐点 join；键缺失按底处理 ----
template <class K, class V>
Lattice<std::map<K, V>> maps(const Lattice<V> &l, const std::set<K> &keys) {
    using M = std::map<K, V>;
    M topM, botM;
    for (const K &k : keys) {
        topM.emplace(k, l.top());
        botM.emplace(k, l.bot());
    }
    auto getOrBot = [&botM](const M &m, const K &k) {
        auto it = m.find(k);
        if (it != m.end()) return it->second;
        return botM.at(k);
    };
    return Lattice<M>{
        topM, botM,
        [](const M &a, const M &b) { return a == b; },
        [=](const M &a, const M &b) {
            for (const K &k : keys)
                if (!l.leq(getOrBot(a, k), getOrBot(b, k))) return false;
            return true;
        },
        [=](const M &a, const M &b) {
            M r;
            for (const K &k : keys) r.emplace(k, l.join(getOrBot(a, k), getOrBot(b, k)));
            return r;
        }};
}

// ---- 幂集：join=并，meet=交，序=包含；顶=给定全集（默认为空集） ----
template <class K>
Lattice<std::set<K>> powerset(const std::set<K> &universe = {}) {
    using S = std::set<K>;
    return Lattice<S>{
        universe, S{},
        [](const S &a, const S &b) { return a == b; },
        [](const S &a, const S &b) {
            for (const K &k : a)
                if (!b.count(k)) return false;
            return true;
        },
        [](const S &a, const S &b) {
            S r = a;
            r.insert(b.begin(), b.end());
            return r;
        }};
}

}  // namespace tip
