using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace BindingAdvanced;

// 单值转换器：bool → Visibility。教学手写版；实际项目先用内置 BooleanToVisibilityConverter
public sealed class BoolToVisibilityConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        => value is true ? Visibility.Visible : Visibility.Collapsed;

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => value is Visibility.Visible;
}

// 多值转换器：姓 + 名 → 全名
public sealed class FullNameConverter : IMultiValueConverter
{
    public object Convert(object?[] values, Type targetType, object? parameter, CultureInfo culture)
    {
        var last = values.Length > 0 ? values[0]?.ToString() : null;
        var first = values.Length > 1 ? values[1]?.ToString() : null;
        return $"{last}{first}";
    }

    public object?[] ConvertBack(object? value, Type[] targetTypes, object? parameter, CultureInfo culture)
        => throw new NotSupportedException("单向聚合，不回写");
}
