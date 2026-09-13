fn main() {
    let n = 7;
    if n < 0 {
        println!("negative");
    } else if n == 0 {
        println!("zero");
    } else {
        println!("positive");
    }

    let mut sum = 0;
    for i in 1..=5 {
        sum += i;
    }
    println!("sum={}", sum);

    let mut k = 0;
    while k < 3 {
        k += 1;
    }
    println!("k={}", k);

    let mut c = 0;
    loop {
        c += 1;
        if c == 2 {
            break;
        }
    }
    println!("loop_count={}", c);
}

