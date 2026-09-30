import Foundation
import AVFoundation
let url = Bundle.main.url(forResource: "note1", withExtension: "wav")
print("url = \(String(describing: url))")
do {
    let p = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/tmp/definitely-not-here.wav"))
    print("player = \(String(describing: p))")
} catch {
    print("catch: \(error)")
    print("catch: \((error as NSError).domain) code=\((error as NSError).code)")
}
let q = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/tmp/nope2.wav"))
print("try? = \(String(describing: q))")
