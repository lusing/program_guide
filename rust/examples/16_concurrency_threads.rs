use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0_i32));
    let mut handles = Vec::new();

    for _ in 0..4 {
        let shared = Arc::clone(&counter);
        handles.push(thread::spawn(move || {
            for _ in 0..5 {
                let mut guard = shared.lock().expect("lock failed");
                *guard += 1;
            }
        }));
    }

    for h in handles {
        h.join().expect("thread join failed");
    }

    let result = *counter.lock().expect("lock failed");
    println!("counter={}", result);
}

