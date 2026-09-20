# 17 · 优化层：把 -O2 装进 JIT

> 对应示例：`examples/17_minilang_opt/`（minilang.cpp v0.6 + test.mini + foldcheck.mini）

LLJIT 默认"拿来就编"（相当于 -O0）。本章在模块进 JIT 的路上插一道**IRTransformLayer**——用 PassBuilder 组装 `default<O2>` 同款管线先加工。第 5 章的 opt、第 7 章的 PassBuilder、第 15 章的 alloca 策略，在这里三线合流。

## 17.1 管线的编程式组装

```cpp
static void optimizeModuleAtO2(ThreadSafeModule &TSM) {
  TSM.withModuleDo([](Module &M) {
    LoopAnalysisManager LAM;  FunctionAnalysisManager FAM;
    CGSCCAnalysisManager CGAM; ModuleAnalysisManager MAM;
    PassBuilder PB;
    PB.registerModuleAnalyses(MAM);   PB.registerCGSCCAnalyses(CGAM);
    PB.registerFunctionAnalyses(FAM); PB.registerLoopAnalyses(LAM);
    PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);      // 四层管理器互相认识
    ModulePassManager MPM = PB.buildPerModuleDefaultPipeline(OptimizationLevel::O2);
    MPM.run(M, MAM);
  });
}

// 挂到 LLJIT 的变换层（materialize 前自动过一遍）
J->getIRTransformLayer().setTransform(
    [](ThreadSafeModule TSM, MaterializationResponsibility &) {
      optimizeModuleAtO2(TSM);
      return TSM;
    });
```

四件套（Loop/FUNC/CGSCC/Module AnalysisManager + crossRegister）是 PassBuilder 的固定开场——和 clang 中端同构。`--jit`（优化）与 `--jit0`（对照）共用其余全部代码。

## 17.2 实测一：正确性（两模式输出必须一致）

```text
--jit  与 --jit0 均输出：
=> 6.765000e+03     # fib(20)
=> 3.628800e+06     # 10!
=> 5.005000e+05     # sum_to(1000)
=> 3.178110e+05     # fib(28)
==== 17 ok ====
```

## 17.3 实测二：优化的代价与收益（诚实的数据）

在这台机器上计时（整进程含启动+JIT 装配）：

| 负载 | --jit（含 -O2 编译） | --jit0 | 结论 |
|---|---|---|---|
| test.mini（小负载混合） | 48.1 ms | 44.6 ms | **优化反而慢 8%** |
| fib(34)（纯递归） | 22.4 ms | 15.6 ms | 优化开销 > 运行收益 |
| var 热循环 1e7 圈 | 21.7 ms | 15.4 ms | 同上——现代 CPU 的 L1 延迟掩盖了 alloca 成本 |

**结论（写进教科书的反面教材）**：优化不是免费的——每个模块 5-10ms 的管线成本，只有在运行期收益超过它时才赚。fib 递归吃不到 mem2reg/licm 的红利；热循环本就全部命中 L1。**真正立竿见影的是"编译期消灭工作"**——见 17.4。Julia 这类语言做 per-function 渐进优化、Julia 的 "world age"，rustc 的 crate 级缓存，都是在管理这笔账。

## 17.4 实测三：结构性收益（自产 IR 被整体折叠）

`foldcheck.mini`（fib + sum_to + 两行 print）先 `--ir` 出原始 IR，再 `opt -O2`：

（实测产物 `build/17_minilang_opt/foldcheck.O2.ll` 关键行）：

```llvm
define double @__anon1() local_unnamed_addr #2 {
entry:
  br label %loop.body.i              ; ← ".i" 后缀 = sum_to 被内联进来了
loop.body.i:
  %for.result3.i = phi double ...
  %i.02.i.int = phi i32 [ %nextvar.i.int, %loop.body.i ], [ 1, %entry ]
                                 ; ← 注意 i32！double 循环变量被优化器整数化了
  %indvar.conv = uitofp nneg i32 %i.02.i.int to double
  %addtmp.i = fadd double %for.result3.i, %indvar.conv
  ...
  %multmp.i = fmul double %addtmp.i, 0.000000e+00   ; ← 我们 "*0 + acc" 的痕迹
  %addtmp7.i = fadd double %addtmp.i, %multmp.i     ;   也被 instcombine 化简掉
```

三个可讲解的观察：

1. **内联**：`sum_to` 整体消失，代码进调用者（`.i` 后缀块）；
2. **归纳变量整数化**：优化器把 double 计数器换成 i32（`indvar` 变换），比较用整数、加法处再转回——比人写得还讲究；
3. **我们的 `*0` 技巧被看穿**：`x*0 + y` 折成 `y`。

build 脚本验证：`-O2` 输出必须包含 `.i:`（内联痕迹），否则判失败。

## 17.5 本章小结

- IRTransformLayer.setTransform 是 JIT 优化层的挂点；PassBuilder 四件套组装 default<O2>。
- 优化的账本：编译期成本 vs 运行期收益；小负载/递归/缓存友好循环收益小，**结构性消除（内联/折叠）才是大头**。
- 自产 IR 被上游优化器完整消化（内联+整数化+常量折叠）——前端"够标准"，红利自来。

| 坑 | 解法 |
|---|---|
| 管线跑完分析全失效 | crossRegisterProxies 别漏 |
| Transform 回调签名不符 | 22：返回 TSM（Expected 语义），参数 MaterializationResponsibility& |
| 优化后行为变了 | 先查语言语义是否依赖浮点精度/求值顺序 |

下一章补齐控制流最后两块：while 与短路逻辑。
