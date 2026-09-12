// 09 异常处理：throw、try/catch/on/finally、自定义异常
class InsufficientBalanceError extends Error {
  final double balance;
  final double amount;

  InsufficientBalanceError(this.balance, this.amount);

  @override
  String toString() =>
      'InsufficientBalanceError: 需要 $amount，但余额只有 $balance';
}

class ValidationException implements Exception {
  final String field;
  final String reason;

  ValidationException(this.field, this.reason);

  @override
  String toString() => 'ValidationException($field): $reason';
}

double withdraw(double balance, double amount) {
  if (amount <= 0) {
    throw ValidationException('amount', '金额必须为正数');
  }
  if (amount > balance) {
    throw InsufficientBalanceError(balance, amount);
  }
  return balance - amount;
}

void main() {
  // on 按类型捕获，catch 拿到异常对象与堆栈
  try {
    withdraw(100, 250);
  } on InsufficientBalanceError catch (e) {
    print('捕获到余额不足: $e');
  }

  try {
    withdraw(100, -5);
  } on ValidationException catch (e) {
    print('捕获到校验异常: $e');
  }

  // finally 总会执行
  try {
    var result = withdraw(100, 30);
    print('取款成功，余额 $result');
  } finally {
    print('finally: 释放资源');
  }

  // 通用 catch 可捕获任意对象（含 Error）
  try {
    throw StateError('something broke');
  } catch (e, st) {
    print('generic catch: $e');
    print('stack first line: ${st.toString().split('\n').first}');
  }

  // 重新抛出
  try {
    try {
      throw FormatException('bad format');
    } catch (e) {
      print('inner catch: $e');
      rethrow;
    }
  } on FormatException catch (e) {
    print('outer catch: ${e.message}');
  }
}
