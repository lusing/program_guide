#ifndef DS_MAZE_HPP
#define DS_MAZE_HPP

#include <algorithm>
#include <cstddef>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace ds {

using Cell = std::pair<int, int>;

// 用显式栈做迷宫深度优先寻路。'#' 为墙，其余字符可通行。
// parent 记录每个格子是从哪走过来的；找到终点后沿 parent 回溯、逆置成正向路径。
// 找不到时返回空路径。
inline std::vector<Cell> solve_maze(std::span<const std::string_view> grid,
                                    Cell start, Cell goal) {
    const int rows = static_cast<int>(grid.size());
    const int cols = rows == 0 ? 0 : static_cast<int>(grid[0].size());

    const Cell none{-1, -1};
    std::vector<std::vector<Cell>> parent(
        static_cast<size_t>(rows),
        std::vector<Cell>(static_cast<size_t>(cols), none));
    std::vector<std::vector<unsigned char>> visited(
        static_cast<size_t>(rows),
        std::vector<unsigned char>(static_cast<size_t>(cols), 0));
    std::vector<Cell> st;

    auto inside = [&](int r, int c) {
        return r >= 0 && r < rows && c >= 0 && c < cols;
    };
    auto open = [&](int r, int c) {
        return grid[static_cast<size_t>(r)][static_cast<size_t>(c)] != '#';
    };

    // 四邻接顺序固定：上、左、右、下
    const int dr[4] = {-1, 0, 0, 1};
    const int dc[4] = {0, -1, 1, 0};

    visited[static_cast<size_t>(start.first)][static_cast<size_t>(start.second)] = 1;
    st.push_back(start);
    bool found = false;

    while (!st.empty()) {
        const Cell cur = st.back();
        st.pop_back();
        if (cur == goal) {
            found = true;
            break;
        }
        for (int d = 0; d < 4; ++d) {
            const int nr = cur.first + dr[d];
            const int nc = cur.second + dc[d];
            if (inside(nr, nc) &&
                visited[static_cast<size_t>(nr)][static_cast<size_t>(nc)] == 0 &&
                open(nr, nc)) {
                visited[static_cast<size_t>(nr)][static_cast<size_t>(nc)] = 1;
                parent[static_cast<size_t>(nr)][static_cast<size_t>(nc)] = cur;
                st.emplace_back(nr, nc);
            }
        }
    }

    if (!found) {
        return {};
    }

    std::vector<Cell> path;
    for (Cell cur = goal;; cur = parent[static_cast<size_t>(cur.first)]
                                              [static_cast<size_t>(cur.second)]) {
        path.push_back(cur);
        if (cur == start) {
            break;
        }
    }
    std::reverse(path.begin(), path.end());
    return path;
}

}  // namespace ds

#endif  // DS_MAZE_HPP
