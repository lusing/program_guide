// 03 第一个 WPF 程序（F# 版）：与 csharp/ 目录的 C# 版功能一致。
// F# 没有 XAML 代码生成器（x:Class 要靠分部类），所以走「纯代码 UI」路线——
// 这也是本教程 F# 章节的统一写法：所有界面都用对象初始化器搭建。
module HelloWpfFs.Program

open System
open System.Windows
open System.Windows.Controls

[<EntryPoint; STAThread>]
let main _ =
    let prompt = TextBlock(Text = "请输入你的名字：", FontSize = 18., Margin = Thickness(0., 0., 0., 12.))

    let nameBox = TextBox(Width = 220., Height = 32., Margin = Thickness(0., 0., 0., 12.))

    let greet = Button(Content = "打招呼", Width = 120., Height = 36.)
    greet.Click.Add(fun _ ->
        let name = if System.String.IsNullOrWhiteSpace nameBox.Text then "朋友" else nameBox.Text.Trim()
        MessageBox.Show(sprintf "Hello, %s!" name, "Greeting") |> ignore)

    let panel = StackPanel(VerticalAlignment = VerticalAlignment.Center)
    panel.Children.Add prompt |> ignore
    panel.Children.Add nameBox |> ignore
    panel.Children.Add greet |> ignore

    // Grid.Children 是只读集合属性——F# 没有 C# 的 { Children = { ... } } 集合初始化器，
    // 只能先建容器再 Add（这是纯代码 UI 的固定三步：建 → 设属性 → Add）
    let grid = Grid(Margin = Thickness 20.)
    grid.Children.Add panel |> ignore

    let window = Window(Title = "Hello WPF (F#)", Height = 220., Width = 400., Content = grid)

    Application().Run window
