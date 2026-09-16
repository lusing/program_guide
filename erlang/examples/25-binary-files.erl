%% ---------------------------------------------------------------------------
%%  25) 文件 I/O 与二进制序列化
%%
%%  编译：erlc -Werror -Wall -o build/ebin examples/25-binary-files.erl
%%  运行：erl -noshell -pa build/ebin -run '25-binary-files' main -s init stop
%%
%%  这一章解决三件实际的事：
%%    1. 文件和目录怎么读写、路径怎么拼；
%%    2. 「字符串」在这个语言里到底是什么 —— 为什么写文件会 badarg；
%%    3. 怎么把数据打包成字节（二进制协议）以及如何序列化成字节流。
%%
%%  本章会用到的临时目录固定在 /tmp/erl-demo-25/，开头重建、结尾删掉，
%%  所以可以反复跑，输出稳定。
%% ---------------------------------------------------------------------------
-module('25-binary-files').

%% #file_info 记录的定义在 kernel 的头文件里
-include_lib("kernel/include/file.hrl").

-export([main/0]).

%% d/2 用 ~p：可打印的字节列表会被美化成字符串（[104,105] → "hi"）。
%% 想强制按「列表/字节」看数字，用 ds/2（内部用 ~w）。
d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
ds(Label, Value) -> io:format("  ~ts = ~w~n", [Label, Value]).

-define(DIR, "/tmp/erl-demo-25").

main() ->
    _ = logger:remove_handler(default),
    io:format("=== 25) 文件 I/O 与二进制序列化 ===~n"),
    reset_dir(),
    paths(),
    dirs_and_meta(),
    whole_file_io(),
    encoding_trap(),
    streaming_io(),
    text_lines(),
    binary_protocol(),
    serialization(),
    mistakes(),
    cleanup(),
    io:format("==== 25 结束 ====~n"),
    ok.

reset_dir() ->
    _ = file:del_dir_r(?DIR),
    ok = file:make_dir(?DIR),
    ok.

cleanup() ->
    ok = file:del_dir_r(?DIR),
    ok.

%% ---------------------------------------------------------------------------
%% 1) 路径：一律用 filename，不要手拼字符串
%% ---------------------------------------------------------------------------
paths() ->
    io:format("~n== 1) 路径：filename 模块 ==~n"),
    io:format("  手拼 \"a\" ++ \"/\" ++ \"b\" 在 Windows 上就错了；"
              "filename 会按当前系统的分隔符处理。~n"),
    d("filename:join([\"/tmp\", \"a\", \"b.txt\"])", filename:join(["/tmp", "a", "b.txt"])),
    d("filename:split(上一条)", filename:split(filename:join(["/tmp", "a", "b.txt"]))),
    d("filename:basename", filename:basename("/tmp/a/b.txt")),
    d("filename:dirname", filename:dirname("/tmp/a/b.txt")),
    d("filename:rootname（去掉扩展名）", filename:rootname("/tmp/a/b.txt")),
    d("filename:extension", filename:extension("/tmp/a/b.txt")),
    d("  没有扩展名时 extension", filename:extension("/tmp/a/README")),
    d("  只有点开头的文件（.gitignore）", filename:extension("/tmp/a/.gitignore")),
    d("filename:absname(\"b.txt\") 转成了绝对路径（pathtype 验证）",
      filename:pathtype(filename:absname("b.txt"))),
    d("filename:pathtype（相对/绝对/卷相关）", filename:pathtype("/tmp/a/b.txt")),
    d("  相对路径的 pathtype", filename:pathtype("b.txt")),
    d("filename:nativename 在 macOS 上就是原样",
      filename:nativename(filename:join(["a", "b"]))),
    io:format("~n  -- 两个容易踩的点 --~n"),
    d("join 的第二参数给 binary 时返回什么类型",
      {is_binary(filename:join(?DIR, <<"b.txt">>)),
       is_list(filename:join(?DIR, <<"b.txt">>))}),
    d("  join 会保留 binary（不是自动转 list）—— 所以 file 模块两种都能吃",
      filename:join(?DIR, <<"b.txt">>)),
    d("filename:join 传入绝对路径的第二段（会直接替换）",
      filename:join("/a/b", "/c/d")),
    ok.

%% ---------------------------------------------------------------------------
%% 2) 目录与文件元信息
%% ---------------------------------------------------------------------------
dirs_and_meta() ->
    io:format("~n== 2) 目录与文件元信息 ==~n"),
    Sub = filename:join(?DIR, "sub"),
    d("filelib:ensure_dir(一个还不存在的文件路径)",
      filelib:ensure_dir(filename:join(Sub, "x.txt"))),
    d("  之后 sub 目录存在了吗", filelib:is_dir(Sub)),
    d("  注意：ensure_dir 只建**目录**，不建文件", filelib:is_file(filename:join(Sub, "x.txt"))),

    F = filename:join(?DIR, "meta.txt"),
    ok = file:write_file(F, <<"0123456789">>),
    d("filelib:is_file / is_dir / is_regular",
      {filelib:is_file(F), filelib:is_dir(F), filelib:is_regular(F)}),
    d("filelib:file_size", filelib:file_size(F)),
    d("filelib:last_modified 是个非零时间", filelib:last_modified(F) > 0),

    {ok, Info} = file:read_file_info(F),
    d("read_file_info 返回一个 #file_info 记录", true),
    d("  size", Info#file_info.size),
    d("  type", Info#file_info.type),
    d("  access", Info#file_info.access),
    d("  mode（是个整数，按位存权限）", is_integer(Info#file_info.mode)),
    d("  mtime 是个非零时间", Info#file_info.mtime > 0),

    io:format("~n  -- 列目录 --~n"),
    ok = file:write_file(filename:join(?DIR, "z.txt"), <<"z">>),
    ok = file:write_file(filename:join(?DIR, "y.dat"), <<"y">>),
    d("file:list_dir（排序后）", lists:sort(element(2, file:list_dir(?DIR)))),
    d("filelib:wildcard(\"*.txt\")", lists:sort(filelib:wildcard(filename:join(?DIR, "*.txt")))),
    d("wildcard 只匹配**文件名**，不对路径分隔符做特殊处理",
      lists:sort([filename:basename(P) || P <- filelib:wildcard(filename:join(?DIR, "*"))])),
    d("file:open 一个目录会怎样", file:open(?DIR, [read])),
    d("file:read_file 一个目录会怎样", file:read_file(?DIR)),
    ok.

%% ---------------------------------------------------------------------------
%% 3) 一次性读写：read_file / write_file 与 iodata
%% ---------------------------------------------------------------------------
whole_file_io() ->
    io:format("~n== 3) 一次性读写与 iodata ==~n"),
    F = filename:join(?DIR, "one.txt"),
    d("file:write_file（二进制）", file:write_file(F, <<"hello">>)),
    d("file:read_file", file:read_file(F)),
    d("file:read_file 一个不存在的文件（不抛，返回 error 元组）",
      file:read_file(filename:join(?DIR, "nope.txt"))),

    io:format("~n  -- iodata：比 binary 更宽松的\"能写出去的东西\" --~n"),
    io:format("  iodata = binary | 字节列表 | 这两者的任意嵌套列表。"
              "好处是拼接不用复制。~n"),
    Deep = ["ab", ["cd", <<"ef">>], "g"],
    d("写深嵌套 iodata", file:write_file(F, Deep)),
    d("  读回来", file:read_file(F)),
    d("iolist_size（不用真的拼起来就能算长度）", iolist_size(Deep)),
    d("iolist_to_binary（真的拼起来）", iolist_to_binary(Deep)),
    d("iolist_to_iovec 存在吗（OTP 里有）",
      erlang:function_exported(erlang, iolist_to_iovec, 1)),

    io:format("~n  -- 追加 / 重命名 / 复制 / 删除 --~n"),
    d("write_file 加 [append]", file:write_file(F, <<"!">>, [append])),
    d("  读回来", file:read_file(F)),
    G = filename:join(?DIR, "two.txt"),
    d("file:copy 返回拷贝的字节数", file:copy(F, G)),
    d("file:rename", file:rename(G, filename:join(?DIR, "three.txt"))),
    d("file:delete", file:delete(filename:join(?DIR, "three.txt"))),
    d("  删完之后", filelib:is_file(filename:join(?DIR, "three.txt"))),
    d("file:delete 一个不存在的文件（不报错）",
      file:delete(filename:join(?DIR, "never-existed"))),
    ok.

%% ---------------------------------------------------------------------------
%% 4) 编码陷阱：字符串是「码点列表」，文件是「字节」
%% ---------------------------------------------------------------------------
encoding_trap() ->
    io:format("~n== 4) 编码陷阱：码点列表 vs 字节 ==~n"),
    io:format("  \"你好\" 在内存里是码点列表 [20320, 22909]，而文件里存的是字节。~n"),
    io:format("  file:write_file 要求参数是**字节** iodata（每个元素 0..255），~n"),
    io:format("  所以直接把中文字符串交给它会 badarg —— 这是最常见的踩坑。~n~n"),
    F = filename:join(?DIR, "enc.txt"),

    d("写纯 ASCII 字符串（码点都 <= 255，正好合法）", file:write_file(F, "abc")),
    d("  读回来", file:read_file(F)),
    d("写含中文的字符串 \"你好\"（注意：是**返回** error 元组，不是抛异常）",
      file:write_file(F, "你好")),
    d("正确写法 1：<<\"你好\"/utf8>>", file:write_file(F, <<"你好"/utf8>>)),
    d("  读回来（字节）", file:read_file(F)),
    d("  byte_size（UTF-8 下一个汉字 3 字节）",
      byte_size(element(2, file:read_file(F)))),
    d("正确写法 2：unicode:characters_to_binary(\"你好\")",
      file:write_file(F, unicode:characters_to_binary("你好"))),
    d("  byte_size", byte_size(element(2, file:read_file(F)))),

    io:format("~n  -- 反向：字节 → 字符串 --~n"),
    d("unicode:characters_to_list(<<\"你好\"/utf8>>)",
      unicode:characters_to_list(<<"你好"/utf8>>)),
    d("  拿 latin1 字节去当 UTF-8 解会失败（返回 incomplete/error 元组）",
      unicode:characters_to_list(<<99, 97, 102, 233>>)),
    d("  lists:flatten(io_lib:format(\"~ts\", [<<\"你好\"/utf8>>]))",
      lists:flatten(io_lib:format("~ts", [<<"你好"/utf8>>]))),

    io:format("~n  -- write_file/3 加 {encoding, utf8} 能救吗？不能 --~n"),
    io:format("  write_file 写的是**字节**，encoding 选项对它无效（也不报错），~n"),
    io:format("  数据里只要有大于 255 的码点，照样 badarg：~n"),
    d("write_file(F, <<\"x\">>, [{encoding, utf8}])（字节本来就合法 → ok）",
      file:write_file(F, <<"x">>, [{encoding, utf8}])),
    d("write_file(F, \"你好\", [{encoding, utf8}])（选项没帮上忙）",
      file:write_file(F, "你好", [{encoding, utf8}])),
    d("write_file(F, [\"你\",\"好\"], [{encoding, utf8}])（拆开也不行）",
      file:write_file(F, ["你", "好"], [{encoding, utf8}])),
    io:format("  想让运行时替你做 UTF-8 编码，得走 file:open + io:put_chars（第 6 节）。~n"),
    d("  顺便：不认识的选项被**静默忽略**（返回 ok）—— 拼错选项不会报错",
      file:write_file(F, <<"x">>, [{totally_made_up, 1}])),

    io:format("~n  -- 字符串长度：length 数的是码点，不是字节 --~n"),
    d("length(\"你好\")（码点数）", length("你好")),
    d("byte_size(<<\"你好\"/utf8>>)（UTF-8 字节数）", byte_size(<<"你好"/utf8>>)),
    d("string:length(\"你好\")（字素簇数）", string:length("你好")),
    d("  string:slice(\"你好世界\", 1, 2)（按码点切）", string:slice("你好世界", 1, 2)),
    ok.

%% ---------------------------------------------------------------------------
%% 5) 流式读写
%% ---------------------------------------------------------------------------
streaming_io() ->
    io:format("~n== 5) 流式读写：open / read / position / pread ==~n"),
    F = filename:join(?DIR, "stream.txt"),
    ok = file:write_file(F, <<"abcdefg">>),

    {ok, Fd} = file:open(F, [read, binary]),
    d("file:read(Fd, 3)", file:read(Fd, 3)),
    d("file:position(Fd, cur)（当前偏移）", file:position(Fd, cur)),
    d("file:position(Fd, {bof, 1})（绝对定位）", file:position(Fd, {bof, 1})),
    d("file:read(Fd, 2)", file:read(Fd, 2)),
    d("file:pread(Fd, 0, 2)（定位读，不动当前偏移）", file:pread(Fd, 0, 2)),
    d("  之后 position 还是刚才的位置（pread 不影响）", file:position(Fd, cur)),
    d("file:read(Fd, 100) 超过文件长度 → 给剩下的，不是 eof", file:read(Fd, 100)),
    d("file:read(Fd, 1) 再读 → eof", file:read(Fd, 1)),
    d("file:position(Fd, eof)", file:position(Fd, eof)),
    ok = file:close(Fd),
    d("关掉之后再 read（句柄变成 terminated）", file:read(Fd, 1)),

    io:format("~n  -- 写：默认覆盖，不会问你 --~n"),
    {ok, Fd2} = file:open(F, [write, binary]),
    d("file:write(Fd2, <<\"XY\">>)", file:write(Fd2, <<"XY">>)),
    ok = file:close(Fd2),
    d("  文件内容（被截断了，只剩 2 字节）", file:read_file(F)),
    {ok, Fd3} = file:open(F, [append, binary]),
    ok = file:write(Fd3, <<"Z">>),
    ok = file:close(Fd3),
    d("[append] 打开再写", file:read_file(F)),

    io:format("~n  -- raw / delayed_write 什么时候用 --~n"),
    io:format("  默认打开的是\"文件服务器\"的句柄：所有进程共享，可以 read/pread，~n"),
    io:format("  但每次调用都有进程间开销。加 raw 就是直接用驱动，快但功能少。~n"),
    {ok, Fd4} = file:open(F, [read, binary, raw]),
    d("raw 模式下的 read", file:read(Fd4, 1)),
    d("raw 模式下用 io:get_line（io 协议不支持）",
      try io:get_line(Fd4, "") of L -> {unexpected, L}
      catch error:R2 -> {error, R2} end),
    ok = file:close(Fd4),
    d("delayed_write：攒够了再落盘（用 file:write_file/3 传选项）",
      file:write_file(F, <<"q">>, [binary, {delayed_write, 64, 200}])),
    ok.

%% ---------------------------------------------------------------------------
%% 6) 文本文件与 io 协议
%% ---------------------------------------------------------------------------
text_lines() ->
    io:format("~n== 6) 按行读写与 {encoding, utf8} ==~n"),
    F = filename:join(?DIR, "lines.txt"),
    ok = file:write_file(F, <<"第一行\n第二行\n第三行"/utf8>>),

    {ok, Fd} = file:open(F, [read, {encoding, utf8}]),
    io:format("  io:get_line 第 1 行 = ~ts", [io:get_line(Fd, "")]),
    io:format("  io:get_line 第 2 行 = ~ts", [io:get_line(Fd, "")]),
    io:format("  io:get_line 第 3 行 = ~ts~n", [io:get_line(Fd, "")]),
    d("io:get_line 到末尾 → eof（不是空字符串）", io:get_line(Fd, "")),
    ok = file:close(Fd),

    io:format("~n  上面的行是**字符串**（码点列表），因为打开时给了 {encoding, utf8}。~n"),
    io:format("  不给 encoding 就是 latin1，读 UTF-8 中文会得到一串 latin1 字符。~n"),
    {ok, Fd2} = file:open(F, [read]),
    L1 = io:get_line(Fd2, ""),
    d("latin1 打开读第一行：长度（UTF-8 的 3 字节被当成 3 个字符）", length(L1)),
    ds("  这些字符的码点（用 ~w 看，不然 ~p 会美化成乱码字符串）", L1),
    ok = file:close(Fd2),

    io:format("~n  -- 写：latin1 设备写 unicode 会抛 no_translation --~n"),
    {ok, Fd3} = file:open(filename:join(?DIR, "out1.txt"), [write]),
    d("latin1 设备 io:put_chars(\"你好\")（{抛出, 类, 原因}）",
      try io:put_chars(Fd3, "你好") of R -> {unexpected_returned, R}
      catch Class:Reason -> {thrown, Class, Reason} end),
    ok = file:close(Fd3),
    {ok, Fd4} = file:open(filename:join(?DIR, "out2.txt"), [write, {encoding, utf8}]),
    d("utf8 设备 io:put_chars(\"你好\")", io:put_chars(Fd4, "你好")),
    ok = file:close(Fd4),
    d("  写出来的字节数", byte_size(element(2, file:read_file(filename:join(?DIR, "out2.txt"))))),

    io:format("~n  -- file:consult：把 Erlang 项存成配置文件 --~n"),
    TermsFile = filename:join(?DIR, "conf.terms"),
    ok = file:write_file(TermsFile,
                         [io_lib:format("~p.~n", [T]) || T <- [{name, <<"kv"/utf8>>}, {port, 8080}]]),
    d("file:consult", file:consult(TermsFile)),
    ok = file:write_file(filename:join(?DIR, "empty.terms"), <<>>),
    d("consult 一个空文件", file:consult(filename:join(?DIR, "empty.terms"))),
    ok = file:write_file(filename:join(?DIR, "bad.terms"), <<"this is not a term">>),
    d("consult 一个坏文件（第几行 + 解析器原因）",
      element(2, file:consult(filename:join(?DIR, "bad.terms")))),
    ok.

%% ---------------------------------------------------------------------------
%% 7) 二进制协议实战
%% ---------------------------------------------------------------------------
binary_protocol() ->
    io:format("~n== 7) 二进制协议：位语法实战 ==~n"),
    io:format("  位语法不只是\"能拼字节\"，它同时是**构造**和**匹配**，~n"),
    io:format("  编解码写起来是对称的，这一节做一个定长头 + 变长体的报文格式。~n~n"),
    io:format("  报文格式（大端）：~n"),
    io:format("    Magic   16 位   0x45 0x52 （'E' 'R'）~n"),
    io:format("    Ver      8 位   版本号~n"),
    io:format("    Type     8 位   消息类型~n"),
    io:format("    Len     16 位   Payload 字节数~n"),
    io:format("    Payload  Len 字节~n"),
    io:format("    Crc     32 位   erlang:crc32(Payload)~n~n"),

    Pkt = encode(1, 7, <<"hello">>),
    d("encode(1, 7, <<\"hello\">>) 的字节", Pkt),
    d("  总字节数", byte_size(Pkt)),
    d("decode 回去", decode(Pkt)),
    d("decode 空 payload", decode(encode(1, 0, <<>>))),
    d("改一个字节（把 Ver 从 1 改成 2）",
      decode(setelement_pkt(Pkt))),

    io:format("~n  -- 解不开的三种情况，都得显式处理 --~n"),
    d("Magic 不对", decode(<<0, 0, 1, 7, 0, 1, 0>>)),
    d("Magic 对了但长度不够（头就 8 字节，只给了 7）",
      decode(<<16#45, 16#52, 1, 7, 0, 5, $h>>)),
    d("头够了但 payload 短了（说 5 字节只给了 2）",
      decode(<<16#45, 16#52, 1, 7, 0, 5, $h, $e>>)),
    d("Crc 对不上（payload 被改了）",
      decode(<<16#45, 16#52, 1, 7, 0, 5, $h, $e, $l, $l, $x, 0, 0, 0, 0>>)),

    io:format("~n  -- 位语法的常用写法（全部实测） --~n"),
    d("<<258:16/big>> vs <<258:16/little>>", {<<258:16/big>>, <<258:16/little>>}),
    d("binary:encode_unsigned(258) / little",
      {binary:encode_unsigned(258), binary:encode_unsigned(258, little)}),
    d("binary:encode_unsigned(-1)（负数要自己用 /signed）",
      try binary:encode_unsigned(-1) of V -> {unexpected, V}
      catch error:R -> {error, R} end),
    d("<<-1:8/signed>> 的字节", <<-1:8/signed>>),
    d("<<1:3, 5:5>>（非整字节）", <<1:3, 5:5>>),
    d("  binary:at(它, 0)", binary:at(<<1:3, 5:5>>, 0)),
    d("  bit_size vs byte_size（byte_size 向上取整）",
      {bit_size(<<1:3>>), byte_size(<<1:3>>)}),
    d("<<1.5:64/float>> vs <<1.5:32/float>>",
      {<<1.5:64/float>>, <<1.5:32/float>>}),
    d("<<\"A\":8/unit:2>>（unit 是重复倍数）", <<"A":8/unit:2>>),
    d("binary:part / split / match / replace",
      {binary:part(<<"hello world">>, 0, 5),
       binary:split(<<"a,b,c">>, <<",">>, [global]),
       binary:match(<<"hello world">>, <<"world">>),
       binary:replace(<<"a-b">>, <<"-">>, <<"+">>)}),
    d("binary:encode_hex / decode_hex 往返",
      binary:decode_hex(binary:encode_hex(<<1, 2, 255>>))),
    d("base64:encode(<<\"hi\">>)", base64:encode(<<"hi">>)),
    ok.

%% 编码：<<魔法:16, 版本:8, 类型:8, 长度:16, 负载/bytes, CRC:32>>
encode(Ver, Type, Payload) when is_binary(Payload) ->
    Len = byte_size(Payload),
    Crc = erlang:crc32(Payload),
    <<16#45, 16#52, Ver:8, Type:8, Len:16/big, Payload/binary, Crc:32/big>>.

%% 解码：模式匹配一次完成；任何对不上的情况走后面的 catch-all 子句。
decode(<<16#45, 16#52, Ver:8, Type:8, Len:16/big,
         Payload:Len/binary, Crc:32/big>>)
  when byte_size(Payload) =:= Len ->
    case erlang:crc32(Payload) of
        Crc -> {ok, #{ver => Ver, type => Type, payload => Payload}};
        _ -> {error, crc_mismatch}
    end;
decode(<<16#45, 16#52, _/binary>>) -> {error, truncated};
decode(<<_/binary>>) -> {error, bad_magic};
decode(_) -> {error, not_binary}.

%% 把版本号字节改掉（第 3 个字节），用来演示 crc/结构校验拦不住头字段被改
setelement_pkt(<<M1:8, M2:8, _Ver:8, Rest/binary>>) ->
    <<M1:8, M2:8, 2:8, Rest/binary>>.

%% ---------------------------------------------------------------------------
%% 8) 序列化：term_to_binary
%% ---------------------------------------------------------------------------
serialization() ->
    io:format("~n== 8) 序列化：term_to_binary / binary_to_term ==~n"),
    T = {user, <<"张三"/utf8>>, 30, #{tags => [a, b]}},
    B = term_to_binary(T),
    d("原始 term", T),
    d("term_to_binary 的字节数", byte_size(B)),
    d("  第一个字节是外部格式版本号（固定 131）", binary:at(B, 0)),
    d("binary_to_term 完全还原（不是\"像\"，是相等）", binary_to_term(B) =:= T),

    Big = lists:seq(1, 20000),
    io:format("  -- 压缩：对重复/长列表效果明显 --~n"),
    d("  20000 个整数的列表：未压缩 / 压缩后字节数",
      {byte_size(term_to_binary(Big)),
       byte_size(term_to_binary(Big, [{compressed, 9}]))}),
    d("  上面那个小 term：未压缩 / 压缩后",
      {byte_size(B), byte_size(term_to_binary(T, [{compressed, 9}]))}),
    d("  压缩对很短的数据反而变**大**（头信息开销）—— 别无脑开",
      byte_size(term_to_binary({a}, [{compressed, 9}])) >
      byte_size(term_to_binary({a}))),
    d("  压缩级别 0（几乎不压）", byte_size(term_to_binary(Big, [{compressed, 0}]))),

    io:format("~n  -- 安全性：binary_to_term 会**创建原子** --~n"),
    io:format("  原子表不会回收，所以拿不可信输入去解码是一个真实的 DoS 入口。~n"),
    d("[safe] 解一个本节点没见过的原子（手工拼的外部格式）",
      try binary_to_term(unknown_atom_ext(), [safe]) of V -> {unexpected, V}
      catch error:R -> {error, R} end),
    io:format("  （上面故意先解一个「肯定没见过」的原子；"
              "如果先默认解过一次，它就在原子表里了，safe 也就拦不住了。）~n"),

    d("binary_to_term 喂垃圾字节",
      try binary_to_term(<<0, 1, 2, 3>>) of V2 -> {unexpected, V2}
      catch error:R2 -> {error, R2} end),
    d("term_to_binary 一个 pid（能编，但解出来只在原节点有意义）",
      is_binary(term_to_binary(self()))),

    io:format("~n  -- 什么时候用哪个 --~n"),
    Choices = [{"跨节点/同语言进程之间传数据", "term_to_binary（快、保真、支持任意 term）"},
               {"要落盘、以后还要读", "term_to_binary + 版本号字段（别裸存，改结构就解不了了）"},
               {"要和其它语言互通", "自己定位长协议（第 7 节）或 JSON（jsx/jiffy 等库）"},
               {"配置给**人**看", "file:consult（就是 Erlang 项，能写注释）"},
               {"配置给**机器**批量下发", ".app 的 env，或者 sys.config"}],
    [begin
         io:format("  ~ts~n", [When]),
         io:format("      → ~ts~n", [Use])
     end || {When, Use} <- Choices],
    ok.

%% 手工拼一个「外部格式里的原子」，避免在本节点先把它创建出来。
%% 131 = 版本号，100 = ATOM_EXT，后面 16 位长度 + 字节。
unknown_atom_ext() ->
    Name = "zz_atom_that_does_not_exist_yet",
    <<131, 100, (length(Name)):16, (list_to_binary(Name))/binary>>.

%% ---------------------------------------------------------------------------
%% 9) 常见错误清单
%% ---------------------------------------------------------------------------
mistakes() ->
    io:format("~n== 9) 常见错误清单 ==~n"),
    Rows =
     [{"file:write_file(F, \"中文\")", "badarg",
       "参数是字节 iodata，中文码点 > 255。用 <<\"中文\"/utf8>> 或 unicode:characters_to_binary/1"},
      {"file:write_file(F, D, [{encoding, utf8}])", "badarg",
       "write_file 不接受 encoding 选项；要编码就 file:open + io:put_chars"},
      {"latin1 设备 io:put_chars 中文", "error:no_translation（抛）",
       "打开时加 {encoding, utf8}"},
      {"io:get_line 到末尾", "返回 eof 原子，不是 \"\"",
       "用 =:= eof 判断，别用 length(L) =:= 0"},
      {"file:read(Fd, N) 超过文件长度", "给剩下的字节，不是 eof",
       "判断是不是真的读完，要看下一次 read 是否返回 eof"},
      {"file:open(目录, [read])", "{error, eisdir}", "先 filelib:is_dir/1 判断"},
      {"关掉句柄后再 read", "{error, terminated}", "句柄是一次性的，忘了 close 会泄漏描述符"},
      {"filelib:ensure_dir(File)", "只建目录不建文件",
       "想要文件还得自己 write_file"},
      {"size(Bin) 当 byte_size 用", "已被 byte_size 取代", "size/1 对 binary 还能用但别写"},
      {"byte_size(<<1:3>>)", "返回 1（向上取整）", "想看真实位数用 bit_size/1"},
      {"binary_to_term(不可信数据)", "会创建新原子，可能 DoS", "加 [safe]，或改用自己定义的协议"},
      {"term_to_binary 默认开 compressed", "短数据反而变大", "只在数据确实大时开"}],
    [begin
         io:format("  ~ts~n", [What]),
         io:format("      现象：~ts~n", [Sym]),
         io:format("      处理：~ts~n", [Fix])
     end || {What, Sym, Fix} <- Rows],
    ok.
