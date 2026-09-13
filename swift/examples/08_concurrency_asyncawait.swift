import Foundation

func delayedValue() async -> Int {
    try? await Task.sleep(nanoseconds: 150_000_000)
    return 2026
}

let semaphore = DispatchSemaphore(value: 0)

Task {
    async let a = delayedValue()
    async let b = delayedValue()
    let sum = await a + b
    print("sum =", sum)
    semaphore.signal()
}

semaphore.wait()
