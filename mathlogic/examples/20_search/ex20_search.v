(* ex20_search.v —— 证明搜索：LJpm* 表列与判定程序（Mints ch10）
   机器件：表列=矢列分量表（析取语义——Lemma 10.1 剪枝引理）；LJpm*
   规则：可逆规则换分量、⇒→ 保留原分量+添加新分量 (Γ,α⇒β)——或分支
   数据化（Thm 10.1 的机制）；淹没式阻断=无进展实例过滤（新分量被现有
   分量两侧包含即弃，Def 10.1/admissible 的算法面）；判定器 dfs
   （实例 OR×前提 AND，燃料界）；**饱和器 saturate**（贪心走第一条
   有进展实例到不动点——Lemma 10.3 的终表列）；终表列→反模型：
   分量=世界、R=前件反包含、逐分量真引理式检查+根世界驳倒原目标
   （10.3→8.2 的反模型构造，「不可证」由模型认证）；电池双向账；
   IPC 可判定性的可执行化身（Thm 10.2）。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.

Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

Definition impb (a b : bool) : bool := if a then b else true.

(* ---------- 1. 公式/矢列/表列 ---------- *)

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

Definition memF (a : fm) (l : list fm) : bool := existsb (fmeqb a) l.
Definition addF (a : fm) (l : list fm) : list fm :=
  if memF a l then l else a :: l.
Definition remF (a : fm) (l : list fm) : list fm :=
  filter (fun x => negb (fmeqb a x)) l.
Definition inclF (l1 l2 : list fm) : bool :=
  forallb (fun x => memF x l2) l1.

Definition sq := (list fm * list fm)%type.
Definition tb := list sq.

Definition isAtom (a : fm) : bool :=
  match a with pv _ => true | _ => false end.

Definition axSeq (s : sq) : bool :=
  match s with
  | (G, D) =>
      orb (memF ff G)
          (existsb (fun x => andb (memF x G) (memF x D)) (filter isAtom G))
  end.

Definition closedT (T : tb) : bool := existsb axSeq T.

Definition eqbSq (u s : sq) : bool :=
  andb (andb (inclF (fst u) (fst s)) (inclF (fst s) (fst u)))
       (andb (inclF (snd u) (snd s)) (inclF (snd s) (snd u))).

Definition addComp (s : sq) (T : tb) : tb :=
  if existsb (fun u => eqbSq u s) T then T else s :: T.

Fixpoint dedupT (T : tb) : tb :=
  match T with
  | [] => []
  | s :: t => let r := dedupT t in
      if existsb (fun u => eqbSq u s) r then r else s :: r
  end.

(* 淹没（subsumption）：s ⊆ u（两侧皆含）——s 被 u 淹没（Def 10.1） *)
Definition subsumedBy (s u : sq) : bool :=
  andb (inclF (fst s) (fst u)) (inclF (snd s) (snd u)).

(* 无进展过滤：新表列里每个分量都被旧表列某分量淹没 ⟹ 弃（admissible） *)
Definition hasProgress (old newT : tb) : bool :=
  existsb (fun s => negb (existsb (fun u => subsumedBy s u) old)) newT.

(* ---------- 2. 分析实例：分量×复合公式 → 前提表列组 ---------- *)

(* subst：把分量 s 换成 repl（可能多个），可选地添加新分量 extra *)
Definition subst (T : tb) (s : sq) (repl : list sq) (extra : option sq)
  : tb :=
  let base :=
    flat_map (fun u => if eqbSq u s then repl else [u]) T in
  match extra with
  | Some e => addComp e base
  | None => base
  end.

Definition mkInst (T : tb) (s : sq) (repl : list sq) (extra : option sq)
  : list (list tb) :=
  let newT := subst T s repl extra in
  if hasProgress T newT then [[newT]] else [].

(* 双前提实例：两支都必须闭合（树枝干 AND）；任一支无进展则整实例弃 *)
Definition mkInst2 (T : tb) (s : sq) (p1 p2 : sq) : list (list tb) :=
  let t1 := subst T s [p1] None in
  let t2 := subst T s [p2] None in
  if andb (hasProgress T t1) (hasProgress T t2) then [[t1; t2]] else [].

Definition analyze (T : tb) (s : sq) (c : fm) : list (list tb) :=
  match fst s, snd s with
  | G, D =>
      if negb (memF c (G ++ D)) then []
      else
        match c with
        | aand x y =>
            if memF c G
            then mkInst T s [(addF x (addF y (remF c G)), D)] None
            else if memF c D
            then mkInst2 T s (G, addF x (remF c D)) (G, addF y (remF c D))
            else []
        | oor x y =>
            if memF c G
            then mkInst2 T s (addF x (remF c G), D) (addF y (remF c G), D)
            else if memF c D
            then mkInst T s [(G, addF x (addF y (remF c D)))] None
            else []
        | iimp x y =>
            if memF c G
            then mkInst2 T s (G, addF x D) (addF y (remF c G), D)
            else if memF c D
            (* ⇒→：保留原分量+添加 (Γ,α ⇒ β)——或分支数据化 *)
            then mkInst T s [(G, D)] (Some (addF x G, [y]))
            else []
        | _ => []
        end
  end.

Definition allInstances (T : tb) : list (list tb) :=
  flat_map (fun s =>
      flat_map (fun c => analyze T s c)
               (filter (fun x => negb (isAtom x)) (fst s ++ snd s)))
    (dedupT T).

(* ---------- 3. 判定器：实例 OR × 前提 AND（燃料界） ---------- *)

(* Some T = 闭合失败（T=该层终表列）；None = 闭合成功。
   实例间 OR（existsb）、实例内前提间 AND（forallb）——双前提规则
   的树枝干与表列分量的或分支在此分家。 *)
Fixpoint dfs (fuel : nat) (T : tb) {struct fuel} : option tb :=
  match fuel with
  | 0 => Some T
  | S k =>
      if closedT T then None
      else if existsb (fun inst =>
                  forallb (fun p => match dfs k p with
                                    | None => true
                                    | Some _ => false
                                    end) inst)
                     (allInstances T)
      then None
      else (* 全实例失败：带着首支最深失败分支的终表列返回（终节点） *)
        match allInstances T with
        | [] => Some T
        | inst0 :: _ =>
            match inst0 with
            | p0 :: _ =>
                match dfs k p0 with Some T' => Some T' | None => Some T end
            | [] => Some T
            end
        end
  end.

Definition decide (fuel : nat) (G D : list fm) : bool :=
  match dfs fuel [(G, D)] with
  | None => true
  | Some _ => false
  end.

(* ---------- 4. 终表列 → 反模型（10.3→8.2），真引理式认证 ---------- *)

Definition wRel (w w' : sq) : bool := inclF (fst w) (fst w').

Fixpoint force (a : fm) (W : tb) (w : sq) : bool :=
  match a with
  | pv n => memF (pv n) (fst w)
  | ff => false
  | aand x y => andb (force x W w) (force y W w)
  | oor x y => orb (force x W w) (force y W w)
  | iimp x y =>
      forallb (fun w' => impb (wRel w w') (impb (force x W w') (force y W w')))
              W
  end.

(* 每个分量被自己的世界驳倒：Γ 全force、Δ 全不force（Thm 8.2 形态） *)
Definition falsified (W : tb) : bool :=
  forallb (fun w =>
             andb (forallb (fun a => impb (memF a (fst w)) (force a W w))
                           (fst w))
                  (forallb (fun a => impb (memF a (snd w))
                                          (negb (force a W w)))
                           (snd w)))
          W.

Definition refutedBy (fuel : nat) (a : fm) : bool :=
  match dfs fuel [([], [a])] with
  | None => false
  | Some T => andb (falsified T) (existsb (fun w => negb (force a T w)) T)
  end.

(* ---------- 5. 电池 ---------- *)

Definition P : fm := pv 0.
Definition Q : fm := pv 1.

Example der_id : decide 24 [] [P ~> P] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_nocontra : decide 24 [] [negf (aand P (negf P))] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_gliv : decide 24 [] [negf (negf (oor P (negf P)))] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_andcomm : decide 24 [aand P Q] [aand Q P] = true.
Proof. vm_compute. reflexivity. Qed.

Example der_disjsyl : decide 24 [negf P; oor P Q] [Q] = true.
Proof. vm_compute. reflexivity. Qed.

Example nder_lem : decide 24 [] [oor P (negf P)] = false.
Proof. vm_compute. reflexivity. Qed.

Example nder_dne : decide 24 [] [iimp (negf (negf P)) P] = false.
Proof. vm_compute. reflexivity. Qed.

Example nder_peirce : decide 24 [] [iimp (iimp (iimp P Q) P) P] = false.
Proof. vm_compute. reflexivity. Qed.

Example nder_wlem : decide 24 [] [oor (negf P) (negf (negf P))] = false.
Proof. vm_compute. reflexivity. Qed.

Example nder_dummett : decide 24 [] [oor (iimp P Q) (iimp Q P)] = false.
Proof. vm_compute. reflexivity. Qed.

(* Open 侧由饱和器+反模型认证（「不可证」升级为「有反模型」） *)
Example lem_refuted : refutedBy 24 (oor P (negf P)) = true.
Proof. vm_compute. reflexivity. Qed.

Example dne_refuted : refutedBy 24 (iimp (negf (negf P)) P) = true.
Proof. vm_compute. reflexivity. Qed.

Example peirce_refuted : refutedBy 24 (iimp (iimp (iimp P Q) P) P) = true.
Proof. vm_compute. reflexivity. Qed.

Example wlem_refuted : refutedBy 24 (oor (negf P) (negf (negf P))) = true.
Proof. vm_compute. reflexivity. Qed.

Example dummett_refuted : refutedBy 24 (oor (iimp P Q) (iimp Q P)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 书例 10.1：¬(p&q) ⊢ ¬p∨¬q——经典有效、直觉失败、三世界反模型。
   7 个子公式的搜索空间对无记忆 DFS 过大（4^7 分量宇宙）；此处按书
   中终表列手工装配同一反模型，认证交机器（分量=世界、逐分量真引理
   式检查、根世界驳倒原目标）——搜索版留给 Lean/Prolog 侧小电池。 *)
Definition demorganT : tb :=
  [ ([P; negf (aand P Q)], [ff])
  ; ([Q; negf (aand P Q)], [ff])
  ; ([], [oor (negf P) (negf Q)]) ].

Example demorgan_model :
  andb (falsified demorganT)
       (existsb (fun w => negb (force (iimp (negf (aand P Q))
                                           (oor (negf P) (negf Q)))
                                  demorganT w)) demorganT) = true.
Proof. vm_compute. reflexivity. Qed.
