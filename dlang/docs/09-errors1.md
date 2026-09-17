# 09 · 错误处理 I：异常、enforce 与 scope guards

> 对应示例：`examples/09_errors1/`

## 9.1 异常体系

```text
Throwable                 ← 万物之根（一般别直接用）
├── Exception             ← 可恢复错误：业务代码 throw/catch 它
│   ├── ConvException     （std.conv 转换失败）
│   ├── JSONException     （std.json）
│   └── 你的自定义异常
└── Error                 ← 不可恢复：AssertError/RangeError/FinalizeError…
                            别 catch Error——让它崩，崩了修 bug
```

```d
class ConfigError : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);           // 惯例：记下抛出位置，报错直达行号
    }
}

try {
    throw new ConfigError("数据库连不上");
} catch (ConfigError e) {                  // 子类在前（catch 按顺序匹配）
    writeln(e.msg);
} catch (Exception e) {                    // 根类兜底
    writeln(e.msg, " @", e.file, ":", e.line);
} finally {
    writeln("总会执行");
}
```

异常链（因果）：`outer.next = inner;` 把"原始异常"挂上——顶层 catch 后 `e.next.msg` 还能看根因。

## 9.2 enforce：把 if+throw 浓缩成一行

```d
import std.exception;

enforce(port >= 1 && port <= 65535, "端口越界");          // 默认抛 Exception
enforce(port > 0, new ConfigError("端口越界"));          // 指定异常类型
```

标准库内部大量用 enforce——D 的习惯是**前置条件不满足就抛**，而不是返回魔数错误码。

## 9.3 ⭐ scope guards：D 最优雅的错误处理

```d
void demo() {
    scope (exit)    writeln("总会执行");
    scope (success) writeln("没抛异常才执行");
    scope (failure) writeln("抛异常才执行");
    // ... 主体 ...
}
```

三条铁律（实测验证）：

1. **所有 guard 按"注册的逆序"执行**——exit 和 success/failure 交错时也统一逆序（不是 success 先于 exit！）。
2. guard 在**离开作用域**时触发：正常 return、异常抛出、break 出块都算。
3. 同类多个 guard 也是逆序（和 C++ 析构顺序一致的直觉）。

实战形态——**先登记回滚，再干活**：

```d
balance -= 30;
scope (failure) { balance += 30; writeln("回滚"); }   // 后面任何一步炸了自动还钱
scope (exit) if (ok) log("转账完成");
doRiskyTransfer();                                     // 失败会抛
ok = true;
```

对比 Go 的 defer（只有 exit）、Zig 的 errdefer（只有 failure）——D 一个语法三个开关。

## 9.4 测试异常

```d
unittest {
    assertThrown!ConfigError(parsePort("70000"));
    assertNotThrown!Exception(parsePort("80"));
}
```

`assertThrown!类型(表达式)` 是标准姿势（std.exception）。

## 9.5 坑位清单

1. **scope guard 顺序是"统一逆序"**：注册 exit1 → success → exit2，执行序是 exit2 → success → exit1。网上教程常说"success 先于 exit"——错，实测不是。
2. **catch Error 类要小心**：契约/断言失败抛的是 Error（AssertError），程序状态可能已坏——正常代码只 catch Exception。
3. `catch (Exception e)` 里访问 `e.file`/`e.line`：只有构造时传了才有（自定义异常请按 9.1 模板带 `__FILE__/__LINE__` 默认参数）。
4. 异常消息**拼接别忘 .to!string**：`"端口：" ~ 8080` 编译错（int 不能 ~ string），用 `"端口：" ~ 8080.to!string` 或 writefln 风格。
5. `finally` 与 scope(exit) 二选一即可——混用执行顺序容易把人绕晕。
6. 找不到 `AssertError` 符号？`import core.exception;`（object 模块不再自动导出它，2.113 实测）。

---
