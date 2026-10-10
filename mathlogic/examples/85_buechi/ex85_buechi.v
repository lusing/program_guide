(* ex38 —— 自动机与 LTL 模型检查（Ben-Ari 3e §16.4-16.8）
   路线：程序 = 自动机；性质的否定 = Büchi 监视自动机（Ben-Ari
   16.18/16.19 的手工构造法）；同步积；**空性 = 无反例**；非空
   见证 = 「到达接受态且成环」——环 = 无穷反例路径的有限证书。

   教学版选择（docs/38 详述）：环用**后继函数** bsucc 表示（确定性
   Büchi），◇ 的不确定性猜测分解为「对每个可达起点分别试」——
   Ben-Ari 手推 NBA 的机器对应。监视自动机取 □◇p 的否定：
   「某一刻起 p 永不再真」——活状态上 ¬p 循环，遇 p 落入拒绝死点。

   机器件：baut + runFrom（轨道）+ findLoop（可达 × 接受 × 成环）
   + 旗舰 loop_accept_inf（环 ⟹ 无穷次过接受态——有限证书的
   无穷内容）。现场：K（p 轮流出现）无环判真；K'（p 一去不返）
   有环给出反例轨道。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Fixpoint inL (l : list nat) (x : nat) : bool :=
  match l with
  | [] => false
  | y :: l' => Nat.eqb y x || inL l' x
  end.

Fixpoint upto (n : nat) : list nat :=
  match n with 0 => [] | S m => upto m ++ [m] end.

(* ---------- 确定性 Büchi 自动机 ---------- *)

Record baut : Type := MkB {
  bS : list nat;          (* 状态表 *)
  bsucc : nat -> nat;     (* 后继（死点自环、不入 bF） *)
  bI : list nat;          (* 初态 *)
  bF : list nat           (* 接受态 *)
}.

(* 轨道：从 s 出发 t 步后的状态 *)
Fixpoint runFrom (bs : nat -> nat) (s : nat) (t : nat) : nat :=
  match t with
  | 0 => s
  | S t' => runFrom bs (bs s) t'
  end.

Lemma runFrom_add : forall bs a s b,
  runFrom bs s (a + b) = runFrom bs (runFrom bs s a) b.
Proof.
  intros bs a. induction a as [| a IH]; intros s b; simpl.
  - reflexivity.
  - apply IH.
Qed.

(* 可达集（从初态出发，fuel 化收集） *)
Fixpoint reachL (A : baut) (fuel : nat) (frontier seen : list nat)
  : list nat :=
  match fuel with
  | 0 => seen
  | S k =>
      match frontier with
      | [] => seen
      | s :: fr =>
          if inL seen s then reachL A k fr seen
          else reachL A k (map (bsucc A) fr ++ [bsucc A s]) (s :: seen)
      end
  end.

Definition reachSet (A : baut) : list nat := reachL A 64 (bI A) [].

(* 环检测：可达接受态 s 在某正步数回到自己 *)
Definition loopsAt (A : baut) (s : nat) : bool :=
  existsb (fun t => Nat.ltb 0 t && Nat.eqb (runFrom (bsucc A) s t) s) (upto 8).

Definition findLoop (A : baut) : bool :=
  existsb (fun s => inL (bF A) s && loopsAt A s) (reachSet A).

(* ---------- 旗舰：环 = 无穷接受的有限证书 ---------- *)

Theorem loop_accept_inf : forall (A : baut) s T,
  In s (bF A) -> runFrom (bsucc A) s T = s -> 0 < T ->
  forall n, exists t, n <= t /\ In (runFrom (bsucc A) s t) (bF A).
Proof.
  intros A s T Hacc Hloop HT n.
  assert (Hperiod : forall k, runFrom (bsucc A) s (k * T) = s).
  { induction k as [| k IH].
    - simpl. reflexivity.
    - rewrite Nat.mul_succ_l, runFrom_add, IH. exact Hloop. }
  assert (Hmult : forall m, exists k, m <= k * T).
  { intro m. exists (S m).
    destruct T as [| T']; [lia |].
    rewrite Nat.mul_succ_r. lia. }
  destruct (Hmult n) as [k Hk].
  exists (k * T). split; [exact Hk |].
  rewrite (Hperiod k). exact Hacc.
Qed.

(* ---------- 现场：□◇p 的模型检查 ---------- *)

(* 模型 K：0→1→2→0 三循环，p 只在 0 —— p 轮流出现，□◇p 真 *)
Definition dead : nat := 9.

Definition labelK (k : nat) : bool :=
  match k with 0 => true | _ => false end.   (* p 只在 0 *)

Definition succK (k : nat) : nat :=
  match k with 0 => 1 | 1 => 2 | 2 => 0 | _ => dead end.

(* 监视积：活状态遇 p 落死点（「p 永不再真」的承诺破产），
   死点自环且不入接受表 *)
Definition PK : baut :=
  {| bS := [0; 1; 2; dead];
     bsucc := fun k => if labelK k then dead else succK k;
     bI := [0; 1; 2];      (* ◇ 的相位猜测：每个可达起点都试 *)
     bF := [0; 1; 2] |}.

(* 模型 K'：0→1→2→1 —— 离开 0 后 p 一去不返，□◇p 假 *)
Definition succK' (k : nat) : nat :=
  match k with 0 => 1 | 1 => 2 | 2 => 1 | _ => dead end.

Definition PK' : baut :=
  {| bS := [0; 1; 2; dead];
     bsucc := fun k => if labelK k then dead else succK' k;
     bI := [0; 1; 2];      (* ◇ 的相位猜测：每个可达起点都试 *)
     bF := [0; 1; 2] |}.

(* K：无活环 —— □◇p 成立 *)
Example good_no_loop : findLoop PK = false.
Proof. reflexivity. Qed.

(* K'：活环在 {1,2} —— 反例轨道从 1 出发 *)
Example bad_loop_found : findLoop PK' = true.
Proof. reflexivity. Qed.

(* 反例轨道读出：从 1 出发永远绕 {1,2}（p 永不再真） *)
Example counterex_orbit :
  map (runFrom (bsucc PK') 1) (upto 7) = [1; 2; 1; 2; 1; 2; 1].
Proof. reflexivity. Qed.

(* 反例轨道是无穷次接受：直接调用旗舰 *)
Corollary counterex_inf : forall n,
  exists t, n <= t /\ In (runFrom (bsucc PK') 1 t) (bF PK').
Proof.
  intros n. apply (loop_accept_inf PK' 1 2).
  - simpl. auto.
  - reflexivity.
  - lia.
Qed.
