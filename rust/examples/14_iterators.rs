fn main() {
    let nums = [1, 2, 3, 4, 5, 6];
    let evens_squared: Vec<i32> = nums
        .iter()
        .copied()
        .filter(|n| n % 2 == 0)
        .map(|n| n * n)
        .collect();
    let total = evens_squared.iter().fold(0, |acc, v| acc + v);

    println!("evens_squared={:?}", evens_squared);
    println!("total={}", total);
}

