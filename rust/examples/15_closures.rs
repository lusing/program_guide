fn apply_twice<F>(x: i32, f: F) -> i32
where
    F: Fn(i32) -> i32,
{
    f(f(x))
}

fn main() {
    let factor = 3;
    let mul = |x: i32| x * factor;
    println!("apply_twice={}", apply_twice(2, mul));

    let mut values = vec![3, 1, 2];
    values.sort_by_key(|v| *v);
    println!("sorted={:?}", values);
}

