# 08 · 错误单子与解码

对应示例：`../examples/S08_error_monad.thy`

## 8.1 第二道门槛：错误单子

内核操作要么成功（`Inr`），要么返回一个错误码（`Inl`）。
把非确定性状态单子的结果类型换成 `'e + 'a`，就得到 seL4 的错误单子
（`l4v/spec/abstract/Exceptions_A.thy:32`）：

<!-- 源码块：l4v/spec/abstract/Exceptions_A.thy:32-32 -->
```text
type_synonym ('a,'z) se_monad = "(syscall_error + 'a,'z) s_monad"
```

`syscall_error` 的 datatype 在 `l4v/spec/abstract/ExceptionTypes_A.thy:40`，
十个构造子：`InvalidArgument`、`InvalidCapability`、`IllegalOperation`、
`RangeError`、`AlignmentError`、`FailedLookup`、`TruncatedMessage`、`DeleteFirst`、
`RevokeFirst`、`NotEnoughMemory`——**别以为能自己加**，
用户侧的 `seL4_Error`（`seL4/libsel4/include/sel4/errors.h`）与它**按编号**对应；
但两边的"形状"不一样：规范里有一半构造子是带数据的，见 8.7。

组合子：`returnOk`、`throwError`、`bindE`、`liftE`、`whenE`、`unlessE`。

## 8.2 短路：错误就是左值

```text
theorem bindE_throw_left: throwError ?e \<bind> ?f = throwError ?e
```

这就是"短路"：左边一旦出错，右边的 `f` 根本不执行。
它的对偶是"右端套一个 `returnOk` 是恒等变换"（实测）：

```text
theorem bindE_returnOk_right: ?m \<bind> returnOk = ?m
```

> 这条是本章最难证的一条：要证明两个单子**逐分量相等**。
> 可行做法是先证两个分别处理 `fst` 与 `snd` 的辅助引理，再用 `prod_eqI` 合起来。

## 8.3 一个真实的 decode 片段

`decode_*` 把用户传进来的一串机器字翻译成一次"调用请求"。顺序不能改（实测）：

```text
theorem
  decode_bad_label:
    ?label \<notin> valid_cnode_labels \<Longrightarrow>
    decode_head ?label ?args = throwError IllegalOperation
```

**先看标签，再看参数个数**。反过来写就会先读参数——而参数个数不够时读参数是越界访问。
真实解码器见 `l4v/spec/abstract/Decode_A.thy`（`decode_cnode_invocation` 从第 46 行起），
标签判定用的是**枚举区间** `set [CNodeRevoke .e. CNodeSaveCaller]`（第 50 行），
错误码枚举在 `seL4/libsel4/include/sel4/errors.h`。

## 8.4 错误不会污染状态

```text
theorem throw_keeps_state: (?r, ?s') \<in> fst (throwError ?e ?s) \<Longrightarrow> ?s' = ?s
```

出错的计算不会产生任何状态迁移。这条在高层次上支撑第 21 章的完整性定理：
**失败的系统调用不改变任何人能观察到的状态**。

## 8.5 把错误提升成故障（fault）

```text
theorem illegal_is_cap_fault: to_fault IllegalOperation = CapFault
```

seL4 里有三套"出错"的东西，别混：

| 类别 | 谁产生 | 后果 |
|---|---|---|
| error（`seL4_Error`） | 系统调用的参数/权利问题 | 返回错误码给用户 |
| fault | 线程触发了内核无法代劳的事 | 交给线程的 fault handler |
| 异常 | 硬件 | 走异常路径 |

规范的开头注释就是这么写的（`l4v/spec/abstract/ExceptionTypes_A.thy:21`，示意）：

<!-- 示意块：这是 ExceptionTypes_A.thy 第 19–26 行注释的节选（去掉了缩进），非构建产物 -->
```text
There are two types of exceptions that can occur in the kernel: faults and errors.
Faults are reported to the user's fault handler. Errors are reported to the user directly.
Capability lookup failures can be be either fault or error, depending on context.
```

第三句才是重点：`lookup_failure`（同文件第 28 行）是**第三种东西**，
它靠两个提升函数选边站——
`cap_fault_on_failure` 把它抬成 `CapFault`（`l4v/spec/abstract/Exceptions_A.thy:75`），
`lookup_error_on_failure` 把它抬成 `FailedLookup`（同文件第 78 行）。
所以真实规范里**不存在"error → fault"的映射函数**；
上面的 `to_fault` 只是模型用来演示"两种结局长得不一样"的简化品。

真实代码：`seL4/libsel4/include/sel4/errors.h`、
`l4v/spec/abstract/ExceptionTypes_A.thy`、`seL4/src/api/faults.c`。

## 8.6 五层单子：`se_monad` 只是其中一层

本章标题里的"错误单子"在规范里有个同族，五兄弟全写在文件开头那二十几行里
（`l4v/spec/abstract/Exceptions_A.thy`）：

<!-- 源码块：l4v/spec/abstract/Exceptions_A.thy:19-41 -->
```text

text \<open>The basic kernel monad without faults, interrupts, or errors.\<close>
type_synonym ('a,'z) s_monad = "('z state, 'a) nondet_monad"

text \<open>The fault monad: may throw a @{text fault} exception which
will usually be reported to the current thread's fault handler.\<close>
type_synonym ('a,'z) f_monad = "(fault + 'a,'z) s_monad"

term "a::(unit,'a) s_monad"

text \<open>The error monad: may throw a @{text syscall_error} exception
which will usually be reported to the current thread as system call
result.\<close>
type_synonym ('a,'z) se_monad = "(syscall_error + 'a,'z) s_monad"

text \<open>The lookup failure monad: may throw a @{text lookup_failure}
exception. Depending on context it may either be reported directly to
the current thread or to its fault handler.
\<close>
type_synonym ('a,'z) lf_monad = "(lookup_failure + 'a,'z) s_monad"

text \<open>The preemption monad. May throw an interrupt exception.\<close>
type_synonym ('a,'z) p_monad = "(unit + 'a,'z) s_monad"
```

五层底下都是第 07 章那个 `nondet_monad`，区别只在结果类型前面套了哪个异常：

| 别名 | 异常类型 | 谁用它 |
|---|---|---|
| `s_monad` | 无 | 已经把异常都处理完的计算 |
| `f_monad` | `fault` | 会把故障交给线程 fault handler 的路径 |
| `se_monad` | `syscall_error` | 本章主角：系统调用返回值 |
| `lf_monad` | `lookup_failure` | 能力查找，**还没决定站哪一边** |
| `p_monad` | `unit` | 抢占点，异常位只表示"可以被打断" |

`p_monad` 的异常类型是 `unit`，所以它不携带任何信息；把 `s_monad` 抬进 `p_monad`
的那个包装函数因此干脆没有函数体——`without_preemption`
的定义式就是 `liftE`（`l4v/spec/abstract/Exceptions_A.thy:58`）：

<!-- 源码块：l4v/spec/abstract/Exceptions_A.thy:54-58 -->
```text
text \<open>Perform non-preemptible operations within preemptible blocks.\<close>
definition
  without_preemption :: "('a,'z::state_ext) s_monad \<Rightarrow> ('a,'z::state_ext) p_monad"
where without_preemption_def[simp]:
 "without_preemption \<equiv> liftE"
```

也就是说"这一段不许抢占"在这层规范里**只是类型约束**，运行时什么也不做。
真正的抢占判断在 `preemption_point`（同文件第 61 行起），它检查工作量上限
与活跃中断，条件满足时抛的是 `throwError $ ()`——一个 `unit` 异常。

紧跟着五层定义还有一段只管打印的 `translations`（`l4v/spec/abstract/Exceptions_A.thy:47`）：

<!-- 源码块：l4v/spec/abstract/Exceptions_A.thy:44-52 -->
```text
text \<open>
  Printing abbreviations for the above types.
\<close>
translations
  (type) "'a s_monad" <= (type) "state \<Rightarrow> (('a \<times> state) \<Rightarrow> bool) \<times> bool"
  (type) "'a f_monad" <= (type) "(fault + 'a) s_monad"
  (type) "'a se_monad" <= (type) "(syscall_error + 'a) s_monad"
  (type) "'a lf_monad" <= (type) "(lookup_failure + 'a) s_monad"
  (type) "'a p_monad" <=(type) "(unit + 'a) s_monad"
```

第一行值得停一下：`s_monad` 被印成 `state ⇒ (('a × state) ⇒ bool) × bool`，
把第 07 章定义里的 `('a × 's) set` 写成了它的**成员判定**。这不是另一套表示——
Isabelle 里 `'a set` 本身就是 `'a ⇒ bool` 的记法，所以证明器看到的还是集合，
只是屏幕上像谓词。以为"结果集合"在真实规范里被换成了布尔函数，
是这一页最容易上当的地方。

### 为什么非要有 `bindE`：库里把理由写在了注释里

`returnOk`、`throwError`、`bindE` 不是新语法糖，而是因为类型类不够用
（`l4v/lib/Monads/nondet/Nondet_Monad.thy:241`）：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:241-251 -->
```text
  This new type itself forms a monad again. Since type classes in
  Isabelle are not powerful enough to express the class of monads,
  we provide new names for the @{term return} and @{term bind} functions
  in this monad. We call them @{text returnOk} (for normal return values)
  and @{text bindE} (for composition). We also define @{text throwError}
  to return an exceptional value.\<close>
definition returnOk :: "'a \<Rightarrow> ('s, 'e + 'a) nondet_monad" where
  "returnOk \<equiv> return o Inr"

definition throwError :: "'e \<Rightarrow> ('s, 'e + 'a) nondet_monad" where
  "throwError \<equiv> return o Inl"
```

`returnOk` 与 `throwError` 就是 `return o Inr` 和 `return o Inl`，
所以 8.2 那条"短路"定理在真实库里同样是定义级的展开。`bindE` 本体只是
"普通 `bind` 外面套一个 `case`"（`lift` 与 `bindE` 在同一页，
`l4v/lib/Monads/nondet/Nondet_Monad.thy:266`）：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:253-266 -->
```text
text \<open>
  Lifting a function over the exception type: if the input is an
  exception, return that exception; otherwise continue execution.\<close>
definition lift :: "('a \<Rightarrow> ('s, 'e + 'b) nondet_monad) \<Rightarrow> 'e +'a \<Rightarrow> ('s, 'e + 'b) nondet_monad" where
  "lift f v \<equiv> case v of Inl e \<Rightarrow> throwError e | Inr v' \<Rightarrow> f v'"

text \<open>
  The definition of @{term bind} in the exception monad (new
  name @{text bindE}): the same as normal @{term bind}, but
  the right-hand side is skipped if the left-hand side
  produced an exception.\<close>
definition bindE ::
  "('s, 'e + 'a) nondet_monad \<Rightarrow> ('a \<Rightarrow> ('s, 'e + 'b) nondet_monad) \<Rightarrow> ('s, 'e + 'b) nondet_monad"
  (infixl ">>=E" 60) where
```

`lift` 遇到 `Inl` 就原样 `throwError`，遇到 `Inr` 才调右边的函数——
"短路"这件事的全部实现就是那三行 `case`。

### 三种"处理掉异常"的算子，区别只在留不留在单子里

8.5 那六个提升函数用的其实就是三个算子，第一个是 `catch`
（`l4v/lib/Monads/nondet/Nondet_Monad.thy:523`）：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:523-531 -->
```text
definition catch ::
  "('s, 'e + 'a) nondet_monad \<Rightarrow> ('e \<Rightarrow> ('s, 'a) nondet_monad) \<Rightarrow> ('s, 'a) nondet_monad"
  (infix "<catch>" 10) where
  "f <catch> handler \<equiv>
     do x \<leftarrow> f;
        case x of
          Inr b \<Rightarrow> return b
        | Inl e \<Rightarrow> handler e
     od"
```

另两个是 `handleE'` 与它的同型特化 `handleE`（后者定义就是一行
`handleE ≡ handleE'`，同文件第 555 行）：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:537-546 -->
```text
definition handleE' ::
  "('s, 'e1 + 'a) nondet_monad \<Rightarrow> ('e1 \<Rightarrow> ('s, 'e2 + 'a) nondet_monad) \<Rightarrow> ('s, 'e2 + 'a) nondet_monad"
  (infix "<handle2>" 10) where
  "f <handle2> handler \<equiv>
   do
      v \<leftarrow> f;
      case v of
        Inl e \<Rightarrow> handler e
      | Inr v' \<Rightarrow> return (Inr v')
   od"
```

| 算子 | 记法 | 结果还在错误单子里吗 | 能不能换异常类型 |
|---|---|---|---|
| `catch` | `<catch>` | 否，降到普通单子 | —— |
| `handleE'` | `<handle2>` | 是 | 能（`'e1 → 'e2`） |
| `handleE` | `<handle>` | 是 | 不能 |

把五个提升函数按算子排一下，8.5 那句"选边站"就有了具体形状。领衔的
`cap_fault_on_failure` 起手的这一串在（`l4v/spec/abstract/Exceptions_A.thy:73`）：

<!-- 源码块：l4v/spec/abstract/Exceptions_A.thy:71-95 -->
```text
text \<open>Lift one kind of exception monad into another by converting the error
into various other kinds of error or return value.\<close>
definition
  cap_fault_on_failure :: "obj_ref \<Rightarrow> bool \<Rightarrow> ('a,'z::state_ext) lf_monad \<Rightarrow> ('a,'z::state_ext) f_monad" where
 "cap_fault_on_failure cptr rp m \<equiv> handleE' m (throwError \<circ> CapFault cptr rp)"

definition
  lookup_error_on_failure ::  "bool \<Rightarrow> ('a,'z::state_ext) lf_monad \<Rightarrow> ('a,'z::state_ext) se_monad" where
 "lookup_error_on_failure s m \<equiv> handleE' m (throwError \<circ> FailedLookup s)"

definition
  null_cap_on_failure :: "(cap,'z::state_ext) lf_monad \<Rightarrow> (cap,'z::state_ext) s_monad" where
 "null_cap_on_failure \<equiv> liftM (case_sum (\<lambda>x. NullCap) id)"

definition
  unify_failure :: "('f + 'a,'z::state_ext) s_monad \<Rightarrow> (unit + 'a,'z::state_ext) s_monad" where
 "unify_failure m \<equiv> handleE' m (\<lambda>x. throwError ())"

definition
  empty_on_failure :: "('f + 'a list,'z::state_ext) s_monad \<Rightarrow> ('a list,'z::state_ext) s_monad" where
 "empty_on_failure m \<equiv> m <catch> (\<lambda>x. return [])"

definition
  const_on_failure :: "'a \<Rightarrow> ('f + 'a,'z::state_ext) s_monad \<Rightarrow> ('a,'z::state_ext) s_monad" where
 "const_on_failure c m \<equiv> m <catch> (\<lambda>x. return c)"
```

`cap_fault_on_failure`、`lookup_error_on_failure`、`unify_failure` 走 `handleE'`
（换异常类型或把它抹平），`empty_on_failure`、`const_on_failure` 走 `<catch>`
（彻底出单子，给一个普通返回值），`null_cap_on_failure` 连 handler 都不写，
直接 `liftM case_sum`——因为它的"出错"分支要返回一个**值**（`NullCap`），
而不是抛另一个异常。

---

## 8.7 `syscall_error` 带数据：错误码走 label，数据走消息寄存器

8.1 说"十个构造子"是省事的说法；真实的 `syscall_error`
（`l4v/spec/abstract/ExceptionTypes_A.thy:40`）里有五个构造子是**带参数的**：

<!-- 源码块：l4v/spec/abstract/ExceptionTypes_A.thy:40-50 -->
```text
datatype syscall_error
         = InvalidArgument nat
         | InvalidCapability nat
         | IllegalOperation
         | RangeError data data
         | AlignmentError
         | FailedLookup bool lookup_failure
         | TruncatedMessage
         | DeleteFirst
         | RevokeFirst
         | NotEnoughMemory data
```

带参数的原因是：光一个数字不够用户定位问题。`RangeError` 要把上下界都告诉调用者，
`FailedLookup` 还要带上"是不是源能力"这个布尔值和一次完整的 `lookup_failure`。
于是规范里有一对把异常编码成消息寄存器的递归函数，`msg_from_syscall_error`
（`l4v/spec/abstract/ExceptionTypes_A.thy:63`）是后一个：

<!-- 源码块：l4v/spec/abstract/ExceptionTypes_A.thy:52-74 -->
```text
text \<open>Create a message from a system-call failure to be returned to the
thread attempting the operation that failed.\<close>
primrec
  msg_from_lookup_failure :: "lookup_failure \<Rightarrow> data list"
where
  "msg_from_lookup_failure InvalidRoot           = [1]"
| "msg_from_lookup_failure (MissingCapability n) = [2, of_nat n]"
| "msg_from_lookup_failure (DepthMismatch n m)   = [3, of_nat n, of_nat m]"
| "msg_from_lookup_failure (GuardMismatch n g)   = [4, of_nat n, of_bl g, of_nat (size g)]"

primrec
  msg_from_syscall_error :: "syscall_error \<Rightarrow> (data \<times> data list)"
where
  "msg_from_syscall_error (InvalidArgument n)    = (1, [of_nat n])"
| "msg_from_syscall_error (InvalidCapability n)  = (2, [of_nat n])"
| "msg_from_syscall_error IllegalOperation       = (3, [])"
| "msg_from_syscall_error (RangeError minv maxv) = (4, [minv, maxv])"
| "msg_from_syscall_error AlignmentError         = (5, [])"
| "msg_from_syscall_error (FailedLookup s lf)    = (6, [if s then 1 else 0]@(msg_from_lookup_failure lf))"
| "msg_from_syscall_error TruncatedMessage       = (7, [])"
| "msg_from_syscall_error DeleteFirst            = (8, [])"
| "msg_from_syscall_error RevokeFirst            = (9, [])"
| "msg_from_syscall_error (NotEnoughMemory n)    = (10, [n])"
```

返回类型是 `data × data list`：第一个分量是**标签**，列表是**追加的 extra MR**。
标签恰好是 1 到 10，跟 C 侧枚举的**书写顺序**一致——`seL4_NoError`
之后的十项靠 C 的隐式取值排到 1..10（`seL4/libsel4/include/sel4/errors.h:9`）：

<!-- 源码块：seL4/libsel4/include/sel4/errors.h:9-26 -->
```text
typedef enum {
    seL4_NoError = 0,
    seL4_InvalidArgument,
    seL4_InvalidCapability,
    seL4_IllegalOperation,
    seL4_RangeError,
    seL4_AlignmentError,
    seL4_FailedLookup,
    seL4_TruncatedMessage,
    seL4_DeleteFirst,
    seL4_RevokeFirst,
    seL4_NotEnoughMemory,

    /* This should always be the last item in the list
     * so it gives a count of the number of errors in the
     * enum.
     */
    seL4_NumErrors
```

所以 8.1 那句"`seL4_Error` 与它逐项对应"要说得更准：**对应的是编号，不是形状**。
C 侧的枚举是纯数字，携带的数据放在别处（见下）。两边真正对上的是这张表：

| HOL 构造子 | `msg_from_syscall_error` 给的 `(label, MR)` | C 侧写 MR 的个数 |
|---|---|---|
| `InvalidArgument n` | `(1, [n])` | 1 |
| `RangeError min max` | `(4, [min, max])` | 2 |
| `IllegalOperation` | `(3, [])` | 0 |
| `FailedLookup s lf` | `(6, [s ? 1 : 0] @ msg_from_lookup_failure lf)` | 1 + 查找失败那几个 |
| `NotEnoughMemory n` | `(10, [n])` | 1 |

C 侧的执行者叫 `setMRs_syscall_error`（`seL4/src/object/tcb.c:2079`），
它 switch 的正是上面那十个枚举值：

<!-- 源码块：seL4/src/object/tcb.c:2079-2118 -->
```text
word_t setMRs_syscall_error(tcb_t *thread, word_t *receiveIPCBuffer)
{
    switch (current_syscall_error.type) {
    case seL4_InvalidArgument:
        return setMR(thread, receiveIPCBuffer, 0,
                     current_syscall_error.invalidArgumentNumber);

    case seL4_InvalidCapability:
        return setMR(thread, receiveIPCBuffer, 0,
                     current_syscall_error.invalidCapNumber);

    case seL4_IllegalOperation:
        return 0;

    case seL4_RangeError:
        setMR(thread, receiveIPCBuffer, 0,
              current_syscall_error.rangeErrorMin);
        return setMR(thread, receiveIPCBuffer, 1,
                     current_syscall_error.rangeErrorMax);

    case seL4_AlignmentError:
        return 0;

    case seL4_FailedLookup:
        setMR(thread, receiveIPCBuffer, 0,
              current_syscall_error.failedLookupWasSource ? 1 : 0);
        return setMRs_lookup_failure(thread, receiveIPCBuffer,
                                     current_lookup_fault, 1);

    case seL4_TruncatedMessage:
    case seL4_DeleteFirst:
    case seL4_RevokeFirst:
        return 0;
    case seL4_NotEnoughMemory:
        return setMR(thread, receiveIPCBuffer, 0,
                     current_syscall_error.memoryLeft);
    default:
        fail("Invalid syscall error");
    }
}
```

注意最后三行 `default: fail(...)`——**编译器不会因为漏了 case 而报错**，
漏掉的那一路会走到 `fail`，所以这张对照表只有"读代码 + 跑测试"这一种证法。
同一个文件里那几条 `compile_assert` 才是机器裁判（`seL4/src/api/faults.c:19`）：

<!-- 源码块：seL4/src/api/faults.c:19-23 -->
```text
/* consistency with libsel4 */
compile_assert(InvalidRoot, lookup_fault_invalid_root + 1 == seL4_InvalidRoot)
compile_assert(MissingCapability, lookup_fault_missing_capability + 1 == seL4_MissingCapability)
compile_assert(DepthMismatch, lookup_fault_depth_mismatch + 1 == seL4_DepthMismatch)
compile_assert(GuardMismatch, lookup_fault_guard_mismatch + 1 == seL4_GuardMismatch)
```

这几行断言的是"内核内部的 `lookup_fault_*` 枚举 + 1 恰好等于 libsel4 的
`seL4_*` 常量"，也就是说 `msg_from_lookup_failure` 那 1..4 的编号在编译期就被钉住了；
写 MR 的那一句同样带 `+ 1`（同文件第 35 行）。libsel4 侧的枚举
`seL4_LookupFailureType` 在（`seL4/libsel4/include/sel4/constants.h:63`）：

<!-- 源码块：seL4/libsel4/include/sel4/constants.h:63-70 -->
```text
typedef enum {
    seL4_NoFailure = 0,
    seL4_InvalidRoot,
    seL4_MissingCapability,
    seL4_DepthMismatch,
    seL4_GuardMismatch,
    SEL4_FORCE_LONG_ENUM(seL4_LookupFailureType),
} seL4_LookupFailureType;
```

最后是 label 真正被写进寄存器的那一处，`replyFromKernel_error`
（`seL4/src/object/endpoint.c:299`）：

<!-- 源码块：seL4/src/object/endpoint.c:299-318 -->
```text
void replyFromKernel_error(tcb_t *thread)
{
    word_t len;
    word_t *ipcBuffer;

    ipcBuffer = lookupIPCBuffer(true, thread);
    setRegister(thread, badgeRegister, 0);
    len = setMRs_syscall_error(thread, ipcBuffer);

#ifdef CONFIG_KERNEL_INVOCATION_REPORT_ERROR_IPC
    char *debugBuffer = (char *)(ipcBuffer + DEBUG_MESSAGE_START + 1);
    word_t add = strlcpy(debugBuffer, (char *)current_debug_error.errorMessage,
                         DEBUG_MESSAGE_MAXLEN * sizeof(word_t));

    len += (add / sizeof(word_t)) + 1;
#endif

    setRegister(thread, msgInfoRegister, wordFromMessageInfo(
                    seL4_MessageInfo_new(current_syscall_error.type, 0, 0, len)));
}
```

`seL4_MessageInfo_new(current_syscall_error.type, 0, 0, len)` 就是"错误码当标签、
数据当 `len` 个 extra MR"。用户侧读回来时走的是同一套通道，
`seL4_getFault` 的第一个动作就是 `seL4_MessageInfo_get_label`
（`seL4/libsel4/include/sel4/faults.h:13`）。

### 为什么 C 侧不用 sum type

规范里 `syscall_error` 是代数数据类型，C 里却是一个"全字段结构 + 一个 type 标签"：
`struct syscall_error`（`seL4/include/api/failures.h:27`）。文件开头那行注释
连"和 Haskell 差得远"都写明了（同文件第 12 到 13 行）：

<!-- 源码块：seL4/include/api/failures.h:12-37 -->
```text
/* These datatypes differ markedly from haskell, due to the
 * different implementation of the various fault monads */


enum exception {
    EXCEPTION_NONE,
    EXCEPTION_FAULT,
    EXCEPTION_LOOKUP_FAULT,
    EXCEPTION_SYSCALL_ERROR,
    EXCEPTION_PREEMPTED
};
typedef word_t exception_t;

typedef word_t syscall_error_type_t;

struct syscall_error {
    word_t invalidArgumentNumber;
    word_t invalidCapNumber;
    word_t rangeErrorMin;
    word_t rangeErrorMax;
    word_t memoryLeft;
    bool_t failedLookupWasSource;

    syscall_error_type_t type;
};
typedef struct syscall_error syscall_error_t;
```

`enum exception` 那五项（同文件第 16 行）值得单独记：C 内核把"这次调用怎么结束的"
统一成一个 `exception_t`，`EXCEPTION_SYSCALL_ERROR` 与 `EXCEPTION_FAULT` 是
**两个不同的值**，分别对应规范里的 `se_monad` 与 `f_monad`。第 07、08 章讲的
"多层单子"在 C 里被摊平成这一个 enum 加几个全局变量（`current_fault`、
`current_syscall_error`、`current_lookup_fault`，同文件末尾三行 `extern`）。

---

## 8.8 `no_throw`：错误单子里"不出错"是**两条**后置条件

第 07 章的坑位 4 说"`no_fail` 不等于结果非空"。到了错误单子里，
"不出错"又是另一个概念 `no_throw`
（`l4v/lib/Monads/nondet/Nondet_No_Throw.thy:19`）：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_No_Throw.thy:19-27 -->
```text
text \<open>
  The predicates @{text no_throw} and @{text no_return} allow us to reason about functions in
  the exception monad that never throw an exception or never return normally.\<close>

definition no_throw :: "('s \<Rightarrow> bool) \<Rightarrow> ('s, 'e + 'a) nondet_monad \<Rightarrow> bool" where
  "no_throw P A \<equiv> \<lbrace>P\<rbrace> A \<lbrace>\<lambda>_ _. True\<rbrace>, \<lbrace>\<lambda>_ _. False\<rbrace>"

definition no_return :: "('a \<Rightarrow> bool) \<Rightarrow> ('a, 'b + 'c) nondet_monad \<Rightarrow> bool" where
  "no_return P A \<equiv> \<lbrace>P\<rbrace> A \<lbrace>\<lambda>_ _. False\<rbrace>, \<lbrace>\<lambda>_ _. True\<rbrace>"
```

区别在于 Hoare 三元组在这里带**两个**后置条件：一个管正常返回，一个管抛出的异常。
`no_throw` 是"正常返回什么都不保证（`True`），异常分支绝不可能（`False`）"；
`no_return` 正好反过来。两条一起读，才能理解第 07 章那份
`l4v/lib/Monads/README.md` 上的口诀为什么要分三个词：`empty_fail`、`no_fail`、
`no_throw`。

还有一个不对称容易踩：`no_throw` 的前置条件类型是 `'s ⇒ bool`（状态上的谓词），
而 `no_return` 写的是 `'a ⇒ bool`——它约束的是**返回值**。
把两者的前置条件当成同一种东西，展开定义时就对不上。

---

## 8.9 `range_check`：一条 `unlessE`，为什么错误里要带上下界

8.7 说 `RangeError` 带两个数据，实现它的最短路径就是这个工具函数
（`l4v/spec/abstract/Exceptions_A.thy:97`）：

<!-- 源码块：l4v/spec/abstract/Exceptions_A.thy:97-103 -->
```text
text \<open>Checks whether first argument is between second and third (inclusive).\<close>

definition
  range_check :: "machine_word \<Rightarrow> machine_word \<Rightarrow> machine_word \<Rightarrow> (unit,'z::state_ext) se_monad"
where
  "range_check v min_v max_v \<equiv>
    unlessE (v \<ge> min_v \<and> v \<le> max_v) $ throwError $ RangeError min_v max_v"
```

一行里三件事：用 `unlessE`（条件不成立才执行）、闭区间（`≥` 和 `≤`）、
把 `min_v`/`max_v` 原封不动塞进错误。除了定义本身，`l4v` 里还有 12 处调用，
架构相关的那几处校验的是中断号，例如 `range_check`
（`l4v/spec/abstract/ARM/ArchDecode_A.thy:306`）。
最典型的一处就在解码器里，`decode_read_registers` 的开头就是它
（`l4v/spec/abstract/Decode_A.thy:150`）：

<!-- 源码块：l4v/spec/abstract/Decode_A.thy:150-161 -->
```text
definition
  decode_read_registers :: "data list \<Rightarrow> cap \<Rightarrow> (tcb_invocation,'z::state_ext) se_monad"
where
"decode_read_registers data cap \<equiv> case data of
  flags#n#_ \<Rightarrow> doE
    range_check n 1 $ of_nat (length frameRegisters + length gpRegisters);
    p \<leftarrow> case cap of ThreadCap p \<Rightarrow> returnOk p;
    self \<leftarrow> liftE $ gets cur_thread;
    whenE (p = self) $ throwError IllegalOperation;
    returnOk $ ReadRegisters p (flags !! 0) n ArchDefaultExtraRegisters
  odE
| _ \<Rightarrow> throwError TruncatedMessage"
```

对着它重读 8.3，会得到三点修正过的认识：

1. **"先看参数够不够"不是靠 `if` 做的**，而是靠 `case data of flags#n#_` 模式匹配——
   参数不够时走的是最后那条 `| _ ⇒ throwError TruncatedMessage`，
   `range_check` 那一行根本不会被执行。顺序是数据形状保证的，不是判断语句保证的。
2. `whenE (p = self) $ throwError IllegalOperation`：想读自己的寄存器会被直接拒绝。
   同一层解码里既有"范围"检查也有"身份"检查，两种错误码不同。
3. 解码函数返回的是 `tcb_invocation`，也就是"这次调用要做的事"，
   而它整个类型是 `se_monad`——解码阶段就已经在错误单子里了，
   不等执行阶段。

---

## 8.10 内核里还有个 `userError`，它跟错误码没关系

`seL4/src` 里到处能搜到 `userError("...")`，望文生义会以为它是"给用户返回错误"。
它其实是内核往串口打印一行诊断，`userError` 宏定义在
`seL4/include/api/types.h:137`：

<!-- 源码块：seL4/include/api/types.h:133-146 -->
```text
/*
 * Print to serial a message helping userspace programmers to determine why the
 * kernel is not performing their requested operation.
 */
#define userError(M, ...) \
    do {                                                                       \
        out_error(ANSI_BOLD "<<" ANSI_GREEN "seL4(CPU %" SEL4_PRIu_word ")"    \
                ANSI_BOLD " [%s/%d T%p \"%s\" @%lx]: " M ">>" ANSI_RESET "\n", \
                CURRENT_CPU_INDEX(),                                           \
                __func__, __LINE__, NODE_STATE(ksCurThread),                   \
                THREAD_NAME,                                                   \
                (word_t)getRestartPC(NODE_STATE(ksCurThread)),                 \
                ## __VA_ARGS__);                                               \
    } while (0)
```

注释第一句就说清了对象：*"Print to serial a message helping userspace programmers
to determine why the kernel is not performing their requested operation."*
打印的是**当前线程**的函数名、行号、TCB 地址和 PC。关掉 `CONFIG_PRINTING`
之后整个宏被替换成空（同文件第 147 到 148 行）。它和返回给调用者的 `seL4_Error`
是两条互不相干的路：前者给人看，后者给程序看。

只有一种情况两者会汇合：开了 `CONFIG_KERNEL_INVOCATION_REPORT_ERROR_IPC`
之后，`out_error` 不再 printf，而是 `snprintf` 进一个全局缓冲
（`seL4/include/api/types.h:123`）：

<!-- 源码块：seL4/include/api/types.h:123-131 -->
```text
#ifdef CONFIG_KERNEL_INVOCATION_REPORT_ERROR_IPC
extern struct debug_syscall_error current_debug_error;

#define out_error(...) \
    snprintf((char *)current_debug_error.errorMessage, \
            DEBUG_MESSAGE_MAXLEN * sizeof(word_t), __VA_ARGS__);
#else
#define out_error printf
#endif
```

这个全局变量的类型就是"一个 50 个字的字符数组"，`DEBUG_MESSAGE_MAXLEN`
定在（`seL4/libsel4/include/sel4/constants.h:125`）。真正把它搬进 IPC buffer 的
就是 8.7 末尾那段 `replyFromKernel_error` 里 `#ifdef` 包住的那几行。
这一条纯属调试设施，官方 12.0.0 的发布说明里记了它的来历
（`docs/content_collections/_releases/sel4/12.0.0.md:54`）：

<!-- 源码块：docs/content_collections/_releases/sel4/12.0.0.md:54-56 -->
```text
* Introduced a new config flag, KernelInvocationReportErrorIPC, to enable userError format strings to be written to
  the IPC buffer. Another config bool has been introduced to toggle printing the error out and this can also be set at
  runtime. LibSel4PrintInvocationErrors is a libsel4 config used to print any kernel error messages reported in the IPC
```

所以本章这三个"错误"名字要分开记：HOL 的 `throwError`（单子里的异常位）、
C 的 `seL4_Error`（跨内核边界返回给调用者的编号）、C 的 `userError`
（内核自己打印的一行字）。第三个既不在规范里，也不影响返回值。

---

## 官方教程对照

| 官方文档 | 覆盖本章哪一段 | 本教程的处理 |
|---|---|---|
| `docs/Tutorials/fault-handlers.md` | 8.5 三类异常、8.7 的用户侧读法 | 只在表里挂号：本地镜像只有 front matter |
| `docs/Tutorials/how-to-seL4.md` | 用户侧动作清单（`Resolve a fault`、`Get a message`） | 8.7 引用它的条目名，不引它没有的正文 |
| `docs/content_collections/_releases/sel4/12.0.0.md` | 8.10 那个开关的来历 | 抄了那三行，并核了今天 `seL4/config.cmake` 里这个开关还在 |
| `l4v/lib/Monads/README.md` | 8.6、8.8 的三个概念 | 与第 07 章共用，见 7.7 |
| `l4v/docs/conventions.md` | 单子变量命名 `f`/`g`/`m` | 8.6 的表按这套名字读 |

**1. 这一层官方没有"错误与故障"教程页。** `docs/Tutorials/` 里最接近的是
`fault-handlers.md`，而它讲的是**用户侧**怎么配 fault endpoint，
和内核规范里的 `se_monad`/`f_monad` 分层不是同一件事；
本章 8.6 到 8.10 的口径全部来自源码与那几条 `compile_assert`。

**2. 镜像里的教程页是"壳"，正文在另一个仓库。** `docs/Tutorials/*.md` 只有
front matter，正文是一行 `{% include tutorial.md %}`，构建时由 `docs/Makefile`
把官方教程仓库克隆到 `_repos/` 再渲染到 `_processed/tutes/`；本地镜像没有
`_repos/`，所以这些正文离线取不到。`docs/Tutorials/how-to-seL4.md` 是例外——
它是镜像里真有一页的索引，只列锚点不列答案。

**3. 一处编号差异值得记。** `errors.h` 的枚举有 11 项（含 `seL4_NoError`）
再加一个哨兵 `seL4_NumErrors`，规范里的 `syscall_error` 只有十个构造子；
两边能对上完全靠"编号从 1 开始往后排"这个约定，
`msg_from_syscall_error` 里那 1..10 是手写的，没有任何东西保证它和 C 枚举同步
——C 侧那几行 `compile_assert` 只钉住了 `lookup_failure`，没钉住 `syscall_error`。

---

## 本章坑位清单（实测）

1. **`Error` 是普通标识符**：`throwError` / `seL4_Error` / `Exceptions_A` 都是正常名字；验证脚本裸搜 `Error` 会把本章误判为"含溃逃痕迹"（`run-all.sh` 的判据是**行锚定**的 `^Error`、`^\*\*\*`、`FAILED`、`Uncaught`，见第 01 章）。
2. **把 `bindE` 的顺序写反**：短路只在左侧出错时发生。
3. **`case` 表达式在 `simp` 下不分裂**：要显式 `split: sum.split`。
4. **想一步证完 `m \<bind> returnOk = m`**：先拆 `fst`/`snd` 两个辅助引理，再用 `prod_eqI`。
5. **解码顺序改成"先看参数"**：参数个数不足时读参数等于越界；顺序是安全性质的一部分。
6. **以为错误会改状态**：`throw_keeps_state` 说明出错的计算没有状态迁移。
7. **把 error 与 fault 混为一谈**：error 返回给用户，fault 交给线程的 handler。
8. **`whenE`/`unlessE` 的返回值是 `('e + unit)`**：类型对不上时报错位置在很远的地方。
9. **`liftE` 用错方向**：它是把普通单子抬进错误单子；反向需要显式 `case` 处理。
10. **以为 `no_fail` 在错误单子里同样好用**：错误单子多了一层，"不出错"要换成 `no_throw`，它是带**两条**后置条件的三元组（8.8）。
11. **以为 `p_monad` 的"不许抢占"有运行时内容**：`without_preemption` 的定义式就是 `liftE`，只是类型约束（8.6）。
12. **看到打印出来的 `('a × state) ⇒ bool` 就以为结果集合换成了谓词**：那是一段 `translations` 缩写，`'a set` 本来就是 `'a ⇒ bool` 的记法（8.6）。
13. **把 `msg_from_syscall_error` 的第一个分量当成返回值**：它是 MessageInfo 的 **label**，列表才是 extra MR；C 侧对应 `setMRs_syscall_error` 写的个数（8.7）。
14. **以为 C 与规范的错误码有编译期同步**：`compile_assert` 只钉住了 `lookup_failure` 的 1..4，`syscall_error` 那 1..10 两边各写一遍（8.7、对照注 3）。
15. **把内核里的 `userError(...)` 当成返回给调用者的错误**：它是串口打印，关掉 `CONFIG_PRINTING` 就整个消失（8.10）。

---

上一章：[07 · 非确定性状态单子](07-nondet-monad.md) ｜ 下一章：[09 · 系统调用入口](09-syscall-entry.md) ｜ 返回：[README](../README.md)
