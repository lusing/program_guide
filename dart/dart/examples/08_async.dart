// 08 异步编程：Future、async/await、Stream
import 'dart:async';

Future<String> fetchUserName() async {
  // 模拟网络延迟
  await Future.delayed(Duration(milliseconds: 50));
  return 'DartUser';
}

Future<int> fetchScore(String user) async {
  await Future.delayed(Duration(milliseconds: 30));
  return user.length * 10;
}

Stream<int> countDown(int from) async* {
  for (var i = from; i >= 1; i--) {
    await Future.delayed(Duration(milliseconds: 20));
    yield i;
  }
}

void main() async {
  // async/await 串行
  var user = await fetchUserName();
  var score = await fetchScore(user);
  print('user=$user, score=$score');

  // Future.wait 并发执行
  var results = await Future.wait([
    Future.delayed(Duration(milliseconds: 40), () => 'A'),
    Future.delayed(Duration(milliseconds: 10), () => 'B'),
  ]);
  print('parallel results: $results');

  // 错误处理：try/catch 捕获 await 抛出的异常
  try {
    await Future.error(StateError('simulated failure'));
  } on StateError catch (e) {
    print('caught: ${e.message}');
  }

  // catchError 链式写法
  var fallback = await Future<int>.error(FormatException('bad input'))
      .catchError((_) => -1);
  print('fallback = $fallback');

  // Stream 消费
  var buffer = StringBuffer('countdown: ');
  await for (var tick in countDown(3)) {
    buffer.write('$tick ');
  }
  print(buffer.toString().trim());

  // Stream 转换
  var doubled = countDown(3).map((n) => n * 2);
  var list = await doubled.toList();
  print('doubled stream: $list');
}
