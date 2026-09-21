// 22 · 异常处理：可预期的失败用返回值，意外用异常
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 基本结构：try / catch / finally =====");
try
{
    var result = 100 / GetDivisor();
    Console.WriteLine($"  100/{GetDivisor()} = {result}");
}
catch (DivideByZeroException ex) when (DateTime.Now.Year > 2000)   // when 过滤器：先判条件再进 catch
{
    Console.WriteLine($"  过滤器命中的 catch: {ex.Message}");
}
finally
{
    Console.WriteLine("  finally 无论如何都执行（释放资源的兜底位）");
}

static int GetDivisor() => 0;

Console.WriteLine();
Console.WriteLine("===== 栈展开：异常一路上抛，路过层层 finally =====");
try
{
    Level1();
}
catch (AppException ex)
{
    Console.WriteLine($"  顶层捕获: {ex.Message}");
    Console.WriteLine($"  内部原因: {ex.InnerException?.Message}   ← 异常链");
}

static void Level1() { try { Level2(); } finally { Console.WriteLine("  Level1 的 finally"); } }
static void Level2() { try { throw new AppException("业务失败", new InvalidOperationException("根因：状态不对")); }
                       finally { Console.WriteLine("  Level2 的 finally"); } }

Console.WriteLine();
Console.WriteLine("===== throw; vs throw ex;（保不保栈）=====");
try { ThrowPreserved(); } catch (Exception ex) { Console.WriteLine($"  throw; 保留完整栈（第一帧 {FirstFrame(ex)}）"); }
try { ThrowReset(); } catch (Exception ex) { Console.WriteLine($"  throw ex; 栈被重置（第一帧 {FirstFrame(ex)}——原始抛出点丢了）"); }

static void ThrowPreserved() { try { Deep(); } catch { throw; } }        // 保留原始栈
static void ThrowReset() { try { Deep(); } catch (Exception ex) { throw ex; } }  // 栈被重置
static void Deep() => throw new InvalidOperationException("最深处抛的");
static string FirstFrame(Exception ex)
    => (ex.StackTrace ?? "").Split('\n').FirstOrDefault(l => l.Contains("at "))?.Trim() ?? "(无栈)";

Console.WriteLine();
Console.WriteLine("===== 自定义异常：继承 + 语义命名 =====");
Console.WriteLine("  AppException : Exception —— 业务层异常的根");
Console.WriteLine("  要点：结尾带 Exception 后缀、给构造函数重载、不变更基类行为");

Console.WriteLine();
Console.WriteLine("===== 原则清单 =====");
Console.WriteLine("  ① 可预期的失败（文件不存在/解析失败）→ 返回值/TryDo 模式，别用异常做流程控制");
Console.WriteLine("  ② 意外状态 → 异常；越往上抛越「总括」（内层具体的，外层汇总的）");
Console.WriteLine("  ③ finally/using 管资源（第 25 章）；catch 里至少记日志");
Console.WriteLine("  ④ 不要 catch (Exception) 后一声不吭——吞异常是调试黑洞");

public class AppException(string message, Exception? inner = null) : Exception(message, inner);
