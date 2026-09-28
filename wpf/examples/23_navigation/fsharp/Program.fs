// 23 窗口与页面导航（F# 版）：与 csharp/ 版功能一致。
// Frame.Navigate(页面对象) 是对象导航（每次都新实例）；Page 也可以是纯代码构建。
module NavigationDemoFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Navigation   // NavigationUIVisibility 在这

let homePage () =
    let p = Page()
    p.Content <- TextBlock(Text = "欢迎来到首页", FontSize = 22., FontWeight = FontWeights.Bold,
                           Margin = Thickness 20.)
    p

let settingsPage () =
    let p = Page()
    let panel = StackPanel(Margin = Thickness 20.)
    panel.Children.Add(TextBlock(Text = "设置页面", FontSize = 22., FontWeight = FontWeights.Bold)) |> ignore
    panel.Children.Add(CheckBox(Content = "启用通知", IsChecked = true, Margin = Thickness(0., 12., 0., 0.))) |> ignore
    panel.Children.Add(CheckBox(Content = "自动保存", IsChecked = true)) |> ignore
    p.Content <- panel
    p

[<EntryPoint; STAThread>]
let main _ =
    let frame = Frame(NavigationUIVisibility = NavigationUIVisibility.Visible)

    let homeBtn = Button(Content = "首页", Width = 90., Margin = Thickness(0., 0., 8., 0.))
    homeBtn.Click.Add(fun _ -> frame.Navigate(homePage ()) |> ignore)
    let settingsBtn = Button(Content = "设置", Width = 90.)
    settingsBtn.Click.Add(fun _ -> frame.Navigate(settingsPage ()) |> ignore)

    let toolbar = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 0., 0., 12.))
    toolbar.Children.Add homeBtn |> ignore
    toolbar.Children.Add settingsBtn |> ignore

    let dock = DockPanel(Margin = Thickness 12.)
    DockPanel.SetDock(toolbar, Dock.Top)
    dock.Children.Add toolbar |> ignore
    dock.Children.Add frame |> ignore

    let window = Window(Title = "Navigation Demo (F#)", Height = 300., Width = 500., Content = dock)
    frame.Navigate(homePage ()) |> ignore   // 启动页
    Application().Run window
