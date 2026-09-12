external interface User {
    var name: String
    var age: Int
}

val userCard = FC<User> { props ->
    div {
        style {
            border = "1px solid #ccc"
            padding = 16.px
            margin = 8.px
        }
        h3 { +props.name }
        p { +"Age: ${props.age}" }
    }
}

val userList = FC {
    val users = listOf(
        jsObject<User> { name = "Alice"; age = 25 },
        jsObject<User> { name = "Bob"; age = 30 }
    )
    
    div {
        users.forEach { user ->
            userCard {
                name = user.name
                age = user.age
            }
        }
    }
}
