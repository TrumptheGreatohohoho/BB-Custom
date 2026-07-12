# FantasyBro 技能制作分析报告

分析对象：`参考/mod_fantasybro-473-4-2b-1722856556.zip`  
版本标识：FantasyBro 4.2b（来自文件名）  
分析日期：2026-06-28

## 1. 范围与结论

压缩包共有 759 个条目，其中 464 个脚本、291 个图形资源。技能目录包含：

| 类别 | 文件数 | 说明 |
| --- | ---: | --- |
| `scripts/skills/actives` | 177 | 玩家技能、AI 技能、装备技能和若干辅助技能混放 |
| `scripts/skills/effects` | 25 | 增益、减益、施法者/目标配对状态 |
| `scripts/skills/backgrounds` | 12 | 自定义角色背景 |
| 技能书可授予技能 | 111 | 80 个主动/特殊技能，31 个被动技能 |

这不是一个独立“技能包”，而是完整大型模组的一部分。很多技能依赖自定义 effect、实体、地块、
物品、粒子、声音和世界状态。适合借鉴实现模式，不适合把整个 FantasyBro 当作 BB-Custom
运行时依赖。

中文逐技能图鉴见 `docs/fantasybro-skill-catalog.html`。

## 2. 技能装载链

### 2.1 模组注册

`scripts/!mods_preload/mod_xxpreload.nut`：

1. 注册 `mod_fantasybro`。
2. 通过 `mods_queue("mod_fantasybro", ">mod_legends", ...)` 安排 Hook。
3. 扩展 AI 可用技能。
4. Hook UI tooltip、战术角色渲染和世界资产管理器。

`>mod_legends` 是排序表达式，不等于严格依赖声明；源码中没有发现其他
`mod_legends`/MSU API 直接引用。

### 2.2 技能书目录

`scripts/!mods_preload/!config/mod_xx_config.nut` 的 `FantasySpellbookact` 和两个技能书事件
各自维护一份技能文件名数组。授予时动态执行：

```squirrel
chk.add(this.new("scripts/skills/actives/" + sk_type));
```

因此文件名、`this.m.ID`、去重 ID 和事件页索引必须一致。当前实现把同一份 111 项目录复制到
多个文件，扩展时容易发生漂移。

## 3. 单个技能的基本结构

典型主动技能继承 `scripts/skills/skill`：

```squirrel
this.example_skill <- this.inherit("scripts/skills/skill", {
    m = {
        Cooldown = 3,
        Skillcool = 3
    },

    function create()
    {
        this.m.ID = "actives.example_skill";
        this.m.Name = "Example";
        this.m.Description = "...";
        this.m.Type = this.Const.SkillType.Active;
        this.m.IsSerialized = true;
        this.m.IsActive = true;
        this.m.IsTargeted = true;
        this.m.ActionPointCost = 4;
        this.m.FatigueCost = 20;
        this.m.MinRange = 1;
        this.m.MaxRange = 3;
    }
});
```

核心契约：

- `ID`：容器去重、查找和存档兼容接口。
- `Type` / `IsActive` / `IsTargeted` / `IsAttack`：决定 UI 与原版攻击流程。
- `ActionPointCost` / `FatigueCost` / `MinRange` / `MaxRange`：基础资源与选格。
- `Icon` / `IconDisabled` / `Overlay`：必须有对应 `gfx/ui` 资源。
- `IsSerialized = true`：让授予角色的技能随存档保留。

## 4. 主动技能实现模式

### 4.1 原版攻击管线复用

火球、巨石、飞踢等技能通常在 `onUse` 中调用：

```squirrel
this.attackEntity(_user, target, false);
```

并通过 `onAnySkillUsed` 临时修改 `_properties`：

- 固定伤害上下限；
- 改变穿甲与破甲倍率；
- 增加命中；
- 强制只打身体或头部；
- 取消远程阻挡；
- 读取角色等级或当前武器属性。

这种模式能复用原版命中、伤害、事件和动画，但会受到其他模组对 `skill.attackEntity` 的影响。

### 4.2 多目标与范围

常见实现有三类：

1. `getAffectedTiles` 构造六角格区域，例如火球与净化烈焰。
2. 沿方向逐格查找，例如冲击波与贯穿射击。
3. 遍历战术实体或邻格，筛选敌我阵营，例如旋风斩与奇迹。

范围技能通常同时实现 `onTargetSelected`，用
`Tactical.getHighlighter().addOverlayIcon` 显示预览。

### 4.3 延迟事件与动画

31 个技能使用 `Time.scheduleEvent`，共发现 66 处调用，用于：

- 等待弹道结束后结算伤害；
- 连续多段攻击；
- 先播放粒子，再应用 effect；
- 传送完成后攻击或击退；
- 延迟两回合的炮击。

异步 tag 应显式保存 `Skill`、`User`、`TargetTile`、目标引用和回调。执行前要再次检查角色是否
存活、目标格是否仍占用、目标是否仍可攻击。

### 4.4 位移技能

暗影行走、背刺、破阵、抓取、换位和飞踢主要使用
`Tactical.getNavigator().teleport`。可靠实现需要同时处理：

- 目标格为空和高度差；
- 定身与控制区；
- 移动前后攻击机会；
- 目标死亡或落点在延迟期间改变；
- `Container.setBusy(true/false)` 成对恢复；
- 相机、淡入淡出和粒子资源。

### 4.5 冷却

FantasyBro 常用：

```squirrel
m = { Cooldown = 5, Skillcool = 5 }
```

- `onUse`：`Skillcool = 0`
- `onTurnStart`：递增
- `isUsable`：比较 `Skillcool < Cooldown`
- `onCombatFinished`：恢复为可用

技能书 111 项中，44 项实现 `onTurnStart`，61 项实现 `onCombatFinished`。这种冷却只要求跨回合，
不依赖战斗外存档；若 BB-Custom 以后允许战斗中保存或持久化参数，应使用独立序列化配置。

## 5. 被动技能实现模式

31 个被动技能仍放在 `actives` 目录，ID 也使用 `actives.*`，但设置：

```squirrel
this.m.Type = this.Const.SkillType.StatusEffect;
this.m.IsActive = false;
this.m.IsSerialized = true;
```

主要回调：

- `onUpdate(_properties)`：常驻属性、装备条件、士气或疲劳阈值。
- `onAnySkillUsed(...)`：只在本次攻击/技能结算时改变属性。
- `onBeingAttacked(...)`：根据攻击者或攻击技能调整防御。
- `onTargetHit(...)`：吸血、爆头回疲劳、追加伤害。
- `onTargetKilled(...)`：击杀奖励。
- `onCombatStarted/Finished`：开局代价和战后恢复。

应优先选择最窄的回调。只影响某次攻击的逻辑不要放入全局 `onUpdate`，否则会影响其他技能。

## 6. 配套 effect 模式

49 个技能直接引用自定义 `scripts/skills/effects`，共 84 次。常见形态：

- 单一增益：`sb_bloodlust_effect`、`sb_great_effect`。
- 施法者/目标配对：`sb_sguard_effect_caster/target`、
  `sb_snake_caster/target`。
- 临时控制：寒冷、隐藏、狂怒。
- 持续回合与刷新：effect 自己维护持续时间，在 `onTurnStart` 或 `onTurnEnd` 移除。

移植技能时必须从 `new("scripts/skills/effects/...")`、`add(...)`、`removeByID(...)` 和
`hasSkill(...)` 反向追踪完整依赖，不能只复制主动技能文件。

## 7. 资源和外部依赖

技能常用资源：

- `gfx/ui/*.png`：启用/禁用图标；
- `sounds/...`：使用、命中、移动音效；
- `Const.Tactical.*Particles`：原版粒子；
- 自定义 `Const.ProjectileType` 与 sprite；
- 自定义召唤实体；
- 自定义物品、城镇、阵营和世界 Flags。

技能书目录中：

- 53 个技能引用 `Const.Tactical`；
- 31 个技能使用延迟事件；
- 49 个技能依赖自定义 effect；
- 3 个技能直接生成自定义实体。

因此可移植性应分级：

| 等级 | 特征 | 示例 |
| --- | --- | --- |
| A | 单文件、原版属性回调 | 敏捷杀手、全能者、生命汲取 |
| B | 单技能 + 图标，使用原版 effect/API | 踢击、扬沙、战吼 |
| C | 主技能 + 自定义 effect/成对状态 | 嗜血术、盾牌守护、巨蛇束缚 |
| D | 自定义实体/地形/世界状态 | 召唤恶魔、洪水炸弹、宣传活动 |

BB-Custom 首选 A/B，C 必须打包完整依赖，D 应单独立项。

## 8. 发现的实现风险

### 高风险

1. **技能书事件会删除已有技能。**  
   `xxzzskillbook_event.nut:1857` 和 `xxzzskillbook2_event.nut:213` 在发现角色已有技能时调用
   `chk.removeByID(skname)`，没有从候选数组移除。打开技能书可能先删掉已有 FantasyBro 技能。

2. **武术打击 ID 不一致。**  
   `sb_strike_skill.nut` 文件和技能书期望 `actives.sb_strike_skill`，实际设置为
   `actives.ai_punch`。去重、查询和与 AI 技能共存都会异常。

3. **原版渲染函数被完整覆盖。**  
   `mod_xxpreload.nut` 重写战术 actor 的 `onRender`。游戏版本或其他模组修改原函数后，极易产生
   兼容问题。移植单个技能时不要复制这段全局覆盖。

### 中风险

4. `FantasySpellbookact` 删除候选数组时仍递增索引，连续已有技能可能被跳过。
5. 三处独立维护 111 项数组，新增/删除技能容易索引错位。
6. 宣传活动对敌人调用 `Math.rand(-1, -2)`，参数顺序可疑；在严格实现中下界大于上界会报错。
7. 大量延迟闭包直接捕获局部格子和角色，没有统一弱引用/存活检查。
8. 部分范围技能允许敌我同时受伤，tooltip 未必完整提示友伤。
9. 111 项没有自定义 `onSerialize/onDeserialize`；当前仅依赖技能本身序列化和战后重置。
10. 被动技能使用 `actives.*` ID 虽可运行，但语义混乱，未来编辑器应显式记录类型而不是按 ID
    前缀判断。

## 9. 对 BB-Custom 的推荐制作规范

### 9.1 一个技能一个稳定 ID

- 主技能：`actives.bbca_<name>`
- 被动状态：`effects.bbca_<name>`
- 持久参数：`effects.bbca_<name>_config`
- ID 发布后不重命名。

### 9.2 参数与战斗逻辑分离

可编辑参数写入隐藏序列化 config；战斗技能只读取 config。不要直接依赖 UI 临时对象。

### 9.3 明确技能清单

使用一个结构化 catalog 作为唯一权威，至少包含：

- ID、脚本路径、显示名、类型；
- config ID 与脚本；
- 可编辑参数、默认值、上下限；
- 依赖资源和配套 effect；
- 存档迁移版本。

UI、授予逻辑和文档从同一 catalog 生成，避免复制多份数组。

### 9.4 分层验证

1. Squirrel 语法编译。
2. ID、脚本路径和资源存在性。
3. 依赖闭包检查。
4. 包内路径检查。
5. 游戏内授予、读档和参数保存。
6. 近战/远程、友军/敌军、死亡目标、定身、控制区和高度差边界。
7. 日志无 `Script Error`。

## 10. 建议的后续路线

1. 从图鉴中选择 3～5 个 A/B 级技能进入 BB-Custom。
2. 先扩展技能 catalog 的类型和依赖字段，再复制技能。
3. 每个技能建立独立配置和最小回归场景。
4. C 级技能按“主技能 + effect + 图标 + 声音”的闭包移植。
5. D 级技能不要混入当前轻量编辑器，应作为独立模组功能开发。

本次分析没有把 FantasyBro 安装到游戏，也没有修改参考压缩包。
