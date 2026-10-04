#pragma once
// 组合：树形结构里"叶子"与"容器"共享同一接口，容器透明地递归转发。
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace dp {

// Component：叶与容器统一身份。
class FsNode {
public:
    virtual ~FsNode() = default;
    [[nodiscard]] virtual std::string name() const = 0;
    [[nodiscard]] virtual size_t size() const = 0;   // 叶: 自身大小；夹: 递归求和
};

// Leaf：文件——大小就是自己的。
class File final : public FsNode {
public:
    File(std::string name, size_t size) : name_(std::move(name)), size_(size) {}

    [[nodiscard]] std::string name() const override { return name_; }
    [[nodiscard]] size_t size() const override { return size_; }

private:
    std::string name_;
    size_t size_;
};

// Composite：文件夹——持有一组 FsNode（叶与夹不区分），size 递归转发。
class Folder final : public FsNode {
public:
    explicit Folder(std::string name) : name_(std::move(name)) {}

    void add(std::unique_ptr<FsNode> child) { children_.push_back(std::move(child)); }

    [[nodiscard]] std::string name() const override { return name_; }
    [[nodiscard]] size_t size() const override {
        size_t total = 0;
        for (const auto& c : children_) total += c->size();   // 递归：对夹也成立
        return total;
    }
    [[nodiscard]] size_t count() const { return children_.size(); }

private:
    std::string name_;
    std::vector<std::unique_ptr<FsNode>> children_;
};

}  // namespace dp
