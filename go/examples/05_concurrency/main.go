package main

import (
    "fmt"
    "time"
)

func worker(id int) {
    fmt.Println("worker", id, "start")
    time.Sleep(200 * time.Millisecond)
    fmt.Println("worker", id, "done")
}

func main() {
    for i := 0; i < 3; i++ {
        go worker(i)
    }
    time.Sleep(800 * time.Millisecond)
    fmt.Println("all workers finished")
}
