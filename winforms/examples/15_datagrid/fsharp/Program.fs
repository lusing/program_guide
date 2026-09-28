// 15 DataGridView（F# 版）
module GridFs.Program

open System
open System.ComponentModel
open System.Drawing
open System.Windows.Forms

// 可变记录用 CLIMutable 也不够（属性 set 不触发通知）——直接用带 set 的类
type Order() =
    member val Id = 0 with get, set
    member val Customer = "" with get, set
    member val Product = "" with get, set
    member val Qty = 0 with get, set
    member val Price = 0m with get, set
    member val Paid = false with get, set
    member this.Total = decimal this.Qty * this.Price

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "DataGridView 深入（F#）", ClientSize = Size(760, 520),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let orders = BindingList<Order>()
    let order id customer product qty price paid =
        Order(Id = id, Customer = customer, Product = product, Qty = qty, Price = price, Paid = paid)
    orders.Add(order 1 "林一" "键盘" 2 299m true)
    orders.Add(order 2 "林一" "显示器" 1 1899m false)
    orders.Add(order 3 "陈二" "鼠标" 5 89m false)
    orders.Add(order 4 "陈二" "内存条" 2 459m true)
    orders.Add(order 5 "张三" "U盘" 10 39m true)

    let source = new BindingSource()

    let sum = new Label(Dock = DockStyle.Bottom, Height = 30, BackColor = Color.Gainsboro,
                        TextAlign = ContentAlignment.MiddleLeft)
    let refreshSum () =
        let view = source.DataSource :?> BindingList<Order>
        let total = view |> Seq.sumBy (fun o -> o.Total)
        sum.Text <- $"  当前列出 {view.Count} 单，合计 {total:C}（改个数量试试，合计实时变）"

    // ═══ 15.1 主从联动 ═══
    let filterBox = new GroupBox(Text = " 主从联动 ", Dock = DockStyle.Top, Height = 74)
    let customer = new ComboBox(DropDownStyle = ComboBoxStyle.DropDownList)
    customer.SetBounds(70, 28, 140, 30)
    orders
    |> Seq.map (fun o -> o.Customer)
    |> Seq.distinct
    |> Seq.iter (fun c -> customer.Items.Add c |> ignore)
    customer.SelectedIndex <- 0

    let all = new CheckBox(Text = "看全部", AutoSize = true, Location = Point(230, 30))
    let applyFilter () =
        let view =
            if all.Checked then BindingList<Order>(orders)
            else
                let picked = orders |> Seq.filter (fun o -> o.Customer = string customer.SelectedItem) |> ResizeArray
                BindingList<Order>(picked)
        source.DataSource <- view
        refreshSum ()
    customer.SelectedIndexChanged.Add(fun _ -> applyFilter ())
    all.CheckedChanged.Add(fun _ -> applyFilter ())

    let fl = new Label(Text = "客户：", AutoSize = true, Location = Point(14, 32))
    let filterControls: Control[] = [| fl; customer; all |]
    filterBox.Controls.AddRange filterControls

    // ═══ 15.2 手工列 ═══
    let grid = new DataGridView(Dock = DockStyle.Fill, AutoGenerateColumns = false,
                                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                                AllowUserToAddRows = false)
    grid.DataSource <- source

    let textCol header prop weight =
        let c = new DataGridViewTextBoxColumn(HeaderText = header, DataPropertyName = prop, FillWeight = weight)
        grid.Columns.Add c |> ignore
    textCol "单号" "Id" 10f
    grid.Columns.[grid.Columns.Count - 1].ReadOnly <- true
    textCol "客户" "Customer" 16f
    let productCol = new DataGridViewComboBoxColumn(HeaderText = "商品", DataPropertyName = "Product", FillWeight = 18f)
    productCol.DataSource <- ResizeArray [ "键盘"; "鼠标"; "显示器"; "内存条"; "U盘" ]
    grid.Columns.Add productCol |> ignore
    textCol "数量" "Qty" 12f
    textCol "单价" "Price" 14f
    grid.Columns.[grid.Columns.Count - 1].DefaultCellStyle.Format <- "C"
    let checkCol = new DataGridViewCheckBoxColumn(HeaderText = "已付", DataPropertyName = "Paid", FillWeight = 10f)
    grid.Columns.Add checkCol |> ignore
    textCol "合计" "Total" 14f
    grid.Columns.[grid.Columns.Count - 1].ReadOnly <- true
    let btnCol = new DataGridViewButtonColumn(HeaderText = "操作", Text = "删除",
                                              UseColumnTextForButtonValue = true, FillWeight = 10f)
    grid.Columns.Add btnCol |> ignore

    // ═══ 15.3 校验 ═══
    grid.CellValidating.Add(fun e ->
        if (grid.Columns.[e.ColumnIndex].DataPropertyName = "Qty") then
            match Int32.TryParse(string e.FormattedValue) with
            | true, qty when qty >= 1 && qty <= 99 -> ()
            | _ ->
                e.Cancel <- true
                grid.Rows.[e.RowIndex].ErrorText <- "数量必须是 1~99 的整数")
    grid.CellEndEdit.Add(fun e -> grid.Rows.[e.RowIndex].ErrorText <- null)

    // ═══ 15.4 条件着色 ═══
    grid.CellFormatting.Add(fun e ->
        if e.RowIndex >= 0 && grid.Rows.[e.RowIndex].DataBoundItem :? Order then
            let row = grid.Rows.[e.RowIndex].DataBoundItem :?> Order
            e.CellStyle.BackColor <- if row.Total >= 1000m then Color.MistyRose else Color.White)

    // ═══ 按钮列 ═══
    grid.CellContentClick.Add(fun e ->
        if grid.Columns.[e.ColumnIndex] :? DataGridViewButtonColumn then
            match grid.Rows.[e.RowIndex].DataBoundItem with
            | :? Order as doomed ->
                orders.Remove doomed |> ignore
                applyFilter ()
            | _ -> ())

    form.Controls.Add grid
    form.Controls.Add sum
    form.Controls.Add filterBox

    applyFilter ()

    Application.Run form
    0
