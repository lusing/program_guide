fn main() {
    let mut s = String::from("hello");
    s.push_str(", Rust");
    println!("s={}", s);
    println!("bytes_len={}", s.len());

    let chars: Vec<char> = s.chars().collect();
    println!("chars={:?}", chars);

    let first_three_bytes: Vec<u8> = s.bytes().take(3).collect();
    println!("first_three_bytes={:?}", first_three_bytes);
}
