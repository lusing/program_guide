// Bridging.h —— Swift 侧的「桥接头」
//
// Xcode 新建 OC 文件时会问你要不要创建它；命令行编译则要用
//   swiftc -import-objc-header Bridging.h
// 显式指定。凡是在这个文件里 #import 的 OC 头文件，对工程里所有 Swift 文件可见。

#import "Greeter.h"
#import "ObjcCaller.h"
