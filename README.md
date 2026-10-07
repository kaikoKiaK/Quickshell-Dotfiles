# Quickshell Dotfiles

A personal collection of Quickshell configuration files and related dotfiles for a customized desktop environment.

## Overview

This repository is meant to hold the config, scripts, and styling used to shape a Quickshell-based setup. It is designed to be easy to review, tweak, and sync across machines.

## Typical layout

- `quickshell/` – main Quickshell configuration
- `scripts/` – helper scripts and automation
- `themes/` – colors, styling, and appearance config
- `config/` – additional dotfiles and application settings

## Dependencies

This configuration requires the following to function properly:

### Core Requirements
- **[Quickshell](https://github.com/quickshell/quickshell)** – A Qt-based shell replacement for Wayland. This is the primary framework for the entire dotfiles setup.

### Required Tools
- **fd** – Fast file finder used by the launcher's file search functionality
- **wl-copy** – Wayland clipboard utility for copying calculator results
- **xdg-open** – Standard tool for opening files with default applications

### Required Qt Modules
- **QtQuick** – Qt's declarative UI framework
- **QtQuick.Controls** – Standard UI controls

### Quickshell-specific Modules
- **Quickshell.Io** – Input/Output operations
- **Quickshell.Hyprland** – Hyprland window manager integration
- **Quickshell.Wayland** – Wayland protocol support

### Fonts
- **JetBrainsMono Nerd Font** – Used throughout the UI for a consistent monospace appearance with Nerd Font icons

### Optional
- **mpd** (Music Player Daemon) – For media widget functionality
- **hyprctl** – Hyprland control utility for workspace and monitor information

## Quick setup

```bash
git clone https://github.com/kaikoKiaK/Quickshell-Dotfiles.git
cd Quickshell-Dotfiles
```

Then copy or symlink the relevant files into your system configuration directories as needed for your setup.

Example:

```bash
mkdir -p ~/.config/quickshell
cp -r . ~/.config/quickshell
```

## Notes

This is a personal dotfiles repo, so feel free to adapt paths, layouts, and settings to match your own system.

## License

This project currently does not include a license file. If you plan to share or redistribute it, consider adding one.
