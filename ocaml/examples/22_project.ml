(* ==========================================================================
   22_project.ml - 综合实战：成绩CSV分析
   ==========================================================================
   主题：一个完整的 CSV 成绩分析小项目
   内容：
     1. CSV 生成
     2. CSV 解析与读取
     3. 缺失值处理
     4. 逐科统计（平均分、最高分、最低分）
     5. Top-N 排名
     6. 最小二乘拟合（两科成绩相关性）
     7. 报告写回与校验
     8. 临时文件清理

   运行方式：
     ocaml 22_project.ml
     或
     utop # #use "22_project.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-')

(* ========================================================================
   1) CSV 生成
   ========================================================================
   生成模拟的学生成绩 CSV 文件。
   包含字段：姓名、学号、数学、语文、英语、物理、化学
   部分数据有缺失值（用于演示缺失值处理）。
*)
section 1 "CSV Generation";;

(* 学生成绩记录类型 *)
type student_score = {
  name : string;
  id : string;
  math : float option;       (* option 表示可能缺失 *)
  chinese : float option;
  english : float option;
  physics : float option;
  chemistry : float option;
}

(* 生成随机成绩数据 *)
let generate_scores n =
  Random.self_init ();
  let names = [|
    "Alice"; "Bob"; "Charlie"; "Diana"; "Eve";
    "Frank"; "Grace"; "Henry"; "Iris"; "Jack";
    "Karen"; "Leo"; "Mona"; "Nick"; "Olivia";
    "Peter"; "Queenie"; "Rose"; "Sam"; "Tina";
    "Uma"; "Victor"; "Wendy"; "Xavier"; "Yvonne";
    "Zack"; "Amy"; "Brian"; "Catherine"; "David"
  |] in
  let random_score _ =
    if Random.float 1.0 < 0.1 then None  (* 10% 概率缺失 *)
    else Some (60.0 +. Random.float 40.0)  (* 60-100 分 *)
  in
  Array.init n (fun i ->
    let name = names.(i mod Array.length names) ^
               if i >= Array.length names then string_of_int (i / Array.length names) else "" in
    let id = Printf.sprintf "S%04d" (i + 1) in
    {
      name;
      id;
      math = random_score ();
      chinese = random_score ();
      english = random_score ();
      physics = random_score ();
      chemistry = random_score ();
    }
  )

(* 将成绩数组写入 CSV 文件 *)
let write_csv filename scores =
  let oc = open_out filename in
  (* 写表头 *)
  output_string oc "name,id,math,chinese,english,physics,chemistry\n";
  (* 写数据行 *)
  Array.iter (fun s ->
    let opt_to_str = function
      | None -> ""
      | Some v -> Printf.sprintf "%.1f" v
    in
    Printf.fprintf oc "%s,%s,%s,%s,%s,%s,%s\n"
      s.name s.id
      (opt_to_str s.math)
      (opt_to_str s.chinese)
      (opt_to_str s.english)
      (opt_to_str s.physics)
      (opt_to_str s.chemistry)
  ) scores;
  close_out oc

(* 生成 30 个学生的成绩数据 *)
let tmp_dir = Filename.get_temp_dir_name ()
let csv_file = Filename.concat tmp_dir "student_scores.csv"

let scores_data = generate_scores 30
let () = write_csv csv_file scores_data
Printf.printf "Generated CSV file: %s\n" csv_file;
Printf.printf "Number of students: %d\n" (Array.length scores_data);;

(* 预览前 5 行 *)
let preview_csv filename n =
  let ic = open_in filename in
  Printf.printf "First %d lines of CSV:\n" n;
  try
    for i = 1 to n do
      let line = input_line ic in
      Printf.printf "  %s\n" line
    done;
    close_in ic
  with End_of_file ->
    close_in ic

let () = preview_csv csv_file 6

(* ========================================================================
   2) CSV 解析与读取
   ========================================================================
   手写一个简单的 CSV 解析器。
   支持：
   - 逗号分隔
   - 空字段（缺失值）
   - 表头识别
   - 数值解析
*)
section 2 "CSV Parsing and Reading";;

(* 简单的 CSV 行分割（不处理引号内的逗号） *)
let split_csv_line line =
  let n = String.length line in
  let fields = ref [] in
  let current = Buffer.create 32 in
  let i = ref 0 in
  while !i < n do
    if line.[!i] = ',' then begin
      fields := Buffer.contents current :: !fields;
      Buffer.clear current;
      incr i
    end else begin
      Buffer.add_char current line.[!i];
      incr i
    end
  done;
  fields := Buffer.contents current :: !fields;
  List.rev !fields

(* 解析浮点数字段，空字符串返回 None *)
let parse_float_field s =
  if s = "" then None
  else
    try Some (float_of_string s)
    with Failure _ -> None

(* 解析整个 CSV 文件 *)
let parse_csv filename =
  let ic = open_in filename in
  try
    (* 跳过表头 *)
    let header_line = input_line ic in
    let headers = split_csv_line header_line in

    let records = ref [] in
    (try
      while true do
        let line = input_line ic in
        if line <> "" then begin
          let fields = split_csv_line line in
          match fields with
          | name :: id :: math :: chinese :: english :: physics :: chemistry :: _ ->
              let record = {
                name;
                id;
                math = parse_float_field math;
                chinese = parse_float_field chinese;
                english = parse_float_field english;
                physics = parse_float_field physics;
                chemistry = parse_float_field chemistry;
              } in
              records := record :: !records
          | _ ->
              Printf.eprintf "Warning: skipping malformed line: %s\n" line
        end
      done
    with End_of_file -> ());

    close_in ic;
    (headers, Array.of_list (List.rev !records))
  with exn ->
    close_in ic;
    raise exn

(* 解析 CSV 文件 *)
let headers, parsed_scores = parse_csv csv_file
Printf.printf "Parsed CSV successfully\n";
Printf.printf "Headers: [%s]\n" (String.concat ", " headers);
Printf.printf "Records: %d\n" (Array.length parsed_scores);;

(* 显示前 3 条解析后的记录 *)
let print_student s =
  let opt_str = function
    | None -> "N/A"
    | Some v -> Printf.sprintf "%.1f" v
  in
  Printf.printf "  %s (%s): math=%s chinese=%s english=%s physics=%s chemistry=%s\n"
    s.name s.id
    (opt_str s.math) (opt_str s.chinese) (opt_str s.english)
    (opt_str s.physics) (opt_str s.chemistry)

print_endline "First 3 records:";
for i = 0 to min 2 (Array.length parsed_scores - 1) do
  print_student parsed_scores.(i)
done;;

(* ========================================================================
   3) 缺失值处理
   ========================================================================
   处理数据中的缺失值：
   - 统计缺失率
   - 删除含缺失值的记录（listwise deletion）
   - 用均值填充（mean imputation）
   - 用中位数填充
*)
section 3 "Missing Value Handling";;

(* 获取某科目的所有成绩（排除缺失） *)
let get_subject_scores scores subject_getter =
  let rec collect i acc =
    if i >= Array.length scores then List.rev acc
    else
      match subject_getter scores.(i) with
      | None -> collect (i + 1) acc
      | Some v -> collect (i + 1) (v :: acc)
  in
  collect 0 []

(* 统计缺失情况 *)
let count_missing scores =
  let total = Array.length scores in
  let subjects = [
    ("math", (fun s -> s.math));
    ("chinese", (fun s -> s.chinese));
    ("english", (fun s -> s.english));
    ("physics", (fun s -> s.physics));
    ("chemistry", (fun s -> s.chemistry));
  ] in
  List.map (fun (name, getter) ->
    let missing = ref 0 in
    Array.iter (fun s ->
      if getter s = None then incr missing
    ) scores;
    (name, !missing, float_of_int !missing /. float_of_int total *. 100.0)
  ) subjects

let missing_stats = count_missing parsed_scores in
print_endline "Missing value statistics:";
Printf.printf "  %-12s %8s %10s\n" "Subject" "Missing" "Rate";
Printf.printf "  %s\n" (String.make 32 '-');
List.iter (fun (name, missing, rate) ->
  Printf.printf "  %-12s %8d %9.1f%%\n" name missing rate
) missing_stats;;

(* 统计至少有一科缺失的学生数 *)
let count_students_with_missing scores =
  let count = ref 0 in
  Array.iter (fun s ->
    if s.math = None || s.chinese = None || s.english = None
       || s.physics = None || s.chemistry = None then
      incr count
  ) scores;
  !count

let missing_students = count_students_with_missing parsed_scores in
Printf.printf "\nStudents with at least one missing score: %d / %d (%.1f%%)\n"
  missing_students (Array.length parsed_scores)
  (float_of_int missing_students /. float_of_int (Array.length parsed_scores) *. 100.0);;

(* 方法一：删除含缺失值的记录 *)
let drop_missing scores =
  let result = ref [] in
  Array.iter (fun s ->
    match s.math, s.chinese, s.english, s.physics, s.chemistry with
    | Some _, Some _, Some _, Some _, Some _ ->
        result := s :: !result
    | _ -> ()
  ) scores;
  Array.of_list (List.rev !result)

let clean_scores = drop_missing parsed_scores in
Printf.printf "\nAfter dropping missing: %d students (removed %d)\n"
  (Array.length clean_scores)
  (Array.length parsed_scores - Array.length clean_scores);;

(* 方法二：用均值填充缺失值 *)
let compute_mean scores getter =
  let vals = get_subject_scores scores getter in
  if vals = [] then 0.0
  else List.fold_left (+.) 0.0 vals /. float_of_int (List.length vals)

let fill_with_mean scores =
  let math_mean = compute_mean scores (fun s -> s.math) in
  let chinese_mean = compute_mean scores (fun s -> s.chinese) in
  let english_mean = compute_mean scores (fun s -> s.english) in
  let physics_mean = compute_mean scores (fun s -> s.physics) in
  let chemistry_mean = compute_mean scores (fun s -> s.chemistry) in

  Array.map (fun s ->
    {
      s with
      math = (match s.math with None -> Some math_mean | v -> v);
      chinese = (match s.chinese with None -> Some chinese_mean | v -> v);
      english = (match s.english with None -> Some english_mean | v -> v);
      physics = (match s.physics with None -> Some physics_mean | v -> v);
      chemistry = (match s.chemistry with None -> Some chemistry_mean | v -> v);
    }
  ) scores

let filled_scores = fill_with_mean parsed_scores in
Printf.printf "After mean imputation: %d students (all complete)\n"
  (Array.length filled_scores);;

(* 验证：填充后没有缺失值 *)
let all_complete scores =
  Array.for_all (fun s ->
    s.math <> None && s.chinese <> None && s.english <> None &&
    s.physics <> None && s.chemistry <> None
  ) scores
Printf.printf "All complete after fill? %b\n" (all_complete filled_scores);;

(* ========================================================================
   4) 逐科统计（平均分、最高分、最低分）
   ========================================================================
   对每个科目计算：
   - 平均分（mean）
   - 最高分（max）
   - 最低分（min）
   - 标准差（standard deviation）
*)
section 4 "Per-subject Statistics";;

(* 计算统计量 *)
let compute_stats values =
  let n = List.length values in
  if n = 0 then (0.0, 0.0, 0.0, 0.0)
  else
    let sum = List.fold_left (+.) 0.0 values in
    let mean = sum /. float_of_int n in
    let max_v = List.fold_left max (List.hd values) (List.tl values) in
    let min_v = List.fold_left min (List.hd values) (List.tl values) in
    let variance = List.fold_left (fun acc v ->
      acc +. (v -. mean) ** 2.0
    ) 0.0 values /. float_of_int n in
    let std = sqrt variance in
    (mean, max_v, min_v, std)

(* 逐科统计 *)
let subject_stats scores =
  let subjects = [
    ("math", (fun s -> s.math));
    ("chinese", (fun s -> s.chinese));
    ("english", (fun s -> s.english));
    ("physics", (fun s -> s.physics));
    ("chemistry", (fun s -> s.chemistry));
  ] in
  List.map (fun (name, getter) ->
    let vals = get_subject_scores scores getter in
    let (mean, max_v, min_v, std) = compute_stats vals in
    (name, List.length vals, mean, max_v, min_v, std)
  ) subjects

let stats = subject_stats filled_scores in
Printf.printf "Per-subject statistics (n=%d):\n" (Array.length filled_scores);
Printf.printf "  %-12s %5s %8s %8s %8s %8s\n"
  "Subject" "N" "Mean" "Max" "Min" "Std";
Printf.printf "  %s\n" (String.make 55 '-');
List.iter (fun (name, n, mean, max_v, min_v, std) ->
  Printf.printf "  %-12s %5d %8.2f %8.2f %8.2f %8.2f\n"
    name n mean max_v min_v std
) stats;;

(* 计算每个学生的总分（使用填充后的数据） *)
let compute_total s =
  let sum_opt opt acc = match opt with None -> acc | Some v -> acc +. v in
  sum_opt s.math 0.0
  |> sum_opt s.chinese
  |> sum_opt s.english
  |> sum_opt s.physics
  |> sum_opt s.chemistry

let total_stats =
  let totals = Array.map compute_total filled_scores in
  let total_list = Array.to_list totals in
  compute_stats total_list

let total_mean, total_max, total_min, total_std = total_stats in
Printf.printf "\nTotal score statistics:\n";
Printf.printf "  Mean: %.2f, Max: %.2f, Min: %.2f, Std: %.2f\n"
  total_mean total_max total_min total_std;;

(* ========================================================================
   5) Top-N 排名
   ========================================================================
   按总分排名，找出 Top-N 学生。
   同时按单科排名。
*)
section 5 "Top-N Ranking";;

(* 按总分排序 *)
let sort_by_total scores =
  let with_totals = Array.map (fun s -> (s, compute_total s)) scores in
  Array.sort (fun (_, t1) (_, t2) -> compare t2 t1) with_totals;
  with_totals

let sorted_by_total = sort_by_total filled_scores in
Printf.printf "Top 10 students by total score:\n";
Printf.printf "  %-4s %-15s %8s %8s\n" "Rank" "Name" "ID" "Total";
Printf.printf "  %s\n" (String.make 38 '-');
for i = 0 to min 9 (Array.length sorted_by_total - 1) do
  let s, total = sorted_by_total.(i) in
  Printf.printf "  %-4d %-15s %8s %8.1f\n" (i + 1) s.name s.id total
done;;

(* 按单科排名 *)
let top_n_by_subject scores n getter =
  let valid = ref [] in
  Array.iter (fun s ->
    match getter s with
    | None -> ()
    | Some v -> valid := (s, v) :: !valid
  ) scores;
  let arr = Array.of_list !valid in
  Array.sort (fun (_, s1) (_, s2) -> compare s2 s1) arr;
  Array.sub arr 0 (min n (Array.length arr))

let print_top_n title top_n =
  Printf.printf "  Top %d - %s:\n" (Array.length top_n) title;
  Printf.printf "    %-4s %-15s %8s\n" "Rank" "Name" "Score";
  Printf.printf "    %s\n" (String.make 30 '-');
  for i = 0 to Array.length top_n - 1 do
    let s, score = top_n.(i) in
    Printf.printf "    %-4d %-15s %8.1f\n" (i + 1) s.name score
  done

let top_math = top_n_by_subject filled_scores 5 (fun s -> s.math) in
let top_physics = top_n_by_subject filled_scores 5 (fun s -> s.physics) in

print_endline "Top 5 by subject:";
print_top_n "Math" top_math;
print_top_n "Physics" top_physics;;

(* 排名变化分析：比较总分排名和数学排名的差异 *)
let math_rank =
  let arr = top_n_by_subject filled_scores (Array.length filled_scores) (fun s -> s.math) in
  let rank_tbl = Hashtbl.create 50 in
  Array.iteri (fun i (s, _) -> Hashtbl.add rank_tbl s.id (i + 1)) arr;
  rank_tbl

let total_rank =
  let arr = sort_by_total filled_scores in
  let rank_tbl = Hashtbl.create 50 in
  Array.iteri (fun i (s, _) -> Hashtbl.add rank_tbl s.id (i + 1)) arr;
  rank_tbl

print_endline "\nRank comparison (Top 10 total vs math rank):";
Printf.printf "  %-4s %-15s %8s %8s %8s\n"
  "Rank" "Name" "Total" "Math" "Diff";
Printf.printf "  %s\n" (String.make 42 '-');
for i = 0 to min 9 (Array.length sorted_by_total - 1) do
  let s, _ = sorted_by_total.(i) in
  let tr = i + 1 in
  let mr = try Hashtbl.find math_rank s.id with Not_found -> -1 in
  let diff = mr - tr in
  let diff_str = if mr = -1 then "N/A" else
    if diff > 0 then Printf.sprintf "+%d" diff
    else if diff < 0 then Printf.sprintf "%d" diff
    else "0" in
  Printf.printf "  %-4d %-15s %8d %8d %8s\n" tr s.name tr mr diff_str
done;;

(* ========================================================================
   6) 最小二乘拟合（两科成绩相关性）
   ========================================================================
   使用最小二乘法进行线性回归，分析两科成绩之间的相关性。
   给定数据点 (xi, yi)，拟合直线 y = ax + b
   - 斜率 a = (nΣxy - ΣxΣy) / (nΣx² - (Σx)²)
   - 截距 b = (Σy - aΣx) / n
   - 相关系数 r 衡量线性相关程度
*)
section 6 "Least Squares Fitting (Correlation)";;

(* 最小二乘线性回归 *)
let linear_regression points =
  let n = List.length points in
  if n < 2 then failwith "linear_regression: need at least 2 points";
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
    sum_y2 := !sum_y2 +. y *. y;
  ) points;
  let nf = float_of_int n in
  let denom = nf *. !sum_x2 -. !sum_x *. !sum_x in
  if denom = 0.0 then failwith "linear_regression: vertical line";
  let a = (nf *. !sum_xy -. !sum_x *. !sum_y) /. denom in
  let b = (!sum_y -. a *. !sum_x) /. nf in
  (* 相关系数 r *)
  let r_denom = sqrt ((nf *. !sum_x2 -. !sum_x *. !sum_x) *.
                      (nf *. !sum_y2 -. !sum_y *. !sum_y)) in
  let r = if r_denom = 0.0 then 0.0
          else (nf *. !sum_xy -. !sum_x *. !sum_y) /. r_denom in
  (a, b, r)

(* 提取两科都有成绩的学生，生成数据点 *)
let extract_pair_scores scores getter_x getter_y =
  let points = ref [] in
  Array.iter (fun s ->
    match getter_x s, getter_y s with
    | Some x, Some y -> points := (x, y) :: !points
    | _ -> ()
  ) scores;
  !points

(* 分析数学和物理的相关性 *)
let math_physics_points = extract_pair_scores filled_scores
  (fun s -> s.math) (fun s -> s.physics) in
let a, b, r = linear_regression math_physics_points in
Printf.printf "Math vs Physics correlation:\n";
Printf.printf "  Data points: %d\n" (List.length math_physics_points);
Printf.printf "  Regression: physics = %.4f * math + %.4f\n" a b;
Printf.printf "  Correlation coefficient (r): %.4f\n" r;
let strength =
  if abs_float r >= 0.9 then "very strong"
  else if abs_float r >= 0.7 then "strong"
  else if abs_float r >= 0.5 then "moderate"
  else if abs_float r >= 0.3 then "weak"
  else "very weak or no" in
Printf.printf "  Strength: %s %s correlation\n"
    strength (if r >= 0.0 then "positive" else "negative");;

(* 分析语文和英语的相关性 *)
let chinese_english_points = extract_pair_scores filled_scores
  (fun s -> s.chinese) (fun s -> s.english) in
let a2, b2, r2 = linear_regression chinese_english_points in
Printf.printf "\nChinese vs English correlation:\n";
Printf.printf "  Data points: %d\n" (List.length chinese_english_points);
Printf.printf "  Regression: english = %.4f * chinese + %.4f\n" a2 b2;
Printf.printf "  Correlation coefficient (r): %.4f\n" r2;;

(* 预测：给定数学成绩，预测物理成绩 *)
let predict_physics math_score = a *. math_score +. b in
Printf.printf "\nPrediction examples:\n";
Printf.printf "  Math=70.0 -> Predicted Physics: %.2f\n" (predict_physics 70.0);
Printf.printf "  Math=80.0 -> Predicted Physics: %.2f\n" (predict_physics 80.0);
Printf.printf "  Math=90.0 -> Predicted Physics: %.2f\n" (predict_physics 90.0);;

(* ========================================================================
   7) 报告写回与校验
   ========================================================================
   将分析结果写回 CSV 报告文件。
   然后读取回来验证数据的一致性。
*)
section 7 "Report Writing and Verification";;

let report_file = Filename.concat tmp_dir "score_analysis_report.csv"

(* 生成分析报告 CSV *)
let write_report filename scores =
  let oc = open_out filename in

  (* 第一部分：逐科统计 *)
  output_string oc "=== Subject Statistics ===\n";
  output_string oc "subject,n,mean,max,min,std\n";
  let stats = subject_stats scores in
  List.iter (fun (name, n, mean, max_v, min_v, std) ->
    Printf.fprintf oc "%s,%d,%.2f,%.2f,%.2f,%.2f\n"
      name n mean max_v min_v std
  ) stats;

  (* 第二部分：总分排名前 20 *)
  output_string oc "\n=== Top 20 by Total ===\n";
  output_string oc "rank,name,id,total\n";
  let sorted = sort_by_total scores in
  for i = 0 to min 19 (Array.length sorted - 1) do
    let s, total = sorted.(i) in
    Printf.fprintf oc "%d,%s,%s,%.1f\n" (i + 1) s.name s.id total
  done;

  (* 第三部分：相关性分析 *)
  output_string oc "\n=== Correlation Analysis ===\n";
  output_string oc "x_subject,y_subject,slope,intercept,correlation\n";
  let pairs = [
    ("math", "physics");
    ("math", "chemistry");
    ("chinese", "english");
    ("physics", "chemistry");
  ] in
  let getter_of = function
    | "math" -> (fun s -> s.math)
    | "chinese" -> (fun s -> s.chinese)
    | "english" -> (fun s -> s.english)
    | "physics" -> (fun s -> s.physics)
    | "chemistry" -> (fun s -> s.chemistry)
    | _ -> (fun s -> s.math)
  in
  List.iter (fun (x_subj, y_subj) ->
    let points = extract_pair_scores scores (getter_of x_subj) (getter_of y_subj) in
    try
      let a, b, r = linear_regression points in
      Printf.fprintf oc "%s,%s,%.4f,%.4f,%.4f\n" x_subj y_subj a b r
    with _ ->
      Printf.fprintf oc "%s,%s,N/A,N/A,N/A\n" x_subj y_subj
  ) pairs;

  close_out oc

let () = write_report report_file filled_scores
Printf.printf "Report written to: %s\n" report_file;;

(* 读取报告并显示 *)
let read_and_display_report filename =
  let ic = open_in filename in
  let content = Buffer.create 1024 in
  (try
    while true do
      let line = input_line ic in
      Buffer.add_string content line;
      Buffer.add_char content '\n'
    done
  with End_of_file -> ());
  close_in ic;
  Buffer.contents content

let report_content = read_and_display_report report_file in
print_endline "Report content:";
print_endline (String.make 50 '-');
print_string report_content;
print_endline (String.make 50 '-');;

(* 校验：重新计算并与报告中的值比较 *)
let verify_report scores =
  let stats = subject_stats scores in
  let math_stat = List.find (fun (n, _, _, _, _, _) -> n = "math") stats in
  let (_, _, math_mean, _, _, _) = math_stat in

  (* 计算预测值与实际值的均方误差 *)
  let math_physics = extract_pair_scores scores (fun s -> s.math) (fun s -> s.physics) in
  let a, b, _ = linear_regression math_physics in
  let mse = List.fold_left (fun acc (x, y) ->
    let predicted = a *. x +. b in
    acc +. (y -. predicted) ** 2.0
  ) 0.0 math_physics /. float_of_int (List.length math_physics) in

  Printf.printf "Verification:\n";
  Printf.printf "  Math mean (recomputed): %.2f\n" math_mean;
  Printf.printf "  Regression MSE (math->physics): %.4f\n" mse;
  Printf.printf "  Report file size: %d bytes\n"
    (Unix.stat filename).Unix.st_size
  where filename = report_file  (* 简化写法 *)

let _ =
  let stats = subject_stats filled_scores in
  let math_stat = List.find (fun (n, _, _, _, _, _) -> n = "math") stats in
  let (_, _, math_mean, math_max, math_min, math_std) = math_stat in

  let math_physics = extract_pair_scores filled_scores
    (fun s -> s.math) (fun s -> s.physics) in
  let a, b, r = linear_regression math_physics in
  let mse = List.fold_left (fun acc (x, y) ->
    let predicted = a *. x +. b in
    acc +. (y -. predicted) ** 2.0
  ) 0.0 math_physics /. float_of_int (List.length math_physics) in

  Printf.printf "Verification:\n";
  Printf.printf "  Math mean: %.2f (max: %.2f, min: %.2f, std: %.2f)\n"
    math_mean math_max math_min math_std;
  Printf.printf "  Regression MSE (math->physics): %.4f\n" mse;
  Printf.printf "  Report file exists: %b\n" (Sys.file_exists report_file);
  let file_size = (Unix.stat report_file).Unix.st_size in
  Printf.printf "  Report file size: %d bytes\n" file_size;;

(* ========================================================================
   8) 临时文件清理
   ========================================================================
   清理生成的临时文件。
   实际项目中可以使用 Fun.protect 或类似的资源管理模式。
*)
section 8 "Temporary File Cleanup";;

(* 列出临时目录中的相关文件 *)
let list_temp_files pattern =
  let dir = Filename.get_temp_dir_name () in
  let entries = Sys.readdir dir in
  let matching = ref [] in
  Array.iter (fun name ->
    if String.starts_with ~prefix:pattern name then
      matching := name :: !matching
  ) entries;
  List.rev !matching

let csv_files_before = list_temp_files "student_scores" in
Printf.printf "CSV files in temp dir before cleanup: %d\n" (List.length csv_files_before);;

(* 清理函数 *)
let cleanup_file path =
  if Sys.file_exists path then begin
    Sys.remove path;
    Printf.printf "  Removed: %s\n" path;
    true
  end else begin
    Printf.printf "  Not found: %s\n" path;
    false
  end

print_endline "Cleaning up temporary files:";
let csv_removed = cleanup_file csv_file in
let report_removed = cleanup_file report_file in

Printf.printf "\nFiles removed: %d\n"
  ((if csv_removed then 1 else 0) + (if report_removed then 1 else 0));
Printf.printf "CSV file exists: %b\n" (Sys.file_exists csv_file);
Printf.printf "Report file exists: %b\n" (Sys.file_exists report_file);;

(* ========================================================================
   总结
   ======================================================================== *)
print_endline "\n";;
print_endline (String.make 60 '=');;
print_endline "  PROJECT SUMMARY";;
print_endline (String.make 60 '=');;
Printf.printf "  Data source:  generated CSV with %d students\n"
  (Array.length scores_data);
Printf.printf "  Missing data: %d students had at least one missing score\n"
  missing_students;
Printf.printf "  After imputation: %d complete records\n"
  (Array.length filled_scores);
Printf.printf "  Subjects analyzed: 5 (math, chinese, english, physics, chemistry)\n";
Printf.printf "  Top total score: %.2f\n" total_max;
Printf.printf "  Average total score: %.2f\n" total_mean;
Printf.printf "  Strongest correlation: math-physics (r=%.4f)\n" r;;
print_endline (String.make 60 '=');;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 22 jieshu ===="  (* 第二十二个文件结束 *)
