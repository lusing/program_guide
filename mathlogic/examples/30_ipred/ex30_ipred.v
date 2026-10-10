(* ex30_ipred.v —— 直觉主义谓词逻辑：扩张域与传递规则（Mints ch13-16）
   机器件：（W,R,D,V）扩张域 Kripke 模型与 Def 14.3 全子句求值器
   （∃ 看当前域、∀ 看一切未来域）；**例 14.1**：链 0≤1≤2、P(d,w_i)
   ⟺ j<i 驳倒 ∀x¬¬Px→¬¬∀xPx——Glivenko 在谓词层的死亡现场（引
   13.2 的反例）；**CD 框架刻画**（Lemma 14.4）：增长域帧驳倒常域
   公理 ∀x(φ∨q)→(q∨∀xφ)、常域模型全过——双向账；**DNS 对账**：
   ∃x¬¬Px→¬¬∃xPx 在全枚举模型有效（=谓词表列传递规则的语义载荷，
   ch16）、∀ 向被例 14.1 驳倒——双否定迁移只顺 ∃ 山谷走；**谓词 GG
   负翻译**（Def 13.1）：∀ 保形、∃ 缀 ¬¬，负公式稳定性（⊢¬¬φ↔φ，
   Thm 13.2）+经典保持样本；**命题级 SOA**（Def 8.7）：(φ,w) 翻译成
   经典一元谓词公式，Kripke 有效 ⟺ 经典有效在全部枚举结构上对账
   （Thm 15.3 的有限影子）。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.

Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

Definition impb (a b : bool) : bool := if a then b else true.
Definition beqb (a b : bool) : bool := if a then b else negb b.

(* ---------- 1. 谓词公式与扩张域模型（Def 14.1-14.3） ---------- *)

Inductive pf : Type :=
| pP  : nat -> pf            (* P_j(x) *)
| pff : pf
| paand : pf -> pf -> pf
| poor : pf -> pf -> pf
| piimp : pf -> pf -> pf
| pall : pf -> pf            (* ∀x *)
| pex  : pf -> pf.           (* ∃x *)

Notation "a ~> b" := (piimp a b) (at level 90, right associativity).
Definition pneg (a : pf) : pf := a ~> pff.

(* 模型 = (世界数, R 掩码, 域函数 D:世界→个体表, 谓词 V:个体→世界→bool) *)
Definition pmodel := (nat * nat * (nat -> list nat) * (nat -> nat -> nat -> bool))%type.
(* pmodel = ((n,m),D,V) 的左结合嵌套：fst(fst M)=(n,m) *)
Definition pW (M : pmodel) : nat := fst (fst (fst M)).
Definition pRm (M : pmodel) : nat := snd (fst (fst M)).
Definition pR (M : pmodel) (i j : nat) : bool :=
  Nat.testbit (pRm M) (pW M * i + j).
Definition pD (M : pmodel) (w : nat) : list nat := snd (fst M) w.
Definition pV (M : pmodel) (j d w : nat) : bool := snd M j d w.

(* Def 14.3：∃ 的见证在 D(w) 里找；∀ 要一切未来世界的整个域 *)
(* 个体环境 d 贯穿递归（结构递归的关键：绑定处换 d，不代人公式） *)
Fixpoint peval (M : pmodel) (d w : nat) (a : pf) {struct a} : bool :=
  match a with
  | pP j => pV M j d w
  | pff => false
  | paand x y => andb (peval M d w x) (peval M d w y)
  | poor x y => orb (peval M d w x) (peval M d w y)
  | piimp x y =>
      forallb (fun w' => impb (pR M w w')
                        (impb (peval M d w' x) (peval M d w' y)))
               (seq 0 (pW M))
  | pall b =>
      forallb (fun w' => impb (pR M w w')
                        (forallb (fun d' => peval M d' w' b) (pD M w')))
               (seq 0 (pW M))
  | pex b =>
      existsb (fun d' => peval M d' w b) (pD M w)
  end.

(* ---------- 2. 例 14.1：Glivenko 的谓词层死亡现场 ---------- *)

(* 机器翻案（本轮实测最深的一课）：∀x¬¬Px→¬¬∀xPx 在**一切有限帧上
   有效**——极大世界里「每个个体终将 P」迫使 ∀xPx 当场成立，¬∀xPx
   无处安放。Mints 的反例必须用**无穷链** (ℕ,≤)（D=正整数、
   P(d,i)⟺d<i）：前提真（每个 d 都有更晚的 i）、而每个世界 i 都有
   失败个体 i+1——¬¬∀xPx 在根世界死。下面的算术化账把无穷链的两条
   子句各算一遍；有限侧的有效性由 pvValid 枚举作证。 *)
Definition infPremise (k : nat) : bool :=
  forallb (fun d => existsb (fun i => Nat.ltb d i) (seq d (k + 2))) (seq 0 (S k)).

Definition infFailing (k : nat) : bool :=
  forallb (fun i => negb (Nat.ltb (S i) i)) (seq 0 (S k)).

Example ex14_inf_account : andb (infPremise 6) (infFailing 6) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 3. DNS 对账：双否定迁移只顺 ∃ 山谷走 ---------- *)

(* 个体 2 个、谓词 1 个的全模型枚举（域与谓词均按帧上集取值） *)
Definition preordOK (n m : nat) : bool :=
  forallb (fun i => Nat.testbit m (n * i + i)) (seq 0 n)
  && forallb (fun i =>
       forallb (fun j =>
         forallb (fun k =>
            impb (andb (Nat.testbit m (n * i + j)) (Nat.testbit m (n * j + k)))
                 (Nat.testbit m (n * i + k)))
           (seq 0 n)) (seq 0 n)) (seq 0 n).

Definition framesAll : list (nat * nat) :=
  map (fun m => (1, m)) (filter (fun m => preordOK 1 m) (seq 0 1))
  ++ map (fun m => (2, m)) (filter (fun m => preordOK 2 m) (seq 0 16))
  ++ map (fun m => (3, m)) (filter (fun m => preordOK 3 m) (seq 0 512)).

(* 帧上集（个体的「在域」模式与谓词真值模式共用） *)
Definition upsOf (n m : nat) : list nat :=
  filter (fun s =>
     forallb (fun i =>
        impb (Nat.testbit s i)
             (forallb (fun j =>
                impb (Nat.testbit m (n * i + j)) (Nat.testbit s j))
                (seq 0 n)))
             (seq 0 n))
    (seq 0 (2 ^ n)).

Definition modelsAll : list pmodel :=
  flat_map (fun F =>
     let n := fst F in let m := snd F in
     let U := upsOf n m in
     flat_map (fun sd =>
        flat_map (fun sv0 =>
           flat_map (fun sv1 =>
              [(n, m,
                (fun w => filter (fun d => Nat.testbit sd (n * d + w)) (seq 0 2)),
                (fun j d w => Nat.testbit (if Nat.eqb j 0 then sv0 else sv1)
                                        (n * d + w)))])
           U)
        U)
        U)
    framesAll.

Definition pvValid (a : pf) : bool :=
  forallb (fun M => forallb (fun w => peval M 0 w a) (seq 0 (pW M))) modelsAll.

(* ∃ 向 DNS：有效——谓词表列「传递规则」的语义载荷（ch16） *)
Example dns_exist : pvValid (piimp (pex (pneg (pneg (pP 0))))
                                   (pneg (pneg (pex (pP 0))))) = true.
Proof. vm_compute. reflexivity. Qed.

(* ∀ 向 DNS：有限帧上**有效**——反例必须无穷（例 14.1 的无穷链） *)
Example dns_all_finite :
  pvValid (piimp (pall (pneg (pneg (pP 0))))
                 (pneg (pneg (pall (pP 0))))) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 4. CD 框架刻画（Lemma 14.4） ---------- *)

(* 常域公理 CD：∀x(φ∨q)→(q∨∀xφ)，x∉FV(q)——φ=P(x), q=P_1(x) 代 *)
Definition cdAxiom : pf :=
  piimp (pall (poor (pP 0) (pP 1)))
        (poor (pP 1) (pall (pP 0))).

(* 增长域帧上的驳倒：链模型里 CD 翻车 *)
Example cd_fails_growing : pvValid cdAxiom = false.
Proof. vm_compute. reflexivity. Qed.

(* 常域模型全过：D 恒定 {0,1} 的子模型族上 CD 有效 *)
Definition constDomModels : list pmodel :=
  flat_map (fun F =>
     let n := fst F in let m := snd F in
     let U := upsOf n m in
     flat_map (fun sv0 =>
        flat_map (fun sv1 =>
           [(n, m, (fun _ => [0; 1]),
             (fun j d w => Nat.testbit (if Nat.eqb j 0 then sv0 else sv1)
                                     (n * d + w)))])
        U)
       U)
    framesAll.

Example cd_holds_constdom :
  forallb (fun M => forallb (fun w => peval M 0 w cdAxiom) (seq 0 (pW M)))
          constDomModels = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 5. 谓词 GG 负翻译（Def 13.1）与稳定性（Thm 13.2） ---------- *)

Fixpoint gg (a : pf) : pf :=
  match a with
  | pP j => pneg (pneg (pP j))
  | pff => pff
  | paand x y => paand (gg x) (gg y)
  | poor x y => pneg (paand (pneg (gg x)) (pneg (gg y)))
  | piimp x y => piimp (gg x) (gg y)
  | pall b => pall (gg b)
  | pex b => pneg (pall (pneg (gg b)))
  end.

(* 负公式：无 ∨∃、原子皆双重否定——稳定性 ⊢¬¬φ↔φ（Thm 13.2 引理 13.3） *)
Fixpoint negative (a : pf) : bool :=
  match a with
  | pP _ => false                              (* 裸原子不是负公式 *)
  | pff => true
  | piimp (piimp (pP _) pff) pff => true       (* ¬¬ 原子：负 *)
  | piimp b pff => negative b                  (* ¬ 外壳保持负性 *)
  | paand x y => andb (negative x) (negative y)
  | piimp x y => andb (negative x) (negative y)
  | _ => false
  end.

Definition negFormulas : list pf :=
  [ pneg (pP 0)
  ; pneg (paand (pneg (pneg (pP 0))) (pP 1 ~> pff))
  ; pneg (poor (pP 0) (pP 1))
  ; piimp (pneg (pP 0)) (pneg (pP 1)) ].

(* 负公式的稳定性：¬¬φ→φ 在全枚举模型有效 *)
Example negative_stable :
  forallb (fun a => impb (negative a)
                         (pvValid (piimp (pneg (pneg a)) a)))
          negFormulas = true.
Proof. vm_compute. reflexivity. Qed.

(* 经典保持样本：经典有效式翻译后直觉有效（¬¬ 缀法吃掉经典性） *)
Example gg_classical_sample :
  pvValid (gg (poor (pP 0) (pneg (pP 0)))) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 6. 命题级 SOA（Def 8.7）：Kripke⟺经典的全枚举对账 ---------- *)

(* 经典一阶公式（个体=世界；P/Q 一元、R 二元） *)
(* soaFull 不含量词（世界皆为显式常元），cf 只需无量词片段；
   合取用显式构造子（→⊥ 编码在长度上有奇偶坑，教学从简） *)
Inductive cf : Type :=
| cP : nat -> cf
| cQ : nat -> cf
| cR : nat -> nat -> cf
| cimp : cf -> cf -> cf
| cand : cf -> cf -> cf
| cfalse : cf
| ctrue : cf.

Fixpoint ceval (n m vp vq : nat) (g : cf) : bool :=
  match g with
  | cP v => Nat.testbit vp v
  | cQ v => Nat.testbit vq v
  | cR a b => Nat.testbit m (n * a + b)
  | cimp x y => impb (ceval n m vp vq x) (ceval n m vp vq y)
  | cand x y => andb (ceval n m vp vq x) (ceval n m vp vq y)
  | cfalse => false
  | ctrue => true
  end.

(* 命题 Kripke 力迫（世界 n 个、R 掩码 m、p/q 上集赋值） *)
Fixpoint pkForce (n m vp vq : nat) (w : nat) (a : pf) {struct a} : bool :=
  match a with
  | pP 0 => Nat.testbit vp w
  | pP _ => Nat.testbit vq w
  | pff => false
  | paand x y => andb (pkForce n m vp vq w x) (pkForce n m vp vq w y)
  | poor x y => orb (pkForce n m vp vq w x) (pkForce n m vp vq w y)
  | piimp x y =>
      forallb (fun w' => impb (Nat.testbit m (n * w + w'))
                        (impb (pkForce n m vp vq w' x) (pkForce n m vp vq w' y)))
               (seq 0 n)
  | _ => false
  end.

(* 翻译 (φ,w)：蕴含条款=Def 8.7 的 ∀w' 形——有限帧上显式展开为合取 *)
Fixpoint soaFull (a : pf) (n : nat) (w : nat) {struct a} : cf :=
  match a with
  | pP 0 => cP w
  | pP _ => cQ w
  | pff => cfalse
  | paand x y =>
      cimp (cimp (soaFull x n w) (cimp (soaFull y n w) cfalse)) cfalse
  | poor x y =>
      cimp (cimp (soaFull x n w) cfalse) (soaFull y n w)
  | piimp x y =>
      fold_right (fun w' acc =>
          cand (cimp (cR w w') (cimp (soaFull x n w') (soaFull y n w'))) acc)
        ctrue (seq 0 n)
  | _ => cfalse
  end.

Definition soaFms : list pf :=
  [ pP 0; pneg (pP 0); poor (pP 0) (pP 1); piimp (pP 0) (pP 1)
  ; pneg (poor (pP 0) (pneg (pP 0)))
  ; piimp (pneg (pP 0)) (pneg (pneg (pP 0))) ].

(* 逐结构对账：Kripke 力迫(φ,w) = 经典真值(soaFull φ n w, w) *)
Example soa_agrees :
  forallb (fun F =>
     let n := fst F in let m := snd F in
     let U := upsOf n m in
     forallb (fun vp =>
        forallb (fun vq =>
           forallb (fun w =>
              forallb (fun a =>
                 beqb (pkForce n m vp vq w a)
                      (ceval n m vp vq (soaFull a n w)))
              soaFms)
           (seq 0 n))
        U)
     U)
    framesAll = true.
Proof. vm_compute. reflexivity. Qed.
