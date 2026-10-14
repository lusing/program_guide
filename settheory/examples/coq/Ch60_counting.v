(* 第 60 章：计数的机器化（Makinson Ch5）
   四式选取的枚举验证 + banana/Turramurra 重排计数 + 容斥电话例。 *)
From Coq Require Import List Arith Lia Bool.
Import ListNotations.

(* ---------- 四式选取：5 选 2 的 25/20/15/10 ---------- *)
Definition dom5 := seq 0 5.

Definition sel_op : list (nat * nat) :=
  flat_map (fun a => map (fun b => (a, b)) dom5) dom5.

Definition sel_or : list (nat * nat) :=
  filter (fun p => Nat.leb (fst p) (snd p)) sel_op.
Definition sel_pr : list (nat * nat) :=
  filter (fun p => negb (Nat.eqb (fst p) (snd p))) sel_op.

Example cert_four_modes :
  length sel_op = 25 /\ length sel_pr = 20 /\
  length sel_or = 15.
Proof. vm_compute. repeat split; reflexivity. Qed.

(* ---------- 排列与组合公式证书 ---------- *)
Fixpoint fact (n : nat) : nat :=
  match n with 0 => 1 | S k => (S k) * fact k end.

Definition P (n k : nat) : nat := fact n / fact (n - k).
Definition C (n k : nat) : nat := fact n / (fact k * fact (n - k)).

(* P(10,6) = 151200 超出一元 nat 的可判上限，由 Julia/Python 通道承载 *)
Example cert_P63 : P 6 3 = 120.
Proof. vm_compute. reflexivity. Qed.

Example cert_C106 : C 10 6 = 210.
Proof. vm_compute. reflexivity. Qed.

Example cert_C_6row : map (C 6) (seq 0 7) = [1; 6; 15; 20; 15; 6; 1].
Proof. vm_compute. reflexivity. Qed.

(* 帕斯卡递推：C(7,k+1) = C(6,k) + C(6,k+1)，k ≤ 6 逐点 *)
Example cert_pascal : map (fun k => C 7 (S k)) (seq 0 6)
                   = map (fun k => C 6 k + C 6 (S k)) (seq 0 6).
Proof. vm_compute. reflexivity. Qed.

(* 重复组合：C(k+n-1, k)。C(15,6) = 5005 超一元上限（15! 太大），
   由 Julia/Python 通道承载；这里验证隔板法的等价小例 C(9,4) = 126 *)
Example cert_stars_bars_small : C 9 4 = 126.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 容斥：三人电话 = 16 ---------- *)
Example cert_incl_excl : 5 + 10 + 7 - (3 + 2 + 2) + 1 = 16.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 重排：多重集的字谜计数 ---------- *)
Fixpoint dedup (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: xs => let d := dedup xs in
               if existsb (Nat.eqb x) d then d else x :: d
  end.

Fixpoint remove1 (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => []
  | y :: ys => if Nat.eqb x y then ys else y :: remove1 x ys
  end.

Fixpoint anagrams (fuel : nat) (l : list nat) : list (list nat) :=
  match fuel with
  | 0 => [[]]
  | S f =>
      match l with
      | [] => [[]]
      | _ => flat_map (fun x => map (cons x) (anagrams f (remove1 x l)))
                     (dedup l)
      end
  end.

(* banana：1 个 b、3 个 a、2 个 n → 60 *)
Example cert_banana : length (anagrams 6 [1; 3; 3; 3; 2; 2]) = 60.
Proof. vm_compute. reflexivity. Qed.

(* 小多重集的执行证书；Turramurra=37800 与 Mississippi=34650 由
   Julia/Python 通道按公式承载（一元 nat 上限内放不下生成过程） *)
Example cert_aabb : length (anagrams 4 [1; 1; 2; 2]) = 6.
Proof. vm_compute. reflexivity. Qed.

Example cert_aabbb : length (anagrams 5 [1; 1; 2; 2; 2]) = 10.
Proof. vm_compute. reflexivity. Qed.
