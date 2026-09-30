// 探针 e07：UIAlertAction 上读不回 handler —— §24/§25 那份「自己存一份闭包」的凭据
//
// 主线 §25 的断言是：那颗「重新开始」按钮**真正做的事**存在一个闭包里，
// 而闭包在 UIAlertAction 上是读不回来的，所以 QuizViewController 在把闭包递给
// UIKit 之前先自己存了一份（`restartHandler`），主线调的是那一份。
// 「读不回来」这件事在原书里没有对应内容（书里判据是「点了按钮界面就重置了」），
// 它的凭据就是这一条编译器原文。
//
// 上面那三行量的就是「UIAlertAction 到底让你读回什么」：title、isEnabled 都在成员列表里
// （主线 §24 连 style 的 rawValue 也读回来了），唯独 handler 不在 ——
// 这一条编译器原文就是 §25 那份「自己存一份闭包」的凭据。
// 这个不对称正是 §25 那句话的形状：按钮的**外观**在 UIKit 那边，
// 按钮的**行为**只在递给它的那个闭包里，而那个闭包没有回头的入口。
//
// 跑法：bash probes/run.sh e07
import UIKit

let action = UIAlertAction(title: "重新开始", style: .default) { _ in }

print(action.title ?? "nil")
print(action.isEnabled)
print(action.handler)
