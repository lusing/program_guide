# 07-settings-hub（设置中心）

控件篇第一功能工程：一个**真的能用**的设置界面——主题/密度/透明度即点即生效并持久化，通知总闸真的禁用渠道，保存有进度与反馈。

## 承载章节

| 章 | 控件 | 在本工程的真实职责 |
|---|---|---|
| 7/8 | Button/TextBlock | 保存动作 + 标题/说明/状态行 |
| 10 | RadioButton/CheckBox | 主题三选一组 + 渠道复选（连坐灰显） |
| 11 | ToggleSwitch | 通知总闸 |
| 12 | Slider/ProgressBar | 透明度即时预览 + 保存分帧进度 |
| 13/14 | NumberBox/ComboBox | 任务数默认值 + 列表密度（真改行高） |
| 15 | AutoSuggestBox | NavigationView 内建搜索位（真跳页） |
| 16 | DatePicker/TimePicker | 周起始 + 每日提醒 |
| 22 | NavigationView | 应用外壳 |
| 25 | InfoBar/TeachingTip | 保存反馈条 + 首访教学（只弹一次） |

## 架构

```text
MainWindow          NavigationView 外壳 + ASB 搜索 + SavedBar 浮层
├── AppearancePage  主题/密度/透明度（无 ScrollViewer——手势层吃注入点击，实测）
├── NotificationsPage 总闸/渠道/TeachingTip
├── PreferencesPage NumberBox/日期时间/保存协程
App                 ApplyTheme（资源覆盖 + RequestedTheme 双赋值）
SettingsStore       JSON 键值持久化（%LOCALAPPDATA%\SettingsHub）
```

## 关键实现位

- **换肤**：`App::ApplyTheme` → `RequestedTheme(Default→目标)` 双赋值触发 ThemeResource 重估（WindowsAppSDK 实测坑）
- **密度**：`OnDensityChanged` 代码构造 `Style`(ListViewItem MinHeight)——元数据里没有 PaddingProperty
- **搜索**：`OnSearchChanged` 的 `Reason()` 防重入是正确性不是优化
- **窗口**：构造期 `MoveAndResize`（AppWindow 系实测按**逻辑单位**解释）

## 冒烟

```powershell
pwsh tools\ui-smoke\smoke-settingshub.ps1
```

四流程：theme（整窗换暗）/ master（渠道灰显）/ save（InfoBar+进度）/ search（真跳页）。证据在 `.smoke/07-settings-hub/<流程>/tap-N.png`。
