# 23 · Slint 综合实战：待办管理器

> 对应示例：[examples/23_slint_app](../examples/23_slint_app)

## 23.1 三份答卷到齐

同一规格的待办管理器，第 23 章交出 Slint 版：

| 规格 | egui（09） | iced（16） | Slint（本章） |
|---|---|---|---|
| 列表 | ScrollArea 急切 | scrollable 急切 | **ListView 虚拟化** |
| 添加 | TextEdit + Enter | text_input.on_submit | LineEdit `accepted` |
| 勾选 | checkbox 当场改 | checkbox 消息 | **点行 TouchArea + 划线动画** |
| 删除 | 相对查询找按钮 | 唯一命名按钮 | `for todo[i]` 的索引回调 |
| 持久化 | —— | 订阅心跳节流 | 回调即时落盘 |

## 23.2 划线动画：states/animate 的实战

完成一条待办，红色划线从 0 撑满文字宽——纯声明式：

```slint
// ═══ 23.1 行模板：文字 + 划线层 ═══
TouchArea {
    clicked => { root.toggle(i); }
    line-holder := Rectangle {
        width: todo-text.width;         // 裹住文字
        todo-text := Text {
            text: todo.text;
            color: todo.done ? #999 : #111;
        }
        Rectangle {                      // 划线层
            y: parent.height / 2;
            height: 2px;
            width: todo.done ? parent.width : 0px;  // done 时撑满
            background: #e53935;
            animate width { duration: 200ms; easing: ease-out; }
        }
    }
}
```

注意三目里 `parent.width` 与 `0px` 都是 length——写 `100%` 会因 percent/length 类型不混而编译错（本章实测坑）。

## 23.3 输入与持久化

```slint
// ═══ 23.2 输入：edited 存草稿，accepted 提交 ═══
draft-input := LineEdit {
    placeholder-text: "新待办…";
    text: root.draft;                     // 草稿是根属性（Rust 读得到）
    edited(t)   => { root.draft = t; }
    accepted(t) => { root.add(t); root.draft = ""; }  // 回车即提交
}
Button { text: "添加"; clicked => { root.add(root.draft); root.draft = ""; } }
```

持久化走"**模型即数据源**"：slint 生成类型不带 serde，Rust 侧用平行的 `TodoRow` 做序列化载体；每个回调（add/toggle/remove）末尾即时 `save`——比 16 章的心跳节流更简单直接，代价是高频操作时写盘多（真实应用可改 dirty + 定时器合并，思路同 16）。

```rust
// ═══ 23.3 即时落盘（wire 里的统一尾部）═══
model.push(Todo { text: text.into(), done: false });
refresh_count(&app, &model);   // done-count 是 Rust 算的（.slint 聚合不了模型内容）
let _ = save(&model, &path);   // 序列化 VecModel → JSON → 文件
```

## 23.4 无头剧本：三份考卷的最后一份

```rust
// ═══ 23.4 输入→点行→删除→持久化往返 ═══
input.set_accessible_value("写综合实战");   // a11y 输入（18 章通道）
app.invoke_add(app.get_draft());           // accepted 的等价调用

let row = ElementHandle::find_by_accessible_label(&app, "写综合实战")
    .next().expect("找行文本");
send_mouse_click(row.absolute_position().x + 10.0, ..);  // 几何点行 → toggle

let dels = /* 类型名查 Button + 标签过滤"删" */;
send_mouse_click(dels.last().absolute_position()...);     // 删最后一条

let saved_len = fs::read_to_string(&path)?.len();         // 回调已即时落盘
assert_eq!(load(&path).len(), 2);                         // 重启读档一致
```

九处对照点全部机器判定：模型条数、done 计数、划线状态（模型侧）、落盘字节数、读档往返。**同一张考卷，三份答卷的判卷标准完全一致**——这就是 24 章横评的底座。

## 23.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 23_slint_app
```

实测输出（`build/23_slint_app.run.out`）：

```text
==== 23 slint 待办管理器 开始 ====
items=2 done=1 saved=84 bytes
==== 23 slint 待办管理器 结束 ====
```

真窗口里打字回车添加、点行看划线动画划过、删行、重开应用——条目都在（启动读档）。

## 坑位清单

- **percent 与 length 不混**：`width: cond ? 100% : 0px` 编译错（"Cannot convert length to percent"）——用 `parent.width` 与 `0px` 同类型。
- **slint 生成类型不带 serde**：持久化要 Rust 侧平行结构（`TodoRow`）+ `From` 转换；想直接序列化生成类型是没有的。
- **done-count 这类模型聚合 Rust 算**：`todos.length` 内建，但"数 done 的条数"表达式做不了——每次变更后 `refresh_count`（忘了就是状态栏永远不动）。
- **划线层要"裹住"文字**：直接把划线放 Text 旁边会拿不到文字宽度——包一层 `Rectangle { width: text.width }`，划线在其中 `parent.width`。
- **高频操作 × 即时落盘**：每次按键级回调都写盘对 SSD 无害但语义粗糙——产品化改 dirty+节流（16 章模式），教程取简单。

---

上一章：[22 · Slint 模型与 ListView](22-slint-models.md) ｜ 下一章：[24 · 三框架横评与选型](24-comparison.md) ｜ 返回：[README](../README.md)
