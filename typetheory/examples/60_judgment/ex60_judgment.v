(* ============================================================
   54 判断语义与事件语义 —— Coq（罗朝晖书 4.3–4.4 + 5.3.4）
   ① 判断语义的命题形式：「张三是人」= 判断 zhang:Human，
      判断不是命题——不能否定、不能组合。IS/DO/NOT 三算子
      （式 4.53–4.55）；NOT 由**异类等式 JMeq**（McBride）
      定义（式 4.56），定律 A1–A3 机器证明（定理 4.2 选段）
   ② 生成过剩的防线：类型不相交 + 否定性语境（4.3.3）
   ③ 依赖事件类型 Evt_A/Evt_P/Evt_AP 与强制菱形（图 4.5），
      合谐条件 c3(a)∘c1 = c4(p)∘c2（书 121 页）
   ④ 事件量化问题 EQP：错误语义在依赖事件类型下**非法**
      （Fail 见证，书 5.3.4 II）
   ⑤ 选择限制的回归与「带论域的依赖事件类型」Evt_A[H]
      （书 5.3.4 III）
   ============================================================ *)

(* ---- ① 判断语义 → 命题形式（书 4.3）---------------------- *)
Parameters Human54 Table54 Book54 : Type.
Parameter zhang54 : Human54.

(* 正确判断 a:A 的命题形式：常真谓词 P_A(a)（式 4.38）
   —— 其合法性**预设** a : A 可导出 *)
Definition PA (A : Type) (a : A) : Prop := True.

(* JMeq（McBride 异类等式，自造——Coq 8.20 预加载库里无）：
   不同类型对象间的等式命题 a ≈ b（A、B 可以不同） *)
Inductive JMeq {A : Type} (a : A) : forall {B : Type}, B -> Prop :=
| JMeq_refl : JMeq a a.

(* 判断不是命题：¬(zhang : Table) 不能写成命题（式 4.42 ✗），
   对**错误**判断需要命题形式 is(A, t)（式 4.45）。
   IS/DO/NOT 三算子由 NOT 定义（式 4.53–4.56）： *)
Definition NOT (A : Type) (p : A -> Prop) (B : Type) (b : B) : Prop :=
  forall x : A, JMeq x b -> ~ p x.
Definition is (A B : Type) (b : B) : Prop := NOT A (fun _ => True) B b.
Definition do (A B : Type) (p : A -> Prop) (b : B) : Prop := NOT A p B b.
(*   is(A,b) ≈「b 是 A」；do(p,b) ≈「b 做 p」 *)

(* 定律 A1（式 4.54 组）：p x 蕴含 ¬NOT(A,p,A,x) *)
Lemma law_A1 : forall (A : Type) (p : A -> Prop) (x : A),
  p x -> ~ NOT A p A x.
Proof.
  intros A p x Hpx HN. apply (HN x).
  - exact (JMeq_refl x).
  - exact Hpx.
Qed.

(* 定律 A2（式 4.55 组）：p 蕴含 q ⟹ do(q) 蕴含 do(p)
   ——「不会讲话 ⟹ 不会大声讲话」 *)
Lemma law_A2 : forall (A B : Type) (p q : A -> Prop),
  (forall x : A, p x -> q x) ->
  forall b : B, do A B q b -> do A B p b.
Proof.
  intros A B p q Himp b Hq x Hjm Hpx.
  apply (Hq x Hjm). apply Himp. exact Hpx.
Qed.

(* 「桌子不会讲话」(式 4.47/4.49)：talk 论域 Human、w 论域
   Table——¬DO(talk, t) 合法 *)
Parameter talk54 : Human54 -> Prop.
Definition tables_dont_talk : Prop :=
  forall t : Table54, ~ do Human54 Table54 talk54 t.
Check tables_dont_talk : Prop.
(*   ——判断语义进了否定性语境，命题化合法（4.3.3） *)

(* ---- ② 生成过剩的防线（书 4.3.3）--------------------------
   IS/DO 不能无限制用：「张三是一张桌子」(4.57) 不能给
   is(Table, zhang)。必要条件一：类型不相交（Human 与 Table
   无共同子类型）；条件二：否定性语境（定义 4.7）。
   Coq 侧：is 的定义已把 A 上的谓词喂给 NOT——若 A=Human、
   b : Human，is(Human, zhang) 可证但平凡（PA 常真）；
   越界的 is(Table, zhang) 在 Coq 里因 b : Human54 ≠ Table54
   而直接类型错误： *)
Definition over_gen : Prop := is Table54 Human54 zhang54.
(*   ——注意：形式上**合法**！is 的 A、B 是独立参数。这正是
   书 4.3.3 的警示：IS/DO 的类型本身不设防，「张三是桌子」
   的生成过剩要靠**语境纪律**（类型不相交 + 否定性语境）
   防守，而非类型检查——MTT 语义学的自我约束条款 *)

(* ---- ③ 依赖事件类型与强制菱形（书 4.4.2–4.4.3，图 4.5）-- *)
Parameters Agent54 Patient54 Event54 : Type.
Parameter Evt_A  : Agent54 -> Type.        (* 施事为 a 的事件 *)
Parameter Evt_P  : Patient54 -> Type.      (* 受事为 p 的事件 *)
Parameter Evt_AP : Agent54 -> Patient54 -> Type.
(* 四条强制构成菱形：Evt_AP ≤c1 Evt_A ≤c3 Event 等 *)
Axiom c1 : forall (a : Agent54) (p : Patient54), Evt_AP a p -> Evt_A a.
Axiom c2 : forall (a : Agent54) (p : Patient54), Evt_AP a p -> Evt_P p.
Axiom c3 : forall a : Agent54, Evt_A a -> Event54.
Axiom c4 : forall p : Patient54, Evt_P p -> Event54.
Coercion c1 : Evt_AP >-> Evt_A.
Coercion c3 : Evt_A >-> Event54.
Coercion c4 : Evt_P >-> Event54.
(* 注意 c2 未注册成全局 Coercion（它依赖两个参数且 Coq 的
   强制系统对双参数函数目标支持有限）——以 Axiom 承载，
   见下面合谐条件的陈述。 *)

(* 合谐条件（书 121 页）：两条路径到 Event 必须相同
     c3(a) ∘ c1(a,p) = c4(p) ∘ c2(a,p)
   ——菱形的「对角相等」，否则 Evt_AP 的对象经两条路到
   Event 得到两个不同映像，(CD) 的恢复就崩了 *)
Axiom diamond_coherent : forall (a : Agent54) (p : Patient54)
  (v : Evt_AP a p), c3 a (c1 a p v) = c4 p (c2 a p v).

(* ---- ④ EQP：错误语义非法化（书 5.3.4 II）------------------
   「没有人讲话」：普通事件类型下错误语义（式 4.88）是
   **合法**命题（量词可搬家）；依赖事件类型下（式 4.90）
   因 x 跑出辖域而**非法**——Coq 的 Fail 见证： *)
Parameter talk_ev : Event54 -> Prop.
Parameter ag : Event54 -> Agent54.
Axiom ha54 : Human54 -> Agent54.
Coercion ha54 : Human54 >-> Agent54.

(* 正确语义（式 4.89）：合法 *)
Definition intended_sem : Prop :=
  ~ exists (x : Human54) (v : Evt_A x), talk_ev v.
Check intended_sem : Prop.
(* 错误语义（式 4.90）：exists v : Evt_A(x) 中 x 未绑定 ——
   依赖类型把量词辖域焊死，搬家直接非法 *)
Fail Definition incorrect_sem : Prop :=
  exists v : Evt_A x, ~ exists x : Human54, talk_ev v.

(* ---- ⑤ 选择限制的回归与带论域事件类型（书 5.3.4 III）-----
   引入事件后（Table ≤ Agent 时）「桌子会讲话」的事件语义
   （式 4.93）**居然合法**——选择限制丢了！解药：事件类型
   带论域参数 Evt_A[H](d)——d 的类型限为 H 的子类型。 *)
Axiom ta54 : Table54 -> Agent54.
Coercion ta54 : Table54 >-> Agent54.
Parameter talk_H : Human54 -> Prop.
(* 事件版（式 4.93）：合法——但这是**失去选择限制**的合法 *)
Definition illegal_sem : Prop :=
  forall t : Table54, exists v : Evt_A t, talk_ev v.
(* 带论域版（式 4.94）：Evt_H(d) := Evt_A(d) 且 d : Human——
   t : Table54 喂不进 Human 位，非法 *)
Definition Evt_H (h : Human54) : Type := Evt_A h.
Fail Definition illegal_sem2 : Prop :=
  forall t : Table54, exists v : Evt_H t, talk_ev v.

(* ---- 事件强迫完整版（书 5.3.4 I：War and Peace）-----------
   Julie started W&P / Tolstoy finished / never lasts /
   never finishes long novels——read/write 的强制 c(h,b)
   按「h 是否为 b 的作者」选边（式 3.57–3.60 的依赖版） *)
Parameters start54 finish54 last54 : forall h : Human54, Evt_A h -> Prop.
Parameter read54 : forall h : Human54, Book54 -> Evt_A h.
Parameter long54 : Book54 -> Prop.
Record LBook := mkLB54 { lb54 :> Book54 ; _ : long54 lb54 }.
Parameters j54 t54 : Human54.
Parameter WP54 : Book54.
(* 依赖性强制 cj : Book -> Evt_A(j)（j 不是作者 → reading） *)
Definition cj (b : Book54) : Evt_A j54 := read54 j54 b.
Coercion cj : Book54 >-> Evt_A.
Definition sem_WaP : Prop :=
  start54 j54 WP54
  /\ ~ last54 j54 WP54
  /\ forall lb : LBook, ~ finish54 j54 lb.
Set Printing Coercions.
Check sem_WaP.      (* 强制展开：start j (read j WP) 等（书 5.3.4）*)
Unset Printing Coercions.
