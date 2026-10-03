/- ex21 —— 可判定性与 SMT（Lean 4 版：Decidable 现场 + 半可判定文档） -/
namespace Ex21

/-- 命题层可判定：有限搜索即决策——bounded 量词的 List.all -/
def boundedAll (P : Nat → Bool) (n : Nat) : Bool :=
  (List.range n).all P

/-- 可判定片段：等词理论（nat 上 decidability 是计算性的） -/
example (x y : Nat) : Decidable (x = y) := instDecidableEqNat x y

/-- 半可判定的一阶层：有效式可枚举（完备性 ⟹ r.e.）——文档；
    不可判定（Church）：r.e. 但非递归——文档。
    机器层面：Decidable 实例的存在性就是可判定性的命题表述。 -/

example : boundedAll (fun _ => true) 10 = true := by rfl

example : boundedAll (fun x => x < 5) 10 = false := by rfl

/- 坑位速记（Lean 侧）：
   - Decidable 实例即「可判定的机器面」——instDecidableEqNat 等
     内核自带；自定义谓词须手写实例或 decide 推导；
   - bounded 量词的可判定性来自 List.all 的有限性——
     一阶的 unbounded 量词破坏有限性（不可判定的起点）。 -/

end Ex21
