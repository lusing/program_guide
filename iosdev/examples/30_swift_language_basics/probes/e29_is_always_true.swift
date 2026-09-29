import Foundation

// is / as? 也有「编译器已经知道答案」的情况：静态类型保证了的事情，运行时检查反而是错的写法。
class Animal { func breathe() {} }
class Birds: Animal {}
let zoo: [Animal] = [Birds()]
print(zoo[0] is Animal)
print(zoo[0] is Birds)
