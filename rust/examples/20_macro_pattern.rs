macro_rules! sum {
    ($($x:expr),* $(,)?) => {{
        let mut total = 0;
        $(total += $x;)*
        total
    }};
}

fn classify(n: i32) -> &'static str {
    match n {
        x if x < 0 => "negative",
        0 => "zero",
        1..=9 => "small",
        _ => "large",
    }
}

fn main() {
    println!("sum={}", sum!(1, 2, 3, 4));
    println!("classify(-2)={}", classify(-2));
    println!("classify(0)={}", classify(0));
    println!("classify(7)={}", classify(7));
    println!("classify(20)={}", classify(20));
}

