' 19_threads.bas —— 多线程：ThreadCreate/MutexLock/CondWait 生产者-消费者
' 编译：fbc -w all -g -exx 19_threads.bas -x 19_threads.exe
' 注意：多线程 + 运行时 → 需要 -mt 编译线程安全运行库吗？实测默认链接即可（见章内说明）。

' ---- 1) 互斥保护的共享计数 ----
Dim Shared As Any Ptr gMtx

Sub worker(ByVal ud As Any Ptr)        ' 线程入口签名固定：Sub(ByVal As Any Ptr)（win64 下别加 Cdecl）
    Dim As Integer Ptr p = CPtr(Integer Ptr, ud)
    For i As Integer = 1 To 10000
        MutexLock(gMtx)
        *p += 1
        MutexUnlock(gMtx)
    Next
End Sub

' ---- 2) 条件变量：单槽缓冲的生产者-消费者 ----
Type Channel
    mtx As Any Ptr
    cond As Any Ptr
    value As Integer
    ready As Boolean
    closed As Boolean
End Type

Dim Shared As Channel chan

Sub chInit()
    chan.mtx = MutexCreate()
    chan.cond = CondCreate()
    chan.value = 0
    chan.ready = False
    chan.closed = False
End Sub

Sub chSend(v As Integer)
    MutexLock(chan.mtx)
    While chan.ready                     ' 槽满就等（用 While 防 虚假唤醒）
        CondWait(chan.cond, chan.mtx)
    Wend
    chan.value = v
    chan.ready = True
    CondSignal(chan.cond)
    MutexUnlock(chan.mtx)
End Sub

Function chRecv() As Integer
    MutexLock(chan.mtx)
    While chan.ready = False AndAlso chan.closed = False
        CondWait(chan.cond, chan.mtx)
    Wend
    Var v = chan.value
    chan.ready = False
    CondSignal(chan.cond)
    MutexUnlock(chan.mtx)
    Return v
End Function

Sub chClose()
    MutexLock(chan.mtx)
    chan.closed = True
    CondBroadcast(chan.cond)             ' 唤醒所有等待者
    MutexUnlock(chan.mtx)
End Sub

' ---- 生产者/消费者线程体 ----
Sub producer(ByVal ud As Any Ptr)
    For i As Integer = 1 To 50
        chSend(i * i)
    Next
    chClose()
End Sub

Sub consumer(ByVal ud As Any Ptr)
    Dim As Integer Ptr sum = CPtr(Integer Ptr, ud)
    Do
        MutexLock(chan.mtx)
        Var closed = chan.closed AndAlso chan.ready = False
        MutexUnlock(chan.mtx)
        If closed Then Exit Do
        If chan.ready Then *sum += chRecv()
    Loop
End Sub

' ================= 验证 =================
Print "== 互斥计数：2 线程 x 10000 =="
gMtx = MutexCreate()
Dim As Integer counter = 0
Dim As Any Ptr t1 = ThreadCreate(@worker, @counter)
Dim As Any Ptr t2 = ThreadCreate(@worker, @counter)
ThreadWait(t1)
ThreadWait(t2)
MutexDestroy(gMtx)
Print "counter ="; counter; "（正确则互斥生效）"
Assert(counter = 20000)

Print "== 条件变量：生产 1..50 的平方，消费求和 =="
chInit()
Dim total As Integer = 0
Dim As Any Ptr tp = ThreadCreate(@producer, 0)
Dim As Any Ptr tc = ThreadCreate(@consumer, @total)
ThreadWait(tp)
ThreadWait(tc)
MutexDestroy(chan.mtx)
CondDestroy(chan.cond)
Print "sum(1..50 的平方) ="; total
Assert(total = 42925)                  ' 50*51*101/6

Print "[OK] 19_threads"
End 0
