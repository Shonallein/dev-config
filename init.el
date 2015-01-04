(require 'cl)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;
;;;;;;;;;;  Packages ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'package)
(package-initialize)
(add-to-list 'package-archives
  '("melpa" . "http://melpa.milkbox.net/packages/") t)

(defvar shona/packages '(
			 auto-complete
			 cmake-mode
			 flx-ido
			 ggtags
			 glsl-mode
			 google-this
			 google-c-style
			 markdown-mode
			 molokai-theme
			 multiple-cursors
			 projectile
			 pt
			 undo-tree
			 yasnippet
			 zeal-at-point)
  "Default packages")

(defun shona/packages-installed-p ()
  (loop for pkg in shona/packages
        when (not (package-installed-p pkg)) do (return nil)
        finally (return t)))

(unless (shona/packages-installed-p)
  (message "%s" "Refreshing package database...")
  (package-refresh-contents)
  (dolist (pkg shona/packages)
    (when (not (package-installed-p pkg))
      (package-install pkg))))

;; Config files
;(load-file "~/.emacs/C++-custom.el")

;; Start server automatically
(require 'server)
(when (and (>= emacs-major-version 23)
           (equal window-system 'w32))
  (defun server-ensure-safe-dir (dir) "Noop" t)) ; Suppress error "directory
                                                 ; ~/.emacs.d/server is unsafe"
                                                 ; on windows.
(server-start)

;; disambiguate buffer names
(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

;; smart switch-buffer and find file
(require 'flx-ido)
(ido-mode 1)
(ido-everywhere 1)
(flx-ido-mode 1)
;; disable ido faces to see flx highlights.
(setq ido-use-faces nil)

;; smart text completion
(require 'auto-complete-config)
(ac-config-default)
(add-to-list 'ac-modes 'cmake)
(setq ac-auto-show-menu 0.3)
(setq ac-show-menu-immediately-on-auto-complete t)

;; projectile
(require 'projectile)
(projectile-global-mode)

;; Multiple cursors
(require 'multiple-cursors)

;; snippets!
(require 'yasnippet)
(yas-global-mode 1)

;; GGtags config
(add-hook 'c-mode-common-hook
		  (lambda ()
            (when (derived-mode-p 'c-mode 'c++-mode 'java-mode)
              (ggtags-mode 1))))

;; Google this. Google search intregrated in emacs
(require 'google-this)
(google-this-mode 1)

;; Zeal doc integration
(setq zeal-at-point-mode-alist nil)

;; Google c++ coding standards
(add-hook 'c-mode-common-hook 'google-set-c-style)
(add-hook 'c-mode-common-hook 'google-make-newline-indent)
(add-hook 'c++-mode-hook 'google-set-c-style)
(add-hook 'c++-mode-hook 'google-make-newline-indent)

;; Projectile config
(setq projectile-indexing-method 'alien)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; Language modes ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'cmake-mode)
(require 'glsl-mode)
(add-to-list 'auto-mode-alist '("\\.glsl\\'" . glsl-mode))
(add-to-list 'auto-mode-alist '("\\.vert\\'" . glsl-mode))
(add-to-list 'auto-mode-alist '("\\.frag\\'" . glsl-mode))
(add-to-list 'auto-mode-alist '("\\.geom\\'" . glsl-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; Keyboard ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Modern like key bindings and behaviour
(cua-mode t)
(transient-mark-mode 1) ;; No region when it is not highlighted
(setq shift-select-mode t)

;; Undo / redo remap
(require 'undo-tree)
(global-undo-tree-mode 1)
(defalias 'redo 'undo-tree-redo)
(define-key global-map (kbd "C-y") 'redo)

;; Define my own minor mode to be able to use my key bindings everywhere
(defvar my-keys-minor-mode-map (make-keymap) "my-keys-minor-mode keymap.")
(define-minor-mode my-keys-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  t " my-keys" 'my-keys-minor-mode-map)
(defun my-minibuffer-setup-hook ()
  (my-keys-minor-mode 0))
(add-hook 'minibuffer-setup-hook 'my-minibuffer-setup-hook)

;; duplicate current line
(defun duplicate-line-or-region (&optional n)
  "Duplicate current line, or region if active.
With argument N, make N copies.
With negative N, comment out original line and use the absolute value."
  (interactive "*p")
  (let ((use-region (use-region-p)))
    (save-excursion
      (let ((text (if use-region        ;Get region if active, otherwise line
                      (buffer-substring (region-beginning) (region-end))
                    (prog1 (thing-at-point 'line)
                      (end-of-line)
                      (if (< 0 (forward-line 1)) ;Go to beginning of next line, or make a new one
                          (newline))))))
        (dotimes (i (abs (or n 1)))     ;Insert N times, or once if not specified
          (insert text))))
    (if use-region nil                  ;Only if we're working with a line (not a region)
      (let ((pos (- (point) (line-beginning-position)))) ;Save column
        (if (> 0 n)                             ;Comment out original with negative arg
            (comment-region (line-beginning-position) (line-end-position)))
        (forward-line 1)
        (forward-char pos)))))

;; ErgoEmacs toggle case
(defun xah-toggle-letter-case ()
  "Toggle the letter case of current word or text selection.
Toggles between: “all lower”, “Init Caps”, “ALL CAPS”."
  (interactive)
  
  (let (p1 p2 (deactivate-mark nil) (case-fold-search nil))
    (if (use-region-p)
        (setq p1 (region-beginning) p2 (region-end))
      (let ((bds (bounds-of-thing-at-point 'word)))
        (setq p1 (car bds) p2 (cdr bds))))
	
    (when (not (eq last-command this-command))
      (save-excursion
        (goto-char p1)
        (cond
         ((looking-at "[[:lower:]][[:lower:]]") (put this-command 'state "all lower"))
         ((looking-at "[[:upper:]][[:upper:]]") (put this-command 'state "all caps"))
         ((looking-at "[[:upper:]][[:lower:]]") (put this-command 'state "init caps"))
         ((looking-at "[[:lower:]]") (put this-command 'state "all lower"))
         ((looking-at "[[:upper:]]") (put this-command 'state "all caps"))
         (t (put this-command 'state "all lower")))))

    (cond
     ((string= "all lower" (get this-command 'state))
      (upcase-initials-region p1 p2) (put this-command 'state "init caps"))
     ((string= "init caps" (get this-command 'state))
      (upcase-region p1 p2) (put this-command 'state "all caps"))
     ((string= "all caps" (get this-command 'state))
      (downcase-region p1 p2) (put this-command 'state "all lower")))))

;; Search
(define-key my-keys-minor-mode-map (kbd "C-f") 'isearch-forward)
(define-key my-keys-minor-mode-map (kbd "C-S-f") 'isearch-backward)
(define-key isearch-mode-map (kbd "C-f") 'isearch-repeat-forward)
(define-key isearch-mode-map (kbd "C-S-f") 'isearch-repeat-backward)
(define-key isearch-mode-map (kbd "C-v") 'isearch-yank-kill)
(define-key my-keys-minor-mode-map (kbd "<f8>") 'google-this)
(define-key my-keys-minor-mode-map (kbd "C-<f8>") 'zeal-at-point)

;; Buffer switch
(define-key my-keys-minor-mode-map (kbd "C-<tab>") 'next-buffer)
(define-key my-keys-minor-mode-map (kbd "C-S-<tab>") 'previous-buffer)

;; Save, close, open
(define-key my-keys-minor-mode-map (kbd "C-s") 'save-buffer)
(define-key my-keys-minor-mode-map (kbd "C-w") 'kill-this-buffer)
(define-key my-keys-minor-mode-map (kbd "C-o") 'find-file)
(define-key my-keys-minor-mode-map (kbd "C-S-o") 'dired-other-window)

;; Multi-line edit
(define-key my-keys-minor-mode-map (kbd "C-S-m") 'mc/edit-lines)
(define-key my-keys-minor-mode-map (kbd "C-M-m") 'mc/mark-all-like-this)
(define-key my-keys-minor-mode-map (kbd "C-r") 'query-replace)

;; Windows management
(define-key my-keys-minor-mode-map (kbd "M-é") 'split-window-horizontally)
(define-key my-keys-minor-mode-map (kbd "M-C-é") 'split-window-vertically)
(define-key my-keys-minor-mode-map (kbd "M-\"") 'delete-window)
(define-key my-keys-minor-mode-map (kbd "M-C-\"") 'delete-other-windows)
(define-key my-keys-minor-mode-map (kbd "M-q") 'other-window)

;; Projectile shortcuts
(define-key projectile-mode-map (kbd "C-M-o") 'projectile-find-file)
(define-key projectile-mode-map (kbd "C-M-a") 'projectile-pt)
(define-key projectile-mode-map (kbd "C-<f5>") 'projectile-compile-project)
(define-key projectile-mode-map (kbd "<f5>") 'compile)
(define-key projectile-mode-map (kbd "C-<f6>") 'projectile-find-other-file)
(define-key projectile-mode-map (kbd "<f6>") 'ff-find-other-file)
(define-key projectile-mode-map (kbd "C-<f7>") 'projectile-find-tag)

;; Misc
(define-key ac-mode-map (kbd "C-SPC") 'auto-complete)
(define-key my-keys-minor-mode-map (kbd "M-ù") 'xah-toggle-letter-case)
(define-key my-keys-minor-mode-map (kbd "C-d") 'duplicate-line-or-region)

(my-keys-minor-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; Display ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq inhibit-splash-screen t ;; Deactivate splashscreen and default scratch message
      initial-scratch-message nil)
;; Font and theme
(load-theme 'molokai t)
(add-to-list 'default-frame-alist '(font . "DejaVu Sans Mono-10"))
;; Remove menu / tool bars
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

(line-number-mode 1) ;; Display line
;(column-number-mode 1) ;; Column number (too expensive !)

;; Parenthesis highlight
(show-paren-mode t)
(setq show-paren-style 'parenthesis)
(setq-default tab-width 4) ;;tab display size

;; Enable font-lock mode. Has to be done before new font-lock definitions
;; We use lazy-lock-mode which is cleverer and faster for large files.
(global-font-lock-mode t)
(setq lazy-lock-minimum-size '((c-mode . 10000) (c++-mode . 10000))) ; lazy is unabled for these sizes
(setq lazy-lock-defer-on-the-fly nil)   ; Immediately fontify new text
(setq lazy-lock-stealth-time nil)	; After 5 seconds on inactivity, rest of the buffer is fontified
(setq lazy-lock-defer-time 1)           ; Immediately fontify new text
(setq lazy-lock-defer-on-scrolling t)   ; scroll first, fontify after defer time
(setq lazy-lock-stealth-verbose nil)    ; print a message when stealth mode is activated
(setq font-lock-maximum-decoration 3)   ; Niveau max 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; Misc ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General behaviour
(setq case-fold-search 1) ;; Case unsensitive search/expand (if typed in lowercase)
(delete-selection-mode t) ;; Replace / erase the selection
(global-auto-revert-mode t) ;; Auto reload modified files
(setq x-select-enable-clipboard t) ;; Interact with native clipboard
(setq make-backup-files nil) ;; Deactivate backup files
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(delete-selection-mode t)
 '(org-CUA-compatible nil)
 '(org-replace-disputed-keys nil)
 '(recentf-mode t)
 '(shift-select-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
