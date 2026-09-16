# 17 · 测试：xUnit 与纯函数架构

> 对应示例：examples/17_testing

## 17.1 解决什么问题

"我的解析函数改了一行，还能对吗？"——只有测试能给确定的答案。F# 的测试体验出乎意料地好：**record/DU 的结构相等（第 09/10 章）让断言直接写期望值**，不用几十个 Assert 属性逐个比。本章用 xUnit（事实标准）+ 两个测试风格约定讲清楚。

## 17.2 工程：dotnet new xunit -lang F#

```bash
dotnet new xunit -lang F# -o tests
```

fsproj 关键部分：

```xml
<ItemGroup>
  <Compile Include="Tests.fs" />
</ItemGroup>

<ItemGroup>
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
  <PackageReference Include="xunit" Version="2.9.3" />
  <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
</ItemGroup>
```

三个包各司其职：`xunit` 是框架（Fact/Theory/Assert），`Test.Sdk` 让 `dotnet test` 认识这个工程，`runner.visualstudio` 管 IDE/运行器集成。跑测试就是 `dotnet test`；本仓库 build.ps1 对测试工程自动执行它（第 01 章）。

## 17.3 Fact 与 Theory

测试必须放在 **type 里**（xUnit 按类发现），F# 的 let 绑定成员 + 双反引号命名是主流风格：

```fsharp
type 解析与校验 () =

    [<Fact>]
    let ``正常整数解析为 Ok`` () =
        Assert.Equal(Ok 42, parseInt "42")

    [<Theory>]
    [<InlineData("abc")>]
    [<InlineData("")>]
    [<InlineData("  ")>]
    let ``非法输入解析为 Error`` (input: string) =
        Assert.True(match parseInt input with Error _ -> true | _ -> false)
```

`[<Fact>]` 是单个用例；`[<Theory>]` + `[<InlineData>]` 是**数据驱动**——同一断言跑多组输入（FizzBuzz 四组一行一例）。中文反引号命名让失败报告直接可读：``解析与校验.正常整数解析为 Ok``。

## 17.4 AAA 结构与断言选型

```fsharp
[<Fact>]
let ``范围校验两端都检查`` () =
    // Arrange：准备输入（纯函数场景极薄）
    // Act：调用
    let result = inRange 1 10 99
    // Assert：验证
    Assert.True(match result with Error _ -> true | _ -> false)
```

| 断言 | 用途 |
|---|---|
| `Assert.Equal(expected, actual)` | 结构相等——**record/DU 直接比**（最大红利） |
| `Assert.True/False(cond)` | 布尔与"模式匹配出某类结果" |
| `Assert.Empty(col)` / `Assert.Single(col)` | 集合形态 |
| `Assert.Throws<T>(fun () -> ...)` | 异常路径 |

被测代码是什么？示例把三个纯函数直接放在 Tests.fs 里教学；**正式项目里它们在 src 工程、测试工程引用之**——第 20 章的 20_todo/tests 就是这个结构（`<ProjectReference>`）。

## 17.5 纯函数核心 + 薄 IO 壳：可测性的来源

第 08 章 parse/apply 全是纯函数——**不碰文件、不碰网络、不藏状态**，所以测试不用 mock：传数组进、比 Result 出。这份架构不是为测试妥协，而是 F# 建模的自然结果。对照：`Todo.load`/`save`（IO）被隔离在边缘两三个函数里，核心 `apply` 100% 可测（第 20 章的测试分布就是这个形状）。

## 17.6 构建脚本集成

两个入口（`build.ps1` / `run-all.sh`）都会识别测试工程（fsproj 含 `Microsoft.NET.Test.Sdk`）自动 `dotnet test`——17_testing 全绿输出：

```
已通过! - 失败:     0，通过:     9，已跳过:     0，总计:     9    # 中文语言环境
Passed!  - Failed:     0, Passed:     9, Skipped:     0, Total:     9    # 英文语言环境
```

这行是 xUnit 的汇总，**文案随系统语言变**，所以两个平台看到的措辞不同、数字一致——看 `Failed: 0` / `失败: 0` 就行，别把文案当断言。

一步之外还有属性测试（FsCheck：随机生成输入找反例），思路一句话：**"对所有输入成立"比"对三个例子成立"强**——入门后再学。

## 17.7 跑单个测试与过滤

日常循环里全量跑太慢，`--filter` 按名字挑：

```bash
dotnet test --filter "FullyQualifiedName~FizzBuzz"     # 只跑 FizzBuzz 类
dotnet test --filter "FullyQualifiedName~解析"          # 中文名也能过滤
```

VS/Rider 里测试名旁边的运行按钮走的同一条路。失败输出会带 ``类名.方法名``——双反引号命名的回报就在这里。

## 17.8 坑位清单

- **测试必须在 type 里**：顶层 `[<Fact>] let` 不会被发现——"测试消失"的第一嫌疑。
- **类型名不能带空格**：`type Parse 测试 ()` 两个词编不过；用 `type 解析测试 ()`（示例 20 章实测踩过）。
- **浮点比较**：`Assert.Equal(0.1+0.2, 0.3)` 失败；用 `Assert.Equal(expected, actual, precision)` 重载。
- **中文测试名**：源文件保持 UTF-8；个别 CI 的控制台编码会花，但运行不受影响。
- **别测实现细节**：断言 Result 的形状而不是内部调了几次函数。
