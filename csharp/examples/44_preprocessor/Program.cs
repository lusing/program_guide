// 44 · 预处理指令与代码组织：条件编译、命名空间、嵌套类型、程序集
// #define 必须出现在一切语句之前——它就是给本文件开一个「布尔开关」
#define SELF_TEST
// （写本例时实测：#undef 放到语句后面直接 CS1032「不能在文件的第一个标记之后定义或取消
//   定义预处理器符号」——C# 的 #define/#undef 都只能待在文件头，这点与 C/C++ 不同）

using IntMap = System.Collections.Generic.Dictionary<int, string>;   // using 别名：长类型名起短名

Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 预处理指令不是宏：只是布尔开关 =====");
Console.WriteLine("  C/C++ 的 #define SIZE 10 是文本替换宏；C# 的 #define SELF_TEST 只定义一个 true/false 符号");
#if SELF_TEST
Console.WriteLine("  [SELF_TEST 已定义] 这行被编译——文件头 #define SELF_TEST 打开了开关");
#else
Console.WriteLine("  [SELF_TEST 未定义] 这行不会出现在 IL 里（不是注释掉的死代码，是压根没编译）");
#endif
#if !SELF_TEST
Console.WriteLine("  不可能出现的行");
#else
Console.WriteLine("  #if !SELF_TEST / #else：符号反过来判断，仍走另一侧——条件编译就是编译期 if");
#endif
Console.WriteLine("  关掉符号的两条路：删掉文件头的 #define，或在 csproj 写 <DefineConstants>SELF_TEST</DefineConstants> 反向控制");

Console.WriteLine();
Console.WriteLine("===== 编译器白送的符号：DEBUG 与 NET10_0 =====");
#if DEBUG
Console.WriteLine("  [DEBUG] 当前是 Debug 配置（dotnet run 默认）——诊断代码只在开发期进产物");
#else
Console.WriteLine("  [RELEASE] Release 配置：调试输出不进产物");
#endif
#if NET10_0
Console.WriteLine("  [NET10_0] csproj 写了 <TargetFramework>net10.0</TargetFramework>，编译器自动定义");
#endif
Console.WriteLine("  用途：Trace/日志只在 DEBUG 编译、平台分支在 TFM 符号编译——零运行时判断开销");
Console.WriteLine("  验证：dotnet run -c Release 再跑一遍，上面 DEBUG 两行会换成 RELEASE 版");

Console.WriteLine();
Console.WriteLine("===== #warning / #error：把「配错环境」拦在编译期 =====");
#if DEMO_ERROR
#error 这个分支永远不会编译到——除非哪里定义了 DEMO_ERROR 符号
#warning 同理
#endif
Console.WriteLine("  #error/#warning 放在 #if 里当「配置哨兵」：条件不满足直接拒绝编译，部署脚本一眼看到原因");
Console.WriteLine("  （常见用法：#if NETFRAMEWORK #error 本库不支持 .NET Framework #endif）");

Console.WriteLine();
Console.WriteLine("===== #pragma warning：定点静音，修完记得恢复 =====");
#pragma warning disable CS0219 // 变量已赋值但从未使用
int unusedDemo = 42;               // 没有 #pragma 这行，编译时会报 CS0219 警告
#pragma warning restore CS0219
Console.WriteLine($"  上面那行无用的赋值没有产生警告——#pragma warning disable CS0219 只对这一段静音");
Console.WriteLine("  把 disable/restore 两行删掉重新编译，构建输出里会出现 warning CS0219");
Console.WriteLine("  原则：不用全局关警告（csproj NoWarn），要关就定点关、写明编号、成对恢复");

Console.WriteLine();
Console.WriteLine("===== #line hidden：异常栈里「隐藏」模板生成的行 =====");
try { ThrowVisible(); }
catch (Exception ex) { PrintFrame(ex, "正常区"); }
try { ThrowHidden(); }
catch (Exception ex) { PrintFrame(ex, "隐藏区"); }
Console.WriteLine("  两帧都打印了方法名，但隐藏区没有行号——源生成器/模板代码用它让自己的帧不污染用户栈");

Console.WriteLine();
Console.WriteLine("===== #region / #nullable：编辑器语义，不产 IL =====");
Console.WriteLine("  #region 折叠块：只在 IDE 里折叠显示；#nullable enable/disable 是编译器可空检查的区间开关");
Console.WriteLine("  本工程的 <Nullable>enable</Nullable> 是全文件级开关，21 章细讲");

Console.WriteLine();
Console.WriteLine("===== 命名空间组织：块状、文件级、别名 =====");
Console.WriteLine("  本文件顶层语句没有 namespace（进自动生成的 Program 类）；下面用别名声明的字典：");
IntMap ages = new() { [1] = "一岁", [2] = "两岁" };
Console.WriteLine($"  using IntMap = Dictionary<int,string> → {ages[1]}（别名对泛型特别省字）");
Console.WriteLine("  常规文件的两种写法：namespace Foo {{ ... }}（块状）与 namespace Foo;（文件级，一文件一空间）");
Console.WriteLine("  global using X; 写一次全解决方案生效——ImplicitUsings 就是微软替你写的 global using 包（02 章拆过）");

Console.WriteLine();
Console.WriteLine("===== 嵌套类型：Inner 是 Outer 的成员，能读 Outer 的私有 =====");
Console.WriteLine($"  Outer.Inner.Peek() → {Organizer.Outer.Inner.Peek()}");
Console.WriteLine("  非嵌套的任何类都读不到 secret——嵌套是「设计上的一家人」，常用于外部不应感知的实现细节");

Console.WriteLine();
Console.WriteLine("===== 程序集：编译产物这个「集装箱」 =====");
var asm = System.Reflection.Assembly.GetExecutingAssembly();
Console.WriteLine($"  全名: {asm.FullName}");
Console.WriteLine($"  位置: {asm.Location}");
Console.WriteLine($"  引用的程序集: {asm.GetReferencedAssemblies().Length} 个");
Console.WriteLine("  一个 csproj → 一个程序集（dll/exe），IL + 元数据都在里面（01 章的装箱单）");
Console.WriteLine("  #if 的选择在编译期已固化——程序集里找不到任何符号痕迹；23 章的反射是运行期读元数据，两者互补");

static void ThrowVisible() => throw new InvalidOperationException("正常区的异常");

#line hidden
static void ThrowHidden() => throw new InvalidOperationException("隐藏区的异常");
#line default

static void PrintFrame(Exception ex, string label)
{
    var frame = (ex.StackTrace ?? "").Replace("\r", "").Split('\n')
        .FirstOrDefault(l => l.Contains("Throw")) ?? "（无帧）";
    Console.WriteLine($"  {label}: {frame.Trim()}");
}

// 类型声明必须在所有语句之后（顶层语句文件的规矩）
file class Organizer
{
    public class Outer
    {
        private const string Secret = "Outer 的私有常量";

        public class Inner
        {
            public static string Peek() => $"Inner 直接读到了「{Secret}」——特权来自嵌套";
        }
    }
}
