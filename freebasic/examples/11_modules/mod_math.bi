' mod_math.bi —— 第二个模块的接口：纯函数集合，展示多模块链接
#Include Once "mod_math.bi"     ' 自包含守卫（重复 #Include 无害）

Namespace MathX
    Declare Function clamp(v As Double, lo As Double, hi As Double) As Double
    Declare Function lerp(a As Double, b As Double, t As Double) As Double
End Namespace
