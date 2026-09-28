// 17 文件 IO 与加密（F# 版）
module CryptoFs.Program

open System
open System.Drawing
open System.IO
open System.Security.Cryptography
open System.Threading.Tasks
open System.Windows.Forms

// ── 纯函数工具区（与 UI 无关，可单独测试）──
let sha256 (path: string) =
    use sha = SHA256.Create()
    use fs = File.OpenRead path
    sha.ComputeHash fs

// PBKDF2：口令不是密钥——拉伸 + 加盐
let deriveKey (pwd: string) (salt: byte[]) (len: int) =
    Rfc2898DeriveBytes.Pbkdf2(pwd, salt, 100000, HashAlgorithmName.SHA256, len)

// 加密产物布局：[16 字节盐][16 字节 IV][密文]
let encryptFile (src: string) (dst: string) (pwd: string) =
    use aes = Aes.Create()                          // 默认 CBC + PKCS7
    let salt = RandomNumberGenerator.GetBytes 16
    aes.Key <- deriveKey pwd salt (aes.KeySize / 8)
    aes.IV <- RandomNumberGenerator.GetBytes 16
    use outFs = File.Create dst
    outFs.Write(salt, 0, salt.Length)               // 盐不保密，跟着文件走
    outFs.Write(aes.IV, 0, aes.IV.Length)
    use enc = aes.CreateEncryptor()
    use cs = new CryptoStream(outFs, enc, CryptoStreamMode.Write)
    use inFs = File.OpenRead src
    inFs.CopyTo cs

let decryptFile (src: string) (dst: string) (pwd: string) =
    use aes = Aes.Create()
    use inFs = File.OpenRead src
    let salt = Array.zeroCreate<byte> 16
    let iv = Array.zeroCreate<byte> 16
    inFs.ReadExactly(salt, 0, salt.Length)
    inFs.ReadExactly(iv, 0, iv.Length)
    aes.Key <- deriveKey pwd salt (aes.KeySize / 8)
    aes.IV <- iv
    use dec = aes.CreateDecryptor()
    use cs = new CryptoStream(inFs, dec, CryptoStreamMode.Read)
    use outFs = File.Create dst
    cs.CopyTo outFs

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "文件保险箱（F#）", ClientSize = Size(640, 300),
                        StartPosition = FormStartPosition.CenterScreen,
                        Font = new Font("微软雅黑", 10F),
                        FormBorderStyle = FormBorderStyle.FixedSingle, MaximizeBox = false)
    let mutable picked: string option = None

    let lbl y t = new Label(Text = t, AutoSize = true, Location = Point(16, y + 4))
    let box y ro = new TextBox(Location = Point(70, y), Width = 370, ReadOnly = ro)

    let fileBox = box 30 true
    let pwdBox = box 70 false
    pwdBox.UseSystemPasswordChar <- true

    let mutable btnY = 30
    let mkBtn text onClick =
        let b = new Button(Text = text, AutoSize = true, Location = Point(460, btnY))
        btnY <- btnY + 40
        b.Click.Add(fun _ -> onClick ())
        b

    let status = new Label(Dock = DockStyle.Bottom, Height = 60, BackColor = Color.Gainsboro,
                           TextAlign = ContentAlignment.MiddleLeft)
    let say msg = status.Text <- "  " + msg

    let hashLbl = new Label(AutoSize = true, Location = Point(16, 200),
                            ForeColor = Color.DimGray, Text = "哈希会显示在这里")

    let pickBtn = mkBtn "① 选一个文件…" (fun () ->
        use dlg = new OpenFileDialog(Filter = "所有文件|*.*")
        if dlg.ShowDialog(form) = DialogResult.OK then
            picked <- Some dlg.FileName
            fileBox.Text <- dlg.FileName
            hashLbl.Text <- "哈希会显示在这里")

    let hashBtn = mkBtn "② 算 SHA256" (fun () ->
        match picked with
        | None -> say "先选文件"
        | Some p ->
            let hex = sha256 p |> Convert.ToHexString
            let head = hex.Substring(0, 16)
            hashLbl.Text <- $"SHA256 = {head}…（前 16 位十六进制）"
            say "哈希已算出。加密后再算 .enc 的哈希对比——完全不同；解密回来应当与现在一致")

    let encBtn = mkBtn "③ 加密 → .enc" (fun () ->
        match picked with
        | None -> say "先选文件"
        | Some p ->
            if pwdBox.Text.Length < 4 then say "口令至少 4 个字符"
            else
                say "正在加密（后台线程）…"
                Task.Run(fun () -> encryptFile p (p + ".enc") pwdBox.Text) |> ignore
                say $"后台加密中 → {p}.enc。每次加密结果都不同（随机盐 + 随机 IV）")

    let decBtn = mkBtn "④ 解密 → .dec 并校验" (fun () ->
        match picked with
        | None -> say "先选文件"
        | Some p ->
            let enc, dec = p + ".enc", p + ".dec"
            if not (File.Exists enc) then say $"没找到 {enc}，先加密"
            else
                Task.Run(fun () ->
                    try
                        decryptFile enc dec pwdBox.Text
                        let same = sha256 p = sha256 dec
                        form.BeginInvoke(fun () ->
                            let msg =
                                if same then "✔ 哈希一致——解密还原成功（口令正确、数据未被动过）"
                                else "✘ 哈希不一致！（口令错了或文件被动过）"
                            MessageBox.Show(form, msg, "校验结果") |> ignore
                            say (if same then "还原成功" else "还原失败")) |> ignore
                    with
                    | :? CryptographicException ->
                        form.BeginInvoke(fun () ->
                            MessageBox.Show(form, "口令不对（AES 解不开）", "校验结果") |> ignore
                            say "口令错误") |> ignore
                    | ex ->
                        form.BeginInvoke(fun () -> say $"解密失败：{ex.Message}") |> ignore)
                |> ignore)

    let controls: Control[] =
        [| status; hashLbl; decBtn; encBtn; hashBtn; pwdBox; pickBtn; fileBox
           lbl 70 "口令："; lbl 30 "文件：" |]
    form.Controls.AddRange controls
    say "小提示：先拿个小文本文件练手。加密/解密在后台线程跑，不冻界面。"

    Application.Run form
    0
