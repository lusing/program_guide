// 22 对话框与文件 IO（F# 版）：与 csharp/ 版功能一致。
// OpenFileDialog/SaveFileDialog 在 Microsoft.Win32 命名空间（不在 System.Windows）。
// ShowDialog 返回 Nullable<bool>——判真用 GetValueOrDefault，没有 == true。
module FileDialogDemoFs.Program

open System
open System.IO
open System.Windows
open System.Windows.Controls
open Microsoft.Win32

[<EntryPoint; STAThread>]
let main _ =
    let pathBox = TextBox(Text = "未选择文件", TextWrapping = TextWrapping.Wrap, IsReadOnly = true,
                         VerticalScrollBarVisibility = ScrollBarVisibility.Auto)

    let openBtn = Button(Content = "打开文件", Width = 120., Height = 32., Margin = Thickness(0., 0., 12., 0.))
    openBtn.Click.Add(fun _ ->
        let dialog = OpenFileDialog(Filter = "文本文件|*.txt|所有文件|*.*",
                                    InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments))
        if dialog.ShowDialog().GetValueOrDefault() then
            pathBox.Text <- dialog.FileName
            MessageBox.Show(sprintf "已选择: %s" dialog.FileName, "Open File") |> ignore)

    let saveBtn = Button(Content = "保存文件", Width = 120., Height = 32.)
    saveBtn.Click.Add(fun _ ->
        let dialog = SaveFileDialog(Filter = "文本文件|*.txt|所有文件|*.*",
                                    FileName = "newfile.txt",
                                    InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments))
        if dialog.ShowDialog().GetValueOrDefault() then
            pathBox.Text <- dialog.FileName
            File.WriteAllText(dialog.FileName, "Hello from WPF!\r\n")
            MessageBox.Show(sprintf "已保存: %s" dialog.FileName, "Save File") |> ignore)

    let row = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 0., 0., 12.))
    row.Children.Add openBtn |> ignore
    row.Children.Add saveBtn |> ignore

    let grid = Grid(Margin = Thickness 20.)
    grid.RowDefinitions.Add(RowDefinition(Height = GridLength.Auto))
    grid.RowDefinitions.Add(RowDefinition(Height = GridLength.Auto))
    grid.RowDefinitions.Add(RowDefinition(Height = GridLength(1., GridUnitType.Star)))
    let title = TextBlock(Text = "文件对话框示例", FontSize = 22., FontWeight = FontWeights.Bold,
                          Margin = Thickness(0., 0., 0., 12.))
    Grid.SetRow(title, 0); Grid.SetRow(row, 1); Grid.SetRow(pathBox, 2)
    grid.Children.Add title |> ignore
    grid.Children.Add row |> ignore
    grid.Children.Add pathBox |> ignore

    let window = Window(Title = "File Dialog Demo (F#)", Height = 260., Width = 480., Content = grid)
    Application().Run window
