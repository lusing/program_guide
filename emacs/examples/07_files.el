;;; -*- lexical-binding: t; -*-
(let ((temp-file (make-temp-file "emacs-guide-")))
  (with-temp-file temp-file
    (insert "Emacs file example\n"))
  (message "temp file: %s" temp-file)
  (delete-file temp-file))
