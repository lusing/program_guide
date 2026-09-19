' mod_counter.bas —— 计数器模块的实现：.bi 声明的函数在这里长出身体
' #Include 的是自己的 .bi（拿到声明），实现用 Namespace 同名块包住。

#Include Once "mod_counter.bi"

Namespace Counter
    Dim As Integer value_ = 0         ' 模块私有状态：外界拿不到
    Dim As Stats st_

    Function add(v As Integer) As Integer
        value_ += v
        st_.total += v
        st_.calls += 1
        Return value_
    End Function

    Function getvalue() As Integer
        Return value_
    End Function

    Function stats() As Stats
        Return st_
    End Function

    Sub reset()
        value_ = 0
        st_ = Type(0, 0)
    End Sub
End Namespace
