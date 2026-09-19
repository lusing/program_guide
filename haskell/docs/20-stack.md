# 20 · Stack 工程与生态 ⭐

> 对应示例：`examples/20_stackenv/`（stack 工程：库 + 可执行 + 测试三件套）

## 20.1 为什么是 stack（且必须配镜像）

国内实测：stackage.org 系域名（raw.stackage.org、stackage-haddock）不通，hackage 可达。
stack 拉 snapshot/包走 stackage 域——**不配镜像基本不可用**。清华 TUNA 三行救命配置
（`%APPDATA%\stack\config.yaml`）：

```yaml
setup-info-locations: ["https://mirrors.tuna.tsinghua.edu.cn/stackage/stack-setup.yaml"]
urls:
  latest-snapshot: https://mirrors.tuna.tsinghua.edu.cn/stackage/snapshots.json
snapshot-location-base: https://mirrors.tuna.tsinghua.edu.cn/stackage/stackage-snapshots/
```

外加一步（官方文档没写全）：手动下载 global-hints 到
`%APPDATA%\stack\pantry\global-hints-cache.yaml`——路径是 **fpco**/stackage-content（不是
commercialhaskell，实测 404 才知道）。

## 20.2 stack.yaml：本教程工程的四行决策

```yaml
resolver: lts-24.59      # 快照：三千余包的版本组合（自带 GHC 9.10.3）
compiler: ghc-9.12.1     # 覆盖：本机系统 GHC（lts 没有 9.12.1 的配套）
system-ghc: true         # 用 PATH 上的 ghc，别自己装
install-ghc: false       # 绝不让 stack 下载 GHC
```

**版本错位是现实**：镜像上 latest LTS（24.59）配 GHC 9.10.3、nightly 配 9.12.4——都没有
9.12.1。`compiler:` 覆盖 + `system-ghc` 是"scoop GHC + stack 构建"共存的正解（实测可编）。

## 20.3 cabal 文件：三件套

```
stackenv/
  stack.yaml
  stackenv.cabal         # 库 src/ + 可执行 app/ + 测试 test/
  src/StackEnv.hs
  app/Main.hs
  test/Spec.hs
```

```cabal
library
    exposed-modules:  StackEnv
    hs-source-dirs:   src
    build-depends:    base
    default-language: Haskell2010

executable stackenv
    main-is:          Main.hs
    hs-source-dirs:   app
    build-depends:    base, stackenv

test-suite stackenv-test
    type:             exitcode-stdio-1.0     # 退出码即判定
    main-is:          Spec.hs
    hs-source-dirs:   test
    build-depends:    base, stackenv
```

`build-depends` 里的包必须显式列（boot 库也要）——**隐藏包**是包内编译最常见报错（24 章
transformers 实测）。

## 20.4 日常命令

```bash
stack build              # 编译三件套
stack test               # 跑测试套件（exitcode-stdio 即进程退出码）
stack run                # 跑可执行
stack exec stackenv      # 同上（显式名）
stack ghci               # 工程环境进 REPL（库模块可直接 import）
stack ls snapshots       # 看可用快照（走镜像）
```

## 20.5 strip 坑（Windows 实测现场）

**症状**：`stack build` 在 `copy/register` 阶段失败（exe 其实已生成）。**根因**：scoop 残留的
坏 shim `G:\scoop\shims\strip.exe` 指向已卸载的 binutils；而 **Cabal 惯例从 ghc 同目录解析 strip**
（stack 把 ghc 定位到 shims 目录）——PATH 顺序救不了。**修复**：`scoop shim rm strip`。
build.ps1 对 stack 工程另有"探测可用 strip 前置 PATH"的兜底。

## 20.6 生态地图（介绍层，不入主线）

| 工具 | 用途 |
|---|---|
| cabal-install | 另一构建系统（scoop 的 extras `cabal` 是**同名聊天应用**，实测坑） |
| HLS | 语言服务器：类型提示/重构（IDE 体验的关键） |
| ormolu/fourmolu | 格式化 |
| hlint | 改进建议 |
| weeder | 死代码 |
| hackage/stackage | 包仓库 / 策划快照 |

## 20.7 坑位清单

1. **stackage 被墙**：TUNA 三行 + global-hints 手动下载（fpco 路径）——配错表现为"解析快照
   卡死十几分钟"（20.1）。
2. **LTS 与系统 GHC 错位**：`compiler:` 覆盖 + `system-ghc: true` + `install-ghc: false`
   三件套（20.2）。
3. **build-depends 漏包 = hidden package**：transformers/mtl 这类 boot 库也要显式列（20.3）。
4. **坏 strip shim 卡 copy 阶段**：exe 已生成但构建报失败——scoop 清 shim（20.5）。
5. **stack.yaml.lock 入库**：锁住 resolver 解析结果，CI 可复现（本教程提交了它）。
