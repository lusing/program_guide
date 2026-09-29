import Foundation

// 书 11.3：「如果函数的最后一个参数是闭包，则可以先删除参数名称，再把闭包移到括号外面」。
// 反过来问：闭包挪出去之后，还能在它后面补一个普通参数吗？
func withClosureFirst(_ body: () -> Int, then label: String) -> String { return label + String(body()) }
print(withClosureFirst { 42 } then: "答案 = ")
