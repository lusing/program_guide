# 25 · 位运算、溢出与运算符重载

> 对应示例：`examples/25_advanced_operators/`
> 运行：`swift run Ch25AdvancedOperators`，测试：`swift test --filter Ch25AdvancedOperatorsTests`

本章讲三件事：一是位运算符（`~` `&` `|` `^` `<<` `>>`），它让你能直接操作整数的
每一个二进制位，是图像处理、协议编解码、权限标志等底层场景的必备工具；二是溢出
运算符（`&+` 家族），Swift 默认让溢出崩溃，这组运算符让你显式选择"回绕"语义；
三是运算符函数——给自定义类型装上内置运算符（`+` `==` 等），甚至发明全新的运算符。

## 25.1 位运算符：直接读写二进制位

一个 `UInt8` 是 8 个比特位，每位非 0 即 1。位运算符就是对两个操作数的对应位
逐一运算。Swift 提供四个按位二元运算符加一个一元取反：

| 运算符 | 名称 | 规则（对每一位） |
|---|---|---|
| `~x` | 按位取反（前置一元） | 0 → 1，1 → 0 |
| `x & y` | 按位与 | 两位都是 1 才得 1，否则得 0 |
| `x \| y` | 按位或 | 任一位是 1 就得 1，都是 0 才得 0 |
| `x ^ y` | 按位异或 | 两位不同得 1，相同得 0 |
| `x << n` / `x >> n` | 左移 / 右移 | 所有位整体移动 n 位 |

### 按位取反 `~`

`~` 是前置一元运算符，写在操作数前面（不要加空格）：

```swift
let initialBits: UInt8 = 0b0000_1111  // 十进制 15
let invertedBits = ~initialBits       // 0b1111_0000 = 240
```

`0b` 前缀表示二进制字面量，下划线 `_` 纯粹为了分组可读。`UInt8` 是 8 位无符号
整数，范围 0...255。`~` 把 8 个位全部翻转：前 4 位的 0 变 1，后 4 位的 1 变 0，
结果是 `0b1111_0000`，也就是 240。

### 按位与 `&`：掩码提取

`&` 的规则是"两位都是 1 才得 1"。它的典型用途是**掩码**（mask）：用一个"模板"
把不需要的位清成 0，只保留关心的位。

```swift
let firstSixBits: UInt8 = 0b1111_1100
let lastSixBits: UInt8 = 0b0011_1111
let middleFourBits = firstSixBits & lastSixBits  // 0b0011_1100 = 60
```

`lastSixBits` 就是掩码：它的前 2 位是 0，所以 `firstSixBits` 的前 2 位被清零；
它的后 6 位是 1，所以 `firstSixBits` 的后 6 位原样保留。结果是 `0b0011_1100`。

### 按位或 `|`：合并标志位

`|` 的规则是"任一位是 1 就得 1"。它用来**合并**：把两组各自为 1 的位拼到一起。

```swift
let someBits: UInt8 = 0b1011_0010
let moreBits: UInt8 = 0b0101_1110
let combinedBits = someBits | moreBits  // 0b1111_1110 = 254
```

两个操作数在不同位置上有 1，`|` 把它们全保留下来，得到 `0b1111_1110`。

### 按位异或 `^`：无进位加法

`^` 的规则是"两位不同得 1，相同得 0"。它有一个极有用的代数性质：
**一个值异或同一个 key 两次会还原**（`a ^ b ^ b == a`）。这让它既能用来
翻转指定位，也能做最朴素的"加密"：

```swift
let firstBits: UInt8 = 0b0001_0100
let otherBits: UInt8 = 0b0000_0101
let outputBits = firstBits ^ otherBits  // 0b0001_0001 = 17

// 实用性质：a ^ key ^ key == a
func xorCipher(_ data: [UInt8], key: UInt8) -> [UInt8] {
    data.map { $0 ^ key }
}
let secret: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]  // "Hello"
let ciphered = xorCipher(secret, key: 0x5A)
let recovered = xorCipher(ciphered, key: 0x5A)
print(recovered == secret)  // true
```

第一次异或把每个字节变了样，第二次用同一个 key 再异或就还原了。这不是真正的
加密（key 只有 256 种可能，暴力破解 trivial），但演示了异或的可逆性——很多
协议里的校验和、简单混淆都用这个性质。

### 移位 `<<` `>>`：乘除 2 的幂

左移 n 位相当于乘 2ⁿ，右移 n 位相当于除 2ⁿ（向零取整）：

```swift
let shiftBits: UInt8 = 4  // 0b0000_0100
shiftBits << 1  // 8，×2
shiftBits << 2  // 16，×4
shiftBits >> 2  // 1，÷4
```

**无符号数**移位时，被移出边界的位直接丢弃，空出来的位补 0（这叫**逻辑移位**）。
注意 `UInt8(1) << 7` 是 128，但 `UInt8(1) << 8` 就溢出了——Swift 对移位也做
溢出检查，移出所有有效位会 trap。

**有符号数**右移时，空位按**符号位**填充（正数补 0，负数补 1），这叫**算术移位**，
保证右移时符号不变：

```swift
let negative: Int8 = -4           // 0b1111_1100（补码表示）
let shiftedNegative = negative >> 1  // 0b1111_1110 = -2
```

负数在内存里用**二进制补码**存储：符号位是 1，其余位存的是"2ⁿ − |值|"。
`-4` 的 8 位补码是 `1111_1100`，右移 1 位后高位补 1 得到 `1111_1110`，
正是 `-2`。所以 `-4 >> 1 == -2`，右移让负数向 0 靠近但仍是负数。

> 补码的好处：加减法不用区分符号。`-1 + -4` 直接按位相加（丢掉进位溢出）
> 就得到 `-5`，CPU 不需要两套电路。

### 实战：从打包颜色值拆 RGB

位运算的经典组合——掩码 + 移位。一个 32 位颜色值 `0xCC6699` 里，红、绿、蓝
三个分量各占 8 位：

```swift
let pink: UInt32 = 0xCC6699
let redComponent = (pink & 0xFF_0000) >> 16   // 0xCC = 204
let greenComponent = (pink & 0x00_FF00) >> 8  // 0x66 = 102
let blueComponent = pink & 0x00_00FF          // 0x99 = 153
```

第一步用 `&` 把不需要的字节清零（掩码），第二步用 `>>` 把目标字节移到最低位。
两步配合，从打包数据里精确拆出每个字段——解析二进制文件、网络协议时这个
模式会反复出现。

## 25.2 溢出运算符：默认崩溃，& 家族回绕

Swift 的整数运算默认**不允许溢出**：编译期能看出来直接报错，运行期才暴露的
会 trap（进程崩溃）。这是刻意的安全设计——C/C++ 的有符号溢出是未定义行为，
优化后可能错得离谱。

但有些时候你**就是要回绕**（比如哈希算法、CRC 校验、固定宽度计数器）。这时
用 `&` 开头的溢出运算符：

| 运算符 | 含义 |
|---|---|
| `&+` | 溢出加法 |
| `&-` | 溢出减法 |
| `&*` | 溢出乘法 |

```swift
// let tooBig: UInt8 = UInt8.max + 1   // ❌ 编译期报错
// var trap: UInt8 = 250; trap += 10   // ❌ 运行期 trap

var willOverflow = UInt8.max
willOverflow = willOverflow &+ 1  // 上溢出：255 + 1 → 0
// 二进制视角：0b1111_1111 + 1 = 1_0000_0000，第 9 位被丢弃，剩 0b0000_0000

var willUnderflow = UInt8.min
willUnderflow = willUnderflow &- 1  // 下溢出：0 - 1 → 255
// 借位绕回：0b0000_0000 - 1 = 0b1111_1111

var signedUnderflow = Int8.min
signedUnderflow = signedUnderflow &- 1  // -128 - 1 → 127
// 补码下溢：0b1000_0000 - 1 = 0b0111_1111，符号位翻转
```

三种溢出都演示了：**上溢出**（超过最大值，从最小值继续）、**下溢出**（小于最小值，
从最大值继续）、**有符号下溢出**（补码环绕，最小负数减 1 变成最大正数）。

> ⚠️ 老资料里可能提到 `&/` 和 `&%`——**Swift 3 已移除**（SE-0007）。
> 除零没有"安全版本"：需要容错就用可选绑定或错误处理（12 章），
> 别指望运算符兜底。

## 25.3 优先级与结合性

多个运算符混用时，**优先级**决定谁先算，**结合性**决定同级的从左还是从右 grouping：

```swift
let result = 2 + 3 * 4 % 5  // 4
// 不是 ((2+3)*4)%5 = 0
// 而是 2 + ((3*4) % 5) = 2 + (12 % 5) = 2 + 2 = 4
```

`*` 和 `%` 优先级相同、**左结合**（从左往右 grouping），且都高于 `+`。
所以 `3 * 4 % 5` 等价于 `(3 * 4) % 5`，不是 `3 * (4 % 5)`。

写复杂表达式时**不要依赖记忆**——加括号让意图明确。Swift 的完整优先级表
见官方文档，但日常只需要记住：一元 > 乘除 > 加减 > 移位 > 比较 > 逻辑。

## 25.4 运算符函数：给自定义类型装内置运算符

Swift 的 `+` `-` `==` 等不是关键字，而是**函数**。你可以为自己的 struct/class/enum
实现这些函数，让自定义类型直接用内置运算符。这叫**运算符重载**。

实现方式是：在类型体内写 `static func`，函数名就是运算符符号。

### 中置二元运算符 `+`

```swift
struct Vector2D {
    var x = 0.0
    var y = 0.0

    static func + (left: Vector2D, right: Vector2D) -> Vector2D {
        Vector2D(x: left.x + right.x, y: left.y + right.y)
    }
}

let vector = Vector2D(x: 3.0, y: 1.0)
let anotherVector = Vector2D(x: 2.0, y: 4.0)
let combinedVector = vector + anotherVector  // (5.0, 5.0)
```

参数名 `left`/`right` 对应运算符左右两边的操作数。返回值是新向量，两个分量
分别相加。这个 `+` 是 `Vector2D` 的**静态方法**——它不属于某个实例，而是
类型级别的函数，所以 `vector + anotherVector` 本质上等价于
`Vector2D.+(vector, anotherVector)`。

### 前置一元运算符 `-`

前置运算符在 `func` 前加 `prefix` 关键字：

```swift
extension Vector2D {
    static prefix func - (vector: Vector2D) -> Vector2D {
        Vector2D(x: -vector.x, y: -vector.y)
    }
}

let positive = Vector2D(x: 3.0, y: 4.0)
let negative = -positive  // (-3.0, -4.0)
```

### 组合赋值 `+=`

`+=` 的左参数必须是 `inout`——它要在函数体内被原地修改：

```swift
extension Vector2D {
    static func += (left: inout Vector2D, right: Vector2D) {
        left = left + right  // 复用已定义的 +
    }
}

var toIncrement = Vector2D(x: 1.0, y: 2.0)
toIncrement += Vector2D(x: 3.0, y: 4.0)  // (4.0, 6.0)
```

> 普通的赋值 `=` 不能重载，只有组合赋值（`+=` `-=` 等）可以。
> 三目条件 `?:` 也不能重载。

### 等值运算符 `==`

自定义类型默认不能用 `==` 比较。要支持，声明 `Equatable` 协议并实现 `==`：

```swift
extension Vector2D: Equatable {
    static func == (left: Vector2D, right: Vector2D) -> Bool {
        left.x == right.x && left.y == right.y
    }
}
```

`!=` 不用自己写——标准库会根据你的 `==` 自动提供默认实现。
（07 章讲过：struct 声明 `Equatable` 时编译器可以**自动合成** `==`，
前提是所有存储属性本身也 `Equatable`。手写 `==` 适用于需要自定义比较逻辑的场景。）

## 25.5 自定义运算符：发明自己的符号

内置运算符不够用？Swift 允许你发明新运算符。两步：先用 `operator` 关键字
**声明**，再像内置运算符一样**实现**。

可用的字符集：`/ = - + * % < > ! & | ^ . ~`（以及它们的组合）。

### 声明与实现

```swift
// 声明：infix 表示中置（两个操作数之间），+- 是运算符名
// AdditionPrecedence 是标准库预定义的优先级组（与 + 同级，左结合）
infix operator +-: AdditionPrecedence

extension Vector2D {
    static func +- (left: Vector2D, right: Vector2D) -> Vector2D {
        Vector2D(x: left.x + right.x, y: left.y - right.y)
    }
}

let firstVec = Vector2D(x: 1.0, y: 2.0)
let secondVec = Vector2D(x: 3.0, y: 4.0)
let plusMinusResult = firstVec +- secondVec  // (4.0, -2.0)
```

`+-` 的语义是"x 相加、y 相减"。它复用了加法优先级组，所以在混合表达式里
它的优先级和 `+` 一样。

### 自定义优先级组

标准库的优先级组不够用？自己定义：

```swift
precedencegroup RightMultiplyPrecedence {
    higherThan: MultiplicationPrecedence   // 比 * 先算
    associativity: right                   // 同级从右往左结合
}
infix operator **: RightMultiplyPrecedence

extension Vector2D {
    static func ** (left: Vector2D, right: Vector2D) -> Vector2D {
        Vector2D(x: left.x * right.x, y: left.y * right.y)
    }
}

let powResult = Vector2D(x: 2, y: 3) ** Vector2D(x: 5, y: 7)  // (10.0, 21.0)
```

`precedencegroup` 的三个关键属性：

- `higherThan` / `lowerThan`：相对于其他优先级组的位置
- `associativity`：`left`（左结合）/ `right`（右结合）/ `none`（不允许同级连用）
- `assignment`：`true` 表示这个运算符参与赋值链（像 `??` 那样允许
  `a ??= b` 之类的简写），一般不用设

> ⚠️ 自定义运算符是把双刃剑：`+-` `**` 对作者直观，对读者可能是谜语。
> 团队代码里优先用**命名方法**（`mergedWith(_:)`），自定义运算符只留给
> 领域内有共识的符号（比如数学库里的 `×` `÷`）。

## 25.6 坑位清单

1. **`~/&/|` 与 `&&/||` 完全不同**：前者是位运算（对整数的二进制位操作），
   后者是逻辑运算（对 Bool 短路求值）。`&` 没有短路——两边永远都会算。
2. **移位也查溢出**：`UInt8(1) << 8` 会 trap（结果超出 UInt8 范围），
   不是得 0。需要宽结果先升到更宽的类型：`UInt16(UInt8(1)) << 8`。
3. **`&+` 家族只回绕，不解决除零**：`&/` `&%` 已删除（Swift 3 / SE-0007）。
4. **重载不要改变运算符的直觉语义**：给 `+` 定义成"减法"会让读代码的人
   怀疑人生。重载是让自定义类型获得**与内置类型一致**的体验，不是炫技。
5. **自定义运算符不能含字母**：只能用 `/ = - + * % < > ! & | ^ . ~` 组合，
   想写 `dot` `cross` 这样的名字？用方法。
6. **优先级组是类型级别的**：`infix operator` 声明必须出现在**全局作用域**
   （不能写在类型体内），实现（`static func`）才写在类型里。

上一章：[24 · 实战：迷你 grep](24-minigrep.md) ｜ 下一章：[26 · 继承与类型转换](26-inheritance-casting.md) ｜ 返回：[README](../README.md)
