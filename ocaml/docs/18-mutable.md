# 18 · 可变状态

对应示例：`../examples/14_mutable.ml`

对应示例：`examples/14_mutable.ml`

### 18.1 为什么 OCaml 提供可变状态

OCaml 是一门函数式语言，但它不是纯函数式的。它提供了完整的可变状态机制——引用、可变记录字段、数组、哈希表等等。

为什么一门函数式语言要提供可变状态？有几个原因：

**性能**：有些算法用可变数据结构实现效率高得多。比如数组的随机访问是 O(1)，而列表是 O(n)。在性能敏感的场景下，你需要这些工具。

**便利**：有些问题用命令式方式写更自然。比如累加器、计数器、状态机——当然用纯函数式也能写（用递归 + 参数传递状态），但有时候用可变变量写起来更直接。

**实用主义**：OCaml 的设计哲学是「函数式优先，但不教条」。它相信最好的程序员会根据场景选择最合适的范式。默认是不可变的（函数式），但当你需要可变状态时，语言提供了清晰、明确的工具。

记住这个原则：**优先使用不可变数据，只有在有充分理由时才使用可变状态。**

### 18.2 ref 引用类型

`ref` 是 OCaml 中最基本的可变数据结构。`ref 'a` 表示一个「指向 'a 类型值的可变引用」。

三个基本操作：
- `ref x`：创建一个引用，初始值为 `x`
- `!r`：读取引用 `r` 的当前值（解引用）
- `r := x`：将引用 `r` 的值设为 `x`（赋值）

```ocaml
let counter = ref 0        (* 创建一个引用，初始值为 0 *)
let _ =
  print_int !counter;      (* 0 —— 读取当前值 *)
  counter := 10;           (* 赋值为 10 *)
  print_int !counter       (* 10 *)
```

注意 `!` 不是逻辑非运算符（那是 `not`），而是解引用。`:=` 是赋值运算符。

标准库还提供了两个便捷函数：
- `incr r`：自增，等价于 `r := !r + 1`
- `decr r`：自减，等价于 `r := !r - 1`

```ocaml
let counter = ref 0
let _ =
  incr counter;   (* !counter = 1 *)
  incr counter;   (* !counter = 2 *)
  decr counter;   (* !counter = 1 *)
  Printf.printf "%d\n" !counter
```

`ref` 可以引用任意类型：

```ocaml
let name = ref "Alice"
let _ =
  print_endline !name;    (* "Alice" *)
  name := "Bob";
  print_endline !name     (* "Bob" *)
```

### 18.3 ref 的本质：一个只有一个可变字段的记录

`ref` 不是什么神奇的内置类型。它的定义非常简单：

```ocaml
type 'a ref = { mutable contents : 'a }
```

`ref` 就是一个只有一个字段的记录，而且这个字段是可变的（`mutable`）。

- `ref x` 就是 `{ contents = x }`
- `!r` 就是 `r.contents`
- `r := x` 就是 `r.contents <- x`

你可以自己验证一下：

```ocaml
let r = ref 42
let _ =
  print_int r.contents;     (* 42 —— 直接访问字段 *)
  r.contents <- 100;        (* 直接赋值给字段 *)
  print_int !r              (* 100 *)
```

知道 `ref` 的本质很重要——它帮助你理解 OCaml 的设计哲学：尽量用简单的机制来构造复杂的功能，而不是不断增加特殊语法。

### 18.4 可变记录字段

记录（record）中的字段默认是不可变的。你可以用 `mutable` 关键字声明可变字段。

```ocaml
type person = {
  name : string;           (* 不可变字段 *)
  age : int;               (* 不可变字段 *)
  mutable salary : float;  (* 可变字段 *)
}
```

不可变字段一旦创建就不能修改，可变字段可以随时修改。

```ocaml
let alice = { name = "Alice"; age = 30; salary = 50000.0 }

let _ =
  (* 读取字段 *)
  Printf.printf "%s earns %.2f\n" alice.name alice.salary;
  
  (* 修改可变字段 *)
  alice.salary <- 60000.0;
  Printf.printf "After raise: %.2f\n" alice.salary;
  
  (* 不可变字段不能修改 —— 编译错误 *)
  (* alice.age <- 31 *)
```

可变字段的赋值语法是 `record.field <- new_value`，用 `<-` 而不是 `:=`。

**什么时候用可变记录字段，什么时候用 ref？**

- 如果你有一个数据结构，其中只有一部分字段需要修改——用可变记录字段
- 如果你只需要一个单独的可变变量——用 ref
- 其实 ref 就是带一个可变字段的记录，两者本质上是一样的

### 18.5 Array 数组

列表是不可变的，而且随机访问是 O(n)。如果你需要高效的随机访问和原地修改，就需要数组（Array）。

**创建数组**：

```ocaml
let arr1 = [| 1; 2; 3; 4; 5 |]    (* 字面量语法 *)
let arr2 = Array.make 5 0          (* 长度为 5，初始值都是 0 *)
let arr3 = Array.init 5 (fun i -> i * i)   (* 用函数初始化：[| 0; 1; 4; 9; 16 |] *)
```

**访问元素**：

```ocaml
let arr = [| 10; 20; 30; 40; 50 |]
let _ =
  print_int arr.(0);    (* 10 —— 第一个元素，索引从 0 开始 *)
  print_int arr.(2)     (* 30 *)
```

数组访问用 `arr.(i)` 语法，这是 `Array.get arr i` 的语法糖。

**修改元素**：

```ocaml
let arr = [| 10; 20; 30 |]
let _ =
  arr.(1) <- 200;       (* 把索引 1 的元素改为 200 *)
  print_int arr.(1)     (* 200 *)
```

`arr.(i) <- x` 是 `Array.set arr i x` 的语法糖。

**常用函数**：

```ocaml
let arr = [| 5; 2; 8; 1; 9; 3 |]
let _ =
  Array.length arr;               (* 6 —— 数组长度 *)
  Array.iter print_int arr;       (* 遍历每个元素 *)
  Array.map (fun x -> x * 2) arr; (* 映射：每个元素翻倍 *)
  Array.fold_left (+) 0 arr;      (* 折叠：求和 *)
  Array.sort compare arr;         (* 原地排序：[| 1; 2; 3; 5; 8; 9 |] *)
  Array.to_list arr;              (* 转成列表 *)
  Array.of_list [1; 2; 3]         (* 列表转数组 *)
```

注意 `Array.sort` 是**原地排序**（in-place），它会直接修改数组，而不是返回新数组。这和 `List.sort` 不同——列表不可变，所以 `List.sort` 返回新列表。

### 18.6 Hashtbl 哈希表

哈希表（Hash table）是键值对的可变集合，提供平均 O(1) 的查找、插入、删除操作。

**创建哈希表**：

```ocaml
let table = Hashtbl.create 10    (* 初始容量为 10（只是提示，会自动扩容） *)
```

**添加和查找**：

```ocaml
let _ =
  Hashtbl.add table "alice" 95;    (* 添加键值对 *)
  Hashtbl.add table "bob" 87;
  Hashtbl.add table "charlie" 92;
  
  print_int (Hashtbl.find table "alice");   (* 95 —— 查找 *)
  (* Hashtbl.find table "dave"              找不到会抛出 Not_found 异常 *)
  
  print_bool (Hashtbl.mem table "bob");     (* true —— 检查是否存在 *)
  
  Hashtbl.replace table "alice" 98;         (* 替换（如果键已存在） *)
  Hashtbl.remove table "charlie";           (* 删除 *)
  
  Printf.printf "%d\n" (Hashtbl.length table)   (* 2 —— 元素个数 *)
```

注意 `Hashtbl.add` 和 `Hashtbl.replace` 的区别：
- `add` 是添加新绑定，旧绑定仍然存在（被遮蔽）
- `replace` 是替换已有绑定

大多数时候你应该用 `replace`，除非你特意想要「多层绑定」的行为。

**遍历哈希表**：

```ocaml
(* 遍历所有键值对 *)
Hashtbl.iter (fun k v -> Printf.printf "%s: %d\n" k v) table

(* 收集所有键 *)
let keys = Hashtbl.fold (fun k _ acc -> k :: acc) table []

(* 收集所有值 *)
let values = Hashtbl.fold (fun _ v acc -> v :: acc) table []
```

标准库的 `Hashtbl` 使用的是**结构相等**（`=`）和 `Hashtbl.hash` 作为默认的哈希函数。也就是说，两个内容相同的字符串会被认为是同一个键——这通常是你想要的行为。

### 18.7 Buffer 可变字符串缓冲

OCaml 中的字符串（`string`）是不可变的。如果你需要频繁拼接字符串，比如构建一个长文本，每次拼接都会分配新字符串，效率很低。

`Buffer` 模块提供了可变的字符串缓冲区，类似于 Java 的 `StringBuilder`。

```ocaml
let buf = Buffer.create 100      (* 创建一个初始容量为 100 的缓冲区 *)

let _ =
  Buffer.add_string buf "Hello";
  Buffer.add_char buf ' ';
  Buffer.add_string buf "world";
  Buffer.add_string buf "!";
  let s = Buffer.contents buf in  (* 获取最终字符串 *)
  print_endline s                 (* "Hello world!" *)
```

`Buffer` 的优势是：它内部用一个可扩容的字节数组来存储数据，追加操作是均摊 O(1) 的，比反复字符串拼接高效得多。

### 18.8 物理相等 vs 结构相等

OCaml 中有两种相等性比较，初学者很容易混淆。

**结构相等（=、<>）**：比较两个值的「内容」是否相同。

```ocaml
let _ =
  [1; 2; 3] = [1; 2; 3];    (* true —— 内容相同 *)
  "hello" = "hello";        (* true *)
  [| 1; 2 |] = [| 1; 2 |]   (* true —— 数组的内容相同 *)
```

**物理相等（==、!=）**：比较两个值是否存储在同一块内存地址上。

```ocaml
let _ =
  let a = [1; 2; 3] in
  let b = [1; 2; 3] in
  a == b;                   (* false —— 两个不同的列表对象 *)
  
  let c = a in
  a == c                    (* true —— 同一个对象 *)
```

对于不可变值（整数、字符串、列表），你几乎总是应该用结构相等（`=`）。物理相等（`==`）对于不可变值来说意义不大——因为值不可变，内容相同就够了，它们是不是同一个内存地址不重要。

对于可变值（ref、数组、记录的可变字段），物理相等和结构相等的区别就很重要了：

```ocaml
let _ =
  let r1 = ref 0 in
  let r2 = ref 0 in
  r1 = r2;     (* true —— 内容都是 0，结构相等 *)
  r1 == r2     (* false —— 是两个不同的引用，物理不等 *)
```

如果你想判断「这两个引用是不是同一个引用」（即修改 r1 会不会影响 r2），就用 `==`。如果你只是想判断「它们当前的值是否相同」，就用 `=`。

**Hashtbl 的键比较**：标准库的 `Hashtbl` 默认使用结构相等（`=`）和结构哈希。也就是说，两个内容相同的字符串会被认为是同一个键。这通常是你想要的。但如果你需要物理相等的哈希表（用对象的身份而不是内容做键），可以用 `Hashtbl.Make`  functor 自定义哈希函数。

### 18.9 闭包封装可变状态

第 13 章我们讲过闭包，现在结合可变状态，闭包可以实现更强大的状态封装。

```ocaml
let make_bank_account initial_balance =
  let balance = ref initial_balance in
  object
    method deposit amount =
      if amount > 0 then balance := !balance + amount
      else failwith "deposit amount must be positive"
    method withdraw amount =
      if amount > 0 && amount <= !balance then
        (balance := !balance - amount; amount)
      else failwith "insufficient funds or invalid amount"
    method get_balance = !balance
  end
```

（这个例子用了对象，我们还没讲对象系统，但核心思想是一样的——`balance` 被闭包捕获，外部只能通过方法来访问和修改。）

更简洁的版本，用闭包返回多个函数：

```ocaml
let make_counter () =
  let count = ref 0 in
  let increment () = incr count in
  let get () = !count in
  let reset () = count := 0 in
  (increment, get, reset)

(* 使用 *)
let inc, get, reset = make_counter ()
let _ =
  inc (); inc (); inc ();
  Printf.printf "%d\n" (get ());   (* 3 *)
  reset ();
  Printf.printf "%d\n" (get ())    (* 0 *)
```

这种模式的好处是：`count` 完全被封装在闭包内部，外部无法直接访问，只能通过你提供的接口函数来操作。这是一种轻量级的封装方式，不需要定义模块和签名。

### 18.10 为什么 OCaml 不鼓励可变状态但又提供它

你可能会问：既然函数式编程推崇不可变，为什么 OCaml 还要提供 `ref`、`Array`、`Hashtbl` 这些可变数据结构？

答案是**实用主义**。OCaml 的设计者认为：

1. **默认不可变是对的**：大多数代码用不可变数据写更清晰、更容易推理、更少 bug
2. **但有时候你确实需要可变**：性能、算法复杂度、与外部世界交互（I/O）
3. **让可变状态显式化**：可变的东西需要特殊语法（`:=`、`<-`、`!`），一眼就能看出来哪里有副作用

所以 OCaml 的策略是：默认不可变，可变需要明确写出来。你可以从代码中一眼看出哪些地方有副作用——那些 `:=`、`<-`、`!` 就是「危险信号」。

这和 Java 正好相反——Java 中默认是可变的，你需要加 `final` 才能让东西不可变。结果就是 Java 代码中到处都是可变状态，你根本不知道哪里会修改东西。

### 18.11 本章小结

- `ref` 是最基本的可变引用：`ref x` 创建，`!r` 读取，`r := x` 赋值
- `ref` 的本质是一个带可变字段的记录 `{ mutable contents : 'a }`
- 记录字段默认不可变，用 `mutable` 声明可变字段，赋值用 `<-`
- `Array` 提供 O(1) 随机访问和原地修改，用 `arr.(i)` 访问，`arr.(i) <- x` 修改
- `Hashtbl` 是可变的键值对集合，平均 O(1) 查找插入
- `Buffer` 是可变字符串缓冲，适合频繁拼接的场景
- 结构相等 `=` 比较内容，物理相等 `==` 比较内存地址
- 对于不可变值用 `=`，要判断是否是同一个可变对象时用 `==`
- 闭包可以封装可变状态，实现轻量级的信息隐藏
- OCaml 默认不可变，可变需要显式语法，让副作用一目了然

---

---
上一章：[17 · 模块系统进阶](modules-advanced.md) ｜ 下一章：[19 · 排序与经典算法](algorithms.md) ｜ 返回：[README](../README.md)
