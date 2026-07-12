# 接手说明 / START HERE（换机器先读这一篇）

这是 Battle Brothers 的「自定义造型 + 技能编辑器」便携工程。本工程自包含，
不依赖 FantasyBro 运行时；面向 Steam 正版 Battle Brothers。

> 给新机器上的大模型：先完整读本文件，再按 `docs/README.md` 的顺序读取核心工程记忆。
> 然后按用户的具体任务行动。未经用户明确要求，不要写入 Steam 游戏目录。

---

## 1. 这是什么

按 `Shift+X` 打开 Breditor，右侧出现两块面板：

- **CUSTOM APPEARANCE**：给选中的兄弟换 body / head / hair / beard 四层透明 PNG
  brush。资产在 `asset_repo/custom_appearance`，构建成 `.brush` + 图集后注入。
- **技能编辑器**：下拉选技能 → 改参数 → 「授予技能 / 保存参数」。布尔项是
  「绿=开启 / 红=关闭」的一键切换按钮。目前五个技能：
  - **Shadow Walk**：传送主动技能（AP / 疲劳 / 距离 / 冷却 / 缠斗或定身时是否可用 可调）。
  - **燃烧手雷 (Fire Grenade)**：不消耗物品的主动投掷技能；燃烧半径 0–4 可调（默认 2），
    AP / 疲劳 / 投掷距离 / 高度差 / 冷却 / 火焰持续时间也可调。
  - **召唤装甲复生者 (Summon Zombie)**：在附近空地召唤由友方 AI 控制的装甲复生者；
    默认最多维持 3 个，AP / 疲劳 / 距离 / 高度差 / 冷却 / 最大数量可调。
  - **异常免疫 (Aegis)**：隐藏被动，逐项免疫负面效果（见第 5 节）。
  - **Hard Chance**：最终命中/闪避加值，支持 100% 硬命中与 100% 硬闪避，并在回合开始
    清空当前疲劳。

Breditor 的 `Legendary` 装备列表还包含两件独立装备：

- **自愈圣饰链甲衫**：圣饰链甲衫外观，270 耐久，每回合恢复 90，战后回满。
- **自愈纹章尖顶盔**：蓝羽纹章尖顶盔（红装）外观，270 耐久，每回合恢复 90，战后回满。

还内置了「命中率 0–100」行为
（`mod_source/.../scripts/!mods_preload/mod_bbca_hitchance_100or0.nut`），随 pack 一起，
**不需要**单独的第三方运行时包。

---

## 2. 运行环境 + 适配（最关键的一步）

- 系统：Windows + PowerShell 5.1 或更高。
- 游戏：Steam 正版 Battle Brothers，至少正常启动过一次。
- 工具：随包自带 `_tools/bbros/bin/`（`bbrusher.exe` / `bbsq.exe` / `nutcracker.exe`），
  **无需另装**；**不需要 Node.js**。
- 工程放哪个盘哪个目录都行（脚本用相对工程根的路径）。

**唯一需要按本机适配的，是 Steam 游戏目录路径。**

- 最近核对机器的实际路径只记录在 `docs/current-state.md`，不要把它当作其他机器的默认值。
- 新机器多半是 `C:\Program Files (x86)\Steam\steamapps\common\Battle Brothers`，
  或某个 Steam 库所在的盘。
- 怎么找：Steam → 库 → 右键 Battle Brothers → 管理 → 浏览本地文件。
- 怎么确认对不对：该目录下必须有 `data\data_001.dat`。
- 安装用的 `.bat` 会提示你输入这个目录；PowerShell 脚本则用 `-GameDir "<路径>"` 传入。
  PowerShell 脚本中的默认 `-GameDir` 可能是某台开发机路径，**务必换成本机实际路径**。

---

## 3. 安装到游戏（部署）

1. **完全关闭** Battle Brothers（确认 `BattleBrothers.exe` 不在运行）。
2. 双击 `Install-Custom-Appearance-To-Steam.bat`，按提示输入本机 Steam 游戏目录。
3. 启动游戏 → 读档 → 按 `Shift+X`，右侧出现两块面板即成功。

安装做了什么：把 `build/custom_appearance/mod_bb_custom_appearance.zip`、打过补丁的
Breditor、Mod Hooks 写入游戏 `data\`。首次会为被替换的文件创建一次 `.bbca-backup` 备份；
**已存在的 `.bbca-backup` 永不覆盖**。

> `Install-...bat` 只安装、不构建，用的是已构建好的 `build/custom_appearance/`（已随包附带、
> 与源码同步）。改过源码/资产后要先重新构建（见第 4 节）。

---

## 4. 改资产 / 源码后重新构建

- 改 PNG 或技能源码后，二选一：
  - 跑 `Manage-Custom-Appearance-Assets.bat`（图形管理器，可导入 PNG、构建、安装）；
  - 或手动：`powershell -NoProfile -ExecutionPolicy Bypass -File tools\build_custom_appearance_pack.ps1`，
    再跑安装。
- 构建把 `mod_source` + `asset_repo` 打成新的 `mod_bb_custom_appearance.zip`。
- PNG 尺寸是严格校验值，见 `docs/png-asset-spec.md`。
- 构建会逐像素校验透明度；耗时随资产数量变化。

---

## 5. 当前功能状态（2026-06-28）

- **Custom Appearance**：body / head / hair / beard 四层，面板选 brush → APPLY。
- **Shadow Walk**：传送主动技能，参数可调。
- **燃烧手雷 (Fire Grenade)**：主动技能，复用原版火焰罐图标、投射物、声音和普通火焰地块。
  不消耗副手物品或金钱；燃烧半径可设为 0–4（最多 61 格），固定敌我同伤。参数保存在
  `effects.bbca_fire_grenade_config`，序列化版本为 **v2**；v1 读取时半径默认为 2。
- **召唤装甲复生者 (Summon Zombie)**：主动技能，复用原版 `zombie_yeoman` 实体、
  亡灵复活动画和声音。召唤物属于 `PlayerAnimals`，由友方 AI 控制，禁止自动复活，
  战斗结束后消失；启用/禁用图标已作为本包资源打包。参数保存在
  `effects.bbca_summon_zombie_config`，序列化版本为 **v1**。
- **异常免疫 (Aegis)**：隐藏被动状态/perk。逐项开关：
  - 默认开：中毒、流血、昏迷、茫然、定身/网、击退/抓取、缴械。
  - 默认关（按需逐人开）：换位、火焰、爆头、伤残、**压制(Overwhelm)**、**分心(Distracted)**。
    **吞噬（最高级食尸鬼）**。
  - 战斗内技能名与提示是英文 `Aegis` + 英文行（游戏战斗界面字体没有中文字形，中文会变方块）；
    `Shift+X` 编辑面板里仍是中文（面板字体我们能控制）。
  - 「压制 / 分心」原版没有免疫属性，用钩子实现：
    `scripts/!mods_preload/mod_bbca_overwhelmed_immunity.nut`、`mod_bbca_distracted_immunity.nut`。
  - 可选的 `StunPiercer` 允许六种原版眩晕攻击穿透符合条件的硬眩晕免疫；可选的
    `PassiveCounterattack` 会对相邻合法攻击安排一次原版还击流程，但移动触发的借机攻击
    不会再触发该反击。
  - 参数存在隐藏序列化技能 `effects.bbca_negative_immunity_config` 里，序列化已到 **v6**，
    **向后兼容老存档**。给已有 Aegis / Shadow Walk 的老角色升级后，需逐人点一次
    **保存参数**，把新字段写进存档。
- **Hard Chance**：隐藏被动 `effects.bbca_hard_chance`，配置
  `effects.bbca_hard_chance_config` 为 **v1**；`HardHitChance` / `HardEvasionChance`
  范围 0–100，状态图标默认隐藏。
- **独狼队伍上限**：内嵌 Mod Hooks 扩展把独狼开局的总 roster 与单场战术部署上限均改为
  **16**；不修改敌方规模参数，并把开局说明同步为 16 人。
- **命中率 0–100**：内置，随 pack。2026-06-28 已同步当前原版攻击流程。安装器会按精确
  SHA-256 识别并停用已知冲突的旧版独立补丁，修复盾墙攻击中断及链锤 AI 无法选择目标。

本机游戏版本、构建哈希、安装状态和待回归项统一记录在 `docs/current-state.md`，不要从本节
推断某台机器已经安装或已经完成游戏内验证。

---

## 6. 铁律（务必遵守，等同硬约束）

- **绝不**删除 / 覆盖 / 修改任何已存在的 `.bbca-backup` 文件。
- **绝不**在游戏运行时安装；每次安装前确认 `BattleBrothers.exe` 已关闭。
- 用户于 2026-07-12 授予本工程后续修改的常设部署授权：完成源码修改、所需 `.nut` 编译、
  标准构建和最终 ZIP 核验后，直接通过标准安装器更新 Steam，无需再次等待安装指令。每次安装前
  仍必须确认 `BattleBrothers.exe` 已关闭；该授权不允许手工复制、修改 `.bbca-backup`、改动
  未受管第三方包，或绕过安装器。
- **不要**把 FantasyBro 作为运行时依赖安装（造型资产与 Shadow Walk 源码已内置）。
- 游戏 `data\` 里第三方「狐狸汉化」补丁（如 `狐狸汉化适配-命中率改为0-100.zip`）及其
  `.bbca-backup` 是历史素材，未经明确要求**不要改**。
- 用户已于 2026-07-12 明确授权恢复本次汉化 UI 兼容；当前受管内容仅为
  `ui/world_names.js`、`ui/bbca_cn_ui_compat.js` 与 Breditor 的加载接入，用于提供菜单、提示和
  城镇界面所需的翻译全局函数。安装器会对精确 SHA-256 的旧 BBCA 一体包执行运行时停用，避免它
  覆盖受管脚本；未经新的明确范围，不扩展为通用汉化审计、翻译或发布工作。
- 不用 clone 启动器、`steam_appid.txt`、ASCII `SUBST` 路径或 Steam 重定向之类的 hack。

---

## 7. 想再加一个「免疫某 debuff」时怎么查原版效果

游戏脚本是编译过的，但能读：

1. `data\data_00X.dat` 其实是 **ZIP**；`data_001.dat` 里有
   `scripts/skills/effects/*.cnut`（约 100 个状态效果）。
2. 取出要看的 `.cnut`，逐个解：`bbsq.exe -d <文件>`（原地解密）→
   `nutcracker.exe <文件> > out.nut`（反编译）。工具在 `_tools/bbros/bin/`。
3. `_tools/bbros/bin/massdecompile.bat` 这个封装在带空格/引号的路径下会失败，
   直接在 PowerShell 里循环调 `bbsq` + `nutcracker` 即可。反编译输出是 UTF-16（字符间有空格）但可读。
4. 免疫模型：中毒/流血/昏迷等是靠技能 `onUpdate` 里设 `_properties.IsImmuneToX`；
   但有些 debuff（如 `effects.overwhelmed`、`effects.distracted`）**没有**免疫属性，
   就用 `mods_hookClass` 钩住那个效果类，免疫时跳过它的 `onUpdate`（必要时 `onAdded` 里
   `removeSelf()`）。可参照已有的两个 `mod_bbca_*_immunity.nut`。

---

## 8. 文档导航

- `docs/README.md` — 工程记忆索引、必读顺序和文档更新规则
- `docs/current-state.md` — 带日期的本机版本、构建、安装和待验证状态
- `docs/portable-custom-appearance-readme.md` — 总览
- `docs/portable-custom-appearance-handoff.md` — 稳定架构（技能 / 序列化 / 钩子 / 安装契约）
- `docs/development-playbook.md` — 长线开发、反编译、构建、安装和回归手册
- `docs/engineering-log.md` — 重要故障、决策与验证记录
- `docs/fantasybro-skill-production-analysis.md` — FantasyBro 技能制作分析与移植风险
- `docs/fantasybro-skill-catalog.html` — 111 个技能的中文可搜索图鉴
- `docs/png-asset-spec.md` — PNG 资产规范（尺寸是严格校验值）
- `docs/import-custom-appearance.md` — 资产导入器与管理器
- `docs/new-llm-starter-prompt.md` — 给新对话粘贴的起手提示词
- `docs/new-skill-development-starter-prompt.md` — 新技能开发专用交接对白
- `NEW-MACHINE-START.md` — 工程换机步骤、迁移包边界和当前起手对白
- `fantasybro-skill-book-and-shadow-walk..md` — Shadow Walk 来源的静态分析（参考）
- `codex-skills/battle-brothers-skill-development` — 便携的 Battle Brothers 技能开发 Codex skill

**给新对话起手**：把 `docs/new-llm-starter-prompt.md` 的内容贴给新 LLM；该提示会引导它
先读本文件和 `docs/README.md` 定义的核心文档。
