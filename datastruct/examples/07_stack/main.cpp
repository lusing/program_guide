#include <cassert>
#include <cmath>
#include <cstdlib>
#include <exception>
#include <print>
#include <string>
#include <string_view>
#include <vector>

#include "array_stack.hpp"
#include "calculator.hpp"
#include "linked_stack.hpp"
#include "maze.hpp"

// 07 栈：顺序栈/链式栈、括号匹配、中缀转后缀与求值、迷宫寻路

int main() {
    // ═══ 顺序栈：后进先出，空栈 pop/top 抛异常 ═══
    ds::ArrayStack<int> as;
    assert(as.empty());
    as.push(1);
    as.push(2);
    as.push(3);
    assert(as.size() == 3 && as.top() == 3);
    as.pop();
    assert(as.top() == 2);
    as.pop();
    as.pop();
    assert(as.empty());
    bool threw = false;
    try {
        as.pop();
    } catch (const std::runtime_error&) {
        threw = true;
    }
    assert(threw);
    threw = false;
    try {
        (void)as.top();
    } catch (const std::exception&) {
        threw = true;
    }
    assert(threw);
    std::println("顺序栈：1/2/3 入栈后按 3/2/1 出栈；空栈 pop、top 均抛异常");

    // ═══ 链式栈：同一合同；拷贝与原件互不影响 ═══
    ds::LinkedStack<int> ls;
    ls.push(1);
    ls.push(2);
    ls.push(3);
    assert(ls.top() == 3);
    const ds::LinkedStack<int> copy = ls;
    assert(copy.size() == 3);
    ls.pop();
    assert(ls.top() == 2);
    assert(copy.top() == 3);  // 原件出栈，副本栈顶不变
    ls.pop();
    ls.pop();
    assert(ls.empty());
    threw = false;
    try {
        ls.pop();
    } catch (const std::exception&) {
        threw = true;
    }
    assert(threw);
    std::println("链式栈：LIFO 正常；拷贝副本与原件独立；空栈 pop 抛异常");

    // ═══ 括号匹配：四个合法串、两个非法串 ═══
    constexpr const char* valid[]{"()", "(())", "()[]", "{[()]}"};
    constexpr const char* invalid[]{"(", "([)]"};
    for (const char* s : valid) {
        assert(ds::balanced(s));
    }
    for (const char* s : invalid) {
        assert(!ds::balanced(s));
    }
    std::println("括号匹配：4 个合法串通过，2 个非法串被拒");

    // ═══ 中缀转后缀 + 后缀求值 ═══
    const std::string infix = "3 + 4 * 2 / ( 1 - 5 )";
    const std::string postfix = ds::to_postfix(infix);
    assert(postfix == "3 4 2 * 1 5 - / +");
    const double value = ds::eval_postfix(postfix);
    assert(std::fabs(value - 1.0) < 1e-9);
    std::println("中缀 {} → 后缀 {}", infix, postfix);
    std::println("后缀式求值 = {}（即 3 + 4×2/(1−5) = 1）", value);

    // 除零必须被拦下来
    threw = false;
    try {
        (void)ds::eval_postfix("1 0 /");
    } catch (const std::runtime_error&) {
        threw = true;
    }
    assert(threw);
    std::println("除零检测：后缀式 1 0 / 抛异常");

    // ═══ 迷宫：固定 8×8，栈式深度优先寻路 ═══
    const std::vector<std::string_view> grid{
        ".#......",
        ".#.####.",
        ".#.#....",
        ".#.#.##.",
        ".#...##.",
        ".######.",
        "........",
        "......#.",
    };
    const ds::Cell start{0, 0};
    const ds::Cell goal{7, 7};
    const std::vector<ds::Cell> path = ds::solve_maze(grid, start, goal);
    assert(!path.empty());
    assert(path.front() == start);
    assert(path.back() == goal);
    for (size_t i = 0; i < path.size(); ++i) {
        const int r = path[i].first;
        const int c = path[i].second;
        assert(r >= 0 && r < 8 && c >= 0 && c < 8);
        assert(grid[static_cast<size_t>(r)][static_cast<size_t>(c)] != '#');
        if (i > 0) {
            const int manhattan =
                std::abs(path[i].first - path[i - 1].first) +
                std::abs(path[i].second - path[i - 1].second);
            assert(manhattan == 1);
        }
    }
    std::println("8×8 迷宫：栈式 DFS 找到路径，共 {} 个格子（坐标 行,列）：", path.size());
    for (size_t i = 0; i < path.size(); ++i) {
        std::println("  {:2}: ({},{})", i, path[i].first, path[i].second);
    }

    std::println("自检通过");
}
