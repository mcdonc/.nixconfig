;; Presentation font sizing

;; (setq default-frame-alist '((width . 80)
;;                             (height . 34)
;;                             (font-backend . "xft")
;;                             (font . "Ubuntu Nerd Font Mono-22")))

;;(set-face-attribute 'default nil :height 150)

;; Normal font sizing

(setq default-frame-alist '((width . 80)
                            (height . 34)
                            (font-backend . "xft")
                            (font . "UbuntuMono Nerd Font Mono-18")))

(setq initial-frame-alist default-frame-alist)

;; dont show the GNU splash screen
(setq inhibit-startup-message t)

(set-frame-font "Ubuntu Mono-14" nil t)

;; (add-to-list 'load-path "/home/chrism/projects/python-mode/")
;; (setq py-install-directory "/home/chrism/projects/python-mode/")
;; (require 'python-mode)

;; use original Tim Peters Python-mode rather than fgallina's
;; (autoload 'python-mode "python-mode" "Python Mode." t)

;;(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
;;(add-to-list 'interpreter-mode-alist '("python" . python-mode))

(add-to-list 'load-path "~/.emacs.d/lisp")

(require 'package)

(setq package-archives '(("ELPA" . "http://tromey.com/elpa/")
                         ("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.org/packages/")))

;; nb: barry's "python-mode" comes from melpa; to get fgallina's back,
;; i guess, comment melpa out above.

(package-initialize)

;;(add-to-list 'load-path "/home/chrism/projects/web-mode/")
;(add-to-list 'load-path "/home/chrism/projects/ws-butler/")

;;(load "~/.emacs.d/manual/haskell-mode/haskell-site-file")

;;(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)

(require 'uniquify)
(require 'nxml-mode)
(require 'saveplace)
(require 'auto-complete)
(require 'auto-complete-config)
(require 'ido)
(require 'compile)
(require 'web-mode)
(require 'lsp-mode)
(require 'lsp-ui)
(require 'lsp-jedi)

(defun my-web-mode-hook ()
  "Hooks for Web mode."
  (setq web-mode-markup-indent-offset 2)
)
(add-hook 'web-mode-hook  'my-web-mode-hook)

;; (require 'ws-butler)

;; (yas--initialize)
;; (setq
;;  yas-snippet-dirs
;;  '("~/.emacs.d/snippets"
;;    "~/.emacs.d/elpa/yasnippet-0.8.0/snippets"))
;;(yas/load-directory )
(set-scroll-bar-mode nil)
(tool-bar-mode 0)
(menu-bar-mode 1)
(setq show-trailing-whitespace t)
(setq-default indent-tabs-mode nil)
(show-paren-mode t)
;(ido-mode t)
;(setq ido-enable-flex-matching t)

(global-auto-complete-mode t)

; uh, not quite sure what this does
(setq ac-dwim t)

; start autocomplete offers after 3rd character
(setq ac-auto-start 3)

; don't show autocomplete dropdown (replace nul with 2 for 2 seconds later)
(setq ac-auto-show-menu nil)

; use alt-E for accepting completion rather than return
(define-key ac-completing-map (kbd "RET") nil)
(define-key ac-completing-map [return] nil)
(define-key ac-completing-map (kbd "M-e") 'ac-complete)

; dont ask if we should follow symlinks
(setq vc-follow-symlinks t)

(add-to-list 'ac-dictionary-directories
             "~/.emacs.d/elpa/auto-complete-1.4/dict")

(ac-config-default)

;; All languages:
;; (setq skeleton-pair t)
;; (global-set-key "(" 'skeleton-pair-insert-maybe)
;; (global-set-key "[" 'skeleton-pair-insert-maybe)
;; (global-set-key "{" 'skeleton-pair-insert-maybe)
;; (global-set-key "\"" 'skeleton-pair-insert-maybe)

;; Just python
(add-hook 'python-mode-hook
          (lambda ()
            (define-key python-mode-map "'" 'skeleton-pair-insert-maybe)))

(add-hook 'python-mode-hook 'whitespace-cleanup-mode)
(add-hook 'web-mode-hook 'whitespace-cleanup-mode)
(add-hook 'javascript-mode-hook 'whitespace-cleanup-mode)

;; for fgallina python-mode
(add-hook 'python-mode-hook
        '(lambda () (define-key python-mode-map "\C-m" 'newline-and-indent)))

(require 'flycheck-pyflakes)
(add-hook 'python-mode-hook 'flycheck-mode)

(with-eval-after-load 'flycheck
  (flycheck-pos-tip-mode))


;; (setq mweb-default-major-mode 'html-mode)
;; (setq mweb-tags '((php-mode "<\\?php\\|<\\? \\|<\\?=" "\\?>")
;;                   (js-mode "<script +\\(type=\"text/javascript\"\\|language=\"javascript\"\\)[^>]*>" "</script>")
;;                   (css-mode "<style +type=\"text/css\"[^>]*>" "</style>")))
;; (setq mweb-filename-extensions '("htm" "html" "pt" "jinja2"))
;; (multi-web-global-mode 1)

; Integrate X clipboard and emacs copy/yank; see
; http://www.emacswiki.org/emacs/CopyAndPaste#toc2

(global-set-key "\C-w" 'clipboard-kill-region)
(global-set-key "\M-w" 'clipboard-kill-ring-save)
(global-set-key "\C-y" 'clipboard-yank)

;; Make region visible when it's active
(transient-mark-mode t)

;; turn off damn beeping
(setq visible-bell t)

; In X windows, the first click to focus a frame should not move the
; point.
;(setq x-mouse-click-focus-ignore-position t)

(setq save-place-file "~/.emacs.d/saved-places")

;; Require a final newline in a file, to avoid confusing some tools
(setq require-final-newline t)

(setq column-number-mode t)

;; faster syntax highlighting
(setq jit-lock-stealth-time 0.01)

;; Turn on font-lock in all modes that support it
(if (fboundp 'global-font-lock-mode)
    (global-font-lock-mode t))

;; "maximum gaudiness"
(setq font-lock-maximum-decoration t)

(put 'upcase-region 'disabled nil)
(setq uniquify-buffer-name-style 'post-forward)

(setq line-spacing 0.2)

(setq jshint-configuration-path "~/.emacs.d/jshintrc.json")

(setq js-indent-level 4)

; fill-column-indicator styling
;(setq fci-rule-width 1)
;(setq fci-rule-color "darkblue")

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "google-chrome")

;; dont show the GNU splash screen
(setq inhibit-startup-message t)

;; give this a shot, althought it doesn't seem to work
(setq font-lock-always-fontify-immediately t)

;; Don't make me type out 'yes', 'y' is good enough.
(fset 'yes-or-no-p 'y-or-n-p)

;;from Georg Brandl
;; highlight XXX style code tags in source files
(font-lock-add-keywords 'python-mode
  '(("\\<\\(FIXME\\|HACK\\|XXX\\|TODO\\)" 1 font-lock-warning-face prepend)))

;; good for defeating the whitespace-normalization commit hook
;;(set-variable 'show-trailing-whitespace 1)

(put 'downcase-region 'disabled nil)

(setq-default save-place t)

; make sure emacsclient buffer visit invokes saveplace too
(setq server-visit-hook (quote (save-place-find-file-hook)))

; override default 72 column fill
(setq-default fill-column 79)


;; tab width
(setq default-tab-width 4)
(setq c-basic-offset 4)
(setq indent-tabs-mode nil)
(setq tab-width 4)

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

;; (defun* get-closest-pathname (&optional (file "tox.ini"))
;;   "Determine the pathname of the first instance of FILE starting
;; from the current directory towards root.  This may not do the
;; correct thing in presence of links. If it does not find FILE,
;; then it shall return the name of FILE in the current directory,
;; suitable for creation"
;;   (let ((root (expand-file-name "/")))
;;     (expand-file-name file
;;                    (loop
;;                      for d = default-directory then (expand-file-name ".." d)
;;                      if (file-exists-p (expand-file-name file d))
;;                      return d
;;                      if (equal d root)
;;                      return nil))))

;; (add-hook 'python-mode-hook
;;           (lambda ()
;;             (set (make-local-variable 'compile-command)
;;                  (format "tox -c %s" (get-closest-pathname)))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ange-ftp-ftp-program-name "/usr/bin/ftp")
 '(ansi-color-names-vector
   ["black" "#d55e00" "#009e73" "#f8ec59" "#0072b2" "#cc79a7" "#56b4e9" "white"])
 '(haskell-check-command "hlint")
 '(paren-mode 'blink-paren nil (paren))
 '(safe-local-variable-values '((encoding . utf-8) (encoding . utf8))))

;; Get dired to consider .pyc and .pyo files to be uninteresting
(add-hook 'dired-load-hook
    (lambda ()
      (load "dired-x")
     ))

(add-hook 'dired-mode-hook
    (lambda ()
      (setq dired-omit-files-p t)
      (setq dired-omit-files (concat dired-omit-files "\\|^\\..+$\\|__pycache__"))
     ))

(load "dired")
(setq dired-omit-extensions
      (append '(".pyc" ".pyo" ".bak" ".cache" ".pt.py" "html.py")
              dired-omit-extensions))

(add-to-list 'auto-mode-alist '("\\.zcml$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.xml$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.mxml$" . nxml-mode))

(add-to-list 'auto-mode-alist '("\\.zpt$" . web-mode))
(add-to-list 'auto-mode-alist '("\\.pt$" . web-mode))
(add-to-list 'auto-mode-alist '("\\.jinja2$" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html$" . web-mode))

(add-hook 'after-init-hook #'global-flycheck-mode)


;; Put autosave files (ie #foo#) in one place, *not*
;; scattered all over the file system!

(defvar autosave-dir "~/.emacs.d/saves/")
(make-directory autosave-dir t)

(defun auto-save-file-name-p (filename)
  (string-match "^#.*#$" (file-name-nondirectory filename)))

(defun make-auto-save-file-name()
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

(defun word-count nil "Count words in buffer" (interactive)
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
  (interactive)
  (join-line 1))

(defun expand-and-mark-next ()
  (interactive)
  (if (use-region-p)
      (mark-next-like-this-and-scroll 1)
      (er/mark-symbol)))


(setq ispell-process-directory (expand-file-name "~/"))

(defun dired-do-ispell (&optional arg)
  (interactive "P")
  (dolist (file (dired-get-marked-files
                 nil arg
                 #'(lambda (f)
                     (not (file-directory-p f)))))
    (save-window-excursion
      (with-current-buffer (find-file file)
        (ispell-buffer)))
    (message nil)))

; your fingers are wired to using C-x k to kill off buffers (and you
; dont like having to type C-x #)
; http://www.emacswiki.org/emacs/EmacsClient#toc32

(add-hook 'server-switch-hook
          (lambda ()
            (when (current-local-map)
              (use-local-map (copy-keymap (current-local-map))))
            (when server-buffer-clients
              (local-set-key (kbd "C-x k") 'server-edit))))

; fill-column-indicator mode in html-ish modes prevents lines from wrapping
;(add-hook 'web-mode-hook 'fci-mode)

;(add-hook 'html-mode-hook
;	(function (lambda ()
;		(setq fill-column 100))))

;; Use a minor mode for all my "override" key bindings:

(defvar my-keys-minor-mode-map (make-keymap) "my-keys-minor-mode keymap.")

;; Set up the keyboard so the delete key on both the regular keyboard
;; and the keypad delete the character under the cursor and to the right
;; under X, instead of the default, backspace behavior.

; Integrate X clipboard and emacs copy/yank; see
; http://www.emacswiki.org/emacs/CopyAndPaste#toc2

; dick around with macros

;; Custom margin keys (useful for Python indentation)

;; bind ctrl-J to join next line (e.g. vi "J")

(define-key my-keys-minor-mode-map (kbd "C-z") 'undo)
(define-key my-keys-minor-mode-map [delete] 'delete-char)
(define-key my-keys-minor-mode-map [kp-delete] 'delete-char)
(define-key my-keys-minor-mode-map (kbd "M-g") 'goto-line)
(define-key my-keys-minor-mode-map (kbd "M-t") 'pdb-set)
(define-key my-keys-minor-mode-map (kbd "C-q") 'query-replace)
(define-key my-keys-minor-mode-map (kbd "C-o")  'call-last-kbd-macro)
(define-key my-keys-minor-mode-map (kbd "C-d") 'expand-and-mark-next)
;;(define-key my-keys-minor-mode-map (kbd "C-=") 'er/expand-region)
;;(define-key my-keys-minor-mode-map (kbd "C--") 'er/contract-region)
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

;; expand region
;; (global-set-key "\C-w" 'clipboard-kill-region)
;; (global-set-key "\M-w" 'clipboard-kill-ring-save)
;; (global-set-key "\C-y" 'clipboard-yank)
;; (global-set-key (kbd "C-d") 'expand-and-mark-next)
;; (global-set-key (kbd "C-=") 'er/expand-region)
;; (global-set-key (kbd "C--") 'er/contract-region)
;; (global-set-key [delete] 'delete-char)
;; (global-set-key [kp-delete] 'delete-char)
;; (global-set-key "\M-g" 'goto-line)
;; (global-set-key "\M-t" 'pdb-set)
;; (global-set-key "\^q" 'query-replace)
;; (global-set-key "\C-o"  'call-last-kbd-macro)
;(define-key global-map "\C-h" 'backward-delete-char)
; rebind help key (was "C-h")
;(global-unset-key "\M-?")
;(setq help-char ?\M-?)
;(global-set-key "\M-?" 'help-for-help)


(define-minor-mode my-keys-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  t " my-keys" 'my-keys-minor-mode-map)

(my-keys-minor-mode 1)

;; but turn that off in minibuffer

(defun my-minibuffer-setup-hook ()
  (my-keys-minor-mode 0))

(add-hook 'minibuffer-setup-hook 'my-minibuffer-setup-hook)

(defun stop-using-minibuffer ()
  "kill the minibuffer"
  (when (and (>= (recursion-depth) 1) (active-minibuffer-window))
    (abort-recursive-edit)))

(add-hook 'mouse-leave-buffer-hook 'stop-using-minibuffer)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-lock-constant-face ((t (:foreground "purple"))))
 '(font-lock-string-face ((t (:foreground "RosyBrown3")))))

(set-face-attribute 'web-mode-html-attr-name-face nil :foreground "sienna")
(set-face-attribute 'web-mode-html-attr-value-face nil :foreground "RosyBrown3")
(set-face-attribute 'web-mode-html-tag-face nil :foreground "Blue1")
(set-face-attribute 'web-mode-doctype-face nil :foreground "Purple")


(put 'dired-find-alternate-file 'disabled nil)

;;; Stefan Monnier <foo at acm.org>. It is the opposite of fill-paragraph
    (defun unfill-paragraph (&optional region)
      "Takes a multi-line paragraph and makes it into a single line of text."
      (interactive (progn (barf-if-buffer-read-only) '(t)))
      (let ((fill-column (point-max))
            ;; This would override `fill-column' if it's an integer.
            (emacs-lisp-docstring-fill-column t))
        (fill-paragraph nil region)))
;; Handy key definition
(define-key global-map "\M-Q" 'unfill-paragraph)

;;(load-theme 'vscode-dark-plus t)

(autoload 'smart-tabs-mode "smart-tabs-mode"
  "Intelligently indent with tabs, align with spaces!")
(autoload 'smart-tabs-mode-enable "smart-tabs-mode")
(autoload 'smart-tabs-advice "smart-tabs-mode")
(autoload 'smart-tabs-insinuate "smart-tabs-mode")

(smart-tabs-insinuate 'c 'c++)

(setq inihibit-compating-font-caches t)

(require 'doom-modeline)
(doom-modeline-mode 1)

(add-hook 'c-mode-common-hook
          (lambda () (setq indent-tabs-mode t)))

(setq nix-nixfmt-bin "nixpkgs-fmt")

;; flycheck-pos-tip font face, see

;; https://www.reddit.com/r/emacs/comments/11f05kr/question_on_configuring_flycheckpostip/?rdt=43425

;; https://github.com/flycheck/flycheck-pos-tip/issues/20

(setq x-gtk-use-system-tooltips nil)

;; (use-package faces
;;              :ensure nil
;;              :config
;;              (set-face-attribute 'default
;; 			         nil
;; 			         :family "Ubuntu Nerd Font Mono"
;; 			         :weight 'semi-light
;; 			         :width 'semi-condensed
;; 			         :height 130))
