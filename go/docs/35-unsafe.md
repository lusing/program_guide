# 35 · 底层窥视：unsafe

> 对应示例：`examples/35_unsafe/`。标准库篇收尾：绕过类型系统的逃生舱——规矩比功能更重要。

## 35.1 三个常量级函数：Sizeof / Alignof / Offsetof

```go
type Padded struct {
    A bool    // 1 字节 + 7 字节填充
    B int64   // 8
    C bool    // 1 + 7
}                // sizeof = 24

type Packed struct {
    B int64
    A bool
    C bool     // A、C 共享同一轮填充
}                // sizeof = 16 —— 只是换了字段顺序！

unsafe.Sizeof(x)          // 类型占多少字节
unsafe.Alignof(x)         // 对齐要求（int64 是 8）
unsafe.Offsetof(v.B)      // 字段距结构体头的偏移
```

这些是**编译期常量**、纯只读——在 unsafe 包里它们几乎算"安全"的：算布局、做对齐敏感的优化、给 cgo 填结构体。**字段顺序影响内存占用**：把大对齐的字段排前面，填充变少（`Padded` → `Packed` 省 1/3）。

## 35.2 unsafe.Pointer：四条合法通道

`unsafe.Pointer` 是带 GC 追踪的万能指针。包文档划了**四条合法用法**，出这四条之外的玩法都是未定义行为：

1. **`*T1` → `*T2`**：两个类型内存布局相同时重解释（`*int64` ↔ `*MyInt64`）；
2. **Pointer ↔ uintptr 做系统调用**：syscall.Syscall 的参数收 uintptr（进入内核那一刻由它持有）；
3. **syscall 返回的指针值**转回 Pointer；
4. **`reflect.Value.Pointer/UnsafeAddr` 的结果**立刻转 Pointer。

核心天条：**uintptr 只是个数字，GC 不认识它**。指针算术必须**在一个表达式内**完成——`unsafe.Add(p, n)` / `p2 := unsafe.Pointer(uintptr(p) + offset)` 都不能跨语句存 uintptr，否则 GC 半路搬走对象、你拿的是野地址（`-race` 都查不出来）。1.17+ 用 `unsafe.Add`/`unsafe.Slice` 代替手算。

## 35.3 零拷贝 string ↔ []byte（1.20 的正道）

25 章说过 `string(b)` / `[]byte(s)` 每次全量拷贝。1.20 给了受控的零拷贝原语：

```go
// []byte → string，不拷贝：之后**绝不能再改 b**（string 的不可变性被你亲手出卖）
s := unsafe.String(unsafe.SliceData(b), len(b))

// string → []byte 可写视图：只能用于"你确知底层其实是自己的 byte 切片"的串
b := unsafe.Slice(unsafe.StringData(s), len(s))

// 空切片/空串要特判：SliceData 可能返回 nil
```

热路径（大缓冲转字符串送去比较/哈希/当天主教 map 键用完即弃）能省一次大分配——**改不改的纪律全靠人肉维持**，传出去的 string 存活期间动 b 就是数据竞争。库代码的公开 API 别这么干，内部快路径可以。

## 35.4 什么时候才需要 unsafe

| 场景 | 替代品 |
|---|---|
| 想零拷贝提速 | 先测：`string(b)` 往往不是瓶颈 |
| 访问结构体私有字段 | reflect（unsafe 之上的封装） |
| 与 C 交互 | cgo 自动处理（24/23 章） |
| reinterpret cast | 大多可用泛型/接口重设计绕开 |

真用到它的时候：`sync/atomic` 的实现、runtime 内部、性能极致的序列化库（flatbuffers 思路）、cgo 边界。业务代码里出现 unsafe 的正确反应是**先怀疑设计**。

## 35.5 坑位清单

1. **uintptr 存进变量再算术**：GC 随时搬家——`unsafe.Add` 一表达式内完成。
2. **零拷贝 string 后改底层数组**：string 语义被出卖，读侧随时撕裂——纪律：转换后 b 冻结。
3. **`*T1` 转 `*T2` 布局不同**：字段对不上静默读错值——先 `Sizeof`/`Offsetof` 验证布局。
4. **slice 越界造出来**：`unsafe.Slice(p, n)` 的 n 没人替你查——造出来的切片越界照样 panic（还更难查）。
5. **go vet 会盯**：possible misuse of unsafe.Pointer 就是第二条天条被踩的信号，别压这个告警。
6. **依赖它做的优化没测**：unsafe 改动必须配 benchmark（示例 35 的测试用 `testing.AllocsPerRun` 断言零拷贝真的零分配）。

---
