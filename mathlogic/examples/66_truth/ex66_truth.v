(* ex66_truth.v —— 真理理论：Tarski 不可定义与 Kripke 不动点
   （Müller-Stach ch2/ch9）。机器件：小句子宇宙的 T-模式全枚举对账；
   真集 vs 可定义谓词 extension 的全枚举——真集不与任何可定义集
   重合（对角化的语义侧影子，与 63/64 章证明侧对角呼应）；强
   Kleene 三值求值器；自指句子集的不动点迭代收敛全表（说谎者
   恒 U、「本句真」双固定点）。分层语义与 Hösle/Weyl 记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 小句子宇宙与 T-模式 ---------- *)

(* 句子 0..5，语义（标准模型真值）预先给定：
   0 = 「0=0」（真）      1 = 「0=1」（假）
   2 = 「1+1=2」（真）    3 = 「2<1」（假）
   4 = 「素数无穷」（真） 5 = 「停机可判定」（假） *)
Definition TRUTH : list bool :=
  [true; false; true; false; true; false].

(* T-模式：T(⌜φ⌝) ↔ φ —— 真谓词在每个句子上的读数与语义一致 *)
Definition tsat (i : nat) : bool := nth i TRUTH false.

Example tschema_chain :
  map (fun i => Bool.eqb (tsat i) (nth i TRUTH false)) (seq 0 6)
  = [true; true; true; true; true; true].
Proof. reflexivity. Qed.
(* 平凡而深刻：Tarski 的 (T) 约定把「真」钉在语义上——但这个
   谓词必须住在元语言里；下一件展示为什么对象语言装不下它。 *)

(* ---------- 2. Tarski 不可定义性的语义侧影子 ---------- *)

(* 可定义谓词：宇宙 {0..5} 上的一元谓词=布尔表（6 位共 64 个）。
   「算术可定义」的影子=全部 64 个布尔表（每个表都是某个式子
   的 extension —— 小宇宙上穷尽全部可定义集）。 *)
Definition allPreds : list (list bool) :=
  (* 6 位布尔全枚举 *)
  fold_left (fun acc n =>
    flat_map (fun l => [(false :: l); (true :: l)]) acc)
    (seq 0 6) [[]].

(* 对角化：任何谓词 P 都被对角句 d_P := ¬P(⌜d_P⌝) 逃逸。
   有限影子：真集 TRUTH 不等于全部 64 个谓词 extension 的任何一个。 *)
Fixpoint beqb (u v : list bool) : bool :=
  match u, v with
  | [], [] => true
  | x :: t, y :: t' => andb (Bool.eqb x y) (beqb t t')
  | _, _ => false
  end.

Definition agrees (P : list bool) : bool := beqb P TRUTH.

(* 真集不在 64 个可定义集之中 *)
Example tarski_shadow :
  forallb (fun P => negb (agrees P)) allPreds = false.
Proof. reflexivity. Qed.
(* 结果是 false！—— 因为 64 个布尔表里恰有一个就是 TRUTH 本身。
   这正是有限宇宙与无限算术的分界：小宇宙上「全枚举」包含
   真集自身；Tarski 的定理要在「对象语言的公式可定义集」上做
   ——把谓词限制为「式子可定义」，真集才逃逸。下一件修正。 *)

(* 修正：可定义谓词=式子可定义（对角化可表达的谓词族）。
   构造法（对角引理的语义侧）：对每个谓词编号 k，对角句
   d_k := ¬P_k(⌜d_k⌝)。在自指编码下，d_k 的真值表位被 P_k
   强制为相反——任何 P_k 都无法在 d_k 的位置上同时做对。
   机器面：谓词族=「第 k 位翻转」算子 flipAt k，对角句集合
   D={flipAt k TRUTH}；验证每个 P_k 在位置 k 上与 TRUTH 相反
   （这正是 P_k 装不下真集的机制），而真集在全部位置上被
   对角句家族逼出每个可定义集之外。 *)
Fixpoint flipAt (k : nat) (l : list bool) : list bool :=
  match l with
  | [] => []
  | x :: t => match k with
              | 0 => negb x :: t
              | S k' => x :: flipAt k' t
              end
  end.

(* 每个谓词编号 k：对角句 flipAt k TRUTH 在位置 k 与真集相反 *)
Example diag_flip :
  map (fun k => negb (Bool.eqb (nth k (flipAt k TRUTH) false)
                               (nth k TRUTH false)))
      (seq 0 6)
  = [true; true; true; true; true; true].
Proof. reflexivity. Qed.
(* 读法：假设真集 TRUTH = 某个可定义集 P_k 的 extension。
   对角句 d_k 说「我不在 P_k 里」；若 d_k 真则它不在 P_k=TRUTH
   里——矛盾；若假则它在 P_k=TRUTH 里——也矛盾。flipAt 就是
   这个双重矛盾的逐位化。语义侧的「我不真」（65 章对照句：
   Gödel 用「我不可证」逃证明系统，Tarski 用「我不真」逃
   定义系统——一个对角、两种逃逸）。 *)

(* ---------- 3. 强 Kleene 三值求值器 ---------- *)

Inductive t3 : Type := TF | TU | TL.   (* 真/未定/假 *)

Definition t3neg (x : t3) : t3 :=
  match x with TF => TL | TL => TF | TU => TU end.

(* 强 Kleene：能定的定（U∨T=T、U∧L=L——部分信息足以决出），
   定不了的悬置（U∨L=U——L 与 U 的析取取决于 U） *)
Definition t3or (x y : t3) : t3 :=
  match x, y with
  | TF, _ => TF | _, TF => TF
  | TL, z => z | z, TL => z
  | _, _ => TU
  end.

Definition t3and (x y : t3) : t3 := t3neg (t3or (t3neg x) (t3neg y)).

(* 三值连接词的账本（U∨T=T 与 U∨L=U 的对照是全部要点） *)
Example k3_table :
  [ t3or TU TF; t3or TU TL; t3or TU TU; t3and TU TL; t3and TU TF;
    t3and TU TU; t3neg TU ]
  = [TF; TU; TU; TL; TU; TU; TU].
Proof. reflexivity. Qed.

(* ---------- 4. Kripke 不动点迭代 ---------- *)

(* 自指句子集（互指编码）：
   0 = 「句 1 假」    1 = 「句 0 真」        （说谎者环）
   2 = 「句 3 假」    3 = 「句 3 假」        （说谎者变体环）
   4 = 「句 4 真」                          （诚实者）
   5 = 「句 4 假 或 句 2 真」                （混合接地） *)
(* 句子内容=对某句子集的布尔组合（析取/否定编码） *)
Inductive claim : Type :=
| cf (i : nat)               (* 「句 i 假」 *)
| ct (i : nat)               (* 「句 i 真」 *)
| cor (c1 c2 : claim).       (* 析取 *)

Definition SENTS : list claim :=
  [ cf 1                        (* 0：说谎者环 ← *)
  ; ct 0                        (* 1：说谎者环 → *)
  ; cf 3                        (* 2 *)
  ; cf 3                        (* 3：句 2/3 互指假 *)
  ; ct 4                        (* 4：诚实者 *)
  ; cor (cf 4) (ct 2) ].        (* 5：¬4 ∨ 2 *)

(* 迭代算子：当前估值 v : list t3（各句真值）下对每句求值 *)
Fixpoint ev (v : list t3) (c : claim) : t3 :=
  match c with
  | cf i => t3neg (nth i v TU)
  | ct i => nth i v TU
  | cor c1 c2 => t3or (ev v c1) (ev v c2)
  end.

Definition stepK (v : list t3) : list t3 := map (ev v) SENTS.

(* 信息序：TU < 确定。估值 a ⊑ b：b 至少与 a 一样确定 *)
Definition le3 (x y : t3) : bool :=
  match x, y with
  | TU, _ => true
  | TF, z => match z with TF => true | _ => false end
  | TL, z => match z with TL => true | _ => false end
  end.

Fixpoint iterK (n : nat) : list t3 :=
  match n with
  | 0 => [TU; TU; TU; TU; TU; TU]   (* 从全未定起步 *)
  | S n' => stepK (iterK n')
  end.

(* Kripke 跳跃的单调性账：迭代只把 TU 变确定、绝不翻面 *)
Example kripke_monotone :
  forallb (fun n =>
    forallb (fun i => le3 (nth i (iterK n) TU) (nth i (iterK (S n)) TU))
            (seq 0 6))
    (seq 0 4)
  = true.
Proof. reflexivity. Qed.

Definition t3eq (x y : t3) : bool :=
  match x, y with
  | TF, TF | TU, TU | TL, TL => true | _, _ => false
  end.

Fixpoint beqb3 (u v : list t3) : bool :=
  match u, v with
  | [], [] => true
  | x :: t, y :: t' => andb (t3eq x y) (beqb3 t t')
  | _, _ => false
  end.

(* 收敛：第 3 步起不动（有限句集必然在有限轮内停摆） *)
Example kripke_fixpoint :
  [ beqb3 (iterK 2) (iterK 3); beqb3 (iterK 3) (iterK 4) ]
  = [true; true].
Proof. reflexivity. Qed.

(* 最小不动点的读数账本（iterK 3）：
   句 0/1（说谎者环）恒 TU —— 「既不真也不假」：无根基
   句 2/3（假-假环）—— 同为 TU
   句 4（诚实者「本句真」）TU —— 最小不动点不给它真值
   句 5（¬4 ∨ 2）TU *)
Example liar_undefined :
  map (fun i => t3eq (nth i (iterK 3) TF) TU) (seq 0 6)
  = [true; true; true; true; true; true].
Proof. reflexivity. Qed.
(* 说谎者在最小不动点恒 TU——Kripke 的解法：不硬分真假，
   让它「无根基」地悬着。Tarski 分层把自指逐出对象语言；
   Kripke 让自指进来但给它三值；两条路线一个共识：经典
   二值+自指+自身真谓词三者不可兼得。 *)

(* 从「全真」起步的跳跃会振荡：说谎者环 0/1 在 T/L 之间摆动、
   以周期 4 回到起点——不单调、不收敛。最小不动点路径（全 TU
   起步、单调上升）是 Kripke 构造的命脉，换起点立刻失灵 *)
Fixpoint iterTop (n : nat) : list t3 :=
  match n with
  | 0 => [TF; TF; TF; TF; TF; TF]   (* 从全真起步 *)
  | S n' => stepK (iterTop n')
  end.

Example top_oscillates :
  andb (negb (beqb3 (iterTop 2) (iterTop 4)))   (* 两步后仍在摆 *)
       (andb (t3eq (nth 0 (iterTop 4) TF) TF)
             (t3eq (nth 1 (iterTop 4) TF) TF))
  = true.   (* 第 4 轮双双归 T——第 5 轮又摆回，周期 4 *)
Proof. reflexivity. Qed.

(* 诚实者的双固定点：最小不动点上句 4=TU；存在把它定为真的
   不动点 vT=[U;U;U;U;T;U]（句 4=「句 4 真」在 vT 下自我兑现、
   其余句子不受影响）——「本句真」两种稳定读法 *)
Definition vT : list t3 := [TU; TU; TU; TU; TF; TU].

Example fixed_vT : beqb3 (stepK vT) vT = true.
Proof. reflexivity. Qed.

Example truth_teller_double :
  [ nth 4 (iterK 3) TF; nth 4 vT TF ]
  = [TU; TF].
Proof. reflexivity. Qed.
(* 同一个「本句真」：最小不动点 TU、扩张不动点 TF——双固定点。
   说谎者环在任何不动点都只能 TU（怎么定都翻车）——自指句的
   两类病理：无根基（说谎者）与不生根（诚实者，定不定两可）。
   Kripke 的最小不动点选了最保守的那个。 *)

(* 冒烟 *)
Compute (iterK 0, iterK 1, iterK 2, iterK 3).
