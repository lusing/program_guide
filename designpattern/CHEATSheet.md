# CHEATSheet —— C++23 设计模式教程实测速查

40 章、40 个示例、双通道（MSVC 14.51 + clang，/std:c++latest 与 -std=c++23）实测沉淀。分三部分：语言坑（写示例时真实踩过）、构建工具坑（build.ps1 验证体系）、双形态判据（经典 vs 现代一条线）。

---

## 一、语言坑（按主题分组，全部有示例级复现）

### variant / visit

- **visit 进行中不得改写被访问的 variant**——销毁正绑定的备选项是 UB。对策：visitor 返回新状态，visit 结束后赋回（25 章状态机、36 章陷阱 2）。
- **variant 递归不能直装**：`variant<Num, Add>` 里 Add 持 Ast 值会因备选项不完整/无限大小编不过。对策：`unique_ptr<Ast>` 拆环（unique_ptr 允许持未完整类型）——20/36 章标准手法。
- **visit 的整组 lambda 返回类型必须一致**（或统一转换）；异类型返回用 variant 装或副作用收编（28 章）。
- **加备选项后漏 visit 分支编译即报错**——封闭集合的 exhaustive 是免费的，28 章"何时该用访问者"的判据来源。

### concepts / requires

- **单一形态 concept 对类策略不成立**：只有 `{ f(o) }`（operator()）形态时，成员函数策略装不进去。对策：双形态 concept（`.apply` 析取 `operator()`）+ `if constexpr` 分派（26 章实测）。
- **MSVC requires 表达式有顺序相关误判 bug**：特定文件布局下对无 operator() 的类误判通过（孤立最小复现时正确失败）。对策：concept 判定用双编译器对拍，深探针用 build/_probe 模式直调 cl/clang++。
- **concept 只查语法不查语义**——`d.draw(out)` 能过编译不等于副作用合同成立，语义合同写进注释与测试（29 章陷阱 4）。

### 类型擦除 / std::function

- **构造函数模板不是默认构造函数**：静态哨兵对象 `RegisterOne reg_hex;` 需要默认构造，模板构造函数推不了 C。对策：模板类 `RegisterOne<C>`（35 章实测 C2512）。
- **std::function 要求被装物可拷贝**——捕获 unique_ptr 的 lambda 装不进。对策：std::move_only_function（C++23）或自写擦除外壳（30 章）。
- **擦除三件套第一行永远是 `virtual ~Concept_() = default`**——经基类指针 delete 非虚析构是 UB（30 章陷阱 2）。
- **擦除外壳所有权三态**：std::function（拥有+可拷贝）/ move_only_function（拥有+move-only）/ function_ref（引用，只活一次调用）——选型判据"擦除后对象活多久"（30 章）。
- **move-only 有连锁反应**：vector 扩容走移动（需 noexcept）、需值拷贝的算法不可用、存进 std::function 编不过（30 章"move-only 的连锁反应"）。

### 虚函数 / 继承

- **基类析构必须 virtual**（接口类第一条）——29 章陷阱 2。
- **const visit 里累计用 mutable**——逻辑 const 物理可变；忘写则 C2678 无 viable operator+=（28 章实测）。
- **struct/class 前置声明必须与定义一致**——`struct Machine;` 对 `class Machine` 定义，MS ABI 下 clang 报 -Wmismatched-tags（25 章实测）。
- **声明拷贝构造会抑制隐式默认构造**；make_unique 需完整类型 → 构造函数移到类外定义（25 章实测）。
- **状态类间互相切换**：成员函数只声明、状态类全部定义完再统一内联实现，否则引用未定义类型（25 章实测）。
- **值容器装基类 = 切片**：多态容器永远 `unique_ptr<Base>` 或 variant，29 章陷阱 5。
- **final 不只是文档**：去虚化（devirtualization）的合同——单一类型热路径上虚函数版可追平 concepts 版（29 章）。

### 初始化 / 生命周期

- **静态初始化顺序事故**：跨 TU 命名空间级静态对象顺序未定义。对策：Meyers 单例（函数内静态，C++11 起线程安全）——35 章 Registry 的地基。
- **哨兵可能被链接器丢弃**：静态库里无人引用的目标文件整个被丢。对策：可执行工程直接列源文件 / /WHOLEARCHIVE / force-link（35 章陷阱 3）。
- **vector 扩容悬空引用**：池借出 `Conn&` 前必须 reserve(上限)，引用稳定性是设计决定（34 章陷阱 2）。
- **RAII 守卫三查**：析构只做归还、拷贝一律禁、构造抛出则析构不跑（没借到不用还）——32/34 章守卫手法。
- **运行期可写的单例 = 全局变量**：测试污染实证见 39 章第三幕；合规判据"启动期写、运行期只读、真全局"三条全占。
- **捕获悬垂**：std::function sink 按引用捕获局部变量，活得比变量久就是 UB（31 章陷阱 4）；订阅者析构必须退订（RAII 订阅句柄，32 章）。

### 格式化 / 输出

- **std::println 的字符串是编译期 format string**：字面 `{x:3,y:4}` 被当格式参数解析，consteval 检查失败（C7595）。对策：花括号转义 `{{...}}` 或改写文本（36 章实测）。
- **确定性输出纪律**：同一性/计数/时序断言转布尔或计数比较；不打印地址、时间戳、浮点直接值、类型大小（全书的判定六条之一）。

---

## 二、构建与验证（build.ps1 体系）

- **双通道**：MSVC（vcvars64 → 接口单元/.cpp 三步或一次多 cpp 链接）+ clang（-std=c++23）；clangd 旧 std 诊断全为噪音，以 build.ps1 为准。
- **判定六条**：exit 0 / stderr 空 / stdout 非空 / 无控制字符 / 以"自检通过"结尾 / 零告警；`-All` 全量约 80 项 ≈ 6-8 分钟。
- **多编译单元**：示例目录里所有 .cpp 按名排序一次编出来并链接（35 章插件三 TU 依赖此机制）。
- **探针方法**：疑似编译器 bug 用 build/_probe_$PID.cpp 最小复现 + 变体对照 + .cmd 包装直调 cl/clang++（26 章 requires bug 的定位路径）。
- **并发跑 build.ps1 安全**：探针与产物均带 PID/示例名隔离；不同示例名互不碰撞。
- **CRLF 纪律**：仓库 autocrlf 环境下，.sh 与输入文件注意行尾（Go/Prolog 教程同款教训）。

---

## 三、双形态判据（经典 vs 现代，一条线贯穿全书)

| 维度 | 经典类层次 | 现代压缩 | 判据 |
|---|---|---|---|
| 策略/规则 | Strategy 子类 | concept 策略 / std::function | 无状态小函数 → function；有状态重逻辑/跨库 → 类 |
| 状态 | State 类层次 | variant 状态 / constexpr 表 | 转移纯跳转 → 表；带动作/负载 → variant 或类 |
| 访问 | Visitor 双分派 | variant + overload | 结构冻结 → 两版都行；结构开放 → 只有继承 |
| 多态容器 | unique_ptr<Base> | variant 值容器 | 集合开放 → 虚函数；封闭 → variant |
| 通知 | Observer 类 | function 订阅 + RAII 句柄 | 生命周期管理交给作用域 |
| 装饰 | Decorator 类链 | function 组合 | 运行期叠放 → 类；编译期固定 → 组合 |
| 创建 | Factory 体系 | lambda / 直接构造 | 产品族成套切换才上工厂 |
| 可调用物 | 函数对象类 | std::function / move_only_function / function_ref | 按所有权三态选 |

一句话总纲：**骨架成本必须被红利覆盖**（39 章）；合同先行，形态可换（29 章三版对拍）。
