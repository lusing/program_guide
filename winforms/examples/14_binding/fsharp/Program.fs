// 14 数据绑定（F# 版）
module BindingFs.Program

open System
open System.ComponentModel
open System.Drawing
open System.Windows.Forms

// ═══ 14.1 INPC 的 F# 惯用写法：Event<_> + get/set 属性 ═══
type Person() as this =

    let propertyChanged = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let mutable name = ""
    let mutable age = 0
    let mutable email = ""

    interface INotifyPropertyChanged with
        [<CLIEvent>]                                   // 不加这个属性，F# 不认它是对应的抽象事件
        member _.PropertyChanged = propertyChanged.Publish

    member _.Name
        with get() = name
        and set v = if name <> v then name <- v; this.Notify "Name"

    member _.Age
        with get() = age
        and set v = if age <> v then age <- v; this.Notify "Age"

    member _.Email
        with get() = email
        and set v = if email <> v then email <- v; this.Notify "Email"

    member private _.Notify propName =
        propertyChanged.Trigger(this, PropertyChangedEventArgs propName)

    override _.ToString() = name

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "数据绑定（F#）", ClientSize = Size(680, 520),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let mkPerson n a e =
        Person(Name = n, Age = a, Email = e)

    let people = BindingList<Person>()
    people.Add(mkPerson "林一" 28 "linyi@example.com")
    people.Add(mkPerson "陈二" 35 "chener@example.com")
    people.Add(mkPerson "张三" 41 "zhangsan@example.com")

    let source = new BindingSource()
    source.DataSource <- people

    // ═══ 14.3 表单 ═══
    let box = new GroupBox(Text = " 当前人员（编辑后看表格同步刷新）", Dock = DockStyle.Top, Height = 150)

    let nameBox = new TextBox()
    nameBox.SetBounds(90, 28, 160, 30)
    nameBox.DataBindings.Add("Text", source, "Name") |> ignore     // 双向：改对象→控件，改控件→对象

    let ageBox = new NumericUpDown(Minimum = 0m, Maximum = 120m)
    ageBox.SetBounds(90, 66, 90, 30)
    // NumericUpDown.Value 是 decimal、Person.Age 是 int：Format/Parse 两端做换算
    let ageBind = new Binding("Value", source, "Age")
    ageBind.Format.Add(fun e -> e.Value <- Convert.ToDecimal e.Value)
    ageBind.Parse.Add(fun e -> e.Value <- Convert.ToInt32 e.Value)
    ageBox.DataBindings.Add ageBind

    let emailBox = new TextBox()
    emailBox.SetBounds(90, 104, 200, 30)
    emailBox.DataBindings.Add("Text", source, "Email") |> ignore

    // ═══ 14.4 Format 加工展示层 ═══
    let ageEcho = new Label(AutoSize = true, Location = Point(310, 70))
    let echoBind = new Binding("Text", source, "Age")
    echoBind.Format.Add(fun e -> e.Value <- $"{e.Value} 岁（Format 事件加工）")
    echoBind.Parse.Add(fun _ -> ())        // 只读回显
    ageEcho.DataBindings.Add echoBind

    let nl = new Label(Text = "姓名：", AutoSize = true, Location = Point(16, 32))
    let al = new Label(Text = "年龄：", AutoSize = true, Location = Point(16, 70))
    let el = new Label(Text = "邮箱：", AutoSize = true, Location = Point(16, 108))

    let boxControls: Control[] = [| nl; nameBox; al; ageBox; el; emailBox; ageEcho |]
    box.Controls.AddRange boxControls

    // ═══ 14.5 导航与表格 ═══
    let nav = new BindingNavigator(true)
    nav.BindingSource <- source
    nav.Dock <- DockStyle.Top
    let add = new Button(Text = "＋新增人员", Dock = DockStyle.Top, Height = 32)
    add.Click.Add(fun _ ->
        source.Add(mkPerson "新人员" 20 "")
        source.Position <- source.Count - 1)

    let grid = new DataGridView(Dock = DockStyle.Fill,
                                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                                SelectionMode = DataGridViewSelectionMode.FullRowSelect)
    grid.DataSource <- source

    form.Controls.Add grid
    form.Controls.Add add
    form.Controls.Add nav
    form.Controls.Add box

    Application.Run form
    0
