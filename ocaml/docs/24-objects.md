# 24 · 记录、对象与类

对应示例：`../examples/20_records.ml`

对应示例：`examples/20_records.ml`

第 6 章讲过记录基础，第 18 章讲过可变状态。这一章把两条线接起来：先回顾记录的高级用法——参数位置解构、嵌套更新、参数化记录、函数字段，然后进入 OCaml 的对象系统：`object` 字面量、`class` 类、`inherit` 继承、结构子类型 `:>`。24.9 的「实测坑」是本教程在 `20_records.ml` 里真实修过的类型错误，值得细读。

### 24.1 记录高级用法回顾

```ocaml
type point = { x : float; y : float }

let p3 = { p1 with y = 5.0 }             (* 函数式更新，p1 不变 *)
let p4 = { p1 with x = 10.0; y = 20.0 }  (* 同时改多个字段 *)
```

一个实测细节：`p4` 把 `point` 的全部字段都列了出来，OCaml 5.x 会给 `Warning 23 [useless-record-with]`——都全量覆盖了，不如直接写 `{ x = 10.0; y = 20.0 }`。示例文件里有两处触发此警告（`p4` 和下面 `move_rect` 的内层更新），编译时能看到。

模式匹配可以直接在参数位置解构记录，比 `let ... in` 逐个拆干净：

```ocaml
let distance2 { x = x1; y = y1 } { x = x2; y = y2 } =
  sqrt ((x2 -. x1) ** 2. +. (y2 -. y1) ** 2.)
```

嵌套记录的函数式更新要层层 `with`：

```ocaml
type rectangle = { top_left : point; width : float; height : float }

let move_rect dx dy rect =
  { rect with
    top_left = { rect.top_left with
      x = rect.top_left.x +. dx;
      y = rect.top_left.y +. dy
    }
  }
```

记录类型可以带类型参数（参数化记录），一个类型多种用途：

```ocaml
type 'a labeled = {
  label : string;
  value : 'a;
}

let int_labeled = { label = "count"; value = 42 }
let str_labeled = { label = "name";  value = "Alice" }
```

这和第 4 章的值限制是一体两面：`{ value = 42 }` 是不可泛化的值，`int_labeled` 被钉死在 `int labeled`；只有函数（如示例的 `print_labeled`）能保持多态。

### 24.2 可变记录：封装状态的经典手法

字段加 `mutable` 就能用 `<-` 赋值。这是 OCaml 里「有状态的数据」最常用的形态——比 `ref` 清晰（多字段一个绑定搞定），比对象轻量：

```ocaml
type counter = {
  mutable count : int;
  mutable step : int;
}

let make_counter ?(step = 1) start = { count = start; step }

let next c =
  let current = c.count in
  c.count <- c.count + c.step;
  current
```

更典型的例子是玩家状态：不可变字段与可变字段混搭：

```ocaml
type player = {
  name : string;                          (* 不可变 *)
  mutable hp : int;                       (* 可变：生命值 *)
  mutable level : int; mutable exp : int; (* 可变：等级、经验 *)
  mutable inventory : string list;
}

let take_damage player amount =
  player.hp <- max 0 (player.hp - amount);
  player.hp = 0  (* 返回是否死亡 *)
```

示例里的 `gain_exp` 是这类代码的范式：先累加经验、比较阈值，够了一步扣减并升级——状态变化集中在一处，外部看到的仍然是普通记录值。

### 24.3 函数字段：让记录模拟对象

记录的字段可以是函数。把一组操作打包进记录，就得到「接口 + 闭包状态」的迷你对象，不需要任何对象语法：

```ocaml
type 'a stack_ops = {
  push : 'a -> unit;
  pop : unit -> 'a;
  is_empty : unit -> bool;
  size : unit -> int;
  to_list : unit -> 'a list;
}

let make_stack () =
  let data = ref [] in
  {
    push = (fun x -> data := x :: !data);
    pop = (fun () ->
      match !data with
      | [] -> failwith "Stack.pop: empty"
      | h :: t -> data := t; h);
    is_empty = (fun () -> !data = []);
    size = (fun () -> List.length !data);
    to_list = (fun () -> List.rev !data);
  }
```

（示例的接口还有 `peek : unit -> 'a`，实现与 `pop` 同构，这里略去。）

私有状态（`data`）被闭包捕获，外部只能通过六个函数字段访问——这就是封装。

更有说服力的是「一个接口、多种实现」。示例定义了 `('k, 'v) dict_ops`（字段为 `get`/`set`/`mem`/`remove`/`size`/`keys`），然后给了两个实现——基于关联表的 `make_alist_dict`：

```ocaml
let make_alist_dict () =
  let data = ref [] in
  {
    get = (fun k -> List.assoc k !data);
    set = (fun k v -> data := (k, v) :: List.remove_assoc k !data);
    mem = (fun k -> List.mem_assoc k !data);
    remove = (fun k -> data := List.remove_assoc k !data);
    size = (fun () -> List.length !data);
    keys = (fun () -> List.map fst !data);
  }
```

`make_hashtbl_dict` 结构完全相同，只是六个字段换成 `Hashtbl.find/replace/mem/remove/length/fold`。示例用同一个 `test_dict` 先后测试两种实现——它们类型一致，可随意替换。这正是第 15 章 functor 所解决问题的轻量版：接口小、只有一个类型参数时，函数字段记录通常比 functor 顺手。

### 24.4 对象字面量：object ... end

OCaml 有完整的对象系统。`object ... end` 直接创建对象值：`val`/`val mutable` 声明实例变量，`method` 声明方法，调用用 `#`：

```ocaml
let point_obj = object
  val mutable x = 0.0
  val mutable y = 0.0

  method get_x = x
  method get_y = y

  method move dx dy = x <- x +. dx; y <- y +. dy

  method distance_to other =
    let dx = x -. other#get_x in
    let dy = y -. other#get_y in
    sqrt (dx *. dx +. dy *. dy)

  method to_string = Printf.sprintf "(%.2f, %.2f)" x y
end
```

使用：`point_obj#move 3.0 4.0`、`point_obj#get_x`。注意实例变量赋值用 `<-`（与可变记录字段相同），方法调用用 `#`（不是 `.`）。

两个细节：

1. **实例变量与方法可以重名**。24.6 的 `rectangle_class` 里 `val width = w` 加 `method width = width`——方法体里的 `width` 指实例变量，对外暴露的是方法。
2. **`initializer`** 在对象构造完成时执行一次；外层函数的参数就是「构造参数」——每次调用产生一个新对象，各自独立：

```ocaml
let p2_obj = object
  val mutable x = 0.0
  val mutable y = 0.0
  method get_x = x
  method get_y = y
  initializer x <- 10.0; y <- 5.0
end
```

示例的 `bank_account` 是「函数即构造参数」的完整版：`let bank_account initial = object ... end`，`deposit`/`withdraw` 方法维护 `balance` 和 `transactions`（多态变体流水），每调用一次得到一个独立账户，`statement` 方法拼对账单。需要 `self`（方法里调自己的其他方法）时写 `object (self)`，24.6 的 `rectangle_class` 会用到。

### 24.5 对象类型与开放类型 `< ... ; .. >`

对象类型由「它有哪些方法」决定，与它是谁、从哪个类来无关（结构类型）。`point_obj` 的推断类型是：

```ocaml
< get_x : float; get_y : float;
  move : float -> float -> unit;
  distance_to : < get_x : float; get_y : float; .. > -> float;
  to_string : string >
```

注意 `distance_to` 的参数类型：`< get_x : float; get_y : float; .. >`。末尾的 `..` 是**开放类型**（row 变量），意思是「至少有 `get_x` 和 `get_y`，别的随便」。所以示例里 `point_obj#distance_to p2_obj` 成立——`p2_obj` 只有 `get_x`/`get_y` 两个方法，类型与 `point_obj` 并不相同，但结构上满足要求。这正是对象版的「鸭子类型」，而且由类型检查器静态验证。对单个函数参数，开放类型自动生效；24.8 会看到列表场景下为什么还需要显式 `:>`。

### 24.6 class：对象的模板

`object ... end` 每次写一遍太重复。`class` 把对象提炼成模板，`new` 实例化——类参数替代了「外层函数当构造参数」的技巧：

```ocaml
class point_class init_x init_y = object
  val mutable x = init_x
  val mutable y = init_y
  method get_x = x
  method get_y = y
  method move dx dy = x <- x +. dx; y <- y +. dy
  method to_string = Printf.sprintf "(%.2f, %.2f)" x y
end

let pt1 = new point_class 1.0 2.0
let pt2 = new point_class 4.0 6.0
```

`pt1#move 2.0 3.0` 之后 `pt2` 不受影响——每个实例有自己的实例变量。类参数还支持可选参数，注意可选参数后要跟一个 `()` 占位，否则无法确定取参何时结束（用法：`new counter_class ~init:100 ~step_val:10 ()`）：

```ocaml
class counter_class ?(init = 0) ?(step_val = 1) () = object
  val mutable count = init
  val mutable step = step_val

  method next =
    let current = count in
    count <- count + step;
    current

  method reset = count <- 0
  method get_count = count
end
```

类体里还可以 `new` 别的类做组合。矩形类内部持有一个点对象，把移动委托出去：

```ocaml
class rectangle_class x y w h = object (self)
  val top_left = new point_class x y
  val width = w
  val height = h

  method width = width          (* 实例变量与方法重名 *)
  method area = width *. height

  method move dx dy = top_left#move dx dy

  method contains : 'a. (< get_x : float; get_y : float; .. > as 'a) -> bool =
    fun pt ->
      let px = pt#get_x and py = pt#get_y in
      let tx = top_left#get_x and ty = top_left#get_y in
      px >= tx && px <= tx +. width &&
      py <= ty && py >= ty -. height

  method to_string =
    Printf.sprintf "Rect[top-left=%s, w=%.2f, h=%.2f, area=%.2f]"
      top_left#to_string width height self#area
end
```

`contains` 的方法标注先跳过，24.9 专门讲它为什么必须写成长这样。`to_string` 里的 `self#area` 则是 `object (self)` 的用途：类体里调自己的方法。

### 24.7 继承：inherit 与 super

`inherit` 让一个类获得另一个类的全部实例变量与方法：

```ocaml
class shape name = object (self)
  val name = name
  method name = name
  method area = 0.0  (* 子类会覆盖 *)
  method describe = Printf.sprintf "Shape '%s', area: %.2f" name self#area
end

class circle name radius = object (self)
  inherit shape name as super
  val radius = radius
  method area = 3.1415926535 *. radius *. radius
  method describe =
    Printf.sprintf "Circle '%s', radius: %.2f, area: %.2f" name radius self#area
end
```

要点：

1. **方法覆盖即重定义**。子类里重新写 `method area = ...` 就覆盖了父类版本，不需要任何关键字。
2. **`inherit ... as super` 给父类起别名**。`self#m` 是动态派发——按对象实际类型调用最终覆盖版；`super#m` 是静态派发——明确调父类版本。`movable_point` 两者配合实现动画步进（`rectangle_shape`、两层继承的 `square` 与此同构，完整代码见示例）：

```ocaml
class movable_point x y = object
  inherit point_class x y as super

  val mutable speed_x = 0.0
  val mutable speed_y = 0.0

  method set_speed sx sy = speed_x <- sx; speed_y <- sy

  method tick dt =
    super#move (speed_x *. dt) (speed_y *. dt)
end
```

最后补一个示例里没用到的语法：**虚方法**。`class virtual` 定义不能实例化的抽象类，`method virtual` 声明必须被子类实现的方法：

```ocaml
class virtual shape_base = object
  method virtual area : float
end

class real_shape name = object
  inherit shape_base
  method area = 3.0
end
```

`new shape_base` 直接报错；虚方法的类型必须显式标注——原因见下一节。

### 24.8 结构子类型与 `:>`

OCaml 的子类型是**结构性的**：不看血缘，只看方法集合。任何有 `area` 方法的对象都能传给下面这个函数，无论它继承自谁、甚至是不是类的实例：

```ocaml
let print_area obj =
  Printf.printf "  Area: %.2f\n" obj#area
```

`print_area s1`（circle）、`print_area s2`（rectangle_shape）、`print_area s3`（shape）全部成立——参数类型被推断为 `< area : float; .. >`，开放类型自动匹配，这就是行多态。

但列表是另一回事：列表所有元素必须类型**完全相同**，行多态帮不上忙。`circle` 的对象和 `rectangle_shape` 的对象互不为子类型，直接混装会报类型错误。这时用强制转换 `:>` 把它们弱化到公共类型：

```ocaml
let shapes : shape list = [
  (s1 :> shape);   (* circle           -> shape *)
  (s2 :> shape);   (* rectangle_shape  -> shape *)
  (s3 :> shape);
]

List.iter (fun s -> Printf.printf "  %s\n" s#describe) shapes
```

两条规则记牢：

- `:>` 的方向是「子到父」，只能丢方法、不能加方法；丢弃的方法在目标类型里不可见（本例丢掉了子类特有的 `radius`、`describe` 覆盖版等，列表里只剩 `shape` 的方法）。
- 目标必须是**闭合**的对象类型（如 `shape`，没有 `..`）。转成开放类型 `< area : float; .. >` 不允许——那是行多态该干的活，不需要转换。

### 24.9 实测坑：class 方法里的开放对象类型

这是 `20_records.ml` 开发时真实踩过、在 OCaml 5.4.1 下实测复现的编译错误。

**踩坑过程**。`rectangle_class` 的 `contains` 方法想接受「任何有 `get_x`/`get_y` 的对象」，最自然的写法是不加标注，让类型推断自己推出开放类型：

```ocaml
(* 错误写法 *)
method contains pt =
  let px = pt#get_x and py = pt#get_y in
  let tx = top_left#get_x and ty = top_left#get_y in
  px >= tx && px <= tx +. width &&
  py <= ty && py >= ty -. height
```

编译失败（原样照录，中间字段以 `...` 略）：

```text
Error: Some type variables are unbound in this type:
         class rectangle_class :
           float -> float -> float -> float ->
           object
             ...
             method contains : < get_x : float; get_y : float; .. > -> bool
           end
       The method contains has type
         (< get_x : float; get_y : float; .. > as 'a) -> bool
       where 'a is unbound
```

**原理**。错误信息最后两行是关键：推断出的方法类型是 `(< get_x : float; get_y : float; .. > as 'a) -> bool`，其中 `'a` 就是开放类型里那个 `..`（row 变量）的内部名字——一个未绑定的类型变量。

为什么普通 `let` 不报错、`method` 就报错？两者的泛化规则不同：

- **值绑定会自动泛化**。`let contains pt = ...` 满足值限制（是函数），类型检查器自动把 `'a` 全称量化成 `'a. (< ... ; .. > as 'a) -> bool`，开放类型合法。
- **class 定义不做这种隐式泛化**。类体作为整体定型，类类型里出现的方法类型必须闭合；多态方法必须由程序员显式写出全称量化的标注，否则其中的类型变量一律算 unbound。这个设计是为了避免类类型推断的歧义——类会被继承、被实例化多次，隐式泛化会让一个笔误扩散到所有子类。

**修法**。给方法加显式多态标注，把 row 变量用 `as 'a` 命名后交给 `'a.` 量化：

```ocaml
(* 正确写法（示例 20_records.ml 第 540 行起） *)
method contains : 'a. (< get_x : float; get_y : float; .. > as 'a) -> bool =
  fun pt ->
    let px = pt#get_x and py = pt#get_y in
    let tx = top_left#get_x and ty = top_left#get_y in
    px >= tx && px <= tx +. width &&
    py <= ty && py >= ty -. height
```

逐块拆开：

- `'a. (...)` —— 显式全称量化：「对所有可能的 `'a`」。这就是普通 `let` 自动帮你做的那一步。
- `< get_x : float; get_y : float; .. > as 'a` —— `as 'a` 把整个开放对象类型（含 `..`）绑定到名字 `'a`，使它可以被量化。没有 `as 'a`，`..` 仍是匿名变量，照样 unbound。
- 方法体要写成 `fun pt -> ...` —— 标注给出了方法的完整类型，等号右边就是该类型的值，参数由 `fun` 引入。

**同一错误的另一副面孔**。实测发现：把 `point_class` 里的 `move` 和 `to_string` 删掉（即没有任何 `+.`/`%.2f` 把 `init_x`/`init_y` 钉死为 `float`），class 本身就会报同一个 `Some type variables are unbound`（`The method get_x has type 'a where 'a is unbound`）——类参数保持完全多态，类类型里就出现未绑定变量。修法要么在用法里钉死类型（示例正是靠 `move` 里的 `+.` 把 `x` 定为 `float`），要么给类参数加标注（`class point_class (init_x : float) ...`）。**经验法则：写 class 时多写显式类型标注**——对象系统不像 `let` 那样替你泛化，标注是它要求的正常写法，不是画蛇添足。

### 24.10 对象、记录、模块：怎么选

OCaml 里表达「数据 + 操作」至少有三条路，选型建议：

| 场景 | 推荐 | 理由 |
|------|------|------|
| 纯数据，字段固定 | 记录 | 模式匹配、`with` 更新，类型推断最省事 |
| 有状态的小对象（计数器、缓存） | 可变记录 | 比 `ref` 清晰，比对象轻量（24.2） |
| 接口 + 多实现，状态简单 | 函数字段记录 | 一个 `make_xxx` 函数搞定（24.3） |
| 接口 + 多实现，类型抽象要求高 | 模块 + functor | 第 14-16 章的工具，能隐藏类型 |
| 深层继承、开放递归（`self`）、运行时异构集合 | class / object | 只有对象系统提供这些 |

实践中的倾向：OCaml 社区用对象很少，标准库里几乎没有（`Oo` 模块只是运行时支持），主要使用者是 lablgtk（GTK 绑定）、OCamlGraph 这类把对象模型映射过来的库。原因不难体会——对象让推断变弱（24.9 的标注负担）、方法调用比直接函数调用慢，而记录 + 模块能覆盖绝大多数需求。对象真正不可替代的是开放递归（子类覆盖方法后，父类里经 `self` 调用的也是新版本）和 24.8 的异构集合。判断标准：需要「多种运行时可互换的实现且要在集合里混装」时用对象；否则优先记录和模块。

### 24.11 本章小结

- 记录高级用法：参数位置解构、嵌套 `with` 层层更新、`'a` 参数化记录（与值限制一体两面）
- 可变记录是封装状态的首选：`mutable` 字段 + `<-` 赋值，不可变与可变字段可混搭
- 函数字段让记录模拟对象：闭包捕获私有状态，「一个接口、多种实现」的轻量方案
- `object ... end`：`val`/`val mutable` 状态、`method` 行为、`#` 调用、`initializer`、`object (self)`
- 对象类型是结构性的；开放类型 `< ... ; .. >` 是静态检查的鸭子类型，函数参数自动行多态
- `class` + `new`：类参数、可选参数（后跟 `()`）、`new` 组合；`inherit ... as super` 继承并覆盖方法，`self#` 动态派发、`super#` 静态派发；`class virtual`/`method virtual` 定义抽象
- 结构子类型 `:>` 只能把对象弱化到闭合类型，用于异构列表；日常参数匹配交给行多态
- 实测坑：class 方法里用开放对象类型报 `Some type variables are unbound`——class 不做隐式泛化，必须显式写 `'a. (< ... ; .. > as 'a) -> ...` 多态方法标注；类参数完全多态时同样触发
- 选型顺序：记录 → 函数字段记录 / 模块 → 对象；对象留给开放递归和运行时异构集合

---

---
上一章：[23 · 测试与断言](testing.md) ｜ 下一章：[25 · 流与序列](streams.md) ｜ 返回：[README](../README.md)
