# 两台电脑 GitHub 同步规则

共享仓库：<https://github.com/TrumptheGreatohohoho/BB-Custom>

`main` 是两台电脑共同的源码历史。工作副本的绝对路径可以不同；仓库内容、提交历史和远端
`origin` 才用于判断是否同步。`build/` 是本机生成物，受 `.gitignore` 排除，不会上传。

## 新电脑首次建立工作副本

```powershell
New-Item -ItemType Directory -Force "D:\project"
Set-Location "D:\project"
git clone https://github.com/TrumptheGreatohohoho/BB-Custom.git
Set-Location "D:\project\BB-Custom"
git config user.name "TrumptheGreatohohoho"
git config user.email "xukang1989513@gmail.com"
git status
```

首次克隆后应位于 `main`，并显示工作区干净。不要把另一台电脑的 `build/`、Steam `data/`、
存档、`.bbca-backup` 或 `.bbca-disabled` 复制进仓库。

## 每次开始工作

```powershell
git status
git pull --ff-only
```

只有拉取成功且工作区状态符合预期后才开始修改。`--ff-only` 失败时停止修改，不要 force pull、
reset hard 或随意覆盖；先检查另一台电脑是否有尚未推送的提交，再处理分支或冲突。

## 每次离开当前电脑前

```powershell
git status
git add -A
git commit -m "简短说明本次修改"
git push
git status
```

最后一次 `git status` 应显示当前 `main` 与 `origin/main` 同步且工作区干净。没有实际变化时不需要
创建空提交，但仍应确认此前提交已经 push。

## 两机切换铁律

1. 同一时间只在一台电脑上修改同一批文件。
2. 离开一台电脑前完成 commit + push；到另一台电脑后先 pull --ff-only。
3. 不使用 `git push --force`、`git reset --hard` 或直接复制整个工程目录来解决分歧。
4. 源码与稳定文档要提交；`build/`、Steam 包、日志和存档不提交。
5. 安装游戏 MOD 仍是独立部署动作：未经用户明确要求不写 Steam，安装前关闭
   `BattleBrothers.exe`，绝不修改任何 `.bbca-backup`。

## 网络或登录问题

Git for Windows 自带的 Git Credential Manager 会在首次 push 时引导浏览器登录 GitHub。
如果 `pull`/`push` 报网络、认证或非快进错误，不要继续改文件，把完整错误交给 Codex 处理。
