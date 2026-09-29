// ============================================================
// 28 章 · ObjC 侧收集器对 Swift 暴露的接口
//
// 每个函数返回「已经排好版的一节」，Swift 侧只加小节标题再逐行打印。
// 之所以让 OC 拼字符串而不是 Swift：这些行里的数字全是 C 量的，
// 而格式化的规则（「| 分隔」「不打印指针」「中文用 %@」）在 OC 侧和 27 章保持一致更好维护。
// ============================================================
#import <Foundation/Foundation.h>

#import "CLTypes.h"   // CLOpaqueRef 要出现在下面的方法签名里

NS_ASSUME_NONNULL_BEGIN

/// §17 用的 ObjC 侧类型：把「返回码 + 出参」的 C 约定包成 ObjC 的 BOOL + NSError **。
/// 声明放在头文件里，Swift 才看得见它（§22 那一节的 throws 就是它）。
@interface CLCStyleAPI : NSObject
+ (BOOL)readSeedOfHandle:(nullable CLOpaqueRef)handle
                    seed:(out int * _Nullable)outSeed
                   error:(out NSError * _Nullable * _Nullable)outError;
@end


/// §1 数据类型：尺寸、范围、转换
NSArray<NSString *> *CLLinesTypes(void);
/// §2 运算符与控制语句
NSArray<NSString *> *CLLinesOperators(void);
/// §3 数组：连续内存与退化
NSArray<NSString *> *CLLinesArrays(void);
/// §4 字符数组与 C 字符串
NSArray<NSString *> *CLLinesStrings(void);
/// §5 指针运算
NSArray<NSString *> *CLLinesPointers(void);
/// §6 出参与二级指针
NSArray<NSString *> *CLLinesOutParams(void);
/// §7 结构体布局与对齐
NSArray<NSString *> *CLLinesStructs(void);
/// §8 联合体与浮点位模式
NSArray<NSString *> *CLLinesUnions(void);
/// §9 枚举
NSArray<NSString *> *CLLinesEnums(void);
/// §10 不透明句柄
NSArray<NSString *> *CLLinesHandles(void);
/// §11 函数、值传递与递归
NSArray<NSString *> *CLLinesFunctions(void);
/// §12 可变参数
NSArray<NSString *> *CLLinesVarargs(void);
/// §13 函数指针与回调表
NSArray<NSString *> *CLLinesFuncPointers(void);
/// §14 memcpy / memmove
NSArray<NSString *> *CLLinesMemoryBlocks(void);
/// §15 malloc 家族
NSArray<NSString *> *CLLinesMalloc(void);
/// §16 宏
NSArray<NSString *> *CLLinesMacros(void);
/// §17 C 与 Objective-C 的边界
NSArray<NSString *> *CLLinesInterop(void);

NS_ASSUME_NONNULL_END
