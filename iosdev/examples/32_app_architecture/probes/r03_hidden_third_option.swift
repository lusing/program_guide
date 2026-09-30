// 探针 r03：二选一的那一题上调用第三颗按钮 —— `isHidden` 挡住的是手，挡不住方法调用
//
// 主线 §28 有一条刻意**不执行**的断言：第 2 题只有两个选项（第三颗按钮 isHidden = true），
// 而它的 tag 仍然写着 3，减一 = 2，`questionScore[2]` 出界。
// 真实 App 里用户摸不到那颗按钮（裸进程里 sendActions 本来也不派发，第 31 章 §16），
// 所以这一支量的是**代码路径**：任何一次直接调用 answerPressed(buttonThree) 都会走到这里，
// 判卷层从头到尾不知道屏幕上少了一颗按钮。
//
// 这一支与 r02 的分别是重点：同一句 `questionScore[tag - 1]`，
// 崩与不崩取决于「题库里这一题恰好有几档」，而视图层是按这个数在摆按钮的。
//
// 跑法：bash probes/run.sh r03（现场与 r01 同一类：退出码 132 = signal 4，stderr 里那一句一模一样）
import Foundation

setvbuf(stdout, nil, _IONBF, 0)

struct QuestionEQ {
    let questionText: String
    let questionOption: [String]
    let questionScore: [Int]
}

// 书 7.13 步骤 3：29 道题里「有一部分是二选一，还有一部分是三选一」
let bank = [
    QuestionEQ(questionText: "第1题", questionOption: ["是的", "不一定", "不是"], questionScore: [6, 3, 0]),
    QuestionEQ(questionText: "第2题", questionOption: ["是的", "不一定"], questionScore: [6, 3]),
]

/// 控制器里那句判卷：它的输入只有「第几颗按钮」，没有「屏幕上有几颗按钮」。
func score(for question: QuestionEQ, tag: Int) -> Int {
    question.questionScore[tag - 1]
}

print("第 1 题（三选一）按第三颗：\(score(for: bank[0], tag: 3)) 分 —— 同一条调用在三选一上是安全的")
print("第 2 题（二选一，第三颗按钮 isHidden=true）按第三颗：")
let got = score(for: bank[1], tag: 3)     // ← 这一支要量的就是这一行
print("  \(got)")
