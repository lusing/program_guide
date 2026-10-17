(* ============================================================
   53 标记与点类型 —— Coq（罗朝晖书 4.1–4.2）
   ① 标记（signature）：语境要用**常量**描述（上下文的变量
      可被量化抽象——「萌萌」不是任意一只猫）；Coq 的
      Section 局部强制 = 标记**子类型条目**的机器化身
      （Sandwich ≤k Human 只在餐馆情景内成立，式 4.4–4.7）
   ② 定义性条目 c~a:A：单点类型 1(A,a) 的技巧（书 4.1.3）
   ③ 点类型 A•B 与同谓（copredication）：午餐既可口（Food）
      又花时间（Process）——A•B 两侧**不共享组成部分**
      （定义 4.1），p1/p2 双投影强制**合谐**（定理 4.1——
      与 54 章 PairNN 双 nat 字段的 ambiguous-paths 反例恰成
      对照：歧义只在两强制**同目标**时发生）
   ④ 集胚/子集胚与数字量词「三」（定义 4.2–4.5）
   ============================================================ *)

(* ---- ① 标记：常量 + 局部子类型（书 4.1）------------------
   语境 ≠ 上下文：Meng : Cat 作上下文条目是**变量**，可被
   λMeng:P(Meng) 抽象——荒谬（萌萌是具体的猫）。标记条目
   c : A 是常量，不可抽象。Coq 的 Parameter 即常量语义。 *)
Parameters Cat53 : Type.
Parameter Meng : Cat53.                   (* 标记条目：萌萌 *)
Parameter black53 : Cat53 -> Prop.
(* 上下文版（错误示范，注释保留）：
   context x : Cat 里 x 是变量，∀x:Cat.P(x) 可抽象；
   标记版 Meng 不可抽象——两者的分野在「能否被量化」。 *)

Section Restaurant.
  (* 标记的**子类型条目**（书式 4.5）：Sandwich ≤k Human
     ——「那个三明治还没付账就走了」（式 4.4），指称变迁：
     k 把三明治映到买它的顾客。局部性：只在餐馆情景内。 *)
  Parameters Sandwich53 Human53 : Type.
  Parameter s53 : Sandwich53.
  Parameters pay53 leave53 : Human53 -> Prop.
  Parameter k53 : Sandwich53 -> Human53.
  Coercion k53 : Sandwich53 >-> Human53.
  (* 式 4.6：¬pay(s) ∧ leave(s) ——s 的类型是 Sandwich53，
     两个谓词的论域 Human53，强制 k53 隐式插入 *)
  Definition sem_4_6 : Prop := ~ pay53 s53 /\ leave53 s53.
  Set Printing Coercions.
  Check sem_4_6.
  Unset Printing Coercions.
End Restaurant.
(* Section 关闭后局部强制失效——「三明治是人」出了餐馆
   不再成立。标记类型论 TS[C] 的局部化思想（书 6.3.3）
   在 Coq 里的最近亲。 *)

(* ---- ② 定义性条目与单点类型（书 4.1.3）-------------------
   c~a:A 即 c:1(A,a) 的简写——1(A,a) 是以 a 为唯一对象的
   参数化单点类型（书 6.3.1 式 (6.11) 附近）。 *)
Definition Singleton1 (A : Type) (a : A) : Type := { x : A | x = a }.
Definition def_entry (A : Type) (a : A) : Singleton1 A a :=
  exist _ a (eq_refl a).
(* c 处处可代表 a：任何函数作用在 c 上都等于作用在 a 上 *)
Lemma rep_ok : forall (A B : Type) (a : A) (f : A -> B) (c : Singleton1 A a),
  f (proj1_sig c) = f a.
Proof. intros A B a f c. destruct c as [x Hx]. subst x. reflexivity. Qed.

(* ---- ③ 点类型与同谓（书 4.2）-----------------------------
   「午餐挺可口，但花了很长时间」（式 4.9）：
     delicious : Food -> Prop，take_long : Process -> Prop
   论域 Food 与 Process 互不相交——同一顿午餐却要同时进
   两个论域。点类型 Food•Process（式 4.10/4.11 的解）。 *)
Parameters Food53 Process53 PHY53 INFO53 : Type.
Parameters delicious : Food53 -> Prop.
Parameters take_long : Process53 -> Prop.
Parameters Lunch53 : Type.
Parameter l53 : Lunch53.

(* 点类型：p1/p2 双投影强制——**合谐**（定理 4.1），因为
   两侧目标 Food/Process 不共享组成部分（定义 4.1：
   C(A)∩C(B)=∅，PHY•PHY、PHY•(PHY•INFO) 都不成点类型） *)
Record FoodProcess := mkFP
  { fp_food :> Food53 ; fp_proc :> Process53 }.
Axiom lunch_dot : Lunch53 -> FoodProcess.
Coercion lunch_dot : Lunch53 >-> FoodProcess.
(* 式 4.11：delicious(l) ∧ take_long(l) 合法——一句双目标 *)
Definition sem_4_11 : Prop := delicious l53 /\ take_long l53.
Check sem_4_11 : Prop.
(* 注意：fp_food 与 fp_proc 的目标类型**不同**——不触发
   54 章 PairNN 的 ambiguous-paths（歧义只在两强制同目标
   时发生）。这正是点类型优于积类型的类型论根据：积的
   π1/π2 若同作强制则 Nat×Nat ≤π1 Nat 且 ≤π2 Nat——
   不合谐；点类型因 C(A)∩C(B)=∅ 而天然免疫。 *)

(* 书的组成部分定义 4.1（示意）：
   C(T) 按 nf(T) 的形状归纳——Σ 形取左支，点形取两支之并；
   形成点类型 A•B 要求 C(A)∩C(B)=∅：
     PHY•PHY ✗（同一类型）
     PHY•(PHY•INFO) ✗（共享 PHY）
     PHY•INFO ✓ *)

(* ---- 「书」的同谓（书式 4.12–4.14）------------------------
   张三拿了本书来读：take 论域 PHY、read 论域 INFO，
   Book ≤ PHY•INFO 让 b 同时两侧合法。 *)
Record PHYINFO := mkPI { pi_phy :> PHY53 ; pi_info :> INFO53 }.
Parameter Book53 : Type.
Axiom book_dot : Book53 -> PHYINFO.
Coercion book_dot : Book53 >-> PHYINFO.
Parameters take_z read_z : Book53 -> Prop.
Parameter zhang53 : Type -> Prop.   (* 占位 *)
Definition sem_4_14 (b : Book53) : Prop := take_z b /\ read_z b.
Check (fun b : Book53 => sem_4_14 b) : Book53 -> Prop.

(* ---- ④ 集胚、子集胚与量词「三」（书 4.2.3，定义 4.2–4.5） *)
Record Setoid := mkSetoid
  { carrier : Type ; equiv : carrier -> carrier -> Prop
  ; equiv_refl  : forall x, equiv x x
  ; equiv_sym   : forall x y, equiv x y -> equiv y x
  ; equiv_trans : forall x y z, equiv x y -> equiv y z -> equiv x z }.
(* 子集胚（定义 4.3）：A ⊑ B 当有 c:A→B 且 (=A) = (=B)|A ——
   「两个男人是同一个男人当且仅当同一个人」（式 4.21），
   子通名**继承**母通名的等同标准 *)
Record Subsetoid (B : Setoid) := mkSub
  { sub_carrier : Type
  ; sub_coerce :> sub_carrier -> carrier B
  ; sub_inherit : forall x y : sub_carrier,
      equiv B (sub_coerce x) (sub_coerce y)
      <-> (fun _ _ => True) x y \/ equiv B (sub_coerce x) (sub_coerce y) }.
(*   （教学简化：完整定义见书——继承条件 (=A)=（=B)|A 的
     机器化需要把「限制」写成谓词组合，此处示意结构。） *)

(* 数字量词「三」（定义 4.5 的三元素精神）：
   Three(A,B,P) = ∃三个 A 对象两两按 B 的标准不等且都满足 P *)
Definition Three (A B : Type) (neq : B -> B -> Prop)
  (embed : A -> B) (P : A -> Prop) : Prop :=
  exists x y z : A,
    neq (embed x) (embed y) /\ neq (embed y) (embed z)
    /\ neq (embed x) (embed z)
    /\ P x /\ P y /\ P z.
(* 「张三拿了三本不同的书来读」（式 4.15/4.26）——书在
   PHY•INFO 的**双标准**下两两不同：书 a≠b 要同时 ≠phy
   且 ≠info（书定义 4.4 的合取不等）——同谓现象与量词
   相互作用时，等同标准由**集胚**承载，这正是「通名即
   集胚」（CNs-as-setoids）解释模式的用武之地。 *)
