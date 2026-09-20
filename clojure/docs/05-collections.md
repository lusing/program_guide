# 05 · 集合 ⭐

> 对应示例：`examples/03_collections.clj`

> 四种核心集合 + 一个"不可变但不贵"的底层故事。`conj` 在不同集合上
> 插不同位置——这个"多态"是 Clojure API 设计的缩影：**按抽象编程，
> 不按具体类型编程**。

## 5.1 四种集合一张表

| 类型 | 字面量 | 有序 | 查找 | `conj` 插在哪 | `(count x)` |
|---|---|---|---|---|---|
| list | `'(1 2 3)` | 插入序 | O(n) | **头部** O(1) | O(n) |
| vector | `[1 2 3]` | 索引序 | `nth` O(1) | **尾部** 摊还 O(1) | O(1) |
| map | `{:a 1}` | 无序 | `get` O(1)≈ | 不适用（用 assoc） | O(1) |
| set | `#{1 2}` | 无序 | `contains?` O(1)≈ | 元素级 | O(1) |

**默认用 vector**：读多写多、能随机访问、字面量好写。list 的主场是"代码"（11 章）和"头插频繁"的场景。

```clojure
(conj '(1 2 3) 0)    ; => (0 1 2 3)   头部
(conj [1 2 3] 4)     ; => [1 2 3 4]   尾部
(conj #{1 2} 3)      ; => #{1 2 3}
(conj {:a 1} [:b 2]) ; => {:a 1, :b 2}   conj 对 map 吃"键值对"
```

`conj` 语义是"以该集合最自然的方式加入"——同一函数名，四种行为，写出与具体类型解耦的代码。

## 5.2 不可变但不贵：结构共享

```clojure
(def a [1 2 3])
(def b (conj a 4))     ; a => [1 2 3]   b => [1 2 3 4]
```

直觉会以为 `conj` 复制了整个 vector。实际：vector 内部是 **32 叉树**（trie），`conj` 只在尾部加一个元素时**新分配一条从根到叶的路径**（≈ log₃₂ n 个节点，百万元素才 4 层），其余节点与旧 vector **共享**。`b` 和 `a` 是两棵逻辑上独立的树，物理上共享 99% 节点。

这就是"持久化数据结构"（persistent data structures）。代价模型：

| 操作 | vector | 数组（可变） |
|---|---|---|
| `nth` | O(1)（树高） | O(1) |
| `conj` 尾插 | O(log₃₂ n) ≈ 实际常数 | 摊还 O(1) |
| 结构共享的新旧并存 | 免费 | 做不到（改了旧的就没旧的） |

**同一个旧值可以派生 N 个新值，互不干扰**——这是函数式管线（09 章）和并发安全（14 章）的地基。

## 5.3 序列抽象：一切皆可 `first`/`rest`

`first`/`rest`/`seq` 是比四种集合更底层的抽象——vector、list、map、set、string、Java 数组、Java 集合、文件行、无限流……全都能喂给序列函数：

```clojure
(first [10 20 30])      ; => 10
(rest [10 20 30])       ; => (20 30)     注意：返回惰性 seq，不是 vector
(seq {:a 1 :b 2})       ; => ([:a 1] [:b 2])   map 转 Entry seq
(seq "ab")              ; => (\a \b)     字符 seq
(seq nil)               ; => nil         习惯用法：判空 (if (seq xs) ...)
```

`(seq coll)` 把任何"可枚举物"转成 seq；空集合和 nil 都给出 nil——所以惯用的判空是 `(when (seq xs) ...)` 而不是 `(when (not (empty? xs)) ...)`。

## 5.4 vector 专属

```clojure
(nth [10 20 30] 1)        ; => 20   越界抛异常
(get [10 20 30] 1)        ; => 20   越界返回 nil（容忍风格）
([10 20 30] 1)            ; => 20   vector 本身也是函数！（ifn?）
(peek [1 2 3])            ; => 3   看尾（栈/队列视角）
(pop [1 2 3])             ; => [1 2]   去尾
(subvec [1 2 3 4 5] 1 3)  ; => [2 3]   O(1) 切片，共享结构！
(vec '(1 2 3))            ; => [1 2 3]  转 vector
(vector-of :int 1 2)      ; 未装箱 int vector（省内存，23 章）
```

`subvec` 是"切片不复制"的隐藏武器，处理大 buffer 时比 `slice` 类 API 舒服。

## 5.5 map 专属

```clojure
(def m {:name "Alice" :age 30})
(:name m)                    ; => "Alice"   关键字取值（首选）
(get m :name)                ; => "Alice"
(get m :nick "N/A")          ; => "N/A"     带默认
(m :name)                    ; => "Alice"   map 也能当函数
(:age m)                     ; 两种"函数调用"都行，但关键字版更短

(assoc m :age 31 :city "NYC")  ; 增/改（多个）
(dissoc m :age)                ; 删
(update m :age inc)            ; => {:name "Alice", :age 31}  用函数改
(merge {:a 1} {:b 2} {:a 9})  ; => {:a 9, :b 2}  后者覆盖前者
(merge-with + {:a 1} {:a 2})  ; => {:a 3}   冲突时用函数合
(get-in {:addr {:city "NYC"}} [:addr :city])          ; 深取
(update-in m [:addr :city] str "!")                   ; 深改
(assoc-in {:a {}} [:a :b] 1)                          ; 深设（中间层自动建 map）
(keys m) (vals m)                ; 键/值 seq
(zipmap [:a :b] [1 2])           ; => {:a 1, :b 2}
(frequencies [:a :b :a])         ; => {:a 2, :b 1}
```

`update` 是"读-改-写"三合一，比 `(assoc m :age (inc (:age m)))` 干净且少一次查键。**嵌套结构用 `-in` 家族**，别一层层手撕。

map 键**任何类型都行**（关键字、字符串、数字、向量……），但要求不可变且实现正确 hashCode——关键字是默认答案。

## 5.6 set 专属

```clojure
(def s #{:a :b})
(contains? s :a)              ; => true
(:a s)                        ; => :a   set 里有关键字 → 返回它自己；没有 → nil
(s :a)                        ; 同上
(conj s :c) (disj s :a)       ; 增 / 删
(clojure.set/union #{1 2} #{3})          ; 并
(clojure.set/intersection #{1 2 3} #{2}) ; 交
(clojure.set/difference #{1 2 3} #{2})   ; 差
(clojure.set/select even? #{1 2 3 4})    ; => #{2 4}  set 版 filter
(set [1 2 2 3])               ; => #{1 2 3}  去重神技
```

`(set coll)` 去重 + `(clojure.set)` 四则运算——很多"手写循环去重"的代码一行就没了。

## 5.7 有序变体

```clojure
(sorted-map 3 :c 1 :a)          ; => {1 :a, 3 :c}      按键排序
(sorted-set 3 1 2)              ; => #{1 2 3}
(sorted-map-by > 1 :a 2 :b)     ; 自定义比较器
(array-map :a 1 :b 2)           ; 保持插入序（小 map；大了自动升 hash map）
```

需要"确定性输出顺序"（测试、diff、报告）时 `sorted-map` 是开关。

## 5.8 相等语义

```clojure
(= [1 2 3] '(1 2 3))      ; => true   序列相等：元素相等即相等（跨类型！）
(= [1 2] (seq [1 2]))     ; => true
(= {:a 1} {:a 1N})        ; => true   数字键按数值比
(= #{1 2} #{2 1})         ; => true   set/map 无序
(= [1 2] (list 1 2))      ; => true
(hash [1 2 3])            ; 与 '(1 2 3) 同 hash —— 相等即同 hash，才能当 map 键
```

**序列相等跨具体类型**是刻意设计：数据长得一样就是一样，不管它是 vector 还是 list。代价：`(= [1 2 3] (subvec ...))` 等都成立，心智简单。

## 5.9 元数据：值上贴标签

```clojure
(def v (with-meta [1 2 3] {:doc "三个数"}))
(meta v)                          ; => {:doc "三个数"}
(vary-meta v assoc :tag :demo)    ; 派生一个带新 meta 的等值集合
```

元数据**不参与相等比较**——同一个值可以带不同标签。编译器用它存类型提示（23 章），库用它存行号、来源等。

## 5.10 坑位清单

1. **`(contains? [10 20] 10)` 是 false**：vector 上 `contains?` 判的是**索引**不是元素——`(contains? [10 20] 1)` 才是 true。判元素用 `(some #{10} [10 20])` 或先转 set。
2. **`rest` vs `next`**：空集合 `(rest [1])` → `()`（空 seq），`(next [1])` → nil。判空惯用 `(seq ...)`，循环里混用会踩边界。
3. **`assoc` 到 vector 用索引**：`(assoc [1 2 3] 0 9)` → `[9 2 3]`；索引必须在范围内（不能像 map 一样"追加"）。
4. **map 字面量重复键不报错**：`{:a 1 :a 2}` 悄悄取后者——reader 不警告，出 bug 极难查。
5. **`(conj m {:b 2})` 和 `(conj m [:b 2])` 都行**，但 `(conj m '(:b 2))` 也可以——"MapEntry 样子的东西"都吃；纯键 `(:b)` 不行，`{:b nil}` 想清楚再写。
6. **`subvec` 后持有大 vector**：subvec 共享父结构——持有切片会钉住整个父树，内存敏感场景用 `(vec (subvec ...))` 断开。
7. **`{}` 和 `#{}` 在 reader 里就差一个 `#`**：手滑写 `{1 2 3}` 是"1→2, 3→nil?"——奇数个元素直接语法错，但偶数时静默变 map。

---

上一章：[04 数据类型](04-data-types.md) · 下一章：[06 函数与闭包](06-functions.md)
