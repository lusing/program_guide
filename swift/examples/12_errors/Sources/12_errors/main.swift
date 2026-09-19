// 12 · 错误处理——throws/try 家族、do-catch、typed throws、Result、错误分层

import Foundation

// ═══ 12.1 纯函数区（供测试）：错误就是 conform Error 的类型（枚举最自然）
enum VendingError: Error, Equatable {
    case outOfStock(item: String)
    case insufficientFunds(needed: Int, given: Int)
}

struct VendingMachine {
    let prices = ["可乐": 3, "薯片": 5]
    var stock: [String: Int] = ["可乐": 2, "薯片": 0]

    mutating func vend(_ item: String, with money: Int) throws -> Int {
        guard let price = prices[item] else {
            throw VendingError.outOfStock(item: item)  // 没这个商品也当缺货
        }
        guard (stock[item] ?? 0) > 0 else {
            throw VendingError.outOfStock(item: item)
        }
        guard money >= price else {
            throw VendingError.insufficientFunds(needed: price, given: money)
        }
        stock[item, default: 0] -= 1
        return money - price  // 找零
    }
}

// do-catch + 模式匹配：错误也是值，能 switch
func describe(vending result: Result<Int, VendingError>) -> String {
    switch result {
    case .success(let change): return "成功，找零 \(change) 元"
    case .failure(.outOfStock(let item)): return "缺货：\(item)"
    case .failure(.insufficientFunds(let needed, let given)): return "钱不够：要 \(needed) 有 \(given)"
    }
}

// throws 与 Result 互转：Result(catching:) 产生 any Error，要显式收窄
func vendResult(_ machine: inout VendingMachine, item: String, money: Int) -> Result<
    Int, VendingError
> {
    do {
        return .success(try machine.vend(item, with: money))
    } catch let error as VendingError {
        return .failure(error)
    } catch {
        return .failure(.outOfStock(item: item))  // 理论不可达（vend 只抛 VendingError）
    }
}

// typed throws（Swift 6）：括号里钉死的是"错误类型"，不是返回类型！
enum ScoreError: Error, Equatable {
    case invalid(text: String)
}

func parseScore(_ text: String) throws(ScoreError) -> Int {
    guard let value = Int(text), (0...100).contains(value) else {
        throw ScoreError.invalid(text: text)
    }
    return value
}

// try? / try! 家族
func safeScore(_ text: String) -> Int? {
    try? parseScore(text)
}

// rethrows：只重抛调用者传入的闭包抛的错，自己不产生错误
func transformAll(_ values: [String], _ transform: (String) throws -> Int) rethrows -> [Int] {
    try values.map(transform)
}

// 错误分层：可恢复（throws）vs 程序员错误（precondition/fatalError）
func mustBePositive(_ n: Int) -> Int {
    precondition(n > 0, "必须为正数，得到 \(n)")  // 契约违反 = bug，不是业务错误
    return n
}

// ═══ 12.2 do-catch 与错误传播
var machine = VendingMachine()
do {
    let change = try machine.vend("可乐", with: 5)
    print("买到可乐，找零 \(change) 元")
    precondition(change == 2)
} catch VendingError.insufficientFunds(let needed, let given) {
    print("这一支不会走到：要 \(needed) 给了 \(given)")
} catch {
    print("兜底捕获：\(error)")
}

do {
    _ = try machine.vend("薯片", with: 10)
} catch VendingError.outOfStock(let item) {
    print("缺货捕获：\(item)")
}
if case .failure = vendResult(&machine, item: "可乐", money: 1) {
    print("1 元买不到可乐（预期内失败）")
} else {
    precondition(false, "应当失败")
}

// ═══ 12.3 Result：把"成功或失败"装进值里传递
let r1 = vendResult(&machine, item: "可乐", money: 5)
let r2 = vendResult(&machine, item: "可乐", money: 1)
print(describe(vending: r1))
print(describe(vending: r2))
if case .success(let change) = r1 { precondition(change == 2) }
if case .failure(.insufficientFunds(let needed, _)) = r2 { precondition(needed == 3) }

// ═══ 12.4 typed throws：错误类型进签名
do {
    let score = try parseScore("88")
    print("分数 \(score)")
    precondition(score == 88)
} catch ScoreError.invalid(let text) {
    print("非法输入：\(text)")
}
// typed throws 下 catch 的 error 已是 ScoreError，不需要 as? 转换
do {
    _ = try parseScore("abc")
} catch {
    let e = error  // 编译器已知是 ScoreError
    precondition(e == ScoreError.invalid(text: "abc"))
    print("typed catch：\(e)")
}

// ═══ 12.5 try? / try!
precondition(safeScore("42") == 42)
precondition(safeScore("-1") == nil)
precondition(try! parseScore("100") == 100)  // 确知合法才用 try!

// ═══ 12.6 rethrows
if let ints = try? transformAll(["1", "2"], { try parseScore($0) }) {
    precondition(ints == [1, 2])
}
do {
    let ints = try transformAll(["1", "x"], { try parseScore($0) })
    print("不应到达：\(ints)")
} catch ScoreError.invalid(let text) {
    print("rethrows 透传：\(text) 非法")
}
// map 本身就是 rethrows 的——传不抛错的闭包时连 try 都不用写
let plain = transformAll(["3"], { Int($0)! })
precondition(plain == [3])

// ═══ 12.7 错误分层演示
print(mustBePositive(5))
// mustBePositive(-1)  // 取消注释 = 立即崩溃：契约违反不给恢复机会

print("==== 12 结束 ====")
