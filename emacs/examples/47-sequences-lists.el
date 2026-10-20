;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 47 - 序列与列表：cl-map、cl-reduce 与列表构造
;;;   CL 手册第 10 章（Sequences）把「列表/字符串/向量」统称
;;;   序列，给出一整套带关键字参数的操作；第 11 章（Lists）
;;;   专攻 cons cell 链：访问、树替换、集合运算、关联列表。
;;;   本章把两章的每个函数在 Emacs 31.1 上实测一遍，重点分清
;;;   「复制版 / 破坏版」两大家族（remove vs delete、subst vs
;;;   nsubst），以及 :key/:test/:start/:end 这套统一的关键字
;;;   约定。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "47-sequences-lists.el")'
;;; 运行：emacs -Q --batch -l 47-sequences-lists.el
;;; ============================================================
(require 'cl-lib)

;;; ---------- 1) 序列函数的统一关键字：:test/:key/:count/:start/:end/:from-end ----------
(princ "== 1) 序列函数的统一关键字 ==\n")
(princ (format "  cl-remove 0 :test '= ≡ cl-remove-if 'zerop → %S / %S\n"
               (cl-remove 0 '(0 1 0 2) :test #'=)
               (cl-remove-if #'zerop '(0 1 0 2))))
(princ (format "  :key 过滤视角（find 2 :key car ≡ cl-assoc 的思路）→ %S\n"
               (cl-find 2 '((1 . a) (2 . b)) :key #'car)))
(princ (format "  :count 2 只删左边两个 → %S\n"
               (cl-remove 1 '(1 2 1 3 1) :count 2)))
(princ (format "  :count 1 :from-end t 改删右边 → %S\n"
               (cl-remove 1 '(1 2 1 3 1) :count 1 :from-end t)))
(princ (format "  :start 2 :end 4 只看窗口内 → %S\n"
               (cl-remove 1 '(1 2 1 3 1) :start 2 :end 4)))
(princ "  手册约定：:test 默认 eql；:key 是「看元素的滤镜」；\n")
(princ "  :start 含、:end 不含；-if/-if-not 变体用谓词代替 item。\n")

;;; ---------- 2) Mapping 家族：cl-mapcar / cl-map / cl-maplist / cl-mapc / cl-mapcan ----------
(princ "\n== 2) Mapping 家族 ==\n")
(princ (format "  cl-mapcar 双序列并行、最短即停 → %S\n"
               (cl-mapcar #'+ '(1 2 3) '(10 20))))
(princ (format "  cl-map 'vector 换返回类型 → %S\n"
               (cl-map 'vector #'+ '(1 2 3) '(10 20 30))))
(princ (format "  cl-map 'string（元素是字符码）→ %S\n"
               (cl-map 'string #'1+ "abc")))
(princ (format "  cl-map nil 丢弃结果 → %S\n"
               (cl-map nil #'ignore '(1 2))))
(princ (format "  cl-maplist 每次拿到的是 CDR 链 → %S\n"
               (cl-maplist #'identity '(1 2 3))))
(princ (format "  cl-mapc 丢弃函数值、返回第一个序列 → %S\n"
               (cl-mapc #'ignore '(1 2))))
(princ (format "  cl-mapcan 把各轮列表 nconc 起来 → %S\n"
               (cl-mapcan (lambda (x) (list x (* x 10))) '(1 2))))
(princ "  cl-mapcar 是 CL mapcar 与原生 mapcar 的兼容超集：\n")
(princ "  多序列、可混类型；cl-maplist 走 cons cell 本身（≡ loop 的 for on）。\n")

;;; ---------- 3) 量词：cl-some / cl-every / cl-notany / cl-notevery ----------
(princ "\n== 3) 量词 ==\n")
(princ (format "  cl-some 返回第一个非 nil 值（不是 t）→ %S\n"
               (cl-some (lambda (x) (and (> x 2) x)) '(1 2 3 4))))
(princ (format "  cl-every 全真才 t → %S / %S\n"
               (cl-every #'cl-plusp '(1 2 3))
               (cl-every #'cl-plusp '(1 -2 3))))
(princ (format "  cl-notany（全假才 t）→ %S\n"
               (cl-notany #'cl-minusp '(1 2 3))))
(princ (format "  cl-notevery（有假即非 nil）→ %S\n"
               (cl-notevery #'cl-plusp '(1 -2 3))))
(princ "  手册保证：some/every 按从左到右顺序调用，且命中即停——\n")
(princ "  谓词里放副作用是安全的（别的序列函数不做此保证）。\n")

;;; ---------- 4) cl-reduce：左右结合、:initial-value 与空序列 ----------
(princ "\n== 4) cl-reduce ==\n")
(princ (format "  左结合：(- (- (- 1 2) 3) 4) → %S\n"
               (cl-reduce #'- '(1 2 3 4))))
(princ (format "  :from-end t 右结合：(- 1 (- 2 (- 3 4))) → %S\n"
               (cl-reduce #'- '(1 2 3 4) :from-end t)))
(princ (format "  :initial-value 100 加在最前 → %S\n"
               (cl-reduce #'- '(1 2) :initial-value 100)))
(princ (format "  单元素不调用函数直接返回 → %S\n"
               (cl-reduce #'- '(5))))
(princ (format "  空序列调用函数零次取单位元：(+) → %S\n"
               (cl-reduce #'+ '())))
(princ "  手册原话：cl-loop 都能写出这些映射，编译后 cl-loop\n")
(princ "  更快（内联、无函数调用）；cl-reduce 胜在读起来是函数式。\n")

;;; ---------- 5) cl-subseq / cl-concatenate / cl-fill / cl-replace ----------
(princ "\n== 5) 截取、拼接、填充、替换 ==\n")
(let ((src (list 1 2 3 4)))
  (princ (format "  cl-subseq 拷贝（改结果不动原序列）→ %S，原序列 %S\n"
                 (let ((s (cl-subseq src 1 3))) (setcar s 99) s) src)))
(princ (format "  负索引（Emacs 扩展）：(cl-subseq '(1 2 3 4) -2) → %S\n"
               (cl-subseq '(1 2 3 4) -2)))
(let ((v (vector 1 2 3 4 5)))
  (setf (cl-subseq v 1 3) '(9 9))
  (princ (format "  setf cl-subseq 就地替换一段 → %S\n" v)))
(princ (format "  cl-concatenate 混类型拼成 string → %S\n"
               (cl-concatenate 'string '(?a ?b) "cd")))
(let ((v (vector 1 2 3 4)))
  (princ (format "  cl-fill 填窗口 [1,3) → %S\n"
                 (cl-fill v 0 :start 1 :end 3))))
(let ((l (list 1 2 3 4)))
  (princ (format "  cl-replace 返回 seq1 本体 → %S，l 已变 %S\n"
                 (cl-replace l '(9 8) :start1 1) l)))
(princ "  cl-subseq 是唯一允许负 start/end 的序列函数；setf 它的\n")
(princ "  效果等同 cl-replace。cl-fill/cl-replace 都是就地修改。\n")

;;; ---------- 6) 复制版 vs 破坏版：remove/delete、remove-duplicates、substitute ----------
(princ "\n== 6) 复制版 vs 破坏版 ==\n")
(let ((orig (list 1 2 1 3)))
  (princ (format "  cl-remove 不动原列表：结果 %S，原列表 %S\n"
                 (cl-remove 1 orig) orig)))
(let ((l (list 0 1 2 1 3)))
  (princ (format "  cl-delete 就地剪接：结果 %S，l 变成 %S\n"
                 (cl-delete 1 l) l)))
(let ((v (vector 1 2 1 3)))
  (princ (format "  向量上 cl-delete ≡ cl-remove（不可伸缩）：%S，原向量 %S\n"
                 (cl-delete 1 v) v)))
(princ (format "  cl-remove-duplicates 保留最右 → %S\n"
               (cl-remove-duplicates '(1 2 1 3 2))))
(princ (format "  :from-end t 改留最左 → %S\n"
               (cl-remove-duplicates '(1 2 1 3 2) :from-end t)))
(let ((l (list 1 2 1 3)))
  (setq l (cl-nsubstitute 'x 1 l))
  (princ (format "  cl-nsubstitute 用 setcar 就地换 → l 变成 %S\n" l)))
(princ "  规律：无前缀名=复制版（原序列不动），n 前缀或 delete\n")
(princ "  前缀=破坏版；字符串/向量不可伸缩，破坏版退化为复制版。\n")

;;; ---------- 7) 搜索：cl-find / cl-position / cl-count / cl-mismatch / cl-search ----------
(princ "\n== 7) 搜索 ==\n")
(princ (format "  cl-find 返回元素本身，:from-end 取最右 → %S\n"
               (cl-find 1 '(1 2 1 3) :from-end t)))
(princ (format "  cl-find 未命中 → %S\n" (cl-find 9 '(1 2 3))))
(princ (format "  cl-position :start 1 仍按全序列计位置 → %S\n"
               (cl-position 1 '(1 2 1 3) :start 1)))
(princ (format "  cl-count → %S\n" (cl-count 1 '(1 2 1 3))))
(princ (format "  cl-mismatch 第一处不同（相对 seq1 的下标）→ %S\n"
               (cl-mismatch '(1 2 3) '(1 2 4))))
(princ (format "  短序列先走完也算不匹配 → %S\n"
               (cl-mismatch '(1 2) '(1 2 3))))
(princ (format "  全同 → %S；:key upcase 忽略大小写 → %S\n"
               (cl-mismatch '(1 2) '(1 2))
               (cl-mismatch "Hello" "hello" :key #'upcase)))
(princ (format "  cl-search 找子序列，返回左端起点的下标 → %S\n"
               (cl-search "el" "hello")))
(princ "  cl-position 的位置永远相对序列整体（哪怕用了 :start）；\n")
(princ "  cl-mismatch 全匹配返回 nil，别当 0 用。\n")

;;; ---------- 8) 排序：cl-sort / cl-stable-sort / cl-merge ----------
(princ "\n== 8) 排序 ==\n")
(princ (format "  cl-sort 直接排序向量（原生 sort 只会排列表）→ %S\n"
               (cl-sort (vector 3 1 2) #'<)))
(princ (format "  手册例：:key downcase 忽略大小写 → %S\n"
               (cl-sort (list "Bob" "alice" "Carol") #'string-lessp :key #'downcase)))
(let ((l (list 3 1 2)))
  (setq l (cl-sort l #'<))
  (princ (format "  cl-sort 是破坏性的：排完 l = %S\n" l)))
(princ (format "  cl-merge 归并两个已序列表 → %S\n"
               (cl-merge 'list (list 1 3 5) (list 2 4) #'<)))
(princ "  cl-sort 对任意序列可用且就地；31.1 里底层 sort 本来就\n")
(princ "  稳定，cl-stable-sort 与之等价（手册保留将来换实现的权利）。\n")

;;; ---------- 9) 列表函数：cl-first/rest/endp/list-length/list*/ldiff/copy-list/tree-equal ----------
(princ "\n== 9) 列表函数 ==\n")
(princ (format "  cl-first..cl-tenth ≡ car/cadr/…：%S %S %S\n"
               (cl-first '(1 2 3)) (cl-second '(1 2 3)) (cl-rest '(1 2 3))))
(princ (format "  cl-endp 对非列表报错 → %S\n"
               (condition-case err
                   (cl-endp 'sym)
                 (error (error-message-string err)))))
(let ((l (list 1 2 3)))
  (setcdr (cddr l) l)
  (princ (format "  环形列表 cl-list-length → %S（length 会死循环）\n"
                 (cl-list-length l))))
(princ (format "  cl-list* 尾参变 CDR：%S 与 %S\n"
               (cl-list* 'a 'b 'c) (cl-list* 'a 'b nil)))
(let ((x (list 1 2 3 4)))
  (princ (format "  cl-ldiff 取前段拷贝 → %S（与原列表不共享：%S）\n"
                 (cl-ldiff x (cddr x))
                 (eq (cl-ldiff x (cddr x)) x))))
(princ (format "  cl-copy-list 正确复制点列表 → %S\n"
               (cl-copy-list '(1 2 . 3))))
(princ (format "  cl-tree-equal 默认 eql：%S；:test equal：%S\n"
               (cl-tree-equal '(("a")) '(("a")))
               (cl-tree-equal '(("a")) '(("a")) :test #'equal)))
(princ "  cl-endp 是「严格版 null」；cl-tree-equal 递归比 cons 树，\n")
(princ "  字符串元素记得给 :test 'equal（默认 eql 不比字符串内容）。\n")

;;; ---------- 10) 树替换：cl-subst / cl-nsubst / cl-sublis ----------
(princ "\n== 10) 树替换 ==\n")
(princ (format "  cl-subst 递归 CAR 与 CDR（含 dotted 尾）→ %S\n"
               (cl-subst 'x 1 '(1 (2 1) . 1))))
(let ((tree (list 1 (list 2 1))))
  (setq tree (cl-nsubst 'x 1 tree))
  (princ (format "  cl-nsubst 就地（setcar/setcdr）→ tree 变成 %S\n" tree)))
(princ (format "  cl-sublis 按 alist 批量换 → %S\n"
               (cl-sublis '((a . apple) (b . banana)) '(a b c a))))
(princ "  cl-substitute（第 6 节）只换序列顶层；cl-subst 一族换整棵\n")
(princ "  cons 树。old 本身是 cons 时按整体匹配、不再递归进去。\n")

;;; ---------- 11) 列表当集合：member/tailp/adjoin/pushnew/union 等 ----------
(princ "\n== 11) 列表当集合 ==\n")
(princ (format "  cl-member 命中返回尾巴（不是元素）→ %S\n"
               (cl-member 2 '(1 2 3))))
(let ((needle (copy-sequence "b"))
      (hay (list "a" "b")))
  (princ (format "  字符串默认 eql 不中：%S；:test equal 才中：%S\n"
                 (cl-member needle hay)
                 (cl-member needle hay :test #'equal))))
(let ((x (list 1 2 3)))
  (princ (format "  cl-tailp 判定真尾巴 → %S / %S\n"
                 (cl-tailp (cddr x) x) (cl-tailp (list 3) x))))
(princ (format "  cl-adjoin 已在则不 cons：%S / %S\n"
               (cl-adjoin 2 '(1 2 3)) (cl-adjoin 0 '(1 2 3))))
(let ((s (list 2 3)))
  (cl-pushnew 2 s)
  (princ (format "  cl-pushnew 重复不推 → %S；" s))
  (cl-pushnew 1 s)
  (princ (format "新元素推入 → %S\n" s)))
(princ (format "  cl-union（排序后展示，顺序未定义）→ %S\n"
               (sort (cl-union '(1 2 3) '(2 3 4)) #'<)))
(princ (format "  cl-intersection → %S；cl-set-difference → %S\n"
               (sort (cl-intersection '(1 2 3) '(2 3 4)) #'<)
               (cl-set-difference '(1 2 3 4) '(2 4))))
(princ (format "  cl-set-exclusive-or → %S；cl-subsetp → %S\n"
               (sort (cl-set-exclusive-or '(1 2 3) '(2 3 4)) #'<)
               (cl-subsetp '(1 2) '(1 2 3))))
(princ "  原生 member 用 equal，cl-member 默认 eql——字符串成员判断\n")
(princ "  是两者的经典差异。集合函数结果顺序未定义，演示前先 sort。\n")

;;; ---------- 12) 关联列表：cl-assoc / cl-rassoc / cl-acons / cl-pairlis ----------
(princ "\n== 12) 关联列表 ==\n")
(princ (format "  cl-assoc 忽略非 cons 元素 → %S\n"
               (cl-assoc 'b '(junk (a . 1) (b . 2) nil))))
(princ (format "  cl-rassoc 按 CDR 反查 → %S\n"
               (cl-rassoc 2 '((a . 1) (b . 2)))))
(princ (format "  cl-acons ≡ (cons (cons k v) alist) → %S\n"
               (cl-acons 'a 1 '((b . 2)))))
(princ (format "  cl-pairlis 键值两表配对 → %S\n"
               (cl-pairlis '(a b) '(1 2) '((c . 3)))))
(princ "  cl-assoc 比较键用 eql（:test 可换）；对应 -if/-if-not\n")
(princ "  变体按谓词查。alist 就是「元素都是 cons cell 的列表」。\n")

(princ "==== 47 结束 ====\n")
