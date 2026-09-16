#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核查 common-lisp-guide.md 里所有 `; => 值` 断言是否与 SBCL 实际输出一致。

做法：
  1. 把 Markdown 里每个 ```lisp 代码块还原成一个 .lisp 文件，
     断言行 `EXPR ; => VALUE` 改写成 `(ck "…" EXPR "VALUE")`；
     注释里写了「报错」的形式用 handler-case 包起来，好让后面的形式继续跑。
  2. 用一个 driver 按顺序 --load 这些块，所以前面块里的 defvar / defun /
     defpackage / defclass 对后面的块可见 —— 相当于把整份指南从头执行一遍。
  3. 逐条比对打印结果，列出不符的断言。

用法：
    python3 verify-guide.py [指南路径]        # 默认 ./common-lisp-guide.md
    SBCL=/path/to/sbcl python3 verify-guide.py

判定说明（哪些不符是可以接受的）：
  对象地址（`#<TRACED {1202A6C183}>`）、`gensym` 编号、哈希表遍历顺序、
  线程调度顺序这几类必然因运行而异，指南里都显式标注了，会出现假阳性。
  真正要看的是「数值类断言」有没有不符 —— 那才是指南写错了。
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
GUIDE = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "common-lisp-guide.md")

SBCL = os.environ.get("SBCL") or shutil.which("sbcl") or "/opt/local/bin/sbcl"

ERR_WORDS = re.compile(r"报错|会报错|失败|会崩|会挂")

# 比对前把「必然每次不同」的东西抹平：空白量、对象地址、gensym 编号。
# 这样只有真正的数值/结构不符才会被报出来。
NORM_LISP = r'''
(defun norm (s)
  "折叠连续空白；把 #<... {地址}> 里的地址、#:G123 里的编号抹成不定形式。"
  (let ((flat (with-output-to-string (o)
                (let ((ws nil))
                  (loop for c across s do
                    (if (member c '(#\Space #\Tab #\Newline #\Return))
                        (unless ws (write-char #\Space o) (setf ws t))
                        (progn (write-char c o) (setf ws nil))))))))
    (let ((flat (string-trim '(#\Space) flat)))
      ;; 对象地址 #<TRACED {1202A6C183}> -> #<TRACED …}
      (let ((i (search "{" flat)))
        (when i
          (setf flat (concatenate 'string (subseq flat 0 i) "~}"))))
      ;; gensym 编号 #:G264 -> #:G
      (with-output-to-string (o)
        (let ((i 0) (n (length flat)))
          (loop while (< i n) do
            (if (and (char= (char flat i) #\#) (< (1+ i) n)
                     (char= (char flat (1+ i)) #\:))
                (progn (write-string "#:" o) (incf i 2)
                       (loop while (and (< i n)
                                        (or (alpha-char-p (char flat i))
                                            (char= (char flat i) #\-)))
                             do (write-char (char flat i) o) (incf i))
                       (loop while (and (< i n) (digit-char-p (char flat i)))
                             do (incf i)))
                (progn (write-char (char flat i) o) (incf i)))))))))
'''


def split_comment(line):
    """把一行拆成 (代码, 注释)。分号在字符串里不算注释起点。"""
    instr = esc = False
    for i, ch in enumerate(line):
        if esc:
            esc = False
        elif instr:
            if ch == "\\":
                esc = True
            elif ch == '"':
                instr = False
        elif ch == '"':
            instr = True
        elif ch == ";":
            return line[:i], line[i:]
    return line, ""


def balanced(s):
    """括号是否配平（忽略字符串里的括号）。"""
    depth = 0
    instr = esc = False
    for ch in s:
        if esc:
            esc = False
        elif instr:
            if ch == "\\":
                esc = True
            elif ch == '"':
                instr = False
        elif ch == '"':
            instr = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
    return depth == 0 and not instr


def strip_tail(s):
    """去掉值后面跟着的说明文字（两个以上空格、或中文括号注释）。"""
    s = s.rstrip()
    m = re.match(r"^(.*?\S)\s{2,}\S", s)
    if m:
        s = m.group(1).rstrip()
    m = re.match(r"^(.*?)\s*（[^（）]*）\s*$", s)
    if m:
        s = m.group(1).rstrip()
    m = re.match(r"^(.*?)\s*\(([^()]*)\)\s*$", s)
    if m and re.search(r"[\u4e00-\u9fff]", m.group(2)):
        s = m.group(1).rstrip()
    return s


def read_blocks(path):
    """取出所有 ```lisp 代码块，返回 [(起始行号, [行...]), ...]。"""
    blocks = []
    in_fence = False
    lang = ""
    cur = []
    start = 0
    for i, ln in enumerate(open(path, encoding="utf-8").read().split("\n")):
        if ln.startswith("```"):
            if not in_fence:
                in_fence, lang, cur, start = True, ln[3:].strip(), [], i + 2
            else:
                in_fence = False
                if lang.lower() in ("lisp", "cl"):
                    blocks.append((start, cur))
            continue
        if in_fence:
            cur.append(ln)
    return blocks


def render_block(startline, blk, outdir, index):
    """把一个代码块还原成可加载的 .lisp，返回 (路径, 断言条数)。"""
    body = []
    buf = buf_claim = ""
    buf_first = 0
    buf_err = False
    buf_claims = 0    # 这个形式里有几条 `; =>`（多于一条就没法一一对应，跳过比对）
    nclaim = 0

    def flush():
        nonlocal buf, buf_claim, buf_err, nclaim, buf_claims
        if not buf.strip():
            buf_claim, buf_err, buf_claims = "", False, 0
            return
        if buf_claim and buf_claims == 1:
            nclaim += 1
            body.append('(ck %s %s %s)'
                        % (json.dumps("L%d %s" % (buf_first, buf.strip()),
                                      ensure_ascii=False),
                           buf.strip(),
                           json.dumps(buf_claim, ensure_ascii=False)))
        elif buf_err:
            body.append('(handler-case %s (error (e) (declare (ignore e)) nil))'
                        % buf.strip())
        else:
            body.append(buf.rstrip("\n"))
        buf, buf_claim, buf_err, buf_claims = "", "", False, 0

    for ln in blk:
        code, comment = split_comment(ln)
        was_empty = not buf.strip()
        if was_empty:
            buf_first = startline
        if ERR_WORDS.search(comment):
            buf_err = True
        buf += code + "\n"
        if re.search(r"=>\s*\S", comment) or re.search(r"=>\s*$", comment):
            buf_claims += 1
            if not buf_claim:
                val = re.search(r"=>\s*(.*)$", comment).group(1)
                if "←" in val:
                    val = val.split("←")[0]
                buf_claim = strip_tail(val)
        if not code.strip() and comment.strip():
            if was_empty:
                body.append(ln.rstrip())
                buf, buf_claim, buf_err, buf_claims = "", "", False, 0
            continue
        if balanced(buf):
            flush()
    flush()

    # 第二次扫描：紧跟在后面的独立注释里写了「报错」，说明这个形式是故意演示错误
    fixed = []
    for i, item in enumerate(body):
        nxt = body[i + 1] if i + 1 < len(body) else ""
        if (item.strip() and not item.strip().startswith(";")
                and not item.startswith("(ck ")
                and nxt.strip().startswith(";") and ERR_WORDS.search(nxt)):
            fixed.append('(handler-case %s (error (e) (declare (ignore e)) nil))'
                         % item.strip())
        else:
            fixed.append(item)

    if not any(l.strip() and not l.strip().startswith(";") for l in fixed):
        return None, 0

    path = os.path.join(outdir, "%03d.lisp" % index)
    with open(path, "w", encoding="utf-8") as f:
        f.write(";;;; block %03d (markdown line %d)\n" % (index, startline))
        f.write('(setf *blk* "%03d")\n' % index)
        for l in fixed:
            f.write(l + "\n")
    return path, nclaim


def main():
    outdir = tempfile.mkdtemp(prefix="cl-guide-verify-")
    blocks = read_blocks(GUIDE)
    paths, total_claims = [], 0
    for startline, blk in blocks:
        path, n = render_block(startline, blk, outdir, len(paths) + 1)
        if path:
            paths.append(path)
            total_claims += n

    driver = os.path.join(outdir, "driver.lisp")
    with open(driver, "w", encoding="utf-8") as f:
        f.write("(defvar *bad* 0) (defvar *n* 0)\n")
        f.write('(defvar *blk* "") (defvar *fails* nil) (defvar *broken* nil)\n')
        f.write(NORM_LISP)
        f.write("(defmacro ck (label form want)\n")
        f.write("  `(progn (incf *n*)\n")
        # 形式本身用默认打印变量求值（否则 (*print-right-margin* 之类的断言会被自己绑的值污染），
        # 只把「打印成字符串」这一步放在放宽的 *print-right-margin* 下。
        # *print-pretty* 保持默认 T —— SBCL 只在 pretty 打开时才把 (quote x) 打印成 'x，
        # 指南里的输出就是这么来的。
        f.write("     (let* ((v (handler-case ,form (error (e) (declare (ignore e)) :!!err)))\n")
        f.write("            (got (if (eq v :!!err) \"[report]\"\n")
        f.write("                     (let ((*print-right-margin* 1000)) (prin1-to-string v)))))\n")
        f.write("       (unless (string= (norm got) (norm ,want))\n")
        f.write("         (incf *bad*)\n")
        f.write('         (push (list (concatenate \'string *blk* " " ,label) got ,want)\n')
        f.write("               *fails*)))))\n")
        for p in paths:
            f.write('(handler-case (load %s :verbose nil :print nil)\n'
                    '  (error (e) (push (format nil "~A: ~A" %s e) *broken*)))\n'
                    % (json.dumps(p), json.dumps(os.path.basename(p))))
        f.write('(format t "~%==== blocks ~D, claims ~D, mismatch ~D, broken ~D ====~%" '
                + str(len(paths)) + ' *n* (length *fails*) (length *broken*))\n')
        f.write('(dolist (b (reverse *broken*))\n'
                '  (format t "BROKEN ~A~%" b))\n')
        f.write('(dolist (f (reverse *fails*))\n'
                '  (format t "MISMATCH ~A~%  got  = ~A~%  want = ~A~%"\n'
                '          (first f) (second f) (third f)))\n')

    print("guide  : %s" % GUIDE)
    print("sbcl   : %s" % SBCL)
    print("blocks : 共 %d 个 lisp 代码块，其中 %d 个有可执行内容；断言行 %d 条"
          % (len(blocks), len(paths), total_claims))

    # SBCL 的编译警告走 stderr，stdout 才是核查结果
    proc = subprocess.run([SBCL, "--noinform", "--non-interactive", "--no-userinit",
                           "--load", driver],
                          stdin=subprocess.DEVNULL,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out = proc.stdout.decode("utf-8", "replace")
    for ln in out.split("\n"):
        if ln.startswith(("====", "BROKEN", "MISMATCH", "  got", "  want")):
            print(ln)

    tail = re.search(r"==== blocks \d+, claims \d+, mismatch (\d+), broken (\d+)", out)
    print()
    print("注意：对象地址 / gensym 编号 / 哈希表顺序 / 线程顺序这几类必然随运行而变，"
          "指南里都显式标注了，列进 MISMATCH 里属正常。")
    shutil.rmtree(outdir, ignore_errors=True)
    return 1 if (tail and (int(tail.group(1)) > 0 or int(tail.group(2)) > 0)) else 0


if __name__ == "__main__":
    sys.exit(main())
