#!/usr/bin/env bash
# Bootstrap tmux plugin manager (TPM) + install the plugins declared in
# ~/.tmux.conf (tmux-resurrect, tmux-continuum). run_once: chezmoi runs this a
# single time per machine (re-runs only if this script's content changes).
set -eu

log() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }

# tmux isn't strictly required to clone TPM, but if it's missing the plugins
# can't install — install-packages should have provided it already.
command -v tmux >/dev/null 2>&1 || { log "tmux not on PATH yet; skipping TPM bootstrap"; exit 0; }

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  log "Cloning TPM"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  log "TPM present"
fi

# Install plugins non-interactively (no attached session needed).
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
  log "Installing tmux plugins (resurrect, continuum)"
  "$TPM_DIR/bin/install_plugins" || log "plugin install returned non-zero (often fine on first run)"
fi
