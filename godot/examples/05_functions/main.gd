extends SceneTree

func add(a: int, b: int) -> int:
    return a + b

func apply_potion(target: String, amount := 10) -> String:
    return "%s 恢复了 %d HP" % [target, amount]

var square := func(x: int) -> int:
    return x * x

func factorial(n: int) -> int:
    if n <= 1:
        return 1
    return n * factorial(n - 1)

func _initialize():
    print("7 + 5 = ", add(7, 5))
    print(apply_potion("Alice"))
    print(apply_potion("Bob", 25))
    print("6 的平方 = ", square.call(6))
    print("5! = ", factorial(5))

    var ops := [add, factorial]
    for op in ops:
        print("Callable 名：", op)
    quit()
