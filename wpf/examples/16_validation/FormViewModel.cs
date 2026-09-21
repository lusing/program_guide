using System.Collections;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace ValidationDemo;

// INotifyDataErrorInfo：WPF 验证三方案（异常 / DataAnnotation / 本接口）中最灵活的一个——
// 支持异步、支持一属性多错误、支持跨字段联动
public sealed class FormViewModel : INotifyPropertyChanged, INotifyDataErrorInfo
{
    private readonly Dictionary<string, List<string>> _errors = new();

    private string _userName = "";
    private string _ageText = "";
    private string _email = "";
    private string _result = "";

    public string UserName
    {
        get => _userName;
        set { _userName = value; OnPropertyChanged(); ValidateUserName(); }
    }

    public string AgeText
    {
        get => _ageText;
        set { _ageText = value; OnPropertyChanged(); ValidateAge(); }
    }

    public string Email
    {
        get => _email;
        set { _email = value; OnPropertyChanged(); ValidateEmail(); }
    }

    public string Result
    {
        get => _result;
        private set { _result = value; OnPropertyChanged(); }
    }

    public bool HasErrors => _errors.Values.Any(list => list.Count > 0);

    // 界面取错误文本的入口：参数为属性名；null = "全部错误"
    public IEnumerable GetErrors(string? propertyName)
        => propertyName is not null && _errors.TryGetValue(propertyName, out var list)
            ? list
            : Array.Empty<string>();

    public event EventHandler<DataErrorsChangedEventArgs>? ErrorsChanged;
    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

    // ---------- 三条验证规则 ----------

    private void ValidateUserName()
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(UserName))
            errors.Add("用户名不能为空");
        else if (UserName.Length < 2)
            errors.Add("用户名至少 2 个字符");
        SetErrors(nameof(UserName), errors);
    }

    private void ValidateAge()
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(AgeText))
            errors.Add("年龄不能为空");
        else if (!int.TryParse(AgeText, out var age))
            errors.Add("年龄必须是整数");
        else if (age is < 18 or > 60)
            errors.Add("年龄必须在 18 到 60 之间");
        SetErrors(nameof(AgeText), errors);
    }

    private void ValidateEmail()
    {
        var errors = new List<string>();
        if (!string.IsNullOrEmpty(Email) && !Email.Contains('@'))
            errors.Add("邮箱必须包含 @（留空表示不填）");
        SetErrors(nameof(Email), errors);
    }

    // ---------- 错误集合的维护：改了要通知，否则界面不知道要重新取 ----------

    private void SetErrors(string propertyName, List<string> errors)
    {
        var changed = !_errors.TryGetValue(propertyName, out var old)
                      || !old.SequenceEqual(errors);
        if (!changed) return;

        if (errors.Count == 0) _errors.Remove(propertyName);
        else _errors[propertyName] = errors;

        ErrorsChanged?.Invoke(this, new DataErrorsChangedEventArgs(propertyName));
        OnPropertyChanged(nameof(HasErrors));
    }

    public void Submit()
        => Result = HasErrors
            ? "表单有错误，请按红框提示修改后再提交。"
            : $"提交成功：{UserName}，{int.Parse(AgeText)} 岁" +
              (string.IsNullOrEmpty(Email) ? "，未留邮箱" : $"，邮箱 {Email}");
}
