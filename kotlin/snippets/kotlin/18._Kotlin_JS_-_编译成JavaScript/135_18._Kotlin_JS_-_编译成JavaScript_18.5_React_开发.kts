import react.*
import react.dom.html.*
import react.dom.html.ReactHTML.*
import web.cssom.*

val app = FC {
    var count by useState(0)
    
    div {
        h1 {
            +"Counter: $count"
        }
        button {
            onClick = { count++ }
            +"Increment"
        }
    }
}

fun main() {
    val root = createRoot(document.getElementById("root")!!)
    root.render(app.create())
}
