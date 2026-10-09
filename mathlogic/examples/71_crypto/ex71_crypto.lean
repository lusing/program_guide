/- ex71 —— 密码与信任机器（Müller-Stach ch4）Lean 镜像
   powmod 平方-乘（Nat 二进制无 guard 之扰）+ RSA 全流程 +
   费马实例账 + Shamir 三趟 + 哈希链篡改级联 + 纠缠锥 +
   感知器 XOR 不可分。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

/- ---------- 1. 平方-乘快速模幂 ---------- -/

/-- Lean 的 Nat 是 GMP 二进制——指数减半的平方-乘直接结构递归 -/
def powmod (base e n : Nat) : Nat :=
  match e with
  | 0 => 1 % n
  | e + 1 =>
      -- 递归传 (e+1)/2（不是 e/2！）：base^(2k)=base^k 的平方，
      -- 奇数再乘一个底
      let half := powmod base ((e + 1) / 2) n
      let sq := half * half % n
      if (e + 1) % 2 == 1 then sq * base % n else sq

example :
    [ (4, 13, 497), (7, 3, 143), (9, 5, 100), (2, 10, 1000) ].map
      (fun t => powmod t.1 t.2.1 t.2.2 == t.1 ^ t.2.1 % t.2.2)
    = [true, true, true, true] := by native_decide

/- ---------- 2. RSA 全流程 ---------- -/

def p0 : Nat := 11
def q0 : Nat := 13
def n0 : Nat := 143
def phi0 : Nat := 120
def e0 : Nat := 7
def d0 : Nat := 103

example : (e0 * d0 - 1) % phi0 == 0 := by native_decide

/-- 加解密回环：(m^e)^d ≡ m (mod n)，含 gcd≠1 的边界消息 11、22 -/
example :
    [5, 9, 12, 42, 100, 142, 7, 11, 22].map
      (fun m => powmod (powmod m e0 n0) d0 n0 == m % n0)
    = [true, true, true, true, true, true, true, true, true] := by
  native_decide

/- ---------- 3. 费马小定理实例账 ---------- -/

def fermatRow (p : Nat) : Bool :=
  ((List.range (p - 1)).map (· + 1)).all (fun a =>
    !(a % p == 0) && powmod a (p - 1) p == 1)

example : [5, 7, 11, 13].map fermatRow = [true, true, true, true] := by
  native_decide

/- ---------- 4. Shamir 三趟协议 ---------- -/

def pg : Nat := 17
def g0 : Nat := 3
def mA : Nat := 5
def m'A : Nat := 13   -- 5·13=65≡1 mod 16
def kB : Nat := 7
def k'B : Nat := 23   -- 7·23=161≡1 mod 16

example :
    [(mA * m'A - 1) % (pg - 1) == 0, (kB * k'B - 1) % (pg - 1) == 0]
    = [true, true] := by native_decide

/-- 四步状态机（Eve 视角）：前三个公开值都不含明文，末步开箱 -/
def shamirRun : List Nat :=
  let s1 := powmod g0 mA pg          -- Alice 上锁
  let s2 := powmod s1 kB pg          -- Bob 再上锁
  let s3 := powmod s2 m'A pg         -- Alice 拆自己的锁
  let s4 := powmod s3 k'B pg         -- Bob 拆自己的锁 = g
  [s1, s2, s3, s4]

example :
    shamirRun[3]! == g0 && shamirRun[0]! != g0 && shamirRun[1]! != g0
      && shamirRun[2]! != g0 := by native_decide

/- ---------- 5. 哈希链与篡改级联 ---------- -/

def hsh (acc x : Nat) : Nat :=
  match x with
  | 0 => acc
  | x' + 1 => hsh ((acc * 31 + (x' + 1)) % 9973) x'

def blockHash (prev data : Nat) : Nat := hsh (prev * 101 + 53) (data + 1)

def buildChain : List Nat → Nat → List (Nat × Nat)
  | [], _ => []
  | d :: rest, prev =>
      let h := blockHash prev d
      (d, h) :: buildChain rest h

def chainOK (prev : Nat) : List (Nat × Nat) → Bool
  | [] => true
  | (d, h) :: rest => (h == blockHash prev d) && chainOK h rest

def chain3 : List (Nat × Nat) := buildChain [10, 20, 30] 0

example : chainOK 0 chain3 := by native_decide

/-- 篡改中间块数据 → 整链立刻失配 -/
def tamper : List (Nat × Nat) → List (Nat × Nat)
  | (d, h) :: (d2, h2) :: rest => (d, h) :: (99, h2) :: rest
  | c => c

example : !chainOK 0 (tamper chain3)
    && (tamper chain3)[1]!.1 == 99 := by native_decide

/- ---------- 6. 纠缠锥方程 ---------- -/

/-- nat 截断减法会让积差为负的纠缠态误判——用等式判定 -/
def separable (l : Nat × (Nat × (Nat × Nat))) : Bool :=
  l.1 * l.2.2.2 == l.2.1 * l.2.2.1

example :
    [ ((1 : Nat), (0, (0, 1))),   -- |00⟩+|11⟩：Bell 态纠缠
      (1, (0, (0, 0))),           -- |00⟩：积态
      (1, (1, (0, 0))),           -- (|0⟩+|1⟩)⊗|0⟩ 型积态
      (1, (0, (1, 0))),           -- |0⟩⊗(|0⟩+|1⟩) 型积态
      (0, (1, (1, 0))),           -- |01⟩+|10⟩：纠缠
      (1, (1, (1, 1))) ].map separable
    = [false, true, true, true, false, true] := by native_decide

/- ---------- 7. 感知器 ---------- -/

def fire (w1 w2 x1 x2 theta : Nat) : Bool := theta <= w1 * x1 + w2 * x2

def b2n (b : Bool) : Nat := if b then 1 else 0

def andGate (x1 x2 : Bool) : Bool :=
  fire 1 1 (b2n x1) (b2n x2) 2
def orGate (x1 x2 : Bool) : Bool :=
  fire 1 1 (b2n x1) (b2n x2) 1

example :
    [(true, true), (true, false), (false, true), (false, false)].all
      (fun p => andGate p.1 p.2 == (p.1 && p.2)
             && orGate p.1 p.2 == (p.1 || p.2)) := by native_decide

/-- XOR 不可线性分：9×9×19 组权重无一实现四点全对 -/
example :
    (List.range 9).all fun w1 =>
      (List.range 9).all fun w2 =>
        (List.range 19).all fun th =>
          !([(true, true), (true, false), (false, true), (false, false)].all
            fun p => fire (w1 + 1) (w2 + 1) (b2n p.1) (b2n p.2) th
                       == xor p.1 p.2)
    := by native_decide

#eval (powmod 2 10 1000, shamirRun, chain3.map (·.2))
