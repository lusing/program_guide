use std::num::ParseIntError;

fn parse_positive(input: &str) -> Result<u32, ParseIntError> {
    input.parse::<u32>()
}

fn first_word_len(text: &str) -> Option<usize> {
    text.split_whitespace().next().map(str::len)
}

fn main() {
    match parse_positive("123") {
        Ok(v) => println!("ok={}", v),
        Err(e) => println!("err={}", e),
    }

    match parse_positive("abc") {
        Ok(v) => println!("ok={}", v),
        Err(e) => println!("err={}", e),
    }

    println!("first_word_len={:?}", first_word_len("rust language"));
}

