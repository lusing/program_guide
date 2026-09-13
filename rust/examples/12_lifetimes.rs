fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() {
        a
    } else {
        b
    }
}

fn main() {
    let s1 = String::from("short");
    let s2 = String::from("much longer text");
    let result = longest(&s1, &s2);
    println!("longest={}", result);
}

