# 25 · 二进制数据与内存布局

> 对应示例：`examples/25_binary/`
>
> 文本格式看 20 章的 JSON；真实世界的另一半是二进制：文件头、网络协议帧、硬件寄存器。取材 Tsoukalos《Systems Programming with Zig》ch3——extern struct、packed struct、字节序三板斧。

## 25.1 extern struct：C ABI 的"外交护照"

普通 struct 的字段顺序由编译器定（重排优化）；`extern struct` 保证 C 布局——按声明顺序、按 C 规则填充：

```zig
const Record = extern struct {
    magic: u16,
    version: u8,
    kind: u8,
    length: u32,
};
```

线协议（wire format）结构必须用它——对端按字节解释，布局不能"看心情"。再配一个 comptime 断言，把"协议尺寸"钉死在编译期（书上的 EOCD 技巧）：

```zig
comptime {
    var wire: usize = 0;
    for (std.meta.fields(Record)) |f| wire += @sizeOf(f.type);
    if (wire != @sizeOf(Record)) @compileError("Record 布局被编译器填充了");
}
```

字段尺寸之和 ≠ `@sizeOf`，说明有对齐填充——要么调整字段顺序消填充（大字段在前），要么接受填充并把协议里的跳过字节显式写出来。

## 25.2 字节序：永远显式，不赌本机

```zig
const value: u32 = 0x12345678;
std.mem.asBytes(&value).*        // 本机序的字节面貌（x86/ARM 桌面端 = 小端）
std.mem.nativeToBig(u32, value)  // 得到"按大端解释刚好正确"的值
std.mem.readInt(u32, &bytes, .little)   // 从字节读：指定端序（WAV/ELF 小端，网络序大端）
std.mem.writeInt(u32, &buf, 36, .little) // 往字节写
```

文件格式几乎都是小端（RIFF/WAV/ELF/PE）或大端（网络序、JPEG 部分）。`readInt/writeInt` 从任意偏移取数、不要求对齐，是最稳的手工解包姿势。

## 25.3 整体重解释：bytesToValue

```zig
const raw align(@alignOf(Record)) = [_]u8{ 0xEF, 0xBE, 0x01, 0x02, 0x08, 0x00, 0x00, 0x00 };
const rec = std.mem.bytesToValue(Record, &raw);
```

把字节块直接 view 成结构体——**前提是布局可预测（extern struct）且对齐过关**（`align(@alignOf(T))` 标注字节数组）。反方向 `std.mem.bytesAsValue` 把结构体 view 成字节。对齐吃不满时它会当场报错而不是静默错读——这正是它比 `@ptrCast` 直转安全的原因。

## 25.4 packed struct：位级打包

```zig
const Flags = packed struct(u16) {   // 背板：整个结构就是 16 个 bit
    enabled: bool,                   // 1 bit
    mode: u2,                        // 2 bit
    reserved: u5,
    level: u8,
};
const board: u16 = @bitCast(f1);     // 结构 ↔ 背板整数，@bitCast 进出
```

与 extern struct 的差别：extern 按 C 规则到**字节**边界，packed 精确到 **bit**。硬件寄存器、协议标志位的读写就用它配 `@bitCast`。

## 25.5 实战：手写 WAV 头

示例里 `makeWav` 用 `writeInt` 逐字段小端打包，`parseWavHead` 逐字段读回并校验魔数——**不依赖结构体内存布局**。对比 25.3 的整体 view：手工逐字段慢一点，但跨平台、跨编译器版本绝对稳。两种姿势都该会：性能敏感的热路径用 view，协议首次实现用手工（把格式文档逐行翻译成代码，错不了）。

## 25.6 坑位清单

1. **普通 struct 不能上线路**：没有布局保证——换编译器版本字段顺序都可能变；线格式一律 `extern struct`（或手工逐字段）。
2. **packed struct 的字段不可取地址**：字段不按字节对齐，`&f.level` 直接编译错；要拿指针先把整个背板 `@bitCast` 出来。
3. **`@bitCast` 的两个方向都要类型匹配尺寸**：`@bitCast` 不改变字节数，u16 背板 ↔ `packed struct(u16)` 刚好；尺寸不齐是编译错，不是运行时坑。
4. **`bytesToValue` 的对齐**：源字节数组要 `align(@alignOf(T))`；从任意切片 view 用 `bytesAsValue` 家族并小心对齐断言。
5. **大小端搞反的症状**：数值大得离谱（如 0x78563412）——文件格式查规范，别猜。
6. **混合行尾会传染源码**：示例仓库里 `.zig` 文件统一 LF（`.gitattributes` 已钉死）——Windows autocrlf 检出成 CRLF 后 `zig fmt --check` 整文件挂，混合行尾只报部分行，更迷惑（本教程实测踩过：25–34 批次一次终验被 11/21/22 三章的旧 CRLF 绊停）。

---

上一章：[24 实战：迷你 grep](24-minigrep.md) · 下一章：[26 编码与流处理](26-encoding.md)
