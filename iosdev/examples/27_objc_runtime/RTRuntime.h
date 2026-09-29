// 27 章的 Objective-C 侧：所有「只有 runtime 才知道答案」的证据都在这里采集。
//
// 分工：本文件只声明「返回一列证据行」的 C 函数，实现分在三个 .m 里
// （RTMsg.m = §1~§5，RTDecl.m = §6/§7/§10/§11/§16/§17，RTDyn.m = §8/§9/§12~§15）；
// Swift 侧（main.swift）负责打印、断言，以及演示「Swift 类在 ObjC runtime 眼里长什么样」。
// 之所以不让 Swift 直接调 OC 方法：很多结论一旦经过 Swift 的类型检查就看不到了
// —— 例如「声明了但没实现」在 Swift 里根本编译不过，而在 ObjC 里是可以编译、运行时才崩。
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// §1 消息发送的真实形状：SEL 是什么、@selector 与 sel_registerName 的关系
NSArray<NSString *> *RTLinesSelectors(void);
/// §2 nil 接收者的返回值全表
NSArray<NSString *> *RTLinesNilReturns(void);
/// §3 IMP / methodForSelector / objc_msgSend 家族（含 x86_64 的 stret）
NSArray<NSString *> *RTLinesMsgSend(void);
/// §4 self / _cmd 两个隐藏参数
NSArray<NSString *> *RTLinesHiddenArgs(void);
/// §5 @encode 全表与方法类型编码（含参数偏移）
NSArray<NSString *> *RTLinesEncoding(void);
/// §6 属性在 runtime 里的三件套：访存方法 + ivar + 属性编码串
NSArray<NSString *> *RTLinesProperties(void);
/// §7 ivar 反射与关联对象
NSArray<NSString *> *RTLinesIvarsAndAssoc(void);
/// §8 消息转发的四级台阶与日志顺序
NSArray<NSString *> *RTLinesForwarding(void);
/// §9 换实现 / 换实现的两条路（交换 IMP 与直接 set）
NSArray<NSString *> *RTLinesSwizzle(void);
/// §10 分类：同名覆盖、+load 顺序、不能加 ivar
NSArray<NSString *> *RTLinesCategories(void);
/// §11 协议的运行时视图
NSArray<NSString *> *RTLinesProtocols(void);
/// §12 KVC：访问器/ivar 查找顺序、集合运算符
NSArray<NSString *> *RTLinesKVC(void);
/// §13 KVO：isa 改名、change 字典、直写 ivar、取消观察
NSArray<NSString *> *RTLinesKVO(void);
/// §14 内省方法清单：isKindOfClass / isMemberOfClass / respondsToSelector 家族
NSArray<NSString *> *RTLinesIntrospection(void);
/// §15 对象通信：目标-动作、委托、通知的 runtime 视角
NSArray<NSString *> *RTLinesCommunication(void);
/// §16 可变/不可变的类层级与 copy 的实际类
NSArray<NSString *> *RTLinesMutability(void);
/// §17 异常：@try/@catch 匹配、@finally、@throw 任意对象
NSArray<NSString *> *RTLinesExceptions(void);

/// 给 Swift 侧用：把一个任意对象丢进 runtime 里问几句（Swift 对象也能问）
Class _Nullable RTIsaOf(id obj);
/// Swift 侧的 @objc 交换实验需要 OC 提供「调一次这个方法」的通道
NSString *RTCallThroughObjC(id target, NSString *selectorName);

NS_ASSUME_NONNULL_END
