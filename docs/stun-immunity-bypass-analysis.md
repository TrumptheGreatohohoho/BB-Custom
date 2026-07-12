# 攻击者被动穿透眩晕免疫：生产分析

分析日期：2026-06-30
分析游戏：Battle Brothers `1.5.2.3`
原版数据：`D:\games\Steam\steamapps\common\Battle Brothers\data\data_001.dat`
状态：**安全方案已重做为 Aegis v5 开关并安装；第一回归必须验证旧档读档**

## 1. 目标

研究能否新增一个只属于攻击者的天赋/被动，使拥有它的玩家使用原本具备眩晕能力的攻击时，
可以穿透敌人当前的硬性 `IsImmuneToStun`，让原先不吃眩晕的敌人能被眩晕技能眩晕，但普通
攻击不会凭空获得眩晕。

结论：**可以实现**。不能只给攻击者增加一个普通属性；需要同时处理攻击技能的前置免疫检查
和 `effects.stunned` 的持续免疫检查。推荐使用窄 Mod Hooks 包装和攻击者被动回调，不复制
完整原版函数。

2026-06-30/07-01 实现与回滚结果：

- 首版被动 ID 曾为 `effects.bbca_stun_piercer`，但该独立序列化技能方案已废弃；
- 重做版不新增独立技能 ID，不新增独立 `mod_bbca_stun_piercer.nut`；改为
  `effects.bbca_negative_immunity_config` 的 v5 `StunPiercer` 布尔开关，默认关闭；
- Hook 嵌入既有 `scripts/!mods_preload/mod_bbca_hitchance_100or0.nut`，采用上下文栈、
  正常/异常共用清理和外部实例列表 `::BBCA_StunPiercer.MarkedStuns`；
- 首版与热修版均在用户旧档读档时触发 `ID mismatch while deserializing script data`；
- 2026-07-01 用户明确要求 Stun Piercer 覆盖“原先不吃晕眩的敌人”，因此当前 build
  改为穿透敌人当前硬免疫；`perk.battering_ram` 不再是硬停止项。
- 当前 build 与 Steam 安装包 SHA-256 均为
  `51283EBD86A105CDA9260B91128412F2A6D828108255735EBAAF66112CC72C9A`。

## 2. 当前原版眩晕链

### 2.1 攻击技能先拒绝免疫目标

玩家可获得的眩晕攻击都会在命中后检查：

```squirrel
!target.getCurrentProperties().IsImmuneToStun
```

检查通过后才创建：

```squirrel
this.new("scripts/skills/effects/stunned_effect")
```

因此只 Hook `stunned_effect` 不够：免疫目标通常根本不会收到该效果。

### 2.2 `stunned_effect` 再次检查

当前 `scripts/skills/effects/stunned_effect.cnut` 有第二层保护：

- `onAdded()`：目标仍免疫时把效果标记为垃圾，不执行打断 Shieldwall、Spearwall、
  Riposte、Return Favor 和 Possessed Undead。
- `onUpdate(_properties)`：只有目标当前不免疫时才设置 `IsStunned = true`、清空 AP 并显示
  眩晕 sprite。

所以即使强行把效果加入容器，若没有给这个具体效果实例记录“可穿透免疫”，下一次属性更新时
仍不会实际眩晕。

### 2.3 硬免疫来源

扫描当前 268 个 tactical entity 脚本，19 个实体直接设置
`BaseProperties.IsImmuneToStun = true`，其中 16 个敌方实体、3 个战术目标。主要包括：

- Ghost、Ghost Knight、Flying Skull；
- Sand Golem、Greater Flesh Golem；
- Schrat、Schrat Small；
- Lindwurm 本体和尾巴；
- Kraken；
- Skeleton Lich、Mirror Image、Phylactery；
- Flesh Cradle、Spider Eggs、Trickster God；
- Donkey、Greenskin Catapult、Mortar 等战术目标。

技能层还可临时或常驻提供硬免疫：

- `effects.indomitable`
- `perk.battering_ram`

若实现只是无条件忽略 `IsImmuneToStun`，这些主动防御和天赋也会一并失效。

### 2.4 状态抗性不是硬免疫

`stunned_effect.onAdded()` 在硬免疫之外还有两个独立摇脱判定：

- `IsResistantToAnyStatuses`：50%；
- `IsResistantToPhysicalStatuses`：33%。

推荐的新被动只穿透硬免疫，保留这两个概率抗性，除非用户明确要求“连状态抗性也无效”。

## 3. 玩家可获得的眩晕攻击

扫描当前 743 个 item 脚本，确认玩家武器可提供以下六个眩晕技能：

| ID | 名称 | 原版眩晕规则 |
| --- | --- | --- |
| `actives.knock_out` | Knock Out | 75%；Mace Mastery 时 100%，1 回合 |
| `actives.knock_over` | Knock Over | 75%；Mace Mastery 时 100%，1 回合 |
| `actives.strike_down` | Strike Down | 75%；Mace Mastery 时 100%，2 回合 |
| `actives.overhead_strike` | Overhead Strike | 读取武器的 `StunChance`；普通值可为 0 |
| `actives.pound` | Pound | 30%，1 回合 |
| `actives.thresh` | Thresh | 每个实际命中目标 20%，1 回合 |

推荐只允许这六个 ID 进入穿透逻辑，并继续由原技能自己的 RNG、Mace Mastery、命中结果和持续
时间决定是否眩晕。普通攻击及没有 `StunChance` 的技能不应获得新眩晕能力。

## 4. 推荐实现（已按此落地）

### 4.1 被动

首版候选 ID `effects.bbca_stun_piercer` 已废弃，不得恢复为独立序列化技能。当前采用
BB-Custom 技能编辑器中 Aegis 的 v5 `StunPiercer` 布尔开关；它仍是玩家侧能力，不改原版
perk tree。

### 4.2 一次技能执行上下文

用 `mods_hookClass("scripts/skills/skill", ...)` **包装**原版 `use()`，不复制完整函数。

仅当以下条件同时成立时开启短暂上下文：

1. 施法者拥有 `effects.bbca_negative_immunity`，且其隐藏配置
   `effects.bbca_negative_immunity_config.m.StunPiercer` 为 true；
2. 当前技能 ID 在六项 allowlist 中；
3. 当前执行是同步攻击路径。

包装器在正常返回和异常路径都必须清理上下文及所有临时目标状态。Squirrel 没有可靠的
`finally` 使用惯例时，应在正常分支和 `catch` 分支显式调用同一清理函数，再重新抛出异常。

### 4.3 攻击者 `onTargetHit`

被动使用最窄的 `onTargetHit`：

- 每个实际命中的目标单独处理，因此兼容 `Thresh` 多目标；
- 仅在目标当前 `IsImmuneToStun` 且满足安全范围时，暂时把目标当前属性中的该字段设为
  `false`；
- 记录目标、原值和攻击者/技能上下文，供 `use()` 包装器结束时恢复；
- 不自行掷眩晕概率，让原技能继续执行原版 RNG、Mace Mastery、时长、日志和成就逻辑。

### 4.4 标记具体 `stunned_effect`

Hook `scripts/skills/effects/stunned_effect`：

- `onAdded()` 在当前穿透上下文与目标吻合时，把该效果实例加入
  `::BBCA_StunPiercer.MarkedStuns`；
- 不向原版 `stunned_effect.m` 写入新字段，避免旧档反序列化布局风险；
- 调用原 `onAdded()` 时只为该实例临时压低目标的硬免疫，保留 50%/33% 状态抗性；
- `onUpdate(_properties)` 对带标记实例临时绕过硬免疫，随后恢复目标原属性；
- 未标记的所有原版眩晕完全保持原行为。

标记必须在 `skill_container.add()` 触发 `onAdded()` 前可见；不能在效果加入后才补写。

### 4.5 推荐安全边界

当前采用的安全边界：

- 只对敌对、可战斗 actor 生效；
- 穿透目标当前硬性 `IsImmuneToStun`，不再要求 `BaseProperties.IsImmuneToStun = true`；
- `perk.battering_ram` 不再是硬停止项；兽人狂战士、兽人战士等靠该 perk 免疫眩晕的敌人
  是预期穿透目标；
- 保留 `effects.indomitable` 提供的临时主动防御免疫；
- 保留 50%/33% 状态抗性；
- 排除 `isNonCombatant()`、`IsMovable = false`、战术目标和多部位首领；
- 因而默认不穿透 Kraken、Lindwurm 本体/尾巴、Flesh Cradle、Phylactery、Spider Eggs、
  Catapult、Mortar 等对象。

若用户明确要“任何怪物，包括首领，都能被晕”，应作为更激进的独立开关，并单独回归首领
脚本、回合 AI、部位联动和胜负条件。

## 5. 不推荐方案

- **只 Hook `stunned_effect`**：攻击技能在创建效果前已经因免疫返回。
- **被动 `onUpdate` 永久把目标免疫改成 false**：属性属于目标，没有攻击者来源，会让所有人
  的眩晕都穿透。
- **在 `onTargetHit` 自己重新掷概率并创建眩晕**：可以运行，但会复制六个技能的 RNG、
  Mace Mastery、两回合 Strike Down、日志和成就语义，游戏升级后更易漂移。
- **完整覆盖六个 `onUse()` 或原版 `skill.use()`**：兼容风险过高；窄包装足够。
- **直接改怪物 entity 基础属性**：会全局移除免疫，不满足“只由拥有该被动的玩家穿透”。

## 6. 当前兼容性

只读扫描新机 Steam `data\` 中所有活动 `.zip`：

- 没有其他活动模组 Hook `stunned_effect` 或实现攻击者侧眩晕免疫穿透；
- 当前 BB-Custom 只有 Aegis 被动会给玩家设置 `IsImmuneToStun = true`；
- 当前重做 build SHA-256 为
  `51283EBD86A105CDA9260B91128412F2A6D828108255735EBAAF66112CC72C9A`；
- Steam 包已安装本次 Battering Ram 穿透调整；安装前已确认游戏关闭。

## 7. 已采用的产品选择

1. 作为 Shift+X 可授予被动，不修改原版升级 perk tree。
2. 穿透敌人当前硬眩晕免疫，包含 Battering Ram；保留 Indomitable。
3. 保留 50%/33% 状态抗性。
4. 默认排除不可移动首领、多部位实体、非战斗单位和战术目标。
5. 被动显示英文战斗 tooltip，复用原版 `skills/passive_03.png`，不增加位图依赖。

## 8. 实现与验证清单

已完成：

1. 新增序列化被动并加入唯一 `::BBCA_SkillCatalog`。
2. 新增 preload Hook，包装 `skill.use` 和 `stunned_effect`。
3. 对新增/修改 `.nut` 使用 disposable `bbsq.exe -e` 编译。
4. 构建并检查最终 ZIP 的 ID、路径、allowlist、Hook、图标和无完整函数复制。
5. 静态检查所有临时属性在正常/异常路径均恢复，并确认嵌套 `skill.use` 会暂停父上下文。
6. 最终 ZIP 的 15 份 `.nut` 全部二次编译；召唤稳定契约未回退。

仍待游戏内：

1. 分别测试六个技能：命中/未命中、眩晕成功/概率失败、Mace Mastery、Strike Down
   两回合、Thresh 多目标。
2. 测试普通敌人、先天免疫怪、Battering Ram 敌人、Indomitable、50%/33% 状态抗性。
3. 确认 Kraken、Lindwurm、多部位实体、不可移动对象、非战斗单位和战术目标仍被排除。
4. 测试多个拥有/不拥有被动的兄弟攻击同一目标及嵌套攻击，确认穿透不泄漏。
5. 保存/读档、战斗结束清理及 `log.html` 无 `Script Error`。

未经用户明确要求，不安装到 Steam；安装前确认 `BattleBrothers.exe` 已关闭；绝不修改任何
`.bbca-backup`。
