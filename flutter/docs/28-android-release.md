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
- `1.2.0+7`：加号前是 `versionName`（用户可见），加号后是 `versionCode`（整数，商店判断升级）。**每次发版必须递增 versionCode**，versionName 随意。
- iOS 侧对应：Xcode 里 `Display Name` 与 `Bundle Identifier`（书 19.4 的 General 页就是它）。

## 28.3 脸面：图标与闪屏

- **图标**：生态包 `flutter_launcher_icons`（dev_dependencies）+ 一张 1024×1024 源图，一键生成 Android 全密度 `mipmap-*` 与 iOS `Assets.xcassets`（书 19.1 的流程原样有效，包已迭代多年）。Android 13+ 另有自适应图标（前景/背景两层）。
- **闪屏**：Android 的 `res/drawable/launch_background.xml`（layer-list：底色 + 居中位图，书 19.2）；生态包 `flutter_native_splash` 把这套模板化。iOS 是 `LaunchImage.imageset`。
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

铁律三条：**keystore 与 key.properties 都不进仓库**（本仓库 .gitignore 已拦 `**/android/key.properties`、`**/*.jks`）；**debug 与 release 签名是两把钥匙**（模板默认 release 借 debug 签名，仅为本机 `flutter run --release` 能跑）；**keystore 丢了 = 应用终身残废**，备份进密码管理器/保险库。

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

## 28.6 商店与 iOS 流程

- **国内 Android 商店**（应用宝/华为/小米……）：各开开发者后台，上传 APK + 截图 + 软著等材料，各家审核节奏不同——一次签名多处上架。
- **Google Play**：只收 AAB；首版审核最严。
- **iOS**（书 19.4，流程至今没变）：苹果开发者账号（年费）→ 注册 App ID / Bundle Identifier → App Store Connect 建 App（名称/语言/SKU）→ Xcode 打开 `ios/Runner.xcworkspace` 设 Team 与 Bundle Identifier → `Product → Archive` 上传 → Connect 里提交审核。**全程需要 Mac + Xcode**——Windows 主机上做到"知道每一步在干嘛"即可。

## 坑位清单

- **release 借 debug 签名就上架**：商店拒绝；同事装了 debug 签名的包，后续真签名包覆盖安装失败（签名不同 = 不同应用）。
- **keystore/密码进仓库**：泄漏=别人能给你发"官方更新"——gitignore 拦住，密钥进保险库。
- **忘加 versionCode**：商店报"已存在更高版本"——发版 checklist 第一条。
- **manifest 还在改 package 属性**：现代模板没有这一项——身份归 `namespace`/`applicationId` 管。
- **改图标/闪屏没重新构建**：生成物在原生目录，热重载不覆盖——完整重跑。
- **AAB 当 APK 到处分发**：AAB 只有商店能装——直发用户用 APK。
