# 12 · 多方法

> 对应示例：`examples/10_multimethods.clj`

> 单分发看类型（协议，13 章）；**多方法按任意函数的结果分发**——
> 一块数据、多个维度、还能带层级（派生）关系。它是 Clojure 里
> "开放扩展 + 灵活分发"的那把瑞士军刀。

## 12.1 defmulti / defmethod：两步走

```clojure
(defmulti area :shape)            ; 1) 分发函数：取参数的 :shape 字段做"路由键"

(defmethod area :rectangle        ; 2) 每个键注册一个实现
  [{:keys [w h]}]
  (* w h))

(defmethod area :circle
  [{:keys [r]}]
  (* Math/PI r r))

(area {:shape :rectangle :w 3 :h 4})    ; => 12.0... 12
(area {:shape :circle :r 1})            ; => 3.14159...
```

心智模型：`defmulti` 建一张"键 → 方法"注册表；调用时先跑**分发函数**（这里是 `:shape`——关键字当函数，04/06 章），拿结果查表执行。

**分发函数任意复杂**——这是与 Java 重载/协议的本质区别：

```clojure
(defmulti pay (fn [order] [(count order) (:vip? (meta order))]))  ; 向量键：多维度
(defmulti handle (fn [req] [(:method req) (:version req)]))       ; "方法 × 版本"双维
```

## 12.2 默认分支：:default

```clojure
(defmethod area :default [shape] 0)
(area {:shape :triangle :base 3 :h 4})    ; => 0    没命中走默认
```

没有 `:default` 且无命中 → 抛 `IllegalArgumentException: No method in multimethod ... for dispatch value: :triangle`。

## 12.3 层级：derive / isa?

多方法的第二板斧——**自定义 isa? 层级**（不是 Java 类继承！）：

```clojure
(derive ::dog ::animal)          ; ::dog 派生自 ::animal（关键字层级的边）
(derive ::cat ::animal)
(derive ::puppy ::dog)           ; 可以多层

(isa? ::dog ::animal)            ; => true
(isa? ::puppy ::animal)          ; => true   传递
(parents ::dog)                  ; => #{:my-ns/animal}
(ancestors ::puppy)              ; #{::dog ::animal}
(descendants ::animal)           ; #{::dog ::cat ::puppy}
```

分发时自动沿层级上行找方法：

```clojure
(defmulti speak (fn [x] (:kind x)))
(defmethod speak ::animal [x] "...")     ; 给"大类"统一实现
(defmethod speak ::cat [x] "Meow")       ; 个别覆盖

(speak {:kind ::puppy})                  ; => "..."   沿 ::puppy→::dog→::animal 命中
(speak {:kind ::cat})                    ; => "Meow"  精确命中优先
```

**优先级规则**：精确匹配 > 层级距离更近的 > :default。

层级默认进**全局层级表**（`derive` 不带第一参数时）。多线程/库场景用私有层级：

```clojure
(def h (make-hierarchy))
(def h2 (derive h ::a ::b))              ; 返回新层级（不可变！）
```

然后把层级传给 defmulti：`(defmulti f disp-fn :hierarchy #'h)`。库代码别污染全局层级——这是社区礼仪。

## 12.4 管理方法

```clojure
(defmulti f :k)
(defmethod f :a [x] 1)
(remove-method f :a)          ; 删一个
(remove-all-methods f)        ; 清空
(prefer-method f Type1 Type2) ; 两者歧义时声明偏好
(methods f)                   ; => {:a #object[...]}   查看注册表
```

**歧义**：两个 ancestor 距离相同且都有方法 → 抛歧义异常，用 `prefer-method` 裁决。

## 12.5 三种分发机制对比

| | `case`/`condp` (07 章) | 多方法 | 协议 (13 章) |
|---|---|---|---|
| 分发依据 | 编译期字面量 / 任意值 | **任意函数结果** | **类型**（Java class） |
| 扩展新情况 | 改原代码 | **加 defmethod，不动原代码** | 加 extend/defrecord |
| 多维分发 | 手写嵌套 | 原生支持（向量键） | 不支持 |
| 性能 | 最快（hash/常量） | 中（map 查 + isa?） | 快（直接方法表） |
| 数据导向 | 弱 | **强**（分发值可以来自数据本身） | 弱 |

**选择直觉**：
- 分发键是**类型** → 协议（13 章）。
- 分发键是**数据的值/多个维度**（形状、状态机状态、消息类型组合）→ 多方法。
- 就两三个固定分支 → `case`，别杀鸡用牛刀。

多方法的甜点区是**"数据自己声明自己该怎么处理"**——`area :shape` 里没有一行类型检查；新形状新文件加 `defmethod` 即可，开闭原则的语言级实现。

## 12.6 坑位清单

1. **分发函数返回的键必须是"稳定相等"的值**：关键字/小向量没问题；返回**新建大对象**（每次 hash 不同）永远 miss——键要简单（`:shape`、`[a b]`、类型对象）。
2. **`nil` 也是合法分发值**：分发函数返回 nil 时找 `nil` 方法或 `:default`——数据缺字段时行为要预设。
3. **全局 derive 污染**：库代码用 `make-hierarchy` 私有层级，否则两个库对同一关键字的不同派生会互相打架。
4. **ISA 歧义抛异常**：多继承层级 + 两个等距方法 → `prefer-method` 显式裁决，别靠运气。
5. **defmulti 重定义**：`defmulti` 重新执行会**清空方法表**——REPL 里重载 defmulti 后记得重注册 defmethod（常见"方法怎么没了"惊魂）。
6. **多方法不参与类型检查**：参数形状写错（`:keys [w h]` vs 数据 `:width`）到运行时才 nil 参与运算——边界用 spec 钉住（19 章）。

---

上一章：[11 宏与元编程](11-macros.md) · 下一章：[13 记录与协议](13-records-protocols.md)
