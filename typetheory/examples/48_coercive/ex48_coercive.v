(* ============================================================
   48 强制性子类型 —— Coq（罗朝晖书 2.5.1–2.5.2 + 6.3.2 概览）
   A ≤c B：缩写机制——需要 B 的地方可用 A 的对象，实际用的是
   其经强制转换 c 的映像 c(a)。Coq 的 Coercion 系统是强制
   子类型理论在证明助手中的落地（书脚注：Coq/Lego/Matita/
   Plastic 均实现之）。
   机器面：
   ① CA/CD 的语义：插入与可见（Set Printing Coercions）
   ② π1 投射子类型：Man = Σx:Human.male(x) ≤π1 Human（书 2.30/2.31）
   ③ 合谐性反例：双投影强制同时注册的歧义（π1/π2 不合谐，
      书 2.5.3 末脚注：Nat×Nat ≤π1 Nat 且 ≤π2 Nat）
   ④ 函数类型不自动逆变（结构性传播要手写——Coq 的边界）
   ⑤ Σ 的谓词传播 (Sp)：dprop 把 (a,p) 映到 (c(a),p)
   ============================================================ *)

Require Import List.
Import ListNotations.

(* ---- ① CA/CD：强制转换的省略与恢复 ---------------------- *)
Record Boxed := mkBox { unbox :> nat }.   (* :> 字段即注册强制 *)

Definition b3 : Boxed := mkBox 3.

(* (CA) 应用规则：unbox 被省略——b3 用在需要 nat 的地方 *)
Definition shifted : nat := b3 + 1.
Compute shifted.                     (* = 4：经 unbox 的映像 *)
Compute (S b3).                      (* = 4 *)
Compute (Nat.eqb b3 3).              (* = true *)

(* (CD) 定义规则：省略的强制转换可被恢复（打印出来） *)
Set Printing Coercions.
Check (b3 + 1).                      (* unbox b3 + 1 *)
Check (S b3).                        (* S (unbox b3) *)
Unset Printing Coercions.

(* CD 的等式面：speak(m) 定义性等于 speak(c(m)) —— 在计算性
   语境里由 Compute 直接见证（上面 S b3 = S (unbox b3) = 4）。 *)

(* ---- ② π1 投射子类型（书式 2.30/2.31）--------------------
   Man = Σx:Human.male(x)，Man ≤π1 Human——包含式子类型表达
   不了的**投射性**子类型关系，强制转换就是第一投影。 *)
Inductive Human := John | Mary.
Definition male (h : Human) : Prop := h = John.
Record Man := mkMan { man_of :> Human ; male_prf : male man_of }.
Definition john_man : Man.
Proof. refine (mkMan John _). reflexivity. Defined.

(* 强制 man_of : Man >-> Human 已由 :> 字段注册 *)
Check (man_of john_man : Human).
Definition is_john (h : Human) : Prop := h = John.
Check (is_john john_man) : Prop.     (* CA：论域 Human 收 Man 的对象 *)

(* 「男人是人」的推理面：每个男人都是人 *)
Lemma man_is_human : forall m : Man, is_john m -> male m.
Proof. intros m H. exact H. Qed.     (* male m 经强制即 is_john (man_of m) *)

(* 黑猫是猫（书 3.4 的 (3.65)：Σ 类型子类型传播 (Sp) 的先行版） *)
Inductive Cat := Oliver | Felix.
Definition black (c : Cat) : Prop := c = Oliver.
Record BlackCat := mkBC { cat_of :> Cat ; black_prf : black cat_of }.
Definition is_black (c : Cat) : Prop := match c with Oliver => True | _ => False end.
Check (fun b : BlackCat => is_black b) : BlackCat -> Prop.

(* ---- ③ 合谐性反例：双投影强制 -----------------------------
   书 2.5.3 脚注：若 π1 与 π2 同时是 A×B 的强制转换，则
   Nat×Nat ≤π1 Nat 且 ≤π2 Nat——两条强制不等，不合谐。
   Coq 里的对应物：两个字段同为 nat 的记录都声明 :> ——
   **Coq 自己会报警**（下以 Set Warnings 屏蔽以过检，原文：
   Warning: New coercion path [pnn_snd] : PairNN >-> nat
   is ambiguous with existing [pnn_fst] : PairNN >-> nat.）
   ——系统检测到歧义但不阻止，使用点默默选 fst。 *)
Set Warnings "-ambiguous-paths".
Record PairNN := mkPairNN { pnn_fst :> nat ; pnn_snd :> nat }.
Definition pp := mkPairNN 5 9.
(* 两个投影都注册成了强制。使用点 Coq 选哪条？——实测： *)
Compute (S pp).                      (* 取 pnn_fst？看输出 *)
Set Printing Coercions.
Check (S pp).
Check (Nat.eqb pp 5).
Unset Printing Coercions.
(* 教学点：Coq 对同一对 (PairNN, nat) 允许多条强制并存，
   使用点按注册序/路径长度择一——**系统不替你保证合谐性**
   （合谐性定义 6.8 要求：任意两类型间至多一条强制转换，
   这是保守扩张定理 6.4 的前提）。若两投影都「正确」，
   S pp 的语义就依赖实现细节——这正是 Luo 要求合谐性的
   机器理由。 *)

(* ---- ④ 函数类型不自动逆变 --------------------------------
   书 2.5.2 传播规则 (2)：A'≤A、B≤B' ⟹ A→B ≤ A'→B'。
   Coq 的 Coercion **不做**结构传播：下面的 f : list Boxed -> nat
   不能直接用在需要 list nat -> nat 的地方。 *)
Definition count_boxes (l : list Boxed) : nat :=
  fold_left (fun acc b => acc + unbox b) l 0.
Compute count_boxes [b3; mkBox 4].        (* = 7 *)
(* 若要「list Boxed ≤ list nat」：手写映射（map 版强制） *)
Definition map_unbox (l : list Boxed) : list nat := map unbox l.
Definition count_nats (l : list nat) : nat := fold_left Nat.add l 0.
(* Coq 无法注册参数化强制 Coercion map_unbox : list Boxed >-> list nat
   ——那是具体的一对；要 List(A)≤List(B) 的一般传播需逐实例
   手写。机器边界：理论有（书传播规则 (1) map(c)），Coq 未实现。 *)
Compute (count_nats (map_unbox [b3; mkBox 4])).   (* = 7：手工插 map *)

(* ---- ⑤ Σ 的谓词传播 (Sp)：dprop ---------------------------
   书规则 (Sp)：Σx:A.P(x) ≤dprop(c) Σy:B.P(y) 的强制把
   (a,p) 映到 (c(a),p)——第二分量（证明）原样搬运。
   机器件：Man ≤π1 Human 时，带证明的对 (m, p) 投到 (c m, p)。 *)
Record BlackCatOf (c : Cat) := mkBCO { bco_prf : black c }.
Definition dprop (b : BlackCat) : BlackCatOf (cat_of b) :=
  match b with mkBC c p => mkBCO c p end.
Check dprop : forall b : BlackCat, BlackCatOf (cat_of b).
(* 注意值域依赖输入——这正是 2.5.3 说的**依赖性强制转换**
   （dependent coercion：π2/Snd 一族）。 *)

(* ---- 收束：强制子类型 = 保守的缩写机制 --------------------
   元理论（书 6.3.2 定理 6.4）：若强制转换集合 C 合谐，则
   T[C] 是 T 的保守扩张——规范性、逻辑相容性全部保持。
   机器面对应：Compute 的结果里强制已消失——「展开后无痕」。 *)
Compute (b3 + b3).                   (* = 6：两个强制都展开成 nat *)
