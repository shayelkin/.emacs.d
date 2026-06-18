;;; early-init.el --- Loaded before packages and GUI are initialized. -*- lexical-binding: t -*-

;; SPDX-License-Identifier: MIT
;; Author: Shay Elkin <shay@elkin.io>
;; Package-Requires: ((emacs "30.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

;; Avoid GC pauses during startup.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold 10000000) ;; Emacs' default is 800000
            (setq gc-cons-percentage 0.1)))

;; Set frame parameters before it is displayed, to avoid a redraw (hiding the
;; toolbar after frame creation takes 0.2s).
(modify-all-frames-parameters
 '((height . 53)
   (width . 202)
   (tool-bar-lines . 0)
   (vertical-scroll-bars . nil)))

(provide 'early-init)
;;; early-init.el ends here
