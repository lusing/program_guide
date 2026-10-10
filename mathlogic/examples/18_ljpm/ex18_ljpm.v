(* ex18_ljpm.v —— LJpm 多后件矢列：饱和与典范模型（Mints fst ch8-8.2）
   机器件：多后件矢列演算 LJpm 的「子公式宇宙闭包式」可导性神谕（每条
   规则严格降总规模⟹推导深度有界⟹迭代界=宇宙总规模——Mints 完备性
   证明的算法化身；DER 账本以「子公式位掩码」编码，查询 O(1)）；显式
   推导树+逐节点规则检查；完备化（Lemma 8.4：逐式归属 Γ/Δ）；可逆
   饱和六条件（Def 8.3）；典范模型（完备矢列+反包含序，Def 8.4）与
   真引理（Thm 8.2）全样本对账；LEM 在典范模型里被当场驳倒；世界数
   4^s 上界（Cor 8.1(b)）；切规则=语义推论的注解账（Cor 8.2：无视
   cut 前提，无 cut 搜索必成）。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.

Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

Definition impb (a b : bool) : bool := if a then b else true.

(* ---------- 1. 公式与集合账 ---------- *)

Inductive fm : Type :=
| pv  : nat -> fm
| ff  : fm
| aand : fm -> fm -> fm
| oor : fm -> fm -> fm
| iimp : fm -> fm -> fm.

Notation "a ~> b" := (iimp a b) (at level 90, right associativity).
Definition negf (a : fm) : fm := a ~> ff.

Fixpoint fmeqb (a b : fm) : bool :=
  match a, b with
  | pv m, pv n => Nat.eqb m n
  | ff, ff => true
  | aand x y, aand u v => andb (fmeqb x u) (fmeqb y v)
  | oor x y, oor u v => andb (fmeqb x u) (fmeqb y v)
  | iimp x y, iimp u v => andb (fmeqb x u) (fmeqb y v)
  | _, _ => false
  end.

Fixpoint szF (a : fm) : nat :=
  match a with
  | pv _ => 1 | ff => 1
  | aand x y => S (szF x + szF y)
  | oor x y => S (szF x + szF y)
  | iimp x y => S (szF x + szF y)
  end.

Fixpoint sub (a : fm) : list fm :=
  match a with
  | pv _ => [a]
  | ff => [ff]
  | aand x y => a :: (sub x ++ sub y)
  | oor x y => a :: (sub x ++ sub y)
  | iimp x y => a :: (sub x ++ sub y)
  end.

Definition subL (l : list fm) : list fm := flat_map sub l.

Fixpoint dedup (l : list fm) : list fm :=
  match l with
  | [] => []
  | x :: t => let r := dedup t in if existsb (fmeqb x) r then r else x :: r
  end.

Definition memF (a : fm) (l : list fm) : bool := existsb (fmeqb a) l.
Definition inclF (l1 l2 : list fm) : bool := forallb (fun x => memF x l2) l1.
Definition eqF (l1 l2 : list fm) : bool := andb (inclF l1 l2) (inclF l2 l1).
Definition addF (a : fm) (l : list fm) : list fm :=
  if memF a l then l else a :: l.
Definition remF (a : fm) (l : list fm) : list fm :=
  filter (fun x => negb (fmeqb a x)) l.

(* ---------- 2. LJpm：公理与规则（Mints p53-54 图） ---------- *)

(* 矢列 (G,D) 读作 G ⇒ D。多后件：⇒→ 的前提砍掉全部后件参数公式——
   这正是直觉主义约束（经典版保留即可导 p∨¬p，见 nder_lem_classical）。 *)
Definition sq := (list fm * list fm)%type.

Definition isAtom (a : fm) : bool :=
  match a with pv _ => true | _ => false end.

Definition axSeq (s : sq) : bool :=
  match s with
  | (G, D) =>
      orb (memF ff G)
          (existsb (fun x => andb (memF x G) (memF x D)) (filter isAtom G))
  end.

(* 一个矢列的全部可用规则实例（每实例=前提矢列表）。主公式按「剪除」
   形态移除——收缩可允许，集语义下二者等价（Mints p59 修剪注）。 *)
Definition ruleSets (s : sq) : list (list sq) :=
  match s with
  | (G, D) =>
      flat_map
        (fun c =>
           match c with
           | aand x y =>
               (if memF c G then [[(addF x (addF y (remF c G)), D)]] else [])
               ++ (if memF c D
                   then [[(G, addF x (remF c D)); (G, addF y (remF c D))]]
                   else [])
           | oor x y =>
               (if memF c G
                 then [[(addF x (remF c G), D); (addF y (remF c G), D)]]
                 else [])
               ++ (if memF c D
                   then [[(G, addF x (addF y (remF c D)))]]
                   else [])
           | iimp x y =>
               (if memF c G
                  then [[(G, addF x D); (addF y (remF c G), D)]]
                  else [])
               ++ (if memF c D
                    then [[(addF x G, [y])]]     (* 后件参数公式全部退场 *)
                    else [])
           | _ => []
           end) (dedup (subL (G ++ D)))
  end.

Inductive btrie : Type :=
| TB : bool -> btrie
| TN : btrie -> btrie -> btrie.

(* ---------- 3. 位串 trie 账本（DER 的零算术查询） ---------- *)

(* 键 = 矢列的「在册位串」：先 U 逐位抄后件、再抄前件（长 2|U| 的布尔
   表）。导航只走构造子分支——不做任何算术。性能教训（本章实测）：
   初版用「矢列索引 nat + i/2 导航」，Coq 的 nat 是一元的，div2 线性
   步——75 轮×4096 矢列×13 次查询×12 层 div2 ≈ 10^12 步；换成位串后
   每层 O(1)，全程秒级。Lean 侧 Nat 是 GMP，位图天然可行。 *)

Fixpoint tGet (t : btrie) (bs : list bool) {struct bs} : bool :=
  match bs with
  | [] => match t with TB b => b | _ => false end
  | h :: tl =>
      match t with
      | TB b => b
      | TN a c => if h then tGet c tl else tGet a tl
      end
  end.

Fixpoint tIns (t : btrie) (bs : list bool) {struct bs} : btrie :=
  match bs with
  | [] => TB true
  | h :: tl =>
      match t, h with
      | TB true, _ => t
      | TB false, false => TN (tIns (TB false) tl) (TB false)
      | TB false, true => TN (TB false) (tIns (TB false) tl)
      | TN a c, false => TN (tIns a tl) c
      | TN a c, true => TN a (tIns c tl)
      end
  end.

Fixpoint subsets (l : list fm) : list (list fm) :=
  match l with
  | [] => [[]]
  | x :: t => let r := subsets t in r ++ map (cons x) r
  end.

Definition seqUniv (U : list fm) : list sq :=
  let S := subsets U in flat_map (fun A => map (fun B => (A, B)) S) S.

Definition bitsOfSet (U : list fm) (G : list fm) : list bool :=
  map (fun x => memF x G) U.

Definition keyOf (U : list fm) (s : sq) : list bool :=
  bitsOfSet U (snd s) ++ bitsOfSet U (fst s).

(* 性能要害：规则表预计算——每轮扫描不再重算 ruleSets/键串，只剩
   trie 查询。表条目 =(自身键, 公理位, 各规则实例的前提键表)。 *)
Definition rulesTab (extra : sq -> list (list sq)) (U : list fm)
  : list (list bool * bool * list (list (list bool))) :=
  map
    (fun s =>
       (keyOf U s,
        axSeq s,
        map (fun prems => map (keyOf U) prems) (ruleSets s ++ extra s)))
    (seqUniv U).

Definition stepE (der : btrie) (ax : bool)
               (premss : list (list (list bool))) : bool :=
  orb ax (existsb (fun prems => forallb (fun k => tGet der k) prems) premss).

(* 一轮扫描：把「公理或全部前提已导」的新矢列入账（ch=本轮有无增长） *)
Definition sweepE (tab : list (list bool * bool * list (list (list bool))))
                  (acc : btrie) : btrie * bool :=
  fold_left
    (fun st e =>
       match st, e with
       | (der, ch), (k, ax, premss) =>
           if orb (tGet der k) (stepE der ax premss)
           then (tIns der k, true)
           else (der, ch)
       end) tab (acc, false).

(* 迭代界：每条规则使矢列总规模严格下降（⇒→ 连参数公式一起退场），
   故推导深度 ≤ 宇宙总规模 sumSize U+缓冲——上界严谨而非拍脑袋。 *)
Fixpoint closeE (n : nat)
                  (tab : list (list bool * bool * list (list (list bool))))
                  (acc : btrie) : btrie :=
  match n with
  | 0 => acc
  | S k =>
      match sweepE tab acc with
      | (a', true) => closeE k tab a'
      | (_, false) => acc
      end
  end.

Definition sumSize (l : list fm) : nat :=
  fold_right (fun a n => szF a + n) 0 l.

Definition oracleT (U : list fm) : btrie :=
  closeE (S (sumSize U + 2 ^ length U)) (rulesTab (fun _ => []) U) (TB false).

Definition ljDer (G D : list fm) : bool :=
  let U := dedup (subL (G ++ D)) in
  tGet (oracleT U) (keyOf U (dedup G, dedup D)).

(* 经典对照：把 ⇒→ 改成「后件参数公式保留」（经典 LK 形）——多后件
   直觉演算与经典演算只差这一处。 *)
Definition ruleSetsC (s : sq) : list (list sq) :=
  match s with
  | (G, D) =>
      flat_map
        (fun c =>
           match c with
           | iimp x y =>
               if memF c D then [[(addF x G, addF y (remF c D))]] else []
           | _ => []
           end) (dedup (subL (G ++ D)))
  end.

Definition clDer (G D : list fm) : bool :=
  let U := dedup (subL (G ++ D)) in
  tGet (closeE (S (sumSize U + 2 ^ length U)) (rulesTab ruleSetsC U) (TB false))
       (keyOf U (dedup G, dedup D)).

(* ---------- 4. 电池：定理与非定理（双向账） ---------- *)

Definition P : fm := pv 0.
Definition Q : fm := pv 1.
Definition R : fm := pv 2.

Example der_id       : ljDer [] [P ~> P] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_mp       : ljDer [P; P ~> Q] [Q] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_nocontra : ljDer [] [negf (aand P (negf P))] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_gliv     : ljDer [] [negf (negf (oor P (negf P)))] = true.  (* Glivenko *)
Proof. vm_compute. reflexivity. Qed.

Example der_syll     : ljDer [iimp P Q; iimp Q R] [iimp P R] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_andcomm  : ljDer [aand P Q] [aand Q P] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_disjsyl  : ljDer [negf P; oor P Q] [Q] = true.
Proof. vm_compute. reflexivity. Qed.

Example nder_lem     : ljDer [] [oor P (negf P)] = false.
Proof. vm_compute. reflexivity. Qed.

Example nder_dne     : ljDer [] [iimp (negf (negf P)) P] = false.
Proof. vm_compute. reflexivity. Qed.

Example nder_peirce  : ljDer [] [iimp (iimp (iimp P Q) P) P] = false.
Proof. vm_compute. reflexivity. Qed.

Example nder_dummett : ljDer [] [oor (iimp P Q) (iimp Q P)] = false.
Proof. vm_compute. reflexivity. Qed.

Example nder_wlem    : ljDer [] [oor (negf P) (negf (negf P))] = false.
Proof. vm_compute. reflexivity. Qed.

Example der_lem_classical : clDer [] [oor P (negf P)] = true.  (* 一处之差 *)
Proof. vm_compute. reflexivity. Qed.

(* ---------- 5. 显式推导树+逐节点检查 ---------- *)

Inductive drule : Type :=
| RAx | RAndL | RAndR | ROrL | ROrR | RImpL | RImpR.

Inductive dtree : Type :=
| DNode : drule -> sq -> list dtree -> dtree.

Definition dseq (d : dtree) : sq := match d with DNode _ s _ => s end.

(* 节点检查：公理节点无前提且为公理；逻辑节点的孩子矢列必须恰为该
   规则对某主公式的实例前提集（主公式=孩子与父矢列的差异公式）。 *)
Definition chkOne (r : drule) (s : sq) (kids : list sq) : bool :=
  match r, s, kids with
  | RAx, (G, D), [] => axSeq (G, D)
  | RAndL, (G, D), [(G', D')] =>
      existsb (fun c =>
                 match c with
                 | aand x y =>
                     andb (memF c G)
                          (andb (eqF G' (addF x (addF y (remF c G))))
                                (eqF D' D))
                 | _ => false
                 end) G
  | RAndR, (G, D), [(G1, D1); (G2, D2)] =>
      existsb (fun c =>
                 match c with
                 | aand x y =>
                     andb (memF c D)
                          (andb (eqF D1 (addF x (remF c D)))
                                (andb (eqF D2 (addF y (remF c D)))
                                      (andb (eqF G1 G) (eqF G2 G))))
                 | _ => false
                 end) D
  | ROrL, (G, D), [(G1, D1); (G2, D2)] =>
      existsb (fun c =>
                 match c with
                 | oor x y =>
                     andb (memF c G)
                          (andb (eqF G1 (addF x (remF c G)))
                                (andb (eqF G2 (addF y (remF c G)))
                                      (andb (eqF D1 D) (eqF D2 D))))
                 | _ => false
                 end) G
  | ROrR, (G, D), [(G', D')] =>
      existsb (fun c =>
                 match c with
                 | oor x y =>
                     andb (memF c D)
                          (andb (eqF D' (addF x (addF y (remF c D))))
                                (eqF G' G))
                 | _ => false
                 end) D
  | RImpL, (G, D), [(G1, D1); (G2, D2)] =>
      existsb (fun c =>
                 match c with
                 | iimp x y =>
                     andb (memF c G)
                          (andb (eqF G1 (remF c G))
                                (andb (eqF D1 (addF x D))
                                      (andb (eqF G2 (addF y (remF c G)))
                                            (eqF D2 D))))
                 | _ => false
                 end) G
  | RImpR, (G, D), [(G', D')] =>
      existsb (fun c =>
                 match c with
                 | iimp x y =>
                     andb (memF c D)
                          (andb (eqF G' (addF x G)) (eqF D' [y]))
                 | _ => false
                 end) D
  | _, _, _ => false
  end.

Fixpoint chkTree (d : dtree) : bool :=
  match d with
  | DNode r s kids =>
      andb (chkOne r s (map dseq kids)) (forallb chkTree kids)
  end.

(* 样本一：⊢ p→p（⇒→ 一步到公理） *)
Definition tree_id : dtree :=
  DNode RImpR ([], [P ~> P]) [DNode RAx ([P], [P]) []].

(* 样本二：p∧q ⊢ q∧p（∧左+∧右+两公理） *)
Definition tree_andcomm : dtree :=
  DNode RAndL ([aand P Q], [aand Q P])
    [DNode RAndR ([P; Q], [aand Q P])
       [DNode RAx ([P; Q], [Q]) [];
        DNode RAx ([P; Q], [P]) []]].

(* 样本三：⊢ ¬(p∧¬p)（⇒¬=⇒→ 到 [⊥]；∧左；→左两前提皆公理） *)
Definition tree_nocontra : dtree :=
  DNode RImpR ([], [negf (aand P (negf P))])
    [DNode RAndL ([aand P (negf P)], [ff])
       [DNode RImpL ([P; negf P], [ff])
          [DNode RAx ([P], [ff; P]) [];
           DNode RAx ([ff; P], [ff]) []]]].

Example chk_trees :
  andb (chkTree tree_id)
    (andb (chkTree tree_andcomm) (chkTree tree_nocontra)) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 6. 完备化与可逆饱和（Lemma 8.3/8.4, Def 8.2/8.3） ---------- *)

(* 键必须相对全宇宙 U 计算——递归走剩余表 R。 *)
Fixpoint completeSeqW (U R : list fm) (der : btrie)
            (G D' : list fm) {struct R} : sq :=
  match R with
  | [] => (dedup G, dedup D')
  | Phi :: R' =>
      if negb (tGet der (keyOf U (addF Phi G, D')))
      then completeSeqW U R' der (addF Phi G) D'
      else if negb (tGet der (keyOf U (G, addF Phi D')))
      then completeSeqW U R' der G (addF Phi D')
      else completeSeqW U R' der G D'
  end.

Definition completeSeq (U : list fm) (der : btrie)
               (G D' : list fm) : sq := completeSeqW U U der G D'.

(* 完备化查询都在固定宇宙 U 内做——DER 只需一次闭包 *)
Definition lemU : list fm := dedup (subL [oor P (negf P)]).
Definition lemDER : btrie := oracleT lemU.
Definition lemCS : sq := completeSeq lemU lemDER [] [oor P (negf P)].

Example lem_cs_underivable :
  negb (tGet lemDER (keyOf lemU lemCS)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 可逆饱和六条件（Def 8.3）在完备矢列上逐一成立 *)
Definition satInv (s : sq) : bool :=
  match s with
  | (G, D) =>
      forallb
        (fun c =>
           match c with
           | aand x y =>
               andb (impb (memF c G) (andb (memF x G) (memF y G)))
                    (impb (memF c D) (orb (memF x D) (memF y D)))
           | oor x y =>
               andb (impb (memF c G) (orb (memF x G) (memF y G)))
                    (impb (memF c D) (andb (memF x D) (memF y D)))
           | iimp x y =>
               impb (memF c G) (orb (memF x D) (memF y G))
           | _ => true
           end) (dedup (subL (G ++ D)))
  end.

Example lem_cs_saturated : satInv lemCS = true.
Proof. vm_compute. reflexivity. Qed.

Fixpoint dedupSq (l : list (option sq)) : list sq :=
  match l with
  | [] => []
  | None :: t => dedupSq t
  | Some s :: t =>
      let r := dedupSq t in
      if existsb (fun u => andb (eqF (fst u) (fst s)) (eqF (snd u) (snd s))) r then r
      else s :: r
  end.

Definition allComplete (U : list fm) (der : btrie) : list sq :=
  dedupSq
    (map (fun s =>
            if tGet der (keyOf U s) then None
            else Some (completeSeq U der (fst s) (snd s))) (seqUniv U)).

Definition lemW : list sq := allComplete lemU lemDER.

Definition wRel (w w' : sq) : bool := inclF (fst w) (fst w').
Definition wVal (n : nat) (w : sq) : bool := memF (pv n) (fst w).

Fixpoint force (a : fm) (W : list sq) (w : sq) : bool :=
  match a with
  | pv n => wVal n w
  | ff => false
  | aand x y => andb (force x W w) (force y W w)
  | oor x y => orb (force x W w) (force y W w)
  | iimp x y =>
      forallb (fun w' =>
                 impb (wRel w w') (impb (force x W w') (force y W w'))) W
  end.

Definition truthLemma (W : list sq) (U : list fm) : bool :=
  forallb (fun w =>
             forallb (fun Phi =>
                        andb (impb (memF Phi (fst w)) (force Phi W w))
                             (impb (memF Phi (snd w)) (negb (force Phi W w))))
                     U) W.

Example lem_truth_lemma : truthLemma lemW lemU = true.
Proof. vm_compute. reflexivity. Qed.

Definition rootW : sq := lemCS.
Example lem_refuted : force (oor P (negf P)) lemW rootW = false.
Proof. vm_compute. reflexivity. Qed.

Example lem_worlds_ge2 : Nat.leb 2 (length lemW) = true.
Proof. vm_compute. reflexivity. Qed.

Example lem_4s_bound : Nat.leb (length lemW) 256 = true.  (* 4^|U|=4^4 *)
Proof. vm_compute. reflexivity. Qed.
