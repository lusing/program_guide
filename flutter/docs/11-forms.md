# 11 · 表单：校验与提交

> 对应示例：examples/11_forms/

## 11.1 解决什么问题

输入框单个用 TextField（第 08 章）就够；但"注册表单"需要的是**一组字段统一校验、统一提交**——Form 就是这组字段的"校验域"，配一把 GlobalKey 钥匙调度它。

```dart
class _SignupPageState extends State<SignupPage> {
  // ═══ 11.1 FormState 的钥匙：GlobalKey 触发校验/保存 ═══
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _message = '';
```

结构三件套：`Form(key: _formKey)` 包住字段们；字段用 **TextFormField**（不是 TextField——它带 validator 挂钩）；GlobalKey 是把手，拿它调 `currentState!.validate()`。

### Form / FormField / TextFormField 三层关系

这三层是"容器—协议—实现"的关系，先理清再写代码：

- **`Form`**（容器）：本身不渲染任何东西，只是给后代 `FormField` 提供统一调度。它持有的 `FormState` 提供三个方法：`validate()`（跑全部字段的 validator）、`save()`（触发全部字段的 onSaved）、`reset()`（把全部字段重置回初始值）。
- **`FormField<T>`**（协议）：一个抽象 Widget，定义了字段与 Form 之间的接口——`validator`、`onSaved`、`initialValue`、`autovalidateMode`。Form 不认识 TextFormField，它只认识 FormField。
- **`TextFormField`**（实现）：`FormField<String>` 的具体实现，内部包了一个真正的 `TextField` 负责渲染和输入。你写的 `validator`/`onSaved` 挂在 FormField 层，`controller`/`decoration`/`keyboardType` 透传给内层 TextField。

这个分层解释了为什么 TextFormField 的构造参数看起来是 TextField + FormField 的并集——它确实是两层职责的合体。

### TextFormField 还是 TextField？

一句话判别：**要 Form 统一校验就用 TextFormField，单字段自娱自乐就用 TextField**。TextField 没有 validator/onSaved 挂钩，想校验得自己监听 onChanged 手动判断——一个字段这么干行，五个字段就是灾难。TextFormField 让 Form 替你调度，错误文案的显示位置、时机、样式都自动化。

## 11.2 TextFormField：validator 一行一个规则

```dart
            // ═══ 11.2 TextFormField：validator 一行一个规则 ═══
            TextFormField(
              controller: _userCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '用户名'),
              validator: (v) =>
                  (v == null || v.length < 3) ? '至少 3 个字符' : null,
            ),
            TextFormField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: '密码'),
              validator: (v) =>
                  (v == null || v.length < 6) ? '至少 6 位' : null,
            ),
```

validator 的契约：**返回错误文案或 null**（null = 通过）——就是 [Dart 教程·第 12 章](../dart/docs/12-exceptions.md) 说的"错误当值"在 UI 层的翻版。函数签名是 `FormFieldValidator<String> = String? Function(String? value)`——入参可能为 null（字段从未被触摸时），所以示例里先判 `v == null`。

常用参数速查：

| 参数 | 类型 | 用途 |
|---|---|---|
| `controller` | `TextEditingController?` | 读写当前值（见 11.3） |
| `initialValue` | `String?` | 初始值——**与 controller 互斥**，同时给会 assert 失败 |
| `obscureText` | `bool` | 密码点（配合 `obscuringCharacter: '*'` 可换字符） |
| `autofocus` | `bool` | 打开页面即聚焦 |
| `keyboardType` | `TextInputType?` | 键盘类型（见下表） |
| `textInputAction` | `TextInputAction?` | 回车键图标（`next`/`done`/`search`/`send`） |
| `maxLines` / `minLines` | `int?` | 多行输入（`maxLines: null` 自适应高度） |
| `maxLength` | `int?` | 字数上限（右下角自动出计数器） |
| `inputFormatters` | `List<TextInputFormatter>?` | 输入过滤（见 11.5） |
| `enabled` | `bool?` | false 时字段变灰且不可编辑 |
| `readOnly` | `bool` | true 时可选中复制但不可改（比 enabled 温和） |

`keyboardType` 常用值一张表：

| 值 | 键盘 | 场景 |
|---|---|---|
| `TextInputType.text`（默认） | 字母 | 通用 |
| `TextInputType.number` | 数字 | 年龄、数量 |
| `TextInputType.phone` | 拨号盘 | 手机号 |
| `TextInputType.emailAddress` | 带 @ 的字母键盘 | 邮箱 |
| `TextInputType.url` | 带 .com 条 | 网址 |
| `TextInputType.multiline` | 多行 + 回车换行 | 备注、评论 |

注意 `keyboardType` 只是**软键盘的提示**——桌面端没有软键盘，这个参数在 Windows/macOS 上无效果；它不限制输入内容（用户用物理键盘什么都能敲），要限制内容用 `inputFormatters`（11.5）。

## 11.3 validate 与提交流程

```dart
  void _submit() {
    // ═══ 11.3 validate()：跑一遍全部字段的 validator ═══
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _message = '欢迎，${_userCtrl.text}！');
    }
  }
```

点"注册"时 `validate()` 跑全表单的 validator：有一个不过，对应字段下方冒出错误文案且整体返回 false；全过才走提交。取值两套方案二选一：

- **controller**（示例用法）：`_userCtrl.text` 随时可读，适合"提交时才取值"的简单场景
- **onSaved 回调**：validate 通过后 `save()` 统一触发每个字段的 `onSaved: (v) => _formData['user'] = v`——适合字段多、想集中收进一个 Map 的场景

团队里统一一种，别混。`autovalidateMode: AutovalidateMode.onUserInteraction` 可以让字段失焦即校验（输入即反馈，桌面体验好）。

### AutovalidateMode 三态

`AutovalidateMode` 控制"什么时候自动跑 validator"：

| 值 | 语义 | 场景 |
|---|---|---|
| `disabled`（默认） | 不自动校验，只在 `validate()` 被调用时跑 | 提交时才报错的经典表单 |
| `onUserInteraction` | 用户碰过字段（输入或失焦）后自动校验 | 边输边反馈，纠错及时 |
| `always` | 字段一 build 出来就校验 | 编辑已有数据时立刻标出当前非法字段 |

经验：**注册/登录表单用 disabled（点提交才报）或 onUserInteraction（输完一项报一项）**；always 容易让"还没填"的字段一打开就一片红，体验差——只有"回填数据编辑"场景适合。

## 11.4 InputDecoration：外观全参数

`InputDecoration` 管外观。按功能分组：

| 组 | 参数 | 说明 |
|---|---|---|
| 标签 | `labelText` / `label` | 浮动标签——聚焦或输入时缩到左上角，空时占满输入区 |
| 提示 | `hintText` / `hint` | 空字段时的占位文字，聚焦时消失 |
| 图标 | `prefixIcon` / `suffixIcon` | 输入框**内部**的固定图标（锁、眼睛） |
| 任意装饰 | `prefix` / `suffix` | 输入区前后的任意 Widget（比 Icon 灵活） |
| 辅助 | `helperText` | 标签下方的常驻说明文字 |
| 计数 | `counterText` | 右下角计数（`maxLength` 会自动生成） |
| 边框 | `border` / `enabledBorder` / `focusedBorder` / `errorBorder` / `focusedErrorBorder` / `disabledBorder` | 各状态下的描边形态 |
| 错误 | `errorText` | 错误文案——validator 返回非 null 时框架自动显示，手动传则覆盖 |

`labelText` 与 `hintText` 的分工：**label 是"这个字段叫什么"，hint 是"请填什么例子"**——`labelText: '邮箱'` + `hintText: 'name@example.com'`。`prefixIcon` 与 `prefix` 的区别：Icon 是固定槽位（不影响文字布局），prefix 是任意 Widget 且可以随焦点变化（比如聚焦时显示搜索进度条）。

边框五态一张表（Material 3 默认下沿）：

| 状态 | 生效的 border |
|---|---|
| 未聚焦无错 | `enabledBorder`（或 `border` 兜底） |
| 聚焦无错 | `focusedBorder` |
| 未聚焦有错 | `errorBorder` |
| 聚焦有错 | `focusedErrorBorder`（errorBorder 兜底） |
| 禁用 | `disabledBorder` |

日常用 `border: OutlineInputBorder()` 一条就够——所有状态共享圆角描边；要区分错误态颜色时单独给 `errorBorder` 上色。

## 11.5 inputFormatters：输入过滤

`inputFormatters` 在**字符进入 controller 之前**拦截修改——不是校验（事后判对错），是过滤（事前拦字符）。常用组合：

```dart
import 'package:flutter/services.dart';

// 只允许数字
TextFormField(
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  decoration: const InputDecoration(labelText: '手机号'),
)

// 只允许单行道——把换行符干掉
TextFormField(
  inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
)

// 自定义正则：只允许字母和数字（拒绝表情、空格、标点）
TextFormField(
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
  ],
)

// 长度硬上限（比 maxLength 更硬——maxLength 还能粘贴超长再截断显示）
TextFormField(
  inputFormatters: [LengthLimitingTextInputFormatter(11)],
)
```

`FilteringTextInputFormatter.allow(pattern)` 是白名单（只留匹配的），`deny(pattern)` 是黑名单（删掉匹配的）。内置静态实例 `digitsOnly`（`RegExp(r'[0-9]')`）和 `singleLineFormatter`（`\n` 黑名单）覆盖最高频场景。

formatter 与 validator 的配合：**formatter 管"能不能输入"，validator 管"输入完对不对"**。手机号字段：formatter 限 11 位数字，validator 检查"是不是 1 开头"——两层各管一段。

## 11.6 焦点链：键盘流转

`autofocus: true` 打开即聚焦第一个字段；`onFieldSubmitted`（回车）里 `FocusScope.of(context).nextFocus()` 跳下一格；Tab 键默认按**树序**流转——想让顺序符合视觉顺序，就按视觉顺序排 build 里的 children。

### FocusNode：编程控制焦点

更精细的控制用 `FocusNode`：每个需要编程控制的字段挂一个 node，State 里创建、dispose 里释放（与 controller 同纪律）：

```dart
final _userFocus = FocusNode();
final _passFocus = FocusNode();

@override
void dispose() {
  _userFocus.dispose();
  _passFocus.dispose();
  super.dispose();
}

TextFormField(
  focusNode: _userFocus,
  onFieldSubmitted: (_) => _passFocus.requestFocus(),  // 回车跳密码框
  // ...
)
```

`FocusNode` 的三个常用操作：

- **`requestFocus()`**：把焦点抢过来（等价于 `FocusScope.of(context).requestFocus(node)`，后者显式指定作用域）
- **`unfocus()`**：放弃焦点（软键盘随之收起）——提交成功后 `_passFocus.unfocus()` 让键盘退下
- **`addListener(() => ...)`**：监听焦点得失，做"聚焦时显示帮助文字"之类的联动

### textInputAction 与回车语义

`textInputAction: TextInputAction.next` 让软键盘回车键显示"下一项"箭头；最后一个字段给 `TextInputAction.done` 显示"完成"。桌面端没有软键盘，但 Enter 键的行为同样受 `onFieldSubmitted` 管辖——给每个字段安排好回车去向，桌面用户不用摸鼠标。

## 11.7 跨字段校验与错误定位

### 跨字段校验

"确认密码"要访问密码字段的值——validator 只有一个入参（自己的值），跨字段靠 controller 闭包：

```dart
TextFormField(
  controller: _confirmCtrl,
  obscureText: true,
  decoration: const InputDecoration(labelText: '确认密码'),
  validator: (v) =>
      v != _passCtrl.text ? '两次输入不一致' : null,
)
```

validator 在 `validate()` 被调用的那一刻执行——此刻 `_passCtrl.text` 是最新值，闭包读到的是现场。注意**校验顺序**：Form 按字段在树中的顺序跑 validator，确认密码必须排在密码之后（视觉顺序即校验顺序）。

### 错误字段自动滚动

表单长于一屏时，用户点提交、第一个错误字段在屏幕外——体验断裂。两种补救：

1. **提交前手动滚**：给每个字段包一个 Scrollable.ensureVisible 的 key，validate 失败后找到第一个错误字段滚过去（要写约 20 行胶水代码）。
2. **避免长表单**：桌面端屏幕大，分页/分 Tab 比"一页滚到底"更常见——把"账号信息 / 个人资料 / 偏好设置"拆成三个 Tab 页，每页一个独立 Form。

本教程的示例（两个字段）不需要滚动定位；真遇到长表单，优先方案 2。

## 11.8 提交后：重置与脏标记

`FormState.reset()` 把全部字段重置回 `initialValue`（controller 字段则保留 controller 的当前值——reset 只清 FormField 内部状态，不动 controller，这是又一个"controller 与 initialValue 不要混用"的理由）。

编辑场景的脏标记（"有未保存修改"）自己维护：

```dart
bool _isDirty = false;

TextFormField(
  controller: _userCtrl,
  onChanged: (_) => setState(() => _isDirty = true),
  // ...
)
```

配合第 10 章的 `PopScope(canPop: !_isDirty, ...)` 拦截误退——表单 + 导航的组合拳。

## 坑位清单

- **currentState! 空指针**：GlobalKey 没挂到 Form 上（或挂了别的 key）——`Form(key: _formKey)` 别漏。
- **validator 忘 return null**：条件写反，字段永远报错——契约是"错误文案 or null"。
- **controller 与 initialValue 同给**：assert 失败——二选一。controller 字段想设初值，在 initState 里 `_ctrl.text = '初值'`。
- **controller 与 onSaved 混用取值**：两处来源容易不一致；选一套贯彻。
- **dispose 漏 controller / FocusNode**：表单页字段多，统一在 dispose 里逐个释放（第 08 章纪律）。FocusNode 与 controller 一样占用资源，漏 dispose 会在页面反复进出时累积。
- **keyboardType 当输入限制**：它只是软键盘提示，不拦物理键盘输入——内容限制交给 inputFormatters。
- **inputFormatters 顺序**：多个 formatter 按列表顺序应用——先 `LengthLimiting` 再 `Filtering` 与反过来结果不同（先限长再过滤可能留下非法字符；先过滤再限长才是"只数合法字符"）。白名单 + 限长的常见组合把 `Filtering` 放前面。
- **onFieldSubmitted 里跳下一格但下一格不在屏幕内**：ScrollView 不会自动滚——长表单把"跳下一格"换成"跳可见的下一格"，或接受用户手动滚。
---

上一章：[10 · 导航与路由：页面的栈](10-navigation.md) ｜ 下一章：[12 · 列表与滚动：从十条到十万条](12-lists.md) ｜ 返回：[README](../README.md)
