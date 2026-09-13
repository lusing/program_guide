enum Status {
    Ok(u32),
    NotFound,
    Forbidden(String),
}

fn describe(status: &Status) -> String {
    match status {
        Status::Ok(code) => format!("ok {}", code),
        Status::NotFound => "not found".to_string(),
        Status::Forbidden(reason) => format!("forbidden: {}", reason),
    }
}

fn main() {
    let items = vec![
        Status::Ok(200),
        Status::NotFound,
        Status::Forbidden("token expired".to_string()),
    ];

    for item in &items {
        println!("{}", describe(item));
    }

    if let Status::Ok(code) = &items[0] {
        println!("first_code={}", code);
    }
}

