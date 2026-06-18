;;; my-use-packages-built-in.el -- Configuration for packages included with Emacs. -*- lexical-binding: t -*-

;; SPDX-License-Identifier: MIT
;; Author: Shay Elkin <shay@elkin.io>
;; Package-Requires: ((emacs "30.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'use-package)
  (require 'use-package-ensure))

(require 'bind-key)

(use-package compare-w
  :bind ("<f4>" . compare-windows))

(use-package smtpmail
  :autoload smtpmail-send-it
  :custom
  (send-mail-function 'smtpmail-send-it)
  (smtpmail-smtp-server "smtp.gmail.com")
  (smtpmail-smtp-service 465)
  (smtpmail-stream-type 'ssl)
  (smtpmail-servers-requiring-authorization "\\.gmail\\.com"))

(use-package windmove
  :config (windmove-default-keybindings))

(use-package speedbar
  :custom (speedbar-show-unknown-files t)
  ;; See comment on the use-package stanza for `sr-speedbar'.
  :defer t)
(use-package server
  :config (server-start))

 ;; Buttonize URLs and e-mail addresses.
(use-package goto-addr
  :config (global-goto-address-mode))

(use-package paren
  :config (show-paren-mode))

(use-package flyspell
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode)))

(use-package paredit
  :hook ((lisp-mode emacs-lisp-mode lisp-data-mode) . enable-paredit-mode))

;; (use-package hl-line  ;; built-in
;;   :hook (prog-mode text-mode))

(use-package which-func  ;; built-in
  :config
  (setq which-func-unknown "")
  ;; Drop the brackets
  (when (equal (car which-func-format) "[")
    (setq which-func-format (cadr which-func-format)))
  :custom-face (which-func ((t (:inherit nil))))
  ;; Package is called `which-func', but mode is `which-function-mode'
  :hook ((c++-ts-mode java-ts-mode js-ts-mode) . which-function-mode))

(use-package which-key
  :config (which-key-mode))

(use-package eglot
  :bind ((:map eglot-mode-map
               ("C-c i" . eglot-find-implementation)
               ("C-c d" . eglot-find-declaration)
               ("C-c t" . eglot-find-typeDeclaration))))

(use-package go-ts-mode
  :mode "\\.go\\'"
  :hook ((go-ts-mode . (lambda ()
                         (setq-local indent-tabs-mode nil)))))

(use-package js
  :defer
  :custom (js-indent-level 2))



;;; ======================================================================
;;; Flymake
;;; ======================================================================

(defvar flymake-ignore-patterns nil
  "Buffer-local list of regexes for flymake diagnostics text to ignore.")
(make-variable-buffer-local 'flymake-ignore-patterns)

(defun my--flymake-filter-by-pattern (orig-fn &rest args)
  "Advice around `flymake--publish-diagnostics'"
  (if (null flymake-ignore-patterns)
      (apply orig-fn args)
    (let ((diags (car args)))
      (apply orig-fn
             (cons (cl-remove-if
                    (lambda (d)
                      (let ((text (flymake-diagnostic-text d)))
                        (cl-some (lambda (re) (string-match-p re text)) flymake-ignore-patterns)))
                    diags)
                   (cdr args))))))

(use-package flymake ;; built-in
  :custom
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-wrap-around t)
  :config (advice-add 'flymake--publish-diagnostics :around  #'my--flymake-filter-by-pattern)
  :bind
  ("<f7>" . flymake-show-buffer-diagnostics)
  (:map flymake-mode-map
        ("M-n" . flymake-goto-next-error)
        ("M-p" . flymake-goto-prev-error))
  ;; Usually flymake-mode would be started by Eglot, but `emacs-lisp-mode'
  ;; doesn't use LSP/Eglot.
  :hook (emacs-lisp-mode . flymake-mode ))




(provide 'my-use-packages-built-in)
;;; my-use-packages-built-in ends here
