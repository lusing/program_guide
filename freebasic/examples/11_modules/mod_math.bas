' mod_math.bas —— MathX 实现
#Include Once "mod_math.bi"

Namespace MathX
    Function clamp(v As Double, lo As Double, hi As Double) As Double
        If v < lo Then Return lo
        If v > hi Then Return hi
        Return v
    End Function

    Function lerp(a As Double, b As Double, t As Double) As Double
        Return a + (b - a) * t
    End Function
End Namespace
