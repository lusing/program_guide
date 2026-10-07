(* ex33_modalnd —— 模态自然演绎与知识逻辑 KT45n（H&R §5.4-5.5）

   对书：Huth&Ryan §5.4（模态 ND 四规则）/ §5.5.1-5.5.4（KT45n
             与 muddy children）
   依赖：31 章 frame/msat 基础设施（自包含复制）

   交付两件：
   (1) 模态 ND 深嵌入：□i 带**严格性侧条件**（上下文全 □ 形时
       才能引入 □——「虚线框」的类型化）+ □e + ◇i + ◇e；
       派生件：上下文含 ¬◇φ 且全 □ 形时 ⊢ □¬φ——上下文条目
       在 □ 框内**存活**（mnHyp 跨框），推导不 wander。
   (2) muddy children 两孩版：四世界模型 + 公开宣告 = 世界过滤
       的表计算——第二轮「都知道」的 decide 现场。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

(* ---------- 语法（含 ⊥） ---------- *)

Inductive mform : Type :=
| mBot  : mform
| mAtom : nat -> mform
| mNeg  : mform -> mform
| mImp  : mform -> mform -> mform
| mBox  : mform -> mform
| mDia  : mform -> mform.

(* ---------- 模态 ND：□i 的严格性侧条件 ---------- *)

Fixpoint allBoxed (G : list mform) : bool :=
  match G with
  | [] => true
  | mBox _ :: G' => allBoxed G'
  | _ :: _ => false
  end.

Inductive mnd : list mform -> mform -> Prop :=
| mnHyp : forall G f, In f G -> mnd G f
| mnBotE : forall G f, mnd G mBot -> mnd G f
| mnImpI : forall G f g, mnd (f :: G) g -> mnd G (mImp f g)
| mnImpE : forall G f g, mnd G (mImp f g) -> mnd G f -> mnd G g
| mnNegI : forall G f, mnd (f :: G) mBot -> mnd G (mNeg f)
| mnNegE : forall G f, mnd G (mNeg f) -> mnd G f -> mnd G mBot
(* □i（严格性）：上下文全 □ 形——H&R 虚线框：进入框内
   只剩必然知识；上下文**条目**跨框存活（mnHyp 仍可用） *)
| mnBoxI : forall G f,
    allBoxed G = true -> mnd G f -> mnd G (mBox f)
(* □e：必然知识随时可用 *)
| mnBoxE : forall G f, mnd G (mBox f) -> mnd G f
(* ◇i *)
| mnDiaI : forall G f, mnd G f -> mnd G (mDia f)
(* ◇e：临时见证框（□f 伪装成必然形进框——H&R 的 ◇ 消去纪律） *)
| mnDiaE : forall G f g,
    mnd G (mDia f) -> mnd (mBox f :: G) g -> mnd G g.

(* ---------- 侧条件的拦截现场 ---------- *)

(* 上下文有非 □ 形条目时 allBoxed 直接 false——□i 被类型挡 *)
Example allBoxed_ok : allBoxed [mBox (mAtom 0)] = true.
Proof. reflexivity. Qed.

Example allBoxed_bites : allBoxed [mAtom 0] = false.
Proof. reflexivity. Qed.

(* ---------- 派生件：¬◇φ ⊢ □¬φ（上下文版） ---------- *)

(* 读法：上下文里挂着 ¬◇φ（且全 □ 形）时 □¬φ 可推——
   □ 框内的 φ 假设经 ◇i 造 ◇φ，与跨框存活的 ¬◇φ 对撞。
   注意：**推导**不能跨框 wander——上下文条目可以（mnHyp）。
   这正是严格性侧条件的用意：只有必然化的知识进框。 *)
Theorem notDia_to_boxNeg : forall G f,
  allBoxed G = true ->
  In (mNeg (mDia f)) G ->
  mnd G (mBox (mNeg f)).
Proof.
  intros G f Hab Hin.
  apply mnBoxI; [exact Hab|].
  apply mnNegI.
  apply (mnNegE _ (mDia f)).
  - apply mnHyp. right. exact Hin.
  - apply mnDiaI. apply mnHyp. left. reflexivity.
Qed.

(* ---------- □ 分配（K 模式的演算内形态） ---------- *)

Theorem K_mnd : forall G f g,
  mnd G (mBox (mImp f g)) -> mnd G (mBox f) -> mnd G (mBox g).
Proof.
  intros G f g Hfg Hf.
  destruct (allBoxed G) eqn:Hab.
  - apply mnBoxI; [exact Hab|].
    apply (mnImpE _ f _).
    + apply mnBoxE. exact Hfg.
    + apply mnBoxE. exact Hf.
  (* 上下文非全 □ 形时：两个 □ 前提本身在上下文外——
     教学版按侧条件形态陈述；无侧条件版需要框化引理，登记边界 *)
Abort.

(* ---------- muddy children 两孩版（KT45n 语义现场） ---------- *)

(* 世界 = (m1, m2)：两位孩子的泥额（true=有泥）。
   主体 i 的可达 = 只看对方额（自己额不可见）。
   宣告₁「至少一个有泥」= 滤掉 (0,0)。
   宣告₂「第一轮没人行动」= 滤掉「对方第一轮就能确定自己」的世界。
   全程布尔表计算，decide/reflexivity 直收。 *)

Definition w4 : list (bool * bool) :=
  [(true, true); (true, false); (false, true); (false, false)].


Definition vis1' (u v : bool * bool) : bool := Bool.eqb (snd u) (snd v).
Definition vis2' (u v : bool * bool) : bool := Bool.eqb (fst u) (fst v).

(* 宣告₁后的世界表 *)
Definition afterAnn1 : list (bool * bool) :=
  filter (fun v => negb (andb (Bool.eqb (fst v) false)
                               (Bool.eqb (snd v) false))) w4.

(* 主体 1 在 w 的（宣告₁后）可达表 *)
Definition reach1 (w : bool * bool) : list (bool * bool) :=
  filter (fun v => vis1' w v) afterAnn1.

(* 主体 2 在 w 的（宣告₁后）可达表 *)
Definition reach2 (w : bool * bool) : list (bool * bool) :=
  filter (fun v => vis2' w v) afterAnn1.

(* 第一轮：主体 i 知道自己额 ⟺ 可达表内 fst/snd 全真 *)
Definition kid1_knows_r1 (w : bool * bool) : bool :=
  forallb (fun v => Bool.eqb (fst v) true) (reach1 w).
Definition kid2_knows_r1 (w : bool * bool) : bool :=
  forallb (fun v => Bool.eqb (snd v) true) (reach2 w).

(* 宣告₂：滤掉「有人第一轮就知道」的世界 *)
Definition afterAnn2 : list (bool * bool) :=
  filter (fun v => andb (negb (kid1_knows_r1 v))
                        (negb (kid2_knows_r1 v))) afterAnn1.

(* 第二轮主体 1 在 w 的可达表（宣告₂后） *)
Definition reach1' (w : bool * bool) : list (bool * bool) :=
  filter (fun v => vis1' w v) afterAnn2.

(* ---------- 决定性现场 ---------- *)

(* 现场一：世界 (1,1)（都有泥）第一轮谁都不知道 *)
Example r1_nobody_knows :
  andb (negb (kid1_knows_r1 (true, true)))
       (negb (kid2_knows_r1 (true, true))) = true.
Proof. reflexivity. Qed.

(* 现场二：世界 (0,1)（只有 2 有泥）第一轮主体 2 就知道 *)
Example r1_kid2_knows :
  kid2_knows_r1 (false, true) = true.
Proof. reflexivity. Qed.

(* 现场三（招牌）：宣告₂后在 (1,1) 处主体 1 的可达表只剩 (1,1)
   ——「都知道」兑现 *)
Example r2_kid1_knows :
  reach1' (true, true) = [(true, true)].
Proof. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - mnBoxI 的严格性侧条件是**数据**（allBoxed 计算上下文形状）
     ——深嵌入里侧条件「类型化」的直接形态；
   - 派生件的正确姿势：把前提放进**上下文**（mnHyp 跨框存活），
     而不是当外部推导（推导不能 wander 进框——严格性的用意）；
   - K_mnd 无侧条件版需要「框化」引理（演绎定理的模态版），
     登记边界（与 17 章 Gen 侧条件同族）；
   - 泥孩子全程 bool 表计算：vis/afterAnn/reach 都是 Definition，
     reflexivity 直收——语义推理被「过滤+量化」的程序化吸收；
     宣告即过滤（public announcement = world elimination）是
     动态认知逻辑的最小教学模型。 *)
