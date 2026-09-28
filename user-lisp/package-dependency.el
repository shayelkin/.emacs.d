;;; package-dependency.el --- Build a DAG of installed Packages. -*- lexical-binding: t -*-

;; Author: Shay Elkin <shay@elkin.io>
;; Package-Requires: ((emacs "30.1"))
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Code:

;;;###autoload
(defun package-dependency-dag ()
  "Builds a complete dependency DAG for all installed packages.
Returns an alist where each entry is (package . (list-of-dependencies))."
  (let* ((dag (list (cons 'emacs nil))))
    (dolist (pkg package-alist)
      (push (cons (car pkg) (list (mapcar #'car (package-desc-reqs (cadr pkg))))) dag))
    ;; Make sure every package, including built-in ones is listed, so we could use `tsort'
    (dolist (dep (seq-mapcat #'cadr dag))
      (unless (assq dep dag)
        (push (cons dep '((emacs))) dag)))
    dag))

(provide 'package-dependency)
;;; package-dependency.el ends here
