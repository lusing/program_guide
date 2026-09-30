# 34 · 实战：LRU 缓存服务器 zcache

> 对应示例：`examples/34_zcache/`
>
> 收官工程：内存 KV 缓存——LRU 淘汰核 + TCP 文本协议 + 并发访问。取材 Tsoukalos ch10（zcache 的核心问题："为什么哈希表和双向链表两个都要"）。

## 34.1 LRU = HashMap + 双向链表，缺一不可

```zig
const Entry = struct {
    key: []u8,
    value: []u8,
    link: std.DoublyLinkedList.Node = .{},   // 侵入式节点：挂在宿主结构里
};
// map: StringHashMap(*Entry)  —— O(1) 定位
// order: DoublyLinkedList     —— O(1) 记新旧（first = 最新，last = 淘汰候选）
```

单用 HashMap：找得到但不知谁最旧；单用链表：知新旧但找不快。合体后 `get` 命中即 `touch`（摘下重挂队首），淘汰就是摘链表尾巴——**全程 O(1)**。`std.DoublyLinkedList` 是侵入式的：`Node` 塞进自己的结构体，`@fieldParentPtr("link", node)` 从节点反查宿主（7 章字段父指针的实战回收）。

注意 0.16 的方法名：队首插是 `prepend`（不是 pushFront），队尾摘是 `pop`。

## 34.2 文本协议：一行命令一行应答

```text
SET a 1        → OK          GET a   → VALUE 1
DEL b          → OK / MISS   STATS   → STATS hits=.. misses=.. evictions=.. entries=..
```

比书的二进制帧协议（ZEMP）好写好调试——telnet 都能当客户端；二进制协议的长度前缀、部分读、状态机见书 ch10 与 33 章练习。`recvLine` 按 `\r\n` 收帧；应答里值内嵌空格会破坏协议（练习：定长或转义）。

## 34.3 并发：一把 Io.Mutex 罩住整个核

服务器的每条命令在锁内完成读改写；串行 accept + 顺序服务让演示**完全确定**（断言到具体数字）。两个并发客户端连接打同一个键 `shared`：各自的 SET 后 GET 都必然命中（值是 v0 还是 v1 不确定——**断言形状不断言内容**，这是并发测试的通用心法）。书的原版是事件驱动/线程池服务器——那是 31 章线程池的天然练习场。

## 34.4 自演脚本：语义断言到具体数字

```text
容量 3：SET a b c → GET a（a 提新）→ SET d（淘汰 b）→ GET a = MISS / GET d = VALUE
→ DEL b → STATS hits=2 misses=2 evictions=1 entries=2
```

LRU 的正确性全靠这种"访问历史敏感"的序列——单元测试（`examples/34_zcache/main.zig` 的 34.5 节）四组：淘汰序、更新不占位、计数、删后重插。

## 34.5 坑位清单

1. **`pushFront` 不存在**：0.16 的 `DoublyLinkedList` 用 `prepend/append/pop/popFirst`——方法名照 std 源码，不照记忆。
2. **侵入式链表的内存归 map 管**：Entry 的 key/value 是自有堆内存，链表只串指针——deinit 沿链表走一遍释放（map 和链表是同一批 Entry 的两个视图，别释放两遍）。
3. **淘汰时机在插入之后**：先插再 `while (count > capacity) pop 尾`——先删后插会在"恰好满容量"时误删活键。
4. **并发断言只到形状**：两个线程 SET 同一键后各自 GET——值内容取决于交错，断言 `startsWith("VALUE ")` 而不是具体值。
5. **服务器定长收摊**：恰好服务 N 条连接后退出（29 章关停策略复用）——自演脚本的连接数是已知常量，join 必然返回。

## 34.6 扩展练习

1. **TTL**：Entry 加过期时间戳，GET 时惰性清理（或后台线程定期扫尾段）。
2. **线程池服务器**：31 章的 Pool 接进来，每连接一个任务——锁竞争立刻变成真实问题（分片锁）。
3. **二进制协议**：`extern struct` 帧头（magic/len/op）+ 33 章的部分读状态机——书上 ZEMP 的完整复刻。
4. **持久化**：把淘汰的脏页写进 SQLite（32 章）——缓存与存储的经典分层。

---

上一章：[33 实战：表达式解释器](33-zcalc.md) · 下一章：（完）
