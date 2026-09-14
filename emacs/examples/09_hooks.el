;;; -*- lexical-binding: t; -*-
(defun my-buffer-hook ()
  (message "Buffer hook: %s" (buffer-name)))

(add-hook 'find-file-hook #'my-buffer-hook)
(message "hook count: %d" (length (memq #'my-buffer-hook find-file-hook)))
