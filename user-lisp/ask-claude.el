;;; ask-claude.el --- Send a one-shot query to Claude. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; Package-Requires: ((emacs "30.1"))
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

(defcustom ask-claude-model "sonnet"
  "Model name passed to \"claude --model\".
When nil, the default is used."
  :type '(choice (const :tag "Default" nil) string)
  :group 'ask-claude)

;;;###autoload
(defun ask-claude (prompt)
  "Run \"claude --print\" with PROMPT and show the result in a new buffer.

When the region is active its contents are used as the default PROMPT."
  (interactive
   (list (read-string "Ask Claude: "
                      (when (use-region-p)
                        (buffer-substring-no-properties (region-beginning)
                                                        (region-end))))))
  (let ((buffer (generate-new-buffer "*claude*")))
    (with-current-buffer buffer
      (setq buffer-read-only t)
      (view-mode 1)
      (let ((inhibit-read-only t))
        (goto-char (point-max))
        (insert (format "\n\n> %s\n\n" prompt)))
      (setq mode-line-process '(:propertize "running" face compilation-mode-line-run)))
    (let ((proc
           (make-process
            :name "claude"
            :buffer buffer
            :command (append '("claude" "--print")
                             (when ask-claude-model (list "--model" ask-claude-model))
                             (list prompt))
            :noquery t
            :connection-type 'pipe
            :sentinel (lambda (proc event)
                        (unless (process-live-p proc)
                          (with-current-buffer (process-buffer proc)
                            (let ((inhibit-read-only t))
                              (goto-char (point-max))
                              (insert (format "\n\n[claude %s]" (string-trim event))))
                            (setq mode-line-process nil)))))))
      ;; claude reads stdin; close it so it doesn't wait for input.
      (process-send-eof proc))
    (display-buffer buffer)))


(provide 'ask-claude)
;;; ask-claude.el ends here
