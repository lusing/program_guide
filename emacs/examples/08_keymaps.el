;;; -*- lexical-binding: t; -*-
(defvar my-map (make-sparse-keymap))
(define-key my-map (kbd "C-c x") #'message)

(message "binding: %s" (lookup-key my-map (kbd "C-c x")))
