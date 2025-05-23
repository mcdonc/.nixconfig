;;; package --- Summary
;;; Commentary:

;;; Code:

;; uncopied: auto-complete-mode
(setq inhibit-startup-message t)
(tool-bar-mode 0)
(menu-bar-mode 1)
(set-scroll-bar-mode nil)

;;;; Presentation font sizing (emacsclient)
;; (setq default-frame-alist '((width . 80)
;;                             (height . 34)
;;                             (font-backend . "xft")
;;                             (font . "Ubuntu Nerd Font Mono-22")))
;;(set-face-attribute 'default nil :height 150)

;; Normal font sizing (emacsclient)
(setq default-frame-alist '((width . 80)
                            (height . 34)
                            (font-backend . "xft")
                            (font . "UbuntuMono Nerd Font Mono-18")
                            (vertical-scroll-bars . nil)))

;; (set-frame-font "Ubuntu Mono-14" nil t)

(setq show-trailing-whitespace t)
(setq-default indent-tabs-mode nil)
(show-paren-mode t)
;; Make region visible when it's active
(transient-mark-mode t)
;; turn off damn beeping
(setq visible-bell t)
;; Require a final newline in a file, to avoid confusing some tools
(setq require-final-newline t)
(setq line-spacing 0.2)
;; Don't make me type out 'yes', 'y' is good enough.
(fset 'yes-or-no-p 'y-or-n-p)
(setq column-number-mode t)
; override default 72 column fill
(setq-default fill-column 79)
(setq indent-tabs-mode nil)
;; tab width
(setq tab-width 4)
(add-hook 'after-init-hook 'hide-emacs-options-menu)
;; Turn on font-lock in all modes that support it
(if (fboundp 'global-font-lock-mode)
    (global-font-lock-mode t))
;; "maximum gaudiness"
(setq font-lock-maximum-decoration t)


; Integrate X clipboard and emacs copy/yank; see
; http://www.emacswiki.org/emacs/CopyAndPaste#toc2

(global-set-key "\C-w" 'clipboard-kill-region)
(global-set-key "\M-w" 'clipboard-kill-ring-save)
(global-set-key "\C-y" 'clipboard-yank)

(require 'uniquify)
(require 'nxml-mode)
(require 'saveplace)
(require 'auto-complete-config)
(require 'auto-complete)
(require 'compile)
(require 'web-mode)
(require 'auth-source)
(require 'server)
(require 'font-core)
(require 'dired)
(require 'browse-url)
(require 'multiple-cursors)
(require 'editorconfig)
(require 'lsp-mode)
(require 'lsp-ui)
(require 'lsp-jedi)

(use-package lsp-mode
  :init
(setq lsp-auto-guess-root nil)
  :hook (rust-mode . lsp)
        (lsp-mode . lsp-enable-which-key-integration)
        :commands lsp)

(use-package lsp-ui
  :commands lsp-ui-mode)

(use-package lsp-nix
  :ensure lsp-mode
  :after (lsp-mode)
  :demand t
  :custom
  (lsp-nix-nil-formatter ["nixpkgs-fmt"]))

(use-package nix-mode
  ; :mode ("\\.nix\\'" "\\.nix.in'")
  :hook (nix-mode . lsp-deferred)
  )

(editorconfig-mode 1)

;; set up multiple cursor mode like vs code
(global-set-key (kbd "C-S-l") 'mc/mark-all-like-this)

; your fingers are wired to using C-x k to kill off buffers (and you
; dont like having to type C-x #)
; http://www.emacswiki.org/emacs/EmacsClient#toc32

; requires server.el
(add-hook 'server-switch-hook
          (lambda ()
            (when (current-local-map)
              (use-local-map (copy-keymap (current-local-map))))
            (when server-buffer-clients
              (local-set-key (kbd "C-x k") 'server-edit))))


;; from font-core package
(setq inihibit-compacting-font-caches t)

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "firefox")

(add-hook 'dired-load-hook
    (lambda ()
      (load "dired-x")
     ))

(add-hook 'dired-mode-hook
    (lambda ()
      (setq dired-omit-files-p t)
      (setq dired-omit-files
            (concat dired-omit-files "\\|^\\..+$\\|__pycache__"))
     ))

;; Get dired to consider .pyc and .pyo files to be uninteresting
(load "dired")

(setq dired-omit-extensions
      (append '(".pyc" ".pyo" ".bak" ".cache" ".pt.py" "html.py")
              dired-omit-extensions))

(put 'dired-find-alternate-file 'disabled nil)

(defun dired-do-ispell (&optional arg)
  "Do ispell from Dired.  Takes ARG."
  (interactive "P")
  (dolist (file (dired-get-marked-files
                 nil arg
                 #'(lambda (f)
                     (not (file-directory-p f)))))
    (save-window-excursion
      (with-current-buffer (find-file file)
        (ispell-buffer)))
    (message nil)))

;; https://emacs.stackexchange.com/questions/66541/git-track-flag-in-dired
;(add-hook 'dired-mode-hook 'diff-hl-dired-mode)

; dont ask if we should follow symlinks
(setq vc-follow-symlinks t)

(require 'doom-modeline)
(doom-modeline-mode 1)

(setq save-place-file "~/.emacs.d/saved-places")
(setq-default save-place t)
(setq uniquify-buffer-name-style 'post-forward)
; make sure emacsclient buffer visit invokes saveplace too
(setq server-visit-hook (quote (save-place-find-file-hook)))
;; Put autosave files (ie #foo#) in one place, *not*
;; scattered all over the file system!

(defvar autosave-dir "~/.emacs.d/saves/")
(make-directory autosave-dir t)

(defun auto-save-file-name-p (filename)
  "Save file.  Takes FILENAME."
  (string-match "^#.*#$" (file-name-nondirectory filename)))

(defun make-auto-save-file-name()
  "Make filename."
  (concat autosave-dir
   (if buffer-file-name
      (concat "#" (file-name-nondirectory buffer-file-name) "")
    (expand-file-name
     (concat "#%" (buffer-name) "#")))))

;; Put backup files (ie foo~) in one place too. (The backup-directory-alist
;; list contains regexp=>directory mappings; filenames matching a regexp are
;; backed up in the corresponding directory. Emacs will mkdir it if necessary.)

(defvar backup-dir "~/.emacs.d/backups")
(make-directory backup-dir t)

(setq backup-directory-alist
      `((".*" . ,backup-dir)))
(setq auto-save-file-name-transforms
      `((".*" ,backup-dir t)))

;; This is lame, but file watchers that look for patterns and dont have an
;; exclude feature see symlinks that interlocking/lockfiles creates and do a
;; spurious rebuilt (e.g. foo.scss -> .#foo.scss when you are watching *.scss).

(add-hook 'after-init-hook (lambda () (setq-default create-lockfiles nil))) t

(add-hook 'after-init-hook #'global-flycheck-mode)

;; (defun flycheck-python-setup ()
;;   "Run flycheck."
;;   (flycheck-mode))
;; (add-hook 'python-mode-hook #'flycheck-python-setup)

;; (setq flycheck-python-flake8-executable "/run/current-system/sw/bin/flake8")

(require 'flycheck-pyflakes)
(add-hook 'python-mode-hook 'flycheck-mode)

;; If you want to use pyflakes you probably don't want pylint or
;; flake8. To disable those checkers, add the following to your
;; init.el:

(add-to-list 'flycheck-disabled-checkers 'python-flake8)
(add-to-list 'flycheck-disabled-checkers 'python-pylint)

(defun my-web-mode-hook ()
  "Hooks for Web mode."
  (setq web-mode-markup-indent-offset 2)
)
(add-hook 'web-mode-hook  'my-web-mode-hook)

(setq jshint-configuration-path "~/.emacs.d/jshintrc.json")

(setq js-indent-level 4)

;;from Georg Brandl
;; highlight XXX style code tags in source files
(font-lock-add-keywords 'python-mode
  '(("\\<\\(FIXME\\|HACK\\|XXX\\|TODO\\)" 1 font-lock-warning-face prepend)))

(setq c-basic-offset 4)

;; pdb.set_trace() macro
(fset 'pdb-set
   "import pdb; pdb.set_trace()")

; dont be so lazy in rst mode
(setq rst-mode-lazy nil)

; use restructured text mode for .rst and .rest files
(setq auto-mode-alist
      (append '(("\\.rst$" . rst-mode)
                ("\\.rest$" . rst-mode)) auto-mode-alist))

(add-hook 'c-mode-hook
        (function (lambda ()
                (setq c-basic-offset 4)
                (setq c-indent-level 4))))

(autoload 'forth-mode "gforth.el")
(setq auto-mode-alist
    (append '(("\\.fs$" . forth-mode)
                ("\\.fth$" . forth-mode)) auto-mode-alist))

; smartttabs broken in e29: https://github.com/jcsalomon/smarttabs/issues/53
;(autoload 'smart-tabs-mode "smart-tabs-mode"
;  "Intelligently indent with tabs, align with spaces!")
;(autoload 'smart-tabs-mode-enable "smart-tabs-mode")
;(autoload 'smart-tabs-advice "smart-tabs-mode")
;(autoload 'smart-tabs-insinuate "smart-tabs-mode")
;
;(smart-tabs-insinuate 'c 'c++)


(add-to-list 'auto-mode-alist '("\\.zcml$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.xml$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.mxml$" . nxml-mode))

(add-to-list 'auto-mode-alist '("\\.zpt$" . web-mode))
(add-to-list 'auto-mode-alist '("\\.pt$" . web-mode))
(add-to-list 'auto-mode-alist '("\\.jinja2$" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html$" . web-mode))

(add-to-list 'auto-mode-alist '("\\.tmgen$" . hcl-mode))
(add-to-list 'auto-mode-alist '("\\.hcl$" . hcl-mode))

(defun word-count nil "Count words in buffer." (interactive)
  (shell-command-on-region (point-min) (point-max) "wc -w"))

(defun dos2unix()
  "Convert this entire buffer from MS-DOS text file format to UNIX."
  (interactive)
  (save-excurson
    (goto-char (point-min))
    (replace-regexp "\r$" "" nil)
    (goto-char (1- (point-max)))
    (if (looking-at "\C-z")
        (delete-char 1))))

; work like vi "J" (instead of the inverse of joining the current line to the
; previous, join the next line to the current)
(defun join-next-line ()
  "Join next line."
   (interactive)
  (join-line 1))

(setq ispell-process-directory (expand-file-name "~/"))

;;; Stefan Monnier <foo at acm.org>. It is the opposite of fill-paragraph
(defun unfill-paragraph (&optional region)
  "Takes a multi-line paragraph REGION and make it into a single line of text."
  (interactive (progn (barf-if-buffer-read-only) '(t)))
  (let ((fill-column (point-max))
        ;; This would override `fill-column' if it's an integer.
        (emacs-lisp-docstring-fill-column t))
    (fill-paragraph nil region)))

;; Handy key definition
(define-key global-map "\M-Q" 'unfill-paragraph)

(defun unfill-region ()
  "Unfills a region."
  (interactive)
  (let ((fill-column (point-max)))
    (fill-region (region-beginning) (region-end) nil)))

;; Use a minor mode for all my "override" key bindings:

(defvar my-keys-minor-mode-map (make-keymap) "My-keys-minor-mode keymap.")

(define-key my-keys-minor-mode-map (kbd "C-z") 'undo)
(define-key my-keys-minor-mode-map [delete] 'delete-char)
(define-key my-keys-minor-mode-map [kp-delete] 'delete-char)
(define-key my-keys-minor-mode-map (kbd "M-g") 'goto-line)
(define-key my-keys-minor-mode-map (kbd "M-t") 'pdb-set)
(define-key my-keys-minor-mode-map (kbd "C-q") 'query-replace)
(define-key my-keys-minor-mode-map (kbd "C-o")  'call-last-kbd-macro)
(define-key my-keys-minor-mode-map (kbd "C-d") 'expand-and-mark-next)
(define-key my-keys-minor-mode-map (kbd "C-w") 'clipboard-kill-region)
(define-key my-keys-minor-mode-map (kbd "M-w") 'clipboard-kill-ring-save)
(define-key my-keys-minor-mode-map (kbd "M-q") 'fill-paragraph)
(define-key my-keys-minor-mode-map (kbd "C-y") 'clipboard-yank)
(define-key my-keys-minor-mode-map [(control ?,)] 'call-last-kbd-macro)
(define-key my-keys-minor-mode-map [(control ?9)] 'start-kbd-macro)
(define-key my-keys-minor-mode-map [(control ?0)] 'end-kbd-macro)
(define-key my-keys-minor-mode-map [?\M-\C-+] 'increase-left-margin)
(define-key my-keys-minor-mode-map [?\M-\C--] 'decrease-left-margin)
(define-key my-keys-minor-mode-map (kbd "C-j") 'join-next-line)
(define-key my-keys-minor-mode-map (kbd "<f5>") 'compile)

(define-minor-mode my-keys-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  :init-value t
  :lighter " my-keys"
  :keymp 'my-keys-minor-mode-map)

(my-keys-minor-mode 1)

;; but turn that off in minibuffer

(defun my-minibuffer-setup-hook ()
  "Setup minbuffer."
   (my-keys-minor-mode 0))

(add-hook 'minibuffer-setup-hook 'my-minibuffer-setup-hook)

(defun stop-using-minibuffer ()
  "Kill the minibuffer."
  (when (and (>= (recursion-depth) 1) (active-minibuffer-window))
    (abort-recursive-edit)))

(add-hook 'mouse-leave-buffer-hook 'stop-using-minibuffer)

(add-hook 'c-mode-common-hook
          (lambda () (setq indent-tabs-mode t)))

(setq nix-nixfmt-bin "nixpkgs-fmt")

;; hide the options menu
(defun hide-emacs-options-menu ()
  "Hide the Emacs 'Options' menu."
  (define-key global-map [menu-bar options] nil))

(setq gptel-model "gpt-4")

;; ;; flycheck-pos-tip font face, see
;; ;; https://github.com/flycheck/flycheck-pos-tip/issues/20

;; (setq x-gtk-use-system-tooltips nil)

(provide 'init)
;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 ;; (this is to fix markdown mode preformatted text font size)
 '(fixed-pitch ((t (:family "Ubuntu Nerd Font Mono"))))
 '(font-lock-constant-face ((t (:foreground "purple"))))
 '(font-lock-string-face ((t (:foreground "RosyBrown3")))))

(set-face-attribute 'web-mode-html-attr-name-face nil :foreground "sienna")
(set-face-attribute 'web-mode-html-attr-value-face nil :foreground "RosyBrown3")
(set-face-attribute 'web-mode-html-tag-face nil :foreground "Blue1")
(set-face-attribute 'web-mode-doctype-face nil :foreground "Purple")
