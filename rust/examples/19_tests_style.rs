fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn is_even(n: i32) -> bool {
    n % 2 == 0
}

fn main() {
    println!("add_2_3={}", add(2, 3));
    println!("is_even_10={}", is_even(10));
}

#[cfg(test)]
mod tests {
    use super::{add, is_even};

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_even() {
        assert!(is_even(8));
        assert!(!is_even(9));
    }
}

