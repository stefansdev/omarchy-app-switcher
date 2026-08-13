# Omarchy App Switcher

A fast, theme-aware app switcher for Omarchy v4. It follows recent focus order,
shows live window previews, and activates the selected app when Super is
released.

## Controls

- `Super+Tab`: open the switcher or move forward
- `Super+Shift+Tab`: move backward
- Release `Super`: activate the selected app
- `Enter`: activate immediately
- `Escape`: cancel
- Click a card: activate it

## Development install

Link this repository into Omarchy's user plugin directory, rescan plugins,
enable `stefans.app-switcher`, and put `bin/omarchy-app-switcher` on `PATH`.
Load `hypr/app-switcher.lua` from the user Hyprland configuration so releasing
Super commits the current selection reliably on Omarchy v4.

The overlay uses Omarchy's shared `Color`, `Style`, `BorderSurface`, and
Hyprland integration, so it follows the active theme automatically.
