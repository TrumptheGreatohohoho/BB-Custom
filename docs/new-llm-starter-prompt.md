# New LLM conversation starter

```text
继续维护位于 <解压后的 BB-Custom 工程绝对路径> 的 Battle Brothers Custom Appearance
+ 技能编辑器工程。开始前完整读取：

0. START-HERE.md
1. docs/README.md
2. docs/current-state.md
3. docs/portable-custom-appearance-handoff.md
4. docs/development-playbook.md
5. docs/engineering-log.md

然后按 docs/README.md 读取任务相关文档。把 current-state.md 视为带日期的机器状态，
不要直接当作新电脑的 Steam 路径、游戏版本或安装状态。

Scope is strictly the Custom Appearance/Breditor feature: editable transparent
PNG assets, the brush/atlas build, the Breditor extension, and the curated
skill editor. Shift+X comes from the bundled Breditor dependency; the package
extends that screen.

Shadow Walk is self-contained: do not install FantasyBro as a runtime
dependency. Its persistent per-brother settings live in the hidden serialized
`effects.bbca_shadowwalk_config` skill. Existing brothers must press
`保存参数` once after an upgrade to create/migrate this configuration.

技能编辑器当前由唯一 `::BBCA_SkillCatalog` 提供五项：Shadow Walk、燃烧手雷、
召唤装甲复生者、异常免疫 Aegis 和 Hard Chance。燃烧手雷 config 为 v2，燃烧半径
0–4；召唤 config 为 v1，固定生成 AI 控制的 `zombie_yeoman`，默认每名施法者最多维持
3 个；Aegis config 为 v6，包含默认关闭的吞噬免疫、Stun Piercer 和被动反击；
Hard Chance config 为 v1。所有可调值写入隐藏、序列化、带版本号的 config skill。

`::BBCA_EquipmentCatalog` 通过 Breditor 的 Legendary 列表提供两件独立装备：
`armor.body.bbca_regenerating_adorned_mail_shirt` 与
`armor.head.bbca_regenerating_heavy_mail_coif`。两者固定 270 耐久、每回合恢复 90、
战后回满、不可损毁；Variant 107/237、ID 和脚本路径属于存档兼容接口。

独狼上限由
`scripts/!mods_preload/mod_bbca_lone_wolf_roster_cap.nut` 以 Mod Hooks 实现。
它先调用原版 `onInit()`，再把 `BrothersMax` 与 `BrothersMaxInCombat` 都设为 16；
不改 `BrothersScaleMax`。这意味着独狼总 roster 和可战术部署人数都是 16，敌方规模参数保持
原版。当前应优先人工验证角色界面显示、13--16 人部署、第 17 人拒绝、新/旧档与日志。

上一台电脑最后修复了召唤技能第二回合软锁：不要恢复 `weakref()` + `isNull()`；
当前实现保存直接实体引用并先检查 actor API。召唤技能图标已打包到
`gfx/ui/bbca_summon_zombie*.png`，不要恢复不存在的 `active_26.png`。源码、最终 ZIP
和安装哈希已校验，但该修复仍待新一轮游戏内第二回合/最高级食尸鬼/日志人工回归。

用户已明确恢复本次中文 UI 兼容。权威 helper 是
`mod_source/bb_custom_appearance/ui/bbca_cn_ui_compat.js`；Breditor staging
必须按 `world_names.js` → `bbca_cn_ui_compat.js` → `mod_hooks.js` 的顺序加载。
helper 为菜单、tooltip 与城镇翻译全局函数提供 fallback，以免函数未定义造成黑屏或世界地图
卡死。当前应优先人工验证主菜单、新战役、读档、大地图、城市、事件和 tooltip 后的
`log.html`。除这项兼容维护外，不扩展为通用汉化审计、翻译或发布工作，除非用户再次明确授权。
不要使用 clone launcher、steam_appid.txt、ASCII SUBST 路径或 Steam 重定向。

Do not write to the Steam game or modify Steam data unless I explicitly ask for
an appearance-feature installation. Before any such installation, confirm that
BattleBrothers.exe is closed. Never delete, overwrite, or modify any existing
.bbca-backup file.

Do not treat the old FantasyBro archive as a runtime dependency: the selected
female assets and the curated Shadow Walk source/icons are already in the
package. Do not include translation folders or old diagnostic test folders in
new portable releases.

The user-approved 0--100 hit-chance behavior is embedded in
`mod_source/bb_custom_appearance/scripts/!mods_preload/mod_bbca_hitchance_100or0.nut`.
It follows the currently verified vanilla attack flow and changes only the
5--95 caps to 0--100. It registers `mod_bbca_hitchance` through the Mod Hooks
final queue. A known historical standalone ZIP loads after that queue and
overrides it, so the installer disables only its exact known SHA-256 and
preserves the original as `.bbca-backup`. Never alter that backup. Check
current-state.md for the dated machine state.

If Battle Brothers has updated since the game version in current-state.md,
re-decompile the affected vanilla `.cnut` before changing any full-function
override.

换机后先只读核对工程包哈希、`build/custom_appearance`、便携工具和新电脑的
`data/data_001.dat`；报告差异并等待我的下一条指令。未经我明确要求不要安装。
```
