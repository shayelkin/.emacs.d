;;; early-init.el --- Loaded before packages and GUI are initialized. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; SPDX-License-Identifier: MIT
;; Package-Requires: ((emacs "30.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Does two things that should happen as early as possible, to speed up Emacs' startup speed:
;; - Delay garbage collection until after startup.
;; - Set the frame parameters before the first frame is redrawn, as updating an existing frame
;;   can take >0.2s.

;;; Code:

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold 10000000) ;; Emacs' default is 800000
            (setq gc-cons-percentage 0.1)))

(modify-all-frames-parameters
 '((height . 53)
   (width . 202)
   (tool-bar-lines . 0)
   (vertical-scroll-bars . nil)))

(provide 'early-init)
;;; early-init.el ends here
