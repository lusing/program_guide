// 18 TreeView 与层级数据（F# 版）：与 csharp/ 版功能一致。
// HierarchicalDataTemplate 的两个挂钩：VisualTree（节点长相）+ ItemsSource（孩子从哪来，值是 Binding）。
// TreeView.SelectedItem 只读不能 TwoWay——选中要靠 SelectedItemChanged 事件拿（本章第一坑）。
module TreeViewDemoFs.Program

open System
open System.Collections.ObjectModel
open System.ComponentModel
open System.Windows
open System.Windows.Controls
open System.Windows.Controls.Primitives   // VirtualizingStackPanel
open System.Windows.Data
open System.Windows.Media

type BoolToIconConverter() =
    interface IValueConverter with
        member _.Convert(value, _, _, _) : obj =
            match value with
            | :? bool as b when b -> box "\U0001F4C1"   // 📁
            | _ -> box "\U0001F4C4"                      // 📄
        member _.ConvertBack(_, _, _, _) = raise (NotSupportedException())

type FileNode(name: string, isFolder: bool) as this =
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let children = ObservableCollection<FileNode>()
    let mutable isExpanded = false
    member _.Name = name
    member _.IsFolder = isFolder
    member _.Children = children
    member _.IsExpanded
        with get () = isExpanded
        and set v = isExpanded <- v; pc.Trigger(this, PropertyChangedEventArgs "IsExpanded")
    member _.Badge = if isFolder then sprintf "%d 项" children.Count else ""
    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

let buildTree () =
    let file n = FileNode(n, false)
    let folder n expanded kids =
        let f = FileNode(n, true)
        f.IsExpanded <- expanded
        kids |> List.iter f.Children.Add
        f
    let root = ObservableCollection<FileNode>()
    root.Add(folder "NotepadPlus" true [
        file "App.xaml"; file "NotepadPlus.csproj"
        folder "ViewModels" false [ file "MainViewModel.cs"; file "RelayCommand.cs" ]
        folder "Views" false [ file "MainWindow.xaml"; file "FindReplaceWindow.xaml" ]
        folder "Services" false [ file "EncodingDetector.cs"; file "RecentFilesService.cs" ] ])
    root.Add(folder "docs" false [
        file "07-mvvm-commands.md"; file "12-notepad-plus.md" ])
    root

[<EntryPoint; STAThread>]
let main _ =
    let root = buildTree ()
    let window = Window(Title = "TreeView：层级数据 (F#)", Height = 460., Width = 420.)

    let status = TextBlock(Text = "选中树里的任意节点")

    // HierarchicalDataTemplate：代码建树两挂钩
    let hdt = HierarchicalDataTemplate(typeof<FileNode>)
    hdt.ItemsSource <- Binding "Children"   // 孩子从哪来——值是一个 Binding
    let row = FrameworkElementFactory(typeof<StackPanel>)
    row.SetValue(StackPanel.OrientationProperty, Orientation.Horizontal)
    let icon = FrameworkElementFactory(typeof<TextBlock>)
    icon.SetBinding(TextBlock.TextProperty, Binding("IsFolder", Converter = BoolToIconConverter(), FallbackValue = "?"))
    let name = FrameworkElementFactory(typeof<TextBlock>)
    name.SetBinding(TextBlock.TextProperty, Binding "Name")
    name.SetValue(FrameworkElement.MarginProperty, Thickness(6., 0., 0., 0.))
    name.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    let badge = FrameworkElementFactory(typeof<TextBlock>)
    badge.SetBinding(TextBlock.TextProperty, Binding "Badge")
    badge.SetValue(TextBlock.FontSizeProperty, 11.)
    badge.SetValue(TextBlock.ForegroundProperty, SolidColorBrush(Color.FromRgb(0x94uy, 0xA3uy, 0xB8uy)))
    badge.SetValue(FrameworkElement.MarginProperty, Thickness(8., 0., 0., 0.))
    badge.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    row.AppendChild icon |> ignore
    row.AppendChild name |> ignore
    row.AppendChild badge |> ignore
    hdt.VisualTree <- row

    let tree = TreeView(ItemTemplate = hdt)
    tree.ItemsSource <- root   // 代码里数据就在手边：直赋比绕一圈绑定干净
    VirtualizingStackPanel.SetIsVirtualizing(tree, true)   // XAML 的附加属性 → 静态方法
    // SelectedItem 只读：拿选中只能靠事件
    tree.SelectedItemChanged.Add(fun e ->
        match e.NewValue with
        | :? FileNode as node ->
            status.Text <- sprintf "选中：%s（%s）" node.Name (if node.IsFolder then "文件夹" else "文件")
        | _ -> ())

    let setExpanded (nodes: ObservableCollection<FileNode>) expanded =
        // 递归遍历模型本身：树形 UI 的批量操作落在数据上，而不是视觉树上
        let rec loop (nodes: ObservableCollection<FileNode>) =
            for node in nodes do
                node.IsExpanded <- expanded
                loop node.Children
        loop nodes

    let expandAll = Button(Content = "展开全部", Width = 90., Margin = Thickness(0., 0., 8., 0.))
    expandAll.Click.Add(fun _ -> setExpanded root true)
    let collapseAll = Button(Content = "收起全部", Width = 90.)
    collapseAll.Click.Add(fun _ -> setExpanded root false)
    let toolbar = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 0., 0., 8.))
    toolbar.Children.Add expandAll |> ignore
    toolbar.Children.Add collapseAll |> ignore

    let statusBar = StatusBar()
    statusBar.Items.Add status |> ignore

    let dock = DockPanel(Margin = Thickness 12.)
    DockPanel.SetDock(toolbar, Dock.Top)
    DockPanel.SetDock(statusBar, Dock.Bottom)
    dock.Children.Add toolbar |> ignore
    dock.Children.Add statusBar |> ignore
    dock.Children.Add tree |> ignore

    window.Content <- dock
    Application().Run window
