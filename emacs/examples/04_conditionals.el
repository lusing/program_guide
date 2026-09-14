;;; -*- lexical-binding: t; -*-
(defun describe-number (n)
  (cond
   ((< n 0) "negative")
   ((= n 0) "zero")
   (t "positive")))

(message "-3 -> %s" (describe-number -3))
(message "0 -> %s" (describe-number 0))
(message "5 -> %s" (describe-number 5))
