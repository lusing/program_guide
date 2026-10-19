/- ex48 —— 真理理论：Tarski 不可定义与 Kripke 不动点（Lean 镜像）
   T-模式全枚举 + 真集对角逃逸（flipAt）+ 强 Kleene 三值 +
   自指句集不动点迭代（说谎者恒 U、诚实者双固定点、全真起步振荡）。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

/- ---------- 1. 小句子宇宙与 T-模式 ---------- -/

def TRUTH : List Bool := [true, false, true, false, true, false]

def tsat (i : Nat) : Bool := TRUTH.getD i false

example : (List.range 6).map (fun i => tsat i == TRUTH.getD i false)
    = [true, true, true, true, true, true] := by native_decide

/- ---------- 2. Tarski 对角逃逸（语义侧影子） ---------- -/

def flipAt : Nat → List Bool → List Bool
  | _, [] => []
  | 0, x :: t => (!x) :: t
  | k + 1, x :: t => x :: flipAt k t

/-- 每个谓词编号 k：对角句 flipAt k TRUTH 在位置 k 与真集相反
    ——「我不真」的逐位化：任何可定义集都在自己的对角位上装不下真集 -/
example : (List.range 6).all (fun k =>
    !(flipAt k TRUTH).getD k false == TRUTH.getD k false) := by
  native_decide

/- ---------- 3. 强 Kleene 三值 ---------- -/

inductive T3 | TF | TU | TL
deriving DecidableEq, Repr

def t3neg : T3 → T3
  | .TF => .TL | .TL => .TF | .TU => .TU

def t3or : T3 → T3 → T3
  | .TF, _ => .TF | _, .TF => .TF
  | .TL, z => z | z, .TL => z
  | _, _ => .TU

def t3and (x y : T3) : T3 := t3neg (t3or (t3neg x) (t3neg y))

/-- U∨T=T 与 U∨L=U 的对照是全部要点；U∧L=L（部分信息可定的定） -/
example :
  [t3or .TU .TF, t3or .TU .TL, t3or .TU .TU, t3and .TU .TL,
   t3and .TU .TF, t3and .TU .TU, t3neg .TU]
    = [.TF, .TU, .TU, .TL, .TU, .TU, .TU] := by native_decide

/- ---------- 4. Kripke 不动点迭代 ---------- -/

/-- 句子内容：0=「句1假」1=「句0真」（说谎者环）；2/3=互指假；
    4=「句4真」（诚实者）；5=「句4假 ∨ 句2真」 -/
inductive Claim
  | cf (i : Nat)
  | ct (i : Nat)
  | cor (c1 c2 : Claim)

def SENTS : List Claim :=
  [Claim.cf 1, Claim.ct 0, Claim.cf 3, Claim.cf 3, Claim.ct 4,
   Claim.cor (.cf 4) (.ct 2)]

def ev (v : List T3) : Claim → T3
  | .cf i => t3neg (v.getD i .TU)
  | .ct i => v.getD i .TU
  | .cor c1 c2 => t3or (ev v c1) (ev v c2)

def stepK (v : List T3) : List T3 := SENTS.map (ev v)

def iterK : Nat → List T3
  | 0 => [.TU, .TU, .TU, .TU, .TU, .TU]
  | n + 1 => stepK (iterK n)

/-- Kripke 跳跃单调：迭代只把 TU 变确定、绝不翻面 -/
example : (List.range 4).all (fun n =>
    (List.range 6).all (fun i =>
      match (iterK n).getD i .TU, (iterK (n+1)).getD i .TU with
      | .TU, _ => true
      | x, y => x == y)) := by native_decide

/-- 收敛：第 3 步起不动 -/
example : iterK 2 == iterK 3 && iterK 3 == iterK 4 := by native_decide

/-- 最小不动点读数：六句全 TU（说谎者环无根基） -/
example : (List.range 6).all (fun i => (iterK 3).getD i .TF == .TU) := by
  native_decide

/-- 诚实者的扩张不动点 vT：句 4=「句4真」在 vT 下自我兑现 -/
def vT : List T3 := [.TU, .TU, .TU, .TU, .TF, .TU]

example : stepK vT == vT := by native_decide

example : [(iterK 3).getD 4 .TF, vT.getD 4 .TF] = [.TU, .TF] := by
  native_decide

/-- 从全真起步会振荡（周期 4）——最小不动点路径是命脉 -/
def iterTop : Nat → List T3
  | 0 => [.TF, .TF, .TF, .TF, .TF, .TF]
  | n + 1 => stepK (iterTop n)

example : !(iterTop 2 == iterTop 4)
    && (iterTop 4).getD 0 .TF == .TF
    && (iterTop 4).getD 1 .TF == .TF := by native_decide

#eval (iterK 3, vT)
