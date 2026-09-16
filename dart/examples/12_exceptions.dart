// 12 异常：throw、try/on/catch、finally、Error vs Exception、自定义
// 运行：dart run examples/12_exceptions.dart

// ═══ 12.6 自定义异常：实现 Exception 接口 ═══
class InsufficientBalance implements Exception {
  final double need;
  final double have;
  InsufficientBalance(this.need, this.have);

  @override
  String toString() => '余额不足：需要 $need，只有 $have';
}

class BankAccount {
  double balance = 100;

  void withdraw(double amount) {
    if (amount > balance) {
      throw InsufficientBalance(amount, balance); // 业务失败
    }
    if (amount < 0) {
      throw ArgumentError('取款金额不能为负'); // 调用方 bug
    }
    balance -= amount;
  }
}

void main() {
  var account = BankAccount();

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

  // ═══ 12.3 捕获调用栈 + rethrow 交还上层 ═══
  try {
    risky();
  } catch (e, stack) {
    print('捕获：$e');
    print('栈顶：${stack.toString().split('\n').first}');
    // rethrow; // 需要上层继续处理时原样抛出（保留原始栈）
  }

  // ═══ 12.4 finally：无论如何都执行 ═══
  try {
    account.withdraw(30);
    print('取款成功，余额 ${account.balance}');
  } finally {
    print('finally：释放资源放这里');
  }

  // ═══ 12.5 Error vs Exception ═══
  // Error（RangeError/TypeError...）：程序 bug，不该捕获，修代码
  // Exception（自定义业务异常）：可预期失败，选择合适的层捕获处理
  var list = [1];
  try {
    list[5];
  } on RangeError {
    print('RangeError 是 Error：这是 bug，不该靠 try 掩盖');
  }
}

// ═══ 12.1 throw 与 Never ═══
Never risky() {
  throw StateError('状态不对'); // 永不返回的函数标 Never
}
