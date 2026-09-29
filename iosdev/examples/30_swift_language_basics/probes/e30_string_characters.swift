import Foundation

// 这本书基于 Swift 4，而 Swift 5 删掉了 String 的 characters 视图（书 5.x/6.x 里不少写法踩这一刀）。
let s = "幸福巷4号"
print(s.count)
print(s.characters.count)
