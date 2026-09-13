trait Summary {
    fn summary(&self) -> String;
}

struct Article {
    title: String,
    views: u32,
}

impl Summary for Article {
    fn summary(&self) -> String {
        format!("{} ({})", self.title, self.views)
    }
}

fn largest<T: Ord + Copy>(list: &[T]) -> Option<T> {
    list.iter().copied().max()
}

fn print_summary(item: &impl Summary) {
    println!("{}", item.summary());
}

fn main() {
    let nums = [9, 1, 7, 12, 3];
    println!("largest={:?}", largest(&nums));

    let article = Article {
        title: "Rust Guide".to_string(),
        views: 1024,
    };
    print_summary(&article);
}

