// ============================================================
// 28 章 · Swift 的桥接头
//
// 三行全是「把 C 侧的声明交给 Swift」：
//   CLTypes.h   —— C 的类型与函数（Swift 直接看见 struct/enum/函数指针 typedef）
//   CLMacros.h  —— 故意也 include 进来：好让「对象式宏能看见、函数式宏看不见」这条在 §22 可测
//   CLCollect.m —— ObjC 侧收集器，Swift 只管打印
// 这一章不需要反向头（Swift 没有被 .m 调用的东西），所以没有 Needs-Swift-Header。
// ============================================================
#ifndef CLBridging_h
#define CLBridging_h

#import "CLTypes.h"
#import "CLMacros.h"
#import "CLCollect.h"

#endif /* CLBridging_h */
