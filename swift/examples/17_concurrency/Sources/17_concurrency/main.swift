// 17 · 并发 I——async/await、结构化并发（async let / TaskGroup）、取消、AsyncStream

import Foundation

// ═══ 17.1 纯函数区（供测试）：模拟 IO 用固定值（确定性纪律：不依赖真实时序）
enum City {
    static let temperatures = ["北京": 2, "上海": 12, "成都": 9, "广州": 21, "哈尔滨": -8]
}

func fetchTemperature(city: String) async -> Int {
    City.temperatures[city] ?? 0  // 模拟一次网络往返：真实代码这里 await 网络调用
}

func averageTemperature(cities: [String]) async -> Double {
    guard !cities.isEmpty else { return 0 }
    var total = 0
    for city in cities {
        total += await fetchTemperature(city: city)  // 逐个 await：串行
    }
    return Double(total) / Double(cities.count)
}

/// async let：两个"同时起步"的异步绑定，await 时收结果
func pairSum(cityA: String, cityB: String) async -> Int {
    async let a = fetchTemperature(city: cityA)  // 起跑
    async let b = fetchTemperature(city: cityB)  // 起跑（与 a 并发）
    return (await a) + (await b)  // 收账（await 在运算符右侧必须加括号）
}

/// TaskGroup：任意数量子任务并发，结果聚合
func gatherTemperatures(cities: [String]) async -> [(city: String, temp: Int)] {
    await withTaskGroup(of: (String, Int).self) { group in
        for city in cities {
            group.addTask { (city, await fetchTemperature(city: city)) }  // 每城一个子任务
        }
        var results: [(city: String, temp: Int)] = []
        for await (city, temp) in group {  // 谁先完成先收谁
            results.append((city, temp))
        }
        return results.sorted { $0.temp < $1.temp }  // 完成顺序不定 → 按温度排序保证输出确定
    }
}

/// 协作式取消：任务在检查点自觉退出
func countdown(from start: Int) async -> String {
    let task = Task { () -> String in
        var visited = 0
        for i in stride(from: start, through: 1, by: -1) {
            if Task.isCancelled {  // 检查点：取消是请求，配合靠自觉
                return "在第 \(visited) 步被取消（走完 \(i) 前）"
            }
            visited += 1
        }
        return "跑完全程 \(visited) 步"
    }
    task.cancel()  // 同一 actor 上：先请求取消，再 await——body 首个检查点必命中
    return await task.value
}

/// 跑完不取消的对照
func countdownUncancelled(from start: Int) async -> String {
    let task = Task { () -> String in
        var visited = 0
        for i in stride(from: start, through: 1, by: -1) {
            if Task.isCancelled { return "被取消" }
            visited += 1
        }
        return "跑完全程 \(visited) 步"
    }
    return await task.value
}

/// AsyncStream：异步序列（生产者-消费者的字面量）
func numberStream(_ n: Int) -> AsyncStream<Int> {
    AsyncStream { continuation in
        for i in 1...n {
            continuation.yield(i)
        }
        continuation.finish()
    }
}

// ═══ 17.2 await 的基本形态（main.swift 顶层可以直接 await）
let beijing = await fetchTemperature(city: "北京")
print("北京 \(beijing)°C")
precondition(beijing == 2)

let avg = await averageTemperature(cities: ["北京", "上海", "成都"])
print("三城平均 \(avg)°C")
precondition(avg == Double(2 + 12 + 9) / 3)

// ═══ 17.3 async let：并发起步、await 收账
let sum = await pairSum(cityA: "广州", cityB: "哈尔滨")
print("广州+哈尔滨 = \(sum)°C")
precondition(sum == 13)

// ═══ 17.4 TaskGroup：动态数量的并发
let gathered = await gatherTemperatures(cities: ["北京", "上海", "成都", "广州", "哈尔滨"])
print("五城聚合（按温度排序）：\(gathered.map(\.temp))")
precondition(gathered.map(\.temp) == [-8, 2, 9, 12, 21])
precondition(gathered.first?.city == "哈尔滨")  // 最冷的城市排第一

// ═══ 17.5 取消：协作式，检查点决定退出时机
let cancelledResult = await countdown(from: 100)  // 立刻取消 → 第 0 步被取消
let fullResult = await countdownUncancelled(from: 5)  // 不取消 → 跑完全程
print(cancelledResult)
print(fullResult)
precondition(cancelledResult.contains("被取消"))  // precondition 不吃 await，先求值再断言
precondition(fullResult == "跑完全程 5 步")

// ═══ 17.6 AsyncStream：for await 遍历异步序列
var streamed: [Int] = []
for await n in numberStream(5) {
    streamed.append(n)
}
print("AsyncStream 收到：\(streamed)")
precondition(streamed == [1, 2, 3, 4, 5])

print("==== 17 结束 ====")
