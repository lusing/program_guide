#pragma once
#include <algorithm>
#include <array>
#include <cstddef>
#include <queue>
#include <span>
#include <stdexcept>
#include <vector>

namespace ds {

// ═══════════════════════════════════════════════════════════════════
// 案例 1：文件归并最小总代价（Huffman 思想，第 15 章的应用）
// 每次从待归并集合中取出最小的两个文件合并，代价为两者之和，
// 合并结果放回集合，直到只剩一个。总代价即 Huffman 树带权路径长。
// ═══════════════════════════════════════════════════════════════════
inline int merge_file_cost(std::span<const int> file_sizes) {
    for (int s : file_sizes) {
        if (s <= 0) {
            throw std::invalid_argument("文件大小必须为正");
        }
    }
    if (file_sizes.size() < 2) {
        return 0;  // 无需归并
    }
    // 小顶堆：每次合并当前最小的两个（第 13 章堆的直接应用）
    std::priority_queue<int, std::vector<int>, std::greater<int>> pq(
        std::greater<int>{}, {file_sizes.begin(), file_sizes.end()});
    int total = 0;
    while (pq.size() > 1) {
        const int a = pq.top();
        pq.pop();
        const int b = pq.top();
        pq.pop();
        total += a + b;
        pq.push(a + b);
    }
    return total;
}

// ═══════════════════════════════════════════════════════════════════
// 案例 2：01 网格数岛（洪水填充，第 19 章图遍历 / b3-10 传染病问题的变形）
// '1' 为陆地，'0' 为水；上下左右四连通算一座岛。
// ═══════════════════════════════════════════════════════════════════
inline int island_count(std::span<const std::string_view> grid) {
    if (grid.empty()) {
        return 0;
    }
    const std::size_t cols = grid[0].size();
    for (std::string_view row : grid) {
        if (row.size() != cols) {
            throw std::invalid_argument("网格各行长度必须一致");
        }
        for (char ch : row) {
            if (ch != '0' && ch != '1') {
                throw std::invalid_argument("网格只允许字符 0 与 1");
            }
        }
    }
    const std::size_t rows = grid.size();
    std::vector<char> visited(rows * cols, 0);
    constexpr int dr[4] = {-1, 1, 0, 0};
    constexpr int dc[4] = {0, 0, -1, 1};
    int count = 0;
    for (std::size_t r = 0; r < rows; ++r) {
        for (std::size_t c = 0; c < cols; ++c) {
            if (grid[r][c] != '1' || visited[r * cols + c]) {
                continue;
            }
            ++count;  // 发现新岛，BFS 淹没整块
            std::queue<std::pair<std::size_t, std::size_t>> q;
            q.emplace(r, c);
            visited[r * cols + c] = 1;
            while (!q.empty()) {
                const auto [cr, cc] = q.front();
                q.pop();
                for (int k = 0; k < 4; ++k) {
                    const std::size_t nr = static_cast<std::size_t>(
                        static_cast<int>(cr) + dr[k]);
                    const std::size_t nc = static_cast<std::size_t>(
                        static_cast<int>(cc) + dc[k]);
                    if (nr >= rows || nc >= cols) {
                        continue;
                    }
                    if (grid[nr][nc] == '1' && !visited[nr * cols + nc]) {
                        visited[nr * cols + nc] = 1;
                        q.emplace(nr, nc);
                    }
                }
            }
        }
    }
    return count;
}

// ═══════════════════════════════════════════════════════════════════
// 案例 3：AOE 关键路径（复用第 20 章推导：最早/最晚事件时间）
// edges[i] = {from, to, duration}；顶点 0 为源点（入度 0）。
// 关键活动：最早开始 == 最晚开始；路径平局取编号最小的下一顶点。
// ═══════════════════════════════════════════════════════════════════
struct ScheduleReport {
    int critical_length;        // 总工期
    std::vector<int> critical_path;  // 关键路径顶点序列（源点起步）
};

inline ScheduleReport project_schedule(
    const std::vector<std::array<int, 3>>& edges, int n) {
    if (n <= 0) {
        throw std::invalid_argument("顶点数必须为正");
    }
    std::vector<std::vector<std::array<int, 2>>> adj(n);  // {to, dur}
    std::vector<int> indeg(n, 0);
    for (const auto& e : edges) {
        const int u = e[0];
        const int v = e[1];
        const int d = e[2];
        if (u < 0 || u >= n || v < 0 || v >= n) {
            throw std::invalid_argument("顶点编号越界");
        }
        if (d <= 0) {
            throw std::invalid_argument("活动工期必须为正");
        }
        adj[u].push_back({v, d});
        ++indeg[v];
    }
    if (indeg[0] != 0) {
        throw std::invalid_argument("顶点 0 必须是源点");
    }

    // Kahn 拓扑排序（第 19 章）
    std::vector<int> order;
    order.reserve(n);
    std::queue<int> q;
    for (int i = 0; i < n; ++i) {
        if (indeg[i] == 0) {
            q.push(i);
        }
    }
    while (!q.empty()) {
        const int u = q.front();
        q.pop();
        order.push_back(u);
        for (const auto& [v, d] : adj[u]) {
            (void)d;
            if (--indeg[v] == 0) {
                q.push(v);
            }
        }
    }
    if (order.size() != static_cast<std::size_t>(n)) {
        throw std::invalid_argument("图含环，无关键路径");
    }

    // 最早事件时间：正拓扑序取最大
    std::vector<int> ee(n, 0);
    for (int u : order) {
        for (const auto& [v, d] : adj[u]) {
            ee[v] = std::max(ee[v], ee[u] + d);
        }
    }
    const int critical_length =
        *std::max_element(ee.begin(), ee.end());
    // 最晚事件时间：逆拓扑序取最小
    std::vector<int> lt(n, critical_length);
    for (auto it = order.rbegin(); it != order.rend(); ++it) {
        const int u = *it;
        for (const auto& [v, d] : adj[u]) {
            lt[u] = std::min(lt[u], lt[v] - d);
        }
    }

    // 沿关键活动走：活动 (u,v,d) 关键 ⟺ lt[v] - d == ee[u]
    ScheduleReport rep;
    rep.critical_length = critical_length;
    rep.critical_path.push_back(0);
    int u = 0;
    for (int steps = 0; steps < n; ++steps) {
        if (adj[u].empty()) {
            break;  // 到达终点
        }
        int best = -1;
        for (const auto& [v, d] : adj[u]) {
            (void)d;
            if (lt[v] - d == ee[u] && ee[v] == lt[v]) {
                if (best < 0 || v < best) {
                    best = v;
                }
            }
        }
        if (best < 0) {
            throw std::invalid_argument("源点 0 不在关键路径上");
        }
        rep.critical_path.push_back(best);
        u = best;
    }
    return rep;
}

// ═══════════════════════════════════════════════════════════════════
// 案例 4：多位整数计算器（第 07 章双栈法：操作数栈 + 运算符栈）
// 支持 + - * / ( ) 与空格；整型除法向零截断；
// 语法错误 / 括号不匹配 / 除零均抛 std::invalid_argument。
// ═══════════════════════════════════════════════════════════════════
inline int calculator_full(std::string_view expr) {
    std::vector<int> operands;
    std::vector<char> ops;  // 运算符与左括号

    auto apply = [&](char op) {
        if (operands.size() < 2) {
            throw std::invalid_argument("表达式不完整");
        }
        const int b = operands.back();
        operands.pop_back();
        const int a = operands.back();
        operands.pop_back();
        switch (op) {
            case '+': operands.push_back(a + b); break;
            case '-': operands.push_back(a - b); break;
            case '*': operands.push_back(a * b); break;
            case '/':
                if (b == 0) {
                    throw std::invalid_argument("除数为零");
                }
                operands.push_back(a / b);  // C++ 整型除法向零截断
                break;
            default: throw std::invalid_argument("未知运算符");
        }
    };
    auto prec = [](char c) { return (c == '+' || c == '-') ? 1 : 2; };

    std::size_t i = 0;
    while (i < expr.size()) {
        const char c = expr[i++];
        if (c == ' ') {
            continue;
        }
        if (c >= '0' && c <= '9') {
            int v = c - '0';
            while (i < expr.size() && expr[i] >= '0' && expr[i] <= '9') {
                v = v * 10 + (expr[i++] - '0');
            }
            operands.push_back(v);
        } else if (c == '(') {
            ops.push_back(c);
        } else if (c == ')') {
            while (!ops.empty() && ops.back() != '(') {
                apply(ops.back());
                ops.pop_back();
            }
            if (ops.empty()) {
                throw std::invalid_argument("括号不匹配");
            }
            ops.pop_back();  // 弹出 '('
        } else if (c == '+' || c == '-' || c == '*' || c == '/') {
            // 左结合：栈顶优先级不低于当前运算符时先算栈顶
            while (!ops.empty() && ops.back() != '(' &&
                   prec(ops.back()) >= prec(c)) {
                apply(ops.back());
                ops.pop_back();
            }
            ops.push_back(c);
        } else {
            throw std::invalid_argument("非法字符");
        }
    }
    while (!ops.empty()) {
        if (ops.back() == '(') {
            throw std::invalid_argument("括号不匹配");
        }
        apply(ops.back());
        ops.pop_back();
    }
    if (operands.size() != 1) {
        throw std::invalid_argument("表达式不完整");
    }
    return operands[0];
}

}  // namespace ds
