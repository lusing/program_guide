fn length(s: &str) -> usize {
    s.len()
}

fn append_exclamation(s: &mut String) {
    s.push('!');
}

fn main() {
    let a = String::from("hello");
    let b = a.clone();
    println!("a={}, b={}", a, b);
    println!("len={}", length(&a));

    let mut msg = String::from("rust");
    append_exclamation(&mut msg);
    println!("msg={}", msg);
}

