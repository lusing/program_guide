// 37 文档导出：同一份文档（2 段 1 表），HTML 与纯文本两条渲染线输出各自可断言；
// variant 版输出与经典版逐字符一致。
#include <cassert>
#include <print>
#include <string>
#include <vector>

#include "exporter.hpp"

int main() {
    using namespace dp;

    // ---- 经典线：HTML 渲染 ----
    Document doc;
    doc.add_para("hello");
    doc.add_para("world");
    doc.add_table({"a", "b", "c", "d"}, 2);

    const std::string html = doc.render(HtmlRenderer{});
    assert(html.find("<p>hello</p>") != std::string::npos);
    assert(html.find("<p>world</p>") != std::string::npos);
    assert(html.find("<table>") != std::string::npos && html.find("<td>a</td>") != std::string::npos);
    std::println("HTML线: 含 <p>/<table>/<td> 三类标记");

    // ---- 经典线：纯文本渲染 ----
    const std::string plain = doc.render(PlainRenderer{});
    assert(plain.find("|a|b|") != std::string::npos);
    assert(plain.find("|c|d|") != std::string::npos);
    assert(plain.find("|---|") != std::string::npos);
    std::println("文本线: 行式表格 + |---| 分隔线齐备");

    // ---- 现代线：variant 元素 + visit 分派，输出与经典版逐字符一致 ----
    const std::vector<Element> elems{Para{"hello"}, Para{"world"}, Table{{"a", "b", "c", "d"}, 2}};
    assert(render_variant(elems, HtmlRenderer{}) == html);
    assert(render_variant(elems, PlainRenderer{}) == plain);
    std::println("variant线: 两格式输出与经典版逐字符一致");

    // ---- 加一种渲染器：两版都只加一个类/一组 lambda，文档零改动 ----
    struct UpperRenderer final : Renderer {
        std::string render_para(const Para& p) const override {
            std::string s = p.text;
            for (char& c : s) if (c >= 'a' && c <= 'z') c = static_cast<char>(c - 32);
            return s + "\n";
        }
        std::string render_table(const Table& t) const override {
            std::string out;
            for (std::size_t r = 0; r * t.cols < t.cells.size(); ++r) {
                for (int c = 0; c < t.cols; ++c) out += "[" + t.cells[r * t.cols + c] + "]";
                out += "\n";
            }
            return out;
        }
    };
    const std::string upper = doc.render(UpperRenderer{});
    assert(upper.find("HELLO") != std::string::npos);
    assert(upper.find("[a][b]") != std::string::npos);
    std::println("扩展线: 新增 UpperRenderer 只加一个类，Document 零改动");

    std::println("自检通过");
}
