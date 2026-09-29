import Foundation
class VC {
    func notePressed() { let selectedSoundFileName = "note1"; print(selectedSoundFileName) }
    func playSound() { print(selectedSoundFileName) }
}
print(VC().notePressed())
