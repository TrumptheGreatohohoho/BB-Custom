# 长线开发与验证手册

## 1. 开始任务前

1. 读 `START-HERE.md`、`docs/README.md` 和 `docs/current-state.md`。
2. 确认任务属于造型、Breditor 扩展、技能编辑器或已内嵌的兼容行为。
3. 用户已授予后续修改的常设部署授权：完成所需编译、构建和 ZIP 核验后，通过标准安装器
   写入 Steam；每次安装前仍须确认 `BattleBrothers.exe` 已关闭。
4. 不改任何已存在的 `.bbca-backup`，不把 FantasyBro 或汉化包引入运行时。

## 2. 源码权威

- PNG 和资产目录：`asset_repo/custom_appearance`
- 资产清单：`asset_repo/custom_appearance/manifest.json`
- Squirrel、UI、图标：`mod_source/bb_custom_appearance`
- 构建与安装脚本：`tools`
- 固定运行时依赖：`vendor`，哈希见 `vendor/README.md`
- 生成产物：`build/custom_appearance`，可重建，不是源码权威

保存到角色或存档中的 brush ID、技能 ID、配置 ID 都属于兼容接口；不得随意改名。

## 3. 按改动类型验证

### PNG 或 manifest

- 使用导入器或严格遵守 `docs/png-asset-spec.md`。
- 构建必须通过尺寸、PNG 头和透明像素检查。
- 检查 brush ID 未复用，已有 ID 未被重命名。
- 游戏内检查各图层定位、透明边缘、无头发/胡子串层。

### UI 或 Breditor 后端

- 构建后运行标准安装器；安装器会在 staging 中验证 HTML、CSS、JS、brush、atlas 和后端标记。
- 游戏内检查 `Shift+X`、面板布局、下拉项、按钮状态及长文本是否溢出。
- 后端请求必须校验 `BroId`、技能/资源 ID 和参数范围。

### 技能或存档配置

- 对修改过的 `.nut` 用 `_tools/bbros/bin/bbsq.exe -e <copy.nut>` 做语法编译。
- 检查授予技能、保存参数、战斗读取和读档后的持久化。
- 新字段必须提升序列化版本，并按版本条件读取；旧存档缺字段时使用稳定默认值。
- 在 `START-HERE.md` 和 `current-state.md` 记录是否需要逐角色点击“保存参数”。

### 原版类 Hook 或完整函数覆盖

这是最高风险改动。

1. 从当前 Steam `data\data_001.dat` 提取对应 `.cnut`。
2. 运行 `bbsq.exe -d <file.cnut>`，再用 `nutcracker.exe <file.cnut> > out.nut`。
3. 反编译输出为 UTF-16；按当前游戏版本逐段对照，不依赖旧模组副本。
4. 尽量包装原函数；确需完整覆盖时，只改目标行为，其余控制流、事件参数和属性名保持原版。
5. 检查其他压缩包是否 Hook 同一类。无法移除历史包时，用 Mod Hooks 队列明确最后生效顺序。
6. 游戏升级后，完整覆盖一律视为待重新验证。

使用 Mod Hooks 42 时，`mods_hookClass` 还会把回调应用到目标类的直接子类。如果代码直接读取
仅由基类定义的成员（而不是先沿 `SuperName` 查找），应使用 `mods_hookExactClass` 只包装定义
该成员的类；否则派生类可能在预载阶段注册失败，最终以读档 class key 未注册的形式爆发。

## 4. 标准构建

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\build_custom_appearance_pack.ps1
```

构建后至少检查：

- `build/custom_appearance/mod_bb_custom_appearance.zip` 存在。
- 改动脚本存在于包内正确路径。
- 包内脚本文本包含新逻辑，不含已移除的危险字段。
- 记录构建 SHA-256 到 `docs/current-state.md`。

## 5. 标准安装

首选运行：

```text
Install-Custom-Appearance-To-Steam.bat
```

自动化调用可使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\install_custom_appearance_pack.ps1 `
  -GameDir "<STEAM_LIBRARY>\steamapps\common\Battle Brothers"
```

安装后检查构建包与 Steam 安装包 SHA-256 一致。不要通过手工复制绕过安装器的 staging
验证和一次性备份规则。

## 6. 游戏回归与日志

- 日志通常在 `%USERPROFILE%\Documents\Battle Brothers\log.html`。
- 先按最小复现步骤测试，再搜索 `Script Error`、相关字段名和脚本路径。
- 记录游戏版本、复现动作、错误文本、栈顶脚本和行号。
- 修复后重复相同动作，并至少覆盖近战、远程、读档和技能保存中受影响的路径。
- 没有实际进游戏测试时，必须在 `current-state.md` 明确写“待人工回归”，不能写成已完全验证。

## 7. 发布/转移清单

1. 源码、文档和 `build/custom_appearance` 同步。
2. 运行构建并记录哈希。
3. 更新 `current-state.md` 和 `engineering-log.md`。
4. 更新受影响的稳定契约文档与新 LLM 起手提示。
5. 运行时便携发布不包含旧诊断目录、汉化目录或外部 FantasyBro 包。仅用于继续开发的
   工程换机包可以包含 `参考/mod_fantasybro-473-4-2b-1722856556.zip`，但必须明确标为
   源码参考，绝不能把它交给安装器或列为运行时依赖。
6. 不删除任何 `.bbca-backup`；便携包中也不要主动收集 Steam 备份。
7. 新机器只适配 Steam 游戏路径，并用 `data\data_001.dat` 验证目录。
