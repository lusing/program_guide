extends SceneTree

func add(a: int, b: int) -> int:
    return a + b

func multiply(a: int, b: int) -> int:
    return a * b

func _initialize():
    print("7 + 5 = ", add(7, 5))
    print("6 * 8 = ", multiply(6, 8))
    quit()
