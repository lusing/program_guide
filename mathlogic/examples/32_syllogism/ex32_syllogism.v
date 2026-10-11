(* ex32_syllogism.v —— 三段论与传统逻辑（张寅生《证明方法与理论》第 5 章+9.2/9.3）
   机器件：直言命题 A/E/I/O 的载集外延语义；对当方阵四关系的 64 载集对全枚举
   （空载集暴露「存在导入」偏差）；256 格式有限论域枚举判定器→恰 24 有效式
   （非空预设）与恰 15 有效式（现代语义）双账；四格代表式 FOL 机器证明
   （Barbara/Celarent/Darii/Ferio/Baroco/Darapti）；量化扩展（张氏体系）：部分
   量词 PT 与量词否定四式；格岗空间五关系与前提组合→结论关系可达表。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

(* ---------- 1. 载集语义：A/E/I/O ---------- *)

(* 教学论域 D3={0,1,2}；词项=载集（list nat）。subsets 枚举 2^n 个子集 *)
Definition D3 : list nat := [0; 1; 2].

Fixpoint subsets (l : list nat) : list (list nat) :=
  match l with
  | [] => [[]]
  | x :: rest =>
      let ss := subsets rest in
      map (fun s => s) ss ++ map (fun s => x :: s) ss
  end.

(* 子集与不交：A/E 的外延核心 *)
Definition inclB (s p : list nat) : bool :=
  forallb (fun x => existsb (Nat.eqb x) p) s.

Definition disjB (s p : list nat) : bool :=
  forallb (fun x => negb (existsb (Nat.eqb x) p)) s.

(* 四直言命题（S 为主项载集、P 为谓项载集）：
   A「所有 S 是 P」= S⊆P        E「所有 S 不是 P」= S∩P=∅
   I「有 S 是 P」   = S∩P≠∅     O「有 S 不是 P」  = S∖P≠∅  *)
Definition aForm (s p : list nat) : bool := inclB s p.
Definition eForm (s p : list nat) : bool := disjB s p.
Definition iForm (s p : list nat) : bool :=
  existsb (fun x => existsb (Nat.eqb x) p) s.
Definition oForm (s p : list nat) : bool :=
  existsb (fun x => negb (existsb (Nat.eqb x) p)) s.

Definition form2bool (m : nat) (s p : list nat) : bool :=
  match m with
  | 0 => aForm s p   (* A *)
  | 1 => eForm s p   (* E *)
  | 2 => iForm s p   (* I *)
  | _ => oForm s p   (* O *)
  end.

(* ---------- 2. 对当方阵：64 载集对全枚举 ---------- *)

(* 全部 (S,P) 对：8×8=64 *)
Definition allSP : list (list nat * list nat) :=
  flat_map (fun s => map (fun p => (s, p)) (subsets D3)) (subsets D3).

Example sp_count : length allSP = 64.
Proof. reflexivity. Qed.

(* 矛盾律（全对成立——不依赖非空）：A↔¬O 且 E↔¬I *)
Example square_contradiction :
  forallb (fun sp =>
    andb (implb (aForm (fst sp) (snd sp)) (negb (oForm (fst sp) (snd sp))))
          (implb (eForm (fst sp) (snd sp)) (negb (iForm (fst sp) (snd sp)))))
    allSP = true.
Proof. reflexivity. Qed.

(* 反对律（非空主项下成立）：A 与 E 不同真——空载集失守（S=∅ 时 A=E=true
   同真！反对关系同样依赖存在导入预设） *)
Example square_contrary_nonempty :
  forallb (fun sp =>
    implb (negb (Nat.eqb (length (fst sp)) 0))
              (negb (andb (aForm (fst sp) (snd sp)) (eForm (fst sp) (snd sp)))))
    allSP = true.
Proof. reflexivity. Qed.

(* 反对律失守现场：S=∅ 时 A=E=true *)
Example empty_subject_contrary :
  [ aForm [] [0;1]; eForm [] [0;1] ] = [true; true].
Proof. reflexivity. Qed.

(* 差等律 A→I：空载集失守！非空主项下成立——传统逻辑的存在导入预设 *)
Example square_subaltern_nonempty :
  forallb (fun sp =>
    implb (andb (negb (Nat.eqb (length (fst sp)) 0)) (aForm (fst sp) (snd sp)))
              (iForm (fst sp) (snd sp)))
    allSP = true.
Proof. reflexivity. Qed.

(* 失守现场：S=∅ 时 A 真而 I 假 *)
Example empty_subject_breaks :
  [ aForm [] [0;1]; iForm [] [0;1] ] = [true; false].
Proof. reflexivity. Qed.

(* 下反对 I∨O：同样空载集失守（I=O=false） *)
Example square_subcontrary_nonempty :
  forallb (fun sp =>
    implb (negb (Nat.eqb (length (fst sp)) 0))
              (orb (iForm (fst sp) (snd sp)) (oForm (fst sp) (snd sp))))
    allSP = true.
Proof. reflexivity. Qed.

(* ---------- 3. 256 格式枚举判定器 ---------- *)

(* 格（figure）决定前提的词项排布（中项 m 的位置）：
   格1 (m,p)(s,m) | 格2 (p,m)(s,m) | 格3 (m,p)(m,s) | 格4 (p,m)(m,s)
   结论恒为 (s,p)。 *)
Definition prem12 (fig m1 m2 : nat) (s m p : list nat) : bool * bool :=
  match fig with
  | 1 => (form2bool m1 m p, form2bool m2 s m)
  | 2 => (form2bool m1 p m, form2bool m2 s m)
  | 3 => (form2bool m1 m p, form2bool m2 m s)
  | _ => (form2bool m1 p m, form2bool m2 m s)
  end.

(* 单格检查：前提 (h1,h2) 真 ⟹ 结论真 *)
Definition sylCheck (fig m1 m2 m3 : nat) (s m p : list nat) : bool :=
  let '(h1, h2) := prem12 fig m1 m2 s m p in
  implb (andb h1 h2) (form2bool m3 s p).

Definition triples : list (list nat * (list nat * list nat)) :=
  flat_map (fun s =>
    flat_map (fun m => map (fun p => (s, (m, p))) (subsets D3)) (subsets D3))
    (subsets D3).

Definition nonEmpty3 : list (list nat * (list nat * list nat)) :=
  filter (fun t => andb (negb (Nat.eqb (length (fst t)) 0))
               (andb (negb (Nat.eqb (length (fst (snd t))) 0))
                     (negb (Nat.eqb (length (snd (snd t))) 0))))
    triples.

(* 有效性（现代语义：无存在预设——枚举全部 512 组合含空载集） *)
Definition sylValidModern (fig m1 m2 m3 : nat) : bool :=
  forallb (fun t => sylCheck fig m1 m2 m3 (fst t) (fst (snd t)) (snd (snd t)))
    triples.

(* 有效性（传统语义：词项非空预设——7³=343 组合） *)
Definition sylValidTrad (fig m1 m2 m3 : nat) : bool :=
  forallb (fun t => sylCheck fig m1 m2 m3 (fst t) (fst (snd t)) (snd (snd t)))
    nonEmpty3.

Definition allFormats : list (nat * (nat * (nat * nat))) :=
  flat_map (fun fig =>
    flat_map (fun m1 =>
      flat_map (fun m2 =>
        map (fun m3 => (fig, (m1, (m2, m3)))) [0;1;2;3]) [0;1;2;3])
      [0;1;2;3])
    [1;2;3;4].

Example formats_count : length allFormats = 256.
Proof. reflexivity. Qed.

(* 现代语义 15 强式清单（fig,m1,m2,m3；A=0 E=1 I=2 O=3） *)
Definition modern15 : list (nat * (nat * (nat * nat))) :=
  [ (1,(0,(0,0)))  (* Barbara   AAA-1 *)
  ; (1,(0,(2,2)))  (* Darii     AII-1 *)
  ; (1,(1,(0,1)))  (* Celarent  EAE-1 *)
  ; (1,(1,(2,3)))  (* Ferio     EIO-1 *)
  ; (2,(0,(1,1)))  (* Camestres AEE-2 *)
  ; (2,(0,(3,3)))  (* Baroco    AOO-2 *)
  ; (2,(1,(0,1)))  (* Cesare    EAE-2 *)
  ; (2,(1,(2,3)))  (* Festino   EIO-2 *)
  ; (3,(0,(2,2)))  (* Datisi    AII-3 *)
  ; (3,(1,(2,3)))  (* Ferison   EIO-3 *)
  ; (3,(2,(0,2)))  (* Disamis   IAI-3 *)
  ; (3,(3,(0,3)))  (* Bocardo   OAO-3 *)
  ; (4,(0,(1,1)))  (* Camenes   AEE-4 *)
  ; (4,(1,(2,3)))  (* Fresison  EIO-4 *)
  ; (4,(2,(0,2)))  (* Dimaris   IAI-4 *) ].

(* 传统语义 24 式 = 现代 15 + 9 个依赖存在导入的弱式 *)
Definition trad24 : list (nat * (nat * (nat * nat))) :=
  [ (1,(0,(0,0)))  (* Barbara   AAA-1 *)
  ; (1,(0,(0,2)))  (* Barbari   AAI-1（弱） *)
  ; (1,(0,(2,2)))  (* Darii     AII-1 *)
  ; (1,(1,(0,1)))  (* Celarent  EAE-1 *)
  ; (1,(1,(0,3)))  (* Celaront  EAO-1（弱） *)
  ; (1,(1,(2,3)))  (* Ferio     EIO-1 *)
  ; (2,(0,(1,1)))  (* Camestres AEE-2 *)
  ; (2,(0,(1,3)))  (* Camestrop AEO-2（弱） *)
  ; (2,(0,(3,3)))  (* Baroco    AOO-2 *)
  ; (2,(1,(0,1)))  (* Cesare    EAE-2 *)
  ; (2,(1,(0,3)))  (* Cesaro    EAO-2（弱） *)
  ; (2,(1,(2,3)))  (* Festino   EIO-2 *)
  ; (3,(0,(0,2)))  (* Darapti   AAI-3 *)
  ; (3,(0,(2,2)))  (* Datisi    AII-3 *)
  ; (3,(1,(0,3)))  (* Felapton  EAO-3 *)
  ; (3,(1,(2,3)))  (* Ferison   EIO-3 *)
  ; (3,(2,(0,2)))  (* Disamis   IAI-3 *)
  ; (3,(3,(0,3)))  (* Bocardo   OAO-3 *)
  ; (4,(0,(0,2)))  (* Bramantip AAI-4 *)
  ; (4,(0,(1,1)))  (* Camenes   AEE-4 *)
  ; (4,(0,(1,3)))  (* Cameno    AEO-4（弱） *)
  ; (4,(1,(0,3)))  (* Fesapo    EAO-4 *)
  ; (4,(1,(2,3)))  (* Fresison  EIO-4 *)
  ; (4,(2,(0,2)))  (* Dimaris   IAI-4 *) ].

(* 双账：枚举判定恰得两清单 *)
Example valid_modern_is_15 :
  filter (fun q => sylValidModern (fst q) (fst (snd q))
                     (fst (snd (snd q))) (snd (snd (snd q))))
         allFormats
  = modern15.
Proof. reflexivity. Qed.

Example valid_trad_is_24 :
  filter (fun q => sylValidTrad (fst q) (fst (snd q))
                     (fst (snd (snd q))) (snd (snd (snd q))))
         allFormats
  = trad24.
Proof. reflexivity. Qed.

(* 9 个弱式的共同机制：全部靠空载集之外的反例不可得——即去掉非空预设即失效。
   现代账里它们被拒的现场（取 Darapti AAI-3：S=P={0}, M=∅ 前提真结论假） *)
Example darapti_counter :
  sylCheck 3 0 0 2 [0] [] [1] = false.
Proof. reflexivity. Qed.

(* ---------- 4. 四格代表式的 FOL 机器证明 ---------- *)

(* 谓词版：词项=谓词 nat->Prop。Barbara（AAA-1） *)
Theorem barbara : forall (m p s : nat -> Prop),
  (forall x, m x -> p x) -> (forall x, s x -> m x) ->
  forall x, s x -> p x.
Proof.
  intros m p s h1 h2 x hs. apply h1, h2, hs.
Qed.

(* Celarent（EAE-1）：全称否定大前提 *)
Theorem celarent : forall (m p s : nat -> Prop),
  (forall x, m x -> ~ p x) -> (forall x, s x -> m x) ->
  forall x, s x -> ~ p x.
Proof.
  intros m p s h1 h2 x hs hp. apply (h1 x (h2 x hs)), hp.
Qed.

(* Darii（AII-1）：特称小前提 *)
Theorem darii : forall (m p s : nat -> Prop),
  (forall x, m x -> p x) -> (exists x, s x /\ m x) ->
  exists x, s x /\ p x.
Proof.
  intros m p s h1 [x [hs hm]]. exists x. split; [exact hs | apply h1, hm].
Qed.

(* Ferio（EIO-1） *)
Theorem ferio : forall (m p s : nat -> Prop),
  (forall x, m x -> ~ p x) -> (exists x, s x /\ m x) ->
  exists x, s x /\ ~ p x.
Proof.
  intros m p s h1 [x [hs hm]]. exists x. split; [exact hs | apply h1, hm].
Qed.

(* Baroco（AOO-2）：否定结论经反证（¬P 由假设 P 导矛盾——RAA 的直觉形式） *)
Theorem baroco : forall (p m s : nat -> Prop),
  (forall x, p x -> m x) -> (exists x, s x /\ ~ m x) ->
  exists x, s x /\ ~ p x.
Proof.
  intros p m s hpm [x [hs hnm]]. exists x. split; [exact hs|].
  intro hp. apply hnm, hpm, hp.
Qed.

(* Darapti（AAI-3）：需要「中项非空」的显式存在前提——存在导入的正面形态 *)
Theorem darapti : forall (m p s : nat -> Prop),
  (forall x, m x -> p x) -> (forall x, m x -> s x) ->
  (exists x, m x) -> exists x, s x /\ p x.
Proof.
  intros m p s h1 h2 [x hm]. exists x.
  split; [apply h2, hm | apply h1, hm].
Qed.

(* ---------- 5. 量化扩展（张氏体系，书 4.2 定理 4.1 选样） ---------- *)

(* 部分量词 PT「有些…但非全部」= I ∧ ¬A（真子集语义：PT(X) 表 m<n） *)
Definition ptForm (s p : list nat) : bool :=
  andb (iForm s p) (negb (aForm s p)).

(* 否定运算（表 4.7）：¬A=O、¬E=I、¬I=E、¬O=A —— 64 对全对账 *)
Example quant_neg_table :
  forallb (fun sp =>
    andb (Bool.eqb (negb (aForm (fst sp) (snd sp))) (oForm (fst sp) (snd sp)))
          (Bool.eqb (negb (eForm (fst sp) (snd sp))) (iForm (fst sp) (snd sp))))
    allSP = true.
Proof. reflexivity. Qed.

(* PT∨∀=∃（表 4.5 排斥或选样）：部分或全部恰=「有」——非空主项下 64 对全对账
   （空载集失守：S=∅ 时 A 空真而 I 假——量词定律同样背着存在导入的包袱） *)
Example pt_or_all_is_ex :
  forallb (fun sp =>
    implb (negb (Nat.eqb (length (fst sp)) 0))
     (Bool.eqb (orb (ptForm (fst sp) (snd sp)) (aForm (fst sp) (snd sp)))
                   (iForm (fst sp) (snd sp))))
    allSP = true.
Proof. reflexivity. Qed.

(* PT→∃：部分量词强于存在量词（真子集必相交——非空主项下成立） *)
Example pt_implies_ex :
  forallb (fun sp =>
    implb (andb (negb (Nat.eqb (length (fst sp)) 0)) (ptForm (fst sp) (snd sp)))
              (iForm (fst sp) (snd sp)))
    allSP = true.
Proof. reflexivity. Qed.

(* 定理 4.2 现场：亚氏特称命题把 I（m≤n，可能=全部）与 PT（m<n）混用——
   S=P 时 I 真 PT 假：同一「有些」两读法的分裂账 *)
Example i_vs_pt_split :
  [ iForm [0;1] [0;1]; ptForm [0;1] [0;1] ] = [true; false].
Proof. reflexivity. Qed.

(* ---------- 6. 格岗空间：五关系与前提组合→结论可达 ---------- *)

(* 格岗空间（定义 4.5）：任意两集合恰处五关系之一 *)
Inductive gerg : Type :=
| GDisj | GEq | GCross | GSub | GSup.   (* 全异/全同/交叉/包含(S⊇P)/被包含(S⊆P) *)

Definition gergOf (s p : list nat) : gerg :=
  if andb (inclB s p) (inclB p s) then GEq
  else if andb (inclB s p) (negb (inclB p s)) then GSub
  else if andb (inclB p s) (negb (inclB s p)) then GSup
  else if disjB s p then GDisj
  else GCross.

(* 三个词项非空组合（343）按 (S,M)(M,P) 的格岗关系分箱，统计 (S,P) 可达关系 *)
Definition gergCode (g : gerg) : nat :=
  match g with GDisj => 0 | GEq => 1 | GCross => 2 | GSub => 3 | GSup => 4 end.

(* 纯关系可达性：非空三元组中 (S,M)=r1 且 (M,P)=r2 时 (S,P) 能落在哪些关系。
   r1=4（被包含）时 M 可能为空（S⊆∅ 仅当 S=∅，但 S 非空则 M 非空）——
   统一加 M 非空守卫，保证大前提的「关系」有真实载体 *)
Definition reachSet (r1 r2 : nat) : list nat :=
  let rel3 (t : list nat * (list nat * list nat)) : nat :=
    gergCode (gergOf (fst t) (snd (snd t))) in
  let ok (t : list nat * (list nat * list nat)) : bool :=
    andb (Nat.eqb (gergCode (gergOf (fst t) (fst (snd t)))) r1)
         (andb (Nat.eqb (gergCode (gergOf (fst (snd t)) (snd (snd t)))) r2)
               (negb (Nat.eqb (length (fst (snd t))) 0))) in
  nodup Nat.eq_dec (map rel3 (filter ok nonEmpty3)).

(* Barbara 的格岗读法（严格包含版）：P⊊M 且 M⊊S ⟹ P⊊S——包含关系传递 *)
Example gerg_barbara :
  reachSet 4 4 = [4].       (* (S,M)=GSup,(M,P)=GSup → (S,P)=GSup *)
Proof. reflexivity. Qed.

(* Celarent 类读法：M⊊S 且 M∩P=∅——S 的「多余部分」S∖M 与 P 关系任意，
   (S,P) 可达 {全异,交叉,被包含}——单一大前提定不死结论关系 *)
Example gerg_celarent :
  reachSet 4 0 = [0; 2; 4].
Proof. reflexivity. Qed.

(* 交叉+交叉：可达集仅 {交叉,全同}——看似不确定，实则排除全异/包含；
   （非严格格岗分类的量化推理要回到 256 枚举判定器——第 3 节已做） *)
Example gerg_cross_cross :
  reachSet 2 2 = [2; 1].
Proof. reflexivity. Qed.

(* 冒烟 *)
Compute (length (filter (fun q => sylValidTrad (fst q) (fst (snd q))
                         (fst (snd (snd q))) (snd (snd (snd q)))) allFormats)).
