sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error<T>(val message: String) : Result<T>()
    object Loading : Result<Nothing>()
}

// 使用
fun handleResult(result: Result<String>) = when (result) {
    is Result.Success -> "Success: ${result.data}"
    is Result.Error -> "Error: ${result.message}"
    Result.Loading -> "Loading..."
}

// 递归密封类
sealed class Tree<out T> {
    data class Node<T>(
        val value: T,
        val left: Tree<T>? = null,
        val right: Tree<T>? = null
    ) : Tree<T>()

    data class Leaf<T>(val value: T) : Tree<T>()
}
