-- StackEnv 库模块：stack 工程的知识载体——镜像配置、resolver 解析、工程结构
module StackEnv
    ( tunaConfig, ourStackYaml, parseSnapshot, SnapshotTag(..)
    , projectParts
    ) where

import Data.List (isPrefixOf)

-- ═══ 20.1 清华镜像三行（stackage.org 系被墙时的救命配置；正文含 global-hints 手动下载）
tunaConfig :: [String]
tunaConfig =
    [ "setup-info-locations: [\"https://mirrors.tuna.tsinghua.edu.cn/stackage/stack-setup.yaml\"]"
    , "urls:"
    , "  latest-snapshot: https://mirrors.tuna.tsinghua.edu.cn/stackage/snapshots.json"
    , "snapshot-location-base: https://mirrors.tuna.tsinghua.edu.cn/stackage/stackage-snapshots/"
    ]

-- ═══ 20.2 本工程的 stack.yaml（四行决策：resolver / compiler 覆盖 / system-ghc / 不另装）
ourStackYaml :: [String]
ourStackYaml =
    [ "resolver: lts-24.59"      -- 快照：三千余包的版本组合（GHC 9.10.3 配套）
    , "compiler: ghc-9.12.1"     -- 覆盖快照的编译器（用系统版）
    , "system-ghc: true"         -- 用 PATH 上的 ghc
    , "install-ghc: false"       -- 绝不让 stack 另下自己的 GHC
    ]

-- ═══ 20.3 resolver 名字的解析规则（纯函数，可测）
data SnapshotTag = LTS Int Int | Nightly String
    deriving (Show, Eq)

parseSnapshot :: String -> Maybe SnapshotTag
parseSnapshot s
  | Just rest <- stripP "lts-" s
  , (maj, '.' : minor) <- break (== '.') rest
  , [(mj, "")] <- reads maj
  , [(mi, "")] <- reads minor
  = Just (LTS mj mi)
  | Just rest <- stripP "nightly-" s = Just (Nightly rest)
  | otherwise = Nothing
  where
    stripP p x = if p `isPrefixOf` x then Just (drop (length p) x) else Nothing

-- ═══ 20.4 工程组成部件（library / executable / test-suite 三件套）
projectParts :: [(String, [String])]
projectParts =
    [ ( "library"
      , ["src/StackEnv.hs —— 库模块：可复用逻辑", "build-depends: base"] )
    , ( "executable"
      , ["app/Main.hs —— 入口", "build-depends: base, stackenv"] )
    , ( "test-suite"
      , ["test/Spec.hs —— 测试入口", "type: exitcode-stdio-1.0（退出码即判定）"] )
    ]
