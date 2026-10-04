#pragma once
// 37 文档导出：渲染器家族（格式维度）× 文档组装（结构维度）——桥 + 外观。
// 经典线：虚函数 Renderer；现代线：variant 元素 + overload 渲染器。
#include <memory>
#include <string>
#include <utility>
#include <variant>
#include <vector>

namespace dp {

// ---- 元素 ----
struct Para { std::string text; };
struct Table { std::vector<std::string> cells; int cols; };

// ---- 经典线：Renderer 家族（每个输出格式一个类）----
struct Renderer {
    virtual ~Renderer() = default;
    virtual std::string render_para(const Para& p) const = 0;
    virtual std::string render_table(const Table& t) const = 0;
};

class HtmlRenderer final : public Renderer {
public:
    std::string render_para(const Para& p) const override {
        return "<p>" + p.text + "</p>\n";
    }
    std::string render_table(const Table& t) const override {
        std::string out = "<table>\n";
        for (std::size_t r = 0; r * t.cols < t.cells.size(); ++r) {
            out += "<tr>";
            for (int c = 0; c < t.cols; ++c) out += "<td>" + t.cells[r * t.cols + c] + "</td>";
            out += "</tr>\n";
        }
        out += "</table>\n";
        return out;
    }
};

class PlainRenderer final : public Renderer {
public:
    std::string render_para(const Para& p) const override {
        return p.text + "\n";
    }
    std::string render_table(const Table& t) const override {
        std::string out;
        for (std::size_t r = 0; r * t.cols < t.cells.size(); ++r) {
            out += "|";
            for (int c = 0; c < t.cols; ++c) out += t.cells[r * t.cols + c] + "|";
            out += "\n";
        }
        out += "|---|\n";   // 表格结束分隔线（可断言）
        return out;
    }
};

// ---- 文档组装：按顺序收元素，一行门面 render 输出 ----
class Document {
public:
    void add_para(std::string text) {
        items_.push_back(Item{Kind::para, std::move(text), {}, 0});
    }
    void add_table(std::vector<std::string> cells, int cols) {
        items_.push_back(Item{Kind::table, {}, std::move(cells), cols});
    }

    std::string render(const Renderer& r) const {   // 外观：一次调用出全文
        std::string out;
        for (const auto& it : items_) {
            if (it.kind == Kind::para) out += r.render_para(Para{it.text});
            else out += r.render_table(Table{it.cells, it.cols});
        }
        return out;
    }

private:
    enum class Kind { para, table };
    struct Item { Kind kind; std::string text; std::vector<std::string> cells; int cols; };
    std::vector<Item> items_;
};

// ---- 现代线：元素用 variant，渲染器是 overload 的两个 lambda ----
using Element = std::variant<Para, Table>;

inline std::string render_variant(const std::vector<Element>& elems, const Renderer& r) {
    std::string out;
    for (const auto& e : elems) {
        std::visit([&](const auto& el) {
            using T = std::decay_t<decltype(el)>;
            if constexpr (std::is_same_v<T, Para>) out += r.render_para(el);
            else out += r.render_table(el);
        }, e);
    }
    return out;
}

}  // namespace dp
