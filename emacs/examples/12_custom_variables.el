;;; -*- lexical-binding: t; -*-
(defgroup my-demo nil
  "Demo settings for Emacs extension examples."
  :group 'emacs)

(defcustom my-demo-name "guide"
  "Name used by the demo extension."
  :type 'string
  :group 'my-demo)

(message "custom: %s" my-demo-name)
