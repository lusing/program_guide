# 26 · 独立编译、子单位与可见性

> 示例：[`examples/ch26_separate.adb`](../examples/ch26_separate.adb)（共 6 个文件）
> 运行：`./run-all.sh 26`
>
> 本示例是多文件工程：主程序 + 2 个子单位 + 1 个父包 + 子库单元对。
> 文件见 `examples/ch26_separate*.adb` 与 `examples/ch26_support*.*`。

到目前为止，所有示例都是"一个文件一个程序"。真实工程动辄几百个编译
单元，Ada 的应对方案在老教材里各占一章（何诚第 9 章"再谈程序结构"、
刘炳文第 13 章"独立编译"）：**库单元自底向上**、**子单位自顶向下**、
外加一套把"名字什么时候看得见"讲得比任何语言都细的**可见性规则**。
这三件东西构成了 Ada 软件工程的地基——也是 SPARK 大规模验证能落地
的前提。

---

## 26.1 编译单元与 with/use 的准确语义

能单独交给编译器的 topLevel 构件叫**编译单元**：子程序、包（规范
和体各算一个）、泛型、子单位。`with` 声明依赖，`use` 开启直接可见。
老教材反复强调的三条语义规则：

1. **with 作用到"体"为止**：包规范前的 `with` 自动覆盖对应的体——
   体前**不必重复**（`use` 同理）。反之，体可以有自己的 with/use，
   只影响体内部（把依赖收窄在体的做法叫"最小上下文"，GNAT 有
   `-gnatwd` 提示）。
2. **use 的位置即作用域**：放在文件头作用于整个单元；放在某个
   declare 块里只作用于该块——把 `use` 圈进最小作用域是 Ada 的
   好品味（避免名字污染）。
3. **with 子包即隐式 with 祖先**：`with Ada.Containers.Vectors`
   同时让你用 `Ada.Containers` 这个祖先名。

## 26.2 三档名字访问：限定名 / use / use type

同一个包 `Dist` 里的类型与算符，三档打开方式：

```ada
declare
   use type Dist.Meters;      -- ★ 只放行"算符"，不放行类型名
   A : Dist.Meters := 300;    -- 类型名仍须限定（或另一条 use）
   B : Dist.Meters := 120;
begin
   Put_Line (Dist.Meters'Image (Dist."+" (A, B)));  -- 完全限定
   Put_Line (Dist.Meters'Image (A + B));            -- use type 的功劳
end;
```

| 方式 | 放行什么 | 副作用 |
|------|---------|--------|
| `Dist.X`（限定名） | 精确到这一个名字 | 无——最安全，长 |
| `use Dist;` | 全部直接可见 | 名字污染（撞名风险） |
| `use type Dist.Meters;` | **仅该类型的算符** | 几乎无——中缀算符的标准姿势 |

`use type` 是"我只想写 `A + B`、不想把整个包倒进作用域"的答案，
在 [20 章](20-c-interop.md) 的 C 互操作里早见过它
（`use type Interfaces.C.int` 撑起跨语言判等）。

## 26.3 renames：零成本的"本地别名"

`renames` 给既有实体换个名字，**不创建新实体**：

```ada
procedure Say (S : String) renames Put_Line;   -- 子程序改名
package TIO renames Ada.Text_IO;               -- 包改名：长名缩短
Middle : Integer renames Arr (3);              -- 对象改名：零拷贝别名
```

对象 renames 最有分量：`Middle` 与 `Arr (3)` 是**同一块内存**，
改别名即改本体（示例实测：`Middle := 99` 后 `Arr (3) = 99`）。
工程用途：给深层分量的短名（`Config.Server.Port` → `Port`）、
给泛型实例起可读名、老代码换名不改逻辑。还有异常 renames
（`E : exception renames Ada.Text_IO.Layout_Error;`）——
[11 章](11-exceptions.md) 的分诊技巧。

## 26.4 子单位：自顶向下的分别编译

**库单元**（前面所有章节的玩法）是自底向上：先编译被依赖的包，
再编译上层。**子单位（subunit）**反过来——大程序先写骨架，把
实现的体"推迟"到别的文件：

```ada
procedure Ch26_Separate is
   procedure Report (Title : String; Data : Ch26_Support.Int_Array)
     is separate;                        -- ① 体存根（body stub）

   package Helpers is
      function Squared (X : Integer) return Integer;
   end Helpers;
   package body Helpers is separate;     -- ② 包体也能拆
begin
   ...
end Ch26_Separate;
```

被拆走的体住在子单位文件里，`separate (父单元名)` 打头：

```ada
-- ch26_separate-report.adb
separate (Ch26_Separate)
procedure Report (Title : String; Data : Ch26_Support.Int_Array) is
begin
   ...
end Report;
```

五条规则（老教材 §9.3 原版 + 实测确认）：

1. **文件名 = 父单元名 + `-` + 单元名**（GNAT 约定）：
   `ch26_separate-report.adb`、`ch26_separate-helpers.adb`；
2. **存根必须在编译单元的最外层说明部分**——嵌套单元里不能再套
   存根（想把 Helpers 里的过程再拆出去？不行，把 Helpers 整个拆）；
3. **子单位签名必须与存根完全一致**（连类型写法解析后都要同型）；
4. **子单位的可见性 = 存根处的可见性**——父单元 `with`/`use` 过的
   名字直接可用，不多也不少；Ada 2012 起子单位还可以带自己的
   `with` 子句把依赖显式化（老教材预言的"较近控制"）；
5. 子单位拆的是**体**（子程序体/包体/任务体），任务可以做子单位
   但**不能**做库单元（老教材明令）。

自顶向下 + 自底向上两条路合起来，就是何诚那句话："分别编译支持
程序的两个构造方向"。历史上子单位是 80 年代大项目分文件的主力；
今天的 GNAT 工程更常用**子库单元**（下一节），子单位主要用于
超长体（编译时间优化）与遗留代码。运行时与语义完全等价。

## 26.5 子库单元：层级库

现代 Ada 组织大库的主流武器——**孩子**。`Ada.Containers.Vectors`
就是三层：`Ada` → `Ada.Containers` → `Ada.Containers.Vectors`。

```ada
-- ch26_support.ads —— 父包：共享类型的家
package Ch26_Support is
   type Int_Array is array (Positive range <>) of Integer;
end Ch26_Support;

-- ch26_support-stats.ads —— 子包：挂在父包规范之下
package Ch26_Support.Stats is
   function Average (A : Int_Array) return Integer;   -- 直接用父包类型
   function Max_Of (A : Int_Array) return Integer;
end Ch26_Support.Stats;
```

使用方：

```ada
with Ch26_Support.Stats;      -- with 子包即隐式 with 祖先
...
use Ch26_Support.Stats;
Data : constant Ch26_Support.Int_Array := (3, 1, 4, 1, 5, 9, 2, 6);
Average (Data)                -- 3
```

实测踩出来的两条硬规则（本章写作时撞的头两堵墙，值得记录）：

1. **孩子挂在父单元的规范上**——子包看得见的是**父包 .ads 里**的
   声明；父**体**里的东西对孩子不可见。想把类型给孩子共享，
   类型必须上移到父包规范（这正是 `Ch26_Support` 存在的理由）。
2. **过程主程序没法直接挂孩子**：GNAT 找不到 `ch26_separate.ads`
   规范文件就拒绝 `Ch26_Separate.Stats`。正统做法就是本例这样：
   立一个父**包**当"名字空间"，孩子挂包上。

子库单元 vs 子单位的选型：

| 维度 | 子单位 (separate) | 子库单元 (child) |
|------|-------------------|------------------|
| 方向 | 自顶向下拆体 | 自底向上长枝 |
| 依赖 | 反向依赖父单元的一切 | 只依赖父**规范** |
| 可复用 | 否（私属实现） | 是（独立库单元，可再被别人 with） |
| 现代用途 | 超长体、遗留拆分 | 一切新库 |

## 26.6 可见性速查：谁遮谁、怎么破

Ada 的可见性规则（老教材 §9.5–9.7 讲了二十页）浓缩成一张表：

| 情形 | 规则 | 破解 |
|------|------|------|
| 内层声明同名 | 内层**遮蔽**外层（合法且常见） | 块标签扩展名 `Outer.X`（示例第 5 节实测） |
| 两个 use 的同名实体 | 两个都**不可见**（不是撞错） | 限定名 `Pkg.X` 点名 |
| 包内私有部分 | 包外只见规范，不见私有部分 | —（这就是封装） |
| 子单元 | 存根处的可见性原样继承 | 子单位自带 with（Ada 2012） |
| 孩子 | 看得见父规范的声明 | 需要更多就上移到父规范 |
| 重载名 | 按参数签名消歧 | 实参类型对准；还不行用限定 |

"两个 use 都不可见"这条最反直觉也最有用：`use A; use B;` 之后
`A`、`B` 各自的 `X` 都直接写不得，必须 `A.X` / `B.X` 点名——
Ada 用"强制点名"消灭了 C++ 那类 namespace 惊喜。

## 26.7 常见坑

1. **子单位签名不严格一致**：存根 `Data : Ch26_Support.Int_Array`、
   子单位写 `Data : Int_Array`——"not fully conformant" 编译错，
   连可见性都得两边都说得通。
2. **孩子找父规范**：子库单元要求父单元有 .ads（过程主程序没有）
   ——立父包，别硬挂。
3. **use 当默认**：全文件 `use` 十个包是坏味道；限定名 +
   局部 use + use type 才是 Ada 的分层卫生。
4. **renames 当新对象**：`renames` 是别名不是拷贝，
   生存期跟着本体（本体失效后别名也失效——悬挂 renames 编译期就会
   被可访问性规则拦下）。
5. **存根嵌套**：想在子单位里再拆子单位——存根必须在最外层，
   嵌套体不行。
6. **GNAT 文件名**：子单位/子库单元的 `父-子.adb` 命名是 GNAT
   约定（可被 gnat.adc/项目文件改写）；教程工程保持默认约定最省心。

## 26.8 小结

| 工具 | 一句话 |
|------|--------|
| `with` / `use` | 声明依赖 / 开直接可见；use 圈进最小作用域 |
| `use type` | 只放行某类型的算符——中缀运算的标准姿势 |
| `renames` | 子程序/包/对象/异常的零成本别名 |
| `is separate` + `separate (P)` | 体存根与子单位：自顶向下拆体 |
| `package P.C is` | 子库单元：层级库，Ada.Containers 的组织法 |
| 块标签扩展名 | `Outer.X` 破遮蔽 |

到此，教程的正文全部结束。回头看：03–09 章类型系统、10–13 章模块化
与泛型、14 章 OOP、15–17 章并发、18–19 章 I/O、20–22 章系统级、
23–25 章现代高级设施——**每一章的机制都为"把错误拦在离成因最近处"
服务**，而本章的独立编译把它们组装成大型工程。

---

### 习题（改编自何诚第 9 章、刘炳文第 13 章）

1. 何诚 §9.2 的"SETS 包"分层练习：把 08 章判别记录的 `Set` 类型
   做成库单元包 `Sets`，主程序拆两个子单位（读入/统计），全部
   独立编译通过。
2. 给 `Ch26_Support.Stats` 加孙单元 `Ch26_Support.Stats.Histogram`
   （输出字符直方图），验证三层层级库与隐式 with 链。
3. 造一个"两个 use 撞名"的最小例子：两个包各有 `X`，
   `use` 两个包后直接写 `X` 观察编译错误，再用限定名修复。
4. 把 `Report` 子单位带上自己的 `with Ada.Calendar;`（Ada 2012
   起合法），打印编译时间戳；对比把它挪回父单元上下文子句的差别。

---
上一章：[25 SPARK 形式化验证](25-spark.md) ｜ 下一章：[27 附录](27-appendix.md) ｜ 返回：[README](../README.md)
