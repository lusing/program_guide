package main

import "fmt"

func add(a int, b int) int {
    return a + b
}

func main() {
    fmt.Println("5 + 7 =", add(5, 7))
    fmt.Println("9 * 3 =", multiply(9, 3))
}

func multiply(a int, b int) int {
    return a * b
}
