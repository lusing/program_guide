# 09 · 集合

> 对应示例：`examples/09_collections/`
>
> std 的四大集合：Vec、HashMap、BTreeMap、VecDeque（外加 HashSet）。
> 选型、惯用法（entry）、以及"为什么没有 C++ 那么多容器"。

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

## 9.3 HashMap 与 entry 惯用法

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

键的约束：`Eq + Hash`（String、整数、&str、tuple 都行；float 不行——NaN）。**键 move 进表**：

```rust
let key = String::from("键");
map.insert(key, 1);      // key 所有权进表
// println!("{key}");    // ← 编译错：key 已 move
```

查找却不用拥有键：`map.get("字面量")`——`&str` 能哈希就能查 String 的表。

## 9.4 HashMap 遍历顺序每次运行都不同

```rust
for (k, v) in &map { }   // 顺序 = 哈希布局 + 随机化种子，每次运行不同！
```

这是**防依赖**设计（RandomState）。需要确定顺序：

- 只要求有序遍历/范围查询 → `BTreeMap`；
- 要求"插入顺序" → `indexmap` crate；
- 测试里比较集合 → 排序后比较（本教程示例实测踩过：HashSet 交集顺序不稳定）。

## 9.5 BTreeMap：有序版的代价与收益

```rust
let mut bt = BTreeMap::new();
bt.insert(3, "c"); bt.insert(1, "a"); bt.insert(2, "b");
for (k, v) in &bt { }            // 恒按 1,2,3 输出
bt.range(1..=2)                  // 范围查询（HashMap 做不到）
bt.first_key_value() / bt.last_key_value()
```

O(log n) vs HashMap 的 O(1)，换来：有序遍历、范围迭代、最坏情况稳定（HashMap 有病态碰撞）。键约束 `Ord`。

## 9.6 HashSet：集合运算

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

## 9.7 VecDeque：双端队列

```rust
let mut dq: VecDeque<i32> = VecDeque::new();
dq.push_back(2);    // 尾进
dq.push_front(1);   // 头进
dq.pop_front()      // Option<T>：头出（队列）
dq.pop_back()       // 尾出
dq.front() / dq.back()   // Option<&T>
```

FIFO 队列用它（`Vec` 头部操作是 O(n)）。与数组可直接比较：`assert_eq!(dq, [2]);`。

## 9.8 容器与所有权

容器拥有元素（04 章递归规则）：

```rust
let mut v: Vec<String> = vec![];
let s = String::from("data");
v.push(s);              // s move 进容器
let back = v.remove(0); // move out
let drained: Vec<String> = std::mem::take(&mut v); // 整表搬空
```

`Vec<Option<T>>` 想"取出元素但保留位置"时是常用手法：`v[i].take()`。

## 9.9 坑位清单

1. **HashMap 遍历顺序不稳定**：测试断言先 collect→sort；展示输出用 BTreeMap。
2. **dedup 不排序**：只去相邻重复，先 `sort_unstable()` 再 `dedup()`。
3. **f64 不能做 HashMap 键**：无 Eq/Hash；离散化（`OrderedFloat` crate）或换整数。
4. **insert 覆盖旧值并返回它**：`let old = map.insert(k, v2);` 返回 `Option<V>`——判断"是否首次插入"用 `entry().or_insert()` 的引用语义更直。
5. **`vec![...]` 对编译期定长数据多余**：clippy `useless_vec` 会建议改数组 `[1,2,3]`——数组也能 `.iter()`、也能比较，本教程零警告纪律照办。
6. **`get(0)` 被 clippy 提醒改 `first()`**：语义同，可读性高。
7. **容量预分配**：知道规模时 `Vec::with_capacity(n)` / `HashMap::with_capacity(n)`，省掉反复扩容拷贝（默认翻倍增长）。
8. **remove(i) 返回元素而不是 bool**：拿走值；"删存在与否"用 `if i < v.len()` 先判或换数据结构。

---

上一章：[08 枚举与模式匹配](08-enums.md) · 下一章：[10 错误处理](10-errors.md)
