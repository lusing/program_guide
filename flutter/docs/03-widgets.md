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

### Widget 的四种形态

Flutter 的 Widget 体系按"谁持有状态、怎么渲染"分四类：

| 形态 | 基类 | 用途 | 例子 |
|---|---|---|---|
| 无状态 | `StatelessWidget` | 纯配置，无内部状态 | `Text`、`Icon`、`ProfileCard` |
| 有状态 | `StatefulWidget` | 配置 + State（可变状态） | `Checkbox`、`TextField` |
| 继承式 | `InheritedWidget` | 沿树向下传数据，子孙可订阅 | `Theme`、`MediaQuery`、`Locale` |
| 渲染式 | `RenderObjectWidget` | 直接对应 RenderObject（布局/绘制） | `RichText`、`RawImage` |

前两种占日常代码的 95%（第 08 章展开 StatefulWidget）；InheritedWidget 是主题/媒体查询的底层机制（第 09/16 章展开）；RenderObjectWidget 是框架作者的工具——除非你写自定义渲染（超出本教程范围），否则不碰。

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

### Text 的样式分层

`Text` 的 `style` 参数不是"全有或全无"——`TextStyle` 的每个字段独立生效，没设的字段从最近的 `DefaultTextStyle`（通常是 Theme）继承：

```dart
Text(
  '大字但继承颜色',
  style: Theme.of(context).textTheme.headlineMedium,  // 主题的大字样式
)
```

`Theme.of(context).textTheme` 提供 M3 的全套文字层级（`displayLarge` → `bodyMedium` → `labelSmall`），优先用它们而不是手写 `fontSize: 24`——保证全应用 typography 一致，暗色模式自动适配。

## 3.3 组合优于继承：界面是拼出来的

```dart
        // ═══ 3.3 组合优于继承：页面 = Widget 拼 Widget ═══
        body: ListView(children: const [ProfileCard(), SkillList()]),
```

想扩展 Text 的功能？不继承（Widget 也不鼓励继承），**包一层**：要边距就包 Padding、要卡片就包 Card、要点击就包 InkWell（第 07 章）。WinForms 时代"继承 Button 造 SuperButton"的套路在这里是"Button 外面套 N 层装饰"——层次即功能。嵌套深了读不下去时，把内层**提取成具名 Widget**（像 ProfileCard 那样），缩进自然变浅；Flutter Inspector（DevTools）能可视化这棵树。

### BuildContext：build 的"你在哪"

`build(BuildContext context)` 的 context 参数是**当前 Widget 在树中的位置句柄**——它实际上就是对应的 Element 对象，框架以接口形式暴露（防止你直接操作 Element）。context 的用途：

- **向上找祖先**：`Theme.of(context)`、`Navigator.of(context)`、`Scaffold.of(context)`——都靠 context 沿树向上找到最近的对应 InheritedWidget
- **向下找不到**：context 看不到自己的子孙——想拿子 Widget 的 State 用 GlobalKey（第 08/22 章）

每个 Widget 的 build 拿到的 context **指向自己**（不是父级）——所以 `Theme.of(context)` 读到的是"包着我的主题"，在 build 返回的子树里新包的主题不影响本次 build。

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

### const 的传播规则

`const` 不是"这个 Widget 加不加"的局部决定——它沿构造链传播：父 Widget 要 const，**所有**构造参数也必须是 const（编译期可求值）。这解释了为什么 Flutter 代码里 `const` 随处可见：一个 const 子树要求叶子全 const。反过来，任何一层有运行时值（变量、函数调用），整棵链都失去 const 资格。

```dart
const Card(                    // ✅ Card 可以 const
  child: ListTile(
    title: Text('固定文案'),    // ✅ Text 的构造参数全 const
  ),
)

Card(
  child: ListTile(
    title: Text(userName),     // ❌ userName 是运行时值 → 外层都不能 const
  ),
)
```

## 3.5 Key：Widget 的身份标识

`super.key` 在每个示例里都出现，它的作用是**帮助框架匹配新旧 Widget**：没有 Key 时，框架按"类型 + 在父级 children 中的位置"匹配；有 Key 时按 Key 匹配。三种 LocalKey 的语义：

| Key | 匹配依据 | 场景 |
|---|---|---|
| `ValueKey(v)` | 值相等 | 列表项业务 id（`ValueKey(note.id)`） |
| `ObjectKey(o)` | 同一性（identical） | 同值不同物（两个同名 Note 对象） |
| `UniqueKey()` | 永不相等 | 强制每次重建（极少用） |
| `GlobalKey` | 全局注册表 | 跨树取 State（第 08/11 章 Form 钥匙） |

什么时候**必须**给 Key：列表项有状态（输入框、勾选框）且列表会增删/重排——没 Key 或 Key 随索引变，框架会把"第 2 条的 State"错配给"现在的第 2 条"（数据其实是第 3 条），输入内容"跳行"。第 12 章列表章会实战。

## 3.6 三棵树一瞥：为什么重建不慢

Widget 之下还有两层框架实现：**Element**（Widget 的实例化对应物，持有状态、管理树结构）与 **RenderObject**（真正布局绘制的对象）。日常心智模型：Widget 树 = 不断重建的"图纸"，Element/RenderObject = 稳定的"厂房"——图纸变了，厂房只按差异小改。所以"整个页面重建"听起来吓人，实际便宜的只是比较，真正的布局绘制是增量的。第 08 章讲 setState 时会用到这个模型：为什么 State 在 Element 侧长期存活。

### 重建的实际开销

一次 setState 后框架做的事：

1. **标记**：State 对应的 Element 被标记 dirty
2. **重建**：下一帧调用 build 拿到新 Widget 树（这次 build 是纯 Dart 对象创建，微秒级）
3. **diff**：新树与旧树逐节点比较（type + key 相同 → 复用 Element，更新配置；不同 → 销毁重建）
4. **布局/绘制**：只有真正变化的 RenderObject 重新 layout/paint

const 构造让第 3 步的"复用"变成"identical 直接跳过"——整棵子树比较都不做。这就是第 25 章性能优化的理论基础。

## 3.7 资源与图片：把文件打进应用

图片、图标、配置文本这些静态资源不是"放进目录就能用"——**必须在 pubspec.yaml 里声明**才会打进产物（第 01 章埋的线，这里展开）：

```yaml
# ═══ 3.6 pubspec ═══
flutter:
  uses-material-design: true
  assets:
    - assets/logo/            # 目录写法：整个目录（含变体子目录）一起收
    - assets/config.json      # 单文件写法
```

```dart
// ═══ 3.6 ═══
Image.asset('assets/logo/im_logo.png')     // 显示图片资产
final cfg = await rootBundle.loadString('assets/config.json');  // 读文本资产
```

**分辨率变体**是 asset 体系的招牌能力：同名文件按目录分档——`assets/logo/im_logo.png`（1x）、`assets/logo/2.0x/im_logo.png`（2x）、`3.0x/`……框架按设备像素比自动挑最近的高档变体。代码里**永远写 1x 的路径**，高 DPI 屏不糊、低 DPI 设备不多掏内存，一行代码不用改。

三个使用要点：

- `rootBundle.loadString` 是异步的（`package:flutter/services.dart`），应用启动读配置的场景配 14 章的 FutureBuilder；
- 加载**依赖包**里的资产要给 `package:` 参数：`AssetImage('assets/wifi.png', package: 'resources')`——31 章的插件也走这条路发资产；
- 应用图标与启动屏不在 pubspec 里管：Android 走 `android/app/src/main/res/`，iOS 走 `Assets.xcassets`（28 章发布流程）。

完整实战见 32 章（IM 应用打包带 2.0x 变体的 logo）。

## 坑位清单

- **build 里做重活**：build 会被频繁调用——发请求/读文件/深计算放 `initState` 或事件回调（第 08/13 章），build 只做纯描述。
- **在 build 里 new TextEditingController**：每次重建换新控制器，输入状态丢失——控制器是 State 字段（第 08 章）。
- **忘 dispose 控制器**：泄漏警告，State 的 dispose 里统一释放。
- **Widget 撞名**：自定义类别用 Flutter 已有名字（如 `WidgetsApp`）——import 冲突直接编译错；命名加 Demo/App 后缀避让。
- **列表项忘 Key**：有状态的列表项（输入框/勾选框）在增删重排时 State 错配——给 `ValueKey(item.id)`。
- **context 用错层级**：在 build 返回的子树里新包的主题/InheritedWidget，本次 build 读不到——context 指向当前 Widget，不是返回的子树。
---

上一章：[02 · 第一个应用：从 create 到热重载](02-hello.md) ｜ 下一章：[04 · 布局 I：容器与装饰](04-layout-single.md) ｜ 返回：[README](../README.md)
