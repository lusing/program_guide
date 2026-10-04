#ifndef DS_RECURSION_HPP
#define DS_RECURSION_HPP

#include <span>
#include <utility>
#include <vector>

namespace ds {

// n! = n * (n-1)!，基线 0! = 1。
long long fact(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * fact(n - 1);
}

// 朴素斐波那契：F(n) = F(n-1) + F(n-2)。同一个子问题被反复求解，
// 调用次数随 n 指数膨胀 —— 第 02 章的复杂度分析会量化它有多慢。
long long fib(int n) {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

// 备忘录版：算过的 F(k) 存进数组，每个子问题只解一次，时间降到 O(n)。
long long fib_memo(int n) {
    std::vector<long long> memo(static_cast<size_t>(n) + 1, -1);
    auto solve = [&](auto&& self, int k) -> long long {
        if (k <= 1) {
            return k;
        }
        if (memo[k] != -1) {
            return memo[k];
        }
        return memo[k] = self(self, k - 1) + self(self, k - 2);
    };
    return solve(solve, n);
}

// 递归二分查找：每次比较后区间减半，找不到返回 false。
bool binary_search_rec(std::span<const int> a, int target) {
    if (a.empty()) {
        return false;
    }
    size_t mid = a.size() / 2;
    if (a[mid] == target) {
        return true;
    }
    if (target < a[mid]) {
        return binary_search_rec(a.first(mid), target);
    }
    return binary_search_rec(a.subspan(mid + 1), target);
}

using Move = std::pair<char, char>;

// 汉诺塔：把 n 个盘从 from 搬到 to。
// 第 1 步搬 n-1 个到 via，再搬最大盘，最后把 n-1 个从 via 搬到 to。
void hanoi(int n, char from, char via, char to, std::vector<Move>& moves) {
    if (n == 0) {
        return;
    }
    hanoi(n - 1, from, to, via, moves);
    moves.emplace_back(from, to);
    hanoi(n - 1, via, from, to, moves);
}

}  // namespace ds

#endif  // DS_RECURSION_HPP
