// RTDyn.m 里的转发链要用 RTMsg.m 提供的那个 IMP 生成工具：
// 它是 C 函数，跨 .m 文件用必须有个声明（否则 clang 会抱怨隐式声明）。
#import <Foundation/Foundation.h>

IMP RTForwardingIMP(SEL sel);
