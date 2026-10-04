#include <array>
#include <cassert>
#include <print>
#include <stdexcept>
#include <string_view>
#include <vector>

#include "cases.hpp"

// 28 综合案例：文件归并 / 数岛 / AOE 关键路径 / 计算器

int main() {
    // ═══ 案例 1：文件归并（Huffman 归并序）═══
    {
        const int sizes[] = {5, 9, 12, 13, 8};
        const int cost = ds::merge_file_cost(sizes);
        assert(cost == 107);
        assert(ds::merge_file_cost(std::span<const int>{}) == 0);
        const int single[] = {42};
        assert(ds::merge_file_cost(single) == 0);
        std::println("文件归并：[5 9 12 13 8] 最小总代价 {}（13+21+26+47）",
                     cost);
        std::println("文件归并边界：空表与单文件代价 0");
    }

    // ═══ 案例 2：数岛（洪水填充，四连通）═══
    {
        const std::string_view grid[] = {
            "11000",  //
            "10001",  //
            "00011",  //
            "00000",  //
            "00100",  //
        };
        const int islands = ds::island_count(grid);
        assert(islands == 3);
        std::println("数岛：5x5 网格共 {} 座岛", islands);
        const std::string_view all_water[] = {"000", "000"};
        assert(ds::island_count(all_water) == 0);
    }

    // ═══ 案例 3：AOE 关键路径（6 顶点 8 边，双关键路径取编号小者）═══
    {
        const std::vector<std::array<int, 3>> edges{
            {0, 1, 3}, {0, 2, 4},  // 源点 0 的两项先行活动
            {1, 3, 5}, {1, 4, 2},  // 顶点 1 有松弛（ee=3, lt=5）
            {2, 3, 6}, {2, 4, 7},
            {3, 5, 4}, {4, 5, 3},
        };
        const ds::ScheduleReport rep = ds::project_schedule(edges, 6);
        assert(rep.critical_length == 14);
        const std::vector<int> expected_path{0, 2, 3, 5};
        assert(rep.critical_path == expected_path);
        std::print("AOE 关键路径：总工期 {}，路径", rep.critical_length);
        for (int v : rep.critical_path) {
            std::print(" {}", v);
        }
        std::println("");
        // 有环图抛异常
        bool caught = false;
        try {
            const std::vector<std::array<int, 3>> cyclic{
                {0, 1, 1}, {1, 0, 1}};
            (void)ds::project_schedule(cyclic, 2);
        } catch (const std::invalid_argument&) {
            caught = true;
        }
        assert(caught);
        std::println("AOE 边界：含环图抛出异常");
    }

    // ═══ 案例 4：计算器（双栈 + 优先级 + 括号）═══
    {
        assert(ds::calculator_full("( 3 + 4 ) * 2") == 14);
        assert(ds::calculator_full("100 / 5 / 2") == 10);
        assert(ds::calculator_full("7 + 3 * 2") == 13);
        std::println(
            "计算器：( 3 + 4 ) * 2 = {}；100 / 5 / 2 = {}；7 + 3 * 2 = {}",
            ds::calculator_full("( 3 + 4 ) * 2"),
            ds::calculator_full("100 / 5 / 2"),
            ds::calculator_full("7 + 3 * 2"));

        bool caught = false;
        try {
            (void)ds::calculator_full("9 / 0");
        } catch (const std::invalid_argument&) {
            caught = true;
        }
        assert(caught);
        caught = false;
        try {
            (void)ds::calculator_full("3 + a");
        } catch (const std::invalid_argument&) {
            caught = true;
        }
        assert(caught);
        std::println("计算器异常：除零与非法字符均抛出 std::invalid_argument");
    }

    std::println("自检通过");
    return 0;
}
