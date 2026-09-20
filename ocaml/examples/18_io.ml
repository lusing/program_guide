(* ==========================================================================
   18_io.ml - 输入输出与文件
   ==========================================================================
   主题：OCaml 的输入输出（I/O）和文件操作
   内容：
     1. print_endline / print_string
     2. Printf 格式化输出
     3. 读取标准输入
     4. 文件读写：open_in / open_out
     5. 逐行读取
     6. 追加写入
     7. 目录操作（Sys 模块）
     8. 环境变量

   运行方式：
     ocaml 18_io.ml
     或
     utop # #use "18_io.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) print_endline / print_string
   ========================================================================
   最基本的输出函数：
   - print_string s : 输出字符串 s（不换行）
   - print_endline s : 输出字符串 s，然后换行
   - print_newline () : 输出一个换行符
   - print_int n : 输出整数
   - print_float f : 输出浮点数
   - print_char c : 输出字符
   - print_bool b : 输出布尔值
*)
section 1 "print_endline / print_string";;

print_string "Hello, ";;
print_string "World!";;
print_newline ();;

print_endline "This is a line.";;
print_endline "This is another line.";;

print_string "Integer: ";;
print_int 42;;
print_newline ();;

print_string "Float: ";;
print_float 3.14159;;
print_newline ();;

print_string "Char: ";;
print_char 'A';;
print_newline ();;

print_string "Bool: ";;
print_string (string_of_bool true);;
print_newline ();;

(* 使用 print_endline 打印列表元素 *)
let print_list_strings label lst =
  print_endline label;
  List.iter (fun s -> print_endline ("  - " ^ s)) lst;;

print_list_strings "Fruits:" ["apple"; "banana"; "cherry"];;

(* ========================================================================
   2) Printf 格式化输出
   ========================================================================
   Printf 模块提供类似 C 语言 printf 的格式化输出功能。
   常用格式说明符：
   - %d / %i : 整数
   - %f / %F : 浮点数
   - %s : 字符串
   - %c : 字符
   - %b : 布尔值
   - %a : 用户自定义打印函数
   - %! : 刷新缓冲区
   - \n : 换行
   - %.2f : 保留2位小数的浮点数
   - %10d : 宽度为10的右对齐整数
   - %-10s : 宽度为10的左对齐字符串
*)
section 2 "Printf formatted output";;

(* 基本格式化 *)
Printf.printf "Integer: %d\n" 42;;
Printf.printf "Float: %f\n" 3.14159;;
Printf.printf "String: %s\n" "hello";;
Printf.printf "Char: %c\n" 'A';;
Printf.printf "Bool: %b\n" true;;

(* 多个参数 *)
Printf.printf "Name: %s, Age: %d, Score: %.2f\n" "Alice" 30 95.5;;

(* 宽度和对齐 *)
Printf.printf "Right-aligned: [%10d]\n" 42;;
Printf.printf "Left-aligned:  [%-10d]\n" 42;;
Printf.printf "Zero-padded:   [%010d]\n" 42;;

(* 浮点数精度 *)
Printf.printf "Default float: %f\n" 3.1415926535;;
Printf.printf "2 decimal:     %.2f\n" 3.1415926535;;
Printf.printf "6 decimal:     %.6f\n" 3.1415926535;;
Printf.printf "Scientific:    %e\n" 3.1415926535;;

(* 表格输出示例 *)
print_endline "\nFormatted table:";
Printf.printf "%-15s %5s %8s %10s\n" "Name" "Age" "Score" "Grade";
print_endline (String.make 40 '-');
let students = [
  ("Alice", 20, 95.5, 'A');
  ("Bob", 21, 87.3, 'B');
  ("Charlie", 19, 92.0, 'A');
  ("Diana", 22, 78.6, 'C');
] in
List.iter (fun (name, age, score, grade) ->
  Printf.printf "%-15s %5d %7.1f %9s\n" name age score (String.make 1 grade)
) students;;

(* Printf.sprintf : 格式化到字符串 *)
let formatted = Printf.sprintf "Result: %d + %d = %d" 3 4 7 in
Printf.printf "sprintf result: \"%s\"\n" formatted;;

(* Printf.bprintf : 格式化到 Buffer *)
let buf = Buffer.create 64 in
Printf.bprintf buf "Name: %s\n" "Alice";
Printf.bprintf buf "Age: %d\n" 30;
Printf.bprintf buf "Score: %.2f\n" 95.5;
Printf.printf "bprintf result:\n%s" (Buffer.contents buf);;

(* ========================================================================
   3) 读取标准输入
   ========================================================================
   从标准输入（stdin）读取数据：
   - read_line () : 读取一行，返回字符串
   - read_int () : 读取一个整数
   - read_float () : 读取一个浮点数
   - input_char stdin : 读取一个字符
   - input_line stdin : 读取一行（与 read_line 相同）

   注意：这些函数在非交互式环境下可能需要特殊处理。
   本示例使用预先准备的字符串模拟输入。
*)
section 3 "Reading from standard input";;

(* 注意：read_line 会阻塞等待输入。
   为了演示，我们使用字符串作为输入源。 *)

(* 使用 Scanf 模块从字符串解析输入 *)
let input_str = "42\n3.14\nhello world\n" in
Scanf.sscanf input_str "%d\n%f\n%s@\n" (fun i f s ->
  Printf.printf "Parsed from string:\n";
  Printf.printf "  Integer: %d\n" i;
  Printf.printf "  Float:   %f\n" f;
  Printf.printf "  String:  %s\n" s
);;

(* 从字符串逐行读取 *)
let read_lines_from_string s =
  let lines = ref [] in
  let pos = ref 0 in
  let n = String.length s in
  while !pos < n do
    let line_end = try String.index_from s !pos '\n' with Not_found -> n in
    let line = String.sub s !pos (line_end - !pos) in
    lines := line :: !lines;
    pos := line_end + 1
  done;
  List.rev !lines

let () =
  let test_input = "first line\nsecond line\nthird line\n" in
  let lines = read_lines_from_string test_input in
  Printf.printf "Lines from string (%d lines):\n" (List.length lines);
  List.iteri (fun i line ->
    Printf.printf "  %d: %s\n" (i + 1) line
  ) lines;;

(* Scanf 更复杂的解析 *)
let data = "Alice:30:95.5\nBob:21:87.3\nCharlie:19:92.0\n" in
let parse_line line =
  Scanf.sscanf line "%s@:%d:%f" (fun name age score -> (name, age, score))
in
let data_lines = read_lines_from_string data in
let parsed = List.map parse_line data_lines in
print_endline "Parsed student data:";
List.iter (fun (name, age, score) ->
  Printf.printf "  %s (age %d): %.1f\n" name age score
) parsed;;

(* ========================================================================
   4) 文件读写：open_in / open_out
   ========================================================================
   文件操作基本函数：
   - open_in filename : 以读模式打开文件，返回 in_channel
   - open_out filename : 以写模式打开文件，返回 out_channel（会覆盖原有文件）
   - input_line ic : 从 in_channel 读取一行
   - output_string oc s : 向 out_channel 写入字符串
   - close_in ic : 关闭输入通道
   - close_out oc : 关闭输出通道
   - input_char ic : 读取一个字符
   - output_char oc c : 写入一个字符
*)
section 4 "File I/O: open_in / open_out";;

(* 使用临时目录进行文件操作演示 *)
let tmp_dir = Filename.get_temp_dir_name ()
let demo_file = Filename.concat tmp_dir "ocaml_demo.txt"

(* 写入文件 *)
let write_demo_file () =
  let oc = open_out demo_file in
  output_string oc "Hello, World!\n";
  output_string oc "This is a demo file.\n";
  output_string oc "Line 3\n";
  output_string oc "Line 4\n";
  output_string oc "The end.\n";
  close_out oc;
  Printf.printf "File written to: %s\n" demo_file

let _ = write_demo_file ();;

(* 读取整个文件内容 *)
let read_file filename =
  let ic = open_in filename in
  let buf = Buffer.create 1024 in
  try
    while true do
      let line = input_line ic in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    done;
    ""  (* 不会执行到这里 *)
  with End_of_file ->
    close_in ic;
    Buffer.contents buf

let () =
  let content = read_file demo_file in
  Printf.printf "File contents (%d bytes):\n" (String.length content);
  print_string content;;

(* 读取文件字符数统计 *)
let count_chars filename =
  let ic = open_in filename in
  let count = ref 0 in
  try
    while true do
      ignore (input_char ic);
      incr count
    done;
    0
  with End_of_file ->
    close_in ic;
    !count

let () =
  let char_count = count_chars demo_file in
  Printf.printf "Character count: %d\n" char_count;;

(* 单词数统计 *)
let count_words filename =
  let content = read_file filename in
  let words = ref 0 in
  let in_word = ref false in
  String.iter (fun c ->
    match c with
    | ' ' | '\t' | '\n' | '\r' ->
        if !in_word then begin
          incr words;
          in_word := false
        end
    | _ -> in_word := true
  ) content;
  if !in_word then incr words;
  !words

let () =
  let word_count = count_words demo_file in
  Printf.printf "Word count: %d\n" word_count;;

(* ========================================================================
   5) 逐行读取
   ========================================================================
   逐行处理大文件，不需要一次性读入内存。
   使用 input_line + End_of_file 异常的模式。
*)
section 5 "Reading line by line";;

(* 逐行读取并处理 *)
let process_lines filename f =
  let ic = open_in filename in
  try
    while true do
      let line = input_line ic in
      f line
    done
  with End_of_file ->
    close_in ic;;

print_endline "Line-by-line processing:";
let line_num = ref 0 in
process_lines demo_file (fun line ->
  incr line_num;
  Printf.printf "  Line %2d (%d chars): %s\n"
    !line_num (String.length line) line
);;

(* 读取到 list 中 *)
let read_lines filename =
  let lines = ref [] in
  process_lines filename (fun line -> lines := line :: !lines);
  List.rev !lines

let () =
  let lines_list = read_lines demo_file in
  Printf.printf "Total lines: %d\n" (List.length lines_list);;

(* 带行号的读取 *)
let read_lines_numbered filename =
  let lines = ref [] in
  let num = ref 0 in
  process_lines filename (fun line ->
    incr num;
    lines := (!num, line) :: !lines
  );
  List.rev !lines

let () =
  let numbered = read_lines_numbered demo_file in
  List.iter (fun (n, line) ->
    if n = 3 then Printf.printf "Line 3: \"%s\"\n" line
  ) numbered;;

(* ========================================================================
   6) 追加写入
   ========================================================================
   追加写入（append mode）：在文件末尾添加内容而不是覆盖。
   - open_out_gen [Open_append; Open_creat] 0o666 filename
   - 或使用 open_out_gen 配合 Open_wronly, Open_append, Open_creat 等标志
*)
section 6 "Appending to files";;

let append_file filename content =
  let oc = open_out_gen [Open_append; Open_creat; Open_text] 0o666 filename in
  output_string oc content;
  close_out oc;;

(* 先打印原始内容 *)
Printf.printf "Before append:\n%s" (read_file demo_file);;

(* 追加内容 *)
append_file demo_file "Appended line 1\n";
append_file demo_file "Appended line 2\n";
append_file demo_file "Appended line 3\n";;

(* 打印追加后内容 *)
Printf.printf "After append:\n%s" (read_file demo_file);;

(* 重新写入（覆盖）以恢复演示文件 *)
let overwrite_file filename content =
  let oc = open_out filename in
  output_string oc content;
  close_out oc;;

overwrite_file demo_file "Hello, World!\nThis is a demo file.\nLine 3\nLine 4\nThe end.\n";;

(* 验证已恢复 *)
Printf.printf "Restored file (%d bytes, %d lines)\n"
  (String.length (read_file demo_file))
  (List.length (read_lines demo_file));;

(* ========================================================================
   7) 目录操作（Sys 模块）
   ========================================================================
   Sys 模块提供系统相关的功能：
   - Sys.file_exists : 检查文件是否存在
   - Sys.is_directory : 检查是否是目录
   - Sys.readdir : 读取目录内容
   - Sys.remove : 删除文件
   - Sys.rename : 重命名/移动文件
   - Sys.getcwd : 获取当前工作目录
   - Sys.chdir : 改变工作目录
   - Filename.concat : 拼接路径
   - Filename.basename : 获取文件名
   - Filename.dirname : 获取目录名
   - Filename.extension : 获取扩展名
*)
section 7 "Directory operations (Sys module)";;

(* 当前工作目录 *)
let cwd = Sys.getcwd () in
Printf.printf "Current working directory: %s\n" cwd;;

(* 文件和目录检查 *)
Printf.printf "Demo file exists: %b\n" (Sys.file_exists demo_file);
Printf.printf "Demo file is directory: %b\n" (Sys.is_directory demo_file);;

(* 路径操作 *)
Printf.printf "Demo file path: %s\n" demo_file;
Printf.printf "  Basename: %s\n" (Filename.basename demo_file);
Printf.printf "  Dirname: %s\n" (Filename.dirname demo_file);
Printf.printf "  Extension: %s\n" (Filename.extension demo_file);
Printf.printf "  Temp dir: %s\n" (Filename.get_temp_dir_name ());;

(* 目录列表 *)
let list_dir dir =
  let entries = Sys.readdir dir in
  Array.sort compare entries;
  entries

let () =
  let tmp_entries = list_dir (Filename.get_temp_dir_name ()) in
  Printf.printf "Entries in temp dir (first 10 of %d):\n" (Array.length tmp_entries);
  let count = ref 0 in
  Array.iter (fun name ->
    if !count < 10 then begin
      let full_path = Filename.concat (Filename.get_temp_dir_name ()) name in
      let kind = if Sys.is_directory full_path then "[DIR]" else "[FILE]" in
      Printf.printf "  %s %s\n" kind name;
      incr count
    end
  ) tmp_entries;;

(* 创建和删除子目录 *)
let () =
  let test_dir = Filename.concat tmp_dir "ocaml_test_dir" in
  if not (Sys.file_exists test_dir) then
    Unix.mkdir test_dir 0o755;
  Printf.printf "Created test directory: %s\n" test_dir;
  Printf.printf "Is directory: %b\n" (Sys.is_directory test_dir);

  (* 在子目录中创建文件 *)
  let test_file1 = Filename.concat test_dir "file1.txt" in
  let test_file2 = Filename.concat test_dir "file2.txt" in
  overwrite_file test_file1 "Content of file 1\n";
  overwrite_file test_file2 "Content of file 2\n";

  let test_entries = list_dir test_dir in
  Printf.printf "Entries in test dir: [%s]\n"
    (String.concat ", " (Array.to_list test_entries));

  (* 清理测试文件和目录 *)
  Sys.remove test_file1;
  Sys.remove test_file2;
  Unix.rmdir test_dir;
  Printf.printf "Cleaned up test directory: %s (exists: %b)\n" test_dir (Sys.file_exists test_dir);;

(* ========================================================================
   8) 环境变量
   ========================================================================
   环境变量操作：
   - Sys.getenv var : 获取环境变量的值（不存在时抛出 Not_found）
   - Sys.getenv_opt var : 获取环境变量（不存在时返回 None）
   - Unix.putenv var value : 设置环境变量
*)
section 8 "Environment variables";;

(* 读取常见环境变量 *)
let print_env var =
  match Sys.getenv_opt var with
  | Some value -> Printf.printf "  %s = %s\n" var value
  | None -> Printf.printf "  %s = (not set)\n" var;;

print_endline "Common environment variables:";
print_env "HOME";;
print_env "PATH";;
print_env "USER";;
print_env "LANG";;
print_env "SHELL";;

(* 设置和读取自定义环境变量 *)
Unix.putenv "MY_CUSTOM_VAR" "hello_world_123";;
Printf.printf "\nCustom env var:\n";
print_env "MY_CUSTOM_VAR";;

Unix.putenv "MY_CUSTOM_VAR" "updated_value";;
print_env "MY_CUSTOM_VAR";;

(* 程序参数 *)
Printf.printf "\nProgram name: %s\n" Sys.argv.(0);
Printf.printf "Argument count: %d\n" (Array.length Sys.argv - 1);
if Array.length Sys.argv > 1 then begin
  print_endline "Arguments:";
  for i = 1 to Array.length Sys.argv - 1 do
    Printf.printf "  %d: %s\n" i Sys.argv.(i)
  done
end else
  print_endline "No arguments passed.";;

(* 清理演示文件 *)
Sys.remove demo_file;
Printf.printf "\nCleaned up demo file: %s (exists: %b)\n" demo_file (Sys.file_exists demo_file);;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 18 jieshu ===="  (* 第十八个文件结束 *)
