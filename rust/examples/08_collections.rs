use std::collections::{BTreeSet, HashMap};

fn main() {
    let mut nums = vec![1, 2, 3];
    nums.push(4);
    let doubled: Vec<i32> = nums.iter().map(|v| v * 2).collect();
    println!("doubled={:?}", doubled);

    let mut scores = HashMap::new();
    scores.insert("alice", 95);
    scores.insert("bob", 88);
    println!("alice={}", scores.get("alice").copied().unwrap_or_default());

    let mut set = BTreeSet::new();
    set.insert("pear");
    set.insert("apple");
    set.insert("banana");
    println!("set={:?}", set);
}

