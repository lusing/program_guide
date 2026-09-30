import Foundation

// 闭包捕获的是**变量本身**，不是写下的那一刻的值（书 11.3 没讲，11.4 的「完成处理」全靠它）。
// 三段对照：外部 var / for 的循环变量 / while 的共享变量。
var log: [String] = []
var counter = 0

func delayed() { log.append("读到 counter=\(counter)") }
delayed()                      // 0 —— 捕获的是变量，调用时才读
counter = 7
delayed()                      // 7 —— 同一个闭包，读到的已经是新值
print("外部 var：写完才调 → \(log)")

log.removeAll(keepingCapacity: true)
var perRound: [() -> Void] = []
for i in 0..<3 { perRound.append { log.append("i=\(i)") } }
for f in perRound { f() }
print("for 的循环变量：每轮一个独立的 i → \(log)")

log.removeAll(keepingCapacity: true)
var j = 0
var shared: [() -> Void] = []
while j < 3 { shared.append { log.append("j=\(j)") }; j += 1 }
for f in shared { f() }
print("while 的变量被三轮共享：三个闭包读同一个 j → \(log)")
