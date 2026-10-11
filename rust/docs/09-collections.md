# 09 · 集合

> 对应示例：`examples/09_collections/`
>
> std 的四大集合：Vec、HashMap、BTreeMap、VecDeque（外加 HashSet）。
> 选型、惯用法（entry）、容量机制、以及"为什么没有 C++ 那么多容器"。

## 9.1 选型表

| 需求 | 用 | 备注 |
|---|---|---|
| 有序序列、按下标 | `Vec<T>` | 90% 场景的默认答案 |
| 键值查找（无序） | `HashMap<K, V>` | O(1)，遍历顺序随机 |
| 键值查找（有序遍历/范围查询） | `BTreeMap<K, V>` | O(log n)，按键排序 |
| 去重集合 | `HashSet<T>` / `BTreeSet<T>` | 同上两者关系 |
| 双端队列 | `VecDeque<T>` | 队列/栈（Vec 只擅长尾端） |
| 栈（LIFO） | `Vec<T>` | push/pop 就是栈 |
| 字符串拼接缓冲 | `String` | 本质是 Vec<u8> 的 UTF-8 版 |

没有链表（`LinkedList` 存在但文档劝退）、没有 deque 之外的 queue——**数据局部性胜过理论复杂度**是 std 的明确立场，特殊需求去 crates.io（如 `indexmap`、`hashbrown`）。

## 9.2 Vec：创建、读写、增删

```rust
let mut v: Vec<i32> = Vec::new();   // 空
let init = vec![10, 20, 30];        // 带初值（vec! 是宏）
let zeros = vec![0u8; 1024];        // [初值; 长度]

v[0]           // 越界 panic（Debug/Release 一致）
v.get(10)      // Option<&T>：None，不 panic —— 下标不可信时用这个
v.first() / v.last()      // Option<&T>（get(0) 的惯用替代）
v.push(x) / v.pop()       // 尾部 O(1)；pop 返回 Option<T>
v.insert(i, x) / v.remove(i)  // O(n)：后面元素搬家
v.sort() / v.sort_unstable()  // 排序（后者更快、不保稳定）
v.dedup()        // 只去相邻重复——先 sort 再 dedup 才彻底
v.contains(&x) / v.iter().position(|e| *e == x)
```

遍历三形态（15 章展开）：

```rust
for x in &v { }       // 共享借用：只读
for x in &mut v { *x *= 10; }   // 可变借用：就地改
let owned = v;        // move 整个容器；for x in v 则逐元素 move 出来
```

## 9.3 容量：Vec 是智能指针

Vec 不是"数组"，它是一个**智能指针**——和 `String` 一样，由三部分组成：指向堆缓冲的指针、记录元素个数的 `len`、堆分配的 `capacity`。`Vec::new()` 不分配堆内存；`with_capacity(n)` 预分配 n 个元素的空间：

```rust
let mut v = Vec::with_capacity(10);
assert_eq!(v.capacity(), 10);
for i in 0..10 { v.push(i); }
v.clear();                      // 清空元素，但容量保留
assert_eq!(v.capacity(), 10);   // 堆内存没释放
v.shrink_to_fit();              // 归还多余容量
assert_eq!(v.capacity(), 0);
```

容量满了会自动翻倍扩容（4→8→16→…），每次扩容都意味着 realloc + 全量拷贝。知道规模时 `with_capacity` 是免费午餐。

**容量 ≠ 大小**：容量是与内存分配相关的概念，大小是元素个数。搞混两者可能写出逻辑漏洞——CVE-2018-1000657 就是 `VecDeque::reserve` 把环形缓冲区的"逻辑容量"当成"物理容量"，少分配了一个位置导致缓冲区溢出。Rust 的内存安全保证的是**没有未定义行为**；逻辑层面的容量计算错误，编译器管不了。

零大小类型（ZST）的 Vec 有个有趣的实现细节：`Vec<Foo>`（Foo 是单元结构体）的容量等于 `usize::MAX`——反正 ZST 不占内存，"无限容量"是合法的占位值。

## 9.4 HashMap 与 entry 惯用法

```rust
use std::collections::HashMap;
let mut freq: HashMap<&str, u32> = HashMap::new();

// 词频统计的惯用法：entry API
for w in "go rust go zig rust go".split_whitespace() {
    *freq.entry(w).or_insert(0) += 1;   // 无则插 0，返回 &mut V
}
freq.get("go")          // Option<&V>
freq.remove("zig")      // Option<V>：连删带取
*freq.entry("new").or_insert(0) += 0;   // 不存在才插入，存在不动
```

`entry()` 一次哈希同时完成"查找 + 预备插入"，比 `contains_key` + `insert` 两趟高效且无 TOCTOU 缝隙。

**Entry 是一个 enum**：`entry(key)` 返回 `Entry<K, V>`，它只有两个变体——`Occupied`（桶里有值）和 `Vacant`（桶是空的）。`or_insert` 的实现就是对这个 enum 做 match：

```rust
pub fn or_insert(self, default: V) -> &'a mut V {
    match self {
        Occupied(entry) => entry.into_mut(),  // 有值：返回已有值的可变引用
        Vacant(entry) => entry.insert(default), // 空桶：插入默认值
    }
}
```

还有 `or_insert_with(|| ...)`（惰性计算默认值，闭包只在空桶时执行）和 `or_default()`（要求 V: Default）。`entry` 也支持 `and_modify(|v| ...)` 链式修改已有值。

键的约束：`Eq + Hash`（String、整数、&str、tuple 都行；float 不行——NaN）。**键 move 进表**：

```rust
let key = String::from("键");
map.insert(key, 1);      // key 所有权进表
// println!("{key}");    // ← 编译错：key 已 move
```

查找却不用拥有键：`map.get("字面量")`——`&str` 能哈希就能查 String 的表。

## 9.5 HashMap 遍历顺序每次运行都不同

```rust
for (k, v) in &map { }   // 顺序 = 哈希布局 + 随机化种子，每次运行不同！
```

这是**防依赖**设计（RandomState）。需要确定顺序：

- 只要求有序遍历/范围查询 → `BTreeMap`；
- 要求"插入顺序" → `indexmap` crate；

**为什么默认哈希不是最快的**：`HashMap` 默认用 SipHash——一种密码学安全的哈希函数，能抵御哈希碰撞 DoS 攻击（攻击者构造大量碰撞键让哈希表退化成链表）。代价是比 FxHash 等非加密哈希慢。性能分析确认哈希是热点时，可以换 `BuildHasher` 实现（如 `hashbrown` 的 `foldhash`、`rustc-hash` 的 `FxHash`）——`HashMap<K, V, S>` 的第三个泛型参数就是哈希器类型。
- 测试里比较集合 → 排序后比较（本教程示例实测踩过：HashSet 交集顺序不稳定）。

## 9.6 BTreeMap：有序版的代价与收益

```rust
let mut bt = BTreeMap::new();
bt.insert(3, "c"); bt.insert(1, "a"); bt.insert(2, "b");
for (k, v) in &bt { }            // 恒按 1,2,3 输出
bt.range(1..=2)                  // 范围查询（HashMap 做不到）
bt.first_key_value() / bt.last_key_value()
```

O(log n) vs HashMap 的 O(1)，换来：有序遍历、范围迭代、最坏情况稳定（HashMap 有病态碰撞）。键约束 `Ord`。

## 9.7 HashSet：集合运算

`HashSet<T>` 是 `HashMap<T, ()>` 的类型别名——值就是键，没有关联数据。它只关心"某个值在不在集合里"，去重是它的本职。

```rust
let a: HashSet<i32> = [1, 2, 3].into();
let b: HashSet<i32> = [2, 3, 4].into();
a.intersection(&b)   // 交：迭代器
a.union(&b)          // 并
a.difference(&b)     // 差（a 有 b 无）
a.symmetric_difference(&b)  // 对称差
a.insert(x) / a.contains(&x) / a.remove(&x)
```

集合运算返回**迭代器**（惰性，15 章），配 `collect` 落地。比较前记得排序——顺序不确定。

### HashSet 的底层：哈希函数如何工作

`HashSet` 的核心是**哈希函数**——把任意大小的输入映射到固定大小的哈希值（通常是 64 位整数）。一个好的哈希函数保证：**输入微小变化 → 输出显著变化**。无论输入是一个 `i32` 还是整本《战争与和平》（约 3MB），输出的哈希值都是同样大小。

```rust
use std::collections::HashSet;
use std::hash::{Hash, Hasher};
use std::collections::hash_map::DefaultHasher;

fn my_hash<T: Hash>(t: &T) -> u64 {
    let mut s = DefaultHasher::new();
    t.hash(&mut s);
    s.finish()
}

assert_eq!(my_hash(&42), my_hash(&42));   // 相同输入 → 相同哈希值
assert_ne!(my_hash(&42), my_hash(&43));   // 不同输入 → （几乎一定）不同哈希值
```

`HashSet` 的 `insert` 内部流程：

1. 计算新条目的哈希值；
2. 如果集合中没有相同哈希值的条目 → 直接插入，更新索引；
3. 如果有（**哈希碰撞**）→ 进一步用 `Eq` 比较确认是否真的相同，相同则替换，不同则处理碰撞（开放寻址或链地址）。

这就是为什么 `HashSet` 要求 `T: Eq + Hash`——`Hash` 决定大致位置，`Eq` 处理碰撞时的精确判断。

### HashSet vs Vec：什么时候用哪个

| 操作 | `Vec<T>` | `HashSet<T>` |
|---|---|---|
| `contains(&x)` | O(n) 线性扫描 | O(1) 哈希查找 |
| `insert(x)` | O(1) 尾部追加 | O(1) 均摊（需算哈希 + 更新索引） |
| 遍历 | O(n)，顺序 = 插入序 | O(n)，顺序随机 |
| 去重 | 手动（`sort` + `dedup`） | 自动（重复 insert 无效） |
| 内存 | 紧凑 | 有哈希表开销（约 2 倍） |

**选型直觉**：需要频繁查"在不在"且不关心顺序 → `HashSet`；需要按下标访问或保持顺序 → `Vec`。数据量小（<100）时 Vec 的线性扫描可能更快（缓存友好），但代码可读性上 `HashSet::contains` 的意图更清晰。

### 实战：用 HashSet 做视场（FOV）缓存

游戏开发中 `HashSet` 的经典用法是存储"当前可见的图块坐标集合"——`contains` 的 O(1) 查询让渲染循环高效判断每个图块是否可见：

```rust
use std::collections::HashSet;

#[derive(Clone, Debug, PartialEq)]
pub struct FieldOfView {
    pub visible_tiles: HashSet<(i32, i32)>,  // 当前可见的坐标集合
    pub radius: i32,
    pub is_dirty: bool,                       // 脏标记：位置变了才重算
}

impl FieldOfView {
    pub fn new(radius: i32) -> Self {
        Self { visible_tiles: HashSet::new(), radius, is_dirty: true }
    }
}

// 渲染时：O(1) 判断图块是否可见
// if player_fov.visible_tiles.contains(&(x, y)) { /* 渲染 */ }
```

`HashSet` 不实现 `Copy`（内部是堆分配的哈希表），所以包含它的结构体也不能 derive `Copy`——这是 04 章所有权规则在集合上的直接体现。

## 9.8 VecDeque：双端队列

```rust
let mut dq: VecDeque<i32> = VecDeque::new();
dq.push_back(2);    // 尾进
dq.push_front(1);   // 头进
dq.pop_front()      // Option<T>：头出（队列）
dq.pop_back()       // 尾出
dq.front() / dq.back()   // Option<&T>
```

FIFO 队列用它（`Vec` 头部操作是 O(n)）。内部是环形缓冲区：两个指针 + 一个可增长数组，头尾指针在数组上环形移动。与数组可直接比较：`assert_eq!(dq, [2]);`。

## 9.9 容器与所有权

容器拥有元素（04 章递归规则）：

```rust
let mut v: Vec<String> = vec![];
let s = String::from("data");
v.push(s);              // s move 进容器
let back = v.remove(0); // move out
let drained: Vec<String> = std::mem::take(&mut v); // 整表搬空
```

`Vec<Option<T>>` 想"取出元素但保留位置"时是常用手法：`v[i].take()`。

## 9.10 坑位清单

1. **HashMap 遍历顺序不稳定**：测试断言先 collect→sort；展示输出用 BTreeMap。
2. **dedup 不排序**：只去相邻重复，先 `sort_unstable()` 再 `dedup()`。
3. **f64 不能做 HashMap 键**：无 Eq/Hash；离散化（`OrderedFloat` crate）或换整数。
4. **insert 覆盖旧值并返回它**：`let old = map.insert(k, v2);` 返回 `Option<V>`——判断"是否首次插入"用 `entry().or_insert()` 的引用语义更直。
5. **`vec![...]` 对编译期定长数据多余**：clippy `useless_vec` 会建议改数组 `[1,2,3]`——数组也能 `.iter()`、也能比较，本教程零警告纪律照办。
6. **`get(0)` 被 clippy 提醒改 `first()`**：语义同，可读性高。
7. **容量预分配**：知道规模时 `Vec::with_capacity(n)` / `HashMap::with_capacity(n)`，省掉反复扩容拷贝（默认翻倍增长）。
8. **remove(i) 返回元素而不是 bool**：拿走值；"删存在与否"用 `if i < v.len()` 先判或换数据结构。
9. **clear/truncate 不释放容量**：要归还内存用 `shrink_to_fit()`（或 drop 整个 Vec）。clippy 会提醒 `truncate(0)` 应写 `clear()`。

---

上一章：[08 枚举与模式匹配](08-enums.md) · 下一章：[10 错误处理](10-errors.md)
