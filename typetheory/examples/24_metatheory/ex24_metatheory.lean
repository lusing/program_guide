/- ============================================================
   24 元理论实操：de Bruijn 移位/代换的引理组 —— Lean 侧
   03 章证过 progress；本文件补「替换机械」本身的两条元定理：
   ① 提升中性律：在截止点替换，提升项纹丝不动
   ② 零移位恒等
   （CR / SN / 主体归约的证明策略见正文；本文件是「元理论
   可以机器做」的最小样本）
   ============================================================ -/

inductive Tm where
  | vr : Nat → Tm
  | lm : Tm → Tm
  | ap : Tm → Tm → Tm
deriving Repr

/-- de Bruijn 移位：≥ 截止点 c 的自由变量平移 d -/
def shift (d : Int) (c : Nat) : Tm → Tm
  | .vr k => if c ≤ k then .vr (Int.toNat (Int.ofNat k + d)) else .vr k
  | .lm b => .lm (shift d (c + 1) b)
  | .ap f a => .ap (shift d c f) (shift d c a)

/-- 代换 [j := s] -/
def subst (j : Nat) (s : Tm) : Tm → Tm
  | .vr k => if k = j then s else .vr k
  | .lm b => .lm (subst (j + 1) (shift 1 0 s) b)
  | .ap f a => .ap (subst j s f) (subst j s a)

/- ---------- 引理一：提升中性律 ----------
   shift 1 j 把 ≥ j 的变量都 +1，于是变量 j 在提升后的项里
   再也不出现——替换空转。这就是「免捕获」的代数面。        -/
theorem subst_lift_neutral (u : Tm) :
    ∀ (j : Nat) (t : Tm), subst j u (shift 1 j t) = shift 1 j t
  | j, .vr k => by
      by_cases h : j ≤ k
      · -- 提升：k ↦ k+1；k+1 ≠ j（因 j ≤ k）
        have hk : (Int.toNat (Int.ofNat k + 1)) = k + 1 := by simp
        rw [shift, if_pos h, subst, hk, if_neg (by omega)]
      · -- 不提升：k < j，k ≠ j
        rw [shift, if_neg h, subst, if_neg (by omega)]
  | j, .lm b => by
      rw [shift, subst]
      exact congrArg Tm.lm (subst_lift_neutral (shift 1 0 u) (j + 1) b)
  | j, .ap f a => by
      rw [shift, subst, subst_lift_neutral u j f, subst_lift_neutral u j a]

/- ---------- 引理二：零移位是恒等 ---------- -/

theorem shift_zero (c : Nat) : ∀ t : Tm, shift 0 c t = t
  | .vr k => by
      by_cases h : c ≤ k
      · have hk : (Int.toNat (Int.ofNat k + 0)) = k := by simp
        rw [shift, if_pos h, hk]
      · rw [shift, if_neg h]
  | .lm b => by rw [shift]; exact congrArg Tm.lm (shift_zero (c + 1) b)
  | .ap f a => by rw [shift, shift_zero c f, shift_zero c a]

/- ---------- 引理三：替换对构造子的逐分量同余 ---------- -/

theorem subst_lm_congr (j : Nat) (s : Tm) (b : Tm)
    : subst j s (.lm b) = .lm (subst (j + 1) (shift 1 0 s) b) := rfl

theorem subst_ap_congr (j : Nat) (s : Tm) (f a : Tm)
    : subst j s (.ap f a) = .ap (subst j s f) (subst j s a) := rfl

/- ---------- 组合实测：β 步骤（02 章的机械，本文件的引理背书） ---------- -/

def betaStep : Tm → Option Tm
  | .ap (.lm b) a => some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | _ => none

-- (λ. 0 0) 7 →β 7 7：代换-提升-回落的完整旅程
example : betaStep (.ap (.lm (.ap (.vr 0) (.vr 0))) (.vr 7))
        = some (.ap (.vr 7) (.vr 7)) := rfl

/- ---------- 24 章正文的「未机器化」清单 ----------
   Church–Rosser（并行归约 + 完全发展归纳，TTAFP 12 章）
   强规范化（逻辑关系法，TTAFP 12 章 / Girard 证明树）
   主体归约（代换引理：[j:=s]([k:=t]u) = [k:=t][j:=s]u 的
     提升-提升交换版——本文件的下一级难度，组装方式同引理一）
   均有标准机器化路径；本仓库 coq 教程 09 章有 TAPL 风格的
   小样本（求值器+优化器的正确性）。 -/
