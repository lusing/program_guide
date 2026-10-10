(* ex97_crypto.v —— 密码与信任机器（Müller-Stach ch4）
   机器件：平方-乘快速模幂 powmod；小参数 RSA 全流程（p=11,q=13,
   n=143,φ=120,e=7,d=103）消息表对账；费马小定理小素数实例枚举账；
   Shamir 三趟协议四步状态机；toy 哈希链+整链验证+篡改级联检测；
   2-qubit 纠缠锥方程检查器；感知器 AND/OR 整数权重+XOR 线性不
   可分四点枚举。Hardy 讽刺剧/AKS/Shor/TDA 记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 平方-乘快速模幂 ---------- *)

(* m^e mod n：朴素线性版（每步乘底即取模——值域被压在 n² 以内，
   unary nat 全程温和）。工业用的平方-乘是 O(log e) 次「底数平方
   +按位乘」；但它的递归走 Nat.div2（指数减半），guard 检查器
   不认（家族第六撞，63/64 章同病）——教学件里消息与指数都小
   （e=7、d=103），线性版诚实够用，快速幂的机制记文档线 *)
Fixpoint powmod (base e n : nat) : nat :=
  match e with
  | 0 => 1 mod n
  | S e' => (base * powmod base e' n) mod n
  end.

(* 与朴素定义的一致性（小样本账：powmod = 直接幂取模） *)
Example powmod_check :
  map (fun t => Nat.eqb (powmod (fst t) (fst (snd t)) (snd (snd t)))
                             ((fst t) ^ (fst (snd t)) mod (snd (snd t))))
      [ (4, (9, 497)); (7, (3, 143)); (9, (5, 100)); (2, (10, 1000)) ]
  = [true; true; true; true].
Proof. reflexivity. Qed.
(* 平方-乘只做 O(log e) 次乘法——RSA 的 65537 位指数加密在实践中
   「免费」；朴素幂在 unary nat 下会先构造天文数字再取模。 *)

(* ---------- 2. RSA 全流程 ---------- *)

Definition p0 : nat := 11.
Definition q0 : nat := 13.
Definition n0 : nat := 143.        (* p*q *)
Definition phi0 : nat := 120.      (* (p-1)(q-1) *)
Definition e0 : nat := 7.
Definition d0 : nat := 103.        (* e*d ≡ 1 mod φ *)

(* 密钥方程：e·d ≡ 1 (mod φ) *)
Example rsa_key_eq : Nat.eqb ((e0 * d0 - 1) mod phi0) 0 = true.
Proof. reflexivity. Qed.

(* 加解密回环：(m^e)^d ≡ m (mod n) —— 消息表逐条对账 *)
Example rsa_roundtrip :
  map (fun m => Nat.eqb (powmod (powmod m e0 n0) d0 n0) (m mod n0))
      [5; 9; 12; 42; 100; 142; 7; 11; 22]
  = [true; true; true; true; true; true; true; true; true].
Proof. reflexivity. Qed.
(* 机制（文档线配书 p61-62）：m^(ed) = m^(1+kφ) ≡ m (mod n)——
   欧拉定理 m^φ(n) ≡ 1 对 gcd(m,n)=1；gcd≠1 的消息（如 11、13
   的倍数）靠 CRT 两翼分别归位，上表 142=11·13-1 等边界情形
   也全过。安全性押注：分解 n 才能算 φ，而分解只有次指数算法。 *)

(* ---------- 3. 费马小定理的实例枚举账 ---------- *)

(* 对小素数 p：Z_p^* 的每个元素 a 都满足 a^(p-1) ≡ 1 (mod p) *)
Definition fermatRow (p : nat) : bool :=
  forallb (fun a => Nat.eqb (powmod a (p - 1) p) 1)
          (filter (fun a => negb (Nat.eqb (a mod p) 0)) (seq 1 (p - 1))).

Example fermat_ledger :
  map fermatRow [5; 7; 11; 13] = [true; true; true; true].
Proof. reflexivity. Qed.
(* 反例侧：Carmichael 数 561=3·11·17 是费马伪素数（对所有底通过
   费马测试却不是素数）——文档线；Miller–Rabin 加二次探测检查
   拆穿它，AKS 2002 证明素性判定本身在 P。 *)

(* ---------- 4. Shamir 三趟协议（无共享密钥的传递） ---------- *)

(* 手提箱协议（书 p62-63）：素数 p=17，g=3 公开；
   Alice 私钥 m=5, m'=5'（m·m'≡1 mod p-1）；
   Bob   私钥 k=7, k'=7'。
   四步：g^m → g^{mk} → g^k → g —— Bob 最后拿到 g，
   Eve 全程只见三个公开值。 *)
Definition pg : nat := 17.
Definition g0 : nat := 3.
Definition mA : nat := 5.   Definition m'A : nat := 13.  (* 5·13=65≡1 mod 16 *)
Definition kB : nat := 7.   Definition k'B : nat := 23.  (* 7·23=161≡1 mod 16 *)

Example shamir3_keys :
  [ Nat.eqb ((mA * m'A - 1) mod (pg - 1)) 0
  ; Nat.eqb ((kB * k'B - 1) mod (pg - 1)) 0 ]
  = [true; true].
Proof. reflexivity. Qed.

(* 四步状态机：每步的公开值（Eve 视角） *)
Definition shamirRun : list nat :=
  let s1 := powmod g0 mA pg in                 (* Alice 上锁 → *)
  let s2 := powmod s1 kB pg in                 (* Bob 再上锁 → *)
  let s3 := powmod s2 m'A pg in                (* Alice 拆自己的锁 → *)
  let s4 := powmod s3 k'B pg in                (* Bob 拆自己的锁 → g *)
  [s1; s2; s3; s4].

Example shamir3_opens_box :
  [ Nat.eqb (nth 3 shamirRun 0) g0        (* 末步恰好是明文 g *)
  ; negb (Nat.eqb (nth 0 shamirRun 0) g0) (* Eve 看到的三步都不含 g *)
  ; negb (Nat.eqb (nth 1 shamirRun 0) g0)
  ; negb (Nat.eqb (nth 2 shamirRun 0) g0) ]
  = [true; true; true; true].
Proof. reflexivity. Qed.
(* 机制：指数乘法可交换 g^(m·k·m'·k') = g^(mk)^(m'k') = g^(1+16t)，
   两次「上锁/拆锁」依交换律抵消——离散对数难（已知 g^m 求 m）
   是 Eve 破解的唯一路径。推广即数字签名与零知识证明的种子。 *)

(* ---------- 5. 哈希链：区块链的最小信任机器 ---------- *)

(* toy 哈希：混合-折叠（非密码学强度——教学件）。模数取 97：
   unary nat 下 mod 的 kernel 归约是 O(被除数) 步——9973 会让
   每次折叠花三十万步，97 让整条链毫秒出账；密码学强度与教学
   机制（雪崩+链式依赖）互不耽误 *)
Fixpoint hsh (acc : nat) (x : nat) : nat :=
  match x with
  | 0 => acc
  | S x' => hsh ((acc * 7 + S x') mod 97) x'
  end.

Definition blockHash (prev data : nat) : nat := hsh (prev * 5 + 3) (data + 1).

(* 链：块 i 的哈希 = f(前块哈希, 数据)。genesis prev=0 *)
Fixpoint buildChain (data : list nat) (prev : nat) : list (nat * nat) :=
  match data with
  | [] => []
  | d :: rest =>
      let h := blockHash prev d in
      (d, h) :: buildChain rest h
  end.

Fixpoint chainOK (prev : nat) (l : list (nat * nat)) : bool :=
  match l with
  | [] => true
  | (d, h) :: rest =>
      andb (Nat.eqb h (blockHash prev d)) (chainOK h rest)
  end.

Definition chain3 := buildChain [10; 20; 30] 0.

(* 诚实链验证通过 *)
Example honest_chain : chainOK 0 chain3 = true.
Proof. reflexivity. Qed.

(* 篡改级联：改中间块数据 → 该块及后续全部失配 *)
Definition tamper (l : list (nat * nat)) : list (nat * nat) :=
  match l with
  | (d, h) :: (d2, h2) :: rest => (d, h) :: (99, h2) :: rest
  | c => c
  end.

Example tampering_breaks :
  [ negb (chainOK 0 (tamper chain3))                 (* 整链立刻断 *)
  ; Nat.eqb (fst (nth 1 (tamper chain3) (0, 0))) 99 ]  (* 数据已改 10→99 *)
  = [true; true].
Proof. reflexivity. Qed.
(* 防篡改的机制：块 i 的哈希被缝进块 i+1 的输入——改任何历史
   数据都要重算其后全部哈希（PoW 让重算贵过重写整条链——51%
   攻击的经济门槛）。Satoshi 白皮书「hash-based proof-of-work」。 *)

(* ---------- 6. 纠缠锥方程（量子一瞥） ---------- *)

(* 2-qubit 纯态系数 λ=(λ00,λ01,λ10,λ11)（非负整数小宇宙）。
   可分离 ⟺ 系数矩阵秩 1 ⟺ 锥方程 λ00·λ11 = λ01·λ10。
   实现用等式判定而非减法判零——nat 截断减法会让 0−1 塌成 0，
   纠缠态（积差为负）被误判可分离 *)
Definition separable (l : nat * (nat * (nat * nat))) : bool :=
  Nat.eqb ((fst l) * (snd (snd (snd l))))
          ((fst (snd l)) * (fst (snd (snd l)))).

(* 张量积态全部可分离；叠加 (|00⟩+|11⟩) 与 (|01⟩+|10⟩) 纠缠 *)
Example entangle_ledger :
  map separable
    [ (1, (0, (0, 1)))        (* |00⟩⊗|0⟩ 型积态——但注意这是 |00⟩+|11⟩！ *)
  ; (1, (0, (0, 0)))          (* 纯 |00⟩：积态 *)
  ; (1, (1, (0, 0)))          (* |00⟩+|01⟩ = |0⟩⊗(|0⟩+|1⟩)：积态 *)
  ; (1, (0, (1, 0)))          (* |00⟩+|10⟩：积态 *)
  ; (0, (1, (1, 0)))          (* |01⟩+|10⟩：纠缠（Bell 型） *)
  ; (1, (1, (1, 1)))          (* 全均匀：可分离（(1,1)⊗(1,1)） *)
  ]
  = [false; true; true; true; false; true].
Proof. reflexivity. Qed.
(* 第一行是主角：(|00⟩+|11⟩)/√2 = Bell 态——锥方程 1·1−0·0=1≠0
   纠缠；测量一个 qubit 立即决定另一个（EPR 的「幽灵般的超距
   作用」）。纠缠是 Shor 算法的燃料：n qubit 张量维数 2^n——
   经典模拟指数爆炸，量子硬件线性堆——RSA 的远期威胁。 *)

(* ---------- 7. 感知器：线性可分的边界 ---------- *)

(* 感知器：wx ≥ θ 触发。AND/OR 有整数权重解；XOR 无 *)
Definition fire (w1 w2 x1 x2 theta : nat) : bool :=
  Nat.leb theta (w1 * x1 + w2 * x2).

Definition andGate (x1 x2 : bool) : bool :=
  fire 1 1 (Nat.b2n x1) (Nat.b2n x2) 2.
Definition orGate (x1 x2 : bool) : bool :=
  fire 1 1 (Nat.b2n x1) (Nat.b2n x2) 1.

Example perceptron_ands :
  map (fun p => andb (Bool.eqb (andGate (fst p) (snd p))
                                (andb (fst p) (snd p)))
                   (Bool.eqb (orGate (fst p) (snd p))
                             (orb (fst p) (snd p))))
      [ (true, true); (true, false); (false, true); (false, false) ]
  = [true; true; true; true].
Proof. reflexivity. Qed.

(* XOR 不可线性分：枚举全部 9×9×19 组 (w1,w2,θ)，验证没有任何
   一组实现四点全对（四点奇偶着色无法用一条直线分开） *)
Example xor_linear_impossible :
  forallb (fun w1 =>
    forallb (fun w2 =>
      forallb (fun th =>
        negb (forallb (fun p =>
          Bool.eqb (fire w1 w2 (Nat.b2n (fst p)) (Nat.b2n (snd p)) th)
                   (xorb (fst p) (snd p)))
                [ (true, true); (true, false); (false, true); (false, false) ]))
            (seq 0 19))
          (seq 0 9))
    (seq 0 9)
  = true.
Proof. reflexivity. Qed.
(* AND/OR 的解在二维平面上是一条直线；XOR 的四点（对角同色）
   没有任何直线可分——1969 Minsky–Papert 的判词、第一次 AI 寒冬
   的导火索。多层堆叠跨过边界（深度>宽度——书 p70 的要点），
   但训练从此要走梯度下降/反向传播——「深度学习同样有不可
   判定问题，一如 Turing 机」（书 p72）记文档线。 *)

(* 冒烟 *)
Compute (powmod 2 10 1000, shamirRun, map snd chain3).
