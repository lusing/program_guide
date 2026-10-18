# 28 · 移动端构建与发布：以 Android 为例

> 对应示例：examples/28_android_release/（`flutter build apk --release` 实测通过）

## 28.1 解决什么问题

写完只是上半场。发布流水线：**身份（名称/ID/版本）→ 脸面（图标/闪屏）→ 签名 → 构建 → 商店**。Windows 桌面的构建发布在第 18 章讲过；本章以 Android 为主线走完整链路（本机 SDK 实测），iOS 流程对照讲清（需 Mac，本教程 Windows 主线不实测）。示例工程改好了全部发布配置，release APK 真实构建过。

## 28.2 身份三件套：名称、ID、版本

```text
显示名称   android/app/src/main/AndroidManifest.xml → android:label="发布演示"
应用 ID    android/app/build.gradle.kts → applicationId = "com.guide.release_demo"
版本       pubspec.yaml → version: 1.2.0+7
```

- `applicationId` 是商店里的全球唯一身份证，**发布后不可换**（换=新应用）。书年代要同时改 manifest 的 `package` 属性；现代模板由 `namespace` 接管（编译期包名），`applicationId` 独立——不必再保持两者一致地手改。
- `1.2.0+7`：加号前是 `versionName`（用户可见），加号后是 `versionCode`（整数，商店判断升级）。**每次发版必须递增 versionCode**，versionName 随意。构建时也可命令行覆盖：`flutter build apk --build-name=1.2.1 --build-number=8`。
- iOS 侧对应：Xcode 里 `Display Name` 与 `Bundle Identifier`（书 19.4 的 General 页就是它），pubspec 的 version 同时映射到 `CFBundleShortVersionString`/`CFBundleVersion`。

### 28.2.1 运行时读版本号

示例在 Dart 侧写死了 `const appVersion = '1.2.0+7'` 与 pubspec 保持同步——演示可以，真项目会漂移。生态包 `package_info_plus`（社区维护，pub.dev 上 package_info 的活跃继任者）运行时读：

```dart
// ═══ 28.2.1 真项目：从平台读，不写死 ═══
final info = await PackageInfo.fromPlatform();
print('${info.appName} ${info.packageName} ${info.version}+${info.buildNumber}');
```

`version`/`buildNumber` 就是 pubspec 里加号的两段——"关于"页、接口 UA、崩溃上报都从这里取，单一事实源在 pubspec。

## 28.3 脸面：图标与闪屏

- **图标**：生态包 `flutter_launcher_icons`（dev_dependencies）+ 一张 1024×1024 源图，一键生成 Android 全密度 `mipmap-*` 与 iOS `Assets.xcassets`（书 19.1 的流程原样有效，包已迭代多年）。Android 8+ 另有**自适应图标**（前景/背景两层，启动器按形状裁剪）；Android 13+ 还支持**单色图标**（用户换主题色时图标跟着变）。配置示例：

```yaml
# ═══ 28.3 pubspec.yaml 里的生成配置 ═══
flutter_launcher_icons:
  android: true
  ios: true
  remove_alpha_ios: true          # App Store 要求 iOS 图标无透明通道
  image_path: "assets/icon.png"   # 1024×1024 源图
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon_foreground.png"
  adaptive_icon_monochrome: "assets/icon_mono.png"   # Android 13+ 主题图标
```

生成命令：`dart run flutter_launcher_icons`（老写法 `flutter pub run flutter_launcher_icons` 已废弃）。

- **闪屏**：Android 的 `res/drawable/launch_background.xml`（layer-list：底色 + 居中位图，书 19.2）；生态包 `flutter_native_splash`（2.4.x）把这套模板化，注意 **Android 12+ 的闪屏 API 完全不同**（系统强制 SplashScreen 主题），该包有独立的 `android_12:` 配置段。iOS 是 `LaunchImage.imageset`。
- 这两步都是**生成物进原生目录**——改完要重新构建，热重载不管用。

## 28.4 签名：release 的通行证

未签名的 release 包装不进任何手机。三步（书 19.3 的现代版，gradle 已从 Groovy 换成 **Kotlin DSL**）：

```bash
# ① 生成私钥（一次性，保管到天荒地老——丢了就无法给同一应用发更新）
keytool -genkeypair -v -keystore android/app/release-demo.jks -alias release-demo \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass <密码> -keypass <密码> -dname "CN=Release Demo, OU=Guide, O=CodeGuide, C=CN"
```

```kotlin
// ② android/key.properties（密码与路径，绝不进 git）
//    storePassword=…  keyPassword=…  keyAlias=release-demo  storeFile=release-demo.jks
//    注意：storeFile 相对【模块目录 android/app/】解析，不是 android/——写成
//    app/release-demo.jks 会找 android/app/app/…（实测翻车点）

// ③ android/app/build.gradle.kts：有 key.properties 就签 release，没有回落 debug
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// android { signingConfigs { create("release") { keyAlias=…; storeFile=file(…) … } }
//          buildTypes { release { signingConfig = if (keystorePropertiesFile.exists())
//              signingConfigs.getByName("release") else signingConfigs.getByName("debug") } } }
```

示例工程 `android/app/build.gradle.kts` 的完整实现（第 10-61 行）与上面骨架一一对应：`keystorePropertiesFile.exists()` 判存 → `signingConfigs.create("release")` 读四个字段 → `buildTypes.release.signingConfig` 三元选择。这是官方文档（docs.flutter.dev/deployment/android）的推荐结构，好处是**没有 key.properties 的机器也能构建**（回落 debug 签名），CI 与本地共用一份脚本。

铁律三条：**keystore 与 key.properties 都不进仓库**（本仓库 .gitignore 已拦 `**/android/key.properties`、`**/*.jks`）；**debug 与 release 签名是两把钥匙**（模板默认 release 借 debug 签名，仅为本机 `flutter run --release` 能跑）；**keystore 丢了 = 应用终身残废**，备份进密码管理器/保险库。

### 28.4.1 Play App Signing：Google 的"双钥匙"制度

Google Play 自 2017 年起强制 **Play App Signing**：你手里的叫 **upload key**（上传钥匙），只用于向 Play 验证"这个 AAB 是你传的"；Google 用另一把 **app signing key**（应用签名钥匙）重新签名后分发给用户。含义：

- **upload key 丢了可以重置**（Play Console 里申请）——不像自分发渠道，丢了就死。
- **app signing key 由 Google 保管**，你接触不到；开启后不可关闭。
- 国内商店（华为/小米/应用宝……）不走这套：你手里的就是最终签名钥匙，**丢了就是终身残废**——别因为"Play 能重置"就放松对 keystore 的保管。

### 28.4.2 改完 gradle 要 clean

Kotlin DSL 的构建脚本有缓存：改完 `build.gradle.kts` 直接构建可能拿到旧的签名配置。官方文档明确建议：**修改 gradle 文件后跑 `flutter clean`** 再构建——签名问题排查的第一步永远是 clean。

## 28.5 构建产物

```bash
flutter build apk --release        # 单一胖 APK（全 ABI），直接 adb install / 发给同事
flutter build apk --split-per-abi   # 按 CPU 拆包：体积最小，商店上传用
flutter build appbundle             # AAB：Google Play 的唯一格式
```

- 产物：`build/app/outputs/flutter-apk/app-release.apk`（示例实测 42.9MB，V2 签名）。
- `--release` 是 AOT 编译（与 18 章 debug/release 行为差异同理：断言消失、性能真实）。
- 签名核对：`apksigner verify --print-certs app-release.apk` 能看到你的证书指纹。
- Windows 上验证安装：USB 连 Android 设备开调试 → `flutter install` 或 `adb install -r app-release.apk`（本机 `G:\android\platform-tools` 有 adb）。

### 28.5.1 ABI 拆分的 versionCode 陷阱

`--split-per-abi` 会为每个架构自动改写 versionCode：`versionCode = 基础值 + 1000 × ABI 序号`（armeabi-v7a→+1000、arm64-v8a→+2000、x86_64→+4000，看 `output-metadata.json` 可验证）。后果：

- 同一次构建的三个 APK **versionCode 各不相同**——商店按设备 ABI 推对应包，升级判断各自独立，没问题。
- 但**别混用渠道**：胖 APK（versionCode=7）与 split 包（versionCode=1007/2007/4007）交错上架，商店会按"最高 versionCode"判断，老设备可能永远收不到更新。一个应用选定一种拆包策略就别来回换。
- 只想要单一架构（如只支持 arm64）：`flutter build apk --target-platform android-arm64` 比 split 更省——不生成多余产物，构建时间也短。

## 28.6 代码混淆与符号

书 15.1.3 的混淆在 Flutter 3 时代是两条参数的事（当年还要配 `--no-shrink` 说明 shrink 行为）：

```bash
# ═══ 28.6 混淆构建：Dart AOT 产物去符号名 ═══
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols     # 符号表输出目录（不随包发布）
```

- **`--obfuscate`**：Dart 类名/函数名变成 `aBc` 之类短名，逆向成本陡增（不是加密，配合足够大的 release 产物依然是可分析的字节码）。
- **`--split-debug-info`**：混淆的代价是崩溃栈也成了天书——符号表单独落在这，**自己收好**。线上崩溃拿到的栈用 `flutter symbolize -d build/symbols/app.android-arm64.symbols < stack.txt` 还原成可读帧。
- **符号表跟版本走**：每次发版的 symbols 归档（与 keystore 同级的重要资产），丢了的版本崩溃栈永久天书。
- Android 侧的 R8 收缩由构建**默认接管**（release 构建自动启用，模板无需再配 `minifyEnabled`；`--no-shrink` 在新版本已无效果）。Dart 侧才是这两条参数管的地盘。
- 崩溃监控接入（Firebase Crashlytics / Sentry 等）时，把 symbols 目录上传对应平台——Android 走 CLI（`firebase crashlytics:symbols:upload`），iOS 的 dSYM 新版插件可自动上传。

## 28.7 商店与 iOS 流程

- **国内 Android 商店**（应用宝/华为/小米……）：各开开发者后台，上传 APK + 截图 + 软著等材料，各家审核节奏不同——一次签名多处上架。
- **Google Play**：只收 AAB；首版审核最严。
- **iOS**（书 19.4，流程至今没变，这里按 docs.flutter.dev/deployment/ios 校订）：苹果开发者账号（年费）→ App Store Connect 注册 Bundle ID（Explicit App ID）→ 建 App（名称/语言/SKU，绑定 Bundle ID）→ Xcode 打开 `ios/Runner.xcworkspace` 设 Team 与 Bundle Identifier（`Automatically manage signing` 默认开）→ `Product → Archive` 上传 → Connect 里提交审核。命令行等价路径：`flutter build ipa --obfuscate --split-debug-info=...` 产出 `.ipa`，用 Transporter app 或 `xcrun altool` 上传。**TestFlight 内测**在上架前必走一轮——审核拒绝的坑在测试阶段就暴露。**全程需要 Mac + Xcode**——Windows 主机上做到"知道每一步在干嘛"即可。

## 28.8 发版 Checklist（示例页同款）

示例 `lib/main.dart` 的 `checklist` 常量（第 25-31 行）就是浓缩版流水线，展开成可执行清单：

1. **身份**：`android:label` / `applicationId` / `version: x.y.z+N` 三处各就各位；N 比上一版大。
2. **脸面**：`dart run flutter_launcher_icons` 重新生成（源图变了就要重跑）；闪屏同步。
3. **签名**：`key.properties` 在（且不在 git 里）；`flutter clean` 后再构建。
4. **构建**：`flutter build appbundle`（Play）或 `flutter build apk --split-per-abi`（国内/直发）；混淆与 symbols 归档。
5. **上架**：商店后台材料齐全；上传后 `apksigner verify --print-certs` 核对指纹是 release 证书。

## 坑位清单

- **release 借 debug 签名就上架**：商店拒绝；同事装了 debug 签名的包，后续真签名包覆盖安装失败（签名不同 = 不同应用）。
- **keystore/密码进仓库**：泄漏=别人能给你发"官方更新"——gitignore 拦住，密钥进保险库。
- **忘加 versionCode**：商店报"已存在更高版本"——发版 checklist 第一条。
- **manifest 还在改 package 属性**：现代模板没有这一项——身份归 `namespace`/`applicationId` 管。
- **改图标/闪屏没重新构建**：生成物在原生目录，热重载不覆盖——完整重跑。
- **AAB 当 APK 到处分发**：AAB 只有商店能装——直发用户用 APK。
- **改完 gradle 直接构建拿到旧签名**：Kotlin DSL 缓存——`flutter clean` 是签名排查第一步。
- **split 包与胖包混着上架**：versionCode 体系互相打架，部分设备收不到更新——一个应用一种拆包策略。
- **混淆后没归档 symbols**：线上崩溃栈全是 `aBc.xY`——symbols 与 keystore 同级保管。
- **iOS 图标带透明通道**：App Store 拒绝——`remove_alpha_ios: true` 让生成器兜底。

---

上一章：[27 · 平台通道：MethodChannel 直通原生](27-platform-channel.md) ｜ 下一章：[29 · 滚动进阶与页面事件](29-scroll-events.md) ｜ 返回：[README](../README.md)
