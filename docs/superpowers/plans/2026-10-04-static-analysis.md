# 静态分析教程（ANTLR4 + LLVM）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `G:\code\guide\compiler\` 交付 30 章静态分析教程（七篇，spa.pdf 为骨架），30 个可独立构建验证的分析器快照 + 30 篇以原理推导为主的正文。

**Architecture:** ANTLR4（4.13.3 源码构建工具 jar + C++ runtime 源码构建）解析 TIP → AST → 名字/CFG → 各分析（类型约束与合一、格与不动点、数据流、widening、上下文敏感、IFDS/IDE、0-CFA、指针、抽象解释）；LLVM C++ API（ORC LLJIT）让 TIP 真实运行，作为分析可靠性的经验标尺，并与工业中端（SCCP 等）对照。分析器逐章复制演进（snapshot），通用 `example_build.sh` 自动生成 parser 并编译 src/ 全部 .cpp。

**Tech Stack:** C++17；scoop MSYS2 UCRT64（pacman 装 LLVM/GCC/CMake/Ninja）；ANTLR 4.13.3-SNAPSHOT（`G:\github\java\antlr4`）；LLVM（pacman UCRT64 版；源码参考 `G:\github\lang\llvm-project`）；Maven 3.10 + OpenJDK 17；Python 3（对账脚本）；pwsh 7 + Git Bash。

**Spec:** `docs/superpowers/specs/2026-10-04-static-analysis-tutorial-design.md`。执行时 spec 与本计划同行，Global Constraints 每个任务都隐含遵守。

## Global Constraints

- 工程根：`G:\code\guide\compiler\`。`build/` 全部产物（antlr.jar、runtime 安装、gen/、tipa.exe、.ll、.o、可执行文件）一律不入库。
- 不写 CHEATSheet、不写坑清单章节；每章正文末尾仅一节叙述体"工程注意点"（3–5 条）。
- 分析器 C++17，编译参数固定：`-std=c++17 -Wall -Wextra`，**零告警**；UCRT64 g++ 为必过通道，clang++ 只门控登记（脚本试跑、记录、不判失败）。
- LLVM 链接用动态库：`llvm-config --cxxflags --ldflags --link-shared --libs core orcjit support native analysis passes --system-libs`；过滤 llvm-config 输出里的 `-std=c++NN`（避免与我们的 -std 冲突）。
- ANTLR 调用：`java -jar build/antlr/antlr.jar -Dlanguage=Cpp -visitor -no-listener -o <gen> TIP.g4`；Maven/ANTLR 构建用 `JAVA_HOME=G:\scoop\apps\openjdk17\current`。
- 每章 = `docs/NN-<slug>.md` + `examples/NN_<slug>/`（章号=示例号，01–30）。slug 全表：
  `01_overview, 02_undecidability, 03_tip_tour, 04_antlr_grammar, 05_ast, 06_scopes, 07_cfg, 08_llvm_run, 09_type_vars, 10_constraints, 11_unify, 12_records_limits, 13_sign_lattice, 14_lattice_build, 15_fixpoint, 16_worklist, 17_sign_const, 18_classic_dfa, 19_transfer, 20_interval, 21_widening, 22_path_sens, 23_interproc, 24_context_sens, 25_ifds, 26_ide, 27_closure_0cfa, 28_pointer, 29_abstract_interp, 30_finale`
- CLI 约定（ch04 起）：`tipa --check FILE`（章目相关输出，必实现）；`tipa --run FILE INPUTS`（ch08 起）；`tipa --verify-soundness FILE INPUTS`（ch17 起）；`tipa --emit-ir FILE`（ch08 起）。
- INPUTS 文件格式：`#` 注释行；其余每行一次运行，空格分隔的整数序列（先填 main 形参，其余供 input 表达式读取）。
- 确定性：不打印地址、耗时、平台相关值；程序点编号按 AST 遍历顺序固定；错误流（stderr）并入对账文本。
- **正文自包含**：src/ 与 TIP.g4 的每个文件必须整文件嵌入对应 docs，代码块首行标记 `// file: <相对路径>`（.g4 用 `// file: TIP.g4`）；expected 下文本以 ```text 块嵌入，首行 `; expected: <相对路径>`。由 tools/check_docs.py 机器核查。
- 每篇正文 ≥ 200 行、文字篇幅多于代码；组织顺序固定：问题与直觉 → 形式化 → 正确性论证思路 → 原理落地（分段代码，段前段后有讲解）→ 真实输出 → 工程注意点。
- 提交：每任务一次，信息 `feat(compiler): …`，末尾空行 + `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## File Structure

```
compiler/
├── .gitignore
├── README.md                  # Task1 骨架 → Task10 定稿（书目导读+30 章导航）
├── build.ps1                  # pwsh：委托 scoop MSYS2 跑 run-all.sh
├── run-all.sh                 # 通用：遍历 examples/*，build + 三层对账 + check_docs
├── tools/
│   ├── bootstrap.sh           # pacman 环境；mvn 构建 antlr.jar；cmake 构建 C++ runtime
│   ├── example_build.sh       # 通用单示例构建（g4 生成 + src 全量编译，识别 llvm.need）
│   ├── check_example.py       # 单示例对账：--check/errors/run/soundness/opt
│   └── check_docs.py          # docs 自包含与行数核查
├── docs/                      # 01-overview.md … 30-finale.md
├── examples/
│   └── NN_<slug>/
│       ├── (TIP.g4)           # ch04 起
│       ├── (llvm.need)        # ch08 起，空文件，构建开关
│       ├── src/               # 全部 .cpp/.hpp
│       ├── programs/          # *.tip；错误样例放 errors/
│       └── expected/          # output.txt、errors/、run/、soundness/、opt/（按需）
└── build/                     # gitignore
    ├── antlr/{antlr.jar, include/antlr4-runtime, lib/libantlr4-runtime.a}
    └── NN_<slug>/{gen/, tipa.exe}
```

---

## Task 1: 环境引导与工程骨架

**Files:**
- Create: `compiler/.gitignore`, `compiler/README.md`（骨架）, `compiler/build.ps1`, `compiler/run-all.sh`, `tools/bootstrap.sh`, `tools/example_build.sh`, `tools/check_example.py`, `tools/check_docs.py`
- Create dirs: `compiler/docs`, `compiler/examples`
- Produce: `build/antlr/antlr.jar`、`build/antlr/include/antlr4-runtime/`、`build/antlr/lib/libantlr4-runtime.a`、UCRT64 LLVM/GCC

- [ ] **Step 1: 建目录与 .gitignore**

```bash
mkdir -p "G:/code/guide/compiler/docs" "G:/code/guide/compiler/examples" "G:/code/guide/compiler/tools"
```

`compiler/.gitignore`：

```gitignore
build/
*.exe
*.o
*.obj
*.ll
*.s
gcm.cache/
```

- [ ] **Step 2: tools/bootstrap.sh（一次性环境引导）**

```bash
#!/usr/bin/env bash
# 引导静态分析教程实验台：UCRT64 LLVM/GCC + ANTLR 工具 jar + ANTLR C++ runtime
set -euo pipefail
export JAVA_HOME='G:\scoop\apps\openjdk17\current'
ROOT=/g/code/guide/compiler

# 1) UCRT64 编译器/LLVM/构建工具（pacman 已验证联网）
pacman -S --needed --noconfirm \
  mingw-w64-ucrt-x86_64-llvm mingw-w64-ucrt-x86_64-clang \
  mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja

# 2) ANTLR 工具 jar（源码树 4.13.3-SNAPSHOT；只构建 tool 模块及其依赖）
cd /g/github/java/antlr4
mvn -q -pl tool -am -DskipTests package
mkdir -p "$ROOT/build/antlr"
cp tool/target/antlr4-4.13.3-SNAPSHOT-complete.jar "$ROOT/build/antlr/antlr.jar"

# 3) ANTLR C++ runtime 静态库，安装到 build/antlr
cd runtime/Cpp
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$ROOT/build/antlr" \
  -DWITH_DEMO=OFF -DANTLR_BUILD_CPP_TESTS=OFF
cmake --build build -j
cmake --install build

# 4) 验收
test -f "$ROOT/build/antlr/antlr.jar"
test -f "$ROOT/build/antlr/lib/libantlr4-runtime.a"
test -d "$ROOT/build/antlr/include/antlr4-runtime"
llvm-config --version
echo "[bootstrap OK]"
```

- [ ] **Step 3: 运行引导（在 UCRT64 shell 内）**

```bash
/g/scoop/apps/msys2/current/usr/bin/bash -lc 'cd /g/code/guide/compiler && bash tools/bootstrap.sh'
```

预期：pacman 装好 llvm/gcc/cmake/ninja（记录 llvm-config 实际版本号到 ch01 正文）；mvn 产出 complete jar；runtime 安装完成；打印 `[bootstrap OK]`。若 mvn 因 JDK 版本失败，检查 JAVA_HOME 指向 openjdk17（脚本已 export）。

- [ ] **Step 4: tools/example_build.sh（通用单示例构建，任何章节不改此脚本）**

```bash
#!/usr/bin/env bash
# 用法: example_build.sh <examples/NN_slug 相对路径> <工程根>
set -euo pipefail
EX=$1; ROOT=$2; NAME=$(basename "$EX"); BUILD="$ROOT/build/$NAME"
mkdir -p "$BUILD/gen"
SRCS=()
if [ -f "$EX/TIP.g4" ]; then
  java -jar "$ROOT/build/antlr/antlr.jar" -Dlanguage=Cpp -visitor -no-listener \
       -o "$BUILD/gen" "$EX/TIP.g4"
  SRCS+=("$BUILD/gen"/TIPLexer.cpp "$BUILD/gen"/TIPParser.cpp)
fi
for f in "$EX"/src/*.cpp; do SRCS+=("$f"); done
FLAGS=(-std=c++17 -Wall -Wextra -Werror
       -I"$BUILD/gen" -I"$ROOT/build/antlr/include")
LIBS=("$ROOT/build/antlr/lib/libantlr4-runtime.a")
if [ -f "$EX/llvm.need" ]; then
  mapfile -t LCXX < <(llvm-config --cxxflags | tr ' ' '\n' | grep -v '^-std=')
  mapfile -t LLIB < <(llvm-config --ldflags --link-shared \
       --libs core orcjit support native analysis passes --system-libs)
  FLAGS+=("${LCXX[@]}"); LIBS+=("${LLIB[@]}")
fi
g++ "${FLAGS[@]}" "${SRCS[@]}" "${LIBS[@]}" -o "$BUILD/tipa"
echo "[build $NAME OK]"
```

- [ ] **Step 5: run-all.sh（总入口；非 UCRT64 时自动重启进 MSYS2）**

```bash
#!/usr/bin/env bash
set -euo pipefail
MSYS=/g/scoop/apps/msys2/current
if [ "${MSYSTEM:-}" != "UCRT64" ]; then
  exec "$MSYS/usr/bin/bash" -lc "cd '$(pwd)' && ./run-all.sh $*"
fi
export PATH=/ucrt64/bin:$PATH
ROOT=$(cd "$(dirname "$0")" && pwd); cd "$ROOT"
PY=${PYTHON:-python}
FILTER="$*"
for d in examples/*/; do
  name=$(basename "$d")
  if [ -n "$FILTER" ] && ! echo "$name" | grep -E "$FILTER"; then continue; fi
  bash tools/example_build.sh "${d%/}" .
  "$PY" tools/check_example.py "${d%/}"
done
"$PY" tools/check_docs.py
```

- [ ] **Step 6: build.ps1（pwsh 委托 MSYS2）**

```powershell
#!/usr/bin/env pwsh
# 静态分析教程统一构建入口；全部工具链在 scoop MSYS2 UCRT64 内
$ErrorActionPreference = 'Stop'
$root = 'G:\code\guide\compiler'
$filter = ($args | ForEach-Object { "'$_'" }) -join ' '
& G:\scoop\apps\msys2\current\usr\bash.exe -lc "cd '$root' && ./run-all.sh $filter"
```

- [ ] **Step 7: tools/check_example.py（单示例对账）**

```python
#!/usr/bin/env python
# 对 examples/NN_slug 做对账：
#   无 programs/ → 简单程序：无参运行，stdout(+stderr) 对 expected/output.txt，
#                            退出码对 expected/exit.txt（默认 0）
#   有 programs/ → 对 programs/*.tip 依次 tipa --check，拼接 "== file ==" 头，
#                  对 expected/output.txt；programs/errors/*.tip 对 expected/errors/<stem>.txt，
#                  期望退出码非零；expected/run、expected/soundness、expected/opt 按需对账
import pathlib, subprocess, sys

MSYS_BASH = r"G:\scoop\apps\msys2\current\usr\bash.exe"

def run(cmd, stdin=None):
    p = subprocess.run(cmd, input=stdin, capture_output=True, text=True, encoding="utf-8")
    return p.returncode, p.stdout + p.stderr

def read_inputs(path):
    runs = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            runs.append(line)
    return runs

def main(ex):
    ex = pathlib.Path(ex)
    tipa = ex.parents[1] / "build" / ex.name / "tipa.exe"
    exp = ex / "expected"
    progs = ex / "programs"
    if not progs.is_dir():                       # 简单示例（01-03）
        want_code = int((exp / "exit.txt").read_text().strip()) if (exp / "exit.txt").exists() else 0
        code, out = run([str(tipa)])
        assert code == want_code, f"exit {code} != {want_code}"
        assert out == (exp / "output.txt").read_text(encoding="utf-8"), "stdout mismatch"
        print(f"[check {ex.name} OK]"); return
    # --check 正常样例
    chunks = []
    for f in sorted(progs.glob("*.tip")):
        chunks.append(f"== {f.name} ==")
        code, out = run([str(tipa), "--check", str(f)])
        assert code == 0, f"{f.name}: exit {code}\n{out}"
        chunks.append(out.rstrip("\n"))
    got = "\n".join(c for c in chunks if c) + "\n"
    assert got == (exp / "output.txt").read_text(encoding="utf-8"), "analysis output mismatch"
    # 错误样例
    errfiles = sorted((progs / "errors").glob("*.tip")) if (progs / "errors").is_dir() else []
    for f in errfiles:
        code, out = run([str(tipa), "--check", str(f)])
        assert code != 0, f"{f.name}: 期望报错但退出 0"
        assert out == (exp / "errors" / f"{f.stem}.txt").read_text(encoding="utf-8"), \
               f"{f.name}: 诊断文本不符"
    # --run / --verify-soundness（.inputs 与 .txt 同名成对）
    for sub, flag in (("run", "--run"), ("soundness", "--verify-soundness")):
        d = exp / sub
        if not d.is_dir():
            continue
        for inf in sorted(d.glob("*.inputs")):
            runs = read_inputs(inf)
            code, out = run([str(tipa), flag, str(progs / f"{inf.stem}.tip"), str(inf)])
            assert code == 0, f"{sub}/{inf.stem}: exit {code}\n{out}"
            assert out == (d / f"{inf.stem}.txt").read_text(encoding="utf-8"), \
                   f"{sub}/{inf.stem} 输出不符"
    # opt 对照（*.cmd 配 *.out）
    od = exp / "opt"
    if od.is_dir():
        for cmdfile in sorted(od.glob("*.cmd")):
            cmd = f"cd '{pathlib.Path.cwd().as_posix()}' && {cmdfile.read_text(encoding='utf-8').strip()}"
            p = subprocess.run([MSYS_BASH, "-lc", cmd], capture_output=True, text=True)
            assert p.returncode == 0, p.stderr
            want = (od / f"{cmdfile.stem}.out").read_text(encoding="utf-8")
            assert p.stdout == want, f"opt/{cmdfile.stem} 漂移"
    print(f"[check {ex.name} OK]")

if __name__ == "__main__":
    main(sys.argv[1])
```

- [ ] **Step 8: tools/check_docs.py（docs 自包含核查）**

```python
#!/usr/bin/env python
# 每篇 docs：≥200 行；src/、TIP.g4、expected 文本全部以标记代码块嵌入且字节一致
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
FENCE = re.compile(r"```([A-Za-z0-9_]*)\n(.*?)\n```", re.S)
MARK = re.compile(r"^(// file: |; expected: )(.+)$")

def check(doc):
    text = doc.read_text(encoding="utf-8")
    assert len(text.splitlines()) >= 200, f"{doc.name}: 不足 200 行"
    # docs/NN-slug → examples/NN_slug（slug 内连字符也转下划线）
    num, slug = doc.stem.split("-", 1)
    ex = ROOT / "examples" / f"{num}_{slug.replace('-', '_')}"
    seen = set()
    for lang, body in FENCE.findall(text):
        first, *rest = body.split("\n")
        m = MARK.match(first)
        if not m:
            continue
        target = ex / m.group(2)
        content = "\n".join(rest)
        assert target.is_file(), f"{doc.name}: 标记文件不存在 {target}"
        assert content == target.read_text(encoding="utf-8").rstrip("\n"), \
               f"{doc.name}: 代码块与 {target} 不一致"
        seen.add(target)
    if ex.is_dir():
        want = set()
        if (ex / "src").is_dir():
            want.update(p for p in (ex / "src").rglob("*") if p.is_file())
        if (ex / "TIP.g4").is_file():
            want.add(ex / "TIP.g4")
        if (ex / "expected").is_dir():
            want.update(p for p in (ex / "expected").rglob("*.txt") if p.is_file())
        missing = want - seen
        assert not missing, f"{doc.name}: 未嵌入 {[str(m.relative_to(ex)) for m in missing]}"
    print(f"[docs {doc.name} OK]")

docs = sorted((ROOT / "docs").glob("*.md"))
list(map(check, docs)) if docs else None
print(f"[check_docs: {len(docs)} chapters]")
```

- [ ] **Step 9: README 骨架**

```markdown
# 静态分析教程（ANTLR4 + LLVM）

以 Anders Møller & Michael I. Schwartzbach《Static Program Analysis》为骨架，在 TIP 语言上系统实现类型分析、格与不动点数据流、widening、上下文敏感、IFDS/IDE、控制流与指针分析、抽象解释。ANTLR4 构建前端，LLVM（ORC JIT）让程序真实运行以检验分析结论。

构建：`pwsh ./build.ps1`（Windows）或 `./run-all.sh`（Git Bash 自动进入 UCRT64）。首次使用先在 UCRT64 shell 内运行 `bash tools/bootstrap.sh`。

> 30 章导航在全部章节完成后补全。
```

- [ ] **Step 10: 提交**

```bash
cd /g/code/guide && git add compiler
git commit -m "feat(compiler): 批次一骨架——环境引导（LLVM/GCC/ANTLR 源码构建）+通用构建与双对账脚本

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 2: 第一篇——为什么静态分析（ch01–02）

简单示例（无 programs/）：一个 main.cpp，固定文本输出，expected/output.txt 逐字节对账。

| 章 | 示例 |
|---|---|
| 01 | `examples/01_overview/` |
| 02 | `examples/02_undecidability/` |

**Interfaces:**
- Produces: 每目录 `src/main.cpp`（仅一个翻译单元）；`expected/output.txt`。

**01 内容规格：** main.cpp 用固定文本演示 spa ch1 四应用与"同一程序三种工具各知道什么"：硬编码小程序 `x = input; output x/x;`，分别打印三段固定文本——编译器视角（知道语法/能执行，不知道输入是否为 0）、lint 视角（规则匹配，可能漏掉除法）、分析器视角（推出 `x` 可能为 0、除法可能除零）。再打印四应用清单（验证、缺陷发现、编译优化、安全分析）。末行 `[chapter 01 OK]`。

**02 内容规格：** main.cpp 打印三段论证（全部固定文本，不真做数学证明）：(a) 停机问题归约直觉（若分析器总能判定"此程序是否除零"，可构造自指程序推出矛盾）；(b) Rice 定理推论：非平凡语义性质不可判定；(c) sound/complete 四格表（sound&complete 不可能 / sound 漏报 / complete 误报 / 都不保证）与精度—成本谱系一句。末行 `[chapter 02 OK]`。

- [ ] **Step 1: 写两个 src/main.cpp + expected 占位**

先写 main.cpp；expected/output.txt 暂写一行占位。

- [ ] **Step 2: 构建并拿到真实输出**

```bash
./run-all.sh '^0[12]_'
```

check_example 会失败（output 不符）——把 build/01_overview/tipa.exe 实际输出（直接运行该 exe 并合并 stderr）原样覆盖 expected/output.txt，人工核对内容与上面规格一致。

- [ ] **Step 3: 写两篇 docs（正文 ≥200 行；嵌入 main.cpp 与 expected）**

代码块格式：

````markdown
```cpp
// file: src/main.cpp
<整文件内容>
```
````

- [ ] **Step 4: 全量对账（含 check_docs）+ 提交**

```bash
./run-all.sh
cd /g/code/guide && git add compiler
git commit -m "feat(compiler): 批次二——01-02 静态分析动机与不可判定性（全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 3: 第二篇前段——TIP 导览、ANTLR 文法、AST（ch03–05）

| 章 | 示例 | 新增 |
|---|---|---|
| 03 | `03_tip_tour` | 简单示例：src/main.cpp 打印 TIP 构造总览，并用三种 C++ 写法（迭代/递归/模拟 foo 的指针路径）算阶乘，三个值都必须是 120 |
| 04 | `04_antlr_grammar` | TIP.g4（完整版）、src/main.cpp（parse-tree 驱动）、programs/ |
| 05 | `05_ast` | 从 04 复制；src/ast.hpp、ast_build.{hpp,cpp}、pretty.{hpp,cpp} |

**Interfaces:**
- Consumes: build/antlr/antlr.jar 生成的 TIPLexer/TIPParser。
- Produces（ch04，后续所有章节依赖，不得改名）:
  - 文法规则名：`program, function, params, varDecls, stmt, lvalue, expr, field, args, singleExpr`
  - parser 入口：`TIPParser::ProgramContext* program()`、`TIPParser::SingleExprContext* singleExpr()`。
- Produces（ch05）: AST 类型与构建器（后续章节冻结此接口）：

```cpp
// ast.hpp
namespace tip {
enum class BOp { Add, Sub, Mul, Div, Gt, Eq };
struct Expr { virtual ~Expr()=default; };
struct IntLit : Expr { int v; };
struct VarRef : Expr { std::string name; };
struct InputE : Expr {};
struct Binop  : Expr { BOp op; std::unique_ptr<Expr> l, r; };
struct CallE  : Expr { std::unique_ptr<Expr> callee; std::vector<std::unique_ptr<Expr>> args; };
struct Deref  : Expr { std::unique_ptr<Expr> e; };
struct AddrOf : Expr { std::string name; };                 // spa: & Id
struct AllocE : Expr { std::unique_ptr<Expr> e; };
struct NullE  : Expr {};
struct RecLit : Expr { std::vector<std::pair<std::string,std::unique_ptr<Expr>>> fields; };
struct FieldA : Expr { std::unique_ptr<Expr> e; std::string field; };
struct Stmt { virtual ~Stmt()=default; };
struct AssignS : Stmt { std::unique_ptr<Expr> target, value; };  // target 仅 VarRef/FieldA/Deref
struct OutputS : Stmt { std::unique_ptr<Expr> e; };
struct IfS     : Stmt { std::unique_ptr<Expr> cond; std::unique_ptr<Stmt> then, els; };
struct WhileS  : Stmt { std::unique_ptr<Expr> cond; std::unique_ptr<Stmt> body; };
struct BlockS  : Stmt { std::vector<std::unique_ptr<Stmt>> ss; };
struct ReturnS : Stmt { std::unique_ptr<Expr> e; };
struct FunDecl { std::string name; std::vector<std::string> params;
                 std::vector<std::string> vars; std::unique_ptr<Stmt> body;
                 std::unique_ptr<ReturnS> ret; };
struct ProgramA { std::vector<std::unique_ptr<FunDecl>> funs; };
}
```

- [ ] **Step 1: ch03（简单示例，规格同上表）**

main.cpp 打印：TIP 语法构造分类表（表达式 6 类/语句 5 类/函数/指针/记录），然后 `iter(5)==120 && recf(5)==120 && fooPath(5)==120`（fooPath 用 C++ 指针模拟 foo：int q; *p==0 分支），打印 `factorial: 120 120 120` 与 `[chapter 03 OK]`。

- [ ] **Step 2: ch04 TIP.g4 完整内容**

```antlr
grammar TIP;

program    : function+ EOF ;
singleExpr : expr EOF ;
function   : IDENT LPAREN params? RPAREN LBRACE varDecls? stmt* RETURN expr SEMI RBRACE ;
params     : IDENT (COMMA IDENT)* ;
varDecls   : VAR IDENT (COMMA IDENT)* SEMI ;

stmt       : lvalue ASSIGN expr SEMI                # assignStmt
           | OUTPUT expr SEMI                      # outputStmt
           | IF LPAREN expr RPAREN stmt (ELSE stmt)? # ifStmt
           | WHILE LPAREN expr RPAREN stmt         # whileStmt
           | LBRACE stmt* RBRACE                   # blockStmt
           ;
lvalue     : IDENT (DOT IDENT)?                    # directLvalue
           | STAR expr (DOT IDENT)?                # pointerLvalue
           ;

expr       : expr LPAREN args? RPAREN              # callExpr
           | expr DOT IDENT                        # fieldExpr
           | STAR expr                             # derefExpr
           | AND IDENT                             # addrExpr
           | ALLOC expr                            # allocExpr
           | MINUS expr                            # negExpr
           | expr (MUL|DIV) expr                   # mulExpr
           | expr (PLUS|MINUS) expr                # addExpr
           | expr (GT|EQ) expr                     # cmpExpr
           | INT                                   # intExpr
           | IDENT                                 # varExpr
           | INPUT                                 # inputExpr
           | NULL                                  # nullExpr
           | LPAREN expr RPAREN                    # parenExpr
           | LBRACE field (COMMA field)* RBRACE    # recExpr
           ;
field      : IDENT COLON expr ;
args       : expr (COMMA expr)* ;

WS         : [ \t\r\n]+ -> skip ;
BLOCK_CMT  : '/*' .*? '*/' -> skip ;
LINE_CMT   : '//' ~[\r\n]* -> skip ;
INPUT      : 'input' ;
OUTPUT     : 'output' ;
IF         : 'if' ;
ELSE       : 'else' ;
WHILE      : 'while' ;
VAR        : 'var' ;
RETURN     : 'return' ;
ALLOC      : 'alloc' ;
NULL       : 'null' ;
IDENT      : [a-zA-Z_][a-zA-Z0-9_]* ;
INT        : [0-9]+ ;
ASSIGN     : '=' ;
EQ         : '==' ;
GT         : '>' ;
PLUS       : '+' ;
MINUS      : '-' ;
STAR       : '*' ;
DIV        : '/' ;
LPAREN     : '(' ; RPAREN : ')' ;
LBRACE     : '{' ; RBRACE : '}' ;
SEMI       : ';' ; COMMA : ',' ; DOT : '.' ; COLON : ':' ;
```

要点（写进 ch04 正文）：负数字面量按 Exercise 2.1 的"欠定义处自行选择"实现为前缀 `MINUS expr`（等价 0−v 语义）；关键字规则必须在 IDENT 之前；悬空 else 由 ANTLR LL(*) 默认匹配最近 else（确定性）。

- [ ] **Step 3: ch04 src/main.cpp 与 programs**

main.cpp：手写极简 argv 解析，`--check FILE` → ANTLRInputStream/CommonTokenStream/TIPParser，调用 `parser.program()`；语法错（`parser.getNumberOfSyntaxErrors()>0`）打印 `syntax error` 退出 2；成功用 `antlrcpp::trees::TreeDecorator`?——用 `antlr4::tree::Trees::toStringTree(&parser)` 打印 parse tree。programs：
- `programs/ite.tip`：spa 书 ite 阶乘原样；
- `programs/twice.tip`：twice/inc/main 三函数原样；
- `programs/errors/badsyntax.tip`：`main(x){ return x + ; }`。

- [ ] **Step 4: 构建 ch04，生成 expected**

```bash
./run-all.sh '^04_'
```

把两次成功 parse-tree 输出与错误诊断对账为 expected/output.txt、expected/errors/badsyntax.txt（错误退出码非零由脚本校验）。

- [ ] **Step 5: ch05——从 04 复制并新增 AST 层**

```bash
cp -r examples/04_antlr_grammar examples/05_ast
rm -rf build/05_ast   # build/ 内旧 gen 清掉（如有）
```

ast_build.{hpp,cpp}：`BuildAst : TIPBaseVisitor<antlrcpp::Any>`，每个 #标签一个 visit 方法，返回 `std::unique_ptr<Expr/Stmt>`；Binop 由规则备选映射 BOp。programs 增加 `rec.tip`（含记录字面量与字段读取的函数）。pretty.{hpp,cpp}：`std::string print(const ProgramA&)`，固定前缀式语法（如 `fun main(x) { output (== x 0) ; return (-(?)) }`——以实际实现为准并在正文完整给出语法约定表）。main.cpp 的 --check：parse → BuildAst → print。

- [ ] **Step 6: 构建 ch05 + expected；写 03–05 三章 docs**

每章 docs 嵌入该章全部新增 src 文件与 expected（ch05 文档嵌入 5 个文件：TIP.g4、main.cpp、ast.hpp、ast_build.hpp/.cpp、pretty.hpp/.cpp 全部）。

- [ ] **Step 7: 全量回归 + 提交**

```bash
./run-all.sh
cd /g/code/guide && git add compiler
git commit -m "feat(compiler): 批次三——03-05 TIP 导览/ANTLR 文法工程/AST 构建（全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 4: 第二篇后段——作用域、CFG、LLVM 执行台（ch06–08）

| 章 | 示例 | 新增 |
|---|---|---|
| 06 | `06_scopes` | symtab.{hpp,cpp}：Scope/SymbolTable/resolve；main.cpp --check 输出绑定结果 |
| 07 | `07_cfg` | cfg.{hpp,cpp}：程序点编号、pred/succ |
| 08 | `08_llvm_run` | llvm.need；irgen.{hpp,cpp}；jitrun.{hpp,cpp}；tiprt 声明；--emit-ir/--run |

**Interfaces:**
- Produces（ch06）:
```cpp
// symtab.hpp
namespace tip {
struct Symbol { enum Kind { Fun, Param, Local } kind; std::string name; const FunDecl* fun; };
struct Scope { Scope* parent; std::map<std::string,Symbol> table;
               const Symbol* lookup(const std::string&) const; };
struct Diag { std::string text; };
struct Bindings { std::vector<Diag> errors;
                  std::map<const VarRef*, const Symbol*> uses; };
Bindings resolveNames(ProgramA&);          // 两遍：先注册全部函数名，再逐函数建作用域
}
```
- Produces（ch07）:
```cpp
// cfg.hpp
namespace tip {
using PP = int;                              // 程序点编号（entry=1 起，AST 遍历序）
struct CfgFun { std::string name; PP entry, exit;
                std::map<PP,const Stmt*> at;  // entry/exit 对应 nullptr
                std::map<PP,std::vector<PP>> succ, pred; };
struct Cfg { std::vector<CfgFun> funs; std::map<const FunDecl*,PP> funExit; };
Cfg buildCfg(const ProgramA&);
}
```
- Produces（ch08）:
```cpp
// irgen.hpp
namespace tip {
struct IRGen { llvm::LLVMContext ctx; llvm::Module mod{ "tip", ctx };
               llvm::IRBuilder<> b{ctx};
               std::map<const Symbol*, llvm::AllocaInst*> locals;
               const FunDecl* cur = nullptr;
               explicit IRGen();                       // 注册 tip_input/tip_output 声明
               void gen(const ProgramA&);              // 生成全部函数 + tip_main + main
               llvm::Value* expr(const Expr*);
               void stmt(const Stmt*);
               bool verify() const;                    // llvm::verifyModule
};
}
```

- [ ] **Step 1: ch06 实现 resolveNames**

两遍算法（正文对应"为什么需要两遍"：main 调 ite 时 ite 可能尚未声明）。输出格式（--check）：每函数按遍历序打印 `use <行?> <name> -> <fun/param/local>`（不打行号——AST 当前无位置，改用序号），错误逐条 `error: <undeclared/redeclared> <name>`。programs：good.tip（前向调用+var）、errors/undecl.tip、errors/redecl.tip（参数与 var 同名）。

- [ ] **Step 2: 构建 ch06 + expected**

- [ ] **Step 3: ch07 buildCfg（归纳构造，正文对照 spa 2.5 四节点图）**

Stmt 分派：Assign/Output 单出边；If 条件块分出 then/els→汇合（无 els 时条件直连汇合）；While 四块（header→body→header、header→exit）；Block 顺序拼接（退出节点消除法在编号阶段直接连边）。--check 打印每函数 `pp N: <stmt 简记>` 与 `succ: ...`。programs：ite.tip、branches.tip（if 无 else 嵌套 while）。

- [ ] **Step 4: 构建 ch07 + expected**

- [ ] **Step 5: ch08 irgen 表达式/语句/函数（不含指针记录间接调用）**

关键生成规则（正文逐条讲）：int→i32 常量；Binop：算术对应指令，Gt/Eq 生成 i1 后 `b.CreateZExt(..., i32)`（TIP 谓词值为 0/1）；VarRef→locals 查找→load；input→`call i32 @tip_input()`；Assign：左值为 VarRef 时 store；Output：call @tip_output；If/While：cond 先 `CreateICmpNE(..., 0)` 再条件跳转；var 声明与参数：入口 alloca+store；函数：FunctionType(i32, i32…)*；main 特殊包装：

```llvm
define i32 @main() { %r = call i32 @tip_main() ; ret i32 %r }
define i32 @tip_main() { ; 按 main 形参数目逐个 call tip_input，再 call @main
}
```

- [ ] **Step 6: ch08 JIT 运行（--run）**

jitrun.cpp：创建 LLJIT；`tip_input/tip_output` 用 absoluteSymbols 注入两个 C 函数（input 从 `std::vector<int>` 弹出，output push_back 并同时计数）；--run 对 INPUTS 每行真实执行，输出 `run k: <逗号分隔输出值>`。--emit-ir：dump 模块（不优化）。programs：ite.tip、outputs.tip（连续 output 含 input）；expected/run/ite.{inputs,txt}（5→120；0→1）等。构建后必须 `IRGen::verify()` 通过。

- [ ] **Step 7: 构建 ch08 + expected（IR 文本与 run 输出均取真实产物）**

```bash
./run-all.sh '^0[678]_'
```

- [ ] **Step 8: 写 06–08 docs（全部 src 与 expected 嵌入）；全量回归 + 提交**

```bash
./run-all.sh
git add compiler
git commit -m "feat(compiler): 批次四——06-08 名字解析/CFG/LLVM IR 生成与 ORC 执行台（全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 5: 第三篇——类型分析（ch09–12，spa ch3）

| 章 | 示例 | 新增 |
|---|---|---|
| 09 | `09_type_vars` | type.hpp：Type 类族 + TyVar 新鲜变量生成 |
| 10 | `10_constraints` | constraints.{hpp,cpp}：遍历 AST 生成约束，--check 打印约束表 |
| 11 | `11_unify` | unify.{hpp,cpp}：Robinson 合一 + Substitution |
| 12 | `12_records_limits` | 记录字段约束、解器总装、错误矩阵；--check 打印每个表达式最终类型 |

**Interfaces:**
```cpp
// type.hpp
namespace tip {
using Tp = std::shared_ptr<Type>;
struct Type { virtual std::string show() const=0; virtual ~Type()=default; };
struct TyInt : Type { std::string show() const override { return "int"; } };
struct TyPtr : Type { Tp to; };
struct TyFun : Type { std::vector<Tp> params; Tp ret; };
struct TyRec : Type { std::vector<std::pair<std::string,Tp>> fields; };
struct TyVar : Type { int id; static int fresh(); };
Tp tint(), tvar();   // 便利构造
}
// constraints.hpp
struct Con { Tp a, b; std::string why; };
std::vector<Con> collect(const ProgramA&);   // 每个 AST 节点一个新鲜变量，按产生式连约束
// unify.hpp
using Subst = std::map<int,Tp>;
Tp apply(Subst&, Tp);                        // 反复代换直到非变量
void unify(Tp a, Tp b, Subst&);              // 失败抛 TypeError(what)
```

约束生成规则（ch10 正文逐条；`τ(E)` 记为表达式 E 的类型变量）：
- INT：`τ = int`；VarRef：`τ = lookup(名字的声明类型)`（参数/var：同一新鲜变量，函数名：其函数类型）；input：`τ = int`；Binop：算术 `τl=int, τr=int, τ=int`，比较同样操作数 int、结果 int；
- CallE：`τcallee = (τarg1,…,τargn) -> τ`；AllocE：`τ = ptr(τe)`；Deref：`τe = ptr(τ)`；AddrOf：`τ = ptr(decltype(Id))`；NullE：无（合一处特例：与任意 ptr 兼容）；
- RecLit/FieldA：`τ = {f1: τe1,…}`，字段读取 `τe = {…, f: τ, …}`；
- 函数：形参类型变量进入函数类型；return 约束 `ret = τ(E)`。

- [ ] **Step 1: ch09 type.hpp + main.cpp 演示**：对一个硬编码类型结构（int、ptr(int)、(int)->int、变量 αβ）打印 show 与统一化前的新鲜编号。programs 沿用上一章（--check 本章改为类型构造演示 + parse）。

- [ ] **Step 2: ch10 collect**：--check 按程序点顺序打印 `τN == <结构>   ; <why>`。programs：arith.tip、ptr.tip（含 alloc/deref/地址）、rec.tip。

- [ ] **Step 3: ch11 unify，核心算法照此实现（正文逐行讲）**

```cpp
namespace tip {
Tp apply(Subst& s, Tp t) {
    while (auto* v = dynamic_cast<TyVar*>(t.get())) {
        auto it = s.find(v->id);
        if (it == s.end()) break;
        t = it->second;
    }
    return t;
}
static Tp occurs(int id, Tp t) { (void)id; return t; }
void unify(Tp aa, Tp bb, Subst& s) {
    Tp a = apply(s, aa), b = apply(s, bb);
    auto* va = dynamic_cast<TyVar*>(a.get()); auto* vb = dynamic_cast<TyVar*>(b.get());
    if (va && vb && va->id == vb->id) return;
    if (va) {
        if (std::dynamic_pointer_cast<TyVar>(b) == nullptr && containsVar(b, va->id))
            throw TypeError("occurs check");
        s[va->id] = b; return;
    }
    if (vb) { unify(b, a, s); return; }
    if (typeid(*a) != typeid(*b)) throw TypeError("type mismatch");
    if (auto* p = dynamic_cast<TyPtr*>(a.get()))
        unify(p->to, dynamic_cast<TyPtr&>(*b).to, s);
    else if (auto* f = dynamic_cast<TyFun*>(a.get())) {
        auto& g = dynamic_cast<TyFun&>(*b);
        if (f->params.size() != g.params.size()) throw TypeError("arity");
        for (size_t i = 0; i < f->params.size(); ++i) unify(f->params[i], g.params[i], s);
        unify(f->ret, g.ret, s);
    } else if (auto* r = dynamic_cast<TyRec*>(a.get())) {
        auto& q = dynamic_cast<TyRec&>(*b);
        if (r->fields.size() != q.fields.size()) throw TypeError("record shape");
        for (auto& [n, t] : r->fields) {
            auto it = std::find_if(q.fields.begin(), q.fields.end(),
                                   [&](auto& kv){ return kv.first == n; });
            if (it == q.fields.end()) throw TypeError("no field " + n);
            unify(t, it->second, s);
        }
    }
}
}
```

`containsVar`：递归检查结构中是否出现该 TyVar（occurs check）。NullE 处理：收集阶段不生成等式，而在解器总装（ch12）增加规则"ptr(T) 与 null 相容"——实现上把 null 赋一个特殊新鲜变量，unify 遇到 TyNull 与 TyPtr 直接成功；type.hpp 增 `struct TyNull : Type`。

--check ch11：对 ch10 约束求解，打印 `solution: τN -> <apply 后的 show>`。

- [ ] **Step 4: ch12 总装与错误矩阵**

--check：完整 collect→unify→apply，按表达式打印类型；错误 programs/errors/：binop-on-ptr、deref-int、arity、bad-field、unify-occurs（自引用构造，经手写程序触发 α=ptr(α) 场景），每个 expected/errors/*.txt 为固定诊断文本。正文讲 spa 3.5：流不敏感（`if (...) x=1; else x=&y;` 类型矛盾或被迫近似）、无多态（同一函数多次调用共享一个类型变量）。

- [ ] **Step 5: 构建 ch09–12 + expected；写四章 docs；全量回归 + 提交**

```bash
./run-all.sh
git add compiler
git commit -m "feat(compiler): 批次五——09-12 类型变量/约束/Robinson 合一/记录与局限（全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 6: 第四篇前段——格、构造、不动点与算法（ch13–16，spa ch4）

| 章 | 示例 | 新增 |
|---|---|---|
| 13 | `13_sign_lattice` | sign.hpp（Sign 域 {−,0,+,⊤,⊥} + Lattice 概念）、sign_transfer（单趟局部） |
| 14 | `14_lattice_build` | lattice.hpp：提升/积/映射/幂集泛型；state 映射格 |
| 15 | `15_fixpoint` | equations.{hpp,cpp}：为 CFG 生成单调方程，--check 打印方程 |
| 16 | `16_worklist` | solve.{hpp,cpp}：worklist 不动点求解，--check 得最终符号状态 |

**Interfaces:**
```cpp
// lattice.hpp（ch13 先给概念，ch14 补全构造）
namespace tip {
template<class A> struct Lattice {
    A top, bot;
    bool eq(const A&, const A&) const;
    bool leq(const A&, const A&) const;
    A join(const A&, const A&) const;
};
// ch14 构造：
template<class A> Lattice<optional<A>> lift(const Lattice<A>&);     // ⊥=nullopt,⊤ 提升
template<class... A> Lattice<tuple<A...>> product(const Lattice<A>&...);
template<class K,class V> Lattice<std::map<K,V>> maps(const Lattice<V>&, const std::set<K>&);
template<class K> Lattice<std::set<K>> powerset();                  // ∪/∩，序=包含
using SignState = std::map<PP,int>;   // PP→Sign 编码 -2..2（⊥ -2, ⊤ 2）
}
// equations.hpp（ch15）
struct MonoEq { PP point; std::vector<PP> deps; std::string expr; };
std::vector<MonoEq> signEquations(const Cfg&);  // out = join(pred transfers)，文本为可读表达
// solve.hpp（ch16）
SignState solveFixpoint(const Cfg&, const std::vector<MonoEq>&);  // 初值全 ⊥
```

- [ ] **Step 1: ch13 Sign 域**：sign.hpp 实现 join 表（如 `+ ⊔ 0 = ⊤`）；sign_transfer：对程序点做单趟（按 AST/CFG 顺序一遍）符号推导：算术符号规则（`+`: (+,+)→+，(+,−)→⊤…；乘法符号表；比较→{0,+}）。programs/sign1.tip（spa 4.1 动机例：含 x=x+1 循环），--check 打印每点单趟结果——故意在循环回边上不正确（正文点明：缺不动点）。

- [ ] **Step 2: ch14 lattice 构造**：用 Sign 域演示 maps（变量状态）、product（多变量）、powerset（备用，ch18 用）；--check 打印三个构造域上 `join` 的固定示例结果。

- [ ] **Step 3: ch15 equations**：signEquations 为每点生成 `vPP = transfer(stmt)( join vpred )` 文本；--check 按点打印。正文对应 spa 4.4：单调性证明（每条 transfer 单调、join 单调、复合单调）。

- [ ] **Step 4: ch16 worklist**：实现

```cpp
SignState solveFixpoint(const Cfg& cfg, const std::vector<MonoEq>& eqs) {
    SignState cur;                                  // 缺省 ⊥(-2)
    std::deque<PP> wl;
    std::set<PP> in;
    for (auto& f : cfg.funs) wl.push_back(f.entry);
    while (!wl.empty()) {
        PP p = wl.front(); wl.pop_front(); in.erase(p);
        int nv = evalTransfer(p, cur, cfg);         // 局部 transfer(join(pred states))
        int old = cur.count(p) ? cur[p] : -2;
        if (nv != old) {
            cur[p] = nv;                            // 单调框架保证 nv ≥ old
            for (PP s : succOf(cfg, p)) if (!in.count(s)) { wl.push_back(s); in.insert(s); }
        }
    }
    return cur;
}
```

--check：sign1 完整正确状态（循环后 x=+）。正文讲终止性：有限格 + 每次严格上升 + 高度有限；复杂度上界 O(点数 × 格高)。

- [ ] **Step 5: 构建 + expected；写四章 docs；全量回归 + 提交**

```bash
git add compiler
git commit -m "feat(compiler): 批次六——13-16 符号格/格构造/单调方程/worklist 不动点（全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 7: 第四篇后段——符号与常量落地、经典 DFA、传递函数（ch17–19）

| 章 | 示例 | 新增 |
|---|---|---|
| 17 | `17_sign_const` | constant.hpp（常量格 i32 常量/⊤/⊥）；soundness.cpp（--verify-soundness）；opt 对照 |
| 18 | `18_classic_dfa` | dfa.{hpp,cpp}：活跃/到达/可用/非常忙四分析（后向也在框架内） |
| 19 | `19_transfer` | init.{hpp,cpp}：可能未初始化分析；框架分类总表输出 |

**Interfaces:**
```cpp
// constant.hpp：Lattice<optional<int>>（⊥=不可达，nullopt? 约定：struct Const { int kind; int v; }
//   kind: 0 ⊥, 1 常量(v), 2 ⊤）；transfer：赋值折叠常量表达式，遇 input/非常量→⊤
// soundness.cpp：
//   --verify-soundness：先跑符号分析得每个 output 点 Sign 集合；JIT 执行 INPUTS 每次运行，
//   把具体输出值转符号成员，断言 ∈ 预测；再用常量分析对常量点断言 JIT 值逐点相等。
// dfa.hpp：四个分析统一为 Cfg 上的幂集格 + 方向与 may/must 参数：
struct DfaSpec { std::string name; bool forward; bool may;          // may=∪/must=∩
                 std::function<std::set<std::string>(const Stmt*)> gen, kill; };
std::map<PP,std::set<std::string>> runDfa(const Cfg&, const DfaSpec&);
```

四分析 gen/kill（ch18 正文详表）：
- 活跃变量（后向 may）：gen=右值，kill=赋值目标；
- 到达定值（前向 may）：gen=本定值（带编号 dN），kill=同变量其他定值；
- 可用表达式（前向 must）：gen=语句计算的表达式，kill=含被赋值变量的表达式；
- 非常忙（后向 must）：gen/kill 同可用式，方向后向。

初始值差异（正文讲）：may 分析起点 ⊥（∅），must 分析（可用/非常忙）非入口点 ⊤（全集）、入口 ⊥。

- [ ] **Step 1: ch17 constant + soundness**

--check：先打印 SIGN 段（复用 ch16），再 CONST 段（每点 `c=<n> / TOP / BOT`）。programs：sign1.tip、fold.tip（常量折叠与 input 混合）。expected/soundness/sign1.{inputs,txt}（多组输入含 0/正/负），输出格式：

```text
run 1: outputs <…> ; membership OK
SOUND 4 runs, 7 observations
```

opt 对照：expected/opt/sccp.cmd：
```bash
build/17_sign_const/tipa --emit-ir examples/17_sign_const/programs/fold.tip | opt -passes=sccp -S
```
对应 sccp.out 用真实产物提交。正文用两栏并排讲"我们的常量格 join 规则 = SCCP 同时做的稀疏条件常量"。

- [ ] **Step 2: ch18 runDfa 四分析**

programs/classic.tip（含 3–4 个定值、两个分支与循环）。--check 四段输出，每点集合 `{d1 x …}`（空集打印 `{}`）。正文统一分类表：方向（前/后）×合并（may∪/must∩）×初始值，并解释为什么四种组合各有经典代表。

- [ ] **Step 3: ch19 init 分析与框架收官**

可能未初始化（spa 9.1 提前在此讲）：前向 may，幂集元素=变量名，entry 收集 main 参数为已初始化，var 声明为未初始化 gen。--check 打印警告点 + MonotoneFramework 形式化定义（五元组：格、方向、边界条件、初始值、传递函数族）与正确性定理陈述（若 merge-over-paths 近似收集语义，则所有点 sound）。

- [ ] **Step 4: 构建 + expected；写三章 docs；全量回归 + 提交**

```bash
git add compiler
git commit -m "feat(compiler): 批次七——17-19 符号/常量落地与可靠性经验测试、四大 DFA、传递函数理论（全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 8: 第五篇——区间、widening、路径与过程间/上下文敏感（ch20–24，spa ch6–8）

| 章 | 示例 | 新增 |
|---|---|---|
| 20 | `20_interval` | interval.hpp：区间格（含 ±∞，join 取包络）；先朴素迭代演示循环不终止（脚本限步数 50 打印未收敛） |
| 21 | `21_widening` | widen.hpp：widening ∇（阈值表 0,1,±∞）与 narrowing Δ；expected/soundness |
| 22 | `22_path_sens` | path.{hpp,cpp}：分支条件对区间/sign 的精炼（x>k 进入分支时 x 下界=k+1） |
| 23 | `23_interproc` | callgraph.{hpp,cpp} + 过程间 CFG；被调函数 ⊤ 近似 vs 内联展开对比输出 |
| 24 | `24_context_sens` | context.{hpp,cpp}：call-strings（k=0/1/2）与 functional approach；soundness 三档对照 |

**Interfaces:**
```cpp
// interval.hpp
struct Iv { int lo, hi; };                 // INT_MIN/INT_MAX 表 ±∞
Lattice<Iv> ivLattice();                   // join: min lo, max hi；⊥ 用 lo>hi 编码
// widen.hpp
Iv widen(const Iv& a, const Iv& b);        // 边界不在阈值表则推 ±∞
Iv narrow(const Iv& a, const Iv& b);       // 用新方程收紧一遍（不迭代）
// path.hpp
Iv refineOnBranch(const std::string& var, BOp, int k, bool taken, const Iv& cur);
// callgraph.hpp
struct CallGraph { std::map<const FunDecl*,std::vector<const CallE*>> calls; };
// context.hpp
using CtxStr = std::vector<PP>;            // 调用点串，长度 ≤ k
std::map<std::pair<CtxStr,PP>, SignState> solveContext(const Cfg&, int k);
```

- [ ] **Step 1: ch20 interval + 不终止演示**：--check 打印循环头逐次迭代值（`iter 0: [1,1] … iter N: [1,N]`），50 步后打印 `DID NOT CONVERGE`。正文从无穷高度格讲 Tarski 为何不再保证算法终止（定理仍保证不动点存在）。

- [ ] **Step 2: ch21 ∇/Δ**：widening point=循环头；∇ 规则：旧界在 {0,1} 之外且新界更松→∞；先 ∇ 到不动点，再 Δ 一遍（如循环后用法把 [0,+∞] 收 [0,100] 类例）。--check 打印 WIDEN 轨迹与 NARROW 结果。expected/soundness/iv.{inputs,txt}：JIT 多组输入断言具体输出 ∈ 预测区间（成员判定含界）。

- [ ] **Step 3: ch22 路径精炼**：programs/branch.tip（`if (x>0) output x; else output 0-x;`）：--check 对比流不敏感（output: [0,+∞]?）与路径精炼（两支分别 + / +，merge 后同，但 `if(x>5) output 100/x` 的除零点被消除的例子必须给出：分支内 x∈[6,+∞]）。正文讲 assertion 精炼=spa 7.1，路径合并点与爆炸代价。

- [ ] **Step 4: ch23 过程间**：--check 两栏：`context-insensitive: main -> TOP`（callee merge）与内联/过程间 CFG 精确结果。正文构造 spa 例：identity 函数被以不同参数调用，被调函数 merge 导致全部调用点 ⊤。

- [ ] **Step 5: ch24 k-CFA**：--check 打印 k=0/1/2 三档 main 结果（程序：twice 嵌套，k=0 混、k=1 清）；functional approach 作为"无限 k 的记忆化"实现并打印同结果。expected/soundness/ctx.{inputs,txt}：三档预测都须通过 JIT 成员检验（精度不同但都 sound——这是本章要落地的核心结论）。

- [ ] **Step 6: 构建 + expected；写五章 docs；全量回归 + 提交**

```bash
git add compiler
git commit -m "feat(compiler): 批次八——20-24 区间/widening-narrowing/路径敏感/过程间/上下文敏感（全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 9: 第六篇——IFDS、IDE、0-CFA、指针分析（ch25–28，spa ch9–11 精选）

| 章 | 示例 | 新增 |
|---|---|---|
| 25 | `25_ifds` | ifds.{hpp,cpp}：超级图构造与 path-edge tabulation |
| 26 | `26_ide` | ide.{hpp,cpp}：环境边（事实=可选常量），与 ch17 常量分析结果/计时对照（只打印结论不打耗时） |
| 27 | `27_closure_0cfa` | cfa.{hpp,cpp}：λ/函数值约束、0-CFA cubic 不动点 |
| 28 | `28_pointer` | ptrana.{hpp,cpp}：Andersen worklist 求解 + Steensgaard 合一；irgen 扩展 malloc；soundness |

**Interfaces:**
```cpp
// ifds.hpp
namespace tip {
struct IfdsProblem {
    std::set<std::string> flowFunctions(const Stmt*, std::string d); // distributive：单点输入
    std::set<std::string> seeds;                                      // entry 的初始事实
    std::set<std::string> univers;                                   // 零事实 0
};
std::map<PP,std::set<std::string>> solveIFDS(const Cfg&, const IfdsProblem&);
}
// ide.hpp：事实事实格 optional<int>，edge functions 仅 {id, const c, compose}
std::map<PP,std::map<std::string,std::optional<int>>> solveIDE(const Cfg&);
// cfa.hpp
struct CfaConstraints { std::set<std::string> lambda;                 // 函数值名
                        std::vector<std::tuple<std::string,std::string,std::string>> edges; };
std::map<std::string,std::set<std::string>> solve0Cfa(CfaConstraints); // points: var→functions
// ptrana.hpp
struct PtrCon { enum K { New, Copy, Load, Store } k; std::string a,b; };
std::map<std::string,std::set<std::string>> andersen(std::vector<PtrCon>, std::set<std::string> sites);
std::map<std::string,std::string> steensgaard(std::vector<PtrCon>);    // 合一代表元
```

- [ ] **Step 1: ch25 IFDS**：用"可能未初始化"做实例（distributive 性质正文证明：flow 函数满足 f(a⊔b)=f(a)⊔f(b)）。solveIFDS 按 spa 9.4 tabulation：PathEdge/Worklist 三类列表（path edges、call 待返、summary），同址过程内函数调用配对返回。programs：ch19 init 例 + 过程版本（main 调 f 两路径）。--check 输出与 ch19/ch23 结论交叉一致。正文解释多项式时间：边数 O(N D²)，D=有限数据事实域。

- [ ] **Step 2: ch26 IDE**：常量传播实例；edge function 三类；--check 输出与 ch17 CONST 一致并打印一行精度对照结论（不打印耗时，打印观察到的 join 次数分级：`worklist joins: N, IDE fact updates: M` 固定统计）。

- [ ] **Step 3: ch27 0-CFA**：约束生成（函数名引用→{fun}；参数绑定；返回；间接调用边按当前 points-to 集增长）；cubic worklist。programs：twice.tip（高阶）。--check：每个调用点解析到的函数集合；正文讲"鸡与蛋"用不动点解开，及与 ch24 k=0 的关系（0-CFA = 上下文不敏感）。

- [ ] **Step 4: ch28 Andersen/Steensgaard + 执行台扩展**

约束（从含指针 AST 生成）：`x = alloc L` New；`x=y` Copy；`x=*y` Load；`*x=y` Store；地址常量 `&z` 视作特殊 site。Andersen：points-to worklist，包含约束闭包（正文给规则四条并证明 sound：每条规则对应一条具体赋值/load/store 的具体边）。Steensgaard：每条约束让代表元合一（O(n)，精度更差）。irgen 在本章快照扩展：AllocE→`call i8* @malloc(4)` + bitcast + store；Deref→load；AddrOf→alloca 地址（已支持）；NullE→i32 0 作指针。programs：spa 指针示例、nullcheck.tip（`if (p==null)` 分支）。expected/soundness：JIT 跑（malloc 真实分配）断言 null 分析与 points-to 结论。--check 打印 ANDERSEN / STEENSGAARD 两栏（后者 pts 集是前者超集——正文讲精度/成本差）。

- [ ] **Step 5: 构建 + expected；写四章 docs；全量回归 + 提交**

```bash
git add compiler
git commit -m "feat(compiler): 批次九——25-28 IFDS/IDE/0-CFA/指针分析双算法（全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Task 10: 第七篇 + 收官（ch29–30，README 定稿）

| 章 | 示例 | 新增 |
|---|---|---|
| 29 | `29_abstract_interp` | ai.{hpp,cpp}：collecting semantics 状态（PP→环境幂集）与 α/γ 函数；--check 对 sign1 同时打印 concrete traces 集与抽象结果 |
| 30 | `30_finale` | Galois 重看对照表（9 个分析 × 抽象域/γ/sound 陈述）；LLVM 中端协作终览 |

**Interfaces:**
```cpp
// ai.hpp
using TraceEnv = std::map<std::string,int>;
using CollState = std::map<PP,std::set<TraceEnv>>;   // collecting semantics
CollState collect(const Cfg&);                        // 路径展开（对给定有界程序完整）
struct Galois { std::function<SignState(const CollState&)> alpha;
                std::function<CollState(const SignState&)> gamma; };
bool soundByGalois(const SignState&, const CollState&); // α∘collect ≤ analysis
```

- [ ] **Step 1: ch29 collecting + Galois**：collect 对 sign1 展开全部路径（小程序），打印每点环境集行数；α（取符号、join）、γ（枚举匹配环境）成对演示；soundness 定理完整陈述：`α(C[[p]]) ⊑ analysis`，证明结构三步（transfer 与 α 交换/合并/初始），正文给全；completeness/optimality 区别一段。

- [ ] **Step 2: ch30 收官**：--check 打印总表（固定文本：类型/符号/常量/活跃/可用/区间/路径/0CFA/Andersen 每行：域、方向、敏感维、可靠性一句话）；LLVM 部分：用 `opt -print-after-all` 在 fold.tip 上抓 mem2reg→SCCP→ simplify 三段名（不抓全文），正文讲分析—变换协作与 invalidate 依赖；延伸阅读地图（Dragon/Cooper/Torreczon/Nielson 三卷/Scala TIP/Souffle Datalog/Doop）。

- [ ] **Step 3: README 定稿**：30 章全导航（七篇分组，每条一句要点），工具链与 bootstrap 说明，验证状态一行（30/30 三层对账全绿 + check_docs 全绿）。

- [ ] **Step 4: 全量从零回归 + 提交**

```bash
pwsh ./build.ps1
cd /g/code/guide && git add compiler
git commit -m "feat(compiler): 批次十——29-30 抽象解释与收官、README 定稿（30/30 全绿）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Self-Review 记录

- **Spec 覆盖**：spa ch1→Task2；ch2（TIP 素材）→Task3；ch3→Task5；ch4→Task6；ch5→Task6/7（16/17/18/19）；ch6→Task8（20/21）；ch7→Task8（22）；ch8→Task8（23/24）；ch9→Task9（25）；ch9.5/9.6→Task9（26）；ch10→Task9（27）；ch11→Task9（28）；ch12→Task10（29）；LLVM 对照与执行台→Task4 ch08 + Task7 ch17 + Task10 ch30；写作风格（无坑清单/叙述体工程注意点）写入 Global Constraints。无缺口。
- **占位符**：所有构建脚本、文法、关键算法（unify/worklist/widen/IFDS/Andersen/Galois 接口）均给出实码；expected 文本的统一生成协议（先跑、取真实字节、人工核对规格）逐任务写明，无"TBD/适当处理"。
- **类型一致性**：AST 接口在 Task3 冻结后，Task4–10 全部使用同名（ProgramA/FunDecl/AssignS.target/CallE.callee）；CLI 四标志（--check/--run/--verify-soundness/--emit-ir）Global Constraints 统一；Cfg PP、SignState 编码（-2..2）、Subst map<int,Tp> 跨任务一致。
- **已知风险登记**：pacman LLVM 实际版本以 bootstrap 当天为准（版本号写入 ch01；API 若有差异在对应章工程注意点叙述，不改架构）；ch28 irgen 扩展 malloc 是分析器快照内的唯一后端增量，已在该任务显式写出。
