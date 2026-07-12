Custom Appearance is an extension for Breditor.

The user-approved 0-100 hit-chance behavior is embedded in this mod at
scripts/!mods_preload/mod_bbca_hitchance_100or0.nut. Do not add its original
third-party archive as an additional runtime dependency.

Requirements:
- mod_hooks
- mod_breditor

Use:
1. Build mod_bb_custom_appearance.zip with tools\build_custom_appearance_pack.ps1.
2. Install it with tools\install_custom_appearance_pack.ps1 while the game is closed.
3. Start the game and load a campaign.
4. Open Breditor with its existing Shift+X shortcut.
5. Select a brother and use the Custom Appearance and curated skill panels in
   the lower-right area.

The custom image resources must be installed before starting the game.

Curated skills:
- Shadow Walk: active teleport skill with per-brother editable settings.
- Fire Grenade: non-consumable active skill that ignites a configurable area
  of up to 61 tiles. Its radius is editable from 0 to 4, and its settings are stored in
  effects.bbca_fire_grenade_config (serialization v2).
- Summon Zombie: summons an AI-controlled vanilla Armored Wiederganger on an
  empty nearby tile. Automatic resurrection is disabled; up to 3 are active by
  default, and all tactical summons disappear when combat ends. Settings are
  stored in effects.bbca_summon_zombie_config (serialization v1).
- 异常免疫: passive negative-effect immunity skill. It is hidden in battle by
  default, can optionally block a tier-3 Nachzehrer's Swallow Whole target
  validation, enable Stun Piercer for six vanilla stun attacks, and perform a
  passive counterattack against eligible adjacent attacks. Movement-triggered
  attacks of opportunity do not trigger this counterattack. Settings are stored
  in effects.bbca_negative_immunity_config (serialization v6).
- Hard Chance: passive final hit chance control. It can add a flat final hit
  bonus, subtract a flat final evasion bonus from incoming attacks, and clears
  current fatigue at turn start. Settings are stored in
  effects.bbca_hard_chance_config (serialization v1).

Curated equipment:
- 自愈圣饰链甲衫: uses the adorned mail shirt appearance, has 270 durability,
  restores 90 durability every turn, and is fully restored after combat.
- 自愈重型链甲头罩: uses the heavy mail coif appearance, has 270 durability,
  restores 90 durability every turn, and is fully restored after combat.
- Both items are indestructible and are available in Breditor under Legendary.
