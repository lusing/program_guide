// 探针 e01：书 7.2 第一版那个「会报错，如图 7-8」到底报在哪一行
//
// 书 7.2 依次给了三个版本，第一个是两个 `let` 光写着、没有初值也没有 init：
//     class Question {
//         let questionText: String
//         let answer: Bool
//     }
// 正文说「这段代码会报错」。这一节要量的不是「有没有错」，而是**红点落在哪一行** ——
// 因为「排查方向」这件事就藏在这里：如果报错指着类声明，人会去改属性；
// 如果它指着构造那一行，人才会去想「是谁在没给值的情况下造了这个类型」。
//
// 跑法：bash probes/run.sh e01（eNN 族只 -typecheck，不产二进制、不运行）
import Foundation

class Question {
    let questionText: String
    let answer: Bool
}

// 书 7.4 的 QuestionBank 里就是这一句在造对象：
let q = Question()
print("q.questionText = \(q.questionText)")
