# 游戏内验收：`_injured` / `_dead` 派生 brush 修复

**状态：待用户游戏内验证**（代码/资产/部署已完成并通过静态验收，见下）

对应缺陷档案：`../问题记录/BBCA-女性身体-injured-brush缺失.md`
被测构建：`245140` 字节，SHA-256
`2E6975CAE6B67D2A1EE26C84C1B1EEA04D46080508BE19932CDA27A81BE2DA39`（与 Steam 已装包一致）

---

## 为什么要人来做这一步

静态验收只能证明"包里的 brush 名和图形都对"。**"游戏里看起来对不对"只能靠眼睛**：
受伤图层是否正常贴上、尸体外观是否正确、日志是否真的不再报警。自动化跑不到这里。

## 触发条件（必须同时满足才能验到）

关键：受伤/尸体 brush 只在**使用自定义女性身体**的角色身上派生。

1. 启动游戏，载入一个**有自定义 `body` 的兄弟**的存档。没有的话先按
   `Shift+X` → CUSTOM APPEARANCE 面板给某个兄弟 APPLY `Female body 01` 或 `Female body 02`。
2. **受伤路径**：让该角色生命值降到 **40% 以下**（`player.nut` 的判据是 `p > 0.4` 则隐藏）。
   最省事就是打一场硬仗让它挂彩。
3. **尸体路径**：让该角色**阵亡**，在战场上产生尸体（`human.nut:117` 的 `<body>_dead`）。
4. 正常打完、回到大地图并存档，然后**完全退出**游戏（日志在退出时收尾）。

## 判据

| # | 检查 | 通过条件 |
| --- | --- | --- |
| 1 | 受伤图层 | 血量 < 40% 的角色**显示受伤贴图**，不再空白/错位 |
| 2 | 尸体外观 | 阵亡角色的尸体外观正常（不是空白或原版错位） |
| 3 | 日志无缺失刷子 | `log.html` 中 **`Unknown Brush requested` 出现 0 次** |
| 4 | 无新错误 | `log.html` 中 `Script Error` 出现 0 次 |
| 5 | 未回退 | 自定义外观在 `Shift+X` 面板里仍正常可用，面板里**不出现** `injured` / `dead` 选项 |

**失败时最可能看到的字符串**（出现即说明没修好）：

```
Unknown Brush requested: bbca_female_body_01_injured
Unknown Brush requested: bbca_female_body_02_injured
Unknown Brush requested: bbca_female_body_01_dead
Unknown Brush requested: bbca_female_body_02_dead
```

> 注意：日志里那 21 条 `[IO] Unexpected file or directory found:` 和
> `The game uses modified files...` 是**预期噪音**（游戏对 `data\` 里所有非官方文件的固定抱怨），
> 不算失败。**只看 `Unknown Brush requested` 与 `Script Error`。**

## 怎么核日志（日志在游戏安装根目录，不在 Documents）

```powershell
$log = "D:\games\steam\steamapps\common\Battle Brothers\log.html"
$c = Get-Content $log -Encoding UTF8 -Raw
"version     : " + ([regex]::Match($c,'<title>([^<]+)</title>').Groups[1].Value)
"UnknownBrush: " + ([regex]::Matches($c,'Unknown Brush requested[^<]*') | ForEach-Object { $_.Value } | Sort-Object -Unique) -join ' | '
"ScriptError : " + [regex]::Matches($c,'Script Error').Count
```

## 结果记录（用户回报后填写）

| 项目 | 值 |
| --- | --- |
| 验证日期 | *待填* |
| 存档名 | *待填* |
| 触发到的路径 | *待填*（受伤 / 尸体 / 两者） |
| 检查 1 受伤图层 | *待填* |
| 检查 2 尸体外观 | *待填* |
| 检查 3 `Unknown Brush requested` 次数 | *待填*（期望 **0**） |
| 检查 4 `Script Error` 次数 | *待填*（期望 **0**） |
| 检查 5 面板未被污染 | *待填* |
| 日志时间戳区间 | *待填* |
| 结论 | *待填*（通过 / 不通过 + 现象） |

**结论为"通过"后**：把本文件状态改为"已通过"，同步更新
`../待办与回归清单.md` 的 A 节与 `../../docs/current-state.md` 的 2026-09-23 条目，
然后 commit + push（本机需 `git -c http.proxy= -c https.proxy= push`，原因见 `../当前状态.md` 第 2 节）。

**结论为"不通过"后**：别改结论蒙混过去 —— 记录实际日志字符串与截图，回到缺陷档案重开分析。
