(* ============================================================
   47 UTT 与类型空间 —— Coq（罗朝晖书 ch.1–2.4 + 6.3.1 概览）
   UTT 双层结构：数据类型 ∈ 直谓塔 Type_i + 逻辑命题 ∈ 非直谓 Prop
   机器面：
   ① Prop 的非直谓性见证（对任意复杂度的类型量化）
   ② 莱布尼茨等式 + ∧/∃ 的 ∀ 编码（书 2.4.1 式 2.16–2.18）
   ③ Prop ⊆ Type 见证（Σ 中使用命题作分量）
   ④ 宇宙塔 Type_i 的层级（书 2.4.2）
   ⑤ 佩亚诺第四公理（书例 2.7）：Prop 作值域定义 IsZero
   ⑥ CN 宇宙与 Π-多态副词（书例 2.8 + 5.3.1）
   ⑦ 子类型空间 U(H) 的依赖对编码（书 2.5.3 式 2.32）
   ============================================================ *)

(* ---- ① Prop 的非直谓性 ----------------------------------
   书 2.4.1：全称命题 ∀x:A.P(x) : Prop 中的 A 可以是**任意**
   类型——包括 Prop 本身（A = Prop）或更复杂者。这在 Coq
   （pCIC，UTT 的实现后裔）里直接通过类型检查： *)
Definition imp_id : Prop := forall X : Prop, X -> X.
(* A = Prop：量化域本身是命题空间——「对所有命题 X」 *)
Definition imp_any (A : Type) (P : A -> Prop) : Prop :=
  forall x : A, P x.
(* A = Prop -> Prop：量化域任意复杂 *)
Definition hh : Prop := forall F : Prop -> Prop, forall X : Prop, F X -> F X.
Check imp_id : Prop.
Check hh : Prop.

(* Girard 悖论不可机器化（会破坏一致性），但可以看它的**入口**：
   若允许 Type : Type（所有类型的类型），则「对任意类型量化」
   与「命题=类型」合流成 Girard 悖论（书 1.1 脚注）。Coq 的
   Type 是**层级** Type@{i} : Type@{j}（i<j），自指被层级隔断。 *)

(* ---- ② 莱布尼茨等式与逻辑算子的 ∀ 编码 ------------------- *)
Definition leib (A : Type) (a b : A) : Prop :=
  forall P : A -> Prop, P a -> P b.          (* 书式 2.18 *)

Lemma leib_refl : forall (A : Type) (a : A), leib A a a.
Proof. intros A a P pa. exact pa. Qed.

Lemma leib_sym : forall (A : Type) (a b : A),
  leib A a b -> leib A b a.
Proof.
  (* 恒等谓词技巧：把 a≤b 的等式作用到谓词 Q y := P y → P a 上 *)
  intros A a b H P pb.
  exact (H (fun y => P y -> P a) (fun pa => pa) pb).
Qed.

(* 合取：书式 2.16  P ∧ Q = ∀X:Prop.(P⇒Q⇒X)⇒X *)
Definition and' (P Q : Prop) : Prop :=
  forall X : Prop, (P -> Q -> X) -> X.

Definition and'_intro : forall P Q : Prop, P -> Q -> and' P Q :=
  fun P Q p q X f => f p q.
Definition and'_elim_l : forall P Q : Prop, and' P Q -> P :=
  fun P Q h => h P (fun p _ => p).
Definition and'_elim_r : forall P Q : Prop, and' P Q -> Q :=
  fun P Q h => h Q (fun _ q => q).

(* 存在：书式 2.17  ∃x:A.P(x) = ∀X:Prop.(∀x:A.P⇒X)⇒X *)
Definition ex' (A : Type) (P : A -> Prop) : Prop :=
  forall X : Prop, (forall x : A, P x -> X) -> X.

Definition ex'_intro : forall (A : Type) (P : A -> Prop) (a : A),
  P a -> ex' A P :=
  fun A P a pa X f => f a pa.

(* 二阶编码的交换律（不需要排中，纯构造） *)
Lemma and'_comm : forall P Q : Prop, and' P Q -> and' Q P.
Proof.
  intros P Q h X f. apply h. intros p q. exact (f q p).
Qed.

(* ---- ③ Prop ⊆ Type --------------------------------------
   书 2.4.2：Prop : Type₀ 且每个 P:Prop 也是 Type₀ 的对象。
   机器见证：命题 x = x 可以作为 Type 层 Σ 类型的分量出现。 *)
Definition ReflexiveType (A : Type) : Type :=
  { x : A | x = x }.                          (* sig : Type，分量在 Prop *)
Check ReflexiveType nat : Type.

(* ---- ④ 宇宙塔 --------------------------------------------
   书 2.4.2：直谓塔 U₀ ∈ U₁ ∈ …。Coq 中 Set : Type@{0}? 打印
   宇宙即可见层级性：Type@{i} : Type@{j} 仅当 i < j。 *)
Check Set : Type.
Check Type : Type.     (* 层级塔：这里的两个 Type 是不同层的宇宙 *)
Definition Type1_is_big : Type := Type -> Type.
Check Type1_is_big : Type.

(* ---- ⑤ 佩亚诺第四公理（书例 2.7）------------------------
   关键：IsZero : Nat -> Prop 以**命题为值**（true/false 是
   类型——命题即类型），值域是类型空间 Prop——没有类型空间
   则此函数无法定义，第四公理不可证（书引 [206]）。 *)
Definition IsZero (n : nat) : Prop :=
  match n with
  | O => True
   | S _ => False
  end.

(* 书原证：λx.λh:(0 =Nat succ x). h^IsZero id
   ——把等式证明 h 作用到谓词 IsZero 上，真值证明 id 搬过去 *)
Lemma peano4_leib : forall x : nat, ~ leib nat 0 (S x).
Proof.
  intros x h. exact (h IsZero I).       (* h : ∀P, P 0 -> P (S x)；取 IsZero *)
Qed.                                     (* IsZero 0 = True 有证明 I；
                                            IsZero (S x) = False 矛盾 *)

(* 对照：Coq 原生 eq 版（结构等式即判，无需宇宙） *)
Lemma peano4_eq : forall x : nat, S x <> 0.
Proof. discriminate. Qed.

(* ---- ⑥ CN 宇宙与 Π-多态（书例 2.8 + 5.3.1）--------------
   通名（普通名词）的语义都是类型，它们一起组成类型空间 CN。
   Coq 不允许自定义类型空间——书 5.3.1 以 Set 充当 CN。 *)
Definition CN := Set.

Parameter Human Cat : CN.
Parameter zhang : Human.
Parameter talk : Human -> Prop.

(* 副词「很快（地）」：书式 2.26 / 3.24
   quickly : ΠA:CN.(A→Prop) → (A→Prop) —— 论域随通名 A 变化 *)
Parameter quickly : forall A : CN, (A -> Prop) -> A -> Prop.
Parameter run : Human -> Prop.

Definition john_runs_quickly : Prop := quickly Human run zhang.

(* 量词 some 的类型：书表 3.2 —— ΠA:CN.(A→Prop)→Prop *)
Definition some (A : CN) (P : A -> Prop) : Prop :=
  exists x : A, P x.
Check some : forall A : CN, (A -> Prop) -> Prop.
Check some Human talk : Prop.

(* ---- ⑦ 子类型空间 U(H) 与有界量化（书 2.5.3 式 2.32）----
   U(H) 由 H 的所有子类型组成。依赖对编码：每个对象 = 类型 A
   + 内射 A -> H（强制转换）。「有界量化」∀X ≤ H. B(X) 在此
   编码下就是「对所有子类型包」的量化——对 50 章 Fω<: 的
   不可判定问题（源自 Top）是干净的解：这里的 H 是**具体的
   类型**，不是「所有类型的顶类型」。 *)
Definition U (H : Type) : Type := { A : Type & A -> H }.

Parameter evenSub : { A : Type & A -> nat }.   (* nat 的某子类型包 *)

Definition bounded_all (H : Type) (P : U H -> Prop) : Prop :=
  forall X : U H, P X.                        (* 书式 2.32 的有界 ∀ *)
Check (bounded_all nat (fun _ => True)) : Prop.

(* 有界量化的一个可判定场景：子类型包之间的「成员计数」
   bounded_all nat (fun X => ...) 对每个包 X 检查性质 P——
   注意同一子类型可有多个包表示（不同内射），这正是合谐性
   （54 章）要求「至多一个强制转换」的动机。 *)

(* ---- 收束见证：Prop 层与 Type 层在同一证明里合流 ---- *)
Lemma utt_structure_ok :
  and' (forall X : Prop, X -> X) (ex' nat (fun n => n = 0)).
Proof.
  apply and'_intro.
  - exact (fun X x => x).                (* Prop 层：非直谓命题 *)
  - exact (ex'_intro nat (fun n => n = 0) 0 (eq_refl 0)).
Qed.
