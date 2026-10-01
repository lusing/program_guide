/- ============================================================
   09 定义与证明工程（λD 精神）—— Lean 侧
   对照 Coq 版：def 的透明 / opaque 的墙 / variable 与 section /
   局部 let 与 where / 记法扩张
   ============================================================ -/

/- ---------- ① 全局定义：透明 δ ---------- -/
def twice (f : Nat → Nat) (n : Nat) : Nat := f (f n)

#eval twice (fun n => n + 3) 1     -- 7
#print twice                       -- 展开式可见

/- ---------- ② 局部定义：let 与 where ---------- -/
def localDemo : Nat :=
  let x := 2
  let y := 40
  x + y

#eval localDemo                    -- 42

-- where 版：辅助函数挂在定义尾部
def poly2 (a b c x : Nat) : Nat := eval x
where
  eval : Nat → Nat
    | 0 => c
    | n + 1 => step (eval n)
  step (v : Nat) : Nat := a * v * v + b * v + c / (c + 1) -- 教学占位算术

#eval poly2 1 2 3 2                -- 按 where 块逐步算

/- ---------- ③ 透明 vs 不透明 ---------- -/

theorem twice_add_0' : ∀ n, twice (fun _ => 0) n = 0 := fun _ => rfl
-- def 式定理可 rfl 穿透（δ + β 一路展开）

-- opaque：筑墙（与 Coq 的 Qed 同工）
opaque twiceConst : Nat → Nat := fun n => twice (fun _ => 7) n

#eval twiceConst 5                 -- 求值仍可（opaque 有值，只是不可 δ 透视）
-- example : twiceConst 5 = 7 := by rfl   -- 【失败】：opaque 挡的就是 rfl！
example : twiceConst 5 = 7 := by native_decide
-- native_decide 走编译器（绕过内核 δ），是过墙的另一条官道

/- ---------- ④ variable 与 section ----------
   Lean 的 variable「用到才收」：只有【语句里出现】的变量自动泛化，
   假设类前提要写成定理的显式参数（对照 Coq 的 Section 全量泛化） -/
section MonoidLike
variable (U : Type) (op : U → U → U) (e : U)

theorem op_e_left_twice
    (op_assoc : ∀ x y z : U, op (op x y) z = op x (op y z))
    (e_left : ∀ x : U, op e x = x) : ∀ x : U, op e (op e x) = x := by
  intro x
  rw [← op_assoc, e_left, e_left]
  -- ← op_assoc：op e (op e x) → op (op e e) x；再两发 e_left 到 x

#check @op_e_left_twice
end MonoidLike

/- 段外复用：换一套例化（Nat 加法；结合律/左单位是引理不是 rfl —— 0 + x
   在 Lean 的加法下不定义折叠，见 01 章方向学） -/
example : ∀ x : Nat, Nat.add 0 (Nat.add 0 x) = x :=
  op_e_left_twice Nat Nat.add 0 Nat.add_assoc Nat.zero_add

/- ---------- ⑤ 记法：语法扩张 ---------- -/
-- 注意：⊕ 已被核心库占用（Sum 的记号），自定义记号要避开
local infixl:65 " ⊗ " => Nat.add

example : 2 ⊗ 3 = 5 := rfl

/- ---------- ⑥ λD 视角小结 ----------
   TTAFP 的 λD 把「带定义的 λC」形式化：
   - 定义 = 保守扩张（不增加可证命题，只缩短证明）；
   - δ-归约与 β 同级，但工程上要能【关掉】（Qed/opaque）——
     否则 simpl 满屏展开，证明脚本失控；
   - 定义带参数（twice 的 f）、有作用域（Section/where/let），
     06 章 F 的类型层定义（Endo）是同一机制在高一层的镜像。 -/
