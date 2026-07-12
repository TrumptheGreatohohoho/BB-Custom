# 工程记忆索引

本目录保存 BB-Custom 的长期工程记忆。代码和实际构建产物始终是实现事实；
文档负责记录边界、设计原因、当前部署状态和可重复的验证方法。

## 新对话必读顺序

1. `START-HERE.md`：工程入口、功能概览和不可违反的规则。
2. `docs/current-state.md`：最近一次确认的本机版本、部署状态、已知风险和待验证项。
3. `docs/portable-custom-appearance-handoff.md`：稳定架构、运行时契约、技能和序列化设计。
4. `docs/development-playbook.md`：开发、反编译、构建、安装和回归验证流程。

按任务再读：

- `docs/git-sync.md`：两台电脑通过 GitHub 切换、提交、拉取和冲突处理规则。
- `docs/png-asset-spec.md`：PNG 图层、尺寸和命名规范。
- `docs/import-custom-appearance.md`：资产导入器和管理器用法。
- `docs/engineering-log.md`：重要故障、根因、决策和验证证据。
- `docs/fantasybro-skill-production-analysis.md`：FantasyBro 技能制作模式、风险和移植建议。
- `docs/fantasybro-skill-catalog.html`：111 个技能的可搜索中文图鉴。
- `docs/portable-custom-appearance-readme.md`：面向使用者的便携包说明。
- `docs/new-llm-starter-prompt.md`：给新 LLM 对话粘贴的起手提示。
- `docs/new-skill-development-starter-prompt.md`：专用于新技能制作对话的交接提示。
- `NEW-MACHINE-START.md`：工程迁移包的范围、换机检查和当前起手对白。
- `fantasybro-skill-book-and-shadow-walk..md`：Shadow Walk 来源的历史静态分析。
- `codex-skills/battle-brothers-skill-development`：可随工程转移的技能开发 Codex skill。

## 文档职责

| 文档 | 只记录什么 | 何时更新 |
| --- | --- | --- |
| `START-HERE.md` | 当前能力、硬规则、入口导航 | 功能或规则变化时 |
| `current-state.md` | 带日期的机器与部署事实 | 每次构建、安装、游戏升级或发现风险后 |
| `portable-custom-appearance-handoff.md` | 稳定架构和兼容契约 | 设计、ID、序列化或依赖变化时 |
| `development-playbook.md` | 可重复操作和验证清单 | 工具链或测试方法变化时 |
| `engineering-log.md` | 追加式问题与决策历史 | 每次重要修复或架构决策后 |
| `git-sync.md` | 两机 GitHub 同步流程和边界 | 仓库、分支或同步方式变化时 |
| 资产规范/导入说明 | 资产输入契约 | 图层、尺寸或导入流程变化时 |

## 维护规则

- 不在架构文档里长期保存易过期的本机哈希、安装日期和绝对路径；这些只放
  `current-state.md`。
- `engineering-log.md` 采用追加方式；不要为了“看起来整洁”删除曾经有效的诊断证据。
- 行为改动至少同步更新：相关源码、`current-state.md`、`engineering-log.md`，以及受影响的
  稳定契约文档。
- 新增存档字段时必须记录序列化版本、旧版本读取分支和用户迁移动作。
- 覆盖原版完整函数时必须绑定到已验证的游戏版本，并在游戏升级后重新反编译对照。
- 文档中引用脚本、技能 ID、配置 ID 时使用代码里的精确名称，避免只写中文描述。
- 任何 Steam 写入仍受 `START-HERE.md` 的常设部署授权范围、游戏进程关闭检查和
  `.bbca-backup` 铁律约束。
