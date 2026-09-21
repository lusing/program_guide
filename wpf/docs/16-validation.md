# 16 · 数据验证

> 对应示例：`examples/16_validation`（INotifyDataErrorInfo 表单：逐字验证 + 自定义错误模板）

> **本章你将学会**：三种验证方案与选型、INotifyDataErrorInfo 的完整实现、自定义 ErrorTemplate、验证时机控制。
> **前置章节**：[10 绑定进阶](10-binding-advanced.md)、[14 触发器](14-triggers.md)。

## 1. 三种验证方案

TwoWay 绑定把用户输入回写数据——但"年龄必须是 18-60 的整数"这类规则谁来把守？WPF 有三条路：

| 方案 | 机制 | 特点 |
|---|---|---|
| 异常验证 | setter 抛异常 + `ValidatesOnExceptions=True` | 最简单；一个属性只能报一个错；靠异常传状态略脏 |
| DataAnnotation | 属性挂 `[Required]` 等特性 + `ValidatesOnDataAnnotations=True` | 规则声明式；适合 Model 直接复用 EF 校验 |
| **INotifyDataErrorInfo** | VM 自己维护错误集合 | **最灵活**：一属性多错误、异步验证、跨字段联动；推荐默认 |

本教程主讲 INotifyDataErrorInfo（下称 INDE）——它也是 WinUI/MAUI 时代的标准方案。接口只有三个成员：

```csharp
public interface INotifyDataErrorInfo
{
    bool HasErrors { get; }                                  // 有没有错（提交按钮常用）
    IEnumerable GetErrors(string? propertyName);            // 某属性的错误列表
    event EventHandler<DataErrorsChangedEventArgs>? ErrorsChanged;  // 错误变了通知界面
}
```

## 2. 完整实现：FormViewModel

`16_validation` 的 VM 实现了三条规则（用户名必填 ≥2 字、年龄 18-60 整数、邮箱可空但须含 @）。核心是**每属性一个验证方法 + 统一的错误集合维护**：

```csharp
public sealed class FormViewModel : INotifyPropertyChanged, INotifyDataErrorInfo
{
    private readonly Dictionary<string, List<string>> _errors = new();

    public string UserName
    {
        get => _userName;
        set { _userName = value; OnPropertyChanged(); ValidateUserName(); }   // 赋值即验证
    }

    public bool HasErrors => _errors.Values.Any(list => list.Count > 0);

    public IEnumerable GetErrors(string? propertyName)
        => propertyName is not null && _errors.TryGetValue(propertyName, out var list)
            ? list
            : Array.Empty<string>();

    public event EventHandler<DataErrorsChangedEventArgs>? ErrorsChanged;

    private void ValidateUserName()
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(UserName))
            errors.Add("用户名不能为空");
        else if (UserName.Length < 2)
            errors.Add("用户名至少 2 个字符");
        SetErrors(nameof(UserName), errors);      // 统一入口，见下
    }

    // 错误集合的维护：变了才通知，否则界面白刷
    private void SetErrors(string propertyName, List<string> errors)
    {
        var changed = !_errors.TryGetValue(propertyName, out var old)
                      || !old.SequenceEqual(errors);
        if (!changed) return;

        if (errors.Count == 0) _errors.Remove(propertyName);
        else _errors[propertyName] = errors;

        ErrorsChanged?.Invoke(this, new DataErrorsChangedEventArgs(propertyName));
        OnPropertyChanged(nameof(HasErrors));     // HasErrors 是派生属性，联动通知
    }
}
```

四个细节：

1. **验证时机 = setter**：配合 XAML 的 `UpdateSourceTrigger=PropertyChanged`，用户**每敲一个字**就重新验证——"边打字边报错"还是"失焦才报错"由此控制
2. **HasErrors 联动**：它是派生属性（由 `_errors` 算出），任何 SetErrors 后都要 `OnPropertyChanged(nameof(HasErrors))`——提交按钮的可用性绑它
3. **判等再通知**：错误没变化就不触发 ErrorsChanged，避免界面无效刷新
4. **跨字段验证**：在 A 的验证方法里同时校验 B（如"确认密码"），需要时对两个属性都调 SetErrors

## 3. XAML 侧：绑定 + 错误显示

绑定时显式打开验证（INDE 源会自动生效，写出来更醒目）：

```xml
<TextBox Text="{Binding UserName, UpdateSourceTrigger=PropertyChanged,
                        ValidatesOnNotifyDataErrors=True}"/>
```

错误出现时，绑定引擎做三件事：把控件套上**默认错误模板**（红框）、把控件标记 `Validation.HasError=True`、把错误装进附加属性 `Validation.Errors` 集合。显示错误文本用普通绑定取这个集合：

```xml
<TextBlock Foreground="#EF4444" FontSize="11"
           Text="{Binding (Validation.Errors)[0].ErrorContent,
                  ElementName=UserNameBox, FallbackValue=''}"/>
```

`(Validation.Errors)[0]` 是**附加属性的索引路径**（第 04 章的附加属性 + 集合索引合用）；`FallbackValue=''` 保证无错误时文本为空（索引失败静默）。

## 4. 自定义 ErrorTemplate

默认只有个红框，看不出错在哪。自定义错误模板（Validation.ErrorTemplate）加个叹号、悬停看全文：

```xml
<ControlTemplate x:Key="ValidationErrorTemplate">
    <StackPanel Orientation="Horizontal">
        <Border BorderBrush="#EF4444" BorderThickness="1.5" CornerRadius="4">
            <AdornedElementPlaceholder/>      <!-- 出错控件本身渲染在这 -->
        </Border>
        <TextBlock Text="!" Foreground="#EF4444" FontWeight="Bold"
                   ToolTip="{Binding [0].ErrorContent}"/>   <!-- 模板的数据上下文是错误集合 -->
    </StackPanel>
</ControlTemplate>
```

```xml
<TextBox ... Validation.ErrorTemplate="{StaticResource ValidationErrorTemplate}"/>
```

`AdornedElementPlaceholder` 是错误模板的专属占位符（相当于 ControlTemplate 里的 ContentPresenter）。错误模板渲染在**装饰层**——叠加在控件上方、不挤占布局（叹号不会把输入框顶歪）。

## 5. 验证策略的权衡

"每敲一键就报错"体验未必好（刚打一个字就说"用户名至少 2 个字符"）。三个常用策略：

1. **宽松触发**：TextBox 用默认 LostFocus（失焦才回写才验证），提交时手动触发全量验证
2. **先脏后严**：属性被改过（dirty）才开始验证——加一个 `_touched` 标记
3. **提交时兜底**：`Submit()` 里重新调用全部 Validate 方法，HasErrors 才放行（示例做法）

```csharp
public void Submit()
    => Result = HasErrors
        ? "表单有错误，请按红框提示修改后再提交。"
        : $"提交成功：{UserName}，{int.Parse(AgeText)} 岁…";
```

原则：**尽早反馈语法错（格式/必填），别打断语义探索（长度边打边判太苛刻）**。日期类输入推荐先失焦验证。

## 6. 常见坑

**验证根本不触发**：检查三个开关——绑定是 TwoWay（TextBox.Text 默认是，TextBlock 不会回写）、`ValidatesOnNotifyDataErrors=True`、VM 实现了 INDE 且 ErrorsChanged 真的触发过。

**ErrorsChanged 没触发界面不动**：错误集合变了但事件没发——SetErrors 统一入口的意义就在这。另一可能是发错了属性名（手写字符串）。

**HasErrors 不更新**：它是派生属性，忘了在 SetErrors 里联动通知——提交按钮永远可用。

**`(Validation.Errors)[0]` 显示空白**：无错误时集合是空的，索引失败静默——这是预期行为，配 FallbackValue 即可；有错误仍空白则是模板没挂上。

**错误模板挤坏布局**：ErrorTemplate 在装饰层本不占布局；但你在里面放了不带 AdornedElementPlaceholder 的内容，或外部容器触发布局变化——确保占位符在。

**默认红框不消失**：错误清空了红框还在——SetErrors 传空列表时必须触发 ErrorsChanged（移除键也算"变了"）。

## 7. 实战建议

- 新项目默认 INDE：一属性多错误 + 异步场景（查重请求服务器）只有它撑得住
- 错误文案写"怎么改"而不是"什么错了"："年龄必须是 18 到 60 之间" 优于 "年龄非法"
- 验证规则集中在 VM 的 Validate 方法里，别散在 XAML（转换器）与代码后置——规则可测
- 提交按钮 CanExecute 绑 HasErrors（第 12 章命令 + 本章验证的合流），双保险
- 第 25 章实战没做输入验证（记事本对内容无规则），把本章 FormViewModel 抄进去给"查找"对话框加"查找内容不能为空"验证，是个好练习

## 自测

1. **三种验证方案各自的适用？为什么教程主讲 INDE？** —— 异常最简、DataAnnotation 声明式、INDE 最灵活；一属性多错误/异步/跨字段只有 INDE 撑得住。
2. **INDE 的三个成员各是什么？谁来消费它们？** —— HasErrors/GetErrors/ErrorsChanged；绑定引擎消费并喂给 Validation.Errors 与错误模板。
3. **`(Validation.Errors)[0].ErrorContent` 绑的是什么？** —— 出错控件附加属性 Validation.Errors 集合里第一个错误的文本。
4. **"边打字边报错"由什么控制？** —— 验证在 setter 里 + XAML 的 UpdateSourceTrigger=PropertyChanged；改失焦验证就换回默认触发。

---
上一章：[15 模板](15-templates.md) ｜ 下一章：[17 ListView 与 DataGrid](17-listview-datagrid.md)
