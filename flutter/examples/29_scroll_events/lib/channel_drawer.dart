// ═══ 29.7 频道抽屉 ═══
// 书 13 章的 ChannelList 模式：频道名 → 请求参数的映射表驱动 Drawer；
// 与主页零构造耦合——选择结果经 ChannelBus 广播出去。

import 'package:flutter/material.dart';

import 'news_data.dart';

class ChannelDrawer extends StatelessWidget {
  const ChannelDrawer({super.key, required this.current});

  final Channel current;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('选择频道',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            for (final channel in allChannels)
              ListTile(
                leading: Icon(
                  channel == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(channel.name),
                onTap: () {
                  // 发布事件后关抽屉；主页在订阅里自己换频道并刷新。
                  ChannelBus.instance.select(channel);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
