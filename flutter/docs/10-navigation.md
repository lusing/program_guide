# 10 · 导航与路由：页面的栈

> 对应示例：examples/10_navigation/

## 10.1 解决什么问题

应用总要多页面。Flutter 的 Navigator 是一个**栈**——push 进新页、pop 弹回旧页，没有"全局页面注册中心"这种东西。这个模型简单到一句话，但有两个必须养成的配套习惯：**页面间传数据走构造参数、页面回传走 pop 的返回值**。

```dart
  // ═══ 10.1 push 一个页面并 await 它的返回值 ═══
  Future<void> _openDetail() async {
    final picked = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const DetailPage(item: 7)),
    );
    if (!mounted) return;
    setState(() => _result = picked ?? '直接返回（无值）');
  }
```

三个要点一次看清：`MaterialPageRoute` 的 builder **惰性**建页；**push 返回 Future**——await 它拿到新页 pop 回来的值（`Navigator.push<String>` 声明返回值类型）；await 之后用 context/state 前的 `if (!mounted) return` 是纪律（用户可能已经离开这页）。

## 10.2 pop 带回返回值；参数走构造

```dart
            FilledButton(
              // ═══ 10.1（续）pop 带回返回值 ═══
              onPressed: () => Navigator.pop(context, '选中了 #$item'),
              child: const Text('选定并返回'),
            ),
```

```dart
// ═══ 10.2 页面参数：构造传参（不可变配置的一部分） ═══
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.item});

  final int item;
```

数据进页面 = **构造参数**（Widget 本来就是不可变配置，参数即数据，第 03 章哲学的应用）；数据出页面 = **pop 的第二个参数**。用户点标题栏返回/ESC 时 pop 没带值，Future 得到 null——所以 `picked ?? '直接返回'` 兜底。复杂对象（整条 Note）同样直接传引用，第 20 章实战就传 Note。

## 10.3 命名路由：字符串寻址

```dart
      // ═══ 10.3 命名路由：字符串寻址，集中登记 ═══
      routes: {
        '/': (context) => const HomePage(),
        '/about': (context) => const AboutPage(),
      },
```

```dart
            onTap: () => Navigator.pushNamed(context, '/about'),
```

把页面登记到 MaterialApp 的 `routes` 表，跳转用 `pushNamed(context, '/about')`。优点：路径集中管理、页面代码不互相 import；缺点：**传参要另走** `settings: RouteSettings(arguments: ...)` 或 `onGenerateRoute` 按名分发。经验：**两三个页面用直接 push（传参方便）；路由多了、要深链/统一转场再上命名路由**。

## 10.4 桌面小注

路由的 Material 转场动画在桌面同样生效（桌面口味上你以后可能想换更克制的 FadeUpwards）；Windows 上 Alt+Left 能触发 pop（返回栈），写桌面应用时留意"用户可能用键盘导航回去"。

## 坑位清单

- **await 后忘 mounted 检查**：lint（use_build_context_synchronously）会拦——本教程所有示例都带 `if (!mounted) return;` 模板。
- **pop 两次**：一次关对话框一次关页面——连点确认按钮时容易叠（对话框的 pop 与页面 pop 是同一个栈）。
- **routes 表必须有 '/'**：没有首页直接红屏。
- **嵌套 Navigator**：标签页各持独立栈（Flutter 的 shell route 思路）是进阶话题；先用"单栈 + pushNamed"跑通。
