/- ex38 —— 自动机与 LTL 模型检查（Ben-Ari 3e §16.4-16.8）Lean 镜像
   环用后继函数 bsucc 表示（确定性 Büchi）；◇ 的相位猜测 =
   对每个可达起点分别试。旗舰 loop_accept_inf：环 ⟹ 无穷次过
   接受态——有限证书的无穷内容。 -/

structure Baut where
  bS : List Nat
  bsucc : Nat → Nat
  bI : List Nat
  bF : List Nat

def runFrom (bs : Nat → Nat) (s : Nat) : Nat → Nat
  | 0 => s
  | t + 1 => runFrom bs (bs s) t

theorem runFrom_add (bs : Nat → Nat) (a : Nat) :
    ∀ (s b : Nat), runFrom bs s (a + b) = runFrom bs (runFrom bs s a) b := by
  induction a with
  | zero => intro s b; simp only [Nat.zero_add]; rfl
  | succ a ih =>
    intro s b
    rw [Nat.succ_add]
    show runFrom bs (bs s) (a + b) = runFrom bs (runFrom bs (bs s) a) b
    exact ih _ _

def inL : List Nat → Nat → Bool
  | [], _ => false
  | y :: l', x => (y == x) || inL l' x

def upto : Nat → List Nat
  | 0 => []
  | m + 1 => upto m ++ [m]

def reachL (A : Baut) : Nat → List Nat → List Nat → List Nat
  | 0, _, seen => seen
  | _k + 1, [], seen => seen
  | k + 1, s :: fr, seen =>
      if inL seen s then reachL A k fr seen
      else reachL A k ((fr.map A.bsucc) ++ [A.bsucc s]) (s :: seen)

def reachSet (A : Baut) : List Nat := reachL A 64 A.bI []

def loopsAt (A : Baut) (s : Nat) : Bool :=
  (upto 8).any (fun t => 0 < t && (runFrom A.bsucc s t == s))

def findLoop (A : Baut) : Bool :=
  (reachSet A).any (fun s => inL A.bF s && loopsAt A s)

/- ============ 旗舰：环 = 无穷接受的有限证书 ============ -/

theorem loop_accept_inf (A : Baut) (s T : Nat)
    (hacc : s ∈ A.bF) (hloop : runFrom A.bsucc s T = s) (hT : 0 < T) :
    ∀ n, ∃ t, n ≤ t ∧ runFrom A.bsucc s t ∈ A.bF := by
  have hperiod : ∀ k, runFrom A.bsucc s (k * T) = s := by
    intro k
    induction k with
    | zero => simp only [Nat.zero_mul, runFrom]
    | succ k ih =>
      rw [Nat.succ_mul, runFrom_add, ih]; exact hloop
  have hmult : ∀ m : Nat, ∃ k, m ≤ k * T := by
    intro m
    refine ⟨m + 1, ?_⟩
    cases T with
    | zero => omega
    | succ T' => rw [Nat.mul_succ]; omega
  intro n
  obtain ⟨k, hk⟩ := hmult n
  exact ⟨k * T, hk, by rw [hperiod k]; exact hacc⟩

/- ============ 现场：AG F p 的模型检查 ============ -/

def dead : Nat := 9

def labelK : Nat → Bool
  | 0 => true | _ => false

def succK : Nat → Nat
  | 0 => 1 | 1 => 2 | 2 => 0 | _ => dead

def succK2 : Nat → Nat
  | 0 => 1 | 1 => 2 | 2 => 1 | _ => dead

def PK : Baut where
  bS := [0, 1, 2, dead]
  bsucc := fun k => if labelK k then dead else succK k
  bI := [0, 1, 2]        -- ◇ 的相位猜测：每个可达起点都试
  bF := [0, 1, 2]

def PK2 : Baut where
  bS := [0, 1, 2, dead]
  bsucc := fun k => if labelK k then dead else succK2 k
  bI := [0, 1, 2]
  bF := [0, 1, 2]

-- K：无活环 —— AG F p 成立
example : findLoop PK = false := by rfl

-- K2：活环在 {1,2} —— 反例轨道从 1 出发
example : findLoop PK2 = true := by rfl

-- 反例轨道读出：从 1 出发永远绕 {1,2}（p 永不再真）
example : (upto 7).map (runFrom PK2.bsucc 1) = [1, 2, 1, 2, 1, 2, 1] := by
  rfl
