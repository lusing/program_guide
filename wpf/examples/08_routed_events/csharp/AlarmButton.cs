using System.Windows;
using System.Windows.Controls;

namespace RoutedEvents;

/// <summary>自定义路由事件（教材 6.3）：EventManager.RegisterRoutedEvent 注册一个冒泡策略的 Alarm 事件。</summary>
public class AlarmButton : Button
{
    public static readonly RoutedEvent AlarmEvent = EventManager.RegisterRoutedEvent(
        "Alarm", RoutingStrategy.Bubble, typeof(RoutedEventHandler), typeof(AlarmButton));

    // CLR 事件包装器：让 XAML/代码都能用 += 语法挂到这个路由事件上
    public event RoutedEventHandler Alarm
    {
        add => AddHandler(AlarmEvent, value);
        remove => RemoveHandler(AlarmEvent, value);
    }

    public void RaiseAlarm()
        => RaiseEvent(new RoutedEventArgs(AlarmEvent, this));
}
