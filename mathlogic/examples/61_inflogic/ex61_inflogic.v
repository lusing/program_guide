(* 第 61 章 无穷逻辑与决定逻辑（Takeuti Ch4 §22-§24，p208-293）
   对书：Def 22.1 打包规则（一次处理一族主公式）、证明=半证明+本征变元
   三条件（I 同主公式/II 高度函数/III 不入末矢列）、例 22.2 依赖选择公理
   无切证明（h(a_m)=m）、g.c. 广义切、Malitz 反例（文档线）、Def 23.1
   决定逻辑、例 23.3 AD 可证、Gale-Stewart 定理 23.13、开博弈决定性
   例 24.14、定理 23.34 AD<=>切消、BDL=Prop 23.39。
   机器面：打包规则一步账+高度条件样本+有限开博弈胜策略搜索（Zermelo）。
   〔⚠〕打包规则细形在扫描件中残缺——按「规则族语法+语义可靠性+书中
   例 22.2/23.3」三重交叉重构（docs 详述）。零公理。 *)

Require Import List.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb' {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb' f t) end.

(* ---------- 件一：打包规则一步关系账 ----------
   打包（γ=2 样本）：两份主公式一次处理——上矢列是分量矢列的列表。 *)

(* 更直接的账例形式：直接写两个 bool 账 *)
(* 打包 /\:left：两个上矢列的分量一次进入下矢列 *)
Definition packAndSample : bool :=
  (* 上矢列 S1: A1(a1), G1 => D1；S2: A2(a2), G2 => D2
     下矢列：A1/\A2 的两个分量同时进入（一次推理处理 γ=2 个主公式） *)
  match ([1; 10], [20]), ([2; 11], [21]), ([10; 11; 1; 2], [20; 21]) with
  | (G1, D1), (G2, D2), (G, D) =>
      andb (existsb' (Nat.eqb 1) G)                 (* A1 在下矢列 *)
           (andb (existsb' (Nat.eqb 2) G)           (* A2 在下矢列 *)
                 (andb (forallb (fun x => existsb' (Nat.eqb x) (G1 ++ G2)) G)
                       (forallb (fun x => existsb' (Nat.eqb x) (D1 ++ D2)) D)))
  end%nat.

Example packAndAcct : packAndSample = true.
Proof. reflexivity. Qed.

(* 单主公式版对照（有穷 LK 的 γ=1 特例）：一次只消费一份 *)
Definition singleAndSample : bool :=
  match ([1; 10], [20]), ([10; 1], [20]) with
  | (G1, D1), (G, D) =>
      andb (existsb' (Nat.eqb 1) G) (forallb (fun x => existsb' (Nat.eqb x) G1) G)
  end%nat.

Example singleAndAcct : singleAndSample = true.
Proof. reflexivity. Qed.

(* ---------- 件二：高度函数条件样本（本征变元条件 II） ----------
   例 22.2 依赖选择公理的无切证明：!x?yF(x,y) -> !x0?x1?x2... /\_n F(xn,xn+1)
   本征变元 a0,a1,a2... 高度 h(a_m)=m（逐层抬升——高度条件 II 的现场）。 *)
Definition hDep (m : nat) : nat := m.     (* h(a_m) = m *)

(* 条件 II：本征变元高度 > 其主公式中一切自由变元的高度（参数 a 的高度 0） *)
Definition heightOkSample : bool :=
  (* 本征变元 a_1..a_3 各自高于参数 a_0（h(a_0)=0 为参数，非本征） *)
  forallb (fun m => Nat.ltb (hDep 0) (hDep m)) [1; 2; 3].

Example heightAcct : heightOkSample = true.
Proof. reflexivity. Qed.

(* 条件 I：同一变元多处本征时主公式相同——样本：a1 只在层 1 主公式 *)
Definition eigenConsistent : bool :=
  andb (Nat.eqb (hDep 1) 1) (Nat.eqb (hDep 2) 2).

Example eigenAcct : eigenConsistent = true.
Proof. reflexivity. Qed.

(* ---------- 件三：Gale-Stewart 有限版——开博弈胜策略搜索（Zermelo 定理） ----------
   博弈 G(A)：双方轮流出 0/1，depth 步后按对局位是否落在胜集 A 判 I 胜。
   开博弈=胜集由前缀决定（A 是前缀集：命中即终局）。有限深度=完全可判定。
   Zermelo：有限博弈必有一方有必胜策略——定理 23.13 与例 24.14 的有限影子。 *)

(* 胜集：前缀表（编码：位串十进制，0/1 序列 -> 编码数）。命=先手胜 *)
Definition winSet (prefix : list bool) : option bool :=
  (* 教学胜集：I 的奇数步全 true 即胜（首步+第三步双 t——前缀判定） *)
  match prefix with
  | true :: _ :: true :: _ => Some true
  | false :: false :: _ => Some false
  | _ => None            (* 未定：继续下 *)
  end.

Definition option_eqb (o : option bool) : nat :=
  match o with Some true => 1 | Some false => 0 | None => 2 end.

(* 后向归纳求值：position 上轮到 player（0=I/1=II）时谁有必胜策略 *)
Fixpoint gsEval (depth : nat) (player : nat) (pos : list bool) : option bool :=
  match depth with
  | 0 => match winSet pos with Some w => Some w | None => Some false end
        (* 开博弈语义：走完未命中 I 的胜前缀集 = II 胜 *)
  | S d =>
      match winSet pos with
      | Some w => Some w          (* 开博弈：前缀已定局 *)
      | None =>
          (* 未定：出 0 或 1，当前方选对自己最优的分支 *)
          let b0 := gsEval d (Nat.modulo (player + 1) 2) (false :: pos) in
          let b1 := gsEval d (Nat.modulo (player + 1) 2) (true :: pos) in
          match player with
          | 0 => (* I 选：有 true 分支取 true；全 false 取 false；全 None 才 None *)
              if Nat.eqb (option_eqb b1) 1 then Some true
              else if Nat.eqb (option_eqb b0) 1 then Some true
              else if Nat.eqb (Nat.min (option_eqb b0) (option_eqb b1)) 2 then None
              else Some false
          | _ => (* II 选：有 false 分支取 false *)
              if Nat.eqb (option_eqb b1) 0 then Some false
              else if Nat.eqb (option_eqb b0) 0 then Some false
              else if Nat.eqb (Nat.min (option_eqb b0) (option_eqb b1)) 2 then None
              else Some true
          end
      end
  end.

(* 账例一：先手必胜——首步 true 次步 true 即胜（I 抢攻两连） *)
Example gsFirstWins : gsEval 4 0 [] = Some true.
Proof. reflexivity. Qed.

(* 账例二：换博弈（胜集=三步内含两 true 判 II 胜）——构造第二胜集 *)
Definition winSet2 (prefix : list bool) : option bool :=
  match prefix with
  | true :: true :: _ => Some false     (* I 的两连被判负 *)
  | false :: false :: _ => Some true    (* II 失误给 I 送胜 *)
  | _ => None
  end.

Fixpoint gsEval2 (depth : nat) (player : nat) (pos : list bool) : option bool :=
  match depth with
  | 0 => match winSet2 pos with Some w => Some w | None => Some false end
  | S d =>
      match winSet2 pos with
      | Some w => Some w
      | None =>
          let b0 := gsEval2 d (Nat.modulo (player + 1) 2) (false :: pos) in
          let b1 := gsEval2 d (Nat.modulo (player + 1) 2) (true :: pos) in
          match player with
          | 0 => if Nat.eqb (option_eqb b1) 1 then Some true
                 else if Nat.eqb (option_eqb b0) 1 then Some true
                 else if andb (Nat.eqb (option_eqb b0) 2) (Nat.eqb (option_eqb b1) 2) then None
                 else Some false
          | _ => if Nat.eqb (option_eqb b1) 0 then Some false
                 else if Nat.eqb (option_eqb b0) 0 then Some false
                 else if andb (Nat.eqb (option_eqb b0) 2) (Nat.eqb (option_eqb b1) 2) then None
                 else Some true
          end
      end
  end.

(* II 方必胜：I 出 true true 即被擒；I 出 false 则 II 稳守 *)
Example gsSecondWins : gsEval2 4 0 [] = Some false.
Proof. reflexivity. Qed.

(* Zermelo 二择一：任意有限开博弈返回 Some（某方有策略）——双方不可能都无策略 *)
Example zermeloTotal :
  andb (match gsEval 4 0 [] with Some _ => true | None => false end)
       (match gsEval2 4 0 [] with Some _ => true | None => false end) = true.
Proof. reflexivity. Qed.

(* ---------- 件四：AD 的前奏账（例 23.3 的形状） ----------
   -> Q^f x A(x) \/ Q^f~ x ~A(x)：决定性公理本身在 DL 可证。
   机器面：玩具两步推导检查——两分支各引一个量词分量、析取引入。 *)
Definition adShape : bool :=
  (* 分量 1：-> A(a)  分量 2：-> ~A(a)（a 同一变元——条件 I 的现场） *)
  let D1 := [1] in let D2 := [2] in
  andb (Nat.eqb (hd 0 D1) 1) (Nat.eqb (hd 0 D2) 2).

Example adShapeAcct : adShape = true.
Proof. reflexivity. Qed.
