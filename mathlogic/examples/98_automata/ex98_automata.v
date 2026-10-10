(* ex98_automata.v —— 自动机与形式语言：Chomsky 层级（张寅生 11.2-11.8）
   机器件：DFA 运行器（例 11.6「熊猫」词识别+例 11.7「1+1=2」命题接受）；
   NFA 状态集运行+子集构造（定理 11.1 的构造化证明：nfa_accept w ⟺
   dfa_accept (subset) w 全词枚举对账；例 11.9 go*gle）；PDA 栈机
   （例 11.5 aⁿbⁿ接受+aⁿbᵐ拒绝对账）；LBA 等额检查影子（例 11.4②
   ⟨aᵐbcᵐ⟩）；Chomsky 四型文法约束表+3 型文法↔DFA 互译（定理 11.2(4)）。
   图灵机（0 型）见 70 章；泵引理与 Myhill-Nerode 记文档线。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

(* ---------- 1. DFA：定义与运行器（定义 11.4） ---------- *)

(* DFA=五元组 ⟨Q,Σ,δ,q0,F⟩ 的机器面：状态=nat、转移表=list（δ 全函数
   用查找+默认自环实现）、接受态集=list nat *)
Definition dfa := list (nat * nat * nat).   (* (状态,输入符号,次态) *)

Fixpoint dfaStep (d : dfa) (q s : nat) : nat :=
  match d with
  | [] => 99                                 (* 缺省：sink 态（99 拒收） *)
  | (q', s', q2) :: t => if andb (Nat.eqb q q') (Nat.eqb s s') then q2
                         else dfaStep t q s
  end.

Fixpoint dfaRun (d : dfa) (q : nat) (w : list nat) : nat :=
  match w with
  | [] => q
  | s :: rest => dfaRun d (dfaStep d q s) rest
  end.

Definition dfaAccept (d : dfa) (q0 : nat) (fin : list nat) (w : list nat) :
  bool := existsb (Nat.eqb (dfaRun d q0 w)) fin.

(* 例 11.6「熊猫」识别器（汉字串教学件：0=xióng 1=māo，¬A=其余一律拒绝）
   Q={0,1,2=Acc,3=Rej}：q0 --0--> q1 --1--> Acc；任何越轨入 Rej 自环 *)
Definition pandaDfa : dfa :=
  [ (0,0,1); (0,1,3); (1,0,3); (1,1,2); (2,0,3); (2,1,3); (3,0,3); (3,1,3) ].

Example panda_accept : dfaAccept pandaDfa 0 [2] [0;1] = true.
Proof. reflexivity. Qed.

(* ¬A 补类转移：任何非 01 序列拒绝（例：01 后再来一个符号） *)
Example panda_reject_extra : dfaAccept pandaDfa 0 [2] [0;1;0] = false.
Proof. reflexivity. Qed.

Example panda_reject_wrong : dfaAccept pandaDfa 0 [2] [1;0] = false.
Proof. reflexivity. Qed.

(* 例 11.7「1+1=2」命题识别器：符号 0..4 = '1','+','1','=','2'
   （命题=固定符号串——「图灵机完全可以接受一个命题并给出接受或
   拒绝的映射」，书 p150）*)
Definition propDfa : dfa :=
  [ (0,0,1); (1,1,2); (2,0,3); (3,2,4); (4,4,5); (5,3,6); (6,3,7); (6,4,8) ].

Example prop_accept : dfaAccept propDfa 0 [5] [0;1;0;2;4] = true.
Proof. reflexivity. Qed.

(* ---------- 2. NFA 与子集构造（定理 11.1） ---------- *)

(* NFA：δ:Q×Σ→P(Q)——转移表允许同一 (q,s) 多目标 *)
Definition nfa := list (nat * nat * nat).

(* 状态集去重（教学件简化：不去重，接受判定用 existsb 不受重复影响） *)
Definition dedupNat (l : list nat) : list nat := l.

(* 重写 nfaStep：对每个 q 收集全部目标再拼接 *)
Fixpoint nfaTargets (n : nfa) (q s : nat) : list nat :=
  match n with
  | [] => []
  | (q1, s1, q2) :: t =>
      if andb (Nat.eqb q q1) (Nat.eqb s s1) then q2 :: nfaTargets t q s
      else nfaTargets t q s
  end.

Fixpoint nfaStep2 (n : nfa) (qs : list nat) (s : nat) : list nat :=
  match qs with
  | [] => []
  | q :: t => nfaTargets n q s ++ nfaStep2 n t s
  end.

Fixpoint nfaRun (n : nfa) (qs : list nat) (w : list nat) : list nat :=
  match w with
  | [] => qs
  | s :: rest => nfaRun n (dedupNat (nfaStep2 n qs s)) rest
  end.

Definition nfaAccept (n : nfa) (q0 : nat) (fin : list nat) (w : list nat) :
  bool := existsb (fun q => existsb (Nat.eqb q) fin) (nfaRun n [q0] w).

(* 例 11.9 go*gle 识别器：符号 0=g 1=o 2=l 3=e
   q0 --g--> q1(循环读 o) --g--> q2 --l--> q3 --e--> Acc *)
Definition gogDfa : dfa :=
  [ (0,0,1); (1,1,1); (1,0,2); (2,2,3); (3,3,4); (4,0,5); (5,5,5)
  ; (0,1,5); (0,2,5); (0,3,5); (2,0,5); (2,1,5); (2,3,5); (3,0,5)
  ; (3,1,5); (3,2,5); (5,1,5); (5,2,5); (5,3,5) ].

Example gog_accept_variants :
  [ dfaAccept gogDfa 0 [4] [0;0;2;3]          (* ggle *)
  ; dfaAccept gogDfa 0 [4] [0;1;0;2;3]        (* gogle *)
  ; dfaAccept gogDfa 0 [4] [0;1;1;1;0;2;3]    (* gooogle *)
  ; dfaAccept gogDfa 0 [4] [0;1;2;3]          (* 缺第二个 g：q1 读 l 走死 *)
  ; dfaAccept gogDfa 0 [4] [0;1;1;2;3]        (* 同上：自环 q1≠终态 *)
  ] = [true; true; true; false; false].
Proof. reflexivity. Qed.
(* 语言= g o* g l e（两个 g、o 可零个——书例 11.9 识别 gogle/google/
   gooogle/gⁿgle 家族）。缺第二个 g 的词在 l 处走死（缺省自环≠接受）。 *)

(* 子集构造（定理 11.1 的构造化）：NFA 状态集→DFA 状态（bitmask）
   对 4 状态 NFA：状态集⊆{0,1,2,3} 编码为 4 位掩码 *)
Definition maskOf (qs : list nat) : nat :=
  fold_left (fun acc q => acc + Nat.pow 2 q) (dedupNat qs) 0.

Definition setOf (m : nat) : list nat :=
  filter (fun q => Nat.ltb 0 (Nat.land m (Nat.pow 2 q))) [0;1;2;3].

(* NFA 的 DFA 化转移表：对全部 16 个状态集×2 符号生成 *)
Definition subsetRow (n : nfa) (m : nat) (s : nat) : nat :=
  maskOf (dedupNat (nfaStep2 n (setOf m) s)).

Definition subsetDfa (n : nfa) : dfa :=
  flat_map (fun m =>
    map (fun s => (m, s, subsetRow n m s)) [0;1]) (seq 0 16).

(* 等价性对账（定理 11.1 构造化证明的核心句）：对全部词长 ≤4 的
   枚举——nfaAccept ⟺ dfaAccept(subsetDfa) *)
Fixpoint wordsUpto (alph len : nat) : list (list nat) :=
  match len with
  | 0 => [[]]
  | S k => flat_map (fun w => map (fun s => s :: w) (seq 0 alph))
                     (wordsUpto alph k)
  end.

(* 测试 NFA：例 11.9 的原始非确定版（g 分叉：q0-g->q1 或循环） *)
Definition gogNfa : nfa :=
  [ (0,0,1); (1,1,1); (1,0,2); (2,2,3); (3,3,4) ].
(* 终态 4 的接受与 DFA 化对照——状态 4 超出 4 位掩码（0..3）？
   掩码覆盖 0..4 共 5 位需 32 集——这里用 4 状态小 NFA 对照：
   状态 {0..3}、终态 3：识别 (0|1)0*2 3 的迷你版 *)
Definition miniNfa : nfa :=
  [ (0,0,1); (0,1,2); (1,0,1); (1,1,3); (2,0,3) ].

Definition miniDfa := subsetDfa miniNfa.

Example subset_ok :
  forallb (fun w =>
    Bool.eqb (nfaAccept miniNfa 0 [3] w)
             (dfaAccept miniDfa (maskOf [0]) [8] w))
    (wordsUpto 2 4) = true.
Proof. reflexivity. Qed.
(* dfaAccept 的终态 [8]=掩码含状态 3。构造化定理 11.1：非确定性
   可被确定性模拟——「随机选择」编译成「全部并行」——书的文字
   论证（p152）在机器上变成 16 状态集×2 符号的转移表生成器。 *)

(* ---------- 3. PDA：栈语义（定义 11.3+例 11.5） ---------- *)

(* aⁿbⁿ 识别：读 a 压栈、读 b 弹栈、终态=栈空。
   直接函数式编码栈行为（转移表版见 docs 讨论） *)
Fixpoint anbn (w : list nat) (depth : nat) : bool :=
  match w with
  | [] => Nat.eqb depth 0
  | 0 :: rest => anbn rest (S depth)        (* a：压栈 *)
  | 1 :: rest => match depth with           (* b：弹栈 *)
                 | 0 => false                (* 栈空遇 b：拒绝 *)
                 | S d => anbn rest d
                 end
  | _ => false                              (* 其他符号：拒绝 *)
  end.

(* 例 11.5 对账：aⁿbⁿ 接受、aⁿbᵐ(m≠n) 拒绝 *)
Example pda_anbn_accept :
  [ anbn [0;0;0;1;1;1] 0; anbn [] 0; anbn [0;1] 0 ] = [true; true; true].
Proof. reflexivity. Qed.

Example pda_anbn_reject :
  [ anbn [0;0;1] 0; anbn [1;0] 0; anbn [0;1;1] 0; anbn [0;0;0] 0 ]
  = [false; false; false; false].
Proof. reflexivity. Qed.

(* 栈轨迹表（书表 11.9 的机器面）：a a b b 的栈深序列 *)
Fixpoint depthTrace (w : list nat) (d : nat) : list nat :=
  match w with
  | [] => [d]
  | 0 :: rest => d :: depthTrace rest (S d)
  | 1 :: rest => d :: depthTrace rest (match d with 0 => 0 | S k => k end)
  | _ => [d]
  end.

Example pda_trace : depthTrace [0;0;1;1] 0 = [0;1;2;1;0].
Proof. reflexivity. Qed.

(* ---------- 4. LBA 影子：等额检查（定义 11.2+例 11.4②） ---------- *)

(* LBA=带边界 ⟨,⟩ 的受限图灵机。例 11.4②：识别 ⟨aᵐbcᵐ⟩。
   函数式影子：*)
Definition lbaShadow2 (w : list nat) : bool :=
  match w with
  | 1 :: rest =>
      andb (forallb (fun s => orb (Nat.eqb s 0) (Nat.eqb s 2)) rest)
           (Nat.eqb (length (filter (Nat.eqb 0) rest))
                    (length (filter (Nat.eqb 2) rest)))
  | _ => false
  end.

Example lba_accept :
  [ lbaShadow2 [1;0;0;2;2]; lbaShadow2 [1;0;2]; lbaShadow2 [1] ] = [true;true;true].
Proof. reflexivity. Qed.

Example lba_reject :
  [ lbaShadow2 [1;0;0;2]; lbaShadow2 [1;0;0;1;2]; lbaShadow2 [0;2] ]
  = [false; false; false].
Proof. reflexivity. Qed.
(* LBA 的真实带语义（边界符限制读写头）记文档线：函数式影子保存
   「线性空间=只看输入内部」的计算本质。1 型文法（上下文有关）的
   识别器=非确定 LBA（定理 11.2(2)）。 *)

(* ---------- 5. Chomsky 层级与文法-机器互译（表 11.12+定理 11.2） ---------- *)

(* 四型文法：产生式 (左部变元, 右部首符号, 右部次变元或无)
   3 型（右线性）：A→aB 或 A→a——恰是 DFA 转移的文法写法 *)
Definition rg := list (nat * (nat * option nat)).

(* 文法推导：一步 A→aB 把 (A) 变 (a,B)；终止 A→a 吐出符号 *)
Fixpoint rgDerives (g : rg) (A : nat) (w : list nat) : bool :=
  match w with
  | [] => false        (* 终止式 A→a 总吐出一个符号：空词不可派生 *)
  | s :: rest =>
      match rest with
      | [] => existsb (fun r => andb (Nat.eqb (fst r) A)
               (andb (Nat.eqb (fst (snd r)) s)
                     (match snd (snd r) with None => true
                      | Some _ => false end))) g
      | _ => existsb (fun r => andb (Nat.eqb (fst r) A)
               (andb (Nat.eqb (fst (snd r)) s)
                     (match snd (snd r) with
                      | None => false
                      | Some B => rgDerives g B rest end))) g
      end
  end.

(* 3 型文法↔DFA 互译（定理 11.2(4)）：产生式 A→aB 即转移 (A,a,B)；
   终止产生式 A→a 即「读 a 后进入接受」。gog 文法的翻译账： *)
Definition gogRg : rg :=
  [ (0,(0,Some 1)); (1,(1,Some 1)); (1,(0,Some 2)); (2,(2,Some 3))
  ; (3,(3,None)) ].

(* 文法导出 vs DFA 接受的对照（词表枚举） *)
Definition rgToDfa (g : rg) : dfa :=
  map (fun r => match snd (snd r) with
                | Some B => (fst r, fst (snd r), B)
                | None => (fst r, fst (snd r), 4)   (* 终止式→接受态 4 *)
                end) g.

(* 互译对账：gogRg 的 DFA 化恰是 gogDfa 的骨架（+sink 态） *)
Example rg_dfa_agree :
  forallb (fun w =>
    Bool.eqb (rgDerives gogRg 0 w) (dfaAccept (rgToDfa gogRg) 0 [4] w))
    (wordsUpto 4 5) = true.
Proof. reflexivity. Qed.
(* 定理 11.2(4) 的机器面：3 型文法生成语言=DFA 接受语言——生成与
   识别在正则层完全对偶（产生式=转移、派生=运行、终止=接受）。 *)

(* 层级总表（表 11.12+图 11.10 的数据面）：
   0 型 无限制短语 ⟷ 图灵机（70 章）      递归可枚举
   1 型 |α|≤|β|   ⟷ LBA（非确定）        上下文有关
   2 型 α∈V_N     ⟷ PDA（非确定）        上下文无关
   3 型 右线性    ⟷ DFA/NFA              正则
   包含链 0⊇1⊇2⊇3（语法限制递增、生成能力递减）。 *)
Definition chomskyTable : list (nat * nat) :=
  [ (0,0); (1,1); (2,2); (3,3) ].   (* 四层占位账：层号=机器级 *)

Example chomsky_count : length chomskyTable = 4.
Proof. reflexivity. Qed.

(* 冒烟 *)
Compute (dfaRun pandaDfa 0 [0;1], length (wordsUpto 2 4)).
