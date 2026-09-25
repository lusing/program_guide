# 35 · macOS 校验与 2.3→3.0 迁移

前面所有章节原本是在 **Debian/WSL（Agda 2.8.0 + stdlib 2.3）** 上逐个类型
检查连过两遍才钉死的。这一章记录把整套教程搬到 **macOS** 的校验全流程——
从源码编译 Agda 2.9.0、接上 stdlib 3.0 的 git 源、修 27+6 个示例的迁移项，
到最后的全绿判定标准。**目的只有一个：你在别的机器上照这份清单，能从头
复现一次。**

> 版本口径：原教程钉在 Agda 2.8.0 + stdlib 2.3。本次 macOS 装的是
> `/Volumes/mac004/lang/agda`（master，Agda 2.9.0）与
> `/Volumes/mac004/lang/agda-stdlib`（master，standard-library-3.0）的源码。
> 因为源码是 master 前沿版，版本号比原教程"前进一代"——这正是 27 章头号坑
> 的活体版：**stdlib 各版本间模块路径与名字会挪动**，本教程这次升级遇到的全部
> 改动都记在 35.3 迁移清单里。

## 35.1 环境与判定标准

实测环境：

| 项 | 值 |
|---|---|
| 系统 | macOS 14.8.9，x86_64 |
| 包管理 | MacPorts（`/opt/local/bin`），无 brew/ghcup/cabal |
| GHC / stack | GHC 9.14.1 + stack 3.11.1 |
| Agda | 源码编译 2.9.0（master） |
| stdlib | git 源 3.0（master），`/Volumes/mac004/lang/agda-stdlib/src` |

判定标准（同 README）：

1. `build.sh` 对每个 `examples/Ex*.agda` 执行 `agda`，退出码 0。
2. `Ex20_io` 额外 `--compile` 后运行输出 `hello agda 42`。

macOS 上一条硬约束：**HOME（`~/.agda`、`~/.stack`、`~/.local/bin`）在构建
沙箱里不可写**，所以 `AGDA_DIR`/`STACK_ROOT`/安装目录全部改指到可写路径
（本教程用 `/Volumes/mac004/.stack-home/`）。普通用户装在自己机器上不需要
这步——这是"在受限沙箱里从源码装机"的记录，不是普通 macOS 用户的操作指南。

## 35.2 从源码编译 Agda（macOS 实测步骤）

```bash
# 1) 把 Agda 源码复制到可写目录（沙箱只读挡掉了 /Volumes/mac004/lang/* 直接写入）
mkdir -p /Volumes/mac004/.stack-home
rsync -a --exclude .git --exclude cubical --exclude std-lib \
      /Volumes/mac004/lang/agda/ /Volumes/mac004/.stack-home/agda-build/

# 2) 用仓库自带的 GHC 9.14.1 snapshot 编译（输出假可写 STACK_ROOT）
cd /Volumes/mac004/.stack-home/agda-build
export STACK_ROOT=/Volumes/mac004/.stack-home
stack --stack-yaml stack-9.14.1.yaml build Agda:exe:agda \
      --copy-bins --local-bin-path /Volumes/mac004/.stack-home/bin
```

要点：

- 仓库里没有默认 `stack.yaml`，只有按 GHC 分版的 `stack-*.yaml`——必须
  `--stack-yaml stack-9.14.1.yaml`（实测不指定会掉进隐式全局工程）。
- `stack-9.14.1.yaml` 用 `resolver: nightly-2026-08-31` + `compiler:
  ghc-9.14.1` + `compiler-check: match-exact`。
- **提速大招（本次实测省下约 1 小时）**：如果机器上恰好有**版本完全一致**
  的 GHC（本次 MacPorts 的 `/opt/local/bin/ghc` 正是 9.14.1），加
  `--system-ghc` 让 stack 直接用系统编译器、**整个跳过 469 MB 的 GHC
  bindist 下载**（`compiler-check: match-exact` 要求版本逐字一致，恰好
  满足即可）：

  ```bash
  stack --stack-yaml stack-9.14.1.yaml --system-ghc \
        build Agda:exe:agda --copy-bins --local-bin-path /Volumes/mac004/.stack-home/bin
  ```

  实测加了这个旗标后 stack 不再打印 `ghc-9.14.1: … downloaded…`，直接进
  pantry 的 Hackage 索引与依赖拉取。
- **`--system-ghc` 生效的前提是 stack 能按 `PATH` 找到系统 GHC**：本次实测
  在非交互 shell（后台任务）里跑，`PATH` 没有 `/opt/local/bin`，stack 找
  不到系统 GHC，照样回头下载 469 MB bindist——两次中断共白下 230 MB。
  显式 `export PATH="/opt/local/bin:$PATH"` 后同一命令立刻改用系统编译器。
- **网络提速（可选）**：Hackage 索引直连 ~50 KB/s，往 `$STACK_ROOT/config.yaml`
  写清华 TUNA 镜像（stack ≥ 2.9.3 格式）后秒级拉完：

  ```yaml
  package-index:
    download-prefix: https://mirrors.tuna.tsinghua.edu.cn/hackage/
    hackage-security:
      keyids: [9 个官方 TUF keyid，抄 TUNA Haskell 镜像帮助页]
      key-threshold: 3
      ignore-expiry: no
  setup-info-locations:
    - "https://mirrors.tuna.tsinghua.edu.cn/stackage/stack-setup.yaml"
  ```

  （`urls.snapshot-location-base` 在 stack 3.11 已不被识别，写了只告警；
  nightly-* 快照靠 pantry 缓存即可。）
- Agda 是巨型包，即便跳过 GHC 下载，snapshot 依赖 + Agda 本体首次冷启动
  仍要编译很久，第二次以后走缓存。

装好后把 agda 挂进环境：

```bash
export PATH="/Volumes/mac004/.stack-home/bin:$PATH"
agda --version
```

## 35.3 stdlib 3.0 接入与 2.3→3.0 迁移清单

`AgdaTutorial.agda-lib` 的 `include` 行从 Debian 路径改为 git 源：

```text
  # 改前
  include: examples /usr/share/agda-stdlib/src
  # 改后
  include: examples /Volumes/mac004/lang/agda-stdlib/src
```

这次 2.9/3.0 升级里，教程示例实际撞到并已修掉的改动（全部为"跑一遍
`build.sh` + grep 源码行号"实测），按文件列：

| 示例 | 3.0 改动 | 修法 |
|---|---|---|
| Ex29_stdlib-algebra | `Algebra.Bundles` **没有模块参数**（`module Algebra.Bundles where`：`Carrier`/`_≈_` 是 record 字段，层级 `c ℓ` 是 record 参数）——示例里误当成参数化模块 `Algebra.Bundles (ℕ) (_≡_ …)` 裸传参；同时 `Data.Nat.Properties` 单子群顶层名是 `+-0-*` 系，`+-isMonoid`/`+-isCommutativeMonoid`/`+-commutativeMonoid` 不存在 | 改 `open import Algebra.Bundles public`；名字换 `+-0-isMonoid`/`+-0-isCommutativeMonoid`/`+-0-commutativeMonoid`（`+-semigroup` 本来就对） |
| Ex31_stdlib-relations | Reasoning.Triple 链语义收紧：每经一步 `_≤⟨_⟩_`（`≤-go`）链值就被降为 `nonstrict`，而 `begin-equality` 的 `IsEquality?` 只认 `equals`——纯 ≤ 链用 `begin-equality` 起步编不过 | 挂 `Relation.Binary.Reasoning.PartialOrder ≤-poset`，证 ≤/< 的链改用 `begin_ / _≤⟨_⟩_ / _∎`；`begin-equality` 只留给 ≈ 目标 |
| Ex32_stdlib-functions | `Extensionality` 的 `funext` 里 f、g 是**隐式参数**，裸 `pointwise = funext` 喂不进去 | 改 `pointwise f g = funext` 显式定形后再交函数外延性 |
| Ex34_stdlib-automation | `≤-step` 自 v2.0 弃用（`WARNING_ON_USAGE`：不炸编译，但每次使用都打告警） | 换同义新名 `m≤n⇒m≤1+n`（`m ≤ n → m ≤ 1 + n`） |
| Ex32 / Ex33 | `0ℓ` 记号不在 `Agda.Primitive`（那里只导出 `lzero`），stdlib 的 `Level` 模块才提供 `0ℓ` | `open import Level using (0ℓ)` |
| Ex33_stdlib-data | `fromℕ<` 的类型是 `.(m < n) → Fin n`——m 只出现在**被擦除的证明**里，结果类型推不出它；证明位给 `_` 会 UnsolvedMetaVariables | 手工搭证明项：`s≤s` 一层层剥 `suc`、`z≤n` 收底（`7 < 10` 即 8 个 `s≤s` 套 `z≤n`，展开后实为 `8 ≤ 10`）；小目标如 `1 < 2` 写 `s≤s ≤-refl` |
| Ex34_stdlib-automation | `Tactic.Cong.cong!` 两条限制：只解构**裸 `_≡_`** 目标；**不会自动对称**（方向反了直接报 `cong! failed, tried: cong …`） | Setoid 链里配 `≡⟨ cong! … ⟩`（step-≡），不能写 `≈⟨⟩`；反向步先 `sym` 再喂：`≡⟨ cong! (sym (+-identityʳ n)) ⟩` |
| Ex34_stdlib-automation | `Tactic.MonoidSolver.solve` 只做结合律 + 单位元归一，**没有交换律**——`a + b + c ≡ b + a + c` 会归一成 `[b]∙[a]∙[c]` vs `[a]∙[b]∙[c]` 直接报不等 | 目标改写成 monoid 可证的形式（重结合 + 吸 0）：`a + 0 + (b + c) ≡ (a + b) + c`，一句 `solve +-0-monoid` 收掉 |
| Ex34_stdlib-automation | 同一文件裸开 Setoid 链又要开 PartialOrder 链，两套 `begin`/`_∎` 记号同作用域打架（作用域问题，非 3.0 改动，升级排错时撞上） | PartialOrder 侧用限定名：`import Relation.Binary.Reasoning.PartialOrder ≤-poset as PO`，链里写 `PO.begin`/`PO.≤⟨_⟩_`/`PO.≡⟨_⟩_`/`PO.∎` |

其余 28 个示例的 `import` 路径经静态审计全部在 3.0 中健在（见下），模块内
签名层面是否还有暗雷由 35.4 编译实测兜底。

**编译前静态审计**（等编译期间先做的一层保险）：把 33 个示例里全部
`import`/`open import` 去重得到 **94 个唯一模块**，逐一对照
`/Volumes/mac004/lang/agda-stdlib/src` 检查 `.agda` 文件是否存在——结果
**除教程内部兄弟导入 `Ex13_induction`（由 .agda-lib 的 `include: examples`
覆盖）外全部存在**。这意味着 3.0 没有再删掉我们用到的任何模块路径；
剩余风险只剩"模块内改名/改签名"一层（如字段更名、函数换参），那要等
编译器说话。另抽查了 15/16/21/25 章的高风险名字，全部健在：

```text
Data/Nat/Properties.agda:141:1+n≢0    355:≮⇒≥    360:≤∧≢⇒<    548:+-suc
Data/Fin/Properties.agda:186:toℕ<n
Data/Nat.agda:27:    ; _≟_ ;_≡?_ ; eq?          -- 门面同时转发新名与旧别名
Data/String.agda:30:open import Data.String.Properties using (_≟_; _≈?_; _≡?_; _<?_; _==_) public
```

汇总规律（这也是 28/29–34 章反复强调的）：

- `_≟_` → `_≡?_`（3.0 标准化；`_≟_` 保留为别名但废弃）。
- `Data.Fin` 构造子 `zero/suc`；`import Data.Fin using (#_、_≡?_ …)` 走门面。
- `Data.AVL.*` → `Data.Tree.AVL.*`（3.0 整族搬移）。
- `Function.Related` → `Function.Related.Propositional`。
- Reasoning 的 `step-∼`/`_∼⟨_⟩_` → `_≈⟨_⟩_`/`_≤⟨_⟩_`。

## 35.4 校验结果

最终判定：`./build.sh` 全量跑一遍，33 个示例逐个 `agda` 退出码 0，脚本打印
**「全部示例类型检查通过」**、退出码 0；`./build.sh run Ex20_io` 编译运行
输出 `hello agda 42`。

| 类别 | 数量 | 结果 |
|---|---|---|
| 原有 27 示例（Debian 2.8/2.3 校验） | 27 | 27/27 通过（macOS 2.9/3.0） |
| 新增 stdlib 示例（29–34） | 6 | 6/6 通过 |
| **合计** | **33** | **33/33 通过** |
| `Ex20_io --compile`（`./build.sh run Ex20_io`） | 1 | GHC 编译 109 个 MAlonzo 模块后链接运行，输出 `hello agda 42` |

两点说明：

- 33 个示例在 macOS 上**不是原样通过**：35.3 表里的迁移改动全部是全量跑
  `build.sh` 时逐层暴露的——每个文件修掉一处就露出下一处，Ex33/Ex34 各剥
  了三层（`0ℓ` → `fromℕ<` 证明 / `cong!` 方向 → MonoidSolver 目标改写），
  直到全绿。
- `run Ex20_io` 首次要 GHC 编译 109 个 MAlonzo 生成的 Haskell 模块，需
  几分钟，属正常现象；改动未变的重跑走 `_build` 缓存。

## 坑位清单

1. **master 前沿版 ≠ 发布版**：`/Volumes/mac004/lang/agda`（2.9.0）与 stdlib
   （3.0）都在 master 上随 CI 走动，一个今天能过的示例明天可能换 API。要可
   复现就钉某个 release tag，教程文档的版本配对矩阵（27.7）永远是头号参考。
2. **沙箱外 HOME 只读**：本项目在受限环境里把 `STACK_ROOT`/安装目录指向可写
   位置；普通 macOS 用户直接装进 `~/.local`/`~/.stack` 即可，别照抄路径。
3. **仓库无默认 `stack.yaml`**：必须按 GHC 分版显式 `--stack-yaml`。
4. **stdlib 顶层不装 README 用例**(Debian 已如此，git 源 `src/` 也一样)，
   照抄报错信息里的 `See README.X` 会扑空——去 GitHub 对应 tag 看。
5. **两套校验口径**：Debian 2.8/2.3 是老口径，macOS 2.9/3.0 是新口径；
   文档里路径/行号以 `cd ... && agda 文件名` 退出码 0 为准。
6. **只读目录里 `stack build` 直接爆
   `openBinaryTempFile: permission denied`**：stack 要在工程目录写
   `.stack-work`。受限环境务必先按 35.2 第 1 步 rsync 出可写副本再编译，
   别对着 git 源目录直接 stack。
7. **非交互 shell 里 PATH 可能没有 MacPorts 的 `/opt/local/bin`**，刚装好的
   agda 就在眼前却 `command -v agda` 找不到；更阴的是 `set -euo pipefail` 下
   写 `AGDA="$(command -v agda)"`——命令替换一失败，**整条赋值语句非零退出，
   脚本无声死掉**，后面的报错分支永远执行不到。`build.sh` 已改成
   `$(command -v agda 2>/dev/null || true)` 先探 PATH，再逐个试常见安装位
   （stack/cabal/ghcup/Homebrew/`/Volumes/*/.stack-home`），全空才报错退出。
8. **Unicode 输出认 locale**：macOS 默认 locale 下 `≟`/`ℕ`/`≤` 可能打成问号
   或乱码，`build.sh` 的 darwin 分支 `export LC_ALL=en_US.UTF-8` 后正常。

---
上一章：[34 · stdlib 自动证明](34-stdlib-automation.md) ｜ 返回：[README](../README.md)