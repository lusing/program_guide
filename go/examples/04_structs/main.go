package main

import "fmt"

type Person struct {
    Name string
    Age  int
}

func (p Person) Greet() string {
    return fmt.Sprintf("Hello, %s (%d)", p.Name, p.Age)
}

func main() {
    p := Person{Name: "Alice", Age: 30}
    fmt.Println(p.Greet())
}
