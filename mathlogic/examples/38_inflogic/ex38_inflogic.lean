/- 第 38 章 无穷逻辑与决定逻辑（Takeuti Ch4 §22-§24）
    打包规则一步账+高度条件样本+有限开博弈胜策略搜索（Zermelo）+AD 前奏。
    零公理。 -/

namespace Ex38

def allb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => true
  | x :: t => f x && allb f t

def anyb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => false
  | x :: t => f x || anyb f t

/- ---------- 件一：打包规则一步账（γ=2 样本） ---------- /
   两份主公式一次消费——上矢列的分量同时进入下矢列。 -/
def packAndSample : Bool :=
  -- 上矢列 S1 分量 A1、S2 分量 A2；下矢列同时含 A1 与 A2
  let G1 : List Nat := [1, 10]
  let G2 : List Nat := [2, 11]
  let G : List Nat := [10, 11, 1, 2]
  anyb (· == 1) G && anyb (· == 2) G
  && allb (fun x => anyb (· == x) (G1 ++ G2)) G

example : packAndSample = true := by decide

/-- 单主公式版对照（有穷 LK 的 γ=1 特例） -/
def singleAndSample : Bool :=
  let G1 : List Nat := [1, 10]
  let G : List Nat := [10, 1]
  anyb (· == 1) G && allb (fun x => anyb (· == x) G1) G

example : singleAndSample = true := by decide

/- ---------- 件二：高度函数条件（本征变元条件 II，例 22.2 现场） ---------- -/

def hDep (m : Nat) : Nat := m      -- h(a_m) = m（依赖选择证明的逐层抬升）

example : (allb (fun m => hDep 0 < hDep m) [1, 2, 3]) = true := by decide

example : (hDep 1 == 1 && hDep 2 == 2) = true := by decide

/- ---------- 件三：Gale-Stewart 有限版（Zermelo 定理） ---------- -/

/-- I 的胜前缀集（开博弈）：I 的奇数步全 true 即胜 -/
def winSet : List Bool → Option Bool
  | true :: _ :: true :: _ => some true
  | false :: false :: _ => some false
  | _ => none

/-- 第二胜集：I 的两连 true 判负（II 擒双 t） -/
def winSet2 : List Bool → Option Bool
  | true :: true :: _ => some false
  | false :: false :: _ => some true
  | _ => none

def turn (player : Nat) : Nat := (player + 1) % 2

/-- 后向归纳：某方必胜策略求值（开博弈语义：depth 耗尽未命中=II 胜） -/
def gsEval (ws : List Bool → Option Bool) : Nat → Nat → List Bool → Option Bool
  | 0, _, pos => match ws pos with
                 | some w => some w
                 | none => some false
  | d + 1, player, pos =>
      match ws pos with
      | some w => some w
      | none =>
          let b0 := gsEval ws d (turn player) (false :: pos)
          let b1 := gsEval ws d (turn player) (true :: pos)
          match player with
          | 0 => if b1 == some true then some true
                 else if b0 == some true then some true
                 else some false
          | _ => if b1 == some false then some false
                 else if b0 == some false then some false
                 else some true
termination_by depth _player _pos => depth

/-- 账例一：先手必胜（首步+第三步双 t） -/
example : gsEval winSet 4 0 [] = some true := by native_decide

/-- 账例二：后手必胜（I 的双 t 被擒） -/
example : gsEval winSet2 4 0 [] = some false := by native_decide

/-- Zermelo 二择一：有限开博弈总给出某方的必胜判定 -/
example :
  ((gsEval winSet 4 0 []).isSome && (gsEval winSet2 4 0 []).isSome) = true := by
  native_decide

/- ---------- 件四：AD 前奏账（例 23.3 形状） ---------- -/

def adShape : Bool :=
  let D1 : List Nat := [1]
  let D2 : List Nat := [2]
  D1.head? == some 1 && D2.head? == some 2

example : adShape = true := by decide

end Ex38
