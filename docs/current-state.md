# 当前工程状态

最近核对：2026-07-12。

本文件只记录易变化的本机与部署事实。稳定设计见
`docs/portable-custom-appearance-handoff.md`。

## 环境

- GitHub 同步仓库：`https://github.com/TrumptheGreatohohoho/BB-Custom`，默认分支 `main`。
- 两台电脑的工作副本目录允许不同：当前电脑使用 `D:\project\BB-Custom-2`；另一台电脑使用
  `D:\project\BB-Custom`。当前电脑旧的 `D:\project\BB-Custom` 仍不是源码权威。
- 下方 2026-07-12 构建/安装事实来自上传 GitHub 的另一台电脑；切换电脑后必须重新核对该机 Steam
  路径和活动 ZIP，不能只凭本文件假定已安装。
- 最近上传电脑的 Steam 游戏目录：`D:\games\steam\steamapps\common\Battle Brothers`
- 游戏版本：`1.5.2.3`（来自 2026-06-28 的 `log.html`）
- 游戏数据入口：`data\data_001.dat`
- 最近一次安装结束时 `BattleBrothers.exe` 未运行。

## 当前构建与安装

- 构建产物：`build/custom_appearance/mod_bb_custom_appearance.zip`
- 产物大小：`171540` 字节
- 当前构建 SHA-256：
  `3CF4FCC07EFB5A0279CE2F57068BB1F396EB2F9DD09F6BA0A56250650809073C`。
- 当前构建已包含后续 Hard Chance、Aegis v6、Stun Piercer、被动反击、召唤容量修复、
  被动反击的移动触发攻击过滤、数字输入修复、两件自愈装备、独狼总 roster 上限 16 人 Hook，
  以及中文 UI 兼容 helper。
- Steam 当前安装的组件包是 `data\mod_bb_custom_appearance.zip`，大小 `171540` 字节，
  SHA-256：`3CF4FCC07EFB5A0279CE2F57068BB1F396EB2F9DD09F6BA0A56250650809073C`，
  与当前自包含中文 UI/蓝羽纹章尖顶盔构建一致。
- 历史一体包已被标准安装器从活动
  `data\mod_bbca_all_in_one_cn_compat.zip` 改名为
  `data\mod_bbca_all_in_one_cn_compat.zip.bbca-disabled`，大小 `7865379` 字节，
  SHA-256 仍为 `1E75A631FA34A6D0760C661DEC41112A2BC29BBC1CCDDFB2F39D8A4827344750`。
  它不是源码权威，也不再参与运行时加载。
- 该一体包在 2026-07-11 安装。2026-07-12 已把后续 BBCA 修改合并回工程源码；同日通过标准
  安装器部署当前组件包、Breditor 兼容包和 Mod Hooks，未手工覆盖任何 Steam 文件。
- `mod_source/bb_custom_appearance` 重新成为 BBCA 源码权威；一体运行包、
  `build/custom_appearance` 和 Steam 文件都只是产物，不应反向作为长期源码。

## 当前功能

- Custom Appearance：`body` / `head` / `hair` / `beard`。
- 当前源码、构建和已安装组件包包含：Shadow Walk、燃烧手雷、召唤装甲复生者、
  异常免疫 `Aegis`、Hard Chance、两件自愈装备，以及独狼总 roster 16 人 Hook。
- 燃烧手雷 ID：`actives.bbca_fire_grenade`。
- 燃烧手雷配置：`effects.bbca_fire_grenade_config`，序列化 v2。
- 召唤技能 ID：`actives.bbca_summon_zombie`。
- 召唤配置：`effects.bbca_summon_zombie_config`，序列化 v1。
- Aegis 配置序列化：v6（v5 `StunPiercer`，v6 `PassiveCounterattack`）。
- Hard Chance 配置：`effects.bbca_hard_chance_config`，序列化 v1。
- 独狼 roster 上限 Hook：
  `scripts/!mods_preload/mod_bbca_lone_wolf_roster_cap.nut`；将独狼总人数和单场战术部署
  上限均设为 16，不修改敌方规模参数。
- 自愈装备 ID：
  `armor.body.bbca_regenerating_adorned_mail_shirt`、
  `armor.head.bbca_regenerating_heavy_mail_coif`。
- 命中率：0--100，内嵌于 Custom Appearance 包。
- 命中率 Hook 模组 ID：`mod_bbca_hitchance`，通过 Mod Hooks 最终队列注册。

## 2026-07-12 工程源码回写状态

- 从当前活动一体运行包核对并回写了 8 个后续修改文件；新增 Hard Chance 两个脚本和
  两件自愈装备脚本。保留构建时生成 `::BBCA_Catalog` 的源码占位符，没有把运行产物
  反向硬编码进模板。
- 两件装备只复用原版外观字段：圣饰链甲衫 Variant 107、蓝羽纹章尖顶盔 Variant 265；
  均为独立稳定 ID、270 耐久、每回合恢复 90、战后回满、不可损毁。
- Breditor 接入通过 `BBCA_EquipmentCatalog` 包装 `prepareNI()`，只把两条脚本路径加入
  `Legendary` 列表，不覆盖 Breditor 主函数或修改原版装备。
- 同步的 9 个关键 `.nut`（生成后的 catalog preload、命中率/眩晕穿透 Hook、召唤、
  Aegis、Hard Chance、两件装备）均通过工程自带 `bbsq.exe -e` 编译。
- 标准资产/源码构建通过；最终组件 ZIP 无重复路径，并包含全部新 ID、脚本和目录接入。
- 当前组件包已于 2026-07-12 通过标准安装器部署。游戏内仍待验证：从 Legendary 列表生成
  两件装备、受损后每回合恢复、战后回满、保存/读档，以及新 `log.html` 无错误。

## 2026-07-12 自愈头盔外观改为纹章尖顶盔（初版 Variant 263，已被后续修正取代）

- 从当前游戏 `1.5.2.3` 反编译原版红装
  `scripts/items/helmets/named/heraldic_mail_helmet.cnut`。它使用 Variant 262--266 的
  纹章尖顶盔族；本包固定选用红羽 Variant 263，而不是原先重型链甲头罩的 Variant 237。
- 自愈头盔保留稳定类路径和 ID
  `armor.head.bbca_regenerating_heavy_mail_coif`，以及 270 耐久、每回合恢复 90、战后回满、
  不可损毁、疲劳 -10 等所有功能数值。仅更新显示名/说明和外观 Variant，因此不新增存档字段。
- 修改后的头盔源码副本和最终 ZIP 内副本均通过 `bbsq.exe -e`。标准构建通过；最终 ZIP 有
  34 条唯一路径，头盔脚本恰一份，确认含 Variant 263、不含 Variant 237，并保留 ID、耐久和
  自愈逻辑。构建大小 `171427` 字节，SHA-256：
  `40CC4F6E6E93E89822651F026B4EF594F6A35451CE6093E05B3E45F257D2B41E`。
- 用户明确授权后已通过标准安装器部署。安装前后 `BattleBrothers.exe` 均未运行；Steam 组件包
  与构建 SHA-256 一致，包内头盔脚本恰一份，确认含 Variant 263 并保留稳定 ID 与自愈逻辑。
  4 个既有 `.bbca-backup` 哈希均保持不变。
- 待人工游戏回归：从 Legendary 列表生成/已有头盔装备后显示红羽纹章尖顶盔；受损后的回合恢复、
  战后回满、存读档及 `log.html` 正常。

## 2026-07-12 自愈头盔修正为截图所示蓝羽纹章尖顶盔（已构建并安装）

- 用户提供的原版参考图对应 `heraldic_mail_helmet` 的蓝羽 Variant 265，而不是初版选用的
  Variant 263。该目标的 inventory 图标与游戏内外观均为蓝色羽饰。
- 用户看到旧外观的另一个原因是：原版 `helmet.onDeserialize()` 从存档读取已保存的 Variant，
  所以只修改 `create()` 仅影响新生成的装备。自定义头盔现重写 `onDeserialize()`：先执行原版
  读取耐久等逻辑，再强制设为 Variant 265 并 `updateVariant()`；已拥有的同 ID 头盔在读档后也会
  更新外观。该迁移不读写新增字节，不改变 ID 或数值。
- 头盔源码副本和最终 ZIP 内副本均通过 `bbsq.exe -e`。最终 ZIP 有 34 条唯一路径，头盔脚本
  恰一份，确认含 Variant 265、迁移 `onDeserialize()`、原版 deserialize 调用、稳定 ID 与自愈
  逻辑。构建大小 `171540` 字节，SHA-256：
  `C3DD29CBF39C37FFF2DDCC78DBFB5766BC42C0061C5D5A267D00C85962EAD634`。
- 按常设部署授权，安装前后 `BattleBrothers.exe` 均未运行；Steam 包与构建哈希一致，包内 Variant
  265 与迁移逻辑均确认存在，4 个既有 `.bbca-backup` 哈希保持不变。
- 待人工回归：载入已有存档后，旧自愈头盔立即显示截图所示蓝羽外观；新生成装备同样正确，
  且耐久恢复、战后回满、存读档和 `log.html` 正常。

## 2026-07-12 蓝羽头盔读档时立即刷新角色立绘（已构建并安装）

- 进一步审计当前原版 `helmet.updateAppearance()`：它会在未装备/无容器时安全返回，在已装备时
  更新角色 appearance。仅在 `onDeserialize()` 里执行 `updateVariant()` 会更新图标资源，但不保证
  同一读档流程中的已装备角色立绘立即刷新。
- 自定义迁移现在在设置 Variant 265、`updateVariant()` 后调用 `updateAppearance()`，因此无需让
  用户手动卸下再装备。该调用沿用原版容器/装备检查，不新增字段或改变耐久、自愈和 ID。
- 源码与最终 ZIP 头盔脚本通过 `bbsq.exe -e`；最终 ZIP 有 34 条唯一路径，确认 Variant 265、
  `onDeserialize()`、原版 deserialize 调用和 `updateAppearance()` 均存在。构建大小 `171541`
  字节，SHA-256：`477EB83C82460289026A0526CEE1C723487C9E5C0D96291AACCD15D8BF292EB5`。
- 按常设授权已通过标准安装器部署。安装前后游戏未运行，Steam 包哈希与构建一致，4 个既有
  `.bbca-backup` 哈希保持不变。待载入已有存档确认角色立绘、库存图标、自愈和 `log.html`。

## 2026-07-12 停用覆盖脚本的一体包并自包含中文世界名称资源（已构建并安装）

- 用户报告即使新档头盔外观也未变。读档日志和 Steam ZIP 逐包检查确认：活动
  `mod_bb_custom_appearance.zip` 的同路径头盔脚本已经是 Variant 265，但活动
  `mod_bbca_all_in_one_cn_compat.zip` 仍含旧 Variant 237。后者覆盖前者，因此不是存档迁移问题。
- 新增 `tools/disable_known_legacy_bbca_all_in_one_archive.ps1`，只识别文件名
  `mod_bbca_all_in_one_cn_compat.zip` 且 SHA-256 为
  `1E75A631FA34A6D0760C661DEC41112A2BC29BBC1CCDDFB2F39D8A4827344750` 的精确旧包；命中时
  改名为新的 `.bbca-disabled[-N]`。未知哈希不处理，任何 `.bbca-backup` 都不创建、移动、
  覆盖或修改。
- 为保持此前一体包提供的完整中文世界/城镇/tooltip 文本，已将其 `ui/world_names.js` 导入受管
  源 `mod_source/bb_custom_appearance/ui/world_names.js`（SHA-256
  `5BE6121B275A57ABCAB9A8F59B698B97C5DB318ADA09B94728F450AAEC083A5F`）。Breditor 暂存补丁
  现写入该资源，安装器断言资源与 `TranslateTooltips`、`TranslateTownScreenNames` 存在。
- 隔离 Breditor 暂存验证及标准安装后验证均确认 `world_names.js` →
  `bbca_cn_ui_compat.js` → `mod_hooks.js` 顺序正确，资源和全局函数齐全。一体包不再以 `.zip`
  扩展名参与加载；当前唯一活动头盔脚本是组件包中的 Variant 265，包含读档立绘刷新。
- 构建大小 `171540` 字节，SHA-256：
  `3CF4FCC07EFB5A0279CE2F57068BB1F396EB2F9DD09F6BA0A56250650809073C`。安装前后游戏未运行，
  4 个既有 `.bbca-backup` 哈希保持不变。待人工回归：新旧档头盔外观、中文菜单/大地图/城镇/
  tooltip、存读档和 `log.html`。

## 2026-07-12 被动反击 Hook 读档崩溃修复（已构建并安装）

- 用户安装初版移动过滤构建后读档失败。13:47--13:48 的最新 `log.html` 有 87 个 error 行，
  其中 42 个直接为 `the index 'onAttackOfOpportunity' does not exist`，并有大量派生战术类
  `Failed to execute script file`。随后 `player.nut` 缪误缺少 `IsControlledByPlayer` / `human`，
  最终报 class key `7598820860669657090` 未注册；存档错误是前置类注册失败的连锁结果。
- 根因是初版使用 `mods_hookClass("entity/tactical/actor", ...)`。当前 Mod Hooks 42 的该 API
  会同时把回调应用到 actor 的直接子类；`warwolf` 等子类成员表没有继承函数的本地索引，直接
  读取 `o.onAttackOfOpportunity` 会在启动预载阶段抛错。
- 源码现改为 `mods_hookExactClass("entity/tactical/actor", ...)`，仅包装实际定义该函数的
  actor 类一次。移动攻击深度标记和 Aegis 过滤逻辑不变，也不修改任何序列化字段。
- 修复 Hook 的源码副本与最终 ZIP 副本均通过 `bbsq.exe -e`。标准构建通过，最终 ZIP 有
  34 条唯一路径、Hook 恰一份，确认包含 exact-class API 且不含旧的 actor `mods_hookClass`。
  构建大小 `171430` 字节，SHA-256：
  `F2F36E792E6E4C79C4713701B7A7AA4F8FD336101FDB1BA5C7F998F56C5CA003`。
- 用户再次明确授权后，修复构建已通过标准安装器部署。安装前后 `BattleBrothers.exe` 均未运行；
  Steam 组件包与构建 SHA-256 一致。Steam 包内 Hook 恰一份，确认使用 exact-class API 且不含
  旧的 actor `mods_hookClass`；4 个既有 `.bbca-backup` 哈希保持不变。
- 待人工游戏回归：先验证同一存档可正常载入且新日志不再有
  `onAttackOfOpportunity`/class registration 错误，再回归移动借机攻击不反击与普通主动攻击仍反击。

## 2026-07-12 被动反击排除移动触发攻击（初版已安装，现已被后续修复构建取代）

- 从当前游戏 `1.5.2.3` 反编译 `scripts/entity/tactical/actor.cnut`、`skill.cnut`、
  `skill_container.cnut` 与 `skills/actives/riposte.cnut`。原版
  `actor.onAttackOfOpportunity()` 会取攻击者的普通 `getAttackOfOpportunity()` 技能并
  `useForFree()`，因此仅凭 `_incomingSkill` 无法区分手动攻击与移动触发的借机攻击。
- 新增窄 Hook `scripts/!mods_preload/mod_bbca_passive_counterattack.nut`，只在原版
  `onAttackOfOpportunity()` 同步执行期间设置临时深度标记，并在正常返回和异常路径均恢复。
  Aegis 的 `PassiveCounterattack` 检测该标记并跳过反击；普通相邻主动攻击仍沿用原逻辑。
- 不新增或修改存档字段；`effects.bbca_negative_immunity_config` 仍为 v6，旧存档无需迁移。
- 三个修改/新增的 `.nut` 源码副本及最终 ZIP 内副本均通过 `bbsq.exe -e`。标准构建通过；
  最终 ZIP 共 34 条唯一路径，新 Hook 恰有一份。构建大小 `171266` 字节，SHA-256：
  `A53943F761ACF52EF9153255F5BC9CAFE676E166273B3C3DD14D09ACC5D0DA6D`。
- 用户明确授权后已通过标准安装器部署。安装前后 `BattleBrothers.exe` 均未运行；Steam
  组件包与构建包 SHA-256 一致。Steam 包内新 Hook 和 Aegis skill 均恰有一份且包含移动过滤；
  Breditor 保持 `world_names.js` → `bbca_cn_ui_compat.js` → `mod_hooks.js` 加载顺序，helper
  所需翻译全局函数存在。Steam 中 4 个既有 `.bbca-backup` 均保留，已知旧命中率活动 ZIP
  仍不存在。
- 待人工游戏回归：控制角色贴着敌人移动或脱离控制区时，敌人的借机攻击不触发 Aegis 被动
  反击；敌人普通相邻主动攻击命中/未命中时仍触发一次反击；死亡、移位、非相邻及忽略还击
  路径保持原行为，且新 `log.html` 无相关 `Script Error`。

## 2026-07-12 独狼总 roster 上限改为 16（已构建并安装）

- 从本机游戏 `1.5.2.3` 的 `scripts/scenarios/world/lone_wolf_scenario.cnut` 反编译确认：
  原版 `onInit()` 将默认 `BrothersMax = 20` 改为 12；它不修改 `BrothersMaxInCombat = 12`。
- 新增窄范围 Mod Hooks 包装，先调用原版 `onInit()` 再将
  `World.Assets.m.BrothersMax` 设为 16；同时把独狼开局菜单中的 Elite Few 文案更新为
  16 人。没有修改 Steam 原版 `data_001.dat`、没有新增存档字段，也没有改变战斗部署或敌方规模。
- 当前原版 `asset_manager.onDeserialize()` 会在读档末尾调用 origin 的 `onInit()`，因此新档和
  已有独狼档在加载该模组后都会得到 16 人 roster 上限。
- 新增 Hook 的源码副本和最终 ZIP 内副本均已通过 `bbsq.exe -e`；标准构建通过，最终 ZIP
  恰有一份 preload 脚本，且静态检查确认保留原版调用、设为 16、不触碰
  `BrothersMaxInCombat`、说明文案为 16。
- 用户明确授权后，通过标准安装器安装到 Steam。安装前后 `BattleBrothers.exe` 均未运行；
  Steam `data\mod_bb_custom_appearance.zip` 与构建包 SHA-256 一致，包内恰有一份 Hook，
  包含 16 人上限且不触碰 `BrothersMaxInCombat`。Breditor 与 Mod Hooks 档案均存在。
- Steam `data\` 中 `.bbca-backup` 数量安装前后均为 4；安装器没有修改既有备份。
- 待人工游戏回归：独狼新开局菜单显示 16；新档和已有独狼档可招募至 16、尝试第 17 人被拒绝；
  战术部署仍最多 12；存档/读档后上限仍为 16，且 `log.html` 无相关 `Script Error`。

## 2026-07-12 独狼战术部署上限改为 16（已构建并安装）

- 用户截图显示角色界面 `12/12`。从当前 `character_screen.nut` 核对确认，该数字读取的是
  `World.Assets.getBrothersMaxInCombat()`，而非此前已改为 16 的总 roster `BrothersMax`；因此
  它证明需求包含战术部署 16，不代表此前 roster Hook 未执行。
- 独狼 Hook 现于原版 `onInit()` 后同时写入 `BrothersMax = 16` 和
  `BrothersMaxInCombat = 16`。当前原版编队逻辑支持至少 18 个部署位；本次不改
  `BrothersScaleMax`，故不扩大敌方规模。
- 源码副本和最终 ZIP 内副本均通过 `bbsq.exe -e`，标准构建与安装通过。Steam 组件包与构建
  SHA-256 一致，包内两个字段均确认存在；安装前后游戏未运行，4 个既有 `.bbca-backup` 未变。
- 待人工游戏回归：独狼角色界面的容量显示为 16（招满后 `16/16`），可配置/部署第 13--16 人，
  第 17 人仍被拒绝；新档、旧档、战斗载入、存读档和 `log.html` 正常。

## 2026-07-12 中文 UI 黑屏修复（已构建并安装）

- 黑屏启动日志没有独狼 Hook 的脚本错误；Custom Appearance、命中率 Hook、Breditor 和 Mod Hooks
  均完成注册。首个 UI 错误是 `TranslateDialog`、`TranslateButtons` 未定义，随后新战役菜单
  的 DOM 成员为空并黑屏。
- 原因是标准 Breditor 兼容包的 `ui/main.html` 未加载当前中文 UI 所需的翻译全局函数。已有一体
  运行包含有该实现，但它不是源码权威。
- 用户明确授权恢复本次汉化兼容后，新增受管源文件
  `mod_source/bb_custom_appearance/ui/bbca_cn_ui_compat.js`；它定义四个既有翻译全局函数。
  `patch_active_breditor_ui.ps1` 将 helper 写入暂存 Breditor 包，并在 `mod_hooks.js` 前加载；
  `install_steam_breditor_compat.ps1` 在写入 Steam 前断言 helper、script tag、
  `TranslateDialog` 和 `TranslateButtons` 均存在。
- 临时 archive 补丁验证、标准构建和标准安装均通过。安装前后 `BattleBrothers.exe` 未运行，
  Steam 组件包与当前构建 SHA-256 一致；Steam Breditor 包确认 helper 存在、已加载且在
  Mod Hooks 前加载，4 个既有 `.bbca-backup` 未变。
- 待人工游戏回归：从主菜单进入新战役/读档不再黑屏，菜单中文按钮和弹窗正常，进入世界地图后
  无新的 `Translate* is not defined` 或其他 UI 错误。

## 2026-07-12 中文世界地图 UI 卡死修复（已构建并安装）

- 首轮 UI helper 修复后可新建独狼并看见大地图，但 09:44--09:45 日志报
  `TranslateTooltips` 与 `TranslateTownScreenNames` 未定义；调用栈分别在 tooltip 和世界事件
  UI，因而不是独狼脚本或战术逻辑问题。
- 既有一体兼容包仍提供完整 `ui/world_names.js`。Breditor 补丁现按顺序加载
  `world_names.js` → `bbca_cn_ui_compat.js` → `mod_hooks.js`；受管 helper 对全部世界/提示
  翻译函数提供 no-op fallback，避免可选翻译资源缺失导致 UI 再次卡死。
- 临时 archive 验证、标准构建和标准安装均通过。安装前后游戏未运行；Steam 组件包与构建哈希
  一致，Breditor 三段加载顺序、Tooltip/Town fallback 和一体包的完整 world-name 资源均已确认，
  4 个既有 `.bbca-backup` 未变。
- 待人工游戏回归：新建独狼进入大地图、城市/事件/tooltip 交互、读档与 `log.html`；确认没有
  `Translate* is not defined`、卡死或新的 UI error。

## 2026-06-28 盾墙修复状态

- 已从本机 `data_001.dat` 反编译当前原版 `scripts/skills/skill.cnut`。
- 内嵌补丁已同步当前原版 `attackEntity` / `getHitchance` 流程，仅修改 5--95 上下限。
- 已移除对不存在字段 `this.m.IsShieldwallRelevant` 的读取。
- 已恢复当前原版远程偏射参数：
  `HitChanceOnDiversion` 和 `DamageTotalOnDiversionMult`。
- 已恢复攻击已死亡目标的提前返回保护。
- 已通过 `bbsq.exe` 语法编译、静态断言、完整构建、安装哈希和包内脚本检查。
- 后续日志确认：中文文件名的旧独立 ZIP 在 Mod Hooks 队列完成后才加载，会再次覆盖
  `getHitchance`；因此仅依靠最终队列不足以解决冲突。
- 安装器现调用 `tools/disable_known_legacy_hitchance_archive.ps1`，只对已知冲突 SHA-256
  生效，并保证已有 `.bbca-backup` 不被覆盖。
- 尚待人工游戏回归：
  - 近战和远程分别攻击正在使用 Shieldwall 的目标；
  - 敌方链锤单位走近持盾角色后能正常选择并发动攻击；
  - 日志不再出现 `IsShieldwallRelevant`。

## 2026-06-28 燃烧手雷半径参数状态

- 主动技能 `actives.bbca_fire_grenade` 继续由唯一 `::BBCA_SkillCatalog` 授予和显示。
- 新增第 8 个可调参数 `AreaRadius`，编辑器范围 0–4、默认 2；完整地图分别影响
  1、7、19、37、61 格。使用原版普通火焰，固定友伤。
- 隐藏配置 `effects.bbca_fire_grenade_config` 已升级到序列化 v2；读取 v1 时
  `AreaRadius` 使用稳定默认值 2，点击“保存参数”后写入 v2。
- 已通过主动技能、配置和 preload 的 `bbsq.exe -e` 编译副本。
- 已通过标准构建、最终 ZIP 路径/ID/依赖断言，以及临时 Breditor 后端补丁与编译。
- 最终 ZIP 已确认包含 v2 配置、v1 兼容分支、动态半径读取和 catalog 的“燃烧半径”参数。
- 新构建已安装；Steam 包内动态半径、v2 写入、v1 读取分支和 catalog 参数校验通过。
- 安装前后 `BattleBrothers.exe` 均未运行；已知旧命中率活动 ZIP 仍不存在，历史
  `.bbca-backup` 保持原 SHA-256。
- 待人工游戏内回归：
  - `Shift+X` 下拉菜单显示“燃烧手雷 (Fire Grenade)”，可授予并保存 8 项参数；
  - 目标中心、第一圈、第二圈高亮正确，地图边缘不重复或越界；
  - 空格、敌军占用格、友军占用格均可投掷，当前占用者按固定友伤规则结算；
  - 投射期间原目标死亡或移动不改变落点，新进入落点的单位按当前占用结算；
  - 水面/不可燃地形、已有烟雾或瘴气、火焰免疫单位行为符合原版；
  - 高度差限制、定身、敌方控制区、投掷专精疲劳折扣和冷却符合配置；
  - 战斗结束后冷却复位，保存/读档后技能及 v1 参数持续存在；
  - `%USERPROFILE%\Documents\Battle Brothers\log.html` 无相关 `Script Error`。

## 2026-06-28 Aegis 吞噬免疫状态

- 新增默认关闭的 `ImmuneToSwallowWhole` / “免疫吞噬（最高级食尸鬼）”开关。
- Hook 当前原版 `scripts/skills/actives/swallow_whole_skill` 的 `onVerifyTarget`；
  AI 选目标和 `skill.use()` 实际执行都会经过此门槛，免疫目标不会被吞噬，也不会让食尸鬼
  消耗 AP/疲劳。
- 不影响 `kraken_devour`，也不会释放已经被吞噬的角色。
- `effects.bbca_negative_immunity_config` 已从 v3 升到 v4；v1–v3 读取时新字段默认关闭，
  保存参数后写入 v4。
- Aegis、v4 config、新 Hook 和 catalog preload 的 `bbsq.exe -e` 编译副本通过。
- 最终 ZIP 内脚本再编译、Hook 类/函数、v4 字段顺序、旧版本默认值、catalog 开关及
  不含 Kraken 引用的断言通过。
- 新构建已安装；Steam 包内 Hook、Aegis v4 config 和 catalog 开关校验通过。
- 待人工游戏内回归：
  - 开关关闭时，三级食尸鬼仍可正常吞噬；
  - 开关开启时，食尸鬼 AI 不选择该角色，实际 `skill.use()` 也拒绝该目标；
  - 队伍中免疫与非免疫角色并存时，AI 可改选合法目标；
  - 全员免疫时吞噬技能无合法目标，普通攻击和移动 AI 不受影响；
  - 保存/读档后开关持续存在，`log.html` 无相关 `Script Error`。

## 2026-06-28 装甲复生者召唤状态

- 新增 `actives.bbca_summon_zombie`，并加入唯一 `::BBCA_SkillCatalog`；
  下拉标签为“召唤装甲复生者 (Summon Zombie)”。
- 固定生成原版 `scripts/entity/tactical/enemies/zombie_yeoman`，设为
  `Const.Faction.PlayerAnimals`，使用原版僵尸 AI 和随机装备。
- 默认 6 AP、25 疲劳、范围 3、高度差 1、冷却 5、每名施法者最多维持 3 个；
  六项均可从技能编辑器修改，最大维持数量范围 1–12。
- 召唤物 `ResurrectionChance = 0`；使用直接脚本引用按施法者追踪存活单位，清理时先检查
  actor API，再移除死亡/濒死单位并释放名额。战斗开始/结束清空追踪；原版
  PlayerAnimals 战后路径移除装备，单位不会进入佣兵团。
- 2026-06-28 的实际日志确认旧实现会在第二回合调用弱引用对象不存在的 `isNull()`，
  从 `bbca_refreshSummonedEntities` 中断回合开始流程；最高级食尸鬼此前已正常完成行动，
  因此该次软锁不是吞噬免疫 Hook 导致。
- 技能现使用包内 `gfx/ui/bbca_summon_zombie.png` 和
  `gfx/ui/bbca_summon_zombie_sw.png`，不再引用缺失的原版 `active_26.png` 或 overlay。
- v1 隐藏配置存储所有可调参数；旧存档无同名 ID，首次授予时创建。
- 主动技能和 preload 的编译副本通过；最终 ZIP 内再编译、包内图标、实体路径、友方 AI
  阵营、禁止自动复活、默认/可调数量、战后清理及无 FantasyBro 运行时依赖断言通过。
- 新构建已安装；Steam 包内召唤技能、v1 config、实体/阵营/禁止复活逻辑和 catalog
  选项校验通过。
- 待人工游戏内回归：
  - 召唤后结束第一回合；第二回合轮到施法者时正常进入行动，不再出现 `isNull`；
  - 同场存在最高级食尸鬼时重复上述流程，并分别验证吞噬免疫开关；
  - 技能栏正常显示启用/禁用图标，日志不再出现 `gfx/skills/active_26.png` 打开失败；
  - 空格、占用格、不可见格、地图边缘和不同高度目标；
  - 召唤物与玩家结盟并由 AI 行动，敌我识别和控制区正常；
  - 同一施法者达到上限后技能禁用，召唤物死亡后恢复名额；
  - 多名施法者分别维护自己的数量上限；
  - 召唤物死亡后不自动复活，敌方死灵法师仍可按原版机制处理尸体；
  - 战斗结束后召唤物及装备不进入佣兵团或战利品；
  - 保存/读档后 v1 参数持续存在，`log.html` 无相关 `Script Error`。

## 历史兼容包

Steam `data\` 当前保留历史备份：

- 活动文件 `狐狸汉化适配-命中率改为0-100.zip` 已不存在。
- 备份文件：`狐狸汉化适配-命中率改为0-100.zip.bbca-backup`
- SHA-256：`4C53189CC73DD5BDEB8C30E7CFC41A337088F048F71F3ACDDE947B4A2A1256FB`
- 备份内的旧脚本会读取当前游戏不存在的 `IsShieldwallRelevant`；它只作为历史源保留，
  不再以 `.zip` 扩展名参与运行时加载。

绝不修改或删除上述备份。若未来需要恢复，必须先解决旧脚本与当前游戏版本的兼容问题。

## 下次接手先检查

1. `BattleBrothers.exe` 是否运行。
2. Steam 游戏版本是否仍为 `1.5.2.3`。
3. 构建包与安装包哈希是否一致。
4. 最近的 `Documents\Battle Brothers\log.html` 是否有 Script Error。
5. 若游戏升级，优先重新反编译 `scripts/skills/skill.cnut`，再维护命中率完整函数覆盖。

## 2026-07-12 完整中文 UI 恢复（已构建并安装）

- 根因：Git 同步后的标准构建只携带 `world_names.js` 和少量启动兜底函数；此前被禁用的狐狸汉化整包才含完整 `ui/ui.js`，因此菜单汉化消失。
- 处理：从已禁用历史包只读核对并把完整 `ui.js` 纳入工程权威；没有重新启用夹带旧 Mod Hooks、旧 UI 入口和大量脚本的历史整包。
- Breditor 固定加载顺序为 `world_names.js` → `ui.js` → `bbca_cn_ui_compat.js` → `mod_hooks.js`；兼容 helper 现在只在函数不存在时提供 no-op，不会覆盖完整汉化。
- 19 份 `.nut` 已用 disposable `bbsq.exe -e` 编译。标准构建和安装器校验通过；组件包大小 `194474` 字节，构建与 Steam SHA-256 均为 `3C9CED0D25FE55694771205DA844E628FF02980689856E0818202758B81F65EB`。
- 安装前游戏未运行；Steam 中 4 个既有 `.bbca-backup` 均未修改。
- 待游戏内回归：主菜单、新战役、读档、角色/仓库按钮、大地图城镇与 tooltip 均显示中文；Shift+X 编辑器正常；`log.html` 无 `Translate* is not defined`、UI error 或 Script Error。

## 2026-07-13 完整狐狸汉化运行层恢复（已构建并安装）

- 2026-07-12 的 `ui.js` 修复不足：截图确认主菜单仍为英文。根因是狐狸汉化还依赖 34 个翻译 UI 模块和 2281 个中文游戏脚本；仅恢复翻译函数不会让原版控件调用它们。
- 新增受管 `vendor/data_bbca_fox_cn_runtime.zip`，包含 2621 个条目、2281 个 `.nut` 和 34 个 `.js`。明确剔除旧 `!!redirect.nut`、`~~finalize.nut`、`ui/mod_hooks.js` 与冲突 `ui/main.html`。
- 全部 2281 个 `.nut` 已使用 disposable `bbsq.exe -e` 编译，失败数为 0。运行包大小 `6832962` 字节，工程与 Steam SHA-256 均为 `0EAF5F0B7B89BFB9C196B42930104B4181152524D51BCA37B6FF55F9780BB647`。
- 标准 BBCA 组件也已重建并重新安装。安装前后游戏未运行；4 个既有 `.bbca-backup` 未修改；原狐狸汉化历史包仍以 `.bbca-disabled` 保存且未修改。
- 待游戏内回归：主菜单按钮中文；新战役、读档、角色、物品、事件、城镇、战斗与 tooltip 文本中文；Shift+X 及全部 BBCA 技能正常；新 `log.html` 无 Script Error/UI error。

## 2026-07-14 Hard Chance 面板疲劳恢复值修正（已构建，待安装）

- 截图中的 `0 / 92 (1002)` 中，括号值是独立疲劳模组显示的每回合恢复量，不是最大疲劳。Hard Chance 为压过该模组此前在 `onUpdate()` 中把 `FatigueRecoveryRate` 强制提高到至少 1000，因而把内部兼容值泄漏到了战斗外面板。
- 原版 `actor.onTurnStart()` 顺序已核对：先做原版疲劳恢复，再调用技能容器 `Skills.onTurnStart()`。因此在没有外层疲劳模组时，Hard Chance 的 `actor.setFatigue(0)` 会最后执行并可靠清空疲劳。
- 已删除 Hard Chance 对 `FatigueRecoveryRate` / `FatigueRecoveryRateMult` 的修改，保留回合开始清空疲劳。新增精确 SHA-256 停用脚本，只处理已知 `98ACE863...448BE8` 的“8+面板疲劳÷10”活动 ZIP，并改名为 `.bbca-disabled`；不会修改任何 `.bbca-backup` 或未知文件。
- 修改后的技能源码已用 disposable `bbsq.exe -e` 编译；标准构建及最终 ZIP 检查通过。构建大小 `194156` 字节，SHA-256 为 `30AD22B42C3B2CE6DCFF0C29DB85CDD4DA22563A21A49C20B5351C184FEA09CB`。
- 当前 `BattleBrothers.exe` 正在运行，因此尚未写入 Steam、也尚未停用活动疲劳模组。待关闭游戏后通过标准安装器部署。
- 待游戏内回归：战斗外疲劳行恢复为正常恢复数值；Hard Chance 角色每回合开始当前疲劳仍归零；无 Hard Chance 角色按原版恢复；角色面板、战术面板和 `log.html` 无错误。
