val json: dynamic = JSON.parse("""{"name": "Alice", "age": 25}""")

// 动态访问属性
println(json.name)  // Alice
println(json.age)   // 25

// 动态调用方法
json.sayHello()
