Dim As Integer value = 10
Dim p As Integer Ptr
p = @value

Print "value(before) = "; value
*p = 42
Print "value(after)  = "; value
Print "ptr points to = "; *p

