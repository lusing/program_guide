Type Vector2
    x As Double
    y As Double
    Declare Function Length() As Double
End Type

Function Vector2.Length() As Double
    Return Sqr(x * x + y * y)
End Function

Dim v As Vector2
v.x = 3
v.y = 4
Print "vector length = "; v.Length()

