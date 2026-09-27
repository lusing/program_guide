# 23 · 测试与断言

对应示例：`../examples/19_testing.ml`

对应示例：`examples/19_testing.ml`

### 23.1 为什么需要测试

你写了一个函数，怎么知道它是对的？

「我试了几个例子，都对」——这不够。你可能漏掉了边界情况，可能你的例子恰好覆盖不到 bug。

测试是软件工程中保证质量的基本手段。它的核心价值：

1. **验证正确性**：确保代码按预期工作
2. **防止回归**：修改代码后，确保没有破坏已有的功能
3. **文档作用**：测试用例是代码行为的活文档
4. **设计反馈**：难以测试的代码往往设计也有问题

在函数式语言中，测试尤其重要——因为函数是纯的（相同输入总是产生相同输出），写测试非常自然。

### 23.2 简单断言函数的实现

断言（assertion）是测试的基本单元：检查一个条件是否为真，如果不为真就报错。

```ocaml
let assert_equal expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "assertion failed: expected %s, got %s"
                (string_of_int expected) (string_of_int actual))
```

这个版本只能比较整数，而且错误信息很简陋。我们来改进一下。

更通用的方式是让调用者提供比较函数和打印函数：

```ocaml
let assert_equal ~equal ~to_string expected actual =
  if not (equal expected actual) then
    failwith (Printf.sprintf "assertion failed:\n  expected: %s\n  got:      %s"
                (to_string expected) (to_string actual))
```

使用方式：

```ocaml
let _ =
  assert_equal ~equal:(=) ~to_string:string_of_int 3 (1 + 2);
  assert_equal ~equal:(=) ~to_string:String.capitalize_ascii "Hello" (String.capitalize_ascii "hello")
```

这种方式灵活，但每次都要传 `equal` 和 `to_string` 有点繁琐。我们可以为常见类型写专用的断言函数。

### 23.3 各种类型的断言

为常用类型定义专用的断言函数，用起来更方便。

**整数断言**：

```ocaml
let check_int expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "check_int failed: expected %d, got %d"
                expected actual)
```

**布尔断言**：

```ocaml
let check_bool expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "check_bool failed: expected %b, got %b"
                expected actual)
```

**字符串断言**：

```ocaml
let check_string expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "check_string failed:\n  expected: %S\n  got:      %S"
                expected actual)
```

**列表断言**：

```ocaml
let check_list ~equal expected actual =
  let rec loop a b =
    match (a, b) with
    | ([], []) -> true
    | (x :: xs, y :: ys) -> equal x y && loop xs ys
    | _ -> false
  in
  if not (loop expected actual) then
    failwith (Printf.sprintf "check_list failed: lists have different content or length")
```

**带 to_string 的列表断言**（更好的错误信息）：

```ocaml
let check_list_str ~to_string expected actual =
  let rec loop a b i =
    match (a, b) with
    | ([], []) -> ()
    | ([], _) ->
        failwith (Printf.sprintf "check_list failed at index %d: expected list is shorter" i)
    | (_, []) ->
        failwith (Printf.sprintf "check_list failed at index %d: actual list is shorter" i)
    | (x :: xs, y :: ys) ->
        if x <> y then
          failwith (Printf.sprintf "check_list failed at index %d:\n  expected: %s\n  got:      %s"
                      i (to_string x) (to_string y))
        else loop xs ys (i + 1)
  in
  loop expected actual 0
```

好的断言函数应该提供：
- 清晰的错误信息（哪个测试失败了）
- 期望值和实际值（方便对比）
- 位置信息（哪个索引、哪个字段出了问题）

### 23.4 浮点数断言的特殊性

浮点数不能直接用 `=` 比较，因为有精度问题。浮点数断言需要用 epsilon 比较。

```ocaml
let check_float ?(epsilon = 1e-9) expected actual =
  let diff = abs_float (expected -. actual) in
  if diff > epsilon && 
     diff > epsilon *. max (abs_float expected) (abs_float actual) then
    failwith (Printf.sprintf "check_float failed:\n  expected: %.10g\n  got:      %.10g\n  diff:     %.10g"
                expected actual diff)
```

这里用了「绝对误差 + 相对误差」的组合判断：
- 当数值很小时，用绝对误差（`diff > epsilon`）
- 当数值很大时，用相对误差（`diff > epsilon * max(|expected|, |actual|)`）

这比单纯的绝对误差更合理，因为浮点数的精度是相对的——大数的绝对误差大但相对误差可能很小。

还要注意 nan 的处理：nan 不等于任何东西，包括它自己。如果 expected 或 actual 是 nan，上面的比较会有问题。一个完善的浮点数断言应该单独处理 nan。

### 23.5 异常断言：检查是否抛出预期异常

有时候你想测试「这个函数在某种情况下应该抛出某个异常」。比如除法函数在除以零时应该抛出 `Division_by_zero`。

```ocaml
let check_raises expected_exn f =
  try
    let _ = f () in
    failwith "check_raises failed: no exception was raised"
  with exn ->
    if exn <> expected_exn then
      failwith (Printf.sprintf "check_raises failed: expected %s, got %s"
                  (Printexc.to_string expected_exn)
                  (Printexc.to_string exn))
```

使用方式：

```ocaml
let _ =
  (* 测试除以零应该抛出 Division_by_zero *)
  check_raises Division_by_zero (fun () -> 1 / 0);
  
  (* 测试 List.hd 空列表应该抛出 Failure *)
  check_raises (Failure "hd") (fun () -> List.hd [])
```

注意 `f` 是一个 `unit -> ...` 的函数——我们把要测试的表达式包在 `fun () -> ...` 里，这样 `check_raises` 可以控制什么时候执行它。如果直接写 `1 / 0`，表达式会在 `check_raises` 调用之前就求值并抛出异常了。

### 23.6 测试框架雏形

当测试越来越多时，你需要一个框架来组织和管理它们。我们来搭建一个简单的测试框架。

```ocaml
type test_case = {
  name : string;
  run : unit -> unit;   (* 抛出异常表示失败 *)
}

type test_suite = {
  suite_name : string;
  tests : test_case list;
}

let test name f = { name; run = f }

let suite name tests = { suite_name = name; tests }

let run_test t =
  try
    t.run ();
    (t.name, true, None)
  with exn ->
    (t.name, false, Some (Printexc.to_string exn))

let run_suite s =
  Printf.printf "\n=== %s ===\n" s.suite_name;
  let results = List.map run_test s.tests in
  let passed = List.filter (fun (_, ok, _) -> ok) results in
  let failed = List.filter (fun (_, ok, _) -> not ok) results in
  List.iter (fun (name, ok, err) ->
    if ok then
      Printf.printf "  PASS: %s\n" name
    else
      Printf.printf "  FAIL: %s\n    %s\n" name (Option.get err)
  ) results;
  Printf.printf "  Result: %d passed, %d failed, %d total\n"
    (List.length passed) (List.length failed) (List.length results);
  (List.length failed = 0)
```

使用示例：

```ocaml
let math_tests = suite "Math" [
  test "addition" (fun () ->
    check_int 5 (2 + 3)
  );
  test "subtraction" (fun () ->
    check_int (-1) (2 - 3)
  );
  test "multiplication" (fun () ->
    check_int 6 (2 * 3)
  );
]

let list_tests = suite "List" [
  test "length of empty" (fun () ->
    check_int 0 (List.length [])
  );
  test "length of cons" (fun () ->
    check_int 3 (List.length [1; 2; 3])
  );
  test "hd of empty raises" (fun () ->
    check_raises (Failure "hd") (fun () -> List.hd [])
  );
]

let _ =
  let ok1 = run_suite math_tests in
  let ok2 = run_suite list_tests in
  if ok1 && ok2 then
    print_endline "\nAll tests passed!"
  else
    print_endline "\nSome tests failed!"
```

这个简单的框架已经具备了基本功能：组织测试用例、运行测试、报告结果。

实际项目中，你应该使用成熟的测试框架，比如：
- **Alcotest**：轻量级测试框架，社区最常用
- **OUnit2**：另一个流行的测试框架
- **Crowbar**：属性测试框架

### 23.7 属性测试（Property-based Testing）简介

普通测试（也叫「基于示例的测试」）是这样的：你写几个具体的输入输出例子，然后验证函数对这些输入给出正确的输出。

属性测试（property-based testing）是另一种思路：你描述函数应该满足的**性质**，然后测试框架自动生成大量随机输入来验证这些性质。

比如，对于一个排序函数，你可以说：
- 性质 1：排序后的列表长度和原来相同
- 性质 2：排序后的列表是有序的（每个元素 <= 下一个元素）
- 性质 3：排序后的列表和原列表包含相同的元素（多重集相等）
- 性质 4：已经排序的列表再排序，结果不变（幂等性）

如果你的排序函数满足所有这些性质，那它很可能是对的——比你手动写三五个测试用例有说服力得多。

OCaml 生态中常用的属性测试库：
- **QCheck**：最流行的属性测试库，支持 Alcotest 和 OUnit
- **Crowbar**：基于 AFL 的模糊测试 + 属性测试

属性测试特别适合：
- 数据结构（验证不变量）
- 编解码（编码再解码应该得到原值）
- 数学函数（验证代数性质）
- 解析器（解析再打印应该得到等价的结果）

### 23.8 TDD 在函数式语言中的应用

测试驱动开发（Test-Driven Development，TDD）的流程是：
1. 先写一个会失败的测试
2. 写最少的代码让测试通过
3. 重构代码，保持测试通过

TDD 在函数式语言中特别自然，因为：
- 函数是纯的，测试不需要 setup/teardown
- 类型系统已经帮你保证了很多东西，测试可以集中在业务逻辑上
- 函数式代码通常更容易测试（依赖少、副作用少）

但 TDD 不是银弹。在函数式语言中，类型系统本身就是一种「编译时测试」——很多错误在类型检查阶段就被发现了，不需要写测试。

所以函数式语言中的测试策略通常是：
1. **先用类型系统保证正确**：让非法状态不可表示
2. **再测试核心业务逻辑**：写单元测试验证关键性质
3. **最后用属性测试加强信心**：对关键模块做属性测试

### 23.9 本章小结

- 测试是保证代码质量的基本手段
- 断言是测试的基本单元：检查条件是否满足
- 为常用类型提供专用断言函数（check_int、check_string 等）
- 浮点数断言要用 epsilon 比较，不能直接用 `=`
- 异常断言验证函数是否抛出预期的异常
- 测试框架用于组织测试用例、运行和报告结果
- 属性测试：描述性质，自动生成测试用例
- 在函数式语言中，类型系统是第一道防线，测试是第二道
- TDD 在函数式语言中很自然，但要结合类型系统的优势

---

---
上一章：[22 · 输入输出与文件](io.md) ｜ 下一章：[24 · 记录、对象与类](objects.md) ｜ 返回：[README](../README.md)
