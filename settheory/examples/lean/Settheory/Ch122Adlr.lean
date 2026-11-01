import Mathlib.Data.Fintype.Pi

/-
  第 122 章：AD^{L(R)} 的有限影子。
  长度四的有限博弈、尾等价代表、完美树密度界与定义参数编码。
  所有定理只涉及有限对象，不证明 AD、AD^{L(R)} 或无限博弈决定性。
-/

-- 安全查表：所有已给出的下标均小于 16；模运算同时固定证明接口。
def payAt (f : Fin 16 → Bool) (k : Nat) : Bool :=
  f ⟨k % 16, Nat.mod_lt _ (by decide)⟩

-- 张三策略：(开局，位置二对 b=0 的回答，对 b=1 的回答)。
def iWins (f : Fin 16 → Bool) (a0 z0 z1 : Bool) : Bool :=
  (payAt f (a0.toNat + 4 * z0.toNat) &&
   payAt f (a0.toNat + 4 * z0.toNat + 8)) &&
  (payAt f (a0.toNat + 2 + 4 * z1.toNat) &&
   payAt f (a0.toNat + 2 + 4 * z1.toNat + 8))

-- 李四策略：(b 对 a0=0/1 的回答，b1 对四个相关历史的回答)。
def iiWins (f : Fin 16 → Bool)
    (b00 b01 q000 q001 q100 q101 : Bool) : Bool :=
  (!(payAt f (2 * b00.toNat + 8 * q000.toNat)) &&
   !(payAt f (2 * b00.toNat + 4 + 8 * q001.toNat)) &&
   !(payAt f (1 + 2 * b01.toNat + 8 * q100.toNat)) &&
   !(payAt f (1 + 2 * b01.toNat + 4 + 8 * q101.toNat)))

def iAny (f : Fin 16 → Bool) : Bool :=
  [false, true].any fun a0 => [false, true].any fun z0 =>
    [false, true].any fun z1 => iWins f a0 z0 z1

def iiAny (f : Fin 16 → Bool) : Bool :=
  [false, true].any fun b00 => [false, true].any fun b01 =>
  [false, true].any fun q000 => [false, true].any fun q001 =>
  [false, true].any fun q100 => [false, true].any fun q101 =>
    iiWins f b00 b01 q000 q001 q100 q101

-- 与 Julia/Python 相同的终局下标。
def play4 (a0 z0 z1 b00 b01 q000 q001 q100 q101 : Bool) : Nat :=
  let b0 := if a0 then b01 else b00
  let a2 := if b0 then z1 else z0
  let q := if a0 then (if a2 then q101 else q100)
           else (if a2 then q001 else q000)
  a0.toNat + 2 * b0.toNat + 4 * a2.toNat + 8 * q.toNat

-- 全部 65536 张收益表恰至少一方有必胜策略；排他性由下一定理给出。
theorem finite_determinacy_length4 (f : Fin 16 → Bool) :
    (iAny f || iiAny f) = true := by
  revert f
  native_decide

-- 任意张三/李四策略不可能同时必胜：在对弈终点收益既要真又要假。
theorem exclusive_strategies_length4
    (f : Fin 16 → Bool) (a0 z0 z1 b00 b01 q000 q001 q100 q101 : Bool) :
    (!(iWins f a0 z0 z1 && iiWins f b00 b01 q000 q001 q100 q101)) = true := by
  revert f a0 z0 z1 b00 b01 q000 q001 q100 q101
  native_decide

-- 尾等价代表：保留高两位，清除低两位；n=4、m=2。
def tailRep (x : Nat) : Nat := x / 4 * 4

theorem tailrep_idempotent (x : Fin 16) : tailRep (tailRep x.val) = tailRep x.val := by
  revert x
  decide +kernel

theorem tailrep_same_class (x : Fin 16) : tailRep x.val / 4 = x.val / 4 := by
  revert x
  decide +kernel

def tailPayoff (x : Fin 16) : Bool := decide (x.val % 4 ≠ 1)

theorem tailset_size_12 :
    ((List.finRange 16).filter tailPayoff).length = 12 := by decide

-- A 含深度 d 的完美子树：存在柱 s，其全部 2^d 个叶点都属于 A。
def hasPerfect (f : Fin 16 → Bool) (d : Nat) : Bool :=
  (List.finRange (2 ^ (4 - d))).any fun s =>
    (List.finRange (2 ^ d)).all fun t =>
      f ⟨(s.val * 2 ^ d + t.val) % 16, by omega⟩

-- 有限完美集性质：无深度 d 完美树则至多缺 2^(4-d) 个柱各留一叶之外。
theorem perfect_tree_density_bound (f : Fin 16 → Bool) (d : Fin 4) :
    hasPerfect f (d.val + 1) = false →
      ((List.finRange 16).filter f).length ≤ 16 - 2 ^ (4 - (d.val + 1)) := by
  revert f d
  native_decide

-- 紧例：每柱恰删去 t=0 的叶点。
def tightSet (d : Nat) (x : Fin 16) : Bool :=
  !(decide (x.val % (2 ^ d) = 0))

theorem perfect_bound_tight (d : Fin 4) :
    hasPerfect (tightSet (d.val + 1)) (d.val + 1) = false ∧
    ((List.finRange 16).filter (tightSet (d.val + 1))).length =
      16 - 2 ^ (4 - (d.val + 1)) := by
  revert d
  decide +kernel

-- L(R) 的每个对象可由序数参数和实数参数定义；这里验证参数配对。
def encParam (p : Fin 8) (a : Fin 16) : Fin 128 :=
  ⟨p.val * 16 + a.val, by omega⟩

def decParam (c : Fin 128) : Fin 8 × Fin 16 :=
  (⟨c.val / 16, by omega⟩, ⟨c.val % 16, by omega⟩)

theorem param_roundtrip (p : Fin 8) (a : Fin 16) :
    decParam (encParam p a) = (p, a) := by
  revert p a
  decide +kernel
