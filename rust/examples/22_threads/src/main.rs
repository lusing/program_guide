//! 22 · 并发 ⭐：spawn/join、scoped threads、mpsc、Mutex/RwLock、原子、Send/Sync
//!
//! Rust 的承诺：数据竞争（data race）在安全代码里不可能发生——
//! 两个线程同时访问同一内存、至少一个是写、无同步——这个组合
//! 在编译期就被 Send/Sync 检查挡下。要么 &（共享只读），要么 &mut（独占），
//! 跨线程也一样。

use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc;
use std::sync::{Arc, Mutex, RwLock};
use std::thread;
use std::time::Duration;

fn main() {
    // ============ spawn + join：线程的生与死 ============
    let data = vec![1, 2, 3];
    let handle = thread::spawn(move || {
        // move 必不可少：闭包必须拥有 data（线程活得比当前栈帧久，不能借用局部）
        println!("工作线程拿到 {data:?}");
        data.iter().sum::<i32>()
    });
    let sum = handle.join().unwrap(); // join 等待 + 取回返回值
    println!("join 拿到结果：{sum}");
    // join 返回 Result：线程 panic 时这里拿到 Err（panic 不会静默丢失）

    // 命名线程（调试器/日志里可读）
    let named = thread::Builder::new()
        .name("统计线程".into())
        .spawn(|| (1..=100).sum::<i64>())
        .unwrap();
    println!("命名线程结果：{}", named.join().unwrap());

    // ============ scoped threads（1.63+）：借用局部变量，无需 Arc ============
    let mut scores = vec![0i32; 4];
    thread::scope(|s| {
        // scope 保证所有子线程在闭包结束前 join，
        // 因此子线程可以安全借用 &、&mut —— 这是现代 Rust 的首选写法
        for (i, slot) in scores.iter_mut().enumerate() {
            s.spawn(move || {
                *slot = (i as i32 + 1) * 10;
            });
        }
    }); // ← 这里自动 join
    println!("scoped 写回：{scores:?}");

    // ============ mpsc：多生产者单消费者通道 ============
    let (tx, rx) = mpsc::channel();
    for i in 0..3 {
        let tx = tx.clone(); // 每个生产者一个克隆句柄
        thread::spawn(move || {
            tx.send(format!("来自生产线程 {i} 的消息")).unwrap();
        });
    }
    drop(tx); // 主线程的句柄弃权
    for msg in rx {
        // 所有 sender drop 后，rx 迭代自然结束（不会死等）
        println!("  收到：{msg}");
    }

    // ============ Arc<Mutex<T>>：共享可变状态 ============
    let counter = Arc::new(Mutex::new(0u64));
    let mut handles = vec![];
    for _ in 0..4 {
        let c = Arc::clone(&counter); // 引用计数 +1，不是复制数据
        handles.push(thread::spawn(move || {
            let mut guard = c.lock().unwrap(); // 拿锁；unwrap 处理"毒锁"（见下）
            *guard += 1;
        })); // guard 在此 drop → 锁释放（RAII，永不忘记 unlock）
    }
    for h in handles {
        h.join().unwrap();
    }
    println!("4 线程各 +1 后：{}", *counter.lock().unwrap());

    // ============ 锁中毒（poisoning）：持锁线程 panic 后的防线 ============
    let lock = Arc::new(Mutex::new(vec![1]));
    let l2 = Arc::clone(&lock);
    let _ = thread::spawn(move || {
        let mut g = l2.lock().unwrap();
        g.push(2);
        panic!("持锁崩溃"); // guard 随栈展开被释放，锁标记为"有毒"
    })
    .join(); // Err 被有意忽略
    let poisoned = lock.is_poisoned();
    let data = lock.lock().unwrap_or_else(|e| e.into_inner()); // 常用恢复手法
    println!("锁中毒 = {poisoned}，数据 {data:?}（互斥量保证没有半写状态）");

    // ============ RwLock：读多写少 ============
    let cfg = RwLock::new(String::from("verbose=true"));
    {
        let r1 = cfg.read().unwrap();
        let r2 = cfg.read().unwrap(); // 多个读锁可共存
        println!("并发读：{r1} / {r2}");
    } // 读锁释放后才能拿写锁
    {
        let mut w = cfg.write().unwrap();
        w.push_str(", level=debug");
    }
    println!("写后：{}", cfg.read().unwrap());

    // ============ 原子类型：无锁计数 ============
    let hits = Arc::new(AtomicUsize::new(0));
    let mut hs = vec![];
    for _ in 0..4 {
        let h = Arc::clone(&hits);
        hs.push(thread::spawn(move || {
            for _ in 0..1000 {
                h.fetch_add(1, Ordering::Relaxed); // 原子自增，不需要 Mutex
            }
        }));
    }
    for h in hs {
        h.join().unwrap();
    }
    println!("原子计数：{}", hits.load(Ordering::Relaxed)); // 恒为 4000

    // ============ Send / Sync：自动判定的两协议 ============
    // Send：类型的值可以移交给另一个线程（所有权搬家）
    // Sync：&T 可以安全地跨线程共享（等价 T: Send + 可共享引用）
    // Rc<i32> 两者皆非（计数非原子）→ 编译错：cannot send Rc between threads
    // Arc<i32> Send+Sync；RefCell 非 Sync（借用计数非原子）→ Arc<RefCell<T>> 不 Sync
    // Mutex<T> 让 T 的可变性跨线程安全 → Arc<Mutex<T>> 是标准共享可变姿势
    fn assert_sync<T: Sync>() {}
    assert_sync::<Mutex<i32>>();
    assert_sync::<AtomicUsize>();
    fn assert_send<T: Send>() {}
    assert_send::<thread::JoinHandle<i32>>();

    // ============ 计时 ============
    thread::sleep(Duration::from_millis(5));
    println!("主线程收工");
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::mpsc;

    #[test]
    fn spawn_returns_value_via_join() {
        let h = thread::spawn(move || 6 * 7);
        assert_eq!(h.join().unwrap(), 42);
    }

    #[test]
    fn panic_crosses_join_as_error() {
        let h = thread::spawn(|| panic!("爆炸"));
        assert!(h.join().is_err()); // panic 化为 JoinError，不会传染本测试
    }

    #[test]
    fn scoped_threads_share_locals() {
        let mut buf = vec![0u8; 8];
        thread::scope(|s| {
            for (i, slot) in buf.iter_mut().enumerate() {
                s.spawn(move || *slot = i as u8);
            }
        });
        assert_eq!(buf, vec![0, 1, 2, 3, 4, 5, 6, 7]);
    }

    #[test]
    fn channel_transfer() {
        let (tx, rx) = mpsc::channel();
        thread::spawn(move || {
            for i in 0..5 {
                tx.send(i * i).unwrap();
            }
        }); // tx 随线程结束 drop → rx 迭代终止
        let got: Vec<i32> = rx.iter().collect();
        assert_eq!(got, vec![0, 1, 4, 9, 16]);
    }

    #[test]
    fn arc_mutex_counter_is_exact() {
        let c = Arc::new(Mutex::new(0));
        thread::scope(|s| {
            for _ in 0..8 {
                let c = &c;
                s.spawn(move || {
                    *c.lock().unwrap() += 1;
                });
            }
        });
        assert_eq!(*c.lock().unwrap(), 8);
    }

    #[test]
    fn atomics_add_up() {
        let n = Arc::new(AtomicUsize::new(0));
        thread::scope(|s| {
            for _ in 0..4 {
                let n = &n;
                s.spawn(move || {
                    for _ in 0..1000 {
                        n.fetch_add(1, Ordering::Relaxed);
                    }
                });
            }
        });
        assert_eq!(n.load(Ordering::Relaxed), 4000);
    }

    #[test]
    fn rwlock_allows_concurrent_reads() {
        let lock = RwLock::new(10);
        let (a, b) = {
            let r1 = lock.read().unwrap();
            let r2 = lock.read().unwrap();
            (*r1, *r2)
        };
        assert_eq!(a + b, 20);
    }
}
