// 18 通讯录 UI（F# 版）
module DataFs.Program

open System
open System.Drawing
open System.IO
open System.Windows.Forms

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "通讯录（SQLite，F#）", ClientSize = Size(700, 480),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let db = Path.Combine(Path.GetTempPath(), "winforms18fs.db")
    let repo = Repository.ContactRepository(db)

    let nameBox = new TextBox()
    let phoneBox = new TextBox()
    let cityBox = new TextBox()
    let mutable selectedId = 0L
    let status = new Label(Dock = DockStyle.Bottom, Height = 30, BackColor = Color.Gainsboro)
    let say msg = status.Text <- "  " + msg

    let field (box: TextBox) y =
        box.Location <- Point(70, y)
        box.Width <- 200
    field nameBox 30; field phoneBox 66; field cityBox 102

    let editor = new GroupBox(Text = " 联系人（先在表格里选中一行，再编辑/删除）",
                              Dock = DockStyle.Top, Height = 120)
    let add = new Button(Text = "新增", Location = Point(430, 26), AutoSize = true)
    let upd = new Button(Text = "保存修改", Location = Point(510, 26), AutoSize = true)
    let del = new Button(Text = "删除选中", Location = Point(430, 60), AutoSize = true)

    let search = new TextBox()
    search.SetBounds(16, 28, 240, 30)

    let grid = new DataGridView(Dock = DockStyle.Fill, ReadOnly = true,
                                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                                AllowUserToAddRows = false)
    grid.CellClick.Add(fun e ->
        if e.RowIndex >= 0 then
            let row = grid.Rows.[e.RowIndex]
            selectedId <- unbox row.Cells.["id"].Value
            nameBox.Text <- string row.Cells.["name"].Value
            phoneBox.Text <- string row.Cells.["phone"].Value
            cityBox.Text <- string row.Cells.["city"].Value)

    let reload message =
        grid.DataSource <- repo.All(search.Text.Trim())
        selectedId <- 0L
        match message with
        | Some m -> say $"{m}，当前 {grid.RowCount} 条"
        | None -> ()

    add.Click.Add(fun _ -> repo.Add(nameBox.Text, phoneBox.Text, cityBox.Text) |> ignore; reload (Some "已新增"))
    upd.Click.Add(fun _ ->
        if selectedId = 0L then say "先在表格里选中一行"
        else repo.Update(selectedId, nameBox.Text, phoneBox.Text, cityBox.Text) |> ignore; reload (Some "已修改"))
    del.Click.Add(fun _ ->
        if selectedId = 0L then say "先在表格里选中一行"
        else repo.Delete selectedId |> ignore; reload (Some "已删除"))

    let go = new Button(Text = "查", Location = Point(270, 26), AutoSize = true)
    go.Click.Add(fun _ -> reload None)
    search.KeyDown.Add(fun e -> if e.KeyCode = Keys.Enter then reload None)

    let searchBox = new GroupBox(Text = " 搜索（参数化——输入 ' OR '1'='1 也只是当普通文本）",
                                 Dock = DockStyle.Top, Height = 70)

    let editorControls: Control[] =
        [| new Label(Text = "姓名：", AutoSize = true, Location = Point(16, 34)); nameBox
           new Label(Text = "电话：", AutoSize = true, Location = Point(16, 70)); phoneBox
           new Label(Text = "城市：", AutoSize = true, Location = Point(16, 106)); cityBox
           add; upd; del |]
    editor.Controls.AddRange editorControls
    let searchControls: Control[] = [| search; go |]
    searchBox.Controls.AddRange searchControls

    form.Controls.Add grid
    form.Controls.Add searchBox
    form.Controls.Add editor
    form.Controls.Add status

    reload None
    say $"数据库：{db}"

    Application.Run form
    0
