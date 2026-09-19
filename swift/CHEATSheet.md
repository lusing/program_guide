# Swift 速查（6.3.3 / Swift 6 语言模式）

> 配套 [24 章教程](docs/01-overview.md)：语法速查 + 实测坑位索引。`swift/` 根目录下
> 所有命令直接可用（build.ps1 已配好环境）。

## 1. 语法速查

### 声明与类型

```swift
let x = 1                  // 常量（默认首选）
var y = 2                  // 变量
let z: Double = 5          // 显式标注
let pair = (a: 1, b: 2)    // 元组
let opt: Int? = nil        // 可选（默认 nil）
let iou: String!           // 隐式解包可选（遗留，新代码别用）
typealias Op = (Int, Int) -> Int

func f(_ a: Int, label b: Int = 2, others c: Int...) -> Int { a + b }   // _ 省标签/默认值/变参
func g(inout a: Int) { a += 1 }          // 调用处写 &a
func h(x: Int) throws(MyError) -> Int    // typed throws（括号里是错误类型！）
func k(_ body: (Int) throws -> Void) rethrows   // 只重抛闭包的错
```

### 控制流

```swift
if let v = opt { }                     // 解包作用域
guard let v = opt else { return }      // 解包外溢（else 必须退出）
switch x {
case 1...5: break                     // 区间；无贯穿；必须穷尽
case let n where n > 0: break         // 值绑定 + 谓词
case (0, let y): break                // 元组模式
@unknown default: break               // 冻结枚举的未来防御
}
for i in 0..<n { }                     // 半开区间（无 C 式 for）
for (i, x) in arr.enumerated() { }
outer: while true { break outer }      // 标签跳转
x ?? y                                 // nil 合并
```

### 集合与字符串

```swift
var arr: [Int] = []; arr.append(1); arr[0]
var set: Set<Int> = []; set.insert(1)
var dict: [String: Int] = [:]; dict["k", default: 0] += 1   // 计数惯用法
arr.map { $0 * 2 }; arr.filter { $0 > 0 }; arr.reduce(0, +)
arr.compactMap { $0 }                  // 洗 nil
let slice = arr[1..<3]                 // 切片：startIndex 是 1 不是 0！
let sub = str.prefix(5)                // Substring；长期持有要 String(sub)
let i = str.index(str.startIndex, offsetBy: 2); str[i]      // 下标是 Index 不是 Int
str.firstMatch(of: /\d+/)              // Regex 字面量（编译期检查）
```

### 类型系统

```swift
struct S: Equatable, Sendable { let x: Int }        // 值语义 + 全 let 自动合成 ==
class C { deinit { } weak var parent: C? }          // 引用语义 + ARC
enum E { case a(Int), b(String); indirect case tree(E) }   // 代数数据类型
protocol P { var x: Int { get } }                    // { get } 是下限
extension Int { var isEven: Bool { self % 2 == 0 } } // 万物可扩
extension Array where Element: Comparable { }        // 条件能力
func f<T: Comparable>(_ xs: [T]) -> T? { }          // 泛型约束
func g(_ p: some P) { }   /  func h(_ p: any P) { } // 不透明 / 存在
@propertyWrapper struct W { var wrappedValue: Int }  // @W 包装
```

### 错误

```swift
enum Err: Error { case bad }
func parse() throws -> Int { throw Err.bad }
do { let r = try parse() } catch Err.bad { } catch { print(error) }
let v = try? parse(); let w = try! parse()
Result<Int, Err>.success(1)            // 值形态的错误
```

### 并发（Swift 6）

```swift
let x = await f()                       // 挂起点
async let a = f()                       // 并发起跑（收账 await a）
await withTaskGroup(of: Int.self) { g in g.addTask { } }   // 动态并发
actor Counter { var n = 0; func inc() { n += 1 } }          // 隔离域
await counter.inc()                     // 跨隔离必须 await
struct Conf: Sendable { let host: String }                  // 跨域护照
Task { }                                // 非结构化（谨慎）
for await v in stream { }               // AsyncSequence
```

### 测试（swift-testing）

```swift
import Testing
@Test func 名字() async throws { #expect(f() == 1); let x = try #require(opt) }
@Test("描述", arguments: [(1, "一"), (2, "二")]) func 表(a: Int, s: String) { }
@Suite struct S { @Test(.tags(.slow)) func t() { } }
extension Tag { @Tag static var slow: Self }
```

## 2. 命令速查

```bash
swift run Ch12Errors               # 跑某章示例（改完立刻看）
swift test --filter Ch12ErrorsTests # 单章测试
swift build --target Ch12Errors     # 单目标编译
swift format format --configuration .swift-format -r -i examples  # 自动格式化
swift format lint --configuration .swift-format --strict -r examples  # 检查
swift test                          # 全部测试
./run-all.sh 12_errors              # Git Bash 等价入口
pwsh build.ps1 -All                 # 四层全量验证
swiftc -static-stdlib a.swift -o a.exe   # 静态链接独立分发
```

## 3. 实测坑位索引（6.3.3 @ Windows，全部踩过验证）

### 环境（杀伤力最大）

1. **scoop 6.4.0 缺 Runtimes\usr\bin**——exe 一跑 0xC00000135，SPM 清单也死 → 钉
   6.3.3（01 章）。
2. **SDKROOT 指向 current** → 版本切换后混编报
   `module compiled with Swift 6.4 cannot be imported by Swift 6.3.3` → 脚本显式覆盖。
3. **exe 运行需要 Runtimes\usr\bin 在 PATH**——`swift run` 自动配，裸跑要手动；
   分发用 `-static-stdlib`。
4. **swift-format 无配置默认 2 空格**——`.swift-format` 钉 4 空格，配置必须走
   `--configuration` 传参。
5. **lint 目录必须 `--recursive`**。

### Swift 6 严格并发

6. **main.swift 顶层 let/var 是 MainActor 隔离**——非隔离函数/测试引用报错 →
   `enum NS { static let data = ... }`；Task 闭包捕获顶层 var 报 async 访问 →
   拷贝本地 let。
7. **`await` 不能在非赋值运算符右侧**——`(await a) + (await b)`。
8. **`precondition(...)` 的 autoclosure 不吃 try/await/actor 属性**——先求值成
   let 再断言（16/17/18/20 章连环踩）。
9. **`for await` 收割顺序不定**——排序后再输出/断言。

### 类型与语义

10. **无隐式数值转换**——Int 与 Double、Int 与 Int64 混算都要显式构造；
    `Int / Double` 直接编译错误。
11. **`where A == B` 同型约束非法**；空数组字面量推断 `[Any]`——`[Int]()` 给锚点。
12. **String 的 Comparable 是 Unicode 标量序**——"香蕉" > "苹果" > "樱桃"（按首字
    码点），拼音序要自定义。
13. **Equatable/Hashable/CaseIterable/Comparable 都要显式声明**——合成的是实现，
    conformance 是门牌。
14. **元组可选比较要解包**——`optTuple == (1, 2)` 编译不过。
15. **`String.reversed()` 不是 String**；filter 在 String 上返回 String、数组上返回
    数组——比较前 `Array(...)` 归一。

### API 细节

16. **切片/前缀的 startIndex 不归零**——`slice[0]` 崩；`Array(slice)` 转正。
17. **Set 字面量默认推断 Array**——`[3,5].isSubset(of: s)` 编译错，`Set([3,5])` 才行。
18. **`split` 返回 [Substring]**；空串 split(omittingEmptySubsequences: false) 得
    `[""]`（行数 1 不是 0）。
19. **Regex 匹配 API 在字符串一侧**——`text.matches(of:)`；`Regex` 对象没有
    `matches(in:)`；模式里的空格是字面空格。
20. **`throws(E)` 括号里是错误类型不是返回类型**；`Result { try ... }` 产
    `any Error` 要收窄；`try? x == nil` 要括号。
21. **JSONEncoder 的 `.sortedKeys`** 是输出确定性/快照测试的前提；编解码两侧日期
    策略必须一致。
22. **宽字符 API**：`GetSystemDirectoryW` 写 UTF-16 数组——
    `String(decoding: buf.prefix(n), as: UTF16.self)`。
23. **swift-format 的 AlwaysUseLowerCamelCase** 拒绝大写开头的函数名——中文没问题，
    `Stack推弹` 不行（改 `stack推弹`）。
24. **并行测试的清理范围 = 自己创建的文件**——删共享目录殃及邻居（19 章实测竞态）。

## 4. 相关资源

- [Swift 官方文档](https://www.swift.org/documentation/)（The Swift Programming
  Language 一册读完约等于本教程英文版）
- [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- 每章坑位清单的完整上下文：[docs/](docs/01-overview.md)
