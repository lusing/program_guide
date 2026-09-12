import kotlinx.coroutines.await
import kotlin.js.json

suspend fun fetchJson(url: String): dynamic {
    val response = window.fetch(url).await()
    return response.json().await()
}

suspend fun postData(url: String, data: dynamic): dynamic {
    val response = window.fetch(url, json(
        "method" to "POST",
        "headers" to json(
            "Content-Type" to "application/json"
        ),
        "body" to JSON.stringify(data)
    )).await()
    return response.json().await()
}
