# 工程记录

本文件按时间追加重要故障、设计决策和验证证据。当前部署事实以
`docs/current-state.md` 为准。

## 2026-07-12：停用覆盖 BBCA 脚本的一体包，并将世界名称资源纳入受管 Breditor（已安装）

- 用户验证新档和旧档的头盔外观均未改变。逐包检查证明当前组件包中的
  `bbca_regenerating_heavy_mail_coif` 是 Variant 265 并含读档刷新，但活动一体包在相同脚本路径
  保留 Variant 237；后加载资源覆盖了组件包，所以任何存档迁移都无法生效。
- 新增精确哈希迁移工具 `disable_known_legacy_bbca_all_in_one_archive.ps1`，并接入标准安装器。
  它仅处理已知 SHA-256 `1E75A631FA34A6D0760C661DEC41112A2BC29BBC1CCDDFB2F39D8A4827344750` 的
  `mod_bbca_all_in_one_cn_compat.zip`：将活动 ZIP 改名为 `.bbca-disabled`；未知包不处理，
  不触碰任何 `.bbca-backup`。
- 禁用一体包前发现 Breditor 的 `world_names.js` 标签依赖其运行时资源。将该完整资源一次性导入
  权威源 `mod_source/.../ui/world_names.js`（SHA-256
  `5BE6121B275A57ABCAB9A8F59B698B97C5DB318ADA09B94728F450AAEC083A5F`），更新 Breditor 暂存
  补丁和安装断言，确保资源及 `TranslateTooltips`、`TranslateTownScreenNames` 随 Breditor 部署。
- 隔离暂存和实际 Steam 验证均确认 world names → helper → Mod Hooks 顺序、完整资源和函数存在。
  一体包已不以 `.zip` 扩展名运行；当前唯一活动头盔脚本为 Variant 265 且含立绘刷新。
- 标准构建和安装通过，大小 `171540` 字节，SHA-256：
  `3CF4FCC07EFB5A0279CE2F57068BB1F396EB2F9DD09F6BA0A56250650809073C`。安装前后游戏未运行，
  4 个既有 `.bbca-backup` 哈希不变。待用户回归头盔外观、中文 UI 与日志。

## 2026-07-12：蓝羽头盔迁移后立即刷新已装备角色的立绘（已安装）

- 原版 `helmet.onDeserialize()` 读取 Variant 并调用 `updateVariant()`；进一步审计表明角色立绘
  的同步由独立的 `helmet.updateAppearance()` 完成，且该函数对未装备/无容器物品安全 no-op。
- 为避免用户必须手动卸下再装备，BBCA 头盔的 Variant 265 迁移在 `updateVariant()` 后追加
  `updateAppearance()`。不新增存档字段，也不改 ID、耐久、自愈或疲劳数值。
- 源码副本和最终 ZIP 内脚本通过 `bbsq.exe -e`；ZIP 有 34 条唯一路径，确认 Variant 265、
  原版 deserialize、迁移和 appearance 刷新均存在。构建大小 `171541` 字节，SHA-256：
  `477EB83C82460289026A0526CEE1C723487C9E5C0D96291AACCD15D8BF292EB5`。
- 按常设授权安装；Steam 包哈希与构建一致，安装前后游戏未运行，4 个既有 `.bbca-backup`
  哈希保持不变。待用户读档验证。

## 2026-07-12：将自愈头盔修正为蓝羽 Variant 265，并迁移已有装备（已安装）

- 用户提供原版目标图，确认需要的是蓝羽纹章尖顶盔；此前固定的 Variant 263 与目标不符，
  正确外观为 `heraldic_mail_helmet` 的 Variant 265。
- 用户游戏内仍看到旧造型，审计当前原版 `helmet.onDeserialize()` 后确认：它会从存档读回旧
  Variant 并执行 `updateVariant()`，故只改构造函数不能更新已拥有的自愈头盔。
- 自定义头盔改为 Variant 265，并添加窄 `onDeserialize()` 包装：先调用
  `this.helmet.onDeserialize(_in)` 保留原版存档/耐久流程，再固定 Variant 265 并刷新 Variant。
  不新增序列化字段，不改稳定 ID、270 耐久、每回合恢复 90、战后回满或疲劳 -10。
- 源码副本和最终 ZIP 内脚本通过 `bbsq.exe -e`；标准构建通过。ZIP 有 34 条唯一路径，头盔脚本
  恰一份，含 Variant 265、迁移与原版 deserialize 调用。构建大小 `171540` 字节，SHA-256：
  `C3DD29CBF39C37FFF2DDCC78DBFB5766BC42C0061C5D5A267D00C85962EAD634`。
- 按常设部署授权通过标准安装器部署。安装前后游戏未运行，Steam 包哈希与构建一致，4 个既有
  `.bbca-backup` 哈希保持不变。待用户回归已有装备读档后的蓝羽外观与正常自愈行为。

## 2026-07-12：自愈头盔改用红装纹章尖顶盔外观（已构建并安装）

- 用户要求将新增的自愈头盔由重型链甲头罩外观改为“纹章尖顶盔”红装外观。
- 反编译当前原版 `named/heraldic_mail_helmet.cnut`，确认其红装外观 Variant 为 262--266。
  通过原版 inventory 图标核对后，固定选择红羽 Variant 263。
- 只修改自定义头盔的显示名、说明和 `Variant`（237 → 263）；稳定类路径、ID、270 耐久、
  每回合恢复 90、战后回满、不可损毁与疲劳 -10 均未变，不涉及序列化迁移。
- 源码副本和最终 ZIP 副本通过 `bbsq.exe -e`；标准构建通过。ZIP 内头盔脚本恰一份，含
  Variant 263、不含 237，且 ID/耐久/自愈断言通过；34 条路径无重复。构建大小 `171427` 字节，
  SHA-256：`40CC4F6E6E93E89822651F026B4EF594F6A35451CE6093E05B3E45F257D2B41E`。
- 用户明确授权后通过标准安装器部署。安装前后 `BattleBrothers.exe` 均未运行；Steam 组件包
  与构建 SHA-256 一致，包内 Variant 263、稳定 ID 与自愈逻辑均核对通过，4 个既有
  `.bbca-backup` 哈希保持不变。待游戏内外观/自愈/存读档回归。

## 2026-07-12：后续修改的常设 Steam 部署授权

- 用户明确改变原部署规则：本工程未来完成源码修改、所需 `.nut` 编译、标准构建和最终 ZIP
  核验后，直接通过标准安装器写入 Steam，无需再次等待单独指令。
- 此授权不放宽安全边界：每次安装前仍须确认 `BattleBrothers.exe` 已关闭；绝不删除、覆盖、
  移动或修改任何 `.bbca-backup`；不手工复制或修改未受管的 Steam 第三方包。

## 2026-07-12：修复被动反击 Hook 导致战术类未注册和读档崩溃（已安装）

- 初版移动过滤构建安装后，用户载入 `Battle Brothers_14077` 时收到 class key
  `7598820860669657090` 未注册与 `world_state.loadCampaign()` 崩溃。
- 最新日志在载入存档前已经有 87 个 error 行：42 次直接报
  `the index 'onAttackOfOpportunity' does not exist`，其余主要是 `warwolf`、`human`、
  多种敌人与战术对象脚本执行失败；之后 `player.nut` 才连锁缺少 `IsControlledByPlayer` 和
  `human`。因此不是先把正常存档判为损坏，而是新 Hook 让大量类在预载阶段未完成注册。
- 根因是 `mods_hookClass("entity/tactical/actor", ...)` 的 Mod Hooks 42 语义：除 actor 自身
  new-object Hook 外，还对直接子类执行继承 Hook。子类 `newMembers` 表不自带继承来的
  `onAttackOfOpportunity` 索引，初版的直接成员读取当场失败。
- 改用 `mods_hookExactClass("entity/tactical/actor", ...)`，只在 actor 类通过 `inherit()` 创建
  时包装其本地函数，不向派生类重复应用。临时移动攻击上下文、异常清理与 Aegis 判定不变，
  未改配置字段或序列化版本。
- 修复后的源码副本和最终 ZIP Hook 均通过 `bbsq.exe -e`；标准构建通过。最终 ZIP 有 34 条
  唯一路径，exact-class Hook 恰一份且不含旧的 actor `mods_hookClass`。大小 `171430` 字节，
  SHA-256：`F2F36E792E6E4C79C4713701B7A7AA4F8FD336101FDB1BA5C7F998F56C5CA003`。
- 用户再次明确授权后通过标准安装器部署修复构建。安装前后 `BattleBrothers.exe` 均未运行；
  Steam 组件包 SHA-256 与修复构建一致，Hook 恰一份且确认使用 exact-class API。4 个既有
  `.bbca-backup` 哈希均保持不变。仍需验证同一存档、启动日志与反击行为。

## 2026-07-12：被动反击不再响应移动触发的借机攻击（已构建并安装）

- 用户确认当前漏洞：带 `PassiveCounterattack` 的角色贴着敌人移动时，敌人的控制区借机攻击
  会反过来触发角色的免费反击，从而可通过绕敌移动主动刷出攻击。
- 反编译当前游戏 `1.5.2.3` 的 `actor.cnut`、`skill.cnut`、`skill_container.cnut` 和
  `riposte.cnut` 后确认，`actor.onAttackOfOpportunity()` 复用攻击者普通的
  `getAttackOfOpportunity()` 技能并执行 `useForFree()`；技能对象本身没有“由移动触发”标记。
- 新增 `mod_bbca_passive_counterattack.nut`，窄包装原版 `onAttackOfOpportunity()`，仅在同步
  调用范围设置全局执行深度。正常返回和异常重抛路径都会清理标记。Aegis 技能在安排反击前
  检查该上下文；上下文存在时退出，普通攻击路径不受影响。
- 未改 `PassiveCounterattack` 字段、配置顺序或序列化版本，Aegis 继续使用 v6。
- 新 Hook、Aegis skill 与 catalog preload 的源码副本编译通过；标准构建和最终 ZIP 内三份
  脚本二次编译通过。最终 ZIP 有 34 条唯一路径，新 Hook 恰一份，大小 `171266` 字节，
  SHA-256：`A53943F761ACF52EF9153255F5BC9CAFE676E166273B3C3DD14D09ACC5D0DA6D`。
- 用户明确授权后通过标准安装器部署。安装前后 `BattleBrothers.exe` 均未运行；Steam
  `data\mod_bb_custom_appearance.zip` 与构建包 SHA-256 一致。Steam 包内新 Hook 与 Aegis
  skill 各恰有一份并包含过滤逻辑；Breditor 的中文 UI helper 和三段加载顺序也经安装后检查
  仍正确。4 个既有 `.bbca-backup` 均保留，已知旧命中率活动 ZIP 仍不存在。
- 仍需游戏内验证移动借机攻击不触发反击、普通相邻攻击仍触发，以及新日志无错误。

## 2026-07-12：将独狼战术部署上限同步提高到 16（已安装）

- 用户截图中角色界面仍显示 `12/12`。审计当前 `character_screen.nut` 发现该 UI 调用的是
  `World.Assets.getBrothersMaxInCombat()`，而不是独狼 Hook 原先已经设为 16 的
  `BrothersMax`；此前实现只扩大 roster，未扩大可部署人数。
- 用户确认其“队伍人数 16”需求后，Hook 在保留原版 `onInit()` 调用的基础上，同时设置
  `BrothersMax = 16` 和 `BrothersMaxInCombat = 16`。原版编队逻辑允许至少 18 个位置；保持
  `BrothersScaleMax` 不变，避免无授权扩大敌方规模。
- 源码与最终 ZIP 副本的 `bbsq.exe -e` 均通过；标准构建包大小 `170326` 字节，SHA-256：
  `5E3C6838F0677FA18534CEC844D3B1FE28EF48F291C120C2AF60A388969D2C25`。
  游戏关闭时经标准安装器部署，Steam 组件包哈希与构建一致，两个 16 人字段均存在，4 个既有
  `.bbca-backup` 未修改。待人工验证第 13--16 人的部署与战斗。

## 2026-07-12：修复独狼进入世界地图后的中文 UI 卡死（已安装）

- 首轮菜单修复后，用户可新建独狼并看到大地图，但 09:44 日志连续报
  `TranslateTooltips` 未定义，09:45 世界事件 UI 报 `TranslateTownScreenNames` 未定义。调用栈
  仅在 tooltip/world-event JavaScript，不涉及独狼 Hook。
- 一体兼容包保有完整 `ui/world_names.js`（含世界实体、城镇、区域与 tooltip 翻译函数）。更新
  Breditor 补丁，在现有 `bbca_cn_ui_compat.js` 前加载 `world_names.js`；helper 以
  `typeof TranslateAllWorldNames === "undefined"` 防护并定义全部 world/tooltip 函数的 no-op
  fallback。完整中文资源可用时不会覆盖其实现，资源缺失时也不会再因未定义函数卡死。
- 临时 Breditor archive 验证三段顺序 `world_names.js` → helper → Mod Hooks 以及两个 fallback
  通过。标准构建组件包大小 `170334` 字节，SHA-256：
  `D311CDA987B86464325C47FBE08A02D337F720984BD74F26B47A938C6AC6D126`。
- 用户已授权后通过标准安装器部署；安装前后游戏关闭，Steam 组件包哈希一致，Breditor 实际包
  的 tag 顺序和 helper 内容均已核对，一体包的 world-name 资源存在，4 个既有 `.bbca-backup`
  未修改。待用户回归世界地图、城镇、事件、tooltip 和读档。

## 2026-07-12：恢复中文 UI 兼容并修复主菜单黑屏（已安装）

- 09:27 启动日志确认 Custom Appearance、命中率 Hook、Breditor 与 Mod Hooks 均注册成功，
  没有独狼 Hook 报错；09:27:22 首先报 `TranslateDialog`、随后报 `TranslateButtons` 未定义，
  并连锁造成新战役菜单的 DOM 成员为空。
- 当前 Breditor 包与其 `.bbca-backup` 都不定义这两个全局函数；既有
  `mod_bbca_all_in_one_cn_compat.zip` 的 `ui/ui.js` 有完整的既有实现。用户明确授权
  “恢复汉化”后，将最小的四个启动相关全局函数回写到权威源文件
  `mod_source/bb_custom_appearance/ui/bbca_cn_ui_compat.js`，不再依赖一体运行包的主页面加载顺序。
- `patch_active_breditor_ui.ps1` 现将 helper 写到 staged Breditor archive，并在
  `mod_hooks.js` 前加入 script tag；`install_steam_breditor_compat.ps1` 对 helper 文件、tag、
  `TranslateDialog` 与 `TranslateButtons` 作 staging 断言。临时 archive 验证通过。
- 标准构建后组件包大小 `170075` 字节，SHA-256：
  `C47A03586B1AD8D945F74231A57A08ACF863E8699756EFCB1AB9599F0385196B`。
  用户授权后经标准安装器部署；安装前后游戏未运行，Steam 组件包哈希一致，Steam Breditor
  包确认 helper 存在且在 Mod Hooks 前加载，既有 4 个 `.bbca-backup` 未修改。
- 仍待游戏内验证主菜单、读档与进入世界地图均无 `Translate*` UI 错误。

## 2026-07-12：以 Mod Hooks 将独狼总 roster 上限改为 16（已安装）

- 反编译本机游戏 `1.5.2.3` 的
  `scripts/scenarios/world/lone_wolf_scenario.cnut`，确认独狼限制只有
  `onInit()` 中的 `World.Assets.m.BrothersMax = 12`；原版默认总 roster 是 20，单场部署
  `BrothersMaxInCombat` 为 12。
- 新增 `scripts/!mods_preload/mod_bbca_lone_wolf_roster_cap.nut`，通过
  `mods_hookClass("scenarios/world/lone_wolf_scenario", ...)` 包装 `create()` 与 `onInit()`：
  保留原版调用后把总上限设为 16，并将 Elite Few 菜单文案同步为 16 人。没有复制完整原版类，
  也没有改动 Steam `data_001.dat`。
- 审计当前活动一体包，没有既有的 16 人补丁或同类 Hook 冲突。`asset_manager.onDeserialize()`
  在读档结束时调用 origin 的 `onInit()`，因此现有独狼存档也会在加载模组后重设到 16；不需要
  新序列化字段或迁移操作。
- 新脚本的 `bbsq.exe -e` 编译副本、标准构建和最终 ZIP 内的二次编译均通过。最终组件 ZIP
  大小 `168647` 字节，SHA-256：
  `12B327A51B00C77FFF652DFF6A0BC9B929D165D6CC1FA95D04E2443103B0DE5C`。
- 用户明确授权后通过标准安装器部署。安装前后 `BattleBrothers.exe` 均未运行；Steam
  `data\mod_bb_custom_appearance.zip` 与构建包 SHA-256 一致，包内恰有一份独狼 Hook，确认
  为 16 人且未改 `BrothersMaxInCombat`。Breditor 与 Mod Hooks 档案均存在，Steam `data\`
  的既有 `.bbca-backup` 数量仍为 4。
- 待游戏内验证新档/旧档的 16 人上限、第 17 人拒绝、战术仍为 12 人、存读档及 `log.html`。

## 2026-07-12：把活动一体包的后续改动回写工程源码

- 用户确认 `D:\project\BB-Custom` 才是长期工程权威。此前 7 月初直接修改 Steam
  `mod_bbca_all_in_one_cn_compat.zip` 的做法停止；运行 ZIP 今后只作为构建/部署产物。
- 对比工程 `mod_source/bb_custom_appearance` 与当前活动一体包，发现 8 个已有文件落后，
  并缺少 Hard Chance 两个脚本。选择性同步了 Hard Chance、Stun Piercer、Aegis v6/
  被动反击、召唤容量/实体失效防护和技能数字输入修复；保留源码的
  `// __BBCA_CATALOG__` 构建占位符。
- 新增独立装备 `armor.body.bbca_regenerating_adorned_mail_shirt` 与
  `armor.head.bbca_regenerating_heavy_mail_coif`。它们只复用圣饰链甲衫 Variant 107 和
  重型链甲头罩 Variant 237 的外观契约，固定 270 耐久、每回合恢复 90、战后回满、
  不可损毁，不修改原版装备类。
- 新增唯一 `::BBCA_EquipmentCatalog`，通过包装 Breditor 后端 `prepareNI()` 把两件装备
  加入现有 `Legendary` 列表。未复制或完整覆盖 Breditor 主函数。
- 工程自带 `bbsq.exe -e` 编译通过 9 个关键脚本：生成后的 catalog preload、命中率/
  眩晕穿透 Hook、召唤、Aegis skill/config、Hard Chance skill/config 和两件装备。
- 标准 `tools/build_custom_appearance_pack.ps1` 构建通过。组件包大小 `167866` 字节，
  SHA-256：`EAE9EB9F6343BB603A4E4C09229AE7B36482511E618E04ED72640D340809054F`。
- 本次没有再次写入 Steam；当前活动一体包已包含同样功能。Breditor 生成、装备、回耐久、
  战后回满、保存/读档和日志仍待人工游戏回归。

## 2026-06-28：制作跨电脑工程交接包

- 新增根入口 `NEW-MACHINE-START.md` 和可重复脚本
  `tools/build_engineering_handoff.ps1`；更新通用/新技能起手提示到当前四技能状态、
  Aegis v4、召唤软锁修复及待人工回归边界。
- 工程交接包包含源码资产、模组源码、文档、构建/安装工具、便携 `bbsq` 工具链、
  固定 vendor 依赖、便携 Codex skill、当前可安装游戏包、图鉴报告和 FantasyBro
  源码参考档案。参考档案仅用于分析，不是运行时依赖。
- 打包脚本只从 `build` 收集
  `build/custom_appearance/mod_bb_custom_appearance.zip`；不收集 Steam 文件、存档、
  日志、汉化包、`analysis_shieldwall_bug`、`reference_analysis`、安装 staging、
  `.bbca-backup` 或 `.bbca-disabled`。
- 为换机重新构建当前游戏包，大小仍为 `159362` 字节，新外层 SHA-256：
  `09C7D98921F9D315FA7E1B02FE444E19C1E247E6D751A303ACE0C48C7F8961BE`。
  与旧电脑 Steam 安装包比较 23 个文件的逐项 SHA-256，内容差异为 0；外层 ZIP
  哈希变化仅由重新打包元数据产生。本次未写入 Steam。
- 工程交接 ZIP 自带 `HANDOFF-MANIFEST.txt`、逐文件
  `HANDOFF-SHA256SUMS.txt`，并在 ZIP 旁生成总包 `.sha256`；总包哈希以该 sidecar 为准，
  避免把外层哈希写入包内形成自引用。

## 2026-06-28：修复召唤技能第二回合软锁与缺失图标（已构建并安装）

- 实际 `log.html` 时间线显示：召唤于 14:54:27 成功；最高级食尸鬼在
  14:54:32–14:54:36 正常行动；14:54:38 进入第二回合，14:54:39 轮到施法者 Zoe 时
  抛出 `the index 'isNull' does not exist`。
- 栈顶为 `bbca_refreshSummonedEntities` 第 99 行，随后是召唤技能 `onTurnStart`、
  `skill_container.onTurnStart` 和回合序列；错误对象为 `Table`。因此软锁根因是召唤技能，
  不是 Aegis 吞噬免疫 Hook。
- 根因是将实体保存为 `weakref()` 后又假定该对象存在 `isNull()`。现改为保存直接脚本引用；
  清理时先检查非空和 `isAlive` 成员，再调用 `isAlive()`，仅在存在 `isDying` 时调用，
  并继续以新数组替换旧数组，避免遍历中修改。
- 同一日志还重复报告无法打开 `gfx/skills/active_26.png`。这不是软锁原因，但原版敌方
  `raise_undead` 的脚本路径并非可复用的实际文件。现打包独立的启用/禁用图标
  `gfx/ui/bbca_summon_zombie.png` 与 `gfx/ui/bbca_summon_zombie_sw.png`（56×56），
  删除 `active_26` overlay。图像仅从 FantasyBro 参考包提取为本包资产，不产生运行时依赖。
- 修改后的主动技能和 catalog preload 编译副本通过；最终 ZIP 内脚本二次编译通过。
  包内断言确认直接引用和成员检查存在，`isNull()`、`weakref()`、`active_26`、
  FantasyBro 脚本/路径引用均不存在；两个图标、v1 config、实体、阵营和禁止复活逻辑齐全。
- 最终 ZIP 大小 `159362` 字节，SHA-256：
  `3F85FDC5033273E4FA6A744447D835A24D84C3A350BC386DF739A635E04DD2C3`。
- 安装前确认 `BattleBrothers.exe` 未运行；Steam 根
  `data\mod_bb_custom_appearance.zip` 与构建包哈希一致。`data\mod\` 的旧镜像保持不动，
  不作为当前加载分支或源码权威。
- 安装前后均有 4 个既存 `.bbca-backup`；安装器对已存在备份不会进入创建分支。
  已知旧命中率备份仍为
  `4C53189CC73DD5BDEB8C30E7CFC41A337088F048F71F3ACDDE947B4A2A1256FB`，
  对应活动 ZIP 仍不存在。
- 游戏内第二回合、召唤物死亡释放名额、同场最高级食尸鬼、图标加载及新日志仍待人工回归。

## 2026-06-28：新增装甲复生者召唤技能（D 级，已构建并安装）

- 审计当前原版 12 个 `zombie*.cnut`：4 个适合通用召唤的实体为普通复生者
  `zombie`、装甲复生者 `zombie_yeoman`、南方装甲复生者 `zombie_nomad` 和堕落英雄
  `zombie_knight`；其余是玩家尸体、剧情/Boss 或护卫 AI 变体。
- 用户选择固定召唤 `zombie_yeoman`、AI 控制、禁止自动复活；默认每名施法者最多维持
  3 个，最大数量作为 1–12 的可调参数。
- 新增 `actives.bbca_summon_zombie` 和 v1
  `effects.bbca_summon_zombie_config`。默认 6 AP、25 疲劳、范围 3、高度差 1、
  冷却 5、最大数量 3。
- 复用原版 `Tactical.spawnEntity`、`PlayerAnimals` 阵营、`zombie_agent`、
  `assignRandomEquipment`、`active_26` brush、死灵法师声音和复活粒子；无自定义实体、
  图标、声音或 FantasyBro 运行时依赖。
- 每个技能实例维护召唤实体弱引用并先构建新数组再替换，避免遍历时修改；死亡/失效实体
  不计入上限。战斗开始/结束清空引用，召唤实体不进入 roster。
- 设置 `ResurrectionChance = 0` 禁止原版 66% 自动复活。尸体仍可被敌方死灵法师按原版
  机制复活，这是“禁止自动复活”与“尸体完全不可复活”的明确边界。
- 修改的主动技能、配置和 catalog preload 编译副本通过；标准构建和最终 ZIP 内再编译通过。
  包内 ID、实体路径、PlayerAnimals 阵营、自动复活关闭、默认/可调数量、战斗清理和原版
  依赖断言通过。
- 最终 ZIP 大小 `143235` 字节，SHA-256：
  `4E372F13006F84A185BC091C75BF16DC6CEB34A30C2816F7DFB673531F1BFF6D`。
- 用户明确授权后已通过标准安装器部署。安装前后 `BattleBrothers.exe` 均未运行。
- Steam 安装包与构建包 SHA-256 一致；包内召唤技能、v1 config、装甲复生者实体路径、
  `PlayerAnimals` 阵营、禁止自动复活及 catalog 选项校验通过。
- 已知旧命中率活动 ZIP 仍不存在；历史 `.bbca-backup` 保持原 SHA-256。
- 游戏内召唤、AI、数量限制、死亡释放名额、战后清理和日志仍待人工回归。

## 2026-06-28：Aegis 新增最高级食尸鬼吞噬免疫（v4，已构建并安装）

- 从当前游戏 `1.5.2.3` 的 `data_001.dat` 重新反编译并审计：
  `skills/actives/swallow_whole_skill.cnut`、
  `skills/effects/swallowed_whole_effect.cnut`、
  `ai/tactical/behaviors/ai_attack_swallow_whole.cnut`、
  `entity/tactical/enemies/ghoul.cnut` 与 `ghoul_high.cnut`。
- 原版 `actives.swallow_whole` 仅在食尸鬼尺寸为 3 时可用。其 `onUse` 会立即移除目标的
  盾墙/矛墙/还击、将士气改为崩溃、造成 10–20 生命损失（最低保留 5）、设置
  `Devoured` flag 并把角色移出地图；`effects.swallowed_whole` 实际加在食尸鬼身上。
- 当前原版 `skill.use()` 在扣 AP/疲劳和调用 `onUse` 前再次调用 `onVerifyTarget`；
  食尸鬼 AI 的 `getBestTarget` 也调用同一函数。因此新增
  `mod_bbca_swallow_whole_immunity.nut`，只包装该真实合法目标门槛，不复制完整原版函数。
- 新字段 `ImmuneToSwallowWhole` 默认关闭，并加入 Aegis tooltip 与唯一
  `::BBCA_SkillCatalog`。作用域只含 `actives.swallow_whole`，不影响 `kraken_devour`。
- Aegis config 从 v3 升到 v4，新布尔字段追加在 v3 字段之后；v1–v3 读取时保留默认关闭，
  保存参数后写入 v4。
- 修改的四个 `.nut` 编译副本通过；标准构建及最终 ZIP 内再编译通过。最终 ZIP 大小
  `140206` 字节，SHA-256：
  `08463D5B2ED80B067C92E510B3705B3509BEC1DFB09F5A36BC88A199C1757246`。
- 包内 Hook 路径、原函数先行调用、v4 写入、v1–v3 默认值、catalog 开关和不包含 Kraken
  引用的断言通过。
- 已随 SHA-256
  `4E372F13006F84A185BC091C75BF16DC6CEB34A30C2816F7DFB673531F1BFF6D`
  的当前构建安装；包内 Hook、Aegis v4 config 和 catalog 开关校验通过。
- 游戏内开关关闭/开启、AI 改选目标、全员免疫和日志仍待人工回归。

## 2026-06-28：燃烧半径改为可调（v2，已构建并安装）

- `::BBCA_SkillCatalog` 新增整数参数 `AreaRadius`，编辑器标签“燃烧半径”，范围 0–4、
  默认 2；0–4 在完整地图内分别覆盖 1、7、19、37、61 格。
- `actives.bbca_fire_grenade` 的范围预览、tooltip 和实际延迟落地格集合统一读取
  `effects.bbca_fire_grenade_config.m.AreaRadius`，不再读取固定半径。
- 配置序列化从 v1 升到 v2，新字段追加在 v1 字段之后；`version < 2` 时保留类默认值 2，
  因此旧角色无需预处理即可读档，逐人点击“保存参数”后写入 v2。
- 主动技能、配置和 preload 的 `bbsq.exe -e` 编译副本通过。
- 标准构建及最终 ZIP 内脚本再编译通过；包内动态半径、v2 写入、v1 读取分支和 catalog
  参数断言通过。
- 新构建大小 `139319` 字节，SHA-256：
  `7BEBD8870E6B0C4D7F0038FB1AE6FF20ADE554F118ABAF3A62B5FAB9786E6F19`。
- 用户明确授权后已通过标准安装器部署。安装前后 `BattleBrothers.exe` 均未运行。
- Steam 安装包与构建包 SHA-256 一致；包内动态半径、v2 写入、v1 读取分支和 catalog
  “燃烧半径”参数校验通过。
- 已知旧命中率活动 ZIP 仍不存在；历史
  `狐狸汉化适配-命中率改为0-100.zip.bbca-backup` 保持原 SHA-256
  `4C53189CC73DD5BDEB8C30E7CFC41A337088F048F71F3ACDDE947B4A2A1256FB`。
- 游戏内半径 0/1/2/3/4 的预览与实际落地区域、参数保存/读档及 `log.html` 仍待人工回归。

## 2026-06-28：新增并安装燃烧手雷技能

- 新增主动技能 `actives.bbca_fire_grenade`：
  `scripts/skills/actives/bbca_fire_grenade_skill.nut`。
- 新增隐藏配置 `effects.bbca_fire_grenade_config`：
  `scripts/skills/effects/bbca_fire_grenade_config_skill.nut`，序列化 v1。
- 唯一 `::BBCA_SkillCatalog` 新增 `燃烧手雷 (Fire Grenade)`，包含 ID、路径、类型、
  图标、原版 effect 依赖、序列化版本、迁移说明及 7 个可调参数；UI 与授予后端继续从
  同一 catalog 生成下拉菜单和参数表单。
- 固定半径 2（最多 19 格）、固定友伤；默认 6 AP、35 疲劳、投掷距离 2--4、
  高度差 1、冷却 7、火焰持续 2 回合。
- 复用当前原版 `throw_fire_bomb_skill` 的图标、`Bomb1` 投射物、声音及
  `Tactical.State.spawnFireOnTile`。没有物品、副手卸除、金钱、自定义实体或
  FantasyBro 运行时依赖。
- 延迟事件不保存施法者或目标 actor 引用，只保存目标格集合、阵营标记和持续时间；
  目标移动/死亡不改变落点，回调执行时的当前占用者承受火焰。
- 编辑器后端调整为：存在 config 时仅写 config，不再把参数重复写入战斗技能；新授予技能
  按用户选择的冷却值初始化为可用。源码 Hook 与临时 Breditor 补丁模板同步。

验证：

- 主动技能、配置和 preload 脚本的 `bbsq.exe -e` 编译副本通过。
- 标准构建通过；最终 ZIP 大小 `139190` 字节，SHA-256：
  `E5C87A96F3FA1EE77169831083E4B3A449D30B3F832C48ED23C09746ED6C5006`。
- 最终 ZIP 的技能/配置/catalog 路径、唯一 ID、v1 版本、半径、原版火焰调用、
  无物品/金钱/FantasyBro 依赖断言通过。
- 在临时目录对 Breditor vendor 副本应用后端补丁并用 `bbsq.exe -e` 编译通过；
  随后通过标准安装器部署。
- 安装前确认 `BattleBrothers.exe` 已关闭；安装结束后再次确认未运行。
- Steam `data\mod_bb_custom_appearance.zip` 与构建包 SHA-256 一致。
- 安装包内 catalog 的燃烧手雷标签、技能 ID 和 config ID 校验通过；Breditor 后端的
  `getCustomSkillCatalog`、`applyCustomSkill` 和配置冷却初始化逻辑校验通过。
- 已知旧命中率活动 ZIP 仍不存在；历史
  `狐狸汉化适配-命中率改为0-100.zip.bbca-backup` 保持原 SHA-256
  `4C53189CC73DD5BDEB8C30E7CFC41A337088F048F71F3ACDDE947B4A2A1256FB`。
- 游戏内下拉显示、授予、使用、冷却、友伤、存读档和 `log.html` 仍待人工回归。

## 2026-06-28：新增技能开发交接入口

新增 `docs/new-skill-development-starter-prompt.md`，统一新技能对话的必读文档、FantasyBro
参考边界、ID/config/序列化规范、依赖审计、构建验证和安装许可流程。

## 2026-06-28：链锤 AI 停在持盾目标旁

### 现象

敌方链锤单位走到持盾角色旁后不发动攻击。游戏界面仍可操作，没有错误弹框。

### 证据与根因

最后一场战斗的 `log.html` 约 71 MB。08:33:05--08:33:06 反复记录：

- `the index 'IsShieldwallRelevant' does not exist`
- 栈顶：`scripts/!mods_preload/mod_hitchance_100or0.nut : 379`
- 调用链：`queryTargetValue` → `queryBestMeleeTarget` → AI `think`
- 变量：`shieldBonus = 18`、`skill = 56`、`defense = 7`、`toHit = 67`
- AI 收到的 `hitchance = Null`

链锤攻击会绕过盾牌防御，因此 AI 评估路径进入旧 `getHitchance` 的盾牌补偿分支。旧独立 ZIP
直接读取当前游戏不存在的 `IsShieldwallRelevant`，使 AI 无法给目标评分。错误发生在 AI
评估而非玩家技能执行路径，所以只写日志、不弹框，游戏主循环也没有卡死。

此前认为内嵌 Hook 的 Mod Hooks 最终队列能覆盖旧独立包，这一判断不完整：中文文件名 ZIP
在 Mod Hooks 的 `~~finalize.nut` 之后加载，旧 Hook 注册得更晚，仍会覆盖内嵌实现。

### 修复

- 新增 `tools/disable_known_legacy_hitchance_archive.ps1`。
- 只识别已知冲突 SHA-256：
  `4C53189CC73DD5BDEB8C30E7CFC41A337088F048F71F3ACDDE947B4A2A1256FB`。
- 无备份时把活动 ZIP 原样移动为 `.bbca-backup`。
- 已有备份时不修改备份，把活动 ZIP 移到新的 `.bbca-disabled[-N]` 名称。
- 标准安装器在成功安装内嵌实现后执行该迁移。

临时目录测试覆盖了首次迁移、重复运行和已有备份三种情况。2026-06-28 已在本机执行：
活动 ZIP 已移除，原始哈希文件保存在
`狐狸汉化适配-命中率改为0-100.zip.bbca-backup`。游戏内链锤 AI 回归待验证。

## 2026-06-28：FantasyBro 技能体系审计

- 扫描 `参考/mod_fantasybro-473-4-2b-1722856556.zip` 的 759 个条目。
- 识别 214 个技能类脚本；技能书目录实际包含 111 项（80 主动/特殊、31 被动）。
- 生成 `docs/fantasybro-skill-production-analysis.md`。
- 生成自包含 `docs/fantasybro-skill-catalog.html`，含原始技能图标、中文说明、数值、
  搜索和主动/被动筛选。
- 图鉴生成源为 `docs/reference/fantasybro-skill-cn.tsv`，构建脚本为
  `tools/build_fantasybro_skill_catalog.ps1`。
- 桌面 1440×1000 与移动 390×844 浏览器验证通过：111 项、31 个被动、图标完整、无横向
  溢出和控制台错误。
- 创建 Codex skill `battle-brothers-skill-development`；安装在用户 Codex skills 目录，
  便携源保存在 `codex-skills/battle-brothers-skill-development`。

重要代码风险包括：技能书事件删除已有技能、`sb_strike_skill` ID 错配、宣传活动随机数参数
顺序可疑、重复维护 111 项数组，以及完整覆盖战术 actor `onRender`。

## 2026-06-28：盾墙目标攻击中断

### 现象

- 攻击正在使用 Shieldwall 的敌人时，界面可显示高命中率，但攻击无伤害。
- 近战和 Quick Shot 都可能报错并中断攻击流程。

### 证据与根因

`Documents\Battle Brothers\log.html` 在同一场战斗中记录：

- Overhead Strike：`the index 'IsShieldwallRelevant' does not exist`
- Quick Shot：相同错误
- 栈顶：`scripts/!mods_preload/mod_hitchance_100or0.nut : 73`

Steam `data\狐狸汉化适配-命中率改为0-100.zip` 中的历史脚本直接读取
`this.m.IsShieldwallRelevant`。当前游戏 `1.5.2.3` 的原版 `skills/skill` 没有该字段。
历史脚本还完整覆盖了旧版 `attackEntity`，使用写死的偏射命中和伤害常量。

### 决策

- 不修改历史第三方压缩包，也不假设它有可用备份。
- 内嵌补丁注册独立模组 ID `mod_bbca_hitchance`。
- 通过 `mods_queue` 在所有 preload 完成后注册 Hook，使内嵌实现覆盖历史立即注册的 Hook。
- 从本机 `data_001.dat` 反编译当前原版 `skill.cnut`，同步
  `attackEntity` / `getHitchance`；只把 5--95 上下限改为 0--100。
- 保留当前原版 Shieldwall 计算、死亡目标保护和
  `HitChanceOnDiversion` / `DamageTotalOnDiversionMult`。

### 验证

- `bbsq.exe -e` 语法编译通过。
- 静态检查确认不存在 `IsShieldwallRelevant`。
- 完整资产/源码构建通过。
- 安装包与 Steam 文件 SHA-256 一致：
  `D65C9762A61C15E908C7BE148137F0379AB6C6161E5239EB12E0CE2C7F591259`。
- 实际盾墙战斗回归仍待用户执行。

### 长期规则

任何从原版复制的完整函数覆盖都必须记录对应游戏版本。游戏升级后，先重新反编译对照，
不能只修复触发报错的单个字段。

## 2026-06-28：工程记忆分层

审阅发现架构、机器状态和历史记录混写，造成安装日期陈旧、文档数量不一致，以及错误声称
本机存在历史包 `.bbca-backup`。现采用以下分层：

- `START-HERE.md`：入口、能力、硬规则。
- `docs/README.md`：记忆索引和更新规则。
- `docs/current-state.md`：带日期的本机状态。
- `docs/portable-custom-appearance-handoff.md`：稳定架构契约。
- `docs/development-playbook.md`：可重复开发与验证流程。
- `docs/engineering-log.md`：追加式证据和决策历史。

同时移除了对不存在的 `启动造型修改器并进入游戏.bat` 的说明，统一使用实际入口
`Manage-Custom-Appearance-Assets.bat`。

## 2026-06-27：Aegis 配置扩展到 v3

- 技能编辑器包含 Shadow Walk 和异常免疫 `Aegis`。
- Aegis 新增 `Overwhelmed` 与 `Distracted` 两个无原版免疫属性的 Hook。
- 配置 `effects.bbca_negative_immunity_config` 序列化版本为 v3，向后兼容 v1/v2。
- 已有角色需要逐人点击“保存参数”以写入新字段。

## 2026-07-12：Git 同步后完整汉化缺失

### 现象与根因

标准安装后游戏可以启动，但菜单汉化消失。检查确认被安全禁用的狐狸汉化整包包含完整 `ui/ui.js`；Git 工程当时只有 `world_names.js` 和 `bbca_cn_ui_compat.js`。后者既不覆盖全部汉化，又含错误编码文本。直接重新启用旧整包会同时恢复它自己的 Mod Hooks、`main.html` 和大量脚本，与当前集成实现重叠。

### 修复与验证

- 将完整中文 `ui.js` 纳入受管源码，不把旧压缩包恢复为运行时依赖。
- Breditor 补丁按 `world_names.js`、`ui.js`、fallback helper、`mod_hooks.js` 顺序加载。
- helper 改为仅在全局函数缺失时提供 no-op，消除乱码并禁止覆盖完整翻译。
- 安装器在写 Steam 前校验资源、script tag 和核心函数。
- disposable `bbsq.exe -e` 编译 19 份 `.nut`；标准构建、最终 ZIP 检查和安装通过。组件包 SHA-256 为 `3C9CED0D25FE55694771205DA844E628FF02980689856E0818202758B81F65EB`，与 Steam 一致；4 个历史 `.bbca-backup` 未改变。

待人工验证菜单、读档、世界地图/城镇 tooltip、Shift+X 以及新 `log.html`。

## 2026-07-13：仅恢复 `ui.js` 仍无法恢复汉化

用户截图确认主菜单按钮仍为英文。进一步核对原狐狸汉化包发现，翻译调用并不只由 `ui.js` 提供：`ui/controls/button.js` 等 34 个 JS 模块负责把界面文本交给翻译函数，另有 2281 个 `.nut` 提供游戏内容中文。此前只复制 `ui.js` 与 `world_names.js`，依赖闭包不完整。

没有直接重新启用原包，因为其中还包含旧 Mod Hooks bootstrap、`ui/mod_hooks.js` 和自己的 `ui/main.html`，会与当前 Hooks/Breditor 入口重叠。改为生成受管纯汉化运行包，保留 2621 个翻译条目并剔除四类冲突路径。安装器现在先校验条目总量、核心游戏/UI 翻译文件和禁止路径，再写入 Steam。

2281 个包内 `.nut` 均通过 disposable `bbsq.exe -e`；运行包与 Steam 哈希一致为 `0EAF5F0B7B89BFB9C196B42930104B4181152524D51BCA37B6FF55F9780BB647`。历史汉化包和 4 个 `.bbca-backup` 未修改。游戏内完整中文与 BBCA 兼容回归待用户执行。

## 2026-07-14：Hard Chance 在角色面板显示 1002 疲劳恢复

截图显示疲劳栏为 `0 / 92 (1002)`。活动第三方模组“疲劳恢复从15改为(8+面板疲劳÷10)”会把 `getFatigueRecovery()` 注入 UI 的括号字段；Hard Chance 为兼容它，在 `onUpdate()` 中把角色 `FatigueRecoveryRate` 提高到至少 1000。该模组按“当前恢复率与 15 的差值”计算，最终显示约 1002。

用户确认第三方疲劳模组不再需要。核对当前 `actor.onTurnStart()` 后确认原版先恢复疲劳、后调用技能容器，因此移除外层包装后，Hard Chance 自己的 `onTurnStart() -> setFatigue(0)` 位于正确的最终位置。实现已删除属性注入，新增基于精确文件名和 SHA-256 的可逆停用脚本，并接入标准安装器；未知哈希和所有 `.bbca-backup` 均不处理。

技能编译、标准构建和最终 ZIP 断言已通过，确认保留 `setFatigue(0)` 且包内不再出现 `forcedRecovery` 或 `FatigueRecoveryRate`。由于诊断时游戏仍在运行，本轮尚未部署，待游戏关闭后安装并执行面板与战斗回归。
