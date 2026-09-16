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

validator 的契约：**返回错误文案或 null**（null = 通过）——就是 [Dart 教程·第 12 章](../dart/docs/12-exceptions.md) 说的"错误当值"在 UI 层的翻版。常用参数速查：`obscureText`（密码点）、`autofocus`、`keyboardType`、`maxLines`、`inputFormatters`（输入过滤）。`InputDecoration` 管外观：`labelText`（浮动标签）、`hintText`、`border`（描边形态）、`errorText`（校验错时自动显示 validator 的返回）。

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

点"注册"时 `validate()` 跑全表单的 validator：有一个不过，对应字段下方冒出错误文案且整体返回 false；全过才走提交。取值两套方案二选一：**controller**（实时可读，示例用法）或 **onSaved 回调**（validate 后统一收进 Map）——团队里统一一种，别混。`autovalidateMode: AutovalidateMode.onUserInteraction` 可以让字段失焦即校验（输入即反馈，桌面体验好）。

## 11.4 焦点链：键盘流转

`autofocus: true` 打开即聚焦第一个字段；`onFieldSubmitted`（回车）里 `FocusScope.of(context).nextFocus()` 跳下一格；`FocusNode` 可以做更精细的控制（监听焦点、请求/放弃）。Tab 键默认按**树序**流转——想让顺序符合视觉顺序，就按视觉顺序排 build 里的 children。

## 坑位清单

- **currentState! 空指针**：GlobalKey 没挂到 Form 上（或挂了别的 key）——`Form(key: _formKey)` 别漏。
- **validator 忘 return null**：条件写反，字段永远报错——契约是"错误文案 or null"。
- **controller 与 onSaved 混用取值**：两处来源容易不一致；选一套贯彻。
- **dispose 漏 controller**：表单页字段多，统一在 dispose 里逐个释放（第 08 章纪律）。
