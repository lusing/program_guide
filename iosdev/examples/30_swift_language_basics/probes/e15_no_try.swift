import Foundation
enum E: Error { case bad }
func risky() throws { throw E.bad }
do { risky() } catch { print(error) }
