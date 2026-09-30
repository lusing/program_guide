import Foundation
class Holder {
    var stored: (() -> Void)?
    func set(_ completion: @escaping () -> Void) { stored = completion }
    func run() { stored?() }
}
let hh = Holder()
hh.set { print("captured") }
hh.run()
