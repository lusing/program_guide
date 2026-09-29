// 27 章的桥接头：Swift 侧要能直接叫出 OC 采集器的名字。
//
// 混编方向是单向的 —— OC 不需要知道任何 Swift 类型（所以本示例没有 Needs-Swift-Header 哨兵文件），
// 只有 Swift 需要看见 RTRuntime.h 里那一排 C 函数。这本身就是本章的一个结论：
// 「Swift 调 ObjC」是走 runtime，「ObjC 调 Swift」才需要编译器吐一个 -Swift.h。
#ifndef RT27_BRIDGING_H
#define RT27_BRIDGING_H

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "RTRuntime.h"

#endif
