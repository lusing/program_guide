fn main() {
    let x: i32 = 42;
    let mut y = 3.5_f64;
    y += 1.0;
    let active = true;
    let label = "typed variables";
    let tuple = (x, y, active);
    let arr = [1, 2, 3, 4];

    println!("x={}", x);
    println!("y={}", y);
    println!("active={}", active);
    println!("label={}", label);
    println!("tuple.0={}, arr_len={}", tuple.0, arr.len());
}

