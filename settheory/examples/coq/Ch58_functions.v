(* 第 58 章：函数的机器化（Makinson Ch3）
   鸽笼原理（列表版：单射保 NoDup → 长度保持）+ 三道应用证书
   + 特征函数同构 + 四函数的像与闭包。全部 vm_compute 可判。 *)
From Coq Require Import List Arith Lia Bool.
Import ListNotations.

(* ---------- 单射保持无重复 ---------- *)
Definition injective_on (f : nat -> nat) (l : list nat) : Prop :=
  forall x y, In x l -> In y l -> f x = f y -> x = y.

Lemma nodup_map_inj : forall (f : nat -> nat) l,
    NoDup l -> injective_on f l -> NoDup (map f l).
Proof.
  induction l as [|a xs IH]; intros Hnd Hinj; simpl.
  - constructor.
  - inversion Hnd; subst.
    constructor.
    + intros Hin. apply in_map_iff in Hin.
      destruct Hin as [y [Hy Hiny]].
      assert (a = y) by (apply Hinj; simpl; auto).
      subst y. contradiction.
    + apply IH; [assumption|].
      intros x y Hx Hy; apply Hinj; simpl; auto.
Qed.

(* ---------- 碰撞检测器 ---------- *)
Definition collision_on (f : nat -> nat) (n : nat) : bool :=
  existsb (fun i => existsb (fun j =>
    andb (Nat.ltb i j) (Nat.eqb (f i) (f j))) (seq 0 n)) (seq 0 n).

(* 鸽笼原理：10 鸽 9 洞（i mod 9）必有碰撞 *)
Example cert_pigeon10 : collision_on (fun i => i mod 9) 10 = true.
Proof. vm_compute. reflexivity. Qed.

(* 9 鸽 9 洞可以无碰撞 *)
Example cert_pigeon9 : collision_on (fun i => i mod 9) 9 = false.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 三道书本应用的数字证书 ---------- *)
(* 677 会员 vs 26*26 缩写空间 *)
Example cert_initials : 26 * 26 = 676 /\ 677 > 676.
Proof. lia. Qed.

(* 97 学生 vs 2^5 答案纸，4 人同卷 *)
Example cert_exam : 2 ^ 5 = 32 /\ 3 * 32 + 1 = 97.
Proof. vm_compute. lia. Qed.

(* 400 村民 vs 366 天与 33*12 月 *)
Example cert_village : 400 > 366 /\ 400 > 33 * 12.
Proof. lia. Qed.

(* ---------- 平方函数：域依赖的证书 ---------- *)
(* 在 0..9（ℕ 的一段）上无碰撞：单射 *)
Example cert_sq_nat : collision_on (fun n => n * n) 10 = false.
Proof. vm_compute. reflexivity. Qed.

(* 在 -9..9（含负数，平移到 0..19 再减 9）上有碰撞 *)
Definition shifted_sq (i : nat) : nat :=
  let z := match i with 0 => 0 | S m => S m end in (z - 9) * (z - 9).

Example cert_sq_int : collision_on (fun i =>
    let z := i - 9 in z * z) 19 = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 特征函数与子集一一对应 ---------- *)
Definition chi (s : list nat) (u : nat) : bool := existsb (Nat.eqb u) s.

(* 交并补与与或非逐点同构（在 4 元宇宙上穷举） *)
Example cert_chi_hom :
  forallb (fun u =>
    andb (Bool.eqb (chi [1;2] u && chi [2;3] u) (chi [2] u))
         (Bool.eqb (chi [1;2] u || chi [2;3] u) (chi [1;2;3] u)))
    (seq 0 4) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 四函数的像与闭包（书本 3.2.2 的数字侧写） ---------- *)
Definition incl_check (s t : list nat) : bool :=
  forallb (fun x => existsb (Nat.eqb x) t) s.

Fixpoint iter_image (fuel : nat) (f : nat -> nat) (s : list nat)
  : list nat :=
  match fuel with
  | 0 => s
  | S g =>
      let t := filter (fun x => negb (existsb (Nat.eqb x) s)) (map f s) in
      iter_image g f (s ++ t)
  end.

(* square 的闭包：{2} → {2,4,16,256,…} *)
Example cert_square_closure :
  incl_check (iter_image 3 (fun n => n * n) [2]) [2;4;16;256] = true /\
  incl_check [2] (iter_image 3 (fun n => n * n) [2]) = true.
Proof. vm_compute. repeat split; reflexivity. Qed.
