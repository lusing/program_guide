import Foundation

// 逃逸闭包（@escaping）里能不能省略 self？和非逃逸闭包放在一起对照，两行都不带 self。
class Holder {
    var tag = "车钥匙"
    var stored: (() -> Void)?
    func setEscaping(_ body: @escaping () -> Void) { stored = body }
    func setNonEscaping(_ body: () -> Void) { body() }
    func demo() {
        setNonEscaping { print(tag) }
        setEscaping { print(tag) }
    }
}
Holder().demo()
