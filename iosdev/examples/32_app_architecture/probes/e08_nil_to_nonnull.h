// e08 用的是主线那份真头文件：ProgressHUDStrict 的参数在 NS_ASSUME_NONNULL 里，
// 所以 Swift 侧的参数类型是非可选的 String —— 这一支要的那条 error 就来自这里。
#import "../ProgressHUD.h"
