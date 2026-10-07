# 30 · 类型擦除

虚函数的接口很干净，但有两个代价：被装的类型必须**继承自你的基类**、对象必须**经指针堆上持有**。模板很灵活，但**每种类型一份代码**、异构容器装不下。类型擦除把两边的好处合体：**接口干净如虚函数，合同宽松如 concepts，外壳还有值语义**。std::function、std::any、std::shared_ptr 的自定义删除器，全是这个手法。本章不引库，手工把一个 AnyDrawable 从零拆到零件——虚函数在擦除里并没有消失，它只是被降级成了实现细节。

## 意图与动机

回到第 29 章的 Drawable 场景，提两个新要求：一，第三方形状类不能改——`Sq` 没有 `: public Drawable` 的基类列表，虚函数版直接出局；二，客户想要**值语义**——`AnyDrawable` 能直接 push 进 vector、能按值传递、不用 make_unique。两个要求合起来就是类型擦除的标准立项场景：**统一接口（外壳非模板）+ 任意实现（构造函数模板）**。名字里的"擦除"指的是：具体类型 D 在构造时被"藏"进一个内部对象，外壳和客户从此只看得见合同，看不见 D——D 甚至可以是**写不出名字的类型**（匿名局部类型、闭包），只要它满足合同。

## 经典写法：三件套手工擦除

示例 `erase.hpp`。第一件：内部抽象接口，只声明"能做什么"：

```cpp
// 内部接口：只声明"能做什么"。名字带下划线——它是实现细节，不该被客户引用。
class Concept_ {
public:
    virtual ~Concept_() = default;
    virtual void do_draw(std::string& out) const = 0;
    virtual std::string do_id() const = 0;
};

// 合同：双接口 draw + id。lambda 只有 operator()，装不进来——必须包一层。
template <typename D>
concept DrawableLike = requires(const D& d, std::string& out) {
    d.draw(out);
    { d.id() } -> std::convertible_to<std::string>;
};
```

注意合同的位置：concept 检查的是**外部类型的形状**（draw + id 双接口），Concept_ 是**内部转发的跳板**——两者一个对"装进来的"说话，一个对"用出去的"说话。第二件：模板适配器，把任意 D 接到 Concept_ 上：

```cpp
// 模板适配器：每个 D 实例化一份 Model，把调用转发给被藏起来的对象。
template <DrawableLike D>
class Model final : public Concept_ {
public:
    explicit Model(D d) : data_(std::move(d)) {}
    void do_draw(std::string& out) const override { data_.draw(out); }
    std::string do_id() const override { return data_.id(); }
private:
    D data_;
};
```

第三件：值语义外壳。构造函数是模板、类不是——**模板性被擦掉了**：

```cpp
class AnyDrawable {
public:
    template <DrawableLike D>
    AnyDrawable(D d) : self_(std::make_unique<Model<D>>(std::move(d))) {}

    AnyDrawable() = delete;                   // 没有对象就没有可转发的合同
    AnyDrawable(const AnyDrawable&) = delete; // 深拷贝需要 clone，本例从略
    AnyDrawable(AnyDrawable&&) = default;
    AnyDrawable& operator=(AnyDrawable&&) = default;

    void draw(std::string& out) const { self_->do_draw(out); }
    std::string id() const { return self_->do_id(); }
private:
    std::unique_ptr<Concept_> self_;
};
```

运行侧（`main.cpp`）把"写不出名字的类型"也装进去：

```cpp
std::vector<AnyDrawable> bag;
bag.emplace_back(SqA{});                    // 适配器：给没有 id() 的形状补齐合同
bag.emplace_back(LamA{[](std::string& o) { /* 追加 "lam" */ }});

{   // 匿名局部类型：名字写不出来，虚函数版装不下（写不出基类列表），擦除装得下
    struct {
        void draw(std::string& out) const { /* 追加 "local" */ }
        std::string id() const { return "local"; }
    } local_shape;
    bag.push_back(local_shape);
}

std::string out;
for (const auto& d : bag) d.draw(out);
assert(out == "sq;ci;lam;local");          // 四种来源，一份合同
```

适配器 `SqA` 是本例的隐藏主角：形状类**零改动**，缺点（缺 id()）在包装层补齐——"不改旧类型、在外围适配"正是擦除相对继承的核心优势。运行输出：

```text
类型擦除: 四种类型（含匿名局部类型与 lambda 包装）统一 draw/id
自检通过
```

## 模式结构（一次调用的完整路径）

```text
   客户 ──draw(out)──> AnyDrawable::draw           非虚，转发
                        │ self_（unique_ptr<Concept_>）
                        └──> Model<Sq>::do_draw     虚函数：真正的分派点
                               │ data_
                               └──> Sq::draw        直接调用

   构造路径：AnyDrawable(D d) ──make_unique──> Model<D>（D 在这里被"藏"进堆上）
   虚函数的位置：不在接口层（客户不继承任何东西），在擦除层（Model : Concept_）
```

虚函数在擦除里的位置就是最后一行：**类型擦除没有消灭虚函数，它把虚函数从"客户必须继承的义务"降级成"库内部的转发跳板"**。客户侧合同从继承约束变成 concept 检查——这正是 std::function 能装下"任何可调用物"的原因：它内部也是 `Model<F> : Concept_` 的三件套，只不过合同只有一个 operator()。

## 现代写法：所有权对照——std::function 与 function_ref

擦除外壳的**所有权语义**是现代 C++ 里最重要的一组对照（`std::function` 系 vs `std::function_ref` / `std::move_only_function` 系）：

- **std::function**：拥有型擦除——内部拷贝（或移动）可调用物进自己堆上的 Model，生命周期跟 function 走。对应本例 `unique_ptr<Concept_>` 的结构。代价是拷贝开销与"要求可拷贝"的约束。
- **std::function_ref（C++26）**：引用型擦除——只存 `(void*, fn指针)` 两个词，**不拥有**被擦对象；被调物必须活过 function_ref 的生命周期。适合"调用一下就完"的参数位（回调形参），对应本例若把 `unique_ptr` 换成裸 `Concept_*` 的形态。
- **std::move_only_function（C++23）**：拥有型 + 可移动不可拷贝——正是本例 AnyDrawable 的语义（拷贝被 delete、移动 default）。装线程、装 unique_ptr 捕获的 lambda 时，std::function 装不下（要求可拷贝），move_only_function 恰好够。

一句话判据：**擦除之后对象活多久？跟着容器走选拥有型（function / move_only_function / 本例 AnyDrawable）；只活一次调用选引用型（function_ref）**。本例选择 move-only 的拥有型外壳，理由写在构造函数的 delete 行注释里：擦除后的深拷贝需要 clone 虚函数（Model 再加一个 `clone()` 返回 `make_unique<Model>(*data_)`），那是完整工业版的必备件，教学版用 move-only 明确划出边界。

## 什么时候该用类型擦除

三个信号同时满足才值得手工擦除：**被装类型不受你控制**（第三方库、闭包、匿名类型——继承路线直接封死）；**接口小而稳**（一两个函数——Concept_ 和每个 Model 要为每个接口函数写一份转发，接口越大擦除骨架越贵）；**需要值语义或异构容器**（否则模板 + span 就够）。标准库现成的擦除件按序考虑：能装"可调用"就 `std::function`/`move_only_function`，能装"任意值"就 `std::any`，两者都不合体再手写。手写骨架是模板化的：Concept_/Model/外壳三段式背下来，换什么合同都一样写。

## 补全工业版：clone 与真拷贝

教学版把拷贝 delete 掉、只留移动，是为了把注意力留给擦除骨架本身。工业版要支持值语义的完整承诺（能进要求可拷贝的容器、能按值传出函数），只差一件：**clone**。原理一句话——Model 知道自己装的 D 的真实类型，深拷贝交给它：

```cpp
// Concept_ 加一条：
virtual std::unique_ptr<Concept_> do_clone() const = 0;
// Model<D> 加：
std::unique_ptr<Concept_> do_clone() const override {
    return std::make_unique<Model>(data_);   // 拷贝 D 本身——D 的拷贝构造说了算
}
// AnyDrawable 拷贝改为：
AnyDrawable(const AnyDrawable& o) : self_(o.self_->do_clone()) {}
```

三行补完，AnyDrawable 从 move-only 升级为普通值类型。注意 clone 的语义边界：深拷贝的是 D 的**拷贝构造**——D 自己持句柄/指针时，拷贝是深是浅全看 D 的定义，擦除层不越权替它做深拷贝（否则双重管理）。这也是 std::function 的实际做法：拷贝 function 就是拷贝被装的可调用物。

## 标准库擦除件全家福

手写三件套之前，先数一遍标准库已经替你写好的：**std::function\<R(Args...)\>** 擦除"可调用"——最常用的擦除件，本章结论的全部要素（内部 Model + 拷贝即 clone）它都有；**std::move_only_function**（C++23）同合同但 move-only——装捕获 unique_ptr 的 lambda 时唯一选择；**std::function_ref**（C++26）引用型——参数位"只调一次"的零分配擦除；**std::any** 擦除"任意值"——存取靠 any_cast，类型安全但取回时要写对类型；**std::shared_ptr\<void\> + 自定义删除器**——最老的擦除形态，构造时类型信息进了删除器，析构正确但取回同样要 any 式的 cast。判读顺序：可调用物按"要拷贝吗？只调一次吗？"在 function / move_only_function / function_ref 里选；非可调用物先问"要不要取回来"——要就 any，不要就 shared_ptr\<void\>；全不合体再手写三件套——骨架你已经会了，换合同只是改 concept 与转发行数。

## move-only 的连锁反应

把拷贝 delete 掉不是一行注释的事，它会沿着使用场景逐层传导，提前知道才能不踩坑。**容器要求**：`vector<AnyDrawable>` 扩容需要搬移元素——搬移走移动构造，move-only 没问题，但**要求元素是"可移动且 noexcept"才安全**（强异常保证路径下 vector 用搬移，不可移动才退回复制——move-only 类型直接编不过）；所以擦除外壳的移动构造应当 noexcept（本例 `= default` 的隐式 noexcept 依赖成员 unique_ptr 的 noexcept 移动，成立）。**算法要求**：需要值拷贝的 STL 算法（copy、sort 的部分实现路径）对 move-only 元素不可用，sort 幸好走移动——但排序比较函数里若想"拷贝一份再比"就断了。**回调链要求**：把 AnyDrawable 存进另一个擦除件（如 std::function 按值捕获它）会因 std::function 要求可拷贝而编不过——这正是 std::move_only_function 存在的理由（第 31 章 LoggerT 的 sink 若要装擦除形状，就得用它）。**设计上的正面价值**：move-only 把所有权语义写进类型系统——"这个对象有唯一主人"由编译器监督，比运行期约定强一整个量级。判据：擦除对象**小且无独占资源**就做全值语义（补 clone），**大或有独占资源**就 move-only——本例形状无独占资源，delete 拷贝纯属教学聚焦，真实代码里补 clone 更顺手。

## 一次调用的成本账

把 AnyDrawable::draw 的调用路径数一遍，性能直觉就有了。客户调用 `d.draw(out)`：**第一步**外壳成员函数——非虚、内联没问题，但 self_ 是堆指针，这一步多一次内存间接；**第二步**`self_->do_draw(out)`——虚表跳转，与经典虚函数版的 `d->draw(out)` 同价；**第三步**Model::do_draw 转发到 `data_.draw(out)`——data_ 是 Model 对象内的值成员，这步通常被内联吞掉。合计：**擦除版比"裸虚函数"多一步堆指针间接，比 concepts 版多两步（堆指针 + 虚表）**。账的另一面是收入：异构容器 + 值语义 + 第三方类型可装——三条 concepts 版给不了、裸虚函数版给两条（无值语义、要求继承）。工程上这笔账的常见结论：**边界处用擦除（API 入参、配置化的处理器链），热循环内用模板**——先把数据从容器里取出来、downcast 回具体类型做不到，就按类型分桶（`vector<AnyDrawable>` 在边界拆成 `vector<Sq>`/`vector<Ci>` 喂给模板函数），分桶动作本身是一次性的。这个"边界擦除、内核模板"的分层，正是很多渲染/解析库（如 std::function 挂回调 + 内核模板管线）的宏观结构。

手写三件套的判读清单，立项前过一遍：

- **被装类型有几百个实例化点吗？**——Model\<D\> 每类型一份，类型爆炸时擦除层代码体积可观测地涨；
- **接口函数超过三个吗？**——Concept_ 与每个 Model 要为每个接口函数写一行转发，接口大骨架就开始交税；
- **需要取回具体类型吗？**——擦除是单向门，取回只能 downcast 或换 std::any——需要取回的场景擦除不是正解；
- **外壳要进 unordered_map 的 key 吗？**——擦除外壳没有天然相等性，key 语义要自己定义（按 id？按内容？），定义不清就别放 key 位。

四问里两问以上答"是"，先考虑标准库现成件或重构接口；全"否"，三件套放手写——它就值这个价。

## 本章示例的断言面

main.cpp 的断言虽短，覆盖的合同条款一条不缺：

- `out == "sq;ci;lam;local"`——四来源异构容器的 draw 逐字符一致；
- `ids[0..3]` 四个 id——第二条转发路径独立验证（Model 双转发行各司其职）；
- `moved.draw(mout) == "sq"`——move 语义下被转走对象仍正确工作；
- 匿名局部类型能 push 进容器——"类型不可名状也可装"的擦除独有能力，直接断言。

## 陷阱清单

1. **拷贝构造被静默切片或丢合同**（现象：外壳允许默认拷贝，vector 扩容时行为诡异或编译错乱；原因：unique_ptr 不可拷贝，默认拷贝被 delete，但作者又在别处写了手抄拷贝；后果：编译错或双堆悬空。对策：明确所有权——要么补 clone 实现真拷贝，要么 delete 拷贝只留移动，本例选后者并写明理由）。
2. **Concept_ 析构非虚**（现象：外壳析构时只析构 Concept_ 部分，Model::data_ 泄漏；原因：经基类指针 delete 非虚析构对象是 UB；后果：内存泄漏。对策：`virtual ~Concept_() = default` 是三件套的第一行，永不可省）。
3. **构造函数模板吞下一切类型**（现象：本想只装形状，结果字符串、整数都能构造 AnyDrawable（若 concept 太宽）；原因：模板构造函数是隐式转换口；后果：类型系统防线失守。对策：concept 从宽到严收紧（本例双接口 + convertible_to），必要时 explicit）。
4. **擦除层的 const 撕裂**（现象：外壳 draw 声明 const，内部 Model::do_draw 也 const，但被装对象的方法非 const；原因：const 要一路传导到最内层；后果：编不过或被迫 const_cast。对策：合同里就写 const（本例 concept 用 `const D&`），让不满足 const 的类型在构造时就被拒）。
5. **以为擦除是免费的**（现象：热路径上万次 AnyDrawable::draw，性能不达标；原因：每次调用一跳虚表 + 对象堆上分布（缓存不友好）+ 外壳非模板调用不可内联；后果：比 concepts 版慢数倍。对策：热路径用模板/variant，擦除留给"边界处"（API 入参、异构集合），与第 29 章三栏表的结论一致）。

## 测试法

- **四来源对拍**：适配器形状、原生合同类型、lambda 包装、匿名局部类型，四种来源装进同一容器，输出逐字符断言（`sq;ci;lam;local`）——擦除的核心承诺"任意满足合同者可装"被断言钉死。
- **id 通道独立验证**：draw 与 id 两条转发路径各自断言（`ids[0]=="Sq" && ids[3]=="local"`），防止 Model 只转发了一条而另一条静默空转。
- **所有权行为断言**：移动后原对象不再可用（本例从容器里 move 出来单独画，结果仍正确；拷贝语句直接编译失败也是测试——注释在 erase.hpp 里）。
- **合同拒绝测试**：给一个只有 operator() 的类型尝试构造 AnyDrawable，应编译失败——concept 的拒绝能力本身是测试项（开发期用 static_assert 验证一轮即可）。

## 三书对应

- 之禅：第 22 章"适配器模式"（22.x 把不兼容接口包装成目标接口）——本例 SqA 适配器是它的微型版；另见第 6 章"代理模式"关于"外壳与实体分离"的讨论。
- 刘伟：第 9 章"外观模式"9.2 节"外观与适配器的区别"（外观统一门面、适配器转换接口——擦除外壳是两者的合体：统一门面 + 转发适配）；第 25 章策略模式 25.2 节"策略的泛型实现"。
- GoF：第 4 章 4.1 节 Adapter（4.1.2"实现"小节讨论"可插入的适配器"——"用参数化类型或 C++ 模板使适配器无需多用一个类"，正是 Model\<D\> 的思路）；第 1 章 1.6 节对运行期/编译期结构差异的论述是本章"擦除层虚函数 vs 客户层 concept"分层的理论源头。

*可选延伸：可运行示例见 examples/30_typeerasure/。*

---

上一章：[29 多态的三副面孔（虚函数/concepts/variant）](29-polymorphism.md) · 下一章：[31 日志系统：四模式混编现场](31-logging.md)
