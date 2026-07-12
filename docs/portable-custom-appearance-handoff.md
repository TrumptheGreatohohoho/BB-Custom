# Portable Custom Appearance handoff

## Scope

Maintain the Battle Brothers Custom Appearance extension and its curated skill
editor in this package. It manages transparent PNG assets, builds
`bb_custom_appearance.brush` and its atlas, applies body/head/hair/beard brushes
to a selected brother through the existing Breditor screen, and exposes bundled
curated skills through a separate right-side Breditor panel.

## Runtime dependency chain

`Shift+X` is supplied by Breditor (`mod_hx_breditor...zip` / `mod_breditor`).
Custom Appearance is an extension of that screen and needs Mod Hooks. Both
exact dependency archives are bundled under `vendor` and must remain
hash-identical to the values in `vendor/README.md` unless deliberately updated.

The female presets are self-contained in
`asset_repo/custom_appearance/sprites/presets/female`. FantasyBro is not a
runtime dependency of this package.

## Embedded 0--100 hit-chance behavior

The user-approved 0--100 hit-chance patch is embedded in
`mod_source/bb_custom_appearance/scripts/!mods_preload/mod_bbca_hitchance_100or0.nut`.
It ships inside `mod_bb_custom_appearance.zip`, so no separate third-party
archive is required at runtime. The implementation follows the current vanilla
`skill.attackEntity` and `skill.getHitchance` flows, changing only their 5--95
caps to 0--100. Its hook is registered through the Mod Hooks final queue.

An archive whose filename sorts after Mod Hooks' `~~finalize.nut` can still
register a later Hook and override the queued implementation. The known
historical archive with SHA-256
`4C53189CC73DD5BDEB8C30E7CFC41A337088F048F71F3ACDDE947B4A2A1256FB`
does exactly that. The standard installer calls
`tools/disable_known_legacy_hitchance_archive.ps1` to move that exact active ZIP
out of runtime loading while preserving it as `.bbca-backup`. It never
overwrites an existing backup and does not act on unknown hashes.

Because this behavior overrides complete vanilla functions, it is tied to the
game version recorded in `docs/current-state.md`. After a game update, extract
and decompile the new `scripts/skills/skill.cnut` before editing or reinstalling
this compatibility behavior. The current implementation must preserve vanilla
Shieldwall, diversion, event scheduling, and damage flow.

## Lone Wolf roster cap

`scripts/!mods_preload/mod_bbca_lone_wolf_roster_cap.nut` narrowly wraps vanilla
`scenarios/world/lone_wolf_scenario`. It first calls the original `onInit()` and
then sets `World.Assets.m.BrothersMax` and `BrothersMaxInCombat` to 16. This
raises both the Lone Wolf world-map roster and tactical deployment caps. It
does not change `BrothersScaleMax`, formation code, or enemy scaling. The
wrapper also updates the scenario-menu Elite Few description to state 16 men.

The asset manager invokes the origin's `onInit()` when creating a campaign and
again after deserializing an existing save, so the hook applies to new and
existing Lone Wolf campaigns without adding serialized fields. Keep the script
path and the narrow original-first wrapper unless the current game version's
scenario lifecycle is re-audited.

## Curated skill editor

The right-side `技能编辑器` panel has a skill catalog. It currently exposes
`Shadow Walk`, `燃烧手雷 (Fire Grenade)`,
`召唤装甲复生者 (Summon Zombie)`, `异常免疫`, and `Hard Chance`. The UI uses
`开启 / 关闭` toggles for boolean parameters and stores persistent per-brother
settings in hidden serialized configuration skills.

The original FantasyBro Shadow Walk implementation and its two icons were copied
into the package:

- `mod_source/bb_custom_appearance/scripts/skills/actives/sb_shadowwalk_skill.nut`
- `mod_source/bb_custom_appearance/gfx/ui/xx3.png`
- `mod_source/bb_custom_appearance/gfx/ui/xx3_sw.png`

Do not add FantasyBro itself as a runtime dependency. Parameters are stored in
the hidden, serialized `effects.bbca_shadowwalk_config` skill
(`scripts/skills/effects/bbca_shadowwalk_config_skill.nut`). The active skill
reads that configuration in battle so values persist across battles and saves.
After upgrading an existing campaign, select each brother who already has
Shadow Walk and press `保存参数` once to migrate their values.

`燃烧手雷 (Fire Grenade)` is a non-consumable active skill:

- skill: `scripts/skills/actives/bbca_fire_grenade_skill.nut`
- config: `scripts/skills/effects/bbca_fire_grenade_config_skill.nut`
- skill ID: `actives.bbca_fire_grenade`
- config ID: `effects.bbca_fire_grenade_config`

It reuses vanilla `skills/active_209.png`, `Const.ProjectileType.Bomb1`,
throw/fire-pot sounds, and `Tactical.State.spawnFireOnTile`; there is no custom
item, entity, effect, icon copy, money cost, or FantasyBro runtime dependency.
The target tile and all tiles within the configured radius are highlighted and
ignited. Radius is editable from 0 to 4 (default 2), yielding 1, 7, 19, 37, or
61 tiles at map interiors. Fire is immediate, persists for the configured
duration, respects vanilla fire immunity and non-flammable terrain, replaces
other tile effects, and intentionally harms friend and foe alike.

The delayed callback stores the selected tiles, player-applied flag, and
duration rather than an actor target or user reference. Target movement and
death therefore do not redirect the grenade; whoever occupies an affected tile
when the projectile lands is affected. Throwing causes no movement, ignores
zones of control, works while rooted, and does not use an item slot.

The hidden config is serialized at version 2 and stores AP, fatigue, minimum
and maximum range, maximum height difference, cooldown, fire duration, and
area radius. Version-1 configs load with radius 2; pressing `保存参数` writes
version 2. Future fields must increment the version and preserve v1/v2 defaults.

`召唤装甲复生者 (Summon Zombie)` is a D-class tactical entity skill:

- skill: `scripts/skills/actives/bbca_summon_zombie_skill.nut`
- config: `scripts/skills/effects/bbca_summon_zombie_config_skill.nut`
- skill ID: `actives.bbca_summon_zombie`
- config ID: `effects.bbca_summon_zombie_config`
- entity: vanilla `scripts/entity/tactical/enemies/zombie_yeoman`

It targets an empty visible tile, calls vanilla `Tactical.spawnEntity`, changes
the result to `Const.Faction.PlayerAnimals`, assigns vanilla random equipment,
sets `ResurrectionChance = 0`, and uses the vanilla zombie AI. Each caster
tracks living summons through direct script references. Cleanup first checks
that the reference exposes the actor API, then removes dead/dying entries by
building a replacement array rather than mutating while iterating. The default
maximum is 3 and is editable from 1 to 12.

The enabled/disabled icons are packaged at
`gfx/ui/bbca_summon_zombie.png` and
`gfx/ui/bbca_summon_zombie_sw.png`. They were copied from the FantasyBro
reference archive into this package; no FantasyBro script, mod ID, or archive
is required at runtime. Do not restore the earlier `active_26` icon/overlay
paths: the current game logs show that `gfx/skills/active_26.png` is not an
openable standalone asset.

Summons are tactical-only actors and never enter the player roster. The vanilla
zombie's `onBeforeCombatResult` drops its items when its faction is
`PlayerAnimals`; the tactical state then disposes the entity at battle end.
The skill also clears tracking on combat start/finish. A dead summon cannot
automatically resurrect, although an enemy necromancer may still raise its
corpse through normal corpse mechanics.

The v1 hidden config stores AP, fatigue, maximum range, maximum height
difference, cooldown, and maximum active summons. The active skill reads only
that config and uses stable defaults if it is absent.

`异常免疫` is a passive status/perk skill:

- skill: `scripts/skills/effects/bbca_negative_immunity_skill.nut`
- config: `scripts/skills/effects/bbca_negative_immunity_config_skill.nut`
- skill ID: `effects.bbca_negative_immunity`
- config ID: `effects.bbca_negative_immunity_config`

It defaults to hidden in battle (`ShowStatusIcon = false`) and applies selected
immunity flags in `onUpdate(_properties)`. Default enabled flags are poison,
bleeding, stun, daze, root/net, knockback/grab, and disarm. Stronger options
such as rotation immunity, fire immunity, headshot immunity, injury immunity,
`Overwhelmed` immunity, and `Distracted` immunity are exposed but default off.

The in-battle display name and tooltip lines are English (`Aegis`, "Immune to
Poison", …). The game's tactical tooltip font has no CJK glyphs, so Chinese
renders there as boxes; the Shift+X editor panel keeps Chinese because we control
its font (`Microsoft YaHei`). The editor dropdown label is `异常免疫 (Aegis)`.

`ImmuneToOverwhelmed` is special: the vanilla `effects.overwhelmed` is the debuff
applied by the `Overwhelm` perk (`perk.overwhelm`, via `onTargetHit`/`onTargetMissed`
when you strike an enemy that has not acted yet) — monsters with that perk apply it
too. It stacks `-10% Melee/Ranged Skill` per hit toward zero and has no vanilla
immunity property. It is neutralized by a hook in
`scripts/!mods_preload/mod_bbca_overwhelmed_immunity.nut` that, when the actor's
Aegis config has `ImmuneToOverwhelmed` on, skips `overwhelmed_effect.onUpdate`
(no stat loss, icon hidden) and `onRefresh` (no stacking).

`ImmuneToDistracted` is the same kind of hook. The vanilla `effects.distracted`
(the "dirty trick" debuff, `DamageTotalMult` and `InitiativeMult` ×0.65 for a
turn) also has no immunity property. `scripts/!mods_preload/mod_bbca_distracted_immunity.nut`
calls `removeSelf()` in `onAdded` when immune — mirroring the effect's own vanilla
resist path — and also neutralizes `onUpdate` as a safety net.

`ImmuneToSwallowWhole` blocks the tier-3 Nachzehrer's vanilla
`actives.swallow_whole`. The player is not given a swallowed effect: the
original skill immediately damages the target, removes it from the map, stores
it on the Nachzehrer skill, and adds `effects.swallowed_whole` to the
Nachzehrer. Therefore
`scripts/!mods_preload/mod_bbca_swallow_whole_immunity.nut` wraps the active
skill's real `onVerifyTarget` gate. Both AI target scoring and `skill.use()`
consult that gate before AP/fatigue and `onUse`, so an immune brother is not a
legal target. This hook intentionally does not affect `kraken_devour` and
cannot retroactively release a brother who was already swallowed.

The config skill's serialization is at version 6: `onDeserialize` reads
`ImmuneToOverwhelmed` only when `version >= 2` and `ImmuneToDistracted` only when
`version >= 3`; `ImmuneToSwallowWhole` is read only when `version >= 4`.
`StunPiercer` is read only when `version >= 5`, and `PassiveCounterattack` only
when `version >= 6`. Older saves keep those new options off. Existing brothers
must press `保存参数` once to write the current v6 configuration.

`StunPiercer` is implemented by the embedded hit-chance preload. It is limited
to six vanilla stun attacks and temporarily opens eligible hostile targets whose
hard stun immunity can safely be bypassed. It restores touched property objects
after the skill execution and excludes allies, dead/non-combatant targets,
Indomitable, and immovable targets.

`PassiveCounterattack` schedules the defender's vanilla attack-of-opportunity
through `actor.onRiposte` after an eligible adjacent incoming attack. It reuses
the vanilla counter guard/free-use path, rejects allied, ranged, dead, moved, or
riposte-ignoring cases, and revalidates both actors when the delayed event runs.
It also rejects attacks executed inside vanilla `actor.onAttackOfOpportunity`,
so moving beside or away from an enemy cannot turn that enemy's movement-triggered
attack into a free counterattack by the moving Aegis user. A narrow actor hook
registered with `mods_hookExactClass` provides only a synchronous execution-depth
marker; it adds no serialized state. Do not change this to `mods_hookClass`:
Mod Hooks 42 also invokes that API for direct child-class member tables, which do
not locally contain the inherited `onAttackOfOpportunity` function and will fail
during class registration before a campaign can load.

`Hard Chance` is a hidden passive/config pair:

- skill ID: `effects.bbca_hard_chance`
- config ID: `effects.bbca_hard_chance_config`
- serialization: v1

`HardHitChance` is added to the actor's final outgoing hit chance and
`HardEvasionChance` is subtracted from incoming final hit chance. A configured
100 is a hard outcome; absolute evasion wins if both sides are absolute. The
effect also clears current fatigue at turn start. Both numeric values are
clamped to 0–100 and the status icon is hidden by default.

## Curated regenerating equipment

Two standalone item classes are exposed through Breditor's existing
`Legendary` list via `::BBCA_EquipmentCatalog` and a narrow `prepareNI()` wrapper:

- `armor.body.bbca_regenerating_adorned_mail_shirt` at
  `scripts/items/armor/legendary/bbca_regenerating_adorned_mail_shirt`
- `armor.head.bbca_regenerating_heavy_mail_coif` at
  `scripts/items/helmets/legendary/bbca_regenerating_heavy_mail_coif`

They copy only the selected vanilla appearance contracts (body Variant 107;
helmet Variant 265, the blue-plumed `heraldic_mail_helmet` / Heraldic Bascinet,
with hair hidden and beard visible), not the source items' class identity. Both
have 270 durability, restore 90 at `onTurnStart`, fully
repair at `onCombatFinished`, set `IsIndestructible = true`, and call
`updateAppearance()` after durability changes. Their class paths and IDs are
save compatibility contracts and must remain stable.

## Installation and write-back

The only supported game write is the standard installer
`Install-Custom-Appearance-To-Steam.bat` or the manager's install action while
BattleBrothers.exe is closed. The user granted BB-Custom a standing deployment
authorization on 2026-07-12: after a scoped source change has passed its required
compilation, build, and final-ZIP checks, use that installer without waiting for
a separate installation request. The installer stages and verifies the patched
Breditor compatibility archive before it writes it, Mod Hooks, and the Custom
Appearance pack to the game's `data` directory. It then disables the exact known
conflicting legacy hit-chance archive if present.

Never delete, overwrite, copy over, or otherwise modify an existing
`.bbca-backup` file. Never install while the game is running.

## Chinese UI compatibility boundary

The user explicitly resumed the narrow Chinese UI compatibility work on
2026-07-12 after a Breditor replacement made the main menu black-screen.
`mod_source/bb_custom_appearance/ui/ui.js`, `world_names.js`, and
`bbca_cn_ui_compat.js` are authoritative for the required menu, world/tooltip,
and startup globals. `tools/patch_active_breditor_ui.ps1` writes all three into
the staged Breditor archive in the order `world_names.js` → `ui.js` → fallback
helper → `mod_hooks.js`. The helper must never override translations already
defined by the two complete resources. The installer asserts all three files,
their script tags, and their core translation functions before writing Steam.

The known historical `mod_bbca_all_in_one_cn_compat.zip` contains stale copies
of BBCA script paths and can override the authoritative component pack. The
standard installer calls `disable_known_legacy_bbca_all_in_one_archive.ps1`:
only the exact documented SHA-256 is renamed to `.bbca-disabled`; unknown files
are left untouched, and no `.bbca-backup` file is changed. This keeps the
runtime self-contained without reviving the one-off archive as a source authority.

This narrowly restores the existing Chinese UI's required globals. It does not
authorize a broader translation audit, translation build, or publication effort
without a new explicit user scope. Do not use workspace-clone launchers,
`steam_appid.txt`, ASCII `SUBST` paths, or Steam redirection workarounds.

The complete localization runtime is now the managed vendor archive
`vendor/data_bbca_fox_cn_runtime.zip`. It retains the fox translation's game
scripts and translated UI modules, but must never contain `!!redirect.nut`,
`~~finalize.nut`, `ui/mod_hooks.js`, or `ui/main.html`. Those four paths belong
to current Mod Hooks and the patched Breditor entry point. The standard Steam
installer validates this boundary and installs the runtime as
`data/data_bbca_fox_cn_runtime.zip`.

## Development workflow

The full workflow and validation matrix are maintained in
`docs/development-playbook.md`. At minimum:

1. Import or edit source under `asset_repo` or `mod_source`.
2. Compile changed Squirrel scripts where practical.
3. Build with `tools/build_custom_appearance_pack.ps1`.
4. Inspect the generated package if changing source behavior.
5. Install only after the user explicitly asks to update the game and the game
   is closed.
6. Update `docs/current-state.md` and append the change to
   `docs/engineering-log.md`.

The manifest is the asset catalog authority. Keep its brush IDs stable if they
may already be written to a saved brother.

## Machine state and history

Do not store changing install hashes or machine-specific claims in this
architecture document:

- Current game version, paths, hashes, installed files and pending tests:
  `docs/current-state.md`
- Historical fixes, evidence and decisions: `docs/engineering-log.md`
