;;; init.el --- Emacs initialization file. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; SPDX-License-Identifier: MIT
;; Package-Requires: ((emacs "30.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

;; Don't bother with backwards compatibility.
(when (version< emacs-version "30")
  (error "It is time to upgrade this Emacs!"))

;; Take effect early, before anything that would try to connect to remotes
(setq gnutls-verify-error t)

(eval-when-compile
  (require 'use-package)
  (require 'use-package-ensure))
(require 'bind-key)

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs loaded in %.3f seconds with %d garbage collections done."
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

(defconst on-mac-window-system (memq window-system '(mac ns))
  "Non-nil when running on macOS graphical environment.")

;; Like `exec-path-from-shell' but faster, as it just gets PATH from bash or zsh,
;; which is all I care for.
(when on-mac-window-system
  (let ((path-string (string-trim
                      (with-temp-buffer
                        (call-process (getenv "SHELL") nil t nil "-lc" "echo $PATH")
                        (buffer-string)))))
    (setq exec-path (parse-colon-path path-string))
    (setenv "PATH" path-string)))

(setq use-package-compute-statistics t
      use-package-always-ensure t
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

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'my-commands)
(require 'my-mode-line)
(require 'my-prog-custom)

;; This is also a time saver, as having the scratch buffer be `lisp-interaction-mode'
;; costs ~150ms at startup.
(setq initial-major-mode 'fundamental-mode)

(setq delete-by-moving-to-trash t
      blink-cursor-blinks       2
      inhibit-startup-message   t
      mac-option-modifier       'meta
      read-file-name-completion-ignore-case t
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

(setq-default cursor-type 'hbar
              indent-tabs-mode nil
              fill-column 99)
(add-hook 'before-save-hook #'delete-trailing-whitespace)
(column-number-mode t)
(global-display-line-numbers-mode t)

(add-hook 'text-mode-hook #'turn-on-auto-fill)
(add-hook 'text-mode-hook #'visual-line-mode)
(setopt Buffer-menu-group-by '(Buffer-menu-group-by-mode)
        text-mode-ispell-word-completion nil)

;; Sort the buffer list by major mode
(add-hook 'buffer-menu-mode-hook (lambda () (Buffer-menu-sort 5)))

(setq frame-title-format '(buffer-file-name
                           (:eval (abbreviate-file-name (buffer-file-name)))
                           "%b"))



;;;;; Key bindings

(bind-key "M-j" (lambda ()
                  "Joins the next line to this, regardless of where the point is in the line."
                  (interactive) (join-line -1)))

(bind-keys ("C-x C-s-f" . find-file-other-window)
           ("<f2>" . revert-buffer-quick)
           ("C-c C-k" . kill-region)
           ("C-w" . backward-kill-word)
           ("C-z" . undo)
           ;; M-> is S-M-. which is set to effectively undo M-.
           ("M->" . pop-tag-mark)
           ("C-h m" . manual-entry))

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

;;;;;

(use-package server   :config (server-start))
(use-package windmove :config (windmove-default-keybindings))
(use-package paren    :config (show-paren-mode))

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

;; `markdown-ts-mode' exists, but markdown-mode has better ergonomics today.
(use-package markdown-mode
  :mode "\\.md\\'"
  :custom
  (markdown-header-scaling t)
  ;; Make the default font for markdown buffers variable-pitch
  ;; :hook (markdown-mode . (lambda ()
  ;;                          (setq buffer-face-mode-face '(:inherit variable-pitch :height 1.2))
  ;;                          (buffer-face-mode)))
  )

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
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode)))

(use-package which-key
  :config (which-key-mode))

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

;;;;; Fonts ;;;;;

(set-charset-priority 'unicode)

(when (display-multi-font-p)
  (set-fontset-font t nil (font-spec :family "Noto Sans Symbols") nil :append)
  (set-fontset-font t nil (font-spec :family "Noto Sans Symbols 2") nil :append))

(set-face-attribute 'default nil :family "Comic Code")
(set-face-attribute 'variable-pitch nil :family "Noto Sans")

;;;;; Text (terminal) frames ;;;;

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
  :commands xterm-mouse-mode
  :init
  ;; can't use `:hook', as after-make-frame-functions doesn't have a -hook suffix.
  (add-hook 'after-make-frame-functions (lambda (&optional frame)
                                          (unless (or xterm-mouse-mode
                                                      (display-graphic-p frame))
                                            (xterm-mouse-mode)))))




;; Split the inital frame
(when (< split-width-threshold (frame-parameter nil 'width))
  (split-window-horizontally))

;; Custom file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load-file custom-file)

(provide 'init)
;;; init.el ends here
