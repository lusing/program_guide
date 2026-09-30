// 探针 r02：书 7.13 步骤 3 那句 `sender.tag - 1`，忘了填 tag 的那一颗
//
// 主线 §16 与 §26 各断言了一次「tag 出厂是 0，减一得 -1，下标运算当场越界」，
// 并且都写明了「编译器拦不住，因为 tag 的类型是 Int，不是『合法下标』」。
// 这一支就是那一下的现场：唯一的输入是**一个没被填过的 tag**。
//
// 值得看的是崩溃消息本身：负数下标和「超出末尾」的下标报的是同一句话
// （`Fatal error: Index out of range`），运行时并不告诉你它越的是哪一边 ——
// 也就是说，「数组下标」这个概念在 Swift 里是**一个**检查，不是两个。
//
// 跑法：bash probes/run.sh r02（现场与 r01 同一类：退出码 132 = signal 4，stderr 里那一句一模一样）
import Foundation

setvbuf(stdout, nil, _IONBF, 0)

// 书 7.13 的 Model：选项是数组、分值是数组、答案是这一档的分值
struct QuestionEQ {
    let questionText: String
    let questionOption: [String]
    let questionScore: [Int]
}

// 一颗在故事板里忘了填 tag 的按钮（UIButton.tag 的出厂值就是 0）
let untaggedTag = 0
let question = QuestionEQ(questionText: "你的情商很高。",
                          questionOption: ["是的", "不一定", "不是"],
                          questionScore: [6, 3, 0])

print("tag = \(untaggedTag)，减一得到下标 \(untaggedTag - 1)")
print("这一题有 \(question.questionScore.count) 档分值：\(question.questionScore)")
let picked = question.questionScore[untaggedTag - 1]     // ← 这一行是这一支要量的
print(" picked = \(picked)")
