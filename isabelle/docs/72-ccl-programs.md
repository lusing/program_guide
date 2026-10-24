# 72 · CCL（四）：四个可执行例子——Nat、List、Stream、Flag

对应示例：`../examples/ccl/T72_ccl_programs.thy`（IsaTutCCLex 会话，父堆
`IsaTutCCL`，另导 `IsaTutCCL.Nat` / `.List` / `.Stream` / `.Flag`）

> 参考：[Isabelle/CCL 库索引](https://dist.isabelle.cit.tum.de/dist/library/FOL/CCL/index.html?token=Isabelle)

## 72.1 四个例子理论：CCL 库的「毕业设计」

前三章（69–71）把 CCL 库的**机制**讲完了：集合与不动点、无类型
λ 演算、类型系统、良基关系、不动点归纳。本章讲**用法**——库在
`src/CCL/ex/` 下放了四个完整例子，每一个都是一篇小论文：

- `ex/Nat.thy`（109 行）在自然数上定义算术与比较，并用 `typechk`
  证明它们保类型、用 `NatPR` 证明它们终止；
- `ex/List.thy`（121 行）定义 map / append / filter / flat /
  insert / isort / partition / qsort；
- `ex/Stream.thy`（137 行）定义两个迭代函数，并用**余归纳**证明
  无穷流上的等式；
- `ex/Flag.thy`（76 行）把 Dijkstra 的荷兰国旗问题改写成列表版
  （库自己的吐槽：原例的精髓是用数组，这里只能用列表）。

四个理论的依赖链是一条直线：
`Nat` → `List` → `Stream` / `Flag`。本章把它们逐个拆开。

## 72.2 Nat 上的程序：定义

库源码 `src/CCL/ex/Nat.thy` 第 12–19 行，七个定义两种写法。

**非递归的**用 `nrec`（第 70 章的原始递归子）：

```isabelle
definition not :: "i\<Rightarrow>i"
  where "not(b) == if b then false else true"

definition add :: "[i,i]\<Rightarrow>i"  (infixr \<open>#+\<close> 60)
  where "a #+ b == nrec(a, b, \<lambda>x g. succ(g))"

definition mult :: "[i,i]\<Rightarrow>i"  (infixr \<open>#*\<close> 60)
  where "a #* b == nrec(a, zero, \<lambda>x g. b #+ g)"
```

`add` 读作"对第一个参数递归：递归到 0 返回第二个参数，每层多套
一个 `succ`"——就是结构递归版的加法。`mult` 则是"把 `b` 连加
`a` 次"。

**递归的**（自己调用自己）必须用 `letrec`：

```isabelle
definition sub :: "[i,i]\<Rightarrow>i"  (infixr \<open>#-\<close> 60)
  where
    "a #- b ==
      letrec sub x y be ncase(y, x, \<lambda>yy. ncase(x, zero, \<lambda>xx. sub(xx,yy)))
      in sub(a,b)"
```

`sub` 的递归结构值得细看：先对 `y` 分情况——`y` 是 `zero` 就直接
返回 `x`（减光了）；否则再对 `x` 分情况，`x` 是 `zero` 说明
"减出负数了"，库选择**返回零**（截断减法，源第 78 行的注释
`(* Defined to return zero if a<b *)`）。`le` / `lt` 是同一模板
（源第 27–34 行），`div` 和 `ackermann`（源第 36–47 行）稍复杂但
同构：

```isabelle
definition div :: "[i,i]\<Rightarrow>i"  (infixr \<open>##\<close> 60)
  where
    "a ## b ==
      letrec div x y be if x #< y then zero else succ(div(x#-y,y))
      in div(a,b)"
```

`ackermann` 是双重递归，两个参数互相递归——正是它让普通的原始
递归子 `nrec` 不够用。

七个定义实测（`examples/ccl/T72_ccl_programs.thy` 第 28 行）：

```text

  not(?b) \<equiv> if ?b then false else true
  ?a #+ ?b \<equiv> nrec(?a, ?b, \<lambda>x. succ)
  ?a #* ?b \<equiv> nrec(?a, zero, \<lambda>x. (#+)(?b))
  ?a #- ?b \<equiv>
  letrec sub x y be ncase(y, x, \<lambda>yy. ncase(x, zero, \<lambda>xx. sub(xx, yy)))
     in sub(?a, ?b)
  ?a #<= ?b \<equiv>
  letrec le x y be ncase(x, true, \<lambda>xx. ncase(y, false, le(xx)))
     in le(?a, ?b)
  ?a #< ?b \<equiv> not(?b #<= ?a)
  ?a ## ?b \<equiv>
  letrec div x y be if x #< y then zero else succ(div(x #- y, y))
     in div(?a, ?b)
  ackermann(?a, ?b) \<equiv>
  letrec ack n m be ncase
                     (n, succ(m),
                      \<lambda>x. ncase
                           (m, ack(x, succ(zero)),
                            \<lambda>y. ack(x, ack(succ(x), y))))
     in ack(?a, ?b)
```

注意 `#+` 与 `#*` 的形态：`nrec(a, b, λx. succ)` 的第三个参数
只用到 `g` 的一部分（`λx g. succ(g)` 打印时 `x` 被吸收），而
`#*` 的 `λx g. b #+ g` 则两个都用。**`nrec` 的第三个参数永远拿
"当前层号 `x`"和"下一层结果 `g`"**——第 70 章 `nrecBsucc` 的形态。

## 72.3 natBs：哪些函数能算，哪些不能

库源码第 49–60 行把可计算的函数打包成一条 simp 规则集：

```isabelle
lemmas nat_defs = not_def add_def mult_def sub_def le_def lt_def ackermann_def napply_def

lemma natBs [simp]:
  "not(true) = false"
  "not(false) = true"
  "zero #+ n = n"
  "succ(n) #+ m = succ(n #+ m)"
  "zero #* n = zero"
  "succ(n) #* m = m #+ (n #* m)"
  "f^zero`a = a"
  "f^succ(n)`a = f(f^n`a)"
  by (simp_all add: nat_defs)
```

注意这条规则集**只覆盖 `not` / `add` / `mult` / `napply`**，
`sub` / `le` / `lt` / `div` / `ackermann` 一条都没有。原因在第 70
章已经踩过：后几个用 `letrec` 定义，`letrecB` 会把 `fix(...)`
无限展开，不能进 simp 集。这不是疏漏，是**有意的设计取舍**——
下面四个计算演示全部落在"能算"的那一侧：

```isabelle
lemma not_demo: "not(true) = false"
  by simp

lemma add_demo: "succ(succ(zero)) #+ succ(succ(zero)) = succ(succ(succ(succ(zero))))"
  by simp

lemma mult_demo: "succ(succ(zero)) #* succ(succ(zero)) = succ(succ(succ(succ(zero))))"
  by simp

lemma napply_demo: "succ ^ succ(succ(zero)) ` zero = succ(succ(zero))"
  by simp
```

```text

theorem not_demo: not(true) = false

theorem
  add_demo:
    succ(succ(zero)) #+ succ(succ(zero)) = succ(succ(succ(succ(zero))))

theorem
  mult_demo:
    succ(succ(zero)) #* succ(succ(zero)) = succ(succ(succ(succ(zero))))

theorem napply_demo: succ ^ succ(succ(zero)) ` zero = succ(succ(zero))
```

四条全是 `by simp` 一步过。`add_demo` 走的路：`add_def` 展开 →
`nrecBsucc` 逐层剥 `succ` → `nrecBzero` 收口 → `succ` 塔对齐。
`napply_demo` 的 `succ ^ 2 ` zero` 则是 `napplyBsucc` 两遍。

反过来，把 `sub` 交给 `simp`（哪怕连 `nat_defs` 一起给）只会得到
展开到一半的 `letrec`，此后再无规则可施——库因此没给
`sub` / `le` / `lt` / `div` / `ackermann` 任何计算规则。**这是
读 CCL 时第一个反直觉的地方：库里有函数，但算不了。**

## 72.4 类型保持：`typechk` 战术

库源码第 68–96 行，五个类型定理形状完全一样："两个 Nat 进去，
一个 Nat/Bool 出来"。证明全是三行：

```isabelle
lemma addT: "\<lbrakk>a:Nat; b:Nat\<rbrakk> \<Longrightarrow> a #+ b : Nat"
  apply (unfold add_def)
  apply typechk
  done
```

`typechk` 是 `Wfd.thy` 第 482–484 行定义的 `method_setup`，它把
第 71 章的 `ncaseT` / `lrecT` 等类型规则按目标形状自动拼起来。
**关键在于 `unfold add_def`**：不先把定义展开，`typechk` 看到
的只是一个陌生的常量 `#+`，无从下手。这也是本章第一条实用经验：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
unfold 定义 → typechk → （必要时）clean_ccs + 良基证明
```

下面把四个类型定理原样复用一遍（这一步什么新东西都没证明，
目的是让读者看到"库的定理可以直接当地基用"）：

```isabelle
lemma add_type_demo: "a:Nat \<Longrightarrow> b:Nat \<Longrightarrow> a #+ b : Nat"
  by (rule addT)

lemma mult_type_demo: "a:Nat \<Longrightarrow> b:Nat \<Longrightarrow> a #* b : Nat"
  by (rule multT)

lemma le_type_demo: "a:Nat \<Longrightarrow> b:Nat \<Longrightarrow> a #<= b : Bool"
  by (rule leT)

lemma lt_type_demo: "a:Nat \<Longrightarrow> b:Nat \<Longrightarrow> a #< b : Bool"
  by (rule ltT)
```

```text

theorem add_type_demo: \<lbrakk>?a : Nat; ?b : Nat\<rbrakk> \<Longrightarrow> ?a #+ ?b : Nat

theorem mult_type_demo: \<lbrakk>?a : Nat; ?b : Nat\<rbrakk> \<Longrightarrow> ?a #* ?b : Nat

theorem le_type_demo: \<lbrakk>?a : Nat; ?b : Nat\<rbrakk> \<Longrightarrow> ?a #<= ?b : Bool

theorem lt_type_demo: \<lbrakk>?a : Nat; ?b : Nat\<rbrakk> \<Longrightarrow> ?a #< ?b : Bool
```

## 72.5 终止性：`NatPR` 三件套

`sub` / `le` 是**自己调用自己**的，`typechk` 只能证明"如果递归
调用有类型，那整体有类型"，剩下的义务是"递归确实停下来"。库源码
第 79–84 行（`leT` 在第 86–91 行，同款）：

```isabelle
lemma subT: "\<lbrakk>a:Nat; b:Nat\<rbrakk> \<Longrightarrow> a #- b : Nat"
  apply (unfold sub_def)
  apply typechk
  apply clean_ccs
  apply (erule NatPRI [THEN wfstI, THEN NatPR_wf [THEN wmap_wf, THEN wfI]])
  done
```

拆开最后那行 `OF` 链（从右往左读）：

- `NatPR_wf`：前驱关系 `NatPR = {p. EX x:Nat. p=<x,succ(x)>}`
  在 Nat 上良基（第 71.7 节引过）；
- `wmap_wf`：经函数映射保持良基；
- `wfI`：把良基判据兑现成集合包含；
- `wfstI`：把"对第一个分量递减"升级成"对序对递减"；
- `NatPRI`：给出具体的递减序对 `<t, h$t>` 形状的见证。

`clean_ccs`（源第 486–488 行的 `method_setup`）负责把 `letrec`
产生的"干净性副条件"清掉。这一套（`clean_ccs` + 良基链）就是
CCL 里证明**递归函数终止**的标准动作，第 72.6 节的 ackermann 和
第 72.11 节的荷兰国旗用的都是它。

六条规则实测（`examples/ccl/T72_ccl_programs.thy` 第 185 行）：

```text

  NatPR \<equiv> {p. EX x:Nat. p = <x,succ(x)>}
  Wfd(NatPR)
  ?x : Nat \<Longrightarrow> <?x,succ(?x)> : NatPR
  <?xa,?ya> : ?r \<Longrightarrow> <<?xa,?xb>,<?ya,?yb>> : wmap(fst, ?r)
  Wfd(?r) \<Longrightarrow> Wfd(wmap(?f, ?r))
  \<lbrakk>Wfd(?r); ?a : ?r\<rbrakk> \<Longrightarrow> ?a : wf(?r)
```

## 72.6 ackermann：字典序

Ackermann 函数的终止性不能靠单一递减关系——它的两个递归调用中，
一个减 `n`、一个加 `m`，是典型的**字典序**形状。库源码第 99–107
行先造一条复合良基关系：

```isabelle
lemmas relI = NatPR_wf [THEN NatPR_wf [THEN lex_wf, THEN wfI]]
```

读作：`ra ** rb` 良基，若 `ra` 与 `rb` 都良基（第 71.7 节的
`lex_wf`）。然后：

```isabelle
lemma "\<lbrakk>a:Nat; b:Nat\<rbrakk> \<Longrightarrow> ackermann(a,b) : Nat"
  apply (unfold ackermann_def)
  apply gen_ccs
  apply (erule NatPRI [THEN lexI1 [THEN relI]] NatPRI [THEN lexI2 [THEN relI]])+
  done
```

`lexI1` / `lexI2` 分别覆盖字典序的两支：第一分量严格递减，或
第一分量相同、第二分量递减。两个递归调用正好一支一支。`gen_ccs`
是 `typechk` 的加强版（源第 490–492 行），额外接受要用的类型定理
作参数。

五条规则实测（第 211 行）：

```text

  ?ra ** ?rb \<equiv>
  {p. \<exists>a a' b b'.
         p = <<a,b>,<a',b'>> \<and> (<a,a'> : ?ra \<or> a = a' \<and> <b,b'> : ?rb)}
  \<lbrakk>Wfd(?R); Wfd(?S)\<rbrakk> \<Longrightarrow> Wfd(?R ** ?S)
  <?a,?a'> : ?ra \<Longrightarrow> <<?a,?b>,<?a',?b'>> : ?ra ** ?rb
  <?b,?b'> : ?rb \<Longrightarrow> <<?a,?b>,<?a,?b'>> : ?ra ** ?rb
  ?a : NatPR ** NatPR \<Longrightarrow> ?a : wf(NatPR ** NatPR)
```

最后一条 `?a : NatPR ** NatPR ⟹ ?a : wf(NatPR ** NatPR)` 正是
`relI` 兑现出来的东西：字典序复合关系落在自己的良基域里。

## 72.7 List 上的程序：定义

库源码 `src/CCL/ex/List.thy` 第 12–28 行。非递归的（对列表结构
递归的）用 `lrec`：

```isabelle
definition map :: "[i\<Rightarrow>i,i]\<Rightarrow>i"
  where "map(f,l) == lrec(l, [], \<lambda>x xs g. f(x)$g)"

definition comp :: "[i\<Rightarrow>i,i\<Rightarrow>i]\<Rightarrow>i\<Rightarrow>i"  (infixr \<open>\<circ>\<close> 55)
  where "f \<circ> g == (\<lambda>x. f(g(x)))"

definition append :: "[i,i]\<Rightarrow>i"  (infixr \<open>@\<close> 55)
  where "l @ m == lrec(l, m, \<lambda>x xs g. x$g)"

axiomatization member :: "[i,i]\<Rightarrow>i"  (infixr \<open>mem\<close> 55)  (* FIXME dangling eq *)
  where member_ax: "a mem l == lrec(l, false, \<lambda>h t g. if eq(a,h) then true else g)"

definition filter :: "[i,i]\<Rightarrow>i"
  where "filter(f,l) == lrec(l, [], \<lambda>x xs g. if f`x then x$g else g)"

definition flat :: "i\<Rightarrow>i"
  where "flat(l) == lrec(l, [], \<lambda>h t g. h @ g)"
```

`member` 是全库唯一一条函数级 `axiomatization`（库注释自己标了
`FIXME dangling eq`——它引用的 `eq` 在 CCL 里根本没有定义）。后果
很具体：`mem` 一条 simp 规则都没有（第 72.8 节的 `listBs` 不含它），
凡是含 `mem` 的目标都算不动；第 72.11 节国旗问题的规格里恰好用
到了它。

注意 `map` 的第一个参数是 **HOL 函数** `i⇒i`（所以
`map(succ, l)` 能直接写），而 `filter` 的谓词参数是 **CCL 项**
（要用 `f`x` 施加，所以得写 `lam x. ...`）——这个不对称在第
72.10 节还会再咬一次。

两个比较函数的例子用 `letrec`：

```isabelle
definition partition :: "[i,i]\<Rightarrow>i" where
  "partition(f,l) == letrec part l a b be lcase(l, <a,b>, \<lambda>x xs.
                            if f`x then part(xs,x$a,b) else part(xs,a,x$b))
                    in part(l,[],[])"
```

`partition` 把 `l` 按谓词 `f` 劈成两截，用的是**双累加器**
`a` / `b`；快排 `qsort`（源第 41–45 行）则是它加自身递归：

```isabelle
definition qsort :: "i\<Rightarrow>i" where
  "qsort(f) == lam l. letrec qsortx l be lcase(l, [], \<lambda>h t.
                                   let p be partition(f`h,t)
                                   in split(p, \<lambda>x y. qsortx(x) @ h$qsortx(y)))
                          in qsortx(l)"
```

十个定义实测（第 29–30 行 `thm` 分两批）：

```text

  map(?f, ?l) \<equiv> lrec(?l, [], \<lambda>x xs. ($)(?f(x)))
  ?f \<circ> ?g \<equiv> \<lambda>x. ?f(?g(x))
  ?l @ ?m \<equiv> lrec(?l, ?m, \<lambda>x xs. ($)(x))
  ?a mem ?l \<equiv> lrec(?l, false, \<lambda>h t. if(?eq(?a, h), true))
  filter(?f, ?l) \<equiv> lrec(?l, [], \<lambda>x xs g. if ?f ` x then x $ g else g)
  flat(?l) \<equiv> lrec(?l, [], \<lambda>h t. (@)(h))
```

```text

  partition(?f, ?l) \<equiv>
  letrec part l a b be lcase
                        (l, <a,b>,
                         \<lambda>x xs.
                            if ?f ` x then part(xs, x $ a, b)
                               else part(xs, a, x $ b))
     in part(?l, [], [])
  insert(?f, ?a, ?l) \<equiv>
  lrec(?l, ?a $ [], \<lambda>h t g. if ?f ` ?a ` h then ?a $ h $ t else h $ g)
  isort(?f) \<equiv> lam l. lrec(l, [], \<lambda>h t. insert(?f, h))
  qsort(?f) \<equiv>
  lam l.
     letrec qsortx l be lcase
                         (l, [],
                          \<lambda>h t. let p be partition(?f ` h, t)
                                   in split
 (p, \<lambda>x y. qsortx(x) @ h $ qsortx(y)))
        in qsortx(l)
```

`insert` 那一支的 `if ?f ` ?a ` h` 是**两次应用**：先 `f ` a`
再 `f`a` ` h`——比较函数 `f` 在这里是一个 CCL 项函数，
`f`a`h` 读作 `f(a)(h)`，即"a 与 h 的比较结果"。

## 72.8 listBs 与计算

库源码第 47–63 行，与 `natBs` 同构：

```isabelle
lemmas list_defs = map_def comp_def append_def filter_def flat_def
  insert_def isort_def partition_def qsort_def

lemma listBs [simp]:
  "\<And>f g. (f \<circ> g) = (\<lambda>a. f(g(a)))"
  "\<And>a f g. (f \<circ> g)(a) = f(g(a))"
  "\<And>f. map(f,[]) = []"
  "\<And>f x xs. map(f,x$xs) = f(x)$map(f,xs)"
  "\<And>m. [] @ m = m"
  "\<And>x xs m. x$xs @ m = x$(xs @ m)"
  "\<And>f. filter(f,[]) = []"
  "\<And>f x xs. filter(f,x$xs) = if f`x then x$filter(f,xs) else filter(f,xs)"
  "flat([]) = []"
  "\<And>x xs. flat(x$xs) = x @ flat(xs)"
  "\<And>a f. insert(f,a,[]) = a$[]"
  "\<And>a f xs. insert(f,a,x$xs) = if f`a`x then a$x$xs else x$insert(f,a,xs)"
  by (simp_all add: list_defs)
```

`map` / `append` / `flat` / `insert` / `filter` 都能算；
`isort` / `qsort` / `partition` 含 `letrec`，算不动。四个计算演示：

```isabelle
lemma map_demo: "map(succ, zero $ succ(zero) $ []) = succ(zero) $ succ(succ(zero)) $ []"
  by simp

lemma append_demo: "zero$[] @ succ(zero)$[] = zero $ succ(zero) $ []"
  by simp

lemma flat_demo: "flat(zero $ (succ(zero)$[]) $ []) = zero @ (succ(zero) $ [])"
  by simp

lemma insert_demo:
  "insert(lam x. lam y. true, zero, succ(zero)$[]) = zero $ succ(zero) $ []"
  by simp
```

```text

theorem
  map_demo:
    map(succ, zero $ succ(zero) $ []) = succ(zero) $ succ(succ(zero)) $ []

theorem append_demo: zero $ [] @ succ(zero) $ [] = zero $ succ(zero) $ []

theorem
  flat_demo: flat(zero $ (succ(zero) $ []) $ []) = zero @ succ(zero) $ []

theorem
  insert_demo:
    insert(lam x y. true, zero, succ(zero) $ []) = zero $ succ(zero) $ []
```

`insert` 那一支把比较函数写死成 `lam x. lam y. true`（"总是插到
前面"），于是 `if f`a`h` 直接归约；这也反证了第 72.3 节的取舍——
想让 `insert` 真正按大小插入，得先让 `#<=` 可计算，而库刻意没给。

## 72.9 有限列表用归纳，无穷流用余归纳

这是本章最重要的一节。第 71.2 节说过：
`List(A) == lfp(...)`（有限），`Lists(A) == gfp(...)`（含无穷）。
两类列表的证明方法因此完全不同：有限的用 `List_ind` 归纳，
无穷的用 `eq_coinduct3` 余归纳。

库在 `ex/Stream.thy` 里给无穷版证了三条（`map_comp` / `map_id` /
`map_append`），全是 apply 风格。这里先把**有限版**用 Isar 写出来
当对照——同一条命题，归纳证明只多几行，且每一步都能说清：

```isabelle
lemma map_id_finite_demo: "l : List(A) \<Longrightarrow> map((\<lambda>x. x), l) = l"
proof (erule List_ind)
  show "map((\<lambda>x. x), []) = []" by simp
  fix x xs assume "x:A" "xs:List(A)" and ih: "map((\<lambda>x. x), xs) = xs"
  show "map((\<lambda>x. x), x$xs) = x$xs" by (simp add: ih)
qed

lemma map_comp_finite_demo:
  "l : List(A) \<Longrightarrow> map((\<lambda>x. f(g(x))), l) = map(f,map(g,l))"
proof (erule List_ind)
  show "map((\<lambda>x. f(g(x))), []) = map(f,map(g,[]))" by simp
  fix x xs assume "x:A" "xs:List(A)"
    and ih: "map((\<lambda>x. f(g(x))), xs) = map(f,map(g,xs))"
  show "map((\<lambda>x. f(g(x))), x$xs) = map(f,map(g,x$xs))" by (simp add: ih)
qed

lemma append_assoc_finite_demo:
  "\<lbrakk>k:List(A); l:List(A); m:List(A)\<rbrakk> \<Longrightarrow> k @ l @ m = (k@l) @ m"
proof (erule List_ind)
  show "[] @ l @ m = ([]@l) @ m" by simp
  fix x xs assume "x:A" "xs:List(A)" "l:List(A)" "m:List(A)"
    and ih: "xs @ l @ m = (xs@l) @ m"
  show "x$xs @ l @ m = (x$xs@l) @ m" by (simp add: ih)
qed
```

三条的证法一模一样：`erule List_ind` 把目标按列表结构拆成空表
一支与 `x$xs` 一支，基例 `simp`（`listBs` 里 `map(f,[]) = []`、
`[] @ m = m`），步进支 `simp add: ih` 把归纳假设喂进去。

```text
theorem map_id_finite_demo: ?l : List(?A) \<Longrightarrow> map(\<lambda>x. x, ?l) = ?l

show map(\<lambda>x. x, []) = []

show map(\<lambda>x. x, x $ xs) = x $ xs

theorem
  map_comp_finite_demo:
    ?l : List(?A) \<Longrightarrow> map(\<lambda>x. ?f(?g(x)), ?l) = map(?f, map(?g, ?l))

show map(\<lambda>x. f(g(x)), []) = map(f, map(g, []))

show map(\<lambda>x. f(g(x)), x $ xs) = map(f, map(g, x $ xs))

theorem
  append_assoc_finite_demo:
    \<lbrakk>?k : List(?A); ?l : List(?A); ?m : List(?A)\<rbrakk>
    \<Longrightarrow> ?k @ ?l @ ?m = (?k @ ?l) @ ?m

show [] @ l @ m = ([] @ l) @ m

show x $ xs @ l @ m = (x $ xs @ l) @ m
```

**换成无穷列表，这套立刻失效**——`List_ind` 的归纳假设只覆盖
有限层，而一条无穷流有穷层永不到头。三条规则实测（第 347 行）：

```text

  \<lbrakk>?l : List(?A); ?P([]);
   \<And>x xs. \<lbrakk>x : ?A; xs : List(?A); ?P(xs)\<rbrakk> \<Longrightarrow> ?P(x $ xs)\<rbrakk>
  \<Longrightarrow> ?P(?l)
  ?a : Lists(?A) \<longleftrightarrow> ?a = [] \<or> (EX x:?A. EX xs:Lists(?A). ?a = x $ xs)
  ?a : ILists(?A) \<longleftrightarrow> (EX x:?A. EX xs:ILists(?A). ?a = x $ xs)
```

## 72.10 流：iter1、iter2 与余归纳

库源码 `src/CCL/ex/Stream.thy` 第 12–16 行定义两个"从一个起点
产生无穷流"的函数，写法不同、语义相同：

```isabelle
definition iter1 :: "[i\<Rightarrow>i,i]\<Rightarrow>i"
  where "iter1(f,a) == letrec iter x be x$iter(f(x)) in iter(a)"

definition iter2 :: "[i\<Rightarrow>i,i]\<Rightarrow>i"
  where "iter2(f,a) == letrec iter x be x$map(f,iter(x)) in iter(a)"
```

`iter1` 直接递归调用自己，`iter2` 先把 `f` 通过 `map` 施加到尾部
再递归。两者的一步展开规则（源第 108–118 行）就是 `letrecB` 的
直接推论：

```isabelle
lemma iter1B: "iter1(f,a) = a$iter1(f,f(a))"
  apply (unfold iter1_def)
  apply (rule letrecB [THEN trans])
  apply simp
  done

lemma iter2B: "iter2(f,a) = a $ map(f,iter2(f,a))"
  apply (unfold iter2_def)
  apply (rule letrecB [THEN trans])
  apply (rule refl)
  done
```

注意 `letrecB` 后面必须接 `trans`：`letrecB` 给出的是
`let x be t in f(x) = f(t)`，还要再传一步才落到 `iter1(f,a)` 上。

真正有意思的是**证明两者相等**。库的做法（源第 127–135 行）是
第 70 章 `eq_coinduct3` 的标准三段式：

```isabelle
lemma iter1_iter2_eq: "iter1(f,a) = iter2(f,a)"
  apply (eq_coinduct3
    "{p. EX x y. p=<x,y> \<and> (EX n:Nat. x=iter1 (f,f^n`a) \<and> y=map (f) ^n`iter2 (f,a))}")
  apply (fast intro!: napplyBzero [symmetric] napplyBzero [symmetric, THEN arg_cong])
  apply (EQgen iter1B iter2Blemma)
  apply (subst napply_f, assumption)
  apply (rule_tac f1 = f in napplyBsucc [THEN subst])
  apply blast
  done
```

关系 `R` 的设计是全证明的灵魂：它不说"`x` 与 `y` 结构相同"，
而说"`x` 是 `iter1` 从 `f^n`a` 出发、`y` 是 `iter2` 施加 `n` 次
`map`"——把"已经同步了多少步"编码进关系里，于是余归纳的每一步
只要把 `n` 推成 `succ(n)`。`EX n:Nat` 这个存在量词是**余归纳
关系的燃料**：每展开一层就换一个更大的 `n`，关系却不变。

作为对照，库还给无穷列表证了三条纯等式（源第 27–67 行的
`map_comp` / `map_id` / `map_append`），全是 `eq_coinduct3` +
`drule ListsXH [THEN iffD1]` + `EQgen` 的三连。第 72.9 节已经用
Isar 把它们的有限版写完了，读者可以自己对比：同样的命题，一边
是 `erule List_ind`，一边是 `eq_coinduct3` + 一条精心设计的 `R`。

六条规则实测（第 410 行 `thm`）：

```text

  iter1(?f, ?a) \<equiv> letrec iter x be x $ iter(?f(x)) in iter(?a)
  iter2(?f, ?a) \<equiv> letrec iter x be x $ map(?f, iter(x)) in iter(?a)
  iter1(?f, ?a) = ?a $ iter1(?f, ?f(?a))
  iter2(?f, ?a) = ?a $ map(?f, iter2(?f, ?a))
  \<lbrakk><?t,?u> : ?R; ?R <= EQgen(lfp(\<lambda>x. EQgen(x) Un ?R Un EQ))\<rbrakk> \<Longrightarrow> ?t = ?u
  <?t,?t'> : EQgen(?R) \<longleftrightarrow>
  ?t = bot \<and> ?t' = bot \<or>
  ?t = true \<and> ?t' = true \<or>
  ?t = false \<and> ?t' = false \<or>
  (\<exists>a a' b b'. ?t = <a,b> \<and> ?t' = <a',b'> \<and> <a,a'> : ?R \<and> <b,b'> : ?R) \<or>
  (\<exists>f f'. ?t = lam x. f(x) \<and> ?t' = lam x. f'(x) \<and> (\<forall>x. <f(x),f'(x)> : ?R))
```

前两条是定义，三、四条是 `iter1B` / `iter2B`，第五条是
`eq_coinduct3`，第六条是 `EQgenXH`——余归纳的全部机器一字排开。

## 72.11 荷兰国旗：列表版 Dijkstra

库源码 `src/CCL/ex/Flag.thy`。Dijkstra 的原例用数组，这里退化成
列表：三色各归各的桶。颜色用和类型编码（源第 13–23 行）：

```isabelle
definition Colour :: "i set"
  where "Colour == Unit + Unit + Unit"

definition red :: "i"
  where "red == inl(one)"

definition white :: "i"
  where "white == inr(inl(one))"

definition blue :: "i"
  where "blue == inr(inr(one))"
```

`ccase`（源第 25–26 行）是颜色上的三分支 case，`flag`（源第
28–36 行）用双累加器 `lr` / `p` / `lw` / `lb` 一趟扫完。库证了
它的**类型**（源第 63–69 行）——注意最后两步与第 72.5 节完全
同构：

```isabelle
lemma "flag : List(Colour)->List(Colour)*List(Colour)*List(Colour)"
  apply (unfold flag_def)
  apply (typechk redT whiteT blueT ccaseT)
  apply clean_ccs
  apply (erule ListPRI [THEN ListPR_wf [THEN wfI]])
  apply assumption
  done
```

这里 `typechk` 带上了三个参数 `redT` / `whiteT` / `blueT` 与
`ccaseT`——它们不是 Nat 上那样的内置规则，而是本文件自己证的
（源第 53–61 行），正好演示"类型定理也是普通定理，可以当参数传"。

库最后一条（源第 71–74 行）想证 flag 满足规格
`PROD l:List(Colour).{x:...Flag(x,l)}`，用 `gen_ccs` 之后**以
`oops` 收场**——`Perm` 是公理化的（源第 38 行
`axiomatization Perm`），correctness 证不下去。这是库作者留的
诚实尾巴。

四条定义与四条类型规则实测（第 452 行 `thm`）：

```text

  Colour \<equiv> Unit + Unit + Unit
  red \<equiv> inl(one)
  white \<equiv> inr(inl(one))
  blue \<equiv> inr(inr(one))
  \<lbrakk>?c : Colour; ?c = red \<Longrightarrow> ?r : ?C(red); ?c = white \<Longrightarrow> ?w : ?C(white);
   ?c = blue \<Longrightarrow> ?b : ?C(blue)\<rbrakk>
  \<Longrightarrow> ccase(?c, ?r, ?w, ?b) : ?C(?c)
  red : Colour
  white : Colour
  blue : Colour
```

`ccaseT` 的形状是"按 `c` 的实际取值分派"——三条前提各带一个
`?c = red` 式的守卫，正是 `whenT` 在三个 `Unit` 上反复嵌套的
结果。

## 72.12 坑位清单（实测）

1. **`map` 收 HOL 函数，`filter` / `insert` / `isort` 收 CCL 项**：
   `map(succ, l)` 直接写，`map(lam x. x, l)` 反而类型报错
   （`lam x. x :: i` 塞不进 `i⇒i`）；而 `filter(f,l)` 里 `f` 要用
   `f`x` 施加，必须写 `lam x. ...`。两类参数写法相反，是本库最
   容易反复踩的一条。
2. **`letrec` 定义的函数没有 simp 规则**：`natBs` 只覆盖
   `not` / `add` / `mult` / `napply`；`sub` / `le` / `lt` /
   `div` / `ackermann` / `partition` / `qsort` 一条都没有
   （`letrecB` 进 simp 集会无限展开）。拿它们做计算演示只会得到
   展开到一半的 `letrec`。
3. **证明类型之前必须 `unfold` 定义**：`typechk` 靠 `ncaseT` /
   `lrecT` 这些**规则**匹配目标，面对未展开的常量 `#+` 无从
   下手；顺序写成 `typechk` 再 `unfold` 必然失败。
4. **`sub` 是截断减法**：`a #- b` 在 `a < b` 时返回 `zero` 而
   不是负数（源第 78 行注释）。拿它当普通减法推性质会推出假命题。
5. **`eq_coinduct3` 的关系里要带存在量词当燃料**：
   `iter1_iter2_eq` 的 `R` 里有 `EX n:Nat`，每展开一层换更大的
   `n`；写成不带量词的"结构相同"型关系，余归纳前提
   `R <= EQgen(...)` 证不出来。
6. **`letrecB` 后必须接 `trans`**：它给的是
   `let x be t in f(x) = f(t)`，与目标 `iter1(f,a) = ...` 还差
   一次传递，少了 `trans` 会报形状不匹配。
7. **有限与无穷的证明方法不能混用**：`List_ind` 对 `Lists(A)`
   无效（无穷流到不了基例），`eq_coinduct3` 对 `List(A)` 也能用
   但是杀鸡用牛刀。选错方法的报错是 `Failed to refine`，很难直接
   看出原因。
8. **`typechk` 可以带类型定理作参数**：
   `typechk redT whiteT blueT ccaseT`——这些定理是本文件现证的，
   不是内置规则。`gen_ccs` 同理。忘了传参会在 `clean_ccs` 阶段
   留下无法关闭的义务。
9. **`Perm` 是公理不是定理**：`Flag.thy` 第 38 行
   `axiomatization Perm`，所以 correctness 那条以 `oops` 结束；
   读库时别把 `oops` 当成"已经证完"。
10. **`x$xs` 与 `l @ m` 优先级不同**：`$` 是 80、`@` 是 55，
    写 `x$xs @ m` 不会被解析成 `x $ (xs @ m)`，但也别依赖直觉，
    拿不准就加括号（本章 `flat_demo` 就这么干的）。
## 72.13 与其他章的接口

- 第 70 章：`nrec` / `lrec` / `letrec` / `eq_coinduct3` 是本章
  全部程序的执行与证明引擎。
- 第 71 章：`ncaseT` / `lrecT` / `typechk` 管类型，`NatPR` /
  `ListPR` / `lex` 管终止，`HTT` 管"会不会发散"。
- 第 69 章：lfp 造 `List`，gfp 造 `Lists`——有限与无穷的分界线
  就刻在这两个不动点上。


上一章：[71 · CCL（三）：Type、Hered、Wfd、Fix](71-ccl-type.md) ｜ 下一章：暂无（本篇为 CCL 部分终章） ｜ 返回：[README](../README.md)
