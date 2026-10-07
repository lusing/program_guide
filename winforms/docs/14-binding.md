# 14 · 数据绑定：DataBindings、INotifyPropertyChanged、BindingSource

> 对应示例：`examples/14_binding`（Person 三字段双向绑定 + BindingList + 白送的导航条 + Format 加工）

> **本章你将学会**：控件属性 ← 对象属性的绑定三要素、INPC 双向刷新、BindingSource/BindingList、BindingNavigator、Format/Parse。
> **前置章节**：[05](05-controls-text.md)、[07](07-controls-lists.md)、[11 事件](11-events.md)。

## 1. 绑定三要素

```csharp
_name.DataBindings.Add("Text", _source, "Name");
//                  ①        ②       ③
//  ① 控件属性（"Text"）
//  ② 数据源（对象/BindingSource/DataTable…）
//  ③ 属性路径（字符串反射，拼错运行时才炸）
```

一行代码把控件属性和对象属性焊在一起。**默认双向**：改控件写回对象，改对象刷新控件（后者需要 INPC，见下）。

## 2. INPC：对象主动广播

```csharp
public class Person : INotifyPropertyChanged
{
    private string _name = "";
    public string Name
    {
        get => _name;
        set { if (_name != value) { _name = value; OnPropertyChanged(nameof(Name)); } }
    }
    …
    public event PropertyChangedEventHandler PropertyChanged;
    private void OnPropertyChanged(string name) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
```

**没有 INPC，改对象属性控件不知道**（绑定引擎收不到通知）；控件 → 对象方向倒是照常。14 示例实测：编辑表格里的姓名，上方表单的文本框**同一瞬间**跟着变——那就是 INPC 在广播。

## 3. BindingList + BindingSource：列表的中枢

```csharp
var people = new BindingList<Person> { new() { … }, … };   // 可通知的列表（增删行自动刷 UI）
_source.DataSource = people;                               // BindingSource 包一层
…
_grid.DataSource = _source;                                 // 表格与表单共用同一个源
```

`BindingSource` 是绑定架构的**中枢**：表单、表格都看它；它记着"当前是第几条"（`Position`）、支持增删（`Add/RemoveCurrent/MoveNext…`）。**BindingList 在 `System.ComponentModel`**（不是 Collections.ObjectModel 的 ObservableCollection——那个不是绑定列表）。

### 白送的导航条

```csharp
var nav = new BindingNavigator(_source) { Dock = DockStyle.Top };
```

首/前/后/末四个按钮 + 计数 + 增删——一行代码。它操作的就是 `BindingSource.Position`。

### 新增并跳转

```csharp
_source.Add(new Person { Name = "新人员", Age = 20, Email = "" });
_source.Position = _source.Count - 1;          // 跳到刚加的
```

## 4. Format/Parse：展示层的翻译官

绑定的两个数据流动方向各有一个翻译事件：

```csharp
var echoBinding = new Binding("Text", _source, "Age");
echoBinding.Format += (s, e) => e.Value = $"{e.Value} 岁（Format 事件加工）";   // 对象 → 控件
echoBinding.Parse += (s, e) => { };                                            // 控件 → 对象（只读回显留空）
_ageEcho.DataBindings.Add(echoBinding);
```

类型换算也在这做（14 的 F# 版用它换算 `int ↔ decimal`）：

```fsharp
ageBind.Format.Add(fun e -> e.Value <- Convert.ToDecimal e.Value)   // int → decimal
ageBind.Parse.Add(fun e -> e.Value <- Convert.ToInt32 e.Value)      // decimal → int
```

## 5. 三语言差异

**F#**——INPC 的惯用形（属性 get/set + Event）：

```fsharp
type Person() as this =
    let propertyChanged = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let mutable name = ""
    interface INotifyPropertyChanged with
        [<CLIEvent>]                                   // ★ 不加则 FS0859：接口不认这个实现
        member _.PropertyChanged = propertyChanged.Publish
    member _.Name
        with get() = name
        and set v = if name <> v then name <- v; this.Notify "Name"
    member private _.Notify propName =
        propertyChanged.Trigger(this, PropertyChangedEventArgs propName)
```

要点：绑定引擎要的是**可写属性**——F# 记录（record）不可变、`member val` 也不会通知，所以 INPC 模型用类 + `with get/and set`。

**C++/CLI**——实现接口的事件要 `virtual event`：

```cpp
public ref class Person : public INotifyPropertyChanged
{
public:
    virtual event PropertyChangedEventHandler^ PropertyChanged;    // virtual 才满足接口
    property String^ Name
    {
        String^ get() { return _name; }
        void set(String^ value) { if (_name != value) { _name = value; Notify(L"Name"); } }
    }
};
```

## 坑位清单

1. 属性路径 `"Name"` 拼错 → 运行时才炸（反射字符串无编译期检查）。
2. 模型没实现 INPC → 对象变了控件不动（单向残废）。
3. `ObservableCollection` 当绑定列表用 → 它不通知；要 `BindingList<T>`（System.ComponentModel）。
4. F# 接口事件缺 `[<CLIEvent>]` → FS0859；C++/CLI 缺 `virtual` → 接口不认。
5. NumericUpDown.Value 是 decimal、模型是 int——不换算绑不上（Format/Parse 各写一行）。

## 自测

1. 绑定三要素各是什么？"属性路径"的错误什么时候暴露？
2. 没实现 INPC 时，双向绑定的哪个方向仍正常？
3. `BindingSource` 在绑定架构里扮演什么角色？`Position` 是什么？
4. BindingNavigator 一行代码给了你哪些功能？
5. Format 与 Parse 各自处理哪个方向的数据流？

---

上一章：[13 GDI+ 应用](13-gdi-apps.md) · 下一章：[15 DataGridView](15-datagridview.md)
