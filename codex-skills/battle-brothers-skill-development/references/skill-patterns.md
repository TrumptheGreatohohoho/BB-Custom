# Battle Brothers Skill Patterns

## Contents

1. Skill class contract
2. Callback selection
3. Targeting and execution
4. Effects and dependency closure
5. Cooldown and persistence
6. Vanilla compatibility
7. Catalog and editor integration
8. Review checklist

## 1. Skill Class Contract

Typical skill:

```squirrel
this.example_skill <- this.inherit("scripts/skills/skill", {
    m = {},

    function create()
    {
        this.m.ID = "actives.example_skill";
        this.m.Name = "Example";
        this.m.Description = "...";
        this.m.Type = this.Const.SkillType.Active;
        this.m.IsSerialized = true;
        this.m.IsActive = true;
        this.m.IsTargeted = true;
        this.m.IsAttack = true;
        this.m.ActionPointCost = 4;
        this.m.FatigueCost = 20;
        this.m.MinRange = 1;
        this.m.MaxRange = 3;
    }
});
```

`ID`, script path, icon path, and serialized field order are compatibility surfaces. Do not rename them after release.

## 2. Callback Selection

| Callback | Use |
| --- | --- |
| `onUpdate(_properties)` | Persistent actor properties and equipment/state conditions |
| `onAnySkillUsed(...)` | Properties for one attack or skill execution |
| `onBeingAttacked(...)` | Defense changes conditional on attacker or incoming skill |
| `onTargetHit(...)` | Lifesteal, hit-triggered effects, body-part triggers |
| `onTargetKilled(...)` | Kill rewards |
| `onTurnStart()` | Cooldowns and turn counters |
| `onCombatStarted/Finished()` | Per-battle charges and reset/cleanup |
| `onVerifyTarget(...)` | Tile, faction, corpse, occupancy, or geometry constraints |
| `isUsable()` | Root, engagement, equipment, cooldown, and resource constraints |
| `isHidden()` | Equipment-dependent UI visibility |

Use the narrowest callback. Do not put one-attack damage changes in global `onUpdate`.

## 3. Targeting And Execution

- Reuse `attackEntity` for ordinary hit/damage/event behavior.
- Use `onAnySkillUsed` to set temporary damage, hit, head/body, and armor properties.
- Implement `onTargetSelected` whenever an area shape is not obvious.
- Revalidate delayed targets before applying effects.
- Pair `Container.setBusy(true)` with every success, failure, death, and cancellation path.
- For teleports, validate empty destination, height, root, zone of control, opportunity attacks, and target movement.
- State friendly-fire behavior in both code and tooltip.

## 4. Effects And Dependency Closure

For every candidate skill, search:

```text
new("scripts/...")
add(...)
hasSkill(...)
removeByID(...)
Const.ProjectileType
Tactical.spawnEntity
Time.scheduleEvent
gfx/
sounds/
```

Classify portability:

- **A**: one file, original callbacks only.
- **B**: skill plus icon, original effects/API.
- **C**: skill plus custom effects or paired state.
- **D**: custom entities, terrain, items, or world state.

Port A/B first. Treat C as an atomic dependency package. Develop D as a separate feature.

## 5. Cooldown And Persistence

Simple per-battle cooldown:

```squirrel
m = { Cooldown = 5, Skillcool = 5 }

function onUse(...) { this.m.Skillcool = 0; }
function onTurnStart() { this.m.Skillcool += 1; }
function isUsable() {
    return this.skill.isUsable() && this.m.Skillcool >= this.m.Cooldown;
}
function onCombatFinished() { this.m.Skillcool = this.m.Cooldown; }
```

For editable or save-persistent values:

1. Store them in a hidden serialized config skill.
2. Write an explicit serialization version.
3. Read new fields only when the serialized version contains them.
4. Supply defaults for older saves.
5. Document any user migration action.

## 6. Vanilla Compatibility

Game `data_00X.dat` files are ZIP archives. To inspect a current `.cnut`:

```powershell
bbsq.exe -d <file.cnut>
nutcracker.exe <file.cnut> > out.nut
```

Nutcracker output is UTF-16. When overriding a complete vanilla function:

- record the game version;
- preserve all non-target behavior;
- compare event payloads and new properties;
- inspect other archives that hook the same class;
- control registration order with `mods_queue` when required;
- re-audit after game updates.

## 7. Catalog And Editor Integration

Keep one catalog containing:

- ID and script path;
- type and display label;
- config ID and config script;
- editable parameters with default/min/max/type;
- icons and effects;
- serialization version and migration note.

Generate UI choices, grant behavior, and documentation from this catalog. Avoid copying file-name arrays across config and event scripts.

## 8. Review Checklist

- ID matches file/catalog and is unique.
- Active/passive type is explicit.
- Costs, range, cooldown, target rules, and tooltip agree.
- Dependencies and assets exist in the final ZIP.
- Delayed events handle dead/moved targets.
- Friendly fire is intentional.
- Custom fields survive save/load as intended.
- Old saves load with defaults.
- Full vanilla overrides match the installed game version.
- Runtime log has no script errors.
