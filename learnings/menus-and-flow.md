# Menus and navigation flow

What trips people up: **which menu shows first**, **how Survival hands off back to the main menu**, and **what the pause quit dialog is for**.

## Main menu (`main_menu.tscn` / `main_menu.gd`)

- Cold start shows **`MainPage`**: Play, Settings, Quit to Desktop (Play hub — **not** Game modes).
- **Play** hides `MainPage` and shows **`PlayPage`** (Game modes: shooting range, Survival, etc.).
- **Esc** while Game modes are visible returns to the Play hub.

## Survival submenu (`main_menu_survival.tscn` / `main_menu_survival.gd`)

- **Back** (and **Esc** on the hub) goes to `main_menu.tscn` with **`SceneTree` root meta** `main_menu_show_game_modes = true`.
- **`main_menu.gd`** `_ready()` consumes that meta and opens **`PlayPage`** immediately so the player lands on Game modes, not the Play hub.

If you add another scene that should restore Game modes on return, reuse the same meta key and consumer logic — avoid duplicating magic strings.

## Pause menu (`pause_menu.gd`)

- **Quit to Desktop** opens a **`ConfirmationDialog`** (`_build_dialogs()`): title/body/button labels explain stub saves vs session-only state (tone stays playful but readable).
- **Quit to Main Menu** skips that dialog and loads the main menu scene directly.

## Settings (`settings_menu_panel.tscn` / `game_settings.gd` autoload)

- Same panel is embedded under the main menu(s) and opened from **pause → Settings**. Changes apply immediately and save to **`user://settings.cfg`** (no separate Apply button).
- **Gameplay-facing**: mouse sensitivity multiplier + invert Y and hip **FOV** are read by `player_controller.gd`. Master volume uses **AudioServer** Master bus; fullscreen / vsync use **DisplayServer**.
- **Keybinds tab**: remaps keyboard + mouse bindings listed there; persisted in **`user://input_bindings.json`** via **`InputBindingsSave`** (loads after **`InputSetup`** applies defaults). **Reset** wipes the JSON and reapplies code defaults.

## Naming

The playable survival branch from Game modes is labeled **Survival** in UI. Arena/runtime filenames may still say `zombie_*`; don’t rename those paths unless you’re ready to chase references across the project.
