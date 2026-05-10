# dotfiles

Cross-machine dotfiles managed by [chezmoi](https://www.chezmoi.io). Bootstraps:

- **MBA** (M5, daily driver — `mba`)
- **MBP-as-server** (M1, headless dev box — `mac-dev`)
- **DGX** (Linux compute box — `dgx`)

Same repo, per-machine config via templating. See `../migration-plan.md` for the
broader migration this is part of.

## Quickstart on a fresh machine

```bash
# One-liner: installs Homebrew/build tools + chezmoi, then applies dotfiles.
# You'll be prompted for: name, email, machine type, GitHub username.
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robszpila/dotfiles/main/bootstrap.sh)"
```

Or manually:

```bash
# 1. Install Homebrew (macOS) or git+curl (Linux)
# 2. Install chezmoi
brew install chezmoi    # or: sh -c "$(curl -fsLS get.chezmoi.io)"

# 3. Init from this repo
chezmoi init --apply git@github.com:robszpila/dotfiles.git
```

## chezmoi in 60 seconds

- `chezmoi.io` repo lives at `~/.local/share/chezmoi` (the "source")
- Files prefixed `dot_` map to `~/.{name}` (so `dot_zshrc` → `~/.zshrc`)
- Files suffixed `.tmpl` are Go templates, evaluated against `chezmoi data`
- Files prefixed `run_onchange_` are scripts that run when their content changes
- `before_` / `after_` after `run_onchange_` controls ordering vs dotfile application
- Per-machine answers live in `~/.config/chezmoi/chezmoi.toml` (gitignored, machine-local)

Daily commands:

```bash
chezmoi edit ~/.zshrc          # edit the source, opens in $EDITOR
chezmoi diff                   # what would change if I applied right now
chezmoi apply -v               # apply changes from source → home
chezmoi cd                     # cd to source dir
chezmoi git -- pull            # pull latest from remote
chezmoi update                 # pull + apply in one
```

## Adding a new file

```bash
chezmoi add ~/.something       # imports existing file into source
# or:
chezmoi add --template ~/.something  # imports as a template
```

## Secrets

**Secrets do not live in this repo.** Enpass is the canonical store. The
templates here only reference public/non-sensitive values (name, email,
GitHub username). For anything sensitive:

- API keys → set them manually in `~/.config/<tool>/`, fetched from Enpass on first install
- SSH keys → generated **per machine**, never synced across hosts (see below)
- GitHub auth → use `gh auth login`, not a token in this repo

## SSH keys

Per-machine generation. Don't sync. Reasons: easier revocation, better blast-radius
control, no password-manager-as-key-storage failure mode.

```bash
ssh-keygen -t ed25519 -C "rob@$(scutil --get LocalHostName 2>/dev/null || hostname)"
# Add ~/.ssh/id_ed25519.pub to GitHub:
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(scutil --get LocalHostName 2>/dev/null || hostname)"
```

For `mac-dev` and `dgx` (Tailscale-reachable machines), prefer **Tailscale SSH** —
auth is via your Tailscale identity, no key management. Standard SSH stays as
fallback if Tailscale is down.

## gh multi-account

Native in `gh` v2.40+:

```bash
gh auth login                  # add an account
gh auth switch                 # toggle active account
gh auth status                 # list all
```

For repo-specific account selection (e.g. always use work account in work repos),
set via git config in that repo:

```bash
cd ~/work-repo
git config user.email work@example.com
gh repo set-default            # picks the right gh account based on remote
```

## Layout

```
.
├── README.md                                    # this file
├── bootstrap.sh                                 # entry point for fresh machines
├── .chezmoi.toml.tmpl                          # init prompts → ~/.config/chezmoi/chezmoi.toml
├── .chezmoiignore                              # files in source not to apply
├── dot_zshrc.tmpl                              # ~/.zshrc
├── dot_gitconfig.tmpl                          # ~/.gitconfig
├── dot_gitignore_global                        # ~/.gitignore_global
├── dot_config/
│   ├── starship.toml                           # ~/.config/starship.toml
│   ├── ghostty/config                          # ~/.config/ghostty/config
│   └── git/ignore                              # ~/.config/git/ignore (alt to ~/.gitignore_global)
├── run_onchange_before_install-packages.sh.tmpl   # brew bundle / apt install
└── run_onchange_after_macos-defaults.sh.tmpl      # defaults write
```

## Per-machine notes

### mba

- Daily driver, kept light
- No Xcode, no Android Studio, no Docker — those live elsewhere
- Casks: chrome, vscode, ghostty, raycast, enpass, syncthing, obsidian, rectangle

### mac-dev

- Headless on a shelf; reached via Tailscale SSH + Screen Sharing
- Heavy: Xcode (App Store, not brew), Android Studio, Watchman
- Auto-login + caffeinate for headless behavior — set in macos-defaults

### dgx

- Linux. No brew casks (uses apt + flatpak as needed)
- No GUI apps
- Works alongside the DGX-specific bootstrap and backup setup
  (see `../../dgx/dgx-migration-backup.md`)

## When something breaks

1. `chezmoi diff` to see what's different between source and home
2. `chezmoi apply -v --dry-run` to preview changes
3. `chezmoi cat ~/.zshrc` to see the rendered output of a templated file
4. `chezmoi data` to see the values being used in templates

Errors during a `run_onchange_` script don't roll back already-applied dotfiles —
expected behavior, but worth knowing.
