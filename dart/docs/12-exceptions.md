# 12 · 异常：Error 与 Exception 的分界线

> 对应示例：examples/12_exceptions.dart

## 12.1 解决什么问题

try/catch 太好用了，好用到很多人把**程序 bug 也 try 掉**——本该在开发期炸出来的错误被吞成"偶尔不工作"的玄学。Dart 用类型系统划了一条分界线：**Error 族 = 程序 bug，不该捕获；Exception 族 = 可预期失败，选层处理**。理解这条线，比记住多少 catch 语法都重要。

```dart
// ═══ 12.1 throw 与 Never ═══
Never risky() {
  throw StateError('状态不对'); // 永不返回的函数标 Never
}
```

顺带一个类型系统彩蛋：`Never` 是"永不返回"的类型——要么抛异常要么死循环的函数用它标注，编译器因此知道控制流到这里断了（第 13 章的模式穷尽检查也依赖它）。throw 什么都可以（Dart 甚至允许 throw 任意对象），**但请只 throw Exception/Error 族**——自定义异常见 12.6。

## 12.2 try/on/catch：按类型过滤

```dart
  // ═══ 12.2 try/on/catch：on 按类型过滤 ═══
  try {
    account.withdraw(500);
  } on InsufficientBalance catch (e) {
    print('业务异常：$e');
  }

  try {
    account.withdraw(-1);
  } on ArgumentError catch (e) {
    print('参数错误：${e.message}');
  }
```

三种捕获姿势：

| 写法 | 拿到什么 | 适用 |
|---|---|---|
| `on X catch (e)` | 类型 X 的异常对象 | 精确处理某一类 |
| `catch (e)` | 任意异常 | 兜底（慎用，见坑位） |
| `on X`（不带 catch） | 不需要对象 | 只关心"发生了"，如清理路径 |

`on ArgumentError` 的 `e.message` 说明标准 Error 都带诊断信息；自定义异常带什么信息，就是 12.6 的主题。

## 12.3 栈与 rethrow：交给上层时别弄丢现场

```dart
  // ═══ 12.3 捕获调用栈 + rethrow 交还上层 ═══
  try {
    risky();
  } catch (e, stack) {
    print('捕获：$e');
    print('栈顶：${stack.toString().split('\n').first}');
    // rethrow; // 需要上层继续处理时原样抛出（保留原始栈）
  }
```

catch 的第二个参数是 `StackTrace`——"错误在哪发生"的证据链。捕获后想继续往上抛，用 **`rethrow`** 而不是 `throw e`：rethrow 保留原始栈（错误的第一现场），`throw e` 会把栈重置在当前行，上层看到的是"你 rethrow 的位置"而不是真正的出事地点。

## 12.4 finally：无论如何都执行

```dart
  // ═══ 12.4 finally：无论如何都执行 ═══
  try {
    account.withdraw(30);
    print('取款成功，余额 ${account.balance}');
  } finally {
    print('finally：释放资源放这里');
  }
```

finally 在"正常结束/抛异常/rethrow"三种路径下都执行——资源释放（关文件、关连接）的归处。Dart 生态里更地道的资源管理是第 18 章会遇到的模式：IO 对象实现 `Disposable` 风格，但 finally 依旧是语言级的保底。

## 12.5 Error vs Exception：那条分界线

```dart
  // ═══ 12.5 Error vs Exception ═══
  // Error（RangeError/TypeError...）：程序 bug，不该捕获，修代码
  // Exception（自定义业务异常）：可预期失败，选择合适的层捕获处理
  var list = [1];
  try {
    list[5];
  } on RangeError {
    print('RangeError 是 Error：这是 bug，不该靠 try 掩盖');
  }
```

| | Error 族 | Exception 族 |
|---|---|---|
| 成员 | RangeError、TypeError、ArgumentError、StateError… | FormatException、FileSystemException、自定义… |
| 含义 | **程序写错了**（越界、类型错、断言失败） | **世界不配合**（输入非法、网络断、余额不足） |
| 正确反应 | 修代码，**不要捕获** | 在合适的层捕获并处理 |
| 捕获的后果 | 把 bug 埋进生产 | 正常的错误处理流程 |

示例里 catch RangeError 只是为了展示它长什么样——生产代码不该这么写。注意 `ArgumentError` 归 Error 族（调用方传错参数是 bug）；而"取款超过余额"是业务的正常分支，用 Exception 建模。

## 12.6 自定义异常：带上业务上下文

```dart
// ═══ 12.6 自定义异常：实现 Exception 接口 ═══
class InsufficientBalance implements Exception {
  final double need;
  final double have;
  InsufficientBalance(this.need, this.have);

  @override
  String toString() => '余额不足：需要 $need，只有 $have';
}
```

```dart
    if (amount > balance) {
      throw InsufficientBalance(amount, balance); // 业务失败
    }
```

自定义异常的模板三件：`implements Exception`（挂到正确的族）、**带上下文字段**（need/have——调用方catch 后能做精确的分支与展示，而不是靠解析 message 字符串）、重写 `toString`（日志与调试直接可读）。

## 坑位清单

- **裸 `catch (e)` 吞掉一切**：连 Error 和断言都吞；至少 `on Exception catch (e)` 把范围圈在"可预期失败"里。
- **`throw e` 丢栈**：往上层抛一律 `rethrow`。
- **finally 里 return/throw**：会**覆盖** try 里原本要抛出的异常，原始错误凭空消失——finally 只做清理，别再产出新控制流。
- **异常当流程控制**：可预期的业务分支（如"找不到该 id"）优先返回值建模（第 20 章的 ParseErr 就是"错误当值"），异常留给"穿透多层才有人管"的场景。
