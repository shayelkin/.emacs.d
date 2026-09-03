;;; my-mode-line.el --- Mode line customizations. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; Package-Requires: ((emacs "30.1")
;;                    (nyan-mode "1.1.3")
;;                    (crc "1.0.0"))
;;
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:

;; My most extenstive customization to Emacs: a more sparse mode-line, inspired by
;; `mood-line', with a `nyan-mode' scroll bar between the left and right parts.

;;; Code:

(require 'color)
(require 'face-remap)
(require 'nyan-mode)
(require 'crc)

(setq mode-line-right-align-edge 'right-fringe
      ;; `my--mode-line-middle' puts a `%p' if needed.
      mode-line-percent-position nil
      vc-display-status 'no-backend
      ;; Remove the square brackets around the counters.
      flymake-mode-line-counter-format '(""
                                         flymake-mode-line-error-counter
                                         flymake-mode-line-warning-counter
                                         flymake-mode-line-note-counter " "))

(defvar my--flymake-empty-counters-propertized-str
  `(:propertize ("✔ ")
                help-echo "mouse-1: Check now"
                local-map ,(let ((map (make-sparse-keymap)))
                             (define-key map [mode-line down-mouse-1] 'flymake-start)
                             map)))

(defun my--flymake-mode-line ()
  "Mode line construct for Flymake information."
  (when (bound-and-true-p flymake-mode)
    (let* ((exception (format-mode-line flymake-mode-line-exception))
           (counters (format-mode-line flymake-mode-line-counters))
           ;; Extract the counters and sum them
           (counters-sum (apply #'+ (mapcar #'string-to-number (split-string counters "[^0-9]+" t)))))
      (list
       exception
       (cond ((> counters-sum 0) counters)
             ((length= exception 0) my--flymake-empty-counters-propertized-str))))))

;; The default value for mode-line-buffer-identification is ("%12b"), I want just " %b ".
(defvar my--propertized-buffer-identification
  (car (propertized-buffer-identification " %b ")))

(defface mode-line-buffer-id-modified
  '((t (:inherit (mode-line-buffer-id warning))))
  "Face used for buffer identification in the mode line, when buffer is modified.")

(defvar my--propertized-buffer-identification-modified
  (let ((copy (copy-sequence my--propertized-buffer-identification)))
    (add-face-text-property 1 (1- (length copy)) 'mode-line-buffer-id-modified t copy)
    copy))

(defun my--mode-line-buffer-identification ()
  "Return `mode-line-buffer-identification' propertized in `mode-line-buffer-id-modified' when buffer is modified."
  (cond
   ((local-variable-p 'mode-line-buffer-identification) mode-line-buffer-identification)
   ((buffer-modified-p) my--propertized-buffer-identification-modified)
   (t my--propertized-buffer-identification)))

(defun string-pixel-width-face (str face)
  "Return pixel width of STR when rendered with in FACE."
  (let ((copy (copy-sequence str)))
    ;; Append as base face to preserving existing face properties in `str'
    (add-face-text-property 0 (length copy) face t copy)
    (string-pixel-width copy)))

(defconst my--nyan-char-width-px 8)

(defvar-local nyan-cache nil
  "A cons cell with (nyan-bar-length (point)) as car, and a matching nyan bar as cdr.")

(defun my--mode-line-middle ()
  (let* ((left-str (format-mode-line my--mode-line-format-left))
         (left-px  (string-pixel-width-face left-str 'mode-line))
         (right-str (format-mode-line my--mode-line-format-right))
         (right-px  (string-pixel-width-face right-str 'mode-line))
         (space-px (- (window-pixel-width) left-px right-px))
         (nyan-bar-length (1- (/ space-px my--nyan-char-width-px)))
         (draw-nyan (and (display-graphic-p) (> nyan-bar-length 3))))
    (list ""
          (if (not draw-nyan) '(-3 "%p")
            (let ((cache-args (cons nyan-bar-length (point))))
              (when (not (equal cache-args (car nyan-cache)))
                ;; At a glance `nyan-create' looks far from optimal, but benchmarking
                ;; different concatanation strategies and caching create-image doesn't
                ;; show much difference.
                (setq nyan-cache (cons cache-args (nyan-create)))))
            (cdr nyan-cache))
          (propertize " " 'display `(space :align-to (- right-fringe (,right-px)))))))

(defvar my--mode-line-format-left
  '(("" mode-line-mule-info mode-line-client mode-line-modified
     mode-line-remote mode-line-window-dedicated)
    (:eval (my--mode-line-buffer-identification))
    (vc-mode vc-mode) "\t"
    mode-line-position))

(defvar my--mode-line-format-right
  `((:eval (when indent-tabs-mode #("TAB " 0 3 (face warning))))
    mode-line-misc-info
    (:propertize ("" mode-name)
                 help-echo "mouse-1: Display major mode menu\n\
mouse-2: Show help for major mode\n\
mouse-3: Toggle minor modes"
                 mouse-face mode-line-highlight
                 local-map ,mode-line-major-mode-keymap)
    " "
    (:eval (my--flymake-mode-line))
    mode-line-process))

(defcustom mode-line-repo-background-colors-count 12
  "How many colors to use to differentiate a buffer source by mode-line's background.

The hues picked are evenly spaced on the color wheel, and selecting which one to use for each
buffer is determined by the local git repository it belongs to."
  :type '(natnum)
  :group 'mode-line-faces)

(defvar-local git-repo-id 'unset
  "A unique ID per local git repository, nil when the buffer isn't in one.
Holds `unset' until looked up for the buffer.")

(defvar my--git-repo-id-cache (make-hash-table :test 'equal)
  "Maps a `default-directory' to its repository ID, or to nil when it has none.")

(defvar-local mode-line-background-remap-cookie nil
  "face-remap cookie for this buffer's mode-line, so re-applying doesn't stack.")

(defun set-buffer-mode-line-background-hue (hue)
  "Set this buffer's mode-line background to the given HUE, a number between 0.0 and 1.0, inclusive."
  (interactive)
  (when mode-line-background-remap-cookie
    (face-remap-remove-relative mode-line-background-remap-cookie)
    (setq mode-line-background-remap-cookie nil))
  (when hue
    (setq mode-line-background-remap-cookie
          (face-remap-add-relative 'mode-line :background (apply 'color-rgb-to-hex (color-hsl-to-rgb hue 0.45 0.45))))))

(defun my--git-common-dir ()
  "Return the absolute path of this buffer's git common dir, or nil if there is none."
  (with-temp-buffer
    (when (eq 0 (process-file "git" nil '(t nil) nil
                              "rev-parse" "--path-format=absolute" "--git-common-dir"))
      (car (split-string (buffer-string) "\n" t)))))

(defun my--apply-mode-line-repo-background-hue ()
  "Set a unique color for the mode-line, based on the git repository it belongs to."
  (when (eq git-repo-id 'unset)
    (setq git-repo-id
          (let ((cached (gethash default-directory my--git-repo-id-cache 'unset)))
            (if (not (eq cached 'unset)) cached
              (puthash default-directory
                       (when-let* ((common-dir (my--git-common-dir)))
                         (file-name-nondirectory (string-remove-suffix "/.git" common-dir)))
                       my--git-repo-id-cache)))))
  (let* ((hue-index (if (not git-repo-id) 0
                      (1+ (% (crc-32 git-repo-id) (1- mode-line-repo-background-colors-count)))))
         (hue (/ hue-index (float mode-line-repo-background-colors-count))))
    (set-buffer-mode-line-background-hue hue)))

(add-hook 'after-change-major-mode-hook #'my--apply-mode-line-repo-background-hue)

(setq-default mode-line-format
              `(,@my--mode-line-format-left
                (:eval (my--mode-line-middle))
                ,@my--mode-line-format-right))

(custom-set-faces
 '(mode-line ((t (:inherit variable-pitch :height 1.2 :foreground "#fff"))))
 '(mode-line-inactive ((t (:inherit variable-pitch :height 1.2)))))

(provide 'my-mode-line)
;;; my-mode-line.el ends here
