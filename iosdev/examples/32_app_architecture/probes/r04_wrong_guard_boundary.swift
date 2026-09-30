// 探针 r04：书 7.13 步骤 5 那句「只需将之前的13修改为29即可」漏改一处的下场
//
// 主线 §29 数过：那句话在代码里是**三处**字面量（守卫里的 28、除法里的 29、
// progressLabel 里那个字符串），它们说的是同一件事（题库有几条），却互不相干。
// 这一支量「漏改守卫」那一处的现场：控制器一行没改，换上一份 13 道的题库，
// 答满 13 题之后 `13 <= 28` 依然放行，于是 nextQuestion() 去读 list[13]。
//
// 请注意它崩的位置：这份代码有守卫，7.8 那句修法**在**，守卫也**对**——
// 它只是对另一份题库成立。这是本章 §9「抄来的边界」那条结论最贵的一种形态：
// 抄来的数不会跟着源头动，而编译器与运行时都不知道那个数本该是几。
//
// 跑法：bash probes/run.sh r04（现场与 r01 同一类：退出码 132 = signal 4，stderr 里那一句一模一样）
import Foundation

setvbuf(stdout, nil, _IONBF, 0)

struct QuestionEQ {
    let questionText: String
    let questionOption: [String]
    let questionScore: [Int]
}

/// 一份 13 道的题库（控制器以为它 29 道）
func bank(_ n: Int) -> [QuestionEQ] {
    (1...n).map { QuestionEQ(questionText: "第\($0)题",
                             questionOption: ["是的", "不一定", "不是"],
                             questionScore: [6, 3, 0]) }
}

final class EQTestViewController {
    let allQuestions: [QuestionEQ]
    var pickedAnswer = -1
    var questionNumber = 0
    var score = 0

    init(allQuestions: [QuestionEQ]) { self.allQuestions = allQuestions }

    /// 书 7.13 步骤 5 说的就是把这里的 28 改成 29 —— 这一支故意不改。
    func nextQuestion() {
        if questionNumber <= 28 {
            print("屏幕上第 \(questionNumber + 1) 题：\(allQuestions[questionNumber].questionText)")
        } else {
            print("弹框：全部答完")
        }
    }

    func checkAnswer() {
        score += allQuestions[questionNumber].questionScore[pickedAnswer]
    }

    func answerPressed(tag: Int) {
        pickedAnswer = tag - 1
        checkAnswer()
        questionNumber += 1
        nextQuestion()
    }
}

let vc = EQTestViewController(allQuestions: bank(13))
for _ in 0..<13 { vc.answerPressed(tag: 1) }   // 十三道题答完，游标到 13，守卫还在放行
print("跑到了这里：questionNumber = \(vc.questionNumber)")
