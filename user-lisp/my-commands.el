;;; my-commands.el --- Misc. commands for Emacs. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; Package-Requires: ((emacs "30.1")
;;                    (magit "2.90.0"))
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

;;;###autoload
(defun indent-whole-buffer ()
  "Indent the whole buffer."
  (interactive)
  (indent-region (point-min) (point-max) nil))

;;;###autoload
(defun rename-file-and-buffer (new-name)
  "Renames both the current buffer and the file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not filename)
        (message "Buffer '%s' is not visiting a file!" name)
      (if (get-buffer new-name)
          (message "A buffer named '%s' already exists!" new-name)
        (progn
          (rename-file name new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Generates a GitHub link for the current position
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun my--github-remote-urls ()
  "Return the URLs for the current buffer's git remotes that are hosted on GitHub."
  (declare-function magit-get "magit-git")
  (declare-function magit-list-remotes "magit-git")
  (seq-filter
   (lambda (r) (string-match-p "github\\.com" r))
   (mapcar
    (lambda (r) (magit-get "remote" r "url"))
    (magit-list-remotes))))

;;;###autoload
(defun github-url-at-point ()
  "Generate a GitHub link for current file position and copy it into the clipboard."
  (interactive)
  (require 'magit)
  (if-let* ((filename (buffer-file-name))
            (remote-url (car (my--github-remote-urls)))
            (relative-path (file-relative-name filename (magit-toplevel)))
            (github-url (format "%s/blob/%s/%s#L%d"
                                (replace-regexp-in-string
                                 "\\(git@github\\.com:\\|https://github\\.com/\\)\\(.*\\)\\.git$"
                                 "https://github.com/\\2"
                                 remote-url)
                                (magit-rev-parse "HEAD")
                                relative-path
                                (line-number-at-pos))))
      (progn
        (when (called-interactively-p 'interactive)
          (browse-url github-url))
        github-url)
    (when (called-interactively-p 'interactive)
      (message "Can't find a GitHub hosted remote for the current buffer"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Query Claude
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(provide 'my-commands)
;;; my-commands.el ends here
