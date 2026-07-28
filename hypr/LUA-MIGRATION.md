# Hyprland Lua config migration (staged)

Hyprland 0.55 replaced hyprlang with Lua as the config language. hyprlang
still works but is deprecated: it will be dropped "1-2 releases" after 0.55,
and new features (user-defined layouts, timers, events) are Lua-only.
**The installed 0.55.4 already fully supports Lua** — no pacman update is
needed to switch.

The Lua port lives alongside the old config and is completely inert:

- `hyprland-next.lua` — entry point. Hyprland only auto-loads a file named
  exactly `hyprland.lua` (preferring it over `hyprland.conf`, checked once at
  startup), so under this name it does nothing.
- `conf/*.lua` — one module per old `conf/*.conf`, loaded via `require()` from
  the entry point. Also inert until the entry point is active.
- `~/.config/hypr/hyprsplit/` — the [hyprsplit Lua library]
  (https://github.com/shezdy/hyprsplit), cloned machine-locally (like hyprpm
  state, not part of this repo). It replaces the deprecated C++ hyprpm plugin:
  `split:workspace` / `split:movetoworkspace` dispatchers become
  `hs.dsp.focus({ workspace = n })` / `hs.dsp.window.move({ workspace = n })`,
  and the `plugin { hyprsplit { ... } }` block becomes `hs.config({ ... })`.

## Deliberate changes from the .conf config

- `exec-once = hyprpm reload -n` is dropped — hyprsplit was the only plugin,
  and it now loads as a Lua library instead.
- The `borderangle` animation is dropped (no equivalent leaf in 0.55).
- The old duplicate `SUPER+M` binds (movetoroot + swapwithmaster) are one
  bind dispatching both.
- `layouts.conf` (empty `dwindle {}` / `master {}` blocks) has no Lua module.

## Activating (do this on a non-work day)

1. `cd ~/.dotfiles && git mv hypr/hyprland-next.lua hypr/hyprland.lua`
2. `dotsync` (symlinks `hyprland.lua` into `~/.config/hypr/`; the `conf/`
   modules are already visible through the folded `conf` symlink)
3. Restart Hyprland (log out / back in — the conf-vs-lua choice happens only
   at startup; `hyprctl reload` is not enough)
4. Sanity check: `hyprctl -j binds | jq length` should be 75, monitors laid
   out right, eww dock up, CTRL+1..9 switching per-monitor workspaces, and a
   numpad key (CTRL+KP_3) switching too. Note: lua keycode binds show
   `key=""`/`keycode: 0` in hyprctl output — that's cosmetic (the keys live
   in a new multi-key structure hyprctl doesn't serialize), not a failure.

## Rolling back

`git mv hypr/hyprland.lua hypr/hyprland-next.lua && dotsync`, then restart
Hyprland — it falls back to `hyprland.conf`, which stays untouched until
the Lua config has proven itself.

## Fresh machine note

On a new Arch box the hyprsplit library must exist before the Lua config's
first start: `git clone https://github.com/shezdy/hyprsplit
~/.config/hypr/hyprsplit`. Once the migration is proven, this belongs in
`install.sh` (replacing the hyprpm plugin instructions) and the old
`conf/*.conf` files + `hyprland.conf` can be deleted.

## Validation done at staging time

- `luac -p` parse check over the entry point and all modules.
- Executed the full config under `lua5.4` with a stubbed `hl` API and the
  real hyprsplit library: 75 binds, 7 window rules, 3 monitors, 23 env vars,
  6 config blocks registered — matching the .conf config plus the numpad
  workspace binds.
- Booted a nested Hyprland 0.55.4 (`Hyprland -c`) on this config (minus
  autostart): zero `configerrors`, all 75 binds registered, every
  spot-checked option applied (border_size, layout, sensitivity,
  numlock_by_default, rounding, inactive_timeout, disable_hyprland_logo),
  and hyprsplit created its persistent per-monitor workspace rules.
- Verified against the v0.55.4 source that `code:NN` keycode binds parse
  into the new `sMkKeys` structure and match on keycode at press time, and
  that `hl.dsp.window.drag()`/`resize()` invoke the same internal mouse
  handlers as the old `bindm` (no bind options needed — the shipped
  example's `{ mouse = true }` is ignored by the parser and was dropped).

Not provable without the real flip: the three-monitor layout rules and the
autostart block.
