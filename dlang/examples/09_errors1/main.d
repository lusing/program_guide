// 09 · 错误处理 I：异常、enforce 与 scope guards
import std.stdio, std.exception, std.string, std.conv;

// ── 自定义异常：继承 Exception，msg + next 链 ────────────────
class ConfigError : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);        // 惯例：记录抛出位置，报错直接定位
    }
}

// enforce：条件不满足就抛（省掉 if + throw 的样板）
int parsePort(string s) {
    auto n = s.to!int;                       // 转换失败自己会抛 ConvException
    enforce(n >= 1 && n <= 65535,
            new ConfigError("端口越界：" ~ s));   // enforce 的第二种形态：直接给异常对象
    return n;
}

string readConfig(string name) {
    enforce(name.length > 0, "配置名不能为空");   // 默认抛 AssertException? 不——是
    return "值";                                  // Exception（见 unittest）
}

void main() {
    // ── throw / try / catch / finally ──────────────────────
    try {
        throw new ConfigError("数据库连不上");
    } catch (ConfigError e) {              // 子类在前（catch 按声明顺序匹配）
        writeln("ConfigError: ", e.msg);
    } catch (Exception e) {                // Exception 是所有可恢复异常的根
        writeln("兜底: ", e.msg);
    } finally {
        writeln("finally 总会执行");
    }

    // enforce 演示
    try writeln(parsePort("8080"));        // 8080
    catch (Exception e) writeln("错: ", e.msg);
    try parsePort("99999");
    catch (ConfigError e) writeln("越界: ", e.msg);

    // 异常链：next 字段把原始异常串起来（报错时能看到因果）
    try {
        try throw new Exception("内层：文件格式错");
        catch (Exception inner) {
            auto outer = new ConfigError("外层：加载失败");
            outer.next = inner;                  // 挂上"原因"异常
            throw outer;
        }
    } catch (ConfigError e) {
        writeln(e.msg, " ← ", e.next.msg);  // 外层 ← 内层
    }

    // ── scope guards：D 的招牌——所有 guard 统一按注册逆序执行 ──
    void demoScopeGuards() {
        scope (exit) writeln("  exit-1（离开作用域，必执行）");
        scope (exit) writeln("  exit-2（比 exit-1 后注册，先执行）");
        scope (success) writeln("  success（没抛异常才执行）");
        scope (failure) writeln("  failure（抛异常才执行，本次跳过）");
        writeln("  主体开始");
    }   // 离开时按逆序过滤执行：success → exit-2 → exit-1
    demoScopeGuards();

    void throwsSoon() {
        scope (exit) writeln("  [抛] exit 仍执行");
        scope (failure) writeln("  [抛] failure 执行");
        scope (success) writeln("  [抛] success 不执行");
        throw new Exception("boom");
    }
    try throwsSoon();
    catch (Exception e) writeln("  捕获：", e.msg);

    // 实战形态：先登记"回滚"，再做事——成功就撤销回滚
    int balance = 100;
    bool transferSucceeded = false;
    void transfer() {
        balance -= 30;
        scope (failure) { balance += 30; writeln("  转账失败，已回滚"); }
        scope (exit) if (transferSucceeded) writeln("  转账完成，余额 ", balance);
        if (balance < 0) throw new Exception("余额不足");
        transferSucceeded = true;
    }
    transfer();
}

unittest {
    // assertThrown / assertNotThrown：测试里验证异常的标准姿势（23 章细讲）
    assertThrown!ConfigError(parsePort("70000"));
    assertNotThrown!Exception(parsePort("80"));
    assertThrown!Exception(readConfig(""));

    // scope guard 顺序验证：统一逆序（success/exit 交错，按注册顺序倒着来）
    string[] log;
    {
        scope (exit) log ~= "exit1";
        scope (success) log ~= "ok";
        scope (exit) log ~= "exit2";
    }
    assert(log == ["exit2", "ok", "exit1"]);
}
