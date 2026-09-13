mod math {
    pub fn add(a: i32, b: i32) -> i32 {
        a + b
    }

    pub mod stats {
        pub fn mean(values: &[i32]) -> f64 {
            if values.is_empty() {
                return 0.0;
            }
            let sum: i32 = values.iter().sum();
            sum as f64 / values.len() as f64
        }
    }
}

use math::stats::mean;

fn main() {
    println!("add={}", math::add(5, 7));
    println!("mean={}", mean(&[2, 4, 6, 8]));
}

