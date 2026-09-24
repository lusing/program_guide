# WinUI 3 示例重组：画廊 → 功能工程（spec 附录）

日期：2026-09-23 ｜ 状态：已批准
前置：2026-09-22-winui3-tutorial-expansion-design.md

## 动机

用户评审：四个画廊是「StatusText + 控件 + 点击变状态」的 API demo 拼凑，控件间无业务关系。重组为**功能驱动**的 mini-app，控件在真实场景出场、改动真的生效并持久化。

## 决策（用户确认）

- 粒度：**功能组合工程**（非每控件独立）
- 旧画廊：**彻底删除替换**
- 文档：改示例引用与证据路径 + 顺带把薄章加深到 200+ 行（正文真正达 3x ≈ 9000 行）

## 四个功能工程

| 工程 | 形态 | 承接章 |
|------|------|--------|
| `07-settings-hub` | 设置中心：主题/强调色/透明度真生效，通知开关联动禁用，偏好持久化 JSON，设置搜索真过滤导航 | 7/8/10/11/12/13/14/15/16/25（+22 外壳） |
| `09-scratchpad` | 文本编辑器：TabView 多文档 + 关闭未保存确认 + RichEditBox 加粗/斜体 + 查找栏 + Expander 选项 + 菜单/工具栏 + 文档落盘 | 9/21/23/24 |
| `17-data-explorer` | 数据浏览器：SplitView 侧栏 TreeView 分类过滤 + ListView↔GridView 视图切换 + 自制表格多列 + FlipView 详情 + 文本过滤 | 17/18/19/20（+22 SplitView） |
| `26-theme-lab` | 主题实验室：预设换肤真生效 + 自定义控件仪表盘 + 三套样式对比 + ColorPicker 改全局强调资源 + VSM 自适应 + 主题切换过渡动画 + Shape 图表 | 26/27/28/29/30 |

## 处置

- 删除：07-controls-basic / 17-controls-collections / 21-controls-shell / 26-customization
- 保留：01 / 06 / 31 / 32 / 34 / 35
- smoke：逐控件页验证 → **逐功能流程验证**（切主题界面真变色、关页签确认框后页签消失、点分类列表真过滤等），约 16-20 条
- README 验证状态区重写；章节引用与证据路径全部改指新工程

## 章节映射（24 章改引用）

7→SH 按钮 ｜ 8→SH 文案 ｜ 9→SP ｜ 10→SH 外观 ｜ 11→SH 通知 ｜ 12→SH 偏好/进度 ｜ 13→SH 偏好 ｜ 14→SH 外观 ｜ 15→SH 搜索 ｜ 16→SH 偏好 ｜ 17→DE ｜ 18→DE ｜ 19→DE ｜ 20→DE ｜ 21→SP ｜ 22→SH 外壳+DE SplitView ｜ 23→SP ｜ 24→SP+TaskFlow ｜ 25→SH ｜ 26-30→TL（SH=settings-hub, SP=scratchpad, DE=data-explorer, TL=theme-lab）
