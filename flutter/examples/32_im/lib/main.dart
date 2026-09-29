import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'contacts_page.dart';
import 'data.dart';
import 'profile_page.dart';

/// 32 · IM 聊天界面实战（书的综合案例现代化：去 webview/date_format 两个三方包）。
///
/// 路由表（书 16.1.3 的做法）：
/// '/'   加载页——App 的第一帧不一定是主界面，先亮 LOGO；
/// '/app' 主骨架（底部三 Tab：消息/通讯录/我的）；
/// '/chat' 聊天页，arguments 携带 Contact。
void main() {
  runApp(const ImApp());
}

class ImApp extends StatelessWidget {
  const ImApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 书里是 ThemeData(primaryColor: Colors.green)——M2 时代的写法；
    // 现代写法从种子色生成整套色彩系统（16 章）。
    return MaterialApp(
      title: '聊天室',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      initialRoute: '/',
      routes: {
        '/app': (_) => const AppShell(),
        '/chat': (_) => const _ChatRoute(),
      },
      onGenerateRoute: null,
      home: const SplashPage(),
    );
  }
}

/// 加载页：LOGO 停 2 秒后整体替换为主界面。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // pushReplacement 而不是 push：加载页不该留在返回栈里。
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo/im_logo.png', width: 96),
            const SizedBox(height: 16),
            Text('聊天室', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}

/// 主骨架：底部三 Tab + IndexedStack（切 Tab 不丢各页状态）。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const ConversationsPage(),
          ContactsPage(contacts: kContacts),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: '消息'),
          NavigationDestination(icon: Icon(Icons.contacts_outlined), selectedIcon: Icon(Icons.contacts), label: '通讯录'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

/// 会话列表（书 16.5 的应用页面）。
class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: ListView.builder(
        itemCount: kConversations.length,
        itemBuilder: (context, i) {
          final conv = kConversations[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: conv.peer.avatarColor,
              foregroundColor: Colors.white,
              child: Text(conv.peer.initial),
            ),
            title: Text(conv.peer.name),
            subtitle: Text(conv.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(conv.time, style: Theme.of(context).textTheme.bodySmall),
                if (conv.unread > 0)
                  // M3 红点徽标：倒回去十年要自己拼 Container
                  Badge.count(count: conv.unread),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatPage(peer: conv.peer)),
            ),
          );
        },
      ),
    );
  }
}

/// 命名路由的聊天页入口：arguments 取联系人再交给真页面。
class _ChatRoute extends StatelessWidget {
  const _ChatRoute();

  @override
  Widget build(BuildContext context) {
    final peer = ModalRoute.of(context)!.settings.arguments as Contact;
    return ChatPage(peer: peer);
  }
}
