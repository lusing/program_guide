(* ============================================================
   51 形容词修饰 —— Coq（罗朝晖书 3.4 + 5.3.2）
   形容词四分类（表 3.3）的 MTT 机制全家桶：
   ① 相交形容词：简单谓词 + Σ（黑猫；两推理 3.65/3.66）
   ② 下属形容词：ΠA:CN 多态谓词（小象/小动物——简单谓词
      会推出「小象是小动物」的错误 3.69–3.71）；skilful 的
      CN_H 子类型空间界（排除「熟练的楼房」3.76–3.80）
   ③ 否定性形容词：不相交并 G = Gr + Gf（假枪 3.85–3.96）
   ④ 非承诺形容词：特有谓词 H_A（被指控的 3.97–3.103）
   ⑤ 时态形容词：former 三段并 PR = PRcur+(PRfor+PRfut)
      （3.104–3.111）
   开头照书 5.3.2 引证明无关性公理（58 章主角在此预挂）
   ============================================================ *)

Require Import ProofIrrelevance.

Definition CN := Set.
Parameters Cat Elephant Animal Object Human Doctor Musician Building : CN.
Parameters G_R G_F : CN.

(* ---- ① 相交形容词：黑猫（书 3.4.1）---------------------- *)
Parameter black : Object -> Prop.
Axiom ca : Cat -> Animal.  Coercion ca : Cat >-> Animal.
Axiom ao : Animal -> Object. Coercion ao : Animal >-> Object.

Record BCat := mkBC { cat_of :> Cat ; pBlack : black cat_of }.
(* 黑猫是猫：(A,N)⇒N（3.65）——π1 投射子类型（54 章） *)
Check (fun b : BCat => cat_of b) : BCat -> Cat.
(* 黑猫是黑色的：(A,N)⇒A（3.66）——Σ 第二投影直接给出 *)
Theorem bcat_is_black : forall be : BCat, black be.
Proof. intros be. apply be. Qed.       (* 书 5.3.2 原证 *)
(* 计数问题伏笔（书 3.4.1 末）：同一只猫的两个「黑性证明」
   须经证明无关性视作同一个——(c,p) = (c,q) 当且仅当 p = q *)
Lemma black_cat_pi : forall (c : Cat) (p q : black c),
  mkBC c p = mkBC c q.
Proof. intros c p q. f_equal. apply proof_irrelevance. Qed.

(* ---- ② 下属形容词：小（书 3.4.2）-------------------------
   「小」的语义依赖被修饰的通名：小象 ≠ 小动物。
   简单谓词 SMALL 的错误（3.69–3.71）：若小象/小动物都写成
   Σx:A.SMALL(x)，则由 Σ 的谓词传播 (Sp) 得
     Σx:Elephant.SMALL(x) ≤ Σx:Animal.SMALL(x)
   ——「小象是小动物」，假！多态谓词杜绝此路：
   small(Elephant) 与 small(Animal) 是**两个不同**的谓词。 *)
Parameter small : forall X : CN, X -> Prop.
Record SElephant := mkSE { elph :> Elephant ; _ : small Elephant elph }.
Record SAnimal  := mkSA { anim :> Animal  ; _ : small Animal anim }.
(* 两谓词不可互推——类型不同，强制也不存在：
   SElephant ≤ SAnimal 需要 dΣ 传播 small(Elephant)=small(Animal)，
   而它们是不同的常量。Coq 侧见证： *)
Fail Definition wrong : SElephant -> SAnimal :=
  fun se => mkSA (ca (elph se)) (small Elephant (elph se)).

(* skilful 的子类型空间界（3.76–3.80）：
   skilful : ΠA:CN_H.(A→Prop)，CN_H = Human 的子类型空间
   （53 章 U(H)）——「熟练的楼房」排不进 CN_H，类型检测直接拒 *)
Parameter skilful : forall A : CN, (A -> Human) -> A -> Prop.
Axiom dh : Doctor -> Human.  Coercion dh : Doctor >-> Human.
Definition skilful_doctor : Doctor -> Prop := skilful Doctor dh.
Parameter doc1 : Doctor.
Check (skilful Doctor dh doc1) : Prop.    (* 熟练的医生：合法 *)
Fail Definition skilful_building : Building -> Prop :=
  skilful Building (fun _ => john_h).              (* 无 B→H 强制 *)
Parameter john_h : Human.

(* ---- ③ 否定性形容词：假枪（书 3.4.3）---------------------
   枪的类型 = 真枪 + 假枪 的不相交并（3.85）；fake/real 是
   按 inl/inr 判定的谓词（3.86/3.87）——「不是真枪就是假枪」
   与「假枪不是真枪」都是类型论定理，无须意义公设。 *)
Definition G := sum G_R G_F.
Definition fake_G (x : G) : Prop :=
  match x with inl _ => False | inr _ => True end.
Definition real_G (x : G) : Prop :=
  match x with inl _ => True | inr _ => False end.
Record FGun := mkFG { gun_of :> G ; _ : fake_G gun_of }.

Theorem either : forall g : G, real_G g \/ fake_G g.   (* 3.93 *)
Proof.
  intros g. destruct g.
  - left. cbv. trivial.
  - right. cbv. trivial.
Qed.                                                  (* 书 5.3.2 原证 *)

Theorem fake_not_real : forall f : FGun, ~ real_G f.  (* 3.94/3.96 *)
Proof.
  intros [g Hfake] Hreal. destruct g.
  - cbv in Hfake. exact Hfake.      (* inl：fake=False *)
  - cbv in Hreal. exact Hreal.      (* inr：real=False *)
Qed.

(* ---- ④ 非承诺形容词：被指控的（书 3.4.4）-----------------
   无推理约束——每个非承诺形容词有自己的**特有谓词**
   H_A : Human → Prop → Prop（3.97/3.98） *)
Parameter H_a : Human -> Prop -> Prop.   (* ha(h,P) ≈ h 声称 P 真 *)
Parameter murder : Human -> Prop.
Parameter zhang51 : Human.
(* 「张三是被指控的杀人凶手」(3.101) *)
Definition zhang_alleged : Prop :=
  H_a zhang51 (murder zhang51).
(* 「被指控的杀人凶手」作通名（3.103）：Σh:Human.∃x.H_a(x,…) *)
Record AllegedMurderer := mkAM
  { am_of :> Human ; _ : exists x : Human, H_a x (murder am_of) }.

(* ---- ⑤ 时态形容词：以前的（书 3.4.5）---------------------
   「以前(的)」按 Dowty 是否定性形容词：总统类型三段并
   PR = PRcurrent + (PRformer + PRfuture)（3.109）；
   former 按 inr(inl _) 判真（书定义）——「以前的总统不是
   现在的总统」(3.104)⇒(3.107) 无须时间模型。 *)
Parameters PR_current PR_former PR_future : CN.
Definition PR := sum PR_current (sum PR_former PR_future).
Definition former_PR (x : PR) : Prop :=
  match x with
  | inl _ => False
  | inr (inl _) => True
  | inr (inr _) => False
  end.
Definition current_PR (x : PR) : Prop :=
  match x with inl _ => True | _ => False end.
Record FormerPresident := mkFP
  { fp_of :> PR ; _ : former_PR fp_of }.

Theorem former_not_current : forall f : FormerPresident,
  ~ current_PR f.
Proof.
  intros [p Hf] Hc. destruct p as [c | [fr | fu]].
  - cbv in Hf. exact Hf.
  - cbv in Hc. exact Hc.
  - cbv in Hf. exact Hf.
Qed.
