;;; -*- lexical-binding: t; -*-
(let ((proc (start-process "demo-process" nil "cmd.exe" "/c" "echo hello from emacs")))
  (message "process alive: %s" (process-live-p proc)))
