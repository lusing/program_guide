# Coq 教程示例集

本目录按 `guide` 统一结构组织 Coq 教程与可验证示例。教程正文见
[COQ编程指南.md](./COQ编程指南.md)（25 章，24 个配套示例，全部经
coqc 8.20.1 编译验证，含实测坑位 60+ 条）。

## 目录结构

```text
coq/
├── README.md
├── COQ编程指南.md
├── build.ps1
└── examples/
    ├── 01_intro.v            # Check / Compute / 第一个证明
    ├── 02_toolchain.v        # Print / About / Locate / Search 问询
    ├── 03_first_proof.v      # Proof-Qed 解剖、Fail、Abort
    ├── 04_types.v            # nat 真身、sorts、多态与隐式参数
    ├── 05_expressions.v      # 记号、nat 算术坑、if 真身、%Z
    ├── 06_tuples_records.v   # 积类型、Record、字段名坑
    ├── 07_patterns.v         # match 词汇表、穷尽/冗余分支
    ├── 08_lists.v            # list 操作、fold 方向与参数序坑
    ├── 09_inductive.v        # 枚举、自造 bool/nat、二叉树
    ├── 10_fixpoint.v         # 结构递归、守卫检查实测边界
    ├── 11_proof_state.v      # 证明状态演变、apply/exact
    ├── 12_induction.v        # 归纳剧本四例（nat/list）
    ├── 13_rewrite.v          # rewrite 方向学、destruct、discriminate
    ├── 14_logic.v            # /\ \/ -> ~ iff 与子弹层级
    ├── 15_predicates.v       # 归纳谓词、exists、强化、reflect
    ├── 16_higher_order.v     # map 定律、filter 幂等
    ├── 17_option.v           # option 建模、bind 链、定律
    ├── 18_tactics_modules.v  # auto/assert、模块签名封装
    ├── 19_ast.v              # aexp 求值器 + 优化器正确性
    ├── 20_list_laws.v        # 六条列表定律 + rev_acc 强化
    ├── 21_sorting.v          # 插入排序 + 有序/重排双正确性
    ├── 22_numbers.v          # nat/N/Z、lia、作用域坑
    ├── 23_testing.v          # Example 即测试、Print Assumptions
    └── 24_project.v          # 解释器+双 pass 流水线+Extraction
```

## 工具链

- Coq: `G:\scoop\apps\coq\current`（8.20.1，2024 年后更名 Rocq）
- 编译器: `G:\scoop\apps\coq\current\bin\coqc.exe`

## 编译验证

```powershell
cd G:\code\guide\coq
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 03_first_proof.v
```

清理：

```powershell
.\build.ps1 -Clean
```

注：`24_project.v` 的 `Recursive Extraction` 会向输出打印抽取的
OCaml 代码，全量编译耗时略长属正常。
