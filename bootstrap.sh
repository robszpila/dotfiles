#!/usr/bin/env bash
# Bootstrap a fresh machine: install build deps, Homebrew (macOS), chezmoi,
# then run `chezmoi init --apply` against this repo.
#
# Usage:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/robszpila/dotfiles/main/bootstrap.sh)"
#
# Override the repo (e.g., testing a fork or branch):
#   DOTFILES_REPO=git@github.com:robszpila/dotfiles.git bash bootstrap.sh
#
# To install tools only without applying dotfiles (e.g., to inspect first):
#   APPLY=0 bash bootstrap.sh

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/robszpila/dotfiles.git}"
APPLY="${APPLY:-1}"

log() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*" >&2; }
die() { printf "\033[1;31m==>\033[0m %s\n" "$*" >&2; exit 1; }

OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
  log "macOS detected"

  # Xcode Command Line Tools
  if ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools (this opens a GUI prompt)..."
    xcode-select --install || true
    log "Re-run this script after the CLT install completes."
    exit 0
  else
    log "Xcode Command Line Tools present"
  fi

  # Rosetta 2 (Apple Silicon only; some casks still ship Intel binaries, e.g. Enpass)
  if [ "$(uname -m)" = "arm64" ]; then
    if ! arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
      log "Installing Rosetta 2 (requires sudo + license accept)..."
      sudo softwareupdate --install-rosetta --agree-to-license
    else
      log "Rosetta 2 present"
    fi
  fi

  # Homebrew
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon: brew lives at /opt/homebrew
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    log "Homebrew present: $(brew --version | head -1)"
  fi

  # chezmoi
  if ! command -v chezmoi >/dev/null 2>&1; then
    log "Installing chezmoi..."
    brew install chezmoi
  else
    log "chezmoi present: $(chezmoi --version)"
  fi

elif [ "$OS" = "Linux" ]; then
  log "Linux detected"

  # Build deps + chezmoi via the official one-liner (avoids needing brew on Linux)
  if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
    log "Installing git + curl + build-essential via apt..."
    sudo apt-get update
    sudo apt-get install -y git curl build-essential
  fi

  if ! command -v chezmoi >/dev/null 2>&1; then
    log "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
  else
    log "chezmoi present: $(chezmoi --version)"
  fi

else
  die "Unsupported OS: $OS"
fi

if [ "$APPLY" = "1" ]; then
  log "Running: chezmoi init --apply $DOTFILES_REPO"
  log "(You'll be prompted for name, email, machine type, GitHub user.)"
  chezmoi init --apply "$DOTFILES_REPO"
  log "Done. Open a new shell or run: source ~/.zshrc"
else
  log "Skipping chezmoi init (APPLY=0). Next step:"
  log "  chezmoi init --apply $DOTFILES_REPO"
fi
