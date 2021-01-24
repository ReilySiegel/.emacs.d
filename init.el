;;; init.el --- Init File -*- lexical-binding: t; byte-compile-warnings: nil; eval: (outline-hide-body)-*-

;;; Commentary:
;; Nothing to see here...
;;; Code:
;; This section makes the linter happy.
;;; Disable GC during startup
(setq gc-cons-threshold (* 50 1000 1000))

;;; Networking
(require 'gnutls)
(with-eval-after-load 'gnutls

  ;; Do not allow insecure TLS connections.
  (setq gnutls-verify-error t)

  ;; Bump the required security level for TLS to an acceptably modern
  ;; value.
  (setq gnutls-min-prime-bits 3072))

;;; Packaging
;;;; straight.el
;; Use watchexec to check for package modifications if available, as
;; it is faster at startup.

;; Bootstrap the package manager, straight.el.
(defvar bootstrap-version)
(eval-and-compile
  (let ((bootstrap-file
         (expand-file-name "straight/repos/straight.el/bootstrap.el"
                           user-emacs-directory))
        (bootstrap-version 5))
    (unless (file-exists-p bootstrap-file)
      (with-current-buffer
          (url-retrieve-synchronously
           "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
           'silent 'inhibit-cookies)
        (goto-char (point-max))
        (eval-print-last-sexp)))
    (load bootstrap-file nil 'nomessage)))

(require 'straight)

(if (and (executable-find "watchexec")
         (executable-find "python3"))
    (setq straight-check-for-modifications '(watch-files find-when-checking))
  (setq straight-check-for-modifications '(find-at-startup find-when-checking)))

;; Use a custom Emacsmirror mirror, which improves initial clone time.
(setq straight-recipes-emacsmirror-use-mirror t)

;; Clear out recipe overrides (in case of re-init).
(setq straight-recipe-overrides nil)

;;;; use-package
(eval-and-compile (straight-use-package 'use-package))

(require 'use-package)

;; When configuring a feature with `use-package', also tell
;; straight.el to install a package of the same name, unless otherwise
;; specified using the `:straight' keyword.
(setq straight-use-package-by-default t)

;; Tell `use-package' to always load features lazily unless told
;; otherwise. It's nicer to have this kind of thing be deterministic:
;; if `:demand' is present, the loading is eager; otherwise, the
;; loading is lazy. See
;; https://github.com/jwiegley/use-package#notes-about-lazy-loading.
(setq use-package-always-defer t)

(defmacro use-feature (name &rest args)
  "Like `use-package', but with `straight-use-package-by-default' disabled.
Passes NAME and ARGS to use-package."
  (declare (indent defun))
  `(use-package ,name
     :straight nil
     ,@args))

;;; Configure ~/.emacs.d paths
;; Package `no-littering' changes the default paths for lots of
;; different packages, with the net result that the ~/.emacs.d folder
;; is much more clean and organized.
(use-package no-littering
  :demand t
  :config
  (setq custom-file (no-littering-expand-etc-file-name "custom.el"))
  (load custom-file))

;;; Prevent Emacs-provided Org from being loaded
;; Our real configuration for Org comes much later. Doing this now
;; means that if any packages that are installed in the meantime
;; depend on Org, they will not accidentally cause the Emacs-provided
;; (outdated and duplicated) version of Org to be loaded before the
;; real one is registered.
(straight-use-package 'org)


;;; Graphical defaults
(setq inhibit-startup-screen t)

(when (display-graphic-p)
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (winner-mode 1)
  (show-paren-mode 1))

;;; Theme
;;;; Font
(use-package ligature
  :demand t
  :straight (:host github :repo "mickeynp/ligature.el" :files (:defaults "*")
                   :no-byte-compile t)
  :config
  (set-frame-font "Fira Code-11")
  (setq-default fill-column 80)
  ;; Enable the www ligature in every possible major mode
  (ligature-set-ligatures 't '("www"))

  ;; Enable ligatures in programming modes                                                           
  (ligature-set-ligatures 'prog-mode '("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\" "{-" "::"
                                       ":::" ":=" "!!" "!=" "!==" "-}" "----" "-->" "->" "->>"
                                       "-<" "-<<" "-~" "#{" "#[" "##" "###" "####" "#(" "#?" "#_"
                                       "#_(" ".-" ".=" ".." "..<" "..." "?=" "??" ";;" "/*" "/**"
                                       "/=" "/==" "/>" "//" "///" "&&" "||" "||=" "|=" "|>" "^=" "$>"
                                       "++" "+++" "+>" "=:=" "==" "===" "==>" "=>" "=>>" "<="
                                       "=<<" "=/=" ">-" ">=" ">=>" ">>" ">>-" ">>=" ">>>" "<*"
                                       "<*>" "<|" "<|>" "<$" "<$>" "<!--" "<-" "<--" "<->" "<+"
                                       "<+>" "<=" "<==" "<=>" "<=<" "<>" "<<" "<<-" "<<=" "<<<"
                                       "<~" "<~~" "</" "</>" "~@" "~-" "~>" "~~" "~~>" "%%"))
  ;; Add hex ligatures
  (add-to-list 'ligature-composition-table `(t ("0" . ,(rx "x" (+ (or hex-digit hex))))))
  
  (global-ligature-mode 't))
;;;; Color theme
(use-package doom-themes
  :demand t
  :disabled t
  :config
  (setq doom-one-padded-modeline t
	doom-one-brighter-modeline nil)
  (if (daemonp)
      (add-hook 'after-make-frame-functions
		(lambda (frame)
		  (select-frame frame)
		  (load-theme 'doom-one t)))
    (load-theme 'doom-one t)))

(use-package nord-theme
  :demand t
  :config
  (if (daemonp)
      (add-hook 'after-make-frame-functions
		(lambda (frame)
		  (select-frame frame)
		  (load-theme 'nord t)))
    (load-theme 'nord t)))
;;;; Modeline
(use-package doom-modeline
  :demand t
  :hook ((after-init . doom-modeline-mode)
         (after-init . display-time-mode))
  :config
  (line-number-mode 0)
  :custom
  (display-time-24hr-format t)
  (display-time-interval 5)
  (display-time-update)
  (display-time-default-load-average nil)
  (doom-modeline-buffer-file-name-style 'truncate-with-project)
  (doom-modeline-enable-word-count t)
  (doom-modeline-mu4e t)
  (doom-modeline-percent-position nil)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-major-mode-icon nil)
  (doom-modeline-buffer-modification-icon nil)
  (doom-modeline-buffer-state-icon nil))

;;;; Posframe
(use-package ivy-posframe
  :after ivy
  :hook (after-init . ivy-posframe-mode)
  :straight ivy-posframe
  :custom-face
  (ivy-posframe-border ((t (:inherit ivy-posframe))))
  :config
  (setq ivy-posframe-display-functions-alist '((t . ivy-posframe-display-at-frame-center))
        ivy-posframe-height-alist '((t . 20))
        ivy-posframe-parameters '((internal-border-width . 10)
                                  (parent-frame . nil)))
  (setq ivy-posframe-width 90))
;;; System
;;;; exwm-randr
(use-feature exwm-randr
  :custom
  (exwm-randr-workspace-output-plist '(1 "eDP-1"))
  :config
  (add-hook 'exwm-randr-screen-change-hook
            (lambda ()
              (start-process-shell-command
               "xrandr" nil "xrandr --output eDP-1 --right-of HDMI-1 --auto")))
  (exwm-randr-enable))
;;;; exwm
(use-package exwm
  :demand t
  :config
  (require 'exwm-config)
  ;; Start a server for external processes to communicate with.
  (server-start)

  (setq exwm-workspace-number 1)
  ;; Make class name the buffer name
  (add-hook 'exwm-update-class-hook
	    (lambda ()
	      (exwm-workspace-rename-buffer exwm-class-name)))
  ;; 's-r': Reset
  (exwm-input-set-key (kbd "s-r") #'exwm-reset)
  ;; 's-w': Switch workspace
  (exwm-input-set-key (kbd "s-w") #'exwm-workspace-switch)
  ;; 's-N': Switch to certain workspace
  (dotimes (i 10)
    (exwm-input-set-key (kbd (format "s-%d" i))
			`(lambda ()
			   (interactive)
			   (exwm-workspace-switch-create ,i))))
  ;; 's-&': Launch application
  (exwm-input-set-key (kbd "s-&")
		      (lambda (command)
			(interactive (list (read-shell-command "$ ")))
			(start-process-shell-command command nil command)))
  (require 'exwm-systemtray)
  (exwm-systemtray-enable)
  ;; Line-editing shortcuts
  (setq
   exwm-manage-force-tiling t
   exwm-input-simulation-keys
   '(
     ;; movement
     ([?\C-b] . [left])
     ([?\M-b] . [C-left])
     ([?\C-f] . [right])
     ([?\M-f] . [C-right])
     ([?\C-p] . [up])
     ([?\C-n] . [down])
     ([?\C-a] . [home])
     ([?\C-e] . [end])
     ([?\M-v] . [prior])
     ([?\C-v] . [next])
     ([?\C-d] . [delete])
     ([?\C-k] . [S-end delete])
     ;; cut/paste.
     ([?\C-w] . [?\C-x])
     ([?\M-w] . [?\C-c])
     ([?\C-y] . [?\C-v])
     ;; search
     ([?\C-s] . [?\C-f])
     ;; save
     ([?\C-x?\C-s] . [?\C-s])
     ;; quit
     ([?\C-g] . [escape])))
  ;; Enable EXWM
  (exwm-enable))

;;;; Brightness
(defun message-brightness ()
  "Add a message to the mode line with the current brightness."
  (message "Brightness: %s%%"
           ;; Round to nearest 5.
           (* 5 (round
                 (/ (string-to-number
                     (shell-command-to-string "light"))
                    5)))))2

(exwm-input-set-key (kbd "<XF86MonBrightnessUp>")
                    (lambda ()
                      (interactive)
                      (shell-command-to-string "light -A 5")
                      (message-brightness)))

(exwm-input-set-key (kbd "<XF86MonBrightnessDown>")
                    (lambda ()
                      (interactive)
                      (shell-command-to-string "light -U 5")
                      (message-brightness)))

;;;; Volume
(defun message-volume ()
  "Add a message to the mode line with the current brightness."
  (message "Volume: %s%%"
           (round
            (string-to-number
             (shell-command-to-string "pamixer --get-volume")))))



(defun get-muted ()
  "Check if the volume is muted."
  (if (string= "true\n" (shell-command-to-string
                         "pamixer --get-mute"))
      "Muted"
    "Unmuted"))

(exwm-input-set-key (kbd "<XF86AudioRaiseVolume>")
                    (lambda ()
                      (interactive)
                      (shell-command-to-string "pamixer -ui 5")
                      (message-volume)))

(exwm-input-set-key (kbd "<XF86AudioLowerVolume>")
                    (lambda ()
                      (interactive)
                      (shell-command-to-string "pamixer -ud 5")
                      (message-volume)))

(exwm-input-set-key (kbd "<XF86AudioMute>")
                    (lambda ()
                      (interactive)
                      (shell-command-to-string "pamixer -t")
                      (message (get-muted))))


;;;; Battery
(use-feature battery
  :after doom-modeline
  :demand t
  :config
  (display-battery-mode))

;;;; Pinentry
(use-package pinentry
  :demand t
  :config
  (pinentry-start))

(use-package exec-path-from-shell
  :demand t
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "SSH_AGENT_PID")
  (exec-path-from-shell-copy-env "SSH_AUTH_SOCK")
  (exec-path-from-shell-setenv "EDITOR" "emacsclient")
  (exec-path-from-shell-setenv "VISUAL" "emacsclient")
  (exec-path-from-shell-setenv "SYSTEMD_EDITOR" "emacsclient"))
;;; Candidate selection
;;;; Ivy/Counsel
(use-package ivy
  :demand t
  :config
  (ivy-mode 1)
  :custom
  (ivy-use-virtual-buffers t)
  (enable-recursive-minibuffers t)
  (ivy-re-builders-alist '((t . ivy--regex-ignore-order))))

(use-package counsel
  :demand t
  :bind ("C-s" . 'swiper)
  :config
  (counsel-mode 1)
  (exwm-input-set-key (kbd "s-SPC") 'counsel-linux-app))

(use-package prescient
  :demand t
  :config
  (prescient-persist-mode 1))

(use-package ivy-rich
  :after ivy
  :preface
  (defun ivy-rich-linux-command-name (candidate)
    (if (string-match ": \\([^-]*\\)\\(-.*$\\|$\\)" candidate)
        (string-trim (substring-no-properties candidate
                                              (match-beginning 1)
                                              (match-end 1)))
      ""))
  (defun ivy-rich-linux-command-desc (candidate)
    (if (string-match ":[^-]*-\\(.*\\)$" candidate)
        (string-trim (substring-no-properties candidate
                                              (match-beginning 1)
                                              (match-end 1)))
      ""))
  :init
  ;; Total widths of columns must be <= ivy-posframe-width, which is 75.
  (setq ivy-rich-display-transformers-list
        '(ivy-switch-buffer
          (:columns
           ((ivy-rich-candidate (:width 35))
            (ivy-rich-switch-buffer-major-mode (:width 15 :face warning))
            (ivy-rich-switch-buffer-project (:width 15 :face success))
            ;; (ivy-rich-switch-buffer-path
            ;;  (:width (lambda (x)
            ;;            (ivy-rich-switch-buffer-shorten-path
            ;;             x
            ;;             (ivy-rich-minibuffer-width 1)))))
            )
           :predicate
           (lambda (cand) (get-buffer cand)))
          counsel-M-x
          (:columns
           ((counsel-M-x-transformer (:width 35))
            (ivy-rich-counsel-function-docstring (:width 39
                                                         :face font-lock-doc-face))))
          counsel-describe-function
          (:columns
           ((counsel-describe-function-transformer (:width 35))
            (ivy-rich-counsel-function-docstring (:width 39
                                                         :face font-lock-doc-face))))
          counsel-describe-variable
          (:columns
           ((counsel-describe-variable-transformer (:width 35))
            (ivy-rich-counsel-variable-docstring (:width 39
                                                         :face font-lock-doc-face))))
          counsel-recentf
          (:columns
           ((ivy-rich-candidate (:width 0.8))
            (ivy-rich-file-last-modified-time (:face font-lock-comment-face))))

          counsel-linux-app
          (:columns
           ((ivy-rich-linux-command-name (:width 30))
            (ivy-rich-linux-command-desc (:width 44
                                                 :face font-lock-doc-face))))))
  (ivy-rich-mode 1)
  (setcdr (assq t ivy-format-functions-alist) #'ivy-format-function-line))

;; Package `ivy-prescient' provides intelligent sorting and filtering
;; for candidates in Ivy menus.
(use-package ivy-prescient
  :demand t
  :after ivy
  :config
  (setq ivy-prescient-sort-commands  '(:not swiper ivy-switch-buffer counsel-yank-pop))
  ;; Use `prescient' for Ivy menus.
  (ivy-prescient-mode 1))
;;;; Avy
(use-package avy
  :bind ("C-'" . avy-goto-char))
;;; Saving files
;; Don't make backup files.
(setq make-backup-files nil)

;; Don't make autosave files.
(setq auto-save-default nil)

;; Don't make lockfiles.
(setq create-lockfiles nil)
;;; Editing
;;;; Text Formatting
;;;;; Auto Fill
;; When filling paragraphs, assume that sentences end with one space
;; rather than two.
(setq sentence-end-double-space nil)

;; Trigger auto-fill after punctutation characters, not just
;; whitespace.
(mapc
 (lambda (c)
   (set-char-table-range auto-fill-chars c t))
 "!-=+]};:'\",.?")

;; Enable auto-fill-mode in text-mode.
(add-hook 'text-mode-hook #'auto-fill-mode)
;;;; Undo/redo
(use-package undo-tree
  :demand t
  :disabled t
  :bind (;; By default, `undo' (and by extension `undo-tree-undo') is
         ;; bound to C-_ and C-/, and `undo-tree-redo' is bound to
         ;; M-_. It's logical to also bind M-/ to `undo-tree-redo'.
	 ;; This overrides the default binding of M-/, which is to
         ;; `dabbrev-expand'.
         :map undo-tree-map
	 ("M-/" . undo-tree-redo))
  :config
  (global-undo-tree-mode 1))

;;;; Inter-program Killing
(setq save-interprogram-paste-before-kill t)
;;; IDE Features
;;;; Autocomplete
(defvar company-mode/enable-yas t
  "Enable yasnippet for all backends.")

(defun company-mode/backend-with-yas (backend)
  "Enables yasnippets for all company BACKENDs."
  (if (or (not company-mode/enable-yas)
          (and (listp backend)
               (member 'company-yasnippet backend)))
      backend
    (append (if (consp backend) backend (list backend))
            '(:with company-yasnippet))))

(use-package company
  :demand t
  :custom
  (company-idle-delay t)
  :config
  (global-company-mode)
  ;; Add yasnippet support for all company backends
  ;; https://github.com/syl20bnr/spacemacs/pull/179
  (setq company-backends (mapcar #'company-mode/backend-with-yas company-backends)))

;;;; Auto commit
(use-package git-auto-commit-mode)
;;;; Folding
(use-package outshine
  :hook (prog-mode . outshine-mode))
;;;; Indentation
;; Don't use tabs for indentation. Use only spaces. Frankly, the fact
;; that `indent-tabs-mode' is even *available* as an *option* disgusts
;; me, much less the fact that it's *enabled* by default (meaning that
;; *both* tabs and spaces are used at the same time).
(setq-default indent-tabs-mode nil)

(use-package aggressive-indent
  :demand t
  :config
  (global-aggressive-indent-mode))

;;;; Linting
(use-package flycheck
  :hook (after-init . global-flycheck-mode)
  :config
  ;; Enable proselint for emails.
  (flycheck-add-mode 'proselint 'mu4e-compose-mode))
;;;; LSP
(use-package lsp-mode
  :commands lsp
  :custom
  (lsp-ui-doc-enable nil)
  (lsp-ui-sideline-enable nil)
  (lsp-prefer-flymake nil))

(use-package lsp-ui
  :after lsp
  :config
  (lsp-ui-flycheck-enable t))
;;;; DAP
(use-package dap-mode
  :after lsp-mode
  :config
  (dap-mode 1))
;;;; Magit
(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch)))

(use-package forge
  :after magit
  :demand t
  :config
  (setq forge-owned-accounts
        '(("ReilySiegel" . nil))))
;;;; Paredit
(use-package paredit
  :hook (prog-mode . enable-paredit-mode))
;;;; Yasnippet
(use-package yasnippet
  :hook (after-init . yas-global-mode))
;;; Language Support
;;;; Clojure
(use-package clojure-mode
  :custom
  (clojure-align-forms-automatically t)
  (clojure-toplevel-inside-comment-form t))

(use-package cider
  :hook (cider-mode . eldoc-mode)
  :demand t
  :custom
  (cider-font-lock-dynamically '(macro core function var))
  (cider-clojure-cli-global-options "-A:dev")
  :config
  (setq cider-scratch-initial-message
        "(ns user\n  (:require [reilysiegel.scratch :refer :all]))\n\n"
        cider-repl-pop-to-buffer-on-connect nil)
  ;; Put *cider-scratch* buffers in a Clojure project, so that I get middleware.
  (advice-add 'cider-scratch :after (lambda () (cd "~/.clojure/scratch/"))))

(use-package clj-refactor
  :init
  (setq cljr-warn-on-eval t)
  :config
  (cljr-add-keybindings-with-prefix "C-c C-r")
  (add-hook 'clojure-mode-hook #'clj-refactor-mode))

(use-package flycheck-clj-kondo
  :after flycheck
  :demand t)

;;;; Gnuplot
(use-package gnuplot)
;;;; Java
(use-package lsp-java
  :demand t
  :hook (java-mode . lsp)
  :config
  (require 'dap-java))
;;;; Prose
(use-package flyspell
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode)))
;;;; Racket
(use-package racket-mode)
;;;; Scheme
(use-package geiser
  :custom
  (geiser-default-implementation 'racket))
;;;; Yaml
(use-package yaml-mode)
;;; Eshell
(use-feature eshell
  :bind ("C-c s" . eshell)
  :demand t
  :config
  (require 'esh-module)
  (add-to-list 'eshell-modules-list 'eshell-tramp)
  (setq eshell-destroy-buffer-when-process-dies t
        eshell-history-size 1024
        remote-file-name-inhibit-cache nil
        vc-ignore-dir-regexp
        (format "%s\\|%s" vc-ignore-dir-regexp tramp-file-name-regexp)
        eshell-visual-commands '("htop" "nmtui" "vim" "watch"))
;;; Mu4e
  (use-package mu4e
    :load-path "/usr/local/share/emacs/site-lisp/mu/mu4e"
    :straight nil
    :demand t
    :bind
    ("C-c m" . mu4e)
    :preface
    (defun reily/sign-message ()
      (when (y-or-n-p "Sign message? ")
        (mml-secure-message-sign-pgpmime)))

    (defun reily/capture-message (msg)
      (call-interactively 'org-store-link)
      (org-capture t "e"))
    :config
    (add-hook 'message-send-hook 'reily/sign-message)
    (setq
     mu4e-update-interval 30
     mu4e-hide-index-messages t
     message-send-mail-function 'smtpmail-send-it
     starttls-use-gnutls t
     smtpmail-smtp-service 587
     mu4e-compose-format-flowed t
     message-kill-buffer-on-exit t
     mu4e-headers-actions
     '(("capture message" . reily/capture-message))
     mu4e-view-actions
     '(("capture message" . reily/capture-message)
       ("view in browser" . mu4e-action-view-in-browser))
     mu4e-contexts
     `( ,(make-mu4e-context
          :name "Personal"
          :match-func
          (lambda (msg)
            (when msg
              (string-prefix-p "/Personal" (mu4e-message-field msg :maildir))))
          :vars '((mu4e-trash-folder . "/Personal/Trash")
                  (mu4e-sent-folder . "/Personal/Sent")
                  (mu4e-drafts-folder . "/Personal/Drafts")
                  (smtpmail-default-smtp-server . "smtp.zoho.com")
                  (smtpmail-smtp-server . "smtp.zoho.com")
                  (user-mail-address . "mail@reilysiegel.com")
                  (user-full-name . "Reily Siegel")))
        ,(make-mu4e-context
          :name "WPI"
          :match-func
          (lambda (msg)
            (when msg
              (string-prefix-p "/WPI" (mu4e-message-field msg :maildir))))
          :vars '((mu4e-trash-folder . "/WPI/Trash")
                  (mu4e-sent-folder . "/WPI/Sent")
                  (mu4e-drafts-folder . "/WPI/Drafts")
                  (smtpmail-default-smtp-server . "smtp.office365.com")
                  (smtpmail-smtp-server . "smtp.office365.com")
                  (user-mail-address . "rsiegel@wpi.edu")
                  (user-full-name . "Reily Siegel"))))
     mu4e-bookmarks
     '((:name  "Unread messages"
               :query
               "flag:unread AND NOT flag:trashed"
               :key ?u)
       (:name "Personal Inbox"
              :query "maildir:\"/Personal/INBOX\""
              :key ?p)
       (:name "WPI Inbox"
              :query "maildir:\"/WPI/INBOX\""
              :key ?w)
       (:name  "Sent messages"
               :query "from:mail@reilysiegel.com OR from:rsiegel@wpi.edu"
               :key ?s
               :hide t)))))

(use-package mu4e-alert
  :demand t
  :after doom-modeline
  :hook (after-init . mu4e-alert-enable-mode-line-display)
  :custom
  (mu4e-alert-interesting-mail-query
   "flag:unread and not flag:trashed"))

(use-feature org-mu4e
  :after mu4e
  :config
  (setq org-mu4e-link-query-in-headers-mode nil))
;;; Pass
(use-package transient-pass
  :straight (:host github :repo "ReilySiegel/transient-pass" :branch "master")
  :demand t
  :bind ("C-c p" . transient-pass)
  :config
  (setq password-store-password-length 16))
;;; Org Mode
;; Uses use-feature, because org has already been loaded in a previous section.
(use-feature org
  :hook ((org-clock-in . save-buffer)
         (org-clock-out . save-buffer))
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((plantuml . t)
     (scheme . t)
     (gnuplot . t)
     (java . t)
     (python . t)
     (clojure . t)
     (R . t)))

  (setq org-file-apps
        (butlast org-file-apps))
  
  (setq org-directory "~/Dropbox/org"
        org-plantuml-jar-path
        "/usr/share/java/plantuml/plantuml.jar"
        ;; org-latex-pdf-process
        ;; '("xelatex -interaction nonstopmode %f"
        ;;   "xelatex -interaction nonstopmode %f")
        )
  ;; Set (no) indentation
  (setq org-adapt-indentation nil)
  ;; Log time a task was set to Done.
  (setq org-log-done (quote time))

  ;; Don't log the time a task was rescheduled or redeadlined.
  (setq org-log-redeadline nil)
  (setq org-log-reschedule nil)
  ;; Refresh org-agenda after rescheduling a task.
  (defun org-agenda-refresh ()
    "Refresh all `org-agenda' buffers."
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (derived-mode-p 'org-agenda-mode)
          (org-agenda-maybe-redo)))))

  (defadvice org-schedule (after refresh-agenda activate)
    "Refresh org-agenda."
    (org-agenda-refresh)))

;;;; Org agenda
(use-feature org-agenda
  :after org
  :preface
  (defun org-agenda-show-agenda-and-todo (&optional arg)
    (interactive "P")
    (org-agenda arg "n"))
  :bind
  (("C-c a" . org-agenda-show-agenda-and-todo)
   ("C-c o" . org-capture))
  :config
  (setq
   org-agenda-window-setup 'current-window
   org-agenda-files '("~/Dropbox/org/" "~/WPI/2020/")
   org-agenda-span 'week
   org-enforce-todo-dependencies t
   org-log-done (quote time)
   org-log-schedule (quote time)
   org-log-redeadline (quote time)
   org-agenda-skip-scheduled-if-done t
   org-agenda-skip-deadline-if-done t
   org-agenda-skip-deadline-prewarning-if-scheduled (quote pre-scheduled)
   org-agenda-todo-ignore-deadlines (quote all)
   org-agenda-todo-ignore-scheduled (quote all))
  (setq
   org-capture-templates
   `(("t" "Task" entry
      (file+headline "organizer.org" "Tasks")
      "** TODO %?"
      :prepend t)
     ("e" "Email" entry
      (file+headline "organizer.org" "Tasks")
      "** %a %?"
      :prepend t)
     ("p" "Page" entry
      (file+headline "axp.org" "Book")
      ,(string-join '("** %^{Scroll Number} - %^{Name}"
                      ":PROPERTIES:"
                      ":CUSTOM_ID: %\\1"
                      ":END:"
                      "| Big Brother | [[#%^{Big's Scroll Number}][%^{Big's Name}]] |"
                      "| Birthday | %^{Birthday}t |"
                      "| Phone Number | %^{Phone Number} |"
                      "| WPI Email | %^{WPI Email} |"
                      "| Email | %^{Email} |"
                      "| Local Address | %^{Local Address} |"
                      "| Home Address | %^{Home Address} |"
                      "| Major | %^{Major} |"
                      "| Minor | %^{Minor} |"
                      "| Concentration | %^{Concentration} |"
                      "| Year of Graduation | %^{Year of Graduation} |"
                      "| IQP | %^{IQP} |"
                      "| MQP | %^{MQP} |"
                      "| Humanities Project | %^{HUA Project} |"
                      "| Clubs and Organizations | %^{Clubs and Organizations} |"
                      "| House Positions | %^{Positions} |"
                      "| Nicknames | %^{Nicknames} %?|")
                    "\n")))
   org-refile-targets `((nil . (:level . 1))
                        (,(org-agenda-files) . (:maxlevel . 1)))))
;;;;; Org Super Agenda
(use-package org-super-agenda
  :after org-agenda
  :demand t
  :disabled t
  :config
  (setq org-super-agenda-groups
        '((:name "Today"
                 :time-grid t
                 :scheduled today
                 ;; Scheduled tasks will only be shown on day.
                 :scheduled future)
          (:name "Due today"
                 :deadline today)
          (:name "Important"
                 :priority "A")
          (:name "Overdue"
                 :deadline past)
          (:name "Due soon"
                 :deadline future)
          (:name "Other items"
                 :priority<= "B")))
  (org-super-agenda-mode))
;;;; Org habit
(use-feature org-habit
  :after org-agenda
  :config
  (add-to-list 'org-modules 'org-habit))
;;;; Org ox-latex
(use-feature ox-latex
  :config
  (add-to-list 'org-latex-classes
               '("paper" "\\documentclass[12pt]{report} \\PassOptionsToPackage{hyphens}{url} \n [DEFAULT-PACKAGES] [PACKAGES] [EXTRA] \n \\usepackage{setspace} \\doublespacing \\usepackage{fontspec} \\setmainfont{Times Newer Roman} \\usepackage[margin=1.25in]{geometry}"
                 ("\\part{%s}" . "\\part*{%s}")
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))
  (add-to-list 'org-latex-classes
               '("per-file-class"
                 "\\documentclass{moderncv}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  (setq org-src-fontify-natively t
        org-latex-listings 'minted)
  (add-to-list 'org-latex-packages-alist '("" "minted"))
  :custom
  (org-format-latex-options '(:foreground default
                                          :background default
                                          :scale 2.5
                                          :html-foreground "Black"
                                          :html-background "Transparent"
                                          :html-scale 1.0 :matchers
                                          ("begin" "$1" "$" "$$" "\\(" "\\["))))
;;;; Org recur
(use-package org-recur
  :after org-agenda
  :disabled t
  :hook ((org-mode . org-recur-mode)
         (org-agenda-mode . org-recur-agenda-mode))
  :config
  (define-key org-recur-mode-map (kbd "C-c d") 'org-recur-finish)

  ;; Rebind the 'd' key in org-agenda (default: `org-agenda-day-view').
  (define-key org-recur-agenda-mode-map (kbd "d") 'org-recur-finish)
  (define-key org-recur-agenda-mode-map (kbd "C-c d") 'org-recur-finish)

  (setq org-recur-finish-done t
        org-recur-finish-archive t))
;;;; Org Latex
(use-package calctex
  :disabled t
  :straight (:host github :repo "johnbcoughlin/calctex" :branch "master"))

;; Auto toggle latex fragments
(use-package org-fragtog
  :hook ((org-mode . org-fragtog-mode)))
;; Use CDLaTeX for common shortcuts
(use-package cdlatex
  :hook (org-mode . turn-on-org-cdlatex))
;;; Reading
;;;; PDF
(use-package pdf-tools
  :hook (after-init . pdf-loader-install))
;;; AUCtex
(use-package auctex)
;;; QREncode
(defun qr-code-region (start end)
  "Show a QR code of the region."
  (interactive "r")
  (let ((buf (get-buffer-create "*QR*"))
	(inhibit-read-only t)
        (display-buffer-base-action)
        (display-buffer-overriding-action '(display-buffer-same-window)))
    (with-current-buffer buf
      (erase-buffer))
    (let ((coding-system-for-read 'raw-text))
      (shell-command-on-region start end "qrencode -o -" buf))
    (switch-to-buffer buf)
    (image-mode)
    (if (> (window-width) (window-height))
        (image-transform-fit-to-height)
      (image-transform-fit-to-width))))
;;; Calc
(use-feature calc
  :bind ("C-c c" . calc))
;;; Feature discovery
(use-package which-key
  :config
  (which-key-mode 1))

(use-package discover-my-major
  :bind ("C-h C-m" . discover-my-major))
;;; Miscelenious
;;;; y-or-n-p
;; Replace `yes-or-no-p' with `y-or-n-p`, as I cannot be bothered to
;; type 2 or 3 characters.
(defalias 'yes-or-no-p 'y-or-n-p)
;;; Reset GC
(setq gc-cons-threshold (* 2 1000 1000))
;;; init.el ends here
