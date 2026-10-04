# 13 · 组合

组合模式管一类非常具体的结构：**树**。GoF 4.3 节的定义：**将对象组合成树形结构以表示"部分—整体"的层次结构，使得客户对单个对象和组合对象的使用具有一致性**。关键词"一致性"——对文件来说叫 size，对文件夹来说也叫 size，调用方不需要知道拿到的是哪一个。

## 意图与动机

文件系统是天然的树：文件有大小，文件夹没有自己的大小——它是**它包含的一切**的总和，而"它包含的一切"里可能还有文件夹。朴素写法是两套代码：

```cpp
size_t file_size(const File& f);            // 直接返回
size_t folder_size(const Folder& fo);       // 遍历子项：是文件就算，是文件夹就递归
```

`folder_size` 的实现里必然出现 `if (child.is_folder()) ... else ...`——**调用方被迫区分叶与夹**。每加一种节点类型（符号链接、挂载点），所有遍历代码都要加一个分支；每个遍历者都要理解全部类型。

组合模式的解法一句话：**给叶和夹同一个接口**。文件夹的 `size()` 递归转发给子项，文件的 `size()` 返回自身——两者都叫 `size()`，遍历代码只认接口不认类型。

## 经典写法：文件系统树

示例 `composite.hpp`：

```cpp
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
private:
    std::string name_;
    std::vector<std::unique_ptr<FsNode>> children_;
};
```

三个要点：

1. **`Folder` 的容器装的是 `FsNode`，不是 `File`**。这是"一致性"的全部秘密：文件夹不知道自己装的是文件还是文件夹——装谁，`size()` 就递归到谁。`Folder::size()` 那六行代码**不需要为任何节点类型修改**，树再深、再混都一样。
2. **`add()` 只存在于 Folder**。GoF 在"实现"节专门讨论了"把 add/remove 放 Component 还是 Composite"：放 Component（透明型）调用方完全一致，但叶节点被迫背上用不了的接口；放 Composite（安全型）叶是干净的，但调用方要先 `dynamic_cast<Folder*>` 才能调 add。C++ 的主流选择是安全型（本例如此：`add` 在 Folder 上，Component 接口只有查询），`dynamic_cast` 的代价集中出现在"组装树"这一个环节，比污染所有叶节点划算。
3. **`unique_ptr<FsNode>` 表达所有权**：树拥有子树，父析则子亡——树的生命周期由根节点一手管理，没有泄漏路径。

运行输出：

```text
组合: root.size()=1+2+sub(3)=6
组合: 子夹透明参与递归（叶与夹同接口）
```

断言验证：root 下两个文件（1、2）加一个子文件夹（内含文件 3），`root->size() == 6`——两层嵌套的递归求和，调用方一行 `size()` 代码没写。

## 递归结构的三种遍历

树的"消费"不止 size 一种。同一个接口上还能长出：

```cpp
// 深度：叶 0，夹 1 + max(子深)
size_t depth(const FsNode& n) {
    const auto* f = dynamic_cast<const Folder*>(&n);
    if (!f) return 0;                          // 叶
    size_t best = 0;
    for (size_t i = 0; i < f->count(); ++i)    // 需要 Folder 暴露子项访问……
        best = std::max(best, depth(f->child(i)));
    return 1 + best;
}
```

注意这个尴尬：`depth` 需要**访问子项**，而接口里没有 `child(i)`——安全型 Composite 的代价。两种解法：给 Folder 补一个 `child(i)`/`count()`（子项遍历是合理需求，本例如此，见 `count()`）；或者换到下面的 variant 表示。GoF 原书用的是透明型（子项操作在 Component 上），Java 的 `java.io.File`、GUI 的 `Component/Container` 也是透明型——工程上两种都活着，选哪种取决于"遍历"是否是核心需求。

## 现代写法：std::variant 组合

继承版组合的树节点是**堆对象 + 虚表**。C++17 的 `std::variant` 提供了第二种表示：**节点 = 叶数据或子树指针的闭包**，递归类型靠"variant 装自己的 unique_ptr"实现。示例 `variant_composite.hpp`：

```cpp
struct FolderV;
using NodeV = std::variant<int /*文件大小*/, std::unique_ptr<FolderV>>;

struct FolderV {
    std::vector<NodeV> children;
};

// size：variant 版递归求和——叶子装的是 int（大小），夹装的是子树指针。
size_t vsize(const NodeV& n) {
    return std::visit(
        [](const auto& v) -> size_t {
            using T = std::decay_t<decltype(v)>;
            if constexpr (std::is_same_v<T, int>) {
                return static_cast<size_t>(v);            // 叶：直接返回
            } else {
                size_t total = 0;
                for (const auto& c : v->children) total += vsize(c);
                return total;                             // 夹：递归转发
            }
        },
        n);
}
```

三个要点：

1. **递归类型的实现方式**：`std::variant` 不允许装"还不完整的自己"，但允许装 `unique_ptr<FolderV>`——指针打断递归（指针大小已知）。`NodeV` 先于 `FolderV` 完整定义是合法的，因为它的第二个备选项只是一个指针。
2. **`std::visit` + `if constexpr` 替代虚分派**：每个"操作"是一个独立函数，按"当前装的是什么"编译期分派。**新操作 = 新函数，节点类型零修改**——这与继承版正好相反（继承版加新操作要动每个类，加新节点类型只加一个类）。
3. **move-only 的连锁反应**：`NodeV` 含 `unique_ptr` 备选项，整个 variant 不可拷贝（拷贝构造被 variant 删除）——组装树的辅助函数 `make_folder` 用可变参模板逐个 `push_back`（移动），不能用 initializer_list（initializer_list 的元素是 const 的，vector 从它构造要拷贝）。这是本示例实测踩到的坑，值得记住：**variant 组合是 move-only 的世界**。

```cpp
template <typename... Ns>
NodeV make_folder(Ns&&... ns) {
    auto f = std::make_unique<FolderV>();
    (f->children.push_back(std::forward<Ns>(ns)), ...);
    return NodeV{std::move(f)};
}
```

运行输出第三行：

```text
variant: size=6 depth=2
```

同一棵树两种表示，`size` 结果一致，`depth == 2`（root → sub → 叶）。

## 两版取舍

| 维度 | 继承版（FsNode 虚接口） | variant 版（NodeV 闭包） |
|---|---|---|
| 加新节点类型 | 新子类，旧代码不动 | 改 variant 备选项 + 所有 visit 函数 |
| 加新操作 | 每个类加虚函数（或配访问者） | 新写一个 visit 函数 |
| 内存布局 | 堆对象 + 虚表指针（每节点一次分配） | 值存储（叶的 int 内嵌，夹才分配） |
| move-only | 否 | 是（含 unique_ptr 备选项时） |
| 类型安全 | 运行期多态 | 编译期穷尽检查（visit 漏类型直接不过编） |

判据与全书模板/虚函数二分同构：**节点类型集合稳定、操作频繁增加 → variant 版；节点类型开放扩展（插件化）、操作集合稳定 → 继承版**。树深度大、节点数百万级时 variant 版的值语义优势（少一次堆分配）是实打实的性能差。第 28 章访问者模式会回到这张表——访问者正是"继承版树加新操作"的正规解法。

## 树的组装：组合与建造者的天然搭档

本章的 `main` 里组装树用了六行手工代码（造夹、add、造夹、add……）。当树结构来自外部描述（配置文件、UI 布局脚本），组装逻辑该独立出来——这正是第 10 章建造者的领地：

```cpp
// Builder 形态的树组装：add 返回 *this 引用延续链
class FolderBuilder {
public:
    explicit FolderBuilder(std::string name) : root_(std::make_unique<Folder>(name)) {}
    FolderBuilder& file(std::string name, size_t size) {
        root_->add(std::make_unique<File>(name, size));
        return *this;
    }
    std::unique_ptr<Folder> build() { return std::move(root_); }
private:
    std::unique_ptr<Folder> root_;
};
```

组合管**运行时的形状**（叶夹同接口、递归转发），建造者管**构造时的顺序**（分步装、收尾校验）——两个模式一个管结构一个管装配，互不抢戏。这也是 GoF 在 Composite"相关模式"节列的第一对搭档。

## 遍历的另一面：depth 是"新操作"问题的预演

本章给 variant 版随手加了 `vdepth`，但继承版若要加 depth 就得给 `FsNode`/`File`/`Folder` 各加虚函数——动三个类。这个不对称是 GoF"操作 vs 类型"权衡的核心：**继承版树对"加类型"开放、对"加操作"封闭**。继承版树的"加操作"正规解法是第 28 章访问者模式；而 variant 版正好相反（加操作零成本、加类型要动所有 visit）。本章的 `vdepth` 十几行写完、零类改动，就是这份不对称的直接演示——读到访问者那章时带着这张底牌。

## 一笔性能账：递归转发的成本结构

`root->size()` 一次调用触发几次虚调用？答案是"等于节点总数"——每个节点各被 `size()` 一次（叶一次直返、夹一次转发）。成本结构值得摊开：

- **每节点一次虚调用**：100 万节点的树求一次 size 是 100 万次间接跳转。对"构建后查询频繁"的场景，可以在 Folder 上做**缓存求和**（add 时增量更新 `cached_size_`，mutable 存储）——把 O(n) 查询降为 O(1)，代价是 add/remove 路径多做一次加法。这与第 16 章享元池的 mutable 缓存同一逻辑：**逻辑只读、物理记账**。
- **递归深度 = 树深**：调用栈消耗与树深成正比，与节点总数无关——平衡树 O(log n)、退化链 O(n)。上一节陷阱 3 的深度上限不只防恶意输入，也防"顺手把链表当树存"。
- **variant 版没有虚调用**：`std::visit` 分派编译期展开，同样 100 万节点，variant 版的求和是紧密循环 + 分支跳转，实测通常快数倍——这是"两版取舍"表里"内存布局"一行的量化注脚。

## 陷阱清单

1. **叶与夹语义强行统一**（现象：`File::add()` 里 throw 或静默忽略；原因：透明型 Composite 逼叶实现容器接口；后果：要么运行期炸弹要么语义含糊。对策：安全型（add 只在 Folder），叶保持纯净——本教程的选择）。
2. **父指针忘管理**（现象：节点需要 `parent()` 却没存；存了又用裸指针；原因：树通常只有向下所有权；后果：父子互相持有 unique_ptr 成环不析构。对策：父指针用裸指针（父活得比子久是树的不变量）或 `weak_ptr`，第 9 章原型章的独占/共享分类同款思路）。
3. **递归无深度限制**（现象：数据来自外部（路径解析、JSON）直接递归；原因：信任输入；后果：恶意深树栈溢出。对策：受控数据递归无妨，外部数据加深度上限或改显式栈）。
4. **variant 组合里用 initializer_list 组装**（现象：`make_folder({a, b})` 编译报拷贝已删除；原因：init-list 元素是 const，vector 构造要拷贝 move-only 元素；后果：编译错误。对策：可变参模板 + `push_back` 移动——本章实测坑）。
5. **把 Composite 当列表用**（现象：Folder 里只有一层，从不嵌套；原因：需求实际是列表；后果：虚表 + 递归接口全是多余抽象。对策：确认"部分—整体"真的递归，再用组合；一层的用 `vector<T>` 直白得多）。

## 三书对应

- 之禅：第 21 章"组合模式"（21.2 定义、21.3 应用——公司组织架构的例子、21.4 扩展——透明与安全的两种写法对比正是本章两版取舍的原始讨论）。
- 刘伟：第 12 章"组合模式"（12.1 动机与定义、12.2 结构与分析——透明/安全两种方案、12.3 实例——水果盘/文件夹、12.4 效果与应用、12.5 扩展——带 parent 引用的组合）。
- GoF：第 4 章 4.3 节 Composite——Graphics 例（Line/Rect 是叶，Picture 是夹），"实现"节五问（谁管 add、父引用、删叶的内存、递归数据结构、Component 该多胖）与本章要点逐条呼应。

*可选延伸：可运行示例见 examples/13_composite/。*
