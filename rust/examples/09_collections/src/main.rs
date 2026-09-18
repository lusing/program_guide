//! 09 · 集合：Vec、HashMap（entry 惯用法）、BTreeMap、VecDeque、HashSet

use std::collections::{BTreeMap, HashMap, HashSet, VecDeque};

#[allow(clippy::vec_init_then_push)] // 教学演示：先看 Vec::new()，再对比 vec![] 宏
fn main() {
    // ================= Vec =================
    let mut v: Vec<i32> = Vec::new();
    v.push(1);
    v.push(2);
    let from_macro = vec![0; 4]; // vec![初值; 长度]
    let init = vec![10, 20, 30];
    println!("v={v:?} macro={from_macro:?} init={init:?}");

    // 读取：索引（越界 panic）vs get（返回 Option）
    let third = init[2];
    let maybe = init.get(10);
    println!("init[2] = {third}，get(10) = {maybe:?}");

    // 遍历三种形态（15 章细讲迭代器）
    for x in &init {
        print!("{x} "); // 共享引用：只读
    }
    println!();
    let mut nums = vec![3, 1, 2];
    for x in &mut nums {
        *x *= 10; // 可变引用：就地改
    }
    println!("就地翻倍：{nums:?}");

    // 增删
    nums.insert(1, 99);
    let popped = nums.pop();
    let removed = nums.remove(0); // O(n)：后面元素前移
    println!("insert/pop/remove 之后 {nums:?}（pop={popped:?} remove={removed}）");
    nums.sort();
    nums.dedup(); // 只去"相邻"重复——先排序才彻底
    println!("排序去重后 {nums:?}");

    // ================= HashMap =================
    let text = "go rust go zig rust go";
    let mut freq: HashMap<&str, u32> = HashMap::new();
    // 惯用法：entry().or_insert(0) —— 没有就插入 0，返回值的可变引用
    for w in text.split_whitespace() {
        *freq.entry(w).or_insert(0) += 1;
    }
    println!("词频：{freq:?}");

    // get 返回 Option<&V>
    if let Some(n) = freq.get("go") {
        println!("go 出现 {n} 次");
    }
    // remove 返回 Option<V>
    println!("删除 zig：{:?}", freq.remove("zig"));
    println!("删除不存在：{:?}", freq.remove("java"));

    // 键需要 Eq + Hash；拥有所有权的键进表后不可再改（影响哈希）
    let mut owner: HashMap<String, i32> = HashMap::new();
    let key = String::from("键");
    owner.insert(key, 1); // key 被 move 进 map
    // println!("{key}"); // ← 编译错：key 已不属于你
    println!("owner = {owner:?}");

    // ================= BTreeMap：有序遍历 =================
    let mut bt: BTreeMap<i32, &str> = BTreeMap::new();
    bt.insert(3, "c");
    bt.insert(1, "a");
    bt.insert(2, "b");
    // 插入顺序 3,1,2 —— 遍历按键排序 1,2,3（HashMap 遍历顺序随机！）
    for (k, val) in &bt {
        print!("{k}={val} ");
    }
    println!();

    // ================= HashSet =================
    let a: HashSet<i32> = [1, 2, 3].into();
    let b: HashSet<i32> = [2, 3, 4].into();
    // 集合运算返回迭代器（15 章）
    let inter: Vec<i32> = a.intersection(&b).copied().collect();
    let union: Vec<i32> = a.union(&b).copied().collect();
    let diff: Vec<i32> = a.difference(&b).copied().collect();
    println!("交 {inter:?} 并 {union:?} 差 {diff:?}");

    // ================= VecDeque：双端队列 =================
    let mut dq: VecDeque<&str> = VecDeque::new();
    dq.push_back("尾");
    dq.push_front("头");
    dq.push_back("又尾");
    println!(
        "队列 {dq:?} 弹头 {:?} 弹尾 {:?}",
        dq.pop_front(),
        dq.pop_back()
    );

    // ============ 用 collect 在集合间转换（迭代器 15 章）============
    let words = "apple banana apple cherry banana apple";
    let counts: BTreeMap<&str, usize> =
        words.split_whitespace().fold(BTreeMap::new(), |mut m, w| {
            *m.entry(w).or_insert(0) += 1;
            m
        });
    println!("统计（有序）：{counts:?}");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn vec_index_vs_get() {
        let v = [1, 2, 3]; // 数组直接就能演示（vec! 对定长数据是多余的，clippy 会提醒）
        assert_eq!(v[0], 1);
        assert_eq!(v.first(), Some(&1)); // 首元素惯用 first()（get(0) 会被 clippy 提醒）
        assert_eq!(v.get(99), None);
        // v[99]; // ← panic: index out of bounds
    }

    #[test]
    fn entry_idiom_counts() {
        let mut m: HashMap<&str, u32> = HashMap::new();
        for w in "a b a c a".split_whitespace() {
            *m.entry(w).or_insert(0) += 1;
        }
        assert_eq!(m["a"], 3);
        assert_eq!(m["b"], 1);
    }

    #[test]
    fn hashmap_moves_keys() {
        let mut m = HashMap::new();
        let k = String::from("k");
        m.insert(k, 9);
        assert_eq!(m.get("k"), Some(&9)); // 用字面量查：&str 能哈希即可
    }

    #[test]
    fn btreemap_is_sorted() {
        let mut m = BTreeMap::new();
        for k in [5, 1, 3] {
            m.insert(k, k * 10);
        }
        let keys: Vec<i32> = m.keys().copied().collect();
        assert_eq!(keys, vec![1, 3, 5]);
    }

    #[test]
    fn set_operations() {
        let a: HashSet<i32> = [1, 2, 3].into();
        let b: HashSet<i32> = [2, 3, 4].into();
        // HashSet 迭代顺序不定（哈希随机化），比较前先排序
        let mut inter: Vec<i32> = a.intersection(&b).copied().collect();
        inter.sort_unstable();
        assert_eq!(inter, vec![2, 3]);
        assert_eq!(a.union(&b).count(), 4);
        let mut diff: Vec<i32> = a.difference(&b).copied().collect();
        diff.sort_unstable();
        assert_eq!(diff, vec![1]);
    }

    #[test]
    fn vecdeque_both_ends() {
        let mut q: VecDeque<i32> = VecDeque::new();
        q.push_back(2);
        q.push_front(1);
        assert_eq!(q.front(), Some(&1));
        assert_eq!(q.pop_front(), Some(1));
        assert_eq!(q, [2]); // VecDeque 与数组可以直接比较（PartialEq 实现到位）
    }

    #[test]
    fn dedup_needs_sort_first() {
        let mut v = vec![1, 1, 2, 1, 3, 2];
        v.sort_unstable();
        v.dedup();
        assert_eq!(v, vec![1, 2, 3]);
    }
}
