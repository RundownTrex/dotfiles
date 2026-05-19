# Dotfiles (chezmoi migration)

This branch contains an experimental migration of my dotfiles setup to use `chezmoi`.

Main branch remains the original/manual layout.

## Managed files

- `.bashrc`
- `~/.config/*`
  - autorandr
  - autostart
  - betterlockscreen
  - curd
  - dunst
  - fastfetch
  - fish
  - gtk-3.0
  - gtk-4.0
  - hypr
  - i3
  - i3blocks
  - kitty
  - mpv
  - polybar
  - ranger
  - rofi
  - waybar
  - wofi
- `~/.local/bin`
  - personal scripts only


## Useful commands

Preview changes:

```bash
chezmoi diff
chezmoi status
chezmoi apply --dry-run
```

Apply:

```bash
chezmoi apply
```

Show managed files:

```bash
chezmoi managed
```

Edit a file:

```bash
chezmoi edit ~/.config/fish/config.fish
```

Update source:

```bash
chezmoi add ~/.config/fish
```

## Restore on another machine

```bash
chezmoi init --branch chezmoi-migration https://github.com/RundownTrex/dotfiles.git
chezmoi apply
```

