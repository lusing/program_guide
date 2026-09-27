# 26 · 综合实战：成绩 CSV 分析与报告

对应示例：`../examples/22_project.ml`

对应示例：`examples/22_project.ml`

### 26.1 项目需求分析

我们来做一个完整的小项目：读取学生成绩 CSV 文件，做统计分析，生成报告写回文件。

这个项目会用到前面学过的很多知识：
- 模块系统（组织代码）
- 可变状态（Hashtbl、累加器）
- 数值计算（平均值、标准差、最小二乘拟合）
- I/O 与文件（CSV 读写）
- 错误处理（缺失值、异常）
- 测试（结果校验）

具体需求：
1. 生成模拟的成绩 CSV 数据（方便测试）
2. 解析 CSV 文件，处理缺失值
3. 逐科统计：平均分、最高分、最低分、标准差
4. 计算每科的 Top-N 排名（处理并列情况）
5. 计算两科成绩的相关性（最小二乘线性拟合）
6. 生成统计报告，写入新的 CSV 文件
7. 校验：写回后再读回来，确认数据一致
8. 清理临时文件

### 26.2 CSV 格式介绍

CSV（Comma-Separated Values）是最简单的表格数据格式之一：
- 每行是一条记录
- 字段之间用逗号分隔
- 第一行通常是表头（列名）
- 字段如果包含逗号、引号或换行，需要用引号包裹

一个简单的成绩 CSV 示例：
```
name,id,math,chinese,english
Alice,S0001,95.5,88.0,92.0
Bob,S0002,78.0,85.5,80.0
Charlie,S0003,90.0,,95.0
```

注意 Charlie 的语文成绩是空的——这就是缺失值。

完整的 CSV 格式还有很多细节（引号转义、换行处理等），但为了保持代码简洁，我们实现一个简化版：假设字段不包含逗号和引号。

### 26.3 数据类型定义

首先定义数据类型：

```ocaml
type student = {
  name : string;
  id : string;
  math : float option;
  chinese : float option;
  english : float option;
  physics : float option;
  chemistry : float option;
}

type subject =
  | Math
  | Chinese
  | English
  | Physics
  | Chemistry

let all_subjects = [Math; Chinese; English; Physics; Chemistry]

let subject_name = function
  | Math -> "math"
  | Chinese -> "chinese"
  | English -> "english"
  | Physics -> "physics"
  | Chemistry -> "chemistry"
```

成绩用 `float option` 类型表示——`Some score` 表示有成绩，`None` 表示缺失。

用变体类型表示科目，而不是用字符串，这样类型系统可以帮我们检查是否漏掉了某些科目。

### 26.4 CSV 生成器

为了测试，我们先写一个 CSV 生成器，生成带缺失值的随机成绩数据。

```ocaml
let generate_csv filename n =
  Random.self_init ();
  let names = [|
    "Alice"; "Bob"; "Charlie"; "Diana"; "Eve";
    "Frank"; "Grace"; "Henry"; "Iris"; "Jack";
    "Karen"; "Leo"; "Mona"; "Nick"; "Olivia";
    "Peter"; "Queenie"; "Rose"; "Sam"; "Tina";
    "Uma"; "Victor"; "Wendy"; "Xavier"; "Yvonne";
    "Zack"; "Amy"; "Brian"; "Catherine"; "David"
  |] in
  let oc = open_out filename in
  (* 写表头 *)
  output_string oc "name,id,math,chinese,english,physics,chemistry\n";
  (* 生成 n 条记录 *)
  for i = 0 to n - 1 do
    let name = names.(i mod Array.length names) ^
               if i >= Array.length names then string_of_int (i / Array.length names)
               else "" in
    let id = Printf.sprintf "S%04d" (i + 1) in
    (* 生成成绩，10% 概率缺失 *)
    let score _ =
      if Random.float 1.0 < 0.1 then ""
      else string_of_float (60.0 +. Random.float 40.0)
    in
    Printf.fprintf oc "%s,%s,%s,%s,%s,%s,%s\n"
      name id
      (score ()) (score ()) (score ()) (score ()) (score ())
  done;
  close_out oc
```

### 26.5 CSV 解析器

接下来是 CSV 解析器。先实现一个简单的按逗号分割的函数：

```ocaml
let split_comma line =
  let n = String.length line in
  let rec loop start i acc =
    if i >= n then
      List.rev (String.sub line start (i - start) :: acc)
    else if line.[i] = ',' then
      loop (i + 1) (i + 1) (String.sub line start (i - start) :: acc)
    else
      loop start (i + 1) acc
  in
  loop 0 0 []
```

然后解析整个文件：

```ocaml
let parse_csv filename =
  let ic = open_in filename in
  try
    (* 读取并跳过表头 *)
    let header_line = input_line ic in
    let _headers = split_comma header_line in
    
    let students = ref [] in
    begin try
      while true do
        let line = input_line ic in
        let fields = split_comma line in
        match fields with
        | name :: id :: math_s :: chinese_s :: english_s :: physics_s :: chemistry_s :: _ ->
            let parse_score s =
              if String.trim s = "" then None
              else Some (float_of_string s)
            in
            let student = {
              name; id;
              math = parse_score math_s;
              chinese = parse_score chinese_s;
              english = parse_score english_s;
              physics = parse_score physics_s;
              chemistry = parse_score chemistry_s;
            } in
            students := student :: !students
        | _ ->
            Printf.eprintf "Warning: skipping malformed line: %s\n" line
      done
    with End_of_file -> () end;
    
    close_in ic;
    List.rev !students
  with e ->
    close_in_noerr ic;
    raise e
```

解析逻辑：
1. 打开文件，读取第一行作为表头（暂时忽略）
2. 逐行读取，按逗号分割字段
3. 把字符串成绩转成 `float option`——空字符串表示缺失
4. 遇到格式不对的行，打印警告并跳过
5. 读到文件末尾时结束，返回所有学生记录

### 26.6 缺失值处理策略

真实世界的数据经常有缺失。处理缺失值的常见策略：

1. **删除法**：直接丢弃有缺失的记录。简单但可能丢失大量数据
2. **填充法**：用某个值填充缺失，比如 0、平均分、中位数
3. **忽略法**：计算统计量时跳过缺失值，只使用有效值

我们的项目采用**忽略法**——计算每科的统计量时，只使用有成绩的学生。

一个辅助函数：提取某科的所有有效成绩。

```ocaml
let subject_score student = function
  | Math -> student.math
  | Chinese -> student.chinese
  | English -> student.english
  | Physics -> student.physics
  | Chemistry -> student.chemistry

let valid_scores students subject =
  List.filter_map (fun s -> subject_score s subject) students
```

`List.filter_map` 是 `filter` + `map` 的组合——它把列表中返回 `Some x` 的元素的 `x` 收集起来，返回 `None` 的被过滤掉。

### 26.7 逐科统计：平均分、最高分、最低分、标准差

现在来计算每科的统计量。

```ocaml
type subject_stats = {
  subject : subject;
  count : int;
  mean : float;
  max : float;
  min : float;
  std_dev : float;
}

let compute_stats students subject =
  let scores = valid_scores students subject in
  let n = List.length scores in
  if n = 0 then {
    subject; count = 0;
    mean = 0.0; max = 0.0; min = 0.0; std_dev = 0.0;
  } else
    let sum = List.fold_left (+.) 0.0 scores in
    let mean = sum /. float_of_int n in
    let sum_sq = List.fold_left (fun acc x -> acc +. (x -. mean) ** 2.0) 0.0 scores in
    let variance = sum_sq /. float_of_int n in   (* 总体标准差 *)
    let std_dev = sqrt variance in
    let max = List.fold_left max_float (List.hd scores) (List.tl scores) in
    let min = List.fold_left min_float (List.hd scores) (List.tl scores) in
    { subject; count = n; mean; max; min; std_dev }
```

标准差（Standard Deviation）衡量数据的离散程度：
- 标准差小：成绩集中在平均分附近
- 标准差大：成绩分布很分散

注意这里用的是**总体标准差**（除以 n），而不是样本标准差（除以 n-1）。因为我们把这批学生当作总体来看待。

### 26.8 Top-N 排名与并列规则

接下来计算每科的 Top-N 排名。

并列的处理：如果第 N 名和第 N+1 名分数相同，应该都算进 Top-N（也就是并列排名时，Top-N 可能多于 N 个人）。

```ocaml
type ranked_student = {
  name : string;
  score : float;
  rank : int;
}

let top_n students subject n =
  let scored =
    students
    |> List.filter_map (fun s ->
         match subject_score s subject with
         | None -> None
         | Some score -> Some (s.name, score))
    |> List.sort (fun (_, a) (_, b) -> compare b a)   (* 降序 *)
  in
  
  let rec assign_rank acc rank prev_score = function
    | [] -> List.rev acc
    | (name, score) :: rest ->
        let new_rank =
          if score = prev_score then rank
          else List.length acc + 1
        in
        if new_rank > n then List.rev acc
        else
          assign_rank ({ name; score; rank = new_rank } :: acc) new_rank score rest
  in
  match scored with
  | [] -> []
  | (name, score) :: rest ->
      assign_rank [{ name; score; rank = 1 }] 1 score rest
```

排名算法（标准的「并列同名次，跳过后续名次」方式）：
- 第 1 名是最高分
- 如果当前分数和上一名相同，排名相同
- 如果不同，排名 = 已处理人数 + 1
- 当排名超过 N 时停止

比如分数 [100, 95, 95, 90] 的排名是 [1, 2, 2, 4]——两个第 2 名，然后直接跳到第 4 名。

### 26.9 两科成绩相关性：最小二乘线性拟合

两科成绩有没有相关性？比如数学好的人物理也好吗？

我们用**最小二乘线性拟合**来求两科成绩的线性关系 y = ax + b，然后看拟合的好坏程度。

最小二乘的公式：
- a = (nΣxy - ΣxΣy) / (nΣx² - (Σx)²)
- b = (Σy - aΣx) / n

```ocaml
type linear_fit = {
  slope : float;       (* 斜率 a *)
  intercept : float;   (* 截距 b *)
  r_squared : float;   (* 决定系数 R² *)
}

let linear_regression students subj_x subj_y =
  (* 只取两科都有成绩的学生 *)
  let paired =
    List.filter_map (fun s ->
      match subject_score s subj_x, subject_score s subj_y with
      | Some x, Some y -> Some (x, y)
      | _ -> None
    ) students
  in
  let n = List.length paired in
  if n < 2 then { slope = 0.0; intercept = 0.0; r_squared = 0.0 }
  else
    let sum_x = ref 0.0 in
    let sum_y = ref 0.0 in
    let sum_xy = ref 0.0 in
    let sum_x2 = ref 0.0 in
    let sum_y2 = ref 0.0 in
    List.iter (fun (x, y) ->
      sum_x := !sum_x +. x;
      sum_y := !sum_y +. y;
      sum_xy := !sum_xy +. x *. y;
      sum_x2 := !sum_x2 +. x *. x;
      sum_y2 := !sum_y2 +. y *. y
    ) paired;
    
    let nf = float_of_int n in
    let denominator = nf *. !sum_x2 -. !sum_x *. !sum_x in
    if abs_float denominator < 1e-12 then
      { slope = 0.0; intercept = 0.0; r_squared = 0.0 }
    else
      let slope = (nf *. !sum_xy -. !sum_x *. !sum_y) /. denominator in
      let intercept = (!sum_y -. slope *. !sum_x) /. nf in
      
      (* 计算 R² *)
      let mean_y = !sum_y /. nf in
      let ss_tot = List.fold_left (fun acc (_, y) -> acc +. (y -. mean_y) ** 2.0) 0.0 paired in
      let ss_res = List.fold_left (fun acc (x, y) ->
        let y_pred = slope *. x +. intercept in
        acc +. (y -. y_pred) ** 2.0
      ) 0.0 paired in
      let r_squared =
        if ss_tot < 1e-12 then 1.0
        else 1.0 -. ss_res /. ss_tot
      in
      
      { slope; intercept; r_squared }
```

R²（决定系数）衡量拟合的好坏：
- R² = 1：完美拟合，所有点都在直线上
- R² = 0：拟合还不如直接取平均值
- R² 越接近 1，说明两科成绩的线性相关性越强

### 26.10 报告生成与写回

现在把所有统计结果整理成报告，写入 CSV 文件。

```ocaml
let write_report filename students =
  let oc = open_out filename in
  
  (* 1. 总体统计 *)
  Printf.fprintf oc "=== Subject Statistics ===\n";
  Printf.fprintf oc "Subject,Count,Mean,Max,Min,StdDev\n";
  List.iter (fun subj ->
    let stats = compute_stats students subj in
    Printf.fprintf oc "%s,%d,%.2f,%.2f,%.2f,%.2f\n"
      (subject_name subj) stats.count stats.mean stats.max stats.min stats.std_dev
  ) all_subjects;
  
  (* 2. Top-N 排名（每科 Top 5） *)
  Printf.fprintf oc "\n=== Top 5 Rankings ===\n";
  List.iter (fun subj ->
    Printf.fprintf oc "\n--- %s ---\n" (subject_name subj);
    Printf.fprintf oc "Rank,Name,Score\n";
    let top = top_n students subj 5 in
    List.iter (fun t ->
      Printf.fprintf oc "%d,%s,%.2f\n" t.rank t.name t.score
    ) top
  ) all_subjects;
  
  (* 3. 科目间相关性（数学 vs 物理、语文 vs 英语） *)
  Printf.fprintf oc "\n=== Correlation Analysis ===\n";
  Printf.fprintf oc "Subject_X,Subject_Y,Slope,Intercept,R_squared\n";
  let pairs = [(Math, Physics); (Chinese, English); (Math, Chemistry)] in
  List.iter (fun (sx, sy) ->
    let fit = linear_regression students sx sy in
    Printf.fprintf oc "%s,%s,%.4f,%.4f,%.4f\n"
      (subject_name sx) (subject_name sy)
      fit.slope fit.intercept fit.r_squared
  ) pairs;
  
  close_out oc
```

### 26.11 结果校验：写回后再读回来对比

为了确保我们的 CSV 生成和解析是正确的，做一个简单的校验：
1. 生成一个 CSV 文件
2. 读回来，对比数据是否一致

```ocaml
let validate_csv original_scores filename =
  let parsed = parse_csv filename in
  let rec compare a b =
    match (a, b) with
    | ([], []) -> true
    | (x :: xs, y :: ys) ->
        x.name = y.name && x.id = y.id &&
        x.math = y.math && x.chinese = y.chinese &&
        x.english = y.english && x.physics = y.physics &&
        x.chemistry = y.chemistry &&
        compare xs ys
    | _ -> false
  in
  compare original_scores parsed
```

在生产环境中，这种「读写一致性检查」是一种简单但有效的测试手段。

### 26.12 临时文件清理

测试过程中生成的临时文件，用完后应该清理掉。

```ocaml
let cleanup_temp_files filenames =
  List.iter (fun f ->
    if Sys.file_exists f then
      try Sys.remove f with _ -> ()
  ) filenames
```

`Sys.remove` 删除文件。用 `try...with` 包裹，防止删除失败导致程序崩溃——清理失败不是致命错误。

### 26.13 完整主程序

把所有部分串起来：

```ocaml
let () =
  let input_file = "scores.csv" in
  let report_file = "report.txt" in
  
  (* 生成测试数据 *)
  Printf.printf "Generating sample data...\n";
  generate_csv input_file 30;
  
  (* 解析 CSV *)
  Printf.printf "Parsing CSV file...\n";
  let students = parse_csv input_file in
  Printf.printf "Loaded %d students\n" (List.length students);
  
  (* 生成报告 *)
  Printf.printf "Generating report...\n";
  write_report report_file students;
  Printf.printf "Report written to %s\n" report_file;
  
  (* 输出一些摘要信息到终端 *)
  Printf.printf "\n--- Summary ---\n";
  List.iter (fun subj ->
    let stats = compute_stats students subj in
    Printf.printf "%s: avg=%.2f, max=%.2f, min=%.2f, std=%.2f (n=%d)\n"
      (subject_name subj) stats.mean stats.max stats.min stats.std_dev stats.count
  ) all_subjects;
  
  Printf.printf "\nDone!\n"
```

### 26.14 运行说明

运行方式：

```bash
cd /Users/xulun/code/programming/ocaml
ocaml examples/22_project.ml
```

运行后会生成两个文件：
- `scores.csv`：30 个学生的随机成绩数据
- `report.txt`：统计分析报告

你可以用文本编辑器打开 `report.txt` 查看详细的统计结果。

### 26.15 扩展练习

如果你想进一步练习，可以考虑这些扩展：

1. **CSV 解析器增强**：支持带引号的字段、引号转义、Windows 换行符
2. **更多统计量**：中位数、众数、四分位数
3. **总分排名**：计算每个学生的总分，生成总分排名
4. **等级划分**：把成绩分成 A/B/C/D/E 五个等级，统计各等级人数
5. **直方图**：用文本字符画成绩分布直方图
6. **导出为 JSON**：把统计结果导出为 JSON 格式
7. **命令行参数**：用 `Sys.argv` 让用户指定输入文件和输出文件

### 26.16 本章小结

- 完整的项目需要：数据类型定义、解析、计算、输出、校验、清理
- CSV 格式简单但细节多，生产环境建议用成熟的 CSV 库
- 缺失值处理策略：删除法、填充法、忽略法，各有适用场景
- 逐科统计：平均分、最高分、最低分、标准差
- Top-N 排名要处理并列情况（同名次，跳过后续排名）
- 最小二乘线性拟合可以衡量两科成绩的相关性
- R² 决定系数衡量拟合优度，越接近 1 越好
- 结果校验：写回后再读回来对比，确保读写一致
- 临时文件用完及时清理

---

---
上一章：[25 · 流与序列](streams.md) ｜ 下一章：[27 · 错误处理：option / result 与绑定运算符](error-handling.md) ｜ 返回：[README](../README.md)
