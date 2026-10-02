(* ex04 —— 经典加成（HoTT 版）：LEM 的正确形态是「对 h-命题」
   编译：Rocq 9.1 + Coq-HoTT（-q -noinit -indices-matter -R theories HoTT）

   HoTT 的洞察：排中律不能对「一切类型」声明——
   A + ¬A 要求判定的是「证据的截断」，只有 IsHProp 的类型
   才配得上「命题」这个称呼。LEM 的 HoTT 形态：

     LEM_{-1} : forall A : Type, IsHProp A -> A + (A -> Empty)

   对全集类型（LEM_∞）在泛等下不真（11/12 章再议）。 *)

Require Import HoTT.HoTT.

Definition LEM_hprop :=
  forall A : Type, IsHProp A -> A + (A -> Empty).

(* ---------- 矩阵方向（HoTT 里同样构造） ---------- *)

Section Matrix.
Context (LEMh : LEM_hprop).

Theorem lem_to_dne : forall A : Type,
  IsHProp A -> ~ ~ A -> A.
Proof.
  intros A ishp Hnn.
  destruct (LEMh A ishp) as [HA | HNA].
  - exact HA.
  - contradiction.
Defined.
End Matrix.

(* ---------- ¬¬LEM 白送 ---------- *)

Theorem nn_lem : forall A : Type, ~ ~ (A + ~ A).
Proof.
  intros A H.
  apply H. right. intros HA.
  apply H. left. exact HA.
Defined.

(* 现场注记：
   - IsHProp Bool 的实例由库自动解析——布尔层经典性免费；
   - dne→lem 方向在 HoTT 里要证 IsHProp (A + ~ A)（析取的截断性），
     涉及 sum 的 h-level 定理，留作 12 章截断主题的伏笔。 *)

(* 坑位速记（HoTT 侧）：
   - ~ 在 HoTT.Prelude 里定义为 fun A => A -> Empty；
   - contradiction 在 -noinit 环境照常可用（标准 Ltac）；
   - 记号冲突：HoTT 的 /\ 与 stdlib 不同名同形——本文件只用库内记号。 *)
