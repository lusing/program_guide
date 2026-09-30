import Foundation

/// 资源这一侧的全部事实都要靠运行时回读：Package.swift 里那两行 `.copy` / `.process`
/// 到底把文件放成了什么形状，只有把 bundle 目录走一遍才知道（主线 §16 那两行断言）。
public struct BundleLayout {
    /// bundle 目录**自己**那一层的名字（父路径里带着 debug/release，不能进主线输出）。
    public let bundleName: String
    /// 从 bundle 根开始、排过序的相对路径清单。
    public let entries: [String]
    public let cityJSON: String
}

/// 把 bundle 走一遍，返回排序后的相对路径；目录本身也记一格（结尾带斜杠）。
private func walk(_ url: URL, prefix: String) -> [String] {
    var out: [String] = []
    let items = (try? FileManager.default.contentsOfDirectory(
        at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
    for item in items.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        let name = prefix + item.lastPathComponent
        out.append(isDir ? name + "/" : name)
        if isDir { out.append(contentsOf: walk(item, prefix: name + "/")) }
    }
    return out
}

public func bundleLayout() -> BundleLayout {
    let bundle = Bundle.module
    var json = "missing"
    if let url = bundle.url(forResource: "city", withExtension: "json"),
       let data = try? Data(contentsOf: url) {
        json = String(decoding: data, as: UTF8.self)
            .components(separatedBy: CharacterSet(charactersIn: " \n\t{}\"")).filter { !$0.isEmpty }
            .joined(separator: "|")
    }
    return BundleLayout(
        bundleName: bundle.bundleURL.lastPathComponent,
        entries: walk(bundle.bundleURL, prefix: ""),
        cityJSON: json)
}

/// 取一个包里的常量：证明「资源跟着 target 走，不跟着 product 走」——
/// 主线 import 的是 WeatherKit，读到的却是这份 JSON。
public func cityOffset() -> Int {
    guard let url = Bundle.module.url(forResource: "city", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let offset = object["offset"] as? Int else { return -1 }
    return offset
}

/// 给探针 s13 开的一扇 public 的窗：`Bundle.module` 是 SwiftPM 生成在**这个 target 内部**
/// 的 `static let`，默认 internal，模块外一行都写不了（那条原文由探针 c02 抄）。
/// 于是「两个候选路径里命中了哪一个」这件事，外部唯一能看到的方式就是这个返回值本身 ——
/// 它要么指向可执行文件旁边那份，要么指向编译时写死在二进制里的那个构建目录绝对路径。
public func moduleBundlePath() -> String { Bundle.module.bundlePath }
