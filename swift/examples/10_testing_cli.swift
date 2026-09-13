func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

func runChecks() {
    precondition(add(1, 2) == 3, "add(1,2) should be 3")
    precondition(add(-1, 1) == 0, "add(-1,1) should be 0")
    print("checks passed")
}

runChecks()

let args = CommandLine.arguments
if args.count > 1 {
    print("extra args:", Array(args.dropFirst()))
} else {
    print("no extra args")
}

