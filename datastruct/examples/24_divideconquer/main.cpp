#include <array>
#include <cassert>
#include <cstddef>
#include <print>
#include <stdexcept>
#include <vector>

#include "divconquer.hpp"

// 24 分而治之：残缺棋盘铺 tromino、成对分治 min-max、快速选择

int main() {
    // ═══ 残缺棋盘：4x4，缺格 (1,2)，应铺出 5 块 tromino ═══
    {
        const ds::Board board = ds::tromino(1, 2);
        std::println("残缺棋盘（缺格 (1,2)，0 为缺格，数字为铺块编号）：");
        std::array<int, 6> count{};
        for (int r = 0; r < 4; ++r) {
            for (int c = 0; c < 4; ++c) {
                std::print("{:3}", board[r][c]);
                ++count[static_cast<std::size_t>(board[r][c])];
            }
            std::println("");
        }
        assert(count[0] == 1);
        for (int t = 1; t <= 5; ++t) {
            assert(count[static_cast<std::size_t>(t)] == 3);
        }
        std::println("铺块校验：0 出现 1 次，编号 1..5 各出现 3 次（15 格 ÷ 每块 3 格 = 5 块）");
    }

    // ═══ min_max：偶数长度 n=4，成对分治 3n/2-2 = 4 次比较 ═══
    {
        const std::vector<int> a{5, 2, 9, 1};
        const ds::MM r = ds::min_max(a);
        assert(r.min == 1);
        assert(r.max == 9);
        assert(r.comparisons == 4);
        std::println("min_max {{5,2,9,1}}：min={} max={} 比较 {} 次（3n/2-2）",
                     r.min, r.max, r.comparisons);
    }

    // ═══ min_max：单元素，0 次比较 ═══
    {
        const std::vector<int> one{42};
        const ds::MM r = ds::min_max(one);
        assert(r.min == 42);
        assert(r.max == 42);
        assert(r.comparisons == 0);
        std::println("min_max 单元素 {{42}}：min={} max={} 比较 {} 次",
                     r.min, r.max, r.comparisons);
    }

    // ═══ min_max：奇数长度 n=5，3(n-1)/2 = 6 次比较 ═══
    {
        const std::vector<int> odd{3, 1, 4, 1, 5};
        const ds::MM r = ds::min_max(odd);
        assert(r.min == 1);
        assert(r.max == 5);
        assert(r.comparisons == 6);
        std::println("min_max 奇数长 {{3,1,4,1,5}}：min={} max={} 比较 {} 次（3(n-1)/2）",
                     r.min, r.max, r.comparisons);
    }

    // ═══ quickselect：同一夹具的 k=2 / k=0 / k=n-1（各用独立副本，划分会重排）═══
    {
        std::vector<int> a{7, 2, 5, 1, 8, 3};
        const int k2 = ds::quickselect(a, 2);
        assert(k2 == 3);
        std::vector<int> b{7, 2, 5, 1, 8, 3};
        const int k0 = ds::quickselect(b, 0);
        assert(k0 == 1);
        std::vector<int> c{7, 2, 5, 1, 8, 3};
        const int k5 = ds::quickselect(c, 5);
        assert(k5 == 8);
        std::println("quickselect {{7,2,5,1,8,3}}：k=2 → {}，k=0 → {}，k=5 → {}",
                     k2, k0, k5);
    }

    // ═══ 前提违规：quickselect k 越界、min_max 空区间 ═══
    {
        bool threw = false;
        try {
            std::vector<int> a{1, 2, 3};
            (void)ds::quickselect(a, 3);
        } catch (const std::out_of_range&) {
            threw = true;
        }
        assert(threw);
        std::println("quickselect k 越界：抛出异常");

        bool empty_threw = false;
        try {
            const std::vector<int> a;
            (void)ds::min_max(a);
        } catch (const std::invalid_argument&) {
            empty_threw = true;
        }
        assert(empty_threw);
        std::println("min_max 空区间：抛出异常");
    }

    std::println("自检通过");
}
