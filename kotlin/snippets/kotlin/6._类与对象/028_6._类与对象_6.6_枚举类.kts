enum class Color {
    RED, GREEN, BLUE
}

enum class Status(val code: Int, val description: String) {
    SUCCESS(200, "OK"),
    NOT_FOUND(404, "Not Found"),
    ERROR(500, "Server Error")
}

val status = Status.SUCCESS
println(status.code)  // 200
