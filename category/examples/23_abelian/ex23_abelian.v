(* ex23 —— 加法范畴与 Abel 范畴（贺伟第 4 章）
   三书对位：贺伟 4.1-4.3 /《高级范畴论》第 4 章。

   旗舰 1：biproduct_is_product（引理 4.1.6）——五条分块/合成
   等式 ⟹ (C,p1,p2) 是积：中介 h = q1f + q2g，唯一性是
   「1 = q1p1 + q2p2」的算术消去。抽象 Preadd 记录上零公理。
   旗舰 2：单对象准加法 = 半环（nat 版）：双线性 = 分配律。
   附：引理 4.1.5 的 1_A = 0 ⟹ 始对象（零对象的算术身份）。 *)

Require Import Arith.

(* ---------- 准加法范畴（Hom 为交换幺半群的机器近似版：
   群逆元留给 ℤ 升级，文档已注明） ---------- *)

Record Preadd : Type := mkPre {
  pObj : Type;
  pHom : pObj -> pObj -> Set;
  pidn : forall a, pHom a a;
  pcomp : forall {a b c}, pHom a b -> pHom b c -> pHom a c;
  pidL : forall {a b} (f : pHom a b), pcomp (pidn a) f = f;
  pidR : forall {a b} (f : pHom a b), pcomp f (pidn b) = f;
  passoc : forall {a b c d} (f : pHom a b) (g : pHom b c) (h : pHom c d),
             pcomp (pcomp f g) h = pcomp f (pcomp g h);
  pzero : forall a b, pHom a b;
  padd : forall {a b}, pHom a b -> pHom a b -> pHom a b;
  paddC : forall {a b} (f g : pHom a b), padd f g = padd g f;
  paddA : forall {a b} (f g h : pHom a b),
            padd (padd f g) h = padd f (padd g h);
  padd0R : forall {a b} (f : pHom a b), padd f (pzero a b) = f;
  pzeroL : forall {a b c} (g : pHom b c) (f : pHom a b),
             pcomp (pzero a b) g = pzero a c;
  pzeroR : forall {a b c} (f : pHom a b) (g : pHom b c),
             pcomp f (pzero b c) = pzero a c;
  pdistR : forall {a b c} (f g : pHom a b) (h : pHom b c),
             pcomp (padd f g) h = padd (pcomp f h) (pcomp g h);
  pdistL : forall {a b c} (f : pHom a b) (g g' : pHom b c),
             pcomp f (padd g g') = padd (pcomp f g) (pcomp f g')
}.

(* ---------- 旗舰 1：双积（引理 4.1.6） ---------- *)

Section Biproduct.
Variable P : Preadd.
Variables (a b c : pObj P)
         (p1 : pHom P c a) (p2 : pHom P c b)
         (q1 : pHom P a c) (q2 : pHom P b c).

Hypothesis H11 : pcomp P q1 p1 = pidn P a.   (* p1∘q1 = 1A *)
Hypothesis H22 : pcomp P q2 p2 = pidn P b.   (* p2∘q2 = 1B *)
Hypothesis H12 : pcomp P q2 p1 = pzero P b a.  (* p1∘q2 = 0 *)
Hypothesis H21 : pcomp P q1 p2 = pzero P a b.  (* p2∘q1 = 0 *)
Hypothesis Hsum : padd P (pcomp P p1 q1) (pcomp P p2 q2) = pidn P c.

(* 中介公式 h = q1∘f + q2∘g *)
Definition bpMed (x : pObj P) (f : pHom P x a) (g : pHom P x b)
  : pHom P x c := padd P (pcomp P f q1) (pcomp P g q2).

Lemma bpMed_p1 : forall x (f : pHom P x a) (g : pHom P x b),
  pcomp P (bpMed x f g) p1 = f.
Proof.
  intros x f g. unfold bpMed.
  rewrite pdistR.                     (* (u+v);p1 = u;p1 + v;p1 *)
  rewrite passoc, H11, pidR.          (* (f;q1);p1 = f;1 = f *)
  rewrite passoc, H12.                (* (g;q2);p1 = g;0 *)
  rewrite (pzeroR P (a:=x) (b:=b) (c:=a) g (pzero P b a)).
  rewrite (padd0R P (a:=x) (b:=a) f).
  reflexivity.
Qed.

Lemma bpMed_p2 : forall x (f : pHom P x a) (g : pHom P x b),
  pcomp P (bpMed x f g) p2 = g.
Proof.
  intros x f g. unfold bpMed.
  rewrite pdistR.
  rewrite passoc, H21.
  rewrite (pzeroR P (a:=x) (b:=a) (c:=b) f (pzero P a b)).
  rewrite (paddC P (a:=x) (b:=b) (pzero P x b) (pcomp P (pcomp P g q2) p2)).
  rewrite (padd0R P (a:=x) (b:=b) (pcomp P (pcomp P g q2) p2)).
  rewrite passoc, H22, pidR. reflexivity.
Qed.

(* 唯一性：h' = 1;h' = (q1p1+q2p2)... 算术消去 *)
Lemma bpMed_unique : forall x (f : pHom P x a) (g : pHom P x b)
  (h' : pHom P x c),
  pcomp P h' p1 = f -> pcomp P h' p2 = g -> h' = bpMed x f g.
Proof.
  intros x f g h' Hf Hg.
  unfold bpMed.
  (* h' = h';1C = h';(p1q1 + p2q2) = (h';p1);q1 + (h';p2);q2
        = f;q1 + g;q2 *)
  rewrite <- (pidR P h'), <- Hsum, pdistL.
  rewrite <- (passoc P h' p1 q1), <- Hf.
  rewrite <- (passoc P h' p2 q2), <- Hg.
  reflexivity.
Qed.

(* 打包成积的泛性质 *)
Theorem biproduct_is_product : forall (x : pObj P)
  (f : pHom P x a) (g : pHom P x b),
  { h : pHom P x c |
      pcomp P h p1 = f /\ pcomp P h p2 = g /\
      forall h', pcomp P h' p1 = f -> pcomp P h' p2 = g -> h' = h }.
Proof.
  intros x f g. exists (bpMed x f g).
  split; [apply bpMed_p1|]. split; [apply bpMed_p2|].
  exact (bpMed_unique x f g).
Qed.

End Biproduct.

(* ---------- 引理 4.1.5 的一半：1_A = 0 ⟹ 始对象 ---------- *)

Lemma one_zero_initial : forall (P : Preadd) (a : pObj P),
  pidn P a = pzero P a a ->
  forall b, { f : pHom P a b | forall g, g = f }.
Proof.
  intros P a H b. exists (pzero P a b).
  intros g.
  assert (Hkey : g = pcomp P (pidn P a) g) by (symmetry; apply pidL).
  rewrite H in Hkey.
  rewrite (pzeroL P (a:=a) (b:=a) (c:=b) g (pzero P a a)) in Hkey.
  exact Hkey.
Qed.

(* ---------- 旗舰 2：单对象准加法 = 半环（nat 版） ---------- *)

Definition natSemiPreadd : Preadd := {|
  pObj := unit;
  pHom := fun _ _ => nat;
  pidn := fun _ => 1;
  pcomp := fun _ _ _ f g => g * f;          (* 图序：f;g = g*f *)
  pidL := fun _ _ f => Nat.mul_1_r f;      (* f;1 = 1*f *)
  pidR := fun _ _ f => Nat.mul_1_l f;      (* 1;f = f*1 *)
  passoc := fun _ _ _ _ f g h => Nat.mul_assoc h g f;
  pzero := fun _ _ => 0;
  padd := fun _ _ f g => f + g;
  paddC := fun _ _ f g => Nat.add_comm f g;
  paddA := fun _ _ f g h => eq_sym (Nat.add_assoc f g h);
  padd0R := fun _ _ f => Nat.add_0_r f;
  pzeroL := fun _ _ _ g f => Nat.mul_0_r g;          (* 0;g = g*0 *)
  pzeroR := fun _ _ _ f g => Nat.mul_0_l f;          (* f;0 = 0*f *)
  pdistR := fun _ _ _ f g h => Nat.mul_add_distr_l h f g;   (* (f+g);h = h*(f+g) *)
  pdistL := fun _ _ _ f g g' => Nat.mul_add_distr_r g g' f (* f;(g+g') = (g+g')*f *)
|}.

(* 双线性四项律（贺伟 4.1.1 的原文）在 nat 上就是乘法分配 *)
Example bilinear_nat : forall f f' g g' : nat,
  g' * (g * (f' + f)) = g' * (g * f') + g' * (g * f).
Proof.
  intros f f' g g'. ring.
Qed.

Print Assumptions biproduct_is_product.
Print Assumptions one_zero_initial.
