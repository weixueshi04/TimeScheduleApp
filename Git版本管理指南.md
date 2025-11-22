# 🌟 Git版本管理快速指南

## 📋 目录
1. 初始化Git仓库
2. 使用.gitignore文件
3. 基本Git操作
4. 推送到GitHub
5. 常用命令速查
6. Git提交规范
7. 分支管理
8. 常见问题解决

---

## 1️⃣ 初始化Git仓库

### 步骤1：在项目根目录初始化Git

```bash
# 进入项目目录
cd focus_life

# 初始化Git仓库
git init

# 查看状态
git status
```

### 步骤2：复制.gitignore文件

将我为你创建的`.gitignore`文件复制到项目根目录：

```bash
# 项目根目录应该有：
focus_life/
├── .gitignore          ← 这个文件
├── lib/
├── android/
├── ios/
├── pubspec.yaml
└── ...
```

---

## 2️⃣ 使用.gitignore文件

### .gitignore的作用

这个文件告诉Git哪些文件**不需要**提交到版本控制中，包括：

- ✅ 构建产物（build/目录）
- ✅ 依赖包（node_modules/、.pub/）
- ✅ IDE配置（.idea/、.vscode/）
- ✅ 操作系统临时文件（.DS_Store、Thumbs.db）
- ✅ 敏感信息（密钥、配置文件）
- ✅ 编译生成的文件（*.g.dart）

### 验证.gitignore是否生效

```bash
# 查看会被提交的文件
git status

# 如果.gitignore配置正确，你不会看到：
# - build/目录
# - .idea/目录
# - *.g.dart文件
# 等被忽略的内容
```

---

## 3️⃣ 基本Git操作

### 首次提交代码

```bash
# 1. 添加所有文件到暂存区
git add .

# 2. 查看将要提交的文件
git status

# 3. 提交代码（带提交信息）
git commit -m "feat: 初始化项目，搭建基础架构"

# 4. 查看提交历史
git log
```

### 日常提交流程

```bash
# 1. 查看修改了哪些文件
git status

# 2. 查看具体修改内容
git diff

# 3. 添加要提交的文件
git add lib/presentation/screens/home/home_screen.dart
# 或添加所有修改
git add .

# 4. 提交修改
git commit -m "feat: 完成首页UI设计"

# 5. 查看提交记录
git log --oneline
```

---

## 4️⃣ 推送到GitHub

### 步骤1：在GitHub创建仓库

1. 登录GitHub（https://github.com）
2. 点击右上角 "+" → "New repository"
3. 填写仓库信息：
   - **Repository name**: `focus-life`
   - **Description**: "时间与健康管理APP - Flutter项目"
   - **Public/Private**: 根据需要选择
   - **不要**勾选"Add a README file"（我们本地已有）
4. 点击"Create repository"

### 步骤2：关联远程仓库

```bash
# 添加远程仓库（替换成你的GitHub用户名）
git remote add origin https://github.com/你的用户名/focus-life.git

# 验证远程仓库
git remote -v
```

### 步骤3：推送代码

```bash
# 首次推送（创建main分支并推送）
git branch -M main
git push -u origin main

# 以后的推送
git push
```

### 使用SSH方式（推荐，免密码）

```bash
# 1. 生成SSH密钥（如果还没有）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 复制公钥内容
# macOS/Linux:
cat ~/.ssh/id_ed25519.pub
# Windows:
type %USERPROFILE%\.ssh\id_ed25519.pub

# 3. 在GitHub添加SSH密钥
# Settings → SSH and GPG keys → New SSH key → 粘贴公钥

# 4. 修改远程仓库地址为SSH
git remote set-url origin git@github.com:你的用户名/focus-life.git

# 5. 测试连接
ssh -T git@github.com
```

---

## 5️⃣ 常用命令速查

### 查看类命令

```bash
git status              # 查看当前状态
git log                 # 查看提交历史
git log --oneline       # 简洁查看提交历史
git log --graph         # 图形化查看分支
git diff                # 查看未暂存的修改
git diff --cached       # 查看已暂存的修改
git show <commit-id>    # 查看某次提交的详情
```

### 添加和提交

```bash
git add <file>          # 添加指定文件
git add .               # 添加所有修改
git add -A              # 添加所有修改（包括删除）
git commit -m "message" # 提交修改
git commit -am "msg"    # 添加并提交（仅跟踪的文件）
```

### 撤销操作

```bash
git checkout -- <file>  # 撤销工作区的修改
git reset HEAD <file>   # 取消暂存
git reset --soft HEAD~1 # 撤销最后一次提交（保留修改）
git reset --hard HEAD~1 # 撤销最后一次提交（删除修改）
```

### 远程操作

```bash
git remote -v           # 查看远程仓库
git push                # 推送到远程
git pull                # 拉取远程更新
git clone <url>         # 克隆仓库
```

---

## 6️⃣ Git提交规范

### Commit Message格式

遵循约定式提交（Conventional Commits）规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type类型

| 类型 | 说明 | 示例 |
|------|------|------|
| **feat** | 新功能 | `feat: 添加任务优先级筛选功能` |
| **fix** | Bug修复 | `fix: 修复番茄钟暂停后无法恢复的问题` |
| **docs** | 文档更新 | `docs: 更新README安装说明` |
| **style** | 代码格式调整 | `style: 格式化代码，统一缩进` |
| **refactor** | 重构 | `refactor: 重构任务列表组件` |
| **perf** | 性能优化 | `perf: 优化任务查询性能` |
| **test** | 测试相关 | `test: 添加任务Provider单元测试` |
| **chore** | 构建/工具相关 | `chore: 更新依赖包版本` |
| **build** | 构建系统 | `build: 配置Android打包参数` |
| **ci** | CI配置 | `ci: 添加GitHub Actions配置` |

### 好的Commit示例

```bash
# 好的提交 ✅
git commit -m "feat: 实现任务添加功能

- 添加任务表单UI
- 实现表单验证逻辑
- 集成Hive数据持久化
- 添加成功提示"

git commit -m "fix: 修复番茄钟计时不准确的问题"

git commit -m "refactor: 优化TaskProvider代码结构"

# 不好的提交 ❌
git commit -m "更新"
git commit -m "修改了一些东西"
git commit -m "bug fix"
```

---

## 7️⃣ 分支管理

### 创建和切换分支

```bash
# 查看所有分支
git branch

# 创建新分支
git branch feature/task-management

# 切换到分支
git checkout feature/task-management

# 创建并切换（快捷方式）
git checkout -b feature/focus-timer

# 删除分支
git branch -d feature/old-feature
```

### 合并分支

```bash
# 切换到主分支
git checkout main

# 合并功能分支
git merge feature/task-management

# 如果有冲突，解决后：
git add .
git commit -m "merge: 合并任务管理功能"
```

### 推荐的分支策略

```
main                    # 主分支（稳定版本）
├── develop            # 开发分支
│   ├── feature/xxx    # 功能分支
│   ├── feature/yyy    # 功能分支
│   └── bugfix/zzz     # Bug修复分支
└── release/v1.0       # 发布分支
```

---

## 8️⃣ 常见问题解决

### ❓ Q1: 提交了不该提交的文件怎么办？

```bash
# 1. 将文件添加到.gitignore
echo "sensitive_file.txt" >> .gitignore

# 2. 从Git中删除（但保留本地文件）
git rm --cached sensitive_file.txt

# 3. 提交删除操作
git commit -m "chore: 移除敏感文件"

# 4. 推送到远程
git push
```

### ❓ Q2: 如何撤销最后一次提交？

```bash
# 保留修改，撤销提交
git reset --soft HEAD~1

# 删除修改和提交（危险！）
git reset --hard HEAD~1
```

### ❓ Q3: 如何修改最后一次提交信息？

```bash
# 修改最后一次提交的message
git commit --amend -m "新的提交信息"

# 如果已经push，需要强制推送（慎用）
git push --force
```

### ❓ Q4: 如何解决合并冲突？

```bash
# 1. 拉取最新代码时出现冲突
git pull

# 2. Git会标记冲突文件，手动编辑解决
# 文件中会显示：
# <<<<<<< HEAD
# 你的修改
# =======
# 远程的修改
# >>>>>>> origin/main

# 3. 解决冲突后，标记为已解决
git add <冲突文件>

# 4. 完成合并
git commit -m "merge: 解决合并冲突"
```

### ❓ Q5: 如何忽略已经跟踪的文件？

```bash
# 1. 添加到.gitignore
echo "file.txt" >> .gitignore

# 2. 从Git中移除跟踪
git rm --cached file.txt

# 3. 提交更改
git commit -m "chore: 停止跟踪file.txt"
```

### ❓ Q6: 如何查看某个文件的修改历史？

```bash
# 查看文件的提交历史
git log -- lib/main.dart

# 查看文件每次的具体修改
git log -p -- lib/main.dart
```

### ❓ Q7: push被拒绝怎么办？

```bash
# 原因：远程有新的提交，本地落后

# 方法1：先拉取再推送（推荐）
git pull --rebase
git push

# 方法2：强制推送（危险，会覆盖远程）
git push --force  # 仅在确定的情况下使用
```

---

## 🎯 Git工作流程建议

### 每日工作流

```bash
# 早上开始工作
git pull                # 拉取最新代码

# 开发过程中（每完成一个小功能）
git add .
git commit -m "feat: xxx"

# 晚上结束工作
git push                # 推送到远程
```

### 功能开发流程

```bash
# 1. 创建功能分支
git checkout -b feature/task-filter

# 2. 开发功能
# ... 编写代码 ...

# 3. 提交到功能分支
git add .
git commit -m "feat: 实现任务筛选功能"

# 4. 切换到主分支并合并
git checkout main
git merge feature/task-filter

# 5. 推送到远程
git push

# 6. 删除功能分支
git branch -d feature/task-filter
```

---

## 📚 Git学习资源

### 官方文档
- Git官方文档：https://git-scm.com/doc
- Git中文文档：https://git-scm.com/book/zh/v2

### 在线教程
- Git入门教程：https://www.liaoxuefeng.com/wiki/896043488029600
- GitHub官方指南：https://guides.github.com

### 可视化工具
- **SourceTree**（推荐新手）
- **GitHub Desktop**（简单易用）
- **GitKraken**（功能强大）
- **VS Code内置Git**（轻量方便）

---

## ✅ 检查清单

在开始使用Git前，确保：

- [ ] 安装了Git（`git --version`检查）
- [ ] 配置了用户名和邮箱
- [ ] `.gitignore`文件放在项目根目录
- [ ] 初始化了Git仓库（`git init`）
- [ ] 在GitHub创建了远程仓库
- [ ] 关联了远程仓库（`git remote -v`检查）
- [ ] 理解了基本的Git操作流程

---

## 🎊 Git配置建议

### 全局配置

```bash
# 配置用户名和邮箱
git config --global user.name "你的名字"
git config --global user.email "your_email@example.com"

# 配置默认编辑器
git config --global core.editor "code --wait"  # VS Code

# 配置别名（快捷命令）
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all"

# 查看所有配置
git config --global --list
```

### 项目配置

在项目根目录创建`.gitattributes`文件：

```
# 自动转换行尾
* text=auto

# Dart文件
*.dart text diff=dart

# Markdown文件
*.md text

# 图片文件
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
```

---

## 💡 最佳实践

1. **频繁提交**：每完成一个小功能就提交，不要积累太多修改
2. **有意义的提交信息**：让别人（和未来的自己）能看懂
3. **使用分支**：不要直接在main分支开发
4. **定期推送**：避免代码丢失
5. **拉取前提交**：避免冲突
6. **不要提交敏感信息**：密码、密钥等
7. **代码审查**：重要修改可以使用Pull Request
8. **保持.gitignore最新**：及时添加不需要跟踪的文件

---

## 🚀 现在就开始！

```bash
# 完整的第一次提交流程
cd focus_life
git init
git add .
git commit -m "feat: 初始化FocusLife项目

- 配置Flutter项目结构
- 添加依赖包
- 实现底部导航栏
- 创建5个占位页面
- 配置iOS风格主题"

git remote add origin https://github.com/你的用户名/focus-life.git
git branch -M main
git push -u origin main
```

**祝你的项目开发顺利！🎉**

---

**记住：Git是你的好朋友，它会保护你的代码！**
