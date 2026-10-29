# 69 · 链表反转

对应示例：`../examples/69_list_reverse.v`（rocq 9.1.1 + stdlib 9.0.0 + VST 2.16 实测编译退出码 0）

第 68 章用 VST 验证了数组求和——循环加数组下标，内存模型里只有一块连续的 `data_at`。本章换一个真正有**指针**的程序：就地反转单链表。它是 Verified Companions（Software Foundations 第四卷）的第二个示例章节，教学重点有三：

1. 怎么给「链表」写分离逻辑谓词（`listrep`）——递归数据结构的空间表示；
2. 自定义空间谓词必须配套的两个 Hint 数据库（`saturate_local` 与 `valid_pointer`），不注册它们，`entailer!` 和 `forward` 会在你的谓词面前集体失明（69.3 的两个反例）；
3. `forward_while` 的循环不变式如何刻画「已反转前缀 + 未反转后缀」，以及证明收尾时的 listrep 引理链。

### 69.1 运行示例：reverse.c 与准备代码

第 68 章已讲过 clightgen 工作流程：C 源经 `clightgen -normalize reverse.c` 生成 Clight AST（本教程已预生成在 `examples/vc/reverse.v`），Rocq 侧导入它当作 `VC.reverse` 模块。准备代码与第 68 章完全相同，只是换了模块名：

```coq
(* 69 链表反转 —— 用 VST 验证就地反转链表的 C 程序 *)

(* 69.1 准备：导入 VST 与 clightgen 生成的 Clight AST *)

Require Import VST.floyd.proofauto.
Require Import VC.reverse.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
```

要验证的 C 程序全文如下（`examples/vc/reverse.c`）：

```c
#include <stddef.h>

struct list {unsigned head; struct list *tail;};

struct list three[] = {
    {1, three+1}, {2, three+2}, {3, NULL}
};

unsigned sumlist (struct list *p) {
  unsigned s = 0;
  struct list *t = p;
  unsigned h;
  while (t) {
     h = t->head;
     t = t->tail;
     s = s + h;
  }
  return s;
}

struct list *reverse (struct list *p) {
  struct list *w, *t, *v;
  w = NULL;
  v = p;
  while (v) {
    t = v->tail;
    v->tail = w;
    w = v;
    v = t;
  }
  return w;
}

int main (void) {
  struct list *r; unsigned s;
  r = reverse(three);
  s = sumlist(r);
  return (int)s;
}
```

C 侧三个要点：

- **结构体**：`struct list {unsigned head; struct list *tail;}`——每个结点是一个 `unsigned` 数据加一个指向下一结点的指针。clightgen 把字段名解析成 `_head`、`_tail` 这样的 ident，整个类型在 Rocq 侧记作 `Tstruct _list noattr`（第 68 章的 `tuint` 对应 `unsigned`，这里我们给结构体类型起缩写 `t_list`，见 69.2）。
- **反转算法**：`reverse` 用三个指针。`v` 扫描未处理的后缀，`w` 指向已经反转好的前缀（其尾指针已全部改写完毕），循环体先把 `v->tail` 存进 `t` 备用，再执行核心一步 `v->tail = w`——**只改 tail 指针、绝不碰 head 数据**——然后 `w` 前进、`v` 跳到 `t`。循环结束时 `v == NULL`，`w` 即新表头。
- **本章范围**：程序里还有全局数组 `three`、求和函数 `sumlist` 和 `main`，但本章沿用原书范围——`Gprog` 只收录 `reverse` 一个规格的证明主线（69.4），不写 `main`/`sumlist` 的规格，因此本章没有 `semax_prog` 级别的 `prog_correct` 引理。自引用初始化的全局数组 `three` 留给第 70 章的 `lseg` 专题再处理。

### 69.2 链表的分离逻辑表示：listrep

`Tstruct _list noattr` 是 C 类型 `struct list` 的 AST，使用频繁，先起缩写。然后是本章的核心定义：

```coq
(* 69.2 链表的分离逻辑表示：listrep 递归谓词 *)

Definition t_list := Tstruct _list noattr.

Fixpoint listrep (sigma: list val) (p: val) : mpred :=
 match sigma with
 | h::hs =>
    EX y:val, data_at Tsh t_list (h,y) p  *  listrep hs y
 | nil =>
    !! (p = nullval) && emp
 end.

Arguments listrep sigma p : simpl never.
```

`listrep sigma p` 读作「地址 `p` 处存着一条表示数学序列 `sigma`（元素类型是 CompCert 的值类型 `val`）的链表」。逐条拆开：

- **cons 情形**：存在一个地址 `y`，使得 `p` 处有一个数据结点 `data_at Tsh t_list (h,y) p`（头值 `h`、尾指针 `y`、top 权限 `Tsh`），它与「`y` 处表示剩余序列 `hs` 的链表」用**分离合取 `*`** 拼接。注意这个 `Fixpoint` 的结构正是第 22 章 `fold_right` 的 shape：`nil` 分支给出基底资源 `emp`，`cons` 分支把「头部结点的资源」与「对尾部的递归调用结果」用 `*` 结合——只不过这里每步还包了一个存在量词 `EX y`，因为尾指针的地址是内存里读出来的、写规格时未知。
- **nil 情形**：`p` 必须是空指针，且内存足迹为空（`emp`）。`p = nullval` 是纯命题（Rocq 的 `Prop`），用 `!!` 注入断言语言 `mpred`。因为 `!!P` 不占有任何足迹，没有可与 `emp` 「分离」的空间内容，所以用普通合取 `&&` 而不是 `*`——这是分离逻辑里写「纯事实」的标准姿势。
- **`Arguments listrep sigma p : simpl never`**：禁止 `simpl` 自动展开 `listrep`，让「展开/折叠」由你显式控制（`unfold listrep; fold listrep`）。展开时机是本章证明节奏的关键，见 69.5。

这个定义把「不重叠」直接焊进了结构里：`listrep (a::b::l) x` 保证 x 结点与后续结点占用**不相交**的内存（69.6 会形式化这一点）。没有 `*`，「更新 `y->tail` 不会顺带改掉 `x->head`」这类事实就得手工写成一长串地址不等式。

### 69.3 空间谓词的两个 Hint 数据库

每定义一个新的空间谓词（类型为 `mpred` 的定义，如 `listrep`），都必须配两个 Hint 数据库：**`saturate_local`**——从空间事实里抽取纯命题（如「`p` 是个指针」）放到横线上方；**`valid_pointer`**——从空间事实里抽取「`p` 是合法指针（NULL 或指向已分配对象）」，C 语言里做 `p != NULL` 之类的指针比较前必须成立。先看 `entailer!` 对**自带**支持的内置谓词 `data_at` 是怎么工作的：

```coq
(* 69.3 空间谓词的两个 Hint 数据库：saturate_local 与 valid_pointer *)

Lemma data_at_isptr_example1:
  forall (h y p : val) ,
   data_at Tsh t_list (h,y) p |-- !! isptr p.
Proof.
intros.
Print isptr.
(* isptr =
   fun v : val => match v with
                  | Vptr _ _ => True
                  | _ => False
                  end
      : val -> Prop *)
entailer!.
Qed.

Lemma data_at_isptr_example2:
  forall (h y p : val) ,
   data_at Tsh t_list (h,y) p |-- !! isptr p.
Proof.
intros.
saturate_local.
apply prop_right.
Check field_compatible_isptr.
   (* : forall (t : type) (path : list gfield) (p : val),
       field_compatible t path p -> isptr p *)
eapply field_compatible_isptr; eauto.
Qed.
```

`Print isptr` 显示 `isptr p` 就是「`p` 是 `Vptr`」（真指针，非 NULL、非未定义、非浮点）。`entailer!` 一步搞定，拆开看它是三步：`saturate_local` 查 `saturate_local` 数据库，从左边每个空间合取项提取纯命题——`data_at Tsh t_list (h,y) p` 给出 `field_compatible t_list [] p`；`apply prop_right` 把右端的 `!!P` 变成目标 `P`（同时丢弃左端，这也是 `entailer!`「过于激进」的根源，下面马上反例）；`field_compatible_isptr` 说 `field_compatible` 蕴含 `isptr`，`eauto` 收工。

**反例一**：换成自定义谓词 `listrep`，没注册 Hint 时同样的结论 `entailer!` 证不出来——它会丢掉左端、留下一个无假设的不可证目标，只能 `Abort`：

```coq
Lemma listrep_facts_example:
 forall sigma p,
   listrep sigma p |-- !! (isptr p \/ p=nullval).
Proof.
intros.
entailer!.
Abort.

Lemma listrep_facts_example:
 forall sigma p,
   listrep sigma p |-- !! (isptr p \/ p=nullval).
Proof.
intros.
saturate_local.
Abort.
```

第二个版本单独跑 `saturate_local`：横线上方**什么都没有多出来**——数据库里根本没有关于 `listrep` 的条目。修法是按惯例证明一条名为 `f_local_facts` 的引理，把谓词能导出的一切纯事实一次性写在右端，然后注册进数据库：

```coq
Lemma listrep_local_facts:
  forall sigma p,
   listrep sigma p |--
   !! (is_pointer_or_null p /\ (p=nullval <-> sigma=nil)).
Proof.
intros.
revert p; induction sigma; intros p.
- unfold listrep.
  entailer!.
  split; auto.
- unfold listrep; fold listrep.
  entailer.
  entailer!.
  split; intro.
  +
  clear - H H2.
  subst p.
Check field_compatible_isptr.
   (* : forall (t : type) (path : list gfield) (p : val),
       field_compatible t path p -> isptr p *)
Print isptr.
(* isptr =
   fun v : val => match v with
                  | Vptr _ _ => True
                  | _ => False
                  end
      : val -> Prop *)
Print nullval.
(* nullval = if Archi.ptr64 then Vlong Int64.zero else Vint Int.zero
      : val *)
Check field_compatible_nullval.
  (* = forall (CS : compspecs) (t : type) (f : list gfield) (P : Type),
       field_compatible t f nullval -> P *)
  eapply field_compatible_nullval; eauto.
 + inversion H2.
Qed.

#[export] Hint Resolve listrep_local_facts : saturate_local.
```

这条引理同时承载两个事实：`p` 要么是指针要么是 NULL（绝不会是 `Vundef`、`Vfloat` 这类怪物），以及「`p` 为 NULL 当且仅当序列为空」——后面证明收尾全靠这个iff。证明对 `sigma` 归纳：

- **基例**（`sigma = nil`）：`unfold listrep` 后左端就是 `!!(p=nullval)&&emp`，`entailer!` 把 `p = nullval` 提上线，剩下一个平凡的 `Prop`，`split; auto`。
- **归纳步**：`unfold listrep; fold listrep` 把 cons 情形展开一层再折回——分号在这里不是摆设，只 unfold 不 fold 的话，尾部那个 `listrep hs y` 也会摊开，归纳假设 `IHsigma` 就认不出它了。这里**必须**用不带感叹号的 `entailer`：左端有 `EX y`，温和的 `entailer` 会把它 Intro 成 `y` 放到线上；若用 `entailer!`，它看不懂存在量词、直接扔掉整个左端，后面全线崩溃（实测报错见 69.7 坑 3）。随后 `entailer!` 把 `data_at` 和归纳假设能导出的事实（`field_compatible t_list [] p`、`is_pointer_or_null y`、`y = nullval <-> sigma = []` 等）全部摆上横线，`split; intro` 分头证iff的两个方向：
  - `p = nullval -> a::sigma = nil`：此时线上 `H : field_compatible t_list [] p`（来自 data_at）与代入后的 `p = nullval`。`field_compatible_nullval` 的类型是 `field_compatible t f nullval -> P`——**任何**东西都能从「某类型的合法空指针字段」推出，因为 64 位下 `nullval = Vlong Int64.zero`（`Print nullval` 的输出）根本不是 `Vptr`，与 `field_compatible_isptr` 矛盾。`eapply field_compatible_nullval; eauto` 让 eauto 自动找到 `H` 完成爆炸。
  - `a::sigma = nil -> p = nullval`：`a :: sigma = []` 自身就是矛盾的，`inversion H2` 收工。

注册进 `saturate_local` 后，凡是横线上或断言里出现 `listrep sigma p`，`entailer!` 系战术都自动附带这两个事实。

第二个数据库 `valid_pointer` 同理。内置谓词直接可解，自定义谓词必须先证引理再注册：

```coq
Lemma struct_list_valid_pointer_example:
  forall h y p,
   data_at Tsh t_list (h,y) p |-- valid_pointer p.
Proof.
  intros.
  auto with valid_pointer.
Qed.

Lemma listrep_valid_pointer_example:
 forall sigma p,
   listrep sigma p |-- valid_pointer p.
Proof.
 intros.
 auto with valid_pointer.
Abort.

Lemma listrep_valid_pointer:
  forall sigma p,
    listrep sigma p |-- valid_pointer p.
Proof.
 intros.
 unfold listrep.
 destruct sigma; simpl.
- hint.
  entailer!.
- Intros y.
  auto with valid_pointer.
Qed.

#[export] Hint Resolve listrep_valid_pointer : valid_pointer.
```

**反例二**（第二个 `Abort`）再次演示：`auto with valid_pointer` 面对 `listrep` 一无所获——它不认识这个谓词。正解 `listrep_valid_pointer` 甚至不需要归纳：`unfold listrep` 后按 `sigma` 分情形。`nil` 情形 `entailer!` 借数据库里的空指针事实自动解掉（这里 `hint` 的建议就是 `entailer!`）；`cons` 情形用 `Intros y` 把存在量词提上线，左端的 `data_at Tsh t_list (v,y) p` 足以让 `auto with valid_pointer` 自动匹配。注册之后，`while (v)` 这类指针比较的类型检查条件（`tc_expr`）才能被 `entailer!` 全自动通过——69.5 的第二个子目标就靠它。

### 69.4 reverse 的函数规格

```coq
(* 69.4 reverse 的函数规格 reverse_spec 与 Gprog *)

Definition reverse_spec : ident * funspec :=
 DECLARE _reverse
  WITH sigma : list val, p: val
  PRE  [ tptr t_list ]
     PROP ()  PARAMS (p)  SEP (listrep sigma p)
  POST [ (tptr t_list) ]
    EX q:val,
     PROP ()  RETURN (q)  SEP (listrep(rev sigma) q).

Definition Gprog : funspecs := [ reverse_spec ].
```

规格即「调用前 `p` 处有一条表示 `sigma` 的链表；返回后某个 `q` 处有一条表示 `rev sigma` 的链表」。`WITH` 绑定的 `sigma`、`p` 在前后置条件里都可见；`PRE [tptr t_list]` 声明参数类型是结构体指针，`PARAMS (p)` 给出参数值，`SEP (listrep sigma p)` 给出内存资源；`POST` 用 `EX q` 承诺存在返回值，`RETURN (q)` 声明它就是返回的指针。内存资源进出相等（没有 malloc/free），变的只是 **tail 指针的接法**，所以断言内容从 `sigma` 变成了 `rev sigma`——就地反转的全部语义就浓缩在这一个 `rev` 里。`Gprog` 按惯例收编全部函数规格，本章只有一个（69.1 已说明为什么不收 `sumlist`/`main`）。

### 69.5 主定理 body_reverse：循环不变式与符号执行

```coq
(* 69.5 主定理 body_reverse：循环不变式与符号执行 *)

Lemma body_reverse: semax_body Vprog Gprog f_reverse reverse_spec.
Proof.
start_function.
forward.  (* w = NULL; *)
forward.  (* v = p; *)
Fail forward.
forward_while
   (EX s1: list val, EX s2 : list val,
    EX w: val, EX v: val,
     PROP (sigma = rev s1 ++ s2)
     LOCAL (temp _w w; temp _v v)
     SEP (listrep s1 w; listrep s2 v)).
- hint.
Exists (@nil val) sigma nullval p.
entailer!.
unfold listrep.
entailer!.
- hint.
entailer!.
- hint.
Fail forward.
destruct s2 as [ | h r].
 + unfold listrep at 2.
   Intros.
   subst. contradiction.
 + unfold listrep at 2; fold listrep.
   Intros y.
   forward. (* t = v->tail *)
   forward. (* v->tail = w; *)
   forward. (* w = v; *)
   forward. (* v = t; *)
   entailer!.
   Exists (h::s1,r,v,y).
   entailer!.
   * simpl. rewrite app_ass. auto.
   * unfold listrep at 3; fold listrep.
     Exists w. entailer!.
- forward.
Exists w; entailer!.
rewrite (proj1 H1) by auto.
unfold listrep at 2; fold listrep.
entailer!.
rewrite app_nil_r, rev_involutive.
auto.
Qed.
```

`start_function` 把 `semax_body` 打开成 Hoare 三元组。前两步 `forward` 穿过 `w = NULL;` 和 `v = p;`（最强后条件的符号执行，每步过后 LOCAL 里多出 `temp _w ...`、`temp _v p`）。第三条语句是 `while`，`forward` 不会走循环——硬走实测报错（69.7 坑 1），所以原书写 `Fail forward.` 把失败固化成文档；正确姿势是 `forward_while`，**必须**显式提供循环不变式。本循环的每次迭代状态由四个量刻画，不变式就是一个四重存在：

- `s1`、`s2` 是数学序列，**`sigma = rev s1 ++ s2` 恒成立**——这就是「已反转前缀 + 未反转后缀」的精确刻画：`s1` 是已经反转好的部分（`rev s1` 是被换到表尾的顺序），`s2` 是还没动的部分，两者拼起来永远是原序列；
- `w`、`v` 是两个游标：`SEP` 里 `listrep s1 w` 说「`w` 处有一条表示已反转前缀的链表」（它的尾指针都已被改写），`listrep s2 v` 说「`v` 处是未反转后缀」；`LOCAL` 把不变式接到 C 变量 `_w`、`_v` 上。

`forward_while` 留下四个子目标（用 `-` 子弹分隔）：

**子目标 1：当前前置条件蕴含不变式。** 进入循环前 `w = NULL`、`v = p`，所以已反转前缀为空：`Exists (@nil val) sigma nullval p` 依次给出 `s1 = []`、`s2 = sigma`、`w = nullval`、`v = p` 四个实例。`entailer!` 化简后只剩 `emp |-- listrep [] nullval` 这种自定义谓词残项，按惯例 `unfold listrep` 再 `entailer!`：定义说空表就是 `p = nullval` 且足迹 `emp`，恰好吻合。

**子目标 2：循环测试类型检查（不崩溃）。** 循环条件是 `while (v)`——对指针 `v` 做布尔测试，C 语义要求 `v` 是合法指针。右端是 `tc_expr Delta (v)`，这里横线上的 `is_pointer_or_null v` 不够，还需要 `valid_pointer v`。`entailer!` 能全自动通过，正是因为 69.3 注册的 `listrep_valid_pointer` 让 `listrep s2 v` 自动兑换出 `valid_pointer v`——删掉那行 Hint 注册，这个子目标立刻解不动（实测报错见 69.7 坑 6）。

**子目标 3：循环体保持不变式。** 进循环体时线上已有 `HRE : isptr v`（测试为真的方向）与 `H : sigma = rev s1 ++ s2`。第一句 `t = v->tail;` 就 `Fail forward`：穿过 `->tail` 字段解引用需要在 SEP 里找到 `data_at _ t_list _ v`，而现在只有一个整体的 `listrep s2 v`，结点资源藏在谓词内部。于是对 `s2` 分情形：

- **`s2 = nil`**：`unfold listrep at 2` 只展开第二个 `listrep`（`at 2` 是目标里的第 2 个出现），得到 `v = nullval`，`Intros` 把它提上线后与 `HRE : isptr v` 直接矛盾——`subst; contradiction`。这也演示了 local_facts 的实际用途：进入非空情形前，必须先排除空表。
- **`s2 = h::r`**：`unfold listrep at 2; fold listrep` 展开一层恰好露出头结点再折回，SEP 里现在躺着 `data_at Tsh t_list (h,y) v`（`y` 由 `Intros y` 从 `EX` 提出），`forward` 连穿四句：`t = v->tail` 读出 `y`；`v->tail = w` 把该结点的尾指针从 `y` 改写成 `w`——SEP 里那一项随之变成 `data_at Tsh t_list (h,w) v`，**其余合取项（尤其 `listrep s1 w`）纹丝不动，这就是分离合取的功劳**，69.6 专门展开这一点；`w = v`、`v = t` 移动游标。

  循环体末尾要重新建立不变式。`entailer!` 清理后 `Exists (h::s1,r,v,y)` 给出新实例：`s1' = h::s1`（`h` 已加入已反转前缀）、`s2' = r`、`w' = v`、`v' = y`。再 `entailer!` 后剩两条：纯命题侧 `rev (h::s1) ++ r = rev s1 ++ h :: r`——`simpl` 把 `rev (h::s1)` 摊成 `rev s1 ++ [h]`，`rewrite app_ass`（结合律）把左结合掰成右结合，`auto` 收尾；空间侧需要把「`v` 处指向 `w` 的 `h` 结点 + `listrep s1 w`」描述成「`listrep (h::s1) v`」——`unfold listrep at 3; fold listrep` 在右端第 3 个出现处展开一层留出 `EX` 的位置，`Exists w` 供给尾指针实例，`entailer!` 消去。

**子目标 4：出循环，收尾。** 实测目标形态（在 `Exists w; entailer!.` 之后用 `Show` 抓到的）是：

```text
  H0 : w = nullval <-> s1 = []
  H1 : nullval = nullval <-> s2 = []
  ============================
  listrep s1 w * listrep s2 nullval |-- listrep (rev (rev s1 ++ s2)) w
```

注意 `H0`、`H1` 就是 `entailer!` 的 `saturate_local` 借 69.3 的 local_facts Hint 自动挂上的两条iff；`v` 已被换成 `nullval`（循环测试取反的方向）。`forward` 穿过 `return w;` 并实例化返回值为 `w` 后，剩下「当前断言蕴含后置条件」：要证右端那条 `rev sigma` 的链表其实就是左端 `s1` 那条。`rewrite (proj1 H1) by auto` 用条件重写把 `s2` 清成 `[]`（`proj1 H1 : nullval = nullval -> s2 = []`，`by auto` 干掉前提）；`unfold listrep at 2; fold listrep` 把左端那个空表项摊开成 `emp` 交给 `entailer!` 消掉；最后横线上的纯等式只剩 `rev (rev s1 ++ []) = s1`，`rewrite app_nil_r, rev_involutive` 两步归约，`auto` 关门。

### 69.6 为什么需要分离逻辑

看完上面的证明，你可能觉得分离逻辑可有可无。本节用两个引理说明：「更新一个结点不影响其他结点」这种 C 指针程序的命脉事实，本质上就是分离合取的**地址反别名**推论。先看长度 ≥ 2 的链表展开后长什么样：

```coq
(* 69.6 为什么需要分离逻辑：地址反别名 *)

Lemma listrep_len_ge2_fact: forall (a b x: val) (l: list val),
  listrep (a :: b :: l) x |--
  EX y: val, EX z: val,
      data_at Tsh t_list (a,y) x *
      data_at Tsh t_list (b,z) y *
      listrep l z.
Proof.
  intros.
  unfold listrep; fold listrep.
  Intros y z.
  Exists y z.
  cancel.
Qed.
```

`listrep (a::b::l) x` 展开两层就露出两个相邻结点：`x` 处的 `a` 结点与 `y` 处的 `b` 结点由 `*` 分隔。`*` 的直接推论是这两个地址必须不同，否则一块内存被 `data_at` 描述了两次，违反资源的「不重叠」公理：

```coq
Lemma listrep_len_ge2_address_different: forall (a b x y z: val) (l: list val),
  data_at Tsh t_list (a,y) x *
  data_at Tsh t_list (b,z) y *
  listrep l z |--
  !! (x <> y).
Proof.
  intros.
  Check data_at_conflict.
    (* : forall (sh : Share.t) (t : type) (v v' : reptype t) (p : val),
         sepalg.nonidentity sh ->
         0 < sizeof t -> data_at sh t v p * data_at sh t v' p |-- FF *)
  destruct (Val.eq x y); [| apply prop_right; auto].
  subst x.
  sep_apply (data_at_conflict Tsh t_list (a, y)).
  + auto.
  + entailer!.
Qed.
```

证明先对 `x = y` 做情形分析：`x <> y` 时右端的纯命题 `x <> y` 由 `prop_right; auto` 直接给。`x = y` 时（`subst x` 代入），左端前两个合取项变成同一地址上的两个 `data_at`，`Check data_at_conflict` 显示的那条引理说：非空份额下，同一地址的两个 `data_at` 合取蕴含假（`FF`）——这就是从 `*` 提取地址反别名的标准武器。`sep_apply (data_at_conflict Tsh t_list (a, y))` 把它应用到左端（两个子目标分别是份额非空与尺寸为正，都与 `t_list` 和 `Tsh` 无关，`auto`/`entailer!` 各自解决），左端一旦化成 `FF`，任何右端都蕴含。

而且「`x ≠ y`」其实**还不够强**：完整的反别名要求是 `x` 不与 `y` 的**任何字段**重叠（比如 `x != &(y->tail)`），否则写 `y->tail` 时无法保证 `x->head` 没被波及。分离逻辑把这些全部打包进了 `*` 的语义；若不使用它，就得为长度 n 的链表手写约 n² 量级的两两地址不等式。69.5 循环体里 `v->tail = w` 一步只动一个 `data_at` 合取项、其余空间断言原样保留，靠的正是这个打包。

最后盘点全章证明的公理足迹：

```coq
Print Assumptions body_reverse.
(* Axioms:
   ClassicalDedekindReals.sig_not_dec : forall P : Prop, {~ ~ P} + {~ P}
   ClassicalDedekindReals.sig_forall_dec :
     forall P : nat -> Prop,
     (forall n : nat, {P n} + {~ P n}) ->
     {n : nat | ~ P n} + {forall n : nat, P n}
   prop_ext : ClassicalFacts.prop_extensionality
   functional_extensionality_dep :
     forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
     (forall x : A, f x = g x) -> f = g
   Eqdep.Eq_rect_eq.eq_rect_eq :
     forall (U : Type) (p : U) (Q : U -> Type) (x : Q p) (h : p = p),
     x = eq_rect p Q x p h
   Classical_Prop.classic : forall P : Prop, P \/ ~ P
   Ensembles.Extensionality_Ensembles :
     forall (U : Type) (A B : Ensembles.Ensemble U),
     Ensembles.Same_set A B -> A = B *)
```

不是「Closed under the global context」——这是 VST 的正常状态：这些公理（经典逻辑、命题/函数外延、类型化等式消除等）来自 VST 依赖的 CompCert 与泛函外延库，是 VST 声音性定理的标准假设集，不是本证明引入的新公理。整条证明没有 `Admitted`，每个引理都 `Qed`。

### 69.7 本章坑位清单（实测）

以下每条都在 rocq 9.1.1 + stdlib 9.0.0 + VST 2.16 上实测复现（改 `examples/69_list_reverse.v` 对应行后编译抓取的原始报错）。

1. **`while` 循环前直接 `forward`**（69.5）：删掉 `Fail`，在 `v = p;` 后直接 `forward`，实测报：
   ```text
   Error:
   Tactic failure: Use [forward_while Inv] to prove this loop, where Inv is the loop invariant.
   ```
2. **不拆 `s2` 就穿过 `t = v->tail;`**（69.5）：循环体里 `listrep s2 v` 没展开时直接 `forward`，实测报：
   ```text
   Error:
   Tactic failure:
   It is not obvious how to move forward here.  One way:
   Find a SEP clause of the form [data_at _ _ _ ?p] (or field_at, data_at_, field_at_),
   then use assert_PROP to prove an equality of the form
   (offset_val 8 v = field_address ?t ?gfs ?p) ...
   ```
   这正是 `hint` 预告的那句 "the definition [listrep] needs to be unfolded" 的完整版——先 `destruct s2`、再 `unfold listrep at 2`、`Intros y` 把结点资源露出来。
3. **归纳步用 `entailer!` 代替 `entailer`**（69.3）：`listrep_local_facts` cons 情形左端带 `EX y`，`entailer!` 会整个扔掉左端、把目标变成纯命题，跟着的第二个 `entailer!` 实测报：
   ```text
   Error:
   Tactic failure: The entailer tactic works only on entailments  _ |-- _ .
   ```
   带存在量词的左端先用温和的 `entailer`（自动 Intro 存在变量），确认没走死路后再上 `entailer!`。
4. **`Exists` 元组写反**：循环体收尾把实例写成 `Exists (h::s1,v,r,y).`（`v`、`r` 对调），实测在该行报：
   ```text
   Error: No applicable tactic.
   ```
   `Exists` 是 Ltac 包装的类型不敏感报错，不直观——记住 `forward_while` 把不变式的四个存在量词压成一个四元组，顺序就是声明顺序 `(s1, s2, w, v)`。
5. **`auto with valid_pointer` 没解完就 `Qed`**（69.3）：没注册 Hint 前 `auto with valid_pointer` 解不动 `listrep`，此时 `Qed` 实测报：
   ```text
   Error:
   (in proof listrep_valid_pointer_example): Attempt to save an incomplete proof
   (there are remaining open goals).
   ```
6. **忘记 `Hint Resolve ... : valid_pointer`**（69.3/69.5）：删掉注册行后，`forward_while` 的第二个子目标（循环测试类型检查）`entailer!` 解不动，报错位置落在下一个子弹上，实测报：
   ```text
   File "./69_list_reverse.v", line 173, characters 0-1:
   Error: [Focus] Wrong bullet -: Current bullet - is not finished.
   ```
   `Wrong bullet` 的根源往往在上一个子弹里——`entailer!` 静默留下未证目标时不会自己报错。

---
上一章：[68 · VST 入门：数组求和的第一个验证](68-vst-intro.md) ｜ 下一章：[70 · 列表段](70-lseg.md) ｜ 返回：[README](../README.md)
