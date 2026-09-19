# 21 · 测试

> 对应示例：`examples/21_testing/`——**本章的 Tests 目录就是教材**（写法全在里面）

## 21.1 swift-testing：新时代的测试框架

Swift 6 起官方测试框架是 **swift-testing**（`import Testing`），取代 XCTest 成为默认。
本教程从 02 章起每个示例的测试都是它——现在正式盘点写法：

```swift
import Testing
@testable import Ch21Testing

@Test func 基本断言() {
    #expect(letterGrade(85) == "B")
}
```

三大件：

- `@Test`：把函数标记为测试用例（宏生成登记代码）；
- `#expect(表达式)`：通用断言——任意布尔表达式，失败时**打印表达式本身**
  （`Expectation failed: (letterGrade(85) → "C") == "B"`——值与期望一目了然）；
- `#require(表达式)`：会抛错的断言——失败立即中止该用例（后续断言不跑），
  解包可选值的标准姿势：`let first = try #require(scores.first)`。

对比 XCTest 的 `XCTAssertEqual(a, b)`：宏化的 `#expect(a == b)` 少一层 API 表面，
失败诊断反而更丰富（显示两侧求值结果）。`@testable import` 让测试摸到 internal
成员（本教程每章示例的函数就这样被测试引用）。

## 21.2 参数化：一个 @Test 跑一张表

```swift
@Test("letterGrade 边界表", arguments: [
    (-1, "无效"), (0, "F"), (59, "F"), (60, "D"), (69, "D"),
    (70, "C"), (79, "C"), (80, "B"), (89, "B"), (90, "A"),
    (100, "A"), (101, "无效"),
])
func letterGrade边界(score: Int, expected: String) {
    #expect(letterGrade(score) == expected)
}

@Test(arguments: zip(1...10, ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]))
func roman基础(number: Int, numeral: String) { ... }
```

`arguments:` 接受元组数组（或 zip 两个序列），函数参数解包每组——**一条用例失败
只报告那一行**，其余照跑。边界值测试（59/60/69/70…）就该这么写：表即文档。

## 21.3 Suite：打包一组测试

```swift
@Suite("罗马数字全套")
struct RomanSuite {
    @Test func 千位() { #expect(romanNumeral(3999) == "MMMCMXCIX") }
    @Test func 一() { #expect(romanNumeral(1) == "I") }
}
```

Suite = 测试的命名空间：共享辅助函数/属性、统一挂 tag、嵌套组织。默认并行执行
（不同用例可同时跑——所以用例间别共享可变状态）。

## 21.4 Tag 与特征：给测试贴标签

```swift
extension Tag {
    @Tag static var slow: Self
}

@Test(.tags(.slow)) func 慢速用例() { ... }
```

Tag 用于 CI 分层（快跑 subset / 全量夜跑）、按特性筛选；框架还内建
`.disabled(if:)`、`.timeLimit(.seconds(1))` 等特征（traits）。

## 21.5 throws / async 测试

```swift
@Test func require失败即停() throws {
    let first = try #require(scores.first)   // 解包失败 = 用例失败并停止
    #expect(first == 88)
}

@Test func 异步测试形态() async {
    let sum = await withTaskGroup(of: Int.self) { ... }
    #expect(sum == 385)
}
```

函数签名直接标 `throws`/`async`——被抛出的错误算用例失败；17/18 章的并发测试全
是这个形态。**注意**：异步用例并行执行，跨用例共享状态请用 actor。

## 21.6 XCTest 认读（存量代码桥）

```swift
import XCTest

final class OldStyleTests: XCTestCase {
    func testAddition() {
        XCTAssertEqual(add(2, 3), 5)
        XCTAssertNil(find("不存在"))
    }
}
```

网上资料大量是 XCTest 形态，认读要点：`XCTestCase` 子类 + `test` 前缀方法 +
`XCTAssert*` 家族。新代码不必再写它——swift-testing 与 XCTest 可在同一 target
共存（迁移期友好），22 章的包模板只用 swift-testing。

## 21.7 测试本教程的姿势

```bash
swift test --filter Ch21TestingTests        # 单章
swift test                                  # 全部
swift test --filter RomanSuite              # 按 suite 挑
```

`--filter` 匹配测试名/suite 名（正则）。build.ps1 的第 [3/4] 层就是它——并内置
**防假绿**：filter 不匹配时"0 个用例"也算 exit 0，脚本强制校验真的跑到了用例
（"Test run with N tests"且 N ≥ 1）。

TDD 工作流与教程的"改代码再跑"完全兼容：先写 `@Test`（红）→ 实现（绿）→
`swift test --filter` 秒级反馈。

## 21.8 坑位清单（含实测）

1. **`String.reversed()` 不是 String**（21 章实测）：`cleaned == cleaned.reversed()`
   编译错误（ReversedCollection）——先 `Array(...)` 或 `String(...)` 归一。
2. **filter 在 String 上返回 String**，在 Array 上返回 Array——回文比较两侧类型
   必须一致，`Array(filter结果)` 是稳妥姿势。
3. **用例默认并行**：共享可变状态（全局 var、单例）在测试间是数据竞争——要共享
   就 actor。
4. **`#expect(try throwingExpr)` 合法**（宏展开支持 autoclosure 里的 try——与
   `precondition` 不同！16 章的坑在这里不存在），但 `#require` 本身就 throws，
   用 `try #require(...)`。
5. **参数化的 arguments 类型必须齐整**：元组数组里混入不同元数/类型直接编译错误
   （这是特性——表里的用例天然同构）。
6. **中文测试函数名完全可用**（全书 200+ 用例实测），但**不能大写字母开头**
   （swift-format 的 AlwaysUseLowerCamelCase 规则，10 章踩过）。

上一章：[20 · Codable](20-codable.md) ｜ 下一章：[22 · Swift Package Manager](22-spm.md) ｜ 返回：[README](../README.md)
