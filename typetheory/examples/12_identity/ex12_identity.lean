/- ============================================================
   12 相等类型与 J（Nordström ch.8）—— Lean 侧手工课
   自己造 MyEq：构造子 refl + 消去子 J，
   再亲手推出 sym / trans / cong / transport —— 零库依赖
   ============================================================ -/

universe u v

/-- 恒等类型：refl 是唯一构造子（内涵相等的最小实现）。
    Sort (max 1 u)：u=0 时升到 Type，保住单构造子消去到任意层的资格 -/
inductive MyEq {α : Sort u} (a : α) : α → Sort (max 1 u) where
  | refl : MyEq a a

/-- J 规则（基于 refl 的归纳原理）：
    给「a 点上的证据」，沿等式搬运到任意 y -/
def myJ {α : Sort u} {a : α}
    (P : ∀ x, MyEq a x → Sort v) (h : P a MyEq.refl)
    {y : α} (e : MyEq a y) : P y e :=
  match e with
  | .refl => h

/- ---------- 四件套全部由 J 手推 ---------- -/

/-- 对称：把「a = x」族上的 a 点证据沿 e 搬到 b -/
def mySymm {α : Sort u} {a b : α} (e : MyEq a b) : MyEq b a :=
  myJ (fun x _ => MyEq x a) MyEq.refl e

/-- 传递：归纳第二条等式 -/
def myTrans {α : Sort u} {a b c : α} (e1 : MyEq a b) (e2 : MyEq b c) : MyEq a c :=
  myJ (fun x _ => MyEq a b → MyEq a x) (fun h => h) e2 e1

/-- 同余（函数保等） -/
def myCong {α β : Sort u} {a b : α} (f : α → β) (e : MyEq a b) : MyEq (f a) (f b) :=
  myJ (fun x _ => MyEq (f a) (f x)) MyEq.refl e

/-- 替换/搬运：证据沿等式旅行 -/
def myTransport {α : Sort u} (P : α → Sort v) {a b : α}
    (e : MyEq a b) (h : P a) : P b :=
  myJ (fun x _ => P x) h e

/- ---------- 实测 ---------- -/

example : MyEq 3 3 := .refl                      -- refl 只有同点一形
example : mySymm (MyEq.refl (a := 3)) = MyEq.refl := rfl
example : myTrans (MyEq.refl (a := 3)) (MyEq.refl (a := 3)) = MyEq.refl := rfl

-- 数值等式的实际使用：1+1 定义相等
def oneOne : MyEq (1 + 1) 2 := MyEq.refl
example : MyEq 2 (1 + 1) := mySymm oneOne

-- transport 搬运向量：长度证据跟着走
def Vec : Type → Nat → Type
  | _, 0 => Unit
  | α, n + 1 => α × Vec α n

example (h : MyEq (1 + 1) 2) (v : Vec Nat 2) : Vec Nat (1 + 1) := myTransport (Vec Nat) (mySymm h) v

/- ---------- 内涵 vs 外延：J 的边界 ---------- -/

-- 函数外延性【不】能由 J 推出：f x = g x 处处成立推不出 f = g。
-- 用 MyEq 的自造世界里没有它——myJ 只认 refl，而 f ≡ g 不是
-- 定义相等。三家的处理各有故事：Coq 有可选的 Funext 公理类；
-- Lean 从 Quot.sound【推导】出 funext；Agda 内涵理论同样不可证，
-- 同伦路线（19-21 章）给出另一种解法。

#check @funext                -- Lean 核心的函数外延（定理）
#print axioms funext          -- 依赖 [propext, Quot.sound]——不是 J！
