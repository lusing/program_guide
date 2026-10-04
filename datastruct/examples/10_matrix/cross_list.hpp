#ifndef DS_CROSS_LIST_HPP
#define DS_CROSS_LIST_HPP

#include <cstddef>
#include <stdexcept>
#include <vector>

#include "sparse_matrix.hpp"  // Triple

namespace ds {

// 十字链表（orthogonal list）：每个非零节点同时挂在两条有序链上——
// 行链按列号向右（right），列链按行号向下（down）；行/列各有一个头。
// 节点用定长 arena 中的整数下标编号，不出现裸指针。
class CrossList {
public:
    CrossList(int rows, int cols)
        : rows_(rows),
          cols_(cols),
          row_head_(static_cast<size_t>(rows), -1),
          col_head_(static_cast<size_t>(cols), -1) {
        if (rows < 0 || cols < 0) {
            throw std::invalid_argument("CrossList: negative dimension");
        }
        // 最坏情形每格一个节点；arena 预留该上限，实际只消耗非零节点。
        nodes_.reserve(static_cast<size_t>(rows) * static_cast<size_t>(cols));
    }

    // 在 (r,c) 写入 v。位置已存在则更新；新位置写 0 被忽略。
    void set(int r, int c, double v) {
        check_(r, c);

        // 沿行链找插入点：pred 为前驱，cur 指向同列节点或应在的后位置。
        int pred = -1;
        int cur = row_head_[static_cast<size_t>(r)];
        while (cur != -1 && nodes_[static_cast<size_t>(cur)].c < c) {
            pred = cur;
            cur = nodes_[static_cast<size_t>(cur)].right;
        }
        if (cur != -1 && nodes_[static_cast<size_t>(cur)].c == c) {
            nodes_[static_cast<size_t>(cur)].v = v;
            return;
        }
        if (v == 0.0) {
            return;
        }

        const int id = alloc_(r, c, v);

        // 接入行链（插在 pred 与 cur 之间）。
        if (pred == -1) {
            nodes_[static_cast<size_t>(id)].right = row_head_[static_cast<size_t>(r)];
            row_head_[static_cast<size_t>(r)] = id;
        } else {
            nodes_[static_cast<size_t>(id)].right =
                nodes_[static_cast<size_t>(pred)].right;
            nodes_[static_cast<size_t>(pred)].right = id;
        }

        // 沿列链对称地找插入点并接入。
        int col_pred = -1;
        int col_cur = col_head_[static_cast<size_t>(c)];
        while (col_cur != -1 && nodes_[static_cast<size_t>(col_cur)].r < r) {
            col_pred = col_cur;
            col_cur = nodes_[static_cast<size_t>(col_cur)].down;
        }
        if (col_pred == -1) {
            nodes_[static_cast<size_t>(id)].down = col_head_[static_cast<size_t>(c)];
            col_head_[static_cast<size_t>(c)] = id;
        } else {
            nodes_[static_cast<size_t>(id)].down =
                nodes_[static_cast<size_t>(col_pred)].down;
            nodes_[static_cast<size_t>(col_pred)].down = id;
        }
    }

    // 读取 (r,c)；未存节点的位置一律视为 0。
    double get(int r, int c) const {
        check_(r, c);
        int cur = row_head_[static_cast<size_t>(r)];
        while (cur != -1 && nodes_[static_cast<size_t>(cur)].c < c) {
            cur = nodes_[static_cast<size_t>(cur)].right;
        }
        return (cur != -1 && nodes_[static_cast<size_t>(cur)].c == c)
                   ? nodes_[static_cast<size_t>(cur)].v
                   : 0.0;
    }

    // 取整行，按列号升序返回三元组。
    std::vector<Triple> row(int r) const {
        check_(r, 0);
        std::vector<Triple> out;
        for (int cur = row_head_[static_cast<size_t>(r)]; cur != -1;
             cur = nodes_[static_cast<size_t>(cur)].right) {
            const Node& n = nodes_[static_cast<size_t>(cur)];
            out.push_back(Triple{n.r, n.c, n.v});
        }
        return out;
    }

    size_t node_count() const noexcept {
        return nodes_.size();
    }

private:
    struct Node {
        int right = -1;
        int down = -1;
        int r = 0;
        int c = 0;
        double v = 0.0;
    };

    int alloc_(int r, int c, double v) {
        if (nodes_.size()
            == static_cast<size_t>(rows_) * static_cast<size_t>(cols_)) {
            throw std::length_error("CrossList: arena full");
        }
        const int id = static_cast<int>(nodes_.size());
        nodes_.push_back(Node{-1, -1, r, c, v});
        return id;
    }

    void check_(int r, int c) const {
        if (r < 0 || r >= rows_ || c < 0 || c >= cols_) {
            throw std::out_of_range("CrossList: index out of range");
        }
    }

    int rows_;
    int cols_;
    std::vector<int> row_head_;
    std::vector<int> col_head_;
    std::vector<Node> nodes_;
};

}  // namespace ds

#endif  // DS_CROSS_LIST_HPP
