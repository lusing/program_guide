# 26 · 编码与流处理

> 对应示例：`examples/26_encoding/`
>
> hex、Base64、流式分块、SIMD 计数——数据处理工具的四件基本功。取材 Tsoukalos ch4：z64（Base64 工具）、zwc（高性能字数统计）与缓冲尺寸实验。

## 26.1 hex：一对标准库函数

```zig
const hexed = std.fmt.bytesToHex(raw, .upper);   // 定长输入 → 定长输出（栈上完成）
_ = try std.fmt.hexToBytes(&back, &hexed);       // 逆变换（输出长度必须刚好）
```

hex 是"给人看的字节"：hexdump、指纹、协议调试日志。定长数组版本零分配；切片版 `bytesToHex` 也接受运行时长度。

## 26.2 std.base64：先算长度，再谈读写

```zig
const enc_len = base64_std.Encoder.calcSize(msg.len);         // 4×⌈n/3⌉
const b64 = base64_std.Encoder.encode(enc_buf, msg);
const dec_len = try base64_std.Decoder.calcSizeForSlice(b64); // 需要错误集（输入可能是脏的）
try base64_std.Decoder.decode(dec_buf, b64);
```

编码方向长度是纯数学（`calcSize` 不出错）；解码方向输入可能残缺（`calcSizeForSlice` 返回 `error`）。还有 URL 安全字母表（`std.base64.url_safe`）与无填充变体（`standard_no_pad`）——JWT 之类的协议会指定。

## 26.3 手写一遍 Base64：3 字节 → 4 字符

示例的 `encodeB64` 每轮吃 3 字节拼成 24 bit，切成四个 6 bit 查表输出，尾部按 RFC 4648 补 `=`。手写完再和标准库逐字节对拍（测试正是这么断言的）——**协议本体的理解没有捷径，实现一遍最扎实**。位运算 `<<`/`>>`/`&`/`|` 是这类代码的全部家当。

## 26.4 流式分块：内存占用与总量脱钩

```zig
var src = std.Io.Reader.fixed(big);                    // 100KB 的"文件"——内存里的流式源
var sink_state: std.Io.Writer.Allocating = .init(alloc);
try streamHexdump(&src, &sink_state.writer, 32);       // 按 16 字节块拉-算-写
const got = try r.readSliceShort(&chunk);              // 读到多少算多少，EOF 返回 0
```

管道形状：Reader 进、Writer 出，中间的块缓冲固定大小。`readSliceShort` 是"short read"语义——给多少收多少，不硬等填满；`Io.Reader.fixed` 把一个切片变成流（测试的万能道具），`Io.Writer.Allocating` 把输出收进堆（要 `deinit`）。

## 26.5 SIMD：@Vector 一批 32 字节

```zig
const V = @Vector(32, u8);
const v: V = text[i..][0..32].*;                 // 一次装 32 字节
const is_white = (v == sp) | ((v >= tab) & (v <= cr));
const curr: u32 = @bitCast(@select(u1, is_white, ones, zeros));
words += @popCount(~curr & prev);                // 位技巧：数"词首"
```

比较产生位掩码，`@popCount` 数位。词首检测的经典位技巧：当前非空白 且 前一位空白——块间用 `prev_was_space` 把上一块的末位接进来（`curr << 1 | prev`），跨块单词不丢。尾巴不足 32 字节退回标量。示例测试特意构造"块边界切开单词"的用例对拍两个实现。

## 26.6 坑位清单

1. **`@bitCast` 向量到位掩码要求宽度吻合**：`@Vector(32, u1)` 位掩码转 `u32` 刚好 32 bit；向量宽度与整数位宽不齐是编译错。
2. **`readSliceShort` 没有 EOF 错误**：干净结尾返回 0；`ReadFailed` 才是真错——别把 0 当错误吞了。
3. **Writer.Allocating 要 deinit**：它是真分配器背后的增长缓冲；arena 能兜，testing.allocator 会逮。
4. **SIMD 的正确性验证靠对拍**：标量实现是参照系——两实现对拍一组刁钻输入（空串、全空白、跨界单词、满 32 倍数），比单看 SIMD 代码可信得多。
5. **Base64 解码的脏输入**：长度不对/非法字符是 `error.InvalidPadding` 等错误集成员——生产代码别 `catch unreachable`。

---

上一章：[25 二进制数据与内存布局](25-binary.md) · 下一章：[27 目录遍历与文件树](27-tree.md)
