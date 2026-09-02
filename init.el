;;; init.el --- Emacs initialization file. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; SPDX-License-Identifier: MIT
;; Package-Requires: ((emacs "30.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

;; Don't bother with backwards compatibility for pre-2025 Emacsen.
(when (version< emacs-version "30.1")
  (error "It is time to upgrade this Emacs installation!"))

(when (version< emacs-version "31.1")
  ;; https://www.gnu.org/software/emacs/manual/html_node/emacs/User-Lisp-Directory.html
  (add-to-list 'load-path (expand-file-name "user-lisp" user-emacs-directory)))

;; Take effect early, before anything that may try to connect to a remote host
(setq gnutls-verify-error t)

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs loaded in %.3f seconds with %d garbage collections done."
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  use-package
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(eval-when-compile
  (require 'use-package)
  (require 'use-package-ensure))

(eval-when-compile
  (require 'use-package-ensure))
(setq use-package-always-ensure t)

(setq use-package-compute-statistics t
      ;; `use-package-ensure-elpa' loads package.el unconditionally, which pulls in
      ;; url-handlers and costs ~100ms. Only reach for it when something is missing.
      use-package-ensure-function
      (lambda (name args state &optional no-refresh)
        (unless (seq-every-p (lambda (arg)
                               (and (not (consp arg)) ; `:pin' needs the real thing
                                    (package-installed-p
                                     (if (eq arg t) (use-package-as-symbol name) arg))))
                             args)
          (use-package-ensure-elpa name args state no-refresh))))

(setq package-archives '(("gnu" .  "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Environment
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst on-mac-window-system (memq window-system '(mac ns))
  "Non-nil when running on macOS graphical environment.")

(when on-mac-window-system
  (setq mac-option-modifier 'meta)

  ;; Like `exec-path-from-shell' but faster, as it just gets PATH from bash or zsh,
  ;; which is all I care for.
  (let ((path-string (string-trim
                      (with-temp-buffer
                        (call-process (getenv "SHELL") nil t nil "-lc" "echo $PATH")
                        (buffer-string)))))
    (setq exec-path (parse-colon-path path-string))
    (setenv "PATH" path-string)))

;; Important optimization: having the scratch buffer be `lisp-interaction-mode'
;; costs ~150ms at startup.
(setq initial-major-mode 'fundamental-mode)

(setq delete-by-moving-to-trash t
      blink-cursor-blinks       2
      inhibit-startup-message   t
      ring-bell-function        'ignore
      show-trailing-whitespace  t
      create-lockfiles          nil
      ;; See https://debbugs.gnu.org/cgi/bugreport.cgi?msg=5;bug=55737
      read-process-output-max   65535
      use-dialog-box            nil
      use-short-answers         t
      ;; TAB indents, or if already indented, complete-at-point.
      tab-always-indent         'complete
      ;; Small speed up by not bothering with VCs other than git
      vc-handled-backends       '(Git))

(setq read-file-name-completion-ignore-case t)

(setq-default cursor-type 'hbar
              indent-tabs-mode nil
              fill-column 99)

(add-hook 'before-save-hook #'delete-trailing-whitespace)

(column-number-mode t)

(add-hook 'text-mode-hook #'turn-on-auto-fill)
(add-hook 'text-mode-hook #'visual-line-mode)

(add-hook 'prog-mode-hook #'electric-pair-local-mode)
(setq js-indent-level 2)

(setopt Buffer-menu-group-by '(Buffer-menu-group-by-mode)
        text-mode-ispell-word-completion nil)

(setq frame-title-format '(buffer-file-name
                           (:eval (abbreviate-file-name (buffer-file-name)))
                           "%b"))

;; Split the inital frame
(when (< split-width-threshold (frame-parameter nil 'width))
  (split-window-horizontally))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  user-lisp packages
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package my-commands
  :ensure nil ;; a user-lisp package
  :bind (("C-c C-i" . indent-whole-buffer)
         ("<f8>" . github-url-at-point)
         ("<f11>" . ask-claude)))

(use-package shrink-expand-frame
  :ensure nil  ;; a user-lisp package
  :bind* (("C-{" . shrink-frame-horizontally)
          ("C-}" . expand-frame-horizontally)))

(require 'my-mode-line)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Key Bindings
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(bind-key "M-j" (lambda ()
                  "Joins the next line to this, regardless of where the point is in the line."
                  (interactive) (join-line -1)))

(bind-keys
 ("<f2>"      . revert-buffer-quick)
 ("C-c C-k"   . kill-region)
 ("C-h m"     . manual-entry)
 ("C-w"       . backward-kill-word)
 ("C-x C-s-f" . find-file-other-window)
 ("C-z"       . undo)
 ;; M-> is S-M-. which is set to effectively undo M-.
 ("M->"       . pop-tag-mark))

(bind-key* "C-." #'completion-at-point)

;; Unset mouse wheel changing font size: easy to accidently trigger.
(keymap-global-unset "C-<wheel-up>")
(keymap-global-unset "C-<wheel-down>")

(bind-keys ("C-+" . text-scale-increase)
           ("C-_" . text-scale-decrease))
;; C-) (aka C-S-0) needs bind-key* to override a default binding in `paredit-mode-map'.
(bind-key* "C-)" (lambda ()
                   (interactive) (text-scale-increase 0)))

(when on-mac-window-system
  (keymap-global-unset  "s-t")
  (keymap-global-unset  "s-q")
  (bind-keys ("s-<return>" . 'toggle-frame-maximized)
             ("s-w" . delete-frame))
  ;; Emulate a 3-button mouse (<mouse-2> is middle click, <mouse-3> right click)
  (keymap-set key-translation-map "s-<mouse-3>" "<mouse-2>"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Packages
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package display-line-numbers :config (global-display-line-numbers-mode 1))
(use-package paren        :config (show-paren-mode))
(use-package server       :config (server-start))
(use-package windmove     :config (windmove-default-keybindings))
;; pixel-scroll needs :ensure nil as it is completely missing from ELPA (built-in only)
(use-package pixel-scroll :ensure nil :config (pixel-scroll-mode 1))
(use-package which-key    :config (which-key-mode))

(use-package sr-speedbar
  ;; Don't :after speedbar, as then use-package won't bind-key. Instead, :defer
  ;; the speedbar package below.
  :custom
  (sr-speedbar-use-frame-root-window t)
  (sr-speedbar-right-side nil)
  :commands sr-speed-bar-toggle
  :bind ("<f10>" . sr-speedbar-toggle))

(use-package speedbar
  :defer t   ;; See comment on the use-package stanza for `sr-speedbar'.
  :custom (speedbar-show-unknown-files t))

(use-package markdown-ts-mode
  :mode "\\.md\\'"
  :custom-face
  (markdown-ts-heading-1
   ((t (:inherit font-lock-function-name-face :weight bold :height 1.5))))
  (markdown-ts-heading-2
   ((t (:inherit font-lock-function-name-face :weight bold :height 1.4))))
  (markdown-ts-heading-3
   ((t (:inherit font-lock-function-name-face :weight bold :height 1.3))))
  (markdown-ts-heading-4
   ((t (:inherit font-lock-function-name-face :weight bold :height 1.2))))
  (markdown-ts-heading-5
   ((t (:inherit font-lock-function-name-face :weight bold :height 1.1)))))

(use-package auto-dim-other-buffers
  ;; There's massive speedup from starting this in `after-init-hook', but doing it there
  ;; would override a face if set by a theme loaded earlier. Explicitly save and restore it.
  :hook (after-init . (lambda ()
                        (let ((bg (face-attribute 'auto-dim-other-buffers :background)))
                          (auto-dim-other-buffers-mode)
                          (set-face-attribute 'auto-dim-other-buffers nil :background bg)))))

;; Corfu for in-buffer completions, Vertico for mini-buffer completions
(use-package corfu
  :config
  (global-corfu-mode)
  ;; Show corfu-info-documentation in a popup
  (corfu-popupinfo-mode))

(use-package vertico :config (vertico-mode))

(use-package marginalia
  :after vertico
  :config (marginalia-mode)
  :bind ((:map minibuffer-local-map ("M-A" . marginalia-cycle))
         (:map completion-list-mode-map ("M-A" . marginalia-cycle)))
  ;; :bind implies defer, but this need to be started not only in response
  ;; to the defined keybindings
  :demand t)

(use-package yasnippet
  :defer t)

(use-package smtpmail
  :autoload smtpmail-send-it
  :custom
  (send-mail-function 'smtpmail-send-it)
  (smtpmail-smtp-server "smtp.gmail.com")
  (smtpmail-smtp-service 465)
  (smtpmail-stream-type 'ssl)
  (smtpmail-servers-requiring-authorization "\\.gmail\\.com"))

 ;; Buttonize URLs and e-mail addresses.
(use-package goto-addr
  :config (global-goto-address-mode))

(use-package flyspell
  :bind ((:map flyspell-mode-map) ("<mouse-3>" . flyspell-correct-word-before-point))
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode)))

(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-c g" . magit-file-dispatch))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-section-initial-visibility-alist '((stashes . show)
                                            (recent . show)
                                            (unpushed . show)))
  (magit-status-margin '(t age magit-log-margin-width nil 18))
  :hook (git-commit-setup . (lambda () (setq-local fill-column 72)))
  :config (magit-add-section-hook 'magit-status-sections-hook
                                  'magit-insert-worktrees
                                  'magit-insert-stashes
                                  t))

(use-package diff-hl
  :after magit
  :config (global-diff-hl-mode)
  :hook ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)))

(use-package vterm
  :bind ("<f12>" . vterm-other-window))

(use-package deadgrep
  :ensure-system-package (rg . ripgrep)
  :bind ("<f3>" . deadgrep))

(use-package dash-at-point
  :if on-mac-window-system
  :ensure-system-package "/Applications/Dash.app"
  :bind ("C-?" . dash-at-point))

(use-package which-func
  :config
  (setq which-func-unknown "")
  ;; Drop the brackets
  (when (equal (car which-func-format) "[")
    (setq which-func-format (cadr which-func-format)))
  :custom-face (which-func ((t (:inherit nil))))
  ;; Package is called `which-func', but mode is `which-function-mode'
  :hook ((c++-ts-mode java-ts-mode js-ts-mode) . which-function-mode))

(use-package eglot
  :bind ((:map eglot-mode-map
               ("C-c i" . eglot-find-implementation)
               ("C-c d" . eglot-find-declaration)
               ("C-c t" . eglot-find-typeDeclaration))))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Flymake
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Tree-sitter
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Fonts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(set-charset-priority 'unicode)

(when (display-multi-font-p)
  (set-fontset-font t nil (font-spec :family "Noto Sans Symbols") nil :append)
  (set-fontset-font t nil (font-spec :family "Noto Sans Symbols 2") nil :append))

(set-face-attribute 'default nil :family "Comic Code")
(set-face-attribute 'variable-pitch nil :family "Noto Sans")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Text (Terminal) Frames
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun my--hide-menu-bar-on-text-frames (&optional frame)
  "Toggle the menu bar based on FRAME being text-only or graphical."
  (let ((frame (or frame (selected-frame))))
    (set-frame-parameter frame 'menu-bar-lines
                         (if (display-graphic-p frame) 1 0))))

(add-hook 'after-make-frame-functions #'my--hide-menu-bar-on-text-frames)
;; Also apply to the already created initial frame.
(dolist (frame (frame-list))
  (my--hide-menu-bar-on-text-frames frame))

(use-package xt-mouse
  :if (version< emacs-version "31.1")
  :commands xterm-mouse-mode
  :init
  ;; can't use `:hook', as after-make-frame-functions doesn't have a -hook suffix.
  (add-hook 'after-make-frame-functions (lambda (&optional frame)
                                          (unless (or xterm-mouse-mode
                                                      (display-graphic-p frame))
                                            (xterm-mouse-mode)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Custom File
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load-file custom-file)


(provide 'init)
;;; init.el ends here
