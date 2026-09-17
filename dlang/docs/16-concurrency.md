# 16 · 并发 I：消息传递

> 对应示例：`examples/16_concurrency/`

## 16.1 D 的并发哲学

> **数据属于线程；线程间靠消息。**

类型系统站在哲学这边：可变数据**默认不能**跨线程——编译期就拒绝共享，数据竞争在 D 里是编译错误（大多数时候）。

```d
import std.concurrency;

void worker(Tid owner) {                  // Tid：线程地址（spawn 时传入）
    bool running = true;
    while (running) {
        receive(
            (Work w)      { owner.send(Result(w.id, calc(w))); },  // 按类型分支
            (string cmd)  { if (cmd == "quit") running = false; },
        );
    }
}

auto wid = spawn(&worker, thisTid);       // 起线程；thisTid = 自己的地址
wid.send(Work(1, "hello"));               // 寄消息（异步，立即返回）
auto r = receiveOnly!Result;              // 收指定类型（阻塞）
```

## 16.2 消息类型即协议

```d
struct Work   { int id; string payload; }   // 值类型消息：拷贝传输
struct Result { int id; long checksum; }
```

- `receive(类型1处理器, 类型2处理器, ...)`：一条通道混传多种类型。
- `receiveOnly!T`：只收 T，类型不符抛 `MessageMismatch`。
- 能发的东西：**值拷贝 / immutable / shared**——其他一律编译错。

## 16.3 immutable：自由通行证

```d
void strictWorker(Tid owner) {
    auto msg = receiveOnly!(immutable(int)[]);     // 注意形状！
    owner.send(msg.sum);
}

auto tid = spawn(&strictWorker, thisTid);
tid.send(cast(immutable int[])[1, 2, 3, 4]);       // 尾不可变：随便发
```

## 16.4 限时与退避

```d
string lateMsg;
auto got = receiveTimeout(50.msecs, (string s) { lateMsg = s; });   // 返回 bool
```

`receiveTimeout` 返回"是否收到"（bool），消息内容在 handler 里接——它不是"带超时的 receiveOnly"。

## 16.5 类型系统挡竞争

```d
int secret = 42;
spawn((Tid owner) { owner.send(secret); }, thisTid);
// 编译错：局部变量被闭包捕获 → "may not be shared"
```

想共享可变状态必须显式 `shared`——而 `shared` 变量的操作又要求原子/锁（17 章），一路把你逼向消息传递。

## 16.6 模型对照

| | D std.concurrency | Go | Erlang |
|---|---|---|---|
| 单位 | spawn 线程（OS 线程） | goroutine（绿色） | 进程 |
| 通信 | Tid + 类型化消息 | channel | 信箱 |
| 共享检查 | 类型系统编译期 | 运行期 race detector | 无共享 |

D 线程是 OS 线程（默认无 M:N 调度）——几千个轻任务请用 17 章的 taskPool，不要 spawn 几千个。

## 16.7 坑位清单

1. **`cast(immutable int[])字面量` ≠ `immutable(int[])`**：cast 产出的是 `immutable(int)[]`（冻元素、切片头可变）——`receiveOnly!(immutable int[])` 解析为 `immutable(int[])`（全冻），两者**不匹配**抛 MessageMismatch。两侧形状必须一致：要么都 `immutable(int)[]`，要么都 `immutable(int[])`。这是本章实测头号坑。
2. **worker 里异常没人接 → 主线程死等**（不是崩溃！）：MessageMismatch 在 worker 里炸，主线程 receiveOnly 永远阻塞——worker 内 try-catch 把异常回报成消息是工程习惯。
3. **`lazy` 是关键字**不能做变量名（worker 演示时踩过）。
4. `Thread.sleep(200.msecs)` 要 `import core.thread` + `import core.time : msecs`——`.msecs` 不在默认作用域。
5. 消息里的**结构体是浅拷贝**：字段有切片时两边共享底层——要独占就 dup 后再 send，或发 immutable。
6. `receiveOnly` 收到**多个**消息在邮箱里也只取队首一条——按序处理，类型分支别漏（漏的类型会一直堵在队首）。

---
