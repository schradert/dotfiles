(setq user-full-name "Tristan Schrader"
      user-mail-address "tristanschrader@proton.me")
(map! "C-M-i" #'completion-at-point)
(setq delete-by-moving-to-trash t
      trash-directory "~/.Trash")
(setq doom-theme 'doom-dracula)
;; (setq doom-font (font-spec :family "Fira Code" :size 14 :weight 'medium))

(after! org
  (setq org-directory '("~/Code/Personal/dev/knowledge/sabedoria"))
  (setq org-agenda-files '("~/Code/Personal/dev/knowledge/sabedoria/agenda"))
  (setq org-log-done 'note)
  (setq org-todo-keywords '((sequence "DRAFTED(d)" "PLANNED(p)" "IN PROGRESS(i)" "ON HOLD(h)" "|" "COMPLETED(c)" "ABANDONED(a)"))))

;; (setq org-agenda-custom-commands
;;       '(("v" "A better agenda view"
;;          ((tags "PRIORITY=\"A\""
;;                 ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
;;                  (org-agenda-overriding-header "High-priority unfinished tasks:")))
;;           (tags "PRIORITY=\"B\""
;;                 ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
;;                  (org-agenda-overriding-header "Medium-priority unfinished tasks:")))
;;           (tags "PRIORITY=\"C\""
;;                 ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
;;                  (org-agenda-overriding-header "Low-priority unfinished tasks:")))))))

(setq org-roam-capture-templates
  '(("d" "default" plain
     "%?"
     :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
     :unarrowed t)
    ("l" "programming language" plain
     "* Characteristics:\n\n- Family: %?\n- Inspired by: \n\n* Reference:\n\n"
     :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
     :unnarrowed t)))

(after! vterm
    (define-key vterm-mode-map (kbd "C-c ESC") #'vterm-send-escape))

(map! :leader
      (:after dired
       (:map dired-mode-map
        :desc "Peep-dired image previews" "d p" #'peep-dired)))

(evil-define-key 'normal dired-mode-map
  (kbd "h") 'dired-up-directory
  (kbd "l") 'dired-view-file
  (kbd "x") 'dired-do-kill-lines)

(after! magit
  ;; Enable granular diff-highlights for all hunks
  (setq magit-diff-refine-hunk 'all)
  ;; Enable gravatars when viewing commits
  (setq magit-revision-show-gravatars '("^Author:     " . "^Commit:     ")))

(setq auth-sources '("~/.netrc"))

;; Show pretty symbols
(add-hook 'code-review-mode-hook #'emojify-mode)
;; Line wrap in comments
(setq code-review-fill-column 80)
;; Show *Code Review* in current workspace (Doom bug)
(add-hook 'code-review-mode-hook (lambda () (persp-add-buffer (current-buffer))))
;; Use same passwords used for forge
(setq code-review-auth-login-marker 'forge)
;; Jump into code review from a magit-forge PR view
(after! forge
    (define-key forge-topic-mode-map (kbd "rr") 'code-review-forge-pr-at-point))

(setq +tree-sitter-hl-enabled-modes t)

(custom-set-faces!
  '(aw-leading-char-face
    :foreground "white" :background "red"
    :weight bold :height 2.5 :box (:line-width 10 :color "red")))
