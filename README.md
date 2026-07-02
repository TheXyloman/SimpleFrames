# SimpleFrames

Standalone Classic Anniversary TBC party and raid frames.

⚠️ **Note:** This project is currently a **work in progress** and not yet at final release status. Please use at your own discretion, and be aware that features, APIs, and behavior may change. Your feedback and contributions are welcome!

## Install

Copy the `SimpleFrames` folder into:

`World of Warcraft\_anniversary_\Interface\AddOns\SimpleFrames`

The addon TOC targets `## Interface: 20505`.

## Commands

- `/sfr`, `/sframes`, or `/simpleframes` opens the options panel.
- `/sfr lock` locks the frame position.
- `/sfr unlock` unlocks the frame position and shows the drag handle.
- `/sfr test party` shows the party preview.
- `/sfr test raid` shows the raid preview.
- `/sfr test off` turns preview off.
- `/sfr reset` restores defaults.
- `/sfr profiles` lists saved account-wide profiles.
- `/sfr profile save <name>` saves the current settings as a reusable profile.
- `/sfr profile load <name>` loads a saved profile on the current character.
- `/sfr profile delete <name>` deletes a saved profile.

`/sf` is used by some world-buff/Songflower addons. SimpleFrames only registers `/sf` if it is not already taken, so `/sfr` is the reliable short command.

## Notes

- Profiles are saved account-wide in `SimpleFramesProfilesDB`, while the active settings remain per-character in `SimpleFramesDB`.
- Middle click targets a real unit through secure frame attributes.
- Left and right clicks are intentionally unused.
- The minimap button opens options on left click, stops preview on right click, and can be dragged around the minimap.
- Layout and unit assignment changes are queued while in combat.
- Stun and silence detection is best-effort from visible auras and curated TBC spell IDs.
