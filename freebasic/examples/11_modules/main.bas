' main.bas —— 11_modules 主模块：只 #Include .bi（接口），实现由链接器拼上
' 编译（在示例目录内）：fbc -w all -g -exx main.bas mod_counter.bas mod_math.bas -x ../..
' 教程统一入口：build.ps1 / run-all.sh 会把目录下全部 .bas 一起编译（首个为主模块）。

#Include Once "mod_counter.bi"
#Include Once "mod_math.bi"

' ---- 用模块 1：计数器（有状态，封装在模块私有变量里）----
Print "== Counter 模块 =="
Print "add 5 ->"; Counter.add(5)
Print "add 3 ->"; Counter.add(3)
Assert(Counter.getvalue() = 8)

Var st = Counter.stats()
Print "统计: total="; st.total; " calls="; st.calls
Assert(st.total = 8 And st.calls = 2)

Counter.reset()
Assert(Counter.getvalue() = 0)
Print "reset 后 getvalue="; Counter.getvalue()

' ---- 用模块 2：纯函数 ----
Print "== MathX 模块 =="
Print "clamp(3.5, 0, 2)="; MathX.clamp(3.5, 0, 2)
Print "lerp(0, 10, 0.25)="; MathX.lerp(0, 10, 0.25)
Assert(MathX.clamp(3.5, 0, 2) = 2)
Assert(MathX.lerp(0, 10, 0.25) = 2.5)

' ---- Using：免写前缀（就近使用，别全局乱 Using）----
Using MathX
Print "Using 后 clamp(-1, 0, 2)="; clamp(-1, 0, 2)
Assert(clamp(-1, 0, 2) = 0)

Print "[OK] 11_modules"
End 0
