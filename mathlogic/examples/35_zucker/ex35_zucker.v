(* ex35_zucker.v —— Zucker 对应：截消与正规化（Urban 篇，书 ch2）
   机器件：{∧,→} 的两个项语言——
   (1) ND 项（pair/fst/snd/lam/app；另带 ∨ 侧 inl/inr/case 用于
       「对应断裂」现场）：β + γ（case 的换位）；
   (2) 矢列项（名字/余名：Ax/AndR/AndiL/ImpR/ImpL/Cut——截公式显式
       携带，Urban 原版由推导读出，教学版由检查器核对两侧一致）；
   (3) Prawitz 翻译 |·|：右规则↦根处引入、左规则↦顶处消去、Cut↦ND
       代入；
   (4) 截消一步归约 cut1：逻辑截（∧R/∧L、→R/→L 取书 (1) 第一种排法）
       + 名字截（Ax）+ 换位截（截公式非主时下推进前提）。
   电一：|·| 形状账；电二：换位截步 |M|≡|N|（定理 4 的换位侧）；
   电三：逻辑截步 |M| β→*|N|（定理 4 的逻辑侧，BFS 成员判定）；
   电四：ND 一步 β 对应矢列侧截步+翻译对齐（引理 5 样本面）；
   电五：**对应断裂现场**——∨ 进场后「成对 case 的 ∧I 换位」不在
   标准 β/γ 里（例 8 的教学重构）：BFS 全枚举证不可达 + 补上
   「怪规则」一步可达的对照。
   零公理。坑位速记见 docs/35-zucker.md。 *)

From Stdlib Require Import List Arith Bool.
Import ListNotations.

(* ---------- 1. ND 项与 β/γ ---------- *)

Inductive tm : Type :=
| var (n : nat)
| pr (a b : tm)
| fst (a : tm)
| snd (a : tm)
| inl (a : tm)
| inr (a : tm)
| case_ (d : tm) (x y : nat) (a b : tm)   (* case d of x⇒a | y⇒b：x,y 为绑定名 *)
| lam (x : nat) (a : tm)
| app (a b : tm).

Fixpoint subst (n : nat) (T : tm) (a : tm) : tm :=
  match a with
  | var m => if Nat.eqb m n then T else var m
  | pr u v => pr (subst n T u) (subst n T v)
  | fst u => fst (subst n T u)
  | snd u => snd (subst n T u)
  | inl u => inl (subst n T u)
  | inr u => inr (subst n T u)
  | case_ d x y u v =>
      case_ (subst n T d) x y
            (if Nat.eqb x n then u else subst n T u)
            (if Nat.eqb y n then v else subst n T v)
  | lam x u => lam x (if Nat.eqb x n then u else subst n T u)
  | app u v => app (subst n T u) (subst n T v)
  end.

Fixpoint tmEq (a b : tm) : bool :=
  match a, b with
  | var n, var m => Nat.eqb n m
  | pr u1 v1, pr u2 v2 => andb (tmEq u1 u2) (tmEq v1 v2)
  | fst u, fst v => tmEq u v
  | snd u, snd v => tmEq u v
  | inl u, inl v => tmEq u v
  | inr u, inr v => tmEq u v
  | case_ d1 x1 y1 u1 v1, case_ d2 x2 y2 u2 v2 =>
      andb (Nat.eqb x1 x2) (andb (Nat.eqb y1 y2)
        (andb (tmEq d1 d2) (andb (tmEq u1 u2) (tmEq v1 v2))))
  | lam x1 u1, lam x2 u2 => andb (Nat.eqb x1 x2) (tmEq u1 u2)
  | app u1 v1, app u2 v2 => andb (tmEq u1 u2) (tmEq v1 v2)
  | _, _ => false
  end.

(* ---------- 2. 矢列项 {∧,→}：名字/余名机 ---------- *)

Inductive form : Type :=
| atom (n : nat)
| fand (a b : form)
| fimp (a b : form).

Fixpoint eqF (x y : form) : bool :=
  match x, y with
  | atom n, atom m => Nat.eqb n m
  | fand x1 x2, fand y1 y2 => andb (eqF x1 y1) (eqF x2 y2)
  | fimp x1 x2, fimp y1 y2 => andb (eqF x1 y1) (eqF x2 y2)
  | _, _ => false
  end.

Fixpoint lookupF (x : nat) (G : list (nat * form)) : option form :=
  match G with
  | [] => None
  | (y, A) :: t => if Nat.eqb y x then Some A else lookupF x t
  end.

Fixpoint remv (x : nat) (G : list (nat * form)) : list (nat * form) :=
  match G with
  | [] => []
  | (y, A) :: t => if Nat.eqb y x then remv x t else (y, A) :: remv x t
  end.

(* 项：SAx x a / SAndR ⟨a⟩M ⟨b⟩N c / SAndiL i (x)M z（i=false 吃左
   分量；z=语境中引入的名）/ SImpR (x)⟨a⟩M c / SImpL ⟨a⟩M (x)N z /
   SCut A ⟨a⟩M (x)N（截公式 A 显式携带，检查器核对两侧一致）。 *)
Inductive st : Type :=
| SAx (x a : nat)
| SAndR (a b c : nat) (M N : st)
| SAndiL (i : bool) (x z : nat) (M : st)
| SImpR (x a c : nat) (M : st)
| SImpL (a x z : nat) (M N : st)
| SCut (A : form) (a : nat) (M : st) (x : nat) (N : st).

(* 检查器**自顶向下**：后件公式作输入。stCheck G M C ⟺ G ⊢ M ◦ c:C。 *)
Fixpoint stCheck (G : list (nat * form)) (M : st) (C : form) : bool :=
  match M with
  | SAx x _ =>
      match lookupF x G with
      | Some A => eqF A C | None => false end
  | SAndR _ _ _ M N =>
      match C with
      | fand A B => andb (stCheck G M A) (stCheck G N B)
      | _ => false end
  | SAndiL i x z M =>
      match lookupF z G with
      | Some (fand A1 A2) =>
          stCheck ((x, (if i then A2 else A1)) :: remv z G) M C
      | _ => false end
  | SImpR x _ _ M =>
      match C with
      | fimp A B => stCheck ((x, A) :: remv x G) M B
      | _ => false end
  | SImpL _ x z M N =>
      match lookupF z G with
      | Some (fimp A B) =>
          andb (stCheck (remv z G) M A)
               (stCheck ((x, B) :: remv x (remv z G)) N C)
      | _ => false end
  | SCut A _ M x N =>
      andb (stCheck G M A) (stCheck ((x, A) :: remv x G) N C)
  end.

Fixpoint stEq (M N : st) : bool :=
  match M, N with
  | SAx x1 a1, SAx x2 a2 => andb (Nat.eqb x1 x2) (Nat.eqb a1 a2)
  | SAndR a1 b1 e1 M1 N1, SAndR a2 b2 e2 M2 N2 =>
      andb (Nat.eqb a1 a2) (andb (Nat.eqb b1 b2)
        (andb (Nat.eqb e1 e2) (andb (stEq M1 M2) (stEq N1 N2))))
  | SAndiL i1 x1 z1 M1, SAndiL i2 x2 z2 M2 =>
      andb (Bool.eqb i1 i2) (andb (Nat.eqb x1 x2)
        (andb (Nat.eqb z1 z2) (stEq M1 M2)))
  | SImpR x1 a1 e1 M1, SImpR x2 a2 e2 M2 =>
      andb (Nat.eqb x1 x2) (andb (Nat.eqb a1 a2)
        (andb (Nat.eqb e1 e2) (stEq M1 M2)))
  | SImpL a1 x1 z1 M1 N1, SImpL a2 x2 z2 M2 N2 =>
      andb (Nat.eqb a1 a2) (andb (Nat.eqb x1 x2)
        (andb (Nat.eqb z1 z2) (andb (stEq M1 M2) (stEq N1 N2))))
  | SCut A1 a1 M1 x1 N1, SCut A2 a2 M2 x2 N2 =>
      andb (eqF A1 A2) (andb (Nat.eqb a1 a2) (andb (Nat.eqb x1 x2)
        (andb (stEq M1 M2) (stEq N1 N2))))
  | _, _ => false
  end.

(* ---------- 3. Prawitz 翻译 |·| ---------- *)

Fixpoint trans (M : st) : tm :=
  match M with
  | SAx x _ => var x
  | SAndR _ _ _ M N => pr (trans M) (trans N)
  | SAndiL i x z M =>
      subst x (if i then snd (var z) else fst (var z)) (trans M)
  | SImpR x _ _ M => lam x (trans M)
  | SImpL _ x z M N => subst x (app (var z) (trans M)) (trans N)
  | SCut _ _ M x N => subst x (trans M) (trans N)
  end.

(* ---------- 4. 截消一步归约 cut1 ---------- *)

Fixpoint renConame (M : st) (c d : nat) : st :=
  match M with
  | SAx x a => SAx x (if Nat.eqb a c then d else a)
  | SAndR a b e M N =>
      SAndR (if Nat.eqb a c then d else a) (if Nat.eqb b c then d else b)
            e (renConame M c d) (renConame N c d)
  | SAndiL i x z M => SAndiL i x z (renConame M c d)
  | SImpR x a e M =>
      SImpR x (if Nat.eqb a c then d else a) e (renConame M c d)
  | SImpL a x z M N =>
      SImpL (if Nat.eqb a c then d else a) x z
            (renConame M c d) (renConame N c d)
  | SCut A a M x N =>
      SCut A (if Nat.eqb a c then d else a) (renConame M c d) x
             (renConame N c d)
  end.

(* 逻辑截 ∧ 的截公式随分量选择重算——直接从语境侧由检查器一致性
   保证；样本级用 CA/AA 占位再由电池核对翻译，不做类型反查。 *)
Fixpoint cut1 (M : st) : st :=
  match M with
  | SCut CA c (SAndR a b e M N) x P =>
      match P with
      | SAndiL i x' z Q =>
          if Nat.eqb z x
          then (if i then SCut CA b N x' Q else SCut CA a M x' Q)
          else SCut CA c (SAndR a b e (cut1 M) (cut1 N)) x (cut1 P)
      | _ => SCut CA c (SAndR a b e (cut1 M) (cut1 N)) x (cut1 P)
      end
  | SCut CA c (SImpR x a e M) z P =>
      match P with
      | SImpL a' y z' N Q =>
          if Nat.eqb z' z
          then SCut CA a (SCut CA a' N x M) y Q
          else SCut CA c (SImpR x a e (cut1 M)) z (cut1 P)
      | _ => SCut CA c (SImpR x a e (cut1 M)) z (cut1 P)
      end
  | SCut CA a (SAx x a') y P =>
      if Nat.eqb a' a
      then renConame P a y
      else SCut CA a (SAx x a') y (cut1 P)
  | SCut CA c (SAndiL i x z M) y P =>
      SAndiL i x z (SCut CA c M y P)
  | SCut CA c (SImpL a x z M N) y P =>
      SImpL a x z (SCut CA c M y P) (SCut CA c N y P)
  | SCut CA c (SCut A2 a2 M2 x2 N2) y P =>
      (* 截套截：内层截的右前提再接外层截（换位族样本）；
      左项=SAndR 的情形已被首句覆盖（其 else 支下推） *)
      SCut A2 a2 M2 x2 (SCut CA c N2 y P)
  | SAx x a => SAx x a
  | SAndR a b e M N => SAndR a b e (cut1 M) (cut1 N)
  | SAndiL i x z M => SAndiL i x z (cut1 M)
  | SImpR x a e M => SImpR x a e (cut1 M)
  | SImpL a x z M N => SImpL a x z (cut1 M) (cut1 N)
  end.

(* ---------- 5. ND 归约 BFS：β∪γ 成员判定 ---------- *)

Fixpoint betaCtx (a : tm) : list tm :=
  match a with
  | fst u =>
      (match u with
       | pr x _ => [ x ]
       | _ => []
       end) ++ map (fun w => fst w) (betaCtx u)
  | snd u =>
      (match u with
       | pr _ y => [ y ]
       | _ => []
       end) ++ map (fun w => snd w) (betaCtx u)
  | app u v =>
      (match u with
       | lam x b => [ subst x v b ]
       | _ => []
       end)
      ++ map (fun w => app w v) (betaCtx u)
      ++ map (fun w => app u w) (betaCtx v)
  | case_ d x y u v =>
      (match d with
       | inl s => [ subst x s u ]
       | inr s => [ subst y s v ]
       | _ => []
       end)
      ++ map (fun w => case_ w x y u v) (betaCtx d)
      ++ map (fun w => case_ d x y w v) (betaCtx u)
      ++ map (fun w => case_ d x y u w) (betaCtx v)
  | pr u v =>
      map (fun w => pr w v) (betaCtx u) ++ map (fun w => pr u w) (betaCtx v)
  | inl u => map (fun w => inl w) (betaCtx u)
  | inr u => map (fun w => inr w) (betaCtx u)
  | lam x u => map (fun w => lam x w) (betaCtx u)
  | var _ => []
  end.

Fixpoint gammaCtx (a : tm) : list tm :=
  match a with
  | fst u =>
      (match u with
       | case_ d x y p q => [ case_ d x y (fst p) (fst q) ]
       | _ => []
       end) ++ map (fun w => fst w) (gammaCtx u)
  | snd u =>
      (match u with
       | case_ d x y p q => [ case_ d x y (snd p) (snd q) ]
       | _ => []
       end) ++ map (fun w => snd w) (gammaCtx u)
  | app u v =>
      (match u with
       | case_ d x y p q => [ case_ d x y (app p v) (app q v) ]
       | _ => []
       end)
      ++ map (fun w => app w v) (gammaCtx u)
      ++ map (fun w => app u w) (gammaCtx v)
  | case_ d x y u v =>
      (match d with
       | case_ e s t p q =>
           [ case_ e s t (case_ p x y u v) (case_ q x y u v) ]
       | _ => []
       end)
      ++ map (fun w => case_ w x y u v) (gammaCtx d)
      ++ map (fun w => case_ d x y w v) (gammaCtx u)
      ++ map (fun w => case_ d x y u w) (gammaCtx v)
  | pr u v =>
      map (fun w => pr w v) (gammaCtx u) ++ map (fun w => pr u w) (gammaCtx v)
  | inl u => map (fun w => inl w) (gammaCtx u)
  | inr u => map (fun w => inr w) (gammaCtx u)
  | lam x u => map (fun w => lam x w) (gammaCtx u)
  | var _ => []
  end.

Definition stepsOf (a : tm) : list tm := betaCtx a ++ gammaCtx a.

Fixpoint bfsReach (fuel : nat) (target : tm) (frontier : list tm) : bool :=
  match fuel with
  | 0 => existsb (tmEq target) frontier
  | S k =>
      if existsb (tmEq target) frontier then true
      else bfsReach k target (flat_map stepsOf frontier)
  end.

Definition betaGammaStar (target a : tm) : bool := bfsReach 7 target [ a ].

(* ---------- 6. 断言电池 ---------- *)

Notation fA := (atom 0).
Notation fB := (atom 1).

(* 样本 ∧：语境 0:A, 1:B, 2:A∧B；截公式 A∧B。
   左项：AndR ⟨0⟩(Ax 0 0) ⟨1⟩(Ax 1 1) 3 证出 A∧B；
   右项：AndiL false (x'=0) z=2 (Ax 0 4)——吃左分量 A。 *)
Definition Gand : list (nat * form) :=
  [ (0, fA); (1, fB); (2, fand fA fB) ].

Definition andCut : st :=
  SCut (fand fA fB) 3 (SAndR 0 1 3 (SAx 0 0) (SAx 1 1)) 2
       (SAndiL false 0 2 (SAx 0 4)).

(* 电零：矢列项良型（自顶向下检查器收下 andCut，端式 A） *)
Example andcut_typed : stCheck Gand andCut fA = true.
Proof. vm_compute. reflexivity. Qed.

(* 电一：|·| 形状账——Ax↦var、AndR↦pair、ImpR↦lam、AndiL↦fst 代入、
   Cut↦ND 代入（合成为 fst ⟨var 0, var 1⟩ 的 β 红ex） *)
Example trans_andcut :
  tmEq (trans andCut) (fst (pr (var 0) (var 1))) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：换位截步 |M|≡|N|——截在 AndiL 前提里移动不改变翻译 *)
Definition commCut : st :=
  SCut fA 5 (SAndiL false 0 2 (SAx 0 5)) 3 (SAx 3 6).
Example commuting_identity :
  tmEq (trans commCut) (trans (cut1 commCut)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电三：逻辑截步 |M| β→*|N|（定理 4 逻辑侧）
   cut1(andCut) = SCut (Ax 0 0) 0' (Ax 0 4)——翻译 = var 0 *)
Example logical_cut_beta :
  betaGammaStar (trans (cut1 andCut)) (trans andCut) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电四（引理 5 样本面）：ND 一步 β（fst ⟨v0,v1⟩→v0）对应矢列侧
   一步截消+翻译恰为同两态 *)
Example lemma5_sample :
  andb (tmEq (trans andCut) (fst (pr (var 0) (var 1))))
       (tmEq (trans (cut1 andCut)) (var 0))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* → 侧样本：语境 0:A→B, 1:A, 2:B。
   左项 ImpR (x=1)⟨a=2⟩(Ax 2 2) c=3 : A→B；
   右项 ImpL ⟨a=1⟩(Ax 1 1) (y=3) (Ax 3 4) z=0。 *)
Definition Gimp : list (nat * form) :=
  [ (0, fimp fA fB); (1, fA); (2, fB) ].

Definition impCut : st :=
  SCut (fimp fA fB) 3 (SImpR 1 2 3 (SAx 2 2)) 0
       (SImpL 1 3 0 (SAx 1 1) (SAx 3 4)).

Example impcut_typed : stCheck Gimp impCut fB = true.
Proof. vm_compute. reflexivity. Qed.

(* 翻译：|impCut| = (λ1.var 2) 应用到 var 1 的 β 红ex；
   cut1 后（书 (1) 第一种排法）翻译 = var 2 *)
Example imp_cut_beta :
  andb (tmEq (trans impCut) (app (lam 1 (var 2)) (var 1)))
       (betaGammaStar (trans (cut1 impCut)) (trans impCut))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 7. 对应断裂现场（例 8 的教学重构） ---------- *)

(* 收缩让 ∧R 的两个前提各自经 ∨E 消费**同一个** A∨B：
   t1 = ⟨case d 1⇒M 2⇒N , case d 1⇒S 2⇒T⟩
   t2 = case d 1⇒⟨M,S⟩ 2⇒⟨N,T⟩   （需要「∧I 与 ∨E 换位」——怪规则）
   断言 A：t2 不在 t1 的标准 β/γ 闭包里（BFS 全枚举）；
   断言 B：怪规则一步到达——缺的正是它。 *)
Definition t1 : tm :=
  pr (case_ (var 9) 1 2 (var 3) (var 4))
     (case_ (var 9) 1 2 (var 5) (var 6)).
Definition t2 : tm :=
  case_ (var 9) 1 2 (pr (var 3) (var 5)) (pr (var 4) (var 6)).

(* 怪规则（书 p.48）：⟨case P λx.M λy.N, case P λz.S λw.T⟩
   → case P λx.⟨M,S[z/x]⟩ λy.⟨N,T[w/y]⟩——需「两 P 相等」测试且
   破坏 λ 演算的合流（文档线）。 *)
Definition strangeStep (a : tm) : tm :=
  match a with
  | pr (case_ d x y u v) (case_ d' z w s t) =>
      if tmEq d' d
      then case_ d x y (pr u (subst z (var x) s)) (pr v (subst w (var y) t))
      else a
  | _ => a
  end.

Example break_witness_unreachable : betaGammaStar t2 t1 = false.
Proof. vm_compute. reflexivity. Qed.

Example break_witness_strange_reaches : tmEq (strangeStep t1) t2 = true.
Proof. vm_compute. reflexivity. Qed.

(* 冒烟 *)
Compute (trans andCut, trans (cut1 andCut)).
Compute (trans impCut, trans (cut1 impCut)).
