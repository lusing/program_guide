// 探针 e02：书 7.11 那三个 bug 里唯一「编译器会红一条」的那个
//
// 书 7.11 的原文顺序是：先写
//     scoreLabel.text = score
// 正文说「此时代码会报错，因为 scoreLabel 的 text 属性需要一个字符串，而 score 是整型」。
// 这一支量的是那句话的原文，以及一个容易被混掉的分工：
//   §10 那个「屏幕上少显示一道题」的 off-by-one 是**语义**错，编译器管不着；
//   这一条是**类型**错，编译器当场接管 —— 本章 §11/§15 分别引了这两类。
//
// 跑法：bash probes/run.sh e02
import UIKit

final class QuizViewController: UIViewController {
    let scoreLabel = UILabel()
    var score: Int = 0

    func updateUI() {
        scoreLabel.text = score
    }
}
