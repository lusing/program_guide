# 10 · 建造者

创建型篇收官。前四个模式都在回答"造什么"，建造者回答"**怎么一步步造一个复杂的东西**"。刘伟 7.1.2 节的定义：**将一个复杂对象的构建与它的表示分离，使得同样的构建过程可以创建不同的表示**。前半句是手段（分步），后半句是目的（同一过程，不同成品）。

## 意图与动机

构造函数参数爆炸是每个 C++ 工程师的老朋友：

```cpp
HttpRequest req("POST", "/api/orders",
                R"({"item":1})",
                {"Content-Type", "application/json"},
                {"X-Trace", "t-1"});      // 这五个参数哪个是 body 哪个是 header？
```

问题不止可读性：参数一多必然出现**同型参数相邻**（两个 string），调换顺序编译器一声不吭；必填与选填混在一张参数表里，调用方被迫抄全所有默认值；一旦加字段，全调用点重写。之禅第 11 章的场景（建造一辆车：引擎/底盘/车轮分步装配）和 GoF 的房子例子（先地基后墙再窗）讲的同一种痛：**装配有步骤、步骤有顺序、顺序里有约束**，一个构造函数装不下这么多信息。

## 经典写法：流式建造者

示例 `builder.hpp`，先立产品：

```cpp
struct HttpRequest {
    std::string method;
    std::string url;
    std::string body;
    std::vector<std::pair<std::string, std::string>> headers;
};
```

产品是一个普通聚合体——建造者模式的**成品不需要任何特殊设计**，这点常被误解。建造逻辑全部在 builder 上：

```cpp
class RequestBuilder {
public:
    // 链式设置返回 RequestBuilder&&（把 *this 当右值转发），让整条链
    // 保持右值属性；build() 用 && 限定——只能在右值上收尾，防止
    // "组装一半的 builder 被误当完成品再用"。
    RequestBuilder&& method(std::string m) {
        req_.method = std::move(m);
        return std::move(*this);
    }
    RequestBuilder&& url(std::string u) {
        req_.url = std::move(u);
        return std::move(*this);
    }
    RequestBuilder&& header(std::string k, std::string v) {
        req_.headers.emplace_back(std::move(k), std::move(v));
        return *this;
    }
    RequestBuilder&& body(std::string b) {
        req_.body = std::move(b);
        return std::move(*this);
    }

    HttpRequest build() && {
        // 不变量校验集中在这里：缺 method/url 当场报，调用方改不了内部状态
        if (req_.method.empty() || req_.url.empty())
            throw std::invalid_argument("method/url 必填");
        return std::move(req_);
    }

private:
    HttpRequest req_;
};
```

四个精心设计的细节，每个都值得展开：

1. **每个 setter 一个职责、名字即文档**：`method("POST")` 比第三个位置参数是 body 还是 header 清楚一万倍。参数校验分散在各 setter（本示例简单到无需），不变量校验集中在 `build()`。
2. **`std::move(*this)` 返回 `RequestBuilder&&`**：这是 C++ 流式 API 的正确写法。setter 若返回 `RequestBuilder&`（左值引用），整条链就是左值，`build() &&` 无法调用；返回 `&&` 保持链的右值属性。GoF 时代没有这个机制（当时 C++ 也没有右值引用），流式 API 是 C++11 后建造者的标配形态。
3. **`build() &&` 的右值限定**：只允许在临时链尾调用 `build()`。写 `RequestBuilder b; b.method("GET"); b.build();` 编译不过——半成品不能当完成品用。这是把"组装未完成"的错误从运行期提到编译期的范例。
4. **`build()` 返回 `std::move(req_)`**：内部状态的最后一刻移交，builder 用完即弃。

使用端：

```cpp
auto req = RequestBuilder{}
               .method("POST")
               .url("/api/orders")
               .header("Content-Type", "application/json")
               .header("X-Trace", "t-1")
               .body(R"({"item":1})")
               .build();
```

一行读出全部意图：发 POST 到 /api/orders，两个头，JSON 体。**每个字段名出现一次、只出现一次，字段与值肉眼对齐**——这就是建造者相对于位置参数的全部优势。运行输出：

```text
建造者: POST /api/orders headers=2 body={"item":1}
校验: build 拒绝 -> method/url 必填
Director: GET /index.html 固定产出
现代: GET /health 一步到位（无需 builder）
```

第二段演示不变量校验：缺 `url` 的组装在 `build()` 被拒绝，抛 `std::invalid_argument`——错误集中在一个出口，调用方 try-catch 一次即可。

## Director：固定剧本

GoF 定义里有第四个角色 Director（指挥者）——把"步骤顺序"固化下来复用。示例 `builder.hpp` 末尾：

```cpp
// Director：固定"剧本"，把步骤顺序固化——这是建造者区别于链式调用器的关键。
inline HttpRequest construct_get_index() {
    return RequestBuilder{}
        .method("GET")
        .url("/index.html")
        .header("Accept", "text/html")
        .build();
}
```

`construct_get_index` 是个函数形态的 Director：**同一个 GET 首页的组装剧本，处处调用处处一致**。GoF 书里 Director 是持着 Builder 引用调 `buildPart()` 的类，现代 C++ 里一个小函数即可。Director 存在的意义是"过程复用"：如果所有调用点都是现拼现用，Director 可以省——但一旦发现两处拼装的步骤序列相同，它就该出现了。运行第三行 `GET /index.html 固定产出` 验证两次调用产出逐字段相等。

## 现代写法：designated initializers

C++20 给聚合初始化带来了指定初始化器（C++23 里已完全成熟），简单场景下 builder 可以整个省掉（`main.cpp` 末段）：

```cpp
// ---- 现代对照：designated initializers 一行造简单请求 ----
HttpRequest simple{
    .method = "GET",
    .url = "/health",
    .body = "",
    .headers = {},
};
assert(simple.method == "GET" && simple.url == "/health");
```

`.method = "GET"` 的可读性与 builder 完全相当，且：无额外类型、无 build() 调用、跳过的字段自动默认。什么时候 designated initializers 够用、什么时候仍要 builder？判据三条：

1. **字段少、无复杂不变量** → designated initializers。聚合体能表达的，别造轮子。
2. **有跨字段不变量**（"有 body 就必须有 Content-Type"）→ builder。不变量要有代码载体，聚合初始化没有收尾钩子。
3. **同一过程多种表示**（同样的"组装 HTTP 请求"流程，产出 GET 请求/POST 请求/二进制包）→ 完整 GoF 形态（Builder 接口 + 多实现 + Director）。这是定义的后半句，也是建造者真正的本职。

换句话说：**builder 的不可替代区在"不变量校验"和"过程抽象"两件事上；只为参数可读性服务时，它已被语言特性取代**。这是 C++23 视角下对本模式的最大改写。

## 两版取舍

| 维度 | designated initializers | 建造者 |
|---|---|---|
| 代码量 | 零 | 一个类 |
| 校验时机 | 无（聚合不校验） | build() 收尾集中校验 |
| 过程复用 | 无 | Director 固化剧本 |
| 多表示 | 不支持 | 核心能力 |
| 部分设置 | 天然（跳过即默认） | 天然（不调即默认） |

## build() 的错误通道：异常还是 expected

第 1 章立的约定是"编程错误 throw、可预期失败 expected"，落到 builder 上就是一道真实的设计题：`build()` 校验失败走哪个通道？本示例选择抛 `std::invalid_argument`，理由是**缺 method/url 的 builder 是调用代码的 bug**——和传错参数类型同级别，这种错误不该出现在正常的错误处理路径里。但存在反例场景：如果 URL 合法性依赖运行期数据（配置表、用户输入），"组装失败"就成了可预期的失败，签名应改为：

```cpp
auto build() && -> std::expected<HttpRequest, std::string>;
```

判据不是"builder 用不用异常"，而是**非法状态从哪来**：代码写错（忘调 setter）→ 异常，让 bug 在测试期炸出来；数据不合格（外部输入填进 setter）→ expected，让调用方处理。同一模式里两个错误通道并存完全合法——`RequestBuilder` 也可以同时提供 `build() &&`（throw 版）和 `try_build() &&`（expected 版），把通道选择权交给调用点。这比"全项目二选一"更贴合实际：UI 层想弹提示（expected），内部管线想快速失败（异常）。

## 参数爆炸的其他药方：与建造者抢饭碗的三种写法

建造者不是治"构造参数多"的唯一药方，工程里还有三种竞争方案，摆在一起才知道 builder 什么时候该上：

```cpp
// ① 聚合 + designated initializers：已演示（本章现代对照），字段少时最轻。

// ② 默认参数链（重载或 std::optional 打底）：编译期把可选参数钉死
struct HttpReq2 {
    std::string method{"GET"};
    std::string url;
    std::string body{""};
};
auto r = HttpReq2{.url = "/health"};          // 与 ① 本质相同，字段默认值内建

// ③ struct 打包 + 命名字段：参数表塞不下时把参数升格成结构体
struct RequestOptions { bool verify_tls = true; int timeout_ms = 3000; };
void send(HttpRequest req, RequestOptions opt = {});
```

②③其实是①的变体——它们的共同本质是"**用聚合体的具名字段取代位置参数**"，C++20 之前（无 designated initializers）这个位置由 builder 独占，C++20 之后聚合体把简单场景收走了。builder 退守的核心阵地：**跨字段不变量校验**、**多步骤装配（中间状态有意义）**、**同一过程产出多种表示**（GoF 定义的后半句，Director 的用武之地）。三者之外 builder 还剩一块独有领地：**装配过程中要调用会失败的操作**——每一步都返回 `expected`、builder 内部累积错误、`build()` 一次性交账，这种"分步收集错误"的形态参数表和聚合体都做不了。

反过来读这张图也是挑选指南：字段 ≤5 且无不变量 → 聚合；参数只是"打包传输" → struct 打包；有不变量/有过程 → builder；还要多表示 → builder + Director（完整 GoF 形态）。

## 陷阱清单

1. **builder 泄漏半成品**（现象：`RequestBuilder b = RequestBuilder{}.method("GET"); b.build();` 编译不过才发现设计对了——但很多人会把 `build()` 的 `&&` 去掉让代码"能跑"；原因：不了解右值限定；后果：半成品被四处复用，不变量校验形同虚设。对策：保留 `build() &&`，理解 `std::move(*this)` 链式写法）。
2. **校验撒在各 setter**（现象：`method()` 里检查"必须是大写 HTTP 方法"；原因：想 fail fast；后果：校验分散、顺序耦合（后设的值可能让先设的非法），文案不一致。对策：setter 只管类型合法，跨字段不变量统一 `build()` 审）。
3. **builder 成了上帝类**（现象：一个 builder 建十种请求，setter 三十个；原因：复用冲昏头脑；后果：与直接传参一样不可读。对策：一个产品一个 builder；共享步骤用 Director 复用）。
4. **建造者持外部资源**（现象：builder 持连接池、文件句柄；原因：把"组装"与"获取"混在一起；后果：析构顺序、异常安全全是雷。对策：builder 只搬数据，资源由产品或使用方管理）。
5. **为三两个字段写 builder**（现象：`Point` 配了 `PointBuilder`；原因：模式过敏；后果：代码量三倍、可读性反降。对策：回到三条判据，designated initializers 优先）。

## 三书对应

- 之禅：第 11 章"建造者模式"（11.2 定义、11.3 应用、11.4 扩展——奔驰车模型的组装场景，Director 与 Builder 分工的经典演示）。
- 刘伟：第 7 章"建造者模式"（7.1 动机与定义、7.2 结构与分析、7.3 实例——KFC 套餐、7.5 扩展——省略 Director/链式调用）。
- GoF：第 3 章 3.2 节 Builder——与 Abstract Factory 对比（Builder 逐步造复杂对象、Abstract Factory 一步造一族；Builder 最后返回成品、AF 立即返回），实现节讨论"由谁组装/谁知道成品类型"，正是本章 Director 归属讨论的原点。

*可选延伸：可运行示例见 examples/10_builder/。*
