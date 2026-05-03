;;; browser-debug-bridge.el --- Portable browser debugging bridge  -*- lexical-binding: t; -*-

(require 'cl-lib)

(defvar bdb/root
  (file-name-directory (or load-file-name buffer-file-name))
  "Root directory for browser-debug-bridge assets.")

(defvar bdb/js-debug-root
  (expand-file-name "vendor/js-debug" bdb/root)
  "Directory containing the unpacked vscode-js-debug adapter.")

(defvar bdb/js-debug-server
  (expand-file-name "src/dapDebugServer.js" bdb/js-debug-root)
  "Path to the js-debug DAP server entry point.")

(defvar bdb/chrome-candidates
  '("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary")
  "Candidate browser executables for js-debug on macOS.")

(defun bdb/chrome-executable ()
  "Return a browser executable path suitable for js-debug."
  (or (cl-find-if #'file-exists-p bdb/chrome-candidates)
      "google-chrome"))

(defun bdb/js-debug-installed-p ()
  "Return non-nil when the js-debug adapter is installed."
  (file-exists-p bdb/js-debug-server))

(defun bdb/ensure-js-debug (config)
  "Ensure js-debug and supporting executables exist for CONFIG."
  (unless (executable-find "node")
    (user-error "Node is required for browser-debug-bridge"))
  (unless (bdb/js-debug-installed-p)
    (user-error "js-debug is missing from vendor/js-debug. Run %s to refresh it"
                (expand-file-name "install-js-debug.sh" bdb/root)))
  (when-let ((runtime-executable (plist-get config :runtimeExecutable)))
    (unless (or (executable-find runtime-executable)
                (file-exists-p runtime-executable))
      (user-error "Browser executable %S was not found" runtime-executable))))

(defun bdb/make-chrome-launch-config (url web-root &rest props)
  "Create a `dape' Chrome launch config for URL rooted at WEB-ROOT.
PROPS is appended to the generated plist."
  (append
   `(modes (js-mode js-ts-mode typescript-mode typescript-ts-mode)
           ensure bdb/ensure-js-debug
           command "node"
           command-args (,bdb/js-debug-server :autoport)
           port :autoport
           :type "pwa-chrome"
           :request "launch"
           :cwd ,web-root
           :url ,url
           :webRoot ,web-root
           :runtimeExecutable ,(bdb/chrome-executable)
           :sourceMaps t)
   props))

(defun bdb/register-config (name config)
  "Register NAME with CONFIG in the current buffer's `dape-configs'.
NAME may be a symbol or string. The intended naming convention is
`<project>-debug'."
  (unless (featurep 'dape)
    (require 'dape))
  (unless (boundp 'dape-configs)
    (user-error "dape-configs is unavailable; dape did not load correctly"))
  (let ((key (if (symbolp name) name (intern name))))
    (setq-local dape-configs
                (cons (cons key config)
                      (assq-delete-all key (or dape-configs nil))))))

(provide 'browser-debug-bridge)

;;; browser-debug-bridge.el ends here
