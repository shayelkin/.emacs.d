;;; my-use-packages.el -- Emacs configuration for added packages. -*- lexical-binding: t -*-

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


;;; ======================================================================
;;; Package management
;;; ======================================================================

(require 'package)
(setq package-archives '(("gnu"          . "https://elpa.gnu.org/packages/")
			 ("melpa-stable" . "https://stable.melpa.org/packages/")
                         ("melpa"        . "https://melpa.org/packages/"))
      package-archive-priorities '(("melpa-stable" . 0)
                                   ("gnu"          . 1)
                                   ("melpa"        . 2)))


;;; ======================================================================
;;; Non-modes
;;; ======================================================================


(use-package magit
  :bind ("C-x g" . magit-status)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-section-initial-visibility-alist '((stashes . show)
                                            (recent . show)
                                            (unpushed . show)))
  (magit-status-margin '(t age magit-log-margin-width nil 18))
  :hook (git-commit-setup . (lambda () (setq-local fill-column 72)))
  :config (magit-add-section-hook 'magit-status-sections-hook
                                  'magit-insert-stashes
                                  'magit-insert-worktrees t))

;; (use-package windsize
;;   :config (windsize-default-keybindings))

(use-package vterm
  :bind ("<f12>" . vterm-other-window))

(use-package deadgrep
  :ensure-system-package (rg . ripgrep)
  :bind ("<f3>" . deadgrep))

(use-package sr-speedbar
  ;; Don't :after speedbar, as then use-package won't bind-key. Instead, :defer
  ;; the speedbar package (loaded in `my-use-packages-built-in')
  :custom (sr-speedbar-use-frame-root-window t)
  :commands (sr-speed-bar-toggle)
  :bind ("<f10>" . sr-speedbar-toggle))

(use-package dash-at-point
  :if on-mac-window-system
  :ensure-system-package "/Applications/Dash.app"
  :bind ("C-?" . dash-at-point))


;;; ======================================================================
;;; Minor modes
;;; ======================================================================

(use-package diff-hl
  :after magit
  :config (global-diff-hl-mode)
  :hook ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)))

(use-package yasnippet
  :defer t)

;; Corfu for in-buffer completions, Vertico for mini-buffer completions
(use-package corfu
  :config
  (global-corfu-mode)
  ;; Show corfu-info-documentation in a popup
  (corfu-popupinfo-mode))

(use-package vertico
  :config (vertico-mode))

(use-package marginalia
  :after vertico
  :config (marginalia-mode)
  :bind ((:map minibuffer-local-map ("M-A" . marginalia-cycle))
         (:map completion-list-mode-map ("M-A" . marginalia-cycle)))
  ;; :bind implies defer, but this need to be started not only in response
  ;; to the defined keybindings
  :demand t)

(use-package auto-dim-other-buffers
  ;; There's massive speedup from starting this in `after-init-hook', but doing it there
  ;; would override a face if set by a theme loaded earlier. Explicitly save and restore it.
  :hook (after-init . (lambda ()
                        (let ((bg (face-attribute 'auto-dim-other-buffers :background)))
                          (auto-dim-other-buffers-mode)
                          (set-face-attribute 'auto-dim-other-buffers nil :background bg)))))

;; ultra-scroll takes longer to load than any other package I use. Disabled for now.
;; (use-package ultra-scroll
;;   :config (ultra-scroll-mode))

(use-package makefile-executor
  :hook (makefile-mode . makefile-executor-mode))

(use-package uv-mode
  :hook ((python-ts-mode python-mode) . uv-mode-auto-activate-hook))


;;; ======================================================================
;;; Major modes
;;; ======================================================================


;; `markdown-ts-mode' exists, but markdown-mode has better ergonomics.
(use-package markdown-mode
  :mode "\\.md\\'"
  :custom
  (markdown-header-scaling t)
  (markdown-header-scaling-values '(1.6 1.3 1.1 1.0 1.0 1.0))
  ;; Make the default font for markdown buffers variable-pitch
  ;; :hook (markdown-mode . (lambda ()
  ;;                          (setq buffer-face-mode-face '(:inherit variable-pitch :height 1.2))
  ;;                          (buffer-face-mode)))
  )

;; (use-package markdown-ts-mode
;;   :mode "\\.md\\'"
;;   :config
;;   (add-to-list 'treesit-language-source-alist
;;                '(markdown
;;                  "https://github.com/tree-sitter-grammars/tree-sitter-markdown"
;;                  "split_parser"
;;                  "tree-sitter-markdown/src"))
;;   (add-to-list 'treesit-language-source-alist
;;                '(markdown-inline
;;                  "https://github.com/tree-sitter-grammars/tree-sitter-markdown"
;;                  "split_parser"
;;                  "tree-sitter-markdown-inline/src")))


(use-package swift-ts-mode
  :ensure nil
  :mode "\\.swift\\'")
;; To build tree-sitter-swift:
;; 1. https://github.com/alex-pinkus/tree-sitter-swift/blob/main/README.md#where-is-your-parserc
;; 2. `cc -fPIC -c -I. -shared parser.c scanner.c -o ~/.config/emacs/tree-sitter/tree-sitter-swift.dylib`

(use-package protobuf-ts-mode
  :mode "\\.proto\\'"
  :config (add-to-list 'treesit-language-source-alist
                       '(proto "https://github.com/mitchellh/tree-sitter-proto")))

(use-package terraform-mode
  :mode "\\.t\\(f\\(vars\\)?\\|ofu\\)\\'")

(use-package awk-ts-mode
  :mode "\\.[mg]?awk\\'")

(use-package perl-ts-mode
  :mode "\\.pl\\'")

(use-package scala-ts-mode
  :mode "\\.sc\\(ala\\)?\\'" "\\.sbt\\'")


(provide 'my-use-packages)
;;; my-use-packages.el ends here
