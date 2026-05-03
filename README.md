# cdp-bridge

Portable browser debugging for Emacs `dape` using Microsoft's `js-debug` adapter.

## How it works

`cdp-bridge` lets Emacs debug a real Chrome or Chromium tab.

The stack looks like this:

- Emacs provides the UI through `dape`
- `dape` speaks DAP to the `js-debug` adapter unpacked into `vendor/js-debug`
- `js-debug` launches Chrome/Chromium and talks to the browser over CDP, the Chrome DevTools Protocol

In practice, this means your app still runs in the browser, while Emacs shows breakpoints, call stacks, locals, scopes, and the debug REPL.

## Overview

This repo can live wherever you want, as long as Emacs loads `browser-debug-bridge.el` from that location and your local `js-debug` install path matches what your config expects.

- `browser-debug-bridge.el` provides a small Emacs bridge for `dape`
- `js-debug` itself is not part of this repo
- you install `js-debug` separately and point Emacs at that install

## Requirements

- Emacs with `dape` installed
- `node` on your `PATH`
- Chrome or Chromium installed locally
- Microsoft's `js-debug` adapter unpacked somewhere on your machine
- Source maps enabled in your app build for useful TS/JS breakpoints

## Install `js-debug`

Install the `js-debug-dap` release from Microsoft's `vscode-js-debug` releases somewhere on your machine.

After unpacking it, make sure you know the full path to:

```text
/path/to/js-debug/src/dapDebugServer.js
```

That is the file Emacs needs to launch through `node`.

## Setup

1. Clone this repo wherever you want
2. Add this to your Emacs init, adjusting the path to where you cloned the bridge:

```elisp
(load-file "/path/to/browser-debug-bridge/browser-debug-bridge.el")
```

3. Set `bdb/js-debug-root` to wherever you unpacked `js-debug`
4. Register a `<project>-debug` config for the project you want to debug
5. Start that project's dev server
6. Run `M-x dape`, choose `<project>-debug`, and debug from Emacs while the app runs in the browser

For example:

```elisp
(load-file "/path/to/browser-debug-bridge/browser-debug-bridge.el")
(setq bdb/js-debug-root "/path/to/js-debug")
(setq bdb/js-debug-server
      (expand-file-name "src/dapDebugServer.js" bdb/js-debug-root))
```

## Example `.dir-locals.el`

One way to register a project config is with `.dir-locals.el`. Copy this into a project and replace the hardcoded path and URL with your own values:

```elisp
((nil . ((eval . (bdb/register-config
                  'cad-debug
                  (bdb/make-chrome-launch-config
                   "http://127.0.0.1:5173"
                   "/Users/j/Workspace/cad"
                   :userDataDir "/Users/j/Workspace/browser-debug-bridge/profiles/cad"))))))
```

If you do not want to use `.dir-locals.el`, you can instead call `bdb/register-config` from your init file or another Emacs Lisp file that you load manually.

The browser profile path can also be anywhere you want. Keeping it under a per-project directory is a simple way to avoid mixing browser state between projects.

`bdb/register-config` accepts either a symbol or a string name, but the intended convention is `<project>-debug`.
