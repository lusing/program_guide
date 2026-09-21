using System.Globalization;
using System.Windows.Data;

namespace TreeViewDemo;

// bool → 图标字符：文件夹/文件。简单场景的转换器比模板触发器更省 XAML
public sealed class BoolToIconConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        => value is true ? "\U0001F4C1" : "\U0001F4C4";   // 📁 / 📄

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotSupportedException();
}
