# 19 · clojure.spec

> 对应示例：`examples/17_spec.clj`

> spec 是 Clojure 官方的**数据规范系统**：描述"数据长什么样"，然后
> 校验、解释错误、自动生成测试数据、给函数加运行时契约。
> 哲学：**在系统边界验数据，内部代码信任数据**。

## 19.1 定义与校验

```clojure
(require '[clojure.spec.alpha :as s])

(s/def ::id pos-int?)                        ; 注册规范：关键字 → 谓词
(s/def ::name (s/and string? #(<= 1 (count %) 50)))   ; and 组合
(s/def ::age (s/and int? #(<= 0 % 150)))
(s/def ::email (s/and string? #(re-matches #".+@.+\..+" %)))

(s/def ::person
  (s/keys :req [::id ::name ::age]           ; map 规范：必键/选键
          :opt [::email]))

(s/valid? ::person {::id 1 ::name "Alice" ::age 30})     ; => true
(s/valid? ::person {::id -1 ::name "Alice" ::age 30})    ; => false
```

`s/def` 把规范挂到**全局注册表**（关键字 → spec），任何地方 `::person` 都能引用——"schema 即数据、全局可寻址"是 spec 与众不同的第一点。

## 19.2 explain：错误解释器

```clojure
(s/explain ::person {::id -1 ::name "Alice" ::age 30})
;; -1 - failed: pos-int? in: [:my-ns/id] at: [:my-ns/id] spec: :my-ns/id
;; val: -1 说人话：哪个键、什么值、违反哪条

(s/explain-data ::person bad)     ; => 机器可读的错误结构（{:clojure.spec.alpha/problems [...]})
(s/conform ::age 30)              ; => 30    "对就（可能变形后）给我"
(s/conform ::age "x")             ; => :clojure.spec.alpha/invalid  错就给这个关键字
```

`conform` 的"变形"能力：规范不只是裁判，还能**解构**——正则操作符（19.3）把顺序数据解析成带标签的形状。

## 19.3 组合子速查

```clojure
(s/and int? pos?)                       ; 全部满足
(s/or :int int? :str string?)           ; 任一满足（conform 后带标签 {:int 42}）
(s/coll-of int? :min-count 1)           ; 元素规范 + 约束
(s/map-of keyword? int?)                ; 键值规范
(s/keys :req [::a] :opt [::b])
(s/tuple int? string?)                  ; 定长异构：[42 "x"]
(s/nilable int?)                        ; 允许 nil
(s/int-in 1 100) (s/double-in 0 1)      ; 范围
(s/uuid ...)                            ; 类型速记族

;; 正则操作符：给"顺序"建模（参数列表、消息序列）
(s/cat :verb keyword? :args (s/* int?))
(s/conform (s/cat :verb keyword? :args (s/* int?)) [:add 1 2 3])
;; => {:verb :add, :args [1 2 3]}     —— 顺序 → 标签 map
(s/+ int?) / (s/? string?) / (s/alt :a int? :b string?)
```

## 19.4 函数规范：fdef

```clojure
(defn add-nums [a b] (+ a b))

(s/fdef add-nums
  :args (s/cat :a number? :b number?)     ; 参数（s/cat 按"参数形状"建模）
  :ret number?                            ; 返回值
  :fn #(= (:ret %) (+ (-> % :args :a) (-> % :args :b))))  ; 参数与返回值的关系

(s/instrument `add-nums)                  ; 开启入参校验（开发期护栏）
(add-nums 1 "x")                          ; 抛 spec 异常，指出哪个参数不合规
```

- `s/fdef` 用**带反引号的函数名**（`` `add-nums `` = Var 引用）。
- `instrument` 只查 `:args`（入口契约）；`:ret`/`:fn` 留给测试。
- 关掉：`(s/unstrument `add-nums)`。开发期开着、生产关掉是惯例（检查有成本）。

## 19.5 生成式测试：spec 白送的数据工厂

注册过的 spec 自动获得**生成器**——前提是类路径上有 `org.clojure/test.check`（spec 的生成功能是可选依赖；本项目 classpath 没带它，示例里未启用）：

```clojure
;; project.clj 加 [org.clojure/test.check "1.1.1"] 后：
(clojure.spec.gen.alpha/generate (s/gen ::age))    ; => 随机一个合法 age（REPL 造数据）
(clojure.spec.test.alpha/check `add-nums)          ; 自动跑 N 组随机参数验证 fdef
```

`check` 对函数做属性测试：随机生成符合 `:args` 的参数 → 调函数 → 验 `:ret`/`:fn`。**不加一行测试代码就得到模糊测试**。发现失败时会**收缩**（shrink）到最小反例——"第 847 次随机尝试炸了，最小化成 `(add-nums ##NaN 0)`"。

## 19.6 实战定位

- **边界验证**：HTTP 入参、配置文件、消息队列负载进来时 `s/explain-data` 一次，错误带完整路径。
- **REPL 造数据**：`(generate (s/gen ::person))` 比手写测试数据快。
- **回归测试**：fdef + check 跑进 CI。
- 全 schema 化的替代品：`Malli`（数据驱动、更快、无全局注册表）——新项目常见选择；spec 胜在"语言亲儿子"与 `instrument`/`check` 生态。

## 19.7 坑位清单

1. **`::kw` 的 ns 归属**：`(s/def ::id ...)` 在 `my.ns` 里注册成 `:my.ns/id`——跨 ns 引用要 `::other/id` 或全名 `:my.ns/id`。数据里的键与 spec 键 ns 不匹配 → 校验失败但看起来"键明明有"。
2. **`s/keys` 只验"有的键"**：map 里**多余**的键默认不报错（除非 `s/map-of` 全量模式）——"少键报错、多键放行"是有意的宽松。
3. **`s/or` 的 conform 结果变形**：`(s/conform (s/or ...) x)` 返回 `[:分支 值]`/`{:分支 值}` 而不是原值——管线里要解标签。
4. **`instrument` 不校验返回值**——`:ret` 契约只有 `check` 会验。
5. **谓词要纯且无副作用**——生成器可能拿它跑成千上万次。
6. **注册表是全局的**：不同库对同一关键字 `s/def` 两次 → 后者覆盖（跟 12 章全局层级同款礼仪问题）。
7. **spec 校验有性能成本**：热路径逐条 `valid?` 不划算——只在边界验，内部信任（本章开头的哲学）。

---

上一章：[18 测试](18-testing.md) · 下一章：[20 Transducer](20-transducers.md)
