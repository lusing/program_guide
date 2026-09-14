;;; -*- lexical-binding: t; -*-
(define-derived-mode demo-mode fundamental-mode "Demo"
  "A minimal demo major mode."
  (setq mode-name "Demo"))

(message "Mode name: %s" "demo-mode")
