;;; -*- lexical-binding: t; -*-
(defun demo-greeting ()
  "Return a greeting string."
  "hello")

(defun demo-advice (&rest _)
  (message "advice triggered"))

(advice-add #'demo-greeting :before #'demo-advice)
(message "%s" (demo-greeting))
