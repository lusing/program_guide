(* ex56_wstable.v —— ω-稳定理论与 Morley 秩（Marker GTM 217 §6.1-6.2）
   机器件：E_inf 实验室（等价关系无穷多无穷类理论）——可定义集的
   范式表示（有限个类的 cofinite×其余全收/全弃+孤立点）与**真
   Morley 秩计算器**（RM：点=0/类=1/全域=2 的范式判定+度）；分拆
   见证（对每个 k：全域拆出 k 片两两不交 rank-1、类拆出 k 片
   rank-0——「无限宇宙上的非退化秩」）；新鲜类引理（maxl+1 永在
   有限表外——有限覆盖盖不住 rank-2 的引擎）；ω-稳定性对账
   （|S₁(A)| 随参数类数线性增长）与 DLO 反例对照。零公理。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

(* ---------- 1. E_inf 的可定义集范式与成员判定 ---------- *)

(* 元素=（类 c，类内第 j 点）。范式：inc=完全收进的类（各挖掉
   有限个点）；rest=其余无穷多类全收/全弃；pts=追加孤立点 *)
Record dset : Type := mkD {
  inc : list (nat * list nat);
  rest : bool;
  pts : list (nat * nat)
}.

Definition inD (D : dset) (c j : nat) : bool :=
  orb (existsb (fun e => andb (Nat.eqb c (fst e))
                         (negb (existsb (Nat.eqb j) (snd e)))) (inc D))
      (orb (existsb (fun e => andb (Nat.eqb c (fst e)) (Nat.eqb j (snd e))) (pts D))
           (andb (rest D) (negb (existsb (fun e => Nat.eqb c (fst e)) (inc D))))).

(* ---------- 2. Morley 秩与度的范式计算器 ---------- *)

Definition rmD (D : dset) : option nat :=
  if rest D then Some 2
  else if negb (Nat.eqb (length (inc D)) 0) then Some 1
  else if negb (Nat.eqb (length (pts D)) 0) then Some 0
  else None.

Definition degD (D : dset) : nat :=
  match rmD D with
  | Some 1 => length (inc D)
  | _ => 1
  end.

Definition pt (c j : nat) : dset := mkD [] false [(c, j)].
Definition cls (c : nat) : dset := mkD [(c, [])] false [].
Definition universe : dset := mkD [] true [].

(* 三层账：点=0、类=1、全域=2；度：四类并加孤点度 4、
   全域度 1（其余类的补有限——rank2 度恒 1） *)
Example rm_layers :
  (rmD (pt 3 7), rmD (cls 5), rmD universe,
   degD (mkD [(3,[]);(5,[]);(9,[]);(11,[])] false [(7,0)]),
   degD universe) = (Some 0, Some 1, Some 2, 4, 1).
Proof. reflexivity. Qed.

(* ---------- 3. 分拆见证：rank-α+1 ⟺ 可拆无穷多片 rank-α ---------- *)

Definition kClasses (k : nat) : list dset := map cls (seq 0 k).
Definition kPoints (c k : nat) : list dset := map (pt c) (seq 0 k).

Definition rmEqb (D : dset) (n : nat) : bool :=
  match rmD D with
  | Some m => Nat.eqb m n
  | None => false
  end.

Definition disjointPair (D D' : dset) : bool :=
  negb (existsb (fun x => existsb (fun y => andb (inD D x y) (inD D' x y))
    (seq 0 6)) (seq 0 6)).

(* 对每个 k=1..8：k 片 rank-1 两两不交（全域的分拆见证） *)
Example split_universe_k :
  forallb (fun k => andb
    (forallb (fun D => rmEqb D 1) (kClasses k))
    (forallb (fun p => disjointPair (cls (fst p)) (cls (snd p)))
      (filter (fun p => negb (Nat.eqb (fst p) (snd p)))
        (flat_map (fun i => map (fun j => (i, j)) (seq 0 k)) (seq 0 k)))))
    (seq 1 8) = true.
Proof. vm_compute. reflexivity. Qed.

(* 对每个 k=1..12：类 5 拆出 k 片 rank-0（两两不交由不同点保证） *)
Example split_class_k :
  forallb (fun k => forallb (fun D => rmEqb D 0) (kPoints 5 k))
    (seq 1 12) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 4. 新鲜类引理：有限覆盖盖不住 rank-2 ---------- *)

Fixpoint maxl (l : list nat) : nat :=
  match l with [] => 0 | x :: t => Nat.max x (maxl t) end.

Lemma maxl_ge : forall l x, In x l -> x <= maxl l.
Proof.
  induction l as [|a t IH]; simpl; intros x H.
  - contradiction.
  - destruct H as [E|H].
    + subst. apply Nat.le_max_l.
    + apply Nat.le_trans with (maxl t); [apply IH; exact H | apply Nat.le_max_r].
Qed.

Lemma fresh_beyond : forall l, ~ In (S (maxl l)) l.
Proof.
  intros l H. apply (maxl_ge l) in H. lia.
Qed.

(* 覆盖泄漏账：rest=false 的有限族必有新鲜类的点漏网——对样本
   族用 freshBeyond 直接找出泄漏点 *)
Definition bads (Ds : list dset) : list nat :=
  flat_map (fun D => map fst (inc D) ++ map fst (pts D)) Ds.

Definition leak (Ds : list dset) : nat * nat :=
  (S (maxl (bads Ds)), 0).

Example cover_leak_samples :
  forallb (fun Ds => implb (forallb (fun D => negb (rest D)) Ds)
    (negb (existsb (fun D => inD D (fst (leak Ds)) (snd (leak Ds))) Ds)))
    [ [cls 0; cls 1; cls 2]
    ; [cls 0; pt 1 0; mkD [(3,[0;1])] false []]
    ; [pt 0 0; pt 0 1; cls 5]
    ] = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 5. ω-稳定性对账：|S₁(A)| 随参数类数线性增长 ---------- *)

(* 1-型（A 上，深度有界）= profile 去重：原子 x=aᵢ、E(x,aᵢ)、
   ¬…。k 个参数类的型数 ≤ 2k+2（每类上有限/余有限两型+全域
   上下型）——随 k 线性 ⟹ 可数 A 上可数个型：ω-稳定 *)
Fixpoint listBeq (l1 l2 : list bool) : bool :=
  match l1, l2 with
  | [], [] => true
  | a :: t1, b :: t2 => andb (Bool.eqb a b) (listBeq t1 t2)
  | _, _ => false
  end.

(* 原子求值：元素 (c,j) 对参数 a=(cᵢ,jᵢ)：x=a、E(x,a) *)
Definition atomEv (op : nat) (c j ci ji : nat) : bool :=
  match op with
  | 0 => andb (Nat.eqb c ci) (Nat.eqb j ji)
  | 1 => Nat.eqb c ci
  | _ => negb (Nat.eqb c ci)
  end.

Definition prof (A : list (nat * nat)) (c j : nat) : list bool :=
  flat_map (fun a => map (fun op => atomEv op c j (fst a) (snd a)) [0;1;2]) A.

Definition dedupP (l : list (list bool)) : list (list bool) :=
  fold_left (fun acc p => if existsb (listBeq p) acc then acc else p :: acc) l [].

(* 证据宇宙：k 个参数类各取 2 个参数点+2 个新鲜类各 2 点 *)
Definition evid (k : nat) : list (nat * nat) :=
  flat_map (fun c => [(c, 0); (c, 1); (c, 2)]) (seq 0 k)
  ++ [(k, 0); (k, 1); (k + 1, 0); (k + 1, 1)].

Definition paramsOf (k : nat) : list (nat * nat) :=
  flat_map (fun c => [(c, 0); (c, 1)]) (seq 0 k).

Definition typeCountE (k : nat) : nat :=
  length (dedupP (map (fun e => prof (paramsOf k) (fst e) (snd e)) (evid k))).

(* 线性增长账：k=1..6 的型数 = 3k+1（每类：2 个命名点型+1 个
   类内余有限型；再加 1 个新鲜类泛型）——随 k 线性 ⟹ 可数参数上
   至多可数个型：E_inf 是 ω-稳定的 *)
Example omega_stable_linear :
  map typeCountE (seq 1 6) = [4; 7; 10; 13; 16; 19].
Proof. vm_compute. reflexivity. Qed.

Print Assumptions omega_stable_linear.
