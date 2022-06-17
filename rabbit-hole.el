;;; rabbit-hole.el --- A tool for helping one descend rabbit holes -*- lexical-binding: t -*-

;; Author: Zachary Romero
;; Maintainer: Zachary Romero
;; Version: 0.1.0
;; Package-Requires: ()
;; Homepage: https://github.com/rabbit-hole.el


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; commentary

;;; Code:

(defgroup rabbit-hole nil
  ""
  :prefix "rabbit-hole-"
  :group 'TODO)

(defconst rabbit-hole-mode-name "Rabbit-Hole")

(defcustom rabbit-hole-indentation 2
  "The amount of indentation of each deeper level."
  :group 'rabbit-hole)

(defcustom rabbit-hole-file "~/Dropbox/org/refile.org"
  "File to save rabbit-hole tree in."
  :group 'rabbit-hole)

(defcustom rabbit-hole-header "Rabbit Hole"
  "Header under which to store task tree.

This header is located in the file stored in the variable
`rabbit-hole-file'."
  :group 'rabbit-hole)

(defcustom rabbit-hole-message-on-action t
  "When non-nil, message the most recent tree when running a command."
  :group 'rabbit-hole)

(defface rabbit-hole-current-task-face
  '((t (:inherit underline)))
  "`rabbit-hole-mode' face used for a showing current task."
  :group 'rabbit-hole)

(defun rabbit-hole--narrow-to-subtree ()
  "Helper function to find subtree and narrow to it."
  (widen)
  (goto-char (point-min))
  (let ((header-found-p (search-forward (concat "* " rabbit-hole-header) nil t)))
    (unless header-found-p
      (error "unable to find rabbit hole header"))
    (org-narrow-to-subtree)
    (goto-char (point-min))))

(defun rabbit-hole--fontify-last-item ()
  "Fontify the last item in the rabbit-hole task tree."
  (with-current-buffer "*rabbit-hole*"
    (when (save-excursion (goto-char (point-max))
                          (search-backward "- " nil t))
      (let ((start (save-excursion (goto-char (point-max))
                                   (search-backward "- ")
                                   (skip-chars-forward "- ")
                                   (point)))
            (end (save-excursion (goto-char (point-max))
                                 (search-backward "- ")
                                 (end-of-line)
                                 (skip-chars-backward " \t")
                                 (point))))
        (add-text-properties start end '(face rabbit-hole-current-task-face))))))

(defun rabbit-hole--update-buffer ()
  "Refresh the contents of the rabbit-hole buffer."
  (let ((rabbit-hole-text nil))
    (save-excursion
      (with-no-warnings (set-buffer (find-file-noselect rabbit-hole-file)))
      (save-restriction
        (rabbit-hole--narrow-to-subtree)
        (end-of-line)
        (let ((start (point)))
          (goto-char (point-max))
          (setq rabbit-hole-text (string-trim (buffer-substring start (point)))))))
    (with-current-buffer (get-buffer-create "*rabbit-hole*")
      (unless (equal mode-name rabbit-hole-mode-name)
        (rabbit-hole-mode))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert rabbit-hole-text)
        (rabbit-hole--fontify-last-item))
      (goto-char (point-max)))))

(defun rabbit-hole--get-tree ()
  "Return the text of the current rabbit-hole tree."
  (let ((rabbit-hole-text nil))
    (save-excursion
      (with-no-warnings (set-buffer (find-file-noselect rabbit-hole-file)))
      (save-restriction
        (rabbit-hole--narrow-to-subtree)
        (end-of-line)
        (let ((start (point)))
          (goto-char (point-max))
          (string-trim (buffer-substring start (point))))))))

(defun rabbit-hole--display-message-p ()
  "Return non-nil if message should be displayed of task tree."
  (and rabbit-hole-message-on-action
       (not (equal (buffer-name) "*rabbit-hole*"))))

(defun rabbit-hole-go-deeper (item)
  "Add ITEM as a new task for a deeper context."
  (interactive "sName of new excursion:")
  (save-excursion
    (with-no-warnings (set-buffer (find-file-noselect rabbit-hole-file)))
    (save-restriction
      (rabbit-hole--narrow-to-subtree)
      (goto-char (point-max))
      (let ((found-item-p (search-backward "- " nil t)))
        (if found-item-p
            (let ((at-col (current-column)))
              (when (= 1 at-col)
                (setq at-col 0))
              (end-of-line)
              (insert "\n"
                      (make-string (+ at-col rabbit-hole-indentation) ?\s)
                      "- "
                      item))
          (insert "\n - " item)
          (indent-according-to-mode)))))
  (rabbit-hole--update-buffer)
  (when (rabbit-hole--display-message-p)
        (message "%s" (rabbit-hole--get-tree))))

(defun rabbit-hole-continue (item)
  "Add ITEM task on the same level as the topmost item."
  (interactive "sName of next task:")
  (save-excursion
    (with-no-warnings (set-buffer (find-file-noselect rabbit-hole-file)))
    (save-restriction
      (rabbit-hole--narrow-to-subtree)
      (goto-char (point-max))
      (let ((found-item-p (search-backward "- " nil t)))
        (if found-item-p
            (let ((at-col (current-column)))
              (when (= 1 at-col)
                (setq at-col 0))
              (end-of-line)
              (insert "\n"
                      (make-string at-col ?\s)
                      "- "
                      item))
          (insert "\n - " item)
          (indent-according-to-mode)))))
  (rabbit-hole--update-buffer)
  (when (rabbit-hole--display-message-p)
    (message "%s" (rabbit-hole--get-tree))))

(defun rabbit-hole-pop ()
  "Remove the topmost context item in the rabbit-tree."
  (interactive)
  (save-excursion
    (with-no-warnings (set-buffer (find-file-noselect rabbit-hole-file)))
    (save-restriction
      (rabbit-hole--narrow-to-subtree)
      (goto-char (point-max))
      (let ((found-item-p (search-backward "- " nil t)))
        (unless found-item-p
          (error "No more items to pop.")))
      (let ((item (save-excursion
                    (skip-chars-forward "- ")
                    (buffer-substring (point) (line-end-position)))))
        (delete-region (1- (line-beginning-position)) (line-end-position))
        (message "Popped off %s" item))
      (rabbit-hole--update-buffer))))

(defun rabbit-hole ()
  "Display rabbit hole buffer."
  (interactive)
  (rabbit-hole--update-buffer)
  (switch-to-buffer "*rabbit-hole*"))

(defconst rabbit-hole-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (define-key map (kbd ">") #'rabbit-hole-go-deeper)
      (define-key map (kbd ".") #'rabbit-hole-continue)
      (define-key map (kbd "<") #'rabbit-hole-pop))))

(define-derived-mode rabbit-hole-mode
  special-mode rabbit-hole-mode-name
  "Major mode for interacting with rabbit-hole buffer.")

(provide 'rabbit-hole)

;;; rabbit-hole.el ends here
