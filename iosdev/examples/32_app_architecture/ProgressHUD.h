// ============================================================
// 书 7.12「合并 Objective-C 代码到 Swift」里从 GitHub 拖进来的那个第三方库 ——
// 这一份是**同 API 形状的手写替身**（原文是 relatedcode/ProgressHUD）。
//
// 为什么要替身：本章不能联网 clone，也不该把别人的 MIT 源码抄进这个仓库，
// 而 §30 要量的从来不是 HUD 怎么画，是「一份 OC 代码进了 Swift 工程之后，
// 两侧各看到什么」—— 桥接头、方法名转换、可选性、单例、以及 OC 反过来调 Swift。
// 这五件事都在下面这十几行声明里。
//
// 请注意第一个类**没有**被 NS_ASSUME_NONNULL_BEGIN/END 包住，而第二个类包住了。
// 这不是遗漏，是对照组：同一份 API 在 Swift 里长成 `String!` 还是 `String`，
// 只差头文件里那两行宏（§30 量运行后果，探针 m01 量编译器那一半）。
//
// 那三个 `_Null_unspecified` 是本仓库的**唯一**写法可行的地方：书 7.12 开头说
// 「你可能会遇到一些与这个库有关的黄色叹号警告……它们并不会影响应用程序的功能」，
// 而这条告警（`-Wnullability-completeness`，原文在探针 m01 与 build/*.log 里）在
// run-all.sh 的判定 1 那里就是硬失败 —— 「不影响功能」的告警在这个工程流程里是不被
// 允许的。注意它的**触发条件不是「没标」**：m03 实测一份从头到尾不标的头文件可以
// 一声不响地编过（swiftc 日志为空、退出码 0），响的是「标了一半」。所以这里选第三种
// 写法：宏一个不写、每个指针手着标 —— 它和「什么都不写」在 Swift 侧给出**同一个类型**
// （隐式解析可选），和「全套 NS_ASSUME_NONNULL」一样安静，却保留了「这参数我不敢保证」
// 的原意。这就是这一节要量的那道题。
// ============================================================

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - 未声明 nullability 的那一半（书里那个库就是这个样子）

@interface ProgressHUD : UIView

/// 书 7.12 步骤 1~4 拖进来的就是这几个类方法。参数标的是 `_Null_unspecified`
/// （= 「我不知道它能不能为 nil」），Swift 侧因此看到 `String!`，而不是 `String`。
+ (void)show;
+ (void)showSuccess:(NSString *_Null_unspecified)success;
+ (void)showError:(NSString *_Null_unspecified)error;
+ (void)dismiss;

/// 本章加的读数口（原库没有）：把「弹了一次 HUD」变成读得回来的数组。
/// 返回类型同样未指定，Swift 侧是 `[String]!`。
+ (NSArray *_Null_unspecified)history;
+ (void)reset;

/// 「HUD 现在真的在屏幕上吗」——裸进程里它永远不在，但调用一律「成功」（§30）。
+ (BOOL)onScreen;

/// 库内部那个单例：两次取回的是同一个对象（§30 用 === 量）。
/// `instancetype` 也会触发同一条告警 —— 它展开出来就是个指针，所以这里也得写 _Nonnull：
/// 「未指定」只管参数和返回值里那几个 NSString *，单例这种「一定拿得到」的东西不该跟着躺平。
+ (instancetype _Nonnull)shared;

@end

#pragma mark - 声明了 nullability 的那一半（书里那句「去除警告」的答案）

// Xcode 对没有 nullability 的第三方头文件给的那条黄色叹号警告，正解就是在这里补上
// 这两行宏。补上之后，下面这些方法在 Swift 里的参数类型变成非可选的 String ——
// 传 nil 在**编译期**就被拒绝（原文见探针 e08）。
NS_ASSUME_NONNULL_BEGIN

@interface ProgressHUDStrict : UIView

+ (void)show;
+ (void)showSuccess:(NSString *)success;
+ (void)showError:(NSString *)error;
+ (void)dismiss;
+ (NSArray<NSString *> *)history;
+ (void)reset;
+ (BOOL)onScreen;
+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
