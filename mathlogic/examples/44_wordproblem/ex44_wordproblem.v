(* ex44_wordproblem.v —— 字问题与重写（Müller-Stach ch5）
   Thue 1910 系统：一切计算 = 项（字）替换序列——比 Turing 机早
   26 年的机器模型。机器件：Tseytin 半群九关系（书 p84 原例）的
   双向重写一步算子 rew1、深度界 BFS 闭包 rewStar、书内等式的应用
   链账本、aaa 不可达的有限影子（不可判定性的「找不到≠不存在」
   语义）、两条写法汇合样本。Novikov/Boone/Markov 与 PCP 表亲
   （53 章）记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

Definition word : Type := list nat.   (* 字母 a..e 编码 0..4 *)

(* ---------- 1. 一步双向重写 ---------- *)

Fixpoint strip (w p : word) : option word :=   (* w 前缀剥掉 p？ *)
  match p with
  | [] => Some w
  | pc :: pt => match w with
                | [] => None
                | wc :: wt => if Nat.eqb pc wc then strip wt pt else None
                end
  end.

Definition replaceAt (w : word) (i : nat) (p q : word) : option word :=
  match strip (skipn i w) p with
  | Some rest => Some (firstn i w ++ q ++ rest)
  | None => None
  end.

(* 每条规则两个方向、每个位置一次尝试 *)
Definition rew1Once (rs : list (word * word)) (w : word) : list word :=
  flat_map (fun r =>
    flat_map (fun i =>
      match replaceAt w i (fst r) (snd r) with
      | Some w1 => w1 :: match replaceAt w i (snd r) (fst r) with
                         | Some w2 => [w2] | None => [] end
      | None => match replaceAt w i (snd r) (fst r) with
                | Some w2 => [w2] | None => [] end
      end)
      (seq 0 (S (length w))))
    rs.

Fixpoint weqb (u v : word) : bool :=
  match u, v with
  | [], [] => true
  | x :: t, y :: t' => andb (Nat.eqb x y) (weqb t t')
  | _, _ => false
  end.

Definition inW (x : word) (l : list word) : bool := existsb (weqb x) l.

(* ---------- 2. 深度界 BFS 闭包 ---------- *)

Fixpoint closureW (d : nat) (rs : list (word * word))
        (seen frontier : list word) : list word :=
  match d with
  | 0 => seen
  | S d' =>
      let next := filter (fun x => negb (inW x seen))
                        (flat_map (rew1Once rs) frontier) in
      closureW d' rs (seen ++ next) next
  end.

Definition rewStar (d : nat) (rs : list (word * word)) (w : word) : list word :=
  closureW d rs [w] [w].

(* ---------- 3. Tseytin 半群九关系（书 p84 原例） ---------- *)

(* ac=ca, ad=da, bc=cb, bd=db, ce=eca, de=edb,
   cdca=cdcae, caaa=aaa, daaa=aaa *)
Definition RS : list (word * word) :=
  [ ([0;2], [2;0]);
    ([0;3], [3;0]);
    ([1;2], [2;1]);
    ([1;3], [3;1]);
    ([2;4], [4;2;0]);
    ([3;4], [4;3;1]);
    ([2;3;2;0], [2;3;2;0;4]);
    ([2;0;0;0], [0;0;0]);
    ([3;0;0;0], [0;0;0]) ].

(* 一步重写样本账（书内关系的直接应用） *)
Example rew1_ledger :
  [ inW [2;0] (rew1Once RS [0;2]);        (* ca ← ac 方向 *)
    inW [0;2] (rew1Once RS [2;0]);        (* ac ← ca 方向 *)
    inW [4;2;0] (rew1Once RS [2;4]);      (* eca ← ce（规则 5 正向） *)
    inW [2;4] (rew1Once RS [4;2;0]);      (* ce ← eca（规则 5 反向） *)
    inW [2;3;2;0;4] (rew1Once RS [2;3;2;0]);  (* cdcae ← cdca *)
    inW [2;3;2;0] (rew1Once RS [2;3;2;0;4]) ] (* cdca ← cdcae *)
  = [true; true; true; true; true; true].
Proof. reflexivity. Qed.

(* ---------- 4. 等式链账本 ---------- *)

(* cdca 与 cdcae 在深度界内互达（一条规则的两侧，BFS 双向收） *)
Example eq_chain_cdca :
  andb (inW [2;3;2;0;4] (rewStar 1 RS [2;3;2;0]))
       (inW [2;3;2;0] (rewStar 1 RS [2;3;2;0;4]))
  = true.
Proof. reflexivity. Qed.

(* 两条写法汇合样本：eca 与 ce 是同一元素的两种写法，
   深度 3 的闭包交集非空（合流的最小现场） *)
Definition interW (l1 l2 : list word) : list word :=
  filter (fun x => inW x l2) l1.

Definition nonemptyW (l : list word) : bool :=
  match l with [] => false | _ => true end.

Example confl_shadow :
  nonemptyW (interW (rewStar 3 RS [4;2;0]) (rewStar 3 RS [2;4]))
  = true.
Proof. reflexivity. Qed.

(* ---------- 5. aaa 不可达的有限影子 ---------- *)

(* 判定 w =_{RS} aaa 不可判定（Tseytin）；有限影子：
   从典型出发词（ce、de、cdca）在深度 5 内的闭包都不含 aaa *)
Example aaa_probe :
  [ negb (inW [0;0;0] (rewStar 5 RS [2;4]));
    negb (inW [0;0;0] (rewStar 5 RS [3;4]));
    negb (inW [0;0;0] (rewStar 5 RS [2;3;2;0])) ]
  = [true; true; true].
Proof. reflexivity. Qed.
(* 影子找不到 ≠ 不存在——「不可判定」说的是不存在任何算法对全部
   输入给答案；深度界的搜索恰恰是要被证明不可能的事的有限余像。
   caaa→aaa 规则只在字已含 aaa 时才 aplicable——而 e/c/d 出发的
   字在九关系下长不出三个连排的 a：这是「字问题的搜索树」现场。 *)

(* 冒烟：闭包规模（深度 5、自 ce） *)
Compute (length (rewStar 5 RS [2;4])).
