# 11 · KVC、KVO 与 Cocoa Bindings

> 示例：`examples/11_kvo_bindings/main.swift`
> 实测输出见 `build/11_kvo_bindings/stdout.clt.txt`

这三者是 AppKit 的「胶水层」，也是 macOS 与 iOS 分野最明显的地方：
**iOS 几乎没有 Cocoa Bindings，macOS 有完整一套**。
你会在 XIB 的 Bindings 检查器里看到它，在 `NSArrayController` 里看到它。

## 1) KVC：按字符串访问属性

```swift
person.setValue("小明", forKey: "name")
let name = person.value(forKey: "name") as? String
person.setValue(30, forKey: "age")                    // 自动包成 NSNumber
person.value(forKeyPath: "address.city")              // 可以穿层
```

实测：

```
== KVC ==
  ok   setValue(_:forKey:) 写入字符串
  ok   写入数字时会自动做 NSNumber 转换
  ok   value(forKey:) 读回来
  ok   数字也是 NSNumber 桥接回来的
  ok   keyPath 可以穿层读取
  ok   keyPath 也能穿层写入
```

### key 不存在时默认是抛异常

`NSUndefinedKeyException`。想让它安静地失败，重写两个方法：

```swift
final class Lenient: NSObject {
    var store: [String: Any] = [:]
    override func value(forUndefinedKey key: String) -> Any? { store[key] }
    override func setValue(_ value: Any?, forUndefinedKey key: String) { store[key] = value }
}
```

实测：

```
  ok   重写 UndefinedKey 就不会崩
```

> **坑**：KVC 的 key 是**字符串**，拼错了编译器不报错，运行时才炸
> （或者静默失败）。Swift 5.9+ 有 `#keyPath` 和 Swift keypath 可以缓解，
> 但 OC 风格的 API 里仍然全是裸字符串。

### 集合运算符

```swift
(books as NSArray).value(forKeyPath: "@count")            // 2
(books as NSArray).value(forKeyPath: "@sum.pageCount")    // 400
(books as NSArray).value(forKeyPath: "@avg.pageCount")    // 200
```

```
  @count=2 @sum=400 @avg=200.0
```

还有 `@min` `@max` `@distinctUnionOfObjects` 等。

## 2) KVO：观察属性变化

### Swift 属性默认不发通知

```swift
final class Thermostat: NSObject {
    @objc dynamic var temperature: Double = 20.0   // ✅ 会发通知
    @objc var label: String = "室温"                // ❌ 不会
}
```

**必须同时有 `@objc` 和 `dynamic`**：
- `@objc` 让它走 ObjC 的消息派发
- `dynamic` 禁用 Swift 的直接派发优化（否则 setter 被内联，KVO 的 swizzle 就没机会插进去）

### 反面：少了 dynamic 会怎样

示例用**旧式 KVO**（`addObserver:forKeyPath:`）来演示，因为
Swift 的闭包版 `observe(\.label)` 碰到非 dynamic 属性会**直接运行时崩**
（`Could not extract a String from KeyPath`），根本跑不到断言。

```swift
thermostat.addObserver(recorder, forKeyPath: "label", options: [.new], context: nil)
thermostat.addObserver(recorder, forKeyPath: "temperature", options: [.new], context: nil)
thermostat.label = "书房"
thermostat.temperature = 21.0
print(recorder.hits)     // ["temperature"]  ← 只有 dynamic 的那个
```

实测：

```
  收到的通知 = ["temperature"]
  ok   只有 dynamic 的属性发了通知
  ok   但 label 的值确实改了
```

### 手工发通知

批量改一堆相关属性时，手动包一层能少发很多次通知：

```swift
override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
    key == "value" ? false : super.automaticallyNotifiesObservers(forKey: key)
}
func bumpSilently() {
    willChangeValue(forKey: "value")
    value += 1
    didChangeValue(forKey: "value")
}
```

实测：

```
  ok   手动 will/didChange 也能触发通知
  ok   关掉自动通知后直接赋值不再通知
  ok   但值还是改了
```

### 观察者必须移除

旧式 KVO（iOS 9 / macOS 10.11 之后）**不再**强制在 deinit 里移除
**基于 selector/context 的**观察者；但**基于闭包的**
`observe(_:options:changeHandler:)` 返回的 token **必须自己持有并在合适时机释放**。

## 3) Cocoa Bindings：macOS 独有

一句话：把控件的某个属性**绑**到 model 的某个 keyPath 上，双向自动同步。

```swift
nameField.bind(.value, to: model, withKeyPath: "userName", options: nil)
```

实测：

```
== Cocoa Bindings ==
  绑定后 textField = 匿名
  ok   绑定后控件立刻显示 model 的值
  model 改成 Ada 之后 = Ada
  ok   改 model 会同步到控件
```

**绑定是立刻生效的**：绑上的那一刻控件就取到了 model 的值。

### 反向（view → model）不会在程序赋值时发生

```swift
nameField.stringValue = "Grace"
// model.userName 仍然是 "Ada"
```

实测：

```
  程序改控件之后 model = Ada
  ok   程序改 stringValue 不会回写 model
  ok   控件自己的值已经改了
  ok   开了 continuouslyUpdatesValue 也不回写
```

> **坑**：那条路径走的是 **field editor**
> （用户敲键盘时 AppKit 临时插进来的编辑视图）。程序赋值根本不经过它，
> 所以**连 `continuouslyUpdatesValue` 也救不了**。
> 用户在界面上编辑时会同步，程序里改 `stringValue` 不会。

### 调试「为什么没同步」

```swift
let info = nameField.infoForBinding(.value)    // 还绑着 → 有值；unbind 之后 → nil
```

实测：

```
  ok   unbind 之后查不到绑定信息
  ok   还绑着的能查到信息
  ok   infoForBinding 能读出被观察的 key path（实际 subscribed）
```

### 常用 options

| option | 作用 |
| --- | --- |
| `.continuouslyUpdatesValue` | 每次击键都同步（默认要等 endEditing） |
| `.valueTransformerName` | 中间转换（比如 Bool → 「是/否」） |
| `.nullPlaceholder` | 值为 nil 时显示什么 |
| `.noSelectionPlaceholder` | 没选中时显示什么 |
| `.validatesImmediately` | 立刻做 KVC 校验 |

## 4) 控制器对象

`NSObjectController` / `NSArrayController` / `NSTreeController`
是 Bindings 的常用中介，它们本身也是「可被绑定」的对象。

```swift
let objectController = NSObjectController(content: model)
let arrayController  = NSArrayController(content: books)
arrayController.setSelectionIndex(0)
arrayController.canSelectNext        // true
```

实测：

```
== 控制器对象 ==
  ok   NSObjectController 装着 model
  ok   默认选中唯一那个对象
  ok   NSArrayController 装着数组
  ok   可以设选中下标
  ok   选中的不是最后一个，还能往后选
  ok   选到最后一个之后 canSelectNext 变 false
  ok   但可以往前选
```

> **坑**：不要把控制器再 `bind` 回同一个对象
> （`bind(.contentObject, to: model, withKeyPath: "self")`）。
> 控制器自己就会观察 content，重复绑定只会让 AppKit 去对一个
> Swift 数组发 `addObserver:forKeyPath:`，**直接抛 `NSInvalidArgumentException`**。
> content 用初始化器给就够了；要 `bind` 的是**别人**（比如 File's Owner 上的属性）。

## 5) 该不该用 Bindings？

**用**：简单的表单、主从界面（master-detail）、偏好设置面板。
一个 `NSArrayController` + 表格列绑定就能做出「列表 + 详情」，代码量极少。

**不用**：复杂的状态机、需要精细控制时序、要写单元测试的逻辑。
Bindings 的错误**静默且难查**（没有编译期检查，跑起来只是一直不同步）。

现在的共识是：**小项目/表单用 Bindings，大项目用手动绑定 + 响应式框架**。

## 6) 坑清单

| 现象 | 原因 |
| --- | --- |
| KVO 回调不来 | 属性没有 `@objc dynamic` |
| `observe(\.x)` 运行时崩 | keypath 的属性不是 dynamic |
| 改了值但界面不变 | 没走 KVO（没 dynamic）或绑定没建立 |
| 程序改控件值 model 不更新 | 走 field editor 的才算用户输入 |
| 把控制器 bind 回 model 直接崩 | AppKit 去对 Swift 数组发 KVO |
| `infoForBinding` 返回 nil | 绑定名写错了（`.value` vs `.content`） |
| 对象不释放 | 闭包版 KVO 的 token 没释放 |

## 小结

- KVC 按字符串访问，key 错了运行时才炸；可重写 `UndefinedKey` 兜底。
- KVO 要求 `@objc dynamic`；少了 `dynamic` 静默失效。
- Cocoa Bindings 是 macOS 独有的双向同步层，绑定立刻生效。
- 「程序改 stringValue」不回写 model —— 那条路径走 field editor。
- `NSArrayController` 的 content 用初始化器给，别 bind 回自己。
