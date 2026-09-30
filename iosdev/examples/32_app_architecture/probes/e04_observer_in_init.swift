// 探针 e04：观察者不能写在 init 里 —— 这一条要等类型检查全过了才轮到它说话
//
// 主线 §3 量的是运行时那一半：给 var 属性挂 didSet，init 里那两次赋值一次都不触发
// （初始化阶段的写入直接落进存储，不走 setter）。于是想「把出厂值也抓到」的人会试
// 一条更直接的路：**在 init 里就把这个对象交给观察者**。
// 这一支抄的是那条路的原文 —— 注意它错在哪：不是「didSet 不触发」，
// 而是 self 根本还没交出来（闭包会逃逸到属性上，它抓的是一个尚未初始化完的对象）。
//
// 顺带记一件与编译器本身有关的事（也是这一族探针的形状为什么是这样）：
// 上面那条错误出自 **SIL 生成期**的 definite-initialization 检查。它要两个条件才说话：
//   · 这个 init 真的会被发射 —— 所以下面必须构造一次，只声明不用的文件一声不吭；
//   · 类型检查那一关先过 —— 同一个文件里只要还留着 e03 那种类型错误，它就根本不打印。
// 于是 probes/run.sh 对 eNN 做了两遍：先 -typecheck（快），若它放过了再完整编一遍。
// 记录里那行「（-typecheck 一声不吭：再用完整编译问一遍）」不是脚本的废话，
// 它标的正是「这条诊断属于哪一遍检查」。
//
// 跑法：bash probes/run.sh e04
import Foundation

final class ObserverRegistersSelf {
    var questionText: String
    var answer: Bool
    var onChange: ((ObserverRegistersSelf) -> Void)?

    init(text: String, correctAnswer: Bool) {
        questionText = text
        // 观察者「现在」就登记：闭包会逃逸（存在属性上），而 self 此刻还没交出来。
        onChange = { model in print(model.questionText, self.answer) }
        answer = correctAnswer
    }
}

// 这一句不是多余的：上面那条错误出自 SIL 生成期的 definite-initialization 检查，
// 它只在**这个 init 真的会被发射**时才说话。只声明不用它的文件，编译器一声不吭
// （探针里刻意留了这一格：一条诊断的存在条件本身就是它的性质的一部分）。
let model = ObserverRegistersSelf(text: "吃烧烤不能喝啤酒。", correctAnswer: true)
model.onChange?(model)
