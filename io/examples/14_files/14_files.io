// ============================================================
// 14_files.io —— 第 14 章：文件与目录
// 运行：io examples/14_files/14_files.io
//
// File / Directory / Path 三件套。最大的坑是「字符串内部是 UCS4」：
// 含中文的串 setContents 出去是每码点 4 字节的鬼东西，必须 asUTF8；
// 读回来又只是**字节串**（size 数的是字节，语义没了）。
//
// 另一条纪律：所有临时文件都建在 TMPDIR 里、结束时删干净，
// 输出里绝不出现绝对路径——文件一律只打 basename / 固定名字。
// 异常全部 try(...) 抓，绝不让脚本中途死掉（Io 未捕获异常会中断
// 脚本、退出码却仍是 0，属于假阳性）。
// ============================================================

fails := 0
chk := method(tag, got, want,
    if(got asString != want asString,
        fails = fails + 1
        writeln("  [FAIL] ", tag, " 得到 ", got asString, "，期望 ", want asString)
    )
)
sec := method(title, writeln(""); writeln("-- ", title))
show := method(label, value, writeln(label, " = ", value asString))
showEsc := method(label, s, writeln(label, " = ", s escape))
// File/Directory 对象的默认 asString 带地址（File_0x7f...），
// 一律先 map 成名字再 sort，否则输出不可比。
names := method(objs, objs map(a, a name) sort asString)

writeln("==== 14 开始 ====")

tmp := System getEnvironmentVariable("TMPDIR")

sec("14.1 路径与 File 对象：Path 就是 Sequence")
p := Path with("cfg", "app", "note.txt")
show("Path with(\"cfg\", \"app\", \"note.txt\")", p)
show("p type", p type)
show("p size（就是字符个数）", p size)
show("p isKindOf(Sequence)", p isKindOf(Sequence))
show("Path with 单个参数", Path with("only.txt"))
base := Path with(tmp, "io_tut_14")
fileA := File with(base)
show("File with(Path) 的 name", fileA name)
fileB := File clone setPath(base)
show("File clone setPath 得到同样的 name", fileB name)
show("File with 就是 clone setPath", fileA name == fileB name)

sec("14.2 写文件：setContents 写的是「内部表示」，含中文必须 asUTF8")
text := "中文 hello world"
show("text size（码点数）", text size)
show("text sizeInBytes", text sizeInBytes)
show("text asUTF8 size（UTF-8 字节数）", text asUTF8 size)
show("text itemType", text itemType)
ucs4Path := Path with(tmp, "io_tut_14_ucs4.bin")
ucs4File := File with(ucs4Path)
ucs4File remove
ucs4File setContents(text)
// 注意：写完不要在同一个 File 对象上读 size——它是缓存值，会给你上一次的。
// 要真实值就新建一个对象，或者读 stat size。
show("setContents(text) 后文件字节数", (File clone setPath(ucs4Path)) size)
raw := (File clone setPath(ucs4Path)) contents
show("前 16 字节 hex（UCS4 小端）", raw exSlice(0, 16) asHex)
ucs4File setContents(text asUTF8)
show("setContents(text asUTF8) 后文件字节数", (File clone setPath(ucs4Path)) size)
utf := (File clone setPath(ucs4Path)) contents
show("前 16 字节 hex（UTF-8）", utf exSlice(0, 16) asHex)
ucs4File remove
chk("含中文的串内部每码点 4 字节：14 码点 → 56 字节", raw size, 56)
chk("asUTF8 之后同样这段中文只有 18 字节", utf size, 18)
chk("两种写法的字节数不相等", raw size == utf size, false)

sec("14.3 读文件：contents / readToEnd / readLine / readLines")
linePath := Path with(tmp, "io_tut_14_lines.txt")
(File with(linePath)) setContents("line1\nline2\nline3\n" asUTF8)
c := (File clone setPath(linePath)) contents
show("contents size（字节数）", c size)
show("contents itemType", c itemType)
show("contents == 原文的 asUTF8", c == ("line1\nline2\nline3\n" asUTF8))
rd := File clone setPath(linePath)
rd openForReading
show("openForReading 后 isOpen", rd isOpen)
showEsc("readToEnd", rd readToEnd)
rd close
rl := File clone setPath(linePath)
rl openForReading
showEsc("readLine 第一次", rl readLine)
showEsc("readLine 第二次", rl readLine)
show("还到末尾了吗", rl isAtEnd)
rl close
rls := File clone setPath(linePath)
rls openForReading
lines := rls readLines
show("readLines type", lines type)
show("readLines size", lines size)
show("readLines", lines asString)
rls close
semPath := Path with(tmp, "io_tut_14_sem.txt")
(File with(semPath)) setContents(text asUTF8)
back := (File clone setPath(semPath)) contents
show("原串 size（码点）", text size)
show("读回来 size（字节）", back size)
show("读回来 == 原串", back == text)
show("读回来 == 原串 asUTF8", back == text asUTF8)
(File with(semPath)) remove
chk("读回来按字节算：14 个码点的中文串读回来是 18", back size, 18)
chk("读回来的字节串和原来的语义串不相等", back == text, false)
chk("只有和 asUTF8 的那一份才相等", back == text asUTF8, true)

sec("14.4 File 没有 openForWriting")
nw := Path with(tmp, "io_tut_14_nowrite.txt")
bad := try(File with(nw) openForWriting)
show("openForWriting 抛异常", bad type asString == "Exception")
show("异常消息原文", bad error)
chk("报错原文", bad error, "File does not respond to 'openForWriting'")
show("File 真正有的打开方式", list("open", "openForReading", "openForAppending", "openForUpdating") asString)
show("写文件最省事的办法", "setContents")

sec("14.5 存在性与元信息")
metaPath := Path with(tmp, "io_tut_14_meta.txt")
metaFile := File with(metaPath)
metaFile remove
show("不存在时 exists", (File clone setPath(metaPath)) exists)
metaFile setContents("hello" asUTF8)
meta := File clone setPath(metaPath)
show("写后 exists", meta exists)
show("size", meta size)
show("stat size == size", meta stat size == meta size)
show("isDirectory", meta isDirectory)
show("lastDataChangeDate 的类型", meta lastDataChangeDate type)
show("lastDataChangeDate 非 nil", meta lastDataChangeDate != nil)
chk("size 就是字节数", meta size, 5)
chk("lastDataChangeDate 是 Date 而不是字符串", meta lastDataChangeDate type asString, "Date")
meta remove

sec("14.6 临时文件：File temporaryFile 与 TMPDIR")
tf := File temporaryFile
show("File temporaryFile 的 type", tf type)
show("它的 path 是空串", tf path size == 0)
tf setContents("x" asUTF8)
show("写它之后 exists（还是 false）", tf exists)
show("所以真正能用的临时文件得自己拼", "Path with(TMPDIR, 名字)")
tmpPath := Path with(tmp, "io_tut_14_tmp.txt")
tmpFile := File with(tmpPath)
tmpFile remove
tmpFile setContents("t" asUTF8)
show("自拼路径写后 exists", (File clone setPath(tmpPath)) exists)
show("TMPDIR 非空", tmp size > 0)
tmpFile remove
show("删后 exists", (File clone setPath(tmpPath)) exists)

sec("14.7 Directory：列目录、顺序与过滤")
root := Path with(tmp, "io_tut_14_dir")
rootDir := Directory with(root)
if(rootDir exists, rootDir remove)
rootDir create
show("建后 exists", (Directory with(root)) exists)
show("File isDirectory", (File clone setPath(root)) isDirectory)
list("b.txt", "a.txt", "note.io", "z.txt", "m.txt") foreach(n,
    (File with(Path with(root, n))) setContents("x" asUTF8))
(Directory with(Path with(root, "sub"))) create
dd := Directory with(root)
show("files 直接打出来的顺序（不稳）", (dd files map(f, f name)) asString)
show("files 的 name sort 后", names(dd files))
show("fileNames sort", dd fileNames sort asString)
show("directories 的 name sort", names(dd directories))
show("items 的 name sort（含 . 和 ..）", names(dd items))
show("按后缀 .io 过滤", (dd fileNames select(n, n endsWithSeq(".io")) sort) asString)
show("filesWithExtension(\"txt\")", names(dd filesWithExtension("txt")))
show("fileNamed 不存在时也不给 nil", (dd fileNamed("nope.txt") == nil) asString)
chk("未排序的 readdir 顺序不是字典序", (dd files map(f, f name)) asString == (dd files map(f, f name) sort) asString, false)
chk("排序之后第一个是 a.txt", (dd fileNames sort) at(0), "a.txt")
chk("items 比 fileNames + directories 多两个（. 和 ..）", dd items size, dd fileNames size + dd directories size + 2)

sec("14.8 递归遍历、删除与失败路径")
(File with(Path with(root, "sub", "deep.io"))) setContents("y" asUTF8)
(File with(Path with(root, "sub", "deep.txt"))) setContents("y" asUTF8)
walked := list()
(Directory with(root)) walk(w, walked append(w name .. ":" .. w type asString))
show("walk 递归结果 sort", walked sort asString)
collect := method(dirObj, out,
    dirObj fileNames sort foreach(n, out append(n))
    dirObj directories sort foreach(sd, collect(sd, out))
    out
)
show("手写递归收集所有文件名", collect(Directory with(root), list()) asString)
show("递归 + 只看 .io", (collect(Directory with(root), list()) select(n, n endsWithSeq(".io")) sort) asString)
chk("walk 递归到 8 个条目", walked size, 8)
chk("递归里 .io 有 2 个", (collect(Directory with(root), list()) select(n, n endsWithSeq(".io")) size), 2)
missing := File with(Path with(tmp, "io_tut_14_missing.txt"))
missing remove
e1 := try(missing contents)
show("读不存在的文件抛异常", e1 type asString == "Exception")
show("异常消息前缀（去掉路径）", e1 error exSlice(0, 18))
show("异常消息里含绝对路径", e1 error containsSeq(tmp))
show("File remove 不存在文件不抛异常", (try(missing remove) type asString == "Exception") not)
e2 := try(Directory with(Path with(tmp, "io_tut_14_nodir")) remove)
show("Directory remove 不存在目录抛异常", e2 type asString == "Exception")
dh := File clone setPath(root)
dh openForReading
show("对目录 openForReading 不报错", dh isOpen)
dirRead := try(dh readToEnd)
show("对目录 readToEnd 不抛异常（静默失败）", dirRead type asString != "Exception")
readLen := 0
if(dirRead != nil and dirRead type asString == "Sequence", readLen = dirRead size)
show("从目录「读到」的字节数", readLen)
dh close
(File with(linePath)) remove
try(Directory with(root) remove)
show("整棵目录树删掉后 exists", (Directory with(root)) exists)
show("临时文件还有残留吗", (File clone setPath(ucs4Path)) exists or (File clone setPath(linePath)) exists or (File clone setPath(tmpPath)) exists or (File clone setPath(metaPath)) exists)

sec("14.9 自检")
chk("14 自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 14 结束 ====")
if(fails != 0, System exit(1))
