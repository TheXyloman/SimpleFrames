<p align="center">
  <img src="Logo.png" alt="SimpleFrames logo" width="180">
</p>

# SimpleFrames

Standalone World of Warcraft: Forever party and raid frames with secure click-casting, spell suggestions, priority targets, profiles, preview mode, and lightweight native options.

SimpleFrames is intentionally dependency-light. It does not embed Ace, LibStub, LibDataBroker, or other addon frameworks.

## Status

**Forever port: 0.2.0-beta.2 — in-game acceptance pending.** Targets official Blizzard Forever only.

The user's in-game `GetBuildInfo()` screenshot confirms **1.60.1, build 70532, Oct 20 2026, interface 16001** (verified October 21, 2026). This confirms the target client, not that the addon has passed gameplay tests. Automated Lua checks pass. User screenshots confirm startup, all diagnostic APIs available, and five-player preview rendering. Live-unit and combat checks remain pending.

The existing appearance and settings are retained. Anniversary TBC is no longer a supported target.

## Install

Copy the `SimpleFrames` folder into:

`World of Warcraft/_forever_/Interface/AddOns/SimpleFrames`

The addon TOC targets `## Interface: 16001`. On this Mac the destination is:

`/Applications/World of Warcraft/_forever_/Interface/AddOns/SimpleFrames`

For a first install, restart the game and enable SimpleFrames in the AddOns list. For subsequent Lua updates, `/reload` is sufficient. Keep any previous addon folder outside `AddOns` as a backup. SavedVariables are not removed or reset during installation.

## Feature Breakdown

### Party And Raid Frames

- Shows the player while solo, party frames while grouped, and raid frames in raids.
- Uses secure unit buttons so targeting and click-casting work through protected WoW frame attributes.
- Middle click targets the clicked real unit by default.
- Layout and unit assignment changes are deferred while in combat.
- Blizzard party and raid frames can be hidden automatically.

| Solo frame | Solo frame with power and raid icon |
| --- | --- |
| <a href="https://i.ibb.co/8gcnb9d1/solo-frame-basic.png"><img src="https://i.ibb.co/8gcnb9d1/solo-frame-basic.png" alt="Solo frame basic" width="320"></a> | <a href="https://i.ibb.co/ksD0fwCb/solo-frame-power-raid-icon.png"><img src="https://i.ibb.co/ksD0fwCb/solo-frame-power-raid-icon.png" alt="Solo frame with power and raid icon" width="320"></a> |

| Raid preview with groups and indicators |
| --- |
| <a href="https://ibb.co/G3Rtdbr4"><img src="https://i.ibb.co/cXQCy7sS/raid-preview-groups-auras.png" alt="Raid preview with groups, auras, raid icons, and status indicators" width="520"></a> |

### Layout

- Adjustable frame width, frame height, spacing, and mana/power bar height.
- Raid groups can be arranged across configurable group columns.
- Unit direction can be vertical or horizontal.
- Raid group headers can be shown or hidden.
- Assigned Tank, DPS, and Healer roles show as icons to the left of party and raid frames when role data is available.
- Raid subgroups with assigned role data are split under their group header into Tank, DPS, Healer, and Other sections.
- Frames can be locked or unlocked.
- When unlocked, the main frame, Prio targets frame, and Pets frame can be dragged.

### Text

- Health text modes: percent, raw, raw + percent, or off.
- Mana/power text modes: percent, raw, raw + percent, or off.
- Name text can be upper-left or centered.
- Raid target icon visibility and size are adjustable.
- Name, health, and power font sizes are adjustable.
- Name, health, and power text offsets are adjustable, with horizontal offsets bounded by the current frame width.

### Auras And Indicators

- Aura display modes: buffs + debuffs, buffs only, debuffs only, or off.
- Configurable maximum buff and debuff icon counts.
- Buff and debuff icon sizes can be adjusted independently.
- Configurable low-health threshold.
- Optional stun and silence indicators.
- Buff and debuff icon positions can be adjusted, with horizontal offsets bounded by the current frame width.
- Debuff coloring is based on dispel type where available.
- Stun and silence detection is best-effort from visible auras and known spell IDs; restricted aura identities are not classified.

### Spells And Click-Casting

- Native click-casting is built into SimpleFrames without external libraries.
- Click-casting can be enabled or disabled from the **Spells** options tab.
- Supported bind keys:
  - `L`: Left click
  - `R`: Right click
  - `SL`: Shift + left click
  - `SR`: Shift + right click
  - `AL`: Alt + left click
  - `AR`: Alt + right click
- Bindings can be set from the **Spells** options tab or with `/sfr bind`.
- The **Spells** tab shows matching spellbook spells as you type.
- Click a spell suggestion or press Enter to pick the first visible match.
- If your character knows a resurrection spell, click-casts automatically use it on dead party or raid members. Blank left click also resurrects dead units.
- Blank right click bindings do nothing. Blank left click does nothing on living units, preserving default behavior.
- Middle click remains reserved for targeting.
- Spell binding changes are deferred while in combat.
- Bindings are local to SimpleFrames and do not change Blizzard's global click bindings.
- Exact ranked names and learned spell IDs are accepted. Unresolved bindings remain saved but inactive; the Spells tab lists their keys. Learning spells refreshes the list automatically.
- Automatic resurrection uses the client's secure macro action and must be verified in-game. If the secure macro API is unavailable, ordinary learned spell bindings continue to work and the Spells tab explains the limitation.

Examples:

- `/sfr bind L Flash Heal`
- `/sfr bind SR Greater Heal`
- `/sfr bind R` clears right click.

### Prio Targets

- Shift + Middle Click a real party or raid unit to add or remove that unit from the separate **Prio targets** frame.
- The Prio targets frame uses the same visual style as the main frames.
- Prio target buttons use the same click-cast bindings as the main frames.
- The frame has its own saved position.
- Drag the frame by its title while SimpleFrames is unlocked.
- Use `/sfr prio clear` or the **Spells** tab to clear all prio targets.
- Prio targets are saved in the active profile and only show while those units are in the current party or raid.
- Priority changes are blocked while in combat when they would require protected updates.

### Pet Frame

- Party and raid pets appear in a separate **Pets** frame when pet units exist.
- The frame supports the player's pet, party pets, raid pets, and summoned demons through native WoW pet unit IDs.
- Pet buttons use the same click-cast bindings as the main frames.
- The frame has its own saved position and can be dragged by its title while SimpleFrames is unlocked.
- Pet frame visibility and column count are available from the **Layout** options tab.

### Profiles

- Active settings are saved per character in `SimpleFramesDB`.
- Reusable profiles are saved account-wide in `SimpleFramesProfilesDB`.
- Profiles include layout, text, aura, spell, pet frame, prio target, minimap, Blizzard UI, and frame position settings.
- Preview mode is not saved as active when capturing a profile.

### Preview Mode

- Party preview shows a simulated 5-player group.
- Raid preview shows a simulated 40-player raid.
- Preview health and power values can animate.
- Preview mode is useful for layout tuning without needing a group.
- Preview can be started from the options panel or slash commands.

| Animated raid preview |
| --- |
| <a href="https://ibb.co/50MCZXc"><img src="https://i.ibb.co/sfmc7p3/raid-preview-groups-animated.gif" alt="Animated raid preview with changing group health" width="520"></a> |

### Minimap Button

- Optional minimap button.
- Left click opens the options panel.
- Right click stops preview mode.
- The minimap button can be dragged around the minimap.

### Options Menu

The options panel is native UI and has no addon-library dependency.

- **General**: lock state, minimap button, frame/options reset, preview shortcuts, full reset, profiles.
- **Layout**: size, spacing, columns, unit direction, power bar, raid headers, pet frame controls.
- **Text**: health/power text modes, name placement, raid icons and raid icon size, font sizes, text offsets.
- **Auras**: aura mode, icon counts, icon sizes, low-health threshold, crowd-control indicators, icon offsets.
- **Spells**: click-cast enable toggle, bindings, spell suggestions, Prio targets enable/clear controls.
- **Blizzard UI**: hide or restore Blizzard party and raid frames.
- **Preview**: party preview, raid preview, preview off, animation toggle.

| General | Layout |
| --- | --- |
| <a href="https://ibb.co/J8z8mXz"><img src="https://i.ibb.co/HRrRBmr/options-general-tab.png" alt="Options General tab" width="360"></a> | <a href="https://ibb.co/HT0nPcQq"><img src="https://i.ibb.co/zV1G23wZ/options-layout-tab.png" alt="Options Layout tab" width="360"></a> |

| Text | Auras |
| --- | --- |
| <a href="https://ibb.co/Psqf3F6J"><img src="https://i.ibb.co/TD9FpYgJ/options-text-tab.png" alt="Options Text tab" width="360"></a> | <a href="https://ibb.co/rGhtpcQ9"><img src="https://i.ibb.co/Fb1WY0hp/options-auras-tab.png" alt="Options Auras tab" width="360"></a> |

| Spells | Blizzard UI |
| --- | --- |
| <a href="https://ibb.co/S4ZhvN0z"><img src="https://i.ibb.co/mVPLzJt3/options-spells-tab.png" alt="Options Spells tab" width="360"></a> | <a href="https://ibb.co/Zp7Tj4fx"><img src="https://i.ibb.co/XrMJQ0Wt/options-blizzard-ui-tab.png" alt="Options Blizzard UI tab" width="360"></a> |

| Preview |
| --- |
| <a href="https://ibb.co/KgcP3gf"><img src="https://i.ibb.co/NqgvHqJ/options-preview-tab.png" alt="Options Preview tab" width="360"></a> |

## Slash Commands

- `/sfr diagnose` prints addon/client versions and API availability without account or character identifiers.
- `/sfr`, `/sframes`, `/simpleframes`, or `/simpleframe` opens the options panel.
- `/sfr options` or `/sfr config` also opens the options panel.
- `/sfr lock` locks frame movement.
- `/sfr unlock` unlocks frame movement.
- `/sfr test party` or `/sfr preview party` starts party preview.
- `/sfr test raid` or `/sfr preview raid` starts raid preview.
- `/sfr test off` or `/sfr preview off` stops preview.
- `/sfr reset` restores defaults.
- `/sfr hideblizzard` hides Blizzard party and raid frames.
- `/sfr showblizzard` restores Blizzard party and raid frames.
- `/sfr bind L|R|SL|SR|AL|AR <spell>` sets or clears a click-cast spell.
- `/sfr prio clear` or `/sfr prio reset` clears the Prio targets frame.
- `/sfr prio show` enables the Prio targets frame.
- `/sfr prio hide` disables the Prio targets frame.
- `/sfr priority ...` works as an alias for `/sfr prio ...`.
- `/sfr profiles` lists saved account-wide profiles.
- `/sfr profile save <name>` saves the current settings as a reusable profile.
- `/sfr profile load <name>` loads a saved profile on the current character.
- `/sfr profile delete <name>` or `/sfr profile remove <name>` deletes a saved profile.

`/sf` is used by some world-buff/Songflower addons. SimpleFrames only registers `/sf` if it is not already taken, so `/sfr` is the reliable short command.

## Combat Lockdown Notes

WoW restricts secure frame changes in combat. SimpleFrames follows those rules.

- Layout, positions, lock state, profile loads, resets, and preview changes wait until combat ends.
- Roster assignment changes wait until combat ends. Existing buttons continue to display and target their current unit token. New members and pets appear after the protected refresh.
- When a priority button's token changes occupant during combat, it shows the current occupant with `(changed)` rather than the old priority name. The priority list is rebuilt after combat.
- Reloading the addon in combat defers frame creation until combat ends.
- Click-cast binding changes are queued until combat ends.
- Prio target display refreshes are queued when protected updates are required.
- Adding, removing, or clearing prio targets is blocked while in combat.
- Pet frame roster refreshes are queued until combat ends.

## Saved Variables

- `SimpleFramesDB`: per-character active settings.
- `SimpleFramesProfilesDB`: account-wide reusable profiles.

## Defaults At A Glance

- Frame width: `160`
- Frame height: `38`
- Power height: `10`
- Power bar: on
- Group columns: `5`
- Unit direction: vertical
- Raid headers: on
- Raid target icons: on
- Raid target icon size: `14`
- Health text: raw + percent
- Power text: raw + percent
- Aura mode: buffs + debuffs
- Buff icons: `2`
- Debuff icons: `3`
- Buff icon size: `12`
- Debuff icon size: `12`
- Low health threshold: `15%`
- Click-casting: enabled, with all spell bindings blank; left click auto-resurrects dead units if you know a resurrection spell
- Pet frame: enabled, one column
- Prio targets: enabled
- Minimap button: shown
- Hide Blizzard frames: enabled


## Forever restrictions

- Health/power values are passed directly to supported status bars and formatted text widgets. Percentages and low-health alpha use client curves, without Lua arithmetic on restricted values.
- Buff/debuff icons and stack text use `C_UnitAuras`. Known stun/silence detection and dispel-type priority borders require readable classifications. Restricted identities are omitted; an unavailable classification does not imply the unit has no crowd control or dispellable effect. This is also explained in Auras settings.
- Crowd-control detection is best-effort against known spell IDs, not a complete catalogue of every new Forever effect.
- When percentage/curve APIs are unavailable, readable values can still be formatted; restricted values fall back to raw display and unsupported low-health alerts are omitted.
- API availability alone cannot prove secure actions or combat displays work. `/sfr diagnose` reports capabilities for troubleshooting, not a compatibility certification.

## Validation

Run from the repository root with Lua 5.1:

```sh
lua tests/run.lua
```

Alternatively, install `lupa==2.6` into a development Python environment and run `python3 tests/run.py`. The Python runner uses Lupa's Lua 5.1 runtime. Neither Python nor Lupa is required by the addon.

Automated tests cover full UI initialization against widget mocks, opaque restricted values, live data displays, aura removal, spell/rank resolution, invalid and blank bindings, profile preservation, combat deferral, occupant changes, late Blizzard-frame loading, and identity-free diagnostics. The mocks cannot reproduce WoW's secure execution, taint system, engine restrictions, or visual rendering; those require the following client checks.

### In-game observations

- October 21, build 70532, beta.1: user screenshots confirm diagnostics and a five-player preview with bars, text, auras and raid markers. No error dialog appears in these screenshots.
- The preview exposed buff/health-text overlap and an incorrect DPS texture cell. Beta.2 moves auras below the text within the health bar and uses the client role-icon helper. Visual confirmation of beta.2 is pending.
- Aura offsets now apply from the bottom corners of the health bar. Existing offset values are preserved. Large fonts/icons or custom offsets may need a taller/wider frame.

### In-game acceptance checklist — remaining scenarios pending

Enable Lua error reporting with `/console scriptErrors 1`, then restart the game for the first installation.

- [ ] Fresh settings: login, `/sfr diagnose`, open all seven options tabs, minimap click/drag, `/reload`, logout/login; no Lua errors.
- [ ] Existing settings/profiles: save, load, delete, reset, and reload without losing bindings or other profiles.
- [ ] `/sfr test party`, `/sfr test raid`, animation on/off, layout and font changes, then `/sfr test off`; frames stay within the configured layout.
- [ ] Solo and five-player party: correct names, classes, roles, raid markers, health/power, death, disconnection, rejoining, zoning, pets appearing/disappearing.
- [ ] Raid: group and role ordering, subgroup changes, joins/leaves, pets and priority targets at the largest available raid size. Record the tested size.
- [ ] Bind every supported click combination to a learned spell; test alive/dead units, resurrection, range/mana failure, blank and invalid bindings, learning ranks, and pet casting.
- [ ] With Blizzard click bindings configured differently, SimpleFrames uses its own bindings and Blizzard frames retain theirs.
- [ ] Enter real combat: raw/percent/both/off text, low-health threshold, buffs/debuffs added/removed, stacks, readable CC/dispel indicators, and restricted-data behavior; no secret-value errors.
- [ ] Change profiles, reset, move/lock, change bindings/layout/preview, and change roster/pets during combat. Protected changes apply afterwards without blocked-action/taint errors or stale names.
- [ ] Hide/restore Blizzard frames, including after roster changes and late module loads.
- [ ] Reload in combat: initialization waits until combat ends and resumes successfully.

Record the exact build, class, group size, scenario, and first complete Lua error for each test run. Untested classes, raids, locales, and secure-action scenarios remain unverified. Do not label this release fully compatible until this checklist passes on the recorded build.

## API references

The reviewed source snapshot is `172a387e3ab85b26e6640d3058d5ec1e6ccd4c63` (build 70450); the installed target is build 70532, so API differences still require in-game verification. The port follows Blizzard's generated API documentation and secure templates mirrored on the `forever` branch of [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source/tree/forever): `UnitDocumentation`, `UnitAuraDocumentation`, `SpellBookDocumentation`, `SimpleFontStringAPIDocumentation`, `SimpleStatusBarAPIDocumentation`, `LuaCurveObjectAPIDocumentation`, and `SecureTemplates.lua`.
