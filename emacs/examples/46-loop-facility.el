;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 46 - cl-loop：Loop 宏的完整语法
;;;   cl-loop 在 Lisp 里嵌了一门「专门描述循环的小语言」：
;;;   for/while/until/collect/if/named/finally 这些保留字串成
;;;   子句，编译期一次性翻译成等价的 while 手写循环。CL 手册
;;;   5.7 用整整六节讲它（Basics / Examples / For / Iteration /
;;;   Accumulation / Other）。本章把手册的每个例子和每条规则
;;;   在 Emacs 31.1 上实测一遍，包括 in-ref、being the symbols
;;;   这些 Emacs 专属扩展，以及 generator.el 注册的 iter-by 子句。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "46-loop-facility.el")'
;;; 运行：emacs -Q --batch -l 46-loop-facility.el
;;; ============================================================
(require 'cl-lib)
(require 'generator) ; 31.1 里 iter-by 子句由 generator.el 注册，不 require 直接报错

;;; ---------- 1) 迷你语言初体验：计数与列表遍历 ----------
(princ "== 1) 迷你语言初体验：计数与列表遍历 ==\n")
(princ (format "  (cl-loop for x to 10 collect x) → %S\n"
               (cl-loop for x to 10 collect x)))
(princ (format "  (cl-loop for x below 10 collect x) → %S\n"
               (cl-loop for x below 10 collect x)))
(princ (format "  (cl-loop for x from 5 downto 1 collect x) → %S\n"
               (cl-loop for x from 5 downto 1 collect x)))
(princ (format "  (cl-loop for x in '(1 2 3 4 5 6) collect (* x x)) → %S\n"
               (cl-loop for x in '(1 2 3 4 5 6) collect (* x x))))
(princ (format "  by 'cddr 隔一个取一个 → %S\n"
               (cl-loop for x in '(1 2 3 4 5 6) by 'cddr collect (* x x))))
(princ (format "  不带累积/return 的循环返回 nil：%S\n"
               (cl-loop for x below 3 do (ignore x))))
(princ "  to 含端点、below 不含；by 步长恒为正；in 走元素、可换遍历函数。\n")

;;; ---------- 2) for on / for = then：更一般的遍历 ----------
(princ "\n== 2) for on / for = then：更一般的遍历 ==\n")
(princ (format "  for x on '(1 2 3 4) 走 cons cell → %S\n"
               (cl-loop for x on '(1 2 3 4) collect x)))
(princ (format "  for x = 表 then (cddr x) + while（手册等价例）→ %S\n"
               (cl-loop for x = '(1 2 3 4 5 6) then (cddr x)
                        while x collect (car x))))
(princ (format "  for x = expr 无 then：每轮重算 → %S\n"
               (let ((seed 0))
                 (cl-loop for x = (setq seed (1+ seed))
                          when (>= x 3) return x))))
(princ "  on 遍历 cons cell；= then 是通用迭代器，本身不带终止条件，\n")
(princ "  常配 while/until/return 使用。\n")

;;; ---------- 3) 顺序 for 与 and 并行 for ----------
(princ "\n== 3) 顺序 for 与 and 并行 for ==\n")
(princ (format "  for x below 5 for y = nil then x → %S\n"
               (cl-loop for x below 5 for y = nil then x collect (list x y))))
(princ (format "  for x below 5 and y = nil then x → %S\n"
               (cl-loop for x below 5 and y = nil then x collect (list x y))))
(princ "  连续 for 串行（≡ let*+setq）；and 链接则并行（≡ let+cl-psetq），\n")
(princ "  y 看到的 x 是上一轮留下的旧值。\n")

;;; ---------- 4) for 的解构 ----------
(princ "\n== 4) for 的解构 ==\n")
(princ (format "  for (x y) in '((2 3) (4 5) (6 7)) collect (+ x y) → %S\n"
               (cl-loop for (x y) in '((2 3) (4 5) (6 7)) collect (+ x y))))
(princ (format "  for (key . value) in alist collect key/value → %S\n"
               (cl-loop for (key . value) in '((a . 1) (b . 2))
                        collect (cons key value))))
(princ (format "  nil 占位丢弃对应列 → %S\n"
               (cl-loop for (x nil y) in '((1 2 3) (4 5 6))
                        collect (list x y))))
(princ "  for 的变量位可以写 lambda-list：值多丢弃、变量多补 nil，\n")
(princ "  nil 当占位符。和第 42 章宏参数解构同一套语法。\n")

;;; ---------- 5) across / being the elements / in-ref ----------
(princ "\n== 5) across / being the elements / in-ref ==\n")
(princ (format "  for x across \"aeiou\" 走字符串 → %S\n"
               (cl-loop for x across "aeiou" collect x)))
(princ (format "  being the elements + using (index i) → %S\n"
               (cl-loop for e being the elements of '(10 20 30)
                        using (index i) collect (list i e))))
(let ((l (list 1 2 3)))
  (cl-loop for x in-ref l do (cl-incf x))
  (princ (format "  in-ref 就地改列表 → %S\n" l)))
(let ((v (vector 1 2 3)))
  (cl-loop for x across-ref v do (cl-incf x))
  (princ (format "  across-ref 就地改向量 → %S\n" v)))
(princ "  in-ref/across-ref 是 Emacs 扩展：循环变量是对元素的 setf 引用，\n")
(princ "  直接接上第 44 章的 place 体系。\n")

;;; ---------- 6) Emacs 专属 for 子句 ----------
(princ "\n== 6) Emacs 专属 for 子句 ==\n")
(let ((ob (obarray-make 17)))
  (intern "mapcar" ob) (intern "map" ob) (intern "sort" ob)
  (princ (format "  being the symbols（按名过滤）→ %S\n"
                 (sort (cl-loop for s being the symbols of ob
                                when (string-match "\\`map" (symbol-name s))
                                collect s)
                       (lambda (p q) (string< (symbol-name p) (symbol-name q)))))))
(let ((h (make-hash-table :test 'equal)))
  (puthash "a" 1 h) (puthash "b" 2 h)
  (princ (format "  hash-keys using hash-values → %S\n"
                 (sort (cl-loop for k being the hash-keys of h
                                using (hash-values v) collect (cons k v))
                       (lambda (p q) (string< (car p) (car q)))))))
(let ((m (make-sparse-keymap)))
  (define-key m "a" 'cmd-a)
  (define-key m "b" 'cmd-b)
  (princ (format "  key-codes using key-bindings → %S\n"
                 (sort (cl-loop for c being the key-codes of m
                                using (key-bindings b) collect (cons c b))
                       (lambda (p q) (< (car p) (car q)))))))
(let ((s (copy-sequence "abcdef")))
  (put-text-property 0 3 'face 'bold s)
  (princ (format "  intervals of 串 property 'face → %S\n"
                 (cl-loop for (a . b) being the intervals of s
                          property 'face collect (list a b)))))
(princ (format "  being the buffers → %S\n"
               (cl-loop for b being the buffers collect (buffer-name b))))
(princ "  symbols/hash/keymap/overlay/interval/frame/window/buffer——\n")
(princ "  手册明说这些都是 Emacs 专属扩展，同类子句一个循环里只能来一个。\n")
(princ "  31.1 实测：obarray 已升级为独立类型，旧写法 (make-vector 17 nil)\n")
(princ "  会被 intern 拒绝（wrong-type-argument obarrayp），必须 obarray-make。\n")

;;; ---------- 7) iter-by / repeat / while / until ----------
(princ "\n== 7) iter-by / repeat / while / until ==\n")
(iter-defun ch46-gen (lst)
  "生成器：逐个 yield 列表元素。"
  (dolist (x lst) (iter-yield x)))
(princ (format "  iter-by 接 generator 迭代器 → %S\n"
               (cl-loop for x iter-by (ch46-gen '(10 20 30))
                        collect x)))
(princ (format "  repeat 20（手册 Yowsa 例改计数）→ %S\n"
               (let ((n 0)) (cl-loop repeat 20 do (setq n (1+ n))) n)))
(princ (format "  while 版 ≡ 原生 while：%S\n"
               (let ((l (list 1 2 3)) (acc nil))
                 (cl-loop while l do (push (pop l) acc))
                 (nreverse acc))))
(princ (format "  until 在前可零次：%S；do 在前至少一次：%S\n"
               (let ((n 3)) (cl-loop until (= n 3) do (setq n (1+ n))) n)
               (let ((n 3)) (cl-loop do (setq n (1+ n)) until (= n 4)) n)))
(princ "  手册原话：until 放 do 前「立即检查」、放 do 后「至少跑一次」。\n")
(princ "  31.1 实测：迭代器协议住在 generator.el（iter-defun/iter-yield/iter-do），\n")
(princ "  make-iterator 不存在；cl-loop 的 iter-by 子句要靠 require generator 注册。\n")

;;; ---------- 8) always / never / thereis ----------
(princ "\n== 8) always / never / thereis ==\n")
(princ (format "  always 全真 → %S\n"
               (cl-loop for x in '(2 4 6) always (> x 1))))
(princ (format "  always 有假 → %S\n"
               (cl-loop for x in '(2 4 6) always (> x 3))))
(princ (format "  never 全假 → %S\n"
               (cl-loop for x in '(2 4 6) never (> x 10))))
(princ (format "  thereis 第一个非 nil → %S\n"
               (cl-loop for x in '(1 2 3 4) thereis (and (> x 2) x))))
(princ (format "  always 失败短路（finally 不跑）→ %S\n"
               (cl-loop for x in '(1 2 3) always (> x 1)
                        finally do (princ "    [finally-RAN]\n"))))
(princ (format "  always 全真跑完 finally return → %S\n"
               (cl-loop for x in '(2 4) always (> x 1)
                        finally return 'fin)))
(princ "  always/never 是谓词量词，thereis 是「找第一个」；\n")
(princ "  注意：always 失败时直接 return nil，finally 不执行（手册 5.7.4）。\n")

;;; ---------- 9) 累积子句全家福 ----------
(princ "\n== 9) 累积子句全家福 ==\n")
(princ (format "  collecting（collect 同义词）→ %S\n"
               (cl-loop for x below 3 collecting x)))
(princ (format "  append → %S\n"
               (cl-loop for x in '((1) (2 3)) append x)))
(princ (format "  nconc → %S\n"
               (cl-loop for x in '((4) (5 6)) nconc x)))
(princ (format "  concat → %S\n"
               (cl-loop for s in '("ab" "cd") concat s)))
(princ (format "  vconcat → %S\n"
               (cl-loop for v in '((1 2) (3)) vconcat v)))
(princ (format "  count → %S\n"
               (cl-loop for x in '(1 2 3 4) count (> x 2))))
(princ (format "  sum → %S\n" (cl-loop for x in '(1 2 3) sum x)))
(princ (format "  maximize → %S；minimize → %S\n"
               (cl-loop for x in '(3 9 1 7) maximize x)
               (cl-loop for x in '(3 9 1 7) minimize x)))
(princ (format "  手册 Steele 例（collect+append 同池）→ %S\n"
               (cl-loop for name in '(fred sue alice joe june)
                        for kids in '((bob ken) () () (kris sunshine) ())
                        collect name
                        append kids)))
(princ "  累积结果默认就是返回值；同类累积可以汇进同一个「池」。\n")

;;; ---------- 10) into / with ----------
(princ "\n== 10) into / with ==\n")
(princ (format "  into + finally return → %S\n"
               (cl-loop for x below 5 collect x into all
                        when (cl-oddp x) collect x into odds
                        finally return (list all odds))))
(princ (format "  手册 with res push 例 → %S\n"
               (cl-loop for x in '(1 2 3) with res
                        do (push x res)
                        finally return res)))
(princ (format "  with 绑在循环外层 → %S\n"
               (cl-loop for i below 3 with x = 17 collect (+ i x))))
(princ "  into 把累积存进具名变量，但不再自动返回——必须 finally return；\n")
(princ "  with ≡ 循环外的 let，全程只绑一次。\n")

;;; ---------- 11) if/when/unless：and、else、end 与 it ----------
(princ "\n== 11) if/when/unless：and、else、end 与 it ==\n")
(let ((funny-numbers '(6 13 -1)))
  (princ (format "  手册例第一跑（oddp 为原生函数）→ %S\n"
                 (cl-loop for x below 10
                          if (oddp x)
                            collect x into odds
                            and if (memq x funny-numbers) return (cdr it) end
                          else
                            collect x into evens
                          finally return (vector odds evens)))))
(let ((funny-numbers '(6 7 13 -1)))
  (princ (format "  7 进了 funny 提前 return → %S\n"
                 (cl-loop for x below 10
                          if (oddp x)
                            collect x into odds
                            and if (memq x funny-numbers) return (cdr it) end
                          else
                            collect x into evens
                          finally return (vector odds evens)))))
(princ (format "  when/unless + it → %S\n"
               (cl-loop for x in '(1 2 3 4 5)
                        when (cl-evenp x) collect it into evens
                        unless (> x 10) collect x into smalls
                        finally return (list evens smalls))))
(princ "  it 拿到条件的那个非 nil 值；end 用来消歧嵌套 if 的 else 归属。\n")

;;; ---------- 12) named / initially / finally / return 的时序 ----------
(princ "\n== 12) named / initially / finally / return 的时序 ==\n")
(princ (format "  named 起块名 + cl-return-from → %S\n"
               (cl-loop named ch46-out for x below 100
                        when (= x 3) do (cl-return-from ch46-out 'found))))
(princ (format "  正常跑完 → %S\n"
               (cl-loop for x below 3
                        initially do (princ "    [initially]\n")
                        collect x
                        finally do (princ "    [finally-do]\n")
                        finally return (list 'ret x))))
(princ (format "  return 提前退出 → %S\n"
               (cl-loop for x below 3
                        do (princ "    [body]\n")
                        when (= x 1) return 'early
                        finally do (princ "    [finally-SKIPPED]\n"))))
(princ "  named 给隐式块命名；initially 循环前跑、finally 正常结束后跑；\n")
(princ "  return（含 always 的短路）直接跳出，finally 整个跳过。\n")

(princ "==== 46 结束 ====\n")
