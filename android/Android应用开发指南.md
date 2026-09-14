# Android 应用开发指南（Kotlin + Jetpack Compose + JNI，含进阶篇）

本教程按 `guide` 统一标准组织：**Markdown 文档 + 独立示例 + build 脚本 + 可编译验证**。  
默认语言：**Kotlin**。并包含基础篇与进阶篇，覆盖多条 **Jetpack Compose** 示例与 **JNI** 示例。

## 目录

1. [环境准备](#环境准备)
2. [Kotlin 版 Android API 基础示例（21 条）](#kotlin-版-android-api-基础示例21-条)
3. [Jetpack Compose 基础示例（6 条）](#jetpack-compose-基础示例6-条)
4. [Jetpack Compose 进阶示例（4 条）](#jetpack-compose-进阶示例4-条)
5. [JNI 示例](#jni-示例)
6. [统一编译验证](#统一编译验证)

---

## 环境准备

- Android SDK：`G:\android`
- Kotlin 编译器：`G:\scoop\apps\kotlin\current\bin\kotlinc.bat`
- Gradle：`G:\scoop\apps\gradle\current\bin\gradle.bat`
- JDK：`G:\scoop\apps\openjdk\current`
- 教程目录：`G:\code\guide\android`

可选检查：

```powershell
G:\scoop\apps\kotlin\current\bin\kotlinc.bat -version
G:\scoop\apps\gradle\current\bin\gradle.bat -v
G:\scoop\apps\openjdk\current\bin\java.exe -version
```

---

## Kotlin 版 Android API 基础示例（21 条）

目录：`examples/`

1. `01_hello_activity.kt`：Hello Activity
2. `02_layout_views.kt`：布局与控件
3. `03_button_toast.kt`：点击事件与 Toast
4. `04_intent_navigation.kt`：Intent 页面跳转
5. `05_listview_adapter.kt`：ListView/Adapter
6. `06_handler_looper.kt`：主线程消息机制
7. `07_shared_preferences.kt`：轻量键值存储
8. `08_internal_storage.kt`：内部文件读写
9. `09_sqlite_helper.kt`：SQLiteOpenHelper
10. `10_broadcast_receiver.kt`：广播收发
11. `11_service_basics.kt`：Service 基础
12. `12_notifications.kt`：通知 API
13. `13_runtime_permission.kt`：运行时权限
14. `14_content_resolver.kt`：ContentResolver
15. `15_json_parse.kt`：JSON 解析
16. `16_network_thread.kt`：网络线程
17. `17_location_manager.kt`：位置服务
18. `18_sensor_manager.kt`：传感器
19. `19_property_animation.kt`：属性动画
20. `20_activity_result_style.kt`：Activity Result 传统模式
21. `21_jni_bridge.kt`：JNI Kotlin 声明与动态库加载

这些示例通过 `kotlinc + android.jar` 执行静态编译验证，确保 API 调用与 Kotlin 语法可用。

---

## Jetpack Compose 基础示例（6 条）

Compose 工程目录：`compose_examples/app/src/main/java/guide/android/compose/samples/ComposeSamples.kt`

包含以下 6 条示例（一个 Activity 中集中展示）：

1. `ComposeCounterSample`：状态计数器（`remember`/`mutableIntStateOf`）
2. `ComposeLazyListSample`：`LazyColumn` 列表
3. `ComposeThemeToggleSample`：`Switch` 主题切换
4. `ComposeFormValidationSample`：输入校验与状态反馈
5. `ComposeCardListSample`：卡片列表组合
6. `JniStatusSample`：Compose 调 JNI 结果显示

Compose 主入口：

- `compose_examples/app/src/main/java/guide/android/compose/MainActivity.kt`

---

## Jetpack Compose 进阶示例（4 条）

进阶源码：`compose_examples/app/src/main/java/guide/android/compose/samples/AdvancedSamples.kt`

1. `AdvancedViewModelStateFlowSample`：`ViewModel + StateFlow + collectAsStateWithLifecycle`
2. `AdvancedNavigationSample`：`Navigation Compose` 基本路由与参数传递
3. `AdvancedRoomArchitectureSample`：`Room` 的 `Entity + DAO + Database` 架构定义
4. `AdvancedWorkManagerSample`：`WorkManager` 一次性后台任务调度

这 4 条示例与基础 Compose 示例共同参与 Gradle Kotlin 编译验证，保证教程代码可持续维护。

---

## JNI 示例

JNI Kotlin 声明：

- `compose_examples/app/src/main/java/guide/android/compose/jni/GuideNativeBridge.kt`

JNI C++ 实现：

- `compose_examples/app/src/main/cpp/native-lib.cpp`
- `compose_examples/app/src/main/cpp/CMakeLists.txt`

该示例通过 `externalNativeBuild + CMake` 编译 `guide_native`，并在 Kotlin 侧通过 `external fun stringFromJNI()` 调用。

---

## 统一编译验证

全量（Kotlin API + Compose + JNI）：

```powershell
cd G:\code\guide\android
.\build.ps1 -All
```

仅验证 Kotlin API 示例：

```powershell
.\build.ps1 -File 12_notifications.kt
```

仅验证 Compose：

```powershell
.\build.ps1 -Compose
```

仅验证 JNI：

```powershell
.\build.ps1 -Jni
```

清理：

```powershell
.\build.ps1 -Clean
```
