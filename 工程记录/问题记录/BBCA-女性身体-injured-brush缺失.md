# 问题：自定义 body 缺派生 brush `_injured` / `_dead`

**状态**：**已修复、已构建、已部署**（2026-09-23）；仅剩游戏内目视确认
**严重度**：低 —— 外观/日志噪音，不影响技能、数值与存档兼容
**影响范围**：使用 Custom Appearance 自定义 `body` 的角色（`bbca_female_body_01`、`_02`）

> 本档案保留完整根因分析（仍有参考价值），修复与验收结果见第 5、6 节。
> 原始标题只写了 `_injured`；追查中发现 `_dead` 是同一根因的第二处，故一并修复。

## 1. 现象

2026-08-15 会话日志中 `SceneManager` 共 9 行，全部是：

```
[13:18:21][SceneManager] Unknown Brush requested: bbca_female_body_01_injured
```

日志：`D:\games\Steam\steamapps\common\Battle Brothers\log.html`
（本机日志在**游戏安装根目录**，不是 `Documents\Battle Brothers`。）

## 2. 根因（已用当前游戏 1.5.2.3 反编译原版确认）

游戏从**当前生效的 body brush 名**派生受伤与尸体图层：

1. `scripts/entity/tactical/player.nut`（约 698–707 行）——本次警告的直接触发点：

   ```nut
   if (p > 0.4) { injury_body.Visible = false; }
   else {
       injury_body.Visible = true;
       injury_body.setBrush(this.getSprite("body").getBrush().Name + "_injured");
   }
   ```

   即生命值 ≤ 40% 时按当前 body brush 名派生受伤 brush。

2. `scripts/entity/tactical/human.nut:117` 与 `player.nut:956` —— 尸体图层同源派生，
   且**没有** `doesBrushExist` 保护：

   ```nut
   local decal = _tile.spawnDetail(sprite_body.getBrush().Name + "_dead", ...);
   ```

3. `scripts/skills/backgrounds/character_background.nut`（约 403–408 行）——出场/换装时同样派生
   `<body> + "_injured"`。

BBCA 把 body 换成 `bbca_female_body_01` 后，派生名落在 BBCA 的 brush 里，而该 brush 只有
14 个基础精灵，于是受伤/尸体刷子必然缺失。

**判定不需要补 `_dead_arrows` / `_dead_javelin`**：这两个 decal 取自
`appearance.Corpse` / `appearance.CorpseArmor`（`human.nut:186/199`、`player.nut:1004/1015`），
而 BBCA 从不改写 `m.Bodies`（`human.nut:501` 的 `app.Corpse = m.Bodies[Body] + "_dead"`）
或 `appearance.Corpse`（已全仓库 grep 确认），所以它们始终解析为原版名。

## 3. 证据：资产侧确实没有派生 brush

| 检查 | 结果（修复前） |
| --- | --- |
| `manifest.json` | 14 个 sprite，无 `_injured` / `_dead` |
| 全仓库源码 grep `injured` | 0 命中（只有 `build/` 里反编译的原版脚本命中） |
| 构建 ZIP | 36 条目，`injured` 出现 0 次 |
| `bb_custom_appearance.brush` 内嵌刷子名 | 14 个，全部无后缀 |

## 4. 资产来源判定（结论：不需要新画素材）

逐像素比对（差异像素数）：

| BBCA sprite | 上游 FantasyBro sprite | 差异 |
| --- | --- | --- |
| `bbca_female_body_01` | `bust_naked_body_7869` | **0** |
| `bbca_female_body_02` | `bust_naked_body_7870` | **0** |

FantasyBro `metadata.xml` 中这两个精灵的几何与 `ic` 与 manifest **逐字段一致**
（7869：W104 H142 T-48 B10 offY35 ic FF4D7120，无 left/right；7870：L-39 R43 T-51 B9 ic FF609570）。

关键发现：**FantasyBro 自己就把同一张 `bust_naked_body_7870_injured.png` 复用给 10 个身体**
（含 `7869_injured`），该图与**原版 `bust_naked_body_02_injured.png` 字节完全相同**；
`_dead` 用的才是 FantasyBro 自有尸图（`bust_naked_body_7870_dead.png`）。
因此沿用上游既有图形是忠实做法，也符合"造型资产来自 FantasyBro"的既有来源约定。

## 5. 修复（2026-09-23 已完成）

- 新增 4 个受管精灵，几何与 `ic` 照抄 FantasyBro 的 `7869`/`7870` 对应定义：

  | id | 来源图 | 尺寸 | ic |
  | --- | --- | --- | --- |
  | `bbca_female_body_01_injured` | 7870_injured | 80×60 | `FF4D7124` |
  | `bbca_female_body_02_injured` | 7870_injured | 80×60 | `FF0E0E77` |
  | `bbca_female_body_01_dead` | 7870_dead | 131×110 | `FF4D7121` |
  | `bbca_female_body_02_dead` | 7870_dead | 131×110 | `FF374D77` |

- 新增 `hidden` manifest 标记 + 构建脚本支持：隐藏精灵**进 brush 但不进 `::BBCA_Catalog`**。
  这是必需的，因为后端 `bbca_isCatalogBrush()` 会用 catalog 校验用户 APPLY —— 若把派生刷子
  混进 catalog，它们会出现在 `Shift+X` 面板并可被当普通外观应用。
- 构建结果：brush 含 **18** 个刷子名（14 可见 + 4 隐藏），catalog 仍 **14** 项，ZIP 仍 36 条路径。
- 构建大小 `245140` 字节，SHA-256
  `2E6975CAE6B67D2A1EE26C84C1B1EEA04D46080508BE19932CDA27A81BE2DA39`，
  与 Steam 已装包同哈希；安装前后 `BattleBrothers.exe` 未运行，5 个 `.bbca-backup` 逐字节未变。

## 6. 验收

**已完成的静态验收（不需要进游戏）**

- `tools/assert_custom_appearance_pack.ps1`：**70 项断言 0 失败**。
- **pack → unpack 往返**：最终 brush 解包后，18 个精灵**逐像素**与 manifest 原图一致
  （字节差异只是 bbrusher 重新编码 PNG）。
- 与 2026-07-10 旧构建的解包结果比对：原有 14 个精灵几何**漂移 0**，只新增 4 个 id、无删除。
- 生成的 preload `.nut` 通过 disposable `bbsq.exe -e`。

**仍需人工游戏内确认（唯一剩余项）**

1. 载入有自定义女性身体兄弟的存档，让该角色生命值降到 40% 以下。
2. 让该角色阵亡，产生尸体。
3. 检查 `log.html`：**不再**出现任何 `Unknown Brush requested`（尤其
   `bbca_female_body_01_injured` / `_dead`）。
4. 目视确认受伤图层与尸体外观正常；`bbca_female_body_02` 角色同样测一遍。

## 7. 遗留观察（非本次回归）

- `bbca_female_hair_05` 的 `left`/`right` 在 manifest 中为 `-30`/`30`，但 bbrusher 打包后
  写成空值。2026-07-10 的旧构建**完全相同**，故与本次改动无关，本次未追查。
- 尸体上的箭矢/标枪贴花用的是原版 body 名（见第 2 节），因此自定义身体角色的箭矢贴花
  仍按原版身体对齐；若日后发现错位，属于这一条，而不是缺少派生 brush。
