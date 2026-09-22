# 09 · Value/User/Use：IR 的对象模型

> 对应示例：`examples/09_value_model/`（walker.cpp + walk.ll）

第 8 章你用 IRBuilder "造" IR；这一章学会"**逛**"和"**改**" IR。LLVM 全部 C++ API 的地基是一个小小的类阶层——`Value`/`User`/`Use`。理解了它，优化器源码、clang AST、甚至 MLIR 都是一路货色。本章示例 `walker` 完成一次真实的"外科手术"：克隆函数 → 替换所有使用 → 删除原件——这是重构类 pass 的标准三连。

## 9.1 类阶层：一切皆 Value

```text
Value                     （有类型的东西，可以被"使用"）
├── Argument              （函数参数）
├── BasicBlock            （基本块——也是 Value！可被 br 使用）
├── Instruction : User    （指令）
│   └── BinaryOperator / CallBase / PHINode / AllocaInst / …
├── Constant : User       （常量也是 Value：i32 1、全局地址、函数地址…）
│   └── Function / GlobalVariable（GlobalValue）
└── MetadataAsValue …

User                      （会"用"别人的 Value：持有若干 operand）
├── Instruction
└── Constant

Use                       （一条"使用边"：串成侵入式双向链表）
```

三个名字一句话：**Value 是数据，User 是消费者，Use 是它们之间的边**。指令 `%t = add %a, %b`：

```text
BinaryOperator %t (User)
 ├─ Use#0 → %a (Value)
 └─ Use#1 → %b (Value)
        反向：%a 的 use 链上有这条边，指回 %t
```

这张双向图是 LLVM 一切数据流分析的物理基础——"谁定义了我"看 operand，"谁用了我"走 use 链，全部 O(1)。

## 9.2 遍历的标准姿势

```cpp
// 模块 → 函数（isDeclaration() 滤掉纯声明）
for (Function &F : M)
  if (!F.isDeclaration()) ...

// 函数 → 基本块 → 指令
for (BasicBlock &BB : F)
  for (Instruction &I : BB) ...

// 或者偷懒（inst_iterator 展平块结构）
for (Instruction &I : instructions(F)) ...

// 指令 → 操作数（User 视角）
for (Use &U : I.operands())
  Value *V = U.get();

// 值 → 使用者（Value 视角）
for (Use &U : V.uses()) {
  User *Usr = U.getUser();   // 谁在用
  // Value *What = U.get();  // 用的是谁（就是 V 自己）
}
```

`getNumUses()` / `use_empty()` 是**死代码判据**——`use_empty()` 的指令没有任何使用者，DCE 删的就是它。

## 9.3 isa/dyn_cast/cast：LLVM 的 RTTI

C++ 自带 RTTI 又慢又不能跨类库；LLVM 用一个可静态断言的"类名编码"自己造了一套：

```cpp
if (isa<CallBase>(I)) ...                        // 是吗？（布尔）
if (auto *CB = dyn_cast<CallBase>(&I)) ...       // 是就给指针，不是给 nullptr
auto *BO = cast<BinaryOperator>(&I);             // 断定是，错了直接崩（assert）
auto *F = dyn_cast_if_present<Function>(V);      // 处理 nullptr 的 dyn_cast
```

配合 `I.getOpcodeName()`（"add"/"mul"…）就能做指令分类统计。walker 的直方图：

> **注意流别**：这些报告走的是 `errs()` 不是 `outs()`（和 opt 的 pass 报告同一套约定——诊断信息不上 stdout，stdout 留给"真正的结果"）。build.ps1 把 `2>&1` 合并了所以看不出来；shell 侧如果分开重定向，报告全在 stderr 里。

（实测输出）：

```text
== module '...walk.ll' has 5 functions, 2 globals
   square: 1 bb, 2 insts
   hypot_sq: 1 bb, 4 insts
   main: 1 bb, 4 insts
== instruction histogram:
   binary:add x1
   binary:mul x1
   call x5
   ret x3
```

> **实测坑（悬垂 StringRef，连环 UB 元凶）**：`std::map<StringRef, unsigned>` 拿 `(Twine("binary:") + 名字).str()` 当键——`.str()` 返回**临时** std::string，StringRef 指向它，分号一过就悬垂。症状诡异地间接：直方图键乱码（mul 计到 add 头上）、后续内存损坏导致卡死/段错误。**凡是要长期持有的键，用 `std::map<std::string, ...>`**；StringRef 只当"借来的视图"。

## 9.4 手术三连：Clone → RAUW → erase

walker 的重头戏，把 `@square` 换成克隆的 `@square2`：

```cpp
// ① 克隆：22 的 CloneFunction 返回副本并【自动加入当前模块】
ValueToValueMapTy VMap;                 // 原值 → 克隆值的映射表
Function *Square2 = CloneFunction(Square, VMap);
Square2->setName("square2");

// ② RAUW = ReplaceAllUsesWith：改写全部"使用边"
Square->replaceAllUsesWith(Square2);

// ③ 断定无人使用后删除
Square->eraseFromParent();
```

- **RAUW 是改图的原子操作**：遍历旧值的 use 链，把每条边的 operand 字段改指新值。它**不删旧值**——旧值变成孤岛（uses=0）。
- `ValueToValueMapTy` 记录"每个原值克隆到了谁"，跨函数/跨模块克隆时用它修边。
- 顺序很重要：**先 RAUW 再 erase**。删除还有使用者的 Value 会 assert 崩溃。

（实测输出）：

```text
== users of @square:
   call site in @hypot_sq
   call site in @hypot_sq        ← 两个调用点（use 链的直观展示）
== after RAUW: uses of @square = 0
wrote ...\after.ll
```

`after.ll` 里 `hypot_sq` 的两个 call 已指向 `@square2`，`lli after.ll` 输出 25 + 标记——手术等价性验证（build 脚本自动做）。

> **实测坑（双重插入死循环）**：老教材的 `M->getFunctionList().push_back(CloneFunction(...))` 在 22 是**灾难**——CloneFunction 已经自动入模块，再 push_back 等于把同一节点插两遍，函数链表成环，后续 `M.print` **无限循环烧 CPU**（实测卡 15 分钟、0 字节输出）。22 里克隆函数就一行 `CloneFunction(F, VMap)`，不要 push_back。需要更精细控制（改名后缀、跨模块、类型重映射）才上 `CloneFunctionInto`（注意它的 `Returns` 出参**必填**，4 参便捷重载不存在）。

## 9.5 与 IR 文本的对读

| 文本 IR | 对象模型 |
|---|---|
| `%name` / `%3` | `Value*`（有 name 或无名靠编号打印） |
| 指令的操作数 | `Use` 边，`I.getOperand(i)` |
| `br label %bb` | 分支指令 use 了 BasicBlock 这个 Value |
| `@fn` 被调用 | CallBase 的 operand 指向 Function |
| phi 的来源块 | PHINode::getIncomingValue(i) / getIncomingBlock(i) |

练习：把 walker 的遍历目标从指令换成"所有被 call 的函数名"，你就写出了一个迷你的调用图生成器。

## 9.6 本章小结

- Value/User/Use = 数据/消费者/边；双向 O(1) 导航是一切分析的地基。
- `isa`/`dyn_cast` 是 LLVM 的 RTTI；遍历有 Module→Function→BB→Inst 与 inst_iterator 两套姿势。
- 改图三连：Clone → RAUW → erase，顺序不可乱。
- 两个大坑都吃过肉：悬垂 StringRef（UB 连环爆）、CloneFunction 双重插入（死循环）。

| 坑 | 解法 |
|---|---|
| `map<StringRef,...>` 配 `.str()` 临时 | 键用 std::string |
| 克隆后 push_back 死循环 | 22 的 CloneFunction 自动入模块 |
| CloneFunctionInto 参数不够 | Returns 是必填出参 |
| erase 崩溃 | 先 RAUW 清 use 链再删 |
| dyn_cast 拿到 nullptr | 检查返回值；确定类型才用 cast |
| 报告打在 stderr 上看着像"没输出" | walker 用 errs()（诊断约定），重定向时别只捞 stdout |

下一章从对象树降回工具层：`llc` 与目标代码生成。
