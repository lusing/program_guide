;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 39 - 哈希表：测试函数、遍历与弱引用
;;;   alist 是「小规模、要保序」的第一选择，哈希表是「大规模、只
;;;   要查得快」的第一选择。本章把 :test、maphash、容量、打印读回、
;;;   弱引用和「nil 值查不出来」这几个坑逐个实测。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "39-hash-tables.el")'
;;; 运行：emacs -Q --batch -l 39-hash-tables.el
;;; ============================================================
(require 'cl-lib)

;;; 本章反复要用「造一个全新的字符串」，避免「字符串字面量是不是
;;; 同一个对象」这种问题干扰结论。
(defun demo-str (s)
  "返回 S 的一个全新副本（确保不是同一个 Lisp 对象）。"
  (copy-sequence s))

;;; 收集哈希表里的键 / 值：Emacs 31.1 没有 hash-table-keys / -values，
;;; 只能自己 maphash。
(defun demo-hash-keys (table)
  "返回 TABLE 里所有键的列表（顺序未定义）。"
  (let (ks)
    (maphash (lambda (k _v) (push k ks)) table)
    (nreverse ks)))

;;; 第 9 节演示弱引用时，需要一个「活到最后的外部引用」。
(defvar demo-keep nil)

;;; ---------- 1) 创建、写入、读取、删除 ----------
(princ "== 1) 创建、写入、读取、删除 ==\n")
(let ((h (make-hash-table :test 'equal)))
  (princ (format "  刚建好: count=%S size=%S test=%S weakness=%S\n"
                 (hash-table-count h) (hash-table-size h)
                 (hash-table-test h) (hash-table-weakness h)))
  (puthash "a" 1 h)
  (puthash "b" 2 h)
  (princ (format "  放两个: count=%S size=%S\n"
                 (hash-table-count h) (hash-table-size h)))
  (princ (format "  读: (gethash \"a\")=%S  (gethash \"z\")=%S  (gethash \"z\" h 'miss)=%S\n"
                 (gethash "a" h) (gethash "z" h) (gethash "z" h 'miss)))
  (puthash "a" 99 h)
  (princ (format "  覆盖: 再 (puthash \"a\" 99) 后 count=%S 值=%S\n"
                 (hash-table-count h) (gethash "a" h)))
  (remhash "b" h)
  (princ (format "  (remhash \"b\") 后 count=%S  (gethash \"b\")=%S\n"
                 (hash-table-count h) (gethash "b" h 'miss)))
  (clrhash h)
  (princ (format "  (clrhash) 后 count=%S size=%S（容量不退）\n"
                 (hash-table-count h) (hash-table-size h))))

;;; ---------- 2) 默认 :test 是 eql：字符串键陷阱 ----------
(princ "\n== 2) 默认 :test 是 eql ==\n")
(let ((h (make-hash-table)))
  (princ (format "  (make-hash-table) 的 test=%S\n" (hash-table-test h)))
  (puthash (demo-str "a") 1 h)
  (puthash (demo-str "a") 2 h)
  (princ (format "  两个内容都是 \"a\" 的字符串: count=%S\n" (hash-table-count h)))
  (princ (format "  再用一个全新的 \"a\" 去查: %S\n"
                 (gethash (demo-str "a") h 'miss)))
  (princ "  原因：eql 比的是「同一个对象，或同样的数 / 字符」，\n")
  (princ "        不是「内容相同」。两个字符串对象永远不 eql。\n"))
(let* ((h (make-hash-table))
       (k (demo-str "a")))
  (puthash k 1 h)
  (princ (format "  用同一个对象做键: (gethash k)=%S  count=%S\n"
                 (gethash k h) (hash-table-count h)))
  (remhash k h)
  (princ (format "  (remhash k) 同一个对象才删得掉: count=%S\n" (hash-table-count h))))
(let ((h (make-hash-table :test 'equal)))
  (puthash (demo-str "a") 1 h)
  (puthash (demo-str "a") 2 h)
  (princ (format "  改成 :test equal: count=%S  (gethash \"a\")=%S\n"
                 (hash-table-count h) (gethash (demo-str "a") h))))
(let ((h (make-hash-table :test 'eq)))
  (puthash (intern "apple") 1 h)
  (princ (format "  把字符串 intern 成符号, eq 表也认: (gethash 'apple h)=%S count=%S\n"
                 (gethash 'apple h) (hash-table-count h)))
  (puthash (intern "apple") 2 h)
  (princ (format "  再放一次 (intern \"apple\"): count=%S 值=%S\n"
                 (hash-table-count h) (gethash 'apple h))))

;;; ---------- 3) eq / eql / equal 的边界 ----------
(princ "\n== 3) eq / eql / equal 的边界 ==\n")
(let ((heq (make-hash-table :test 'eq))
      (heql (make-hash-table :test 'eql))
      (hequal (make-hash-table :test 'equal))
      (big (expt 2 70)))
  (puthash big 'yes heq)
  (puthash big 'yes heql)
  (puthash big 'yes hequal)
  (princ (format "  bignum %S:\n    eq=%S eql=%S equal=%S\n"
                 big
                 (gethash (expt 2 70) heq 'miss)
                 (gethash (expt 2 70) heql 'miss)
                 (gethash (expt 2 70) hequal 'miss)))
  (puthash 1.0 'yes heq)
  (puthash 1.0 'yes heql)
  (princ (format "  浮点数 1.0: eq=%S eql=%S（两个 1.0 不是同一个对象）\n"
                 (gethash 1.0 heq 'miss) (gethash 1.0 heql 'miss)))
  (puthash (demo-str "s") 'yes heq)
  (puthash (demo-str "s") 'yes heql)
  (puthash (demo-str "s") 'yes hequal)
  (princ (format "  字符串 \"s\": eq=%S eql=%S equal=%S\n"
                 (gethash (demo-str "s") heq 'miss)
                 (gethash (demo-str "s") heql 'miss)
                 (gethash (demo-str "s") hequal 'miss)))
  (puthash (list 1 2) 'yes hequal)
  (princ (format "  列表 '(1 2) 只有 equal 认: %S\n"
                 (gethash (list 1 2) hequal 'miss))))

;;; ---------- 4) 自定义测试函数 ----------
(princ "\n== 4) 自定义测试函数 ==\n")
(defun demo-ci-equal (a b)
  "忽略大小写地比较两个字符串。"
  (string-equal (downcase a) (downcase b)))
(defun demo-ci-hash (s)
  "DEMO-CI-EQUAL 配套的哈希函数：先把键归一化再取 sxhash。"
  (sxhash-equal (downcase s)))
(define-hash-table-test 'demo-ci #'demo-ci-equal #'demo-ci-hash)
(let ((h (make-hash-table :test 'demo-ci)))
  (puthash "Hello" 1 h)
  (princ (format "  test=%S\n" (hash-table-test h)))
  (princ (format "  \"hello\"=%S  \"HELLO\"=%S  \"World\"=%S\n"
                 (gethash "hello" h 'miss)
                 (gethash "HELLO" h 'miss)
                 (gethash "World" h 'miss)))
  (princ (format "  表里只有 %S 个键: %S\n" (hash-table-count h) (demo-hash-keys h))))
(princ "  --- 测试函数必须先注册 ---\n")
(princ (format "  直接用没注册的符号: %S\n"
               (condition-case err (make-hash-table :test 'no-such-test)
                 (error (error-message-string err)))))
(princ (format "  equal-including-properties 也不在内置列表里: %S\n"
               (condition-case err
                   (make-hash-table :test 'equal-including-properties)
                 (error (error-message-string err)))))
(define-hash-table-test 'demo-props #'equal-including-properties #'sxhash-equal)
(let* ((bare (demo-str "abc"))
       (fancy (let ((s (demo-str "abc")))
                (put-text-property 0 1 'face 'bold s)
                s))
       (h (make-hash-table :test 'demo-props)))
  (puthash bare 'plain h)
  (princ (format "  注册后可用: 不带属性查=%S 带 face 属性查=%S\n"
                 (gethash bare h 'miss) (gethash fancy h 'miss)))
  (puthash fancy 'fancy h)
  (princ (format "  两个都放进去: count=%S（属性不同算两个键）\n" (hash-table-count h))))

;;; ---------- 5) 遍历：只有 maphash ----------
(princ "\n== 5) 遍历：只有 maphash ==\n")
(princ (format "  hash-table-keys? %S  hash-table-values? %S\n"
               (fboundp 'hash-table-keys) (fboundp 'hash-table-values)))
(princ (format "  hash-table-empty-p? %S  hash-table-to-alist? %S\n"
               (fboundp 'hash-table-empty-p) (fboundp 'hash-table-to-alist)))
(princ "  四个都没有——键和值只能自己 maphash 收集，判空用 count。\n")
(let ((h (make-hash-table :test 'equal))
      (i 0))
  (dolist (k '("a" "b" "c"))
    (setq i (1+ i))
    (puthash k i h))
  (let (ks vs)
    (maphash (lambda (k v) (push k ks) (push v vs)) h)
    (princ (format "  maphash 收集: 键=%S  值=%S\n"
                   (sort ks #'string<) (sort vs #'<))))
  (princ (format "  判空: count=%S  (zerop count)=%S\n"
                 (hash-table-count h) (zerop (hash-table-count h))))
  (clrhash h)
  (princ (format "  clrhash 之后 (zerop count)=%S\n" (zerop (hash-table-count h))))
  (princ (format "  哈希表不是序列: (length h) -> %S\n"
                 (condition-case err (length h)
                   (error (error-message-string err))))))
(princ "  --- 遍历中改 / 删 / 加 ---\n")
(let ((h (make-hash-table :test 'equal))
      (n 0))
  (dotimes (i 4) (puthash (1+ i) (1+ i) h))
  (maphash (lambda (k _v) (setq n (1+ n)) (puthash k (* 10 k) h)) h)
  (princ (format "  改已有键: 回调 %S 次 count=%S 1=%S 4=%S（安全）\n"
                 n (hash-table-count h) (gethash 1 h) (gethash 4 h))))
(let ((h (make-hash-table :test 'equal))
      seen)
  (dotimes (i 4) (puthash i i h))
  (maphash (lambda (k _v) (push k seen) (remhash k h)) h)
  (princ (format "  删除当前键: 看到 %S 个 %S，删完 count=%S（安全）\n"
                 (length seen) (sort seen #'<) (hash-table-count h))))
(let ((h (make-hash-table :test 'equal))
      (n 0)
      (added nil))
  (puthash 0 'zero h)
  (maphash (lambda (_k _v)
             (setq n (1+ n))
             (unless added (setq added t) (puthash 'new 'val h)))
           h)
  (princ (format "  新增一个键: 回调被调了 %S 次（本来只有 1 个键）\n" n))
  (princ (format "  表里现在有 %S 个键——新键也被遍历到了。\n" (hash-table-count h)))
  (princ "  所以：遍历中不断新增 = 死循环，必须先收集键再改。\n"))
(let ((h (make-hash-table :test 'equal))
      keys)
  (puthash "a" 1 h)
  (puthash "b" 2 h)
  (maphash (lambda (k _v) (push k keys)) h)
  (dolist (k keys)
    (puthash (concat k "-copy") (gethash k h) h))
  (princ (format "  正确写法（先收集键，再对收集结果循环）: count=%S 键=%S\n"
                 (hash-table-count h) (sort (demo-hash-keys h) #'string<))))

;;; ---------- 6) 容量：:size 只是提示 ----------
(princ "\n== 6) 容量：:size 只是提示 ==\n")
(let ((h (make-hash-table :test 'equal)))
  (princ (format "  刚建好: count=%S size=%S（还没插东西，一个槽都不分配）\n"
                 (hash-table-count h) (hash-table-size h)))
  (dotimes (i 6) (puthash i i h))
  (princ (format "  塞到第 6 个: count=%S size=%S\n"
                 (hash-table-count h) (hash-table-size h)))
  (dotimes (i 100) (puthash (+ 100 i) i h))
  (princ (format "  再塞 100 个: count=%S size=%S（自己长，不用管）\n"
                 (hash-table-count h) (hash-table-size h))))
(let ((h (make-hash-table :size 1)))
  (princ (format "  :size 1 初始 size=%S\n" (hash-table-size h)))
  (dotimes (i 200) (puthash i i h))
  (princ (format "  塞 200 个后 count=%S size=%S——:size 只是提示，小了兜不住也大了不浪费\n"
                 (hash-table-count h) (hash-table-size h))))
(let ((h (make-hash-table :size 100)))
  (dotimes (i 300) (puthash i i h))
  (princ (format "  :size 100 塞 300 个: size=%S\n" (hash-table-size h)))
  (clrhash h)
  (princ (format "  (clrhash) 后容量不退: size=%S count=%S\n"
                 (hash-table-size h) (hash-table-count h))))
(princ "  --- :rehash-size / :rehash-threshold / :purecopy 已废弃 ---\n")
(let ((h (make-hash-table :rehash-size 2.0 :rehash-threshold 0.5 :purecopy t)))
  (princ (format "  传了 :rehash-size 2.0 和 :rehash-threshold 0.5，照样读到 %S / %S\n"
                 (hash-table-rehash-size h) (hash-table-rehash-threshold h))))
(princ "  make-hash-table 的 docstring 原文：\n")
(princ "    The keywords arguments :rehash-threshold, :rehash-size,\n")
(princ "    and :purecopy are obsolete and ignored.\n")
(princ (format "  但完全陌生的关键字照样报错: %S\n"
               (condition-case err (make-hash-table :bogus 1)
                 (error (error-message-string err)))))

;;; ---------- 7) 打印与读回 ----------
(princ "\n== 7) 打印与读回 ==\n")
(let* ((h (make-hash-table :test 'equal))
       (str (progn (puthash "a" 1 h) (puthash "b" 2 h) (prin1-to-string h))))
  (princ (format "  prin1: %S\n" str))
  (let ((h2 (read str)))
    (princ (format "  read 回来: count=%S (gethash \"a\")=%S test=%S\n"
                   (hash-table-count h2) (gethash "a" h2) (hash-table-test h2)))))
(let ((h (make-hash-table :test 'equal :weakness 'value)))
  (puthash "a" 1 h)
  (princ (format "  弱表会把 weakness 一起写进去: %S\n" (prin1-to-string h))))
(princ "  自定义 test 的表打印出来读不回去：\n")
(let ((h (make-hash-table :test 'demo-ci)))
  (puthash "Hello" 1 h)
  (princ (format "  prin1: %S\n" (prin1-to-string h))))
(princ "  上面那串里的 test demo-ci 是个自定义符号，read 时并未注册，\n")
(princ "  所以存盘前要么换回 equal 表，要么自己存 alist。\n")

;;; ---------- 8) copy-hash-table 是浅拷贝 ----------
(princ "\n== 8) copy-hash-table 是浅拷贝 ==\n")
(let* ((val (list 1 2))
       (h (make-hash-table :test 'equal))
       (c (progn (puthash "k" val h) (copy-hash-table h))))
  (puthash "k" 'changed h)
  (puthash "new" 9 h)
  (princ (format "  原表改了 k: 原表=%S 副本=%S（不受影响）\n"
                 (gethash "k" h) (gethash "k" c)))
  (princ (format "  原表新增 \"new\"，副本里: %S\n" (gethash "new" c 'miss)))
  (princ (format "  副本 test=%S weakness=%S（测试函数和弱类型一起带过来）\n"
                 (hash-table-test c) (hash-table-weakness c)))
  (princ (format "  值本身还是同一个 cons: %S——只复制「映射关系」这一层\n"
                 (eq (gethash "k" c) val))))
(let* ((h (make-hash-table :test 'equal))
       (deep (progn (puthash "k" (list 1 2) h)
                    (let ((d (make-hash-table :test (hash-table-test h))))
                      (maphash (lambda (k v)
                                 (puthash (copy-tree k) (copy-tree v) d))
                               h)
                      d))))
  (setcar (gethash "k" deep) 99)
  (princ (format "  自己 copy-tree 出来的「深」拷贝: 副本=%S 原表=%S\n"
                 (gethash "k" deep) (gethash "k" h))))

;;; ---------- 9) 弱引用表 ----------
(princ "\n== 9) 弱引用表 ==\n")
(princ (format "  合法取值: %S %S %S %S %S（t 是 key-and-value 的别名）\n"
               (hash-table-weakness (make-hash-table :weakness 'key))
               (hash-table-weakness (make-hash-table :weakness 'value))
               (hash-table-weakness (make-hash-table :weakness 'key-or-value))
               (hash-table-weakness (make-hash-table :weakness 'key-and-value))
               (hash-table-weakness (make-hash-table :weakness t))))
(princ (format "  非法取值: %S\n"
               (condition-case err (make-hash-table :weakness 'bogus)
                 (error (error-message-string err)))))
(princ "  四种取值的语义，make-hash-table 的 docstring 是这么写的：\n")
(princ "    Key/value pairs are removed from a weak hash table when there\n")
(princ "    are no non-weak references pointing to their key, value, one\n")
(princ "    of key or value, or both key and value, depending on WEAK.\n")
(princ "  逐项对上就是：key / value / key-or-value / key-and-value。\n")
(let ((h (make-hash-table :test 'eq :weakness 'value :size 8)))
  (dotimes (i 100) (puthash i (list 'payload i) h))
  (princ (format "  value 弱表放 100 个: count=%S\n" (hash-table-count h)))
  (dotimes (_ 5) (garbage-collect))
  (princ (format "  这些值已经没人引用了，5 次 gc 后: count=%S\n"
                 (hash-table-count h))))
(let ((h (make-hash-table :test 'eq :weakness 'key :size 8)))
  (dotimes (i 100) (puthash (list 'k i) i h))
  (princ (format "  key 弱表放 100 个: count=%S\n" (hash-table-count h)))
  (dotimes (_ 5) (garbage-collect))
  (princ (format "  这些键已经没人引用了，5 次 gc 后: count=%S\n"
                 (hash-table-count h))))
(let ((h (make-hash-table :test 'eq :weakness 'value :size 8)))
  (dotimes (i 50) (puthash i (list 'payload i) h))
  (setq demo-keep (list 'i-am-kept))
  (puthash 'special demo-keep h)
  (princ (format "  50 个无人引用的 + 1 个被 demo-keep 引用着的: count=%S\n"
                 (hash-table-count h)))
  (dotimes (_ 5) (garbage-collect))
  (princ (format "  5 次 gc 后: count=%S  被引用着的那条=%S\n"
                 (hash-table-count h) (gethash 'special h 'gone)))
  (princ (format "  同期别的键: (gethash 0 h 'gone)=%S\n"
                 (gethash 0 h 'gone))))
(princ "  这就是弱表的用处：拿它做「对象 → 附属数据」的旁路表，\n")
(princ "  对象没了，附属数据自动跟着消失，不用手动清理。\n")

;;; ---------- 10) nil 键与 nil 值 ----------
(princ "\n== 10) nil 键与 nil 值 ==\n")
(let ((h (make-hash-table :test 'equal)))
  (puthash nil 'the-nil-key h)
  (puthash "x" nil h)
  (princ (format "  nil 可以做键: (gethash nil h)=%S\n" (gethash nil h)))
  (princ (format "  nil 也可以做值: (gethash \"x\" h)=%S\n" (gethash "x" h)))
  (princ (format "  给默认值也没用: (gethash \"x\" h 'miss)=%S\n" (gethash "x" h 'miss)))
  (princ (format "  键不存在时才给默认值: (gethash \"y\" h 'miss)=%S\n"
                 (gethash "y" h 'miss)))
  (princ "  gethash 的默认值只区分「键不存在」，区分不了「值是 nil」。\n")
  (princ (format "  想确认键在不在，只能遍历: %S\n"
                 (let (found)
                   (maphash (lambda (k _v) (when (equal k "x") (setq found t))) h)
                   found))))

;;; ---------- 11) alist 还是哈希表：实测查找代价 ----------
(princ "\n== 11) alist 还是哈希表 ==\n")
(defvar demo-cmp-count 0
  "记录 DEMO-ASSOC 这一次查找做了几次比较。")

(defun demo-assoc (key alist)
  "在 ALIST 里线性查找 KEY，把比较次数记进 `demo-cmp-count'。"
  (setq demo-cmp-count 0)
  (catch 'demo-found
    (dolist (pair alist)
      (setq demo-cmp-count (1+ demo-cmp-count))
      (when (equal (car pair) key)
        (throw 'demo-found (cdr pair))))
    nil))

(let* ((n 1000)
       (al (mapcar (lambda (i) (cons (number-to-string i) i))
                   (number-sequence 0 (1- n)))))
  (princ (format "  alist 有 %S 项\n" (length al)))
  (princ (format "  查第 1 项    \"0\":   值=%S  比较 %S 次\n"
                 (demo-assoc "0" al) demo-cmp-count))
  (princ (format "  查最后一项  \"999\": 值=%S  比较 %S 次\n"
                 (demo-assoc "999" al) demo-cmp-count))
  (princ (format "  查不存在的  \"zzz\": 值=%S  比较 %S 次（必须扫完才知道没有）\n"
                 (demo-assoc "zzz" al) demo-cmp-count)))
(let ((h (make-hash-table :test 'equal)))
  (dotimes (i 1000) (puthash (number-to-string i) i h))
  (princ (format "  哈希表 1000 项: (gethash \"999\")=%S  (gethash \"zzz\")=%S，代价一样\n"
                 (gethash "999" h) (gethash "zzz" h 'miss))))

(princ "  --- 实战：词频统计 ---\n")
(let ((words '("the" "cat" "the" "dog" "a" "cat" "the" "bird" "cat"))
      (h (make-hash-table :test 'equal)))
  (dolist (w words)
    (puthash w (1+ (gethash w h 0)) h))
  (let (pairs)
    (maphash (lambda (k v) (push (cons k v) pairs)) h)
    (setq pairs (sort pairs
                      (lambda (a b)
                        (or (> (cdr a) (cdr b))
                            (and (= (cdr a) (cdr b))
                                 (string< (car a) (car b)))))))
    (princ (format "  词表: %S\n" words))
    (princ (format "  词频（次数降序、同次数按字典序）: %S\n" pairs))
    (princ (format "  Top 2: %S\n" (cl-subseq pairs 0 2)))))

(princ "  --- 用哈希表做缓存 ---\n")
(let ((cache (make-hash-table :test 'equal))
      (calls 0))
  (cl-labels ((slow (x) (setq calls (1+ calls)) (* x x))
              (cached (x)
                (let ((hit (gethash x cache 'miss)))
                  (if (eq hit 'miss)
                      (puthash x (slow x) cache)
                    hit))))
    (princ (format "  第一次 (cached 7)=%S\n" (cached 7)))
    (princ (format "  第二次 (cached 7)=%S\n" (cached 7)))
    (princ (format "  第三次 (cached 7)=%S\n" (cached 7))))
  (princ (format "  底层 slow 实际只被调用了 %S 次\n" calls)))

(princ "==== 39 结束 ====\n")
