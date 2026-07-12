# New skill development conversation starter

把下面内容完整粘贴到新对话：

```text
继续维护 <解压后的 BB-Custom 工程绝对路径>，并为 Battle Brothers 的 BB-Custom
技能编辑器设计和制作新技能。

开始前完整读取：

1. START-HERE.md
2. docs/README.md
3. docs/current-state.md
4. docs/portable-custom-appearance-handoff.md
5. docs/development-playbook.md
6. docs/fantasybro-skill-production-analysis.md
7. docs/engineering-log.md

技能参考：

- 参考模组：参考/mod_fantasybro-473-4-2b-1722856556.zip
- 中文图鉴：docs/fantasybro-skill-catalog.html
- 中文数据源：docs/reference/fantasybro-skill-cn.tsv
- 可调用 Codex skill：$battle-brothers-skill-development
- 便携 skill 源：codex-skills/battle-brothers-skill-development

先询问我要制作或移植哪个技能，以及希望开放哪些可调参数；在我确认前先做设计与依赖分析，
不要直接安装。

开发规则：

- FantasyBro 仅作源码参考，绝不作为运行时依赖安装。
- 优先选择分析报告中的 A/B 级可移植技能；C 级必须包含完整 effect/图标/声音依赖；
  D 级实体、地形或世界状态技能需要单独评估。
- 使用稳定命名：
  - 主动技能：actives.bbca_<name>
  - 被动/effect：effects.bbca_<name>
  - 持久配置：effects.bbca_<name>_config
- 可调参数写入隐藏、序列化、带版本号的 config skill；战斗技能只读取 config。
- 新增存档字段必须提升序列化版本并兼容旧版本默认值。
- 技能编辑器 catalog 是授予、显示、参数和文档的唯一权威，不复制多份技能数组。
- 必须审计 new/add/hasSkill/removeByID、自定义 effect、实体、物品、图标、声音、粒子和
  延迟事件依赖。
- 处理死亡目标、目标移动、空格占用、高度差、定身、控制区、友伤和异步回调边界。
- 覆盖原版完整函数前，必须从本机当前 data_001.dat 重新反编译对应 .cnut。
- 修改后的 .nut 先用 bbsq.exe -e 编译副本，再构建并检查最终 ZIP。
- 未经我明确要求，不写入 Steam 游戏目录。
- 安装前确认 BattleBrothers.exe 已关闭。
- 绝不删除、覆盖或修改任何已有 .bbca-backup。
- 不恢复或修改汉化内容，不使用 FantasyBro、clone 启动器、steam_appid.txt 或路径重定向。

当前命中率 0--100 行为已内嵌。旧独立命中率 ZIP 因 Hook 加载顺序冲突，已由安装器按精确
SHA-256 停用并保存为 .bbca-backup。不要恢复该旧 ZIP。

每个新技能按以下顺序交付：

1. 中文设计说明与平衡建议
2. 依赖闭包和存档兼容方案
3. 源码、图标/effect、技能编辑器 catalog
4. 编译、构建和包内校验结果
5. 待我明确同意后再安装
6. 游戏内测试清单和日志检查
7. 回写 current-state.md 与 engineering-log.md

我的第一个新技能需求是：<在这里填写技能名称或效果>
```
