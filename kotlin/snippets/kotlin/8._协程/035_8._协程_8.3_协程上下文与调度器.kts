// 使用不同调度器
GlobalScope.launch(Dispatchers.Default) {
    // CPU 密集任务
}

GlobalScope.launch(Dispatchers.IO) {
    // I/O 操作
}

GlobalScope.launch(Dispatchers.Unconfined) {
    // 不限制线程
}
