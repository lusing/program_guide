Enum LogLevel
    LOG_DEBUG = 1
    LOG_INFO
    LOG_WARN
    LOG_ERROR
End Enum

Dim As LogLevel lv = LOG_WARN

Select Case lv
Case LOG_DEBUG
    Print "debug"
Case LOG_INFO
    Print "info"
Case LOG_WARN
    Print "warn"
Case LOG_ERROR
    Print "error"
End Select

