(* ======================================================================
   08_strings.ml - 字符串与字符
   ======================================================================
   本文件演示 OCaml 的字符串和字符操作：
     - 字符串基本操作：长度、连接、取字符
     - String.sub, String.concat, String.split_on_char
     - 字符类型 char
     - 字符串与列表互转
     - 字符串不可变性
     - 格式化输出 Printf

   运行方式：
     ocaml 08_strings.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) 字符串基本操作 ---- *)
(* String.length : string -> int
   String.get : string -> int -> char   （也可以用 s.[i]）
   String.concat : string -> string list -> string
   (^) : string -> string -> string     （拼接运算符） *)

let demo_basic_ops () =
  say "=== Section 1: basic string operations ===";
  let s = "Hello, World!" in
  say ("s = \"" ^ s ^ "\"");
  print_string "String.length s = "; print_int (String.length s); say "";

  (* 取单个字符 *)
  print_string "s.[0] = '"; print_char s.[0]; say "'";
  print_string "s.[7] = '"; print_char s.[7]; say "'";

  (* 字符串拼接 *)
  let s2 = "OCaml " ^ "is " ^ "fun" in
  say ("\"OCaml \" ^ \"is \" ^ \"fun\" = \"" ^ s2 ^ "\"");

  (* 重复字符串 *)
  let rec repeat s n =
    if n <= 0 then "" else s ^ repeat s (n - 1)
  in
  say ("repeat \"ab\" 3 = \"" ^ repeat "ab" 3 ^ "\"");
  say "Strings are indexed from 0 with s.[i] syntax."

(* ---- 2) String.sub, String.concat, String.split_on_char ---- *)
(* String.sub s start len : 取子串
   String.concat sep list : 用分隔符连接字符串列表
   String.split_on_char c s : 按字符分割字符串 *)

let demo_sub_concat_split () =
  say "";
  say "=== Section 2: sub, concat, split_on_char ===";
  let s = "Hello, World!" in

  (* String.sub *)
  let sub1 = String.sub s 0 5 in      (* "Hello" *)
  let sub2 = String.sub s 7 5 in      (* "World" *)
  say ("String.sub s 0 5 = \"" ^ sub1 ^ "\"");
  say ("String.sub s 7 5 = \"" ^ sub2 ^ "\"");

  (* String.concat *)
  let words = ["apple"; "banana"; "cherry"] in
  let joined = String.concat ", " words in
  say ("String.concat \", \" [apple; banana; cherry] = \"" ^ joined ^ "\"");

  let joined_empty = String.concat "" ["a"; "b"; "c"] in
  say ("String.concat \"\" [a;b;c] = \"" ^ joined_empty ^ "\"");

  (* String.split_on_char *)
  let csv = "apple,banana,cherry,date" in
  let parts = String.split_on_char ',' csv in
  say ("split_on_char ',' \"" ^ csv ^ "\" =");
  List.iter (fun p -> say ("  \"" ^ p ^ "\"")) parts;

  let path = "/usr/local/bin/ocaml" in
  let path_parts = String.split_on_char '/' path in
  say ("split_on_char '/' \"" ^ path ^ "\" = [" ^
       String.concat "; " (List.map (fun s -> "\"" ^ s ^ "\"") path_parts) ^ "]");
  say "sub extracts substrings; split_on_char is useful for parsing."

(* ---- 3) 字符类型 char ---- *)
(* char 是 8 位字符类型。
   Char.code : char -> int
   Char.chr : int -> char
   Char.uppercase_ascii, Char.lowercase_ascii 等 *)

let demo_char_type () =
  say "";
  say "=== Section 3: char type ===";
  let c1 = 'A' in
  let c2 = 'z' in

  print_string "c1 = '"; print_char c1; say "'";
  print_string "c2 = '"; print_char c2; say "'";

  (* Char.code / Char.chr *)
  print_string "Char.code 'A' = "; print_int (Char.code c1); say "";
  print_string "Char.code 'z' = "; print_int (Char.code c2); say "";
  print_string "Char.chr 97 = '"; print_char (Char.chr 97); say "'";

  (* 大小写转换 *)
  print_string "Char.uppercase_ascii 'a' = '";
  print_char (Char.uppercase_ascii 'a'); say "'";
  print_string "Char.lowercase_ascii 'Z' = '";
  print_char (Char.lowercase_ascii 'Z'); say "'";

  (* 字符判断 *)
  let is_digit c = c >= '0' && c <= '9' in
  say ("is_digit '5' = " ^ string_of_bool (is_digit '5'));
  say ("is_digit 'a' = " ^ string_of_bool (is_digit 'a'));
  say "char is 8-bit; convert with Char.code / Char.chr."

(* ---- 4) 字符串与列表互转 ---- *)
(* String.to_seq / List.of_seq : 字符串转字符列表
   String.of_seq / List.to_seq : 字符列表转字符串
   也可以手动实现转换来理解原理。 *)

let demo_string_list_conversion () =
  say "";
  say "=== Section 4: string <-> list conversions ===";
  let s = "Hello" in

  (* 字符串转字符列表 *)
  let chars = List.of_seq (String.to_seq s) in
  say ("\"Hello\" -> char list: [" ^
       String.concat "; " (List.map (fun c -> "'" ^ String.make 1 c ^ "'") chars) ^ "]");

  (* 字符列表转字符串 *)
  let cl = ['O'; 'C'; 'a'; 'm'; 'l'] in
  let s2 = String.of_seq (List.to_seq cl) in
  say ("char list -> string: \"" ^ s2 ^ "\"");

  (* 用 List.map 处理字符串中的每个字符 *)
  let to_uppercase s =
    s |> String.to_seq |> Seq.map Char.uppercase_ascii |> String.of_seq
  in
  say ("to_uppercase \"hello\" = \"" ^ to_uppercase "hello" ^ "\"");

  (* 手动实现字符串反转（通过列表） *)
  let reverse_string s =
    s |> String.to_seq |> List.of_seq |> List.rev |> List.to_seq |> String.of_seq
  in
  say ("reverse \"Hello\" = \"" ^ reverse_string "Hello" ^ "\"");
  say "Convert via Seq or manually iterate to process strings."

(* ---- 5) 字符串不可变性 ---- *)
(* OCaml 的 string 是不可变的。所有"修改"操作都返回新字符串。
   如果需要可变字符串，使用 Bytes 模块。 *)

let demo_immutability () =
  say "";
  say "=== Section 5: string immutability ===";
  let original = "hello" in
  let modified = String.capitalize_ascii original in

  say ("original = \"" ^ original ^ "\"");
  say ("modified (capitalized) = \"" ^ modified ^ "\"");
  say "original is unchanged - strings are immutable.";

  (* Bytes 是可变的字节序列 *)
  let b = Bytes.of_string "hello" in
  Bytes.set b 0 'H';  (* 原地修改 *)
  say "";
  say "Bytes (mutable):";
  say ("  Bytes.of_string \"hello\" then set [0] to 'H' = \"" ^ Bytes.to_string b ^ "\"");

  say "Use string for immutable text; use Bytes for mutable byte buffers."

(* ---- 6) 格式化输出 Printf ---- *)
(* Printf.printf / Printf.sprintf 提供格式化输出。
   格式说明符：
     %d  int
     %f  float
     %s  string
     %c  char
     %b  bool
     %!  flush
     %x  hex
     %o  octal
     %Lx int64 hex
     etc. *)

let demo_printf () =
  say "";
  say "=== Section 6: formatted output (Printf) ===";

  Printf.printf "Integer: %d\n" 42;
  Printf.printf "Float:   %f\n" 3.14159;
  Printf.printf "String:  %s\n" "hello";
  Printf.printf "Char:    %c\n" 'Z';
  Printf.printf "Bool:    %b\n" true;
  Printf.printf "Hex:     %x\n" 255;
  Printf.printf "Octal:   %o\n" 63;

  (* 更复杂的格式 *)
  Printf.printf "\nMixed format:\n";
  Printf.printf "  %s is %d years old, height %.2f m\n" "Alice" 30 1.65;

  (* sprintf 返回格式化后的字符串 *)
  let message = Printf.sprintf "Result: %d + %d = %d" 3 4 (3 + 4) in
  say ("sprintf result: \"" ^ message ^ "\"");

  (* 宽度与对齐 *)
  Printf.printf "\nWidth and padding:\n";
  Printf.printf "  |%10s|%10s|\n" "Name" "Score";
  Printf.printf "  |%10s|%10d|\n" "Alice" 95;
  Printf.printf "  |%10s|%10d|\n" "Bob" 87;

  say "Printf.printf for formatted output; sprintf returns a string."

(* ---- 主程序 ---- *)
let () =
  demo_basic_ops ();
  demo_sub_concat_split ();
  demo_char_type ();
  demo_string_list_conversion ();
  demo_immutability ();
  demo_printf ();
  say "";
  say "==== 08 jieshu ===="

(* ==== 08 结束 ==== *)
