;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 35 - 收尾项目：打印一张带坐标的柱状图
;;;   全书的收尾项目（eintr 最后一站）：把 cons、递归、
;;;   循环、缓冲区操作这些零件拼成一个完整程序——
;;;   画一张带 Y 轴、X 轴刻度的柱状图。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "35-graph.el")'
;;; 运行：emacs -Q --batch -l 35-graph.el
;;; ============================================================

(defvar my-columns '(3 7 5 10 6 2 8 4 9 1)
  "柱状图数据：每根柱的高度。")
(defvar my-y-spacing 4 "Y 轴刻度间隔（每几行标一个数）。")
(defvar my-x-spacing 3 "X 轴刻度间隔（每几根柱标一个数，从第 1 根起）。")
(defvar my-col-width 2 "每根柱占用的字符宽度。")

;;; ---------- 1) 列模型：一根柱 = 上空下实 ----------
;;; 画一根高度为 c 的柱（画布总高 height）：上面 height-c 行是
;;; 空白，下面 c 行是星号。把它做成一个字符串列表，
;;; 首元素对应图的最顶行——后面所有画法都吃这个模型。
(defun my-column-of-graph (max-height actual-height)
  "返回画一根柱的字符串列表：先 MAX-ACTUAL 个空白，再 ACTUAL 个星号。
列表首元素对应图的最顶行。"
  (let ((acc nil))
    (dotimes (_ (- max-height actual-height))
      (push " " acc))
    (dotimes (_ actual-height)
      (push "*" acc))
    (nreverse acc)))

(princ "== 1) 列模型：一根柱 = 上空下实 ==\n")
(princ (format "columns = %S\n" my-columns))
(princ (format "画布总高（最高柱）= %d\n" (apply #'max my-columns)))
(princ (format "列 4（高 10）自顶向下 = %S\n"
               (my-column-of-graph 10 10)))
(princ (format "列 2（高 7）自顶向下 = %S\n"
               (my-column-of-graph 10 7)))

;;; ---------- 2) 把缓冲区当画布：递归逐列贴入 ----------
;;; eintr 的画法：缓冲区就是画布。先铺好 height 个等宽空行，
;;; 然后一列一列地把星号「贴」进自己的位置。
;;; 贴一列用递归（从顶行贴到底行），贴完一列递归去贴下一列。

(defun my-paint-column (col height c row)
  "把第 COL 列（高 C）贴进当前缓冲区画布，从第 ROW 行开始递归往下。"
  (when (< row height)
    (goto-char (point-min))
    (forward-line row)
    (forward-char (+ (* my-col-width col) (1- my-col-width)))
    (delete-char 1)
    (insert (if (>= c (- height row)) "*" " "))
    (my-paint-column col height c (1+ row))))

(defun my-paint-columns (columns col height)
  "递归：先把第 COL 列贴进画布，再处理余下的列。"
  (when columns
    (my-paint-column col height (car columns) 0)
    (my-paint-columns (cdr columns) (1+ col) height)))

(defun my-graph-body-print (columns)
  "把 COLUMNS 画成不带坐标轴的柱状图体，返回行列表（行尾已修剪）。
画布是临时缓冲区：先铺空行，再逐列递归贴星号。"
  (let ((height (apply #'max columns)))
    (with-temp-buffer
      (dotimes (_ height)
        (insert (make-string (* my-col-width (length columns)) ?\s) "\n"))
      (my-paint-columns columns 0 height)
      (mapcar #'string-trim-right
              (butlast (split-string (buffer-string) "\n"))))))

(princ "\n== 2) 把缓冲区当画布：逐列贴入 ==\n")
(princ "画布上画出的图体（行尾已修剪）：\n")
(princ (concat (mapconcat #'identity (my-graph-body-print my-columns) "\n")
               "\n"))

;;; ---------- 3) 坐标轴：Y 轴刻度与 X 轴对齐 ----------
;;; Y 轴的难点是 eintr 反复讨论的 top label 问题：最高柱未必
;;; 落在刻度上（10 不是 4 的倍数），所以它单独打在图体上方一行。
;;; X 轴的难点是对齐：刻度数字的末位必须正好压在该柱星号的
;;; 正下方——位置是可以算出来的。

(defun my-pad-left (s width)
  "把字符串 S 右对齐到 WIDTH 宽（左侧补空格）。"
  (if (< (length s) width)
      (concat (make-string (- width (length s)) ?\s) s)
    s))

(defun my-y-prefix (i height)
  "图体第 I 行（1 起，自顶往下）的 Y 轴前缀。
落在刻度上的行显示行号，其余行用空格补位。"
  (let ((w (length (number-to-string height))))
    (concat (if (zerop (% i my-y-spacing))
                (my-pad-left (number-to-string i) w)
              (make-string w ?\s))
            " | ")))

(defun my-x-axis-lines (ncols height)
  "返回 X 轴两行：横线行与刻度标签行。
刻度从第 1 根柱起、每 X-SPACING 根一个，数字末位对准该柱星号。"
  (let* ((w (length (number-to-string height)))
         (rule (concat (make-string (+ w 1) ?\s)
                       "+"
                       (make-string (* my-col-width ncols) ?-)))
         (labels (make-string (+ w 3) ?\s))
         (j 1))
    (while (<= j ncols)
      (let* ((num (number-to-string j))
             ;; 列 j 的星号在整行里的 1-based 位置：Y 前缀占 w+3 格，
             ;; 该列单元末位再往右 w*j 格
             (star-pos (+ w 3 (* my-col-width j)))
             (start (1+ (- star-pos (length num)))))
        (while (< (length labels) (1- start))
          (setq labels (concat labels " ")))
        (setq labels (concat labels num)))
      (setq j (+ j my-x-spacing)))
    (list rule labels)))

(princ "== 3) 坐标轴：Y 轴刻度与 X 轴对齐 ==\n")
(princ (format "第 8 行的 Y 前缀 = %S（8 是 4 的倍数，标行号）\n"
               (my-y-prefix 8 10)))
(princ (format "第 9 行的 Y 前缀 = %S（9 不是刻度，补空格）\n"
               (my-y-prefix 9 10)))
(princ (format "最高柱 10 %% 4 = %d ≠ 0，所以顶部单独一行标 10\n"
               (% 10 my-y-spacing)))
(let ((x (my-x-axis-lines (length my-columns) (apply #'max my-columns))))
  (princ (format "X 轴横线 = %S\n" (car x)))
  (princ (format "X 轴标签 = %S\n" (cadr x))))

;;; ---------- 4) 组装：完整的图 ----------
;;; Y 轴前缀 + 图体逐行拼起来；顶部按需补 top label；
;;; 底部接 X 轴。坐标轴与图体从此严丝合缝。

(defun my-print-graph-lines (columns)
  "组装完整柱状图（Y 轴 + 图体 + X 轴），返回行列表。"
  (let* ((height (apply #'max columns))
         (body (my-graph-body-print columns))
         lines)
    ;; top label：最高柱不在刻度上时，单独打一行
    (unless (zerop (% height my-y-spacing))
      (push (my-pad-left (number-to-string height)
                         (length (number-to-string height)))
            lines))
    ;; 图体：从第 height 行（顶）往下到第 1 行
    (let ((i height))
      (while (>= i 1)
        (push (concat (my-y-prefix i height)
                      (nth (- height i) body))
              lines)
        (setq i (1- i))))
    ;; X 轴
    (let ((x (my-x-axis-lines (length columns) height)))
      (push (car x) lines)
      (push (cadr x) lines))
    (nreverse lines)))

(princ "\n== 4) 组装：完整的图 ==\n")
(princ (concat (mapconcat #'identity (my-print-graph-lines my-columns) "\n")
               "\n"))

;;; ---------- 5) 循环与递归：殊途同归 ----------
;;; 同一张图体还能不用缓冲区、纯用循环逐行拼出来。
;;; 两种画法输出完全一致——选哪个看你想练哪种肌肉。

(defun my-graph-body-lines-loop (columns)
  "循环版：逐行直接拼字符串，不经过缓冲区。"
  (let* ((height (apply #'max columns))
         lines)
    (dotimes (row height)
      (let ((line "")
            (level (- height row)))       ; 本行对应的「水位」
        (dolist (c columns)
          (setq line (concat line
                             (if (>= c level)
                                 (concat (make-string (1- my-col-width) ?\s) "*")
                               (make-string my-col-width ?\s)))))
        (push (string-trim-right line) lines)))
    (nreverse lines)))

(princ "== 5) 循环与递归：殊途同归 ==\n")
(princ (format "画布版与循环版输出完全一致？ %S\n"
               (equal (my-graph-body-print my-columns)
                      (my-graph-body-lines-loop my-columns))))

(princ "==== 35 结束 ====\n")
