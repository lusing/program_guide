# 38 · 权限校验实战：三模式的管道切面

职责链（第 18 章）讲的是"请求沿链传递、一关否决即止"；本章给它配上两个搭档——**策略**（每关是一条可替换的规则）与**代理**（Api 门面站在真服务前面）——并让整条链用第 30 章的擦除件（std::function）搭建。权限校验是三模式协作的教科书场景：规则天然分关（认证/角色/时段）、规则天然会变（新合规要求 = 新关）、入口天然要门面（调用方不该知道有几关）。本章把三关管道写全，重点放在**管道顺序与拒因的关系**——顺序是职责链最容易被忽视的语义。

## 意图与动机

API 权限校验的规则清单：匿名用户全拒（认证）、非 admin 只许 read（角色）、8-22 点之外拒（时段）。三种糊法各有病：一个大 if 函数（三规则纠缠，加第四条改核心）；每条规则独立散查（调用方拼装，漏查一处漏一个洞）；抽象类 Guard + 子类链（第 18 章写法，能用但每条规则一个类）。本章写法：**Guard = std::function<bool(Request&, Verdict&)>**——规则是函数、链是函数序列、Api 是门面，三模式各就各位而类总量为零。拒因（Verdict::why）是管道的第一等公民：**哪一关拒的、为什么拒**，调用方与测试都靠它。

## 经典写法：Guard 管道

示例 `pipeline.hpp`。请求、裁决与 Guard 合同：

```cpp
struct Request {
    std::string user;
    std::string action;
    bool admin = false;
    int hour = 0;
};

struct Verdict {
    bool allow = false;
    std::string why;
};

// Guard：返 true = 通过、继续下一关；返 false = 拒绝、终止，why 必须已填。
using Guard = std::function<bool(Request&, Verdict&)>;
```

Guard 的合同一行说尽：**返 false 即终审，why 必须填**——这是第 18 章责任链"处理者决定是否传递"的函数版。三条策略（`auth/role/time_guard`）：

```cpp
// 策略一：认证——匿名用户一律拒绝。
inline Guard auth_guard() {
    return [](Request& r, Verdict& v) {
        if (r.user == "anon") {
            v = {false, "auth: anonymous"};
            return false;
        }
        return true;
    };
}
// role_guard：非 admin 只许 read -> {false, "role: ..."}
// time_guard：hour<8 或 hour>22 -> {false, "time: ..."}
```

三条规则的分类前缀（auth:/role:/time:）不是装饰——**拒因的首字符就是断言锚点**（本章测试用它钉住"哪一关拒的"）。管道与门面：

```cpp
// 管道：按 add_guard 的顺序依次过闸，第一关拒绝即返回。
class Api {
public:
    void add_guard(Guard g) { guards_.push_back(std::move(g)); }

    Verdict check(Request r) {
        Verdict v{true, "ok"};
        for (const auto& g : guards_) {
            if (!g(r, v)) return v;   // 职责链：第一个否决终止整个管道
        }
        return v;
    }
private:
    std::vector<Guard> guards_;
};
```

运行侧（`main.cpp`）六个请求的矩阵：

```cpp
Api api;
api.add_guard(auth_guard());
api.add_guard(role_guard());
api.add_guard(time_guard());   // 管道顺序 = add 顺序：auth -> role -> time

auto v1 = api.check({"anon", "write", false, 9});
assert(!v1.allow && v1.why[0] == 'a');      // 第一关拒

auto v2 = api.check({"root", "write", true, 9});
assert(v2.allow && v2.why == "ok");         // 三关全过

auto v4 = api.check({"tom", "write", false, 23});
assert(!v4.allow && v4.why[0] == 'r');      // role 先拒：非 admin + write

auto v5 = api.check({"root", "write", true, 23});
assert(!v5.allow && v5.why[0] == 't');      // role 过（admin），time 拒
```

第四、五个请求是本例的教学核心：**同一个 "write@23"，非 admin 与 admin 被不同的关拒掉**——拒因取决于管道顺序与请求画像的交点，这正是职责链语义的动态性。运行输出：

```text
auth线: anon+write 被第一关拒，why=auth
放行线: admin+write@9 三关全过
放行线: user+read@9 三关全过
role线: user+write@23 被第二关拒（管道顺序决定拒因）
time线: admin+write@23 被第三关拒
裁剪线: 只挂 auth 的管道同样工作
自检通过
```

## 管道与中间件的谱系

本章 Guard 管道不是孤立发明——它是 Web 中间件、HTTP 过滤器链、消息管道的同一原语在权限域的投影。谱系图一笔画清：

```text
   Web 中间件（Express/Django）      HTTP 过滤器（Servlet Filter）
        │ 请求穿过中间件序列                │ doFilter 前置/后置
        │ 每层可改请求/响应                 │ 责任链 + 组合
        v                                  v
   Guard 管道（本章）：<—— 三者共享同一语义内核
        请求画像 -> 规则序列 -> 终态（放行/拒因）
```

谱系里的细微差别值得点名：中间件模型允许每层**改写**请求（陷阱 4 的温床），本章 Guard 拿到的合同是**只读请求 + 只写裁决**——权限域天然该窄，因为校验不该改变语义。窄合同换来的是本章 six-request 矩阵的可断言性：规则间无隐式通信，拒因才逐关可归因。**把宽中间件的自由度用在权限域，是权限系统失控的第一步**——这也是本教程把合同写进 Guard 类型签名的动机（`bool(Request&, Verdict&)` 里可写面被压到 Verdict 一个通道）。

## 模式结构（管道切面图）

```text
   调用方 ──check(Request)──> Api（代理：门面守卫）
                                │
              ┌─────────────────┼─────────────────┐
              v                 v                 v
        auth_guard         role_guard        time_guard     （策略：规则即函数）
        anon? 拒 a        !admin&&write? 拒 r   8-22外? 拒 t
              │ pass            │ pass           │ pass
              └─────────────────┴────────────────┴──> {allow=true, why="ok"}

   切面语义：每关只看自己的规则（单一职责）；
            否决即终止（职责链）；add 顺序 = 评估顺序（装配即语义）。
```

## 现代讨论：为什么 Guard 是 function 而不是类

第 18 章的职责链用 Handler 抽象类 + 子类链，本章三关全是 lambda。差别在**规则的复杂度分布**：三关都是一行判断，类骨架（抽象基类 + 三个子类 + 挂链代码）是判断逻辑的十倍体量——第 39 章反模式的第一幕就是这类"骨架超过肉"的现场。function 版还免费获得**动态组合**：add_guard 顺序、裁剪（main 第六段只挂 auth）、条件挂载（生产环境才挂 rate_limit_guard）都是运行期装配。什么时候退回类版：**规则有状态**（限流的计数器、IP 黑名单的缓存）——lambda 捕获能带小状态，重状态规则的类更清晰；**规则要独立测试与注册**（第 35 章插件式规则库）——类有身份，function 没有。判据与第 31 章日志系统"经典线 vs 现代线"的取舍完全同构：**规则 = 无状态小函数用 function，有状态重逻辑用类**——这是本教程反复出现的分界线，权当第四次复习。

## Verdict 的合同：拒因是一等公民

权限系统的输出不是 bool 是 Verdict——这个设计决定值得单独说透。**why 通道的三重价值**：给用户看（"时段受限"比"被拒"可操作）、给排查者看（首字符定位到关）、给测试看（本章断言锚点）。合同的三条细则：拒因必须填（返 false 而 why 空是违约——用 debug 断言或预填哨兵机制化）；拒因带分类前缀（auth:/role:/time:）使测试与日志可以按关检索；放行也要有终态（why=="ok"）——"没拒"与"确认放行"是两种语义，测试断言后者。这套合同在合规场景还有第四重价值：**审计**——每条 Verdict 是一条可留痕记录，37 章"门面吞错误通道"的陷阱在这里反向应用：门面不但不吞，还要把拒因完整递出去。设计启示：**管道类系统的输出结构，要在第一版就把"哪一关、为什么"设计进去**——事后补审计是全管道动刀。

## 从三关到 N 关：规则库的组织

三条规则各自成函数只是起点，规则增长后的组织结构才见功力。**按域分组**：auth 域（认证/会话/租约）、resource 域（角色/所有权）、policy 域（时段/频率/合规）——每个域一个文件，域内规则互不知晓；**装配集中**：api.add_guard 的调用序列集中在一处（main 或专门的装配函数），顺序语义有一处可查；**新规则三步**：写函数、挂装配、加测试（拒因首字符断言顺手即得）——管道的可增长性全部来自"规则是 function"这个决定。若规则需要**参数化**（不同 Api 不同时段），函数工厂升级为闭包工厂（`time_guard(8, 22)` 返回捕获参数的 Guard）——第 31 章"组装权在哪一层"的同一决定在权限域重演。

## 拒因的下游：本地化与错误码

Verdict::why 是给**开发者**看的调试通道，面向**用户**与面向**监控**的输出不该直接复用它——三分流是管道类系统的常规收尾：

- **给用户**：why 的分类前缀（auth:/role:/time:）映射到本地化文案表（"时段受限，请于 8:00-22:00 重试"）——用户文案由 UI 层按前缀查表产出，管道不掺自然语言；
- **给监控**：Verdict 加数字错误码（`int code`，auth=1/role=2/time=3），告警按码聚合——字符串做键聚合是运维事故源，数字码才是度量单位；
- **给审计**：每条 Verdict 加时间戳与请求画像快照，落盘只追加——与陷阱 5 的 trail 字段合流成一条审计线。

三分流的组织原则：**管道只产结构化 Verdict，呈现层各取所需**——把用户文案直接写进 why（"您的账户暂时无法执行该操作"）看似省事，实为把 i18n 与管道语义焊死。37 章外观的"门面不吞错误通道"在这里再进一步：门面不但要递出拒因，还要递出**结构化的**拒因。

## 扩展练习

本章骨架上顺理成章的四个延伸，难度递增：

- **闭包工厂**：time_guard 参数化 `time_guard(8, 22)`——返回捕获参量的 Guard，验证"规则即值"（10 分钟）；
- **审计 trail**：Verdict 加 `std::vector<std::string> trail`，每关过/拒各追加一条——陷阱 5 的对账实现；
- **const 化合同**：check 改 `const Request&`，全部 Guard 签名跟着 const 化——陷阱 4 的机械改造，编译器保证"规则只读"；
- **条件挂载**：写一个 `rate_limit_guard`（捕获每秒计数），只在 release 装配挂载——有状态规则的类版与 function 版各写一遍，对拍（对应正文"现代讨论"节末尾的判据）。

## 本章示例的断言面

main.cpp 六个请求钉住的合同：

- v1 anon+write：第一关拒、why 首字符 'a'——认证关先于一切；
- v2 admin+write@9 / v3 user+read@9：双放行路径且 why=="ok"——放行有显式终态；
- v4 user+write@23：role 关拒（'r'）——非 admin 的 write 走不到 time 关；
- v5 admin+write@23：time 关拒（'t'）——同请求不同画像不同拒因；
- v6 只挂 auth 的管道：组合性合同（裁剪不破坏行为）。

## 陷阱清单

1. **管道顺序不当**（现象：time_guard 挂第一，深夜的匿名请求被拒因 "time" 掩盖了更本质的 "auth"；原因：顺序即语义，装配者没按"从廉价到昂贵、从本质到表象"排；后果：拒因误导排查。对策：认证类规则永远先于资源类规则；顺序写进测试（本章 why 首字符断言就是顺序测试））。
2. **Guard 拒绝但不填 why**（现象：verdict.why 为空，调用方无法提示用户；原因：合同"返 false 必填 why"没有强制；后果：静默拒绝。对策：构造 Verdict 时预填哨兵（"unreached"），或 debug 断言 !why.empty()——合同要有机器可查的形态）。
3. **Guard 在链上做重活**（现象：某关内部查数据库/调远程，整条管道延迟叠加；原因：职责链默认每关都被路过；后果：性能黑洞。对策：重活规则挂管道后段（先廉价的过滤），或改异步预筛——顺序纪律的性能面）。
4. **check 里修改 Request**（现象：某 guard 顺手改了 r.action（规范化成小写），下一关看到的是被改过的请求；原因：Guard 收 Request& 可写引用；后果：规则间隐式通信，顺序依赖加深。对策：check 传 const Request&（规则只读）+ Verdict 装载产出——本例合同其实该是 const 引用，教学版保留 & 是为了让"改请求"这个坑可讨论）。
5. **门面吞掉部分通过的信息**（现象：管道过两关后被拒，调用方只知道最终 Verdict，前面关的审计记录全丢；原因：check 只返回终审结果；后果：审计断档。对策：审计日志在 Api 层记（每关过/拒各一条），或 Verdict 加 trail 字段——合规场景这是硬需求）。

## 测试法

- **拒因首字符矩阵**：六个请求的 why 首字符（a/r/t/o）逐一断言——"哪一关拒的"与"顺序即语义"两条合同一次钉死。
- **放行与拒因同权重**：allow 请求断言 why=="ok"——放行也要有可断言的终态，不是"没拒就是过"。
- **管道裁剪**：只挂一关的 Api 行为正确——组合性本身是合同。
- **请求画像交叉**：同一请求两种画像（非 admin vs admin 的 write@23）被不同关拒——职责链动态语义的直接证据。
- **拒因可检索**：分类前缀让日志与审计按关过滤（auth:/role:/time:）——why 通道的结构化面。
- **Guard 只读请求**：check 前后 Request 不变（规则侧 const 化是改造练习，测试先钉住"无副作用"行为）——陷阱 4 的守门哨兵。

## 三书对应

- 之禅：第 17 章"责任链模式"（17.x 责任链与"规则引擎"的扩展讨论）；另见第 18 章策略模式关于"算法整体替换"的定义（本章每关即一个策略）、第 28 章代理模式关于"控制对象访问"的分类（守卫代理 Guard Proxy 正是 Api 的角色名）。
- 刘伟：第 16 章"责任链模式"16.4 节"纯的与不纯的责任链"——本例是**纯**职责链（要么全过要么某关终审）；16.3 节对"链的组装"（客户端组装 vs 配置组装）的讨论与本章 add_guard 的装配语义对应；第 22 章"代理模式"22.2 节"保护代理"（控制对真实对象的访问权限）。
- GoF：第 5 章 5.1 Chain of Responsibility"实现"小节对"链的隐式 vs 显式引用"与"表示请求"的讨论——本例 Request/Verdict 显式成对，"why 通道"是 GoF 时代未展开的一笔；5.10 Proxy 的 Protection Proxy 小节（访问控制代理）。

*可选延伸：可运行示例见 examples/38_permission/。*

---

上一章：[37 文档导出：桥与外观的合体](37-docexport.md) · 下一章：[39 反模式三幕](39-antipatterns.md)
