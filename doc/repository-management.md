# 仓库管理

本文档说明 VKit 如何管理工作区中的多个 Git 仓库，以及如何把你自己的项目导入到 VKit 工作区。

请先记住一个核心原则：

- `.repos` 负责把源码放进工作区
- `config/<platform>/*.cfg` 负责把项目加入构建

这两步缺一不可。

## 目录

- [仓库管理概述](#仓库管理概述)
- [仓库清单文件](#仓库清单文件)
- [仓库变体](#仓库变体)
- [导入仓库](#导入仓库)
- [更新仓库](#更新仓库)
- [VCS 工具](#vcs-工具)
- [自定义仓库配置](#自定义仓库配置)

---

## 仓库管理概述

VKit 使用 `.repos` 文件描述一个工作区需要包含哪些 Git 仓库。每个变体都位于：

```text
repos/<variant>/
```

标准结构如下：

```text
repos/
├── dev/
│   ├── setup.repos
│   ├── prebuilt.repos
│   ├── thirdparty.repos
│   ├── vendor.repos
│   ├── middleware.repos
│   └── app.repos
└── full/
    ├── setup.repos
    ├── prebuilt.repos
    ├── thirdparty.repos
    ├── vendor.repos
    ├── middleware.repos
    └── app.repos
```

VKit 导入时会按这个顺序依次处理这些清单。

---

## 仓库清单文件

`.repos` 文件使用 YAML 格式，核心结构如下：

```yaml
repositories:
  middleware/my-service:
    type: git
    url: git@github.com:myorg/my-service.git
    version: main
```

字段含义：

- `repositories`：所有条目的根键
- `middleware/my-service`：项目导入后的本地相对路径
- `type`：当前一般使用 `git`
- `url`：Git 仓库地址
- `version`：分支、标签或提交号

这里最重要的是本地路径。它决定了仓库最终会被克隆到哪里，也决定了你后续在 `cfg` 中该写什么项目路径。

例如上面的清单会把代码克隆到：

```text
middleware/my-service/
```

---

## 仓库变体

### 当前内置变体

当前仓库中最关键的两个变体是：

- `dev`
- `full`

### `dev` 的含义

`dev` 更偏向最小开发工作区。当前内置重点是：

- `middleware/vlink-msgs`

### `full` 的含义

`full` 在 `dev` 的基础上额外包含：

- `middleware/vlink`

也就是说，当前内置中间件项目只有：

- `middleware/vlink`
- `middleware/vlink-msgs`

`app.repos` 当前可以为空，其他业务项目由用户自行添加。

### 什么时候选 `dev`，什么时候选 `full`

- 如果你先想快速拉起工作区，选 `dev`
- 如果你需要完整的内置中间件工作区，选 `full`

---

## 导入仓库

### 首次导入

最常用写法：

```bash
make import dev
make import full
```

等价脚本写法：

```bash
./vkit-setup.sh import dev
./vkit-setup.sh import full
```

固定简写也可用：

```bash
make import_dev
make import_full
```

### 导入流程

脚本会按下面顺序处理清单：

```text
1. setup.repos
2. prebuilt.repos
3. thirdparty.repos
4. vendor.repos
5. middleware.repos
6. app.repos
```

所以如果你把一个新仓库写进 `app.repos`，它会在 `app/` 层对应路径下被导入。

### 导入自定义变体

如果你新建了：

```text
repos/customer-a/
```

那么就可以使用：

```bash
./vkit-setup.sh import customer-a
```

或者：

```bash
make import customer-a
```

---

## 更新仓库

### 批量更新

```bash
make pull
# 或
./vkit-setup.sh pull
```

这会遍历当前工作区里已经存在的这些仓库根目录并执行批量更新：

- `setup/`
- `prebuilt/`
- `prebuilt-ext/`
- `thirdparty/`
- `thirdparty-ext/`
- `vendor/`
- `vendor-ext/`
- `middleware/`
- `middleware-ext/`
- `app/`
- `app-ext/`

如果某个目录不存在，会被自动跳过。

---

## VCS 工具

VKit 会优先使用：

- `ripvcs`

如果不可用，则回退到：

- `vcs`

你可以查看当前值：

```bash
echo $VKIT_VCS_TOOL
```

这个变量在执行 `source vkit-setup.sh` 时会自动设置。

---

## 自定义仓库配置

这一节是接入你自己项目时最重要的部分。

### 场景一：把一个远程 Git 项目导入到 VKit

假设你要把 `my-service` 接入到 `middleware/` 层。

#### 步骤 1：决定本地目录

先决定它在工作区中要落到哪里，例如：

```text
middleware/my-service
```

#### 步骤 2：编辑对应变体的 `.repos`

如果你希望它属于完整工作区，就编辑：

```text
repos/full/middleware.repos
```

加入：

```yaml
repositories:
  middleware/vlink:
    type: git
    url: https://github.com/thun-res/vlink.git
    version: master
  middleware/vlink-msgs:
    type: git
    url: https://github.com/thun-res/vlink-msgs.git
    version: master
  middleware/my-service:
    type: git
    url: git@github.com:myorg/my-service.git
    version: main
```

如果你不想动现有变体，也可以复制一份新变体：

```bash
cp -r repos/full repos/my-workspace
```

然后修改：

```text
repos/my-workspace/middleware.repos
```

#### 步骤 3：执行导入

```bash
make import my-workspace
```

或者：

```bash
./vkit-setup.sh import my-workspace
```

#### 步骤 4：确认源码已经落地

```bash
ls middleware/my-service
```

#### 步骤 5：把项目注册进构建配置

仅导入仓库还不够，你还必须编辑目标平台的 cfg，例如：

```text
config/linux-x86_64/middleware.cfg
```

加入：

```text
middleware/vlink;
middleware/vlink-msgs;
middleware/my-service;
```

#### 步骤 6：开始构建

```bash
source vkit-setup.sh
cd middleware/my-service
mmm
```

或者整层构建：

```bash
mm_middleware
```

### 场景二：导入一个应用项目

方法完全一样，只是路径改成：

```text
app/my-tool
```

并把仓库条目写到：

```text
repos/<variant>/app.repos
```

构建注册写到：

```text
config/<platform>/app.cfg
```

例如：

```text
app/my-tool;
```

### 场景三：项目不想通过 `.repos` 管理，只想本地直接放进去

这也完全可行。

例如你可以直接创建：

```bash
mkdir -p app/my-local-tool
```

然后：

1. 把源码直接放入该目录
2. 保证项目具备 `CMakeLists.txt`、`build.sh` 或 `Makefile`
3. 在 `config/<platform>/app.cfg` 中加入 `app/my-local-tool;`
4. `source vkit-setup.sh`
5. 进入该目录执行 `mmm`

这种方式的特点是：

- 不依赖 `.repos`
- 更适合本地试验或临时项目
- 但不便于团队统一同步源码来源

### 常见误区

#### 误区 1：导入后为什么 `mm_all` 还是没有构建我的项目？

因为导入只解决源码来源，不会自动修改 `cfg`。

#### 误区 2：我已经把项目写进 cfg 了，为什么还提示目录不存在？

因为 `cfg` 只负责“构建什么”，不负责“代码从哪里来”。要么先导入仓库，要么自己把目录放进去。

#### 误区 3：项目路径应该写仓库名还是目标目录？

始终写工作区里的相对路径，例如：

```text
middleware/my-service
app/my-tool
```

不要只写远程仓库名。
