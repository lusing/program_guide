(* ============================================================
   50 MTT 语义学：通名即类型 —— Coq（罗朝晖书 3.1–3.3 + 5.3.1）
   蒙太古语义学（简单类型论 e/t）vs MTT 语义学（现代类型论）
   的根本对垒：通名是**谓词**（e→t，万物皆实体）还是**类型**
   （Cat/Human/Table 各立门户）。
   机器面：
   ① 表 3.2 各词汇范畴的 MTT 类型（通名/动词/形容词/副词/GQ）
   ② 选择限制 = 类型检测：「桌子会讲话」Fail 见证（蒙太古
      下合法、MTT 下非法——ex50_mttsem.pl 双轨判决）
   ③ 子类型的必要性：read 例（式 3.33–3.41）Man ≤ Human、
      Σheavy ≤ Book 经强制合法
   ④ 异义词 run 的消歧模型（书 5.3.1：单点类型 + 双强制）
   ⑤ 事件强迫 enjoy：Book ≤reading Event（3.50–3.55）
   ============================================================ *)

(* ---- 基本假设（书 5.3.1）-------------------------------- *)
Definition CN := Set.   (* Coq 无自定义类型空间，书以 Set 充当 CN *)

Parameters Human Cat Table Book Animal Institution Object Event : CN.
Parameters zhang julie : Human.

(* 强制性子类型（48 章理论上岗）：Cat ≤ Animal ≤ Object *)
Axiom ca : Cat -> Animal.  Coercion ca : Cat >-> Animal.
Axiom ao : Animal -> Object. Coercion ao : Animal >-> Object.
(* Man = Σx:Human.male(x) ≤π1 Human（书式 3.39） *)
Parameter male : Human -> Prop.
Record Man := mkMan { man_of :> Human ; male_prf : male man_of }.
Definition zhang_man : Man.
Proof. refine (mkMan zhang _). Admitted.       (* 教学占位：设 zhang 男 *)

(* ---- ① 表 3.2：各词汇范畴的 MTT 类型 --------------------- *)
Parameter talk : Human -> Prop.                (* 动词：讲话 *)
Parameter black : Object -> Prop.              (* 形容词：黑的 *)
Parameter quickly : forall A : CN, (A -> Prop) -> A -> Prop.  (* 副词 *)
Parameter run_q : Human -> Prop.               (* 跑（用于副词例） *)
Definition some (A : CN) (P : A -> Prop) : Prop :=
  exists x : A, P x.                           (* GQ：某些，式 3.12 *)
Definition all (A : CN) (P : A -> Prop) : Prop :=
  forall x : A, P x.
Definition no (A : CN) (P : A -> Prop) : Prop :=
  forall x : A, ~ P x.

(* 「有的学生讲话」(3.13/3.14)：some(Student, talk) = ∃x:Student.talk(x)
   ——talk 的论域是 Human 而 x 的类型是 Student，合法性靠
   Student ≤ Human。此处以 Man 代 Student 演示同一机制。 *)
Parameter Student : CN.
Axiom sh : Student -> Human. Coercion sh : Student >-> Human.
Parameter zhang_stu : Student.
Definition example_some : Prop := some Student talk.
Check example_some : Prop.
Example some_demo : talk zhang_stu -> example_some.
Proof. intros H. exists zhang_stu. exact H. Qed.
(*   关键在 H : talk zhang_stu 本身通过了类型检查——
     talk 的论域是 Human 而 zhang_stu : Student，
     Student ≤ Human 的强制被隐式插入（式 3.14 的机器面），
     装进存在量词即得整句语义 *)

(* ---- ② 选择限制 = 类型检测（书 3.3.3）--------------------
   「桌子会讲话」(3.20)：蒙太古语义 talkM(tableM) 是合法公式
   （e→t 作用于 e，式 3.21，只是通常为假）；MTT 语义 talk(t)
   （式 3.22）非法——talk 的论域 Human 与 Table 互不相交，
   无强制可插。Coq 侧的机器见证：定义**根本编译不过**，
   用 Fail 命令把这个失败变成检查项。 *)
Parameter table1 : Table.
Fail Definition tables_talk : Prop := talk table1.
(* 同理：「黑猫是黑色的」合法（Cat ≤ Object 经链式强制），
   「桌子是黑的」……black : Object→Prop 论域是 Object——
   Table ≤ Object 没有声明，同样失败： *)
Fail Definition black_table : Prop := black table1.
Definition black_cat_ok : Cat -> Prop := black.    (* 链式强制放行 *)

(* ---- ③ read 例（书式 3.33–3.41）--------------------------
   read : Human → Book → Prop；zhang : Man；W&P : Σx:Book.heavy(x)
   三个语义 read(zhang, b) / read(h, W&P) 都合法——靠
   Man ≤π1 Human 与 Σheavy ≤π1 Book 两条投射/常量强制。 *)
Parameter read : Human -> Book -> Prop.
Parameter heavy : Book -> Prop.
Record HeavyBook := mkHB { hb_of :> Book ; heavy_prf : heavy hb_of }.
Parameter WP : HeavyBook.
Check (read zhang_man WP) : Prop.
(*   zhang_man : Man  →π1→  Human ✓（48 章 Man 记录字段强制）
     WP : HeavyBook  →π1→  Book  ✓（同款投射强制）
   一句双强制——(3.38) read(zhang, W&P) 的机器面。 *)

(* ---- ④ 异义词 run 的消歧（书 5.3.1，式 3.42–3.49）-------
   「花」名词/动词、「跑/经营」同形异义：单点类型 One_run
   承载词义，两条强制 c1/c2 按语境自动选择。 *)
Inductive Onerun : Set := run_word.
Definition T1 := Human -> Prop.                    (* run₁ 跑 *)
Definition T2 := Human -> Institution -> Prop.     (* run₂ 经营 *)
Parameter run1 : T1.
Parameter run2 : T2.
Definition r1 (r : Onerun) : T1 := run1.
Definition r2 (r : Onerun) : T2 := run2.
Coercion r1 : Onerun >-> T1.
Coercion r2 : Onerun >-> T2.
Parameter john : Human.
Parameter bank1 : { b : { c : Institution & True } & True }%type. (* 占位 *)

(* 「John runs quickly」：语境要求 Human→Prop → 选 run1 *)
Definition john_runs_quickly : Prop := quickly Human (run_word : T1) john.
(* 「John runs a bank」：语境要求 Human→Inst→Prop → 选 run2 *)
Parameter bankh : Institution.
Definition john_runs_a_bank : Prop := exists b : Institution, (run_word : T2) john b.
Check john_runs_quickly : Prop.
Check john_runs_a_bank : Prop.

(* ---- ⑤ 事件强迫 enjoy（书 3.3.4，式 3.50–3.55）----------
   「Julie enjoyed a book」=「Julie enjoyed reading a book」：
   enjoy 的论域是 Event，但 Book ≤reading Event——reading
   作为强制转换被省略地插入。 *)
Parameter enjoy : Human -> Event -> Prop.
Parameter reading_ev : Book -> Event.
Coercion reading_ev : Book >-> Event.
Definition julie_enjoyed : Prop := exists x : Book, enjoy julie x.
(*   enjoy julie x 中 x : Book 被自动转为 reading_ev(x)——
     (CD)：julie_enjoyed 定义性等于
     ∃x:Book. enjoy(julie, reading_ev(x))，即式 3.55。 *)
Set Printing Coercions.
Check julie_enjoyed.
Unset Printing Coercions.
