(* 第 57 章：关系的机器化（Makinson Ch2）
   三点集上全部 512 个关系的人口普查 + 关系代数（连接/投影/复合）+
   传递闭包的迭代计算。全部由 vm_compute 出证书。 *)
From Coq Require Import List Arith Lia Bool.
Import ListNotations.

(* ---------- 三元组取分量 ---------- *)
Definition fst3 (t : nat*nat*nat) : nat := match t with (a,_,_) => a end.
Definition snd3 (t : nat*nat*nat) : nat := match t with (_,b,_) => b end.
Definition thd3 (t : nat*nat*nat) : nat := match t with (_,_,c) => c end.

(* ---------- 三元域与全部关系 ---------- *)
Definition d3 : list nat := [0;1;2].
Definition pairs3 : list (nat * nat) :=
  flat_map (fun x => map (fun y => (x,y)) d3) d3.

Fixpoint powersetT {A} (l : list A) : list (list A) :=
  match l with
  | [] => [[]]
  | x :: xs => let rest := powersetT xs in rest ++ map (cons x) rest
  end.

Definition rels3 : list (list (nat*nat)) := powersetT pairs3.

Definition inr (p : nat*nat) (r : list (nat*nat)) : bool :=
  existsb (fun q => (Nat.eqb (fst p) (fst q)) && (Nat.eqb (snd p) (snd q))) r.

Definition subrel (r s : list (nat*nat)) : bool :=
  forallb (fun p => inr p s) r.

Definition inr3 (t : nat*nat*nat) (l : list (nat*nat*nat)) : bool :=
  existsb (fun u => (Nat.eqb (fst3 t) (fst3 u)) &&
                   ((Nat.eqb (snd3 t) (snd3 u)) && (Nat.eqb (thd3 t) (thd3 u)))) l.

Definition subrel3 (r s : list (nat*nat*nat)) : bool :=
  forallb (fun t => inr3 t s) r.

(* ---------- 性质判定子 ---------- *)
Definition refl3 r := forallb (fun a => inr (a,a) r) d3.
Definition irrefl3 r := forallb (fun a => negb (inr (a,a) r)) d3.
Definition sym3 r :=
  forallb (fun p => if inr p r then inr (snd p, fst p) r else true) pairs3.
Definition trans3 r :=
  forallb (fun p => forallb (fun q =>
     if (inr p r) && ((Nat.eqb (snd p) (fst q)) && inr q r)
     then inr (fst p, snd q) r else true) pairs3) pairs3.
Definition antisym3 r :=
  forallb (fun p => forallb (fun q =>
     if (inr p r) && ((inr q r) && ((Nat.eqb (snd p) (fst q)) &&
                    (Nat.eqb (snd q) (fst p))))
     then Nat.eqb (fst p) (fst q) else true) pairs3) pairs3.
Definition total3 r :=
  forallb (fun p => inr p r || inr (snd p, fst p) r) pairs3.

Definition equiv3 r := (refl3 r) && ((sym3 r) && (trans3 r)).
Definition poset3 r := (refl3 r) && ((antisym3 r) && (trans3 r)).
Definition linear3 r := (poset3 r) && (total3 r).

Definition countf (f : list (nat*nat) -> bool) : nat :=
  length (filter f rels3).

(* ---------- 人口普查：512 个关系的分类账 ---------- *)
Theorem census :
  countf refl3 = 64 /\
  countf sym3 = 64 /\
  countf irrefl3 = 64 /\
  countf trans3 = 171 /\
  countf antisym3 = 216 /\
  countf equiv3 = 5 /\
  countf poset3 = 19 /\
  countf linear3 = 6.
Proof. vm_compute. repeat split; reflexivity. Qed.

Theorem total_rels : countf (fun _ => true) = 512.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 关系代数：书本 2.3.2 数字例子 ---------- *)

(* 整除关系 a ∣ b（A={2,3,13}，B={12,15,17}） *)
Definition Rdiv : list (nat*nat) :=
  filter (fun p => Nat.eqb (snd p mod fst p) 0)
    (flat_map (fun a => map (fun b => (a,b)) [12;15;17]) [2;3;13]).

(* 同奇偶关系 b ≈ c（B 到 C={11,16,21}） *)
Definition Spar : list (nat*nat) :=
  filter (fun p => Nat.eqb ((fst p) mod 2) ((snd p) mod 2))
    (flat_map (fun b => map (fun c => (b,c)) [11;16;21]) [12;15;17]).

(* join(R,S)：三元组；复合 S∘R = join 到首尾坐标的投影 *)
Definition joinRS : list (nat*nat*nat) :=
  flat_map (fun p => map (fun q => (fst p, snd p, snd q))
    (filter (fun q => Nat.eqb (snd p) (fst q)) Spar)) Rdiv.

Definition compSR : list (nat*nat) :=
  map (fun t => (fst3 t, thd3 t)) joinRS.

Example cert_Rdiv :
  subrel Rdiv [(2,12);(3,12);(3,15)] = true /\
  subrel [(2,12);(3,12);(3,15)] Rdiv = true.
Proof. vm_compute. repeat split; reflexivity. Qed.

Example cert_Spar :
  subrel Spar [(12,16);(15,11);(15,21);(17,11);(17,21)] = true /\
  subrel [(12,16);(15,11);(15,21);(17,11);(17,21)] Spar = true.
Proof. vm_compute. repeat split; reflexivity. Qed.

(* 书本答案：join(R,S) = {(2,12,16),(3,12,16),(3,15,11),(3,15,21)} *)
Example cert_join :
  subrel3 joinRS [(2,12,16);(3,12,16);(3,15,11);(3,15,21)] = true /\
  length joinRS = 4.
Proof. vm_compute. repeat split; reflexivity. Qed.

(* 投影：join 到 A×C = {(2,16),(3,16),(3,11),(3,21)} *)
Example cert_proj :
  subrel compSR [(2,16);(3,16);(3,11);(3,21)] = true /\
  subrel [(2,16);(3,16);(3,11);(3,21)] compSR = true.
Proof. vm_compute. repeat split; reflexivity. Qed.

(* ---------- 传递闭包：迭代法 + 环路例子 ---------- *)
Definition comp_rel (r s : list (nat*nat)) : list (nat*nat) :=
  flat_map (fun p => map (fun q => (fst p, snd q))
    (filter (fun q => Nat.eqb (snd p) (fst q)) s)) r.

Fixpoint iter_close (fuel : nat) (r : list (nat*nat)) : list (nat*nat) :=
  match fuel with
  | 0 => r
  | S f => iter_close f (r ++ comp_rel r r)
  end.

(* R = {(0,1),(1,2),(2,0)}：三点环的传递闭包 = 全关系（9 对都在） *)
Definition cycle := [(0,1);(1,2);(2,0)].

Example cert_cycle_closure :
  forallb (fun p => inr p (iter_close 4 cycle)) pairs3 = true.
Proof. vm_compute. reflexivity. Qed.

(* 对称关系的复合可以不对称：S∘R 含 (1,3) 不含 (3,1) *)
Definition Rs := [(1,2);(2,1)].
Definition Ss := [(2,3);(3,2)].

Example cert_sym_comp :  (* S∘R：先 Rs 后 Ss *)
  inr (1,3) (comp_rel Rs Ss) = true /\
  inr (3,1) (comp_rel Rs Ss) = false.
Proof. vm_compute. repeat split; reflexivity. Qed.

(* (R⁺)⁻¹ = (R⁻¹)⁺：双向包含证书 *)
Definition conv (r : list (nat*nat)) : list (nat*nat) :=
  map (fun p => (snd p, fst p)) r.

Example cert_conv_closure :
  subrel (conv (iter_close 4 cycle)) (iter_close 4 (conv cycle)) = true /\
  subrel (iter_close 4 (conv cycle)) (conv (iter_close 4 cycle)) = true.
Proof. vm_compute. repeat split; reflexivity. Qed.
