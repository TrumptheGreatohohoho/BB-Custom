---
name: battle-brothers-skill-development
description: Analyze, design, port, implement, document, and validate Battle Brothers Squirrel skills and effects. Use for `.nut`/`.cnut` skill scripts, skill mods or ZIP archives, active/passive abilities, effects, cooldowns, targeting, damage callbacks, Mod Hooks compatibility, skill catalogs, save serialization, or BB-Custom curated-skill integration.
---

# Battle Brothers Skill Development

Build from the game and mod code that is actually present. Treat skill IDs, serialized fields, script paths, and resource paths as compatibility contracts.

## Route The Task

- **Inventory or report on a mod**: run `scripts/inventory_bb_skills.ps1`, classify player, AI, item, effect, and background scripts, then inspect behavior rather than trusting descriptions alone.
- **Port an existing skill**: identify the complete dependency closure before copying anything. Read `references/skill-patterns.md`.
- **Create a skill**: choose the narrowest callbacks and define targeting, costs, state, assets, persistence, and tests before implementation.
- **Change vanilla combat behavior**: decompile the current installed game script first. Never base a full-function override only on an old mod copy.

## Analyze

1. Locate the authoritative catalog or all call sites that instantiate skills.
2. Extract `ID`, type, costs, range, flags, callbacks, icons, and custom state.
3. Follow every `new(...)`, `add(...)`, `hasSkill(...)`, `removeByID(...)`, custom entity, projectile, item, sound, and particle reference.
4. Separate public skills from helper effects, AI behavior, item-granted skills, and debug sentinels.
5. Flag ID/path mismatches, duplicated catalogs, mutation while iterating, unchecked delayed targets, full vanilla overrides, and missing migration logic.
6. Report exact evidence with archive paths or local file/line references.

## Design Or Port

1. Assign a stable namespace:
   - active: `actives.<mod>_<name>`
   - passive/effect: `effects.<mod>_<name>`
   - persistent config: `effects.<mod>_<name>_config`
2. Keep one structured catalog as the authority for UI, grants, defaults, and documentation.
3. Put editable persistent values in a hidden serialized config skill. Make battle logic read that config.
4. Prefer original `skill` APIs and narrow Mod Hooks wrappers. Copy a complete vanilla function only when no narrower hook exists.
5. Package the full dependency closure, but do not add an entire source mod as a runtime dependency when a self-contained port is feasible.
6. Preserve friendly-fire, faction, corpse, tile, height, root, zone-of-control, and target-lifetime semantics explicitly.

## Validate

1. Compile changed `.nut` files with the bundled `bbsq.exe -e` using a disposable copy.
2. Verify IDs, paths, icons, effects, entities, and catalog entries.
3. Build and inspect the final ZIP, not only the source tree.
4. Test grant, use, cooldown, combat end, save/load, and old-save migration.
5. Exercise melee/ranged, ally/enemy, dead target, occupied tile, height, root, zone of control, and delayed-event cases relevant to the skill.
6. Inspect `Documents/Battle Brothers/log.html` for `Script Error`.
7. State clearly when in-game testing remains pending.

## Deployment Safety

- Write to Steam only when the user explicitly requests installation.
- Confirm `BattleBrothers.exe` is closed before installation.
- Never delete, overwrite, or modify an existing `.bbca-backup`.
- Do not modify unrelated translation or historical compatibility archives.

## Resources

- Read `references/skill-patterns.md` for callback selection, dependency closure, cooldown, serialization, and compatibility patterns.
- Run `scripts/inventory_bb_skills.ps1 -InputPath <mod.zip-or-folder>` for a deterministic JSON inventory.
