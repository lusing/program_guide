# 中译本《面向计算机科学的数理逻辑》术语对照（RapidOCR 抽样）

来源：中译本扫描件目录页（PDF 13–14）+ 第 3/4/5/6 章首页（PDF 129/184/216/251），
RapidOCR（onnxruntime-gpu + cudnn 9.24，`PATH` 须含 `G:\cudnn\9.24\bin\12.9\x64`）。
教程现行术语以 grep 实测为准，**不随中译本改动**；本表仅供阅读对照。

| 英文（2e 原文） | 中译本译名 | 教程现行 |
|---|---|---|
| declarative sentences | 判断语句 | 宣言句（01 章，拟统一为「判断/宣言句」并注异译） |
| natural deduction | 自然演绎 | 自然演绎 ✅一致 |
| derived rules | 派生规则 | 派生规则 ✅ |
| provable equivalence | 逻辑等价 | 可证等价（⚠️异译：中译本易与 semantic equivalence 混） |
| proof by contradiction | 反证法 | 反证法 ✅ |
| soundness | 合理性 | 可靠性（⚠️异译，教程从大陆教材主流） |
| completeness | 完备性 | 完备性 ✅ |
| normal forms | 范式 | 范式 ✅ |
| satisfiability / validity | 满足性 / 有效性 | 可满足性 / 有效性 |
| conjunctive normal form | 合取范式 | 合取范式（CNF）✅ |
| Horn clauses | 霍恩子句 | Horn 子句（教程保留原文姓氏） |
| SAT solver | SAT 求解机 | SAT 求解器（⚠️「求解机」罕用） |
| linear / cubic solver | 线性 / 三次求解机 | 线性 / 三次求解器 |
| predicate logic | 谓词逻辑 | 谓词逻辑（FOL/一阶逻辑混用）✅ |
| substitution | 代换 | 代入（⚠️异译，教程主流用「代入」） |
| free / bound variables | 自由变量和约束变量 | 自由/约束变元（教程用「变元」） |
| proof theory | 证明论 | 证明论 ✅ |
| quantifier equivalences | 量词的等价 | 量词等价 ✅ |
| semantic entailment | 语义推导 | 语义蕴含（⚠️异译） |
| semantics of equality | 相等的语义 | 等式语义 |
| undecidability | 不可判定性 | 不可判定性 ✅ |
| expressiveness | 表达能力 | 表达能力/表达力 ✅ |
| existential / universal second-order logic | 存在式 / 全称式二阶逻辑 | 存在/全称二阶逻辑 |
| micromodels of software | 软件的微观模型 | 软件微模型（2.7 节，本教程不展开） |
| model checking | 模型检测 | 模型检查（⚠️异译，24/26 章现行） |
| linear-time temporal logic | 线性时态逻辑 | 线性时态逻辑（LTL）✅ |
| practical patterns of specifications | 规范的实际模式 | 规范实践模式 |
| adequate sets of connectives | 适当连接词集 | 充足连接词集（adequate sets） |
| mutual exclusion | 互斥 | 互斥 ✅ |
| ferryman puzzle | 摆渡者难题 | 摆渡者（28 章选讲互斥，不展开） |
| alternating bit protocol | 交错位协议 | 交替位协议（ABP，文档提及） |
| branching-time logic | 分支时间逻辑 | 分支时间逻辑 ✅ |
| fixed-point characterisation | 不动点特征 | 不动点刻画（⚠️异译） |
| monotone functions | 单调函数 | 单调函数 ✅ |
| Hoare triples | 霍尔三元组 | 霍尔三元组 ✅ |
| partial / total correctness | 部分正确性和完全正确性 | 部分/完全正确性 ✅ |
| program / logical variables | 程序变量和逻辑变量 | 程序变量/逻辑变量 ✅ |
| proof tableaux | 证明布景 | proof tableaux 竖式（⚠️「布景」罕用，教程用「竖式证明表」） |
| minimal-sum section | 最小和截段 | 最小和段（minimal-sum，30 章案例） |
| programming by contract | 合同编程 | 契约式设计（DbC，⚠️异译） |
| modal logics and agents | 模态逻辑与代理 | 模态逻辑与主体（⚠️agent 教程用「主体」） |
| modes of truth | 真值的模式 | 真值模态（modes of truth） |
| logic engineering | 逻辑工程 | 逻辑工程 ✅ |
| stock of valid formulas | 有效公式储备 | 有效式库 |
| correspondence theory | 对应理论 | 对应理论 ✅ |
| accessibility relation | 可达关系 | 可达关系 ✅ |
| knowledge in multi-agent systems | 多代理系统中的知识推理 | 多主体知识推理 |
| binary decision diagrams | 二叉判定图 | 二叉决策图 BDD（⚠️异译，两译名均通行） |
| ordered / reduced BDD | 有序 BDD / 简约 OBDD | 有序/约简 OBDD（⚠️「简约」罕用） |
| symbolic model checking | 符号模型检测 | 符号模型检查 |
| transition relation | 迁移关系 | 迁移关系 ✅ |
| relational mu-calculus | 关系μ演算 | 关系 μ 演算 ✅ |

## OCR 质量注记

- 目录页识别质量好（两栏交错但词条可读）；公式区一律不可靠（□/◇/希腊字母大量丢失），
  公式以英文 2e 文本层+PDF 页图为准。
- 英文 2e 文本层缺陷实录：`s3_5.txt` 希腊字母/→ 大面积缺失（如 `r A[ R ] =E[ U]`
  应为 `A[φ R ψ] ≡ ¬E[¬φ U ¬ψ]`）——29/34 章公式须对照 PDF 页图人工核。
- 中译本页码→PDF 页偏移 = **+14**（第 1 章书页 1 = PDF 15）。
