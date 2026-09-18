//! 23 · async/await ⭐：async fn、Future、join/select、spawn、异步 IO 与通道
//!
//! 心智模型：
//! - async fn 是"生成 Future 的函数"，调用它什么都不做，await 才驱动
//! - await 点 = "此处可能让出线程，调度器去跑别的任务"
//! - 并发≠并行：单线程运行时也能万级并发；并行靠多线程调度器
//! - std 只定义 Future 协议，运行时（调度/定时器/IO）来自 tokio 等库

use std::time::Duration;
use tokio::time::{sleep, timeout};

/// 模拟一次网络请求：异步等待 ms 毫秒后返回字符串
async fn fetch(name: &str, ms: u64) -> String {
    sleep(Duration::from_millis(ms)).await; // 异步等待：让出线程，不阻塞
    format!("[{name} 完成，耗时 {ms}ms]")
}

#[tokio::main] // 展开成一个多线程运行时 + main 的异步入口
async fn main() {
    // ============ 顺序 await：总耗时 = 各步之和 ============
    let start = std::time::Instant::now();
    let a = fetch("A", 30).await;
    let b = fetch("B", 30).await;
    let seq = start.elapsed();
    println!("{a} {b}（顺序，{seq:?}）");

    // ============ join!：并发跑齐一批（总耗时 ≈ 最慢者）============
    let start = std::time::Instant::now();
    let (x, y, z) = tokio::join!(fetch("X", 40), fetch("Y", 20), fetch("Z", 30));
    let par = start.elapsed();
    println!("{x} {y} {z}（并发，{par:?}）");

    // ============ try_join!：全部成功才算成功（配 Result 的异步）============
    let results = tokio::join!(async { Ok::<_, String>(1) }, async {
        Err::<i32, String>("失败演示".into())
    });
    println!("join 的 Result：{results:?}");

    // ============ spawn：托管任务（丢进调度器，可并行）============
    let handle = tokio::spawn(fetch("后台任务", 10));
    let extra = tokio::spawn(async {
        let a = fetch("链式-1", 10).await;
        let b = fetch("链式-2", 10).await;
        format!("{a} → {b}")
    });
    let bg = handle.await.unwrap(); // JoinHandle 也 await；panic 在这里变 Err
    let chained = extra.await.unwrap();
    println!("{bg}；{chained}");

    // ============ select!：多个等一个（谁先完成用谁，其余取消）============
    let winner = tokio::select! {
        r = fetch("快请求", 5) => r,
        r = fetch("慢请求", 100) => format!("（被舍弃）{r}"),
    };
    println!("select 赢家：{winner}");

    // ============ timeout：给 await 加截止时间 ============
    let maybe = timeout(Duration::from_millis(10), fetch("必超时", 500)).await;
    println!("timeout 结果：{maybe:?}（is_err={}）", maybe.is_err());

    // ============ 异步通道：tokio::sync::mpsc（.send().await 可背压）============
    let (tx, mut rx) = tokio::sync::mpsc::channel::<u32>(8); // 缓冲 8
    let producer = tokio::spawn(async move {
        for i in 1..=5 {
            tx.send(i).await.unwrap(); // 缓冲满则让出（背压）
        }
    }); // tx 随任务结束 drop → rx 收到结束信号
    let mut collected = vec![];
    while let Some(i) = rx.recv().await {
        collected.push(i);
    }
    producer.await.unwrap();
    println!("异步通道收齐：{collected:?}");

    // ============ 异步文件 IO（tokio::fs，线程池上的封装）============
    let dir = std::env::temp_dir().join("guide_async_demo");
    tokio::fs::create_dir_all(&dir).await.unwrap();
    let path = dir.join("note.txt");
    tokio::fs::write(&path, "异步写入的内容").await.unwrap();
    let text = tokio::fs::read_to_string(&path).await.unwrap();
    println!("异步读回：{text:?}");
    tokio::fs::remove_dir_all(&dir).await.unwrap();

    // ============ CPU 密集 ≠ async：阻塞会卡死 worker ============
    // async 块里做重计算/调用阻塞库（std::thread::sleep、阻塞 IO）会占住
    // worker 线程。两种出路：
    //   tokio::task::spawn_blocking(move || 重计算());   // 丢阻塞线程池
    //   独立 std::thread（22 章）                         // 完全绕开运行时
    let heavy = tokio::task::spawn_blocking(|| (1..=1000).sum::<u64>());
    println!("spawn_blocking 结果：{}", heavy.await.unwrap());

    // ============ 协议速记 ============
    // async fn f() -> T        ≡  fn f() -> impl Future<Output = T>
    // Future 是惰性的：不 await / 不 spawn 就不会执行（与 JS Promise 不同）
    // Send 约束：多线程调度器要求跨 await 持有的变量是 Send
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test] // 单线程运行时的测试入口
    async fn await_drives_future() {
        let v = fetch("t", 1).await;
        assert!(v.contains("t"));
    }

    #[tokio::test]
    async fn join_is_concurrent() {
        let start = std::time::Instant::now();
        let (a, b) = tokio::join!(fetch("a", 40), fetch("b", 40));
        assert!(a.contains("a") && b.contains("b"));
        // 并发总耗时应接近单任务时长，而不是两倍
        assert!(start.elapsed() < Duration::from_millis(75));
    }

    #[tokio::test]
    async fn select_takes_fastest() {
        let out = tokio::select! {
            r = fetch("fast", 1) => r,
            _ = fetch("slow", 1_000) => "slow".to_string(),
        };
        assert!(out.contains("fast"));
    }

    #[tokio::test]
    async fn timeout_errs_on_deadline() {
        let r = timeout(Duration::from_millis(5), sleep(Duration::from_secs(1))).await;
        assert!(r.is_err()); // Err(Elapsed)
    }

    #[tokio::test]
    async fn channel_backpressure_works() {
        let (tx, mut rx) = tokio::sync::mpsc::channel(2);
        tokio::spawn(async move {
            for i in 0..4 {
                tx.send(i).await.unwrap();
            }
        });
        let mut seen = vec![];
        while let Some(v) = rx.recv().await {
            seen.push(v);
        }
        assert_eq!(seen, vec![0, 1, 2, 3]);
    }

    #[tokio::test]
    async fn spawn_join_handle() {
        let h = tokio::spawn(async { 21 * 2 });
        assert_eq!(h.await.unwrap(), 42);
    }
}
