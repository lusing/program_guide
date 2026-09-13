fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn stats(values: &[i32]) -> (i32, i32) {
    let min = *values.iter().min().unwrap_or(&0);
    let max = *values.iter().max().unwrap_or(&0);
    (min, max)
}

fn main() {
    println!("add={}", add(3, 4));
    let (min, max) = stats(&[8, 1, 6, 3]);
    println!("min={}, max={}", min, max);
}

