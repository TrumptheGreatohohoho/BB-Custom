# FantasyBro：技能书授予机制与 Shadow Walk

分析对象：
`D:\games\Battle Brothers v1.5.0.15\data\mod_fantasybro-473-4-2b-1722856556.zip`

本文只记录静态代码分析结论，未启动游戏、未安装模组，也未修改游戏文件。

## 结论摘要

FantasyBro 的“技能书”不是通过 Breditor 授予技能，而是 Battle Brothers 的标准可使用物品机制：物品被右键使用或拖到当前选中角色的身体栏时，游戏把该角色传入物品的 `onUse(_actor)` 回调。

需要弹出选择菜单的技能书会先给目标角色添加一个临时隐藏状态作为标记，然后触发世界事件。事件扫描玩家队伍，找到带标记的角色，在选择完成后移除其旧的 FantasyBro 特殊技能、添加新技能，并清除标记。

可由技能书学到的传送技能是 **Shadow Walk**，脚本为 `scripts/skills/actives/sb_shadowwalk_skill.nut`。

## 技能书脚本

| 物品 | 脚本 | 行为 |
| --- | --- | --- |
| Skill Book | `scripts/items/misc/xxsbook.nut` | 95% 直接随机授予，5% 打开完整技能选择；重复使用会提高日薪或扣钱。 |
| Epic Skill Book | `scripts/items/misc/xxsbook_se.nut` | 打开完整技能选择，无重复惩罚。 |
| Rare Skill Book | `scripts/items/misc/xxsbook_sp.nut` | 15% 打开完整技能选择；其余情况为四选一或随机。 |

三者都设置为标准可用物品：

```squirrel
this.m.ItemType = this.Const.Items.ItemType.Usable;
this.m.IsUsable = true;
```

其提示文字也明确说明用法：右键使用，或将物品拖到当前选中角色的身体栏。游戏随后调用：

```squirrel
function onUse( _actor, _item = null )
```

其中 `_actor` 就是本次使用技能书的目标兄弟。

## 完整选择流程

### 1. 标记目标角色并触发事件

以 Epic Skill Book 为例：

```squirrel
local chk = _actor.getSkills();
chk.add(this.new("scripts/skills/actives/xxzzcheck_skill"));
::World.State.getMenuStack().popAll(true);
::World.Events.fire("event.xxzzskillbook_event");
```

相关事件为 `scripts/events/events/xxzzskillbook_event.nut`。

`xxzzcheck_skill` 定义于 `scripts/skills/actives/xxzzcheck_skill.nut`。其 ID 为 `effects.xxzzcheck_skill`，特点是：

- 隐藏；
- 不序列化到存档；
- 战斗开始、回合开始或回合结束时自动移除；
- 仅用于把“本次学习技能的目标是谁”传递给后续事件。

### 2. 事件找回目标角色

事件的 `onUpdateScore()` 扫描玩家 roster：

```squirrel
foreach( bro in this.World.getPlayerRoster().getAll() )
{
    if (bro.getSkills().hasSkill("effects.xxzzcheck_skill"))
    {
        candidates.push(bro);
    }
}
```

一般只有刚使用书的角色带标记，因此该角色会成为事件中的技能学习者。代码在没有标记时会退化为从全队随机选择一人；这是异常回退路径，而非正常流程。

### 3. 选择后替换特殊技能

事件使用包含 111 个 `sb_*` / `sbp_*` / `sbq*` 技能脚本名的白名单。玩家选定技能后，代码会：

1. 移除该角色已拥有的所有白名单内 FantasyBro 特殊技能；
2. 根据选择实例化新技能；
3. 添加到该角色的技能容器；
4. 移除临时标记。

核心逻辑：

```squirrel
chk.removeByID("actives." + oldSkill);
chk.add(this.new("scripts/skills/actives/" + selectedSkill));
actor.getSkills().removeByID("effects.xxzzcheck_skill");
```

因此该模组的设计是：一个角色同一时间只保留一个这套 FantasyBro 特殊技能，而不是无限叠加。

### 4. 普通技能书的直接随机分支

`xxsbook.nut` 的高概率分支直接调用全局函数 `FantasySpellbookact(_actor)`，定义于：

`scripts/!mods_preload/!config/mod_xx_config.nut`

该函数会移除已有的 FantasyBro 特殊技能，从剩余候选里随机取一个并加入角色技能容器。此路径不弹出选择事件。

## 技能书的来源

FantasyBro 自己的商店池会加入普通技能书：

`scripts/entity/world/settlements/buildings/xxmarketplace_building.nut`

其中以 `misc/xxsbook` 注册进货物列表。稀有与史诗书还可由模组的事件、场景或 Arena 相关内容给予。

## Shadow Walk（暗影步）

脚本：`scripts/skills/actives/sb_shadowwalk_skill.nut`

技能 ID：

```squirrel
this.m.ID = "actives.sb_shadowwalk_skill";
```

它在技能书事件和随机授予函数的特殊技能白名单中，因此可由技能书学习。

### 属性

| 属性 | 值 |
| --- | --- |
| 名称 | Shadow Walk |
| AP 消耗 | 4 |
| 疲劳消耗 | 30 |
| 最小 / 最大距离 | 1 / 6 格 |
| 最大高度差 | 1 |
| 冷却 | 9 回合 |
| 目标 | 空地；不是目标角色 |
| 视野 | 不要求目标格对玩家可见 |

技能描述写为“忽略控制区并传送至目标格”。实际 `isUsable()` 还额外禁止角色处于敌方近战控制区时使用，因此更准确的理解是：它可以越过控制区，但不能从已被近战缠住的状态中发动。

目标验证仅额外检查目标格为空：

```squirrel
function onVerifyTarget( _originTile, _targetTile )
{
    if (!_targetTile.IsEmpty)
    {
        return false;
    }
    return true;
}
```

距离、高度差和基础目标合法性由技能框架属性及游戏引擎处理。

### 传送实现

实际位置变更通过战术导航器完成：

```squirrel
this.Tactical.getNavigator().teleport(
    _tag.User,
    _tag.TargetTile,
    _tag.OnDone,
    _tag,
    false,
    2.0
);
```

完整效果顺序：

1. 使用后将冷却计数归零；
2. 在起点播放原版吸血鬼 `Darkflight` 粒子；
3. 角色立绘淡出为透明，等待 400 ms；
4. 调用 `Tactical.getNavigator().teleport(...)` 移至目标格；
5. 在终点播放粒子、落地声音和镜头移动；
6. 角色在约 500 ms 内淡入并恢复原始立绘颜色。

代码日志文本仍写作 `uses Darkflight`，说明该效果复用了原版吸血鬼 Darkflight 的视觉与声音资源；它不是另一项独立技能。

冷却采用递增计数：初始值为 9，使用时清零，每回合加 1，达到 9 后才重新可用。

## 不要混淆的内部传送

`scripts/skills/actives/ai_damaged_teleport.nut` 也叫 **Emergency Teleport**，但不是玩家可学习的主动技能。它是隐藏 AI/怪物效果：角色受到超过 5 点生命伤害时，随机寻找当前格周围约 5–7 格远的可站立空格，然后直接调用同一个 `Tactical.getNavigator().teleport(...)` 逃离。

FantasyBro 中的冲锋、击退、拉拽等其他技能也会调用 `teleport`，那是用战术导航器移动攻击者或目标的实现手段，不代表它们都是“传送技能”。

## 可复用的设计模式

若未来需要实现自己的“技能书授予技能”，可复用下列模式：

```text
Usable item
  → onUse(_actor)
  → 给 _actor 添加隐藏临时标记
  → World.Events.fire(...)
  → 事件用标记确定目标角色
  → actor.getSkills().add(newSkill)
  → 清除标记
```

是否移除旧技能应按新功能的规则单独设计；FantasyBro 的“先清空同类特殊技能”并不是该模式的必要步骤。
