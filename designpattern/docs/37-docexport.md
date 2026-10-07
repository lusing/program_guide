# 37 · 文档导出实战：桥与外观的合体

创建型讲"怎么造"、结构型讲"怎么组装"，本章把它们拧成一个常见需求：**同一份文档，导出成多种格式**。文档的结构（段落、表格）是一个变化维度，输出格式（HTML、纯文本、将来 Markdown）是另一个维度——两维独立增长，正是第 7 章桥模式的领地；而客户想要的只是"一行代码导出"，那是外观的活。本章把两维装进 Document::render(renderer) 一个调用里，再用 variant 版验证同一合同的现代形态。

## 意图与动机

文档导出器的朴素写法把两维焊死：`render_html()`、`render_plain()` 各自遍历文档——加一种格式复制一份遍历，加一种元素改所有格式函数，**M×N 的改动面**。桥模式把两维拆开：元素结构住在 Document 一侧，"怎么画一种元素"住在 Renderer 一侧，中间用抽象接口相接——**加格式加一个 Renderer 子类，加元素加一个虚函数 + 各 Renderer 补实现，两边都不全动**。外观再收一层：客户只见 `doc.render(renderer)` 一行，两维的存在感被门面吃掉。本章示例从"2 段 1 表"的文档出发，验证两条格式线、variant 对拍线，最后以"加第三种渲染器"实测扩展面。

## 经典写法：Renderer 家族 + Document 门面

示例 `exporter.hpp`。元素与渲染器家族：

```cpp
// ---- 元素 ----
struct Para { std::string text; };
struct Table { std::vector<std::string> cells; int cols; };

// ---- Renderer 家族（每个输出格式一个类）----
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
// PlainRenderer 同构：段落原样加换行，表格行式 "|a|b|" + "|---|" 分隔
```

Renderer 家族是桥的实现侧——**每种格式回答"一种元素怎么画"**，元素之间互不知晓。Document 侧收元素、出全文：

```cpp
class Document {
public:
    void add_para(std::string text);
    void add_table(std::vector<std::string> cells, int cols);

    std::string render(const Renderer& r) const {   // 外观：一次调用出全文
        std::string out;
        for (const auto& it : items_) {
            if (it.kind == Kind::para) out += r.render_para(Para{it.text});
            else out += r.render_table(Table{it.cells, it.cols});
        }
        return out;
    }
private:
    std::vector<Item> items_;   // 有序元素（kind 判别 + 载荷）
};
```

运行侧（`main.cpp`）：

```cpp
Document doc;
doc.add_para("hello");
doc.add_para("world");
doc.add_table({"a", "b", "c", "d"}, 2);

const std::string html = doc.render(HtmlRenderer{});
assert(html.find("<p>hello</p>") != std::string::npos);
assert(html.find("<table>") != std::string::npos && html.find("<td>a</td>") != std::string::npos);

const std::string plain = doc.render(PlainRenderer{});
assert(plain.find("|a|b|") != std::string::npos);
assert(plain.find("|---|") != std::string::npos);
```

同一份文档、两个渲染器、两套格式标记各自齐备——**文档侧零渲染知识、渲染器侧零文档结构知识**，桥的合同就在这一句里。运行输出：

```text
HTML线: 含 <p>/<table>/<td> 三类标记
文本线: 行式表格 + |---| 分隔线齐备
variant线: 两格式输出与经典版逐字符一致
扩展线: 新增 UpperRenderer 只加一个类，Document 零改动
自检通过
```

## 现代写法：variant 元素 + visit 分派

元素集合换成 variant、分派交给 visit——渲染器家族原封不动复用（`render_variant`）：

```cpp
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

// main：variant 版输出与经典版逐字符一致
assert(render_variant(elems, HtmlRenderer{}) == html);
assert(render_variant(elems, PlainRenderer{}) == plain);
```

variant 线只改**元素侧**的表示（判别 + 载荷收进 variant，Document 的 Item 结构消失），Renderer 家族照用——这说明桥的两维独立性经得起单侧替换。若格式维度也现代化（渲染器变 overload lambda 组），就得到第 28 章"variant + overload"的完整形态：**两维各自在"类层次 vs variant"之间独立选型，四个组合都是合法架构**——桥模式真正的教益不是"用继承搭桥"，而是**把两维拆成两个独立决策**。

## 加一种元素 vs 加一种渲染器：两个方向的修改面

桥的价值要用修改面来计量，两个方向各算一遍（正文论述，不打印数值）：**加一种渲染器**（本章 main 第三段的 UpperRenderer）——新写一个类、实现两个虚函数，Document 与现有渲染器零改动；M 个格式 × N 个元素中动 1 行维度、M+N 里加 1。**加一种元素**（比如加图片 Image）——Renderer 接口加一个纯虚 `render_image`，**所有现有渲染器被迫补实现**（编译器逼的，这是虚函数版的 exhaustive 保障）；Document 加一个 add_image。对比结论：**这个文档场景里"加格式"远比"加元素"频繁**（HTML/Markdown/RTF 滚动需求，段落表格五年不动），桥把便宜的维度（格式）做成开放扩展、把稳定的维度（元素）做成封闭清单——**先数清哪个维度会变，再决定桥的桥墩打在哪侧**。若两维都频繁变，M×N 的组合爆炸谁也救不了，那是产品问题不是模式问题。

## 两维四组合：桥的完整选型空间

正文说过"两维各自独立选型、四个组合都合法"，这里把四个组合摆开——选型空间一目了然：

| 元素侧 \ 格式侧 | Renderer 类层次 | overload lambda 组 |
|---|---|---|
| **variant 元素** | 本章示例的形态 | 第 28 章"variant + overload"完整形态 |
| **继承元素**（accept/visit） | GoF 原版双分派 | 混合：元素开放、格式封闭 |

四个组合的判据在两维各自回答一遍：**元素侧**会加新元素吗（会 → 继承 accept 体系保 exhaustive；不会 → variant 值语义更轻）；**格式侧**会加新格式吗（会 → 类层次或 overload 组都开放；格式本身重逻辑 → 类，重组合 → overload）。本章选"variant × 类层次"是因为元素稳定（段落表格五年不动）而格式开放——与 37 章开头"先数清哪个维度会变"的结论首尾呼应。

## 什么时候别用桥

两个信号说明桥是过度设计：**格式只有一种且短期不会加**——Document 直接长出 to_html() 更诚实，桥的两维抽象是预付成本；**渲染逻辑依赖文档整体**——比如目录要汇总全文章节，逐元素分派的桥就装不下（渲染器只见单元素），那需要"两趟扫描"（先收集结构再渲染），桥外再加一层编排。桥的甜区：格式家族正交于元素家族、逐元素渲染语义成立、且至少一维会持续增长——图形库（形状 × 渲染后端）、序列化（数据对象 × 编解码格式）都是教科书案例。

一句话收束本章：**桥把 M×N 焊点拆成 M+N 各自开放，外观再把 M+N 的存在感收进一行调用**——37 章的全部机器都在为这两句话打工。

## 从文档导出看"门面的克制"

外观在这章的角色值得单独掂量：`doc.render(renderer)` 一个方法，却不是把 Document 做成上帝类。**门面的克制点**在于它只做路由（遍历 + 分派），不做加工——没有"顺手转义 HTML"、"顺手压缩空白"这类越权逻辑，那些都是 Renderer 的职责。判断门面是否越权的土办法：把门面方法体读一遍，出现"业务判断"（if 数据是 XX 就 YY）就是越权信号；只有"结构判断"（这是段落还是表格）是路由的本分。第 15 章外观模式"门面不新增职责"的原则，在本章的落地形态就是这条土办法。反过来的克制也成立：Renderer 家族对 Document 的存在**一无所知**（只见元素）——门面联通两侧，但两侧互不知晓，这才是桥+外观合体后的正确拓扑。

## 本章示例的断言面

main.cpp 四段断言钉住的合同：

- HTML 线三类标记齐备（p/table/td）——格式指纹逐串断言；
- Plain 线行式表格 + |---| 分隔线——第二种格式独立可验；
- variant 版与经典版两格式逐字符一致——单侧替换不改语义；
- 新增 UpperRenderer 后全部旧断言原样通过——"加格式零改动"的实测面。

## 扩展练习

本章骨架的三处顺理成章的延伸，每处对应一个已学模式（另加一条回归纪律）：

- **加 Markdown 渲染器**：第三个 Renderer 子类，验证 M+N 的 M 侧开放性（10 分钟工作量，改面只有加类）；
- **加图片元素**：Renderer 接口加纯虚 + 全渲染器补实现——"加元素"方向的修改面实测，与正文分析对账；
- **Document 走 builder**：add_para/add_table 链式化（`doc.para("x").table(...)`）——第 10 章 Builder 与本章外观的衔接练习。
- **格式指纹回归**：把本次提交的 HTML/Plain 输出全文快照进测试，此后任何渲染器改动都先对快照——改动面可视化的最朴素做法（快照 diff 就是修改面清单）。回归纪律一句话：**渲染器的改动面永远用快照 diff 出示，不许口头说"只影响 HTML"**。

## 陷阱清单

1. **桥变成单维的两个类**（现象：Renderer 只有一个实现，Document 只有一种元素，桥退化为两个类互相调用；原因：为模式而模式；后果：抽象层白付。对策：两维各至少两个真实取值再上桥——本章 HTML/Plain × Para/Table 就是下限）。
2. **元素载荷在 Document 里复制存储**（现象：add_table 把 cells 拷了一份、render 时又构造临时 Table；原因：Item 结构体按值收载荷；后果：大表格双份内存。对策：accept 版本（visit 原元素）或 move 语义——教学版从简，工业版要审）。
3. **渲染器隐藏状态跨文档泄漏**（现象：渲染器成员里攒了上一篇文档的序号/锚点，下一篇文档编号接续；原因：Renderer 无状态合同没守住；后果：格式错乱。对策：渲染器按趟实例化（一趟一 new）或 render 返回值全量携带状态——与第 28 章访问者的生命周期纪律同源）。
4. **两维合同不对齐**（现象：加 Table::caption 字段，HtmlRenderer 用了、PlainRenderer 忘了渲染；原因：合同没有 exhaustive 检查——虚函数版加元素才有编译器兜底，元素加字段没人管；后果：某格式静默丢信息。对策：元素字段变更时全渲染器过一遍（checklist）；或元素侧改 variant + 渲染器改 overload，让编译器检查覆盖）。
5. **外观吞了错误通道**（现象：render 返回 string，渲染器内部失败只能返回空串；原因：门面只留了一条返道；后果：失败静默。对策：expected<string> 或错误回调——门面简化调用不等于简化失败语义，第 36 章 expected 纪律在门面层同样成立）。

## 测试法

- **双格式标记断言**：HTML 线断言三类标记（p/table/td）、Plain 线断言行式与分隔线——每格式一份"输出指纹"。
- **variant 对拍**：render_variant 与经典 render 在同一文档、同一渲染器上逐字符一致——单侧替换不改语义。
- **扩展面实测**：新渲染器加入后现有断言全绿——"加格式零改动"不是口号，是本次提交里真实发生的操作。
- **元素覆盖完备**：2 段 1 表的文档在两个格式下输出长度/标记数符合预期——每种元素在每格式下至少渲染一次。
- **渲染器无状态回归**：同一渲染器渲染两份文档，第二份输出与第一份同构（首尾一致）——陷阱 3 的守门断言。
- **顺序保真**：文档里元素加入顺序 = 输出顺序（hello 在 world 前）——Document 的有序合同。
- **表格边界**：cells 数量非 cols 整数倍时按行截断不越界（HtmlRenderer 的 `r * t.cols < t.cells.size()` 循环条件）——循环不变式本身是合同。
- **空文档**：零元素的 Document 两个格式都输出空串——边界输入不炸。
- **门面无越权**：render 输出里除元素标记外无任何加工痕迹（无转义/无压缩）——门面克制合同的守门断言。

## 三书对应

- 之禅：第 10 章"桥接模式"（10.x "抽象与实现分离"——避免"多继承爆炸"的动机与本章 M×N 论证一致）；另见第 23 章外观模式关于"门面不新增职责、只做路由"的定位（本章 render 的自我约束）。
- 刘伟：第 10 章"桥接模式"10.3 节"图像格式 × 操作系统"实例（与本章 格式×元素 同构）；第 12 章"外观模式"12.2 节"外观与适配器的区别"。
- GoF：第 4 章 4.2 Bridge"实现"小节——"只需要一个实现时还要不要抽象"的讨论（本章"什么时候别用桥"的直接来源）、"创建正确的 Bridge 抽象"与"共享实现对象"两条；4.4 Facade 对"外观类不承担应用逻辑"的告诫。

*可选延伸：可运行示例见 examples/37_docexport/。*

---

上一章：[36 表达式求值器：四模式一条流水线](36-evaluator.md) · 下一章：[38 权限校验：三模式的管道切面](38-permission.md)
