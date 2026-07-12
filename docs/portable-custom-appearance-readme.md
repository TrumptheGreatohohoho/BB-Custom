# Battle Brothers Custom Appearance — portable package

This package installs and develops the Custom Appearance extension, curated
skill editor, and approved embedded compatibility behavior for a Steam
installation of Battle Brothers. It contains no Chinese-translation packages
or tooling.

## First installation

1. Install Battle Brothers through Steam and launch it once normally.
2. Close the game completely.
3. Double-click `Install-Custom-Appearance-To-Steam.bat` and provide the Steam
   game folder when prompted.
4. Start the game normally, load a campaign, and press `Shift+X` to open
   Breditor. The Custom Appearance and curated skill panels appear to its right.

The installer uses the bundled `vendor` archives, patches a staged Breditor
copy, verifies its UI/backend/resource entries, and then writes the three
required archives to the game's `data` directory. It never overwrites an
existing `.bbca-backup` file. It also disables the exact known legacy
hit-chance ZIP that conflicts with the embedded implementation, preserving the
original as a backup. Close the game before every installation.

## Add or change appearance assets

Run `Manage-Custom-Appearance-Assets.bat`. The manager imports a transparent
PNG into `asset_repo/custom_appearance`, updates `manifest.json`, and can build
and install the package. The source assets are the authority; the generated
`build/custom_appearance/mod_bb_custom_appearance.zip` is disposable.

Required image sizes are in `docs/png-asset-spec.md`.

## Package layout

- `asset_repo` — editable PNG assets and manifest.
- `mod_source` — Custom Appearance Squirrel/UI source.
- `tools` — build, import, manager, and installer scripts.
- `vendor` — exact Breditor and Mod Hooks runtime dependencies.
- `build/custom_appearance` — current installable output.

`mod_fantasybro` is not required for this package. Its selected female sprites
were copied into the asset repository during the original extraction.

The user-approved 0--100 hit-chance behavior is embedded in the Custom
Appearance archive. It is not installed as a separate third-party runtime
archive. The current build and deployment facts are tracked in
`docs/current-state.md`.

The curated skill panel can grant the bundled Shadow Walk,
`燃烧手雷 (Fire Grenade)`, and `召唤装甲复生者 (Summon Zombie)` active
skills, plus the `异常免疫` and Hard Chance passive skills.
Fire Grenade is not an item and does not consume equipment or money. Its
friendly-fire radius is configurable from 0 to 4.
Summon Zombie creates AI-controlled allied Armored Wiedergangers for the
current battle only; automatic resurrection is disabled and the per-caster
active limit is configurable.
`异常免疫` is hidden in battle by default and can be configured per brother,
including Swallow Whole immunity, Stun Piercer, and passive counterattack.
Movement-triggered attacks of opportunity do not trigger that counterattack.
Hard Chance controls final hit/evasion bonuses and resets current fatigue at
turn start.

Breditor's Legendary item list also exposes two standalone regenerating items:
`自愈圣饰链甲衫` and `自愈纹章尖顶盔`. Both have 270 durability, restore 90
durability per turn, fully repair after combat, and use stable custom item IDs.

## Prerequisites

Windows, PowerShell 5.1 or later, and a normal Steam installation of Battle
Brothers are required. No Node.js installation is required for the appearance
workflow.
