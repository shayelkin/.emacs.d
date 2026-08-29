;;; my-prog-custom.el --- Customization for programming modes. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; SPDX-License-Identifier: MIT
;; Package-Requires: ((emacs "30.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'use-package))

(require 'bind-key)

(add-hook 'prog-mode-hook #'electric-pair-local-mode)

(setq js-indent-level 2)

(use-package eglot
  :bind ((:map eglot-mode-map
               ("C-c i" . eglot-find-implementation)
               ("C-c d" . eglot-find-declaration)
               ("C-c t" . eglot-find-typeDeclaration))))

(use-package which-func
  :config
  (setq which-func-unknown "")
  ;; Drop the brackets
  (when (equal (car which-func-format) "[")
    (setq which-func-format (cadr which-func-format)))
  :custom-face (which-func ((t (:inherit nil))))
  ;; Package is called `which-func', but mode is `which-function-mode'
  :hook ((c++-ts-mode java-ts-mode js-ts-mode) . which-function-mode))

(use-package paredit
  :hook ((lisp-mode emacs-lisp-mode lisp-data-mode) . enable-paredit-mode))

(use-package makefile-executor
  :hook (makefile-mode . makefile-executor-mode))

(use-package python-mode
  :magic ("\\`#!.*\\<uv run --script\\>" . python-ts-mode))

(use-package uv-mode
  :hook ((python-ts-mode python-mode) . uv-mode-auto-activate-hook))

(use-package go-ts-mode
  :mode "\\.go\\'"
  :hook ((go-ts-mode . (lambda ()
                         (setq-local indent-tabs-mode nil)))))

(use-package awk-ts-mode      :mode "\\.[mg]?awk\\'")
(use-package perl-ts-mode     :mode "\\.pl\\'")
(use-package protobuf-ts-mode :mode "\\.proto\\'")
(use-package scala-ts-mode    :mode "\\.sc\\(ala\\)?\\'" "\\.sbt\\'")
(use-package swift-ts-mode    :mode "\\.swift\\'")
(use-package terraform-mode   :mode "\\.t\\(f\\(vars\\)?\\|ofu\\)\\'")

;;;;; Flymake ;;;;;

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

(use-package flymake
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
  :hook (emacs-lisp-mode . flymake-mode))


;;;;; Tree-sitter ;;;;;

(setq treesit-extra-load-path '("/usr/local/lib"))
(setopt treesit-font-lock-level 2)

;; `treesit-auto' is slow to load. Simply define major-mode-remap-alist for the
;; built-in modes instead:
(setq major-mode-remap-alist '((conf-toml-mode . toml-ts-mode)
                               (ruby-mode . ruby-ts-mode)
                               (python-mode . python-ts-mode)
                               (js-json-mode . json-ts-mode)
                               (javascript-mode . js-ts-mode)
                               (js-mode . js-ts-mode)
                               (java-mode . java-ts-mode)
                               (sgml-mode . html-ts-mode)
                               (mhtml-mode . html-ts-mode)
                               (css-mode . css-ts-mode)
                               (c++-mode . c++-ts-mode)
                               (csharp-mode . csharp-ts-mode)
                               (c-mode . c-ts-mode)
                               (sh-mode . bash-ts-mode)
                               (awk-mode . awk-ts-mode)
                               (perl-mode . perl-ts-mode)))

;; These ts-modes have no non-ts fallback and/or their `auto-mode-alist' setup runs only
;; after load.
(dolist (entry '(("\\.ya?ml\\'"    . yaml-ts-mode)
                 ("/Dockerfile\\'" . dockerfile-ts-mode)
                 ("\\.go\\'"       . go-ts-mode)
                 ("/go\\.mod\\'"   . go-mod-ts-mode)
                 ("\\.lua\\'"      . lua-ts-mode)
                 ("\\.rs\\'"       . rust-ts-mode)
                 ("\\.ts\\'"       . typescript-ts-mode)
                 ("\\.tsx\\'"      . tsx-ts-mode)
                 ("\\.heex\\'"     . heex-ts-mode)
                 ("\\.exs?\\'"     . elixir-ts-mode)
                 ("\\.mjs\\'"      . js-ts-mode)))
  (unless (assoc (car entry) auto-mode-alist)
    (push entry auto-mode-alist)))

(provide 'my-prog-custom)
;;; my-prog-custom.el ends here
