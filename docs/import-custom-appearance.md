# Import Custom Appearance PNGs

Use `tools/import_custom_appearance_asset.ps1` to add a source PNG to the asset repository and manifest.

For a local window that wraps the same workflow, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\open_custom_appearance_manager.ps1
```

The manager provides file selection, source preview, role selection, asset
listing, import, and an optional build-and-install action. The workspace entry
point is `Manage-Custom-Appearance-Assets.bat`; it opens the same manager after
prompting for the Steam game directory.

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\import_custom_appearance_asset.ps1 `
  -InputPath "C:\art\my_head.png" `
  -Role head `
  -Label "Custom head 02"
```

The importer:

- accepts `body`, `head`, `hair`, or `beard`;
- verifies PNG signature, required dimensions, and transparent background;
- assigns the next available `bbca_<role>_NN` ID unless `-Id` is supplied;
- copies `body` assets to `asset_repo/custom_appearance/sprites/bodies` and the other roles to `asset_repo/custom_appearance/sprites/heads`;
- copies positioning metadata from that role's validated sample; and
- updates `asset_repo/custom_appearance/manifest.json`.

The required source dimensions are currently fixed by the corresponding samples:

| Role | Required PNG dimensions |
| --- | --- |
| `head` | 50 × 68 |
| `hair` | 56 × 52 |
| `beard` | 48 × 42 |
| `body` | 78 × 58 |

Use printable ASCII labels only; the injected game UI has unreliable non-ASCII rendering.

Add `-Install` to build the brush/atlas pack and update the game installation after import. Battle Brothers must be closed when using `-Install`.

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\import_custom_appearance_asset.ps1 `
  -InputPath "C:\art\my_hair.png" `
  -Role hair `
  -Install
```

Use `-WhatIf` to validate an import without changing the asset repository.

Installing is never implicit when the manager closes. Use the manager's
build/install action, the importer's `-Install` switch, or the standard installer
after a successful build.
