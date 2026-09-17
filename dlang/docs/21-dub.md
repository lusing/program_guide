# 21 · 模块、包与 DUB

> 对应示例：`examples/21_dub/`（DUB 工程）

## 21.1 模块系统：文件即模块，目录即包

```text
21_dub/
├── dub.json                      ← 项目描述（包名、依赖、构建配置）
└── source/
    ├── app.d                     ← module app（入口约定）
    └── dguide_dub/               ← 包名 = 包名.模块名 按目录映射
        ├── mathutil.d            ← module dguide_dub.mathutil;
        └── util/
            ├── format.d          ← module dguide_dub.util.format;
            └── convert.d         ← module dguide_dub.util.convert;
```

```d
// app.d
import dguide_dub.mathutil;             // 普通 import：内容直接进作用域
static import dguide_dub.util.convert;  // static import：只能全路径访问

triple(14);                             // 普通导入：裸调用
dguide_dub.util.convert.celsiusToF(36.6);  // static 导入：必须全路径
```

两种姿势对照：普通 import 省字但可能名字污染；static import 刻意隔离。**没有** `from x import y`——选择性导入是 `import std.path : buildPath;`（只引入指定符号）。

## 21.2 dmd -i：不用构建工具的多文件编译

```bash
dmd -w -i -Isource source/app.d     # -i：自动把 import 到的模块一起编译
```

- `-i` 按 import 声明**自动找文件**（所以模块名必须和路径一致）。
- `-Isource` 告诉编译器去哪找包根。
- 小工具/单二进制项目这样够了；依赖管理、测试入口、多配置再上 DUB。

## 21.3 DUB：官方构建 + 包管理

```json
{
    "name": "dguide_dub",
    "version": "1.0.0",
    "targetType": "executable",
    "targetPath": "bin",
    "dflags": ["-w"]
}
```

```bash
dub build          # 编译到 bin/
dub run            # 编译 + 运行
dub test           # 生成测试入口，跑全部模块 unittest
dub add mir-core   # 加依赖（写进 dub.json + 拉包）
```

- 描述文件二选一：`dub.json`（JSON）或 `dub.sdl`（更紧凑的 SDL 语法）。
- 源码默认在 `source/`（老项目可能叫 `src/`，json 里 `"sourcePaths"` 可改）。
- 依赖从 code.dlang.org 拉，本地缓存在用户目录；**无依赖时完全离线可用**（本教程工程零依赖）。

## 21.4 dub test 的机制

`dub test` 会**生成一个测试 main**，把所有模块的 unittest 收进一个可执行文件——所以：

1. 别在自己的 configurations 里加 `-unittest` 的配置再 `dub test`——**双 main 链接冲突**（实测报 main 重复）。
2. `dub run/build` 常规构建不含 unittest；`version (unittest)` 分支只在测试构建激活（示例用这个打印当前模式）。

## 21.5 库与可执行

| targetType | 产物 | 用途 |
|---|---|---|
| `executable` | .exe | 应用 |
| `library` | 静态/动态库（默认） | 给别的 D 项目 import |
| `sourceLibrary` | 不编译只供 import | 头文件库式 |

依赖本地未发布的包：`"path": "../mylib"`（路径依赖，本仓库教程未用，22 章类比 zig 的 zon 讲解可回看）。

## 21.6 坑位清单

1. **模块名必须与路径一致**：`source/dguide_dub/mathutil.d` 里必须写 `module dguide_dub.mathutil;`——不一致时 dmd 的报错是"unable to read module"，像找不到文件其实是不匹配。
2. **dub test 别叠自定义 -unittest 配置**（21.4 的双 main 坑）。
3. **dmd -i 忘了 -Isource** → "unable to read module"，报错文本一模一样——两条坑要一起记。
4. **普通 import 后用"模块名.函数"限定访问会失败**（undefined identifier）——要么裸调用（推荐），要么 static import。
5. dub.json 里 `"dflags": ["-w"]` 会触发 DUB 警告"flags handled by DUB, discouraged"——能用但建议迁移到 buildRequirements（教程保留 dflags 是为了和 dmd 命令行行为一致）。
6. `dub run` 每次检查依赖/重建——想要"最快循环"还是 `dmd -i -run`（本章示例两种姿势都验证过）。

---
