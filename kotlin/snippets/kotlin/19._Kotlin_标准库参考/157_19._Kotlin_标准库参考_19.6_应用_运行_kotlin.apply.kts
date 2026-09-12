data class Person(var name: String = "", var age: Int = 0)

// apply
val person = Person().apply {
    name = "Alice"
    age = 25
}

// with
val builder = StringBuilder().apply {
    append("Hello")
    append(" ")
    append("World")
}

// run
val result = run {
    val x = 10
    val y = 20
    x + y
}

// let
val input: String? = "Hello"
input?.let {
    println("Length: ${it.length}")
}

// also
val list = mutableListOf(1, 2, 3)
    .also { println("Original: $it") }
    .add(4)
    .also { println("After add: $it") }

// use
bufferedReader().use { reader ->
    reader.forEachLine { println(it) }
}
