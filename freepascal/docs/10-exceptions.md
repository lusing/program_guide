# 10 · 异常与资源保护

## 1. 三个关键字：try / except / finally

Pascal 的异常结构和 C++/Java 最像，但有一个关键差异：**except 和 finally 是两个
独立的块，不能合写**（没有 `try...except...finally` 三段合一的语法）：

```pascal
try
  ...                      // 保护段
except                     // 失败路：捕获处理
  on E: Exception do ...
end;

try
  ...                      // 保护段
finally                    // 收尾路：无论如何都执行（成败都跑）
  resource.Free;
end;
```

选择口诀：

- **护资源 → finally**（释放必须发生）
- **处理错误 → except**（转换为业务消息/恢复/记日志）
- 两个都要 → 嵌套（第 6 节的标准形态）

## 2. try/finally：资源保护的标准姿势

```pascal
sl := TStringList.Create;          // 拿到资源
try
  sl.Add('第一行');
finally
  sl.Free;                         // try 里抛异常也保证执行
end;
```

这是 Pascal 侧的 RAII 等价物（没有析构确定性时手动保证）：
**Create 之后立刻 try，Free 写在 finally**。顺序反了（try 里 Create）会把失败创建也
Free。GUI 端每个 `TForm.Create`/`TBitmap.Create` 都是这个套路。

## 3. try/except：类型化捕获

```pascal
try
  n := StrToInt('12x');                  // 抛 EConvertError
except
  on E: EConvertError do                 // 命中：绑定 E 读消息
    caught := 'EConvertError：' + E.Message;
  on EDivByZero do                       // 不要变量也能只判类型
    caught := 'EDivByZero';
else
  caught := '其他';                       // else 兜底 = catch(...)
end;
```

- 多条 `on` **从上到下匹配，先具体后宽泛**——父类分支放后面才能兜住子类
  （实测：`on ETooYoung` 排在 `on ESalaryError` 前面，后者永远到不了）。
- `E.Message` 是人话消息；`E.ClassName` 是类名。
- **空 except（吞异常）是大忌**——至少记日志。

## 4. 常见异常家族

| 异常 | 触发 |
|---|---|
| `EConvertError` | `StrToInt('12x')` 等转换失败 |
| `EDivByZero` | 整数除零（`uses SysUtils` 之后才是异常） |
| `EZeroDivide` | 实数除零 |
| `ERangeError` | 数组/子界越界（检查通道 `-Cr` 下触发） |
| `EListError` | `TList`/`TStringList` 越界索引 |
| `EInvalidPointer` / `EAccessViolation` | 野指针/重复 Free |
| `EAssertionFailed` | `Assert` 失败（`{$C+}` 下） |
| `EStreamError` 家族 | 文件流读写（`EFileNotFound`/`EWriteError`） |

注意：`uses SysUtils` 与否改变除零的表现——**不用 SysUtils 时它是"运行时错误 200"
直接崩进程**（RTL 未挂异常钩子）。现代代码永远 uses SysUtils。

> 坑（实测）：除数是**编译期常量 0** 时，`1 div ZeroVal` 直接编译报错
> `Division by zero`——常量折叠在编译期就拒了。要演示运行期 `EDivByZero`，
> 除数得是变量。

## 5. raise：抛出与转发

```pascal
// 抛出自定义
raise ETooYoung.Create(Format('年龄 %d 未满 18', [age]));

// 捕获后换类型转发（包装）
try
  Level3;
except
  on E: Exception do
    raise ESalaryError.Create('Level2 包装：' + E.Message);
end;

// 裸 raise; 原样重抛当前异常（保留原栈）
except
  on E: Exception do
  begin
    Log(E);
    raise;                       // ← 无参数形式
  end;
end;
```

`Exception.Create(消息)` 是标准构造；异常类名以 **E** 开头是铁惯例
（对照类型 T、接口 I、枚举 T+名词）。

## 6. 完整形态：except 套 finally

```pascal
sl := TStringList.Create;
try                                     // 外层 finally：护资源
  try                                   // 内层 except：处理错误
    sl.Add('数据行');
    raise Exception.Create('处理中途失败');
  except
    on E: Exception do
      WriteLn('处理错误但资源已护住：', E.Message);
  end;
finally
  sl.Free;
end;
```

**内 except、外 finally**（先处理后释放）。反过来写（finally 在内）异常会先穿透
finally 再找 except——资源释放了，但 except 拿到的现场已变。

## 7. Assert：开发期检查，发布期蒸发

```pascal
{$C+}                        // 或命令行 -Sa；本教程检查通道全局开启
Assert(1 + 1 = 2, '数学崩了');
```

- 通过时**零成本**；失败抛 `EAssertionFailed`。
- `{$C-}`（发布构建）下整段**编译消失**——所以断言里别放业务副作用。
- 这也是双通道验证存在的理由（02 章）：错误的断言在发布通道根本不执行，
  检查通道替你盯着。本教程全部示例的关键断言就这样被两个通道轮流烤。

## 8. 自定义异常：继承就是文档

```pascal
type
  ESalaryError = class(Exception);        // 基类：这一族错误的公共祖先
  ETooYoung = class(ESalaryError);        // 具体化

try
  CheckAge(16);
except
  on E: ETooYoung do ...;                 // 具体分支在前
  on E: ESalaryError do ...;              // 家族分支兜底
end;
```

为每个模块建一个异常基类（`EParseError`、`ENetError`），调用方可以只捕家族——
异常类型树就是**错误分类学**。

## 9. 示例与验证

本章示例 `examples/10_exceptions`：finally/except/类型化捕获、常量除零 vs 运行期除零、
包装转发、自定义族、完整形态、Assert。

```powershell
pwsh -File build.ps1 -Example 10_exceptions
```

## 10. 坑位清单（实测）

1. **没有三合一语法**——`try..except..finally` 写一起是语法错误；用嵌套（内 except 外 finally）。
2. 常量除零是**编译期**错误，运行期 `EDivByZero` 需要变量除数。
3. `on` 分支按声明顺序匹配——父类放前面会把子类全截走。
4. 不 `uses SysUtils` 时除零/IO 错误是"运行时错误"直接崩，不是异常。
5. `Assert` 在 `{$C-}` 下整段消失——副作用代码禁止入断言。
6. 吞异常（空 except）比崩溃更难查——至少打日志再 `raise;`。

---
上一章：[09 单元与工程](09-units.md) ｜ 下一章：[11 文件与序列化](11-files.md) ｜ 返回：[README](../README.md)
