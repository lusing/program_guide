# 08 · 解构 ⭐

> 对应示例：`examples/06_destructuring.clj`

> 解构是 Clojure 手感最好的特性：在绑定的位置**按形状声明式取值**。
> `let`、`fn` 参数、`loop`、`defn`、`for`、`doseq`——所有绑定处通用同一套语法。

## 8.1 顺序解构：向量/列表按位拆

```clojure
(let [[a b c] [1 2 3]]        ; a=1 b=2 c=3
  (+ a b c))

(let [[a b & more] [1 2 3 4 5]]   ; & 收尾部：more=(3 4 5)
  more)

(let [[a _ b] [1 :ignored 3]]     ; _ 惯用：跳过不要的位
  [a b])

(let [[a b :as all] [1 2 3]]      ; :as 整体也绑定
  [a b all])                       ; => [1 2 [1 2 3]]

(let [[[x1 y1] [x2 y2]] [[1 2] [3 4]]]   ; 嵌套随意深
  [x1 y1 x2 y2])
```

**超出长度不报错**：`(let [[a b c] [1]] ...)` → c 是 nil。与"参数个数必须匹配"的函数调用相反——解构对数据宽容。

## 8.2 关联解构：map 按名取

```clojure
(def user {:name "Alice" :age 30 :email "a@x.com" :addr {:city "NYC"}})

(let [{:keys [name age]} user]            ; 按键取（关键字键）
  [name age])                              ; => ["Alice" 30]

(let [{:keys [name] :or {name "N/A"}} {}]  ; 缺省值
  name)                                    ; => "N/A"

(let [{:keys [name] :as u} user]           ; :as 整体
  [name (:age u)])

(let [{:keys [addr] {:keys [city]} :addr} user]  ; 嵌套 map 解构
  city)                                     ; => "NYC"
```

- `:keys [a b]` 绑定**同名局部**（键 `:a` → 变量 `a`）。
- `:strs [a]` 对字符串键、`:syms [a]` 对符号键——同款语法三兄弟。
- `:or {name "N/A"` 只在键**缺失**时生效——键存在但值是 nil 时**不**启用默认（`(get m :k :default)` 同语义）。要"nil 也算缺"得自己 `(if (nil? x) default x)`。
- 嵌套解构 `{:keys [city]} :addr` 语法怪但值得会：**在键的位置放一份子解构**。

**命名空间键的简写**：

```clojure
{:user/id 1 :user/name "A"}
(let [{:keys [:user/id :user/name]} m] ...)   ; 全写
(let [:user/keys [id name]] m] ...)           ; ns/keys 简写：绑定 id、name
```

## 8.3 混合与函数参数

顺序 + 关联可以组合——REST API 处理"位置参数 + 选项"的标配：

```clojure
(defn distance [[x1 y1] [x2 y2]]              ; 参数直接是形状
  (Math/sqrt (+ (Math/pow (- x2 x1) 2) (Math/pow (- y2 y1) 2))))
(distance [0 0] [3 4])                        ; => 5.0

(defn make-url [{:keys [host port path] :or {port 80 path "/"}}]
  (str "http://" host ":" port path))
(make-url {:host "example.com"})              ; => "http://example.com:80/"

(defn handle [[verb url] {:keys [body timeout] :or {timeout 30}}]
  ...)                                        ; 混合：位置 + map + 默认
```

**可读性提示**：`(defn f [{:keys [a b]}] ...)` 的签名即文档——读者一眼看到函数要什么形状的数据。这比 `(defn f [m] ... (get m :a))` 强一个量级。

## 8.4 在 for / loop / let 派生体里

```clojure
(for [{:keys [name score]} students              ; for 里按形状取
      :when (> score 80)]
  name)

(loop [{:keys [x y]} start, acc []]              ; loop 绑定同样支持
  ...)
```

## 8.5 惯用法速查

| 需求 | 写法 |
|---|---|
| 取 map 字段 | `(let [{:keys [a b]} m] ...)` |
| 取向量前几个 | `(let [[a b] v] ...)` |
| 头尾分离 | `(let [[head & tail] coll] ...)` |
| 配默认值 | `{:keys [a] :or {a 1}}` |
| 拿整体 + 拆部分 | `[a b :as all]` / `{:keys [a] :as m}` |
| 只判存在 | `(when-let [{:keys [id]} m] ...)` |
| 解构函数返回的多元组 | `(let [[ok data] (validate x)] ...)` |

## 8.6 坑位清单

1. **`:or` 对"值为 nil"不生效**——只救缺失键。DB 里 NULL 变 nil 的场景会咬人。
2. **`{:keys [name]}` 只解关键字键** `:name`——对 `{"name" "A"}`（字符串键）要用 `:strs [name]`。JSON 库默认给字符串键（`cheshire`/`clojure.data.json`）。
3. **解构不是验证**：形状不对给 nil 不报错（`(let [{:keys [a]} [1 2]] a)` → nil）。边界数据要 spec（19 章）。
4. **`&` 解构出的是 seq 不是 vector**：`(let [[a & r] [1 2 3]] (conj r 4))` → `(2 3 4)` 是 list 语义；要 vector 自己 `(vec r)`。
5. **`:as` 放最后**：`[a :as all]` 合法、`[:as all a]` 也合法但风格怪——团队统一放尾。
6. **嵌套解构过深是坏味道**：三层以上的 `{:keys …} :addr` 建议拆中间 let——解构密度太高反而难读。
7. **vector 解构按位置吃 map 也能跑**（map 是 seq of Entry），但得到的不是你以为的字段——跨类型解构前先确认形状。

---

上一章：[07 控制流](07-control-flow.md) · 下一章：[09 高阶函数](09-higher-order.md)
