# Omarchy App Switcher

A fast, theme-aware recent-app switcher for Omarchy v4. It uses large HiDPI
icons, follows recent focus order, and activates the selected app when Super is
released.

## Install

```bash
omarchy plugin add git@github.com:stefansdev/omarchy-app-switcher.git --enable --yes
~/.config/omarchy/plugins/stefans.app-switcher/bin/install
```

The second command safely backs up `~/.config/hypr/bindings.lua`, installs the
shortcuts and Super-release observer, validates the generated Lua, and reloads
Hyprland. Running it again is safe.

## Controls

- `Super+Tab`: open or move forward
- `Super+Shift+Tab`: open or move backward
- Release `Super`: activate the selected app
- `Enter`: activate immediately
- `Escape`: cancel
- Click an app: activate it

## Update

```bash
omarchy plugin update stefans.app-switcher --yes
```

Run the installer again only if release notes request it.

## Remove

Remove the shortcuts and observer before removing the plugin:

```bash
~/.config/omarchy/plugins/stefans.app-switcher/bin/uninstall
omarchy plugin remove stefans.app-switcher --yes
```

## Design

The keep-loaded overlay uses Omarchy's shared colors, typography, spacing, and
surface tokens, so it follows the active theme. Icons are requested at the
screen's device-pixel ratio, with Linux icon-theme lookup for desktop apps and
Chromium web apps. Missing icons fall back to a monogram.

## Requirements

- Omarchy v4 / Quattro shell plugins
- Hyprland's Lua configuration runtime
- `jq`

## License

MIT
