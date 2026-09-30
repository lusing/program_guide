import Foundation

// Swift 的两阶段初始化：自己的存储属性必须在 super.init() **之前**填好，
// 继承来的属性必须在 super.init() **之后**才能读写。书 9.6 只讲了 convenience 的顺序，
// 没讲 designated 与 super.init 的先后。这里故意把两行放错位置。
class CarBase {
    var colour = "Black"
    init() {}
}
class NeedsDest: CarBase {
    var destination: String
    init(to: String) {
        super.init()
        destination = to               // 错 1：自己的属性填在 super.init() 之后
        print(colour)                  // 错 2：这行本身合法，只是用来说明「继承的属性要等到这之后」
    }
}
print(NeedsDest(to: "幸福巷4号").destination)
