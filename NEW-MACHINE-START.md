# BB-Custom 换机接手

## 解压与首次核对

1. 将工程迁移 ZIP 解压；顶层目录应为 `BB-Custom`。
2. 先核对 ZIP 旁边的 `.sha256`，再查看包内 `HANDOFF-SHA256SUMS.txt`。
3. 新电脑只需重新确认 Steam 的 Battle Brothers 根目录；该目录必须包含
   `data\data_001.dat`。不要沿用 `docs/current-state.md` 中上一台电脑的绝对路径。
4. 工程包包含当前源码、文档、便携 BB 工具、固定 vendor 依赖、当前游戏安装包、
   Codex skill 源和 FantasyBro 源码参考档案。FantasyBro 只用于读源码，绝不能安装为
   运行时依赖。
5. 工程包不收集 Steam 文件、存档、日志、汉化包、旧诊断 staging 或任何
   `.bbca-backup`。
6. 在新电脑明确要求安装前，只做只读核对。安装前必须确认
   `BattleBrothers.exe` 已关闭；任何已有 `.bbca-backup` 都不能删除、覆盖或修改。

## 给新电脑上 Codex/LLM 的起手对白

```text
继续维护位于 <解压后的 BB-Custom 工程绝对路径> 的 Battle Brothers BB-Custom 工程。

开始前完整读取：
1. START-HERE.md
2. docs/README.md
3. docs/current-state.md
4. docs/portable-custom-appearance-handoff.md
5. docs/development-playbook.md
6. docs/fantasybro-skill-production-analysis.md
7. docs/engineering-log.md

技能开发时使用 $battle-brothers-skill-development；如果当前 Codex 尚未安装该 skill，
先完整读取便携源 codex-skills/battle-brothers-skill-development/SKILL.md 及其要求的
reference。FantasyBro 压缩包仅作源码参考，绝不作为运行时依赖安装。

上一台电脑的 current-state.md 只是带日期的历史机器状态。先只读核对迁移包 SHA-256、
build/custom_appearance/mod_bb_custom_appearance.zip、vendor 哈希、便携工具，以及新电脑
Battle Brothers 根目录下的 data/data_001.dat；不要假定 Steam 路径或游戏版本没变。

当前技能编辑器由唯一 ::BBCA_SkillCatalog 提供 Shadow Walk、燃烧手雷、召唤装甲复生者、
异常免疫 Aegis 和 Hard Chance；Legendary 列表还提供两件独立自愈装备。燃烧手雷
config v2；召唤 config v1；Aegis config v6；Hard Chance config v1。上一台电脑
最后修复了召唤后的第二回合软锁：当前实现必须保持直接实体引用和 actor API 检查，不能
恢复 weakref()+isNull()；召唤图标必须使用包内 bbca_summon_zombie*.png，不能恢复
active_26.png。自愈装备 ID、脚本路径、Variant 107/237 和每回合恢复 90 都属于稳定契约。
这些改动已编译并从工程重新构建，但游戏内第二回合、同场最高级食尸鬼、自愈装备生成/
恢复/存读档和新 log.html 仍待人工回归。

未经我明确要求，不写入 Steam；安装前确认 BattleBrothers.exe 已关闭；绝不删除、覆盖
或修改任何已有 .bbca-backup；不恢复旧独立命中率 ZIP，不做汉化，不使用 FantasyBro、
clone 启动器、steam_appid.txt、SUBST 或路径重定向。

完成只读核对后，简要报告：工程包是否完整、新电脑游戏版本、构建包哈希、待回归项和任何
路径差异，然后等待我的下一条指令。
```
