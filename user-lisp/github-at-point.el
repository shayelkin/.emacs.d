;;; github-at-point.el --- Get a GitHub link for the point. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; Package-Requires: ((emacs "30.1"))
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

(defun github-at-point--git (&rest args)
  "Run git with ARGS and return its output as a list of lines, or nil on failure."
  (with-temp-buffer
    (when (eq 0 (apply #'process-file "git" nil '(t nil) nil args))
      (split-string (buffer-string) "\n" t))))

(defun github-at-point--remote-url ()
  "Return a URL for the current buffer's git remotes that are hosted on GitHub.

If there are multiple GitHub hosted remotes, returns the first one."
  (seq-find
   (lambda (r) (string-match-p "github\\.com" r))
   (mapcar
    (lambda (line) (substring line (1+ (string-match " " line))))
    (github-at-point--git "config" "--get-regexp" "^remote\\..*\\.url$"))))

;;;###autoload
(defun github-at-point ()
  "Generate a GitHub link for current file position and copy it into the clipboard."
  (interactive)
  (if-let* ((filename (buffer-file-name))
            (base-url (replace-regexp-in-string
                       "\\(git@github\\.com:\\|https://github\\.com/\\)\\(.*\\)\\.git$"
                       "https://github.com/\\2"
                       (github-at-point--remote-url)))
            (relative-path (file-relative-name filename
                                               (car (github-at-point--git "rev-parse" "--show-toplevel"))))
            (rev (car (github-at-point--git "rev-parse" "HEAD")))
            (url (format "%s/blob/%s/%s#L%d"
                                base-url
                                rev
                                relative-path
                                (line-number-at-pos))))
      (progn
        (when (called-interactively-p 'interactive)
          (browse-url url))
        url)
    (when (called-interactively-p 'interactive)
      (message "Can't find a GitHub hosted remote for the current buffer"))))

(provide 'github-at-point)
;;; github-at-point.el ends here
