import node.process.process
import node.fs.*

external fun require(module: String): dynamic
val fs = require("fs")

fun main() {
    console.log("Hello from Node.js!")
    
    // 读取文件
    val content = fs.readFileSync("input.txt", "utf8") as String
    console.log("File content: $content")
    
    // 写入文件
    fs.writeFileSync("output.txt", "Hello from Kotlin!")
    console.log("File written")
    
    // 命令行参数
    console.log("Arguments: ${process.argv}")
}
