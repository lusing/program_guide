;;; -*- lexical-binding: t; -*-
(with-temp-buffer
  (insert "Hello from a temporary buffer\n")
  (goto-char (point-min))
  (message "%s" (buffer-substring-no-properties (point-min) (point-max))))
