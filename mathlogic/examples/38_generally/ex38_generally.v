(* ex38_generally.v —— 「一般」逻辑与滤子（Vana/Veloso/Veloso 篇，书 ch6）
   机器件：∇ 量词的有限宇宙完全语义——
   (1) U={0,1,2}（3 世界、8 子集位掩码）；复形=子集族（256 个族）；
       模块五性质：⊕全域/∈非空(∅∉K)/∩交/∪并/⊇扩集——组合出
       P(⊕∈)/S(⊕∈⊇)/L(⊕∈∩∪)/F(⊕∈∩⊇ 真滤子)；
   (2) 双层语义：内层=世界层公式（扩展=位掩码，补集=7 lxor）；
       外层=∇/∀/∃ 命题+布尔连接（∇u A 真 ⟺ ext(A)∈K）；
   (3) **穷举式机器证明**（256 族×64 赋值）：
       - ∀→∇（⊕）、∇→∃（∈）在 P 即真；
       - ∇A∧∇B→∇(A∧B) 在 F 真、S 假（∩）；
       - 单调性 ∀(A⊃B)∧∇A→∇B 在 F 真、L 假（⊇）——L 与 F 不可比，
         书 §2 模块格的机器面；
       - 一致性 ∇A∧∇¬A→⊥ 在 F 真、P 假；
       - 反例方向 ∇A→∀A 在 F 假（反模型当场交出）；
   (4) 真滤子计数：3 元宇宙恰 **7** 个真滤子（每个非空 S 给出主滤
       子 ↑S——「有限宇宙上滤子皆主」的机器面）；
   (5) 模块格的严格包含账：|F| < |S| < |P|。
   注：公理只依赖公式的**扩展集**，原子样本公式+全赋值枚举=对扩展
   组合的完全覆盖（文档线）。零公理。坑位速记见 docs/38-generally.md。 *)

From Stdlib Require Import List Arith Bool.
Import ListNotations.

(* ---------- 1. 宇宙、子集、复形 ---------- *)

Definition univ : nat := 7.                      (* 位掩码 111 *)
Definition subI (s t : nat) : nat := Nat.lor s t.
Definition subAnd (s t : nat) : nat := Nat.land s t.
Definition comp (s : nat) : nat := Nat.lxor 7 s. (* 补集 *)

Definition allSubs : list nat := seq 0 8.
Definition inFam (m : nat) (s : nat) : bool := Nat.testbit m s.
Definition allFamMasks : list nat := seq 0 256.

(* ---------- 2. 模块五性质 ---------- *)

Inductive module_ : Type := MP | MS | ML | MF.

Definition hasUniv (m : nat) : bool := inFam m univ.
Definition noEmpty (m : nat) : bool := negb (inFam m 0).
Definition capClosed (m : nat) : bool :=
  forallb (fun s => forallb (fun t =>
    if andb (inFam m s) (inFam m t)
    then inFam m (subAnd s t) else true) allSubs) allSubs.
Definition cupClosed (m : nat) : bool :=
  forallb (fun s => forallb (fun t =>
    if andb (inFam m s) (inFam m t)
    then inFam m (subI s t) else true) allSubs) allSubs.
Definition upClosed (m : nat) : bool :=
  forallb (fun s => forallb (fun t =>
    if andb (inFam m s) (Nat.eqb (subAnd s t) s)   (* s ⊆ t *)
    then inFam m t else true) allSubs) allSubs.

Definition moduleOK (md : module_) (m : nat) : bool :=
  match md with
  | MP => andb (hasUniv m) (noEmpty m)
  | MS => andb (andb (hasUniv m) (noEmpty m)) (upClosed m)
  | ML => andb (andb (hasUniv m) (noEmpty m))
              (andb (capClosed m) (cupClosed m))
  | MF => andb (andb (hasUniv m) (noEmpty m))
              (andb (capClosed m) (upClosed m))
  end.

Definition allComplexes (md : module_) : list nat :=
  filter (moduleOK md) allFamMasks.

(* ---------- 3. 双层语义 ---------- *)

(* 内层（世界层）：原子/∧/⊃/¬/⊥；扩展=世界的位掩码。
   外层（∇ 层）：∇/∀/∃ 叶子 + 布尔连接——两层共用一个 AST，
   靠位置区分（样本不嵌套；文档线）。 *)
Inductive gform : Type :=
| gatom (n : nat)
| gand (a b : gform)
| gimp (a b : gform)
| gneg (a : gform)
| gfalse
| grad (a : gform)      (* ∇u a *)
| gall (a : gform)      (* ∀u a *)
| gex (a : gform).      (* ∃u a *)

Definition valAt (v : nat) (w n : nat) : bool :=
  Nat.testbit v (3 * n + w).

Fixpoint extOf (v : nat) (a : gform) : nat :=
  match a with
  | gatom n =>
      (if valAt v 0 n then 1 else 0)
    + (if valAt v 1 n then 2 else 0)
    + (if valAt v 2 n then 4 else 0)
  | gand x y => subAnd (extOf v x) (extOf v y)
  | gimp x y => subI (comp (extOf v x)) (extOf v y)
  | gneg x => comp (extOf v x)
  | gfalse => 0
  | _ => 0
  end.

Fixpoint evG (K v : nat) (f : gform) : bool :=
  match f with
  | gatom _ => false                    (* 原子不许出现在 ∇ 层 *)
  | gfalse => false
  | gand x y => andb (evG K v x) (evG K v y)
  | gimp x y => implb (evG K v x) (evG K v y)
  | gneg x => negb (evG K v x)
  | grad a => inFam K (extOf v a)
  | gall a => Nat.eqb (extOf v a) univ
  | gex a => negb (Nat.eqb (extOf v a) 0)
  end.

Definition allVals : list nat := seq 0 64.

Definition gvalid (md : module_) (f : gform) : bool :=
  forallb (fun K => forallb (fun v => evG K v f) allVals)
          (allComplexes md).

(* 反模型提取：首个弄假 (K,v) *)
Definition counterOf (md : module_) (f : gform) : option (nat * nat) :=
  find (fun p => negb (evG (fst p) (snd p) f))
       (flat_map (fun K => map (fun v => (K, v)) allVals)
                 (allComplexes md)).

(* ---------- 4. 断言电池：模块公理表的完全枚举 ---------- *)

Definition A0 : gform := gatom 0.
Definition B0 : gform := gatom 1.

(* 电一：⊕与∈——P 就够 *)
Example ax_universe : gvalid MP (gimp (gall A0) (grad A0)) = true.
Proof. vm_compute. reflexivity. Qed.

Example ax_nonvoid : gvalid MP (gimp (grad A0) (gex A0)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：∩——F 真，S 假 *)
Example ax_cap_F :
  gvalid MF (gimp (gand (grad A0) (grad B0)) (grad (gand A0 B0))) = true.
Proof. vm_compute. reflexivity. Qed.

Example ax_cap_S_fails :
  gvalid MS (gimp (gand (grad A0) (grad B0)) (grad (gand A0 B0))) = false.
Proof. vm_compute. reflexivity. Qed.

(* 电三：⊇（单调性）——F 真，L 假（L∩∪ 有而 ⊇ 无：与 F 不可比） *)
Definition monoAx : gform :=
  gimp (gand (gall (gimp A0 B0)) (grad A0)) (grad B0).

Example ax_mono_F : gvalid MF monoAx = true.
Proof. vm_compute. reflexivity. Qed.

Example ax_mono_L_fails : gvalid ML monoAx = false.
Proof. vm_compute. reflexivity. Qed.

(* 电四：一致性 ∇A∧∇¬A→⊥——F 真，P 假 *)
Example ax_cons_F :
  gvalid MF (gimp (gand (grad A0) (grad (gneg A0))) gfalse) = true.
Proof. vm_compute. reflexivity. Qed.

Example ax_cons_P_fails :
  gvalid MP (gimp (gand (grad A0) (grad (gneg A0))) gfalse) = false.
Proof. vm_compute. reflexivity. Qed.

(* 电五：反例方向 ∇A→∀A 在 F 假——反模型（主滤子 ↑{0}，A 只在世界 0） *)
Example grad_not_all : gvalid MF (gimp (grad A0) (gall A0)) = false.
Proof. vm_compute. reflexivity. Qed.

Compute (counterOf MF (gimp (grad A0) (gall A0))).

(* 电六：真滤子计数——3 元宇宙恰 7 个（每非空 S 一个主滤子 ↑S） *)
Example filter_count : length (allComplexes MF) = 7.
Proof. vm_compute. reflexivity. Qed.

(* 电七：模块格严格包含 |F| < |S| < |P| *)
Example module_strict :
  andb (Nat.ltb (length (allComplexes MF)) (length (allComplexes MS)))
       (Nat.ltb (length (allComplexes MS)) (length (allComplexes MP)))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 冒烟 *)
Compute (map (fun md => length (allComplexes md)) [MP; MS; ML; MF]).
Compute (counterOf ML monoAx).
