/- ============================================================
   13 归纳类型族（Nordström ch.9–13）—— Lean 侧
   自造 ℕ + 加法 + 交换律（经典三步走）；
   自造列表 + 结合律；Σ 与不交和——四大构造器一文件走完
   ============================================================ -/

/- ---------- 自然数（Nordström ch.9） ---------- -/

inductive N where
  | z : N
  | s : N → N

def add : N → N → N
  | .z, m => m                    -- 递归在第一参数
  | .s n, m => .s (add n m)

/- 两条辅助引理：把「非递归侧」的等式补成定理（方向学 again） -/

theorem add_z (n : N) : add n .z = n := by
  induction n with
  | z => rfl
  | s n ih => simp only [add]; rw [ih]   -- 先把 add 折开，rw 才看得见子项

theorem add_s (n m : N) : add n (.s m) = .s (add n m) := by
  induction n with
  | z => rfl
  | s n ih => simp only [add]; rw [ih]

/-- 交换律：Peano 三步走（z 引理 + s 引理 + 归纳拼装） -/
theorem add_comm (n m : N) : add n m = add m n := by
  induction n with
  | z => rw [add_z]; rfl                -- add m z → m；剩余是定义相等
  | s n ih => rw [add_s m n, ← ih]; rfl

#eval add (N.s (N.s .z)) (N.s .z)   -- 构造子算术：3

/- ---------- 列表（ch.10）与结合律 ---------- -/

inductive Lst (α : Type) where
  | nil : Lst α
  | cons : α → Lst α → Lst α

def app {α : Type} : Lst α → Lst α → Lst α
  | .nil, ys => ys
  | .cons x xs, ys => .cons x (app xs ys)

theorem app_nil_r {α : Type} (xs : Lst α) : app xs .nil = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp only [app]; rw [ih]

theorem app_assoc {α : Type} (xs ys zs : Lst α)
    : app (app xs ys) zs = app xs (app ys zs) := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp only [app]; rw [ih]

/- ---------- Σ：依赖对（ch.11 笛氏积的依赖版） ---------- -/

structure Sig2 (α : Type) (β : α → Type) where
  fst : α
  snd : β fst

def sigEx : Sig2 N (fun _ => Lst N) := ⟨.s .z, .cons .z .nil⟩

example : sigEx.fst = .s .z := rfl
example : (sigEx.snd : Lst N) = .cons .z .nil := rfl

-- Σ 的逻辑读法：存在量词（见证 + 见证处的证据）
def Exists2 (β : N → Type) : Type := Sig2 N β

/- ---------- 不交和（ch.12） ---------- -/

inductive Sum2 (α β : Type) where
  | inl : α → Sum2 α β
  | inr : β → Sum2 α β

def elim2 {α β : Type} (P : Sum2 α β → Type)
    (l : (a : α) → P (.inl a)) (r : (b : β) → P (.inr b))
    (s : Sum2 α β) : P s :=
  match s with
  | .inl a => l a
  | .inr b => r b

-- 逻辑读法：析取的消去 = 分情况
def decEx : Sum2 N (Lst N) → N
  | .inl n => n
  | .inr _ => .z

example : decEx (.inl (.s .z)) = .s .z := rfl
