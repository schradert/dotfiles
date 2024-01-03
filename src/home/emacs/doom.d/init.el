;;; package --- Summary
;;;
;;; Commentary:
;;; This file controls what Doom modules are enabled and what order they load
;;; in. Remember to run 'doom sync' after modifying it!
;;;
;;; NOTE Press 'SPC h d h' (or 'C-h d h' for non-vim users) to access Doom's
;;;      documentation. There you'll find a "Module Index" link where you'll find
;;;      a comprehensive list of Doom's modules and what flags they support.
;;; NOTE Move your cursor over a module's name (or its flags) and press 'K' (or
;;;      'C-c c k' for non-vim users) to view its documentation. This works on
;;;      flags as well (those symbols that start with a plus).
;;;
;;;      Alternatively, press 'gd' (or 'C-c c d') on a module to browse its
;;;      directory (for easy access to its source code).
;;;
;;; Code:

(doom! :input
       ;;chinese
       ;;japanese
       ;;layout            ; auie,ctsrnm is the superior home row

       :completion
       (company +tng)
       (vertico +icons)

       :ui
       doom
       doom-dashboard
       doom-quit
       (emoji +ascii +github +unicode)
       hl-todo
       ligatures
       minimap
       modeline
       nav-flash
       neotree
       ophints
       (popup +defaults)
       ;; tabs
       (treemacs +lsp)
       unicode
       (vc-gutter +pretty)
       vi-tilde-fringe
       (window-select +numbers)
       workspaces
       zen

       :editor
       (evil +everywhere)
       file-templates
       fold
       multiple-cursors
       ;; parinfer
       snippets
       word-wrap

       :emacs
       (dired +icons +ranger)
       electric
       ibuffer
       (undo +tree)
       vc

       :term
       vterm

       :checkers
       (syntax +childframe)
       ;; TODO figure out why flyspell-lazy is freaking out
       ;; (spell +flyspell)
       spell
       grammar

       :tools
       (debugger +lsp)
       direnv
       (docker +lsp)
       editorconfig
       (eval +overlay)
       (lookup +dictionary +docsets +offline)
       lsp
       (magit +forge)
       pdf
       tmux
       tree-sitter
       upload

       :os
       (:if IS-MAC macos)
       (tty +osc)

       :lang
       data
       emacs-lisp
       (gdscript +lsp)
       (go +lsp)
       (haskell +lsp)
       (java +meghanada)
       (javascript +lsp)
       (json +lsp)
       (kotlin +lsp)
       (latex +lsp)
       (markdown +grip)
       (nix +tree-sitter)
       (org +brain +dragndrop +pandoc +pomodoro +present +pretty +roam2)
       ;;plantuml
       (python +lsp +pyright +tree-sitter)
       (rust +lsp +tree-sitter)
       (sh +lsp +tree-sitter)
       ;;solidity
       (swift +lsp)
       (web +lsp)
       (yaml +lsp +tree-sitter)

       :email
       ;; (mu4e +org +gmail)

       :app
       ;; calendar
       ;; emms
       everywhere
       ;; (rss +org)

       :config
       literate
       (default +bindings +smartparens))
