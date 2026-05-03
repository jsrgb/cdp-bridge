# browser-debug-bridge

Portable browser debugging for Emacs `dape` with a vendored `js-debug` adapter.

## How it works

`browser-debug-bridge` lets Emacs debug a real Chrome or Chromium tab.

The stack looks like this:

- Emacs provides the UI through `dape`
- `dape` speaks DAP to the vendored `js-debug` adapter in `vendor/js-debug`
- `js-debug` launches Chrome/Chromium and talks to the browser over CDP, the Chrome DevTools Protocol

In practice, this means your app still runs in the browser, while Emacs shows breakpoints, call stacks, locals, scopes, and the debug REPL.

## Overview

This repo is meant to live at `~/Workspace/browser-debug-bridge` and be reusable across projects and machines.

- `browser-debug-bridge.el` provides a small Emacs bridge for `dape`
- `vendor/js-debug` is committed so the adapter does not need to be reinstalled on every machine
- `install-js-debug.sh` is optional and only used when you want to refresh the vendored adapter

## Requirements

- Emacs with `dape` installed
- `node` on your `PATH`
- Chrome or Chromium installed locally
- Source maps enabled in your app build for useful TS/JS breakpoints

## Setup

1. Clone this repo to `~/Workspace/browser-debug-bridge`
2. Add this to your Emacs init:

```elisp
(load-file "~/Workspace/browser-debug-bridge/browser-debug-bridge.el")
```

3. In each project, add a `.dir-locals.el` snippet that registers a `<project>-debug` config
4. Start that project's dev server
5. Run `M-x dape`, choose `<project>-debug`, and debug from Emacs while the app runs in the browser

## Example `.dir-locals.el`

Copy this into a project and replace the hardcoded path and URL with your own values:

```elisp
((nil . ((eval . (bdb/register-config
                  'cad-debug
                  (bdb/make-chrome-launch-config
                   "http://127.0.0.1:5173"
                   "/Users/j/Workspace/cad"
                   :userDataDir "/Users/j/Workspace/browser-debug-bridge/profiles/cad"))))))
```

The browser profile path under `~/Workspace/browser-debug-bridge/profiles/<project>` keeps state isolated between projects without baking project state into the bridge itself.

`bdb/register-config` accepts either a symbol or a string name, but the intended convention is `<project>-debug`.

## Optional adapter refresh

If you want to update the vendored `js-debug` adapter later:

```sh
~/Workspace/browser-debug-bridge/install-js-debug.sh
```

That refreshes `vendor/js-debug`. It is not part of normal per-machine setup when the repo already includes the adapter.

# cdp-bridge
