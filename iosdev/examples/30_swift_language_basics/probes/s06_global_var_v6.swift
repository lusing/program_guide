import Foundation
var counter = 0
func bump() { counter += 1 }
bump(); bump()
print(counter)
