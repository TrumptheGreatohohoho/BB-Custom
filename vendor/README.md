# Runtime dependencies

These two archives are private migration copies of the exact dependencies used by
the Custom Appearance package. They are deliberately kept separate from the
project's own source.

| File | SHA-256 |
| --- | --- |
| `mod_hx_breditor_VANILLA-294-4-31-1664773426.zip` | `CBA5E5AF9E7CD670C56FA1301BED84C123C2A35DB1067BE3445311DEB283779D` |
| `mod_hooks.zip-42-20-1-1621709174.zip` | `0461EA3F457A798E6AF2082ECBE6E058F5917E70F4487A1298160161B0A8D38C` |
| `data_bbca_fox_cn_runtime.zip` | `0EAF5F0B7B89BFB9C196B42930104B4181152524D51BCA37B6FF55F9780BB647` |

`mod_hx_breditor` provides the `Shift+X` Breditor screen. `mod_hooks` is its
loader dependency. `mod_fantasybro` is not a dependency of this package: the
female presets have already been copied into `asset_repo/custom_appearance`.

`data_bbca_fox_cn_runtime.zip` retains the complete Chinese game scripts and UI
modules from `data狐狸汉化+hooks 20260624_无需解压.zip`, but excludes its historical
Mod Hooks bootstrap files, `ui/mod_hooks.js`, and `ui/main.html`. Current Mod
Hooks and the patched Breditor archive remain authoritative for those paths.

Do not add `.bbca-backup` files here. The installer preserves any existing
backup and never overwrites one.
