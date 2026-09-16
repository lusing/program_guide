import 'package:flutter/material.dart';

// 11 表单与输入：Form/TextFormField/校验/FocusNode
void main() => runApp(const FormsApp());

class FormsApp extends StatelessWidget {
  const FormsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: const SignupPage(),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // ═══ 11.1 FormState 的钥匙：GlobalKey 触发校验/保存 ═══
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _message = '';

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // ═══ 11.3 validate()：跑一遍全部字段的 validator ═══
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _message = '欢迎，${_userCtrl.text}！');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('表单')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            const SizedBox(height: 12),
            FilledButton(onPressed: _submit, child: const Text('注册')),
            const SizedBox(height: 12),
            if (_message.isNotEmpty) Text(_message),
          ],
        ),
      ),
    );
  }
}
