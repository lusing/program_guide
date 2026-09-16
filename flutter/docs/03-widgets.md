# 03 · Widget：不可变的配置树

> 对应示例：examples/03_widgets/

## 3.1 解决什么问题

写过桌面/网页框架的人习惯"控件是可变对象"：拿到按钮引用、改它的文本、加个监听。Flutter 推翻这套：**Widget 是不可变的配置描述**——`Text('你好')` 只是"画一段'你好'"的说明书，你永远改不了它，只能**换一份新说明书**。这不是刁难，是为"声明式 UI + 高效 diff"买的单：配置不可变，前后两棵树才能廉价比较（[Dart 教程·第 03 章](../dart/docs/03-values.md) 的 const/final 正是同款思想）。

最小的 Widget 长这样：

```dart
// ═══ 3.1 StatelessWidget：纯配置，build 描述"长什么样" ═══
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    // …
  }
}
```

三件套：继承 `StatelessWidget`、`const` 构造、实现 `build`。build 是**纯描述**——同样的输入（构造参数 + context）永远产出同样的界面，所以框架可以放心地频繁调用它。

## 3.2 展示组件速览：积木先认识几块

```dart
    // ═══ 3.2 基础展示组件：Card/ListTile/Icon/Text/Divider ═══
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: const Text('阿 Dart'),
        subtitle: const Text('一名会写 Dart 的开发者'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
```

常用积木一张表（全部不可变配置）：

| Widget | 一句话 | 常用参数 |
|---|---|---|
| `Text` | 文本 | `style`（TextStyle：字号/粗细/颜色） |
| `Icon` | 图标（内置 Material 图标集） | `Icons.xxx`、`size`、`color` |
| `CircleAvatar` | 圆形容器（头像/序号） | `child`、`radius` |
| `Card` | 卡片容器（圆角+阴影） | `child`、`elevation` |
| `ListTile` | 一行信息（列表项标配） | `leading/title/subtitle/trailing` 四位 |
| `Divider` | 分隔线 | `height` |

ListTile 的四个"座位"值得记住：`leading`（左）、`title`（主）、`subtitle`（副）、`trailing`（右）——之后列表章会反复用。

## 3.3 组合优于继承：界面是拼出来的

```dart
        // ═══ 3.3 组合优于继承：页面 = Widget 拼 Widget ═══
        body: ListView(children: const [ProfileCard(), SkillList()]),
```

想扩展 Text 的功能？不继承（Widget 也不鼓励继承），**包一层**：要边距就包 Padding、要卡片就包 Card、要点击就包 InkWell（第 07 章）。WinForms 时代"继承 Button 造 SuperButton"的套路在这里是"Button 外面套 N 层装饰"——层次即功能。嵌套深了读不下去时，把内层**提取成具名 Widget**（像 ProfileCard 那样），缩进自然变浅；Flutter Inspector（DevTools）能可视化这棵树。

## 3.4 const：不止是风格，是复用

```dart
        // ═══ 3.4 const 复用：配置不可变，编译期就固定 ═══
        for (final s in skills)
          ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(s),
          ),
```

`const Icon(...)` 让三个条目**共享同一个 Icon 实例**——不可变配置本来就没必要每次新建，框架 diff 时"同一实例"直接跳过整棵子树比较。这就是 lint 强制 prefer_const 的原因：不是洁癖，是性能习惯。注意 `const [ProfileCard(), SkillList()]`（列表整体 const）与 `ListView(...)`（**ListView 构造不是 const**）的正确组合姿势——把 const 放在能放的最大范围。

## 3.5 三棵树一瞥：为什么重建不慢

Widget 之下还有两层框架实现：**Element**（Widget 的实例化对应物，持有状态、管理树结构）与 **RenderObject**（真正布局绘制的对象）。日常心智模型：Widget 树 = 不断重建的"图纸"，Element/RenderObject = 稳定的"厂房"——图纸变了，厂房只按差异小改。所以"整个页面重建"听起来吓人，实际便宜的只是比较，真正的布局绘制是增量的。第 08 章讲 setState 时会用到这个模型：为什么 State 在 Element 侧长期存活。

## 坑位清单

- **build 里做重活**：build 会被频繁调用——发请求/读文件/深计算放 `initState` 或事件回调（第 08/13 章），build 只做纯描述。
- **在 build 里 new TextEditingController**：每次重建换新控制器，输入状态丢失——控制器是 State 字段（第 08 章）。
- **忘 dispose 控制器**：泄漏警告，State 的 dispose 里统一释放。
- **Widget 撞名**：自定义类别用 Flutter 已有名字（如 `WidgetsApp`）——import 冲突直接编译错；命名加 Demo/App 后缀避让。
