import Foundation
class Holder {
    var stored: (() -> Void)?
    func set(_ completion: () -> Void) { stored = completion }
}
print(Holder().set {})
