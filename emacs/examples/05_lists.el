;;; -*- lexical-binding: t; -*-
(defvar my-demo-numbers '(1 2 3 4 5))
(setq my-demo-numbers '(1 2 3 4 5))

(message "first = %s" (car my-demo-numbers))
(message "rest = %s" (cdr my-demo-numbers))
(message "length = %d" (length my-demo-numbers))
