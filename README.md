# Battle Brothers Custom Appearance — portable package

This package installs and develops the Custom Appearance extension, curated
skills (Shadow Walk, Fire Grenade, Summon Zombie, `异常免疫`/`Aegis`, and
Hard Chance), and curated equipment for a Steam installation of Battle
Brothers. It contains no Chinese-translation packages or tooling.

**新机器接手请先读 [`START-HERE.md`](START-HERE.md)**（环境、安装、功能、铁律），再按
[`docs/README.md`](docs/README.md) 的顺序读取工程记忆。
完整换机步骤和可直接复制的起手对白见
[`NEW-MACHINE-START.md`](NEW-MACHINE-START.md)。

## First installation

1. Install Battle Brothers through Steam and launch it once normally.
2. Close the game completely.
3. Double-click `Install-Custom-Appearance-To-Steam.bat` and provide the Steam
   game folder when prompted.
4. Start the game normally, load a campaign, and press `Shift+X` to open
   Breditor. The Custom Appearance panel appears to its right.

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
- `mod_source` — Custom Appearance, curated skill, and curated equipment source.
- `tools` — build, import, manager, and installer scripts.
- `vendor` — exact Breditor and Mod Hooks runtime dependencies.
- `build/custom_appearance` — current installable output.
- `codex-skills` — portable Codex skills for future development and migration.

`mod_fantasybro` is not required for this package. Its selected female sprites
were copied into the asset repository during the original extraction.

The package also embeds the approved 0--100 hit-chance compatibility behavior.
Its current build and installation status are tracked in `docs/current-state.md`.

## Prerequisites

Windows, PowerShell 5.1 or later, and a normal Steam installation of Battle
Brothers are required. No Node.js installation is required for the appearance
workflow.
