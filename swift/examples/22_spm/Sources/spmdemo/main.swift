// spmdemo：可执行壳——参数解析 + 调库 + 输出（逻辑全在 MiniLib，壳保持薄）
import Foundation
import MiniLib

let args = CommandLine.arguments
guard args.count == 3,
    let w = Double(args[1]),
    let h = Double(args[2])
else {
    print("用法：spmdemo <宽> <高>")
    print("例如：spmdemo 3 4")
    exit(2)  // 用法错误：exit 2（约定俗成，24 章的退出码家族）
}

do {
    let rect = try makeRect(width: w, height: h)
    print("矩形 \(w)×\(h)：面积 \(rect.area)，周长 \(rect.perimeter)，正方形？\(rect.isSquare)")
    let demo = [rect, Rect(width: 1, height: 1), Rect(width: 2, height: 2)]
    print("三块合计面积：\(totalArea(demo))")
    print("==== 22 结束 ====")
} catch let GeometryError.negativeDimension(name) {
    print("尺寸不能为负：\(name)")
    exit(1)  // 运行失败：exit 1
}
