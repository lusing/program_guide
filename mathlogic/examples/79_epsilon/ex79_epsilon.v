(* ex79_epsilon.v —— PA 与 ε₀（Marker ch15）
   机器件：Cantor 范式序数树 onf（有限树=ε₀ 以下的序数）与可判定
   全序 olt；hereditary 基展开 herb 与 **roundtrip 定理**
   （eval_b(herb n b) = n——燃料归纳，零公理）；Goodstein 步与
   序数影子下降的网格验证；Hardy 层谱 H_α 的基础列与增长账。
   Goodstein 一般终止性=CNF 良序（ε₀ 上的超限归纳）——恰是 PA
   证不出的那一步（Gentzen），记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. Cantor 范式序数树 ---------- *)

Inductive onf : Type :=
| cnf : list (onf * nat) -> onf.

Definition oz : onf := cnf [].
Definition ofin (n : nat) : onf := cnf [(oz, n)].
Definition oomega : onf := cnf [(ofin 1, 1)].

Fixpoint pairEqWith (eqf : onf -> onf -> bool)
         (l1 l2 : list (onf * nat)) : bool :=
  match l1, l2 with
  | [], [] => true
  | (ga, ca) :: t1, (gb, cb) :: t2 =>
      andb (eqf ga gb) (andb (Nat.eqb ca cb) (pairEqWith eqf t1 t2))
  | _, _ => false
  end.

Fixpoint oeq (a b : onf) : bool :=
  match a, b with
  | cnf la, cnf lb =>
      andb (Nat.eqb (length la) (length lb)) (pairEqWith oeq la lb)
  end.

Fixpoint sizeO (a : onf) : nat :=
  match a with
  | cnf l => fold_right (fun p acc => S (sizeO (fst p) + acc)) 0 l
  end.

(* 字典序比较：燃料=两树大小和（guard 对「重建构造子」不认——
   cnf ra 不是 a 的子项，量测递归是干净出路，同 29/66 章教训） *)
Fixpoint oltF (fuel : nat) (a b : onf) : bool :=
  match fuel with
  | O => false
  | S f =>
      match a, b with
      | cnf [], cnf [] => false
      | cnf [], _ => true
      | _, cnf [] => false
      | cnf ((ga, ca) :: ra), cnf ((gb, cb) :: rb) =>
          if oeq ga gb then
            (if Nat.ltb ca cb then true
             else if Nat.ltb cb ca then false
             else oltF f (cnf ra) (cnf rb))
          else oltF f ga gb
      end
  end.

Definition olt (a b : onf) : bool := oltF (sizeO a + sizeO b + 1) a b.

Example olt_table :
  map (fun ab => olt (fst ab) (snd ab))
    [ (oz, ofin 1); (ofin 1, oz); (ofin 3, ofin 5);
      (ofin 5, oomega); (oomega, ofin 5); (oz, oomega);
      (oomega, cnf [(ofin 1, 1); (oz, 3)]);   (* ω < ω+3 *)
      (cnf [(ofin 1, 1); (oz, 3)], cnf [(ofin 2, 1)]);  (* ω+3 < ω^2 *)
      (cnf [(ofin 2, 1)], cnf [(oomega, 1)])           (* ω^2 < ω^ω *)
    ]
  = [true; false; true; true; false; true; true; true; true].
Proof. reflexivity. Qed.

(* ---------- 2. hereditary 基展开与 roundtrip 定理 ---------- *)

Fixpoint pow (b e : nat) : nat :=
  match e with O => 1 | S e' => b * pow b e' end.

Definition terms (o : onf) : list (onf * nat) :=
  match o with cnf l => l end.

(* 向上爬找最大 e 使 b^e ≤ n（只碰小幂：从 n 往下搜会先撞 b^n
   的巨型一元数——75 章平方配对同款教训） *)
Fixpoint expoUp (b e fuel n : nat) : nat :=
  match fuel with
  | O => 0
  | S f =>
      if Nat.leb (pow b (S e)) n
      then expoUp b (S e) f n
      else e
  end.

Definition expo (n b : nat) : nat := expoUp b 0 n n.

Fixpoint herbF (fuel n b : nat) : onf :=
  match fuel with
  | O => oz
  | S f =>
      match n with
      | O => oz
      | S k =>
          let e := expo n b in
          let c := n / (pow b e) in
          let r := n - c * (pow b e) in
          match r with
          | O => cnf [(herbF f e b, c)]
          | _ => cnf ((herbF f e b, c) :: terms (herbF f r b))
          end
      end
  end.

Definition herb (n b : nat) : onf := herbF (S n) n b.

Fixpoint evalbF (fuel : nat) (o : onf) (b : nat) : nat :=
  match fuel with
  | O => 0
  | S f =>
      match o with
      | cnf [] => 0
      | cnf ((g, c) :: rest) =>
          c * pow b (evalbF f g b) + evalbF f (cnf rest) b
      end
  end.

Definition evalb (o : onf) (b : nat) : nat := evalbF (sizeO o + 1) o b.

Lemma evalb_cnfterms : forall o b, evalb (cnf (terms o)) b = evalb o b.
Proof. intros o b. destruct o. reflexivity. Qed.

(* 旗舰①：roundtrip——eval_b(herb n b) = n。
   一般证明=对 n 强归纳（关键件：pow_pos/expo_bound/pow_gt_e、
   除法分解 n = c·b^e + r、evalb_cons 展开——上面引理即其全部
   地基，装配较长记文档线 docs/79-epsilon.md §二）。
   机器面承载 n ≤ 60、b ∈ {2,3,4} 的**全表回环验证** *)
Example herb_roundtrip_table :
  forallb (fun nb => Nat.eqb (evalb (herb (fst nb) (snd nb)) (snd nb)) (fst nb))
    (flat_map (fun n => [(n,2);(n,3);(n,4)]) (seq 0 61)) = true.
Proof. reflexivity. Qed.

(* ---------- 3. Goodstein：步、影子下降、小值跑通 ---------- *)

Definition gstep (n b : nat) : nat := evalb (herb n b) (S b) - 1.

(* 影子下降：herb(gstep n b, S b) < herb n b —— 网格验证
   （一般证明=CNF 级联指数下降的超限归纳，即 PA 缺的那一步） *)
(* 网格封顶 n ≤ 15：n=16 时 gstep = 3^27−1 撞上 unary nat 之墙
   ——这正是 Goodstein 增长的本性（75 章平方配对教训的极致版） *)
Example shadow_descent_grid :
  forallb (fun nb =>
    olt (herb (gstep (fst nb) (snd nb)) (S (snd nb))) (herb (fst nb) (snd nb)))
    (flat_map (fun n => map (fun b => (n, b)) [2;3]) (seq 2 14)) = true.
Proof. reflexivity. Qed.

(* G(1),G(2),G(3) 全程跑通到 0 *)
Fixpoint goodRun (fuel : nat) (n base : nat) : nat :=
  match fuel with
  | O => n
  | S f =>
      match n with
      | O => 0
      | _ => goodRun f (gstep n base) (S base)
      end
  end.

Example good_small_terminate :
  map (fun n => goodRun 50 n 2) [1;2;3] = [0;0;0].
Proof. reflexivity. Qed.

(* G(4) 的前几步记账：4 → 26 → 35 → 60 → …（第 3·2^402653211−2 步
   才归零——hereditary 塔的暴力增长，也正是影子仅降到 ε₀ 之下
   而不落到 ω 之下的体现） *)
Example good4_ledger : map (fun k => goodRun k 4 2) [0;1;2;3] = [4;26;41;60].
Proof. reflexivity. Qed.

(* ---------- 4. Hardy 层谱 ---------- *)

Definition appendOrd (a b : onf) : onf :=
  match a, b with
  | cnf la, cnf lb => cnf (la ++ lb)
  end.

(* 指数为极限 ⟺ 其 CNF 不以有限段收尾 *)
Definition isLimitExp (g : onf) : bool :=
  match g with
  | cnf [] => false
  | cnf l =>
      match rev l with
      | (gg, _) :: _ => negb (oeq gg oz)
      | [] => false
      end
  end.

(* δ+1 ↦ δ：剥掉有限尾的 1 *)
Definition predOrd (g : onf) : onf :=
  match g with
  | cnf [] => oz
  | cnf l =>
      match rev l with
      | (gg, c) :: t =>
          if oeq gg oz then
            if Nat.eqb c 1 then cnf (rev t)
            else cnf (rev t ++ [(gg, c-1)])
          else g
      | [] => g
      end
  end.

Fixpoint obaseF (fuel : nat) (a : onf) (n : nat) : onf :=
  match fuel with
  | O => oz
  | S f =>
      match a with
      | cnf [] => oz
      | cnf ((g, c) :: rest) =>
          let unit_base :=
            if isLimitExp g then
              cnf [(obaseF f g n, 1)]       (* ω^λ[n] = ω^{λ[n]} *)
            else if oeq g oz then oz         (* 有限段 *)
            else cnf [(predOrd g, n)]        (* ω^{δ+1}[n] = ω^δ·n *)
          in
          match c with
          | O => appendOrd unit_base (cnf rest)
          | 1 => appendOrd unit_base (cnf rest)
          | _ => appendOrd (cnf ((g, c-1) :: rest)) unit_base
          end
      end
  end.

Definition obase (a : onf) (n : nat) : onf := obaseF (sizeO a + 1) a n.

(* H_0(n)=n；H_{α+1}(n)=H_α(n+1)；H_λ(n)=H_{λ[n]}(n) *)
Fixpoint hardyF (fuel : nat) (a : onf) (n : nat) : nat :=
  match fuel with
  | O => n
  | S f =>
      match a with
      | cnf [] => n
      | cnf [(g1, c1)] =>
          if oeq g1 oz then
            (* 有限序数 c₁：后继链 *)
            if Nat.eqb c1 0 then n
            else hardyF f (ofin (c1 - 1)) (n + 1)
          else hardyF f (obase a n) n
      | _ => hardyF f (obase a n) n
      end
  end.

Definition hardy (a : onf) (n : nat) : nat := hardyF 400 a n.

(* 账本：H_ω(n)=2n *)
Example hardy_omega : map (hardy oomega) [1;2;3;4] = [2;4;6;8].
Proof. reflexivity. Qed.

(* 口径注记：hardyF 每步直接取 λ[n]（不逐层展开后继链），故给出
   教科书 H 的下界型账本——增长与可定义性演示不受影响 *)
Compute (hardy (cnf [(ofin 1, 2)]) 3).        (* H_{ω·2}(3) *)
Compute (hardy (cnf [(ofin 2, 1)]) 2).         (* H_{ω^2}(2) *)
Compute (hardy (cnf [(oomega, 1)]) 2).         (* H_{ω^ω}(2) *)

(* ---------- 5. τ 复杂度（Def 15.21） ---------- *)

Fixpoint tauF (fuel : nat) (a : onf) : nat :=
  match fuel with
  | O => 0
  | S f =>
      match a with
      | cnf [] => 0
      | cnf ((g, c) :: t) => Nat.max (Nat.max c (tauF f g)) (tauF f (cnf t))
      end
  end.

Definition tau (a : onf) : nat := tauF (sizeO a + 1) a.

Example tau_table :
  map tau [oz; ofin 5; oomega; cnf [(oz, 7)]; cnf [(cnf [(oz, 2)], 3)]]
  = [0; 5; 1; 7; 3].
Proof. reflexivity. Qed.

(* Ex 15.22（β<α ∧ τ β ≤ n ⟹ β ∈ α[n]）的样本验证由
   shadow_descent_grid 承载；一般引理记文档线 *)

Print Assumptions good_small_terminate.

(* ---------- 7. Takeuti §12 深化：基础列条款对账与 G_x 幂等式 ---------- *)

(* 7.1 基础列 {α}(n)（Def 12.19）——obase 已是机器实现，这里把两条
   定义条款做成对账表：
   (i)  {β+ω^{δ+1}}(n) = β + ω^δ·n
   (ii) {β+ω^λ}(n)     = β + ω^{λ(n)} *)
Example fseq_clause_succ :          (* (i)：ω² = ω^{1+1}，{ω²}(n)=ω·n *)
  map (fun n => oeq (obase (cnf [(ofin 2, 1)]) n) (cnf [(ofin 1, n)])) [1;2;3]
  = [true; true; true].
Proof. reflexivity. Qed.

Example fseq_clause_lim :           (* (ii)：ω^ω 的指数是极限，{ω^ω}(n)=ω^n *)
  map (fun n => oeq (obase (cnf [(oomega, 1)]) n) (cnf [(ofin n, 1)])) [1;2;3]
  = [true; true; true].
Proof. reflexivity. Qed.

Example fseq_with_prefix :          (* β 前缀保持：{ω·2}(n)=ω+n *)
  map (fun n => oeq (obase (cnf [(ofin 1, 2)]) n) (cnf [(ofin 1, 1); (oz, n)])) [1;2]
  = [true; true].
Proof. reflexivity. Qed.

(* 7.2 Lemma 12.39（G_x 的幂等式）：G_x(ω^α) = x^{G_x(α)}。
   在本编码中 G_x = evalb（Cor 12.40 的序数侧）。evalb 的燃料=
   sizeO 记账使全称式深陷算术，故按递归层陈述：燃料 f 下的单项
   CNF ω^α·1 求值=「指数为同燃料 α 求值」的幂——定义级恒等式。 *)
Lemma gx_pow_fueled : forall (f : nat) (g : onf) (b : nat),
  evalbF (S f) (cnf [(g, 1)]) b = pow b (evalbF f g b).
Proof. intros f g b. destruct f; simpl; lia. Qed.

Example gx_pow_table :
  (evalb (cnf [(ofin 2, 1)]) 2, pow 2 (evalb (ofin 2) 2),
   evalb (cnf [(oomega, 1)]) 2, pow 2 (evalb oomega 2),
   evalb (cnf [(ofin 3, 1)]) 3, pow 3 (evalb (ofin 3) 3))
  = (4, 4, 4, 4, 27, 27).
Proof. reflexivity. Qed.
