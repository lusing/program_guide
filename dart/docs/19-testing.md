# 19 · 测试：package:test 与可测试的代码

> 对应示例：examples/19_testing/（独立 pub 包）

## 19.1 解决什么问题

第 20 章要写一个几百行的实战工具，凭什么敢边写边改？凭测试兜底。反过来，"为什么我的代码难测"往往是设计问题：逻辑与 IO 纠缠、参数写死、全局状态。本章用 package:test 讲测试写法，更讲**什么样的代码天生好测**——这一课比任何断言 API 都值钱。

工程形态（19_testing 目录）：`pubspec.yaml` 的 dev_dependencies 声明 `test`，测试放 `test/` 目录，文件名以 `_test.dart` 结尾。跑法：

```bash
cd examples/19_testing
dart test                       # 全部
dart test --plain-name "满 100 打九折"   # 只跑名字匹配的单个用例
dart test --reporter expanded   # 展开每个用例的结果
```

## 19.2 骨架：test/group/expect 与夹具

```dart
void main() {
  // group：把同一主题的用例聚在一起，共享 setUp 里的夹具
  group('Cart 合计', () {
    late Cart cart;

    setUp(() {
      cart = Cart();
      cart.add(const CartItem('书', 45.0, 2));
      cart.add(const CartItem('笔', 5.0, 3));
    });

    test('单价×数量后求和', () {
      expect(cart.total, closeTo(105.0, 0.001));
    });

    test('满 100 打九折', () {
      expect(cart.payable(), closeTo(94.5, 0.001));
    });

    test('空车不打折', () {
      expect(Cart().payable(), 0);
    });
  });
```

三原语各司其职：`test('行为描述', fn)` 一个用例（名字写**行为**："满 100 打九折"而不是"testPayable1"）；`group` 聚主题；`setUp/tearDown` 每个用例前后各跑一遍（夹具重建，用例之间零共享）。用例内部推荐 **AAA 三段**：Arrange 准备 → Act 执行 → Assert 断言——短用例一眼三段。

## 19.3 匹配器：expect 的词表

```dart
    test('负数量抛 ArgumentError', () {
      expect(() => CartItem.parse('书', 45.0, -1), throwsA(isA<ArgumentError>()));
    });

    test('集合匹配器', () {
      final cart = Cart()..add(const CartItem('书', 45.0, 1));
      expect(cart.items.map((i) => i.name), contains('书'));
      expect(cart.items, hasLength(1));
    });
```

| 匹配器 | 断言什么 |
|---|---|
| `equals(x)`（expect 默认） | 深相等 |
| `closeTo(x, 误差)` | **浮点必用**（0.1+0.2 != 0.3 的世界） |
| `throwsA(isA<T>())` | 执行抛 T（注意喂的是**函数**） |
| `contains(x)` / `hasLength(n)` | 包含 / 长度 |
| `isTrue` / `isFalse` / `isNull` / `isNotNull` | 单值判定 |
| `predicate((x) => …)` | 任意条件兜底 |

## 19.4 好测试的形状：被测代码的素质

回头看 fixture 的设计，好测不是测出来的，是**设计**出来的：

```dart
  /// 满 [threshold] 元打 [rate] 折（0.9 = 九折）；空车或未达标不打折。
  double payable({double threshold = 100, double rate = 0.9}) {
```

四个可测试性素质，全是前 19 章知识的应用：

1. **纯逻辑与 IO 分离**——Cart 不碰文件与网络，秒级万次运行（第 20 章把存储拆成独立模块同理）；
2. **行为参数化**——threshold/rate 可注入，测试能覆盖任意档位而不必造全局配置；
3. **边界与负例成对**——"负数量抛 ArgumentError"与"正常输入"同组出现（第 12 章 Error/Exception 分界）；
4. **默认值友好**——不传参即可用，测试最简路径零仪式（第 05 章命名参数）。

## 19.5 红绿循环：小步的安全感

写测试的节奏建议"红→绿→重构"：先写一个**会失败**的用例（红），写最小实现让它通过（绿），在绿灯保护下重构。第 20 章的 parser、storage 都可以这么推进——每个行为先有测试背书，重构时跑一遍就知道有没有改坏。

## 坑位清单

- **浮点用 equals 会抖**：`expect(0.1 + 0.2, 0.3)` 挂掉不是数学问题，是浮点问题——一律 closeTo。
- **用例之间共享可变状态**：setUp 重建夹具正是为此；static 缓存会让用例顺序敏感（Temperature._cache 那种缓存要么注入要么清空）。
- **throwsA 喂成了调用结果**：`expect(parse(-1), throws…)` 直接就抛了——要喂**函数** `() => parse(-1)`。
- **测试依赖执行顺序**：单跑绿、全跑红 = 有共享状态；group 的隔离只是"语义分组"，不是沙箱。
