;; shrink-expand-frame.el -- Add/remove window while keeping others the same size. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; Package-Requires: ((emacs "30.1"))
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

;;;###autoload
(defun shrink-frame-horizontally (&optional window)
  "Delete the window to the right of WINDOW.

If WINDOW is the right-most window in the row, delete the one to its left.
When on a window system, also shrink the frame by the size of the deleted window"
  (interactive)
  (if-let* ((window (or window (selected-window)))
            (window-to-delete (or (window-in-direction 'right window)
                                  (window-in-direction 'left window)))
            (frame (window-frame window-to-delete))
            (shrink-by (window-total-width window-to-delete)))
      (progn
        (delete-window window-to-delete)
        (when window-system
          (set-frame-width frame (- (frame-width frame) shrink-by))))
    (message "There is no other window in the row to delete.")))

(defun shrink-expand-frame--move-frame-left-if-needed (&optional frame)
  "Move FRAME to be inside the display if possible."
  (interactive)
  (let* ((frame (or frame (selected-frame)))
         (frame-width (frame-pixel-width frame))
         (display-width (display-pixel-width)))
    (when (> (+ (frame-parameter frame 'left) frame-width) display-width)
      (set-frame-position frame
                          (max 0 (- display-width frame-width))
                          (frame-parameter frame 'top)))))

(defun shrink-expand-frame--is-fullwidth (&optional frame)
  "Returns non-nil if FRAME is fullwidth, fullboth, or maximized"
  (memq (frame-parameter (or frame (selected-frame)) 'fullscreen)
          '(fullboth fullwidth maximized)))

;;;###autoload
(defun expand-frame-horizontally (&optional window)
  "Create a window to the right of WINDOW and on window system expand the frame."
  (interactive)
  (let ((window (or window (selected-window))))
    (if-let*
        ((frame (window-frame window))
         (should-expand (and (display-graphic-p frame)
                             ;; In Emacs >31, trying to expand a frame on
                             (not (shrink-expand-frame--is-fullwidth frame))))
         (original-frame-width (frame-width frame))
         (expand-by (window-total-width window)))
        (progn
          ;; set-frame-width first, to have window and the new window be the same size
          (set-frame-width frame (+ original-frame-width expand-by))
          (shrink-expand-frame--move-frame-left-if-needed)
          (unless (split-window-right nil window)
            (set-frame-width frame original-frame-width)))
      (split-window-right nil window))))

(provide 'shrink-expand-frame)
;;; shrink-expand-frame.el ends here
