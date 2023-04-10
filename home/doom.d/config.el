(setq user-full-name "Tristan Schrader"
      user-mail-address "tristanschrader@proton.me")

(setq doom-theme 'doom-one)
(map! "C-M-i" #'completion-at-point)

(setq org-roam-capture-templates
  '(("d" "default" plain
     "%?"
     :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
     :unarrowed t)
    ("l" "programming language" plain
     "* Characteristics:\n\n- Family: %?\n- Inspired by: \n\n* Reference:\n\n"
     :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
     :unnarrowed t)))
