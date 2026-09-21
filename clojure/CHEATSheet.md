# Clojure 速查表（CHEAT Sheet）

语法速查 + 全部实测坑索引。配合 `docs/` 28 章教程使用；所有代码在 **Clojure 1.12.6 / Leiningen 2.13 / OpenJDK 26** 实测。

## 1 语法速查

### 1.1 字面量

```clojure
42  0xFF  2r1010     long        3.14  1.5e3    double
42N                 BigInt      3.14M           BigDecimal
1/3                 Ratio（精确分数，自动约分）
\a \newline         字符         "str"           String
'sym  :kw  ::kw     符号/关键字/当前ns关键字
'(1 2)  [1 2]  {:a 1}  #{1}      list/vector/map/set
#"regex"            Pattern     #(...)#(...)#_  匿名fn/字面量集合/丢弃
##Inf ##-Inf ##NaN  特殊浮点    #inst #uuid     tagged
```

### 1.2 定义

```clojure
(def x 1)                       全局 Var
(defn f "doc" [{:keys [a]} & more] ...)   函数（doc/解构/可变参数）
(defn- g ...)                   私有
(defn multi ([] 0) ([x] x))     多 arity
#(+ % %2)                       匿名（% %1 %2 %&；不可嵌套）
(declare h)                     前置声明
(defrecord R [a b])  (->R 1 2) (map->R {:a 1})
(defprotocol P (m [this]))      协议
(deftest t (is (= 1 1)))        测试
```

### 1.3 集合操作

```clojure
(conj [1] 2)  (conj '(1) 2)     vector尾/list头
(assoc m :k v)  (update m :k f)  (dissoc m :k)
(get m :k d)  (m :k)  (:k m)     取值三式（关键字当函数最优）
(get-in m [:a :b])  (update-in ...) (assoc-in ...)
(merge m1 m2)  (merge-with + m1 m2)
(nth v i)  (get v i d)  (v i)   向量取值（nth越界抛/get越界nil）
(subvec v 1 3)                  O(1) 切片
(into {} xf coll)               transducer 收集
(zipmap ks vs)  (frequencies c) (group-by f c)
(set c)  (clojure.set/union|intersection|difference)
(sorted-map) (sorted-set)  (array-map)  有序/插入序变体
```

### 1.4 序列管线

```clojure
(map f c)  (map f c1 c2)  (filter p?)  (remove p?)  (keep f)
(reduce f init c)  (reduced x)         折叠/提前终止
(mapcat f)  (some p? c)  (every? p? c) (not-any? p? c)
(take|drop|take-while|drop-while|take-nth n c)
(partition n)  (partition-all n)  (partition-by f)
(sort-by k >)  (sort-by (juxt :a :b))  多级排序
(iterate f x)  (repeat x)  (cycle c)  (range)  无限流
(for [x c :when p :while q :let [y (f x)]] ...)  列表推导
(doseq [x c] ...)  (dotimes [i n] ...)  副作用循环
(-> x f (g 1))  (->> c (map f) (reduce +))       线程宏
(as-> x $ ...)  (some-> m :a :b)  (cond-> x p f)  变体
(comp f g)  (partial f 1)  (juxt :a :b)  (complement p?)  (constantly v)
```

### 1.5 控制流 / 解构

```clojure
(if t a b)  (when t ...)  (if-let [x f] a b)  (when-let [x f] ...)
(cond p1 v1 :else v)  (condp = x 1 "one" "def")  (case x :a 1 "def")
(and a b)  (or a b)               短路 + 返回决定值
(loop [i 0] ... (recur (inc i)))  尾递归（recur 必须尾位置）
(let [[a b & r :as all] v] ...)   顺序解构
(let [{:keys [a b] :or {a 1} :as m} mp] ...)  关联解构
(defn f [{:keys [host] :or {host "x"}}] ...)  参数解构
(try ... (catch Ex e ...) (finally ...))
(throw (ex-info "msg" {:k v}))  (ex-data e)  (ex-message e)
```

### 1.6 并发 / 状态

```clojure
(atom 0)  (swap! a f)  (reset! a v)  @a
(add-watch a :k f)  (set-validator! a p?)
(dosync (alter r f) (commute r f) (ensure r))   STM
(agent [])  (send a f)  (send-off a f)  (await a)
(future ...)  @f  (deref f 100 :default)  (promise)  (deliver p v)
(pmap f c)  (volatile! v)  (vswap! v f)
```

### 1.7 Java / IO / ns

```clojure
(.method obj a)  (Class/static x)  (Klass. a)  (new Klass a)
(.. o (m1) (m2))  (doto obj (.setX 1))  (memfn m)
(int-array [1])  (aget/aset/alength)  (amap/areduce + ^ints 局部)
^String ^long ^longs                 类型提示
(slurp f)  (spit f s :append true)   一把梭
(with-open [r (io/reader f)] (line-seq r))   流式
(pr-str)  (clojure.edn/read-string)  ← 安全；read-string 会执行代码！
(io/resource "x")  (file-seq dir)
(ns a.b (:require [x.y :as z] :refer [f]) (:import [java.util Date]))
(require 'a.b :reload)  (in-ns 'a.b)  *ns*
(doc f) (source f) (dir ns) (apropos "s")
```

### 1.8 宏 / spec / transducer

```clojure
`form  ~x  ~@xs  x#               syntax-quote 三件套 + gensym
(defmacro m [a & body] `(if ~a (do ~@body) nil))
(macroexpand-1 'form)  (macroexpand 'form)
(s/def ::k p?)  (s/and p1 p2)  (s/or :a p1)  (s/keys :req [::a])
(s/valid? ::k v)  (s/explain ::k v)  (s/conform ::k v)
(s/fdef f :args (s/cat :x int?) :ret int?)  (s/instrument `f)
(into [] xf coll)  (transduce xf + 0 coll)  (sequence xf coll)
(comp (map f) (filter p?) (take 3) cat dedupe distinct)
```

## 2 语言坑位索引（实测）

| # | 坑 | 章 |
|---|---|---|
| L1 | 只有 `nil`/`false` 为假——`0 "" []` 全是真；判空用 `(seq xs)` | 04 |
| L2 | `(/ 1 3)` 是精确比值不是 0.33；出口处 `double` 收口 | 04 |
| L3 | `(+ Long/MAX_VALUE 1)` 抛溢出——大数用 `+' 42N` | 04 |
| L4 | `(= 1 1.0)` false；跨类型比数字用 `==` | 04 |
| L5 | `(count "😀")` = 2（UTF-16 代理对）；用 `codePointCount` | 04 |
| L6 | `conj` 位置随类型变：list 头、vector 尾 | 05 |
| L7 | `(contains? [10 20] 10)` false——vector 判的是索引 | 05 |
| L8 | 序列相等跨类型：`(= [1 2] '(1 2))` true | 05 |
| L9 | map 字面量重复键静默取后者 | 05 |
| L10 | `#()` 不可嵌套；`%` 在 reduce 里是 acc 不是元素 | 06 |
| L11 | **Symbol/关键字/map/vector 都可调用**（IFn）：`('* 2 3)` 返回 3 不报错 | 06/28 |
| L12 | `if` 第三表达式是"if 之后"不是 else 分支 | 07 |
| L13 | `case` 匹配值是编译期字面量 | 07 |
| L14 | `and`/`or` 返回决定值不是布尔 | 07 |
| L15 | `:or` 默认值只在键**缺失**时生效，值为 nil 不救 | 08 |
| L16 | `:keys` 只吃关键字键；JSON 的字符串键要 `:strs` | 08 |
| L17 | `map`/`filter` 惰性：不消费不执行；chunk 一口气 32 个副作用 | 09/10 |
| L18 | 头部驻留：循环里持有长 seq 的头 = 内存泄漏 | 10 |
| L19 | `line-seq` 逃出 `with-open` = 读已关流 | 10/16 |
| L20 | 宏参数 `~x` 出现两次 = 求值两次；`let`+`x#` 缓存 | 11 |
| L21 | defmulti 重定义会清空方法表 | 12 |
| L22 | record 与 map 的 `=` 是 **false**（类型敏感相等） | 13 |
| L23 | `dissoc` 声明字段 → record 退化成普通 map | 13 |
| L24 | `swap!`/`alter` 函数必须纯（重试会重复副作用） | 14 |
| L25 | dosync 里的 IO 会随事务重试重复执行 | 14 |
| L26 | `read-string` 读外部数据 = RCE；用 `clojure.edn` | 16 |
| L27 | ns 名 → 路径：点变目录、`-` 变 `_`；不匹配找不到文件 | 17 |
| L28 | `= 浮点` 断言不稳——用误差范围 | 18 |
| L29 | `s/keys` 只验必键，多键放行 | 19 |
| L30 | spec 生成器需要 test.check 在 classpath | 19 |
| L31 | `(map f)` 单参形态是 transducer 不是 seq | 20 |
| L32 | `cat` 裸进 comp（不带括号）；`(cat)` arity 错 | 20 |
| L33 | `halt-when` 默认返回触发值不是累积结果 | 20 |
| L34 | 有状态 transducer（`partition-all`/`dedupe`）别复用同一实例 | 20 |
| L35 | 函数式快排丢 pivot：`equal` 段不含 pivot，要 `(cons pivot equal)` | 21 |
| L36 | dijkstra 的 min-key 遇 map 缺键 NPE——先灌 `##Inf` | 21 |
| L37 | 拓扑排序每轮从剩余边重算节点集会丢末批节点——单独维护 todo | 21 |
| L38 | 反射 537 倍/装箱 5 倍/数组 26 倍——`*warn-on-reflection*` dev 常开 | 23 |
| L39 | `areduce`/`amap` 直接吃 def var 触发反射——绑 `^ints` 局部 | 23/15 |
| L40 | go 块里写阻塞调用堵死 dispatcher——IO 进 `thread` | 24 |
| L41 | `!!`/`!` 配对：go 里单叹号，普通线程双叹号 | 24 |
| L42 | 写已关闭 channel 返回 false 不抛错——关键路径要检查 | 24 |
| L43 | HttpURLConnection 方法必须大写；POST 不设 Content-Type 默认表单被 wrap-params 吃掉 body | 25 |
| L44 | Ring 的 `:body` InputStream 只能读一次 | 25 |
| L45 | `:aot :all` 放顶层拖慢日常——进 `:uberjar` profile | 26 |
| L46 | standalone jar 里 `slurp` 相对路径失效——用 `io/resource` | 26 |

## 3 Windows / 工具链坑位索引（实测）

| # | 坑 | 对策 |
|---|---|---|
| W1 | PATH java=8 使 lein 2.13 崩（`--enable-native-access`）；lein.bat 只认 `JAVA_CMD` | 设 `JAVA_CMD` 指向 JDK 16+ 完整路径 |
| W2 | PowerShell 拆散 `-Dfile.encoding=UTF-8` → ClassNotFoundException | 参数逐个成串：`& $java '-cp' $cp 'clojure.main' $f` |
| W3 | `(try...)` 不能进 PS 分组表达式 `( ... )` | 辅助函数 + finally 内 Pop-Location |
| W4 | 示例硬编码 `/tmp` → Windows 变 `G:\tmp` | `java.io.tmpdir` / 项目内 `build/tmp` |
| W5 | ring 在 Clojars 不在 Central；偶发 SSL 握手失败 | 重试；确认网络可达两仓库 |
| W6 | Jetty 12 只带 SLF4J API（NOP 警告） | 无害；加 logback 消除 |
| W7 | lein 2.13 uberjar 落 `target/` 而非 `target/uberjar/` | 按 `*standalone.jar` 匹配 |
| W8 | 标记验证只证"跑完"不证"算对"——三路快排丢 pivot 靠输出对账抓出 | 算法示例配 `(= (sort x) (f x))` 对账断言 |

## 4 验证命令

```powershell
pwsh build.ps1 -All          # 24 示例 + lein-lab（25 验证单元）
pwsh build.ps1 -File 19      # 单跑一个
pwsh build.ps1 -Lab          # lein-lab 四步链
```

```bash
# macOS / Linux（Clojure CLI + deps.edn）
./build.sh --all                       # 24 个示例
./build.sh --file 19_algorithms.clj    # 单跑一个
./build.sh --lab                       # lein-lab 四步链（需 lein）
```
