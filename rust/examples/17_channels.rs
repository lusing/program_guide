use std::sync::mpsc;
use std::thread;

fn main() {
    let (tx, rx) = mpsc::channel::<String>();
    let tx2 = tx.clone();

    let h1 = thread::spawn(move || {
        tx.send("from worker-1".to_string())
            .expect("send failed for worker-1");
    });
    let h2 = thread::spawn(move || {
        tx2.send("from worker-2".to_string())
            .expect("send failed for worker-2");
    });

    h1.join().expect("thread join failed");
    h2.join().expect("thread join failed");

    let mut received = vec![rx.recv().expect("recv failed"), rx.recv().expect("recv failed")];
    received.sort();
    println!("received={:?}", received);
}

