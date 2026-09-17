# 14 · XIB 与 nib：Interface Builder 到底产出了什么

> 示例：`examples/14_xib_and_nib/`（`MainView.xib` + `main.swift`）
> 实测输出见 `build/14_xib_and_nib/stdout.clt.txt`

XIB 是 macOS 开发绕不开的一环（Xcode 的模板默认就给一个 `MainMenu.xib`）。
但很多人用了几年也不知道它到底是什么。本章把它拆开。

## 1) XIB 是 XML，nib 才是运行时能读的

```
MainView.xib  （XML 文本，人类可读，可以 diff）
   │
   │  ibtool --compile
   ↓
MainView.nib  （二进制归档，运行时加载）
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ibtool --errors --warnings --notices --compile MainView.nib MainView.xib
```

**nib 的本质是「一组被归档（NSCoding）的对象图」**。
加载它 = 解归档 = 把对象重建出来，然后把连线（outlet/action）接上。

> **坑**：`ibtool` 在本机上很慢（30 秒 ~ 3 分钟），因为它要加载
> Interface Builder 的 Cocoa 插件。别以为它卡死了。
>
> **坑**：`ibtool` 只在有问题时才输出内容。**日志非空 = 有告警**。

## 2) XIB 的结构

一个最小的 Cocoa XIB（示例里的，去掉了无关属性）：

```xml
<document type="com.apple.InterfaceBuilder3.Cocoa.XIB" version="3.0"
          toolsVersion="21507" targetRuntime="MacOSX.Cocoa" useAutolayout="YES">
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.CocoaPlugin" version="21507"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <objects>
        <customObject id="-2" userLabel="File's Owner"
                      customClass="DemoOwner" customModule="xib_and_nib"
                      customModuleProvider="target">
            <connections>
                <outlet property="titleLabel" destination="lbl-0a-001" id="out-0a-001"/>
            </connections>
        </customObject>
        <customObject id="-1" userLabel="First Responder" customClass="FirstResponder"/>
        <customObject id="-3" userLabel="Application" customClass="NSObject"/>
        <view id="vw-0a-001" userLabel="RootView">
            <rect key="frame" x="0.0" y="0.0" width="280" height="90"/>
            <subviews>
                <textField id="lbl-0a-001"> ... </textField>
                <button id="btn-0a-001">
                    <connections>
                        <action selector="tapMe:" target="-2" id="act-0a-001"/>
                    </connections>
                </button>
            </subviews>
        </view>
    </objects>
</document>
```

三个**必须存在**的占位对象（id 是固定的负数）：

| id | userLabel | 作用 |
| --- | --- | --- |
| `-2` | File's Owner | 加载时由你传进去的对象顶上 |
| `-1` | First Responder | 响应链的占位（连线到这里 = target 为 nil，走响应链） |
| `-3` | Application | `NSApplication` 的占位 |

### 关键：customModule 必须等于 -module-name

```xml
customClass="DemoOwner" customModule="xib_and_nib"
```

Xcode 里这一项默认填的是 **target 名**。命令行下没有 target，
必须**手工填成 swiftc 的 `-module-name`**，否则运行时找不到 Swift 类
（Swift 类名在运行时是带模块前缀的 `xib_and_nib.DemoOwner`）。

> **坑**：这个错误**不报错**，只是 outlet 全是 nil、action 不生效。
> 症状是「界面出来了但点什么都没反应」—— 极难查。
> 本仓库为此写了 `tools/check_xib.py`，在编译前静态核对
> XIB 里的类名/模块名/连线与源码是否一致。

## 3) File's Owner

**File's Owner 不在 nib 里被创建**。它是个占位符，加载时由你传的对象顶上：

```swift
let owner = DemoOwner()
var topLevel: NSArray? = nil
let loaded = Bundle.main.loadNibNamed("MainView", owner: owner, topLevelObjects: &topLevel)
```

连到 File's Owner 上的 outlet 会**写进你给的这个对象**。

## 4) outlet 与 action

```swift
final class DemoOwner: NSObject {
    @IBOutlet var titleLabel: NSTextField?
    var tapCount = 0

    @IBAction func tapMe(_ sender: Any?) {
        tapCount += 1
    }
}
```

- `@IBOutlet` 在 Swift 里其实只是个标记（编译期无作用），
  但 **Interface Builder 靠它识别**哪些属性可以连线。
- `@IBAction` 同理，且它隐含 `@objc`。
- **outlet 属性必须是 `var`**（nib 加载时要写它）。

实测：

```
== outlet ==
  titleLabel = 来自 XIB 的标签
  ok   outlet 被填上了（File's Owner 的连线生效）
  ok   标签文字来自 XIB
  ok   XIB 里就是 label，不可编辑
  ok   outlet 指向的对象确实是根视图的子视图

== action ==
  按钮标题 = 点一下
  ok   按钮文字来自 XIB
  ok   按钮的 target 就是 File's Owner
  ok   action 指向 tapMe:
  ok   点一次计数加一（实际 1）
  ok   再点一次变 2（实际 2）
```

> **坑**：`outlet` 挂错宿主是常见错误 —— 把 outlet 连到 root view 上，
> 而不是 File's Owner。Interface Builder 里根本不允许这么连，
> 但手写 XIB 时会写错。`check_xib.py` 会检查这一类问题。

## 5) 顶层对象不会被自动持有

```swift
var topLevel: NSArray? = nil
bundle.loadNibNamed("MainView", owner: owner, topLevelObjects: &topLevel)
```

> **坑**：`topLevelObjects` 里的对象**不会**被自动保留。
> nib 只保证「加载那一刻活着」。你不用变量接住，出了这一行就可能被释放
> （macOS 10.8 之前 nib 用的是「谁 retain 谁负责」的老规则，
> 现在虽然 ARC 化了，但顶层对象仍然只有你手上这个数组的引用）。

实测：

```
  loaded = true, 顶层对象数 = 2
  ok   loadNibNamed 返回 true
  ok   顶层对象数组非空
  ok   顶层对象里有一个 NSView（实际 1）
```

## 6) nib 是模板，不是单例

加载两次得到两份独立的对象：

```
== 重复加载 ==
  ok   第二次加载得到的是新的视图实例
  ok   第二个 owner 有自己的 outlet 对象
  ok   但文字内容一样
  ok   新 owner 的计数从 0 开始
```

所以**表格的每一行可以复用同一个 nib**（配 `NSNib`）。

## 7) NSNib：把 nib 当对象用

```swift
let nib = NSNib(nibNamed: "MainView", bundle: Bundle.main)
var objects: NSArray? = nil
nib?.instantiate(withOwner: owner3, topLevelObjects: &objects)
```

`NSNib` 会**缓存已解析的 nib**，同一个 nib 要实例化很多次时用它更快
（比如表格每一行、每个 collection item）。

```
== NSNib ==
  ok   能造出 NSNib 对象
  ok   instantiate 成功
  ok   第三个 owner 的 outlet 也连上了
  ok   加载不存在的 nib 返回 false（不是崩溃）
```

## 8) XIB vs 纯代码 vs Storyboard

| | XIB | 纯代码 | Storyboard |
| --- | --- | --- | --- |
| 一个文件 | 一个视图/窗口 | — | 多个场景 + segue |
| macOS 上成熟度 | 最成熟 | 最可控 | macOS 10.10+ 才有，用得少 |
| 改布局要重编译 | 不用 | 要 | 不用 |
| 类名/连线错了 | 运行时才炸 | 编译期就炸 | 运行时才炸 |
| 适合 | 静态布局、主菜单、单元格 | 动态布局、可复用组件 | 流程固定的多窗口应用 |

**macOS 上的共识**：主菜单 + 窗口用 XIB，动态内容用代码，
Storyboard 只在窗口流程固定的小应用里用。

## 9) 静态检查：check_xib.py

手写/编辑 XIB 时最容易出的三类错：

1. `customClass` 指向一个不存在的类
2. `customModule` 与 `-module-name` 不一致
3. outlet 挂在了非 File's Owner 的对象上；action 的 selector 在源码里找不到

本仓库的 `tools/check_xib.py` 在编译**之前**把这些全查一遍：

```bash
python3 tools/check_xib.py examples
# XIB 一致性检查通过：2 个 xib，类/模块名/连线全部对得上源码
```

## 10) 坑清单

| 现象 | 原因 |
| --- | --- |
| outlet 全是 nil | `customModule` 与 `-module-name` 不一致 |
| 界面出来了但点了没反应 | action 的 selector 拼错，或 target 没连到 File's Owner |
| `loadNibNamed` 返回 false | nib 不在资源目录里，或名字写错 |
| 加载后对象立刻消失 | 顶层对象没被变量持有 |
| `ibtool` 看起来卡住 | 它本来就慢（要加载 Cocoa 插件），给足超时 |
| XIB 改了但运行没变 | 没重新 `ibtool --compile`（XIB 不是运行时直接读的） |

## 小结

- XIB 是 XML，`ibtool --compile` 出来的 nib 才是运行时读的（本质是归档的对象图）。
- File's Owner（id=-2）是占位符，由加载时传入的对象顶上。
- `customModule` 必须等于 swiftc 的 `-module-name`，否则 outlet 静默为 nil。
- 顶层对象不会被自动持有；nib 是模板，可以加载多次。
- 用 `tools/check_xib.py` 在编译前把类名/模块名/连线核对一遍。
