//! 25 · 系统标准库：std::time / std::env / std::process / std::net
//!
//! 这一章把"和操作系统打交道"的四个 std 模块一次讲透：
//! 计时（time）、环境变量与命令行参数（env）、启动子进程（process）、
//! TCP/UDP 网络（net）。全部示例跨平台（macOS / Linux / Windows）：
//! 网络一律绑 127.0.0.1 + 端口 0（让操作系统分配空闲端口），
//! 子进程一律启动"自己"并加 --child 标志位区分父子，避免依赖平台相关命令名。

use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream, UdpSocket};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

/// 子进程模式：被父进程用 `--child` 启动时走这里，打印一行标记就退出。
/// 父进程靠捕获这行 stdout 验证"确实启动并跑到了业务代码"。
fn child_mode() {
    println!("child-stdout-marker");
}

/// std::time：三种时间概念——时长、单调时钟、墙上时钟。
fn demo_time() {
    // Instant 是单调时钟：只增不减，专门用来测量"经过了多久"。
    // black_box 阻止编译器把整个循环优化掉，让计时有意义。
    let start = Instant::now();
    let mut sum = 0u64;
    for i in 0..100_000u64 {
        sum = std::hint::black_box(sum).wrapping_add(i);
    }
    let elapsed: Duration = start.elapsed();
    let nanos = elapsed.as_nanos();
    println!("计算 sum={sum} 耗时 {nanos} 纳秒");
    assert!(elapsed < Duration::from_secs(10));

    // Duration 是"一段时间长度"，与具体时刻无关，可做算术、可拆秒/纳秒。
    let d = Duration::from_millis(1500);
    let secs = d.as_secs();
    let subsec = d.subsec_nanos();
    println!("1500ms = {secs} 秒 + {subsec} 纳秒");
    assert_eq!((secs, subsec), (1, 500_000_000));

    // SystemTime 是墙上时钟：可能被 NTP 回拨，所以 duration_since 返回 Result。
    let since_epoch = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("系统时间早于 Unix 纪元");
    let ts = since_epoch.as_secs();
    println!("Unix 时间戳：{ts} 秒");
    assert!(ts > 1_700_000_000); // 2023-11 之后，验证拿到的是真实时间
}

/// std::env：命令行参数、环境变量、临时目录、当前目录。
fn demo_env() {
    let args: Vec<String> = std::env::args().collect();
    let argc = args.len();
    println!("命令行参数个数：{argc}");

    // var 返回 Result：变量可能不存在，也可能含非法 Unicode（OsString 转 String 失败）。
    match std::env::var("PATH") {
        Ok(path) => {
            let len = path.len();
            println!("PATH 长度：{len} 字节");
        }
        Err(e) => println!("读 PATH 失败：{e}"),
    }

    // 不存在的变量 → Err(VarError::NotPresent)，这是"查不到"的正常信号，不是崩溃。
    let missing = std::env::var("GUIDE_DEFINITELY_NOT_SET");
    assert!(missing.is_err());
    println!("不存在的变量：{:?}", missing.unwrap_err());

    // temp_dir 跨平台（Windows %TEMP%、macOS/Linux /tmp 系）；current_dir 是进程工作目录。
    println!("临时目录：{}", std::env::temp_dir().display());
    println!("当前目录：{}", std::env::current_dir().unwrap().display());
}

/// std::process：启动子进程、捕获 stdout/stderr、读退出码。
fn demo_process() {
    // 跨平台启动子进程最稳妥的方式：启动"自己"，用标志位区分父子。
    // 不依赖 echo/ls 这类命令名——Windows 上 echo 是 shell 内建而非可执行文件，
    // Command::new("echo") 在 Windows 会直接失败。current_exe 则三平台一致。
    let exe = std::env::current_exe().expect("拿不到当前可执行文件路径");
    let output = std::process::Command::new(exe)
        .arg("--child")
        .output() // output() 等待子进程结束并一次性收回 stdout/stderr/status
        .expect("启动子进程失败");

    assert!(output.status.success(), "子进程应成功退出");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("child-stdout-marker"));
    let trimmed = stdout.trim();
    let code = output.status.code(); // Option<i32>：被信号杀死时是 None
    println!("子进程 stdout={trimmed:?}，退出码={code:?}");
}

/// std::net：TCP 回显服务器 + 客户端，以及 UDP 互发。
fn demo_net() {
    // ---- TCP：面向连接的字节流 ----
    // 绑端口 0 让操作系统分配一个空闲端口，避免与别的进程撞端口（测试可靠性的关键）。
    let listener = TcpListener::bind("127.0.0.1:0").expect("绑定 TCP 失败");
    let addr = listener.local_addr().unwrap();

    // 服务器放进独立线程：accept 是阻塞的，不能和客户端在同一线程顺序跑。
    let server = std::thread::spawn(move || {
        let (mut stream, _peer) = listener.accept().expect("accept 失败");
        let mut buf = [0u8; 5];
        stream.read_exact(&mut buf).expect("服务器读失败");
        stream.write_all(&buf).expect("服务器写失败"); // 原样回显
    });

    let mut client = TcpStream::connect(addr).expect("连接失败");
    client.write_all(b"hello").expect("客户端写失败");
    let mut echo = [0u8; 5];
    client.read_exact(&mut echo).expect("客户端读失败");
    server.join().expect("服务器线程 panic");

    assert_eq!(echo, *b"hello");
    println!("TCP 回显：{:?}", String::from_utf8_lossy(&echo));

    // ---- UDP：无连接数据报，两个 socket 互发 ----
    let a = UdpSocket::bind("127.0.0.1:0").expect("绑定 UDP a 失败");
    let b = UdpSocket::bind("127.0.0.1:0").expect("绑定 UDP b 失败");
    // connect 对 UDP 只是"记住默认对端地址"，不建立连接；之后 send/recv 都走这个对端。
    a.connect(b.local_addr().unwrap()).expect("connect a 失败");
    b.connect(a.local_addr().unwrap()).expect("connect b 失败");
    a.send(b"ping").expect("UDP 发送失败");
    let mut buf = [0u8; 4];
    let n = b.recv(&mut buf).expect("UDP 接收失败");
    assert_eq!(n, 4);
    assert_eq!(buf, *b"ping");
    println!("UDP 收发：{:?}", String::from_utf8_lossy(&buf[..n]));
}

fn main() {
    // 子进程入口：父进程用 --child 启动我们时，只打印标记就退出，不再跑演示。
    let args: Vec<String> = std::env::args().collect();
    if args.iter().any(|a| a == "--child") {
        child_mode();
        return;
    }

    println!("==== std::time ====");
    demo_time();
    println!("==== std::env ====");
    demo_env();
    println!("==== std::process ====");
    demo_process();
    println!("==== std::net ====");
    demo_net();
    println!("全部演示完成。");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn time_demo_runs() {
        demo_time();
    }

    #[test]
    fn net_demo_roundtrips() {
        // TCP/UDP 回环往返：绑 127.0.0.1:0，不依赖外部网络，稳定可重复。
        demo_net();
    }

    #[test]
    fn duration_splits_correctly() {
        let d = Duration::from_secs_f64(2.5);
        assert_eq!(d.as_secs(), 2);
        assert_eq!(d.subsec_millis(), 500);
    }

    #[test]
    fn env_missing_var_is_err() {
        assert!(std::env::var("GUIDE_DEFINITELY_NOT_SET").is_err());
    }

    // 注意：demo_process 不在测试里跑——cargo test 时 current_exe 是测试二进制，
    // 它会把 --child 当成 libtest 的未知参数而报错。进程演示只在 cargo run 时执行。
}
