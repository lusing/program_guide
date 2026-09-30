// Swift → OC 的桥接头：书 7.12 步骤 4 里 Xcode 弹出的那个对话框按「Create Bridging
// Header」之后生成的就是这一个文件，而书里紧接着做的唯一一件事是在里面敲一行
// `#import "ProgressHUD.h"` —— 这一行的作用是「告诉 Swift 项目哪个文件是 OC 的代码」。
//
// 这里是本仓库的等价物：run-all.sh 看到示例目录里有 Bridging.h，就给 swiftc 传
// -import-objc-header（见脚本头部的混编说明）。这里 #import 的 OC 头，对整个
// Swift 模块的**每一个** .swift 文件都可见 —— 不是只能被某个文件用，也没有 import 语句可写。
#import "ProgressHUD.h"
