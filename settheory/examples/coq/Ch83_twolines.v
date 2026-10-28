(* 第 83 章：有限非 Archimedean 序（对偶数截断超有理数）。 *)
From Coq Require Import QArith Lqa.
Open Scope Q_scope.

Module Ch83.

(* 截断超有理数 a + b·ε（ε² = 0 的对偶数）：非 Archimedean 序的
   有限影子。真实的超实数 *ℝ 是模自由超滤子的商，构造留在正文。 *)
Record dual := mkDual {dRe : Q; dEp : Q}.

Definition dplus (x y : dual) : dual :=
  mkDual (dRe x + dRe y) (dEp x + dEp y).
Definition dmul (x y : dual) : dual :=
  mkDual (dRe x * dRe y) (dRe x * dEp y + dEp x * dRe y).
Definition dlt (x y : dual) : Prop :=
  (dRe x < dRe y)%Q \/ (dRe x = dRe y /\ (dEp x < dEp y)%Q).

Definition dz : dual := mkDual 0 0.
Definition d1 : dual := mkDual 1 0.
Definition eps : dual := mkDual 0 1.

(* ε 是无穷小：0 < ε。 *)
Lemma eps_pos : dlt dz eps.
Proof. right. split; [reflexivity | simpl; lra]. Qed.

(* 无穷小不等式的数值见证：ε < 1/n 对 n = 1..4。 *)
Example eps_lt_1 : dlt eps (mkDual (1#1) 0).
Proof. left. simpl; lra. Qed.

Example eps_lt_half : dlt eps (mkDual (1#2) 0).
Proof. left. simpl; lra. Qed.

Example eps_lt_third : dlt eps (mkDual (1#3) 0).
Proof. left. simpl; lra. Qed.

Example eps_lt_quarter : dlt eps (mkDual (1#4) 0).
Proof. left. simpl; lra. Qed.

(* Archimede 性质失效：1000·ε 仍小于 1。 *)
Example eps_times_1000 : dlt (dmul (mkDual 1000 0) eps) d1.
Proof. left. simpl; lra. Qed.

(* 对偶数律：(1+ε)² = 1 + 2ε（ε² = 0 截断）。 *)
Example one_plus_eps_sq :
  dmul (dplus d1 eps) (dplus d1 eps) = mkDual 1 2.
Proof. reflexivity. Qed.

(* 截断超越律：标准部分精确成立（Qeq 归一化后 1/1 = 1）。 *)
Example transfer_inv_7 :
  Qeq (dRe (dmul (mkDual (7#1) 0) (mkDual (1#7) 0))) 1.
Proof. reflexivity. Qed.

Example transfer_inv_13 :
  Qeq (dRe (dmul (mkDual (13#1) 0) (mkDual (1#13) 0))) 1.
Proof. reflexivity. Qed.

End Ch83.
