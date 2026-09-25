(** 示例 19：余极限 —— Pushout 与 Coeq
    用"把东西粘起来"的方式造类型，圆就是这么来的。

    对应文档：docs/19-colimits.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_19_BEGIN := tt.   Check sec_19_BEGIN.

(** * 19.1 推出（Pushout）

    给定 [f : A -> B]、[g : A -> C]，[Pushout f g] 是把 [B] 与 [C]
    沿着 [A] 的像粘起来的类型。 *)

Definition sec_19_1_pushout := tt.   Check sec_19_1_pushout.

Check Pushout.
Check pushl.
Check pushr.
Check pglue.
Check Pushout_ind.
Check Pushout_rec.

(** 泛性质：给一个 [Pushout f g -> X]，等价于给一对
    [B -> X] 与 [C -> X]，且它们在 [A] 上一致。 *)
Check isequiv_Pushout_rec.

(** * 19.2 余等值子（Coeq）

    [Coeq f g] 是把 [f a] 与 [g a] 强行等同起来的类型。 *)

Definition sec_19_2_coeq := tt.   Check sec_19_2_coeq.

Check Coeq.
Check coeq.
Check cglue.
Check Coeq_ind.
Check Coeq_rec.
Check Coeq_rec_beta_cglue.
Check isequiv_Coeq_rec.

(** * 19.3 圆就是一个 Coeq

    库里把圆定义为两个 [idmap : Unit -> Unit] 的余等值子：
    把 [Unit] 的两个拷贝粘起来，粘出的那条路径就是 [loop]。 *)

Definition sec_19_3_circle := tt.   Check sec_19_3_circle.

Check Circle.
Check Circle.base.
Check Circle.loop.

(** 【验证】把 [Circle] 的定义展开，能看到它确实是 [Coeq]：*)
Definition my_circle := @Coeq Unit Unit idmap idmap.
Check my_circle.

(** * 19.4 悬置（Suspension）也是 Pushout *)

Definition sec_19_4_susp := tt.   Check sec_19_4_susp.

Check Susp.
Check (fun A : Type => Susp A).

(** [Susp A] 把 [A] 压到中间，两端各加一个极点，
    它就是把两个 [A] 的拷贝沿恒等映射粘起来（Pushout 的特例）。 *)

(** * 19.5 动手做一次：用 Coeq 造一个"两元素粘合"类型 *)

Definition sec_19_5_exercise := tt.   Check sec_19_5_exercise.

(** 取 [A := Bool]、[B := Unit]，令 [f b := tt]、[g b := tt]，
    则 [Coeq f g] 把 [Bool] 的两个点粘到同一个点上，结果应该还是 [Unit]。 *)

Definition bool_glued := @Coeq Bool Unit (fun _ => tt) (fun _ => tt).
Check bool_glued.

(** 从 [Unit] 进去是平凡的：*)
Definition unit_to_glued : Unit -> bool_glued := fun _ => coeq tt.
Check unit_to_glued.

(** 从 [bool_glued] 出来要用 [Coeq_rec]。
    【坑】[Coeq_rec] 的第一个显式参数是目标类型 [P]，
    第二个是"在 [A] 上的值"，第三个是"粘合路径"；
    它的参数顺序和 [Quotient_rec] 不同，别照抄。 *)
Definition glued_to_unit : bool_glued -> Unit
  := @Coeq_rec Bool Unit (fun _ : Bool => tt) (fun _ : Bool => tt)
       Unit (fun _ : Unit => tt) (fun _ : Bool => 1).
Check glued_to_unit.

(** 计算规则：[cglue] 上的行为就是我们在 [Coeq_rec] 里给的那条路径。 *)
Check Coeq_rec_beta_cglue.

(** * 19.6 余极限的通用模板 *)

Definition sec_19_6_template := tt.   Check sec_19_6_template.

(** 所有 HIT 的消去子都长一个样：
      点构造子 → 给值；
      路径构造子 → 给一条依赖路径（先 [transport] 再相等）。
    区间（第 12 章）、圆（第 13 章）、商（第 16 章）、
    Pushout / Coeq 全都如此。差别只在"要粘多少条路径"。 *)

Check interval_ind.
Check Circle_ind.
Check Quotient_ind.
Check Pushout_ind.
Check Coeq_ind.

Definition sec_19_END := tt.   Check sec_19_END.
